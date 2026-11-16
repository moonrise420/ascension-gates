--[[
	Shield Core Buble
	Copyright (C) 2011 Madman07
]]--

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("devices")) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.CAP_NotSave = true;
ENT.NoDissolve = true;
ENT.DoNotDuplicate = true

AddCSLuaFile("modules/bullets.lua");
AddCSLuaFile("modules/sphere.lua");
AddCSLuaFile("modules/box.lua");
AddCSLuaFile("modules/atlantis.lua");
include("modules/bullets.lua");
include("modules/sphere.lua")
include("modules/box.lua")
include("modules/atlantis.lua")

-- AGP: the collision rule (ShouldCollide), the player wall, the bullet check and the traceline condition are in
-- shared.lua now, so the client predicts the same (modules/collision.lua was server only and errored on the client).
local SC = AGP_SC

-----------------------------------INIT----------------------------------

function ENT:Initialize()
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS);
	self.Entity:SetSolid(SOLID_VPHYSICS);
	self.Entity:SetColor(Color(0,0,0,0));
	self.Entity:SetRenderMode(RENDERMODE_TRANSALPHA);
	self.Entity:SetCustomCollisionCheck(true);
	self.Entity:DrawShadow(false);

	self.Enabled = false;
	self.AGPAllowed = {}; -- AGP: who may be inside (was the nocollide list); set when the bubble goes up
	self.Depleted = false;

	self.Radius = 0.01;
	self.Size = Vector(1,1,1);
	self.RayModel = {};

	self.IsShieldCore = true;
	self.HitDelay = setmetatable({}, { __mode = "k" });
	self.AGPSeen = setmetatable({}, { __mode = "k" });
	self.AGPOut = setmetatable({}, { __mode = "k" });
	self.AGPFxNext = setmetatable({}, { __mode = "k" });
end

-- AGP: a big bubble must be known to every client (its centre can be out of sight while its edge is right in front)
function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

-----------------------------------COLLISION SCALE----------------------------------

function ENT:SetCollisionScale(model, size)
	local vect, vec;
	local convex = {}
	local ShieldModel;
	local mod = 1;

	if (model == "models/Madman07/shields/sphere.mdl") then ShieldModel = SphereModel;
	elseif (model == "models/Madman07/shields/box.mdl") then ShieldModel = BoxModel;  mod = 2;
	elseif (model == "models/Madman07/shields/atlantis.mdl") then ShieldModel = AtlantisModel;  mod = 3; end
	if (not ShieldModel) then ShieldModel = SphereModel; mod = 1; end

	for _, vertex in pairs(ShieldModel) do
		vec = Vector(vertex.x*size.x,vertex.y*size.y,vertex.z*size.z);
		vect = Vertex(vec, 1, 1, Vector( 0, 0, 1 ) )
		table.insert(convex, vect);
		table.insert(self.RayModel, vec);
	end

	if (#convex == 0) then return end //safefail

	self.Radius = math.max(size.x, size.y, size.z);
	self.Size = size*256;

	self.Entity:PhysicsFromMesh(convex)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS);
	self.Entity:SetSolid(SOLID_VPHYSICS);
	-- AGP: traces (bullets) and player movement use the mesh itself, not the tiny cube model in the middle
	-- (that was why players walked half way in and were pushed out slowly, and why everything could be shot through)
	self.Entity:EnableCustomCollisions(true);
	local phys = self.Entity:GetPhysicsObject();
	if (IsValid(phys)) then
		phys:EnableCollisions(true)
		phys:EnableMotion(false)
		phys:Sleep()
	end
	local ext = SC.Extent[mod];
	self:SetCollisionBounds(Vector(ext[1].x*size.x, ext[1].y*size.y, ext[1].z*size.z) - Vector(4,4,4), Vector(ext[2].x*size.x, ext[2].y*size.y, ext[2].z*size.z) + Vector(4,4,4));

	self:SetNWInt("PhysicModel", mod);
	self:SetNWVector("PhysicScale", size);
	self:SetNWBool("DoPhysicClientside", true);

	self:SetNWInt("SGESize",self.Radius);

	self:SetNWVector("TraceSize",self.Size);

	self:SetNotSolid(false);
	self.ShShap = mod;
	self.AGPShapeCache = { mod, Vector(size.x, size.y, size.z) };
end

function ENT:GetTraceSize()
	return self.Size;
end

-----------------------------------WHO MAY BE INSIDE (AGP)----------------------------------

local function isBody(e)
	return e:IsPlayer() or e:IsNPC() or (e.IsNextBot and e:IsNextBot()) or e:IsVehicle()
end

-- size of a body for the wall (half its width)
local function bodyPad(e)
	local mn, mx = e:OBBMins(), e:OBBMaxs()
	return math.max(mx.x - mn.x, mx.y - mn.y) * 0.5 + 2
end

-- tell the clients which players may pass (they predict the wall); props do not need it there
function ENT:AGPSyncAllowed()
	local ids = {}
	for e in pairs(self.AGPAllowed) do
		if (IsValid(e) and (e:IsPlayer() or e:IsVehicle())) then ids[#ids + 1] = e:EntIndex() end
	end
	table.sort(ids)
	local s = table.concat(ids, " ")
	if (#s > 190) then s = string.sub(s, 1, 190); s = string.match(s, "^(.*) ") or "" end -- NW strings are short
	self:SetNWString("NoCollideID", s);
	self:CollisionRulesChanged();
end

-- everything inside when the bubble goes up may stay (and leave); the core, its contraption and inherited ones too
function ENT:AGPCollectInside(inherit)
	local set = {}
	if (inherit) then for e in pairs(inherit) do if (IsValid(e)) then set[e] = true end end end
	local core = self.Parent
	if (IsValid(core)) then
		set[core] = true
		if (IsValid(core.Button)) then set[core.Button] = true end
		for _, c in pairs(constraint.GetAllConstrainedEntities(core) or {}) do if (IsValid(c)) then set[c] = true end end
	end
	for _, e in ipairs(ents.FindInSphere(self:GetPos(), SC.Reach(self))) do
		if (IsValid(e) and e ~= self and not e:IsWorld() and SC.Metric(self, e:WorldSpaceCenter(), 0) < 1) then
			set[e] = true
		end
	end
	for e in pairs(set) do -- weapons, attachments: what belongs to something inside
		for _, c in ipairs(e:GetChildren()) do if (IsValid(c)) then set[c] = true end end
	end
	self.AGPAllowed = set;
	self:AGPSyncAllowed();
end

-- things standing in the surface when it goes up (centre outside) are moved out a bit instead of being stuck in the
-- mesh or shot away by the physics engine
function ENT:AGPClearEdge()
	for _, e in ipairs(ents.FindInSphere(self:GetPos(), SC.Reach(self) + 96)) do
		if (IsValid(e) and e ~= self and not e:IsWorld() and not self.AGPAllowed[e] and not IsValid(e:GetParent())) then
			local ctr = e:WorldSpaceCenter()
			if (isBody(e)) then
				if (SC.OwnerPass(self, e)) then continue end -- the owner may stand in the surface
				if (not (e:IsPlayer() and (not e:Alive() or e:InVehicle()))) then
					local pad = bodyPad(e)
					if (SC.Metric(self, ctr, pad) < 1) then self:AGPPushOut(e, ctr, pad, true) end
				end
			elseif (e:GetMoveType() == MOVETYPE_VPHYSICS) then
				local ph = e:GetPhysicsObject()
				if (IsValid(ph) and ph:IsMotionEnabled() and not e:IsPlayerHolding()) then
					local pad = math.min(e:BoundingRadius(), 128) * 0.7
					if (SC.Metric(self, ctr, pad) < 1) then
						local out = SC.ExitPoint(self, ctr, pad + 2, SC.Normal(self, ctr, 0))
						if (out) then
							e:SetPos(e:GetPos() + (out - ctr))
							ph:SetVelocity(Vector(0, 0, 0))
							ph:Wake()
						end
					end
				end
			end
		end
	end
end

-- a hit flash with a zap where something touches the bubble (at most every 0.3 s per thing)
function SC.TouchFx(b, e, pos, normal)
	if (not IsValid(b) or not b.AGPFxNext) then return end
	local now = CurTime()
	if ((b.AGPFxNext[e] or 0) > now) then return end
	b.AGPFxNext[e] = now + 0.3
	timer.Simple(0, function() -- out of the movement code (effects and sounds there are not sent to the mover)
		if (not IsValid(b)) then return end
		b:DrawBubbleEffect(pos, normal, 5, false, true)
		local fx = EffectData()
		fx:SetOrigin(pos)
		fx:SetNormal(normal)
		fx:SetMagnitude(3); fx:SetScale(1); fx:SetRadius(6)
		util.Effect("StunstickImpact", fx, true, true)
		util.Effect("Sparks", fx, true, true)
		sound.Play("ambient/energy/zap" .. math.random(1, 3) .. ".wav", pos, 75, math.random(90, 110))
	end)
end

-- push a body out (horizontally from the centre first; another way when a wall is there)
function ENT:AGPPushOut(e, ctr, pad, quiet)
	pad = (pad or bodyPad(e)) + 6
	local c = SC.Centre(self)
	local d = ctr - c; d.z = 0
	if (d:LengthSqr() < 1) then d = self:GetForward(); d.z = 0 end
	if (d:LengthSqr() < 0.01) then d = Vector(1, 0, 0) end
	d:Normalize()
	local mins, maxs = e:OBBMins(), e:OBBMaxs()
	local toOrigin = e:GetPos() - ctr
	local tries = { d }
	for _, yaw in ipairs({ 45, -45, 90, -90, 135, -135, 180 }) do
		local v = Vector(d.x, d.y, 0); v:Rotate(Angle(0, yaw, 0)); tries[#tries + 1] = v
	end
	tries[#tries + 1] = Vector(0, 0, 1)
	local target, dir
	for _, t in ipairs(tries) do
		local q = SC.ExitPoint(self, ctr, pad, t)
		if (q) then
			local o = q + toOrigin
			local tr = util.TraceHull({ start = o, endpos = o, mins = mins, maxs = maxs, mask = MASK_PLAYERSOLID, filter = { e, self } })
			if (not tr.StartSolid) then target, dir = o, t break end
		end
	end
	if (not target) then -- nowhere free: at least out of the bubble
		local q = SC.ExitPoint(self, ctr, pad, d)
		if (not q) then return end
		target, dir = q + toOrigin, d
	end
	e:SetPos(target)
	local out = dir * 300 + Vector(0, 0, 80)
	if (e:IsPlayer()) then
		e:SetVelocity(out - e:GetVelocity())
	elseif (e:IsVehicle()) then
		local ph = e:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetVelocity(dir * 150) end
	else
		e:SetVelocity(out)
	end
	if (not quiet) then SC.TouchFx(self, e, target - toOrigin - dir * pad, dir) end
end

-----------------------------------STATUS----------------------------------

-- inherit: who was allowed in the bubble this one replaces (rebuild while on)
function ENT:Status(status, inherit)
	if status then
		if (self.Enabled) then return end
		self.Enabled = true;
		self.Depleted = false;
		self:SetNWBool("depleted", false);
		self:SetNotSolid(false);
		self:AGPCollectInside(inherit);
		self:SetNWBool("Enabled",true); // tracelines
		self:AGPClearEdge();
		self:CollisionRulesChanged();
		self.AGPSeen = setmetatable({}, { __mode = "k" });
		self.AGPOut = setmetatable({}, { __mode = "k" });
		self:DrawBubbleEffect(self:GetPos(), Vector(0,0,1), 1, false, false);
	else
		if (not self.Enabled) then return end
		self.Enabled = false;
		self.AGPAllowed = {};
		self:SetNWBool("Enabled",false);
		self:SetNotSolid(true);
		self:AGPSyncAllowed();
		self:DrawBubbleEffect(self:GetPos(), Vector(0,0,1), 1, true, false);
	end
end

-----------------------------------FOLLOW THE CORE / GUARD (AGP)----------------------------------

local MOVING_PROJ = { [MOVETYPE_FLY] = true, [MOVETYPE_FLYGRAVITY] = true }
-- the same sorting as the shield generator's bubble (entities/shield/init.lua), with a fallback if that is not loaded
local function kindOf(e)
	local G = AGP and AGP.ShieldGuard
	if (G and G.kind) then return G.kind(e) end
	local class = e:GetClass()
	if (class:find("missile", 1, true) or class:find("rocket", 1, true) or class:find("grenade", 1, true)) then return "x" end
	if (e:GetMoveType() == MOVETYPE_VPHYSICS and IsValid(e:GetPhysicsObject())) then return "o" end
	if (MOVING_PROJ[e:GetMoveType()]) then return "s" end
	return "-"
end
local function ignoredThing(e)
	local G = AGP and AGP.ShieldGuard
	if (G and G.ignored) then return G.ignored(e) end
	if (e.CAPOnShieldTouch or e.IsStargate or e.IsAvonShield or e.IsShieldCore) then return true end
	local mt = e:GetMoveType()
	return mt == MOVETYPE_NONE or mt == MOVETYPE_PUSH or mt == MOVETYPE_NOCLIP
end

function ENT:AGPFollow(core)
	local pos = core:LocalToWorld(core.Pos or Vector(0,0,0));
	local ang = core:GetAngles() + (core.Ang or Angle(0,0,0)); -- same as the bubble graphic (effects)
	local cur = self:GetPos();
	local ca = self:GetAngles();
	if (cur:DistToSqr(pos) < 0.04 and ca:Forward():Dot(ang:Forward()) > 0.99999 and ca:Up():Dot(ang:Up()) > 0.99999) then return false end
	self:SetPos(pos);
	self:SetAngles(ang);
	local ph = self:GetPhysicsObject();
	if (IsValid(ph)) then ph:SetPos(pos); ph:SetAngles(ang); ph:EnableMotion(false); ph:Sleep() end
	return true
end

-- loose props the moving bubble came over are moved out (not allowed inside), a few times a second
function ENT:AGPPushLoose()
	local now = CurTime()
	if ((self.AGPLooseNext or 0) > now) then return end
	self.AGPLooseNext = now + 0.1
	for _, e in ipairs(ents.FindInSphere(self:GetPos(), SC.Reach(self))) do
		if (IsValid(e) and e ~= self and not self.AGPAllowed[e] and not isBody(e) and e:GetMoveType() == MOVETYPE_VPHYSICS and not IsValid(e:GetParent())) then
			local ph = e:GetPhysicsObject()
			if (IsValid(ph) and ph:IsMotionEnabled() and not e:IsPlayerHolding() and not SC.Allowed(self, e)) then
				local ctr = e:WorldSpaceCenter()
				if (SC.Metric(self, ctr, 0) < 1) then
					local pad = math.min(e:BoundingRadius(), 128) * 0.7
					local out = SC.ExitPoint(self, ctr, pad + 2, SC.Normal(self, ctr, 0))
					if (out) then
						e:SetPos(e:GetPos() + (out - ctr))
						ph:SetVelocity(Vector(0, 0, 0))
						ph:Wake()
					end
				end
			end
		end
	end
end

-- a shot or thrown thing came in from outside: stop it at the surface
function ENT:AGPStop(e, k, outpos)
	local n = SC.Normal(self, outpos, 0)
	local hitpos = SC.SurfacePoint(self, outpos)
	local class = e:GetClass()
	if (k == "x") then
		local pos = hitpos + n * 16
		e:SetPos(pos)
		self:Hit(e, hitpos, 10, n)
		if (isfunction(e.Blast) and class ~= "rpg_missile") then
			pcall(e.Blast, e, pos)
		else
			local G = AGP and AGP.ShieldGuard
			local known = G and G.KNOWN and G.KNOWN[class]
			if (not istable(known)) then known = nil end
			local dmg = math.Clamp(tonumber(known and known[2] or e.Damage) or 100, 0, 500)
			local rad = math.Clamp(tonumber(known and known[3] or e.Radius) or 200, 50, 600)
			local fx = EffectData()
			fx:SetOrigin(pos)
			util.Effect("Explosion", fx, true, true)
			local att = SC.OwnerOf(e)
			if (dmg > 0) then util.BlastDamage(self, IsValid(att) and att or self, pos, rad, dmg) end -- inside is protected (damage hook below)
		end
		if (IsValid(e)) then e:Remove() end
	elseif (k == "o") then
		local phys = e:GetPhysicsObject()
		if (not IsValid(phys)) then return end
		local v = phys:GetVelocity()
		local strength = math.Clamp(math.ceil(phys:GetMass() * v:Length() / 20000), 1, 20)
		e:SetPos(e:GetPos() + (outpos - e:WorldSpaceCenter()))
		local vn = v:Dot(n)
		if (vn < 0) then v = v - 2 * vn * n end
		if (class ~= "prop_combine_ball") then v = v * 0.5 end
		phys:SetVelocity(v)
		self:Hit(e, hitpos, strength, n)
	else
		local fx = EffectData()
		fx:SetOrigin(hitpos)
		fx:SetNormal(n)
		fx:SetMagnitude(2); fx:SetScale(1); fx:SetRadius(4)
		util.Effect("Sparks", fx, true, true)
		self:Hit(e, hitpos, math.Clamp((tonumber(e.Damage) or 100) / 20, 1, 20), n)
		e:Remove()
	end
end

-- did the way from a (outside) to b (one tick) go into the bubble? Returns the point where it went in. A fast shot
-- crossing the thin low edge was outside at both ticks and never noticed.
local function crossed(b, a, p)
	local d = p - a
	local len = d:Length()
	if (len < 0.01) then return end
	d:Div(len)
	local t = SC.RayEnter(b, a, d, len)
	if (t) then return a + d * t end
	if (SC.Metric(b, p, 0) < 1) then return a end
end

function ENT:AGPGuard()
	local now = CurTime()
	local seen, outp, allowed = self.AGPSeen, self.AGPOut, self.AGPAllowed
	local dirty = false
	for _, e in ipairs(ents.FindInSphere(self:GetPos(), SC.Reach(self) + 256)) do
		if (IsValid(e) and e ~= self and not e:IsWorld() and e ~= self.Parent) then
			if (isBody(e)) then
				if (not (e:IsPlayer() and (not e:Alive() or e:InVehicle() or e:GetMoveType() == MOVETYPE_OBSERVER)) and not IsValid(e:GetParent())) then
					local ctr = e:WorldSpaceCenter()
					if (allowed[e]) then
						-- left the bubble: no way back in (unless the owner, or his friends with immunity)
						if (SC.Metric(self, ctr, bodyPad(e) + 8) > 1) then allowed[e] = nil; dirty = true end
					elseif (SC.OwnerPass(self, e)) then
						-- the owner walked in: his shots from in here go out (from outside they do not get in)
						if (SC.Metric(self, ctr, 0) < 1) then allowed[e] = true; dirty = true end
					elseif (not SC.Allowed(self, e) and SC.Metric(self, ctr, 0) < 1) then
						self:AGPPushOut(e, ctr) -- got in somehow (noclip, teleport, gate, immunity switched off): out
					end
				end
			elseif (not allowed[e] and not IsValid(e:GetParent()) and not ignoredThing(e)) then
				local sp = e:GetVelocity():LengthSqr()
				local tele = e.__StargateTeleport
				if (tele and tele.__LastTeleport and tele.__LastTeleport + 3 > now and e:GetMoveType() == MOVETYPE_VPHYSICS) then
					-- came through a stargate standing inside: pushed out (props built inside are never touched)
					local ctr = e:WorldSpaceCenter()
					if (SC.Metric(self, ctr, 0) < 1 and not SC.Allowed(self, e)) then
						local ph = e:GetPhysicsObject()
						local dir = ctr - SC.Centre(self); dir.z = 0
						if (dir:LengthSqr() < 1) then dir = self:GetForward() end
						dir:Normalize()
						local out = SC.ExitPoint(self, ctr, math.min(e:BoundingRadius(), 128) + 8, dir)
						if (out) then
							e:SetPos(e:GetPos() + (out - ctr))
							if (IsValid(ph)) then ph:SetVelocity(dir * 250) end
							self:DrawBubbleEffect(out, -dir, 1, false, true)
						end
					end
				elseif (sp > 4) then
					local k = kindOf(e)
					if (k ~= "-" and (sp > 22500 or e:GetMoveType() ~= MOVETYPE_VPHYSICS) and not e:IsPlayerHolding()) then
						local pos = e:WorldSpaceCenter()
						local was = seen[e] and seen[e] + 0.3 > now and outp[e]
						local outside = SC.Metric(self, pos, 0) >= 1
						if (outside and not (was and crossed(self, was, pos))) then
							seen[e] = now; outp[e] = pos
						elseif (was) then -- came in from outside just now (or flew through the edge since the last tick)
							seen[e] = nil
							if (SC.Allowed(self, e)) then
								allowed[e] = true -- shot by the owner (immunity) or by someone inside: may pass
							else
								self:AGPStop(e, k, outp[e])
							end
						end
					end
				end
			end
		end
	end
	if (dirty) then self:AGPSyncAllowed() end
end

function ENT:Think()
	local core = self.Parent
	if (not IsValid(core)) then self:Remove() return end
	local moved = self:AGPFollow(core)
	if (self.Enabled and not self.Depleted) then
		if (moved) then self:AGPPushLoose() end
		self:AGPGuard()
	end
	self:NextThink(CurTime())
	return true
end

-----------------------------------COLLISION----------------------------------

function ENT:PhysicsCollide( data, physobj )
	local e = data.HitEntity
	if (not self.Enabled or not IsValid(e) or e == self or e == self.Parent or e:IsWorld() or e:IsPlayer()) then return end -- players: the wall in shared.lua
	local now = CurTime()
	if ((self.HitDelay[e] or 0) > now) then return end -- give it some time to fly away
	if e.CoreNotCollide and e.CoreEntity == self then return end -- bullets?
	self.HitDelay[e] = now + 0.1

	local velo = data.TheirOldVelocity;
	local pos = data.HitPos;
	local normal = SC.Normal(self, e:WorldSpaceCenter(), 0); -- outward

	local phys = e:GetPhysicsObject();
	local strength = 5;
	if(IsValid(phys)) then
		strength = math.ceil(phys:GetMass()*velo:Length()/10000);
	end

	-- AGP: changing physics inside a collision callback is unsafe (crashes, objects shot away; a hit can also make the
	-- bubble collapse, which changes its collisions): do it right after
	timer.Simple(0, function()
		if (not IsValid(self) or not self.Enabled) then return end
		if (IsValid(e)) then self:Reflect(e, velo, normal, pos) end
		self:Hit(e, pos, strength, normal);
	end)
end

-----------------------------------REFLECT----------------------------------

-- normal: outward
function ENT:Reflect(e, velo, normal, pos)
	local IS_NPC = e:IsNPC();
	if(not IS_NPC and velo == Vector(0,0,0)) then return end; -- Not moving = no collision!
	local phys = e:GetPhysicsObject();

	-- Props
	if(IsValid(phys) and not (IS_NPC or e:IsPlayer())) then
		-- Anyone holds this object (Makes theses MingeBags unavailable to move props with physgun into the shield with the intention to exploit it)
		if(e:IsPlayerHolding()) then
			local id = e:EntIndex();
			phys:EnableMotion(false);
			timer.Create("SC_Ungrab"..id,0.2,25, -- AGP: limited (was endless)
				function()
					if(IsValid(e) and IsValid(phys)) then
						if(e:IsPlayerHolding() and timer.RepsLeft("SC_Ungrab"..id) > 0) then return end;
						phys:EnableMotion(true);
						phys:Wake();
					end
					timer.Remove("SC_Ungrab"..id);
				end
			);
			return;
		end
		-- AGP: bounce off gently (the old fixed push of 1000 x mass shot light props away)
		local v = velo
		local vn = v:Dot(normal)
		if (vn < 0) then v = v - 2 * vn * normal end
		v = v * 0.5 + normal * 60
		phys:Wake();
		phys:SetVelocity(v);
	else
		e:SetLocalVelocity(normal*300);
		e:SetVelocity(normal*300);
	end
end

-----------------------------------EFFECT----------------------------------

function ENT:DrawBubbleEffect(pos, normal, strength, turn_off, hit)
	if IsValid(self.Parent) then
		local origin = self:GetPos(); -- AGP: effects are only sent to players near their origin (was the map centre)
		if self.Parent.Draw then -- if Atlantis type
			if (not hit) then
				local fx = EffectData();
				fx:SetEntity(self.Parent);
				fx:SetOrigin(origin);
				if(turn_off) then
					fx:SetMagnitude(0);
				else
					fx:SetMagnitude(1);
				end
				util.Effect("shield_core_flash_atl",fx,true,true);
			else
				local fx = EffectData();
				fx:SetOrigin(pos);
				fx:SetEntity(self);
				fx:SetNormal(normal)
				fx:SetScale(strength);
				util.Effect("shield_core_hit_atl",fx,true,true);
			end

		else
			if (hit) then
				local fx = EffectData();
				fx:SetOrigin(pos);
				fx:SetEntity(self);
				fx:SetNormal(normal)
				fx:SetScale(strength);
				util.Effect("shield_core_hit",fx,true,true);
			end

			local fx = EffectData();
			fx:SetEntity(self.Parent);
			fx:SetOrigin(origin);
			if(turn_off) then
				fx:SetMagnitude(1);
			elseif(hit) then
				fx:SetMagnitude(2);
			else
				fx:SetMagnitude(0);
			end
			util.Effect("shield_core_flash",fx,true,true);
		end
	end
end

-----------------------------------HIT----------------------------------

-- Something hit the shield (beams, gate weapon, staff shots, bullets, blasts): it takes strength (Atlantis type: energy).
-- Returns true when the shield stopped it.
function ENT:Hit(e,pos,dmg,normal)
	local core = self.Parent
	if (not IsValid(core) or not self.Enabled or self.Depleted or core.Depleted) then return false end
	normal = normal or Vector(0,0,0);
	pos = pos or self:GetPos();
	dmg = tonumber(dmg) or 1;
	core:Hit(dmg,normal,pos);
	self:DrawBubbleEffect(pos, normal, dmg, false, true);
	if (not core.Atlantis and (core.Strength or 0) < 1 and core.AGPCollapse) then core:AGPCollapse() end
	return true
end

-----------------------------------BULLETS AND DAMAGE (AGP)----------------------------------

-- a bullet from outside stopped at the surface (the check is in shared.lua)
function SC.BulletHit(b, shooter, data, src, hit, dir)
	if ((data.Tracer or 1) ~= 0) then
		local fx = EffectData();
		fx:SetStart(src);
		fx:SetOrigin(hit);
		fx:SetScale(5000);
		fx:SetNormal(-dir);
		util.Effect(data.TracerName or "Tracer",fx,true,true);
	end
	local dmg = tonumber(data.Damage) or 0
	if (dmg <= 0 and data.AmmoType and game.GetAmmoID) then
		local id = game.GetAmmoID(data.AmmoType)
		if (id and id > 0) then dmg = (shooter:IsPlayer() and game.GetAmmoPlayerDamage(id) or game.GetAmmoNPCDamage(id)) or 0 end
	end
	if (dmg <= 0) then dmg = 10 end
	b:Hit(shooter, hit, math.max(1, dmg * (data.Num or 1) / 20), -dir)
end

-- Damage from outside does not reach inside (blasts, hitscan weapons that do not fire bullets, melee through the wall);
-- the shield takes it instead. Damage to the bubble itself drains it.
local drained = setmetatable({}, { __mode = "k" })
local function source(dmg, inflictor, attacker)
	if (dmg:IsExplosionDamage()) then
		local p = dmg:GetDamagePosition()
		if (p == vector_origin and IsValid(inflictor)) then p = inflictor:GetPos() end
		if (p ~= vector_origin) then return p end
	end
	if (IsValid(inflictor) and not inflictor:IsWorld() and inflictor ~= attacker and not inflictor:IsWeapon()) then return inflictor:WorldSpaceCenter() end
	if (IsValid(attacker) and not attacker:IsWorld()) then return attacker:IsPlayer() and attacker:EyePos() or attacker:WorldSpaceCenter() end
end
local function drain(b, key, src, dmg)
	key = IsValid(key) and key or b
	local now = CurTime()
	if ((drained[key] or 0) > now) then return end -- one hit per explosion, not one per thing inside
	drained[key] = now + 0.1
	local hp = SC.SurfacePoint(b, src)
	b:Hit(key, hp, math.max(1, dmg:GetDamage() / 10), SC.Normal(b, src, 0))
end
hook.Add("EntityTakeDamage", "AGP.ShieldCoreBlocksDamage", function(target, dmg)
	if (not IsValid(target)) then return end
	local L = SC.List()
	if (#L == 0) then return end
	local inflictor, attacker = dmg:GetInflictor(), dmg:GetAttacker()
	local src, srcDone
	for i = 1, #L do
		local b = L[i]
		if (IsValid(b) and SC.Active(b)) then
			if (target == b) then
				if (not srcDone) then src, srcDone = source(dmg, inflictor, attacker), true end
				if (inflictor ~= b and src and SC.Metric(b, src, 0) >= 1 and not SC.Allowed(b, attacker)) then
					drain(b, IsValid(inflictor) and inflictor or attacker, src, dmg)
				end
				return true -- the bubble itself never takes damage
			end
			local tc = target:WorldSpaceCenter()
			local r = SC.Reach(b)
			if (tc:DistToSqr(b:GetPos()) < r * r and SC.Metric(b, tc, 0) < 1) then
				if (not srcDone) then src, srcDone = source(dmg, inflictor, attacker), true end
				if (src and SC.Metric(b, src, 0) >= 1) then
					if (inflictor == b) then return true end -- our own blast at the surface (a stopped rocket)
					if (not (SC.Allowed(b, attacker) or SC.Allowed(b, inflictor))) then
						drain(b, IsValid(inflictor) and inflictor or attacker, src, dmg)
						return true
					end
				end
			end
		end
	end
end)

-- the bubble is not a thing to pick up or to use tools on
hook.Add("PhysgunPickup", "AGP.ShieldCoreBubbleNoPickup", function(ply, e) if (IsValid(e) and e:GetClass() == "shield_core_buble") then return false end end)
hook.Add("GravGunPickupAllowed", "AGP.ShieldCoreBubbleNoPickup", function(ply, e) if (IsValid(e) and e:GetClass() == "shield_core_buble") then return false end end)
hook.Add("CanTool", "AGP.ShieldCoreBubbleNoTool", function(ply, tr, tool) if (IsValid(tr.Entity) and tr.Entity:GetClass() == "shield_core_buble") then return false end end)

-- AGP: what is made inside an active bubble (shots of a turret or ship weapon placed in there later, grenades) belongs
-- inside like everything that was there when it went up: it may fly out. Players and NPCs are not (bodies: the wall).
hook.Add("OnEntityCreated", "AGP.ShieldCoreBornInside", function(e)
	timer.Simple(0, function()
		if (not IsValid(e) or isBody(e) or e:IsWorld() or e:GetClass() == "shield_core_buble") then return end
		local L = SC.List()
		for i = 1, #L do
			local b = L[i]
			-- well inside (not a fast shot from just outside that got in within the first tick), and not shot by a player outside
			if (IsValid(b) and SC.Active(b) and SC.Inside(b, e:WorldSpaceCenter(), -64)) then
				local who = SC.OwnerOf(e)
				if (IsValid(who) and who:IsPlayer() and not SC.Inside(b, who:WorldSpaceCenter())) then return end
				e.AGPBornIn = b
				e:CollisionRulesChanged()
				return
			end
		end
	end)
end)

-- AGP: small fast shots (staff pulses) can tunnel through a shield between two physics steps and explode inside
-- (shield cores: through the solid bubble; shield generators: noticed deep inside and waved through).
-- Every tick: remember where each pulse was last seen outside an active shield core; once it is inside, put it back
-- there and let it hit the shield. (Replaces CAP's GMod 12 damage hook, which no longer ran.)
-- Explosions from outside are blocked by AGP.ShieldCoreBlocksDamage above (cores) and AGP.ShieldBlocksBlasts
-- (shield generators, entities/shield/init.lua).
local pulses = {}
hook.Add("OnEntityCreated", "AGP.ShieldCoreTrackPulses", function(e)
	timer.Simple(0, function() if IsValid(e) and e.CAPOnShieldTouch then pulses[e] = true end end)
end)
hook.Add("Tick", "AGP.ShieldCoreCatchPulses", function()
	if (next(pulses) == nil) then return end
	local cores = SC.List()
	local bubbles = ents.FindByClass("shield")
	local G = AGP and AGP.ShieldGuard
	local now = CurTime()
	for e in pairs(pulses) do
		if (not IsValid(e)) then pulses[e] = nil continue end
		local pos = e:GetPos()
		-- where it was last tick: the whole way in between is checked, not only the two points (a fast pulse crossed
		-- the thin low edge of a bubble between two ticks and was never seen inside)
		local last = e.AGPPulseLast or pos
		e.AGPPulseLast = pos
		-- shield generator bubbles (spheres): a fast shot noticed deep inside was waved through as "spawned inside"
		for _, b in ipairs(bubbles) do
			local gen = b.Parent
			if (IsValid(gen) and not gen.Depleted and not gen.Containment and b.Size and not (b.nocollide and (b.nocollide[e] or (b.AGPShotMayPass and b:AGPShotMayPass(e:GetOwner()))))) then -- AGP: a shooter's pulses pass only while he is inside
				local c, r = b:GetPos(), b.Size
				if (pos:Distance(c) > r and b.AGPSeenOutside) then b.AGPSeenOutside[e] = now end -- Touch must not wave it through
				local hit = G and G.sphereEnter(last, pos, c, r)
				if (hit) then
					local dir = (hit - c):GetNormalized()
					e:SetPos(hit + dir * 6)
					if (b.Hit) then b:Hit(e, hit, math.Clamp((e.Damage or 200) / 20, 1, 20), dir) end
					pulses[e] = nil
					e:CAPOnShieldTouch(b)
					break
				end
			end
		end
		if (not IsValid(e) or not pulses[e]) then continue end
		for _, b in ipairs(cores) do
			if (IsValid(b) and SC.Active(b) and not (e.CoreNotCollide and e.CoreEntity == b) and not SC.Allowed(b, e)) then
				local hit = SC.Metric(b, last, 0) >= 1 and crossed(b, last, pos)
				if (hit) then   -- came from outside this tick: it hits the shell
					local n = SC.Normal(b, hit, 0)
					e:SetPos(hit + n * 6)
					b:Hit(e, SC.SurfacePoint(b, hit), math.Clamp((e.Damage or 200) / 20, 1, 20), n)
					pulses[e] = nil
					e:CAPOnShieldTouch(b)
					break
				end
			end
		end
	end
end)
