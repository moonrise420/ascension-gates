/*
	Stargate Shield for GarrysMod10
	Copyright (C) 2007  aVoN

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
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
AddCSLuaFile("modules/bullets.lua");
include("shared.lua");
include("modules/bullets.lua");

ENT.Sounds = {
	Hit=Sound("shields/shield_hit.mp3"),
	Hit2=Sound("shields/personal_impact.wav"),
	Hit3=Sound("weapons/underwater_explode4.wav"),
	Hit4=Sound("shields/shield_new_impact.wav")
};
ENT.NotTeleportable = true;
ENT.NoDissolve = true;
ENT.CAP_NotSave = true;
ENT.CDSIgnore = true; -- CDS Immunity
function ENT:gcbt_breakactions() end; ENT.hasdamagecase = true; -- GCombat invulnarability!

-- Register shield SENT to the trace class (everything else is handled in bullets.lua)
StarGate.Trace:Add("shield",
	function(e,values,trace,in_box)
		if(not e.Parent.Depleted) then
			if((e.Parent.Containment and in_box and e.AllowContainment) or ((not e.Parent.Containment or not e.AllowContainment) and not in_box)) then
				return true;
			end
		end
	end
);

--################# SENT CODE ###############

--################# Init @aVoN
function ENT:Initialize()
	self.Size = self.Size or 80; -- Make it by default at least fit for one player
	self.Created = CurTime();
	self.Entity:PhysicsInitSphere(self.Size); -- Seems even when it say "Sphere" to create a Cubic PhysObject
	self.Entity:SetSolid(SOLID_BBOX);
	self.Entity:SetMoveType(MOVETYPE_NONE);
	self.Entity:DrawShadow(false);
	self.Entity:SetTrigger(true); -- The most important thing: Makes the shield trigger Touch() events, even when it's not solid
	self.Entity:SetNotSolid(true);
	self.AllowContainment = StarGate.CFG:Get("shield","allow_containment",true);
	local offset = Vector(self.Size,self.Size,self.Size);
	self.Entity:SetCollisionBounds(-1*offset,offset);
	-- To be compatible to Catdaemons shield and/or my staffweapon, I will use the same Table name and method like he does
	self.nocollide = {};
	self.HasHitShield = {};
	self.Parent = self.Entity:GetParent();
	self.IsAvonShield = true;
	self.AntiNoclip = false;

	self.TraceSize = Vector(self.Size, self.Size, self.Size);
	self.Entity:SetNWVector("TraceSize",self.TraceSize);

	-- AGP: the owner may always walk in and out (not in a containment field without immunity) and shoot out from inside
	self:AGPAddOwner();
	-- Imunity to the owner?
	if(self.Parent.ImmuneOwner) then
		self.nocollide[self.Parent.Owner] = true;
		if CPPI then
			local owner = self.Parent.Owner;
			if(owner and owner:IsValid() and owner:IsPlayer() and owner.CPPIGetFriends) then
				local tbl = owner:CPPIGetFriends();
				if (type(tbl)=="table") then
					for k,v in pairs(tbl) do
						self.nocollide[v] = true;
					end
				end
			end
		end
	end
	self.Entity:SetNWInt("size",self.Size);
	if(self.Parent.DrawBubble) then
		-- Necessary for the bubble effect.
		local e = self.Entity;
		-- Wait a little time, until the NW data from above is synched with the client
		timer.Simple(0.3,
			function()
				if(e and e:IsValid()) then
					e:DrawBubbleEffect();
				end
			end
		);
	end
	local multi_shield = StarGate.CFG:Get("shield","multiple_shields",false); -- Allow multiple shields?
	--################# Fetch all things in a sphere to make it nocollide
	for _,v in pairs(ents.FindInSphere(self.Entity:GetPos(),self.Size)) do
		if(not multi_shield and v ~= self.Entity and v:GetClass() == "shield") then
			-- We are smaller - We have to go :(
			if(v.Size >= self.Size) then
				if (IsValid(self.Parent) and self.Parent.Status) then self.Parent:Status(false) end; -- satellites (Ori, Asuran) have no Status()
				self.Entity.Disable = true;
				self.Entity:Remove();
				return;
			else
				-- You are smaller! Yarhar, die!
				if (IsValid(v.Parent) and v.Parent.Status) then v.Parent:Status(false) end;
				v.Disable = true;
				v:Remove();
			end
		end
		self.nocollide[v] = true;
		v.CDSIgnore = true; -- Make it immuned to damage by CDS!
	end

	self.Passed = {};
	self:AddAthmosphere(); -- Add athmosphere to the shield (if turned on in on a planet or in an athmosphere)
	-- When we checked new things for "Collision or no Collision", we put them in here to be sure not to check again (speedup!)
	self.nocollide[game.GetWorld()] = true;
	-- Constrained? Add constrained entities to the list, but only do 10 passes to save performances (must fit for most contraptions)
	if(constraint.HasConstraints(self.Parent)) then
		local entities = StarGate.GetConstrainedEnts(self.Parent,10);
		if(entities) then
			for _,v in pairs(entities) do
				self.nocollide[v] = true;
				v.CDSIgnore = true; -- Make it immuned to damage by CDS!
			end
		end
	end
	-- Fixes a bug with "draw-on-passing". Sents who aren't awake do not trigger Touch! So wake them!
	for k,_ in pairs(self.nocollide) do
		if(k:IsValid()) then
			local phys = k:GetPhysicsObject();
			if(phys:IsValid()) then
				phys:Wake();
			end
		end
	end
	local phys = self.Entity:GetPhysicsObject()
	if(phys:IsValid()) then
		phys:EnableCollisions(false);
	end

	-- for pewpew and other addons
	local contaiment = false;
	if (self.AllowContainment and IsValid(self.Parent) and self.Parent.Containment) then contaiment = true end
	self:SetNWBool("containment",contaiment);
end

function ENT:IsContainment()
	if (self.AllowContainment and IsValid(self.Parent) and self.Parent.Containment) then
		return true
	end
	return false;
end

function ENT:GetTraceSize()
	return self.TraceSize;
end

--################# Owner and shots (AGP)
-- the player who owns the generator
function ENT:AGPOwner()
	local gen = self.Parent;
	if (not IsValid(gen)) then return end
	local own = gen.Owner;
	if (not (isentity(own) and IsValid(own)) and gen.CPPIGetOwner) then own = gen:CPPIGetOwner() end
	if (isentity(own) and IsValid(own) and own:IsPlayer()) then return own end
end

-- the owner may always walk in and out (a containment field keeps him in unless immunity is on)
function ENT:AGPAddOwner()
	local own = self:AGPOwner();
	if (own and not (self.Parent.Containment and self.AllowContainment)) then self.nocollide[own] = true end
end

-- may a shot of this shooter pass? Shots from inside go out; shots from outside do not get in, also not the owner's
-- or those of someone who was inside when the shield went up (immunity on: the owner's shots get in from outside too)
function ENT:AGPShotMayPass(own)
	if (not (isentity(own) and IsValid(own)) or own == self.Entity) then return false end
	-- AGP: a ship weapon of the generator's own ship (StarCore core, SpaceGrid hull, same parent) always shoots
	-- through, also from outside the bubble
	if (StarGate.IsShipWeapon and StarGate.IsShipWeapon(own) and StarGate.SameShip(own, self.Parent)) then return true end
	if (not self.nocollide[own]) then return false end
	if (self.Parent.ImmuneOwner and own:IsPlayer()) then
		local owner = self:AGPOwner();
		if (own == owner) then return true end
		local fr = owner and owner.CPPIGetFriends and owner:CPPIGetFriends();
		if (istable(fr) and table.HasValue(fr, own)) then return true end
	end
	return own:WorldSpaceCenter():Distance(self.Entity:GetPos()) < (self.Size or 0)
end

function ENT:GetFrequency()
	return self.Parent.Frequency;
end

function ENT:FindAShieldIdentifier(ent)
	for _, e in pairs(constraint.GetAllConstrainedEntities(ent)) do
		if e:GetClass() == "shield_identifier" then
			if e:Enabled() then
				self.ShieldIdentifier = e;
				return true;
			end
		end
	end
	return false;
end

function ENT:GetFrequencyOfShieldIdentifier()
	if IsValid(self.ShieldIdentifier) then
		return self.ShieldIdentifier:GetFrequency();
	end
end

--################# Prevent PVS bug/drop of all networkes vars (Let's hope, it works) @aVoN
function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end;

--################# Draw bubble effect, when turning it off @aVoN
function ENT:OnRemove()
	self:RemoveAthmosphere();
	self.GettingDeleted = true;
	for v,_ in pairs(self.nocollide) do
		if(IsValid(v)) then
			v.CDSIgnore = nil; -- Remove CDS immunity from the props again!
		end
	end
	if(IsValid(self.Parent) and not self.Parent.Depleted) then
		-- Has to be drawn on the shield emitter!
		self.DrawBubbleEffect(self.Parent,true);
	end
end

--################# StartTouch @aVoN
function ENT:StartTouch(e)
	if(not IsValid(self.Parent)) then return end;
	if(not IsValid(e)) then return end;
	if not self.nocollide[e] and self:FindAShieldIdentifier(e)/* and (self.Parent:GetFrequency() ~= 0)*/ and self.Parent.GetFrequency and (self:GetFrequencyOfShieldIdentifier() == self.Parent:GetFrequency()) then
		self.RemoveAfterPass = constraint.GetAllConstrainedEntities(e);
		for _,entity in pairs(constraint.GetAllConstrainedEntities(e)) do
			self.nocollide[entity] = true; -- the whole contraption of the identifier may pass
		end
	end
	-- This starts the effect on players who own the shield, but won't reflect them
	if (e:GetClass()=="ascend_ball") then
		self.Parent.Strength = -1
	end
	if(self.Parent.Containment and self.AllowContainment) then
		self.nocollide[e] = true;
	end
	if(self.nocollide[e]) then
		e.CDSIgnore = true; -- Make it immuned to damage by CDS!
	end

	if(self.Parent.ImmuneOwner and e == self.Parent.Owner) then
		self:HitEffect(e,e:LocalToWorld(e:OBBCenter()),5);
	elseif(self.Parent.PassingDraw and (self.nocollide[e] or (self.Parent.Containment and self.AllowContainment))) then
		if(self.Created + 0.2 < CurTime()) then
			-- Fixes a bug, where the "Draw on Passing" effect appears just right after the shield depleted and its now loaded with full strength (activbated) again
			if(self.HasHitShield[e]) then return end;
			self.HasHitShield[e] = true;
			-- When something is allowed to pass the shield, shall the effect be drawn?
			self:HitEffect(e,e:LocalToWorld(e:OBBCenter()),5,true);
		end
	end
end

--################# When something got into the shield and is "reflected constantly" we don't want it to take energy more than one time
function ENT:EndTouch(e)
	if(self.GettingDeleted) then return end; -- Prevents the "Draw on Passing" effect, if a shield is getting depleted (Stops client crashing)
	if(not IsValid(self.Parent)) then return end;
	if(self.Parent.Depleted) then return end; -- Prevents the "Draw on Passing" effect, if a shield is getting depleted (Stops client crashing)
	self.HasHitShield[e] = nil;
	if self.RemoveAfterPass then
		for _,ent in pairs(self.RemoveAfterPass) do
			self.nocollide[ent] = false;
		end
	end
	-- Fixes a few bugs: E.g. if you delete a prop it will call this function before it is invalid => It will draw the "DrawOnPassing" effect but the prop is deleted.
	timer.Simple(0,
		function()
			if(not IsValid(self) or not IsValid(self.Parent) or not e:IsValid()) then return end;
			-- This starts the effect on players who own the shield, but won't reflect them
			if(self.Parent.ImmuneOwner and e == self.Parent.Owner) then
				self:HitEffect(e,e:LocalToWorld(e:OBBCenter()),5);
			elseif(self.nocollide[e]) then
				e.CDSIgnore = nil; -- Remove CDS immunity!
				if(self.Parent.Containment and self.AllowContainment) then
					self:Touch(e,true);
				elseif(self.Parent.PassingDraw) then
					self:HitEffect(e,e:LocalToWorld(e:OBBCenter()),5,true);
				end
			end
		end
	);
end

--################# The most important part - Recognizes entering props and reflects them @aVoN
function ENT:Touch(e,override)
	-- fix for player, when touch shield, it will be like sphere, not box.
	if not e.IgnoreShield and IsValid(e) and not override and e:GetPos():Distance(self.Entity:GetPos())>self.Size then self:EndTouch(e); self:StartTouch(e); return end
	-- it have small bug in containment mode (player sucks into the shield as box), maybe later will fix

	if(not e or (self.nocollide[e] and not override) or e.IgnoreShield) then return end;

	if(not self.Parent:IsValid()) then
		self.Entity:Remove();
		return;
	end
	if(self.Parent.Containment and self.AllowContainment and not override) then return end;

	if(self.Passed and not self.Passed[e]) then
		self.Passed[e] = true;
		local parent = e:GetParent();
		if(
			not e:IsValid() or -- Not valid - HUH? How did this then touched us?
			self:AGPShotMayPass(e:GetOwner()) or self.nocollide[parent] or -- For shots started from the inside like CombineBalls (AGP: only while the shooter is inside)
			((e:GetPos()-self.Entity:GetPos()):Length() <= self.Size/2 and not (self.AGPSeenOutside and (self.AGPSeenOutside[e] or 0) + 0.5 > CurTime())) or -- Entity collided just inside the shield, and that in half-radius - In most cases, owner of the shield spawned it @aVoN -- AGP: not when it was seen outside a moment ago (fast shots)
			IsValid(parent) -- Do not reflect parented props - Simply ignore them!
		) then
			self.nocollide[e] = true;
			e.CDSIgnore = true; -- Add CDS immunity!
			return;
		end
	end
	-- Bounce
	if(self.Parent.Strength > 0) then
		local cons_check = ((e.LastConstraintCheck or 0)+2 < CurTime());
		self:Reflect(e,not cons_check);
		-- Reflect a bit more (like ships )- so they won't take the complete energy of a shield when colliding and it will "really" get reflected (more force)
		if(constraint.HasConstraints(e) and cons_check) then
			local time = CurTime();
			local entities = StarGate.GetConstrainedEnts(e,3); -- Maxcheck 3 seems to be OK
			for _,v in pairs(entities) do
				if(v ~= e) then
					self:Reflect(v,true);
				end
				v.LastConstraintCheck = time;
			end
		end

		-- for support another addons/ents
		if (e.CAPOnShieldTouch) then
			e:CAPOnShieldTouch(self);
		end

		-- cartman300 code, edited by AlexALX
		if self.AntiNoclip then
	        if (e:IsPlayer() and e:GetMoveType()==MOVETYPE_NOCLIP) then
	            e:SetMoveType(MOVETYPE_WALK)
	            timer.Simple(0.2, function()
	            	if (IsValid(e)) then
	                	e:SetMoveType(MOVETYPE_NOCLIP)
	              	end
	            end);
	        end
	    end

		if(e:GetClass() == "lvs_bomb" or e:GetClass() == "lvs_missile" or e:GetClass() == "lvs_protontorpedo") then --proper lvs support because their missiles go through shields
			e:SetRadius(1)
			e:Detonate(self)
		end
	else
		-- Make the shield not touching anything anymore when enegry = 0
		if(not self.Parent.Depleted) then
			self:DrawBubbleEffect(true); -- Set turnoff effect
			self.Parent:EmitSound(self.Parent.Sounds.Disengage,90,math.random(90,110));
			self.Parent.Depleted = true;
			self.Entity:SetNWBool("depleted",true); -- For the traceline class - Clientside
			self.Entity:SetTrigger(false);
			self:RemoveAthmosphere();
		end
	end
end

--################# Reflect the thing @aVoN
function ENT:Reflect(e,do_not_draw_hit)
	local velo = e:GetVelocity();
	local IS_NPC = e:IsNPC();
	if(not IS_NPC and velo == Vector(0,0,0)) then return end; -- Not moving = no collision!
	local class = e:GetClass();
	local e_pos = e:LocalToWorld(e:OBBCenter());
	local pos = self.Entity:GetPos();
	local phys = e:GetPhysicsObject();
	local normal = (e_pos-pos):GetNormalized();
	if(self.Parent.Containment) then normal = -1*normal end; -- It's a containment field. Don't let anyone out!
	-- First, we trigger the Entity's Touch trigger and make sure, the shield and the entity are synchronized (Makes staffblasts explode where they hit the shield)
	if(e.Touch) then e:Touch(self.Entity) end
	if(e.StartTouch) then e:StartTouch(self.Entity) end;
	-- Now, we will override the Entitiy's ENT:PhysicsSimulate() function for a moment (To e.g. reflect Catdaemons shuttle or other SENTs which otherwise wouldn't get reflected)
	if(e.PhysicsSimulate and not e.AlreadyOverwritten) then
		local old_PhysicsSimulate = e.PhysicsSimulate;
		e.AlreadyOverwritten = true;
		e.PhysicsSimulate = function() end;
		-- Reset old
		timer.Simple(1,
			function()
				if(e and e:IsValid()) then
					e.PhysicsSimulate = old_PhysicsSimulate;
					e.AlreadyOverwritten = nil;
				end
			end
		);
	end
	-- Props
	if(phys:IsValid() and not (IS_NPC or e:IsPlayer())) then
		-- Anyone holds this object (Makes theses MingeBags unavailable to move props with physgun into the shield with the intention to exploit it)
		if(e:IsPlayerHolding()) then
			local id = e:EntIndex();
			phys:EnableMotion(false);
			timer.Create("Ungrab"..id,0.2,0,
				function()
					if(e and phys and e:IsValid() and phys:IsValid()) then
						if(e:IsPlayerHolding()) then return end;
						phys:EnableMotion(true);
						phys:Wake();
					end
					timer.Destroy("Ungrab"..id);
				end
			);
			return;
		end
		-- Removes all old velocity from it before
		phys:EnableMotion(false);
		phys:EnableMotion(true);
		phys:Wake();
		-- Now apply force!
		phys:ApplyForceOffset(normal*phys:GetMass()*1000,e_pos-20*normal);
	elseif(class == "rpg_missile") then
		e:SetLocalVelocity(normal*1000);
		e:SetAngles(normal:Angle());
		e:SetHealth(0); -- Take his health
		-- Shoot a bullet on it (Catdaemons Idea), to make it fall down
		self.Entity:FireBullets({Num=1,Src=e_pos,Dir=Vector(0,0,0),Spread=Vector(0,0,0),Tracer=0,Force=1,Damage=100});
		e.IgnoreShield = true; -- Do not register it anymore
	else
		local vel = normal*600;
		if(class=="crossbow_bolt") then
			vel = normal*1000;
		end
		e:SetLocalVelocity(vel);
	end
	-- Make the player killable by his own shot
	if(class == "crossbow_bolt" or class == "rpg_missile" or class == "prop_combine_ball") then
		e:SetOwner(self.Entity);
	end
	if(not do_not_draw_hit) then
		self:HitShield(e,e_pos,phys,class,normal,e.FireFrequency or 0);
	end
end

--################# Draws an hiteffect, drains energy and makes the baseprop "wobbly" @aVoN
function ENT:HitShield(e,pos,phys,class,normal,fireFrequency,softsound)
	-- Zapping
	local fx = EffectData();
	fx:SetStart(e:GetPos());
	fx:SetOrigin(pos);
	fx:SetScale(10);
	fx:SetMagnitude(10);
	fx:SetEntity(e);
	util.Effect("TeslaHitBoxes",fx,true,true);
	-- Hit effect
	if(not self.HasHitShield[e]) then
		self.HasHitShield[e] = true;
		local strength = 5;
		if(phys and phys:IsValid()) then
			strength = math.ceil(phys:GetMass()*e:GetVelocity():Length()/20000);
		end

		if (e:GetClass()=="dakara_wave") then
			
			strength = 1

		end

		-- Draw the hiteffect- But in that function.
		self:HitEffect(e,pos,strength,softsound);
		-- Drain energy
		if(not (e:IsNPC() or e:IsPlayer() or class=="rpg_missile")) then
			self.Parent:Hit(strength,normal,pos,fireFrequency or 0,StarGate.ShieldFactor and StarGate.ShieldFactor(e,self.Parent) or 1); -- AGP: agp_weapon_balance
		end
	end
end

--################# Draw the Hit Effect @aVoN
function ENT:HitEffect(e,pos,strength,softsound)
	if (e:GetClass()=="dakara_wave") then
		strength = 20
	end
	-- Hit sound
	local time = CurTime();
	if((self.NextSound or 0) < time) then
		if (softsound)then
			sound.Play(self.Sounds.Hit2,pos,math.random(70,100),math.random(90,110));
			self.NextSound = time +math.random(2,9)/10;
		else
			local pitch = math.random(90,110)
			sound.Play(self.Sounds.Hit4,pos,380,pitch,1);
			sound.Play(self.Sounds.Hit4,pos,380,pitch,1);
			self.NextSound = time +math.random(1,2)/10;
		end
	end
	-- Draw the hiteffect- But in that function.
	local shield = self.Entity;
	local function draw_effect(shield)
		if(IsValid(shield)) then
			local fx = EffectData();
			fx:SetOrigin(pos);
			fx:SetEntity(shield);
			fx:SetScale(strength);
			util.Effect("shield_hit",fx,true,true);
			shield:DrawBubbleEffect(_,true);
		end
	end
	if(e and IsValid(e) and e:IsPlayer()) then
		timer.Simple(0.1,function() draw_effect(shield) end); -- Let's hope this fixes the shield not beeing drawn, when you run against it in multiplayer. It did for me for my gore addon (same problems)
	else
		draw_effect(shield);
	end
end

--################# Draw a bubble effect @aVoN
function ENT:DrawBubbleEffect(turn_off,hit)
	-- First one is when we delete this SENT, or it will throw an error (there is no self.Parent on shield_generator)
	if(self.DrawBubble or (IsValid(self.Parent) and self.Parent.DrawBubble)) then
		local fx = EffectData();
		fx:SetOrigin(self.Entity:GetPos());
		fx:SetEntity(self.Entity);
		fx:SetScale(self.Size);
		if(turn_off) then
			fx:SetMagnitude(1);
		elseif(hit) then
			fx:SetMagnitude(2);
		else
			fx:SetMagnitude(0);
		end
		util.Effect("shield_engage",fx,true,true);
	end
end

--################# Adds an athmosphere to the shield @aVoN
function ENT:AddAthmosphere()
	-- Really, I don't like SB2 overriding these things (self.planet). Lemmi guess: It's doing this in a think... :(
	if(SB_Add_Environment and not self.Athmosphere and self.Parent.planet) then
		-- The enviroment must be set on the Parent, or self.Parent.planet will return this new enviroment instead of the "real" planet
		self.Athmosphere = SB_Add_Environment(self.Parent,self.Size,self.Parent.gravity,1,1,288);
	end
end

--################# Adds an athmosphere to the shield @aVoN
function ENT:RemoveAthmosphere()
	if(self.Athmosphere) then
		SB_Remove_Environment(self.Athmosphere);
		self.Athmosphere = nil;
	end
end

--################# As requested, add an athmosphere to the shield, when it's turned on (on a planet!) @aVoN
function ENT:Think()
	if (IsValid(self.Parent) and self.Parent.AntiNoclip != nil) then
		self.AntiNoclip = self.Parent.AntiNoclip
	end
	if(SB_Update_Environment and self.Athmosphere) then
		local gravity = 0;
		if(self.Parent.planet) then gravity = self.Parent.gravity or 0 end;
		SB_Update_Environment(self.Athmosphere,self.Size,gravity,1,1,288);
		self.Entity:NextThink(CurTime()+1);
		return true;
	end
end

--################# The hit function (for external usage) @aVoN
function ENT:Hit(e,pos,dmg,normal,fireFrequency)
	if(not self.Parent.Depleted) then
		if(self.Parent.Strength > 0) then
			normal = normal or Vector(0,0,0);
			self:HitEffect(e,pos,dmg);
			if(dmg and dmg ~= 0) then
				self.Parent:Hit(dmg,normal,pos,fireFrequency or 0,StarGate.ShieldFactor and StarGate.ShieldFactor(e,self.Parent) or 1); -- AGP: agp_weapon_balance
			end
			return true;
		else
			self:DrawBubbleEffect(true); -- Set close effect (we are depleted!
			self.Parent:EmitSound(self.Parent.Sounds.Disengage,90,math.random(90,110));
			self.Parent.Depleted = true;
			self.Entity:SetNWBool("depleted",true); -- For the traceline class - Clientside
			self.Entity:SetTrigger(false);
			self:RemoveAthmosphere();
		end
	end
end

--################# Explosions from outside do not reach inside an active shield (AGP)
-- Pulses, drones and beams explode at the shield surface; util.BlastDamage ignores the non-solid bubble, so their
-- blast hurt everything inside near the edge. Block that damage and let the shield take the hit instead.
local blastHits = setmetatable({}, { __mode = "k" }) -- one shield hit per explosion, not one per thing inside
hook.Add("EntityTakeDamage", "AGP.ShieldBlocksBlasts", function(target, dmg)
	if (not dmg:IsExplosionDamage() or not IsValid(target)) then return end
	local src = dmg:GetDamagePosition();
	local inflictor = dmg:GetInflictor();
	if (src == vector_origin and IsValid(inflictor)) then src = inflictor:GetPos() end
	if (src == vector_origin) then return end
	local tpos = target:WorldSpaceCenter();
	-- AGP: blasts of a ship weapon's shots pass the shields of its own ship (and do not drain them)
	local from = StarGate.ShotFrom and (StarGate.ShotFrom(inflictor) or StarGate.ShotFrom(dmg:GetAttacker()));
	for _, sh in ipairs(ents.FindByClass("shield")) do
		local gen = sh.Parent;
		if (IsValid(gen) and not gen.Depleted and not gen.Containment and sh.Size and not (from and StarGate.SameShip(from, gen))) then
			local c, r = sh:GetPos(), sh.Size;
			if (tpos:Distance(c) < r and src:Distance(c) > r - 30) then -- target inside, explosion outside
				local key = IsValid(inflictor) and inflictor or sh;
				if (sh.Hit and (blastHits[key] or 0) < CurTime() and (sh.AGPBlastCounted or 0) < CurTime()) then
					blastHits[key] = CurTime() + 0.1;
					sh:Hit(inflictor, c + (src - c):GetNormalized() * r, math.max(1, dmg:GetDamage() / 10));
				end
				return true;
			end
		end
	end
	-- shield cores: AGP.ShieldCoreBlocksDamage in entities/shield_core_buble/init.lua (exact shape, all damage from outside)
end);

--################# The "ultimate shield": nothing dangerous flies in (AGP)
-- Touch() alone let fast things through: crossbow bolts, RPG rockets, combine balls and other shots were first noticed
-- deep inside and waved through as "spawned inside", or slipped between two physics steps. Now every tick each active
-- bubble looks at what moves near its edge. Whatever was outside a moment ago and is inside now, and may not be inside
-- (not inside when the shield went up, not shot from inside), is stopped at the surface:
--   explosives (rockets, grenades, bombs, drones, addon missiles) blow up there - the blast does not reach inside,
--   see AGP.ShieldBlocksBlasts above;
--   physics things (props, combine balls) bounce off;
--   other shots (bolts, arrows, flechettes, projectile entities of other addons) are destroyed.
-- Players, NPCs and vehicles are still handled by Touch() (pushed back), staff/Ha'tak pulses by the pulse catcher in
-- shield_core_buble/init.lua. Cheap: one FindInSphere per active shield per tick, a few checks per moving thing.
local MOVING_PROJ = { [MOVETYPE_FLY] = true, [MOVETYPE_FLYGRAVITY] = true }
local KNOWN = { -- class = { explodes, damage, radius } ; damage 0 = only removed
	rpg_missile = { true, 150, 200 }, apc_missile = { true, 100, 200 }, grenade_ar2 = { true, 100, 250 },
	npc_grenade_frag = { true, 125, 250 }, grenade_helicopter = { true, 150, 300 }, npc_satchel = { true, 150, 250 },
	crossbow_bolt = { false }, hunter_flechette = { false }, grenade_spit = { false }, npc_grenade_bugbait = { false },
	prop_combine_ball = { false }, ascend_ball = "skip",
}
local EXPLOSIVE_NAMES = { "missile", "rocket", "grenade", "rpg", "bomb", "torpedo", "mortar", "nade", "explosive", "warhead", "nuke" }
local SHOT_NAMES = { "bolt", "arrow", "projectile", "bullet", "shell", "plasma", "flechette", "spit", "dart", "spear", "shot", "laser" }

-- what kind of thing is it? "x" explodes, "s" a shot (destroyed), "o" a physics thing (bounces), "-" left to Touch()
local function kind(e)
	local k = e.AGPShieldKind
	if (k) then return k end
	local class = e:GetClass()
	local known = KNOWN[class]
	if (known == "skip") then k = "-"
	elseif (known) then k = known[1] and "x" or (class == "prop_combine_ball" and "o" or "s")
	elseif (isfunction(e.Blast) or isfunction(e.Detonate) or isfunction(e.Explode)) then k = "x"
	else
		for _, n in ipairs(EXPLOSIVE_NAMES) do if (class:find(n, 1, true)) then k = "x" break end end
		if (not k and e:GetMoveType() == MOVETYPE_VPHYSICS and IsValid(e:GetPhysicsObject())) then k = "o" end
		if (not k and MOVING_PROJ[e:GetMoveType()]) then k = "s" end
		if (not k) then for _, n in ipairs(SHOT_NAMES) do if (class:find(n, 1, true)) then k = "s" break end end end
		k = k or "-"
	end
	e.AGPShieldKind = k
	return k
end

-- never stopped here (Touch or other code handles them, or they belong to the world/the shield)
local function ignored(e)
	if (e:IsPlayer() or e:IsNPC() or e:IsNextBot() or e:IsVehicle() or e:IsRagdoll() or e:IsWorld()) then return true end
	if (e.CAPOnShieldTouch or e.IsStargate or e.IsAvonShield or e.IsShieldCore or e.Type == "vehicle") then return true end
	if (IsValid(e:GetParent())) then return true end
	local mt = e:GetMoveType()
	if (mt == MOVETYPE_NONE or mt == MOVETYPE_PUSH or mt == MOVETYPE_NOCLIP) then return true end
	return false
end

-- did the way from a to b (one tick) go into the sphere c, r? Fast shots crossing the thin low edge of a bubble were
-- outside at both ticks and never noticed. Returns the point where it went in.
local function sphereEnter(a, b, c, r)
	if (a:DistToSqr(c) <= r * r) then return end
	local d = b - a
	local len = d:Length()
	if (len < 0.01) then return end
	d:Div(len)
	local oc = a - c
	local bq = oc:Dot(d)
	local disc = bq * bq - (oc:LengthSqr() - r * r)
	if (disc < 0) then return end
	local t = -bq - math.sqrt(disc)
	if (t < 0 or t > len) then return end
	return a + d * t
end

-- the shield core bubble (entities/shield_core_buble/init.lua) sorts things the same way
AGP = AGP or {}
AGP.ShieldGuard = { kind = kind, ignored = ignored, KNOWN = KNOWN, sphereEnter = sphereEnter }

local function stopAt(sh, gen, e, k, outpos, c, r)
	local dir = outpos - c
	if (dir:LengthSqr() < 1) then dir = -e:GetVelocity() end
	dir:Normalize()
	local hitpos = c + dir * (r + 4)
	local class = e:GetClass()
	local phys = e:GetPhysicsObject()
	if (k == "x") then
		-- blow it up at the surface
		local pos = c + dir * (r + 16)
		e:SetPos(pos)
		sh:HitEffect(e, hitpos, 10)
		-- AGP: the shield takes the hit (once). Before, only the blast drained it, and only when the blast reached
		-- something inside: drones and missiles at a big ship's bubble never brought it down.
		if (not e.AGPShieldDrained and sh.Hit) then
			e.AGPShieldDrained = true
			sh.AGPBlastCounted = CurTime() + 0.2   -- (not again from its blast: AGP.ShieldBlocksBlasts)
			local knownX = KNOWN[class]
			sh:Hit(e, hitpos, math.Clamp((tonumber(knownX and knownX[2] or e.Damage) or 100) / 20, 1, 20), dir)
		end
		if (isfunction(e.Blast) and class ~= "rpg_missile") then
			pcall(e.Blast, e, pos) -- drones and other Lua explosives use their own blast
		else
			local known = KNOWN[class]
			local dmg = math.Clamp(tonumber(known and known[2] or e.Damage) or 100, 0, 500)
			local rad = math.Clamp(tonumber(known and known[3] or e.Radius) or 200, 50, 600)
			local fx = EffectData()
			fx:SetOrigin(pos)
			util.Effect("Explosion", fx, true, true)
			local att = e:GetOwner()
			if (not IsValid(att) and e.CPPIGetOwner) then att = e:CPPIGetOwner() end
			if (dmg > 0) then util.BlastDamage(sh, IsValid(att) and att or sh, pos, rad, dmg) end -- inside is protected by AGP.ShieldBlocksBlasts
		end
		if (IsValid(e)) then e:Remove() end
	elseif (k == "o" and IsValid(phys)) then
		-- bounce off (back where it was a moment ago, velocity mirrored at the surface)
		local v = phys:GetVelocity()
		local strength = math.Clamp(math.ceil(phys:GetMass() * v:Length() / 20000), 1, 20)
		e:SetPos(outpos)
		local vn = v:Dot(dir)
		if (vn < 0) then v = v - 2 * vn * dir end
		if (class ~= "prop_combine_ball") then v = v * 0.5 end
		phys:SetVelocity(v)
		sh:Hit(e, hitpos, strength, dir)
	else
		-- a shot: gone
		local fx = EffectData()
		fx:SetOrigin(hitpos)
		fx:SetNormal(dir)
		fx:SetMagnitude(2); fx:SetScale(1); fx:SetRadius(4)
		util.Effect("Sparks", fx, true, true)
		sh:Hit(e, hitpos, math.Clamp((tonumber(e.Damage) or 100) / 20, 1, 20), dir)
		e:Remove()
	end
end

local guardList, guardNext = {}, 0
hook.Add("Tick", "AGP.ShieldStopsEverything", function()
	local now = CurTime()
	if (now > guardNext) then guardNext = now + 0.5; guardList = ents.FindByClass("shield") end
	for i = 1, #guardList do
		local sh = guardList[i]
		local gen = IsValid(sh) and sh.Parent
		if (IsValid(gen) and sh.Size and sh.nocollide and not sh.GettingDeleted and not gen.Depleted and not gen.Containment and (gen.Strength or 1) > 0) then
			local c, r = sh:GetPos(), sh.Size
			local seen, outpos = sh.AGPSeenOutside, sh.AGPOutPos
			if (not seen) then
				seen = setmetatable({}, { __mode = "k" }); outpos = setmetatable({}, { __mode = "k" })
				sh.AGPSeenOutside, sh.AGPOutPos = seen, outpos
			end
			local nocol = sh.nocollide
			for _, e in ipairs(ents.FindInSphere(c, r + 256)) do
				if (e ~= sh and e ~= gen and not nocol[e] and IsValid(e)) then
					local sp = e:GetVelocity():LengthSqr()
					if (sp > 4 and not ignored(e)) then
						local k = kind(e)
						-- physics things only when fast (slow ones: Touch pushes them back), never one a player holds
						if (k ~= "-" and (sp > 22500 or e:GetMoveType() ~= MOVETYPE_VPHYSICS) and not e:IsPlayerHolding()) then
							local pos = e:WorldSpaceCenter()
							local was = seen[e] and seen[e] + 0.3 > now and outpos[e]
							-- outside, but flew through the edge since the last tick: same as coming in
							local through = was and pos:Distance(c) > r and sphereEnter(was, pos, c, r)
							if (pos:Distance(c) > r and not through) then
								seen[e] = now; outpos[e] = pos
							elseif (was) then -- came in from outside just now
								seen[e] = nil
								if (sh:AGPShotMayPass(e:GetOwner())) then
									nocol[e] = true -- shot from inside, came back: may pass
								else
									stopAt(sh, gen, e, k, outpos[e], c, r)
								end
							end
						end
					end
				end
			end
		end
	end
end)
