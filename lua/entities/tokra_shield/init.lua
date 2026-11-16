--[[
	Tokra Shield
	Copyright (C) 2011 Madman07
]]--

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("devices")) then return end

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("box.lua");
include("box.lua")

AddCSLuaFile("bullets.lua");
include("bullets.lua");

StarGate.Trace:Add("tokra_shield",
	function(e,values,trace,in_box)
		return true;
	end
);

ENT.CAP_NotSave = true;
ENT.Untouchable = true

-----------------------------------INIT----------------------------------

function ENT:Initialize()
	self.Entity:SetModel("models/Madman07/shields/box.mdl");
	self.Entity:PhysicsInit(SOLID_BBOX);
	self.Entity:SetMoveType(MOVETYPE_NONE);
	self.Entity:SetSolid(SOLID_BBOX);
	self.Entity:SetColor(Color(0,0,0,0));
	self.Entity:SetRenderMode(RENDERMODE_TRANSALPHA)
	self.Entity:SetCustomCollisionCheck(true);

	self.Initpos = self:GetPos()
	self.Initang = self:GetAngles()
	self.HitDelay = {};

	self.Enabled = false;
	self.RayModel = {};
	self:SetNWBool("DoClientSide", false)

end

-- the shield wall cannot be picked up with the physgun (one hook for all walls; it was re-added per wall under the
-- generic name "AllowPlayerPickup", so only the newest wall was protected and other addons' hooks could be replaced)
hook.Add("PhysgunPickup", "AGP.TokraShieldNoPickup", function(ply, ent)
	if (IsValid(ent) and ent:GetClass() == "tokra_shield") then return false end
end)

-----------------------------------COLLISION SCALE----------------------------------

function ENT:CreateCollision(Gen1, Gen2)
	if not IsValid(Gen1) then return end
	if not IsValid(Gen2) then return end
	-- AGP 2026-10-30: the wall was a SOLID_BBOX, i.e. a box along the world axes sized by the model, not turned with
	-- the doorway: bullets stopped in front of the door and shots at an angle went past it. Now a thin slab exactly
	-- between the two emitters, turned with them, and traces use it (custom collisions).
	local length = Gen1:GetPos():Distance(Gen2:GetPos());
	if (length < 2) then return end -- AGP: emitters on the same spot: no zero-size physics box (crash)
	local c1 = self.Entity:WorldToLocal(Gen1:LocalToWorld(Gen1:OBBMaxs()))
	local c2 = self.Entity:WorldToLocal(Gen2:LocalToWorld(Gen2:OBBMins()))
	local zmin, zmax = math.min(c1.z, c2.z), math.max(c1.z, c2.z)
	if (zmax - zmin < 40) then zmax = zmin + 130 end
	local mins, maxs = Vector(-length/2, -3, zmin), Vector(length/2, 3, zmax)
	self.WallMins, self.WallMaxs = mins, maxs

	self.Entity:PhysicsInitBox(mins, maxs)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_NONE)
	self.Entity:EnableCustomCollisions(true)
	self.Entity:SetCollisionBounds(mins, maxs)

	if(IsValid(self.Entity:GetPhysicsObject())) then
		self.Entity:GetPhysicsObject():EnableMotion(false)
	end

	self.Entity:SetNWInt("Len", length);
	self.Entity:SetNWVector("WallMins", mins)
	self.Entity:SetNWVector("WallMaxs", maxs)

	self:SetNWBool("DoClientSide", true);
end

function ENT:Think()
	if not IsValid(self.Gen1) or not IsValid(self.Gen2) then self:Remove() return end
	-- AGP: stay between the two emitters (it was reset to its first spot every 0.1 s and fought moved emitters)
	local p1, p2 = self.Gen1:GetPos(), self.Gen2:GetPos()
	local pos, ang = (p1 + p2) / 2, (p1 - p2):Angle()
	if (pos:DistToSqr(self:GetPos()) > 1 or math.abs(math.AngleDifference(ang.y, self:GetAngles().y)) > 0.5 or math.abs(math.AngleDifference(ang.p, self:GetAngles().p)) > 0.5) then
		self:SetPos(pos)
		self:SetAngles(ang)
	end

	self.Entity:NextThink(CurTime()+0.1)
	return true
end

-----------------------------------COLLISION----------------------------------

function ENT:Immunity(Gen1, Gen2)
	self.Gen1 = Gen1;
	self.Gen2 = Gen2;
end

function ENT:PhysicsCollide( data, physobj )
	local e = data.HitEntity
	if (self.HitDelay[e]) then return end -- give it some time to fly away

	local class = e:GetClass();
	if (class == "worldspawn" or self.Gen1 == e or self.Gen2 == e) then return end

	local velo = data.TheirOldVelocity;
	local normal = data.HitNormal;
	local pos = data.HitPos;

	local phys = e:GetPhysicsObject();
	 local strength = 1;
	if(phys and phys:IsValid()) then
		strength = math.ceil(phys:GetMass()*velo:Length()/10000);
	end

	self.HitDelay[e] = true;
	self:Reflect(e, velo, normal, pos);

	timer.Create("Delay"..e:EntIndex(),0.1,1, function() if IsValid(self) then self.HitDelay[e] = false; end end);

	 self:DrawBubbleEffect(pos, normal, strength, false, true);
end

-----------------------------------REFLECT----------------------------------

 function ENT:Reflect(e, velo, normal, pos)
	local IS_NPC = e:IsNPC();
	if(not IS_NPC and velo == Vector(0,0,0)) then return end; -- Not moving = no collision!
	local class = e:GetClass();
	local phys = e:GetPhysicsObject();

	//Props
	if(phys:IsValid() and not (IS_NPC or e:IsPlayer())) then
		//Anyone holds this object (Makes theses MingeBags unavailable to move props with physgun into the shield with the intention to exploit it)
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
		//Removes all old velocity from it before
		phys:EnableMotion(false);
		phys:EnableMotion(true);
		phys:Wake();
		//Now apply force!
		phys:ApplyForceOffset(normal*phys:GetMass()*1000,pos-20*normal);
	else
		local old_vel = e:GetVelocity():Length();
		e:SetLocalVelocity(-1*normal*old_vel*1.5);
		e:SetVelocity(-1*normal*old_vel*1.5);
	end
end

-----------------------------------EFFECT----------------------------------

function ENT:DrawBubbleEffect(pos, normal, strength, turn_off, hit)
	if (hit) then
		local fx = EffectData();
		fx:SetOrigin(pos);
		fx:SetEntity(self);
		fx:SetNormal(normal)
		fx:SetScale(strength);
		util.Effect("shield_core_hit",fx,true,true);
	end
 end

function ENT:Hit(e,pos,dmg,normal)
	self:DrawBubbleEffect(pos, normal, dmg, false, true);
	return true;
end

-----------------------------------NOTHING GETS THROUGH----------------------------------
-- AGP 2026-10-30: like the normal shields (AGP.ShieldStopsEverything in entities/shield/init.lua): anything moving
-- that crosses the wall inside the doorway is stopped there - explosives blow up on the wall, physics things bounce
-- off, other shots (bolts, arrows, plasma, addon projectiles) are destroyed. Bullets and players hit the solid slab.
local function stopAtWall(sh, e, k, side)
	local guard = AGP and AGP.ShieldGuard
	local n = sh:GetRight() * side -- points to the side it came from
	local lp = sh:WorldToLocal(e:WorldSpaceCenter())
	local hitpos = sh:LocalToWorld(Vector(lp.x, 0, lp.z))
	local back = hitpos + n * 20
	local class = e:GetClass()
	local phys = e:GetPhysicsObject()
	if (k == "x") then
		e:SetPos(back)
		sh:DrawBubbleEffect(hitpos, n, 10, false, true)
		if (isfunction(e.Blast) and class ~= "rpg_missile") then
			pcall(e.Blast, e, back)
		else
			local known = guard and guard.KNOWN[class]
			local dmg = math.Clamp(tonumber(istable(known) and known[2] or e.Damage) or 100, 0, 500)
			local rad = math.Clamp(tonumber(istable(known) and known[3] or e.Radius) or 200, 50, 600)
			local fx = EffectData(); fx:SetOrigin(back); util.Effect("Explosion", fx, true, true)
			local att = e:GetOwner()
			if (not IsValid(att) and e.CPPIGetOwner) then att = e:CPPIGetOwner() end
			if (dmg > 0) then util.BlastDamage(sh, IsValid(att) and att or sh, back, rad, dmg) end
		end
		if (IsValid(e)) then e:Remove() end
	elseif (k == "o" and IsValid(phys)) then
		local v = phys:GetVelocity()
		e:SetPos(e:GetPos() + (back - e:WorldSpaceCenter()))
		local vn = v:Dot(n)
		if (vn < 0) then v = v - 2 * vn * n end
		phys:SetVelocity(v * 0.5)
		sh:DrawBubbleEffect(hitpos, n, math.Clamp(math.ceil(phys:GetMass() * v:Length() / 20000), 1, 20), false, true)
	else
		local fx = EffectData(); fx:SetOrigin(hitpos); fx:SetNormal(n); fx:SetMagnitude(2); fx:SetScale(1); fx:SetRadius(4)
		util.Effect("Sparks", fx, true, true)
		sh:DrawBubbleEffect(hitpos, n, 5, false, true)
		e:Remove()
	end
end

local walls, wallsNext = {}, 0
hook.Add("Tick", "AGP.TokraWallStopsEverything", function()
	local guard = AGP and AGP.ShieldGuard
	if (not guard) then return end
	local now = CurTime()
	if (now > wallsNext) then wallsNext = now + 0.5; walls = ents.FindByClass("tokra_shield") end
	for i = 1, #walls do
		local sh = walls[i]
		if (IsValid(sh) and sh.WallMins) then
			local mins, maxs = sh.WallMins, sh.WallMaxs
			local last = sh.AGPSide
			if (not last) then last = setmetatable({}, { __mode = "k" }); sh.AGPSide = last end
			local c = sh:GetPos()
			local reach = math.max(maxs.x, maxs.z - mins.z) + 300
			for _, e in ipairs(ents.FindInSphere(c, reach)) do
				if (e ~= sh and e ~= sh.Gen1 and e ~= sh.Gen2 and IsValid(e) and e:GetVelocity():LengthSqr() > 4 and not guard.ignored(e)) then
					local k = guard.kind(e)
					if (k ~= "-" and not e:IsPlayerHolding()) then
						local lp = sh:WorldToLocal(e:WorldSpaceCenter())
						local side = lp.y >= 0 and 1 or -1
						local inDoor = lp.x > mins.x and lp.x < maxs.x and lp.z > mins.z - 8 and lp.z < maxs.z + 8
						local was = last[e]
						-- crossed the wall plane inside the doorway since the last tick (or is inside the slab)
						if (inDoor and was and (was ~= side or math.abs(lp.y) < 6)) then
							last[e] = nil
							stopAtWall(sh, e, k, was)
						elseif (math.abs(lp.y) >= 6) then
							last[e] = side
						end
					end
				end
			end
		end
	end
end)
