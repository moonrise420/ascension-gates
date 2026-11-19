ENT.PlayerColor = Color(255,255,255,255);

-- AGP 2026-11-16 (owner test): a free spot to stand INSIDE the cabin after leaving the pilot seat. Only spots on the
-- cabin's centre line count (cockpit first, then the rear cabin), on the cabin floor, with the player's whole hull free
-- of the hull, the closed door and bulkhead, the seats - and with the Jumper's roof above (so never outside: the general
-- stand-spot search could step 64 units sideways, through the wall, and put the pilot outside).
local CABIN_X = { 0, 15, -15, -75, -110, -145 }
local CABIN_Y = { 0, 10, -10 }
local function cabinSpot(self, ply)
	local mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72)
	if IsValid(ply) and ply.GetHull then mins, maxs = ply:GetHull() end
	local function skip(e) return IsValid(e) and e ~= ply and not e:IsPlayer() end
	local omin, omax = self:OBBMins(), self:OBBMaxs()
	for _, x in ipairs(CABIN_X) do
		for _, y in ipairs(CABIN_Y) do
			local want = self:LocalToWorld(Vector(x, y, -40))
			local down = util.TraceLine({ start = want + Vector(0, 0, 30), endpos = want - Vector(0, 0, 60), mask = MASK_PLAYERSOLID, filter = skip })
			if down.Hit and not down.StartSolid and down.HitNormal.z > 0.6 then
				local spot = down.HitPos + Vector(0, 0, 2)
				local lp = self:WorldToLocal(spot)
				local inside = lp.x > omin.x and lp.x < omax.x and lp.y > omin.y and lp.y < omax.y and lp.z > omin.z and lp.z < omax.z
				local tr = util.TraceHull({ start = spot, endpos = spot, mins = mins, maxs = maxs, mask = MASK_PLAYERSOLID, filter = skip })
				if inside and not (tr.Hit or tr.StartSolid) then
					local roof = util.TraceLine({ start = spot + Vector(0, 0, maxs.z - 4), endpos = spot + Vector(0, 0, 300), mask = MASK_PLAYERSOLID, filter = skip })
					if roof.Hit and IsValid(roof.Entity) and (roof.Entity == self or roof.Entity.JumperPart) then return spot end
				end
			end
		end
	end
end

function ENT:ExitJumper() --################# Get out the jumper@RononDex
	if (self.Autopilot) then self:AutoPilot(false) end -- AGP: the autopilot ends with the pilot (the next one had every key blocked)
	local exitPly
	if (IsValid(self.Pilot)) then
		StarGate.KeyBoard.ResetKeys(self.Pilot,"PuddleJumper");

		self.Pilot:UnSpectate()
		self.Pilot:DrawViewModel(true)
		self.Pilot:DrawWorldModel(true)
		if (AGP and AGP.ShipRespawnPilot) then AGP.ShipRespawnPilot(self.Pilot) else self.Pilot:Spawn() end -- AGP 2026-11-08: keeps armour and ammo, no Ha'tak bunk move (agp_ship_shield.lua)
		self.Pilot:SetNWBool("isFlyingjumper",false)
		if(IsValid(self.PilotAvatar)) then self.PilotAvatar:Remove() end -- AGP: the pilot figure sat on the exit spot (it blocked the cabin: you were put outside)
		-- AGP 2026-11-16 (owner test): the stand spot is chosen further down, AFTER the cabin's door and bulkhead parts are
		-- back - chosen before them, the player stood inside the closed door/bulkhead and could not move until it opened.
		exitPly = self.Pilot
		self.AllowActivation=false
		self.Pilot:SetHealth(self.health)
		self.Pilot:SetMoveType(MOVETYPE_WALK);
		self.Pilot:SetCollisionGroup(COLLISION_GROUP_PLAYER);
		self.Pilot:SetNetworkedEntity("ScriptedVehicle", NULL)
		self.Pilot:SetViewEntity(NULL)
        self.Pilot:SetCollisionGroup(COLLISION_GROUP_PLAYER);
        self.Pilot:SetColor(self.PlayerColor);
		for k,v in pairs(self.PWeapons) do
			self.Pilot:Give(tostring(v))
		end
		self.Pilot = nil;
	end
    
    if(IsValid(self.PilotAvatar)) then
        self.PilotAvatar:Remove(); 
    end

	if(IsValid(self)) then
		self:EmitSound(self.Sounds.Shutdown,100,100)
		self:SetNetworkedEntity("jumper",NULL)
		self.HoverPos = self:GetPos();
		self:SetWire("Driver",NULL)

		self:RemoveDrones() -- Remove the drone props... SO MANY BUGS BECAUSE OF THESE THINGS!
		self.Roll=0
		self.LiftOff = false
		self.Inflight=false
		self.Accel.FWD = 0;
		self.Accel.RIGHT = 0;
		self.Accel.UP = 0;

		self:SetNWBool("JumperInflight",false);

		self:SpawnToggleButton(self.Owner);
		self:SpawnBulkHeadDoor(nil,self.Owner);
		self:SpawnBackDoor(nil,self.Owner);
		if(self.door) then
			self.Door:SetSolid(SOLID_NONE);
		end
		self:SpawnOpenedDoor(self.Owner);

		-- AGP 2026-11-16: now that the door and bulkhead are back, the pilot gets a free spot in the cabin
		if (IsValid(exitPly)) then
			local want = self:GetPos()+self:GetForward()*-25+self:GetUp()*-40
			exitPly:SetPos(cabinSpot(self, exitPly) or (AGP and AGP.ShipExitSpot and AGP.ShipExitSpot(self, exitPly, want, false)) or want) -- outside only when the cabin is full
		end

		self:ToggleRotorwash(false);

		if(self.epodo) then
			self.CanDoPods = false
			self.sequence = self:LookupSequence("epodc")
			self:EmitSound(self.Sounds.EnginePodClose,100,100)
			self.Roll = 0
			self.WepPods = false -- AGP 2026-11-16: the drone pods close with the drive pods (the flag stayed true: no drones on the next flight)
			self:RemoveDrones()
			self.CloakPods = false;
			timer.Simple( 1, function() if not IsValid(self) then return end
				self.epodo = false
			end)
		
			self:ResetSequence(self.sequence)
			self:SetPlaybackRate(0.9)
			self.NextUse.EnginePods = CurTime() + self:SequenceDuration(self.sequence)
		end

		timer.Simple( 0.75, function() if not IsValid(self) then return end
			self.AllowActivation = true
		end);
	end

end

function ENT:AutoPilot(b)
	
	if(b) then
		if self.Autopilot then return end;
		local gate = self:FindGate(5000);
		if(IsValid(gate)) then
			if((self:GetPos()-gate:GetPos()):DotProduct(gate:GetForward()) > 0) then
			
				local Dist = self:WorldToLocal(gate:GetPos()).x;
				if(Dist < 600) then Dist = 600 end;
				self.AutoAlignPos = gate:GetPos()+gate:GetForward()*Dist;
				
				
				local gateRoll = gate:GetAngles().r;
				self.AutoAlignAng = gate:GetAngles() + Angle(180,0,-180-gateRoll*2);
				
				self.Autopilot = true;
				self.AutoGate = gate;
				AGP.Say(self.Pilot, "agp_jumper_autopilot_on", "Autopilot engaged");
				
				if(self.epodo) then
					self:TogglePods();
				end
				
				if(self.Cloaked) then
					self:ToggleCloak();
				end
				
				if(self.Shielded) then
					self:ToggleShield();
				end
				
				if(self.door) then
					self:ToggleDoor();
				end
			else
				AGP.Say(self.Pilot, "agp_jumper_autopilot_front", "Please move to the front of the Stargate");
			end
		else
			AGP.Say(self.Pilot, "agp_jumper_autopilot_range", "You are not in range of a Stargate");
		end
	else
		self.AutoAlignPos = nil;
		self.AutoAlignAng = nil;
		self.Autopilot = false;
		self.AutoGate = NULL;
		self.FinalAlignment = false;
		AGP.Say(self.Pilot, "agp_jumper_autopilot_off", "Autopilot disengaged");
	end

end


function ENT:EnterJumper(ply) --############### Get in the jumper @ RononDex
	self.RequireATAGene = StarGate.CFG:Get("cap_enhanced_cfg","ATA_gene_active",false);

	if self.RequireATAGene and StarGate.HasATA(ply,true) == false then return end

	if(self.AllowActivation) then
		self:GetPhysicsObject():Wake()
		self:GetPhysicsObject():EnableMotion(true)
		self.Inflight = true
		self.Pilot=ply
		self:SetWire("Driver",self.Pilot)
		self.Roll=0
		if(self.BulkHead) then
			self:ToggleBulkHead()
		end

		if(not self.Cloaked) then
			self:ToggleRotorwash(true)
		end

		ply:SetNetworkedEntity("ScriptedVehicle", self) -- still needed for event horizon
		ply:SetViewEntity(self)

		for _,v in pairs(ply:GetWeapons()) do
			table.insert(self.PWeapons, v:GetClass())
		end
		self.health=ply:Health()

		self.AllowActivation=false
		self.LiftOff = true
		self:EmitSound(self.Sounds.Startup, 100, 100)
		ply:DrawViewModel(false)
		ply:DrawWorldModel(false)

		self.StartPos = self:GetPos()

		self:RemoveAll(); -- We need to remove all welded props in order to go through gates properly.

		ply:Spectate( OBS_MODE_CHASE )
		ply:StripWeapons()

		ply:SetNWBool("isFlyingjumper",true)
		ply:SetNetworkedEntity("jumper",self)
		self:SetNWBool("JumperInflight",true);
        self.PlayerColor = ply:GetColor() or Color(255,255,255,255);
		ply:SetRenderMode(RENDERMODE_TRANSALPHA);
		ply:SetColor(Color(255,255,255,0));
        ply:SpectateEntity(self);
		ply:SetMoveType(MOVETYPE_OBSERVER);		
		ply:SetCollisionGroup(COLLISION_GROUP_WEAPON);
		ply:SetEyeAngles(self:GetAngles());
        if(!self.Cloaked) then self:SpawnPilot(self:GetPos()+self:GetForward()*47.5+self:GetUp()*-17.5+self:GetRight()*-32.5) end;
		ply:Flashlight(false);
		
	end
	self.Entered=true
	timer.Simple( 0.75, function() if not IsValid(self) then return end
		self.AllowActivation=true
		self.LiftOff=false
	end)
end