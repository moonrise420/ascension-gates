--[[
	Stargate Vehicle base for GarrysMod10
	Copyright (C) 2010-2011  RononDex

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

	Dear to whoever is reading this,
		I(RononDex) have had a lot of experience coding vehicles, and finally
		decided that I should make a base. All you need to do is to derive from
		this base and set the vars needed in the Initialize of your entity. Please
		check my other vehicles for the vars that are needed. Please give credit to me,
		if this base is used and finally do NOT reupload this anywhere.
		Regards,
	Ronon Dex
]]--

if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end

ENT.PrintName = "Stargate Vehicle Base"
ENT.Author = "RononDex"
ENT.Base = "base_anim"
ENT.Type = "vehicle"
ENT.HoverAlways = true -- AGP: a ship nobody flies hovers where it was left (it fell like a stone); a ship sets false to fall
ENT.Category = "Ascension Gates: Ships"

ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.IsSGVehicle = true;

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("ship")) then return end
AddCSLuaFile();

ENT.NextExit = CurTime();
ENT.num = 0;
ENT.num2 = 0;
ENT.num3 = 0;
ENT.Roll = 0;
ENT.Accel = {
	FWD = 0;
	RIGHT = 0;
	UP = 0;
};
ENT.CanUse = true;

ENT.WeaponsTable={}; --Make the table for weapons out here, this when a player enters stores there weapons which we give back when they exit

function ENT:Initialize()

	self:SetModel(self.Model);
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);
	self:SetUseType(SIMPLE_USE);
	self:StartMotionController();
	self.HoverPos = self:GetPos();
	self.NextLand = CurTime();

end

-- AGP: Wire input "Hyperspace" [VECTOR] = the hyperdrive's jump target (0 0 0 clears it); ships with their own
-- TriggerInput call AGP.ShipHyperdriveInput themselves
function ENT:TriggerInput(k, v)
	if (AGP and AGP.ShipHyperdriveInput) then AGP.ShipHyperdriveInput(self, k, v) end
end

function ENT:Bang(p) --######## The effect, and killing the player if they're flying @RononDex

	if (self.Done) then return end
	self.Done = true;   -- (first: the ship's own blast below must not come back to its hull)
	local pos, r = self:WorldSpaceCenter(), math.max(80, self:BoundingRadius());
	local pilot = self.Pilot;
	self:EmitSound(Sound("jumper/JumperExplosion.mp3"),100,100); --Play the jumper's explosion sound(Only good explosion sound i have)
	if (AGP and AGP.ShipExplosion) then AGP.ShipExplosion(self) else -- AGP: big explosion scaled to the ship (agp_ship_shield.lua)
	local fx = EffectData();
		fx:SetOrigin(self:GetPos());
	util.Effect("dirtyxplo",fx);
	end

	if(self.Inflight) then
		self:Exit(true); --Let the player out...
	end
	-- AGP: the blast hurts. People and things near the hull (StarGate.BlastDamage), and every ship around takes it on
	-- its shield and, past that, its hull (AGP.ShipBlast): 1.2 times this ship's own hull at the blast, falling off
	-- over three hull radii (a ship of the same class right alongside: shield gone and its hull hurt; without a shield it
	-- goes up too).
	local hull = self:GetNWInt("maxEntHealth", 0);
	if (hull <= 0) then hull = self.MaxHealth or self.EntHealth or 5000 end
	local who = IsValid(pilot) and pilot or self;
	util.BlastDamage(self, who, pos, math.Clamp(r * 1.5, 300, 2500), 400);
	if (AGP and AGP.ShipBlast) then AGP.ShipBlast(pos, math.max(900, r * 3), hull * 1.2, self, who, self) end
	self:Remove(); --Get rid of the vehicle

end

function ENT:OnRemove(p)

	if(self.Inflight and not self.Done) then
		self:Exit(); -- Let the player out
	end
end

-- AGP: E on the shield bubble calls the ship's ToggleShield (ship_shield:Use); ships with the shared shield
-- (ENT.AGPShield, lua/autorun/agp_ship_shield.lua) that had none threw an error there
function ENT:ToggleShield()
	if (self.AGPShield and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self) end
end

-- AGP: the repair tool (sg_repair_tool) calls HealthRepair on anything with EntHealth/MaxHealth; ships without
-- their own (Aurora, Destiny ...) threw an error every tick and were never repaired
function ENT:HealthRepair(health)
	if (not (self.EntHealth and self.MaxHealth)) then return end
	-- one step of the tool (+1) = 0.1 % of the hull, like the Ha'tak's (+1 a tick took minutes on a 30000 hull)
	local step = math.max(health - self.EntHealth, 0) * math.max(1, self.MaxHealth * 0.001)
	self.EntHealth = math.Clamp(self.EntHealth + step, 0, self.MaxHealth)
	if (self.AGPSetWire) then self:AGPSetWire("Health", math.floor(self.EntHealth)) end
end

-- AGP: shared hull damage for the ships: shield first, then the hull, small beam hits add up, destroyed at 0. See
-- AGP.ShipHullDamage in lua/autorun/agp_ship_shield.lua. The ships' OnTakeDamage call this.
function ENT:AGPHullDamage(dmg, scale)
	if (AGP and AGP.ShipHullDamage) then return AGP.ShipHullDamage(self, dmg, scale) end
	return 0
end

--####### Standard stargate vehicle stuff @RononDex
function ENT:Think()
	-- AGP: states the new HUD shows (lua/autorun/client/agp_ship_hud.lua): landing mode, cloak, and the hull for crafts
	-- that keep it only in EntHealth (Dart, Gate Glider)
	local land, cl = self.LandingMode == true, self.Cloaked
	cl = cl == true or (isentity(cl) and IsValid(cl))
	if (self:GetNWBool("AGPLanding") ~= land) then self:SetNWBool("AGPLanding", land) end
	if (self:GetNWBool("AGPCloaked") ~= cl) then self:SetNWBool("AGPCloaked", cl) end
	if (self.AGPHudEntHealth and self.EntHealth) then
		local hp = math.max(0, math.ceil(self.EntHealth))
		if (self:GetNWInt("health", -1) ~= hp) then self:SetNWInt("health", hp) end
		if (self:GetNWInt("maxEntHealth", 0) ~= (self.MaxHealth or 0)) then self:SetNWInt("maxEntHealth", self.MaxHealth or hp) end
	end

	-- AGP: the self-destruct countdown runs on, also after the pilot got out
	if (self.AGPDestructAt) then
		local left = self.AGPDestructAt - CurTime()
		if (left <= 0) then self:Bang(); return end
		if (math.ceil(left) ~= self.AGPDestructBeep) then self.AGPDestructBeep = math.ceil(left); self:EmitSound("buttons/blip1.wav", 90, 100 + math.Clamp(5 - self.AGPDestructBeep, 0, 5) * 10) end
	end

	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
            self.Pilot:SetPos(self:GetPos());
			-- AGP: self-destruct: one press = countdown 5 s, a second press (during it) = at once
			if (AGP and AGP.KeyPress and AGP.KeyPress(self, self.Pilot, self.Vehicle, "BOOM")) then
				if (self.AGPDestructAt) then self:Bang(); return end
				local cv = GetConVar("agp_ship_destruct_time")   -- (admin setting, Stargate > Config > AGP Ships; 5 s by default)
				self.AGPDestructAt = CurTime() + (cv and math.Clamp(cv:GetFloat(), 1, 600) or 5)
				self:SetNWFloat("AGPDestructAt", self.AGPDestructAt)
				self:EmitSound("ambient/alarms/klaxon1.wav", 100, 100)
			end

			-- AGP: the E press that got the pilot in does not get them out again. The ship's keys switch on while E is
			-- often still held, which sent an EXIT press; a second later (after the 1 s lock) it counted and the pilot was
			-- thrown out without pressing anything (Prometheus, Replicator ship). During the lock every EXIT press is
			-- read and dropped, so only a new press afterwards counts.
			local out = AGP.KeyPress(self, self.Pilot, self.Vehicle, "EXIT") -- AGP: a quick tap counts too
			if(self.NextExit<CurTime() and out) then
				self.NextExit = CurTime()+1;
				self:Exit();
			end
		end
	end

	if(self.RunningAnim) then
		self:NextThink(CurTime());
		return true;
	end
end

function ENT:Enter(p) --####### Get in @RononDex

	if(not(self.Inflight) and self.CanUse) then
		p:SetNetworkedEntity(self.Vehicle,self); --Set a networked entity as the name of the vehicle
		p:SetNWBool("Flying"..self.Vehicle,true); --Set a bool on the player
		p:Spectate(OBS_MODE_CHASE); --Spectate the vehicle
		p:DrawWorldModel(false);
		p:DrawViewModel(false);
		p:SetMoveType(MOVETYPE_OBSERVER);
		p:SetCollisionGroup(COLLISION_GROUP_WEAPON);
		self.WeaponsTable = {}; -- AGP: this ship's own list (the class-wide one mixed up two pilots' weapons)
		for _,v in pairs(p:GetWeapons()) do
			table.insert(self.WeaponsTable, v:GetClass());
		end
		p:StripWeapons();
		self.PlayerHealth=p:Health();
		if(p:FlashlightIsOn()) then
			p:Flashlight(false); --Turn the player's flashlight off when Flying
		end
		p:SetNetworkedEntity("ScriptedVehicle", self)
		p:SetViewEntity(self)
		self:GetPhysicsObject():Wake();
		self:GetPhysicsObject():EnableMotion(true); --UnFreeze us
		self:StartMotionController()
		if(self.ShouldRotorwash) then
			self:Rotorwash(true);
		end
		self.Inflight = true;
		self.AGPFlown = true;
		self.Pilot = p;
        self.Pilot:SetRenderMode(RENDERMODE_TRANSALPHA);
        self.Pilot:SetColor(Color(255,255,255,0));
		self.NextExit = CurTime()+1;
	end
end

function ENT:Exit(kill) --####### Get out @RononDex

	if (IsValid(self.Pilot)) then
		StarGate.KeyBoard.ResetKeys(self.Pilot,self.Vehicle);
		self.Pilot:UnSpectate();
		self.Pilot:DrawViewModel(true);
		self.Pilot:DrawWorldModel(true);
		if (AGP and AGP.ShipRespawnPilot) then AGP.ShipRespawnPilot(self.Pilot) else self.Pilot:Spawn() end -- AGP: keeps armour and ammo, no Ha'tak bunk move (agp_ship_shield.lua)
		self.Pilot:SetNWBool("Flying"..self.Vehicle,false);
		self.Pilot:SetPos(AGP and AGP.ShipExitSpot and AGP.ShipExitSpot(self, self.Pilot, self.ExitPos, self.AGPCabinExit) or self.ExitPos or self:GetPos()); -- AGP: a free spot
		self.Pilot:SetParent();
		self.Pilot:SetMoveType(MOVETYPE_WALK);
		self.Pilot:SetCollisionGroup(COLLISION_GROUP_PLAYER);
	end
	if(self.ShouldRotorwash) then
		self:Rotorwash(false);
	end
	self.Inflight = false;
	self:SetNetworkedEntity(self.Vehicle,nil);
	if (IsValid(self.Pilot)) then
		self.Pilot:SetNetworkedEntity( "ScriptedVehicle", NULL )
		self.Pilot:SetViewEntity( NULL )
		self.Pilot:SetHealth(self.PlayerHealth);
        self.Pilot:SetColor(Color(255,255,255,255));
		for _,v in pairs(self.WeaponsTable) do
			self.Pilot:Give(tostring(v));
		end
		if (kill) then self.Pilot:Kill(); end
	end
	self.Pilot = NULL;
	self.Accel.FWD = 0;
	self.Accel.RIGHT = 0;
	self.Accel.UP = 0;
	table.Empty(self.WeaponsTable); --Get rid of our old weapons
	self.HoverPos = self:GetPos();
end


function ENT:Use(p) --####### When you press E on it @RononDex

	if(not(self.CanUse)) then return end;

	if(not(self.Inflight)) then
		self:Enter(p); --Get in
	end
end

local FlightPhys={ -- Make the table of constants out here, to stop creating garbage.
	secondstoarrive	= 1;
	maxangular		= 9000;
	maxangulardamp	= 1000;
	maxspeed			= 1000000;
	maxspeeddamp		= 500000;
	dampfactor		= 1;
	teleportdistance	= 5000;
};
local ZAxis = Vector(0,0,1);
function ENT:PhysicsSimulate( phys, deltatime )--############## Flight code@ RononDex
	local FWD = self.Entity:GetForward();
	local UP = ZAxis;
	local RIGHT = FWD:Cross(UP):GetNormalized();

	if(self.Inflight and IsValid(self.Pilot)) then
		-- Accelerate
		if not self.AirBrake and not self.Boost then
			if((self.Pilot:KeyDown(self.Vehicle,"FWD"))and(self.Pilot:KeyDown(self.Vehicle,"SPD"))) then
				self.num = self.MaxSpeed;
			elseif((self.Pilot:KeyDown(self.Vehicle,"FWD"))) then
				self.num = self.ForwardSpeed;
			elseif(self.Pilot:KeyDown(self.Vehicle,"BACK")) then
				self.num = self.BackwardSpeed;
			else
				self.num = 0;
			end
		end
		self.Accel.FWD = math.Approach(self.Accel.FWD,self.num,self.Accel.SpeedForward);

		-- Strafe
		if(self.GoesRight) then
			if(self.Pilot:KeyDown(self.Vehicle,"RIGHT")) then
				self.num2 = self.RightSpeed;
			elseif(self.Pilot:KeyDown(self.Vehicle,"LEFT")) then
				self.num2 = -self.RightSpeed;
			else
				self.num2 = 0;
			end
		end
		self.Accel.RIGHT = math.Approach(self.Accel.RIGHT,self.num2,self.Accel.SpeedRight);

		-- Up and Down
		if(self.GoesUp) then
			if(self.Pilot:KeyDown(self.Vehicle,"UP")) then
				self.num3 = self.UpSpeed;
			elseif(self.Pilot:KeyDown(self.Vehicle,"DOWN")) then
				self.num3 = -self.UpSpeed;
			else
				self.num3 = 0;
			end
		end
		self.Accel.UP = math.Approach(self.Accel.UP,self.num3,self.Accel.SpeedUp);

		if(self.CanRoll and not self.LandingMode) then
			if(self.Pilot:KeyDown(self.Vehicle,"RL")) then
				self.Roll = self.Roll - 5;
			elseif(self.Pilot:KeyDown(self.Vehicle,"RR")) then
				self.Roll = self.Roll + 5;
			elseif(self.Pilot:KeyDown(self.Vehicle,"RROLL")) then
				self.Roll = 0;
			end
		end

		phys:Wake();
		if(not(self.Hover)) then
			if self.Accel.FWD>-200 and self.Accel.FWD < 200 then return end; --with these you float and won't move
			if(self.GoesUp) then
				if self.Accel.UP>-200 and self.Accel.UP < 200 then return end;
			end
			if(self.GoesRight) then
				if self.Accel.RIGHT>-200 and self.Accel.RIGHT < 200 then return end;
			end
		end

		local pos = self:GetPos();

		--######### Do a tilt when turning, due to aerodynamic effects @aVoN
		local velocity = self:GetVelocity();
		local aim = AGP.SteerAim(self, self.Pilot); -- AGP: ALT = free look (lua/autorun/agp_keypress.lua)
		local ang = aim:Angle();
		local ExtraRoll = math.Clamp(math.deg(math.asin(self:WorldToLocal(pos + aim).y)),-25,25); -- Extra-roll - When you move into curves, make the shuttle do little curves too according to aerodynamic effects
		local mul = math.Clamp((velocity:Length()/1700),0,1); -- More roll, if faster.
		local oldRoll = ang.Roll;
		ang.Roll = (ang.Roll + self.Roll - ExtraRoll*mul) % 360;
		if (ang.Roll!=ang.Roll) then ang.Roll = oldRoll; end -- fix for nan values what cause despawing/crash.

		if(AGP.KeyPress(self, self.Pilot, self.Vehicle, "LAND")) then
			if(self.NextLand < CurTime()) then
				if(not self.LandingMode) then
					self.LandingMode = true;
				else
					self.LandingMode = false;
				end
				self.NextLand = CurTime()+1;
			end
		end

		if(self.LandingMode or self.ForceLevel) then -- AGP: ForceLevel = a ship flying through a narrow opening stays level
			FlightPhys.angle = Angle(0,self:GetAngles().Yaw,self.ForceLevel and 0 or self.Roll);
		end
		
		--##### Calculate our new angles and position based on speed
		if(not(self.LandingMode)) then
			FlightPhys.angle = ang; --+ Vector(90 0, 0)
			if (self.ForceLevel) then FlightPhys.angle = Angle(0, ang.y, 0) end -- AGP: level but still turning (was overwritten)
		end
		FlightPhys.deltatime = deltatime;
		FlightPhys.pos = self:GetPos()+(FWD*self.Accel.FWD)+(UP*self.Accel.UP)+(RIGHT*self.Accel.RIGHT);

		
		phys:ComputeShadowControl(FlightPhys);
	end
	if (not self.Inflight and self.HoverAlways and self.AGPFlown) then -- AGP: a new ship stays on the ground until someone has flown it
		-- AGP: carried with the physgun: hover where it is put down, not fight back to the old spot (it spun and lagged)
		if (self:IsPlayerHolding() or not self.HoverPos) then self.HoverPos = self:GetPos(); return end
		phys:Wake();
		FlightPhys.angle = Angle(0, self:GetAngles().y, 0);
		FlightPhys.deltatime = deltatime;
		FlightPhys.pos = self.HoverPos;
		phys:ComputeShadowControl(FlightPhys);
	end
end


--############## Collison Dammage @ WeltEntSturm
function ENT:PhysicsCollide(cdat, phys)

	-- AGP: shots (energy pulses, drones, missiles: anything with its own .Damage) bring their own damage; at their
	-- speed this crash rule added 1500-2800 per hit on top (the balance test: a 250 bolt did 2800)
	local hit = cdat.HitEntity
	if (IsValid(hit) and type(hit.Damage) == "number") then return end
	if cdat.DeltaTime > 0.5 then --0.5 seconds delay between taking physics damage
		local mass = (cdat.HitEntity:GetClass() == "worldspawn") and 1000 or cdat.HitObject:GetMass(); --if it's worldspawn use 1000 (worldspawns physobj only has mass 1), else normal mass
		-- AGP: the damage after the physics callback (a destroyed ship removes itself and moves its pilot: crash inside it)
		local d = (cdat.Speed*cdat.Speed*math.Clamp(mass, 0, 1000))/9000000;
		timer.Simple(0, function() if (IsValid(self)) then self:TakeDamage(d) end end);
		if((self.Accel.FWD or self.Accel.RIGHT or self.Accel.UP)>500) then
			self.Accel.FWD = math.Approach(self.Accel.FWD,0,30);
		end
	end
end


 --################# After teleporting it, fix the angles of a player @aVoN
function ENT.FixAngles(self,pos,ang,vel,old_pos,old_ang,old_vel,ang_delta)
	-- Move a players view
	local diff = Angle(0,ang_delta.y+180,0);
	if(IsValid(self.Pilot)) then
		self.Pilot:SetEyeAngles(self.Pilot:GetAimVector():Angle() + diff);
	end
end

-- damn, this not work with mask...
for k,v in pairs({"sg_vehicle_dart","sg_vehicle_alkesh","sg_vehicle_gate_glider","sg_vehicle_glider","sg_vehicle_shuttle","sg_vehicle_f302","sg_vehicle_teltac"}) do
	StarGate.Teleport:Add(v,ENT.FixAngles);
end

--########## Run the anim that's set in the arguements @RononDex
function ENT:Anims(e,anim,playback_rate,delay,nosound,sound)

	if(e.CanDoAnim) then
		self:NextThink(CurTime());
		e.CanDoAnim = false;
		e.RunningAnim = true;
		e.Anim = e:LookupSequence(anim); -- The anim, set anim as the name of the anim in a string in the arguements
		if(not(nosound)) then --Set false to allow sound
			e:EmitSound(Sound(sound),100,100); --create sound as a string in the arguements
		end
		e:SetPlaybackRate(playback_rate);
		e:SetSequence(e.Anim); -- play the sequence
		timer.Simple(delay,function() --How long until we can do the anim again?
			e.CanDoAnim = true;
			e.RunningAnim = false;
		end);
	end
end

function ENT:Rotorwash(b) --########## Toggle the rotorwash @RononDex

	if(b) then
		local e = ents.Create("env_rotorwash_emitter");
		e:SetPos(self:GetPos());
		e:SetParent(self);
		e:Spawn();
		e:Activate();
		self.RotorWash = e;
	else
		if(IsValid(self.RotorWash)) then
			self.RotorWash:Remove();
		end
	end
end

function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
	if (StarGate.NotSpawnable(Ent:GetClass(),ply)) then self.Entity:Remove(); return end
	if (IsValid(ply)) then
		local PropLimit = GetConVar("CAP_ships_max"):GetInt()
		if(ply:GetCount("CAP_ships")+1 > PropLimit) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )");
			Ent:Remove();
			return
		end
		ply:AddCount("CAP_ships", Ent);
		Ent.Owner = ply;
	end
	StarGate.WireRD.PostEntityPaste(self,ply,Ent,CreatedEntities)
end

function playerDies( victim, weapon, killer )
	if (IsValid(victim:GetNetworkedEntity("ScriptedVehicle", NULL))) then
          local veh = victim:GetNetworkedEntity("ScriptedVehicle", NULL);
          if (veh:GetClass()!="puddle_jumper" and veh:GetClass()!="sg_vehicle_daedalus" and veh.Bang) then
			veh:Bang();
          end
     end
end
hook.Add( "PlayerDeath", "SG.VEH.playerDies", playerDies )
hook.Add( "PlayerSilentDeath", "SG.VEH.playerDies", playerDies )

-- AGP: a pilot who dies in the Daedalus or leaves the game lets go of the ship (it stayed "occupied" and nobody
-- could get in again; the Daedalus kept pulling the respawned player into its hull)
local function agpLetGo(p)
	local veh = p:GetNetworkedEntity("ScriptedVehicle", NULL)
	if (not IsValid(veh)) then return end
	if (veh:GetClass() == "sg_vehicle_daedalus" and veh.Driver == p and veh.Exit) then veh:Exit()
	elseif (veh.Pilot == p and veh.Inflight and veh.ExitJumper) then veh:ExitJumper()
	elseif (veh.Pilot == p and veh.Inflight and veh.Exit) then veh:Exit() end
end
hook.Add( "PlayerDisconnected", "AGP.VEH.LetGo", agpLetGo )
hook.Add( "PlayerDeath", "AGP.VEH.LetGo", function(p) local veh = p:GetNetworkedEntity("ScriptedVehicle", NULL); if (IsValid(veh) and veh:GetClass() == "sg_vehicle_daedalus") then agpLetGo(p) end end )

end

if CLIENT then

function ENT:Initialize( )
	self.FXEmitter = ParticleEmitter( self:GetPos())
	self.SoundsOn = {}
	if (self.Sounds and self.Sounds.Engine) then
		self.EngineSound = self.EngineSound or CreateSound(self.Entity,self.Sounds.Engine);
	end
end

-- AGP: the engines glow while a ship flies forward, brighter the faster it goes (it fades in and out smoothly)
-- - seen by everyone (our ships first drew it only for their pilot, while W was held). Drawn with soft additive
-- glow sprites from the ship's DrawTranslucent (RENDERGROUP_BOTH):
--  * a round engine (nozzle): a bright core and a soft plume tapering back from it
--  * a line of engines (a drive strip across the stern): a soft glow along it, a little blurred (no single puffs
--    on a strip, no trails)
local ENGINE_GLOW = Material("sprites/light_glow02_add")
function ENT:AGPEngineLevel()
	local speed = self:GetVelocity():Dot(self:GetForward())
	local target = speed > 60 and math.Clamp(speed / 1500, 0.3, 1) or 0
	self.AGPGlowK = Lerp(math.min(1, FrameTime() * 4), self.AGPGlowK or 0, target)
	return self.AGPGlowK
end
-- nozzles: { { model-space centre, radius }, ... }; col: { r, g, b }; len: the plume's length at full speed
function ENT:AGPEngineNozzles(nozzles, col, len)
	local k = self:AGPEngineLevel()
	if (k < 0.02) then return end
	render.SetMaterial(ENGINE_GLOW)
	local back = -self:GetForward()
	for _, n in ipairs(nozzles) do
		local p, r = self:LocalToWorld(n[1]), n[2]
		render.DrawSprite(p - back * 2, r * 3.4, r * 3.4, Color(col[1], col[2], col[3], 255 * k))
		for i = 1, 7 do
			local t = i / 7
			local sz = r * 2.8 * (1 - 0.7 * t)
			render.DrawSprite(p + back * len * k * t, sz, sz, Color(col[1], col[2], col[3], 190 * k * (1 - t) ^ 1.4))
		end
	end
end
-- line: model-space points along the strip, in order; width: the strip's height. Only a soft glow on the strip, a
-- little blurred round it (no rows of trails - "it is enough when it glows and is a little blurred")
function ENT:AGPEngineLine(line, col, width)
	local k = self:AGPEngineLevel()
	if (k < 0.02) then return end
	render.SetMaterial(ENGINE_GLOW)
	local back = -self:GetForward()
	local step = width * 0.8
	for i = 1, #line - 1 do
		local a, b = self:LocalToWorld(line[i]), self:LocalToWorld(line[i + 1])
		local n = math.max(1, math.ceil(a:Distance(b) / step))
		for j = 0, n - (i == #line - 1 and 0 or 1) do
			local p = LerpVector(j / n, a, b) - back * 2
			render.DrawSprite(p, width * 2.2, width * 2.2, Color(col[1], col[2], col[3], 110 * k))
			render.DrawSprite(p + back * width * 0.9, width * 3.2, width * 3.2, Color(col[1], col[2], col[3], 35 * k))
		end
	end
end

function SGVehBaseCalcView(Player, Origin, Angles, FieldOfView)
	local view = {}
	local p = Player
	local self = p:GetNetworkedEntity("ScriptedVehicle", NULL)
	-- (agp_portal: a craft that just went through a doorway turns its pilot's aim; that frame's aim comes from there)
	local turned = IsValid(self) and AGP_PortalTurnAim and AGP_PortalTurnAim()
	local aimVec = turned and turned:Forward() or LocalPlayer():GetAimVector()

	if((self)and(self:IsValid()) and self.IsSGVehicle and not self.IsSGVehicleCustomView and self.FirstPerson) then
		-- AGP: the view key (1) switched FirstPerson on the big ships, but no camera used it ("change view does nothing").
		-- Bridge view: from the front top of the hull, looking where the pilot aims; the ship stays visible.
		local mn, mx = self:OBBMins(), self:OBBMaxs()
		view.origin = self:LocalToWorld(Vector(mx.x * 0.7, 0, mx.z * 0.85 + 20))
		view.angles = aimVec:Angle()
		if (AGP_PortalCamera) then view.origin, view.angles = AGP_PortalCamera(self:WorldSpaceCenter(), view.origin, view.angles) end   -- (through a doorway: agp_portal)
		return view
	end
	if((self)and(self:IsValid()) and self.IsSGVehicle and not self.IsSGVehicleCustomView) then
		-- AGP: the camera stays far enough behind for the ship's size (big ships had it inside the hull at -750); the arrow
		-- keys still move it further out / up from there
		local r = self:BoundingRadius()
		local back = math.min(self.Dist or -750, (self.Dist or -750) + 750 - r * (self.AGPCamBack or 1.6))
		local up = math.max(self.UDist or 120, (self.UDist or 120) - 120 + r * (self.AGPCamUp or 0.25))
		local pos = self:GetPos()+self:GetUp()*up+aimVec:GetNormal()*back
		-- AGP: the camera looks where the mouse aims (the ship turns there). It used to look at the spot the nose
		-- points to, so moving the mouse swung the camera around the ship while the view stayed put (felt wrong).
		-- Where the guns hit right now is shown by a small marker (HUDPaint below).
		local face = aimVec:Angle()
			view.origin = pos
			view.angles = face
		if (AGP_PortalCamera) then view.origin, view.angles = AGP_PortalCamera(self:WorldSpaceCenter(), view.origin, view.angles) end   -- (through a doorway: agp_portal)
		return view
	end
end
hook.Add("CalcView", "SGVehBaseCalcView", SGVehBaseCalcView)

-- AGP: gun marker: a small ring where the ship's nose (its guns) points, so you see where shots go while you steer
hook.Add("HUDPaint", "AGP.ShipGunMarker", function()
	local p = LocalPlayer()
	local ship = p:GetNetworkedEntity("ScriptedVehicle", NULL)
	if (not IsValid(ship) or not ship.IsSGVehicle or ship.IsSGVehicleCustomView) then return end
	-- AGP: a ship whose HUD draws the crosshair (where every gun goes, lua/autorun/agp_ship_aim.lua) does not get this
	-- nose ring as well: two marks that disagreed ("crosshair and shooting do not fit together")
	local spec = AGP and AGP.HUD and AGP.HUD.SpecOf and AGP.HUD.SpecOf(ship)
	if (spec and spec.marker) then return end
	local tr = util.TraceLine({ start = ship:GetPos(), endpos = ship:GetPos() + ship:GetForward() * 20000,
		filter = function(e) return e ~= p and not (AGP and AGP.ShipPart and AGP.ShipPart(ship, e) or e == ship) end })
	-- AGP: glides smoothly (the ship's angles come in steps over the network, the ring jumped from pixel to pixel)
	local x, y
	if (AGP and AGP.HUD and AGP.HUD.SmoothMarker) then x, y = AGP.HUD.SmoothMarker(tr.HitPos) else local sc = tr.HitPos:ToScreen() if (sc.visible) then x, y = sc.x, sc.y end end
	if (not x) then return end
	surface.DrawCircle(x, y, 9, 255, 200, 90, 200)
	surface.DrawCircle(x, y, 2, 255, 200, 90, 200)
end)

function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	if (self.EngineSound) then
		self.EngineSound:Stop();
	end
end

function ENT:Think()

	local p = LocalPlayer()
	local IsDriver = (p:GetNetworkedEntity(self.Vehicle,NULL) == self.Entity);
	local IsFlying = p:GetNWBool("Flying"..self.Vehicle,false);

	--######### Handle engine sound
	if(IsFlying and IsDriver) then
		-- Normal behaviour for Pilot or people who stand outside
		self:StartClientsideSound("Engine");
		--#########  Now add Pitch etc
		local velo = self.Entity:GetVelocity();
		local pitch = self.Entity:GetVelocity():Length();
		local doppler = 0;
		-- For the Doppler-Effect!
		if(not IsDriver) then
			-- Does the vehicle fly to the player or away from him?
			local dir = (p:GetPos() - self.Entity:GetPos());
			doppler = velo:Dot(dir)/(150*dir:Length());
		end
		if(self.SoundsOn.Engine) then
			self.EngineSound:ChangePitch(math.Clamp(60 + pitch/25,75,100) + doppler,0);
		end
	else
		self:StopClientsideSound("Engine");
	end
end

--################# Starts a sound clientside @aVoN
function ENT:StartClientsideSound(mode)
	if(not self.SoundsOn[mode]) then
		if(mode == "Engine" and self.EngineSound) then
			self.EngineSound:Stop();
			self.EngineSound:SetSoundLevel(90);
			self.EngineSound:PlayEx(1,100);
		end
		self.SoundsOn[mode] = true;
	end
end

--################# Stops a sound clientside @aVoN
function ENT:StopClientsideSound(mode)
	if(self.SoundsOn[mode]) then
		if(mode == "Engine" and self.EngineSound) then
			self.EngineSound:FadeOut(2);
		end
		self.SoundsOn[mode] = nil;
	end
end

end