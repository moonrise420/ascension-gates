-- Replicators under a ceiling: their own walk while they hang upside down. The one walk for floors, walls and ceilings
-- had the ceiling as special cases in rules the floor and the walls use too - every fix for a ceiling moved something
-- on the floor (the 12:30 overhang try: strict high edge 5/9, roof 4/9). Under ceilings they hung 2-8 s at the corner of a
-- ceiling and a wall, the waypoint behind the slab (random rounds 87516, 87782 and their probes). This file runs only
-- while its up points down (agp_replicator.lua asks R.Ceil.On first; off: nothing here runs). It decides one of three
-- things and goes there along the ceiling:
--
--
--  * its goal is below, in the room: let itself down if the floor under its whole body is near, else to a wall and down it
--  * its goal is behind the slab (on the roof, the floor above): to the ceiling's nearest edge towards it, round it
--  * its goal is along the ceiling: there
-- From ceiling to wall and round an edge it goes with the corner move body and all (sv_walk.lua R.TransitTo) - one
-- motion run to its end, then the usual walk on the wall. No nearer its aim for 1.2 s: another aim; 2.5 s: down (a short
-- drop, or to any wall); 4 s: it lets go.
-- agp_rep_seamwalk 1: on. Off by default for the update: at the ceiling probes it helped (10/12 there against 9/12, 40 %
-- less time on ceilings) but the strict roof scene's third bug took 21-36 s with it against 11 s without. (A new
-- name: the tests' agp_rep_ceiling 1 is saved in server.vdf.)
local R = AGP.Rep
local C = R.Ceil or {}
R.Ceil = C
R.cv.ceil = R.cv.ceil or CreateConVar("agp_rep_seamwalk", "0", FCVAR_ARCHIVE, "Replicators: their own walk under ceilings and round seams (1, test) or the usual one (0)")

local MASKW = MASK_PLAYERSOLID
local function tr(b, a, c)
	return util.TraceLine({ start = a, endpos = c, mask = MASKW, filter = function(e) return e ~= b and not e.AGPReplicator and (not R.Walkable or R.Walkable(e)) end })
end

-- upside down and walking by itself (not round a corner, not on a planned side-view way, not held in a tower or a bridge,
-- not on a ship)
function C.On(b, up)
	-- (a real ceiling, within about 37 degrees of flat overhead: on the high edge's 45-degree undersides it found no edge or
	-- wall it knew and held still - those stay with the usual walk) (on below -0.8,
	-- off again only above -0.6: at the corner it went on and off every tick, the walks fighting - 66 % of its ticks
	-- there were the other walk)
	local lim = b.CeilActive and -0.6 or -0.8
	if not (R.cv.ceil:GetBool() and up.z < lim and b.RepClimb) then b.CeilActive = nil b.CeilWhy = "off: not upside down (" .. string.format("%.2f", up.z) .. ")" return false end
	if b.Transit or b.InTower or b.InBridge or b.Boarded or b.Falling or b.Crossing or b.BridgeJob or b.Clinging then
		b.CeilWhy = "off: " .. (b.Transit and "round a corner" or b.Falling and "falling" or "busy")
		return false
	end
	-- (a side-view plan brought along onto the ceiling (sv_surfnav.lua) is dropped: under the north building's ceiling it
	-- held the bug 13 s on the spot - the old "balcony hang". Its rails come off by themselves)
	if b.SurfPath then
		b.SurfPath, b.SurfPlanT = nil, CurTime() + 3
		R.Stat("ceiling: dropped a side-view plan")
		if R.SurfNav and R.SurfNav.Drop then R.SurfNav.Drop(b, "upside down: the ceiling walk") end
	end
	return true
end

-- the floor under its whole body within h: a drop it lands on whole
local function floorUnder(b, pos, h)
	for _, o in ipairs({ Vector(0, 0, 0), Vector(16, 0, 0), Vector(-16, 0, 0), Vector(0, 16, 0), Vector(0, -16, 0) }) do
		local fl = tr(b, pos + o - Vector(0, 0, 4), pos + o - Vector(0, 0, h))
		if not fl.Hit or fl.StartSolid or fl.HitNormal.z < 0.7 then return false end
	end
	return true
end

-- along the ceiling from pos in direction d: the first wall (a surface across the way) or edge (no ceiling further on),
-- up to maxd. Returns "wall"/"edge"/nil, the distance, and for a wall its trace
local function along(b, pos, n, d, maxd)
	for s = 24, maxd, 24 do
		local w = tr(b, pos + n * 6 + d * (s - 24), pos + n * 6 + d * s)
		if w.Hit and not w.StartSolid and w.HitNormal:Dot(n) < 0.6 then return "wall", (s - 24) + w.Fraction * 24, w end
		local q = pos + d * s
		local g = tr(b, q + n * 12, q - n * 20)
		if not g.Hit or g.HitNormal:Dot(n) < 0.7 then return "edge", s end
	end
end

-- where to: picked again every 1.5 s, or when it gets no nearer. kind "edge" (goal behind the slab), "wall" (goal below,
-- no short drop), "goal" (along the ceiling); dir along the ceiling; at: the aim point
local function pick(b, pos, n, f, goal, want, avoid)
	local to = goal - pos
	local flat = to - n * to:Dot(n)
	local fl = flat:LengthSqr() > 1 and flat:GetNormalized() or f
	local rt = f:Cross(n)
	local best, bs
	for a = 0, 315, 45 do
		local rad = math.rad(a)
		local d = f * math.cos(rad) + rt * math.sin(rad)
		d = d - n * d:Dot(n)
		d:Normalize()
		if not (avoid and avoid:Dot(d) > 0.9) then
			local kind, dist, w = along(b, pos, n, d, 360)
			if kind == want then
				local at = pos + d * dist
				-- (the way left after it: round the edge to the goal, or down the wall to it)
				local score = dist + at:Distance(goal) - 40 * d:Dot(fl)
				if not bs or score < bs then best, bs = { kind = kind, dir = d, at = at, dist = dist, w = w }, score end
			end
		end
	end
	return best
end

local function control(b, ph, p, u, f, dt, why)
	local vmax = math.max(260, (b.RepSpeed or 150) * (b.SpeedMul or 1) * 2)
	if R.DeadClamp and R.deadGates and #R.deadGates > 0 then p = R.DeadClamp(b, b:GetPos(), p) end
	b.RepUp, b.RepFwd, b.RepAt = u, f, p
	b.RepPlane, b.RepFlat = nil, nil
	b.WalkWhy = why
	b.CeilWhy = "on: " .. why
	ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = p, angle = f:AngleEx(u), maxangular = 4000,
		maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
end

-- round the edge at "at" in direction d: the slab's side face beyond it, and the corner move onto it
local function roundEdge(b, pos, n, d)
	local at
	for s = 4, 48, 4 do
		local q = pos + d * s
		local g = tr(b, q + n * 12, q - n * 20)
		if not g.Hit or g.HitNormal:Dot(n) < 0.7 then at = pos + d * (s - 4) break end
	end
	if not at then return end
	local out = at + d * 14 - n * 6
	local side = tr(b, out, out - d * 30)
	if side.Hit and not side.StartSolid and side.HitNormal:Dot(d) > 0.5 then
		return R.TransitTo(b, pos, n, side.HitPos, side.HitNormal)
	end
end

-- one step under the ceiling. Returns true when it set its body (or let go), false: the usual walk this tick
function C.Step(b, ph, pos, up, fwd, goal, dt)
	local now = CurTime()
	-- the ceiling under its feet (its own up is the smoothed one: the surface's is taken)
	local g = tr(b, pos + up * 12, pos - up * 20)
	if not g.Hit or g.StartSolid or g.HitNormal.z > -0.6 then
		b.CeilWhy = "gave back: " .. (not g.Hit and "no ceiling under its feet" or g.StartSolid and "feet in the ceiling" or string.format("surface not a ceiling (%.2f)", g.HitNormal.z))
		return false
	end
	b.CeilActive = true
	local n = g.HitNormal
	local f = fwd - n * fwd:Dot(n)
	if f:LengthSqr() < 1e-4 then f = n:Angle():Up() end
	f:Normalize()
	local J = b.CeilJob
	if J and (J.n:Dot(n) < 0.9 or J.goal:DistToSqr(goal or J.goal) > 40 * 40 or J.p:DistToSqr(pos) > 300 * 300) then J = nil end
	if not goal or not R.Awake() or b.Eating then
		b.CeilJob = J
		control(b, ph, g.HitPos, n, f, dt, "ceiling: holds")
		return true
	end
	local to = goal - pos
	local below = to:Dot(n)   -- (+: down in the room under it, -: behind the slab)
	local want = (below > 30) and "wall" or (below < -6) and "edge" or "goal"
	-- the goal below and a short drop under its whole body: it lets itself down (a spider does)
	if want == "wall" and floorUnder(b, pos, R.LetDown or 160) then
		b.CeilJob = nil
		b.RepFallWhy = "lets itself down (ceiling)"
		R.Stat("ceiling: let itself down to its goal")
		b:StartFall()
		return true
	end
	-- its aim: kept while it gets nearer
	if not J or J.want ~= want or now > J.t then
		local aim
		if want == "goal" then aim = { kind = "goal", at = goal - n * below }
		else aim = pick(b, pos, n, f, goal, want, J and J.avoid) end
		J = { want = want, aim = aim, t = now + 1.5, n = n, goal = Vector(goal), p = Vector(pos), avoid = J and J.avoid, t0 = J and J.t0 or now }
		b.CeilJob = J
	end
	local aim = J.aim
	-- no aim at all (no edge, no wall within 360 along the ceiling): down if it can, else the usual walk this tick (held
	-- still here it waited for nothing)
	if not aim then
		if floorUnder(b, pos, 260) then
			b.CeilJob = nil
			b.RepFallWhy = "lets go (ceiling, no way along it)"
			R.Stat("ceiling: let go, no edge or wall near")
			b:StartFall()
			return true
		end
		R.Stat("ceiling: no aim - the usual walk")
		b.CeilWhy = "gave back: no aim (" .. want .. ")"
		return false
	end
	local ad = aim.at - pos
	ad = ad - n * ad:Dot(n)
	local dist = ad:Length()
	-- stuck? (moved under 6 in 1.2 s - standing or wobbling on the spot: another aim; 2.5 s: down; 4 s: lets go). On the
	-- bug, not the aim: a new aim does not start the clock again
	local M = b.CeilMove
	if not M or now - M.seen > 0.5 or M.p:DistToSqr(pos) > 6 * 6 then M = { p = Vector(pos), t = now } b.CeilMove = M end
	M.seen = now
	local stuck = now - M.t
	if stuck > 4 then
		b.CeilJob = nil
		b.RepFallWhy = "lets go (ceiling, stuck)"
		R.Stat("ceiling: let go, stuck 4 s")
		R.Dbg(b, "ceiling: let go, stuck", want, tostring(pos))
		b:StartFall()
		return true
	elseif stuck > 2.5 and not M.down then
		M.down = true
		if floorUnder(b, pos, 260) then
			b.CeilJob = nil
			b.RepFallWhy = "lets itself down (ceiling, stuck)"
			R.Stat("ceiling: down, stuck 2.5 s")
			b:StartFall()
			return true
		end
		local w = pick(b, pos, n, f, goal, "wall")
		if w then J.aim, J.want, aim = w, "wall", w R.Stat("ceiling: stuck, to a wall") end
	elseif stuck > 1.2 and not M.repicked and aim.dir then
		M.repicked = true
		J.avoid = aim.dir
		J.t = 0   -- (picked again next tick, not that way)
		R.Stat("ceiling: no nearer, another way")
	end
	-- there: round the edge / onto the wall, body and all - the corner move runs to its end, then the usual walk
	if aim.kind == "edge" and dist < 30 and aim.dir then
		local p, u, ff = roundEdge(b, pos, n, aim.dir)
		if p then
			b.CeilJob = nil
			R.Stat("ceiling: round the edge")
			control(b, ph, p, u, ff, dt, "ceiling: round the edge")
			return true
		end
	end
	if aim.kind == "wall" and aim.w and dist < (b.RepRadius or 18) + 10 then
		local p, u, ff = R.TransitTo(b, pos, n, aim.w.HitPos, aim.w.HitNormal)
		if p then
			b.CeilJob = nil
			R.Stat("ceiling: onto the wall")
			control(b, ph, p, u, ff, dt, "ceiling: onto the wall")
			return true
		end
	end
	if aim.kind == "goal" and dist < 8 then
		control(b, ph, g.HitPos, n, f, dt, "ceiling: at its goal")
		return true
	end
	-- on along the ceiling towards the aim: turned towards it, a step ahead, kept on the ceiling
	local want_d = ad / math.max(dist, 0.001)
	local off = math.acos(math.Clamp(f:Dot(want_d), -1, 1))
	local turn = math.rad((b.RepTurn or 360) * dt)
	if off > 2.6 or off <= turn then f = want_d
	else
		local axis = f:Cross(want_d)
		if axis:LengthSqr() < 1e-6 then axis = n end
		axis:Normalize()
		local a = turn
		f = f * math.cos(a) + axis:Cross(f) * math.sin(a) + axis * axis:Dot(f) * (1 - math.cos(a))
		f = f - n * f:Dot(n)
		f:Normalize()
	end
	local spd = (b.RepSpeed or 150) * (b.SpeedMul or 1) * math.Clamp(1 - off / 1.9, 0.15, 1)
	local q = pos + f * math.min(spd * 0.08, math.max(dist, 2))
	-- a wall right ahead it did not aim for (a beam under the ceiling): onto it, the usual walk takes it from there
	local w = tr(b, pos + n * 6, pos + n * 6 + f * ((b.RepRadius or 18) + 8))
	if w.Hit and not w.StartSolid and w.HitNormal:Dot(n) < 0.6 and aim.kind ~= "edge" then
		local p, u, ff = R.TransitTo(b, pos, n, w.HitPos, w.HitNormal)
		if p then
			b.CeilJob = nil
			R.Stat("ceiling: onto a wall in its way")
			control(b, ph, p, u, ff, dt, "ceiling: onto a wall")
			return true
		end
	end
	local gq = tr(b, q + n * 12, q - n * 20)
	if gq.Hit and not gq.StartSolid and gq.HitNormal:Dot(n) > 0.7 then
		control(b, ph, gq.HitPos, gq.HitNormal, f, dt, "ceiling: to " .. aim.kind)
		return true
	end
	-- no ceiling under the next step: going for the edge - round it here; an edge it did not aim for - hold (the stuck
	-- clock picks another way)
	if aim.kind == "edge" then
		local p, u, ff = roundEdge(b, pos, n, f)
		if p then
			b.CeilJob = nil
			R.Stat("ceiling: round the edge")
			control(b, ph, p, u, ff, dt, "ceiling: round the edge")
			return true
		end
	end
	control(b, ph, g.HitPos, n, f, dt, "ceiling: edge ahead")
	return true
end

-- the crease between a ceiling and a wall (its up between the two, 35-60 degrees): the felt map rounds the corner off
-- and there the bug hung 7-14 s, neither walk sure which face it is on (corner probe: 123 ticks "not upside down", 101
-- "not a ceiling"). Moving on: nothing here. Moved under 6 in 0.8 s: it picks the face its waypoint is on - the ceiling or
-- the wall beside it - and rolls fully onto it in one corner move (R.TransitTo); then that face's walk.
function C.Crease(b, ph, pos, up, fwd, goal, dt)
	if not (R.cv.ceil:GetBool() and b.RepClimb and goal) then return false end
	if up.z >= -0.3 or up.z < -0.8 then b.CreaseM = nil return false end
	if b.Transit or b.InTower or b.InBridge or b.Boarded or b.Falling or b.Crossing or b.BridgeJob or b.Clinging then return false end
	local now = CurTime()
	local M = b.CreaseM
	if not M or now - M.seen > 0.5 or M.p:DistToSqr(pos) > 6 * 6 then M = { p = Vector(pos), t = now } b.CreaseM = M end
	M.seen = now
	if now - M.t < 0.8 then return false end
	-- the two faces near: the ceiling over it and the wall beside it
	local faces = {}
	local c = tr(b, pos - up * 4, pos - up * 4 + Vector(0, 0, 40))
	if c.Hit and not c.StartSolid and c.HitNormal.z < -0.7 then faces[#faces + 1] = c end
	local flat = Vector(-up.x, -up.y, 0)
	if flat:LengthSqr() > 0.01 then
		flat:Normalize()
		local w = tr(b, pos + Vector(0, 0, -4), pos + Vector(0, 0, -4) + flat * 40)
		if w.Hit and not w.StartSolid and math.abs(w.HitNormal.z) < 0.4 then faces[#faces + 1] = w end
	end
	-- which face: the one its waypoint lies on, when its way says so (a felt way carries each waypoint's face, sv_feltnav.lua);
	-- else the face its goal is in front of (not behind it), the one that takes it nearest
	local want
	local rt = b.Route
	if rt and rt.m and b.RouteI then want = rt.m[b.RouteI] or rt.m[b.RouteI + 1] end
	-- (never back onto the face it just rolled off: the walk sent it back the other way and it rocked between the two -
	-- the ping-pong at a seam, as other wall-walking games found too; 2.5 s)
	local left = b.CreaseLeft
	if left and CurTime() > left.t then left = nil b.CreaseLeft = nil end
	local best, bs
	for _, fc in ipairs(faces) do
		if not (left and fc.HitNormal:Dot(left.n) > 0.8) then
			local sc
			if want then
				local d = fc.HitNormal:Dot(want)
				if d > 0.7 then sc = -d end
			else
				local side = (goal - fc.HitPos):Dot(fc.HitNormal)
				if side > -4 then sc = (goal - fc.HitNormal * side):Distance(pos) end
			end
			if sc and (not bs or sc < bs) then best, bs = fc, sc end
		end
	end
	b.CreaseM = nil
	if not best then R.Stat("crease: no face its goal is on") return false end
	local p, u, f = R.TransitTo(b, pos, up, best.HitPos, best.HitNormal)
	if not p then R.Stat("crease: no corner move") return false end
	for _, fc in ipairs(faces) do if fc ~= best then b.CreaseLeft = { n = fc.HitNormal, t = CurTime() + 2.5 } end end
	if want then R.Stat("crease: the face its way says") end
	R.Stat(best.HitNormal.z < -0.7 and "crease: onto the ceiling" or "crease: onto the wall")
	control(b, ph, p, u, f, dt, best.HitNormal.z < -0.7 and "crease: onto the ceiling" or "crease: onto the wall")
	return true
end

-- a seam on its way: its next waypoint lies on another face than the one it stands on - the wall beside a ceiling's
-- corner, a window frame's side round its edge, a sill's top - and its body does not get round onto it: at the corner
-- probe it rocked 7 s between ceiling and wall 18 from a waypoint on the wall, then hung beside the window frame 11 from
-- a waypoint round the frame's edge (the walks took turns, none went round). A felt way knows each waypoint's face
-- (sv_feltnav.lua w.m): within 40 of it, on another face, no 4 nearer for 0.6 s -> onto that face in one corner move
-- (R.TransitTo); never straight back onto the face it just left (2.5 s).
function C.Seam(b, ph, pos, up, fwd, dt)
	if not (R.cv.ceil:GetBool() and b.RepClimb) then return false end
	-- (on a wall or a ceiling only: on a floor the curb's face is a waypoint's face too - it must glide over, not climb it)
	if up.z > 0.7 then b.SeamM = nil return false end
	local rt = b.Route
	if not (rt and rt.felt and rt.m and b.RouteI and b.MoveTo) then b.SeamM = nil return false end
	if b.Transit or b.InTower or b.InBridge or b.Boarded or b.Falling or b.Crossing or b.BridgeJob or b.Clinging or b.Eating then return false end
	local m, wp = rt.m[b.RouteI], rt[b.RouteI]
	if not (m and wp) or m:Dot(up) > 0.8 or wp:DistToSqr(pos) > 40 * 40 then b.SeamM = nil return false end
	local now = CurTime()
	local M = b.SeamM
	if not M or M.i ~= b.RouteI or M.r ~= rt or now - M.seen > 0.5 then M = { i = b.RouteI, r = rt, d = wp:Distance(pos), t = now } b.SeamM = M end
	M.seen = now
	local d = wp:Distance(pos)
	if d < M.d - 4 then M.d, M.t = d, now end
	if now - M.t < 0.6 then return false end
	local left = b.SeamLeft
	if left and now > left.t then left = nil b.SeamLeft = nil end
	if left and m:Dot(left.n) > 0.8 then return false end
	-- the face itself: under the waypoint along its up (the waypoint is 3 off it)
	local t = tr(b, wp + m * 10, wp - m * 20)
	if not t.Hit or t.StartSolid or t.HitNormal:Dot(m) < 0.8 then R.Stat("seam: its waypoint's face not found") M.t = now return false end
	local p, u, f = R.TransitTo(b, pos, up, t.HitPos, t.HitNormal)
	if not p then R.Stat("seam: no corner move") M.t = now return false end
	b.SeamLeft = { n = Vector(up), t = now + 2.5 }
	b.SeamM = nil
	R.Stat("seam: onto its waypoint's face")
	control(b, ph, p, u, f, dt, "seam: onto its waypoint's face")
	return true
end
