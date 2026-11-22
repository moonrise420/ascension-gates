--[[
	Replicator block (Ascension Gates): one grey block. Free blocks crawl towards each other; 12 close together form a
	Replicator (lua/autorun/agp_replicators.lua). Shooting only knocks them around; the anti-replicator gun or the Dakara
	weapon kills them: then they go dark, stop moving and fade.
	A lone block (no other block near, setting agp_rep_lone_grow) with metal next to it slowly builds itself from that
	metal: more and more blocks grow on it (the metal is used up), until it is a small Replicator that goes looking for more
	metal - and with enough it grows into a full one. No metal near: it waits.
]]
local function L(key, fallback, ...)
	if (AGP and AGP.L) then return AGP.L(key, fallback, ...) end
	return fallback
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = L("agp_ent_rep_block", "Replicator Block")
ENT.Author = "Ascension Gates"
ENT.Category = "Replicators"
ENT.Spawnable = false   -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
ENT.AGPReplicator = true
ENT.RenderGroup = RENDERGROUP_BOTH   -- the arcs are translucent
list.Set("CAP.Entity", ENT.PrintName, ENT)

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.Hit) then return end
		-- one click = one block
		local first = AGP.Rep.SpawnBlock(tr.HitPos + tr.HitNormal * 8, nil, ply, 3)
		if (not first) then AGP.Hint(ply, "agp_rep_full", "Too many Replicator blocks on the server (setting agp_rep_max_blocks).") end
		if (first) then
			AGP.Hint(ply, "agp_rep_hint_block", "12 Replicator blocks close together form a Replicator. Shooting only knocks them apart - the anti-replicator gun (ARG) kills them.")
		end
		return first
	end

	function ENT:Initialize()
		self:SetModel(AGP.Rep.MODEL_BLOCK)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)   -- players walk through the pile, bullets still hit
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetMass(3); ph:SetMaterial("metal"); ph:Wake() end
		AGP.Rep.blocks[self] = true
		self.RepRest = self.RepRest or CurTime() + 2
	end

	-- growing alone: every few seconds one more block on it; after 8 it walks off as a small Replicator
	function ENT:Think()
		local R = AGP.Rep
		local now = CurTime()
		-- gliding towards other blocks: smoothly over the ground, like drawn by a magnet (set by the swarm, agp_replicators.lua)
		if (self.RepGlideTo and now < (self.RepGlideUntil or 0) and not self.RepClaimed and not self.RepDead and R.Awake()) then
			self:NextThink(now + 0.1)
			local ph = self:GetPhysicsObject()
			-- (the point lies on something that moves - a flying ship's deck: it moves with it)
			local to = self.RepGlideTo
			if (self.RepGlideL and IsValid(self.RepGlideOn)) then to = self.RepGlideOn:LocalToWorld(self.RepGlideL) end
			local d = to - self:GetPos(); d.z = 0
			local dist = d:Length()
			if (IsValid(ph) and ph:IsMotionEnabled() and dist > 18) then
				-- floating a hand's breadth above the ground (no friction, no hopping), drawn on smoothly
				local tr = util.TraceLine({ start = self:GetPos() + Vector(0, 0, 20), endpos = self:GetPos() - Vector(0, 0, 60), filter = self, mask = MASK_SOLID })
				local hz = tr.Hit and (tr.HitPos.z + 4 - self:GetPos().z) or -2
				local v = ph:GetVelocity()
				local want = d / dist * math.Clamp(dist * 1.2, 30, 110)
				ph:Wake()
				ph:EnableGravity(false)
				ph:SetVelocity(Vector(Lerp(0.4, v.x, want.x), Lerp(0.4, v.y, want.y), math.Clamp(hz * 4, -60, 40)))
				ph:SetAngleVelocity(ph:GetAngleVelocity() * 0.7)
				self.Gliding = true
			elseif (self.Gliding and IsValid(ph)) then
				self.Gliding = nil; ph:EnableGravity(true)
			end
			return true
		end
		self:NextThink(now + 1)
		if (self.Gliding) then   -- not drawn any more: it settles down
			self.Gliding = nil
			local ph = self:GetPhysicsObject()
			if (IsValid(ph)) then ph:EnableGravity(true); ph:Wake() end
		end
		if (now < (self.NextGrowCheck or 0)) then return true end
		self.NextGrowCheck = now + 3
		if (self.RepDead or self.RepClaimed or not R.cv.lonegrow:GetBool() or not R.Awake()) then return true end
		if ((self.RepRest or 0) > CurTime() + 1e8) then return true end   -- left as loose blocks for good (agp_rep_rebuild 0)
		-- (the swarm timer saw others within 110 a moment ago: not alone. Only a fresh count: a block the timer no longer lists keeps an old one)
		if ((self.RepNear or 1) >= 2 and now - (self.RepNearT or 0) < 2.5) then self.GrowT = nil; self:SetNWInt("RepGrow", 0) return true end
		for _, e in ipairs(ents.FindInSphere(self:GetPos(), 300)) do
			if (e ~= self and e.AGPReplicator and not e.RepDead) then self.GrowT = nil; self:SetNWInt("RepGrow", 0) return true end
		end
		self.GrowT = self.GrowT or CurTime() + 10   -- a short wait first: maybe others come
		if (CurTime() < self.GrowT) then return true end
		-- it grows only from metal right next to it, and uses it up
		local food
		for _, e in ipairs(ents.FindInSphere(self:GetPos(), 160)) do
			if (R.Edible(e)) then food = e break end
		end
		if (not food) then return true end
		local fph = food:GetPhysicsObject()
		food.RepLeft = food.RepLeft or math.Clamp(math.floor((IsValid(fph) and fph:GetMass() or 40) / 20), 2, 3000)
		food.RepLeft = food.RepLeft - 0.25   -- 8 steps = 2 blocks' worth: one barrel is enough for a small Replicator
		local fx = EffectData(); fx:SetOrigin(food:NearestPoint(self:GetPos())); fx:SetNormal(VectorRand()); fx:SetMagnitude(1); fx:SetScale(1); fx:SetRadius(2)
		util.Effect("MetalSpark", fx, true, true)
		if (food.RepLeft <= 0 and not food.AGPShip and not R.IsShip(food) and not R.ShipCore(food)) then R.AteMapItem(food); food:Remove() end
		local g = self:GetNWInt("RepGrow", 0) + 1
		self:SetNWInt("RepGrow", g)
		self.GrowT = CurTime() + 5
		if (g >= 8 and not R.Full()) then
			local m = ents.Create("agp_replicator")
			if (not IsValid(m)) then return true end
			m:SetPos(self:GetPos() + Vector(0, 0, 4))
			m:SetAngles(Angle(0, math.random(0, 359), 0))
			m.RepOwner, m.RepMini, m.RepParentMind = self.RepOwner, true, self.RepMind
			m:Spawn(); m:Activate()
			self:EmitSound("agp_replicator/rep_assemble.wav", 65, 125, 0.6)
			self:Remove()
		end
		return true
	end

	function ENT:OnRemove()
		AGP.Rep.blocks[self] = nil
		timer.Remove("AGPRepFade" .. self:EntIndex())
	end

	-- the ARG / Dakara: dead block, never moves again, fades out
	function ENT:AGPDisrupt(freq)
		if (self.RepDead) then return end
		if (freq and AGP.Rep.ArgAdapted(self.RepOwner, freq)) then return end   -- adapted to the gun's frequency
		self.RepDead = true
		AGP.Rep.blocks[self] = nil
		if (self.RepBridge and AGP.Rep.BridgeBreak) then AGP.Rep.BridgeBreak(self.RepBridge) end   -- (a block of a bridge: the beam lets go)
		self:SetNWBool("RepDead", true)
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:Wake(); ph:SetVelocity(VectorRand() * 30) end
		self:SetRenderMode(RENDERMODE_TRANSCOLOR)
		local t0 = CurTime()
		timer.Create("AGPRepFade" .. self:EntIndex(), 0.1, 0, function()
			if (not IsValid(self)) then return end
			local a = 255 - (CurTime() - t0 - 6) * 60
			if (a <= 0) then self:Remove() return end
			self:SetColor(Color(70, 72, 78, math.Clamp(a, 0, 255)))
		end)
	end

	function ENT:OnTakeDamage(dmg)
		if (dmg:IsDamageType(DMG_DISSOLVE)) then self:AGPDisrupt() return end
		-- (a Destiny shot into a heap: a blast of 830 damage threw every 3-mass block hundreds of metres through the
		-- physics engine, 480 of them at once, and they were far apart when they had to find each other again. A strong
		-- hit now pushes it a clamped amount away from the blast instead)
		if (dmg:GetDamage() > 40) then
			local ph = self:GetPhysicsObject()
			if (IsValid(ph)) then
				local away = self:WorldSpaceCenter() - dmg:GetDamagePosition()
				away.z = away.z + 20
				if (away:LengthSqr() < 1) then away = VectorRand() end
				away:Normalize()
				ph:Wake()
				ph:AddVelocity(away * math.Clamp(dmg:GetDamage() * 0.5, 60, 320))
			end
			return
		end
		self:TakePhysicsDamage(dmg)
	end
end

if CLIENT then
	-- electric arcs to the block it is drawn to (jagged, flickering, a few at a time)
	local BEAM = Material("sprites/physbeama")
	local function arc(a, b)
		local d = b - a
		local n = 6
		render.StartBeam(n + 1)
		for i = 0, n do
			local p = a + d * (i / n)
			if (i > 0 and i < n) then p = p + VectorRand() * math.min(4, d:Length() * 0.08) end
			render.AddBeam(p, math.Rand(0.6, 1.6), i / n, Color(150, 205, 255, 230))
		end
		render.EndBeam()
	end
	function ENT:DrawTranslucent()
		local l = self:GetNWEntity("RepLink")
		if (IsValid(l) and math.random() < 0.55 and l:GetPos():DistToSqr(self:GetPos()) < 800 * 800) then
			render.SetMaterial(BEAM)
			arc(self:WorldSpaceCenter(), l:WorldSpaceCenter())
			if (math.random() < 0.3) then arc(self:WorldSpaceCenter(), l:WorldSpaceCenter()) end
		end
	end

	-- the blocks growing on a lone block: a small body forming, piece by piece
	local GROW = {
		{ Vector(0, 3.2, 0.9), Angle(0, 0, 0) }, { Vector(0, -3.2, 0.9), Angle(0, 0, 0) }, { Vector(0, 0, 1.8), Angle(0, 90, 0) },
		{ Vector(3.6, 2, -0.2), Angle(-20, 60, 0) }, { Vector(-3.6, 2, -0.2), Angle(20, -60, 0) },
		{ Vector(3.6, -2.5, -0.2), Angle(-20, 120, 0) }, { Vector(-3.6, -2.5, -0.2), Angle(20, -120, 0) }, { Vector(0, 5.5, 2), Angle(15, 0, 0) },
	}
	function ENT:Draw()
		self:DrawModel()
		local g = self:GetNWInt("RepGrow", 0)
		self.ClParts = self.ClParts or {}
		for i = 1, #GROW do
			local p = self.ClParts[i]
			if (i <= g) then
				if (not IsValid(p)) then
					p = ClientsideModel(self:GetModel(), RENDERGROUP_OPAQUE)
					p:SetNoDraw(true); p:SetModelScale(0.85)
					self.ClParts[i] = p
				end
				p:SetPos(self:LocalToWorld(GROW[i][1])); p:SetAngles(self:LocalToWorldAngles(GROW[i][2]))
				p:DrawModel()
			elseif (IsValid(p)) then p:Remove(); self.ClParts[i] = nil end
		end
	end
	function ENT:OnRemove()
		for _, p in pairs(self.ClParts or {}) do if (IsValid(p)) then p:Remove() end end
	end
end
