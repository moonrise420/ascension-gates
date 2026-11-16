-- Replicators: jumping (owner 2026-11-04: "they know their power, they should be able to jump on their own").
-- A bug knows how hard it can jump (JUMP_MAX) and how hard a landing it survives (its RepFallBreak). Before a jump it
-- picks a spot it can land on near where it wants to be, works out the arc (gravity), checks that the arc is free and
-- the landing not too hard, and takes the gentlest arc that works. A spot on a wall or a pillar is fine too: it grabs
-- on there (agp_replicator.lua ENT:Grab) and climbs on.
-- What it learns, the swarm knows:
--  * how strong to jump: after every landing the swarm compares where it came down with where it aimed (too short:
--    a little harder next time, too far: softer) - a factor round 1
--  * which jumps pay off: landed where it wanted / missed / broke apart, by kind of jump (up / level / down, near /
--    far, onto a wall) in the learned brain ("jump" values); jumps that keep failing are taken less often
local R = AGP.Rep
local JUMP_MAX = 700
R.jumpCal = R.jumpCal or {}

local function key(owner) return IsValid(owner) and owner or game.GetWorld() end
function R.JumpCal(owner) return R.jumpCal[key(owner)] or 1 end

-- the kind of a jump (for what is learned about it)
function R.JumpKind(from, to, wall)
	local dz = to.z - from.z
	local flat = Vector(to.x - from.x, to.y - from.y, 0):Length()
	return (wall and "wall" or (dz > 40 and "up" or dz < -60 and "down" or "level")) .. "/" .. (flat > 250 and "far" or "near")
end

local function clearArc(from, v, T, g, filter, ignore, land)
	local prev = from
	local N = 10
	for i = 1, N do
		local t = T * i / N
		local p = from + Vector(v.x * t, v.y * t, v.z * t - 0.5 * g * t * t)
		local tr = util.TraceHull({ start = prev, endpos = p, mins = Vector(-5, -5, -5), maxs = Vector(5, 5, 5), mask = MASK_PLAYERSOLID, filter = filter })
		-- (the last stretch meets the landing surface: that is no obstacle)
		if tr.Hit and not (ignore and tr.Entity == ignore) and tr.HitPos:DistToSqr(land) > 45 * 45 and i < N then return false end
		prev = p
	end
	return true
end

-- the arc onto 'land' (a point on a surface): velocity, or nil when it cannot (too far for its power, the arc runs into
-- something, or it would land too hard)
function R.JumpTo(bug, land, ignore)
	local from = bug:GetPos() + (bug.RepUp or Vector(0, 0, 1)) * 8
	local g = physenv.GetGravity():Length()
	local cal = R.JumpCal(bug.RepOwner)
	local filter = function(e) return e ~= bug and not e.AGPReplicator end
	local best, bt
	for _, T in ipairs({ 0.4, 0.55, 0.7, 0.9, 1.15 }) do
		local d = land - from
		local v = Vector(d.x / T, d.y / T, d.z / T + 0.5 * g * T)
		local vEnd = Vector(v.x, v.y, v.z - g * T)
		if v:Length() * cal <= JUMP_MAX and vEnd:Length() < (bug.RepFallBreak or 750) * 0.9 and (not best or v:LengthSqr() < best:LengthSqr()) then
			if clearArc(from, v, T, g, filter, ignore, land) then best, bt = v, T end
		end
	end
	if best then return best * cal, bt end
end

-- a surface to land on near a point (around it, a little above): the gentlest jump onto one of them
function R.PlanJump(bug, aim, ignore, radius)
	local spots = { aim }
	radius = radius or 40
	for _, r in ipairs({ radius * 0.5, radius }) do
		for a = 0, 315, 45 do spots[#spots + 1] = aim + Angle(0, a, 0):Forward() * r end
	end
	local best, bv, bt
	for _, p in ipairs(spots) do
		local tr = util.TraceLine({ start = p + Vector(0, 0, 40), endpos = p - Vector(0, 0, 90), mask = MASK_PLAYERSOLID, filter = function(e) return e ~= bug and not e.AGPReplicator and e ~= ignore end })
		if tr.Hit and not tr.StartSolid and tr.HitNormal.z > 0.6 then
			local land = tr.HitPos + Vector(0, 0, 4)
			local v, T = R.JumpTo(bug, land, ignore)
			if v and (not bv or v:LengthSqr() < bv:LengthSqr()) then best, bv, bt = land, v, T end
		end
	end
	return bv, best, bt
end

-- jump now, remembering what it aimed at (judged when it lands: R.JumpLanded)
function R.DoJump(bug, v, land, kind)
	-- "falling" but lying still (set down on the floor, it never hit it): it stands first
	if bug.Falling and bug:GetVelocity():Length() < 30 then bug:Land() end
	if bug.Falling then return false end
	-- (no jump whose arc goes into an incoming gate's horizon - it kills; a hop, a wall jump, a leap at prey standing in
	-- front of one: owner 2026-11-14, sv_pursuit.lua R.DeadArc)
	if R.DeadArc and R.DeadArc(bug:GetPos(), v, land) then R.Stat("jump kept off an incoming gate") R.Dbg(bug, "no jump: the arc runs into an incoming gate") return false end
	bug.JumpPlan = { from = bug:GetPos(), land = land, kind = kind, t0 = CurTime(), v = v }
	-- free of the surface first (a body pressed a little into the floor is held there by the physics and goes nowhere)
	local ph = bug:GetPhysicsObject()
	local lift = math.max(3, -bug:OBBMins().z + 2)
	if IsValid(ph) then ph:SetPos(ph:GetPos() + (bug.RepUp or Vector(0, 0, 1)) * lift) end
	bug:StartFall(v, true)
	R.Stat("aimed jumps")
	R.Dbg(bug, "jumps", kind, "speed", math.Round(v:Length()))
	return true
end

-- it came down (or grabbed a wall): how far off, learn the strength and whether this kind of jump pays off
function R.JumpLanded(bug, at, broke)
	local J = bug.JumpPlan
	bug.JumpPlan = nil
	if not J then return end
	local k = key(bug.RepOwner)
	local planned = Vector(J.land.x - J.from.x, J.land.y - J.from.y, 0)
	local done = Vector(at.x - J.from.x, at.y - J.from.y, 0)
	local pl = planned:Length()
	local miss = at:Distance(J.land)
	-- the strength: only from clean jumps - onto level ground at the height it aimed, along the line it aimed (a jump
	-- stopped early by a rim or a body, or at a moving prey, says nothing about its strength)
	if not broke and pl > 100 and J.kind ~= "leap" and math.abs(at.z - J.land.z) < 15 and miss < 120 then
		local along = done:Dot(planned) / pl
		local side = (done - planned:GetNormalized() * along):Length()
		if side < 30 and along > pl * 0.6 then
			local c = R.jumpCal[k] or 1
			local step = math.Clamp(0.3 * (pl / math.max(along, 1) - 1), -0.04, 0.04)
			R.jumpCal[k] = math.Clamp(c * (1 + step), 0.85, 1.25)
		end
	end
	local r = broke and -2 or (miss < 50 and 1 or (miss < 120 and 0 or -1))
	R.Brain.Judge("jump", J.kind or "level/near", r)
	if miss < 50 and not broke then R.Stat("jumps landed") else R.Stat("jumps missed") end
	R.Dbg(bug, "jump landed", J.kind, "off by", math.Round(miss), broke and "broke" or "", "strength", string.format("%.2f", R.jumpCal[k] or 1))
end

-- how much the swarm trusts this kind of jump (the learned value: 0.6 .. 1.6, 1 = nothing learned yet)
function R.JumpTrust(kind) return R.Brain.Weight("jump", kind) end

-- falling (not an attack jump): it turns its feet to the ground in the air, like a cat (owner 2026-11-05), and lands
-- on them when the fall gives it the time; a short drop can still put it on its back (it flails and rolls upright).
-- A turning push towards upright with damping, given back to ENT:PhysicsSimulate (setting the body's angles in there
-- froze it in the air)
function R.CatTwist(b, ph)
	local u = b:GetUp()
	local axis = u:Cross(Vector(0, 0, 1))
	local ang = math.deg(math.acos(math.Clamp(u.z, -1, 1)))
	if axis:LengthSqr() < 1e-6 then axis = b:GetForward() end   -- (straight on its back: any way over)
	axis:Normalize()
	local spin = ph:LocalToWorldVector(ph:GetAngleVelocity())
	return ph:WorldToLocalVector(axis * ang * 40 - spin * 12), Vector(0, 0, 0), SIM_LOCAL_ACCELERATION
end
