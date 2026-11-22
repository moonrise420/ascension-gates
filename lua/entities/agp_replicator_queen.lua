--[[
	Replicator Queen (Ascension Gates): a big Replicator with 8 legs and a hollow brood chamber at the back. She stays
	near the place she was put, builds a new block every few seconds (much faster with the metal her bugs bring her) and
	pushes it out of the chamber; 12 blocks together become a Replicator. Hurt her and every bug of her swarm attacks the
	attacker for 30 s. 800 health; shot apart she breaks into many blocks (they form bugs, no new Queen).
]]
local function L(key, fallback, ...)
	if (AGP and AGP.L) then return AGP.L(key, fallback, ...) end
	return fallback
end

ENT.Type = "anim"
ENT.Base = "agp_replicator"
ENT.PrintName = L("agp_ent_rep_queen", "Replicator Queen")
ENT.Author = "TaurWing (model), Ascension Gates"
ENT.Category = "Replicators"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AGPReplicator = true
list.Set("CAP.Entity", ENT.PrintName, ENT)
if (CLIENT) then language.Add("agp_replicator_queen", ENT.PrintName) end   -- the kill feed's name for her

ENT.RepModel = "models/agp_replicator/agp_replicator_queen.mdl"
ENT.RepKind = "queens"
ENT.RepHealth = 800
ENT.RepSpeed = 52             -- (45 before)
ENT.RepTurn = 70
ENT.RepBite = 25
ENT.RepReach = 70
ENT.RepSight = 500
ENT.RepSmell = 0            -- does not hunt metal herself: her bugs bring it
ENT.RepBlocks = 36
ENT.RepMass = 600
ENT.RepStride = 24
ENT.RepSwing = 16
ENT.RepLift = 12
ENT.RepLegs = { "leg_l1", "leg_l2", "leg_l3", "leg_r1", "leg_r2", "leg_r3" }
ENT.RepFeet = false   -- (not nil: that falls through to the bug's table. The bug's hips and feet are not hers: her legs keep the plain walking pose)
ENT.RepGait = { leg_l1 = 0, leg_r2 = 0, leg_l3 = 0, leg_r1 = 1, leg_l2 = 1, leg_r3 = 1 }   -- tripod gait
ENT.RepLeap = false
ENT.RepClimb = false        -- too heavy for walls: she stays on the ground
ENT.RepFallBreak = 1400
-- the hum IS her walking sound now, as fast as she walks; standing she is quiet
--
ENT.RepWalkSound = "agp_replicator/rep_queen_loop.wav"
ENT.RepWalkLevel = 70
ENT.RepTurnSound = false   -- (the small ones' turning chirp is not hers)
ENT.RepBuildTime = 5        -- seconds per block without metal
ENT.RepBuildFast = 0.8      -- seconds per block while she has metal

if SERVER then
	AddCSLuaFile()
	local R = AGP.Rep
	local BASE = baseclass.Get("agp_replicator")

	function ENT:Initialize()
		BASE.Initialize(self)
		self.RepHome = self:GetPos()
		self.NextBuild = CurTime() + 2
		self:EmitSound("agp_replicator/rep_queen_born.wav", 85, 100, 0.9)
	end

	function ENT:SpawnFunction(ply, tr) return R.SpawnSent(self, ply, tr) end
	function ENT:UseStock() end   -- her metal is used by Build

	-- the open end of the brood chamber (the back of the model)
	function ENT:RepBroodPos()
		local mn, mx = self:OBBMins(), self:OBBMaxs()
		return self:LocalToWorld(Vector(mn.x + 8, 0, (mn.z + mx.z) * 0.5))
	end

	function ENT:AddStock(n)
		self.RepStock = self.RepStock + (n or 0)
	end

	-- builds blocks in the brood chamber and pushes them out at the back
	function ENT:Build(now)
		if (now < self.NextBuild) then return end
		local fast = self.RepStock > 0
		-- the power the swarm has eaten (ZPMs, generators, shields) makes her build faster (sv_tactics.lua)
		self.NextBuild = now + (fast and self.RepBuildFast or self.RepBuildTime) / (R.PowerBoost and R.PowerBoost(self.RepOwner) or 1)
		if (R.Full() or not R.RoomForBlocks(R.BLOCKS_PER_BUG)) then return end   -- (R.Full: also while the game is behind)
		if (fast) then self.RepStock = self.RepStock - 1 end
		-- on the deck of a flying ship: no loose blocks (the ship moves each of them every tick - a player's laggy Queen
		-- aboard); the brood is counted and a whole new Replicator is built aboard, fixed to the deck
		local deck = self:FlyingDeck(self:GetPos())
		if (deck) then
			self.AboardBrood = (self.AboardBrood or 0) + 1
			if (self.AboardBrood >= R.BLOCKS_PER_BUG) then
				self.AboardBrood = 0
				self.RepStock = self.RepStock + R.BLOCKS_PER_BUG
				self:BuildAboard(deck)
				R.Stat("queen: built aboard a flying ship")
			else
				self:EmitSound("agp_replicator/rep_build.wav", 70, math.random(95, 110), 0.5)
			end
			return
		end
		local back = self:RepBroodPos()
		local out = -self:GetForward() * 120 + VectorRand() * 40 + Vector(0, 0, 80)
		local b = R.SpawnBlock(back, out, self.RepOwner, 2)
		if (b) then
			self:EmitSound("agp_replicator/rep_build.wav", 70, math.random(95, 110), 0.7)
			local fx = EffectData(); fx:SetOrigin(back); fx:SetNormal(-self:GetForward()); fx:SetMagnitude(1); fx:SetScale(1); fx:SetRadius(3)
			util.Effect("Sparks", fx, true, true)
		end
	end

	-- a hidden place far from every player - the swarm's map knows covered spots; if it knows none yet, the best
	-- covered of a few spots away from them. Her guards go with her. A player near again (or seeing her): on.
	--
	function ENT:FindHiding(now, pos)
		local players, near = {}, 99999
		for _, p in ipairs(player.GetAll()) do
			if (p:Alive()) then players[#players + 1] = p:GetPos(); near = math.min(near, p:GetPos():Distance(pos)) end
		end
		if (#players == 0) then return end
		if (self.HideGo and now - (self.HideT or 0) < 60) then return end   -- (on her way: she keeps to it)
		-- (found or close: not hidden any more - she looks again; the old check only asked the swarm's map whether the
		-- place had ever been seen, a player standing in front of her did not count)
		local exposed = near < 1200 or self:SeenByPlayer(pos)
		if (self.Hidden and not exposed) then return end
		if (exposed) then self.Hidden = false end
		-- pressed (a player close) or nowhere to hide on this side: away by rings or a gate, if a sure way is there
		local spot = R.Map.HideSpot(pos, players, 500, 4000)
		if (spot and math.abs(spot.z - pos.z) > 80) then spot = nil end   -- (up on a roof or down a pit: she cannot climb)
		if ((near < 1000 or not spot) and now > (self.NextEscape or 0) and R.QueenEscape) then
			self.NextEscape = now + 120
			if (R.QueenEscape(self, now)) then self.HideGo = nil return end
		end
		if (not spot) then
			-- (like in the series she hides where she is not seen - a covered corner nearby, not across open ground:
			-- cover and out of sight count most, distance from them only up to a point)
			local best, bs
			for _ = 1, 16 do
				local a = math.random() * math.pi * 2
				local c = pos + Vector(math.cos(a), math.sin(a), 0) * math.Rand(600, 2200)
				local tr = util.TraceLine({ start = c + Vector(0, 0, 200), endpos = c - Vector(0, 0, 2000), mask = MASK_SOLID_BRUSHONLY })
				if (tr.Hit and not tr.StartSolid and tr.HitNormal.z > 0.7 and util.IsInWorld(tr.HitPos + Vector(0, 0, 30))) then
					local far = 99999
					for _, q in ipairs(players) do far = math.min(far, q:Distance(tr.HitPos)) end
					-- (a way she can walk straight there: nothing in it at her size, no drop or wall on the way - ENT:CanWalk)
					local walk = far > 700 and math.abs(tr.HitPos.z - pos.z) < 80 and self:CanWalk(pos, tr.HitPos)
					if (walk) then
						local sc = R.Map.Cover(tr.HitPos) * 4 + math.min(far, 2500) / 1000 - (R.Map.Seen(tr.HitPos) and 2 or 0) - tr.HitPos:Distance(pos) / 3000
						if (not bs or sc > bs) then best, bs = tr.HitPos, sc end
					end
				end
			end
			spot = best
		end
		if (not spot) then return end
		self.HideGo, self.Hidden, self.HideT = spot, true, now
		R.Stat("queen hides")
		R.Dbg(self, "queen hides at", math.Round(spot:Distance(pos)), "away")
		for b in pairs(R.bugs) do
			if (IsValid(b) and b.RepGuard == self) then b.RepHome = spot; b:GoTo(spot + VectorRand() * 80, 0.9) end
		end
	end

	function ENT:Brain(now, pos)
		self:Build(now)
		-- (solid again once off the platform and the rings are down - or no ring came)
		if (self.RingGhostT and now - self.RingGhostT > 6 and (not self.Pursuit or now - self.RingGhostT > 15)) then
			local onPad = false
			for _, r in ipairs(ents.FindInSphere(pos, 140)) do if (r.IsRings and r:GetClass():find("^ring_base")) then onPad = true end end
			if (not onPad or now - self.RingGhostT > 30) then self.RingGhostT = nil self:SetCollisionGroup(COLLISION_GROUP_NONE) end
		end
		if (self.Pursuit) then return self:Pursue() end   -- away by rings or a gate (R.QueenEscape)
		if (self.State == "attack") then return BASE.Brain(self, now, pos) end
		if (now > (self.NextHide or 0) and R.cv.queenHide:GetBool()) then self.NextHide = now + 4; self:FindHiding(now, pos) end
		if (self.HideGo) then
			if (pos:DistToSqr(self.HideGo) > 90 * 90 and now - self.HideT < 60) then
				if (not self.Goal or self.Goal:DistToSqr(self.HideGo) > 40 * 40) then self:GoTo(self.HideGo, 0.9) end
				return
			end
			self.RepHome, self.HideGo = self:GetPos(), nil   -- there (or as near as it got in a minute): the new nest
			-- (a spot she went to look for cover: hidden if nobody is near and nobody sees her there; else she goes on looking)
			local near = 99999
			for _, p in ipairs(player.GetAll()) do if (p:Alive()) then near = math.min(near, p:GetPos():Distance(pos)) end end
			if (near > 1200 and not self:SeenByPlayer(pos)) then self.Hidden = true end
			R.Stat("queen: at her hiding place")
		end
		-- no hiding place known, or the nest she is at is seen - she goes looking for cover: on to the edge of what the
		-- swarm knows, away from the players, at her own height, a way she can walk; there she looks again
		--
		if (not self.Hidden and now > (self.SeekT or 0)) then
			self.SeekT = now + 12
			local to = self:SeekCover(pos)
			if (to) then
				self.HideGo, self.HideT = to, now
				self:GoTo(to, 0.8)
				R.Stat("queen: looks for cover")
				R.Dbg(self, "queen looks for cover", math.Round(to:Distance(pos)), "away")
				return
			end
		end
		-- at her nest: she keeps it - stands, builds, turns to face where a player is (or the way she came), now and then a
		-- few steps to another spot of the nest; no aimless stroll (the old one: a new spot 220 round every 5-9 s)
		-- (not while she has a goal of her own - a way somewhere: the nest's little moves took it over)
		if (self.Goal and self.Goal:DistToSqr(pos) > 60 * 60) then return end
		if (not self.MoveTo or now > (self.WanderUntil or 0)) then
			local watch
			for _, p in ipairs(player.GetAll()) do
				if (p:Alive() and p:GetPos():DistToSqr(pos) < 2500 * 2500 and (not watch or p:GetPos():DistToSqr(pos) < watch:DistToSqr(pos))) then watch = p:GetPos() end
			end
			if (watch and math.random() < 0.7) then
				-- (a turn on the spot: a step of 12 towards him - she faces him, ready)
				local d = watch - pos; d.z = 0
				if (d:LengthSqr() > 1) then self.MoveTo = pos + d:GetNormalized() * 12 end
				self.WanderUntil = now + math.Rand(6, 12)
				R.Stat("queen: watches a player")
			elseif (math.random() < 0.35) then
				local home = self.RepHome or pos
				self.MoveTo = self:OnGround(home + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0):GetNormalized() * math.Rand(40, 120)) or nil
				self.WanderUntil = now + math.Rand(10, 18)
			else
				self.MoveTo = nil; self.WanderUntil = now + math.Rand(8, 15)
			end
		end
	end

	-- where to look for cover: the best of a few spots 500-1500 away - away from the players, at her height, the way
	-- there walkable for her (no wall, no drop); covered or unknown spots count more (unknown: she finds out there)
	function ENT:SeekCover(pos)
		local players = {}
		for _, p in ipairs(player.GetAll()) do if (p:Alive()) then players[#players + 1] = p:GetPos() end end
		local best, bs
		local why = { ground = 0, near = 0, way = 0 }
		for _ = 1, 14 do
			local a = math.random() * math.pi * 2
			local c = pos + Vector(math.cos(a), math.sin(a), 0) * math.Rand(500, 1500)
			local tr = util.TraceLine({ start = c + Vector(0, 0, 150), endpos = c - Vector(0, 0, 400), mask = MASK_SOLID_BRUSHONLY })
			if (not (tr.Hit and not tr.StartSolid and tr.HitNormal.z > 0.7 and math.abs(tr.HitPos.z - pos.z) < 80 and util.IsInWorld(tr.HitPos + Vector(0, 0, 30)))) then why.ground = why.ground + 1
			else
				local far, closer = 99999, false
				for _, q in ipairs(players) do
					far = math.min(far, q:Distance(tr.HitPos))
					if (q:Distance(tr.HitPos) < q:Distance(pos) - 100) then closer = true end
				end
				if (closer or far < 600) then why.near = why.near + 1
				elseif (not self:CanWalk(pos, tr.HitPos)) then why.way = why.way + 1
				else
					local sc = (R.Map.Cover(tr.HitPos) or 0) * 3 + math.min(far, 2500) / 1000 - (R.Map.Seen(tr.HitPos) and 2 or 0) + math.random() * 0.5
					if (not bs or sc > bs) then best, bs = tr.HitPos, sc end
				end
			end
		end
		if (not best) then R.Dbg(self, "queen found no cover to look for: no ground", why.ground, "towards a player", why.near, "no way", why.way) end
		return best
	end
	-- does a player see her here: within 2500, looking her way, nothing between
	function ENT:SeenByPlayer(pos)
		local c = pos + Vector(0, 0, 30)
		for _, p in ipairs(player.GetAll()) do
			if (p:Alive()) then
				local eye = p:EyePos()
				local to = c - eye
				if (to:LengthSqr() < 2500 * 2500 and p:GetAimVector():Dot(to:GetNormalized()) > 0.5
					and not util.TraceLine({ start = eye, endpos = c, mask = MASK_OPAQUE, filter = function(e) return e ~= p and not e.AGPReplicator end }).Hit) then return true end
			end
		end
		return false
	end
	-- a straight way she can walk: room for her body, ground all along, no step over 20
	function ENT:CanWalk(a, b)
		if (util.TraceHull({ start = a + Vector(0, 0, 26), endpos = b + Vector(0, 0, 26), mins = Vector(-30, -30, 0), maxs = Vector(30, 30, 24), mask = MASK_PLAYERSOLID, filter = function(e) return not e.AGPReplicator and not e:IsPlayer() end }).Hit) then return false end
		local z = a.z
		for k = 1, 6 do
			local m = LerpVector(k / 7, a, b)
			local g = util.TraceLine({ start = Vector(m.x, m.y, z + 30), endpos = Vector(m.x, m.y, z - 60), mask = MASK_PLAYERSOLID, filter = function(e) return not e.AGPReplicator end })
			if (not g.Hit or g.StartSolid or g.HitPos.z > z + 20) then return false end
			z = g.HitPos.z
		end
		return true
	end

	-- the whole swarm goes for whoever hurts her
	function ENT:OnTakeDamage(dmg)
		R.Alarm(self.RepOwner, dmg:GetAttacker())
		BASE.OnTakeDamage(self, dmg)
	end
end
