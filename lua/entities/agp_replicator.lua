--[[
	Replicator (Ascension Gates): the bug. Model: "Replicator SG1" by TaurWing (Sketchfab, CC BY 4.0), legs put on
	bones by us. It walks on its 4 legs (no navmesh needed: a physics body held upright on the ground by a shadow
	controller, the legs are bones moved on the client) and it thinks:
	- the swarm shares what it finds: metal one bug sees, all know (at most two eat the same prop);
	- it hunts in packs: bugs that attack the same target come from different sides and leap at it;
	- it adapts: every time a kind of damage takes one apart, the whole swarm takes less of it (like in the series);
	- it keeps away from a player holding the anti-replicator gun, unless it is already attacking;
	- it eats loose metal props (agp_rep_eat); 12 blocks' worth = a new Replicator, or it carries the metal to its Queen;
	- shot apart it falls into its blocks, which crawl together and rebuild it; the ARG / Dakara weapon: dead blocks.
	The Queen (agp_replicator_queen) is this entity with other numbers. The swarm logic is in lua/autorun/agp_replicators.lua.
]]
local function L(key, fallback, ...)
	if (AGP and AGP.L) then return AGP.L(key, fallback, ...) end
	return fallback
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = L("agp_ent_rep_bug", "Replicator")
ENT.Author = "TaurWing (model), Ascension Gates"
ENT.Category = "Replicators"
ENT.Spawnable = false   -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
ENT.AGPReplicator = true
list.Set("CAP.Entity", ENT.PrintName, ENT)
-- the kill feed names the attacker by its class: "Replicator" in the player's language, not "agp_replicator"
if (CLIENT) then language.Add("agp_replicator", ENT.PrintName) end

-- numbers (the Queen overrides them)
ENT.RepModel = "models/agp_replicator/agp_replicator.mdl"
ENT.RepKind = "bugs"
ENT.RepHealth = 60
ENT.RepSpeed = 170          -- units per second
ENT.RepTurn = 300           -- degrees per second
ENT.RepBite = 7
ENT.RepReach = 30           -- bite reach from its centre
ENT.RepSight = 800          -- sees players / NPCs this far
ENT.RepSmell = 1500         -- finds metal this far (was 1000)
ENT.RepBlocks = 12          -- blocks it falls into
ENT.RepMass = 40
ENT.RepLeap = true          -- jumps at its target
ENT.RepClimb = true         -- walks on walls and ceilings like a spider
ENT.RepRadius = 18          -- half its length (climbing: how far ahead it feels for a wall)
ENT.RepFallBreak = 750      -- landing faster than this (a long fall) bursts it into blocks
ENT.RepWalkSound = "agp_replicator/rep_walk_loop.wav"
-- played when it turns on the spot
ENT.RepTurnSound = "agp_replicator/rep_turn.wav"
ENT.RepStride = 11          -- client: leg cycle length
ENT.RepSwing = 22           -- client: leg swing / lift (degrees)
ENT.RepLift = 16
ENT.RepLegs = { "leg_l1", "leg_r1", "leg_l2", "leg_r2" }
ENT.RepGait = { leg_l1 = 0, leg_r2 = 0, leg_r1 = 1, leg_l2 = 1 }   -- diagonal pairs, like a trotting animal
-- client: where each leg's hip and foot are in the model (its source) - each foot finds its own ground (ENT:ClFeet)
--
ENT.RepFeet = {
	HIP = { leg_l1 = Vector(0.2282, 3.2138, 11.0095), leg_l2 = Vector(0.1014, 9.1825, 11.0095), leg_r1 = Vector(-0.2281, 3.2138, 11.0095), leg_r2 = Vector(-0.1014, 9.1824, 11.0095) },
	FOOT = { leg_l1 = Vector(6.9142, -14.5892, 0.0337), leg_l2 = Vector(18.4658, 14.1183, 0.0337), leg_r1 = Vector(-6.7184, -14.6605, 0.0337), leg_r2 = Vector(-18.5197, 13.917, 0.0337) },
}

-- Replicator bodies do not push each other - they keep their distance by their own rule (Think) - pushed bodies
-- knocked the waiting ones off a narrow roof at a bridge, and the physics paid for every shove. Bugs and Queens
-- only; players, props and the world as before.
--
hook.Add("ShouldCollide", "AGPRepBodies", function(a, b)
	if (a.AGPReplicator and b.AGPReplicator and a.RepKind and b.RepKind) then return false end
end)

if SERVER then
	AddCSLuaFile()
	local R = AGP.Rep

	function ENT:SpawnFunction(ply, tr) return R.SpawnSent(self, ply, tr) end

	function ENT:Initialize()
		self:SetModel(self.RepModel)
		if (self.RepMini) then
			-- a small Replicator (grown from a lone block): half the size, weaker, it falls into 4 blocks
			self:SetModelScale(0.5)
			local mn, mx = self:OBBMins(), self:OBBMaxs()
			self:PhysicsInitBox(mn * 0.5, mx * 0.5)
			self.RepHealth, self.RepSpeed, self.RepBlocks, self.RepRadius, self.RepBite, self.RepReach, self.RepLeap = 20, 130, 4, 9, 3, 18, false
		else
			self:PhysicsInit(SOLID_VPHYSICS)
		end
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCustomCollisionCheck(true)   -- (the rule above)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetMass(self.RepMass); ph:SetMaterial("metal"); ph:Wake() end
		self:StartMotionController()
		-- (a small one: Activate, right after Spawn, makes its half-size body anew - and the new body is not in the motion
		-- controller: its walking was never called, it stood and only the "stuck" hop moved it, like a frog. A tick
		-- later, on whatever body it has then, mass and controller once more)
		if (self.RepMini) then
			timer.Simple(0, function()
				if (not IsValid(self)) then return end
				local p2 = self:GetPhysicsObject()
				if (IsValid(p2)) then p2:SetMass(self.RepMass); p2:SetMaterial("metal"); p2:Wake() end
				self:StopMotionController()
				self:StartMotionController()
			end)
		end
		self:SetMaxHealth(self.RepHealth); self:SetHealth(self.RepHealth)
		self.RepUp, self.RepFwd = Vector(0, 0, 1), self:GetForward()
		self.RepStock = 0
		self.State = "wander"
		self.RepSide = math.Rand(0, 360)   -- the side it comes from when hunting with others
		self.LastPos, self.LastMoveT = self:GetPos(), CurTime()
		R[self.RepKind][self] = true
		self:RepSound("agp_replicator/rep_chatter2.wav", 65, math.random(95, 115), 0.6)
	end

	function ENT:OnRemove()
		R[self.RepKind][self] = nil
		if (self.Eating and IsValid(self.Eating)) then self.Eating.RepEaten = nil; self.Eating:SetModelScale(1, 0.3) end
		if (self.EatSound) then self.EatSound:Stop() end
	end

	-- surfaces it walks on: the map's brushes (props are pushed, not climbed)
	-- what they walk and climb on: the map, and props (a player's base, crates, a ramp, a parked jumper -), the
	-- parts of a ship (a Ha'tak's decks inside) - not players, NPCs, other Replicators, a ship's hull itself (that
	-- they board: carried along, eating it) or small things (those they eat)
	local MASKW = MASK_PLAYERSOLID
	local function walkable(e)
		local w = e.AGPRepWalk
		if (w == nil) then
			w = e:IsWorld() or not (e:IsPlayer() or e:IsNPC() or e.AGPReplicator or R.IsShip(e) or e:IsWeapon()
				or e:GetClass() == "event_horizon" or e:BoundingRadius() < 24 or e:GetCollisionGroup() == COLLISION_GROUP_DEBRIS or e:GetCollisionGroup() == COLLISION_GROUP_WEAPON)
			e.AGPRepWalk = w
		end
		return w
	end
	R.Walkable = walkable
	local function surf(self, a, b) return util.TraceLine({ start = a, endpos = b, mask = MASKW, filter = function(e) return e ~= self and walkable(e) end }) end
	local function rotate(v, axis, a)   -- v turned by angle a (radians) around a unit axis
		return v * math.cos(a) + axis:Cross(v) * math.sin(a) + axis * axis:Dot(v) * (1 - math.cos(a))
	end

	-- walking: the physics body is held on its surface by a shadow controller and moved towards self.MoveTo.
	-- A bug walks like a spider: up walls, over edges, along ceilings (its "up" is the surface's normal); the Queen
	-- (RepClimb = false) stays on the ground and stops at ledges.
	R.QUEEN_STEP = 26   -- the highest step the Queen walks up (her own ground walker below)
	R.WALK_BUDGET = 4   -- ms of leg-ray walking per server tick for the whole swarm (a tick is 15 ms; ENT:PhysicsSimulate)
	R.WALK_HARD = 4     -- ms a tick the swarm's walking may want before bugs share ticks (R.walkDiv, ENT:PhysicsSimulate)
	R.walkDiv = R.walkDiv or 1
	function ENT:PhysicsSimulate(ph, dt)
		if (self:IsPlayerHolding() or self.RepGone or self.Clinging or self.GateRide) then return SIM_NOTHING end   -- (GateRide: in a wormhole, sv_pursuit.lua)
		if (self.Falling and self.Jumping and CurTime() - (self.FallT or 0) < 2.5) then
			-- in a jump: it was pointed along its flight at take-off (StartFall) and does not tumble; nothing is set here
			-- (setting the body's angles every tick stopped it in the air: the jumps went nowhere)
			-- (no setting of the body's velocity in here: that froze it in the air) - a counter-spin keeps it from tumbling
			return -ph:GetAngleVelocity() * 12, Vector(0, 0, 0), SIM_LOCAL_ACCELERATION
		end
		if (self.Falling and not self.Boarded and R.CatTwist) then return R.CatTwist(self, ph) end   -- (feet down in the air: sv_jump.lua)
		if (self.Falling or self.Boarded or (self.RightUntil and CurTime() < self.RightUntil)) then return SIM_NOTHING end
		-- far from players, resting - only with its body level on its feet: hung upright at a step's edge it rested like
		-- that until its next goal (the Ha'tak's throne step in the release film, the player far off behind the camera,
		-- )
		if (self.RepFar and not self.MoveTo and (self.RepUp or Vector(0, 0, 1)).z > 0.7 and self:GetUp():Dot(self.RepUp or Vector(0, 0, 1)) > 0.9) then return SIM_NOTHING end
		-- the game is behind (the lag guard, agp_replicators.lua): far from every player it rests - held where it stopped
		-- (on a wall too), its body put to sleep from Think once it stands still (it costs the physics nothing then; it
		-- wakes when the game keeps up again). (Put to sleep in here, inside the physics step, the game crashed.)
		if (R.Resting(self) and not self.Jumping) then
			-- (held as it stands - unless its body is off its feet, hung upright at an edge: then held level)
			local ru = self.RepUp or Vector(0, 0, 1)
			if (not self.RestAt) then
				-- (nothing under it - flung off a ship's wreck by its blast: no rest in mid-air, it drops on to what is below
				-- first. Held where it was, it hung there; let go after 1 s it fell a bit and was held again)
				local p0 = ph:GetPos()
				local tg = util.TraceLine({ start = p0 + ru * 8, endpos = p0 - ru * 48, mask = MASK_SOLID,
					filter = function(e) return not e.AGPReplicator and not e:IsPlayer() and not e:IsNPC() and not e.SpaceGridKeel end })
				if (not tg.Hit) then return SIM_NOTHING end
				self.RestAt = ph:GetPos()
				self.RestAng = (self:GetUp():Dot(ru) > 0.9 or not self.RepFwd) and ph:GetAngles() or (self.RepFwd - ru * self.RepFwd:Dot(ru)):AngleEx(ru)
				-- held on what it stands on, not on a spot in the world (the author's play test: the guard held the bugs of a
				-- flying ship where they were - the ship flew on, they hung in the air, and stayed there once it was gone)
				self.RestOn = self:RestGround(self.RestAt, ru)
				if (self.RestOn) then
					self.RestL, self.RestLA = self.RestOn:WorldToLocal(self.RestAt), self.RestOn:WorldToLocalAngles(self.RestAng)
					self.RestOn.AGPRepRestOn = true   -- (removed: its resting bugs fall at once, the hook in agp_replicators.lua)
				end
			end
			local at, ang = self.RestAt, self.RestAng
			if (self.RestOn ~= nil) then
				if (not IsValid(self.RestOn)) then self:RestLost() return SIM_NOTHING end   -- (what it stood on is gone: it falls)
				at, ang = self.RestOn:LocalToWorld(self.RestL), self.RestOn:LocalToWorldAngles(self.RestLA)
			end
			ph:ComputeShadowControl({ secondstoarrive = 0.1, pos = at, angle = ang, maxangular = 4000, maxangulardamp = 8000,
				maxspeed = 300, maxspeeddamp = 9000, dampfactor = 0.9, teleportdistance = 0, deltatime = dt })
			return
		end
		self.RestAt, self.RestAng, self.RestOn = nil, nil, nil
		ph:Wake()
		if (self.Crossing) then
			local T = self.Crossing
			local p0 = ph:GetPos()
			local to = T.b - p0; to.z = 0
			-- (no closer for 1.5 s: at the far end - against the roof's lip, a step up from the bridge - it pushed on
			-- towards the far point for ever, "2 are standing at the end of the bridge and do nothing ... its 1-2 steps".
			-- The walker takes over from there and climbs the step)
			local tl, ct = to:Length(), CurTime()
			if (self.CrossOf ~= T) then self.CrossOf, self.CrossBest, self.CrossBestT = T, tl, ct
			elseif (tl < self.CrossBest - 4) then self.CrossBest, self.CrossBestT = tl, ct end
			local short = ct - self.CrossBestT > 1.5
			if (short) then R.Stat("bridge crossing ended short of the far point") end
			if (not T.done or T.dead or tl < 24 or short) then
				self.Crossing, self.CrossOf = nil, nil
				if (short) then self.NextGap = ct + 3 end   -- (not straight onto the same bridge again)
				if (self.AfterCross) then   -- (over: on to where it was going)
					self.MoveTo, self.AfterCross = self.AfterCross, nil
					if (to:Length() < 24) then R.Stat("bridge arrivals") end
				end
			else
				local f = to:GetNormalized()
				local target = p0 + f * math.min(self.RepSpeed * 0.08, to:Length())
				local span = T.b - T.a; span.z = 0
				local along = math.Clamp((target - T.a):Dot(span:GetNormalized()) / math.max(1, span:Length()), 0, 1)
				target.z = Lerp(along, T.a.z, T.b.z) + 6   -- (a sloped beam: up or down with it)
				T.used = CurTime()
				self.RepUp, self.RepFwd, self.RepAt = Vector(0, 0, 1), f, target
				ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = target, angle = f:Angle(), maxangular = 4000,
					maxangulardamp = 8000, maxspeed = 900, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
				return
			end
		end
		-- walk on from where it should be (the body follows the shadow a moment later, e.g. right after an edge),
		-- unless something pushed it far off
		local pos = ph:GetPos()
		-- (right after a corner it goes on from where it was set last - but never further ahead of its body than its
		-- usual look-ahead: the target ran on ahead, the body raced after it at twice its speed - up walls like a
		-- rocket, off narrow faces right after a corner (most of the falls by a bridge came 0.0-0.2 s after a corner).
		-- That run-ahead was also what carried it past a lip; that is the lip rule's job now, sv_walk.lua)
		local lead = nil
		if (self.RepClimb and self.RepAt and CurTime() - (self.RepWrapT or 0) < 0.6 and self.RepAt:DistToSqr(pos) < 40 * 40) then lead = self.RepAt:Distance(pos) pos = self.RepAt end
		local up = self.RepUp or Vector(0, 0, 1)
		local fwd = self.RepFwd or self:GetForward()
		fwd = fwd - up * fwd:Dot(up)
		if (fwd:LengthSqr() < 1e-4) then fwd = up:Angle():Up() end
		fwd:Normalize()
		local step, moving = Vector(), false
		-- (a steering point holds for the surface it was made on: round a corner, 120 along the face it had left lay in
		-- the air and it walked off after it)
		local st = self.SteerTo
		if (st and ((self.SteerUp and self.SteerUp:Dot(up) < 0.9) or CurTime() > (self.SteerT or 0) + 1.5 or st:DistToSqr(pos) < 12 * 12)) then self.SteerTo = nil end
		local goalPos = self.SteerTo or self.MoveTo
		-- on its back (or side) on a floor for 0.4 s: a hop and it is on its feet. The walk dragged bugs along on their backs
		-- for up to 5.5 s - the controller cannot roll a body upright through the ground - and the landing's flail and random
		-- spin often left them lying; breaking apart waits while a player watches (stall log)
		if (up.z > 0.7 and self:GetUp():Dot(up) < 0.34 and not self.Transit) then
			self.BackT = self.BackT or CurTime()
			if (CurTime() - self.BackT > 0.4) then
				self.BackT = nil
				R.Stat("rolled back onto its feet")
				ph:SetPos(ph:GetPos() + up * 12)
				ph:SetAngles(fwd:AngleEx(up))
				ph:SetVelocity(up * 60)
				ph:AddAngleVelocity(-ph:GetAngleVelocity())
				self:SetNWBool("RepFlail", false)
				return
			end
		else
			self.BackT = nil
		end
		-- one mover (sv_mover.lua, agp_rep_onemover, on by default): it decides alone while it owns the bug; off: as before
		if (R.Mover and R.Mover.Step(self, ph, pos, up, fwd, dt)) then return end
		-- hanging under a ceiling: its own walk (sv_ceiling.lua). None of the floor and wall rules below run while it does;
		-- off it: as before
		if (R.Ceil and R.Ceil.On(self, up) and R.Ceil.Step(self, ph, pos, up, fwd, goalPos, dt)) then
			if (self.Falling) then return SIM_NOTHING end
			return
		end
		-- (in the crease between a ceiling and a wall, stuck: onto the face its goal is on, in one corner move)
		if (R.Ceil and R.Ceil.Crease and R.Ceil.Crease(self, ph, pos, up, fwd, goalPos, dt)) then return end
		-- (its next waypoint on another face - a wall beside a ceiling's corner, a window frame's side, a sill's top - and no
		-- nearer: onto that face, sv_ceiling.lua C.Seam)
		if (R.Ceil and R.Ceil.Seam and R.Ceil.Seam(self, ph, pos, up, fwd, dt)) then return end
		-- (its goal straight through the surface it is on - on the slab it hangs under: to that surface's nearest edge and
		-- round it, not "there" and waiting under it, R.EdgeAim in sv_walk.lua)
		if (goalPos and self.RepClimb and not self.SurfPath and R.EdgeAim) then
			local ea = R.EdgeAim(self, pos, up, goalPos)
			if (ea) then goalPos = ea end
		end
		if (goalPos and R.Awake() and not self.Eating) then
			local d = goalPos - pos
			d = d - up * d:Dot(up)
			local dist = d:Length()
			-- hanging from a ceiling and the goal is below: drop if the floor is near enough to land safely,
			-- else go back the way it came (towards the wall it climbed up)
			if (self.RepClimb and up.z < -0.7 and dist < 30) then   -- the goal straight below / above: along the ceiling, the way it faces
				d = fwd * 100; dist = 100
			end
			-- (not halfway round a corner, body and all, sv_walk.lua transit: going round under an overhang its up passed
			-- the ceiling's for a moment and it let go - all three bugs at the high edge's ledge)
			if (self.RepClimb and up.z < -0.7 and goalPos.z < pos.z - 40 and not self.Transit) then
				local back = Vector(-d.x, -d.y, 0):GetNormalized()
				local wall = surf(self, pos + up * 4, pos + up * 4 + back * 90)
				if (wall.Hit) then
					d = -d                                    -- the wall it came from is right there: climb down it
				else
					-- (a floor it lands on whole: 380 down onto any edge or ledge it broke apart, 22 times in 3 test runs -
					-- now only a short drop (R.LetDown, sv_walk.lua; from 250 it landed at 540), only a real floor, and under
					-- its whole body)
					local ok = true
					for _, o in ipairs({ Vector(0, 0, 0), Vector(16, 0, 0), Vector(-16, 0, 0), Vector(0, 16, 0), Vector(0, -16, 0) }) do
						local fl = surf(self, pos + o, pos + o - Vector(0, 0, R.LetDown or 160))
						if (not fl.Hit or fl.HitNormal.z < 0.7) then ok = false break end
					end
					if (ok) then self.RepFallWhy = "lets itself down" self:StartFall() return SIM_NOTHING end
					d = -d
				end
			elseif (self.RepClimb and up.z < -0.7 and goalPos.z > pos.z - 10) then
				d = -d   -- under an overhang (a ledge) and the goal is above: out along the underside, round the edge, up
			end
			if (dist > 6) then
				local want = d / dist
				local off = math.acos(math.Clamp(fwd:Dot(want), -1, 1))
				local turn = math.rad(self.RepTurn * dt)
				if (off > 2.6 and self.RepClimb) then
					fwd = want; off = 0   -- (almost) straight back: a bug just turns round (no slow sideways wobble)
				elseif (off > turn) then
					local axis = fwd:Cross(want)
					if (axis:LengthSqr() < 1e-6) then axis = up end
					axis:Normalize()
					fwd = rotate(fwd, axis, turn):GetNormalized()
				else
					fwd = want
				end
				-- (the Queen walks on in a curve while she turns - she stood and turned on the spot like a tank; a bug
				-- slows right down for a sharp turn) (close to her
				-- goal - within 160 - a sharp turn slows her right down: at half speed she went round and round a ring platform's
				-- middle 40-90 off it for 20 s and never got on)
				local qmin = (dist < 160) and 0.12 or 0.5
				local spd = self.RepSpeed * (self.SpeedMul or 1) * (self.RepClimb and math.Clamp(1 - off / 1.9, 0.1, 1) or math.Clamp(1 - off / ((dist < 160) and 1.6 or 3), qmin, 1))
				-- the shadow controller needs 0.08 s to reach its target: the target lies that far ahead (one tick ahead
				-- made them walk at a fifth of their speed)
				local ahead = spd * 0.08
				if (lead) then ahead = math.Clamp(ahead - lead, spd * dt, ahead) end
				step = fwd * math.min(ahead, dist)
				moving = true
			elseif (self.SurfPath and goalPos:DistToSqr(pos) > 30 * 30) then
				-- (on a planned way the way says where to go: its goal straight behind the wall it climbs - on the floor
				-- beyond it - lies along its up, nothing of it along the wall, and it stood there "not moving", on the
				-- wall for seconds (the course's capped wall, the sign))
				step = fwd * (self.RepSpeed * (self.SpeedMul or 1) * 0.08)
				moving = true
			end
		end
		local watch = not moving and not self.InBridge and not self.InTower and IsValid(self.Watch) and self.Watch
		if (watch) then   -- waiting: it turns to its prey and keeps it in sight
			local want = watch:WorldSpaceCenter() - pos
			want = want - up * want:Dot(up)
			if (want:LengthSqr() > 1) then
				want:Normalize()
				local off = math.acos(math.Clamp(fwd:Dot(want), -1, 1))
				local turn = math.rad(self.RepTurn * 0.5 * dt)   -- slowly, not a twitch
				if (off > turn) then
					local axis = fwd:Cross(want)
					if (axis:LengthSqr() < 1e-6) then axis = up end
					axis:Normalize()
					fwd = rotate(fwd, axis, turn):GetNormalized()
				else
					fwd = want
				end
			end
		end
		local target = pos + step
		-- its body turned over against the surface its legs are on - its back to the wall, its middle in it: it could not
		-- roll back, the wall it pressed against was in the way, and it climbed on like that for seconds (and
		-- through the wall - the course test's prop walls). A quarter second of that: it is set the right way up at
		-- once. Also hanging upright: its body more than 60
		-- degrees off the surface its feet are on (walked into a step, the front feet hooked on the edge, the step pushed
		-- its front up until it stood on its back legs, legs in the step - the Ha'tak's throne step). A third of a
		-- second of that (not while it goes round a corner body and all - its body follows a moment later there): set
		-- level, a little back off the edge, and for a moment the step ahead counts as a wall it climbs (sv_walk.lua), not
		-- one it walks into.
		local bodyUp = self:GetUp():Dot(up)
		if (bodyUp < -0.3 or (bodyUp < 0.5 and not self.Transit and CurTime() - (self.RepWrapT or 0) > 0.4)) then
			self.FlipT = self.FlipT or CurTime()
			if (CurTime() - self.FlipT > (bodyUp < -0.3 and 0.25 or 0.35)) then
				self.FlipT = nil
				ph:SetAngles(fwd:AngleEx(up))
				ph:SetAngleVelocity(Vector(0, 0, 0))
				if (bodyUp < -0.3) then R.Stat("set the right way up again")
				else
					ph:SetPos(ph:GetPos() + up * 3 - fwd * 6)
					ph:SetVelocity(Vector(0, 0, 0))
					self.RepAt, self.StepClimbT = nil, CurTime() + 2.5
					R.Stat("set level from hanging upright")
					R.Dbg(self, "hung upright at an edge: set level", tostring(pos))
				end
			end
		else
			self.FlipT = nil
		end
		-- (how fast the body may follow its target: up to 900 it shot after a target set a body length on round a
		-- corner - up a wall like a rocket, over the top and off; twice its walking speed now)
		local vmax = math.max(260, (self.RepSpeed or 150) * (self.SpeedMul or 1) * 2)
		-- on an even surface (all its feet on one floor, wall or ceiling, no wall ahead, no corner just now) it walks on
		-- along it without probing: every other tick near the players, two ticks of three further away (the probing was
		-- a quarter of the server's time with 22 bugs). Near edges, corners and walls it probes every tick. the felt
		-- map (sv_field.lua): it glides on what
		-- the swarm felt of the map - no leg rays (agp_rep_legwalk 1: legs only). Not near a prop (the map only is felt), not
		-- on a planned way or round a corner body and all, not
		-- in a tower or a bridge; where the felt map has no surface near it walks with its legs as before
		--
		if (R.FieldOn and R.FieldOn() and R.FieldWalk and self.RepClimb and CurTime() > (self.FieldWaitT or 0) and not self.SurfPath and not self.Transit and not self.InTower and not self.InBridge) then
			local now = CurTime()
			if (now > (self.FieldPropT or 0)) then
				self.FieldPropT = now + 0.5
				self.FieldProps = false
				for _, e in ipairs(ents.FindInSphere(pos, 90)) do
					-- (not what it goes for - a gate, a generator: it walks up to it on the felt map and eats; on its legs it stuck
					-- on the steps at the foot of freespace13's gate. A ship it climbs onto: that one counts) (a frozen
					-- prop the felt map knows where it is now, sv_fieldprops.lua: on it glides on as on the map - on a floor
					-- only: on a prop wall the legs climb a lip the felt walk could not get round)
					if (e ~= self and not (e == self.Target and not R.IsShip(e)) and not e:IsWorld() and walkable(e) and IsValid(e:GetPhysicsObject())
						and not (self:GetUp().z > 0.7 and (up.z > 0.7 or (self.Goal ~= nil and self.Goal.z < pos.z - 40)) and R.Field and R.Field.PropKnown and R.Field.PropKnown(e))) then self.FieldProps = true break end
				end
			end
			-- (its goal even when it is straight out from the surface - above the wall it stands at: "not moving" above, and
			-- the felt map stood still under it)
			local fg = (goalPos and R.Awake() and not self.Eating) and goalPos or nil
			-- (a planned way first, as the leg walker asks for one (sv_walk.lua): the felt map never asked, and a bug that fell
			-- off the roof's edge stood on the floor below it for good - with legs it got a new way and climbed)
			-- (not under a ceiling on a way worked out on the felt map, sv_feltnav.lua: under the tower's platform the side
			-- view's plan took over and hung there for 40 s. Up a wall to a roof's edge it is what gets it round - kept out
			-- there too, the strict roof scene fell to 6 of 9 clean; let in going down too, the high edge fell from 8 to 3
			-- of 9: on a felt way only going up and not under a ceiling)
			if (not self.FieldProps and fg and R.SurfNav and R.SurfNav.Step and not (self.Route and self.Route.felt and (up.z < -0.3 or fg.z < pos.z + 40))) then
				local pt, pu, pf = R.SurfNav.Step(self, pos, up, fwd, fg, moving, dt)
				if (pt) then
					self.WalkWhy = "planned way"
					if (R.DeadClamp and #R.deadGates > 0) then pt = R.DeadClamp(self, pos, pt) end
					self.RepUp, self.RepFwd, self.RepAt = pu, pf, pt
					ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = pt, angle = pf:AngleEx(pu), maxangular = 4000,
						maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
					return
				end
			end
			if (not self.FieldProps) then
				local ft, fu, ff = R.FieldWalk(self, pos, up, fwd, fg, self.RepSpeed * (self.SpeedMul or 1), dt)
				-- (its body does not follow round a sharp edge: upright against a wall just under its top, the felt map's way
				-- leads over the edge onto the top, and a stiff body cannot turn there - it stood 2 s and let go, the strict
				-- cliff. Body more than 45 degrees off the felt map's up and not moving for 0.3 s: it rolls round onto the
				-- face under the felt map's target, body and all, as the legs do (R.TransitTo))
				if (ft and R.TransitTo) then
					local bu = self:GetUp()
					if (bu:Dot(fu) < 0.7) then
						local st = self.FieldStuck
						if (not st or st.p:DistToSqr(pos) > 16) then self.FieldStuck = { p = Vector(pos), t = now }
						elseif (now - st.t > 0.3) then
							self.FieldStuck = nil
							local tr = util.TraceLine({ start = ft + fu * 8, endpos = ft - fu * 20, mask = MASK_PLAYERSOLID_BRUSHONLY })
							if (tr.Hit and not tr.StartSolid and tr.HitNormal:Dot(bu) < 0.7) then
								local cp, cu, cf = R.TransitTo(self, pos, bu, tr.HitPos, tr.HitNormal)
								if (cp) then
									R.Stat("felt map: rolled round an edge it was stuck at")
									self.WalkWhy = "felt map: round the edge"
									self.RepUp, self.RepFwd, self.RepAt = cu, cf, cp
									ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = cp, angle = cf:AngleEx(cu), maxangular = 4000,
										maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
									return
								end
							end
						end
					else
						self.FieldStuck = nil
					end
				end
				-- (stalled at the foot of a step - a paved strip 16 high on freespace13: in the corner between the ground and the
				-- step's face the felt map's up tilts back, the body lift (sv_field.lua) does not reach and it stood there for
				-- good, walking in at full speed. No nearer its goal for 0.4 s with a step at most 26 high in front, towards
				-- the goal: it glides up onto the step's top) (held until it
				-- is up: for one tick only the felt map took it back to the step's foot at once, probe)
				local su = self.StepUp
				if (su and (now > su.t or pos:DistToSqr(su.to) < 8 * 8)) then self.StepUp, su = nil, nil end
				if (su and ft) then ft, fu, ff = su.to, Vector(0, 0, 1), su.dir self.WalkWhy = "felt map: up the step" end
				if (ft and fg and up.z > 0.7 and not su) then
					-- (stalled = no nearer its goal for 0.4 s: at the strip it slid along the step's foot, never standing still)
					local sl = self.FieldStall
					local gd = Vector(fg.x - pos.x, fg.y - pos.y, 0):Length()
					if (not sl or gd < sl.d - 8) then self.FieldStall = { d = gd, t = now }
					elseif (now - sl.t > 0.4) then
						local dir = Vector(fg.x - pos.x, fg.y - pos.y, 0)
						if (dir:LengthSqr() > 100) then
							dir:Normalize()
							for _, ahead in ipairs({ 16, 26, 36 }) do
								local q = pos + dir * ahead
								local tr = util.TraceLine({ start = q + Vector(0, 0, 34), endpos = q - Vector(0, 0, 4), mask = MASK_PLAYERSOLID_BRUSHONLY })
								if (tr.Hit and not tr.StartSolid and tr.HitNormal.z > 0.7 and tr.HitPos.z > pos.z + 2 and tr.HitPos.z < pos.z + 26) then
									local room = util.TraceHull({ start = tr.HitPos + Vector(0, 0, 4), endpos = tr.HitPos + Vector(0, 0, 4), mins = Vector(-12, -12, 0), maxs = Vector(12, 12, 20), mask = MASK_PLAYERSOLID_BRUSHONLY })
									if (not room.Hit and not room.StartSolid) then
										self.FieldStall = nil
										R.Stat("felt map: glided up a step it stalled at")
										self.WalkWhy = "felt map: up the step"
										ft, fu, ff = tr.HitPos + Vector(0, 0, 2), Vector(0, 0, 1), dir
										self.StepUp = { to = tr.HitPos + Vector(0, 0, 2) + dir * 8, dir = dir, t = now + 0.6 }
									end
									break
								end
							end
						end
					end
				end
				if (ft) then
					R.walkField = (R.walkField or 0) + 1
					self.WalkWhy = "felt map"
					if (R.StepGlide and fu.z > 0.7 and not su) then ft = R.StepGlide(self, ft, fu, ff) end   -- (risen before a step ahead, sv_walk.lua)
					if (R.DeadClamp and #R.deadGates > 0) then ft = R.DeadClamp(self, pos, ft) end
					self.RepUp, self.RepFwd, self.RepAt = fu, ff, ft
					self.RepPlane, self.RepFlat = nil, nil
					ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = ft, angle = ff:AngleEx(fu), maxangular = 4000,
						maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
					return
				end
			end
		end
		self.RepTick2 = (self.RepTick2 or 0) + 1
		local skip = self.RepMid and (self.RepTick2 % 3 ~= 0) or (self.RepTick2 % 2 == 1)
		local pn = self.RepPlane
		if (skip and self.RepClimb and pn and not self.SurfPath and not self.Transit and up:Dot(pn) > 0.995 and CurTime() - (self.RepWrapT or 0) > 1
			and (self.RepNoWallT or 0) > CurTime() - 0.2) then
			target = target - pn * (target:Dot(pn) - self.RepPlaneD)
			self.WalkWhy = "even (no probe)"
			if (R.StepGlide and up.z > 0.7) then target = R.StepGlide(self, target, up, fwd) end
			if (R.DeadClamp and #R.deadGates > 0) then target = R.DeadClamp(self, pos, target) end   -- (never into an incoming horizon, sv_pursuit.lua)
			self.RepUp, self.RepFwd, self.RepAt = up, fwd, target
			ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = target, angle = fwd:AngleEx(up), maxangular = 4000,
				maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
			return
		end
		-- the walking budget (the busy-world test: 100 bugs' leg-ray walking took 7-18 ms of a 15 ms tick and the game fell
		-- behind): once the swarm has walked with its legs for R.WALK_BUDGET ms in this tick, the others take a cheap step
		-- along the surface they are on (as on an even floor) - at most 2 ticks running (3 far from every player), never
		-- right after a corner, round one or on a planned way. Far from every player (over 3000) a bug also walks with its
		-- legs only every third tick. Eating, carrying metal and building do not wait for this.
		--
		local tk = engine.TickCount()
		if (R.walkTick ~= tk) then
			-- (freespace13: 60 bugs at a building = 3 fps - nearly all of them climbing or at corners, where the budget below
			-- never applies; their leg-ray walking took 45 % of all the time): how much walking the swarm wants a tick
			-- (smoothed); over R.WALK_HARD each bug walks with its legs only every 2nd, 3rd or 4th tick (R.walkDiv)
			-- and between those goes on along the surface it is on
			R.walkDemand = Lerp(0.1, R.walkDemand or 0, (R.walkUsed or 0) * (R.walkDiv or 1))
			R.walkDiv = math.Clamp(math.ceil(R.walkDemand / R.WALK_HARD), 1, 4)
			R.walkTick, R.walkUsed = tk, 0
		end
		local pn0 = self.RepPlane
		if (self.RepClimb and pn0 and not self.SurfPath and not self.Transit and up:Dot(pn0) > 0.99 and CurTime() - (self.RepWrapT or 0) > 0.5
			and (self.WalkCheapN or 0) < (self.RepFar and 3 or 2) and (R.walkUsed > R.WALK_BUDGET * (R.lag and R.lag.behind and 0.5 or 1) or (self.RepFar and self.RepTick2 % 3 ~= 0))) then
			self.WalkCheapN = (self.WalkCheapN or 0) + 1
			R.walkCheap = (R.walkCheap or 0) + 1
			target = target - pn0 * (target:Dot(pn0) - self.RepPlaneD)
			self.WalkWhy = "budget (no probe)"
			if (R.DeadClamp and #R.deadGates > 0) then target = R.DeadClamp(self, pos, target) end
			self.RepUp, self.RepFwd, self.RepAt = up, fwd, target
			ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = target, angle = fwd:AngleEx(up), maxangular = 4000,
				maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
			return
		end
		self.WalkCheapN = 0
		-- unseen by every player (Think, RepUnseen): on along the surface it is on with two rays - nothing ahead, the same
		-- surface under the next step at the same height (within 3) - instead of its legs'. Anything else (a wall, a step, an
		-- edge, a corner, a planned way) and it walks with its legs as always: it stays on real surfaces, and where a player
		-- looks again it is where it would have been
		if (self.RepUnseen and moving and self.RepClimb and not (R.TestOff and R.TestOff.ghost) and not self.SurfPath and not self.Transit and CurTime() - (self.RepWrapT or 0) > 0.4) then
			local sl = step:Length()
			if (sl > 0.01) then
				local w = surf(self, pos + up * 6, pos + up * 6 + step * ((sl + (self.RepRadius or 18) + 6) / sl))
				if (not w.Hit) then
					local g = surf(self, target + up * 20, target - up * 24)
					if (g.Hit and not g.StartSolid and g.HitNormal:Dot(up) > 0.95 and math.abs((g.HitPos - pos):Dot(up)) < 3) then
						R.walkGhost = (R.walkGhost or 0) + 1
						self.WalkWhy = "unseen (two rays)"
						target = g.HitPos
						if (R.DeadClamp and #R.deadGates > 0) then target = R.DeadClamp(self, pos, target) end
						self.RepUp, self.RepFwd, self.RepAt = up, fwd, target
						ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = target, angle = fwd:AngleEx(up), maxangular = 4000,
							maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
						return
					end
				end
			end
		end
		-- a crowded swarm shares the ticks (see R.walkDiv above): never right after a corner, round one (body and all) or on
		-- a planned way - there it walks with its legs every tick
		if (R.walkDiv > 1 and self.RepClimb and (tk + self:EntIndex()) % R.walkDiv ~= 0 and not self.SurfPath and not self.Transit
			and CurTime() - (self.RepWrapT or 0) > 0.4 and self.RepAt) then
			R.walkShared = (R.walkShared or 0) + 1
			self.WalkWhy = "shared tick (no probe)"
			if (R.DeadClamp and #R.deadGates > 0) then target = R.DeadClamp(self, pos, target) end
			self.RepFwd, self.RepAt = fwd, target
			ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = target, angle = fwd:AngleEx(up), maxangular = 4000,
				maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
			return
		end
		if (self.RepClimb and R.cv.walker and R.cv.walker:GetInt() == 2) then
			-- the leg-ray walker (agp_replicators/sv_walk.lua)
			local walkT0 = SysTime()
			target, up, fwd = R.Walk(self, pos, up, fwd, target - pos, moving, goalPos, dt)
			R.walkUsed = R.walkUsed + (SysTime() - walkT0) * 1000
			if (not target) then self:StartFall() return SIM_NOTHING end
		elseif (self.RepClimb) then
			local r = self.RepRadius or 16
			-- a wall (or ceiling) ahead: climb onto it - what was "up" is now the way forward
			-- on flat open ground the way ahead was free when it last looked: it looks again after 6 units or a turn (the
			-- feeler reaches about 30 units ahead, so a wall is still seen in time) - not every tick
			local freeAhead = moving and up.z > 0.98 and self.RepProbeP and self.RepProbeP:DistToSqr(pos) < 6 * 6 and self.RepProbeF:Dot(fwd) > 0.97
				and CurTime() - (self.RepWrapT or 0) > 1
			if (freeAhead) then self.RepNoWallT = CurTime() end
			if (moving and not freeAhead) then
				self.RepProbeP = nil
				-- far enough ahead that it sees the wall before its front legs touch it (else it stands stuck at the foot)
				-- (starting a little behind it: pressed into an inside corner, a probe from the body itself would start in the wall)
				local w = surf(self, pos + up * 4 - fwd * 12, pos + up * 4 + fwd * (r + 14))
				if (not w.Hit or w.StartSolid) then w = surf(self, pos + up * 14 - fwd * 12, pos + up * 14 + fwd * (r + 14)) end   -- and a little higher (a curb at the foot)
				-- a real wall, or only a step / a rim it walks over? a wall is still there 30 units higher
				if (w.Hit and not w.StartSolid and w.HitNormal:Dot(up) < 0.6) then
					local hi = surf(self, pos + up * 30 - fwd * 12, pos + up * 30 + fwd * (r + 20))
					if (not hi.Hit) then w = { Hit = false } end
				end
				if (not (w.Hit and not w.StartSolid)) then self.RepNoWallT = CurTime(); self.RepProbeP, self.RepProbeF = Vector(pos), Vector(fwd) end
				if (w.Hit and not w.StartSolid and w.HitNormal:Dot(up) < 0.6) then
					local n = w.HitNormal
					local nf = up - n * up:Dot(n)
					if (nf:LengthSqr() > 1e-4) then fwd = nf:GetNormalized() end
					up = n
					target = w.HitPos
					self.RepWrapT = CurTime()
				end
			end
			-- stick to the surface under the feet (on flat open ground only every other tick: the floor does not change)
			self.RepTick = (self.RepTick or 0) + 1
			local g
			if (up.z > 0.98 and self.RepFlat and self.RepTick % 2 == 0 and CurTime() - (self.RepWrapT or 0) > 1) then
				g = { Hit = true, HitPos = Vector(target.x, target.y, self.RepFlat), HitNormal = up }
			else
				g = surf(self, target + up * 22, target - up * 24)   -- from step height: it walks over rims and curbs
				self.RepFlat = (g.Hit and not g.StartSolid and g.HitNormal.z > 0.98) and g.HitPos.z or nil
			end
			-- just went round an edge: hold on - look further below before going round an edge again (no wobbling
			-- between wall and roof, no letting go at a rounded rim)
			if (not (g.Hit and not g.StartSolid) and CurTime() - (self.RepWrapT or 0) < 0.4) then
				g = surf(self, target + up * 30, target - up * 60)
			end
			-- no floor right under it, but floor at its own height just beyond (a crack, a slot narrower than its body):
			-- it walks over it, as over a gutter - only a real drop is an edge to climb down (it climbed down into such
			-- a slot and stuck there)
			if (g.Hit and not g.StartSolid) then
				up = LerpVector(math.min(1, dt * 12), up, g.HitNormal):GetNormalized()
				target = g.HitPos
			else
				-- at a roof edge with the way going on across a deep gap: stop and wait a moment - the swarm may lay a
				-- bridge of bodies (Think, ENT:Bridge); after 3 s without one it goes round the edge as usual
				local gapWait = false
				if (up.z > 0.9 and goalPos and not self.Crossing) then
					local now = CurTime()
					if (not self.GapUntil or now > self.GapUntil + 4) then
						self.GapUntil = self:GapAhead(pos, goalPos) and now + 3 or nil
					end
					gapWait = self.GapUntil and now < self.GapUntil
				end
				local e = gapWait and { Hit = false } or surf(self, target - up * 6, target - up * 6 - fwd * (r + 8))
				if (gapWait) then
					target = Vector(pos); self.NextGap = 0
				elseif (e.Hit and not e.StartSolid) then
					local n = e.HitNormal
					local nf = -up - n * (-up):Dot(n)
					if (nf:LengthSqr() > 1e-4) then fwd = nf:GetNormalized() end
					up = n
					target = e.HitPos
					self.RepWrapT = CurTime()
				else
					self.RepFallWhy = "no surface: under " .. tostring(g.Hit) .. "/" .. tostring(g.StartSolid) .. " edge " .. tostring(e.Hit) .. "/" .. tostring(e.StartSolid)
					self:StartFall()
					return SIM_NOTHING
				end
			end
		else
			-- ground only (the Queen): step up small edges, stop at walls and ledges
			up = Vector(0, 0, 1)
			-- (release chat) nothing under HER: she falls like anything else. The ledge rule below (stop when there is
			-- no ground ahead) held her in mid-air when she was made or put there.
			--
			local under = surf(self, pos + Vector(0, 0, 22), pos - Vector(0, 0, 60))
			if (not under.Hit and not under.StartSolid) then
				self.RepFallWhy = "no ground under the Queen"
				self:StartFall()
				return SIM_NOTHING
			end
			-- (steps up to R.QUEEN_STEP: 26 - more mobile over curbs and ring rims; 20 before)
			local tr = surf(self, target + Vector(0, 0, R.QUEEN_STEP + 6), target - Vector(0, 0, 60))
			self.WalkWhy = "queen: walks"
			if (tr.StartSolid or (tr.Hit and tr.HitPos.z > pos.z + R.QUEEN_STEP)) then
				target = Vector(pos); self.RepBlocked = true
				self.WalkWhy = "queen: too high under her next step" .. (IsValid(tr.Entity) and (" (" .. tr.Entity:GetClass() .. ")") or "")
			elseif (tr.Hit) then
				target.z = tr.HitPos.z
			elseif (moving) then
				target = Vector(pos); self.RepBlocked = true
				self.WalkWhy = "queen: no ground ahead"
			else
				target.z = pos.z - 400 * dt
			end
			-- (and from her tail to her head: she is long - on stairs her front met the first step's edge while the ground under
			-- her middle was still level, and she pushed along the edge for good. The ground is looked at in three steps out
			-- to her head and to her tail, each at most 20 over the one before - more is a wall she stops at; her body leans
			-- along the line from tail to head (at most 30 deg) and her middle rides on that line: level, her front still
			-- met the second step)
			local ff = Vector(fwd.x, fwd.y, 0)
			if (target ~= pos and ff:LengthSqr() > 0.01) then
				ff:Normalize()
				local function along(dir, reach)
					local prev, last = pos.z, nil
					for k = 1, 3 do
						local fp = pos + dir * (reach * k / 3)
						local t = surf(self, Vector(fp.x, fp.y, prev + R.QUEEN_STEP + 6), Vector(fp.x, fp.y, prev - 30))
						if (t.StartSolid or (t.Hit and t.HitPos.z > prev + R.QUEEN_STEP)) then return nil, true end
						if (t.Hit) then prev = t.HitPos.z; last = prev end
					end
					return last, false
				end
				local rf, rb = self:OBBMaxs().x + 6, -self:OBBMins().x + 6
				local zf, wall = along(ff, rf)
				if (wall and moving) then
					target = Vector(pos); self.RepBlocked = true
					self.WalkWhy = "queen: wall ahead of her head"
				else
					local zb = along(-ff, rb)
					zf, zb = zf or target.z, zb or target.z
					if (math.abs(zf - zb) > 4) then
						local slope = math.Clamp((zf - zb) / (rf + rb), -0.577, 0.577)
						-- (going up a little above that line: on it her front corner stayed 1 below a 12-high step's edge and she
						-- stood nose to it)
						target.z = math.max(target.z, zb + slope * rb + (zf > zb and 7 or 0))
						local fw = (ff + Vector(0, 0, slope)):GetNormalized()
						local rt = ff:Cross(Vector(0, 0, 1))
						fwd, up = fw, rt:Cross(fw):GetNormalized()
					end
				end
			end
		end
		-- (the last word on where the body goes: whatever set its goal - a wander spot, a climb, a planned way, the swarm's
		-- pull - it never walks into an incoming gate's horizon, R.DeadClamp in sv_pursuit.lua)
		if (R.DeadClamp and #R.deadGates > 0) then target = R.DeadClamp(self, pos, target) end
		self.RepUp, self.RepFwd, self.RepAt = up, fwd, target
		if (watch) then target = target - up * 3 end   -- crouched, ready to spring
		ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = target, angle = fwd:AngleEx(up), maxangular = 4000,
			maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
	end

	-- falling (off a ceiling, a leap, knocked off): normal physics until it lands
	-- jump: an attack jump (not a knock or a fall) - it flies nose first along its arc, no spinning
	function ENT:StartFall(vel, jump)
		if (self.Falling) then return end
		if (self.SurfRails and R.SurfNav) then R.SurfNav.Rails(self, false) end   -- (solid again before it falls)
		if (R.PivotEnd) then R.PivotEnd(self) end   -- (and out of a pivot round a corner, sv_walk.lua)
		self.Transit = nil   -- (and off its way round a corner)
		self.Falling = true
		self.FallT = CurTime()
		-- (why it let go: the line that dropped it, the reason it gave, where and on what it stood - for the log on landing)
		local ci = debug.getinfo(2, "l")
		self.FallFrom = { line = ci and ci.currentline or 0, why = self.RepFallWhy or "-", at = self:GetPos(), up = self.RepUp, state = self.State, fwd = self.RepFwd }
		self.RepFallWhy = nil
		self.Jumping = jump and vel and true or nil
		self.JumpUp, self.JumpFrom = self.RepUp, self:GetPos()   -- (the surface it jumps off: it does not grab that one again right away)
		self.RepAt = nil
		self:SetNWBool("RepFall", true)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then
			ph:Wake()
			if (self.Jumping) then   -- nose along the flight, legs below (set once, before the push)
				local a = vel:Angle()
				ph:SetAngles(Angle(math.Clamp(math.NormalizeAngle(a.p) * 0.4, -25, 25), a.y, 0))
				ph:SetAngleVelocity(Vector(0, 0, 0))
			end
			if (vel) then ph:SetVelocity(vel) end
		end
	end

	-- landing: from high up it bursts into blocks (that rebuild it); otherwise it flails its legs and gets up again
	function ENT:PhysicsCollide(data)
		if (not self.Falling or self.RepGone) then return end
		local speed = data.OurOldVelocity:Length()
		local hit = data.HitEntity
		local ship = IsValid(hit) and (IsValid(hit.AGPShip) and hit.AGPShip or (R.IsShip(hit) and hit)) or nil
		-- inside a ship (the Ha'tak's interior is its own space, its floors are the ship's parts): it lands on the floor
		-- and walks there - boarding would put it out on the hull
		local it = IsValid(ship) and ship.Interior
		if (IsValid(it) and self:GetPos():DistToSqr(it:GetPos()) < self:GetPos():DistToSqr(ship:GetPos())) then ship = nil end
		-- it jumped at what it wants to eat (a power crystal is part of the ship): it holds on to that and eats it
		if (IsValid(hit) and hit == self.Target and self.State == "eat" and hit ~= ship and speed <= (self.RepFallBreak or 750)) then
			timer.Simple(0, function() if (IsValid(self) and IsValid(hit) and not self.Eating) then self:Land(); self:Eat(hit) end end)
			return
		end
		if (self.RepKind == "bugs" and IsValid(ship)) then
			timer.Simple(0, function() if (IsValid(self) and IsValid(ship)) then self:Board(ship) end end)
			return
		end
		if (IsValid(hit) and hit == self.Target and (hit:IsPlayer() or hit:IsNPC())) then
			self.NextBite = 0
			timer.Simple(0, function() if (IsValid(self) and IsValid(hit)) then self:Bite(hit) end end)
		end
		if (speed > (self.RepFallBreak or 750)) then
			if (self.JumpPlan) then R.JumpLanded(self, self:GetPos(), true) end
			local ff = self.FallFrom or {}
			R.Dbg(self, "landed too hard", math.Round(speed), "dropped at line", ff.line, "why", ff.why, "from", tostring(ff.at), "up", tostring(ff.up), "fwd", tostring(ff.fwd), "state", tostring(ff.state), "jump", tostring(self.Jumping))
			timer.Simple(0, function() if (IsValid(self)) then self:FallApart() end end)
			return
		end
		if ((data.HitNormal.z > -0.5 or self.Jumping) and CurTime() - (self.FallT or 0) < 0.15) then return end   -- the jump itself (pushing off)
		if (self.LipPhase and (-data.HitNormal).z < 0.3) then return end   -- going round a lip: brushing its underside or the wall
		if (self.Jumping and data.OurOldVelocity.z > 60 and data.HitNormal.z < -0.5) then return end   -- still rising: its tail brushed the floor
		-- a jump onto a wall, a pillar, a ceiling: it grabs on (a spider), it does not slide down it
		local n = -data.HitNormal
		if (self.Jumping and self.RepClimb and n.z < 0.6 and (not IsValid(hit) or walkable(hit)) and (not self.JumpUp or n:Dot(self.JumpUp) < 0.9 or CurTime() - (self.FallT or 0) > 0.5 or self:GetPos():DistToSqr(self.JumpFrom or self:GetPos()) > 35 * 35) and not (IsValid(hit) and (hit:IsPlayer() or hit:IsNPC() or hit.AGPReplicator))) then
			local at = data.HitPos
			timer.Simple(0, function() if (IsValid(self) and self.Falling and not self.RepGone) then self:Grab(n, at) end end)
			return
		end
		self:Land()
	end

	function ENT:Land()
		self.LipPhase = nil
		if (self.JumpPlan) then
			-- the front feet clamp on where it lands (one such sound in 1.5 s for the whole swarm: ten landing together are not ten sounds)
			if (CurTime() > (R.NextClampSnd or 0)) then R.NextClampSnd = CurTime() + 1.5; self:RepSound("agp_replicator/rep_clamp.wav", 65, 100, 0.6) end
			local ok = self:GetPos():Distance(self.JumpPlan.land) < 60
			R.JumpLanded(self, self:GetPos())
			if (ok) then self.PounceAt = nil end
			-- it lands on its legs and stops there (it does not slide on over the edge it aimed for)
			timer.Simple(0, function()
				local ph = IsValid(self) and self:GetPhysicsObject()
				if (IsValid(ph)) then local v = ph:GetVelocity() ph:SetVelocity(Vector(0, 0, math.min(v.z, 0))) end
			end)
		end
		-- a jump that missed: after 3 misses the swarm thinks of another way (R.Missed); when every way failed, this bug
		-- leaves that target alone for a minute
		if (IsValid(self.PounceAt) and not self.Boarded) then
			self.Ambush = nil
			R.Reward(self, -0.5)
			if (R.Missed(self, self.PounceAt)) then
				self.Avoid = self.Avoid or {}
				self.Avoid[self.PounceAt] = CurTime() + 60
				if (self.Target == self.PounceAt) then self.State, self.Target = "wander", nil end
				R.Dbg(self, "gives up jumping at", self.PounceAt:GetClass())
			end
		end
		self.PounceAt = nil
		self.Falling, self.Jumping = false, nil
		self:SetNWBool("RepFall", false)
		self.RepUp, self.RepFwd = Vector(0, 0, 1), nil
		if (self:GetUp().z < 0.6) then   -- on its back or side: legs flail, then it rolls upright
			self.RightUntil = CurTime() + 1.1
			self:SetNWBool("RepFlail", true)
			self:RepSound("agp_replicator/rep_chatter2.wav", 65, math.random(110, 130), 0.6)
			timer.Simple(1.1, function()
				if (not IsValid(self)) then return end
				self:SetNWBool("RepFlail", false)
				local ph = self:GetPhysicsObject()
				if (IsValid(ph)) then ph:SetVelocity(Vector(0, 0, 120)); ph:AddAngleVelocity(VectorRand() * 200) end
			end)
		end
	end

	-- a random spot nearby: on the ground around home, or (climbing) along the surface it is on; on a wall or ceiling
	-- it often heads back down. Always a spot it can stand on (sv_walk.lua): along a wall or ceiling no further than
	-- that goes - "450 up" a wall 128 high lay far over its top, it climbed after it, turned at the top and fell (the
	-- wall scenes) - and on the ground, not in the air over a drop
	function ENT:WanderSpot(radius)
		local up = self.RepUp or Vector(0, 0, 1)
		local pos = self:GetPos()
		local function along(p) if (R.Anchor) then return (R.Anchor(self, pos, up, p)) end return p end
		if (self.RepClimb and up.z < -0.7) then   -- on a ceiling: somewhere along it
			local a = math.random() * math.pi * 2
			local f = self.RepFwd or self:GetForward()
			local r = f:Cross(up)
			return along(pos + (f * math.cos(a) + r * math.sin(a)) * math.Rand(radius * 0.4, radius))
		end
		if (self.RepClimb and up.z < 0.7) then
			-- on a wall: mostly up or down along it (sideways only now and then)
			local roll = math.random()
			if (roll < 0.45) then return along(pos - Vector(0, 0, radius)) end
			if (roll < 0.8) then return along(pos + Vector(0, 0, radius)) end
			local a = math.random() * math.pi * 2
			local f = self.RepFwd or self:GetForward()
			local r = f:Cross(up)
			return along(pos + (f * math.cos(a) + r * math.sin(a)) * math.Rand(radius * 0.3, radius))
		end
		local base = self.RepHome or pos
		for _ = 1, 6 do
			local a = math.random() * math.pi * 2
			local p = base + Vector(math.cos(a), math.sin(a), 0) * math.Rand(radius * 0.3, radius)
			local tr = util.TraceLine({ start = pos + Vector(0, 0, 16), endpos = p + Vector(0, 0, 16), filter = self, mask = MASK_SOLID })
			if (not tr.Hit) then
				if (not R.Ground) then return p end
				local g = R.Ground(self, p, 400)
				if (g) then return g end
			end
		end
		local a = math.random() * math.pi * 2
		return along(pos + Vector(math.cos(a), math.sin(a), 0) * 60)
	end

	-- a made-up spot far off (a place to scout, the swarm's middle) put on the ground under it - nil over nothing
	function ENT:OnGround(p)
		if (not R.Ground) then return p end
		return (R.Ground(self, p, 2000))
	end

	-- a spot near the swarm's middle to gather at (the middle of bugs on walls and roofs lies in the air)
	function ENT:Gather(cx, rr)
		local v = VectorRand()
		v.z = 0
		return self:OnGround(cx + v * rr) or self:OnGround(cx) or self:WanderSpot(300)
	end

	-- a steering point (round something in its way, aside from another bug): where it really lies along the surface it
	-- is on (sv_walk.lua: R.Anchor), kept with that surface - dropped after the next corner, when reached or after a
	-- moment (PhysicsSimulate). False when there is no room that way.
	function ENT:SetSteer(want, pos)
		local up = self.RepUp or Vector(0, 0, 1)
		local p = want
		if (self.RepClimb and R.Anchor) then
			local why
			p, why = R.Anchor(self, pos, up, want)
			if (why == "edge") then R.Stat("steering kept off an edge") end
		end
		if (p:DistToSqr(pos) < 30 * 30) then return false end
		self.SteerTo, self.SteerUp, self.SteerT = p, up, CurTime()
		return true
	end

	function ENT:MyQueen()
		local best, bd
		for q in pairs(R.queens) do
			if (IsValid(q) and q ~= self and q.RepOwner == self.RepOwner and not q.RepGone) then
				local d = q:GetPos():DistToSqr(self:GetPos())
				if (d < 5000 * 5000 and (not bd or d < bd)) then best, bd = q, d end
			end
		end
		return best
	end

	-- enough metal for a new Replicator: carry it to the Queen, or build it right here
	function ENT:UseStock(here)   -- (here: builds right where it is - on a ship, in a flying one)
		if (self.RepMini) then   -- a small one grows into a full Replicator first
			local b = ents.Create("agp_replicator")
			if (not IsValid(b)) then return end
			b:SetPos(self:GetPos() + Vector(0, 0, 2)); b:SetAngles(Angle(0, self:GetAngles().y, 0))
			b.RepOwner, b.RepParentMind = self.RepOwner, self.Mind
			self.RepGone = true
			self:Remove()
			b:Spawn(); b:Activate()
			b:RepSound("agp_replicator/rep_assemble.wav", 70, 100, 0.7)
			return
		end
		local q = self:MyQueen()
		if (q and not self.Boarded and not here) then self.State, self.Target = "deliver", q return end   -- on a ship: builds right there
		if (R.Full() or not R.RoomForBlocks(R.BLOCKS_PER_BUG)) then return end   -- (R.Full: also while the game is behind)
		self.RepStock = self.RepStock - R.BLOCKS_PER_BUG
		R.Reward(self, 2)   -- a new Replicator
		local back = self:GetPos() - self:GetForward() * 20 + Vector(0, 0, 10)
		for i = 1, R.BLOCKS_PER_BUG do
			local b = R.SpawnBlock(back + VectorRand() * 8, VectorRand() * 60 + Vector(0, 0, 60), self.RepOwner, 1)
			if (b) then b.RepMind = self.Mind end   -- its offspring inherits its character (a little changed)
		end
		self:RepSound("agp_replicator/rep_assemble.wav", 70, 110, 0.7)
	end

	-- eating: a small thing shrinks into the Replicator; from a big one (a ship, a big build) it chews off a piece every
	-- 2 seconds and damages it, until it is used up (then the ship breaks apart the way it does when destroyed). The metal
	-- becomes stock; with 12 blocks' worth it builds a new Replicator or brings it to the Queen.
	local function consume(p)
		R.AteMapItem(p)
		local drv = p.GetDriver and p:GetDriver()
		if (IsValid(drv)) then drv:ExitVehicle() end
		for _, c in ipairs(p:GetChildren()) do if (c:IsPlayer() and c.ExitVehicle) then c:ExitVehicle() end end
		if (p.HullDamage) then p:HullDamage(1e9)          -- the Ha'tak: its own destruction
		else
			local fx = EffectData(); fx:SetOrigin(p:WorldSpaceCenter()); fx:SetMagnitude(4); fx:SetScale(2); fx:SetRadius(8)
			util.Effect("Sparks", fx, true, true)
			p:Remove()
		end
	end

	function ENT:Eat(p)
		-- (the map's gate or DHD while the players' metal is near and it is not alone any more: it leaves it)
		if (R.MapItem(p) and not R.MapFoodOk(self.RepOwner, self:GetPos())) then self.Eating, self.Target, self.State = nil, nil, "wander" self.NextLook = 0 return end
		self.Eating = p
		-- a colonist without a Queen yet that found metal away from its new home: the colony starts here - its home moves
		-- with it, and the Queen is built where the metal is (exploring off from the ring platform is right; only the
		-- home stayed behind)
		if (self.RepHomeRadius and self.RepHome and not self:MyQueen() and self.RepHome:DistToSqr(self:GetPos()) > self.RepHomeRadius ^ 2) then
			self.RepHome = self:GetPos()
			R.Stat("colony moved to the metal it found")
			R.Dbg(self, "colony moves to the metal it found", tostring(self.RepHome))
		end
		-- in a Ha'tak's engine room: the crew is warned (the ship loses power with every crystal they eat)
		local ship = p.AGPShip
		if (p:GetClass() == "agp_hatak_powercrystal" and IsValid(ship) and (ship.CrewSayL or ship.CrewSay) and CurTime() > (ship.AGPRepWarn or 0)) then
			ship.AGPRepWarn = CurTime() + 20
			-- in everyone's own language ("Ha'tak engine room:" in front comes with "engine")
			if (ship.CrewSayL) then ship:CrewSayL("engine", "agp_hkm_c_reps_core", "Replicators at the power core!", true)
			else ship:CrewSay("Ha'tak engine room: Replicators at the power core!", true) end
			R.Stat("at the power core")
		end
		local big = R.IsBig(p)
		local ph = p:GetPhysicsObject()
		local mass = IsValid(ph) and ph:GetMass() or 50
		local dur = big and 2 or math.Clamp(mass / 60, 1.5, 6)
		if (not big) then
			p.RepEaten = true
			p:SetModelScale(0.05, dur)
			if (IsValid(ph)) then ph:EnableMotion(false) end
		else
			-- part of a ship (also the Ha'tak's inside): the bites count for the whole ship, the part itself stays
			local ship = IsValid(p.AGPShip) and p.AGPShip or p
			-- (a StarCore ship - a SpaceGrid hull, a welded prop ship: one hull for the whole ship, kept by its core. The
			-- the bites went to the hull part, which has no health of its own, so each one cost a fixed 10 of the ship's
			-- whole hull)
			local core = R.ShipCore(ship)
			local meal = core or ship
			local sph = ship:GetPhysicsObject()
			if (not meal.RepLeft) then
				local m = IsValid(sph) and sph:GetMass() or mass
				if (core) then
					m = 0
					for _, e in ipairs(core.Parts or {}) do
						local q = IsValid(e) and e:GetPhysicsObject()
						if (IsValid(q)) then m = m + q:GetMass() end
					end
				end
				meal.RepLeft = math.Clamp(math.floor(m / 20), 30, 1500)   -- blocks' worth of metal in it
				-- each bite costs the hull its share: hull and metal run out together (the ship is not destroyed long
				-- before it is eaten - that would throw the whole swarm off it)
				local hp = core and core.HullMax or tonumber(ship.EntHealth) or ship:Health()
				meal.RepHullPerBite = (hp and hp > 0) and math.max(1, hp * 0.9 / meal.RepLeft * 2) or 10
			end
		end
		-- (the author chose the six-layer loop - "a lot of servos in the mouth" - "but fitted there speed of eating"):
		-- the loop runs as fast as the metal goes down. 60 mass a second is the usual meal (its own tempo); a light thing is
		-- nibbled (the meal never takes under 1.5 s: slower), a heavy one is devoured (never over 6 s: faster)
		local tempo = big and 1 or math.Clamp(mass / dur / 60, 0.8, 1.25)
		self.EatSound = CreateSound(self, "agp_replicator/rep_eat_loop.wav")   -- grinding up the metal
		self.EatSound:PlayEx(0.7, 100 * tempo)
		local id = "AGPRepEat" .. self:EntIndex()
		local t0 = CurTime()
		timer.Create(id, 0.25, 0, function()
			if (not IsValid(self) or not IsValid(p) or self.Eating ~= p or self.Falling) then
				timer.Remove(id)
				if (IsValid(self)) then self.Eating = nil; if (self.EatSound) then self.EatSound:Stop() end end
				if (IsValid(p) and not big) then p.RepEaten = nil; p:SetModelScale(1, 0.3) end
				return
			end
			local at = big and p:NearestPoint(self:WorldSpaceCenter()) or p:WorldSpaceCenter()
			local fx = EffectData(); fx:SetOrigin(at); fx:SetNormal(VectorRand()); fx:SetMagnitude(1); fx:SetScale(1); fx:SetRadius(2)
			util.Effect("MetalSpark", fx, true, true)
			if (CurTime() - t0 < dur) then return end
			timer.Remove(id)
			self.Eating = nil
			if (self.EatSound) then self.EatSound:Stop() end
			if (big) then
				local bite = 2   -- a ship is a big meal: small bites, minutes, not seconds
				R.Reward(self, bite / 6)
				local ship = IsValid(p.AGPShip) and p.AGPShip or p
				local core = R.ShipCore(ship)
				local meal = core or ship
				self.RepStock = self.RepStock + bite
				meal.RepLeft = (meal.RepLeft or 30) - bite
				if (core) then
					-- straight into the ship's hull (from inside: no shield in the way, no weapon factor)
					if (StarCore.HullDamage) then StarCore.HullDamage(core, meal.RepHullPerBite or 20) end
				else
					local d = DamageInfo(); d:SetDamage(meal.RepHullPerBite or 20); d:SetDamageType(DMG_SLASH); d:SetAttacker(self); d:SetInflictor(self); d:SetDamagePosition(at)
					ship:TakeDamageInfo(d)
				end
				if (meal.RepLeft <= 0) then
					-- eaten up: all on it let go before it breaks (its blast does not take them; the fall may)
					for b in pairs(R.bugs) do
						-- (inside a flying hull they hold on through its blast - a wreck that stays carries them, a hull that goes
						-- lets them go as it is removed, agp_replicators.lua)
						if (IsValid(b) and (b.Boarded == ship or (core and b.Boarded == core))) then b.BlastSafe = CurTime() + 3; if (not b.BoardInside) then b:LetGo() end end
					end
					self.BlastSafe = CurTime() + 3
					if (core) then
						-- a StarCore ship breaks apart its own way (its setting: a burning wreck or gone) - the hull part is
						-- not simply removed
						core.Hull = 0; core:SetNWInt("starcore_hull", 0)
						if (StarCore.Destroy and not core.Destroyed) then StarCore.Destroy(core) end
					else
						consume(ship)
					end
					self.State = "wander"; self.MoveTo = nil
				end
				-- keeps on chewing (state stays "eat") until it has enough for a new Replicator
				if (self.RepStock >= R.BLOCKS_PER_BUG) then self.State = "wander"; self.NextLook = 0 end
			else
				local got = math.Clamp(math.floor(mass / 20), 2, 24)
				self.RepStock = self.RepStock + got
				R.Reward(self, got / 6)   -- the metal it brought in (12 blocks = a new Replicator = 2)
				R.Stat("eaten")
				R.AteMapItem(p)
				local ship = R.ShipFitting(p) and p.AGPShip
				local pw = R.LurePower(p)
				if (pw and pw >= 3) then R.Fed(self.RepOwner, pw); R.Stat("power eaten") end
				p:Remove()
				if (IsValid(ship)) then   -- a fitting of the ship: gone, and the ship feels it
					local d = DamageInfo(); d:SetDamage(120); d:SetDamageType(DMG_SLASH); d:SetAttacker(self); d:SetInflictor(self); d:SetDamagePosition(self:GetPos())
					ship:TakeDamageInfo(d)
				end
				self.State = "wander"; self.MoveTo = nil
				self.NextLook = 0
			end
		end)
	end

	function ENT:Bite(t)
		-- (dormant: no bites - a leap or a landing from before the emergency brake bit late and clung on again)
		if (CurTime() < (self.NextBite or 0) or not R.Awake()) then return end
		self.NextBite = CurTime() + 0.8
		-- a skirmisher bites once and runs (hit and run while the swarm holds back)
		local h = R.Hive(self.RepOwner)
		if (h.skirmish and h.skirmish[self] and h.mode == "hold") then
			self.SkirmishAway = CurTime() + math.Rand(4, 7)
			self.State, self.Target = "flee", nil
			local away = self:GetPos() - t:GetPos(); away.z = 0
			timer.Simple(0, function() if (IsValid(self)) then self:GoTo(self:GetPos() + away:GetNormalized() * 500, 1.3) end end)
		end
		local d = DamageInfo()
		d:SetDamage(self.RepBite); d:SetDamageType(DMG_SLASH); d:SetAttacker(self); d:SetInflictor(self)
		d:SetDamagePosition(t:WorldSpaceCenter())
		t:TakeDamageInfo(d)
		R.Reward(self, 0.5)
		R.Dealt(self.RepOwner, self.RepBite)
		self:RepSound("agp_replicator/rep_chatter2.wav", 70, math.random(120, 140), 0.7)
		t:EmitSound("physics/metal/metal_grenade_impact_hard" .. math.random(1, 3) .. ".wav", 60, 180, 0.5)
		-- (series) they climb up people: now and then one holds on and crawls up
		if (t:IsPlayer() and t:Alive() and not t:InVehicle() and not self.Clinging and self.RepKind == "bugs" and not self.RepMini and CurTime() > (self.NoClingT or 0) and math.random() < 0.3) then self:Cling(t) end
	end

	-- ---------- holding on to a player: from the legs up to the shoulders, biting; each one makes him slower. He gets
	-- rid of it by shooting it off, by jumping (each jump throws one off, the others may lose their hold) or by spinning
	-- round fast; it lets go when he dies or gets into a vehicle. One thrown off does not grab him again for 5 s (they
	-- jumped back on as fast as he shook them off).
	R.clingers = R.clingers or setmetatable({}, { __mode = "k" })
	function R.ClingCount(p) local n = 0 for b in pairs(R.clingers[p] or {}) do if (IsValid(b) and b.Clinging) then n = n + 1 end end return n end
	function ENT:Cling(p)
		R.clingers[p] = R.clingers[p] or {}
		local n = R.ClingCount(p)
		if (n >= 4) then return end
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		self:SetNotSolid(true)
		self.Falling, self.Jumping = false, nil
		self:SetNWBool("RepFall", false)
		local a = n * 90 + math.random(-25, 25)
		self.Clinging = { p = p, a = a, t0 = CurTime() }
		self:SetParent(p)
		self:SetLocalPos(Vector(math.cos(math.rad(a)) * 13, math.sin(math.rad(a)) * 13, 12))
		self:SetLocalAngles(Angle(-75, a + 180, 0))
		R.clingers[p][self] = true
		p:SetNWInt("AGPRepCling", R.ClingCount(p))
		self.State, self.Target, self.MoveTo, self.Route = "cling", p, nil, nil
		R.Stat("clung on")
		R.Dbg(self, "clings to", p:Nick())
		if (AGP.Hint) then AGP.Hint(p, "agp_rep_hint_cling", "A Replicator is climbing up you! Jump or spin round fast to shake it off, or shoot it off.") end
		--
		self:RepSound("agp_replicator/rep_clamp.wav", 70, 100, 0.8)
	end
	function ENT:Release(fling)
		local c = self.Clinging
		if (not c) then return end
		self.Clinging = nil
		local p = c.p
		if (R.clingers[p]) then R.clingers[p][self] = nil end
		if (IsValid(p)) then p:SetNWInt("AGPRepCling", R.ClingCount(p)) end
		local at = self:GetPos()
		self:SetParent(NULL)
		self:SetPos(at)
		self:SetNotSolid(false)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(true); ph:Wake() end
		local out = IsValid(p) and (at - p:GetPos()) or VectorRand()
		out.z = 0
		self.State, self.NextLook = "wander", CurTime() + 1
		if (fling) then self.NoClingT = CurTime() + 5 end
		self:StartFall(fling and (out:GetNormalized() * 180 + Vector(0, 0, 140)) or Vector(0, 0, 0))
	end
	function ENT:ClingThink(now)
		local c = self.Clinging
		local p = c.p
		if (not IsValid(p) or not p:Alive() or p:InVehicle() or p:GetMoveType() == MOVETYPE_NOCLIP) then self:Release(false) return end
		-- crawling up: from the knees to the shoulders in about 3 s
		local h = math.min(56, 12 + (now - c.t0) * 15)
		local r = math.rad(c.a)
		self:SetLocalPos(Vector(math.cos(r) * 13, math.sin(r) * 13, h))
		if (now > (c.nextBite or 0)) then
			c.nextBite = now + 1.2
			local d = DamageInfo()
			d:SetDamage(math.max(2, self.RepBite * 0.6)); d:SetDamageType(DMG_SLASH); d:SetAttacker(self); d:SetInflictor(self)
			d:SetDamagePosition(self:GetPos())
			p:TakeDamageInfo(d)
			R.Dealt(self.RepOwner, d:GetDamage())
			if (math.random() < 0.4) then self:RepSound("agp_replicator/rep_chatter2.wav", 65, math.random(130, 150), 0.5) end
		end
		-- spinning round fast (over 40 degrees in this 0.1 s): it may lose its hold (jumps: the KeyPress hook below)
		local yaw = p:EyeAngles().y
		if (c.yaw and math.abs(math.AngleDifference(yaw, c.yaw)) > 40 and math.random() < 0.3) then R.Stat("shaken off by turning") self:Release(true) return end
		c.yaw = yaw
	end
	-- a jump (each press, however short - checking the key every 0.1 s missed quick taps): the one that has held on
	-- longest is thrown off, each other one may lose its hold too
	hook.Add("KeyPress", "AGPRepShakeOff", function(p, key)
		if (key ~= IN_JUMP or not R.clingers[p]) then return end
		local list = {}
		for b in pairs(R.clingers[p]) do if (IsValid(b) and b.Clinging) then list[#list + 1] = b end end
		table.sort(list, function(a, b) return a.Clinging.t0 < b.Clinging.t0 end)
		for i, b in ipairs(list) do
			if (i == 1 or math.random() < 0.3) then R.Stat("shaken off") b:Release(true) end
		end
	end)

	-- a jump at the target (1.5 to 4 m away), bites on landing next to it
	-- a hop onto a point: up over a rim it cannot get round, up onto a pedestal (an arc of about t seconds)
	function ENT:HopTo(p, ignore)
		local v, land = R.PlanJump(self, p, ignore, 30)   -- (sv_jump.lua: a spot to land on, an arc it can do)
		if (not v) then return false end
		if (not R.DoJump(self, v, land, R.JumpKind(self:GetPos(), land))) then return false end
		return true
	end
	-- on a wall under a lip (the wall above sticks out): a spot on the wall face above it, reached by a jump out from
	-- the wall, up past the lip and onto it (or nil)
	function ENT:LipSpot(pos, up)
		-- a real lip: something right above it on its wall (else it simply climbs on)
		if (not util.TraceLine({ start = pos + up * 6, endpos = pos + up * 6 + Vector(0, 0, 120), mask = MASK_PLAYERSOLID, filter = self }).Hit) then return end
		-- out from the wall as far as the lip sticks out (40 / 60 / 85), then up beside it
		for _, o in ipairs({ 40, 60, 85 }) do
			local out = pos + up * o
			if (not util.TraceLine({ start = pos + up * 6, endpos = out, mask = MASK_PLAYERSOLID, filter = self }).Hit) then
				for _, h in ipairs({ 50, 80, 110, 140 }) do
					local p = out + Vector(0, 0, h)
					if (util.TraceLine({ start = out, endpos = p, mask = MASK_PLAYERSOLID, filter = self }).Hit) then break end   -- (still under it: further out)
					local face = util.TraceLine({ start = p, endpos = p - up * (o + 30), mask = MASK_PLAYERSOLID, filter = self })
					if (face.Hit and not face.StartSolid and math.abs(face.HitNormal.z) < 0.5 and (face.HitPos - pos):Dot(up) > -4) then return face end
					-- no wall face up there: the top of a cap (a wall's coping, a roof's rim) to get onto
					if (not face.Hit) then
						local over = p - up * (o - 10)
						local top = util.TraceLine({ start = over, endpos = over - Vector(0, 0, h + 20), mask = MASK_PLAYERSOLID, filter = self })
						if (top.Hit and not top.StartSolid and top.HitNormal.z > 0.7 and top.HitPos.z > pos.z + 10) then return top end
					end
				end
			end
		end
	end

	-- round a lip like a spider: out from the wall to just past the lip's edge, straight up beside it to the face above,
	-- then onto that face (it grabs on there). While it does that it does not take hold of the lip's underside.
	function ENT:LipJump(lip)
		local up = self.RepUp or Vector(0, 0, 1)
		local pos = self:GetPos()
		local g = physenv.GetGravity():Length()
		local out = math.max(0, (lip.HitPos - pos):Dot(up)) + 20   -- the face above lies this far out; a little beyond
		-- the underside of the lip (where it must stay below while it goes out)
		local under = util.TraceLine({ start = pos + up * 6, endpos = pos + up * 6 + Vector(0, 0, 200), mask = MASK_PLAYERSOLID, filter = self })
		local top = lip.HitPos.z + 14   -- where it kicks over onto the face
		local t1 = 0.18
		-- 1. out (holding its height)
		local v1 = up * (out / t1) + Vector(0, 0, 0.5 * g * t1)
		if (not R.DoJump(self, v1, lip.HitPos, R.JumpKind(pos, lip.HitPos, true))) then return false end
		self.LipPhase = true
		timer.Simple(t1, function()
			if (not IsValid(self) or not self.Falling or self.RepGone) then if (IsValid(self)) then self.LipPhase = nil end return end
			-- 2. straight up beside the lip, to the height of the face above
			local ph = self:GetPhysicsObject()
			if (not IsValid(ph)) then return end
			local dz = math.max(10, top - self:GetPos().z)
			local vz = math.sqrt(2 * g * dz)
			ph:SetVelocity(Vector(0, 0, vz))
			timer.Simple(vz / g - 0.03, function()
				if (not IsValid(self) or not self.Falling or self.RepGone) then if (IsValid(self)) then self.LipPhase = nil end return end
				-- 3. onto the face
				self.LipPhase = nil
				local ph2 = self:GetPhysicsObject()
				if (IsValid(ph2)) then ph2:SetVelocity(-up * 240 + Vector(0, 0, 40)) end
			end)
		end)
		R.Dbg(self, "lip: out", math.Round(out), "under", under.Hit and math.Round(under.HitPos.z - pos.z) or "-", "up to", math.Round(top - pos.z))
		return true
	end

	-- straight onto a wall or a pillar (it grabs on where it hits: ENT:Grab)
	function ENT:WallJump(at, n)
		local v = R.JumpTo(self, at - n * 2)   -- (aimed at the face itself: it must touch it to grab on)
		if (not v) then return false end
		if (not R.DoJump(self, v, at, R.JumpKind(self:GetPos(), at, true))) then return false end
		return true
	end

	-- a jump that hit a wall, a pillar or a ceiling: it holds on there like a spider and climbs on from there
	function ENT:Grab(n, at)
		self.LipPhase = nil
		self.SteerTo = nil   -- (a steering point from before the jump, down on the floor, held it there)
		if (self.JumpPlan) then R.JumpLanded(self, at) end
		self.PounceAt = nil
		self.Falling, self.Jumping = false, nil
		self:SetNWBool("RepFall", false)
		local f = (self.MoveTo or (at + Vector(0, 0, 100))) - at
		f = f - n * f:Dot(n)
		if (f:LengthSqr() < 1) then f = Vector(0, 0, 1) - n * n.z end
		if (f:LengthSqr() < 1e-3) then f = n:Angle():Up() end
		f:Normalize()
		local p = at + n * 4
		self.RepUp, self.RepFwd, self.RepAt, self.RepWrapT = n, f, p, CurTime()
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetVelocity(Vector(0, 0, 0)); ph:SetAngleVelocity(Vector(0, 0, 0)); ph:SetPos(p); ph:SetAngles(f:AngleEx(n)) end
		self.LastPos, self.LastMoveT = p, CurTime()
		R.Stat("grabbed a wall")
		R.Dbg(self, "grabs on", "up", math.Round(n.z, 2))
	end

	function ENT:Leap(t)
		local ph = self:GetPhysicsObject()
		if (not IsValid(ph)) then return end
		-- aimed (sv_jump.lua) at where it will be: its middle, plus how it moves while the bug is in the air
		local aim = t:WorldSpaceCenter()
		local v, T = R.JumpTo(self, aim + t:GetVelocity() * 0.4, t)
		if (v) then v, T = R.JumpTo(self, aim + t:GetVelocity() * T, t) end
		if (not v) then return end   -- no clean arc to it from here: it runs at it instead
		self.NextLeap = CurTime() + math.Rand(3, 5)
		if (not R.DoJump(self, v, aim + t:GetVelocity() * T, "leap")) then return end   -- (no leap: e.g. its arc runs into an incoming gate)
		timer.Simple(math.max(0.3, T - 0.05), function()
			if (IsValid(self) and IsValid(t) and t:WorldSpaceCenter():Distance(self:WorldSpaceCenter()) < self.RepReach + 30) then
				self.NextBite = 0; self:Bite(t)
			end
		end)
	end

	-- ---------- the brain
	-- Each bug has its own character (boldness, curiosity, how much it keeps to the others), weighs what it could do
	-- now and picks one - roles from the Queen, the swarm's memory and its own senses change the weights. No fixed script:
	-- the same situation can end differently for two bugs.
	local function mind(self)
		if not self.Mind then
			local p = self.RepParentMind
			local function trait(v) return math.Clamp((v or 1) + math.Rand(-0.25, 0.25), 0.5, 1.6) end
			self.Mind = { bold = trait(p and p.bold), curious = trait(p and p.curious), social = trait(p and p.social) }
		end
		return self.Mind
	end

	-- the walking loop, the two calls and the clicks are the series' own sounds now (cut from the author's episodes):
	-- they play at their own pitch, only a few percent apart - the old generated ones were thrown between 65 and 150
	--
	local SERIES = { ["agp_replicator/rep_chatter2.wav"] = true, ["agp_replicator/rep_clamp.wav"] = true }
	-- both are out of the game and their lines out of the code: those moments make no sound until a call without music is
	-- found in the series
	--
	function ENT:RepSound(snd, lvl, pitch, vol)
		if (self.RepSilent) then return end   -- a survivor makes no sound
		if (SERIES[snd]) then pitch = math.random(96, 104) end
		self:EmitSound(snd, lvl, pitch, vol)
	end

	local function avoided(self, e) return self.Avoid and self.Avoid[e] and self.Avoid[e] > CurTime() end

	-- where it can see / smell / hear: enemies and metal
	local function sense(self, pos)
		local enemy, ed, metal, ms, full
		local mapOk   -- (the map's gate, DHD ...: only for a swarm of one, or with no metal of the players' near - R.MapFoodOk)
		for _, e in ipairs(R.SenseNear(pos, math.max(self.RepSight, self.RepSmell))) do
			if ((e:IsPlayer() or e:IsNPC()) and R.MayAttack(self, e)) then
				local d = e:GetPos():DistToSqr(pos)
				if (d < self.RepSight ^ 2 and (not ed or d < ed)) then enemy, ed = e, d end
			elseif (self.RepSmell > 0 and R.Edible(e) and not avoided(self, e)) then
				if (mapOk == nil and R.MapItem(e)) then mapOk = R.MapFoodOk(self.RepOwner, pos) end
				R.Remember(self.RepOwner, e)
				if (R.MapItem(e) and not mapOk) then   -- (left alone)
				elseif (R.Eaters(e) < R.BiteSlots(e) or self.Target == e) then   -- room there (the swarm knows who is going)
					-- technology first, then the nearest
					local s = math.sqrt(e:GetPos():DistToSqr(pos)) / R.TechValue(e)
					if (not ms or s < ms) then metal, ms = e, s end
				elseif (R.IsShip(e)) then
					full = e   -- a ship with every place round it taken (maybe a way on top of it)
				end
			end
		end
		return enemy, ed and math.sqrt(ed), metal, full
	end

	-- ---------- a target it cannot reach by walking (a ship hovering above, someone on a roof): find a way up - a high
	-- spot the swarm knows, else the nearest wall or building next to the target - climb it, and from there jump at the
	-- target in an arc; a bug that hits a ship clings to it and eats it from there
	-- the craft a player flies (the Jumper and the CAP ships keep their own links)
	local function craftOf(p)
		if (not (IsValid(p) and p:IsPlayer())) then return nil end
		for _, e in ipairs({ p:GetNWEntity("ScriptedVehicle"), p:GetNWEntity("jumper"), p:GetNWEntity("JumperPassenger"), IsValid(p:GetVehicle()) and p:GetVehicle():GetParent() or NULL }) do
			if (IsValid(e) and (R.IsShip(e) or IsValid(e.AGPShip))) then return IsValid(e.AGPShip) and e.AGPShip or e end
		end
	end
	R.CraftOf = craftOf

	function ENT:LaunchSpot(tp, side)
		-- known high places near the target (where bugs have stood before); "side": not from above, from a wall beside it
		local best, bs
		for _, c in ipairs(side and {} or R.Map.Near(tp, 520)) do
			local flat = Vector(c.p.x - tp.x, c.p.y - tp.y, 0):Length()
			if (c.p.z > tp.z - 220 and flat < 500 and flat > 40 and not c.noLaunch) then
				local s = -math.abs(c.p.z - tp.z) * 0.4 - flat - c.d * 100
				if (not bs or s > bs) then best, bs = c.p, s end
			end
		end
		if (best) then return best, "known" end
		-- else: feel around the target for walls (the side of a building) and climb up there
		local near, nd
		for a = 0, 330, 30 do
			local dir = Angle(0, a, 0):Forward()
			local from = Vector(tp.x, tp.y, math.max(tp.z - 300, self:GetPos().z + 30))
			local tr = util.TraceLine({ start = from, endpos = from + dir * 1200, mask = MASK_PLAYERSOLID_BRUSHONLY })
			if (tr.Hit and math.abs(tr.HitNormal.z) < 0.3 and (not nd or tr.Fraction < nd)) then near, nd = tr, tr.Fraction end
		end
		if (near) then
			-- the wall: walk to its foot, then up along it to the target's height
			return Vector(near.HitPos.x, near.HitPos.y, tp.z) + near.HitNormal * 4, "wall"
		end
	end

	-- out of reach (in the air, up on something): find a launch spot, climb there, jump. Returns true while it is busy
	-- with that (used for prey and for food: a ship hovering above is both)
	function ENT:Reach(aim, now, pos)
		-- out of reach = even its nearest part is high above (a hovering ship); a gate standing on the ground is not
		local ap = aim:NearestPoint(pos)
		-- a bug reaches about 45 units up: anything whose lowest near part is higher is out of reach (a hovering ship, a
		-- shelf on a building); things standing on the ground (a gate's foot) are not
		if (not self.RepClimb or ap.z - pos.z <= 45) then self.Ambush = nil return false end
		-- (near enough to bite from where it stands: no jump - a generator frozen 46 over a curb, its foot 60 over the bug,
		-- 72 from its middle: it jumped beside it and landed back again for 25 s and never ate)
		local c0 = self:WorldSpaceCenter()
		if (aim:NearestPoint(c0):Distance(c0) < self.RepReach + 60) then self.Ambush = nil return false end
		-- (standing on something - a generator on a roof, a ship parked on a tower: it walks there by the way across the map,
		-- which climbs walls and beams (sv_feltnav.lua). The launch spot and the jump are for what hovers free and for prey.
		-- A generator on freespace13's tower sent it to a "launch spot" in a corner of a building, where it wobbled for a
		-- minute)
		if (not (aim:IsPlayer() or aim:IsNPC()) and R.Nav and R.cv.nav:GetBool()) then
			local mn, mx = aim:WorldSpaceAABB()
			local c = (mn + mx) * 0.5
			-- (from its top down: from its middle the trace started inside the platform it stands half sunk in - "not on
			-- anything", and the bug jumped at it from halfway up the tower and fell apart) (80 under
			-- it: a generator frozen 40-46 over a roof was "on nothing" - the bug climbed the tall wall to a launch spot,
			-- jumped off the wall, landed 771 off and fell apart; random round seed 86508)
			local tr = util.TraceLine({ start = Vector(c.x, c.y, mx.z + 2), endpos = Vector(c.x, c.y, mn.z - 80), mask = MASK_PLAYERSOLID_BRUSHONLY })
			if (tr.Hit and not tr.StartSolid) then
				self.Ambush = nil
				-- (its goal on what it stands on, under its side nearest the bug: the ship's own middle floats 100 over the
				-- roof, a goal in the air gets no way across the map - 0 of 3 got onto the roof)
				local np = aim:NearestPoint(pos)
				local st = util.TraceLine({ start = np + Vector(0, 0, 8), endpos = np - Vector(0, 0, 400), mask = MASK_PLAYERSOLID_BRUSHONLY })
				local g = (st.Hit and not st.StartSolid) and st.HitPos + Vector(0, 0, 4) or tr.HitPos + Vector(0, 0, 4)
				-- (there - on the roof beside the ship, its hull still over 45 up: the jump onto it below takes over; walking
				-- on round it the bugs never got to eat)
				local there = Vector(np.x - pos.x, np.y - pos.y, 0):Length() < 160 and pos.z > g.z - 40
				if (not there) then
					if (not self.Goal or self.Goal:DistToSqr(g) > 80 * 80) then self:GoTo(g, 1) end
					return true
				end
			end
		end
		local up0 = self.RepUp or Vector(0, 0, 1)
		local flat = Vector(ap.x - pos.x, ap.y - pos.y, 0):Length()
		-- on the way up to a higher launch spot: climb on first (a jump from halfway up the wall falls short)
		local climbing = self.Ambush and self.Ambush.z > pos.z + 40 and up0.z < 0.7
		local tactic = R.Tactic(self.RepOwner, aim)
		if (tactic == "tower" and ap.z - pos.z > 150) then return self:Tower(aim, ap, now, pos) end   -- the plan is the tower: no long jumps from below
		if (pos.z > ap.z - 260 and flat < 650 and now > (self.NextLeap or 0) and not climbing) then
			-- the jump rises: the free way is checked from well above it (a low rim at an edge must not stop it)
			local los = util.TraceHull({ start = pos + up0 * 40, endpos = aim:NearestPoint(pos + up0 * 40), mins = Vector(-4, -4, -3), maxs = Vector(4, 4, 3), filter = { self, aim }, mask = MASK_SOLID_BRUSHONLY })
			if (not los.Hit) then self:Pounce(aim) return true end
		end
		if (tactic == "tower") then return self:Tower(aim, ap, now, pos) end
		-- (kept while the target stays where it is: picked anew every 8 s, the spot - worked out from the target's point
		-- nearest the bug, which moves as it climbs - jumped from one side of a roof's corner to the other, and it went
		-- back and forth on the wall; repfs13 the roof corner)
		local tpos = aim:GetPos()
		if (not self.Ambush or now > (self.AmbushUntil or 0) or not self.AmbushFor or self.AmbushFor:DistToSqr(tpos) > 120 * 120) then
			local s = self:LaunchSpot(ap, tactic == "side")
			if (not (self.Ambush and s and s:DistToSqr(self.Ambush) < 150 * 150)) then self.Ambush = s end
			self.AmbushFor, self.AmbushUntil = tpos, now + 30
		end
		if (self.Ambush) then
			-- standing on the spot and still no jump: this spot is no good (in the way, too far) - next time another
			if (self.Ambush:DistToSqr(pos) < 70 * 70 and now > (self.NextLeap or 0)) then
				local c = R.Map.cells[R.Map.Key(self.Ambush)]
				if (c) then c.noLaunch = true end
				self.Ambush = nil
				R.Dbg(self, "launch spot no good")
				return true
			end
			if (not self.Goal or self.Goal:DistToSqr(self.Ambush) > 100 * 100) then self:GoTo(self.Ambush, 1.2); R.Dbg(self, "launch spot", tostring(self.Ambush), "for", aim:GetClass())
			else self.MoveTo = self.Route and self.Route[self.RouteI] or self.Ambush end   -- always on the way there (also after being stuck)
			return true
		end
		return false
	end

	-- a tower of their own bodies: right below the target the first bug holds still, the next ones climb onto it, one
	-- on top of the other, until the top is high enough - then the one on top jumps. The tower stands until the target
	-- is gone or 45 s are over, then they let go and drop (they land on their legs or fall apart and rebuild).
	local TOWER_STEP = 20
	function ENT:Tower(aim, ap, now, pos)
		local h = R.Hive(self.RepOwner)
		h.towers = h.towers or {}
		local T = h.towers[aim]
		if (T and now > T.till) then R.TowerDown(T) h.towers[aim] = nil T = nil end
		if (not T) then
			local tr = util.TraceLine({ start = ap - Vector(0, 0, 20), endpos = ap - Vector(0, 0, 4000), mask = MASK_PLAYERSOLID_BRUSHONLY })
			-- a tower needs enough bodies: the swarm knows how many free, healthy bugs it has near and how tall they are
			-- (a small one is half a step); the top one jumps the last 200 units
			local need = tr.Hit and (ap.z - tr.HitPos.z - 200) or 1e9
			local me = R.Self(self.RepOwner)
			local near = {}
			for _, b in ipairs(me.free) do
				if (b ~= self and b.RepKind == "bugs" and b.RepClimb and b:GetPos():DistToSqr(pos) < 2500 * 2500) then near[#near + 1] = b end
			end
			table.sort(near, function(x, y) return x:GetPos():DistToSqr(tr.HitPos) < y:GetPos():DistToSqr(tr.HitPos) end)
			local crew, height = {}, 0
			for _, b in ipairs(near) do
				if (height >= need) then break end
				crew[#crew + 1] = b
				height = height + R.BodyHeight(b)
			end
			if (not tr.Hit or ap.z - tr.HitPos.z > 700 or height < need) then   -- too high for a tower, or too few: the next idea
				R.Dbg(self, "tower not possible", "need", math.Round(need), "have", height, "bugs", #near)
				local _, t = R.Tactic(self.RepOwner, aim); t.misses = 2; R.Missed(self, aim)
				return false
			end
			T = { base = tr.HitPos, n = {}, till = now + 45, aim = aim, h = 0 }
			h.towers[aim] = T
			-- the Queen calls exactly the bugs it needs (the nearest free ones), they drop what they do and come
			for _, b in ipairs(crew) do
				b.State, b.Target, b.NextLook = self.State, aim, now + 12
				b.Route, b.Goal = nil, nil
			end
			R.Stat("towers")
			R.Dbg(self, "builds a tower under", aim:GetClass(), "height", math.Round(ap.z - tr.HitPos.z))
		end
		-- a body in it was lost (shot apart): the tower falls down, the swarm builds it again
		for i = #T.n, 1, -1 do
			if (not IsValid(T.n[i]) or T.n[i].RepGone) then R.TowerDown(T) T.h = 0 R.Stat("tower fell") break end
		end
		local base = T.base
		-- a queue at the foot: the first in line climbs, the others wait in a ring round it, each in its own place, and
		-- move up in turn (they do not all push into the same spot)
		T.q = T.q or {}
		if (T.qt ~= now) then
			T.qt = now
			for i = #T.q, 1, -1 do local b = T.q[i] if (not IsValid(b) or b.RepGone or b.InTower or b.Falling or b.Target ~= aim) then table.remove(T.q, i) T.ver = (T.ver or 0) + 1 end end
			T.qi = {}
			for i, b in ipairs(T.q) do T.qi[b] = i end
		end
		local place = T.qi[self]
		if (not place) then T.q[#T.q + 1] = self; place = #T.q; T.qi[self] = place end
		if (place > 1) then
			local wait = base + Angle(0, place * 47, 0):Forward() * (110 + math.floor(place / 8) * 50)
			if (wait:DistToSqr(pos) > 40 * 40) then
				if (not self.Goal or self.Goal:DistToSqr(wait) > 60 * 60) then self:GoTo(wait, 1.1) end
				if (not self.Route) then self.MoveTo = wait end
			else
				self.MoveTo, self.Route, self.Goal = nil, nil, nil   -- in its place: waits for its turn
				-- and sleeps until the queue moves on (or the tower falls), at the latest for a second
				self.TowerWait = { T = T, ver = T.ver or 0, till = now + 1, tg = self.Target }
			end
			return true
		end
		if (Vector(pos.x - base.x, pos.y - base.y, 0):LengthSqr() > 55 * 55) then
			if (not self.Goal or self.Goal:DistToSqr(base) > 40 * 40) then self:GoTo(base, 1.2) end
			if (not self.Route) then self.MoveTo = base end
			return true
		end
		if (T.busy and now < T.busy) then self.MoveTo = nil return true end   -- one climbs at a time
		-- at the foot: climb up the others to the top (each body as tall as it is)
		local top = base + Vector(0, 0, (T.h or 0) + 4)
		self.MoveTo, self.Route, self.Goal = nil, nil, nil
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		self.InTower = T
		self:SetNWBool("RepTower", true)
		local from = self:GetPos()
		local high = top.z + R.BodyHeight(self) > ap.z - 230 or #T.n >= 36
		local steps, i = 8, 0
		T.busy = now + steps * 0.06 + 0.1
		local id = "AGPRepTower" .. self:EntIndex()
		timer.Create(id, 0.06, steps, function()
			if (not IsValid(self) or self.RepGone) then return end
			i = i + 1
			local f = i / steps
			self:SetPos(LerpVector(f, from, top) + Vector(0, 0, math.sin(f * math.pi) * 10))
			if (i < steps) then return end
			if (high and IsValid(aim)) then   -- the top: jump from here
				self.InTower = nil
				self:SetNWBool("RepTower", false)
				if (IsValid(ph)) then ph:EnableMotion(true); ph:Wake() end
				self.NextLeap = 0
				self:Pounce(aim)
				T.jumps = (T.jumps or 0) + 1
			else
				T.n[#T.n + 1] = self
				T.h = (T.h or 0) + R.BodyHeight(self)
				self:SetAngles(Angle(0, math.random(0, 359), 0))
			end
		end)
		self:RepSound("agp_replicator/rep_chatter2.wav", 65, math.random(100, 120), 0.6)
		return true
	end
	-- a bridge of blocks over a deep gap (roof to roof, roof to tower): the builders walk to the edge, one after the
	-- other falls into its 12 blocks, and the blocks fly out over the gap and lock into a beam of rungs, as wide as a
	-- bug when there are bugs enough; when it touches the other side the others run over it. Unused for 25 s (or never finished in
	-- 40): the blocks fly back to the nearer side and build the bugs again (each keeps its character). The ARG/Dakara
	-- on one block: the whole beam lets go and falls. Checked first: deep enough (else they simply climb down and up),
	-- not too wide for the bugs near; the other side may be a little higher or lower (a sloped beam).
	--
	local BLK = 8   -- (one block's length)
	-- in a bridge every block grows into a plate 2.5 times its size (20 x 9.5), laid across the way, two side by
	-- side (40 wide, a bug's width), a row every 9 units - they overlap a little, no gaps. As many blocks as the old
	-- thin beam needed (4 builders over 180), solid to walk on, a player too.
	--
	local PLATE = 2.5
	local ROW = 9
	local PW = BLK * PLATE   -- (a plate's length, across the way: 20)
	local function plate(bl)   -- locked in: a body as big as it looks
		local mn, mx = bl:GetModelBounds()
		bl:PhysicsInitBox(mn * PLATE, mx * PLATE)
		bl.RepPlate = true
		local ph = bl:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
	end
	-- a plate let go (the bridge down or broken): a block again
	function R.PlateBack(bl)
		if (not bl.RepPlate) then return end
		bl.RepPlate = nil
		bl:SetModelScale(1, 0.3)
		bl:PhysicsInit(SOLID_VPHYSICS)
	end
	local function down(p, len) return util.TraceLine({ start = p, endpos = p - Vector(0, 0, len), mask = MASK_PLAYERSOLID_BRUSHONLY }) end
	function ENT:GapAhead(pos, goal)
		local dir = goal - pos; dir.z = 0
		local gd = dir:Length()
		if (gd < 150) then return end
		dir:Normalize()
		if (down(pos + dir * 36 + Vector(0, 0, 20), 100).Hit) then return end   -- still ground ahead: no edge
		for d = 80, 480, 20 do
			local far = down(pos + dir * d + Vector(0, 0, 110), 220)
			if (far.Hit and not far.StartSolid and far.HitNormal.z > 0.9 and math.abs(far.HitPos.z - pos.z) < 100) then
				if (d > gd + 40) then return end
				if (down(pos + dir * (d * 0.5) + Vector(0, 0, 10), 420).Hit) then return end   -- not deep: down and up is fine
				-- (nothing in the way of the beam)
				if (util.TraceLine({ start = pos + dir * 30 + Vector(0, 0, 6), endpos = far.HitPos + Vector(0, 0, 6), mask = MASK_PLAYERSOLID_BRUSHONLY }).Hit) then return end
				local a = pos + dir * 30
				return Vector(a.x, a.y, pos.z), far.HitPos, dir, d
			end
		end
	end
	function ENT:Bridge(pos, now)
		local h = R.Hive(self.RepOwner)
		h.bridges = h.bridges or {}
		local goal = self.BridgeGoal or self.Goal or self.MoveTo
		local gdir = goal - pos; gdir.z = 0
		if (gdir:LengthSqr() < 150 * 150) then self.BridgeGoal = nil return false end
		gdir:Normalize()
		-- a bridge of the swarm near on its way (its goal lies on over the other side): it walks to the head of the bridge
		-- and over it - or waits there beside it while it is still being built (it climbed down the wall before the beam
		-- was finished and nobody used it)
		for _, T in pairs(h.bridges) do
			local across = goal - T.a; across.z = 0
			if (math.abs(pos.z - T.a.z) < 60 and T.a:DistToSqr(pos) < 450 * 450 and across:Length() > 150 and across:GetNormalized():Dot(T.dir) > 0.6) then
				if (T.st:DistToSqr(pos) < 70 * 70 and T.done) then   -- (70: on a small roof the crowd round the head could not all get within 50)
					self.Crossing, self.AfterCross, self.BridgeGoal = T, goal, nil
					T.used = now
					R.Stat("bridge crossings")
					return true
				end
				if (not T.done and T.st:DistToSqr(pos) < 50 * 50 and #T.blocks + T.coming < T.need) then self.BridgeGoal = nil return self:JoinBridge(T, now) end
				self.BridgeGoal = goal
				-- (where it waits: a little back from the head, on the roof - beside it on a narrow wall top they fell off)
				local wait = T.st   -- (the head of it on the roof - its point T.a is out over the edge: they walked off the roof to it)
				if (not T.done) then
					wait = nil
					for _, q in ipairs({ T.st - T.dir * 50 + T.dir:Cross(Vector(0, 0, 1)) * math.Rand(-30, 30), T.st - T.dir * 60, T.st - T.dir * 30, T.st - T.dir * 90, T.st - T.dir * 120 }) do
						local tr = down(q + Vector(0, 0, 20), 50)
						-- (roof all round it, 24 units each way: on the very edge of the narrow brown roof the waiting
						-- crowd pushed each other off)
						local all = tr.Hit and tr.HitNormal.z > 0.9
						for _, o in ipairs({ Vector(24, 0, 0), Vector(-24, 0, 0), Vector(0, 24, 0), Vector(0, -24, 0) }) do
							if (all and not down(q + o + Vector(0, 0, 20), 50).Hit) then all = false end
						end
						if (all) then wait = tr.HitPos + Vector(0, 0, 2) break end
					end
					-- (none of those: further back and to the sides; not where it stands - on a narrow roof that was its very
					-- edge, and it fell from there, 24 times in a test)
					if (not wait) then
						local side = T.dir:Cross(Vector(0, 0, 1))
						for _, back in ipairs({ 160, 200, 250 }) do
							for _, sd in ipairs({ 0, 40, -40 }) do
								local q = T.st - T.dir * back + side * sd
								local tr = down(q + Vector(0, 0, 20), 50)
								if (not wait and tr.Hit and tr.HitNormal.z > 0.9 and math.abs(tr.HitPos.z - T.st.z) < 30) then wait = tr.HitPos + Vector(0, 0, 2) end
							end
						end
					end
					wait = wait or (T.st - T.dir * 120)
				end
				self.MoveTo, self.Route = wait, nil
				if (self.WaitSaidT ~= T) then self.WaitSaidT = T R.Dbg(self, T.done and "to the bridge head" or "waits at the bridge", "from", tostring(pos), "to", tostring(wait), "head", tostring(T.a), "dir", tostring(T.dir)) end
				self.NextLook = math.max(self.NextLook or 0, now + 2)
				return true
			end
		end
		self.BridgeGoal = nil
		local a, b, dir, d = self:GapAhead(pos, goal)
		if (not a) then return false end
		-- (one bridge at a time in a place: a second one started next to it took half the builders - neither was finished)
		for _, T in pairs(h.bridges) do
			if (not T.done and T.a:DistToSqr(pos) < 800 * 800) then self.BridgeJob = T; self.MoveTo, self.Route, self.Goal = T.st, nil, nil return true end
		end
		local len = a:Distance(b) + BLK
		local per = self.RepBlocks or 12
		local me = R.Self(self.RepOwner)
		local near = {}
		for _, x in ipairs(me.free) do
			if (x ~= self and x.RepClimb and not x.RepMini and x:GetPos():DistToSqr(pos) < 1500 * 1500) then near[#near + 1] = x end
		end
		table.sort(near, function(x, y) return x:GetPos():DistToSqr(pos) < y:GetPos():DistToSqr(pos) end)
		-- two plates side by side (40 wide) when the bugs near are enough for it, else one (20); never more than 60 %
		-- of the bugs near (the rest crosses)
		local can = math.min(math.floor((#near + 1) * 0.6), 8)
		local rows = math.ceil(len / ROW)
		local across = (math.ceil(rows * 2 / per) <= can) and 2 or 1
		local need = rows * across
		local builders = math.ceil(need / per)
		if (builders > can) then return false end
		local T = { a = a, st = Vector(pos.x, pos.y, pos.z) - dir * 10, b = b, dir = dir, across = across, need = need, blocks = {}, minds = {}, used = now, prog = now, id = tostring(a), owner = self.RepOwner, h = h, coming = 0 }
		h.bridges[T.id] = T
		R.Stat("bridges")
		R.Dbg(self, "builds a bridge", "gap", math.Round(d), "blocks", need, "builders", builders, "wide", across * PW, "head", tostring(a), "dir", tostring(dir), "from", tostring(pos))
		for k = 1, builders - 1 do
			local x = near[k]
			x.BridgeJob = T; x.Route, x.Goal = nil, nil; x.MoveTo = T.st; x.State = "regroup"; x.NextLook = now + 20
		end
		timer.Create("AGPRepBridgeWatch" .. T.id, 1, 0, function()
			local t = CurTime()
			if (h.bridges[T.id] ~= T) then timer.Remove("AGPRepBridgeWatch" .. T.id) return end
			if ((T.done and t - T.used > 25) or (not T.done and t - T.prog > 40)) then R.BridgeDown(h, T) end
		end)
		return self:JoinBridge(T, now)
	end
	-- one builder falls into its blocks at the edge; they fly to the next places in the beam
	function ENT:JoinBridge(T, now)
		self.BridgeJob = nil
		if (T.dead) then return false end
		if (#T.blocks + T.coming >= T.need) then return true end   -- (enough: it waits for the beam and runs over it)
		if (T.busy and now < T.busy) then return true end
		T.busy = now + 0.6
		T.prog = now
		local n = math.min(self.RepBlocks or 12, T.need - #T.blocks - T.coming)
		T.coming = T.coming + n
		T.minds[#T.minds + 1] = self.Mind or false
		local from = self:WorldSpaceCenter()
		local owner = self.RepOwner
		sound.Play("agp_replicator/rep_break.wav", from, 70, math.random(110, 125))
		R.Stat("bridge builders")
		self.RepGone = true
		if (self.Clinging) then self:Release(false) end
		R.Brain.Settle(self)
		self:Remove()
		local span = T.b - T.a
		local side = T.dir:Cross(Vector(0, 0, 1))
		local ang = span:Angle()
		ang:RotateAroundAxis(ang:Up(), 90)   -- (laid across the way)
		for i = 1, n do
			timer.Simple(0.07 * i, function()
				T.coming = T.coming - 1
				if (T.dead) then return end
				local k = #T.blocks   -- (its place: the next row along, the plates of a row side by side)
				local along = math.floor(k / T.across) * ROW + ROW * 0.5
				local off = ((k % T.across) - (T.across - 1) / 2) * PW
				local f = math.Clamp(along / span:Length(), 0, 1.05)
				local to = T.a + span * f + side * off - Vector(0, 0, 2.5)
				local bl = R.SpawnBlock(from + VectorRand() * 4, nil, owner, 1e9 + 1)
				if (not bl) then return end
				bl.RepClaimed, bl.RepBridge = true, T
				local ph = bl:GetPhysicsObject()
				if (IsValid(ph)) then ph:EnableMotion(false) end
				bl:SetCollisionGroup(COLLISION_GROUP_DEBRIS)   -- (through everything while it flies: solid it knocked the waiting bugs off the roof)
				bl:SetModelScale(PLATE, 0.45)   -- (it grows into a plate on its way)
				T.blocks[#T.blocks + 1] = bl
				local p0, a0, t0 = bl:GetPos(), bl:GetAngles(), CurTime()
				local id = "AGPRepBridgeFly" .. bl:EntIndex()
				timer.Create(id, 0.03, 0, function()
					if (not IsValid(bl) or T.dead) then timer.Remove(id) return end
					local e = math.min(1, (CurTime() - t0) / 0.45)
					local s = e * e * (3 - 2 * e)
					bl:SetPos(LerpVector(s, p0, to) + Vector(0, 0, math.sin(s * math.pi) * 14))
					bl:SetAngles(LerpAngle(s, a0, ang))
					if (e < 1) then return end
					timer.Remove(id)
					plate(bl)
					bl:SetPos(to) bl:SetAngles(ang)
					bl:SetCollisionGroup(COLLISION_GROUP_NONE)   -- (locked in: solid - the bugs, and a player who dares, walk on it)
					T.prog = CurTime()
					T.placed = (T.placed or 0) + 1
					if (not T.done and T.placed >= T.need) then
						T.done = true; T.used = CurTime()
						R.Stat("bridges finished")
						sound.Play("agp_replicator/rep_assemble.wav", T.a + span * 0.5, 72, 90)
						-- (it is ready: every bug of the swarm near that waits to go over is called to its head at once - they
						-- noticed it only when they happened to look again, and meanwhile their minds sent them elsewhere;
						-- three bridges in a test stood finished and nobody went over)
						local now2 = CurTime()
						for b2 in pairs(R.bugs) do
							if (IsValid(b2) and b2.RepOwner == T.owner and not b2.Falling and not b2.Crossing and (b2.BridgeGoal or b2.WaitSaidT == T) and b2:GetPos():DistToSqr(T.st) < 700 * 700) then
								b2.MoveTo, b2.Route, b2.NavWait = T.st, nil, nil
								b2.NextLook = math.max(b2.NextLook or 0, now2 + 8)
								b2.NextGap = 0
							end
						end
					end
				end)
			end)
		end
		return true
	end
	-- not needed any more: the blocks fly back to the nearer side and build the bugs again
	function R.BridgeDown(h, T)
		if (T.dead) then return end
		T.dead = true
		h.bridges[T.id] = nil
		timer.Remove("AGPRepBridgeWatch" .. T.id)
		local left = {}
		for _, bl in ipairs(T.blocks) do if (IsValid(bl) and not bl.RepDead) then left[#left + 1] = bl end end
		-- (all of them go to the side where the swarm's work is: where the bugs near are hunting, eating or going;
		-- only when that is even, each group to the nearer side)
		local mid = (T.a + T.b) * 0.5
		local pull = 0
		for b in pairs(R.bugs) do
			if (IsValid(b) and not b.RepGone and b.RepOwner == T.owner and b:GetPos():DistToSqr(mid) < 2500 * 2500) then
				local at = (IsValid(b.Target) and b.Target:GetPos()) or b.Goal or b.MoveTo or b:GetPos()
				local w = IsValid(b.Target) and 3 or 1   -- (a bug on a target counts more: there is the fight / the food)
				pull = pull + (((at - mid):Dot(T.dir) > 0) and w or -w)
			end
		end
		local side = (pull > 0) and "b" or (pull < 0) and "a" or nil
		if (side) then R.Dbg(nil, "bridge down: blocks go to side", side, "pull", pull) end
		local per = 12
		for g = 1, math.ceil(#left / per) do
			local grp = {}
			for k = (g - 1) * per + 1, math.min(#left, g * per) do grp[#grp + 1] = left[k] end
			local gm = grp[math.ceil(#grp / 2)]:GetPos()
			local toB = side == "b" or (side == nil and gm:DistToSqr(T.b) < gm:DistToSqr(T.a))
			local home = toB and (T.b + T.dir * 20) or (T.st - T.dir * 10)
			home = down(home + Vector(0, 0, 30), 80).HitPos
			local mnd = T.minds[g]
			local t0 = CurTime()
			local from = {}
			for k, bl in ipairs(grp) do from[k] = bl:GetPos(); bl:SetCollisionGroup(COLLISION_GROUP_DEBRIS); bl:SetModelScale(1, 1) end   -- (through everything on the way back, small again)
			local id = "AGPRepBridgeBack" .. grp[1]:EntIndex()
			timer.Create(id, 0.03, 0, function()
				local e = math.min(1, (CurTime() - t0) / 1.2)
				local s = e * e * (3 - 2 * e)
				local alive = 0
				for k, bl in ipairs(grp) do
					if (IsValid(bl) and not bl.RepDead) then alive = alive + 1; bl:SetPos(LerpVector(s, from[k], home + Vector(0, 0, 4)) + Vector(0, 0, math.sin(s * math.pi) * 10)) end
				end
				if (e < 1 and alive > 0) then return end
				timer.Remove(id)
				if (alive >= 9 and R.Count("bugs") < R.cv.bugs:GetInt()) then
					for _, bl in ipairs(grp) do if (IsValid(bl)) then bl:Remove() end end
					local bug = ents.Create("agp_replicator")
					if (not IsValid(bug)) then return end
					bug:SetPos(home + Vector(0, 0, 2))
					bug:SetAngles(Angle(0, math.random(0, 359), 0))
					bug.RepOwner = T.owner
					if (mnd) then bug.Mind = mnd end
					bug:Spawn(); bug:Activate()
					if (IsValid(T.owner) and bug.CPPISetOwner) then bug:CPPISetOwner(T.owner) end
					sound.Play("agp_replicator/rep_assemble.wav", home, 68, math.random(100, 112))
				else   -- (blocks were shot away: the rest are loose blocks, the swarm draws them together)
					for _, bl in ipairs(grp) do
						if (IsValid(bl) and not bl.RepDead) then
							R.PlateBack(bl)
							bl.RepClaimed, bl.RepBridge, bl.RepRest = nil, nil, CurTime() + 2
							bl:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
							local ph = bl:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(true); ph:Wake() end
						end
					end
				end
			end)
		end
	end
	-- one block of it killed (the ARG, Dakara): the beam lets go - everything on it falls
	function R.BridgeBreak(T)
		if (T.dead) then return end
		T.dead = true
		if (T.h) then T.h.bridges[T.id] = nil end
		timer.Remove("AGPRepBridgeWatch" .. T.id)
		R.Stat("bridges broken")
		for _, bl in ipairs(T.blocks) do
			if (IsValid(bl) and not bl.RepDead) then
				R.PlateBack(bl)
				bl.RepClaimed, bl.RepBridge, bl.RepRest = nil, nil, CurTime() + 4
				bl:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
				local ph = bl:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(true); ph:Wake(); ph:SetVelocity(VectorRand() * 40) end
			end
		end
		for b in pairs(R.bugs) do if (IsValid(b) and b.Crossing == T) then b.Crossing = nil; b:StartFall() end end
	end

	-- the tower falls apart: every bug in it lets go
	function R.TowerDown(T)
		for _, b in ipairs(T.n) do
			if (IsValid(b) and not b.RepGone) then
				b.InTower = nil
				b:SetNWBool("RepTower", false)
				local ph = b:GetPhysicsObject()
				if (IsValid(ph)) then ph:EnableMotion(true) end
				b:StartFall(VectorRand() * 60)
			end
		end
		T.n = {}
		T.h = 0
		T.ver = (T.ver or 0) + 1   -- wakes the ones waiting in the queue
	end

	-- a shield between it and what it wants: drain that shield first
	function ENT:ShieldInWay(target, pos)
		if (not IsValid(target)) then return false end
		local sh = R.ShieldNear(target:GetPos(), 1)   -- the target is inside a shield: that shield first
		if (IsValid(sh) and target:GetPos():Distance(sh:GetPos()) < R.ShieldRadius(sh)) then
			self.State, self.Target = "drain", sh
			return true
		end
		return false
	end

	-- a jump in an arc that ends at the target (gravity 600)
	function ENT:Pounce(t)
		local from = self:GetPos() + (self.RepUp or Vector(0, 0, 1)) * 8
		-- something to eat that is not a ship (a crystal on its mount, a prop on a ledge): onto a spot right next to it,
		-- where it can stand and eat (aimed at the thing itself it could fly past it, over an edge)
		if (not R.IsShip(t) and not t:IsPlayer() and not t:IsNPC()) then
			local v, land = R.PlanJump(self, t:NearestPoint(from), t, 50)
			if (v) then
				self.NextLeap = CurTime() + math.Rand(2.5, 4)
				self.Ambush = nil
				self.PounceAt = t
				R.Stat("pounces")
				R.Dbg(self, "aimed jump next to", t:GetClass())
				R.DoJump(self, v, land, R.JumpKind(from, land))
				return
			end
		end
		-- a living target: the gentlest arc onto where it will be (it lands without breaking, also out of a gate)
		if (t:IsPlayer() or t:IsNPC()) then
			local aim = t:WorldSpaceCenter()
			local v, T = R.JumpTo(self, aim + t:GetVelocity() * 0.5, t)
			if (v) then
				self.NextLeap = CurTime() + math.Rand(2.5, 4)
				self.Ambush = nil
				self.PounceAt = t
				R.Stat("pounces")
				R.Dbg(self, "aimed pounce at", t:GetClass(), "speed", math.Round(v:Length()))
				R.DoJump(self, v, aim + t:GetVelocity() * T, "leap")
				return
			end
		end
		-- the near side of it, a little in towards its middle: the box corner nearest to it can be empty air (a ship's hull
		-- is round), aimed a bit inside the arc really meets the hull
		local to = LerpVector(0.3, t:NearestPoint(from), t:WorldSpaceCenter()) + Vector(0, 0, 6)
		local flat = Vector(to.x - from.x, to.y - from.y, 0)
		local dist = flat:Length()
		local time = math.Clamp(dist / 520, 0.45, 1.5)
		local vz = (to.z - from.z + 0.5 * 600 * time * time) / time
		local v = flat / time + Vector(0, 0, vz)
		self.NextLeap = CurTime() + math.Rand(2.5, 4)
		self.Ambush = nil
		self.PounceAt = t
		R.Stat("pounces")
		R.Dbg(self, "pounce at", t:GetClass(), "from height", math.Round(from.z), "to", math.Round(to.z), "speed", math.Round(v:Length()))
		self:StartFall(v, true)
	end

	-- clinging to a ship: parented to it, eats it from the hull (the crew inside is protected by the ship, the ship is not)
	-- (inside: on the deck of a flying ship, ENT:Look - it stays solid for shots and players, only its body is out of the
	-- physics; it eats only when eating is on, builds aboard, and walks again once the ship stands)
	function ENT:Board(ship, inside)
		if (self.RepGone or IsValid(self:GetParent())) then return end
		self.Falling, self.Jumping = false, nil
		self:SetNWBool("RepFall", false)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) if (inside) then ph:EnableCollisions(false) end end
		if (not inside) then self:SetNotSolid(true) end
		self.BoardInside = inside or nil
		ship.AGPRepRestOn = true   -- (removed: who holds on to it lets go at once, agp_replicators.lua)
		-- on the hull itself, feet to its slope: the nearest point of the ship's box and the line from its middle put them
		-- in the air over a sloped roof, upright or tipped up to 90 degrees, legs in the sky (on the Workshop
		-- pictures). The hull under it is felt: towards the ship's middle, along its own down and straight down - the
		-- nearest hit wins; none (a strange model): the old way
		local p, c = self:GetPos(), ship:WorldSpaceCenter()
		local function only(e) return e == ship or e.AGPShip == ship end   -- (a ship of parts, the Ha'tak: its hull plates too)
		local best
		for _, dir in ipairs({ (c - p):GetNormalized(), -(self.RepUp or Vector(0, 0, 1)), Vector(0, 0, -1) }) do
			local tr = util.TraceLine({ start = p - dir * 48, endpos = p + dir * 200, filter = only, ignoreworld = true })
			if (tr.Hit and not tr.StartSolid and (not best or tr.HitPos:DistToSqr(p) < best.HitPos:DistToSqr(p))) then best = tr end
		end
		local at, n
		if (best) then at, n = best.HitPos, best.HitNormal
		else at = ship:NearestPoint(p); n = (at - c):GetNormalized() end
		self:SetPos(at)
		-- (its heading kept, laid into the hull's slope: straight along its up the angle would be anything)
		local f = self:GetForward()
		f = f - n * f:Dot(n)
		if (f:LengthSqr() < 0.01) then f = ship:GetForward() - n * ship:GetForward():Dot(n) end
		f:Normalize()
		self:SetAngles(f:AngleEx(n))
		self.RepUp = n
		R.Stat(best and "boarded: on the hull" or "boarded: on its box (no hull felt)")
		self:SetParent(ship)
		self.Boarded = ship
		self.BoardTry = nil
		R.Reward(self, 2)
		R.Stat("boarded")
		R.Dbg(self, "boarded", ship:GetClass())
		self.State, self.Target, self.MoveTo = "eat", ship, nil
		if (inside) then
			self.BoardSlowT = nil
			self.RestAt, self.RestAng, self.RestOn = nil, nil, nil
			if (R.Awake() and R.cv.eat:GetInt() > 0 and R.Edible(ship)) then self:Eat(ship) else self.State, self.Target = "wander", nil end
			return
		end
		self:RepSound("agp_replicator/rep_chatter2.wav", 75, 100, 0.8)
		self:Eat(ship)
	end
	-- aboard a flying ship: the new Replicator is built right where it is, its blocks fixed to the ship and drawn together
	-- along its deck (loose blocks in a flying hull are moved by the ship every tick - hundreds of them were the lag)
	function ENT:BuildAboard(ship)
		if (R.Full() or not R.RoomForBlocks(R.BLOCKS_PER_BUG)) then return end
		self.RepStock = self.RepStock - R.BLOCKS_PER_BUG
		R.Reward(self, 2)
		local up, fwd = self:GetUp(), self:GetForward()
		local c = self:GetPos() - fwd * 30
		local tr = util.TraceLine({ start = c + up * 24, endpos = c - up * 40, filter = function(e) return e == ship end, ignoreworld = true })
		local ground = tr.Hit and not tr.StartSolid and tr.HitPos or self:GetPos()
		local gL = ship:WorldToLocal(ground)
		local upL = ship:WorldToLocal(ship:GetPos() + up)
		local angL = ship:WorldToLocalAngles(fwd:AngleEx(up))
		local owner, mind = self.RepOwner, self.Mind
		local group = {}
		for i = 1, R.BLOCKS_PER_BUG do
			local b = R.SpawnBlock(self:WorldSpaceCenter() + VectorRand() * 6, nil, owner, 1e9 + 1)
			if (b) then
				b.RepClaimed, b.RepMind = true, mind
				local ph = b:GetPhysicsObject()
				if (IsValid(ph)) then ph:EnableMotion(false); ph:EnableCollisions(false) end
				b:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				b:SetParent(ship)
				b.RepFrom, b.RepFromAng = b:GetLocalPos(), b:GetLocalAngles()
				b.RepTo = gL + upL * (4 + (i % 3) * 2) + VectorRand() * 7
				group[#group + 1] = b
			end
		end
		for i, b in ipairs(group) do b:SetNWEntity("RepLink", i > 1 and group[1] or group[2]) end
		self:RepSound("agp_replicator/rep_assemble.wav", 70, 110, 0.7)
		if (#group == 0) then return end
		local t0, dur = CurTime(), 1.6
		local id = "AGPRepAboard" .. group[1]:EntIndex()
		timer.Create(id, 0.05, 0, function()
			local f = math.min(1, (CurTime() - t0) / dur)
			local e = f * f * (3 - 2 * f)
			if (not IsValid(ship)) then
				timer.Remove(id)
				for _, b in ipairs(group) do if (IsValid(b)) then b:Remove() end end
				return
			end
			for _, b in ipairs(group) do
				if (IsValid(b)) then
					b:SetLocalPos(LerpVector(e, b.RepFrom, b.RepTo) + upL * math.sin(e * math.pi) * 6)
					b:SetLocalAngles(LerpAngle(e, b.RepFromAng, angL))
				end
			end
			if (f < 1) then return end
			timer.Remove(id)
			for _, b in ipairs(group) do if (IsValid(b)) then b:Remove() end end
			if (R.Count("bugs") >= R.cv.bugs:GetInt()) then return end
			local bug = ents.Create("agp_replicator")
			if (not IsValid(bug)) then return end
			bug:SetPos(ship:LocalToWorld(gL) + up * 2)
			bug:SetAngles(ship:LocalToWorldAngles(angL))
			bug.RepOwner, bug.RepParentMind = owner, mind
			bug:Spawn(); bug:Activate()
			if (IsValid(owner) and bug.CPPISetOwner) then bug:CPPISetOwner(owner) end
			bug.RepUp = up
			local fx = EffectData(); fx:SetOrigin(ship:LocalToWorld(gL) + up * 6); fx:SetMagnitude(2); fx:SetScale(1); fx:SetRadius(4)
			util.Effect("Sparks", fx, true, true)
			-- (on at once: a moment loose in the flying hull and it is left behind)
			if (ship.SGKeel or R.ShipCore(ship)) then bug:Board(ship, true) end
			R.Stat("built aboard a flying ship")
		end)
	end
	-- the deck of a flying StarCore ship (a SpaceGrid hull, a welded ship) right under its feet, or nil (also when the ship
	-- stands or drifts slowly: then they walk on it as on any floor)
	function ENT:FlyingDeck(pos)
		local down = -(self.RepUp or self:GetUp())
		local tr = util.TraceLine({ start = pos - down * 8, endpos = pos + down * 40, mask = MASK_SOLID,
			filter = function(e) return not e.AGPReplicator and not e:IsPlayer() and not e:IsNPC() and not e.SpaceGridKeel end })
		local e = tr.Hit and tr.Entity
		if (not (IsValid(e) and not e:IsWorld() and R.ShipCore(e))) then return nil end
		local k = e.SGKeel
		local ph = IsValid(k) and k:GetPhysicsObject() or e:GetPhysicsObject()
		if (not IsValid(ph) or ph:GetVelocity():LengthSqr() < 80 * 80) then return nil end
		return e
	end

	-- what a resting bug stands on when it is not the map (a ship's deck, a prop), or nil
	function ENT:RestGround(pos, up)
		local down = -(up or Vector(0, 0, 1))
		local tr = util.TraceLine({ start = pos - down * 8, endpos = pos + down * 40, mask = MASK_SOLID,
			filter = function(e) return not e.AGPReplicator and not e:IsPlayer() and not e:IsNPC() and not e.SpaceGridKeel end })
		local e = tr.Hit and tr.Entity
		if (IsValid(e) and not e:IsWorld()) then return e end
		return nil
	end
	-- (a flying SpaceGrid hull moves every loose body in it each tick, sv_keel.lua: a resting bug held on its ground by
	-- the rest above is left to that - the two pulling at it shook it into the hull)
	function ENT:SGNoCarry(hull) return self.RestAt ~= nil and self.RestOn ~= nil and IsValid(self.RestOn) end
	-- a resting bug whose ground is gone (a ship blown up, a prop removed): it falls instead of hanging in the air
	function ENT:RestLost()
		self.RestAt, self.RestAng, self.RestOn = nil, nil, nil
		R.Stat("rest: its ground is gone, it falls")
		self:StartFall()
	end

	-- off the ship again (it is gone, or it was eaten up): fall
	function ENT:LetGo()
		self.Boarded, self.BoardInside = nil, nil
		self:SetParent(NULL)
		self:SetNotSolid(false)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetPos(self:GetPos()); ph:SetAngles(self:GetAngles()); ph:EnableCollisions(true); ph:EnableMotion(true); ph:Wake() end
		self:StartFall()
	end

	-- what to do next (about once a second)
	function ENT:Look()
		local pos = self:GetPos()
		local now0 = CurTime()
		local m = mind(self)
		local hive = R.Hive(self.RepOwner)
		local queen = self:MyQueen()
		local role = self.Role
		local enemy, edist, metal, fullShip = sense(self, pos)
		local alarm = R.Enemy(self.RepOwner)
		if (alarm and R.MayAttack(self, alarm) and alarm:GetPos():DistToSqr(pos) < 3000 * 3000 and queen) then enemy, edist = alarm, alarm:GetPos():Distance(pos) end
		-- out of its sight (800) the prey it hunts stays its prey up to 3000 away - the hive mind knows where he is - and
		-- whoever threatened the swarm is felt by every bug up to twice its sight
		--
		if (not enemy) then
			local t = self.Target
			if (self.State == "attack" and IsValid(t) and (t:IsPlayer() or t:IsNPC()) and R.MayAttack(self, t) and t:GetPos():DistToSqr(pos) < 3000 * 3000) then
				enemy, edist = t, t:GetPos():Distance(pos)
			else
				local th = R.threats[IsValid(self.RepOwner) and self.RepOwner or game.GetWorld()]
				local best = (self.RepSight * 2) ^ 2
				for e in pairs(th or {}) do
					if (IsValid(e) and R.MayAttack(self, e)) then
						local d = e:GetPos():DistToSqr(pos)
						if (d < best) then enemy, best = e, d end
					end
				end
				if (enemy) then edist = math.sqrt(best) end
			end
		end
		self.SpeedMul = nil
		-- following prey through a Stargate or by ring, or ringing over to start a new home (sv_pursuit.lua)
		if (self.Pursuit) then return self:Pursue() end
		-- a survivor follows its own plan (escape, lie low, start again)
		if (role == "survivor") then return self:Survive(enemy, edist) end
		if (role == "colonist") then return self:Colonize() end
		-- in a ship that flies (a SpaceGrid hull, a StarCore ship): the deck runs away under every goal picked in the world -
		-- one walked after its old goal and got out of a flying hall (test sgship). With no enemy close they hold on and eat
		-- the ship from inside, and build the new ones right there (the swarm grows aboard)
		if (not (IsValid(enemy) and edist < 600) and not self.Falling) then
			local deck = self:FlyingDeck(pos)
			if (deck) then
				-- (held on fixed to the deck, its body out of the physics - the author's play test: a swarm eating a
				-- flying ship lagged the game till the lag guard stepped in. Measured: 30 bugs and the 230-550 blocks they made
				-- lay loose in the hall, the ship moved each of them every tick - 40-110 ms of a 15 ms tick, 1-5 fps)
				self.Goal, self.MoveTo, self.Route, self.GatherT = nil, nil, nil, nil
				self:Board(deck, true)
				return
			end
		end
		-- a settler walks to the place of the new nest (sv_tactics.lua merges them there into a Queen)
		if (role == "settler" and self.Nest) then
			self.State = "scout"
			if (not self.Goal or self.Goal:DistToSqr(self.Nest.at) > 150 * 150) then self:GoTo(self.Nest.at, 1.0) end
			return
		end
		-- waiting in ambush on a wall above a path: still and silent until prey comes below, then it drops on it
		if (self.State == "ambush") then
			if (now0 > (self.AmbushUntil or 0)) then R.AmbushJudge(self); self.State, self.AmbushAt, self.RepSilent = "wander", nil, nil
			else
				if (IsValid(enemy) and edist < 600) then
					local tp = enemy:GetPos()
					local flat = Vector(tp.x - pos.x, tp.y - pos.y, 0):Length()
					if (pos.z > tp.z + 50 and flat < 230 and not self.Falling) then
						self.State, self.Target, self.AmbushAt, self.RepSilent = "attack", enemy, nil, nil
						R.Stat("ambush drops")
						R.AmbushDropped(self)
						self:StartFall(Vector(tp.x - pos.x, tp.y - pos.y, 0) * 1.6 + Vector(0, 0, 40), true)
						if (self:MyQueen()) then R.Shout(self, enemy) end
					end
				end
				return
			end
		end
		-- a gate guard stays at the map's gate and goes for whoever threatens the swarm there
		if ((role == "gateguard" or role == "escort") and self.GuardAt) then
			if (IsValid(enemy) and edist < 700) then self.State, self.Target = "attack", enemy
			elseif (self.State ~= "guard" or not self.MoveTo) then
				self.State = "guard"
				local a = math.random() * math.pi * 2
				self:GoTo(self.GuardAt + Vector(math.cos(a), math.sin(a), 0) * math.Rand(60, 220), 0.6)
			end
			return
		end
		local opts = {}
		local function opt(name, score, fn) if (score > 0) then opts[#opts + 1] = { name, score * math.Rand(0.85, 1.15), fn } end end
		-- keep away from the anti-replicator gun
		local arg = R.ArgNear(pos, 500)
		if (arg and self.RepKind == "bugs") then
			opt("flee", 2.5 / m.bold, function()
				local away = pos - arg:GetPos(); away.z = 0
				self.State, self.Target = "flee", arg
				self:GoTo(pos + away:GetNormalized() * 450 + VectorRand() * 100, 1.35)
			end)
		end
		if (IsValid(enemy)) then
			local mates = R.Mates(self, pos, 600)
			local hunted = self.State == "attack" and self.Target == enemy
			local base = (role == "hunter" and 1.6 or role == "guard" and 1.2 or role == "scout" and 0.5 or 0.9) * m.bold * hive.bold
			-- the Queen counted: too few of us - no fighting one by one (only when bitten right now, it fights back)
			local skirmisher = hive.skirmish and hive.skirmish[self]
			if (hive.mode == "hold" and not hive.defend and not skirmisher and not (self.HurtBy == enemy and edist < 250)) then base = 0 end
			if (skirmisher and self.SkirmishAway and now0 < self.SkirmishAway) then base = 0 end   -- just bit him: away first
			opt("attack", base * (0.6 + math.min(mates, 6) * 0.15) * (hunted and 1.4 or 1) * (self.HurtBy == enemy and 1.6 or 1), function()
				self.State, self.Target = "attack", enemy
				if (queen) then R.Shout(self, enemy) end
				-- the Queen's tactic: gather out of reach first and strike together (learned per map)
				self.GatherT = queen and hive.fight and hive.fight.gathered and edist > 350 and R.Hunters(enemy) < 3 and CurTime() + 8 or nil
			end)
		end
		-- holding back: hunters gather out of sight near the Queen (the others eat: the swarm grows meanwhile)
		if (hive.mode == "hold" and hive.rally and (role == "hunter" or role == "guard")) then
			opt("rally", 1.5, function()
				self.State = "regroup"
				self:GoTo(hive.rally + VectorRand() * 120, 1.0)
			end)
		end
		-- metal: eat (workers most), carry it home, or build
		if (self.RepStock >= R.BLOCKS_PER_BUG and (queen or not R.Full())) then   -- (no building while the game is behind)
			opt(queen and "deliver" or "build", 1.3, function() self:UseStock() end)
		end
		local food = metal or R.KnownMetal(self.RepOwner, pos) or (not R.MapFoodOk(self.RepOwner, pos) and R.FarMetal(pos)) or nil
		if (IsValid(food) and avoided(self, food)) then food = nil end
		if (IsValid(food) and R.Shielded(food)) then food = nil end   -- behind a shield: the shield first (drain), not this
		if (IsValid(food)) then
			local hunger = 1 - math.min(self.RepStock, 12) / 12
			local close = food:GetPos():DistToSqr(pos) < 500 * 500 and 1.4 or 1   -- metal right there is hard to pass by
			opt("eat", (role == "worker" and 1.4 or role == "scout" and 0.6 or 1.1) * hunger * close * (0.6 + R.TechValue(food) * 0.25) * (queen and 1 or 1.25), function()
				if (self.Target ~= food) then R.Claim(food) end
				self.State, self.Target = "eat", food
			end)
		end
		-- the ground round a ship is full (all bite places taken): jump onto the hull and eat from on top
		if (IsValid(fullShip) and self.Target ~= fullShip and self.RepClimb and not avoided(self, fullShip)) then
			opt("board", 1.0 * (role == "hunter" and 1.2 or 1), function()
				self.State, self.Target, self.BoardTry = "eat", fullShip, true
			end)
		end
		-- a shield nearby: energy to drain (it weakens the shield and feeds the swarm)
		if (self.RepKind == "bugs" and self.RepStock < R.BLOCKS_PER_BUG) then
			local sh = (self.State == "drain" and IsValid(self.Target) and self.Target) or R.ShieldNear(pos, self.RepSmell * 0.8)
			if (IsValid(sh)) then
				opt("drain", (role == "worker" and 1.5 or role == "hunter" and 0.8 or 1.2) * (self.State == "drain" and 1.4 or 1), function()
					self.State, self.Target = "drain", sh
				end)
			end
		end
		-- strong energy or advanced technology further away (a ZPM, a generator, a ship, an open gate, a shield): curious,
		-- they go and see how to get at it (up a building, a jump, a tower - the same ways as for any target)
		if (self.RepKind == "bugs" and not IsValid(enemy) and self.RepStock < R.BLOCKS_PER_BUG) then
			if (now0 > (self.NextLure or 0)) then self.NextLure = now0 + 3; self.Lure, self.LurePower = R.Lure(self, pos) end
			local lure, power = self.Lure, self.LurePower
			if (IsValid(lure)) then
				local plain = not IsValid(metal) or R.TechValue(metal) < 2
				opt("investigate", (role == "scout" and 0.75 or 0.45) * m.curious * (power / 3) * (plain and 1.2 or 0.6) * (self.Target == lure and 1.4 or 1), function()
					if (self.Target ~= lure) then R.Dbg(self, "curious about", lure:GetClass(), "power", power, "at", math.Round(lure:GetPos():Distance(pos))); R.Stat("curious") end
					if (R.IsShield(lure)) then self.State, self.Target = "drain", lure
					else if (self.Target ~= lure) then R.Claim(lure) end self.State, self.Target = "eat", lure end
				end)
			end
		end
		-- scouts explore the edge of what the swarm knows: new ways, metal, hiding places
		if (role == "scout" or (not queen and m.curious > 1.2)) then
			opt("scout", (role == "scout" and 1.0 or 0.55) * m.curious, function()
				self.State = "scout"
				self:GoTo(self.ScoutGoal or self:WanderSpot(900), 1.05)
			end)
		end
		-- (a guard far from its Queen - she moved to hide - goes to her; near her, it strolls round her)
		if (IsValid(self.RepGuard)) then opt("guard", 1.0, function() self.State = "guard"; self:GoTo(self.RepGuard:GetPos():DistToSqr(pos) > 350 * 350 and (self.RepGuard:GetPos() + Angle(0, self.RepSide or 0, 0):Forward() * 120) or self:WanderSpot(220), self.RepGuard:GetPos():DistToSqr(pos) > 350 * 350 and 1.1 or 0.7) end) end
		-- alone, far from the others: back to the swarm
		local cx, cn = R.Centre(self.RepOwner)
		cn = cn - 1
		-- (a colonist's new home - by ring or through a gate - is the start of a new swarm: the old one's middle is not
		-- "the others" any more, neither to go back to nor to gather at for a Queen.: ring colonists came over and walked
		-- straight back to the old swarm)
		local home = self.RepHome
		local awayHome = home ~= nil and cx ~= nil and cx:DistToSqr(home) > (self.RepHomeRadius or 1500) ^ 2
		if (cn > 0 and cx) then
			cx = Vector(cx)
			local far = cx:Distance(pos)
			if (awayHome) then far = 0 end
			if (far > 900) then opt("regroup", 0.5 * m.social * math.min(far / 900, 2), function() self.State = "regroup"; self:GoTo(self:Gather(cx, 150), 0.9) end) end
		end
		-- without a Queen, building one is the swarm's first goal: the bugs gather (agp_replicators.lua merges them)
		-- (only while a Queen may be made at all: with agp_rep_max_queens 0, or as many as allowed, they gathered for
		-- nothing, forever, and left the goal they had - the bridge test's "regroup regroup regroup")
		if (not queen and not awayHome and cn >= 3 and R.Count("queens") < R.cv.queens:GetInt()) then opt("regroup", 0.6 * m.social, function() self.State = "regroup"; self:GoTo(self:Gather(cx, 80), 0.9) end) end
		-- (a colony far from the old swarm builds its own Queen at its new home, once it is enough there)
		if (not queen and awayHome and R.Count("queens") < R.cv.queens:GetInt() and R.Mates(self, home, 1500) >= 3) then opt("regroup", 0.6 * m.social, function() self.State = "regroup"; self:GoTo(self:Gather(home, 80), 0.9) end) end
		-- nothing to eat or fight: go and find something - the edge of what the swarm knows, or simply far away
		if (not IsValid(food) and not IsValid(enemy) and self.RepKind == "bugs") then
			opt("explore", 0.55 * m.curious, function()
				-- ("the one under water is just moving back and forth in a circle": with nothing to eat in reach it looked
				-- for the nearest frontier every second, and after each step another one was the nearest - it turned round
				-- every 2 s, 7 times in 30 s in the water test. It keeps the goal it picked for 8 s unless it got there)
				if (self:WaterLevel() >= 1 and self.State == "scout" and self.Goal and now0 < (self.ScoutKeepT or 0) and self.Goal:DistToSqr(pos) > 80 * 80) then return end   -- (in water only: on land the play test failed twice with it on) (on land
				-- too while it still gets nearer: a new frontier every look, ~1 s, turned it round again and again - "it
				-- wobbles between the two walls"; the curb test logged a new goal at 0.9, 2.1, 3.2, 4.4 s. Kept only while it
				-- gained on it in the last 1.5 s, so a goal it cannot reach is let go - the land fail)
				if (self.State == "scout" and self.Goal and self.ScoutKeepG == self.Goal and now0 < (self.ScoutKeepT or 0)) then
					local d = self.Goal:Distance(pos)
					if (d < (self.ScoutBestD or 1e9) - 10) then self.ScoutBestD, self.ScoutBestAt = d, now0 end
					if (d > 80 and now0 - (self.ScoutBestAt or 0) < 1.5) then return end
				end
				self.State = "scout"
				self.ScoutKeepT = now0 + 8
				local g = R.Map.Frontier(pos, 400, 2500)
				-- (somewhere far off on the ground: at the height of the wall it was on, it lay in the air)
				for _ = 1, 4 do
					if (g) then break end
					local a = math.random() * math.pi * 2
					g = self:OnGround(pos + Vector(math.cos(a), math.sin(a), 0) * math.Rand(800, 2000))
				end
				self:GoTo(g or self:WanderSpot(450), 0.95)
				self.ScoutKeepG, self.ScoutBestD, self.ScoutBestAt = self.Goal, self.Goal and self.Goal:Distance(pos) or nil, now0
			end)
		end
		-- look around / wander
		opt("wander", 0.35, function()
			self.State = "wander"
			if (math.random() < 0.35) then self.MoveTo = nil; self.PauseUntil = CurTime() + math.Rand(0.6, 2.2)   -- stands, "listens"
			else self:GoTo(self:WanderSpot(queen and 600 or 450), 0.65) end
		end)
		-- the Queen has her own plan (agp_replicator_queen.lua ENT:Brain: hide, look for cover, keep her nest): of the swarm's
		-- options only fighting back (the test found her on "regroup" all the time: the bugs' "no Queen yet, gather to build
		-- one" sent her after her own guards' middle)
		if (self.RepKind == "queens") then
			local keep = {}
			for _, o in ipairs(opts) do if (o[1] == "attack") then keep[#keep + 1] = o end end
			opts = keep
			if (#opts == 0) then
				if (self.State ~= "pursue") then self.State = "queen" end
				return
			end
		end
		-- the learned brain: each option counts as much as it paid off in this situation before (sv_brain.lua)
		local sit = R.Brain.Situation(self, food, enemy, hive)
		for _, o in ipairs(opts) do o[2] = o[2] * R.Brain.Weight(sit, o[1]) end
		-- the hive mind (setup 4): the shared network's view of each option in exactly these details
		local feats
		if (R.Brain.HasHive and R.Brain.Mind() >= 4 and #opts > 1) then
			feats = R.Brain.Features(self, food, enemy, edist, hive)
			for _, o in ipairs(opts) do o[2] = o[2] * math.exp(math.Clamp(R.Brain.HiveValue(feats, o[1]), -2.5, 2.5) * 0.35) end
		end
		-- keep doing what it does unless something is clearly better (no jittering)
		local cur = self.State
		table.sort(opts, function(a, b) return a[2] > b[2] end)
		local pick = opts[1]
		if (#opts > 1 and R.Brain.Explore()) then pick = opts[2] end   -- training: try the other idea now and then
		for _, o in ipairs(opts) do if (o[1] == cur and o[2] > pick[2] * 0.75 and cur ~= "wander") then pick = o break end end
		if (pick and (pick[1] ~= cur or cur == "wander" or cur == "scout" or cur == "regroup" or cur == "guard")) then
			if (pick[1] ~= cur) then R.Dbg(self, "decides", pick[1], string.format("%.2f", pick[2]), "options", #opts) end
			if (pick[1] ~= (self.BrainDec and self.BrainDec.opt)) then R.Brain.Decided(self, sit, pick[1], R.Brain.Log and (feats or R.Brain.Features(self, food, enemy, edist, hive)) or nil) end
			pick[3]()
		end
	end

	-- a survivor: escape out of sight (as far as it decides), lie low, then start a new swarm where it is
	function ENT:Survive(enemy, edist)
		local now = CurTime()
		local pos = self:GetPos()
		local hive = R.Hive(self.RepOwner)
		if (self.SurvivePhase == "escape") then
			if (not self.HideAt or now > (self.HideUntil or 0)) then
				local enemies = {}
				for _, p in ipairs(player.GetAll()) do if (p:Alive()) then enemies[#enemies + 1] = p:GetPos() end end
				local far = math.Rand(1500, 6000) * mind(self).curious
				self.HideAt = R.Map.HideSpot(pos, enemies, 800, far) or R.Map.Frontier(pos, 1200, far)
				if (not self.HideAt) then
					local away = Vector()
					for _, e in ipairs(enemies) do away:Add((pos - e):GetNormalized()) end
					away.z = 0
					self.HideAt = pos + (away:LengthSqr() > 0 and away:GetNormalized() or VectorRand()) * far
				end
				self.HideUntil = now + 40
			end
			self.State = "hide"
			self:GoTo(self.HideAt, 1.15)
			if (self.HideAt:DistToSqr(pos) < 120 * 120 and not R.Map.Seen(pos)) then
				self.SurvivePhase, self.SurviveT = "low", now
				self.MoveTo = nil
			end
		elseif (self.SurvivePhase == "low") then
			-- lie still; found: escape again
			self.State = "hide"
			self.MoveTo = nil
			if (IsValid(enemy) and edist < 350) then self.SurvivePhase, self.HideAt = "escape", nil return end
			if (now - self.SurviveT > math.Rand(45, 90) and not R.Map.Seen(pos)) then
				self.SurvivePhase = "rebuild"
				self.RepHome = pos
				self.RepSilent = nil
				self:SetNWBool("RepSilent", false)
			end
		else
			-- start again: careful (stays near its new home, eats, builds; the swarm then builds a Queen)
			self.Role = "worker"
			self.SurvivePhase = nil
			self.RepHomeRadius = 1500
		end
	end

	-- a colonist: to the Stargate the Queen chose, one of them dials (at the DHD if there is one), all walk through and
	-- start a new swarm on the other side
	-- into an open gate: from behind round the side first (the back of an open gate destroys what walks into it), then
	-- lined up in front of it, then straight through - the goal lies behind the horizon, so it walks through at full
	-- stride (a goal right at the horizon: it slowed down and stopped just short of it)
	-- a player it cannot see (in a building, it on the roof above): it goes the way he went - his trail (sv_pursuit.lua),
	-- joined at the newest point it can see from where it is, followed to its end. False: it can see him (straight at him)
	-- the way in the hive worked out to a player under a roof (R.WayIn, sv_pursuit.lua): from outside to the opening,
	-- then point by point through the house to him. Joined at the furthest point it can already see (inside it does
	-- not go back out to the opening). False: it sees him, he is outdoors, or there is no way in
	function ENT:FollowWayIn(t, pos, now)
		local up = self.RepUp or Vector(0, 0, 1)
		if (not util.TraceLine({ start = pos + up * 10, endpos = t:EyePos(), mask = MASK_SOLID_BRUSHONLY }).Hit) then self.WayK = nil return false end
		local way = R.WayIn and R.WayIn(t)
		if (not way or #way == 0) then self.WayK = nil return false end
		-- (also when it lost its point: seeing him again above clears WayK but keeps WayOf - the same way back then made
		-- WayK nil here)
		if (self.WayOf ~= way or not self.WayK) then
			self.WayOf, self.WayK = way, 1
			for k = #way, 2, -1 do
				local q = way[k]
				if (q:DistToSqr(pos) < 500 * 500 and not util.TraceLine({ start = pos + up * 10, endpos = q + Vector(0, 0, 12), mask = MASK_SOLID }).Hit) then self.WayK = k break end
			end
			if (not self.WaySaid or now > self.WaySaid) then self.WaySaid = now + 8 R.Dbg(self, "takes the way in to", t:Nick(), "at point", self.WayK, "of", #way) R.Stat("ways in taken") end
		end
		while (way[self.WayK + 1] and way[self.WayK]:DistToSqr(pos) < 50 * 50) do self.WayK = self.WayK + 1 end
		self.MoveTo, self.Route = way[self.WayK], nil
		return true
	end
	function ENT:FollowTrail(t, pos, now)
		local up = self.RepUp or Vector(0, 0, 1)
		local seen = not util.TraceLine({ start = pos + up * 10, endpos = t:EyePos(), mask = MASK_SOLID_BRUSHONLY }).Hit
		if (seen) then self.Trail = nil return false end
		local tr = R.trails and R.trails[t]
		if (not tr or #tr == 0) then return false end
		local T = self.Trail
		if (not T or T.who ~= t or now > T.untilT) then
			-- (the newest point it can see, not too far: from there on the trail leads to him)
			local from
			for k = #tr, math.max(1, #tr - 120), -1 do
				local q = tr[k].p
				if (q:DistToSqr(pos) < 900 * 900 and not util.TraceLine({ start = pos + up * 10, endpos = q + Vector(0, 0, 16), mask = MASK_SOLID_BRUSHONLY }).Hit) then from = k break end
			end
			if (not from) then self.Trail = nil return false end
			T = { who = t, k = from, untilT = now + 4 }
			self.Trail = T
			if (not self.TrailSaid or now > self.TrailSaid) then self.TrailSaid = now + 8 R.Dbg(self, "follows the trail of", t:Nick(), #tr - from, "steps") R.Stat("trail follows") end
		end
		while (tr[T.k + 1] and tr[T.k].p:DistToSqr(pos) < 50 * 50) do T.k = T.k + 1 end
		local q = tr[math.min(T.k, #tr)]
		if (not q) then return false end
		self.MoveTo, self.Route = q.p + Vector(0, 0, 4), nil
		return true
	end

	function ENT:IntoGate(g, speed)
		self.IntoGateAt, self.IntoGateT = g, CurTime()   -- (meant to go through: the horizon check in sv_pursuit.lua leaves it be)
		local pos = self:GetPos()
		local rel = pos - g:GetPos()
		local ahead, lat = rel:Dot(g:GetForward()), rel:Dot(g:GetRight())
		local s = lat >= 0 and 1 or -1
		R.Dbg(self, "into the gate", "ahead", math.Round(ahead), "side", math.Round(lat), "stable", tostring(R.GateStable(g)))
		-- (right in front of the opening - in it, up to its plane - it keeps walking through.: with the one mover it slowed
		-- down there and stood 28-34 in front of the horizon; "under 40" sent it round to the side again and again,
		-- and it climbed the ring - test gi "it came out of the other gate": gone)
		local inOpening = ahead > -20 and math.abs(lat) < 90
		if (ahead < 40 and not inOpening) then
			if (math.abs(lat) < 260) then self:GoTo(g:GetPos() + g:GetRight() * s * 330 + g:GetForward() * math.max(ahead, -400), speed)
			else self:GoTo(g:GetPos() + g:GetRight() * s * 330 + g:GetForward() * 260, speed) end
		elseif (math.abs(lat) > 90) then   -- beside the opening: line up in front first (a straight line from out at
			-- the side crossed the gate's plane beside the opening: it came out behind the gate and went round again;
			-- within the opening it simply walks through)
			self:GoTo(g:GetPos() + g:GetForward() * 220 + Vector(0, 0, 10), speed)
		else
			self.Goal, self.Route, self.MoveTo, self.SpeedMul = g:GetPos() - g:GetForward() * 90 + Vector(0, 0, 10), nil, g:GetPos() - g:GetForward() * 90 + Vector(0, 0, 10), speed
		end
	end

	-- after prey through a Stargate or by ring (sv_pursuit.lua): through the open gate, or one dials it again; on the
	-- ring platform together, one sends them all
	function ENT:Pursue()
		local P = self.Pursuit
		local esc = P.esc
		local now = CurTime()
		local src, dst = esc.src, esc.dst
		-- (the prey itself may be gone from here: an NPC going through a gate is made anew on the other side - they go anyway)
		if (now > P.untilT or not IsValid(src) or not IsValid(dst)) then
			R.Dbg(self, "pursuit ends:", now > P.untilT and "time" or "way gone")
			R.EndPursuit(self) return
		end
		local pos = self:GetPos()
		self.State, self.Target = "pursue", nil
		-- on the other side: after the prey at once (or a new home)
		local dd = dst:GetPos() - pos
		if (esc.via == "rings" and Vector(dd.x, dd.y, 0):LengthSqr() < 350 * 350 and math.abs(dd.z) < 800 or esc.via == "gate" and dd:LengthSqr() < 700 * 700) then
			R.Stat("pursuers arrived")
			R.EndPursuit(self, true)
			return
		end
		if (esc.via == "gate") then
			-- waiting: beside the gate - the forming vortex (the kawoosh) shoots straight ahead and destroys what it touches
			local front = R.GateWaitSpot(src, self)
			local eh = src.EventHorizon
			local toDst = IsValid(eh) and IsValid(eh.Target) and eh.Target:GetParent() == dst
			-- the others are gone (the vortex, a weapon): alone it does not go - it grows the swarm first, and the swarm
			-- follows later, once they are enough again (the escape is kept for 10 minutes)
			local alive = 0
			for _, b in ipairs(P.members) do if (IsValid(b) and b.Pursuit == P and not b.RepGone) then alive = alive + 1 end end
			if (alive < 2 and #P.members >= 2 and not esc.safe and IsValid(esc.src)) then
				esc.party, esc.minParty, esc.owner, esc.hunters = nil, 3, self.RepOwner, {}
				esc.untilT = now + 600
				if (IsValid(esc.prey)) then R.escapes[esc.prey] = esc end
				R.Stat("waits to be more")
				R.Dbg(self, "alone: grows the swarm first, they follow later")
				R.EndPursuit(self)
				return
			end
			if (R.GateGo(src) and toDst) then
				-- the first one goes ahead; the others wait to know the way is safe (an iris over there: it would be lost)
				if (not esc.safe) then
					if (not (IsValid(P.vanguard) and P.vanguard.Pursuit == P and not P.vanguard.RepGone)) then P.vanguard = self end
					if (P.vanguard ~= self) then self:GoTo(front, 1.1) return end
				end
				-- open and going there: in from the front, straight through
				R.Dbg(self, "to the open gate", "ahead", math.Round((pos - src:GetPos()):Dot(src:GetForward())), "dist", math.Round(pos:Distance(src:GetPos())))
				self:IntoGate(src, 1.3)
				return
			end
			if (src.IsOpen or src.Dialling) then self:GoTo(front, 1.1) return end   -- busy: wait, out of the vortex's way
			-- shut: the first one dials it again (at the DHD if there is one, else beside the gate), the others wait
			if (P.leader ~= self and IsValid(P.leader) and P.leader.Pursuit == P) then self:GoTo(front, 1.1) return end
			P.leader = self
			local dhd = P.dhd
			P.besideT = P.besideT or now + 12   -- (cannot get to the DHD or beside the gate: it dials from where it is)
			if (IsValid(dhd) and dhd:GetPos():DistToSqr(pos) > 90 * 90 and not P.dialT and now < P.besideT) then self:GoTo(dhd:GetPos(), 1.2) return end
			local beside = src:GetPos() + src:GetRight() * 230 + src:GetForward() * 40
			if (not IsValid(dhd) and beside:DistToSqr(pos) > 120 * 120 and not P.dialT and now < P.besideT) then self:GoTo(beside, 1.2) return end
			self.MoveTo = nil
			if (not P.dialT) then P.dialT = now + 1.5; self:RepSound("agp_replicator/rep_chatter2.wav", 65, 115, 0.6) end
			if (now > P.dialT and not P.dialled) then
				-- nobody of them in front of the gate (the vortex would take them), at most 10 s
				local f = src:GetForward()
				for _, b in ipairs(P.members) do
					if (b ~= self and IsValid(b) and b.Pursuit == P) then
						if (R.InBlast(src, b:GetPos(), 60) and now < P.dialT + 10) then
							if (b.Goal == nil or b.Goal:DistToSqr(R.GateWaitSpot(src, b)) > 40 * 40) then b:GoTo(R.GateWaitSpot(src, b), 1.4) end
							return
						end
					end
				end
				P.dialled = now
				local ok = pcall(src.NoxDialGate, src, R.DialString(src, dst))
				R.Stat("pursuit dials")
				R.Dbg(self, "dials after its prey", tostring(ok))
			elseif (P.dialled and now - P.dialled > 8 and not src.Dialling and not src.IsOpen) then
				R.Dbg(self, "the gate will not dial: back")   -- no power, blocked: the hunt ends here
				for _, b in ipairs(P.members) do if (IsValid(b) and b.Pursuit == P) then R.EndPursuit(b) end end
			end
			return
		end
		-- rings: everyone onto the platform (each its own place in the circle), then the first one sends them
		-- the platform's middle (its own transport point moves with each use: the resting one, just above the base)
		local at = src:GetPos() + src:GetUp() * 50
		local idx = 1
		for i, b in ipairs(P.members) do if (b == self) then idx = i end end
		local spot = at + Angle(0, idx * 360 / math.max(1, #P.members), 0):Forward() * (#P.members > 1 and 30 or 0)
		local tr = util.TraceLine({ start = spot + Vector(0, 0, 60), endpos = spot - Vector(0, 0, 120), mask = MASK_SOLID_BRUSHONLY })
		if (tr.Hit) then spot = tr.HitPos end
		-- close enough: the ring takes what is within 80 of its point (the platform's rim may stop them a little short)
		local onPad = Vector(pos.x - spot.x, pos.y - spot.y, 0):LengthSqr() < 22 * 22 or Vector(pos.x - at.x, pos.y - at.y, 0):LengthSqr() < 72 * 72
		R.Dbg(self, "to the ring", "spot", math.Round(pos:Distance(spot)), "dz", math.Round(spot.z - pos.z), "on pad", tostring(onPad), "leader", tostring(P.leader == self))
		if (not onPad) then
			self.PauseUntil = nil
			-- right at the platform (a raised disc, too high to step onto): it jumps up onto it
			local flat = Vector(at.x - pos.x, at.y - pos.y, 0)
			if (flat:LengthSqr() < 130 * 130 and now > (self.NextLeap or 0) and not self.Falling) then
				self.NextLeap = now + 2
				self:StartFall(flat * 1.6 + Vector(0, 0, 230), true)
				return
			end
			if (pos:DistToSqr(spot) > 700 * 700) then
				if (not self.Goal or self.Goal:DistToSqr(spot) > 40 * 40) then self:GoTo(spot, 1.2) end
			else
				self.Goal, self.Route, self.MoveTo, self.SpeedMul = spot, nil, spot, 1.2   -- close: straight there (no old waypoints)
			end
		else
			self.MoveTo, self.Route, self.Goal = nil, nil, nil
		end
		if (not onPad) then return end   -- whoever stands on the platform may send them (the first one may be stuck outside)
		P.leader = self
		local ready = 0
		for _, b in ipairs(P.members) do
			if (IsValid(b) and b.Pursuit == P and Vector(b:GetPos().x - at.x, b:GetPos().y - at.y, 0):LengthSqr() < 70 * 70) then ready = ready + 1 end
		end
		P.waitT = P.waitT or now + 6
		-- (the Queen's escape: not without her - a guard on the pad sent itself over and left her behind)
		local q = P.queen
		local qOn = not IsValid(q) or Vector(q:GetPos().x - at.x, q:GetPos().y - at.y, 0):LengthSqr() < 70 * 70
		-- (she is longer than a ring is wide: the rising rings stuck on her, 3 of 5, and the transport never came. On the
		-- platform the rings go round her - she touches only the world until she is over there)
		if (IsValid(q) and qOn and not q.RingGhostT) then q.RingGhostT = now q:SetCollisionGroup(COLLISION_GROUP_WORLD) end
		if ((ready >= #P.members or now > P.waitT) and qOn and not src.Busy and not dst.Busy and now > (P.rang or 0) + 12) then
			P.rang = now
			src:DialEntity(dst)
			R.Stat("ring jumps")
			R.Dbg(self, "sends", ready, "by ring")
			self:RepSound("agp_replicator/rep_chatter2.wav", 65, 105, 0.6)
		end
	end

	function ENT:Colonize()
		local c = self.Colony
		local now = CurTime()
		if (not c or now > c.untilT or not IsValid(c.src) or not IsValid(c.dst)) then self.Role, self.Colony = nil, nil return end
		local src = c.src
		-- they wait beside the gate: the forming vortex (the kawoosh) shoots straight ahead and destroys what it touches
		local front = R.GateWaitSpot(src, self)
		self.State = "colonize"
		-- arrived on the other side: a new home
		if (self:GetPos():DistToSqr(c.dst:GetPos()) < 700 * 700 and c.phase == "through") then
			R.Stat("colonists arrived")
			if (R.safeGates) then R.safeGates[c.dst] = CurTime() end   -- (a gate one came out of alive: the Queen may use it)
			R.Dbg(self, "colonist arrived at", c.dst:GetGateAddress())
			self.Role, self.Colony = "worker", nil
			self.RepHome, self.RepHomeRadius = self:GetPos(), 1500
			return
		end
		-- through only when the horizon is stable (the forming vortex destroys what it touches)
		if (R.GateGo(src)) then
			c.phase = "through"
			self:IntoGate(src, 1.2)
			return
		end
		if (c.leader == self and not src.Dialling and not src.IsOpen) then
			local dhd = c.dhd
			c.dhdT = c.dhdT or now + 20
			if (IsValid(dhd) and now < c.dhdT and dhd:GetPos():DistToSqr(self:GetPos()) > 90 * 90) then self:GoTo(dhd:GetPos(), 1.0) return end
			local beside = src:GetPos() + src:GetRight() * 230 + src:GetForward() * 40
			c.besideT = c.besideT or now + 32   -- (cannot get there: it dials from where it is)
			if (not IsValid(dhd) or now >= c.dhdT) and beside:DistToSqr(self:GetPos()) > 120 * 120 and now < c.besideT then self:GoTo(beside, 1.0) return end   -- no DHD (or out of reach): beside the gate
			if (not c.dialT) then c.dialT = now + 2.5; self:RepSound("agp_replicator/rep_chatter2.wav", 65, 110, 0.6) end   -- "reading" the DHD
			if (now > c.dialT and not c.dialled) then
				c.dialled = true
				local ok, err = pcall(src.NoxDialGate, src, R.DialString(src, c.dst))
				R.Dbg(self, "dial result", tostring(ok), tostring(err), "dialling", tostring(src.Dialling), "open", tostring(src.IsOpen))
				timer.Simple(2, function()
					-- it did not start: no power (or blocked). The Queen remembers this gate; the colonists go back to work
					if (IsValid(src) and not src.Dialling and not src.IsOpen) then
						local h = R.Hive(self.RepOwner)
						h.badGates = h.badGates or {}
						h.badGates[src] = CurTime() + 300
						for b in pairs(R.bugs) do if (IsValid(b) and b.Colony == c) then b.Role, b.Colony = nil, nil end end
						R.Dbg(self, "gate will not dial: back to work")
					end
				end)
				R.Stat("gate dials")
				R.Dbg(self, "colonist dials", R.DialString(src, c.dst))
			end
			self.MoveTo = nil
			return
		end
		self:GoTo(front, 0.9)
	end

	-- go somewhere: far goals follow a route from the swarm's map memory, near ones are walked straight
	function ENT:GoTo(goal, speed)
		if (goal and (self.State == "wander" or self.State == "scout" or self.State == "regroup" or self.State == "guard") and R.Crowd(goal) >= 5) then
			for k = 1, 6 do
				local alt = goal + Angle(0, k * 60, 0):Forward() * 220
				if (R.Ground) then alt = R.Ground(self, alt, 400) end   -- (not beside a spot on a wall or roof: in the air)
				if (alt and R.Crowd(alt) < 3) then goal = alt break end
			end
		end
		if (R.TraceGoals) then local i = debug.getinfo(2, "Sl") self.GoalSrc = i and (string.match(i.short_src, "[^/]*$") .. ":" .. i.currentline) end   -- (test only: who set the goal)
		-- a goal inside an incoming gate's horizon (it kills): out of it on the same side, at its own height (in front
		-- when it lies in the disc itself) -
		local dz, da, _, de = nil, nil, nil, nil
		if (goal and R.InDeadZone) then dz, da, _, de = R.InDeadZone(goal, 20) end
		if (dz and de) then goal = goal + de.eh:GetForward() * ((da >= -1 and 1 or -1) * 90 - da) end
		self.Goal = goal
		self.SpeedMul = speed
		self.PauseUntil = nil
		local pos = self:GetPos()
		-- a way across the whole map (sv_nav.lua): out of a building, round one, down behind a wall - when it is far,
		-- much higher or lower, or something stands between. Ready: taken; being worked out: taken when it is (Think)
		self.NavWait = nil
		if (self.RepClimb and R.Nav and R.Nav.Wanted(pos, goal)) then
			local r = R.Nav.Request(pos, goal)
			if (r) then self:TakeWay(r, pos) return end
			if (r == nil) then self.NavWait = { from = Vector(pos), goal = goal, t = CurTime() } end
		end
		if (goal:DistToSqr(pos) > 700 * 700) then
			self.Route = R.Map.Path(pos, goal, 500)
			self.RouteI = 1
		else
			self.Route = nil
		end
		self.MoveTo = self.Route and self.Route[1] or goal
	end

	-- a way across the map (sv_nav.lua) as its waypoints: on from the one after the nearest it already is at
	-- (from the nearest one it can SEE: by distance alone, under the top floor's ceiling of a building that was the
	-- way's last one, on the roof right above - the way was over at once, it went straight up into the ceiling, wobbled
	-- there and got the same way again every 3 s) no way to what it goes for, not from inside and not from out
	-- under the open sky: that one is left alone for a minute and it looks again at once - the next food it smells.
	-- Twice without a way in a row: only then (a first "no way" can be a way still being worked out round a closed step).
	-- Prey (players, NPCs) is not given up this way.
	--
	function ENT:NoWayToTarget(now)
		local t = self.Target
		if (not IsValid(t) or t:IsPlayer() or t:IsNPC()) then return end
		self.NoWayN = (self.NoWayT == t) and (self.NoWayN or 0) + 1 or 1
		self.NoWayT = t
		if (self.NoWayN < 2) then return end
		self.NoWayN = 0
		self.Avoid = self.Avoid or {}
		self.Avoid[t] = now + 60
		self.State, self.Target, self.Route, self.Goal, self.MoveTo = "wander", nil, nil, nil, nil
		self.NextLook = 0
		R.Stat("no way to its target: looks for another")
		R.Dbg(self, "no way to", t, "- looks for another")
	end

	function ENT:TakeWay(r, pos)
		local eye = pos + (self.RepUp or Vector(0, 0, 1)) * 8
		local function sees(q) return (R.TestOff and R.TestOff.waySight) or R.Nav.Sees(eye, q, self.Target) end   -- (TestOff: test runs only)
		local i, bd = 1, nil
		for k, q in ipairs(r) do local d = q:DistToSqr(pos) if ((not bd or d < bd) and sees(q)) then i, bd = k, d end end
		if (bd and bd < 90 * 90 and r[i + 1] and sees(r[i + 1])) then i = i + 1 end
		self.Route, self.RouteI = r, i
		self.MoveTo = r[i]
		self.NavUsed, self.NavRoute = CurTime(), r
		R.Dbg(self, "way across the map", #r, "points, from", i)
	end

	-- feelers (invisible traces): is the way ahead open? if not, the most open direction that still leads to the goal,
	-- avoiding places where it was just now (no walking in circles)
	function ENT:Feel(pos)
		local goal = self.MoveTo
		if (not goal) then return end
		-- the way to the goal runs through an incoming gate (its horizon kills, the ring's foot is no way past it either): a
		-- steering point beside it first (sv_pursuit.lua R.RoundDead)
		local round = R.RoundDead and R.RoundDead(pos, goal)
		if (round) then
			if (self:SetSteer(round, pos)) then return end
		end
		local up = self.RepUp or Vector(0, 0, 1)
		local d = goal - pos; d = d - up * d:Dot(up)
		local dist = d:Length()
		if (dist < 40) then return end
		d:Normalize()
		local eye = pos + up * 10
		local look = 140
		local skip = function(e)   -- not around what it goes for (its food, its prey), nor around a Stargate (it walks into it)
			if (e == self or e == self.Target or e.IsStargate or e:GetClass() == "event_horizon") then return false end
			return true
		end
		local tr = util.TraceLine({ start = eye, endpos = eye + d * look, filter = skip, mask = MASK_SOLID })
		-- (an incoming gate's horizon kills what touches it: the way through one is blocked, like a wall)
		local dead = R.SegDead and R.SegDead(eye, eye + d * look, 50)
		-- free, or a wall it can climb (the map's, or a prop's - a player's build, a crate: they climb those too)
		if (not dead and (not tr.Hit or ((tr.HitWorld or (IsValid(tr.Entity) and R.Walkable and R.Walkable(tr.Entity))) and self.RepClimb))) then self.SteerTo = nil return end
		-- (on the ground only - a Queen: stairs and low steps are no wall. Her feeler at 10 up hit the first 12-high step,
		-- she turned away along the stairs' foot and never went up. The ground along the way is felt step by step: no rise
		-- over 20 at a time, room above it)
		if (not dead and not self.RepClimb and tr.Hit) then
			local prev, ok = pos.z, true
			for k = 1, 6 do
				local fp = pos + d * (look * k / 6)
				local t = util.TraceLine({ start = Vector(fp.x, fp.y, prev + 26), endpos = Vector(fp.x, fp.y, prev - 30), filter = skip, mask = MASK_SOLID })
				if (t.StartSolid or (t.Hit and t.HitPos.z > prev + 20)) then ok = false break end
				if (t.Hit) then prev = t.HitPos.z end
			end
			if (ok) then self.SteerTo = nil return end
		end
		local right = d:Cross(up)
		local cand = {}
		for i = -3, 3 do
			if (i ~= 0) then
				local a = math.rad(i * 32)
				local dir = d * math.cos(a) + right * math.sin(a)
				local t2 = util.TraceLine({ start = eye, endpos = eye + dir * look, filter = skip, mask = MASK_SOLID })
				local open = t2.Fraction
				if (dead and R.SegDead(eye, eye + dir * look, 50)) then open = -1 end   -- (that way leads into the deadly horizon too)
				local endp = eye + dir * look * open
				local c = R.Map.cells[R.Map.Key(endp)]
				cand[#cand + 1] = { dir, open * 2 + math.cos(a) - (c and math.min(c.v, 20) * 0.03 or 0) - (c and c.d * 0.3 or 0) }
			end
		end
		table.sort(cand, function(x, y) return x[2] > y[2] end)
		-- (the most open way that also has something to stand on: open air past a board's end looked the most open of all)
		for k = 1, math.min(3, #cand) do
			if (self:SetSteer(pos + cand[k][1] * 120, pos)) then return end
		end
		self.SteerTo = nil
	end

	-- outside the world for several looks running (3; a Queen 6): removed. Once was not enough - a big Queen bumping a
	-- wall, or jumping onto a ring platform, had her middle in it for a moment and was gone
	function ENT:OutOfWorld(pos)
		if (util.IsInWorld(self:WorldSpaceCenter()) or util.IsInWorld(self:WorldSpaceCenter() + Vector(0, 0, 40))) then self.OutN = 0 return false end
		self.OutN = (self.OutN or 0) + 1
		if (self.OutN < (self.RepKind == "queens" and 6 or 3)) then return false end
		R.Dbg(self, "left the world at", tostring(pos))
		self:Remove()
		return true
	end

	-- (a body the physics put to sleep is skipped by the engine: PhysicsSimulate - where it walks, and where it was
	-- woken - is not called any more. Standing still a moment, it fell asleep and stood for good; only the "stuck" hop
	-- woke it, it moved a little and slept again: it hopped like a frog. The brain, which always runs, wakes it)
	function ENT:KeepAwake()
		if (self.Falling or self.Boarded or self.RepGone or not (self.MoveTo or self.Goal)) then return end
		if (self.Eating or R.Resting(self)) then return end   -- (asleep on purpose: eating, resting while the game is behind, dormant)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph) and ph:IsMotionEnabled() and ph:IsAsleep()) then ph:Wake() end
	end

	-- ---------- never looks broken (plan B: walking every map and every player's build perfectly is not possible - a
	-- bug that lies tipped over, hangs on a wall or gets nowhere does what Replicators do in the series: it falls apart,
	-- its blocks tumble on towards where it was going and it is built again there, ENT:BreakFree). Tipped: its
	-- body over ~55 degrees off what its legs are on for 1.5 s (the turns at corners and lips take less). Getting
	-- nowhere while it wants to go somewhere (not within 80 of where it goes): 2.5 s on a wall or ceiling, 8 s on the
	-- floor (there the stuck check in ENT:Think with its detours comes first). Not while it falls, jumps, goes round a
	-- corner, eats, waits on purpose (ambush, hiding, at a gap for a bridge), rides a ship or is held.
	function ENT:BrokenCheck(now, pos)
		-- (nor while it rests on purpose: far off while the game is behind, held still by the lag guard - 46 resting bugs
		-- "got nowhere" and broke apart in one busy-world test)
		if (self.RepKind ~= "bugs" or self.RepMini or self.Falling or self.Jumping or self.Transit or self.InTower or self.InBridge or self.Boarded or self.Eating or self:IsPlayerHolding()
			or R.Resting(self)) then
			self.TipT, self.HangPos = nil, nil
			return false
		end
		local u = self.RepUp or Vector(0, 0, 1)
		if (self:GetUp():Dot(u) < 0.6) then
			self.TipT = self.TipT or now
			-- (longer while it leans onto a wall ahead and its walker just gave up going round that corner body and all:
			-- its old way up takes a few seconds - 2 climbers at the foot of gm_flatgrass's platform broke apart after
			-- 1.5 s)
			local lean = self.TransitFailT and now - self.TransitFailT < 4
			if (now - self.TipT > (lean and 5 or 1.5)) then return self:BreakFree("tipped over", now) end
		else
			self.TipT = nil
		end
		local g = self.MoveTo or self.Goal
		-- (not stuck: at its prey or its food with others crowding round it - 52 attackers round the player broke apart for
		-- that in one busy-world test)
		local t = self.Target
		local atTarget = IsValid(t) and (self.State == "attack" or self.State == "eat" or self.State == "drain" or self.State == "deliver") and t:GetPos():DistToSqr(pos) < 350 * 350
		-- (not while it waits for its way to be worked out - it stands on purpose then)
		local wants = g and not atTarget and g:DistToSqr(pos) > 80 * 80 and self.State ~= "ambush" and self.State ~= "hide" and not (self.GapUntil and now < self.GapUntil + 1) and not (self.NavWait and not self.MoveTo)
		if (not wants or not self.HangPos or pos:DistToSqr(self.HangPos) > 14 * 14) then self.HangPos, self.HangT = pos, now return false end
		local wall = u.z < 0.6
		if (now - self.HangT > (wall and 2.5 or 8)) then return self:BreakFree(wall and "hanging on a wall" or "getting nowhere", now) end
		return false
	end

	-- falls apart on purpose and is built again a few seconds later: the blocks are thrown a little towards where it was
	-- going and fly for real (walls stop them), then they are drawn together where most of them lie (agp_replicators.lua,
	-- "rebuilt in time"). The way it got stuck on counts as slow and the place as "been here a lot": the swarm learns.
	-- At most 2 a second in the whole swarm, and the rebuilt bug does not do it again for 15 s (the stuck check's
	-- detours and giving up a goal take over there).
	function ENT:BreakFree(why, now)
		if (self.RepGone or now < (self.FreedT or 0) + 15) then return false end
		-- a player near (1200) looking at it - it holds on and keeps trying, and falls apart once he looks away; after 20
		-- s in plain view it goes anyway (stuck for good looks broken too). Asked again every think while it is stuck: a
		-- pause of 2 s starts a new count.
		if (not self.WatchLast or now - self.WatchLast > 2) then self.WatchT = now end
		self.WatchLast = now
		if (now - self.WatchT < 20 and R.Watched and R.Watched(self:WorldSpaceCenter(), 1200)) then
			if (not self.WatchSaid or now > self.WatchSaid) then self.WatchSaid = now + 5; R.Dbg(self, "would break apart (" .. why .. "), but a player is watching"); R.Stat("break apart held: watched") end
			return false
		end
		local sec = math.floor(now)
		if (R.freeSec ~= sec) then R.freeSec, R.freeN = sec, 0 end
		local n = self.RepBlocks + math.min(self.RepStock or 0, 12)
		if (R.freeN >= 2 or not R.RoomForBlocks(n)) then return false end
		R.freeN = R.freeN + 1
		if (R.SurfNav and R.SurfNav.Fell) then R.SurfNav.Fell(self, false) end
		R.Map.Mark(self:GetPos(), "v", 5)
		R.Reward(self, -1)
		R.Brain.Settle(self)
		R.Stat("broke apart to get free")
		R.Stat("broke apart: " .. why)
		R.Dbg(self, "breaks apart to get free:", why, "state", tostring(self.State), "up", tostring(self.RepUp), "z", math.Round(self:GetPos().z))
		self.RepGone = true
		local g = self.Goal or self.MoveTo
		local to = g and (g - self:WorldSpaceCenter()) or Vector(0, 0, 0)
		to.z = 0
		if (to:LengthSqr() > 1) then to:Normalize() end
		local by = now + math.Rand(2.5, 3.5)
		local grp = {}
		local mind, idx = self.Mind, self:EntIndex()
		R.Burst(self, n, self.RepOwner, 1.5, 90, function(b)
			b.RepMind, b.RepGroup, b.RepRebuildBy, b.RepFreedT, b.RepFormerIdx = mind, grp, by, now, idx
			local ph = b:GetPhysicsObject()
			if (IsValid(ph)) then ph:AddVelocity(to * 90) end
		end)
		self:Remove()
		return true
	end

	function ENT:Think()
		local now = CurTime()
		if (self.Clinging) then self:ClingThink(now) self:NextThink(now + 0.1) return true end
		-- riding a wormhole (hidden and frozen at the gate till it comes out over there, sv_pursuit.lua): nothing to do
		if (self.GateRide) then
			if (now - self.GateRide > 12) then self.GateRide = nil end   -- (never told it came out: carry on)
			self:NextThink(now + 0.2) return true
		end
		self:KeepAwake()
		-- (standing still while it eats, or resting far off while the game is behind: its body asleep - the physics skips
		-- it; KeepAwake wakes it when that is over)
		-- (asleep, PhysicsSimulate is not called: the check that its resting ground is still there is made here too)
		if (self.RestAt and self.RestOn ~= nil and not IsValid(self.RestOn) and not self.Falling) then self:RestLost() end
		-- what it rests on is still there, but no longer under it: a StarCore ship broken apart keeps its hull entity, the
		-- deck's pieces blown off - its resting bugs hung where the deck had been (packed run, sgship: 12 hang 600 over
		-- the wreck). Nothing under it twice in a row (1 s): it falls; another piece under it: held on that one. (held on
		-- the world - RestOn nil - too: flung off by the blast, it came to rest in mid-air and stayed there)
		if (self.RestAt and (self.RestOn == nil or IsValid(self.RestOn)) and not self.Boarded and not self.Falling and not self.Jumping and now > (self.RestCheckT or 0)) then
			self.RestCheckT = now + 0.5
			local ru = self.RepUp or Vector(0, 0, 1)
			local pos = self:GetPos()
			local tr = util.TraceLine({ start = pos + ru * 8, endpos = pos - ru * 40, mask = MASK_SOLID,
				filter = function(e) return not e.AGPReplicator and not e:IsPlayer() and not e:IsNPC() and not e.SpaceGridKeel end })
			local g = tr.Hit and IsValid(tr.Entity) and not tr.Entity:IsWorld() and tr.Entity or nil
			if (not tr.Hit) then
				self.RestMiss = (self.RestMiss or 0) + 1
				if (self.RestMiss >= 2) then self.RestMiss = nil self:RestLost() end
			else
				self.RestMiss = nil
				if (g ~= self.RestOn) then
					self.RestOn = g
					if (g) then
						self.RestL, self.RestLA = g:WorldToLocal(pos), g:WorldToLocalAngles(self:GetAngles())
						g.AGPRepRestOn = true
					else
						self.RestAt, self.RestAng = pos, self:GetAngles()   -- (on the world now: held where it is)
					end
				end
			end
		end
		-- resting on the deck of a flying ship: fixed to it, its body out of the physics (the author's play test: the lag
		-- guard's resting bugs were held after the deck by force while the ship moved them too - "bugged into the hull and
		-- not stable on their frozen place when I fly around", and 20 loose bodies moved by the ship every tick) (on
		-- a ship that stands too: its body asleep is not moved when the ship starts - 7 of 8 were left behind in the air, and
		-- the bugs on a wreck flung away by its blast hung where it had been, test sgcore/sgship)
		if (self.RestAt and not self.Boarded and not self.Falling and not self.Jumping and not self.RepGone and now > (self.RestDeckT or 0)) then
			self.RestDeckT = now + 0.5
			local deck = (IsValid(self.RestOn) and R.ShipCore(self.RestOn)) and self.RestOn or self:FlyingDeck(self:GetPos())
			if (deck) then
				self.Goal, self.MoveTo, self.Route, self.GatherT = nil, nil, nil, nil
				self:Board(deck, true)
				R.Stat("rest: held on to a flying deck")
			end
		end
		if ((self.Eating or R.Resting(self)) and not self.Falling and not self.Jumping and not self.Boarded) then
			local ph = self:GetPhysicsObject()
			if (IsValid(ph) and not ph:IsAsleep() and ph:GetVelocity():LengthSqr() < 25) then ph:Sleep() end
		end
		if (not self:GetCustomCollisionCheck()) then self:SetCustomCollisionCheck(true) end   -- (a Stargate's horizon switches it off)
		local pos = self:GetPos()
		if (self:BrokenCheck(now, pos)) then return end
		-- far from every player: think less often (a sleeping part of the swarm costs almost nothing)
		local near, close = false, false
		for _, p in ipairs(player.GetAll()) do
			local d = p:GetPos():DistToSqr(pos)
			if (d < 3000 * 3000) then near = true end
			if (d < 1300 * 1300) then close = true break end
		end
		self.RepFar = not near
		self.RepMid = near and not close   -- seen only from further away: walks with half the probing (PhysicsSimulate)
		-- can any player see it? Not when he is far, it is behind him, or a wall is between. Unseen it walks with two rays
		-- instead of its legs' (PhysicsSimulate) - twice a second
		if (now > (self.SeenT or 0)) then
			self.SeenT = now + 0.5
			local c, unseen = self:WorldSpaceCenter(), true
			for _, p in ipairs(player.GetAll()) do
				local eye = p:EyePos()
				local to = c - eye
				local d2 = to:LengthSqr()
				if (d2 < 260 * 260) then unseen = false break end   -- (right by him: always properly)
				if (d2 < 3500 * 3500 and p:GetAimVector():Dot(to:GetNormalized()) > 0.25
					and not util.TraceLine({ start = eye, endpos = c, mask = MASK_OPAQUE, filter = { p, self } }).HitWorld) then unseen = false break end
			end
			self.RepUnseen = unseen
		end
		self:NextThink(now + ((R.lag and R.lag.dormant) and 2 or near and (R.lag and R.lag.behind and 0.3 or 0.2) or (R.lag and R.lag.behind and 3 or 1.0)))   -- (while the game is behind: 0.3 s near, 3 s far off; dormant: 2 s)
		if (not near and now < (self.NextFarThink or 0)) then return true end   -- far from everyone: a calm, slow mind
		if (not near) then self.NextFarThink = now + 2.5 end
		if (not R.Awake()) then self.MoveTo = nil return true end
		-- outside the world (fell out of the map): removed - but only when it really is, not a few units into a floor
		-- (its feet are on the floor; a ring sets things down a little into it)
		if (self:OutOfWorld(pos)) then return end
		if (self.Falling) then
			if (now - self.FallT > 6) then self:Land() end   -- never landed (stuck on something): carry on
			return true
		end
		if (self.RightUntil and now < self.RightUntil) then return true end
		if (self.BridgeJob) then   -- on its way to build: nothing else on its mind (its brain sent it elsewhere after 20 s)
			local T = self.BridgeJob
			if (T.dead or T.done) then self.BridgeJob = nil
			elseif (self:GetPos():DistToSqr(T.st) < 50 * 50) then self:JoinBridge(T, now) return true
			else self.MoveTo, self.Route, self.Goal = T.st, nil, nil; self.NextLook = math.max(self.NextLook or 0, now + 2) end
		end
		if (self.RepClimb and self.MoveTo and not self.Crossing and (self.RepUp or Vector(0, 0, 1)).z > 0.9 and now > (self.NextGap or 0)) then
			self.NextGap = now + 0.7
			if (self:Bridge(pos, now)) then return true end
		end
		if (self.InTower) then   -- part of a tower: holds still while it stands
			local T = self.InTower
			if (not IsValid(T.aim) or now > T.till or T.aim.Destroying) then
				local h = R.Hive(self.RepOwner)
				if (h.towers and h.towers[T.aim] == T) then h.towers[T.aim] = nil end
				R.TowerDown(T)
				if (self.InTower) then   -- still climbing (not in the list yet)
					self.InTower = nil
					self:SetNWBool("RepTower", false)
					local ph = self:GetPhysicsObject()
					if (IsValid(ph)) then ph:EnableMotion(true) end
					self:StartFall()
				end
			end
			return true
		end
		if (self.Boarded) then
			local sh = self.Boarded
			local core = IsValid(sh) and R.ShipCore(sh)
			if (not IsValid(sh) or (not self.BoardInside and (sh.Destroying or (core and core.Destroyed) or sh.SGWreck))) then self:LetGo() return true end
			if (self.BoardInside) then
				-- (on a wreck that stays - StarCore's burning wreck - it holds on while it still moves: let go in a wreck
				-- flung and falling, 116 loose bugs and 430 blocks were moved by it every tick, game time 16 %) on a flying
				-- ship's deck: the ship stands again (1.5 s slow) - it lets go and walks on it as on any floor
				local k = sh.SGKeel
				local kp = IsValid(k) and k:GetPhysicsObject() or sh:GetPhysicsObject()
				-- (resting - the lag guard: it holds on, also to a ship that stands)
				if (R.Resting(self)) then self.BoardSlowT = nil
				elseif (not IsValid(kp) or kp:GetVelocity():LengthSqr() < 60 * 60) then
					self.BoardSlowT = self.BoardSlowT or now
					if (now - self.BoardSlowT > 1.5) then self:LetGo() return true end
				else self.BoardSlowT = nil end
				-- (resting - the lag guard: it only holds on)
				if (not R.Resting(self) and self.RepStock >= R.BLOCKS_PER_BUG) then self:BuildAboard(sh) end
				if (not R.Resting(self) and not self.Eating and now > (self.NextChew or 0) and R.cv.eat:GetInt() > 0 and R.Edible(sh)) then
					self.NextChew = now + 0.5; self.State, self.Target = "eat", sh; self:Eat(sh)
				end
				self:NextThink(now + 0.25)
				return true
			end
			-- what it ate becomes new blocks right away: they drop off the ship and assemble below
			if (self.RepStock >= R.BLOCKS_PER_BUG) then self:UseStock() end
			if (not self.Eating and now > (self.NextChew or 0)) then self.NextChew = now + 0.5; self:Eat(self.Boarded) end
			return true
		end
		-- the map memory: where it walks becomes known
		if (now > (self.NextVisit or 0)) then
			self.NextVisit = now + 0.6
			local key, c = R.Map.Visit(pos, self.MapKey)
			if (key ~= self.MapKey and c and c.v == 1) then R.Reward(self, 0.05) end   -- a new place the swarm did not know
			self.MapKey = key
		end
		if (self.BrainDec and now - self.BrainDec.t0 > 15) then local d = self.BrainDec; R.Brain.Settle(self); R.Brain.Decided(self, d.sit, d.opt) end
		if (self.Role == "scout" and now > (self.NextCover or 0)) then self.NextCover = now + 2; R.Map.Cover(pos) end
		if (now > (self.NextLook or 0)) then
			local tk = engine.TickCount()
			if (R.lookTick ~= tk) then R.lookTick, R.lookN = tk, 0 end
			-- (a few looks a tick for the whole swarm - attackers too: 100 bugs going for the player looked every 0.5 s each,
			-- past the limit, and the game fell behind; one just hurt still looks at once)
			if (R.lookN < math.max(6, math.ceil((R.bugN or 0) / 20)) or now - (self.HurtT or -9) < 3) then
				R.lookN = R.lookN + 1
				self.NextLook = now + (self.State == "attack" and math.Rand(0.7, 0.9) or math.Rand(0.8, 1.4)); self:Look()
			end
		end
		self:WarnOff(now, pos)
		self:Brain(now, pos)
		-- its way runs through a player's build part the plan saw it can eat (sv_nav.lua, Route.eats) - at it, it eats it
		-- out of the way; the way is worked out again once it is gone. One no longer edible (or gone) is crossed off.
		--
		local ea = self.Route and self.Route.eats
		if (ea and not self.Eating) then
			local e = ea[1]
			while (e ~= nil and not (IsValid(e) and R.Edible(e))) do table.remove(ea, 1) e = ea[1] end
			if (IsValid(e) and e:NearestPoint(pos):DistToSqr(pos) < 50 * 50) then
				self.State, self.Target, self.MoveTo, self.Route = "eat", e, nil, nil
				self:Eat(e)
				R.Stat("ate a way through a player's build")
				R.Dbg(self, "eats a way through", e)
			end
		end
		-- route: next waypoint
		-- (on to the next one only when it sees it from here, or is at this one: from 90 away it turned for the next one at
		-- once - at a door that is round the door's edge, at a stair hole round its rim - and went straight at it, up the
		-- wall beside the door, into the ceiling under the hole, and wobbled there)
		--
		if (self.Route and self.MoveTo and self.MoveTo:DistToSqr(pos) < 90 * 90 and not (R.Mover and R.Mover.Owns(self))) then
			local nx = self.Route[self.RouteI + 1] or self.Goal
			self.WpNearT = (self.WpNearI == self.RouteI and self.WpNearR == self.Route) and self.WpNearT or now
			self.WpNearI, self.WpNearR = self.RouteI, self.Route
			local up0 = self.RepUp or Vector(0, 0, 1)
			local eye = pos + up0 * 8
			-- (on a wall a waypoint in the air out in front of it - a cell of the way across the map, beside a cliff - is
			-- never within 28: right in front of it along the wall it counts as reached. It stood still there on the high
			-- edge's cliff and let go before the 3 s were over, strict 0 of 3 clean)
			local tw = self.MoveTo - pos
			local onWall = math.abs(up0.z) < 0.7 and tw:Dot(up0) > 0 and (tw - up0 * tw:Dot(up0)):LengthSqr() < 28 * 28
			-- (near is not there when the waypoint is on the far side of a surface: under a car park's ramp, 6 thick, the
			-- waypoint on its top 23 away counted as reached through it, and after 3 s near it the next one was taken - also
			-- behind the ramp; the bug hung under the ramp for the rest of the minute. Reached only with nothing of the map
			-- between; hidden for 3 s: back to the waypoint before it (it came from there, it sees it), a second time: the
			-- way is given up and asked for anew from where it is) (a surface right at the waypoint does not hide it:
			-- round a window's sill the waypoint lies 3 off the edge and the line to it grazed the edge - it stood 3 s, 7 away;
			-- the ramp's top is 9 and more behind its underside)
			--
			local htr = util.TraceLine({ start = eye, endpos = self.MoveTo, mask = MASK_PLAYERSOLID_BRUSHONLY })
			local hid = htr.Hit and (1 - htr.Fraction) * eye:Distance(self.MoveTo) > 7
			-- (the next one behind the surface it stands on - over a sill, down the wall's far face: this one must really be
			-- reached. On the inside wall beside a window's frame, 25 from the sill's waypoint, "near" and "on a wall" took it,
			-- and it aimed at the far face through the wall and stood 20 s. 6 s at most. Only on a wall: on the floor
			-- before a cliff's edge the next one is below it too - three bugs waited at the edge's waypoint, pushed
			-- each other, "left the crowd" and went off, strict high edge 0/3) (not in a crowd,
			-- and 20 near: within 14 three bugs on one parapet pushed for the same waypoint, "left the crowd" and went off -
			-- strict high edge 0/3 twice, 1/3 with the rule off) (and only
			-- while it still gets closer: pressed against a pillar's corner 21 from the waypoint it stood the 6 s, spot
			-- probe - no nearer for 1.5 s, the usual rules again)
			local dwp = self.MoveTo:Distance(pos)
			if (self.WpBestI ~= self.RouteI or self.WpBestR ~= self.Route) then self.WpBestI, self.WpBestR, self.WpBestD, self.WpBestT = self.RouteI, self.Route, dwp, now
			elseif (dwp < self.WpBestD - 2) then self.WpBestD, self.WpBestT = dwp, now end
			local behind = self.Route.felt and nx and math.abs(up0.z) < 0.7 and (nx - pos):Dot(up0) < -4 and now - self.WpNearT < 6 and (self.Bumps or 0) < 2
				and now - self.WpBestT < 1.5
			local near = self.MoveTo:DistToSqr(pos) < (behind and 20 * 20 or 28 * 28)
			if (not hid and (not nx or near or not behind and (onWall or now - self.WpNearT > 3))
				or not behind and R.Nav.Sees(eye, nx, self.Target)) then
				self.RouteI = self.RouteI + 1
				self.MoveTo = self.Route[self.RouteI] or self.Goal
				if (not self.Route[self.RouteI]) then self.Route = nil end
			elseif (hid and now - self.WpNearT > 3) then
				self.WpBack = (self.WpBackR == self.Route) and (self.WpBack or 0) + 1 or 1
				self.WpBackR = self.Route
				if (self.WpBack <= 1 and self.RouteI > 1) then
					self.RouteI = self.RouteI - 1
					self.MoveTo = self.Route[self.RouteI]
					R.Stat("way: waypoint behind a surface - back to the one before")
				else
					self.Route, self.MoveTo, self.NavRetryT = nil, self.Goal, now + 1
					R.Stat("way: waypoint behind a surface again - asked anew")
				end
				self.WpNearT = now
			end
		end
		-- its way across the map, being worked out: taken when it is ready (and still for the same goal)
		if (self.NavWait) then
			local w = self.NavWait
			if (self.Goal ~= w.goal or now - w.t > 20) then self.NavWait = nil self.MoveTo = self.MoveTo or self.Goal   -- (20: a long way on the felt map takes up to 15 s to work out)
			else
				local r
				if (w.out) then r = R.Nav.RequestOut(w.from) else r = R.Nav.Request(w.from, w.goal) end
				-- (while its way is worked out it waits where it is: straight at a goal high up it went into the corner of the
				-- ceiling and wobbled there for the 15 s the way took watching) (only for a goal
				-- well above it: for one level with it, out of a building to the ground, it walked on and was out in 3-15 s;
				-- waiting it stood 33 s) (on a floor only: stopped on a wall it counted
				-- as hanging there and fell apart - gm_construct's lip test, 3 of 3) (not under water: on gm_construct's
				-- pool floor it stood the whole 20 s and
				-- the goal was dropped - repwater, closest 880) (only under a roof: under open sky there is no ceiling
				-- corner, and it stood 6 s for a way to an
				-- Al'kesh 5000 off - the author's game; looked at once per wait)
				--
				if (r == nil and now - w.t > 0.3 and w.goal and w.goal.z > pos.z + 120 and (self.RepUp or Vector(0, 0, 1)).z > 0.7 and self:WaterLevel() < 2) then
					-- (or a climb right here, its goal less than 800 off to the side: walking on before the way came, at gm_construct's
					-- shelf the way came later, threw away the plan up the shelf, and it ran to and fro for 40 s - course 4.1)
					if (w.roof == nil) then w.roof = Vector(w.goal.x - pos.x, w.goal.y - pos.y, 0):LengthSqr() < 800 * 800 or util.TraceLine({ start = pos + Vector(0, 0, 10), endpos = pos + Vector(0, 0, 3000), mask = MASK_PLAYERSOLID_BRUSHONLY }).Hit end
					if (w.roof) then self.MoveTo = nil end
				end
				if (r) then self.NavWait = nil self:TakeWay(r, pos)
				elseif (r == false) then
					self.NavWait = nil
					self.MoveTo = self.MoveTo or self.Goal
					R.Dbg(self, "no way across the map:", tostring(R.Nav.lastWhy))
					-- (no way to its goal and a roof over it: first the way out to open sky, sv_nav.lua V.RequestOut - straight at a
					-- goal high up it went into the corner of the ceiling and wobbled there)
					if (not w.out and R.Nav.RequestOut and util.TraceLine({ start = pos + Vector(0, 0, 10), endpos = pos + Vector(0, 0, 3000), mask = MASK_PLAYERSOLID_BRUSHONLY }).Hit) then
						self.NavWait = { from = Vector(pos), goal = self.Goal, t = now, out = true }
					else
						self:NoWayToTarget(now)
					end
				end
			end
		end
		-- its way across the map was lost (it stepped aside when stuck, a detour ended, it waited too long for it) and its
		-- goal still lies behind something, far or high: it asks again every 3 s. It asked only when its goal changed - for
		-- food that stays put, never again, and it went straight for it (freespace13: inside a building, the ships behind
		-- it, they wobbled in the top corner of the ground floor's ceiling)
		if (self.Goal and not self.Route and not self.NavWait and not self.DetourUntil and not self.SurfPath and self.RepClimb and R.Nav and now > (self.NavRetryT or 0)
			and not self.Transit and not self.InTower and not self.InBridge and not self.BridgeJob and not self.Crossing and not self.Boarded and not self.Clinging
			and self.State ~= "attack" and self.State ~= "flee" and self.State ~= "merge" and not (IsValid(self.Target) and (self.Target:IsPlayer() or self.Target:IsNPC()))) then
			self.NavRetryT = now + 3
			if (R.Nav.Wanted(pos, self.Goal)) then
				local r = R.Nav.Request(pos, self.Goal)
				if (r) then self:TakeWay(r, pos) R.Stat("asked again for a way across the map")
				elseif (r == nil) then self.NavWait = { from = Vector(pos), goal = self.Goal, t = now }
				elseif (R.Nav.RequestOut and util.TraceLine({ start = pos + Vector(0, 0, 10), endpos = pos + Vector(0, 0, 3000), mask = MASK_PLAYERSOLID_BRUSHONLY }).Hit) then
					self.NavWait = { from = Vector(pos), goal = self.Goal, t = now, out = true }   -- (known: no way - the way out first)
				else
					self:NoWayToTarget(now)
				end
			end
		end
		if (self.MoveTo and near and now > (self.NextFeel or 0)) then self.NextFeel = now + 0.4; self:Feel(pos) end
		-- keep a little distance from the others (they do not pile up)
		if (now > (self.NextSep or 0)) then
			self.NextSep = now + 0.5
			local bumped = false
			for _, e in ipairs(ents.FindInSphere(pos, 30)) do
				if (e ~= self and e.AGPReplicator and e.RepKind == "bugs" and self.MoveTo) then
					-- (aside along the surface it is on: in the world's directions the step aside went through the board
					-- it stood on and over its top - it climbed after it and fell)
					local u = self.RepUp or Vector(0, 0, 1)
					local away, on = pos - e:GetPos(), self.MoveTo - pos
					away = away - u * away:Dot(u); on = on - u * on:Dot(u)
					self:SetSteer(pos + away:GetNormalized() * 50 + on:GetNormalized() * 40, pos)
					bumped = true
					break
				end
			end
			-- a safety net when the shared picture was a moment late: bumping into others again and again without getting
			-- anything done (no bite, no build) - it is in a crowd: the outer ones change their plan, the crowd thins out
			local progress = self.MoveTo and self.LastGoalD and self.MoveTo:DistToSqr(pos) < self.LastGoalD - 100
			self.LastGoalD = self.MoveTo and self.MoveTo:DistToSqr(pos) or nil
			self.Bumps = math.max(0, (self.Bumps or 0) - 0.5) + ((bumped and not progress) and 1 or 0)
			if (self.Bumps >= 8 and self.State ~= "deliver" and self.State ~= "guard" and not self.Eating and not self.InTower and not self.InBridge and self.State ~= "attack" and self.State ~= "merge") then
				self.Bumps = 0
				local inner = self.Target and IsValid(self.Target) and self.Target:NearestPoint(pos):DistToSqr(pos) < 60 * 60
				if (not inner) then
					if (IsValid(self.Target)) then self.Avoid = self.Avoid or {}; self.Avoid[self.Target] = now + 20 end
					self.State, self.Target, self.Route, self.Goal = "wander", nil, nil, nil
					self.MoveTo = self:WanderSpot(300); self.NextLook = now + 1
					R.Stat("left the crowd") R.Dbg(self, "drops its goal: left the crowd")
				end
			end
		end
		-- on a wall or a ceiling and getting no closer to a goal below it (a thin rim or an overhang at an edge can hold it
		-- in a loop, moving a little all the time): it lets go and drops, as a spider does - when the floor is not too far
		local u0 = self.RepUp or Vector(0, 0, 1)
		-- (not while the one mover owns it, sv_mover.lua - it has its own way out; this let go of all three bugs at the strict
		-- roof's overhang while the mover was taking them round its edge)
		if (self.MoveTo and self.RepClimb and u0.z < 0.5 and not self.SurfPath and not self.Falling and not self.InTower and not self.InBridge and not self.Boarded
			and not (R.Mover and R.Mover.Owns(self))) then
			local gd = self.MoveTo:DistToSqr(pos)
			if (not self.BestGoalD or gd < self.BestGoalD * 0.9) then self.BestGoalD, self.BestGoalT = gd, now   -- (real progress, 5 % closer - not a jiggle)
			elseif (now - self.BestGoalT > 2 and self.MoveTo.z < pos.z - 60 and now > (self.NextStuckLook or 0)) then
				self.NextStuckLook = now + 0.5
				-- stuck on a wall or ceiling, the goal below: what now? Not a fixed rule - the ways out are weighed and the
				-- learned brain counts too (sv_brain.lua: each choice is judged later by what came of it - getting on, falling
				-- apart, stuck again), so the swarm learns which way out pays off where
				local fl = util.TraceLine({ start = pos, endpos = pos - Vector(0, 0, 360), mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self })   -- (a safe fall: under its breaking speed)
				local deep = (not fl.Hit) and util.TraceLine({ start = pos, endpos = pos - Vector(0, 0, 8000), mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self }) or nil
				local floorNear = fl.Hit and pos.z - fl.HitPos.z < 25
				local sit = "stuck/" .. (floorNear and "floor" or fl.Hit and "safe" or (deep and deep.Hit) and "high" or "void") .. "/" .. (R.cv.rebuild:GetBool() and "re" or "no")
				local long = math.min(3, (now - self.BestGoalT) / 6)   -- the longer it hangs there, the more a risk is worth
				local opts = {}
				if (fl.Hit and not floorNear) then opts[#opts + 1] = { "letgo", 1.2 } end
				if (deep and deep.Hit and R.cv.rebuild:GetBool()) then opts[#opts + 1] = { "jumpdown", 0.3 * long } end
				opts[#opts + 1] = { "back", 0.5 }
				opts[#opts + 1] = { "wait", 0.6 / (1 + long) }
				-- the goal lies behind the wall and a lip or cap is above it: round it and over (a field, not a local: this
				-- function is at the limit of what LuaJIT compiles)
				self.LipW = ((self.Goal or self.MoveTo) - pos):Dot(u0) < -20 and self:LipSpot(pos, u0) or nil
				if (self.LipW) then opts[#opts + 1] = { "lipjump", 1.5 } end
				-- what the swarm has learned makes it quicker: a way out that has paid off here before is taken after 2 s
				-- instead of 4 (the clearer the lesson, the sooner)
				local bw = 1
				for _, o in ipairs(opts) do if (o[1] ~= "wait") then bw = math.max(bw, R.Brain.Weight(sit, o[1])) end end
				if (now - self.BestGoalT >= 4 - 2 * math.Clamp((bw - 1) / 0.3, 0, 1)) then
					local pick, ps
					for _, o in ipairs(opts) do
						local v = o[2] * R.Brain.Weight(sit, o[1]) * math.Rand(0.8, 1.2)
						if (not ps or v > ps) then pick, ps = o[1], v end
					end
					if (pick ~= "wait") then self.BestGoalD = nil end
					if (pick ~= "wait") then R.Brain.Decided(self, sit, pick) end
					R.Dbg(self, "stuck on the wall:", pick, sit)
					if (pick == "lipjump" and self.LipW and self:LipJump(self.LipW)) then
						R.Stat("jumped past a lip")
						return true
					elseif (pick == "letgo" or pick == "jumpdown") then
						R.Stat(pick == "letgo" and "let go" or "jumped down anyway")
						self:StartFall(Vector(0, 0, 0))
						return true
					elseif (pick == "back") then
						R.Stat("turned back") R.Dbg(self, "drops its goal: turned back at a lip")
						self.State, self.Target, self.Route, self.Goal = "wander", nil, nil, nil
						self.MoveTo = self:WanderSpot(300); self.NextLook = now + 2
					else
						self.BestGoalT = now - 2   -- a little longer, then it weighs again
					end
				end
			end
		else
			self.BestGoalD = nil
		end
		-- not getting any closer, the goal level or above it (a dip with a rim, a lip it cannot get round - it moves a
		-- little all the time, so it is not "stuck" below): a hop up over it towards the goal, turning back or waiting a
		-- little; which pays off where, the swarm learns, and the clearer the lesson, the sooner it acts (3 s instead of 6)
		local goal = self.Goal or self.MoveTo
		-- (not while it waits at a gap for a bridge of bodies, or at one to cross it: that wait is the way on)
		local atBridge = self.Crossing or self.BridgeJob or (self.GapUntil and now < self.GapUntil + 4)
		if (not atBridge) then
			for _, T in pairs(R.Hive(self.RepOwner).bridges or {}) do if (T.a and T.a:DistToSqr(pos) < 260 * 260) then atBridge = true break end end
		end
		if (goal and not atBridge and not self.SurfPath and not self.Falling and not self.InTower and not self.InBridge and not self.Boarded and not self.Clinging and self.State ~= "ambush" and not self.Eating and goal.z > pos.z - 60 and goal:DistToSqr(pos) > 90 * 90) then
			local gd = goal:DistToSqr(pos)
			if (not self.ProgD or gd < self.ProgD * 0.9 or not self.ProgGoal or self.ProgGoal:DistToSqr(goal) > 100 * 100) then
				self.ProgD, self.ProgT, self.ProgGoal, self.ProgPos = gd, now, goal, pos
			elseif (pos:DistToSqr(self.ProgPos) > 120 * 120) then
				self.ProgT, self.ProgPos = now, pos   -- going round something (a detour), not stuck
			elseif (now - self.ProgT > 3 and now > (self.NextStuckLook or 0)) then
				self.NextStuckLook = now + 0.5
				local to = goal - pos
				local flat = Vector(to.x, to.y, 0)
				local fwd = flat:GetNormalized()
				local up = self.RepUp or Vector(0, 0, 1)
				local base = pos + up * 10
				-- a wall or rim in the way towards the goal, and free air above it to hop over
				local wall = util.TraceLine({ start = base, endpos = base + fwd * 60, mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self })
				local over = pos + Vector(0, 0, 110)
				local clear = not util.TraceLine({ start = pos + Vector(0, 0, 12), endpos = over, mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self }).Hit
					and not util.TraceLine({ start = over, endpos = over + fwd * 90, mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self }).Hit
				local land = clear and util.TraceLine({ start = over + fwd * 90, endpos = over + fwd * 90 - Vector(0, 0, 200), mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self })
				-- (a hop only helps over a rim in the way or up onto something: with nothing in the way and the goal far above it
				-- hopped on the spot 29 times at the bottom of a gap)
				local canHop = land and land.Hit and not land.StartSolid and land.HitPos.z > pos.z - 20 and (wall.Hit or land.HitPos.z > pos.z + 20 or to.z < 100)
				-- the goal far above and nothing to climb here: to the nearest wall or pillar - up that, then on (a spider)
				local climbTo
				if (to.z > 100 and not wall.Hit and up.z > 0.7) then
					local bd
					for a = 0, 337.5, 22.5 do
						local d = Angle(0, a, 0):Forward()
						local t = util.TraceLine({ start = base, endpos = base + d * 600, mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self })
						if (t.Hit and not t.StartSolid and math.abs(t.HitNormal.z) < 0.5) then
							local dd = t.Fraction * 600 - 0.3 * d:Dot(fwd) * 100   -- (towards the goal counts a little nearer)
							if (not bd or dd < bd) then bd, climbTo = dd, t end
						end
					end
				end
				-- or a wall / pillar towards the goal it can jump onto (and climb on from there)
				local wt = util.TraceLine({ start = base + Vector(0, 0, 20), endpos = base + Vector(0, 0, 20) + fwd * 400, mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self })
				local canWall = wt.Hit and not wt.StartSolid and math.abs(wt.HitNormal.z) < 0.5 and wt.Fraction * 400 > 70
				-- on a wall under a lip (the wall above sticks out), the goal above: out from the wall, up past the lip,
				-- and onto the wall face above it
				-- (the way goes up, or over: the goal lies behind the wall it is on)
				local lip = (up.z < 0.5 and (goal.z > pos.z + 20 or (goal - pos):Dot(up) < -20)) and self:LipSpot(pos, up) or nil
				local sit = "stuckup/" .. ((wall.Hit or up.z < 0.5) and "rim" or "open") .. "/" .. (canHop and "hop" or "nohop")
				local long = math.min(3, (now - self.ProgT) / 6)
				local opts = {}
				if (canHop) then opts[#opts + 1] = { "hop", 1.1 * R.JumpTrust(R.JumpKind(pos, land.HitPos)) } end
				if (canWall) then opts[#opts + 1] = { "wallhop", 0.8 * R.JumpTrust(R.JumpKind(pos, wt.HitPos, true)) } end
				if (lip) then opts[#opts + 1] = { "lipjump", 1.3 * R.JumpTrust(R.JumpKind(pos, lip.HitPos, true)) } end
				if (climbTo) then opts[#opts + 1] = { "climb", 1.4 } end
				opts[#opts + 1] = { "back", 0.45 + 0.1 * long }
				opts[#opts + 1] = { "wait", 0.6 / (1 + long) }
				local bw = 1
				for _, o in ipairs(opts) do if (o[1] ~= "wait") then bw = math.max(bw, R.Brain.Weight(sit, o[1])) end end
				if (now - self.ProgT >= 6 - 3 * math.Clamp((bw - 1) / 0.3, 0, 1)) then
					local pick, ps
					for _, o in ipairs(opts) do
						local v = o[2] * R.Brain.Weight(sit, o[1]) * math.Rand(0.8, 1.2)
						if (not ps or v > ps) then pick, ps = o[1], v end
					end
					R.Dbg(self, "no closer:", pick, sit)
					if (pick ~= "wait") then self.ProgD = nil; R.Brain.Decided(self, sit, pick) end
					if (pick == "hop") then
						R.Stat("hopped over")
						if (self:HopTo(land.HitPos + Vector(0, 0, 4))) then return true end
					elseif (pick == "lipjump") then
						R.Stat("jumped past a lip")
						if (self:LipJump(lip)) then return true end
					elseif (pick == "wallhop") then
						R.Stat("jumped onto a wall")
						if (self:WallJump(wt.HitPos, wt.HitNormal)) then return true end
					elseif (pick == "climb") then
						-- up the wall to the goal's height (or the wall's top), then on to the goal as before
						R.Stat("went to a wall to climb up")
						local top = util.TraceLine({ start = climbTo.HitPos + climbTo.HitNormal * 6, endpos = climbTo.HitPos + climbTo.HitNormal * 6 + Vector(0, 0, to.z), mask = MASK_PLAYERSOLID_BRUSHONLY, filter = self })
						self.DetourBack = { move = self.MoveTo, goal = self.Goal }
						self.MoveTo = top.HitPos - climbTo.HitNormal * 5 - Vector(0, 0, top.Hit and 16 or 0)
						self.DetourTo, self.DetourUntil = self.MoveTo, now + 25
						self.NextLook = math.max(self.NextLook or 0, now + 20)
						self.Route = nil
						R.Dbg(self, "goes to a wall to climb up", math.Round(climbTo.Fraction * 600), "away")
						return true
					elseif (pick == "back") then
						R.Stat("turned back")
						-- (back a little and on to the same goal by a fresh way across the map; dropping it, the bug sent over
						-- a wall with a cap wandered off - the cap test. Twice in 30 s: then it lets the goal go)
						local g = self.Goal
						if (now - (self.BackT or 0) > 30) then self.BackN = 0 end
						self.BackN, self.BackT = (self.BackN or 0) + 1, now
						if (g and R.Nav and R.cv.nav:GetBool() and self.BackN <= 2) then
							R.Dbg(self, "turned back, on to the same goal by another way", self.BackN)
							self.DetourBack = { move = g, goal = g, nav = true }
							self.MoveTo = self:WanderSpot(220)
							self.DetourTo, self.DetourUntil, self.Route = self.MoveTo, now + 3, nil
							self.NextLook = math.max(self.NextLook or 0, now + 4)
						else
							R.Dbg(self, "drops its goal: turned back (stuck weighing)")
							self.Route, self.Goal = nil, nil
							self.MoveTo = self:WanderSpot(300); self.NextLook = now + 2
						end
					else
						self.ProgT = now - 1.5
					end
				end
			end
		else
			self.ProgD = nil
		end
		-- (the step aside is over: back to the goal it had - unless something else has given it a new one meanwhile)
		if (self.DetourUntil and (now > self.DetourUntil or (self.DetourTo and pos:DistToSqr(self.DetourTo) < 40 * 40))) then
			local back = self.DetourBack
			if (back and self.MoveTo == self.DetourTo) then
				if (back.nav and back.goal) then self.DetourUntil, self.DetourTo, self.DetourBack = nil, nil, nil self:GoTo(back.goal, self.SpeedMul) return true end
				self.MoveTo, self.Goal, self.Route = back.move, back.goal, nil
			end
			self.DetourUntil, self.DetourTo, self.DetourBack = nil, nil, nil
		end
		-- stuck: somewhere else for a while (and remember: this way is no good)
		if (self.MoveTo and pos:DistToSqr(self.LastPos) > 10 * 10) then self.LastPos, self.LastMoveT = pos, now end
		-- waiting at a roof edge for a bridge is not being stuck (it lost its goal there and the bridge stayed unused)
		if (self.GapUntil and now < self.GapUntil + 1) then self.LastMoveT = now end
		if (self.State == "ambush" and self.AmbushAt and self.AmbushAt:DistToSqr(pos) < 60 * 60) then self.LastMoveT = now end   -- (waiting is not being stuck)
		if (self.MoveTo and (self.RepBlocked or now - self.LastMoveT > 3)) then
			self.RepBlocked = nil
			self.LastPos, self.LastMoveT = pos, now
			-- in ambush and close to its spot (a wall does not always let it reach the exact point): it waits right here
			if (self.State == "ambush" and self.AmbushAt and self.AmbushAt:DistToSqr(pos) < 140 * 140) then
				self.AmbushAt = pos; self.MoveTo, self.Route, self.Goal = pos, nil, pos   -- (held there, not let go)
				return true
			end
			-- in ambush but still far from its spot (it stood at the foot of the wall for 3 s, the stuck check made it a
			-- wanderer and the door was forgotten): it tries again from another side, three times, before it gives up
			if (self.State == "ambush" and self.AmbushAt) then
				self.AmbushTries = (self.AmbushTries or 0) + 1
				if (self.AmbushTries <= 3) then
					R.Dbg(self, "ambush spot not reached, tries again", self.AmbushTries, "at", math.Round(self.AmbushAt:Distance(pos)))
					self.RepSide = (self.RepSide or 0) + 90
					self.Route = nil
					-- (over a door the wall does not run down to the floor - the opening is under the spot: up the wall
					-- beside the door, at the spot's height, and across to it - the way a spider goes)
					-- (the 3D way finds that itself - sv_surfgraph.lua: first it gets its turn)
					local d3 = R.SurfNav and R.SurfNav.Graph and R.cv.surf3d:GetBool() and self.AmbushTries < 2
					local side = not d3 and self:WallBeside(self.AmbushAt, self.AmbushTries)
					if (side) then
						self.DetourBack = { move = self.AmbushAt, goal = self.AmbushAt }
						self.MoveTo, self.Goal = side, side
						self.DetourTo, self.DetourUntil = side, now + 20
						R.Dbg(self, "up the wall beside it", tostring(side))
					else
						self:GoTo(self.AmbushAt, 1.0)
					end
					return true
				end
				R.Dbg(self, "gives up the ambush spot")
			end
			-- on a wall, the way goes up, and it stands under a lip: it jumps past it onto the wall above
			local u1 = self.RepUp or Vector(0, 0, 1)
			local g1 = self.Goal or self.MoveTo
			if (u1.z < 0.5 and g1 and not self.SurfPath and (g1.z > pos.z + 20 or (g1 - pos):Dot(u1) < -20) and self.RepClimb) then
				local lip = self:LipSpot(pos, u1)
				if (lip and self:LipJump(lip)) then
					R.Stat("jumped past a lip")
					R.Dbg(self, "jumps past the lip above it")
					return true
				end
			end
			R.Map.Mark(pos, "v", 5)   -- counts as "been here a lot": the feelers steer elsewhere next time
			R.Stat("stuck")
			R.Reward(self, -1)
			R.Stat("stuck_" .. tostring(self.State))
			-- the same goal again and again: give it up for a minute (it learned: not reachable from here)
			if (IsValid(self.Target)) then
				self.StuckOn = self.StuckOn or {}
				local n = (self.StuckOn[self.Target] or 0) + 1
				self.StuckOn[self.Target] = n
				if (n >= 3) then
					self.Avoid = self.Avoid or {}
					self.Avoid[self.Target] = now + 60
					self.StuckOn[self.Target] = 0
					R.Dbg(self, "gives up", self.Target:GetClass())
				end
			end
			R.Dbg(self, "stuck", "state", tostring(self.State), "up", tostring(self.RepUp), "z", math.Round(pos.z), "goal", self.Goal and math.Round(self.Goal:Distance(pos)) or "-")
			self.Route = nil
			self.RepSide = self.RepSide + 90   -- try another side next time
			-- (as a safety net, yes, but it took away what the bug was doing: every bug stuck once became a wanderer and
			-- forgot its goal - the door, the roof across. Now it steps aside for 3 s and goes on to the same goal from
			-- there; only the third time for the same goal within a minute does it give that goal up)
			--
			local g0 = self.Goal or self.MoveTo
			local gk = g0 and (math.floor(g0.x / 64) .. ":" .. math.floor(g0.y / 64) .. ":" .. math.floor(g0.z / 64)) or "-"
			if (self.StuckGoalK ~= gk or now - (self.StuckGoalT or 0) > 60) then self.StuckGoalK, self.StuckGoalN = gk, 0 end
			self.StuckGoalN, self.StuckGoalT = self.StuckGoalN + 1, now
			if (g0 and self.StuckGoalN < 3) then
				-- (back by a fresh way across the map when it was on one: back to the old waypoint without it, it went
				-- straight at the roof spot from inside the building, into the ceiling)
				local nav = self.Goal and self.RepClimb and R.Nav and not (R.TestOff and R.TestOff.detourNav) and R.Nav.Wanted(pos, self.Goal) or nil
				self.DetourBack = { move = self.MoveTo, goal = self.Goal, nav = nav }
				self.MoveTo = self:WanderSpot(220)
				self.DetourTo, self.DetourUntil = self.MoveTo, now + 3
				self.NextLook = math.max(self.NextLook or 0, now + 4)
				R.Dbg(self, "steps aside, then on to the same goal", self.StuckGoalN)
				return true
			end
			if (g0) then R.Stat("goals given up (stuck)") R.Dbg(self, "drops its goal: stuck 3 times") end
			if (self.State ~= "attack" and self.State ~= "merge") then self.State, self.Target = "wander", nil end
			self.MoveTo = self:WanderSpot(350); self.WanderUntil = now + 3; self.NextLook = now + 2
		end
		return true
	end

	-- a point on the same wall as spot, at its height, beside it where the wall runs down unbroken to the floor (n: which
	-- try - the other side, further out)
	function ENT:WallBeside(spot, n)
		local nrm
		for a = 0, 337.5, 22.5 do
			local d = Angle(0, a, 0):Forward()
			local t = util.TraceLine({ start = spot, endpos = spot + d * 16, mask = MASK_PLAYERSOLID_BRUSHONLY })
			if (t.Hit and not t.StartSolid and math.abs(t.HitNormal.z) < 0.3) then nrm = t.HitNormal break end
		end
		if (not nrm) then return end
		local along = nrm:Cross(Vector(0, 0, 1))
		local sides = (n % 2 == 1) and { 1, -1 } or { -1, 1 }
		for _, off in ipairs({ 70, 110, 150, 200 }) do
			for _, sd in ipairs(sides) do
				local p = spot + along * sd * off
				local fl = util.TraceLine({ start = p, endpos = p - Vector(0, 0, 400), mask = MASK_PLAYERSOLID_BRUSHONLY })
				if (fl.Hit and not fl.StartSolid) then
					local ok = true
					for f = 0.1, 0.95, 0.2 do   -- (wall all the way down: at five heights the face is right behind the point)
						local q = LerpVector(f, fl.HitPos + Vector(0, 0, 8), p)
						local w = util.TraceLine({ start = q, endpos = q - nrm * 14, mask = MASK_PLAYERSOLID_BRUSHONLY })
						if (not w.Hit or w.StartSolid) then ok = false break end
					end
					-- (and the way across to the spot along the wall free)
					if (ok and not util.TraceLine({ start = p, endpos = spot, mask = MASK_PLAYERSOLID_BRUSHONLY }).Hit) then return p end
				end
			end
		end
	end

	-- a player who is no enemy (yet) comes close: a Replicator chirps at him - one of them every few seconds, not the
	-- whole swarm at once. (Closer still to the Queen he is a threat: threatens().)
	--
	local warned = setmetatable({}, { __mode = "k" })   -- [player] = when the next chirp at him may come
	function ENT:WarnOff(now, pos)
		if (now < (self.NextWarn or 0)) then return end
		self.NextWarn = now + math.Rand(0.8, 1.4)
		if (self.State == "attack" or self.RepSilent or self.RepDead) then return end
		for _, p in ipairs(player.GetAll()) do
			if (now >= (warned[p] or 0) and p:Alive() and p:GetMoveType() ~= MOVETYPE_NOCLIP and p:GetPos():DistToSqr(pos) < 200 * 200 and not R.MayAttack(self, p)) then
				warned[p] = now + math.Rand(6, 10)
				self.NextWarn = now + math.Rand(10, 16)
				self:RepSound("agp_replicator/rep_chatter2.wav", 70, 100, 0.8)
				R.Stat("chirped at a player close by")
				break
			end
		end
	end

	-- waiting (in the queue at a tower, at the edge for a bridge): it watches its prey like a big cat before the leap -
	-- turned to him, crouched, now and then a low click. When he looks straight at it, it goes still and silent.
	function ENT:WatchPrey(now, pos)
		local t = self.Target
		if (not (IsValid(t) and (t:IsPlayer() or t:IsNPC()))) then
			t = R.Enemy(self.RepOwner)
			if (not (IsValid(t) and t:GetPos():DistToSqr(pos) < 2500 * 2500)) then t = nil end
		end
		self.Watch = t
		if (not t or now < (self.NextGrowl or 0)) then return end
		self.NextGrowl = now + math.Rand(2.5, 5)
		local seen = t:IsPlayer() and t:GetAimVector():Dot((pos - t:EyePos()):GetNormalized()) > 0.95
		if (not seen) then self:RepSound("agp_replicator/rep_chatter2.wav", 55, math.random(65, 80), 0.25) end
	end

	function ENT:Brain(now, pos)
		self.Watch = nil
		if (self.PauseUntil and now < self.PauseUntil) then self.MoveTo = nil return end
		-- waiting in the queue at the foot of a tower: nothing to do until it moves on (hit: it wakes at once)
		local w = self.TowerWait
		if (w) then
			if (now < w.till and (w.T.ver or 0) == w.ver and IsValid(w.T.aim) and self.Target == w.tg and now - (self.HurtT or -9) > 3) then
				self.MoveTo = nil
				self:WatchPrey(now, pos)
				return
			end
			self.TowerWait = nil
		end
		local t = self.Target
		if (self.State == "attack") then
			if (not R.MayAttack(self, t)) then self.State = "wander" return end
			local tp = t:GetPos()
			local dist = tp:Distance(pos)
			-- gathering: wait out of reach until 3 hunters are there (or 8 s), then all at once
			if (self.GatherT and now < self.GatherT and R.Hunters(t) < 3) then
				self:GoTo(tp + (pos - tp):GetNormalized() * 420, 0.8)
				return
			end
			self.GatherT = nil
			self.SpeedMul = 1.25
			-- out of reach (in the air, on something it cannot walk to): up a building nearby and jump from there
			if (self:ShieldInWay(t, pos)) then return end   -- a shield around it: that first
			if (self:Reach(craftOf(t) or t, now, pos)) then return end
			-- learned: an armed player shoots what is in front of him - come from the side he is not looking at
			if (t:IsPlayer() and dist > 260 and dist < 1400 and (R.Hive(self.RepOwner).shot or 0) >= 2) then
				local aim = t:GetAimVector(); aim.z = 0; aim:Normalize()
				local to = pos - tp; to.z = 0
				local tl = to:Length()
				if (tl > 1 and aim:Dot(to / tl) > 0.55) then   -- right in his sights
					local side = aim:Cross(Vector(0, 0, 1)) * ((self.RepSide % 360) < 180 and 1 or -1)
					self.MoveTo = tp + side * 380 - aim * 120
					self.Route = nil
					return
				end
			end
			-- or from above: next to a wall, some climb it and drop on him
			if (self.RepClimb and dist < 900 and (self.Mind and self.Mind.curious or 1) > 1.05) then
				if (not self.AboveT or now > self.AboveT) then
					self.AboveT = now + 5
					local w = self:LaunchSpot(tp, true)
					self.Above = (w and Vector(w.x, w.y, w.z):Distance(Vector(tp.x, tp.y, w.z)) < 220) and (w + Vector(0, 0, 130)) or nil
				end
				if (self.Above and pos.z < tp.z + 60) then self.MoveTo = self.Above; self.Route = nil return end
			end
			if (t:IsPlayer() and (self:FollowWayIn(t, pos, now) or self:FollowTrail(t, pos, now))) then return end   -- out of sight (indoors): the way in, else the way he went
			-- with others on the same target: come from its own side (a ring around it), straight in when close
			local ring = R.Hunters(t) > 1 and dist > 140
			if (ring) then
				local a = math.rad(self.RepSide)
				self.MoveTo = tp + Vector(math.cos(a), math.sin(a), 0) * 110
			else
				self.MoveTo = tp
			end
			self.Route = nil
			-- on a wall or ceiling above its prey: let go and drop on it
			local up = self.RepUp or Vector(0, 0, 1)
			local flat = Vector(tp.x - pos.x, tp.y - pos.y, 0):Length()
			if (up.z < 0.7 and pos.z > tp.z + 60 and flat < 160) then
				self:StartFall(Vector(tp.x - pos.x, tp.y - pos.y, 0) * 1.2, true)
				return
			end
			if (self.RepLeap and not ring and up.z > 0.7 and dist > 70 and dist < 170 and now > (self.NextLeap or 0)) then self:Leap(t) return end
			if (t:WorldSpaceCenter():Distance(self:WorldSpaceCenter()) < self.RepReach + t:BoundingRadius() * 0.5) then self:Bite(t) end
		elseif (self.State == "ambush") then
			if (self.AmbushAt and self.AmbushAt:DistToSqr(pos) < 60 * 60) then
				-- there: hold still - its goal stays the spot (with no goal its climbing plan ended, nothing held it on the
				-- wall over the door and it slid down to the floor before anyone came)
				self.MoveTo, self.Route, self.Goal = self.AmbushAt, nil, self.AmbushAt
				self.RepSilent = true
			elseif (self.AmbushAt and not self.Route) then
				self.MoveTo = self.AmbushAt
			end
		elseif (self.State == "flee" or self.State == "scout" or self.State == "regroup" or self.State == "hide" or self.State == "guard") then
			if (not self.MoveTo and not self.Route and not self.NavWait and self.State ~= "hide") then self.NextLook = 0 end
			if (self.Goal and self.Goal:DistToSqr(pos) < 60 * 60 and (not R.Reached or R.Reached(self, pos, self.Goal))) then self.Goal = nil; self.MoveTo = nil; self.NextLook = math.min(self.NextLook or 0, now + 0.3) end
		elseif (self.State == "eat") then
			if (not IsValid(t) and not self.Eating) then self.State = "wander" return end   -- (a loaded save brings the state back, not the food: script error in ShieldInWay)
			if (not R.Edible(t) and self.Eating ~= t) then self.State = "wander" return end
			if (self.Eating) then return end
			-- food in the air (a ship hovering) or behind a shield: climb and jump / drain the shield
			if (self:ShieldInWay(t, pos)) then return end
			if (self:Reach(t, now, pos)) then return end
			local at = t:GetPos()
			if (self.BoardTry and R.IsShip(t)) then   -- onto the hull: close in, then jump on top of it
				local flat = Vector(t:GetPos().x - pos.x, t:GetPos().y - pos.y, 0):Length()
				if (flat < t:BoundingRadius() + 220 and now > (self.NextLeap or 0)) then self:Pounce(t) return end
				if (not self.Goal or self.Goal:DistToSqr(t:GetPos()) > 300 * 300) then self:GoTo(t:GetPos(), 1.0) end
				if (not self.Route) then self.MoveTo = t:GetPos() end
				return
			end
			if (R.IsBig(t) and not R.IsShip(t) or (R.IsShip(t) and t:NearestPoint(pos).z - pos.z < 45)) then
				-- its own place round the hull (spread by the swarm's count, not all at the same spot)
				local h = R.Hive(self.RepOwner)
				h.bites = h.bites or setmetatable({}, { __mode = "k" })
				local s = h.bites[t] or {}
				h.bites[t] = s
				for b in pairs(s) do if (not IsValid(b) or b.Target ~= t or b.RepGone) then s[b] = nil end end
				if (not s[self]) then
					local used = {}
					for _, i in pairs(s) do used[i] = true end
					for i = 1, R.BiteSlots(t) do if (not used[i]) then s[self] = i break end end
				end
				if (not s[self]) then   -- every place is taken: no pushing, something else (it knows before it gets there)
					self.Avoid = self.Avoid or {}
					self.Avoid[t] = now + 20
					self.State, self.Target, self.NextLook = "wander", nil, 0
					R.Stat("full, went elsewhere")
					return
				end
				local n = R.BiteSlots(t)
				local dir = Angle(0, t:GetAngles().y + s[self] * 360 / n, 0):Forward()
				-- its place: at the thing's foot, on the ground beside it ("the replicators on the gate eating it are
				-- moving weirdly": sent half way up a gate, they climbed its narrow ring and hung, tipped and flipped
				-- there - 1319 stops at its "edges" in one test) (its foot:
				-- the ground under its middle - a gate's bounding box reaches under the floor - or the box's bottom
				-- when that is higher: a ship over the ground; looked up every 5 s)
				local c0 = t:WorldSpaceCenter()
				if (not t.AGPRepFootT or now > t.AGPRepFootT) then
					local tr = util.TraceLine({ start = c0, endpos = c0 - Vector(0, 0, 4000), mask = MASK_PLAYERSOLID, filter = function(e) return e ~= t and not e.AGPReplicator and not e:IsPlayer() end })
					t.AGPRepFootZ = math.max(t:NearestPoint(c0 - Vector(0, 0, 10000)).z, tr.Hit and tr.HitPos.z or -1e9)
					t.AGPRepFootT = now + 5
				end
				local probe = c0 + dir * t:BoundingRadius() * 2
				probe.z = t.AGPRepFootZ + 12
				at = t:NearestPoint(probe)
				at = self:OnGround(at + dir * 8) or at
			end
			if (not self.Goal or self.Goal:DistToSqr(at) > 200 * 200) then self:GoTo(at, 0.9) end
			if (not self.Route) then self.MoveTo = at end
			local c = self:WorldSpaceCenter()
			local gap = t:NearestPoint(c):Distance(c)
			if (gap < self.RepReach + self:BoundingRadius() * 0.4 or (gap < self.RepReach + 60 and CurTime() - self.LastMoveT > 1) or (gap < self.RepReach + 100 and t.AGPShip and CurTime() - self.LastMoveT > 2)) then self:Eat(t)
			elseif (gap < 260 and CurTime() - self.LastMoveT > 1.5 and not self.Falling and now > (self.NextFoodHop or 0) and t:NearestPoint(c).z > c.z - 20) then
				-- it cannot get closer on foot (a crystal on its pedestal): a hop up next to it
				self.NextFoodHop = now + 3
				R.Stat("hopped up to food")
				self:HopTo(t:NearestPoint(c), t)
			end
		elseif (self.State == "drain") then
			if (not IsValid(t) or t:GetNWBool("depleted") or t.Enabled == false) then self.State, self.Target = "wander", nil return end
			local r = R.ShieldRadius(t)
			local at = t:GetPos() + (pos - t:GetPos()):GetNormalized() * r   -- the bubble's surface on its side
			if (at.z - pos.z > 120 and pos:Distance(t:GetPos()) > r + 100) then   -- the shield is up there (on a building): climb first
				if (not self.Goal or self.Goal:DistToSqr(t:GetPos()) > 300 * 300) then self:GoTo(t:GetPos(), 1.0) end
				return
			end
			self.MoveTo = at + (pos - at):GetNormalized() * 12
			self.Route = nil
			-- touching the bubble (it pushes them back a little): within reach of its surface
			if ((at:Distance(pos) < 60 or pos:Distance(t:GetPos()) < r + 100) and now > (self.NextDrain or 0)) then
				self.NextDrain = now + 0.5
				local ok, err = pcall(t.Hit, t, self, at, 40, (pos - at):GetNormalized())   -- the shield's own hit: it weakens and ripples
				R.Dbg(self, "drains", t:GetClass(), "ok", tostring(ok), tostring(err), "strength", tostring(t.Parent and t.Parent.Strength))
				self.RepStock = self.RepStock + 0.4
				R.Fed(self.RepOwner, 0.05)
				R.Reward(self, 0.1)
				local fx = EffectData(); fx:SetOrigin(at); fx:SetNormal((pos - at):GetNormalized()); fx:SetMagnitude(2); fx:SetScale(1); fx:SetRadius(3)
				util.Effect("ElectricSpark", fx, true, true)
				if (math.random() < 0.3) then self:RepSound("agp_replicator/rep_chatter2.wav", 60, math.random(140, 160), 0.4) end
			end
		elseif (self.State == "deliver") then
			if (not IsValid(t)) then self.State = "wander" return end
			local at = t.RepBroodPos and t:RepBroodPos() or t:GetPos()
			if (not self.Goal or self.Goal:DistToSqr(at) > 200 * 200) then self:GoTo(at, 1) end
			if (not self.Route) then self.MoveTo = at end
			if (at:Distance(pos) < 70 or t:NearestPoint(pos):Distance(pos) < 50) then   -- at the brood chamber, or touching her
				if (t.AddStock) then t:AddStock(self.RepStock) end
				R.Reward(self, 0.3)
				self.RepStock = 0
				self.State, self.Target = "wander", nil
			end
		elseif (self.State == "merge") then
			-- walking to the place where the swarm builds a new Queen (agp_replicators.lua)
			if (not self.MoveTo) then self.State = "wander" end
		else
			if (self.MoveTo and self.MoveTo:DistToSqr(pos) < 25 * 25 and (not R.Reached or R.Reached(self, pos, self.MoveTo))) then self.MoveTo = nil; self.NextLook = math.min(self.NextLook or 0, now + math.Rand(0.3, 1.2)) end
		end
	end

	function ENT:OnTakeDamage(dmg)
		if (self.RepGone) then return end
		if (self.Clinging) then self:Release(true) end   -- shot off him
		if (self.BlastSafe and CurTime() < self.BlastSafe and dmg:IsExplosionDamage()) then return end   -- the ship it just ate up
		if (dmg:GetDamage() >= 50) then R.Dbg(self, "hit", math.Round(dmg:GetDamage()), "type", dmg:GetDamageType(), "by", tostring(dmg:GetAttacker()), tostring(dmg:GetInflictor())) end
		-- the vortex took it: the swarm learns how far it reaches (sv_pursuit.lua)
		if (IsValid(dmg:GetAttacker()) and dmg:GetAttacker():GetClass() == "kawoosh_hurt") then
			local g = R.VortexNear(self:GetPos())
			if (IsValid(g)) then R.LearnBlast(g, self:GetPos()) end
		end
		if (dmg:IsDamageType(DMG_DISSOLVE)) then self:AGPDisrupt() return end
		local att = dmg:GetAttacker()
		if (IsValid(att) and (att:IsPlayer() or att:IsNPC())) then
			self.HurtBy, self.HurtT = att, CurTime(); R.Threat(self.RepOwner, att)
			if (dmg:IsBulletDamage() or dmg:IsDamageType(DMG_BUCKSHOT)) then
				R.Map.Mark(att:GetPos(), "d", 0.5)   -- routes avoid where he shoots from
				local h = R.Hive(self.RepOwner); h.shot = (h.shot or 0) + 1
			end
		end
		if (R.MayAttack(self, att)) then self.State, self.Target = "attack", att; self.NextLook = CurTime() + 2; R.Shout(self, att) end
		local amount = dmg:GetDamage() * R.Resist(self.RepOwner, dmg:GetDamageType())   -- what the swarm has learned
		-- series: energy weapons (zat, staff, Goa'uld ship weapons) barely touch them; bullets and explosions work
		if (R.IsEnergy(dmg:GetDamageType())) then
			amount = amount * 0.15
			R.Learn(self.RepOwner, dmg:GetDamageType(), att, 0.2)   -- and every hit teaches them (in the end: sparks, no harm)
		end
		self.LastDmgType = dmg:GetDamageType()
		self:SetHealth(self:Health() - amount)
		local fx = EffectData(); fx:SetOrigin(dmg:GetDamagePosition()); fx:SetNormal(VectorRand()); fx:SetMagnitude(1); fx:SetScale(1); fx:SetRadius(2)
		util.Effect("MetalSpark", fx, true, true)
		if (self:Health() <= 0) then
			R.Learn(self.RepOwner, self.LastDmgType, att)
			self:FallApart()
		end
	end

	-- shot apart: the blocks fly off and build it again later (unless agp_rep_rebuild 0)
	function ENT:FallApart(dead)
		if (R.SurfNav and R.SurfNav.Fell) then R.SurfNav.Fell(self, dead) end   -- (a way it fell from: slow, the swarm learns)
		if (self.RepGone) then return end
		if (self.Clinging) then self:Release(false) end
		R.Reward(self, dead and -3 or -1.5)
		R.Brain.Settle(self)
		self.RepGone = true
		R.Dbg(self, "falls apart", dead and "dead" or "", "state", tostring(self.State), "z", math.Round(self:GetPos().z), "was going to", tostring(self.MoveTo), "bridge wait", tostring(self.BridgeGoal ~= nil), "job", tostring(self.BridgeJob ~= nil))
		R.Lost(self.RepOwner, self:GetPos())
		-- built again within 20 s, now and then within 15 (the swarm timer draws them together when the time is up)
		local by = CurTime() + (math.random() < 0.3 and math.Rand(13, 14) or math.Rand(15.5, 16.5))   -- (+ about 1 s to stand up: at most 18 s)
		local rest = (dead or not R.cv.rebuild:GetBool()) and 1e9 or (by - CurTime() - math.Rand(5, 7))
		local grp = {}
		local mind = self.Mind
		-- playing dead: most of the time the blocks lie still while a player near watches them, and only crawl together
		-- once he has turned away or walked on (but they are back on their legs in time all the same)
		local feign = not dead and R.cv.rebuild:GetBool() and math.random() < 0.6
		-- (the blocks are made a few at a time over the next ticks when many bugs fall apart at once - R.Burst)
		R.Burst(self, self.RepBlocks + math.min(self.RepStock, 12), self.RepOwner, rest, nil, function(b)
			b.RepMind = mind   -- the rebuilt bug keeps its character
			if (not dead) then b.RepGroup, b.RepRebuildBy = grp, by end
			if (feign) then b.RepFeign = by - 3 end
			if (dead) then b:AGPDisrupt() end
		end)
		self:Remove()
	end

	-- the anti-replicator gun / Dakara weapon: falls into dead blocks. The gun works on a frequency (sg_arg.lua): once the
	-- swarm has adapted to it, the bug only shudders and comes for the shooter. The Dakara wave always works.
	function ENT:AGPDisrupt(freq, shot, by)
		if (freq and R.ArgAdapted(self.RepOwner, freq)) then
			local now = CurTime()
			if (now < (self.ArgShrugT or 0)) then return end
			self.ArgShrugT = now + 0.6
			local fx = EffectData(); fx:SetOrigin(self:WorldSpaceCenter()); fx:SetMagnitude(3); fx:SetScale(1); fx:SetRadius(6)
			util.Effect("Sparks", fx, true, true)
			self:RepSound("agp_replicator/rep_chatter2.wav", 75, math.random(70, 85), 0.9)
			R.Stat("shrugged off the ARG")
			R.ArgResisted(by)
			if (IsValid(by)) then
				R.Threat(self.RepOwner, by)
				if (R.MayAttack(self, by)) then self.State, self.Target, self.NextLook = "attack", by, now + 2 end
			end
			return
		end
		if (freq) then R.ArgHit(self.RepOwner, freq, shot) end
		self:FallApart(true)
	end
end

if CLIENT then
	-- looping sounds (walking skitter by speed; the Queen's hum); only near the player
	-- the Replicators' walking sound is the series' sound of a GROUP walking (SG-1 5x01 37:22, centre channel).
	-- One loop per Replicator would stack a group on a group, so only the two walking ones nearest to the player play
	-- it: one alone quietly, the more walk near the player the louder. The ones the player does not see (behind him,
	-- behind a wall) are not drawn, so Draw cannot feed their sound: pickVoices measures how fast those move
	-- and feeds it (before this their loop simply held its last volume).
	--
	local GROUP_SND, VOICES = "agp_replicator/rep_walk_loop.wav", 2
	local walkers, voiceGain, nextPick, lastPick = {}, 0.55, 0, 0
	local nextTurnSnd = 0
	local loops
	local function pickVoices()
		local now = RealTime()
		if (now < nextPick) then return end
		local lp = LocalPlayer()
		if (not IsValid(lp)) then return end
		local dt = math.max(now - lastPick, 0.05)
		nextPick, lastPick = now + 0.15, now
		local eye, moving, unseen = lp:GetPos(), {}, {}
		for e, w in pairs(walkers) do
			if (not IsValid(e)) then
				walkers[e] = nil
			else
				local p = e:GetPos()
				if (now - (w.t or 0) > 0.3) then
					local spd = (e:IsDormant() or not w.p) and 0 or p:Distance(w.p) / dt
					w.w = Lerp(0.5, w.w or 0, math.Clamp(spd / 40, 0, 1))
					w.r = Lerp(0.5, w.r or 0, math.min(spd / e.RepSpeed, 1.3))
					unseen[#unseen + 1] = e
				end
				w.p, w.d = p, eye:DistToSqr(p)
				if (w.w > 0.1) then moving[#moving + 1] = e end
				e.ClVoice = nil
			end
		end
		table.sort(moving, function(x, y) return walkers[x].d < walkers[y].d end)
		for i = 1, math.min(VOICES, #moving) do moving[i].ClVoice = true end
		voiceGain = math.Clamp(0.55 + 0.09 * (#moving - 1), 0.55, 1)
		for _, e in ipairs(unseen) do loops(e, walkers[e].w, true, walkers[e].r) end
	end
	hook.Add("Think", "AGP.Rep.WalkVoices", pickVoices)

	function loops(ent, walk, unseen, rate)
		local near = LocalPlayer():GetPos():DistToSqr(ent:GetPos()) < 1500 * 1500
		ent.ClSnd = ent.ClSnd or {}
		local vol = walk > 0.1 and 0.45 * walk or 0
		if (ent.RepWalkSound == GROUP_SND) then
			local w = walkers[ent]
			if (not w) then w = {}; walkers[ent] = w end
			w.w = walk
			if (not unseen) then w.t = RealTime() end
			pickVoices()
			vol = ent.ClVoice and vol * voiceGain or 0
		end
		-- the loop runs as fast as the legs: its own tempo (100) at the full speed RepSpeed - the legs' cycle is speed /
		-- RepStride, so both follow the same number. Within what still sounds like the same creature (60 .. 125).
		--
		--
		local list = { { ent.RepWalkSound, vol, math.Clamp(100 * (rate or walk), 60, 125) } }
		if (ent.RepHumSound) then list[2] = { ent.RepHumSound, 0.5, 100 } end
		for i, d in ipairs(list) do
			local s = ent.ClSnd[i]
			if (near and d[2] > 0) then
				if (not s) then s = CreateSound(ent, d[1]); s:SetSoundLevel(i == 1 and (ent.RepWalkLevel or 62) or 70); ent.ClSnd[i] = s end
				if (not s:IsPlaying()) then s:PlayEx(0, d[3]) end
				s:ChangeVolume(d[2], 0.3); s:ChangePitch(d[3], 0.15)
			elseif (s and s:IsPlaying()) then
				s:ChangeVolume(0, 0.3)
				if (not near) then s:Stop() end
			end
		end
	end

	function ENT:OnRemove()
		for _, s in pairs(self.ClSnd or {}) do s:Stop() end
	end

	-- each foot on its own ground: the legs were one walking pose, the same on any ground - at a step down the front
	-- feet hung in the air, at a step up they went into it. Now each foot looks along the body's down for the ground
	-- under it and its leg turns (the same "lift" as walking) until the foot is on it: lower until contact, higher until
	-- free. Only near the player (1200), 10 times a second, smoothed.
	--
	local feetCv = CreateClientConVar("agp_rep_feet", "1", true, false, "Replicators: each foot finds its own ground (1) or the plain walking pose (0)")
	local FEET_MAX = 52   -- degrees a leg turns at most for its ground (40 lifted too little at a step)
	local function footAt(F, root, name, ang)
		local v = F.FOOT[name] - F.HIP[name]
		v:Rotate(ang)
		return root * (F.HIP[name] + v)   -- (the bone matrix carries the model's scale)
	end
	-- the lift that puts this foot "drop" units lower along up (negative: higher), within FEET_MAX: searched - how the
	-- leg's turn moves the foot depends on the leg and on the body's tilt
	local function liftFor(F, root, name, side, up, drop)
		local base = footAt(F, root, name, Angle(0, 0, 0)):Dot(up)
		local function lower(l) return base - footAt(F, root, name, Angle(l * side, 0, 0)):Dot(up) end
		local s = lower(FEET_MAX) > lower(-FEET_MAX) and 1 or -1   -- (the turn that lowers it: +lift or -lift)
		if drop < 0 then
			s, drop = -s, -drop
			lower = function(l) return footAt(F, root, name, Angle(l * side, 0, 0)):Dot(up) - base end
		end
		if lower(s * FEET_MAX) <= drop then return s * FEET_MAX end
		local lo, hi = 0, FEET_MAX
		for _ = 1, 8 do
			local m = (lo + hi) * 0.5
			if lower(s * m) < drop then lo = m else hi = m end
		end
		return s * (lo + hi) * 0.5
	end
	function ENT:ClFeet()
		local f = self.ClFeetT
		if (not f) then f = { t = 0, want = {}, cur = {} }; self.ClFeetT = f end
		local F = self.RepFeet
		local now = RealTime()
		local lp = LocalPlayer()
		local d2 = IsValid(lp) and lp:GetPos():DistToSqr(self:GetPos()) or 1e12
		local near = F and feetCv:GetBool() and d2 < 1200 * 1200 and not IsValid(self:GetParent())
		if (near and now > f.t) then
			-- (10 times a second within 500, 4 times further out - 60 bugs round the player cost 7 ms a frame)
			local close = d2 < 500 * 500
			f.t = now + (close and 0.1 or 0.25)
			local root = self:GetBoneMatrix(0)
			if (root) then
				local up = self:GetUp()
				local sc = self:GetModelScale() or 1
				-- each foot feels from higher up (30, a stair step), and while it walks also a little ahead of itself -
				-- the step before it reaches it lifts it, the higher ground of the two wins
				--
				local fwd = close and (self.ClSpd or 0) > 20 and self:GetForward() or nil   -- (ahead: only close by)
				local function filt(e) return e ~= self and not e.AGPReplicator end
				local function dropAt(foot, p)
					local tr = util.TraceLine({ start = p + up * 30 * sc, endpos = p - up * 22 * sc, mask = MASK_PLAYERSOLID, filter = filt })
					-- (started in something: a low overhang above - feel from just above the foot instead; solid there too:
					-- a tall step right at it)
					if (tr.StartSolid) then tr = util.TraceLine({ start = p + up * 12 * sc, endpos = p - up * 22 * sc, mask = MASK_PLAYERSOLID, filter = filt }) end
					if (tr.StartSolid) then return -30 * sc end
					if (tr.Hit) then return (foot - tr.HitPos):Dot(up) end
					return 22 * sc   -- (nothing: it reaches down as far as it goes, over an edge)
				end
				for _, name in ipairs(self.RepLegs) do
					if (F.HIP[name]) then
						local foot = footAt(F, root, name, Angle(0, 0, 0))
						local drop = dropAt(foot, foot)
						if (fwd) then drop = math.min(drop, dropAt(foot, foot + fwd * 12 * sc)) end
						-- (a foot within 1.5 of its ground stays as it was: no twitching on even ground)
						f.want[name] = math.abs(drop) < 1.5 and 0 or liftFor(F, root, name, name:find("_l") and 1 or -1, up, drop)
					end
				end
			end
		elseif (not near) then
			f.want = {}
		end
		local dt = math.max(FrameTime(), 0.001)
		for _, name in ipairs(self.RepLegs) do
			f.cur[name] = Lerp(math.min(1, dt * 10), f.cur[name] or 0, f.want[name] or 0)
		end
		return f.cur
	end

	-- legs: in pairs / threes while it walks (speed from how far it moved), a slow twitch while it stands, a fast
	-- flailing while it falls or lies on its back
	function ENT:Draw()
		if (not self.ClCC) then self.ClCC = true self:SetCustomCollisionCheck(true) end   -- (the same rule on the client)
		local dt = math.max(FrameTime(), 0.001)
		local pos = self:GetPos()
		-- speed over the last 0.3 s, not from one frame to the next: a body that jitters in place (pressed against
		-- something) moved a little every frame, and its legs ran on the spot
		local now = RealTime()
		self.ClHist = self.ClHist or {}
		local h = self.ClHist
		if (not h[#h] or now - h[#h].t > 0.05) then h[#h + 1] = { t = now, p = pos } end
		while (#h > 2 and now - h[2].t > 0.3) do table.remove(h, 1) end
		local v = (#h > 1 and now - h[1].t > 0.02) and pos:Distance(h[1].p) / (now - h[1].t) or 0
		-- (turning on the spot moves the legs too - the Queen turned like a tank on still legs): how fast it turns,
		-- times half its length, counts as walking
		local yaw = self:GetAngles().y
		local turn = math.abs(math.AngleDifference(yaw, self.ClYaw or yaw)) / dt
		self.ClYaw = yaw
		self.ClTurn = Lerp(math.min(1, dt * 8), self.ClTurn or 0, math.min(turn, 360))
		-- turning on the spot has its own sound (not while it is carried, clings to someone, falls or lies on its back; one
		-- Replicator at most every 5 - 8 s, the swarm at most one in 2 s)
		if (self.RepTurnSound and self.ClTurn > 140 and v < 20 and now > (self.ClTurnSnd or 0) and now > nextTurnSnd and not IsValid(self:GetParent())
			and not self:GetNWBool("RepFall") and not self:GetNWBool("RepFlail")) then
			self.ClTurnSnd = now + math.Rand(5, 8); nextTurnSnd = now + 2
			self:EmitSound(self.RepTurnSound, 62, math.random(97, 103), 0.55)
		end
		v = math.max(v, math.rad(self.ClTurn) * (self:OBBMaxs().x - self:OBBMins().x) * 0.5)
		self.ClSpd = Lerp(math.min(1, dt * 6), self.ClSpd or 0, math.min(v, self.RepSpeed * 1.3))
		self.ClPhase = (self.ClPhase or 0) + dt * self.ClSpd / self.RepStride * math.pi
		local flail = self:GetNWBool("RepFall") or self:GetNWBool("RepFlail")
		local walk = flail and 0 or math.Clamp(self.ClSpd / 40, 0, 1)
		self.ClBones = self.ClBones or {}
		local t = CurTime()
		local dbg = AGP and AGP.Rep and AGP.Rep.DebugPose   -- test pictures: { lift, swing }
		local feet = (not flail) and self:ClFeet() or nil   -- (each foot on its own ground: ENT:ClFeet)
		for i, name in ipairs(self.RepLegs) do
			local b = self.ClBones[name]
			if (b == nil) then b = self:LookupBone(name) or false; self.ClBones[name] = b end
			if (b) then
				local ph = self.ClPhase + self.RepGait[name] * math.pi
				local side = name:find("_l") and 1 or -1
				local twitch = (1 - walk) * math.sin(t * 2.3 + i * 1.7) * 3
				local swing = math.sin(ph) * self.RepSwing * walk + twitch
				local lift = math.max(0, math.cos(ph)) * self.RepLift * walk
				if (feet and feet[name]) then lift = lift + feet[name] end
				if (flail) then swing = math.sin(t * 23 + i * 1.9) * 28; lift = 10 + math.sin(t * 29 + i * 2.7) * 22 end
				if (dbg) then swing, lift = dbg[2], dbg[1] end
				self:ManipulateBoneAngles(b, Angle(lift * side, swing, 0), false)
			end
		end
		loops(self, flail and 0.6 or walk, false, flail and 1 or self.ClSpd / self.RepSpeed)
		self:DrawModel()
	end
end
