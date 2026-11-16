/*
	Stargate Eventhorizon for GarrysMod10
	Copyright (C) 2007-2009  aVoN

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
*/

--################# HEADER #################
if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("base")) then return end
ENT.CDSIgnore = true; -- CDS Immunity
function ENT:gcbt_breakactions() end; ENT.hasdamagecase = true; -- GCombat invulnarability!

--################# Include
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
AddCSLuaFile("modules/bullets.lua");
AddCSLuaFile("modules/collision.lua");
AddCSLuaFile("modules/agp_ride.lua");
include("shared.lua");
include("modules/teleport.lua");
include("modules/bullets.lua");
include("modules/collision.lua");
include("modules/agp_ride.lua"); -- AGP: the wormhole ride

local BUFFER = {InBuffer = {}};

--################# Defines
ENT.IgnoreTouch = true; -- This tells the physical objects like drones or staff not to collide with the eventhorizon (= no explode on them)
ENT.CDSIgnore = true; -- Fixes Combat Damage System destroying this entity
ENT.DrawEnterEffectTime = 0;
ENT.CAP_NotSave = true;
ENT.DoNotDuplicate = true 

ENT.DefModel = "models/zup/stargate/stargate_horizon.mdl"
ENT.Sounds = {
	Idle=Sound("stargate/wormhole_loop.wav"),
	Teleport={Sound("stargate/teleport.mp3"),Sound("stargate/teleport_2.mp3"),Sound("stargate/teleport_3.mp3"),Sound("stargate/teleport_4.mp3"),Sound("stargate/teleport_5.mp3"),Sound("stargate/teleport_6.mp3"),Sound("stargate/teleport_7.mp3"),Sound("stargate/teleport_8.mp3")},
	Close=Sound("stargate/gate_close.mp3"),
	Open=Sound("stargate/gate_open.mp3"),  -- You can manually change this later when you spawn the event horizon in the SpawnFunction!
	OpenNox=Sound("stargate/hand_gateopen_device.wav"),
}

ENT.NoTouchTeleport = {
	"kino_ball",
	"npc_grenade_frag",
	"rpg_missile",
	"grenade_ar2",
	"crossbow_bolt",
	"prop_combine_ball",
	"energy_pulse",
	"energy_pulse_stun",
	"drone",
	"npc_satchel",
	"hunter_flechette",
	"grenade_helicopter",
	"weapon_striderbuster",
	"grenade_spit",
	"prop_ragdoll",
	"horizon_missile",
}

-- These entities are immune against autoclose and should also never avoid an autoclose event if to near to a gate
ENT.AutocloseImmunity = {
	"npc_grenade_frag",
	"rpg_missile",
	"grenade_ar2",
	"crossbow_bolt",
	"npc_satchel",
	"prop_combine_ball",
	"hunter_flechette",
	"grenade_helicopter",
	"weapon_striderbuster",
	"grenade_spit", -- Antlion poison blasts
	"cloaking",
	"shield",
	"stargate_iris",
	"goauld_iris",
	"gmod_ghost", -- AdvDupe/Dupe ghostpreview - For some obvious reason, it's having a physics object...
	"prop_dynamic",
	"kino_ball",
}

-- AGP 2026-11-08: Half-Life 2's shots and thrown things. They go through at once with their speed turned to the far gate,
-- as in CAP (CAP Enhanced's wormhole ride froze them 3.2 s and sent them on in their old direction at double speed: a
-- thrown grenade dropped at the far horizon or flew back into it).
ENT.AGPShots = {
	npc_grenade_frag = true, grenade_ar2 = true, rpg_missile = true, crossbow_bolt = true, prop_combine_ball = true,
	npc_satchel = true, hunter_flechette = true, grenade_helicopter = true, weapon_striderbuster = true, grenade_spit = true,
}

-- AGP 2026-11-08: seconds the gate stays open after the last traveller went in or came out; each new traveller starts the
-- wait again, so a group (players, Replicators) can follow. CAP: 3-4 s after going in; CAP Enhanced: 6 s after the 3.2 s
-- wormhole ride (over 9 s in all).
ENT.AGPAutoCloseDelay = 4

BUFFER.ClipIgnore = {
	"event_horizon",
	"dakara_building",
	"anim_ramps",
	"ramp",
	"ramp_2",
	"goauld_iris",
	"ramp",
	"kino_ball",
	"models/madman07/stargate/ring_sg1.mdl",
	"energy_pulse",
	"energy_pulse_stun",
	"rpg_missile",
	"grenade_ar2",
	"npc_grenade_frag",
	"prop_combine_ball",
	"grenade_helicopter",
	"prop_ragdoll",
	"black_hole_power",
	"shield_core_buble",
}

--################# SENT CODE ###############

--################# Init @aVoN
function ENT:Initialize()
	self.Instancing = false
	-- We need a "fresh" copy of sounds for this entity. Otherwise "SGA-opening-sounds" might overwrite "SG1-opening-sounds", because ENT.Sounds is global!
	self.Sounds = table.Copy(self.Sounds);
	local parent = self.Entity:GetParent();

	if(IsValid(parent)) then	
		if(parent.Sounds and parent.Sounds.Open) then
			self.Sounds.Open = parent.Sounds.Open;
		end
		if(parent.Sounds and parent.Sounds.OpenNox) then
			self.Sounds.OpenNox = parent.Sounds.OpenNox;
		end
		if(parent.Sounds and parent.Sounds.Close) then
			self.Sounds.Close = parent.Sounds.Close;
		end
		if (parent.GateSpawnerSpawned) then
			self.GateSpawnerSpawned = true;
		end		
		if (parent.EHColor) then
			self.EHColor = parent.EHColor
		end
	end

	self.Material = ""
	self.UnstableMaterial = ""
	self.Model = self.DefModel
	self.Entity:EHType()
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_NONE);
	self.Entity:SetTrigger(true); -- The most important thing: Makes the EH trigger Touch() events, even when it's not solid
	self.Entity:SetNotSolid(true);
	self.Entity:DrawShadow(false);
	self.Entity:SetRenderMode(RENDERMODE_TRANSALPHA);
	-- Do not draw the model now (Alpha must be 1 because for some mystical reason, setting this to 0 makes effects not draw on it. Seems like Valva/garry added stuff not to draw things which actually have alpha = 0 to save performance) -- STILL? I've seen, it works with 0 now too
	local col = table.Copy(self.EHColor or self.DefColor)
	self:SetEHColor(col);
	col = table.Copy(col)
	col.a = 0
	self:SetColor(col)
	self.Created = CurTime();
	self.AutoClose = StarGate.CFG:Get("stargate","autoclose",true);
	self.WaterNoClose = StarGate.CFG:Get("stargate","water_noclose",true);
	self.HorizonRadius = self.Entity:BoundingRadius(); -- Just needed for effects
	self.OpeningDelay = 1.5; -- This time decides when the script starts it's opening effect after it played the opening sound
	self.OpenTime = 2.2;
	self.Holding = {}; -- A player holds this Entity: We are not going to teleport it until he stopped holding it!
	self.DoNotDestroy = {}; -- A contraption just got teleported to this event horizon but hasn't exited it yet. This prevents the receiving EH from destroying this contraption!
	self.OpenEffect = true; -- Need to place up here so we have the variable ready
	self:Open(); -- Let us open :D
	self.timer_table = {}
	self.Ents={};
	self.CollisionGroup = {};
	self.Buffer = {};
	self.AllBuffer = {};
	self.ClipBuffer = {};
	self.GravBuffer = {};
	self.RoutingPaused = false
	self.Opened = false;
	self.ValidOpen = false;
	self.ModelClip = GetConVar("stargate_model_clipping"):GetBool();


	if self.ModelClip then
		self.PhysClip = GetConVar("stargate_physics_clipping"):GetBool();
		if (self.PhysClip) then
			hook.Add( "ShouldCollide", "ShouldEHEntitiesCollide", ShouldEHEntitiesCollide )
		else
			hook.Remove( "ShouldCollide", "ShouldEHEntitiesCollide" )
		end
	else
		self.PhysClip = false;
		hook.Remove( "ShouldCollide", "ShouldEHEntitiesCollide" )
	end

	local phys = self.Entity:GetPhysicsObject();
	if(phys:IsValid()) then
		phys:EnableCollisions(false);
	end

	if(self:GetParent() ~= nil and self:GetParent():GetClass() == "stargate_supergate") then
		util.AddNetworkString("supergate_sounds"..self:EntIndex())
	end

	if (pewpew and pewpew.NeverEverList and not table.HasValue(pewpew.NeverEverList,self.Entity:GetClass())) then table.insert(pewpew.NeverEverList,self.Entity:GetClass()); end -- pewpew support
end

function ENT:EHType(reset)
	if (reset) then
		self.Material = ""
		self.UnstableMaterial = ""
		self.Model = self.DefModel
	end
	
	local parent = self:GetParent()
	local type = parent.EventHorizonType;
	local Data = StarGate.EventHorizonTypes[type] or {}

	self.DefColor = table.Copy(Data.Color) or Color(255,255,255)
	
	if (Data.LightColor) then
		self.Entity:SetNWVector("LightColR",Data.LightColor.r);
		if (not Data.LightColor.sync) then
			self.Entity:SetNWVector("LightColG",Data.LightColor.g);
			self.Entity:SetNWVector("LightColB",Data.LightColor.b);
		end
		self.Entity:SetNWBool("LightSync",Data.LightColor.sync);
	end
	
	if (Data.Material) then self.Material = Data.Material end
	self.Entity:SetMaterial(self.Material);
	if (Data.UnstableMaterial) then self.UnstableMaterial = Data.UnstableMaterial end
	
	if (parent.EventHorizonData.Model) then self.Model = parent.EventHorizonData.Model end
	self.Entity:SetModel(self.Model);
	
	if (parent.OnEventHorizonType) then
		parent:OnEventHorizonType(self,reset,type,Data)
	end
end

function ENT:SetEHColor(col)
	self.Color = col
	self:SetColor(self.Color)
	if (self.Color.r!=self.DefColor.r or self.Color.g!=self.DefColor.g or self.Color.b!=self.DefColor.b) then
	    self.Entity:SetNWBool("LightCustom",true);
	else
	    self.Entity:SetNWBool("LightCustom",false);	
	end
end

function ENT:Flicker(reset)
	if (reset) then
		if (self.UnstableMaterial!="") then
			self:SetMaterial(self.Material);
		else
		    self:SetNWBool("Flicker",false);
		end
		self:SetColor(self.Color)
		self.Unstable = false;              
	else
		if (self.UnstableMaterial!="") then
			self:SetMaterial(self.UnstableMaterial);
		else
			local col = table.Copy(self.Color)
			col.a = math.random(55,165)
		    self:SetColor(col) -- legacy
			self:SetNWBool("Flicker",true);
		end
		if not self.ShuttingDown then
			self:EmitSound(self:GetParent().UnstableSound,90,math.random(97,103));
		end
		self.Unstable = true;
		self:BufferEmpty();
	end
end

--################# Prevent PVS bug/drop of all networkes vars (Let's hope, it works) @aVoN

--################# OnRemove @aVoN
function ENT:OnRemove()
	-- Kill wormhole idle sound
	if(self.IdleSound)then
	    self.IdleSound:Stop();
	end
	-- AGP 2026-11-08: whoever still rides the wormhole from here is let out now (this horizon goes: its gate was removed
	-- or destroyed, or it closed while routing was paused); the ride's own timer then finds the ride ended
	self:AGPAbortRides(); -- modules/agp_ride.lua
	-- Remove no-collide from our gate
	local parent = self.Entity:GetParent();
	if(IsValid(parent)) then
		parent:SetCollisionGroup(COLLISION_GROUP_NONE);
	end
	self:EndTouch()
end

--################# Set the target GATE (not Event Horizon!!!!!) we are linked to. We need to retrieve the target Horizon later manually
function ENT:SetTarget(e)
	self.TargetGate = e;
end

--################# Are we opened? @aVoN
function ENT:IsOpen()
	if(not self.Opened and self.Created + self.OpenTime + self.OpeningDelay > CurTime()) then
		return false; -- We havent opened yet;
	end
	self.Opened = true; -- Do not calculate this above. This saves performance, even when it's really less. But coding performance saving is always good
	self.ValidOpen = true; -- just to be sure
	return true;
end

-- Just for DEBUG so I can spawn it from the SENT menu
-- FIXME: Remove this function later
function ENT:SpawnFunction(p,t)
	if(not t.Hit) then return end
	local e = ents.Create("event_horizon");
	e:SetPos(t.HitPos+Vector(0,0,90));
	e:SetAngles(Angle(0,p:GetAimVector():Angle().y,0));
	e:Spawn();
	e:Activate();
	return e;
end

--################# The openeing effect @aVoN
function ENT:Open()
        self.Attached = {}; -- These entities won't be dissolveable when the EH openes (Welded/Attached props)
        local parent = self.Entity:GetParent();
        if(IsValid(parent)) then
            self.Attached[parent] = true;
            if(IsValid(parent.Target)) then
           		self.Attached[parent.Target] = true;
            end
            self.Attached[self.Entity] = true;
			for _,v in pairs(StarGate.GetConstrainedEnts(parent,10) or {}) do
				self.Attached[v] = true; -- Instead of doing a table.HasValue() everytime we do this - Much faster!
           end
        end
        local e = self.Entity;
		local gt = 0;

		local class = self:GetParent():GetClass();
		local nox_type = self:GetParent().NoxDialingType; // let it spawn without kawoosh, like nox/asgard/cassandra can do
    	if (nox_type) then
			self.OpeningDelay = 0.87;
			self.OpenTime = 0.9;
		else
			local EHData = self:GetParent().EventHorizonData
			self.OpeningDelay = EHData.OpeningDelay
			self.OpenTime = EHData.OpenTime
			gt = EHData.NNFix
		end

        --##### This effect simply is the eventhorizon creation effect. It's NOT the kawoosh!
		if self.OpenEffect then
			local fx = EffectData();
			fx:SetEntity(e);
			fx:SetRadius(gt or 0);
			fx:SetOrigin(e:GetPos());
			fx:SetScale(self.OpeningDelay+0.2); -- The additional delay stops the effect from stopping to early so the other (below) is getting started to late (Noticabel by a short flicker)
			util.Effect("eventhorizon_open",fx,true,true);
		end
		if (nox_type) then
			self.Entity:EmitSound(self.Sounds.OpenNox,90,math.random(98,102));
		else
			if(self:GetParent():GetClass() == "stargate_supergate") then
				timer.Simple(0.1,function()
					net.Start("supergate_sounds"..self:EntIndex())
					net.WriteString(self.Sounds.Open)
					net.Broadcast()
				end)
			else
				self.Entity:EmitSound(self.Sounds.Open,90,math.random(98,102));
			end
		end
		
		local Gate = self.Entity:GetParent()
		local Data = self.KawooshTypes[Gate.EventHorizonKawoosh or "sg1"];
		self.KawooshData = Data.KawooshDmg;
		
        timer.Create("EventHorizonOpening"..self.Entity:EntIndex(),self.OpeningDelay,1,
                function()
                        if(IsValid(e)) then
                                local blocked = false;
                                if(IsValid(parent) and parent.IsStargate) then
                                        blocked = parent:IsBlocked();
                                end
                                --##### Now, we will FIRST OF ALL get the corresponding event horizon!
                                if(not IsValid(self.Target) and IsValid(self.TargetGate)) then
                                        self.Target = self.TargetGate.EventHorizon;
                                elseif(not IsValid(self.TargetGate) and IsValid(parent) and IsValid(parent.Target) and parent.Outbound) then
                                	-- neuroplanes fix
									self.TargetGate = parent.Target;
									self.Target = self.TargetGate.EventHorizon;
                                end
                                --##### Start opening
                                e:SetNWEntity("Target",self.Target); -- Tell clientside what our target is (Necessary for the ENT:GetTeleportedVector function, if used clientside)
                                local pos = e:GetPos();
                                e:SetColor(e.Color); -- Draw model now
                                -- May fixes this bug where the EH is invisible
                                timer.Simple(e.OpenTime+0.3, -- Compensates up to a ping of 300 ms
                                        function()
                                                if(IsValid(e)) then
                                                        e:SetColor(e.Color); -- Draw model (just to be sure)
                                                end
                                        end
                                );
                                e:SetNWBool("activate_lights",true); -- Tell the event horizon to activate his dynamic lights!
                                if (not nox_type) then
                                	util.ScreenShake(pos,2,2.5,3,1000); -- Add the earth quake when the gate openes!
                                end
                                -- The lovely idle sound
                                e.IdleSound = CreateSound(e,e.Sounds.Idle);
                                e.IdleSound:Play();
                                --##### Do the "gate stabilize" effect. When you watch stargate, youll always see a quite brighter overlay just shortly after the EH has been established
                                local fx = EffectData();
                                fx:SetEntity(e);
                                fx:SetOrigin(pos);
                                if (nox_type) then
                                	fx:SetScale(0.8); -- Time in seconds until it dies
                                else
                                	fx:SetScale(e.OpenTime); -- Time in seconds until it dies
                                end
                                timer.Simple(0.6,function() if(IsValid(self)) then self.Entity:SetColor(self.Color); end end)
                                timer.Simple(e.OpenTime,function()
									if(IsValid(self)) then
										self.ValidOpen = true;
										self:SetColor(self.Color);
										self:SetNWBool("AllowBacksideDrawing",true);
									end
								end);
								if not nox_type then
									if not blocked then
										timer.Simple(e.OpenTime - 0.5, function()
											if (IsValid(self)) then
												self:EnterEffect(self:GetPos(),300,true);
											end
										end);
									end
								end
								if self.OpenEffect then
									-- proper rendering fix
									fx:SetOrigin(pos+e:GetForward()*0.3);
									fx:SetRadius(0)
									util.Effect("eventhorizon_stabilize",fx);
									fx:SetOrigin(pos-e:GetForward()*0.3);
									fx:SetRadius(1)
									util.Effect("eventhorizon_stabilize",fx);
								end
                                --##### The Kawoosh (Yeah, that thing which comes out the gate and kills peopl/stuff)
					if (not blocked and not nox_type) then -- gate is not blocked - Add kawoosh
					local fx = EffectData();
					fx:SetEntity(e);
					--##################### @ Llapp
					-- recode by AlexALX
					local Gate = self.Entity:GetParent()
					local Data = self.KawooshTypes[Gate.EventHorizonKawoosh or "sg1"];
					self.KawooshData = Data.KawooshDmg;
					fx:SetRadius(Gate.EventHorizonType=="universe" and 1 or 0);
					fx:SetMagnitude(Data.ID)
					util.Effect("stargate_kawoosh",fx,true,true);
					-- This will kill people
					local pos = self.Entity:GetPos();
					local normal = self.Entity:GetForward();
					local radius = self.Entity:BoundingRadius()*Data.KawooshDmg[1];
					if (Data.BackKawooshTime) then
						timer.Simple(Data.BackKawooshTime,function()	
							if (IsValid(self)) then
								self:EHDissolve(pos-radius*normal,radius);
								local fx = EffectData()
								fx:SetEntity(e);
								fx:SetRadius(Gate.EventHorizonType=="universe" and 1 or 0);
								util.Effect("stargate_kawoosh_movie",fx,true,true);
							end	
						end);
					end
					local reach = Data.KawooshReach or {1,3,5}; -- AGP 2026-11-13: per gate type (the Supergate's reached past its vortex)
					for _,k in ipairs(reach) do self:EHDissolve(pos+k*radius*normal,radius); end
				end
                                --##### Refract to the event horizon (Because people complained it's to less)
                                local fx = EffectData();
                                fx:SetEntity(e);
                                fx:SetOrigin(pos);
                                if self.OpenEffect then
                                	util.Effect("eventhorizon_refract",fx,true,true);
                                end
                        end
                end
        );
end

--################# The dissolve function of the kawoosh. MOST LEET FUNCTION EVER! @TetaBonita & aVoN
-- Some sort of inspired by TetaBonitas Strider Cannon: His dissolving way is much cuter than my crappy "Lasers". This thing isn't a complete copy and paste
-- The way he does it is already the only way to do it. So I mentioned him "for being the first" who has done this.
function ENT:EHDissolve(pos,radius)
	-- The hurt will actually kill things and give credits to the stargate as killer
	local e = ents.Create("kawoosh_hurt");
	if (self.Instancing) then
		e:SetInstance(self.Entity:GetInstance())
	end

	e:SetOwner(self.Entity);
	e:SetKeyValue("Damage",10000);
	e:SetKeyValue("DamageRadius",radius);
	e:SetKeyValue("DamageType",bit.bor(DMG_DISSOLVE, DMG_BLAST));
	e:SetPos(pos);
	e:SetParent(self.Entity);
	if (self.GateSpawnerSpawned) then e.GateSpawnerSpawned = true; end
	e:Spawn();
	local Data = self.KawooshData;
	for i=0,Data[2] do
		e:Fire("hurt","",0.12*i);
	end
	e:Fire("kill","",Data[3]);
	-- Start dissolving the crap!
	if(StarGate.CFG:Get("stargate","disintegrate",true)) then
		timer.Simple(0.01,function() if IsValid(self.Entity) then self:DissolveEntities(pos,radius) end end);
	end
end

-- AGP: the kawoosh spheres reach below an upright gate and dissolved the floor it stands on (an unwelded base
-- plate, and everything welded to it). Spared is only what lies completely below the gate's bottom edge AND right
-- under the gate (2026-10-25: before, everything low in front was spared too - ramps lying in front of a raised gate).
function ENT:IsBelowGate(v)
	local gate = self.Entity:GetParent();
	if (not IsValid(v) or not IsValid(gate) or math.abs(self.Entity:GetForward().z) >= 0.5) then return false end
	local bot, top = v:WorldSpaceAABB();
	if (top.z > gate:WorldSpaceAABB().z + 4) then return false end
	local c = gate:WorldSpaceCenter();
	return c.x >= bot.x and c.x <= top.x and c.y >= bot.y and c.y <= top.y;
end

--################# Dissolving entities @TetaBonita & aVoN
function ENT:DissolveEntities(pos,radius)
	if (self.Attached==nil) then return end
	local name = "EH_DISSOLVE_"..self:EntIndex();
	for _,v in pairs(ents.FindInSphere(pos,radius)) do
		if (self:IsBelowGate(v)) then continue end
		if(not (self.Attached[v] or v.GateSpawnerSpawned or v.NoDissolve)) then
			if(v:GetMoveType() == 6 and not self.Attached[v:GetParent()] and not self.Attached[v:GetDerive()]) then
				if (constraint.HasConstraints(v)) then
					local entities = StarGate.GetConstrainedEnts(v,2);
					local cont = false;
					if(entities) then
						for c,b in pairs(entities) do
							if(b:IsWorld()) then
								cont = true;
								break;
							end
						end
					end
					if (cont) then continue end
				end
				local phys = v:GetPhysicsObject();
				local class = v:GetClass();
				local mdl = v:GetModel(); -- We are searching e.g. for map entities (func_brush etc): Models with an "*" in it's modelname are such things


				-- Do not dissolve crap!

				if (self.Instancing) then
					if(phys:IsValid() and v:GetInstance()==self.Entity:GetInstance() and (class == "phys_magnet" or not class:find("phys_[^m]")) and mdl ~= "" and not mdl:find("*")) then
						phys:EnableMotion();
						v:SetKeyValue("targetname",name);
						for bone=0,v:GetPhysicsObjectCount()-1 do
							local phys = v:GetPhysicsObjectNum(bone);
							if(phys:IsValid()) then
								phys:SetVelocity(phys:GetVelocity()*0.04);
								phys:EnableGravity(false);
							end
						end
					end
				else
					if(phys:IsValid() and (class == "phys_magnet" or not class:find("phys_[^m]")) and mdl ~= "" and not mdl:find("*")) then
						phys:EnableMotion();
						v:SetKeyValue("targetname",name);
						for bone=0,v:GetPhysicsObjectCount()-1 do
							local phys = v:GetPhysicsObjectNum(bone);
							if(phys:IsValid()) then
								phys:SetVelocity(phys:GetVelocity()*0.04);
								phys:EnableGravity(false);
							end
						end
					end
				end
			end
		end
	end
	-- Start the real cool dissolving effect
	local e = ents.Create("env_entity_dissolver");
	e:SetKeyValue("dissolvetype",3);
	e:SetKeyValue("magnitude",0);
	e:SetPos(pos);
	e:SetKeyValue("target",name);
	e:Spawn();
	e:Fire("Dissolve",name,0);
	e:Fire("kill","",0.1);
end


--################# Shutting down the event horizon @aVoN
function ENT:Shutdown(override)
	if(self.ShuttingDown or (not self:IsOpen() and not override)) then return end; -- Aready shutting down or not opened yets
	if (self.IdleSound) then self.IdleSound:Stop() end
	timer.Remove("EventHorizonEffect"..self.Entity:EntIndex());
	timer.Remove("EventHorizonOpening"..self.Entity:EntIndex());
	self.ShuttingDown = true;
	self.ShuttingDownKill = true;
	if self.OpenEffect then
		local fx = EffectData();
		fx:SetEntity(self.Entity);
		fx:SetOrigin(self.Entity:GetPos());
		util.Effect("eventhorizon_collapse",fx,true,true);
	end
	if(IsValid(self.Target)) then
		self.Target:Shutdown(override);
	end
	-- AGP 2026-11-14: a horizon shut down while its gate is being removed has no parent, and may be gone 0.1 s later
	-- (errors in a test run: "Tried to use a NULL entity", net.Start with an unpooled name)
	local par = self:GetParent();
	if(IsValid(par) and par:GetClass() == "stargate_supergate") then
		timer.Simple(0.1,function()
			if (not IsValid(self)) then return end
			net.Start("supergate_sounds"..self:EntIndex())
			net.WriteString(self.Sounds.Close)
			net.Broadcast()
		end)
	else
		self.Entity:EmitSound(self.Sounds.Close,90,math.random(97,103));
	end

	local e = self.Entity;
	for k,v in pairs(self.AllBuffer) do
		if (IsValid(v)) then
			self:EHDissolve(v:GetPos(),5)
		end
	end
	-- Let the light fade away!
	timer.Simple(2,
		function()
			if(IsValid(e)) then
				e:SetNWBool("activate_lights",false);
				e.ShuttingDownKill = false;
			end
		end
	);
	-- Make sure, it will be deleted!
	timer.Simple(4,
		function()
			if(IsValid(e)) then
				e:Remove();
			end
		end
	);
end

function ENT:BufferEmpty()
	if(self.ShuttingDown or not self:IsOpen()) then return end; -- Aready shutting down or not opened yets
	for k,v in pairs(self.AllBuffer) do
		if (IsValid(v)) then
			self:CleanBufferVars(v) -- may prevent physics crash
			self:EHDissolve(v:GetPos(),5)
		end
	end
	self.AllBuffer = {};
	self.ClipBuffer = {};
	self.Buffer = {};
end

--################# Hit @aVoN
function ENT:Hit()
	if(self.ShuttingDown) then return end;
	-- This basically is the same as the establish effect until someone else does a better one
	-- AGP 2026-11-08: "eventhorizon_establish" never existed; it is the old name of eventhorizon_stabilize (same white
	-- overlay material, zup/stargate/eventhorizon_establish). On the front side like the opening's front overlay;
	-- Radius 0 = not the main overlay, so it leaves the horizon's alpha and ripple alone.
	local fx = EffectData();
	fx:SetEntity(self.Entity);
	fx:SetOrigin(self:GetPos() + self:GetForward() * 0.3);
	fx:SetScale(0.5); -- Time in seconds until it dies
	fx:SetRadius(0);
	util.Effect("eventhorizon_stabilize",fx);
end

--################# Draws an entering effect on the event horizon @aVoN
function ENT:EnterEffect(pos,size,kawoosh)
	local diff = self:WorldToLocal(pos); diff.x = 0;
	local thresold = (self.HorizonRadius - diff:Length()/1.3);
	local effect_radius = size*2;
	effect_radius = math.Clamp(effect_radius,0,thresold);
	-- This effect isnt perfect or looks like the original one. Sometimes you event can't see it. But I dont mind.
	local fx = EffectData();
	-- This is, so the effect will be drawn always on the frontside of the event horizon
	local dist = self:WorldToLocal(self:NearestPoint(pos));
	fx:SetOrigin(self:LocalToWorld(dist)); -- I love this freaking "NearestPoint" function
	fx:SetEntity(self);
	fx:SetScale(effect_radius);
	if (kawoosh) then
		if (IsValid(self:GetParent()) and self:GetParent():GetClass()=="stargate_supergate") then
			util.Effect("gate_enter_super",fx,true,true);
		else
			util.Effect("gate_enter_kawoosh",fx,true,true);
		end
	else
		util.Effect("gate_enter",fx,true,true);
	end
end

--################# This is a wrapper for entities entering the EH @aVoN
function ENT:EnterEffectEntity(e)
	local pos = e:LocalToWorld(e:OBBCenter());
	local radius = e:BoundingRadius();
	self:EnterEffect(pos,radius);
end

-- AGP 2026-11-08: a shot or thrown thing: Half-Life 2's (AGPShots) or a SENT shot that says it does not close the gate
-- (NoAutoClose: staff and other energy blasts, drones, missiles). These go through at once, without the wormhole ride.
function ENT:AGPIsShot(e)
	return IsValid(e) and not e:IsPlayer() and not e:IsNPC() and (self.AGPShots[e:GetClass()] or e.NoAutoClose == true) or false;
end
-- AGP 2026-11-09: what goes through at once, without the wormhole ride: shots, and Replicators (bugs, Queens, blocks).
-- Riding, a bug was held frozen half in the horizon of the gate it went into for 3.2 s - the owner watched them stand
-- there - and when the gate shut meanwhile (its autoclose after the prey) it was deleted with the rest of the swarm that
-- followed it; the ride is a picture for players.
function ENT:AGPNoRide(e)
	return self:AGPIsShot(e) or (IsValid(e) and e.AGPReplicator == true);
end

-- AGP 2026-11-08: something went in or came out: the gate closes AGPAutoCloseDelay s from now (ENT:Think), unless autoclose
-- is off (config "autoclose", Wire/menu "Disable Autoclose") or it is a shot, a grenade or a weapon (CAP's rules, which
-- were copied four times below). Every traveller pushes the close back. Not on an incoming horizon (no Target: what walks
-- in there dies; CAP's close from there did nothing).
function ENT:AGPAutoClose(e)
	if (not self.AutoClose or not IsValid(e) or not IsValid(self.Target)) then return end
	local class = e:GetClass();
	local parent = self.Entity:GetParent();
	if (e.NoAutoClose or table.HasValue(self.AutocloseImmunity,class) or class:find("grenade") or class:find("rpg") or e:IsWeapon()
		or (IsValid(parent) and parent.DisAutoClose)) then return end
	self.DoAutoClose = true;
	self.AGPCloseAt = CurTime() + self.AGPAutoCloseDelay;
	self.Entity:NextThink(self.AGPCloseAt);
end

-- AGP 2026-11-08: is v in or right at this horizon (the nearest point of its box within the horizon's reach)? A buffer
-- entry of something that left long ago no longer keeps the gate open.
function ENT:AGPAtHorizon(v)
	-- AGP 2026-11-08: the gate's own parts never count (the Alteran gate's turning ring, a func_rotating, sat in the
	-- buffer at the horizon's centre and held the gate open for good)
	local g = self.Entity:GetParent();
	if (IsValid(g) and (v == g or v:GetParent() == g or v:GetClass() == "func_rotating")) then return false end
	local c = self.Entity:GetPos();
	local r = self.Entity:BoundingRadius() + 16;
	return v:NearestPoint(c):DistToSqr(c) <= r * r;
end

--################# The most important part - Recognizes entering props and teleports them @RononDex
function ENT:StartTouch(e)
	local class = e:GetClass();
	if (self.Instancing) then
		if e:GetInstance() != self:GetInstance() then return end
	end

	if self.ModelClip then
		if(not self:GetParent().IsSupergate) then
			if(not IsValid(self.Target)) then
				if(class=="puddle_jumper" and not self.ShuttingDown) then
					if(e.Exiting) then
						e:SetPos(self:GetPos());
					end
				end
			end
		end

		if (self.PhysClip) then
			e:SetCustomCollisionCheck(true);
		end
		if(not e:IsPlayer() and not e:IsNPC() and not string.find(e:GetClass(),"grenade") and not e:IsWeapon() and not string.find(e:GetClass(),"rpg") and not table.HasValue(self.NoTouchTeleport,e:GetClass()) and not e.CAP_EH_NoTouchTeleport) then
			if not table.HasValue(BUFFER.ClipIgnore,e:GetClass()) then
				BUFFER:StartTouch(self.Entity,e)
			end
		else
			self:StartTouchPlayersNPCs(e)
		end
	else
		self:StartTouchPlayersNPCs(e);
	end
end

--################# Keeps clipping plane up to date @RononDex
function ENT:Touch(e)
	if (self.Instancing) then
		if e:GetInstance() != self:GetInstance() then return end
	end

	local class = e:GetClass();
	if self.ModelClip then
		if not table.HasValue(BUFFER.ClipIgnore,e:GetClass()) then
			BUFFER:Touch(self.Entity,e)
		end
		if(not self:GetParent().IsSupergate) then
			if(class=="puddle_jumper" and not self.ShuttingDown) then
				if(not IsValid(self.Target)) then
					e.Exiting = true;
					if(IsValid(e.Pilot)) then
						e.Pilot:SetEyeAngles(self:GetParent():GetAngles());
					end
					e:SetAngles(self:GetParent():GetAngles()+Angle(0,0,0));
				end
			end
		end
	end
end

function ENT:StartTouchPlayersNPCs(e,ignore)
	if(self.Attached[e]) then return end; -- Attached props
	if(self.ShuttingDown and not self.ShuttingDownKill) then return; end
	if(not IsValid(e)) then return end; -- Not valid
	if(e:IsPlayer() and (IsValid(e:GetParent()) or IsValid(e:GetVehicle()) or IsValid(e:GetNWEntity("ScriptedVehicle", NULL)))) then return end; -- No teleport/kill of parented players
	if(e.NotTeleportable) then return end; -- Does not want to be teleported!
	local class = e:GetClass();
	if(class:find("stargate")) then return end;
	local parent = self.Entity:GetParent();
	--################# This fixes props, which not have exited the receiving EH yet are getting deleted
	if(e.__StargateTeleport and e.__StargateTeleport.__TARGET == self.Entity) then
		-- Start the check
		local add = false;
		if(e.__StargateTeleport.__LastTeleport + 0.5 > CurTime()) then -- GraceTime says: "Add this entity to DoNotDestroy list!"
			add = true;
		else -- GraceTime is over. But do we still have entities in our DoNotDestroy list which belong to this entity? If so, DO NOT DESTROY!
			for k,_ in pairs(self.DoNotDestroy) do
				if(e.__StargateTeleport[k]) then
					add = true;
					break;
				end
			end
		end
		if(add) then
			-- Nocollide the gate as long as something is in it!
			if(IsValid(parent)) then
				-- If a nocollide timer has been started, stop it so it won't interfere
				timer.Remove("StarGate.SetReceivingGateCollide"..parent:EntIndex());
				parent:SetCollisionGroup(COLLISION_GROUP_WORLD);
			end
			self.DoNotDestroy[e] = true;
			return;
		end
	end
	-- Makes the prop getting teleported as soon as the player stops holding it
	if(e:IsPlayerHolding()) then
		self.Holding[e] = true;
	else
		--################# Is our receiving gate blocked?
		local block = false;
		local target_gate; -- Used in here and a bit lower later (for the iris hit sounds)
		if(not self:IsOpen() or self.ShuttingDownKill) then block = true end; -- We havent opened yet. Kill people!
		-- Are we entering the eventhorizon from the wrong side? Kill us!
		local dir = (self.Entity:GetVelocity()-e:GetVelocity()):GetNormalized();

		if(self.Entity:GetForward():DotProduct(dir) < 0) then
			block = true
		else
			-- Our iris prvents us from getting in "from the front" (but not from the back aka "die"
			if (not ignored and IsValid(parent) and parent:IsBlocked(true)) then
				if (not self.SecretDial or not e:IsPlayer()) then
					self.DoNotDestroy[e] = true;
					return;
				end
			end
		end
		if(not block and not IsValid(self.Target)) then block = true end; -- Do we have a valid target? If not, we are inbound
		if (self.Unstable) then
			block = true
		end
		local bcfd = false;
		-- Not yet getting killed? So check, if the otherside has an iris activated
		if(not block) then
			target_gate = self.Target:GetParent();
			if(IsValid(target_gate) and target_gate.IsStargate) then
				block = target_gate:IsBlocked();
			end
			if (self:BlockedCFD(target_gate,e)) then block = false; bcfd = true; end
		end
		--################# Get attachments, mainly for the hook below but we need it anyway
		local attached = self:GetEntitiesForTeleport(e);

		if(attached) then
			local allow_teleport = hook.Call("StarGate.Teleport",GAMEMODE,e,self.Entity,attached,block); -- AGP: was "blocked" (never set): the hook never learned of a shut iris
			if(allow_teleport ~= nil and not allow_teleport) then return end; -- Someone does not want to teleport us! Shame on him
				--################# Just for the show - The "gulping" effect
				-- Before we teleport, draw the entering effect on out event horizon
				if (not ignore) then
					self:EnterEffectEntity(e);
					self.Entity:EmitSound(self.Sounds.Teleport[math.random(1,#self.Sounds.Teleport)],90,math.random(90,110));
				end
					if (e:IsPlayer() and self.SecretDial and not ignore and self.Entity:GetForward():DotProduct(dir) >= 0) then
						self:DoSecret(e);
			 			return
					end


				-- AGP 2026-11-08: shots and thrown things (grenades, bolts, rockets, combine balls, energy blasts) go through at
				-- once, as in CAP; players, NPCs and the rest take the wormhole ride (when it is on)
				local wormhole = StarGate.CFG:Get("stargate", "doWormholeSequence", false) and not self:AGPNoRide(e);

				if (not wormhole) then
					-- --################# Teleport us

					self:Teleport(e,block,attached);
					--################# Blocked or not? Either make iris play the "blocked" sound or draw the gulping at the other end
					if(block) then
						if (not self.Unstable) then
							-- Iris blocked us. Make hut-noise
							if(IsValid(target_gate) and IsValid(target_gate.Iris) and target_gate.Iris.IsActivated) then
								target_gate.Iris:HitIris(self:GetTeleportedVector(e:GetPos(),e:GetVelocity())); -- Tell that we hit and where and how fast
							end
						end
					end
				end

				if (not wormhole) then
					-- Needs to be delayed, or you wont hear the teleporting gulp if your a player
					local t = self.Target
					if (not bcfd) then
						timer.Simple(0.05,
							function()
								if(IsValid(t) and IsValid(e)) then
									t:EmitSound(self.Sounds.Teleport[math.random(1,#self.Sounds.Teleport)],90,math.random(90,110));
									-- Draw the effect on the other eventhorizon
									t:EnterEffectEntity(e);
								end
							end
						);
					end

					self:AGPAutoClose(e); -- AGP 2026-11-08: CAP's autoclose rules, now in one place (ENT:AGPAutoClose)
				end

				if (wormhole) then
					-- AGP 2026-11-08: going in starts the wait too (CAP Enhanced only started it once the 3.2 s ride was over);
					-- while it rides the wormhole the gate stays open (ENT:Think)
					self:AGPAutoClose(e);
					if (self.Entity:GetForward():DotProduct(dir) >= 0) then
							self:DoWormHole(e,block,attached,bcfd,false);
						else	
							self:DoWormHole(e,block,attached,bcfd,true);
					end
				end
		end
		-- AGP 2026-11-08: no "else" any more (CAP has none): what GetEntitiesForTeleport rejects (frozen, parented, welded
		-- to the gate, no physics) stays where it is, untouched. CAP Enhanced played the gulp at every touch and, with the
		-- wormhole ride on, hid it 3.2 s without teleporting it, then errored on its nil ___dir (ENT:MoveToTarget) and
		-- never counted "Entities On Route" down again.
		end
	end


--################# Stops being in the eventhorizon @aVoN
function ENT:EndTouchPlayersNPCs(e)
	self.DoNotDestroy[e] = nil;
	if(e.__StargateTeleport) then
		e.__StargateTeleport.__LastTeleport = CurTime(); -- Avoids a bug where parts of a contraption has holes between each other. This results into not destroying the object.
	end
	if(table.Count(self.DoNotDestroy) == 0) then
		-- Remove the nocollide again (but delayed)
		local parent = self.Entity:GetParent();
		timer.Create("StarGate.SetReceivingGateCollide"..parent:EntIndex(),1,1,
			function()
				if(IsValid(parent)) then
					parent:SetCollisionGroup(COLLISION_GROUP_NONE);
				end
			end
		);
	end
	self.Holding[e] = nil;
end

--################# Stops being in the eventhorizon @aVoN,RononDex
function ENT:EndTouch(e)

	if(self.ShuttingDown) then return end; -- We are shutting down
	if(not IsValid(e)) then return end; -- Not valid or ignore
	if(e:IsPlayer() and (IsValid(e:GetParent()) or IsValid(e:GetVehicle()) or IsValid(e:GetNWEntity("ScriptedVehicle",NULL)))) then return end;  -- No teleport/kill of parented players
	if(e.NotTeleportable) then return end; -- Does not want to be teleported!

	local parent = self.Entity:GetParent();

	if(e:IsPlayer() or e:IsNPC() or table.HasValue(self.NoTouchTeleport,e:GetClass()) or string.find(e:GetClass(),"grenade") or string.find(e:GetClass(),"rpg") or e:IsWeapon()) then
		self:EndTouchPlayersNPCs(e)
		return
	elseif not self.ModelClip then
		self:EndTouchPlayersNPCs(e)
		return;
	end

	if(not self:GetParent().IsSupergate) then
		if(e:GetClass()=="puddle_jumper") then
			if(not IsValid(self.Target)) then
				e.Exiting = false;
				e.Exited = true;
				timer.Simple(1,function()
					e.Exited = false;
				end);
			end
		end
	end

	local dir = (self:GetPos()-e:GetPos()):GetNormalized();

	local temp_dir = 0;
	if(self:GetForward():DotProduct(dir) < 0) then
		temp_dir = -1;
	else
		temp_dir = 1;
	end

	if self.ModelClip then
		if (self.PhysClip) then
			e:SetCustomCollisionCheck(false);
		end
		if not table.HasValue(BUFFER.ClipIgnore,e:GetClass()) then
			BUFFER:EndTouch(self.Entity,e,nil,temp_dir)
		end
	end

	-- If the ent came out the way it was going in, don't destroy/teleport
	if(e.___EventHorizon != self or temp_dir != e.dir) then
		e.___InBuffer = false;
		e.___EventHorizon = nil;
		return;
	else
		e.___InBuffer = true;
		e.___EventHorizon = self;
	end
	
	if(self.Holding[e]) then
		if(not IsValid(e)) then
			self.Holding[e] = nil;
			return;
		end
		if(not e:IsPlayerHolding()) then
			self.Holding[e] = nil;
			self:EndTouch(e);
		end
	end
	
	local attached = self:GetEntitiesForTeleport(e);
	if(attached) then
		for _,v in pairs(attached.Attached) do
			if (IsValid(v) and v:IsPlayerHolding()) then
				self.Holding[v] = true;
			elseif (not IsValid(v)) then
				self.Holding[v] = nil;
			end
		end
	end

	-- TELEPORT CODE
	--################# This fixes props, which not have exited the receiving EH yet are getting deleted
	if(e.__StargateTeleport and e.__StargateTeleport.__TARGET == self.Entity) then
		-- Start the check
		local add = false;
		if(e.__StargateTeleport.__LastTeleport + 0.5 > CurTime()) then -- GraceTime says: "Add this entity to DoNotDestroy list!"
			add = true;
		else -- GraceTime is over. But do we still have entities in our DoNotDestroy list which belong to this entity? If so, DO NOT DESTROY!
			for k,_ in pairs(self.DoNotDestroy) do
				if(e.__StargateTeleport[k]) then
					add = true;
					break;
				end
			end
		end

		if(add) then
			-- Nocollide the gate as long as something is in it!
			if(IsValid(parent)) then
				-- If a nocollide timer has been started, stop it so it won't interfere
				timer.Remove("StarGate.SetReceivingGateCollide"..parent:EntIndex());
				parent:SetCollisionGroup(COLLISION_GROUP_WORLD);
			end
			self.DoNotDestroy[e] = true;
			return;
		end
	end
	-- Makes the prop getting teleported as soon as the player stops holding it
	if(e:IsPlayerHolding()) then
		self.Holding[e] = true;
	else
		--################# Is our receiving gate blocked?
		local block = false;
		local target_gate; -- Used in here and a bit lower later (for the iris hit sounds)
		if(not self:IsOpen()) then block = true end; -- We havent opened yet. Kill people!
		-- Are we entering the eventhorizon from the wrong side? Kill us!
		local dir = (self.Entity:GetVelocity()-e:GetVelocity()):GetNormalized();

		if(self.Entity:GetForward():DotProduct(dir) < 0) then
			block = true
		else
			-- Our iris prvents us from getting in "from the front" (but not from the back aka "die"
			if(IsValid(parent) and parent:IsBlocked(true)) then
				self.DoNotDestroy[e] = true;
				return;
			end
		end
		if(not block and not IsValid(self.Target)) then block = true end; -- Do we have a valid target? If not, we are inbound
		if (self.Unstable) then
			block = true
		end
		-- Not yet getting killed? So check, if the otherside has an iris activated
		if(not block) then
			target_gate = self.Target:GetParent();
			if(IsValid(target_gate) and target_gate.IsStargate) then
				block = target_gate:IsBlocked();
			end
		end
		--################# Get attachments, mainly for the hook below but we need it anyway
		local attached = self:GetEntitiesForTeleport(e);
		if(attached) then
			for _,v in pairs(attached.Attached) do
				if(not v.___InBuffer or self.Holding[v]) then return end;
			end
			local allow_teleport = hook.Call("StarGate.Teleport",GAMEMODE,e,self.Entity,attached,block); -- AGP: was "blocked" (never set): the hook never learned of a shut iris
			if(allow_teleport ~= nil and not allow_teleport) then return end; -- Someone does not want to teleport us! Shame on him
			--################# Just for the show - The "gulping" effect
			-- Before we teleport, draw the entering effect on out event horizon
			self:EnterEffectEntity(e);
			self.Entity:EmitSound(self.Sounds.Teleport[math.random(1,#self.Sounds.Teleport)],90,math.random(90,110));
			--################# Teleport us
			--Marked Moonwatcher

			-- AGP 2026-11-08: SENT shots (Ha'tak, Wraith, Vanir blasts, F-302 missiles) go through at once, as in CAP
			if (StarGate.CFG:Get("stargate", "doWormholeSequence", false) and not self:AGPNoRide(e)) then

				if (self.Entity:GetForward():DotProduct(dir) >= 0) then
					if (IsValid(e:GetPhysicsObject())) then
						self:DoWormHole(e,block,attached,false,false,e:GetPhysicsObject():IsGravityEnabled());
					else
						self:DoWormHole(e,block,attached,false,false);
					end
				else
					if (IsValid(e:GetPhysicsObject())) then
						self:DoWormHole(e,block,attached,false,true,e:GetPhysicsObject():IsGravityEnabled());
					else
						self:DoWormHole(e,block,attached,false,true);
					end
				end
			else
				self:Teleport(e,block,attached);
			end

			--################# Blocked or not? Either make iris play the "blocked" sound or draw the gulping at the other end
			if(block) then
				if (not self.Unstable) then
					-- Iris blocked us. Make hut-noise
					if(IsValid(target_gate) and IsValid(target_gate.Iris) and target_gate.Iris.IsActivated) then
					end
				end
				e.___InBuffer = false;
				e.___EventHorizon = nil;
			else
				--Needs to be delayed, or you wont hear the teleporting gulp if your a player
				local t = self.Target
				timer.Simple(0.05,
					function()
						if(IsValid(t) and IsValid(e)) then
							e.___dir = nil;
							for _,v in pairs(attached.Attached) do
								if (IsValid(v)) then
									local dir = (t:GetPos()-v:GetPos()):GetNormalized();
									local temp_dir = 0;
									if(t:GetForward():DotProduct(dir) < 0) then
										temp_dir = -1;
									else
										temp_dir = 1;
									end
                                    if (temp_dir==1) then
										t:StartTouch(v);
									end
									v.___dir = nil;
								end
							end
							-- Draw the effect on the other eventhorizon
						end
					end
				);

				self:AGPAutoClose(e); -- AGP 2026-11-08: CAP's autoclose rules, now in one place (ENT:AGPAutoClose)
			end
		end
	end
	-- END TELEPORT CODE

	self.DoNotDestroy[e] = nil;
	if(e.__StargateTeleport) then
		e.__StargateTeleport.__LastTeleport = CurTime(); -- Avoids a bug where parts of a contraption has holes between each other. This results into not destroying the object.
	end
	if(table.Count(self.DoNotDestroy) == 0) then
		-- Remove the nocollide again (but delayed)
		local parent = self.Entity:GetParent();
		timer.Create("StarGate.SetReceivingGateCollide"..parent:EntIndex(),1,1,
			function()
				if(IsValid(parent)) then
					parent:SetCollisionGroup(COLLISION_GROUP_NONE);
				end
			end
		);
	end
	self.Holding[e] = nil;
end

-- AGP 2026-11-08: is something still going through, so the gate must stay open?
-- - riding the wormhole from here (the 3.2 s ride: closing now would kill it); a ride that never ended counts 10 s at most
--   (unless routing is paused)
-- - half-way through this or the far horizon (the buffers) - but only while it is still at that horizon. Buffer entries
--   are not cleared on every way out (BUFFER:EndTouch returns early while a welded part is still clipped): such a stale
--   entry held the gate open for good (up to the 38 min limit).
function ENT:AGPPassing()
	for k,r in pairs(self.Ents or {}) do
		if (not IsValid(k)) then
			self.Ents[k] = nil;
		elseif (r.AGPSince and (self.RoutingPaused or CurTime() - r.AGPSince < 10)) then
			return true;
		end
	end
	for k,v in pairs(self.Buffer) do
		if (not IsValid(v)) then
			self.Buffer[k] = nil;
		elseif (self:AGPAtHorizon(v)) then
			return true;
		end
	end
	local t = self.Target;
	if (not IsValid(t) or not t.Buffer or not t.AGPAtHorizon) then return false end
	-- HD gates keep their old behaviour: their target buffer does not hold the EH open
	local tgate = t:GetParent();
	local tc = IsValid(tgate) and tgate:GetClass() or "";
	if (tc == "stargate_sg1_hd" or tc == "stargate_alt_hd" or tc == "stargate_movie_hd") then return false end
	for k,v in pairs(t.Buffer) do
		if (not IsValid(v)) then
			t.Buffer[k] = nil;
		elseif (t:AGPAtHorizon(v)) then
			return true;
		end
	end
	return false;
end

--################# For the autoclose @aVoN
function ENT:Think()
	if(self.DoAutoClose) then
		-- AGP 2026-11-08: not before the wait is over (a later traveller pushed it back)
		if ((self.AGPCloseAt or 0) > CurTime() + 0.05) then
			self.Entity:NextThink(self.AGPCloseAt);
			return true;
		end

		if(not self.WaterNoClose or self:WaterLevel() < 1) then
			-- FIXME: Add config for the autoclose
			local gate = self.Entity:GetParent();
			if(IsValid(gate)) then

				-- Prevents some bugs
				if(not IsValid(self.Target)) then
					gate:DeactivateStargate();
					return;
				end
				-- fix: "close" was a global, the HD check was always false and an unconditional "close = true"
				-- overwrote both buffer checks, so entities half-way through the EH never kept it open.
				local close = not self:AGPPassing(); -- AGP 2026-11-08: the buffer checks moved to ENT:AGPPassing (+ the ride)

				for _,e in pairs({self.Entity}) do
					if(close) then
						local parent = e:GetParent();
						if(IsValid(parent)) then
							local constrained = (StarGate.GetConstrainedEnts(parent,3) or {}); -- Constrained props to a stargate SHOULD NEVER keep it open!
							for _,v in pairs(ents.FindInSphere(e:GetPos(),e:BoundingRadius())) do
								local class = v:GetClass();
								if(not table.HasValue(constrained,v) and not table.HasValue(self.AutocloseImmunity,class)) then
									local vp = v:GetParent(); -- Parents of the object we found
									local phys = v:GetPhysicsObject();
									if(
										(phys:IsValid() and phys:IsMoveable()) and -- Has to be unfrozen/Movable
										(v ~= e and v ~= parent and not v.IsStargate and not v.IsDHD and not v.GateSpawnerSpawned) and -- General entities
										(not IsValid(vp) or (vp ~= parent and not vp.IsDHD and not vp.IsStargate and not vp.GateSpawnerSpawned))
									) then
										-- Keep the EH open!
										if(not v:IsPlayer() or v:Alive()) then -- Only if it's a player who is alive
											close = false;
											break;
										end
									end
								end
							end
						end
					end

					if(close)then

						gate:DeactivateStargate();
					else
						-- Check a bit more frequently now!
						self.Entity:NextThink(CurTime()+0.5);
						return true;
					end
				end
			end
		end
	end
	self.Entity:NextThink(CurTime()+3);
	return true;
end


--[[
	Beyond here is all model clipping related code
]]--

local KeyValue1 = {"xfriction","yfriction","zfriction","forcelimit","torquelimit"};
local MaxValue = {"xmax","ymax","zmax"};
local MinValue = {"xmin","ymin","zmin"};
--############### What happens when we first touch the EH? Clip maybe? @RononDex
function BUFFER:StartTouch(EventHorizon,e)
	if(not IsValid(e) or self:ClipShouldIgnore(e,true)) then return end; -- Not valid or ignore
	if(not IsValid(e.___EventHorizon)) then e.___EventHorizon = EventHorizon end;
	if(not IsValid(EventHorizon)) then return end;
	if(EventHorizon.ShuttingDown and not EventHorizon.ShuttingDownKill) then return; end
	local attached = EventHorizon:GetEntitiesForTeleport(e);
	if(EventHorizon.Attached[e]) then return end
	if (EventHorizon.AllBuffer[e:EntIndex()]) then return end

	local dir = (e:GetPos()-EventHorizon:GetPos()):GetNormalized();


	if(EventHorizon:GetForward():DotProduct(dir) < 0 and e.___dir==nil) then
		e.dir = -1;
	else
		e.dir = 1;
		EventHorizon.Buffer[e:EntIndex()] = e
		e.___dir = nil;
	end

	EventHorizon.AllBuffer[e:EntIndex()] = e


	if(not e:IsPlayer() and not e:IsNPC()) then
		e.gate = EventHorizon;
		e.gate.agate = EventHorizon:GetParent();
		if (EventHorizon.PhysClip) then
			e:SetNWBool("PhysBuffered",true);
			e:SetNWInt("PhysBufferedDir",e.dir);
			e:SetNWEntity("PhysEntity",e.gate);
		end
	end

	umsg.Start("StarGate.EventHorizon.ClipStart");
		umsg.Short(e.dir)
		umsg.Entity(e);
		umsg.Entity(EventHorizon);
	umsg.End();

	if(not(e:GetClass()=="kino_ball")) then
		if(IsValid(e:GetPhysicsObject())) then
			EventHorizon.GravBuffer[e:EntIndex()] = e:GetPhysicsObject():IsGravityEnabled();
			e:GetPhysicsObject():EnableGravity(false);
		end
	end

	if(attached) then
		for _,v in pairs(attached.Attached) do
			if (IsValid(v)) then
				if(IsValid(phys) and v:GetSolid()!=SOLID_NONE) then
					v.dir = e.dir
					v:SetNWInt("PhysBufferedDir",e.dir);
					local phys = v:GetPhysicsObject();
					EventHorizon.GravBuffer[v:EntIndex()] = phys:IsGravityEnabled();
					phys:EnableGravity(false);
				end
			end
		end
	end

	if(IsValid(e:GetPhysicsObject()) and IsValid(game.GetWorld():GetPhysicsObject())) then -- fix: a NULL physics object is not nil
		e.EventHorizonNoCollide = ents.Create("phys_ragdollconstraint");
		e.EventHorizonNoCollide:SetKeyValue("spawnflags",3);
		for _,v in pairs(MaxValue) do
			e.EventHorizonNoCollide:SetKeyValue(v, 180 );
		end
		for _,v in pairs(MinValue) do
			e.EventHorizonNoCollide:SetKeyValue(v, -180 );
		end
		for _,v in pairs(KeyValue1) do
			e.EventHorizonNoCollide:SetKeyValue(v,0);
		end
		e.EventHorizonNoCollide:SetPhysConstraintObjects(game.GetWorld():GetPhysicsObject(),e:GetPhysicsObject());
		e.EventHorizonNoCollide:Spawn();
		e.EventHorizonNoCollide:Activate();
	end
end

function BUFFER:Touch(EventHorizon,e)

	if(not IsValid(e) or self:ClipShouldIgnore(e)) then return end; -- Not valid or ignore
	if(not IsValid(EventHorizon)) then return end;
	if(not e:GetPhysicsObject():IsValid()) then return end;
	if(EventHorizon.Attached[e]) then return end
	if(EventHorizon.ShuttingDown and not EventHorizon.ShuttingDownKill) then return; end
	if(e:IsPlayer()) then return end
	if (e.___LastCurTime!=nil and e.___LastCurTime==CurTime()) then return end -- PREVENT FUCKING DISCONNECT ON PAUSE IN SP WHEN SOMETHING TOUCH EH!!! Damn it...
	e.___LastCurTime = CurTime();

	-- Draw the enter effect every 20th frame, @Deathmaker
	if (e.___DrawEnterEffectTime!=nil and e.___DrawEnterEffectTime>20) then
		EventHorizon:EnterEffectEntity(e)
		e.___DrawEnterEffectTime=0
	else
		e.___DrawEnterEffectTime = (e.___DrawEnterEffectTime or 0)+1
	end
	-- damn, with old code at same time can be only one effect displaying, fixed by AlexALX

	--########### This handle's what happens when an object is touching the EH and shutsdown
	if(EventHorizon.ShuttingDownKill or EventHorizon.Unstable or not EventHorizon.ValidOpen) then
		if(e.IsJumper) then
			e:DoKill(e.Pilot) -- Jumpers and Vehicles are destroyed
		elseif(e.IsSGVehicle) then
			e:Bang(e.Pilot)
		else
			for _,v in pairs(constraint.GetAllConstrainedEntities(e)) do
				if(IsValid(v)) then
					BUFFER:EndTouch(EventHorizon,v,true)
				end
			end
			if(not(EventHorizon.Attached[e])) then
				EventHorizon:EHDissolve(e:GetPos(),5)
			end
		end
	end

	umsg.Start("StarGate.EventHorizon.ClipStart")
		umsg.Short(e.dir)
		umsg.Entity(e)
		umsg.Entity(EventHorizon)
	umsg.End()
end

function ENT:CleanBufferVars(e)
	self.Buffer[e:EntIndex()] = nil
	self.AllBuffer[e:EntIndex()] = nil
	self.ClipBuffer[e:EntIndex()] = nil
	self.GravBuffer[e:EntIndex()] = nil
	e:SetNWBool("PhysBuffered",false);
	e:SetNWInt("PhysBufferedDir",0);
	e.gate = nil;
	e:SetNWEntity("PhysEntity",NULL);

	if(IsValid(e.EventHorizonNoCollide)) then
		e.EventHorizonNoCollide:Remove();
	end

	umsg.Start("StarGate.EventHorizon.ClipStop");
		umsg.Entity(e);
	umsg.End()

	e.IsInGate = false;
	BUFFER.InBuffer[e] = nil;
	e.___InBuffer = false;
	e.___dir = nil;
end

--############# What happens when we have stopped touching the gate? Stop Clipping? @RononDex
function BUFFER:EndTouch(EventHorizon,e,ignore,tdir)

	local attached = EventHorizon:GetEntitiesForTeleport(e);
	if(not(IsValid(e))) then return end;
	if(not IsValid(EventHorizon)) then return end;
	if(self:ClipShouldIgnore(e,true)) then return end;
    local notouch = false;

	for k,v in pairs (EventHorizon.ClipBuffer) do
		if (not v:IsValid()) then
			EventHorizon.ClipBuffer[k] = nil;
		end
	end

	if(attached and not ignore) then
		for _,v in pairs(attached.Attached) do

			-- less buggy, but still...
			if (IsValid(v) and IsValid(v:GetPhysicsObject()) and v:GetSolid()!=SOLID_NONE) then
				local tvdir = 0;
				local dir = (v:GetPos()-EventHorizon:GetPos()):GetNormalized(); --(EventHorizon:GetVelocity()-e:GetVelocity()):GetNormalized();
				if(EventHorizon:GetForward():DotProduct(dir) < 0) then
					tvdir = -1;
				else
					tvdir = 1;
				end
				if (tdir==1 and tvdir!=tdir and not EventHorizon.ClipBuffer[v:EntIndex()]) then
					EventHorizon.ClipBuffer[v:EntIndex()] = v
					v.___InBuffer = true;
				elseif (tdir==1 and tvdir==tdir and EventHorizon.ClipBuffer[v:EntIndex()]) then
					EventHorizon.ClipBuffer[v:EntIndex()] = nil
					v.___InBuffer = nil;
				elseif (tdir==-1 and tvdir!=tdir and not EventHorizon.AllBuffer[v:EntIndex()]) then
					EventHorizon.AllBuffer[v:EntIndex()] = v
					v.___InBuffer = nil;
					self:EndTouch(EventHorizon,v,true,tdir);
				end
			end

		end

		for _,v in pairs(attached.Attached) do

			if (IsValid(v) and IsValid(v:GetPhysicsObject()) and v:GetSolid()!=SOLID_NONE) then
				if (v.dir==tdir and not EventHorizon.ClipBuffer[v:EntIndex()]) then
					EventHorizon.ClipBuffer[v:EntIndex()] = v
					return
				elseif (v.dir!=tdir and EventHorizon.AllBuffer[v:EntIndex()]) then
					EventHorizon.ClipBuffer[v:EntIndex()] = nil
					notouch = true;
				end
			end
		end
	end

	if(IsValid(e.EventHorizonNoCollide)) then
		e.EventHorizonNoCollide:Remove();
	end

	if(e.___InBuffer and e.dir==tdir) then
		self.InBuffer[e] = true;
	else
		e.IsInGate = false;
		self.InBuffer[e] = nil;
	end

	EventHorizon.Buffer[e:EntIndex()] = nil
	EventHorizon.AllBuffer[e:EntIndex()] = nil
	EventHorizon.ClipBuffer[e:EntIndex()] = nil
	e:SetNWBool("PhysBuffered",false);
	e:SetNWInt("PhysBufferedDir",0);
	e.gate = nil;
	e:SetNWEntity("PhysEntity",NULL);

	e.___dir = nil;

	umsg.Start("StarGate.EventHorizon.ClipStop");
		umsg.Entity(e);
	umsg.End();

	if (not notouch) then
		if(IsValid(e:GetPhysicsObject())) then
			if (EventHorizon.GravBuffer[e:EntIndex()]!=nil) then
				e:GetPhysicsObject():EnableGravity(EventHorizon.GravBuffer[e:EntIndex()]);
				EventHorizon.GravBuffer[e:EntIndex()] = nil;
			end
		end
	end

	if(attached and not notouch) then
		for _,v in pairs(attached.Attached) do
			if (IsValid(v) and EventHorizon.AllBuffer[v:EntIndex()]) then
				self:EndTouch(EventHorizon,v,true)
			end
			if(not EventHorizon.AllBuffer[v:EntIndex()] and IsValid(v)) then
				if(IsValid(v:GetPhysicsObject())) then
					if (EventHorizon.GravBuffer[v:EntIndex()]!=nil) then
						v:GetPhysicsObject():EnableGravity(EventHorizon.GravBuffer[v:EntIndex()]);
						EventHorizon.GravBuffer[v:EntIndex()] = nil;
					end
				end
			end
		end
	end
end

--################ Destroy anthing in the EH's buffer @RononDex
function BUFFER:EmptyBuffer(EventHorizon)
	if(IsValid(EventHorizon)) then
		for k,v in pairs(self.InBuffer) do
			if(IsValid(k)) then
				if(k:IsPlayer() and not k:HasGodMode() or k:IsNPC()) then
					k:KillSilent();
				else
					k:Remove();
				end
			end
		end
	end
end

--############### What should we ignore @RononDex
function BUFFER:ClipShouldIgnore(ent,reset_cache)
	local class = ent:GetClass()
	if (table.HasValue(self.ClipIgnore,class) || table.HasValue(self.ClipIgnore,ent:GetModel()) || StarGate.RampOffset.Gates[ent:GetModel()] || ent.GateSpawnerSpawned || string.find(class,"stargate_") || ent.CAP_EH_NoTouch) then return true end
	if (reset_cache) then ent.__EHConstCache = nil; end
	if (ent.__EHConstCache!=nil) then return ent.__EHConstCache end
	-- adding cache for save performance
	ent.__EHConstCache = false;
	if (constraint.HasConstraints(ent)) then
		local entities = StarGate.GetConstrainedEnts(ent,2);
		if(entities) then
			for k,v in pairs(entities) do
				if(v:IsWorld()) then
					ent.__EHConstCache = true;
					return true;
				end
			end
		end
	end

	return false
end

local hook_added = false

function ENT:DoSecret(v)

	if (not hook_added) then
		hook.Add("PostPlayerDeath","Stargate.EH.Secret",function(ply)
			umsg.Start("StarGate.EventHorizon.SecretStop",ply);
			umsg.End();
		end)
		hook_added = true
	end

	umsg.Start("StarGate.EventHorizon.SecretStart",v);
	umsg.End();

	local old_pos = v:GetPos();
	local old_angles = v:EyeAngles();
	local old_velocity = v:GetVelocity();

	-- Store restore informations
	local restore ={
		MoveType=v:GetMoveType(),
		Solid=v:GetSolid(),
		Color = v:GetColor(),
		Bones = self:GetBones(v),
		RenderMode = v:GetRenderMode(),
		God = v:HasGodMode(),
	};
	-- Attach the Entity to the harvester
	v:SetRenderMode( RENDERMODE_TRANSALPHA );
	v:SetColor(Color(0,0,0,0));
	v:SetSolid(SOLID_NONE);
	v:SetMoveType(MOVETYPE_NONE);
	-- Now, let's change the bone's positions!
	-- Make players spectate the harvester
	if(v:IsPlayer()) then
		v.DisableSpawning = true; -- Can't spawn props
		v.DisableSuicide = true; -- Can't suicide
		v.DisableNoclip = true; -- Disallows him to move or change his movetypez
		v:Spectate(OBS_MODE_CHASE);
		v:SpectateEntity(self.Entity);
		v:DrawViewModel(false);
		v:DrawWorldModel(false);
		restore.Weapons={};
		for _,w in pairs(v:GetWeapons()) do
			table.insert(restore.Weapons,w:GetClass());
		end
		local w = v:GetActiveWeapon();
		if(w and w:IsValid()) then
			restore.ActiveWeapon = w:GetClass();
		end
		v:StripWeapons();
	end
	self.Ents[v] = restore;

	local k = v;
	local v = self.Ents[k];

	timer.Create("Stargate.EH.Secret.Out"..k:EntIndex(),7.0,1,function()
		if (not IsValid(k)) then return end

		if (not IsValid(self) or self.ShuttingDown and not self.ShuttingDownKill) then
			if (not k:HasGodMode()) then
				k:SetColor(v.Color);
				k:SetRenderMode(v.RenderMode);
				k:UnSpectate();
				k:DrawViewModel(true);
				k:DrawWorldModel(true);
				k:StripWeapons();
				k:KillSilent();
				timer.Simple(0.2,
					function()
						if(k and IsValid(k)) then
							k:SetColor(v.Color);
							k:SetRenderMode(v.RenderMode);
						end
					end
				);
				k.DisableSpawning = nil; -- Allow him again to spawn things
				k.DisableSuicide = nil; -- Allow him to commit suicide again
				k.DisableNoclip = nil;
				umsg.Start("StarGate.EventHorizon.SecretReset",k);
				umsg.End();
				umsg.Start("StarGate.EventHorizon.PlayerKill");
				umsg.Entity(k);
				umsg.End();
				return
			end
		end

		umsg.Start("StarGate.EventHorizon.SecretOut",k);
		umsg.End();

		-- Special settings for a player
		if(k:IsPlayer()) then
			k:SetParent(nil);
			k.DisableSpawning = nil; -- Allow him again to spawn things
			k.DisableSuicide = nil; -- Allow him to commit suicide again
			k.DisableNoclip = nil;
			k:UnSpectate();
			k:DrawViewModel(true);
			k:DrawWorldModel(true);
			-- AGP 2026-11-08: the same life goes on (Mimetisor disguise, armour and ammo stay), not a new one: AGP.ShipRespawnPilot
			if (AGP and AGP.ShipRespawnPilot) then AGP.ShipRespawnPilot(k) else k:Spawn() end
			if (v.God) then k:GodEnable() end
			-- Just to be 100% sure!
			-- FIXME: Does sometimes not work. Timer is NO SOLUTION as the fucking timer lags players
			for _,w in pairs(v.Weapons) do
				if(not k:HasWeapon(w)) then
					k:Give(w);
				end
			end
			-- This is a workaround for my own scripts. Using SelectWeapon two times (or just frequently) results into a spawnlag
			if(v.ActiveWeapon) then
				k.DefaultWeapon = v.ActiveWeapon;
				timer.Simple(0,
					function()
						-- We found out, WeaponManager is either in the wrong addon-load-order or not installed. So select it this way!
						if(k:IsValid() and k.DefaultWeapon) then
							k:SelectWeapon(k.DefaultWeapon);
							k.DefaultWeapon = nil;
						end
					end
				);
			end
		end
		-- General settings
		k:SetMoveType(v.MoveType);
		k:SetSolid(v.Solid);
		k:SetParent(nil); -- Again!
		k:SetPos(old_pos);
		k:SetEyeAngles(old_angles);
		k:SetColor(v.Color);
		k:SetRenderMode(v.RenderMode);
		local e = k;
		--Failsafe
		timer.Simple(0.2,
			function()
				if(e and IsValid(e)) then
					e:SetColor(v.Color);
					e:SetRenderMode(v.RenderMode);
				end
			end
		);
		-- Fix up the bones
		-- Now, let's change the bone's positions!
		-- Wake the entity up
		if(v.MoveType==MOVETYPE_VPHYSICS) then
			local phys=k:GetPhysicsObject();
			if(phys:IsValid()) then
				phys:EnableMotion(true);
				phys:Wake();
			end
		end

		if (IsValid(self)) then
			self:StartTouchPlayersNPCs(k,true)
			self.Ents[k]=nil;
		end
	end)
end


function ENT:PauseAllRouting()
	self.RoutingPaused = true
	for timer_name, timer_data in pairs(self.timer_table) do
		timer.Pause(timer_data) 
	end
end


function ENT:ResumeAllRouting()
	self.RoutingPaused = false
	for timer_name, timer_data in pairs(self.timer_table) do
    		timer.UnPause(timer_data) -- AGP 2026-11-10: with the time it had left (an Adjust here cut every ride to index/1.5 s)
	end
end

-- the wormhole ride (ENT:DoWormHole, ENT:AGPRideArrive): our own, modules/agp_ride.lua (2026-11-10; was EAP's DoWormHole /
-- MoveToTarget by Elanis)
