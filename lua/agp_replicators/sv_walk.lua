-- Replicators: walking on any surface like a spider. The old walker felt about with a few single probes and had
-- a rule for every shape (a wall ahead, an edge, a lip, a cap ...); every new shape needed a new rule. This one does
-- what wall-walking creatures in games do: rays from above each of its feet down onto the surface; where they hit,
-- averaged, is where it stands and which way is up. Inside corners (floor to wall, wall to ceiling) come from a
-- feeler ahead: a surface rising across its way is what it walks onto. Outside corners (over a roof's edge, round a
-- lip, over a wall's cap) come from the feet: when the front feet find nothing, it looks for the face beyond the edge
-- and goes round onto it. The same few lines for the map, props, a ship's decks, pillars, ceilings - no rule per
-- shape, and "up" is always the surface's own (no turning its back to a wall). agp_rep_walker: 1 = the old walker, 2
-- = this one.
--
local R = AGP.Rep
R.cv.walker = R.cv.walker or CreateConVar("agp_rep_walker", "2", FCVAR_ARCHIVE, "Replicators: 1 = old walker, 2 = leg-ray walker")
-- how far a bug lets itself drop on purpose (off an edge it walks over, from a ceiling down onto the floor): a short
-- drop, landing under 450. A drop it would just survive - 375 off an edge, 250 from a ceiling - looked like a fall and
-- landed at 540-660 (a "rocket" in the tests): walking off the roof it had just climbed onto, 368 high, was most of the
-- roof scene's falls
R.LetDown = 160

-- a short pivot that does not bump into the world: stepping round an inside corner (floor to wall, wall to ceiling) its
-- 36-unit body has to swing through the corner - solid, its nose hit the wall and it went on up it belly down, upright
-- For a third of a second it does not collide with the world, then it is solid again (checked every tenth of a
-- second, and at once when it falls). On a planned way it was without collisions all along (sv_surfnav.lua "rails") and
-- went through walls.
function R.Pivot(b)
	local ph = b:GetPhysicsObject()
	if not IsValid(ph) then return end
	b.PivotT = CurTime() + 0.35
	if not b.PivotOn then b.PivotOn = true ph:EnableCollisions(false) end
end
function R.PivotEnd(b)
	if not b.PivotOn then return end
	b.PivotOn, b.PivotT = nil, nil
	if b.SurfRails then return end   -- (the old rails, agp_rep_solidways 0: they keep it so)
	local ph = b:GetPhysicsObject()
	if IsValid(ph) then ph:EnableCollisions(true) end
end
timer.Create("AGPRepPivot", 0.1, 0, function()
	local now = CurTime()
	for e in pairs(R.bugs or {}) do
		if IsValid(e) and e.PivotOn and (now > (e.PivotT or 0) or e.Falling) then R.PivotEnd(e) end
	end
end)

local MASKW = MASK_PLAYERSOLID
local function surf(b, a, c)
	return util.TraceLine({ start = a, endpos = c, mask = MASKW, filter = function(e) return e ~= b and (not R.Walkable or R.Walkable(e)) end })
end
-- the feet: { forward, sideways } in body lengths (front pair, back pair, the nose)
local LEGS = { { 0.55, 0.5 }, { 0.55, -0.5 }, { -0.55, 0.5 }, { -0.55, -0.5 }, { 1.0, 0 } }

-- Its body round a corner. Its body is stiff, 40 long. Where it was and how it was tilted were two things worked out
-- apart - the point on the surface, and that surface's "up", smoothed so it would turn, not snap: round a corner its
-- up turned early or late against where it was, its nose went into the wall (on a planned way, without collisions,
-- it went through: 15-38 times a run) or, solid, it stood upright against the wall, belly down, and climbed like
-- that for a second and more (the course test). Now both come from one thing: where its back and its front are on
-- the surface, half a body length behind and ahead along the way. The line from back to front is its body's line:
-- into a wall the front goes up the wall and the body tilts with it, a little at a time; over an edge the front goes
-- down beyond it. The body is lifted until no surface under its length is above that line - it rests on the edge and
-- rolls over it, across a thin plate's top it lies on the top. Its up stands square on its body's line, on the side the
-- surfaces face. R.Stance(points on the surface, their ups, half its length, sample step[, from, to]): its body all
-- along that way - { pts = the middle of its
-- underside, ups, fw = its body's line, d = distance along, len } - or nil
--
function R.Stance(S, U, L, ds, from, to)
	local n = #S
	if n < 2 then return end
	local X, Y, Z, a = {}, {}, {}, { 0 }
	for k = 1, n do X[k], Y[k], Z[k] = S[k].x, S[k].y, S[k].z end
	for k = 2, n do a[k] = a[k - 1] + S[k]:Distance(S[k - 1]) end
	local len = a[n]
	if len < 1 then return end
	-- (beyond its two ends the way goes on straight)
	local d0, d1
	for k = 2, n do if a[k] > a[k - 1] + 0.01 then d0 = (S[k] - S[k - 1]):GetNormalized() break end end
	for k = n, 2, -1 do if a[k] > a[k - 1] + 0.01 then d1 = (S[k] - S[k - 1]):GetNormalized() break end end
	local function find(s)   -- the last point at or before s along the way
		local lo, hi = 1, n
		while hi - lo > 1 do
			local m = math.floor((lo + hi) / 2)
			if a[m] <= s then lo = m else hi = m end
		end
		return lo
	end
	local function at(s)
		if s <= 0 then return S[1] + d0 * s, U[1] end
		if s >= len then return S[n] + d1 * (s - len), U[n] end
		local k = find(s)
		local sl = a[k + 1] - a[k]
		local t = sl > 1e-6 and (s - a[k]) / sl or 0
		return LerpVector(t, S[k], S[k + 1]), LerpVector(t, U[k], U[k + 1])
	end
	-- how far a stretch of the surface (a..c) stands over its underside (through m along d, up u) within its length
	local best
	local function over(ax, ay, az, cx, cy, cz, mx, my, mz, dx, dy, dz, ux, uy, uz)
		local pa = (ax - mx) * dx + (ay - my) * dy + (az - mz) * dz
		local pc = (cx - mx) * dx + (cy - my) * dy + (cz - mz) * dz
		local ha = (ax - mx) * ux + (ay - my) * uy + (az - mz) * uz
		local hc = (cx - mx) * ux + (cy - my) * uy + (cz - mz) * uz
		-- (a hair short of its ends: a surface square to it right at its end - the floor it just left, under its tail as it
		-- stands on the wall - only touches it)
		local t0, t1, E = 0, 1, L - 0.5
		local dp = pc - pa
		if math.abs(dp) < 1e-6 then
			if math.abs(pa) > E then return end
		else
			local ta, tb = (-E - pa) / dp, (E - pa) / dp
			if ta > tb then ta, tb = tb, ta end
			if ta > t0 then t0 = ta end
			if tb < t1 then t1 = tb end
			if t0 > t1 then return end
		end
		local h = math.max(ha + (hc - ha) * t0, ha + (hc - ha) * t1)
		if h > best then best = h end
	end
	from, to = math.Clamp(from or 0, 0, len), math.Clamp(to or len, 0, len)
	if to <= from then to = math.min(len, from + 0.01) end
	local steps = math.max(1, math.ceil((to - from) / (ds or 3)))
	local B = { pts = {}, ups = {}, fw = {}, d = {} }
	local lastU = U[1]
	for i = 0, steps do
		local s = from + (to - from) * i / steps
		local T, uT = at(s - L)
		local N, uN = at(s + L)
		-- (into a corner, floor to wall, the line from back to front cuts across it and is shorter than its body: lifted
		-- to fit, it rose straight up a body's height before it tilted. Its back and front reach further along instead -
		-- up to half again - until its body fits between them, resting on both. Over a thin plate's top they never get
		-- further apart that way: there as it was)
		local w = L
		if N:DistToSqr(T) < (2 * L - 0.5) ^ 2 then
			local T2, uT2, N2, uN2
			while w < 1.5 * L do
				w = math.min(1.5 * L, w + 1)
				T2, uT2 = at(s - w)
				N2, uN2 = at(s + w)
				if N2:DistToSqr(T2) >= (2 * L - 0.5) ^ 2 then break end
			end
			if N2:DistToSqr(T2) >= (2 * L - 0.5) ^ 2 then T, uT, N, uN = T2, uT2, N2, uN2 else w = L end
		end
		local d = N - T
		if d:LengthSqr() < 1 then d = (at(s + 1)) - (at(s - 1)) end
		if d:LengthSqr() < 1e-6 then d = Vector(d0) end
		d:Normalize()
		-- its up: the surfaces' ups along its length, square on its body's line
		local nu = uT + uN
		for k = find(math.max(0, s - w)), n do
			if a[k] >= s + w then break end
			if a[k] > s - w then nu:Add(U[k]) end
		end
		local up = nu - d * nu:Dot(d)
		if up:LengthSqr() < 1e-4 then up = lastU - d * lastU:Dot(d) end
		if up:LengthSqr() < 1e-4 then up = Vector(lastU) end
		up:Normalize()
		-- lifted until nothing of the surface under its length is above its underside
		local mid = (T + N) * 0.5
		local mx, my, mz, dx, dy, dz, ux, uy, uz = mid.x, mid.y, mid.z, d.x, d.y, d.z, up.x, up.y, up.z
		best = 0
		local s0, s1 = s - 2 * L - 2, s + 2 * L + 2
		if s0 < 0 then local q = S[1] + d0 * s0 over(q.x, q.y, q.z, X[1], Y[1], Z[1], mx, my, mz, dx, dy, dz, ux, uy, uz) end
		if s1 > len then local q = S[n] + d1 * (s1 - len) over(X[n], Y[n], Z[n], q.x, q.y, q.z, mx, my, mz, dx, dy, dz, ux, uy, uz) end
		for k = find(math.max(0, s0)), n - 1 do
			if a[k] > s1 then break end
			over(X[k], Y[k], Z[k], X[k + 1], Y[k + 1], Z[k + 1], mx, my, mz, dx, dy, dz, ux, uy, uz)
		end
		local o = mid + up * best
		-- (kept where it turns, every 12 units along a straight stretch)
		local m = #B.pts
		if m == 0 or i == steps or o:DistToSqr(B.pts[m]) >= 144 or up:Dot(B.ups[m]) < 0.9995 or d:Dot(B.fw[m]) < 0.9995 then
			B.pts[m + 1], B.ups[m + 1], B.fw[m + 1] = o, up, d
			B.d[m + 1] = m == 0 and 0 or B.d[m] + math.max(o:Distance(B.pts[m]), math.acos(math.Clamp(up:Dot(B.ups[m]), -1, 1)) * 6)
		end
		lastU = up
	end
	B.len = B.d[#B.d]
	return B
end
-- the body's place, up and line at distance s along R.Stance's way (j: where to start looking)
function R.StanceAt(B, s, j)
	local P, D = B.pts, B.d
	local n = #P
	if n == 1 or s <= 0 then return Vector(P[1]), Vector(B.ups[1]), Vector(B.fw[1]), 1 end
	if s >= D[n] then return Vector(P[n]), Vector(B.ups[n]), Vector(B.fw[n]), n - 1 end
	if not j or j >= n or D[j] > s then j = 1 end
	while j < n - 1 and D[j + 1] < s do j = j + 1 end
	local seg = D[j + 1] - D[j]
	local t = seg > 0 and math.Clamp((s - D[j]) / seg, 0, 1) or 0
	local u = LerpVector(t, B.ups[j], B.ups[j + 1])
	if u:LengthSqr() < 1e-4 then u = Vector(B.ups[j + 1]) end
	u:Normalize()
	local f = LerpVector(t, B.fw[j], B.fw[j + 1])
	f = f - u * f:Dot(u)
	if f:LengthSqr() < 1e-4 then f = u:Angle():Up() end
	f:Normalize()
	return LerpVector(t, P[j], P[j + 1]), u, f, j
end

-- going round a corner on its legs (a wall rising ahead, an edge it goes over): the same stiff body over the corner its
-- feelers found - the surface it is on, the corner, the face beyond - a step at a time, then its legs again. (Before, it
-- was set round at once: up a wall onto the wall half a body length up, its body swinging round through the corner - its
-- nose hit the wall, so for that third of a second it did not collide with the world; over an edge onto the face beyond,
-- turned all at once.) pos: on the surface it is on (up u0), c: the corner, f0: its way to the corner, n and f1: the new
-- face's up and its way on along it.
local function transit(b, pos, u0, f0, c, n, f1, why)
	if b.TransitFailT and CurTime() - b.TransitFailT < 1.5 then return end   -- (it just could not: see R.Walk)
	local L = (b.RepRadius or 18) * 1.1
	local back = math.min(0, (pos - c):Dot(f0))   -- (how far before the corner it is)
	local S = { c + f0 * (back - 2 * L), Vector(c), Vector(c), c + f1 * (3 * L) }
	local U = { u0, u0, n, n }
	local ac = 2 * L - back   -- (the corner, along that way)
	local from = math.min(ac + L - 4, 2 * L + math.max(0, (pos - c):Dot(f0)))
	local B = R.Stance(S, U, L, 2, from, ac + L)
	if not B or B.len < 2 then return end
	b.Transit = { B = B, s = 0, t0 = CurTime(), max = B.len / math.max(40, (b.RepSpeed or 150) * (b.SpeedMul or 1)) * 3 + 0.5, why = why }
	b.RepPlane, b.RepFlat = nil, nil
	R.Stat("went round a corner body and all")
	local p, u, f = R.StanceAt(B, 0)
	b.WalkWhy = why
	return p, u, f
end

-- which way to go when the goal, seen from the surface it is on, points nowhere useful:
--  * on a wall and the goal lies behind it: up and over the top (projected onto the wall it pointed sideways)
--  * on the ground right under the goal (on top of something): to the nearest wall, and up that
-- (not while it builds or crosses a bridge of bodies: there the way is along the edge)
-- its goal straight through the surface it is on - on top of the slab it hangs under, under the floor it stands on:
-- near along the surface is not there (freespace13's roof slab: the planned way ended under it 16 below the goal
-- and the bug hung there for the rest of the test). Where to go instead: the nearest edge of that surface (8 ways
-- along it, every 24 up to 240), the one with the least way left to the goal round it - a little past it, so its legs
-- go round. Or nil: the goal is not behind it, or no edge near. (worked out once a second and a half: only for a
-- bug in that spot, up to 80 rays)
function R.EdgeAim(b, pos, up, goal)
	-- (under a ceiling or on a floor only: on a wall with the goal behind it R.WalkDir takes it up and over the top - here
	-- it was sent at a point past the sign's top edge and its body went into the board's top)
	if math.abs(up.z) < 0.5 then return nil end
	local to = goal - pos
	local along = to:Dot(up)
	if along > -4 then return nil end
	local flat = to - up * along
	if flat:LengthSqr() > 60 * 60 then return nil end
	local now = CurTime()
	if b.EdgeAimT and now < b.EdgeAimT and b.EdgeAimGoal and b.EdgeAimGoal:DistToSqr(goal) < 16 * 16 then return b.EdgeAim end
	if R.Reached and R.Reached(b, pos, goal) then return nil end
	local f = (b.RepFwd or b:GetForward())
	f = f - up * f:Dot(up)
	if f:LengthSqr() < 1e-4 then f = up:Angle():Up() end
	f:Normalize()
	local rt = f:Cross(up)
	local best, bs
	for a = 0, 315, 45 do
		local rad = math.rad(a)
		local d = f * math.cos(rad) + rt * math.sin(rad)
		for s = 24, 240, 24 do
			local q = pos + d * s
			if surf(b, pos + up * 6, q + up * 6).Hit then break end   -- (a wall that way: not an edge)
			local t = surf(b, q + up * 10, q - up * 16)
			if not t.Hit then
				local e = q + d * 6
				local score = s + e:Distance(goal)
				if not bs or score < bs then best, bs = e, score end
				break
			end
		end
	end
	b.EdgeAim, b.EdgeAimT, b.EdgeAimGoal = best, now + 1.5, Vector(goal)
	if best then R.Stat("goal behind its surface: to the nearest edge") end
	return best
end

function R.WalkDir(b, pos, up, goalPos)
	if not goalPos or b.Crossing or b.BridgeJob or b.InBridge or b.InTower then return end
	-- on a wall and the goal lies out in front of it and lower (on the floor beyond, a waypoint down there): straight down
	-- the wall first, then across the floor. Heading for it along the wall it went sideways, round the corner of a box
	-- 25 high onto the next face - where the way to the goal pointed back round the same corner: 20 times in a row, the
	-- rest of the scene (the roof scene). Only once it goes round in such a circle (rule 3 marks it) and with a floor a
	-- short way below (a low box, a counter, the sign's end): always on, it took the high edge scene's cliff, with ledges
	-- and overhangs on it, straight down and fell more (0 of 9 bugs clean in 3 runs, 6 of 9 without it). Also with the
	-- goal a little higher (not well above): round the corner of the sign's end, towards a goal 24 above it, it
	-- circled until it let go (the sign test).
	if math.abs(up.z) < 0.5 and b.CircleT and CurTime() < b.CircleT then
		local to = goalPos - pos
		if to:Dot(up) > 16 and to.z < 60 then
			local fl = surf(b, pos + up * 8, pos + up * 8 - Vector(0, 0, R.LetDown))
			local w = Vector(0, 0, -1) - up * -up.z
			if fl.Hit and not fl.StartSolid and fl.HitNormal.z > 0.7 and w:LengthSqr() > 0.01 then return w:GetNormalized() end
		end
	end
	b.WalkDirCeil = nil
	local to = goalPos - pos
	-- (on a way across the map (sv_nav.lua) its next waypoint says where: "up and over" sent one far up a taller wall
	-- past the roof the way led to. Except under a ceiling with the waypoint hidden above it - it went straight at
	-- it, into the wall, up the wall, onto the ceiling again: wall, ceiling, wall for 20 s under a window's lintel,
	-- repfs13 the roof corner, - then the ceiling's nearest edge below)
	local onRoute = b.Route and b.Route == b.NavRoute
	if onRoute and not (up.z < -0.5 and to:Dot(up) < -20 and surf(b, pos + up * 4, goalPos).Hit) then return end
	if math.abs(up.z) < 0.5 and to:Dot(up) < -20 then
		local w = Vector(0, 0, 1) - up * up.z
		if w:LengthSqr() > 0.01 then return w:GetNormalized() end
	end
	-- under a ceiling and the goal lies above it (on top of the shelf, the roof): to the nearest edge of the ceiling
	-- (the side towards the goal counts a little nearer), round it and up
	if up.z < -0.5 and to:Dot(up) < -20 then
		b.WalkDirCeil = true
		if b.EdgeDirT and CurTime() < b.EdgeDirT then return b.EdgeDir end
		local fl = Vector(to.x, to.y, 0)
		fl = fl:LengthSqr() > 1 and fl:GetNormalized() or Vector(1, 0, 0)
		local best, bs
		for a = 0, 315, 45 do
			local d = Angle(0, a, 0):Forward()
			for dist = 40, 480, 40 do
				local q = pos + d * dist
				local tr = surf(b, q + up * 12, q - up * 30)   -- (from below the ceiling up into it)
				if not tr.Hit then
					-- (on a way across the map: only an edge it can walk to under the ceiling - inside a room the "edge" was
					-- the open sky beyond the room's wall, and it went into the wall; repfs13, bugs inside. Looked for 40 under
					-- the ceiling: a room's wall goes down to the floor, a lintel at the ceiling's edge does not - looked for just
					-- under it, the lintel turned the edge it was under away and it crawled off deeper under the
					-- overhang, the roof corner 3 of 6 runs worse)
					if not onRoute or not surf(b, pos + up * 40, q + up * 40).Hit then
						local score = dist - 60 * d:Dot(fl)
						if not bs or score < bs then best, bs = d, score end
					end
					break
				end
			end
		end
		b.EdgeDir, b.EdgeDirT = best, CurTime() + 2
		return best
	end
	-- (also further from right under it when a ceiling hangs between it and the goal: under a deck on pillars across a
	-- narrow gap they stood under their goal and only hopped on the spot - the way up is the nearest pillar or wall)
	local hz = Vector(to.x, to.y, 0):Length()
	if up.z > 0.7 and to.z > 60 and (hz < 60 or (hz < 400 and surf(b, pos + Vector(0, 0, 10), pos + Vector(0, 0, to.z - 10)).Hit)) then
		if b.WallDirT and CurTime() < b.WallDirT then return b.WallDir end
		local best, bd
		for a = 0, 337.5, 22.5 do   -- (16 ways: a thin pillar between two of 8 was missed)
			local d = Angle(0, a, 0):Forward()
			local tr = surf(b, pos + Vector(0, 0, 10), pos + Vector(0, 0, 10) + d * 400)
			if tr.Hit and not tr.StartSolid and math.abs(tr.HitNormal.z) < 0.5 and (not bd or tr.Fraction < bd) then best, bd = d, tr.Fraction end
		end
		b.WallDir, b.WallDirT = best, CurTime() + 2
		return best
	end
end

-- where it holds still (at a high edge, waiting at a gap): the last point it was set to, not where the body is now -
-- held at its own sagging position it slid down a wall a little every tick (the door ambush test)
local function hold(b, pos)
	local a = b.RepAt
	if a and a:DistToSqr(pos) < 12 * 12 then return Vector(a) end
	return Vector(pos)
end

-- What is at a spot: something a bug can stand on - the map or a prop it may walk on - or only air. The spots a bug
-- makes up for itself (a spot to wander to, a place to scout, a way round something in its way) were plain points in
-- space: on a wall "450 up" lay far over its top, "1500 that way" at the height of the wall it was on lay in the air,
-- a step aside from another bug went through the board it was on - and 529 of 879 asks for a way across the map were
-- for spots in the air (sv_nav.lua). It walked after them up past a board's top, turned and fell (the sign and the
-- wall scenes). Now each made-up spot is put where it can stand: on the ground under it (R.Ground), or along the
-- surface it is on, no further than that goes (R.Anchor).
local function kind(tr) return tr.HitWorld and "map" or "prop" end

-- the ground under a spot (or on top of what it lies in): the spot and "map" / "prop" - or nil, "air"
function R.Ground(b, p, depth)
	local tr = surf(b, p + Vector(0, 0, 40), p - Vector(0, 0, depth or 600))
	if tr.StartSolid then tr = surf(b, p + Vector(0, 0, 160), p - Vector(0, 0, depth or 600)) end
	if not tr.Hit or tr.StartSolid or tr.HitNormal.z < 0.6 then return nil, "air" end
	return tr.HitPos + Vector(0, 0, 2), kind(tr)
end

-- a spot along the surface it stands on, towards "want": as far as the surface goes. Returns the spot, why it ends
-- there - "goal" (all the way), "edge" (nothing to stand on further on: a body's length short of it), "wall" (a surface
-- rising across the way: the spot just onto it, as its legs would put it) - and what it stands on there
function R.Anchor(b, pos, up, want)
	local d = want - pos
	d = d - up * d:Dot(up)
	local len = d:Length()
	if len < 1 then return Vector(pos), "goal", "map" end
	d:Mul(1 / len)
	local r = b.RepRadius or 18
	local s, last, on = 0, Vector(pos), "map"
	while s < len do
		local s2 = math.min(len, s + 20)
		local q = pos + d * s2
		local w = surf(b, pos + d * s + up * 5, q + up * 5)
		if w.Hit and not w.StartSolid and w.HitNormal:Dot(up) < 0.6 then
			local n = w.HitNormal
			local f = up - n * up:Dot(n)
			f = f:LengthSqr() > 1e-4 and f:GetNormalized() or d
			return w.HitPos + n * 1 + f * (r * 0.7), "wall", kind(w)
		end
		local g = surf(b, q + up * 20, q - up * 26)
		if g.StartSolid then g = surf(b, q + up * 8, q - up * 26) end
		if not (g.Hit and not g.StartSolid and g.HitNormal:Dot(up) > 0.7) then
			return s > r and (pos + d * (s - r)) or Vector(pos), "edge", on
		end
		last, on, s = g.HitPos, kind(g), s2
	end
	return last, "goal", on
end

-- round a corner onto another face, body and all: the face through q with up n, beside the one it is on (up u0). A
-- planned way can begin round a corner from where its body is (sv_surfnav.lua) - it goes round onto it first.
-- Behind that face's plane: an outside corner, it rolls round it; in front of it: an inside one, it tilts into it.
function R.TransitTo(b, pos, u0, q, n)
	local side = (pos - q):Dot(n)
	local f0 = n - u0 * n:Dot(u0)
	if f0:LengthSqr() < 0.01 then return end   -- (the same plane, or one facing the other way: no corner to go round)
	f0:Normalize()
	if side > 0 then f0 = -f0 end
	local t = (q - pos):Dot(n) / f0:Dot(n)
	if t < -20 or t > 60 then return end
	local w = side > 0 and u0 or -u0
	local f1 = w - n * w:Dot(n)
	if f1:LengthSqr() < 0.01 then return end
	f1:Normalize()
	return transit(b, pos, u0, f0, pos + f0 * t, n, f1, side > 0 and "wall ahead" or "round an edge")
end

-- one step: the point to hold the body at, its up and its forward - or nil when there is nothing to hold on to
function R.Walk(b, pos, up, fwd, step, moving, goalPos, dt)
	local now = CurTime()
	-- round a corner, body and all (transit above): on along it while its body keeps up, then its legs again
	local tw = b.Transit
	if tw then
		local p, u, f, j = R.StanceAt(tw.B, tw.s, tw.j)
		local real = b:GetPos()
		-- (on while it has a goal: its goal straight behind the wall it is going up - nothing of it along the wall - is
		-- "not moving" to the steering, and it stood halfway round the corner)
		-- (and given up when its body gets no further for a third of a second - round a building's corner at its roof
		-- it stood against the wall, its body not turning, for seconds: the old way round for that corner then)
		if now - tw.t0 > tw.max or real:DistToSqr(p) > 40 * 40 or (tw.stuckT and now - tw.stuckT > 0.35) then
			if tw.stuckT and now - tw.stuckT > 0.35 then b.TransitFailT = now R.Stat("gave up going round a corner body and all") end
			b.Transit = nil
		else
			if (moving or goalPos) and real:DistToSqr(p) < 22 * 22 and b:GetUp():Dot(u) > 0.7 then
				tw.s = tw.s + (b.RepSpeed or 150) * (b.SpeedMul or 1) * dt
				tw.stuckT = nil
			else
				tw.stuckT = tw.stuckT or now
			end
			if tw.s >= tw.B.len then
				b.Transit = nil
				b.RepWrapT = now
			else
				p, u, f, tw.j = R.StanceAt(tw.B, tw.s, j)
				b.WalkWhy = tw.why
				return p, u, f
			end
		end
	end
	-- over a thin plate (rule 3): on the middle of its top, then - once its body is there - down its far side
	local th = b.ThinOver
	if th then
		if now - th.t > 0.5 then b.ThinOver = nil
		elseif b:GetPos():DistToSqr(th.top) < 10 * 10 then
			b.ThinOver = nil
			b.RepWrapT = now
			b.WalkWhy = "over a thin plate"
			return Vector(th.p), th.n, th.f
		else
			b.WalkWhy = "onto a thin plate's top"
			return Vector(th.top), th.tn, th.tf
		end
	end
	-- over a lip (rule 1 below), in two moves: first out to the lip's front face while still under it, then up onto that
	-- face. Straight at its top in one go - from 40 below, as soon as a feeler touched the lip - the body ran into the
	-- lip's corner on the way, was knocked off the wall and lay across it sideways, 18 off it (the lip test's film: "did
	-- you not see the flip over???")
	local lo = b.LipOver
	if lo then
		-- (and stopped as soon as the body leans off the surface it reaches over from: it is not going as planned)
		if now - lo.t > 0.5 or b:GetUp():Dot(lo.n) < 0.85 then b.LipOver = nil
		else
			if not lo.up2 and (b:GetPos():DistToSqr(lo.out) < 5 * 5 or now - lo.t > 0.25) then lo.up2 = true end
			b.RepWrapT = now
			if lo.up2 then
				if b:GetPos():DistToSqr(lo.top) < 8 * 8 then b.LipOver = nil end
				b.WalkWhy = "over a lip"
				return Vector(lo.top), lo.n, lo.f
			end
			b.WalkWhy = "out under a lip"
			return Vector(lo.out), lo.n, lo.f
		end
	end
	-- its legs on one side of something solid and its body on the other: the legs had gone on over a board's top onto
	-- its far side while the body stuck against the near side, and the rays of its feet - from 32 out, through the board
	-- 16 thick - kept finding the far side, so the legs walked on there for seconds, the body pressed against the near
	-- side, until they came to an edge, let go, and it fell (the sign test). It takes hold again where its body is: on
	-- the surface between them, which faces the other way. (Only when it lasts: rounding a thin slab's two edges its
	-- body lags a moment behind too - and not on a planned way, which leads it round such shapes itself.)
	local at = b.RepAt
	if at and not b.ThinOver and not b.SurfPath and (b:GetPos() - at):Dot(up) < -8 then
		local tr = surf(b, b:WorldSpaceCenter(), at + up * 3)
		if tr.Hit and not tr.StartSolid and tr.Fraction < 0.9 and tr.HitNormal:Dot(up) < -0.3 then
			b.LostT = b.LostT or now
			if now - b.LostT > 0.3 then
				b.LostT = nil
				local nn = tr.HitNormal
				local nf = fwd - nn * fwd:Dot(nn)
				if nf:LengthSqr() < 1e-4 then nf = nn:Angle():Up() end
				b.RepWrapT = now
				b.WalkWhy = "takes hold again"
				R.Stat("took hold again where its body is")
				return tr.HitPos + nn * 1, nn, nf:GetNormalized()
			end
		else
			b.LostT = nil
		end
	else
		b.LostT = nil
	end
	-- a planned way over the shape it sees (sv_surfnav.lua): up walls, along ceilings, round edges
	if R.SurfNav then
		local pt, pu, pf = R.SurfNav.Step(b, pos, up, fwd, goalPos, moving, dt)
		if pt then b.WalkWhy = "planned way" return pt, pu, pf end
	end
	local r = b.RepRadius or 18
	local wd = R.WalkDir(b, pos, up, goalPos)
	if wd then
		step = wd * math.max(step:Length(), (b.RepSpeed or 150) * (b.SpeedMul or 1) * 0.08)
		fwd, moving = wd, true
	end
	local dir = (moving and step:LengthSqr() > 1e-4) and step:GetNormalized() or fwd
	local nxt = pos + step

	-- 1. a surface rising across its way (a wall from the floor, a ceiling from a wall, a lip's underside): onto it.
	-- A curb or a rim it walks over: the surface is not there any more a little higher up. It feels along its way and
	-- also straight towards its goal (pressed against a wall the goal lies behind, its body slid along the wall and the
	-- feeler along the body never touched it).
	if moving then
		local dirs = { dir }
		-- (not towards the goal while it heads for a ceiling's edge: the goal lies behind the wall it came down from, and
		-- that feeler put it straight back onto that wall)
		if goalPos and not (wd and b.WalkDirCeil) then
			local g = goalPos - pos
			g = g - up * g:Dot(up)
			if g:LengthSqr() > 100 then g:Normalize() if g:Dot(dir) < 0.95 then dirs[2] = g end end
		end
		local any = false
		for _, d in ipairs(dirs) do
			local w = surf(b, pos + up * 5 - d * 10, pos + up * 5 + d * (r + 24))
			if not (w.Hit and not w.StartSolid) then w = surf(b, pos + up * 14 - d * 10, pos + up * 14 + d * (r + 24)) end
			if w.Hit and not w.StartSolid and w.HitNormal:Dot(up) < 0.6 then
				any = true
				local hi = surf(b, pos + up * 30 - d * 10, pos + up * 30 + d * (r + 32))
				-- (and a step it can simply step onto - top found 32 up at most - is stepped onto unless its goal lies well
				-- above: at the curb by the map's sign, flush with the sign's face, they climbed the sign instead)
				local n0 = w.HitNormal
				local tp = surf(b, w.HitPos - n0 * 6 + up * 34, w.HitPos - n0 * 6 + up * 1)
				-- (on a floor only - a curb is a floor's thing; on a wall a lip close above counted as a step, its body could
				-- not step out over it and it hung under the lip, the lip test) (always,
				-- whatever its goal: with a goal far above - a roof, a waypoint up a wall - it took a step 6-16 high for a
				-- wall to climb, ran against it and its back end came up. A wall right behind the step it climbs from the
				-- step's top the next moment) (just set level after
				-- hanging upright at this step's edge - stepping onto it failed: up its face like a wall and round its top
				-- edge, however low, the Ha'tak's throne step; agp_replicator.lua)
				local climbStep = b.StepClimbT and now < b.StepClimbT and up.z > 0.7
				local stepUp = up.z > 0.7 and tp.Hit and not tp.StartSolid and tp.HitNormal:Dot(up) > 0.7 and not climbStep
				-- (and not up a wall at all when its goal lies well below: on freespace a slanted wall beside the top of a
				-- 428 drop - it climbed it, slid back, climbed again, for 25 s)
				local goalBelow = goalPos and up.z > 0.7 and (goalPos - pos):Dot(up) < -60
				-- a lip: on a wall (or a ceiling), what blocks the way is the underside of a small overhang - its front face
				-- stands out from the wall by a little. A spider reaches over it straight onto that face. (The lip was
				-- passed till now only because its target ran on ahead of its body after the corner below and pulled it
				-- past - the same run-ahead that shot bugs up walls like rockets and off narrow faces)
				local lipFar = false
				-- (only with its body flat on the surface it is on, on 3 feet at least, and the lip's underside square across
				-- its way: half turned onto another surface - at a wall's foot, eating a gate - it took a floor's edge for a
				-- lip and leaned 56-125 deg off) (and only an overhang
				-- - its underside facing down: on the way down a wall a ledge sticking out below looked the same from above, it
				-- reached out and over it downwards instead of onto its top, and fell)
				if up.z < 0.7 and n0.z < -0.5 and n0:Dot(d) < -0.8 and b:GetUp():Dot(up) > 0.9 and (b.RepHits or 0) >= 3 then
					local q = w.HitPos + d * 8
					local lf = surf(b, q + up * 60, q + up * 2)
					if lf.Hit and not lf.StartSolid and lf.HitNormal:Dot(up) > 0.9 then
						local depth = (lf.HitPos - w.HitPos):Dot(up)
						if depth > 6 and depth < 56 then
							-- (only once its front is at the lip; further below it walks on up the wall towards it - not onto the
							-- lip's underside as onto a wall ahead, where it hung)
							lipFar = true
							if (w.HitPos - pos):Dot(d) < r + 4 then
								local out = pos + up * ((lf.HitPos - pos):Dot(up) + 6)   -- (+3: the body still touched the corner, 15-26 deg tilt)
								b.LipOver = { t = now, out = out, top = lf.HitPos + up * 1 + d * (r * 0.5), n = up, f = d }
								b.RepWrapT = now
								b.WalkWhy = "out under a lip"
								R.Stat("reached over a lip")
								return out, up, d
							end
						end
					end
				end
				if not lipFar and not stepUp and not goalBelow and (hi.Hit or climbStep) then
					local n = w.HitNormal
					local f = up - n * up:Dot(n)
					f = f:LengthSqr() > 1e-4 and f:GetNormalized() or (fwd - n * fwd:Dot(n)):GetNormalized()
					b.RepWrapT = now
					-- it walks into the corner and its body tilts up the wall as its front goes up it (transit): along its
					-- way if that runs into the wall, else straight at it
					local into = -n + up * n:Dot(up)
					if into:LengthSqr() > 1e-4 then
						into:Normalize()
						local f0 = d - up * d:Dot(up)
						f0 = (f0:LengthSqr() > 1e-4 and f0:GetNormalized():Dot(into) > 0.5) and f0:GetNormalized() or into
						local t = (w.HitPos - pos):Dot(n) / f0:Dot(n)
						if t > -4 and t < r + 40 then
							local cp, cu, cf = transit(b, pos, up, f0, pos + f0 * t, n, f, "wall ahead")
							if cp then return cp, cu, cf end
						end
					end
					-- (else as before: the whole body round the corner at once - its feet a body's half length on along the
					-- new surface (at the corner point itself its back half stuck in the surface it left and it jammed there,
					-- flipping), and for that moment not bumping into the world)
					b.WalkWhy = "wall ahead"
					R.Pivot(b)
					return w.HitPos + n * 1 + f * (r * 0.7), n, f
				end
				-- (a wall it does not go up: along it, not into it - pressed into the slanted wall its feet found nothing
				-- and it dropped, 5-15 times each)
				if goalBelow and not stepUp and w.Fraction * (r + 34) < r + 12 then
					local into = step:Dot(n0)
					if into < 0 then step = step - n0 * into nxt = pos + step b.WalkWhy = "along a wall" end
				end
			end
		end
		if not any then b.RepNoWallT = now end
	end

	-- 2. the feet: from above each foot down onto the surface
	local right = fwd:Cross(up)
	right:Normalize()
	local sumN, sumP, hits, front, flatZ = Vector(), Vector(), 0, 0, nil
	local flat = true
	local frontTop   -- (the highest a front foot stands, along its up)
	local pn, pd, plane = nil, nil, true   -- (all feet on one even surface - floor, wall or ceiling: see below)
	local held = {}   -- (which feet stand, by number)
	for i, L in ipairs(LEGS) do
		local o = nxt + fwd * (L[1] * r) + right * (L[2] * r)
		-- (from 32 over the foot: a step or curb up to that height is found and stepped onto - from 20 the ray began
		-- inside a higher curb, found nothing, and the body was pushed back along its edge)
		local tr = surf(b, o + up * 32, o - up * 26)
		-- (under a low overhang 32 up is inside it: from lower down then - on freespace one stood under a slanted wall
		-- leaning over its spot, every ray began in the wall, and it "fell" there again and again)
		if tr.StartSolid then tr = surf(b, o + up * 12, o - up * 26) end
		if tr.Hit and not tr.StartSolid and tr.HitNormal:Dot(up) > 0.3 then
			sumN:Add(tr.HitNormal)
			sumP:Add(tr.HitPos)
			hits = hits + 1
			held[i] = true
			if L[1] > 0 then
				front = front + 1
				local hgt = tr.HitPos:Dot(up)
				if not frontTop or hgt > frontTop then frontTop = hgt end
			end
			if tr.HitNormal.z < 0.98 or (flatZ and math.abs(tr.HitPos.z - flatZ) > 1) then flat = false end
			flatZ = flatZ or tr.HitPos.z
			if not pn then pn, pd = tr.HitNormal, tr.HitPos:Dot(tr.HitNormal)
			elseif tr.HitNormal:Dot(pn) < 0.998 or math.abs(tr.HitPos:Dot(pn) - pd) > 1 then plane = false end
		else
			flat, plane = false, false
		end
	end
	b.RepFlat = (flat and hits == #LEGS and up.z > 0.98) and flatZ or nil
	b.RepHits, b.RepFront = hits, front   -- (for the tests: how many feet hold, how many of them in front)
	-- (the lag: every bug probed with all its legs 66 times a second - a quarter of the server's time with 22 bugs):
	-- all feet on one even surface - the next tick it may walk on along it without probing
	if plane and hits == #LEGS and pn:Dot(up) > 0.995 then b.RepPlane, b.RepPlaneD = pn, pd else b.RepPlane = nil end
	-- standing still with its middle out over an edge (only its front feet on the roof it stopped at): it settles back
	-- onto the feet that hold - turning round from there towards its next goal, no foot held any more and it fell (the
	-- roof scene, 2 runs of 3)
	if not moving and hits > 0 and hits < #LEGS then
		local c = surf(b, pos + up * 20, pos - up * 26)
		if c.StartSolid then c = surf(b, pos + up * 8, pos - up * 26) end
		if not (c.Hit and not c.StartSolid) then
			local d = sumP / hits - pos
			d = d - up * d:Dot(up)
			if d:LengthSqr() > 1 then
				b.WalkWhy = "settles back from an edge"
				return pos + d:GetNormalized() * math.min(2, d:Length()), up, fwd
			end
		end
	end

	-- 3. the front feet find nothing: an outside edge (a roof's edge, a lip, a cap) - round it onto the face beyond
	-- (also when one front foot still stands but the body itself would step out over the edge: walking slantwise past
	-- the side of a narrow roof, one foot kept finding roof and the body slid out into the air)
	local off = false
	if front > 0 and moving and hits < #LEGS then
		local c = surf(b, nxt + up * 20, nxt - up * 26)
		if c.StartSolid then c = surf(b, nxt + up * 8, nxt - up * 26) end
		off = not (c.Hit and not c.StartSolid)
	end
	-- the way on still holds, but its body hangs out past an edge beside it - both feet on one side find nothing, both on
	-- the other side stand: climbing a wall right at its end towards waypoints just beyond it. It looked for a face to go
	-- round onto ahead, up the wall, found none and held there for seconds; one let go and fell (the roof scene, the
	-- end of a wall 17 thick). It steps back in from that side and goes on.
	if off then
		local toward
		if not held[1] and not held[3] and held[2] and held[4] then toward = -right
		elseif held[1] and held[3] and not held[2] and not held[4] then toward = right end
		if toward then
			b.WalkWhy = "back in from a side edge"
			R.Stat("stepped back in from a side edge")
			return pos + step - toward * math.min(0, step:Dot(toward)) + toward * 2, up, fwd
		end
	end
	if (front == 0 or off) and moving and now - (b.RepWrapT or 0) > 0.3 then   -- (not right after a corner: it turns round one at a time)
		-- at a roof's edge with the way going on across a deep gap: wait a moment for a bridge of bodies (ENT:Bridge)
		if up.z > 0.9 and goalPos and not b.Crossing then
			if not b.GapUntil or now > b.GapUntil + 4 then b.GapUntil = b:GapAhead(pos, goalPos) and now + 3 or nil end
			if b.GapUntil and now < b.GapUntil then b.NextGap = 0 b.WalkWhy = "gap wait" return hold(b, pos), up, fwd end
		end
		-- (the face beyond the edge: looked for deeper down and from further out too - under a thick cornice or eaves the
		-- wall is further down than 16 units)
		local edge = pos + dir * (r * 0.6)
		for _, dd in ipairs({ 3, 5, 8, 16, 30, 48 }) do   -- (3 and 5: the top of a thin board - a sign - lies between)
			local e = surf(b, edge - up * dd + dir * 24, edge - up * dd - dir * (r + 20))
			-- (the face beyond the edge faces out the way it walks - the wall it just came up from faces back. Told apart by
			-- where it lay - ahead of the body - the right face was thrown away: when the front feet found nothing the body
			-- was already over the edge and the wall, flush 3 units under it, lay behind it; they walked off the brown roof)
			if e.Hit and not e.StartSolid and e.HitNormal:Dot(up) < 0.6 and e.HitNormal:Dot(dir) > 0.3 then
				local n = e.HitNormal
				local f = -up - n * (-up):Dot(n)
				f = f:LengthSqr() > 1e-4 and f:GetNormalized() or fwd
				-- (over a roof's edge down onto a wall: only if that wall goes on a body length down - a narrow band with
				-- windows or a set-back wall under it held it a moment and it fell, the roof test; going sideways
				-- onto a thin top - a sign's board - is not checked)
				local onward = true
				if f.z < -0.7 and math.abs(n.z) < 0.3 then
					local q = e.HitPos + f * (r + 8)
					local c2 = surf(b, q + n * 20, q - n * 30)
					onward = c2.Hit and not c2.StartSolid and c2.HitNormal:Dot(n) > 0.7
				end
				-- a thin plate (the map's sign: a board 16 thick under a body 36 long): the face beyond the edge is too
				-- narrow to stand on - straight on round its far edge onto the plate's other side. (Rounded onto the
				-- board's top, it could not round the next edge for 0.3 s, stepped off, its legs grabbed the face it had
				-- come up and it ran up that past the top and fell). Only up a wall and over its top: round a thin roof's
				-- edge it would go on under the eaves, and round the side ends of walls it took pillars for plates (the
				-- high edge and the roof got worse, 3 runs).
				local q3 = e.HitPos + f * (r * 1.25)
				local c3 = (math.abs(up.z) < 0.5 and n.z > 0.7) and surf(b, q3 + n * 12, q3 - n * 12) or { Hit = true }
				if not (c3.Hit and not c3.StartSolid) then
					for _, dz in ipairs({ 4, 10, 20 }) do
						local fr = surf(b, e.HitPos + f * (r + 24) - n * dz, e.HitPos - n * dz)
						if fr.Hit and not fr.StartSolid and fr.HitNormal:Dot(f) > 0.7 and fr.HitNormal:Dot(-up) > 0.7 then
							b.RepWrapT = now
							b.WalkWhy = "onto a thin plate's top"
							R.Stat("went over a thin plate")
							-- (onto the middle of its top first, then down its far side: set straight onto the far side,
							-- its body cut through the board's corner and stuck against the near side, the sign test
							-- see "takes hold again" above)
							local mid = e.HitPos + f * math.max(0, (fr.HitPos - e.HitPos):Dot(f) * 0.5) + n * 1
							b.ThinOver = { p = fr.HitPos + fr.HitNormal * 1, n = fr.HitNormal, f = -n, top = mid, tn = n, tf = f, t = now }
							return mid, n, f
						end
					end
				end
				if onward then
					-- (round onto the face it left one corner before, within 1.5 s: it goes round in a circle - see R.WalkDir)
					local h = b.WrapHist
					if h and h.n2 and h.n2:Dot(n) > 0.95 and now - h.t2 < 1.5 then b.CircleT = now + 2 end
					b.WrapHist = { n2 = h and h.n1, t2 = h and h.t1, n1 = n, t1 = now }
					b.RepWrapT, b.WrapFromUp = now, Vector(up)
					-- it rolls over the edge, body and all (transit): the corner where the surface it is on meets that face
					local out = n - up * n:Dot(up)
					if out:LengthSqr() > 1e-4 then
						out:Normalize()
						local p0 = hits > 0 and sumP / hits or pos
						local q = pos - up * (pos - p0):Dot(up)
						local t = (e.HitPos - q):Dot(n) / out:Dot(n)
						if t > -r and t < r + 30 then
							local cp, cu, cf = transit(b, q, up, out, q + out * t, n, f, "round an edge")
							if cp then return cp, cu, cf end
						end
					end
					b.WalkWhy = "round an edge"
					return e.HitPos + n * 1, n, f
				end
			end
		end
		-- no face to go round onto: with only its back feet still on, it walked on until its body hung out in the air and
		-- dropped - over a short drop that is fine (a spider lets itself down: that is how they crossed the narrow gaps),
		-- off a high roof it broke apart, again and again. So: a drop it survives (on the ground), it walks off; a
		-- high one - or off the edge of a wall or a ceiling - it stays at the edge, and the stuck check sends it
		-- another way. ("Survives" is R.LetDown now, a short drop.)
		if hits > 0 then
			local dn = up.z > 0.9 and surf(b, edge + dir * 24, edge + dir * 24 - up * R.LetDown) or nil
			if dn and dn.Hit then b.WalkOffT = now end   -- (it walks off on purpose: "lets itself down" when it goes)
			if not (dn and dn.Hit) then
				if not b.EdgeSaidT or now > b.EdgeSaidT + 5 then b.EdgeSaidT = now R.Dbg(b, "stays at a high edge", tostring(pos), "up", tostring(up)) end
				R.Stat("stayed at a high edge")
				b.WalkWhy = "high edge"
				return hold(b, pos), up, fwd
			end
		end
	end
	-- right after a corner it may not round the next edge - but it did not stop at it either: on its back feet it walked
	-- on out over it until no foot held and fell (over the sign's thin board, turned round on its far face towards a spot
	-- above). It waits at the edge until it may go round it.
	if (front == 0 or off) and moving and hits > 0 and now - (b.RepWrapT or 0) <= 0.3 then
		b.WalkWhy = "waits at an edge"
		return hold(b, pos), up, fwd
	end

	if hits == 0 then
		-- just went round an edge: look a little further before letting go (a rounded rim)
		if now - (b.RepWrapT or 0) < 0.4 then
			local g = surf(b, nxt + up * 30, nxt - up * 60)
			if g.Hit and not g.StartSolid then b.WalkWhy = "rim" return g.HitPos, g.HitNormal, fwd end
		end
		-- the step would take it into the air, but where it stands now still holds it: it stays (only when the ground
		-- under itself is gone does it fall)
		local here = surf(b, pos + up * 20, pos - up * 26)
		if here.StartSolid then here = surf(b, pos + up * 8, pos - up * 26) end
		if here.Hit and not here.StartSolid and here.HitNormal:Dot(up) > 0.3 then
			R.Stat("held at an edge")
			b.WalkWhy = "held at edge"
			return here.HitPos, up, fwd
		end
		-- nothing under any foot - it slid past the side of a pillar or the end of a wall. Before letting go its legs
		-- reach round: from out beside the body, a little below the surface it was on, back towards it - the face it
		-- just slipped past (or one rising beside it). The nearest one it grabs and turns onto - never the underside of
		-- the slab it stood on (it went round under it and then let go from the ceiling: 81 drops in one run) (right
		-- after going round an edge, the surface it came from only when there
		-- is no other: round from a ceiling onto a thin lintel's face no foot held, the legs grabbed the ceiling again, it
		-- waited at the edge, went round again - ceiling, face, ceiling for 20 s under the roof corner's overhang. The
		-- lintel's top is the way on)
		local from = b.WrapFromUp and now - (b.RepWrapT or 0) < 1 and not (R.TestOff and R.TestOff.wrapFrom) and b.WrapFromUp or nil   -- (TestOff: test runs only)
		local best, bd, back, bk
		for a = 0, 315, 45 do
			local rad = math.rad(a)
			local d = fwd * math.cos(rad) + right * math.sin(rad)
			for _, ray in ipairs({ { pos - up * 6 + d * (r + 16), pos - up * 6 - d * 4 }, { pos - up * 16 + d * (r + 8), pos - up * 16 - d * 4 }, { pos + up * 4, pos + up * 4 + d * (r + 16) } }) do
				local tr = surf(b, ray[1], ray[2])
				if tr.Hit and not tr.StartSolid and tr.HitNormal:Dot(up) < 0.9 and tr.HitNormal:Dot(up) > -0.5 then
					local dist = tr.HitPos:DistToSqr(pos)
					if from and tr.HitNormal:Dot(from) > 0.9 then
						if not bk or dist < bk then back, bk = tr, dist end
					elseif not bd or dist < bd then best, bd = tr, dist end
				end
			end
		end
		best = best or back
		if best then
			local n = best.HitNormal
			local f = fwd - n * fwd:Dot(n)
			-- (heading straight at the face it grabbed: on round the edge, away from the surface it slipped off - "up"
			-- sent it back up the face it had come over, past the top and off: the sign test)
			if f:LengthSqr() < 1e-4 then f = -up - n * (-up):Dot(n) end
			if f:LengthSqr() > 1e-4 then
				b.RepWrapT, b.WrapFromUp = now, Vector(up)
				R.Stat("legs reached round an edge")
				b.WalkWhy = "legs reached"
				return best.HitPos + n * 1, n, f:GetNormalized()
			end
		end
		if b.WalkOffT and now - b.WalkOffT < 0.6 then b.RepFallWhy = "lets itself down" return nil end
		-- (up a wall past its top - a planned way that thought the wall went higher, a step that overshot: the wall's top
		-- lies behind and below its body, where none of the rays above look (they run along the wall's face). The building
		-- wall on freespace13: every first climb ended in the air 6 above a lower wall's top and fell 350. Its legs
		-- reach back down onto that top - from a little inside the wall's line, down the way it came - and it goes over it.
		-- Only here, where it would let go)
		do
			for _, depth in ipairs({ 10, 18, 26 }) do
				local s0 = pos - up * depth + fwd * 8
				local tr = surf(b, s0, s0 - fwd * 70)
				if tr.Hit and not tr.StartSolid and tr.HitNormal:Dot(fwd) > 0.7 then
					local n = tr.HitNormal
					local f = -up - n * (-up):Dot(n)
					if f:LengthSqr() > 1e-4 then
						b.RepWrapT, b.WrapFromUp = now, Vector(up)
						R.Stat("legs reached back onto the top it overshot")
						b.WalkWhy = "legs reached (top)"
						return tr.HitPos + n * 1, n, f:GetNormalized()
					end
				end
			end
		end
		b.RepFallWhy = "no surface under its feet (surfnav " .. tostring(b.SurfPath ~= nil) .. ", here " .. tostring(here.Hit) .. "/" .. tostring(here.StartSolid) .. ", moving " .. tostring(moving) .. ", last corner " .. string.format("%.1f", now - (b.RepWrapT or 0)) .. " s ago, step " .. math.Round(step:Length()) .. ")"
		return nil
	end
	local n = sumN / hits
	if n:LengthSqr() < 1e-4 then n = up end   -- (feet on opposite faces: their normals cancel)
	n:Normalize()
	local nu = LerpVector(math.min(1, dt * 14), up, n)
	if nu:LengthSqr() < 1e-2 then nu = Vector(n) end   -- (old and new up almost opposite: no blend through zero)
	nu:Normalize()
	local p = sumP / hits
	-- (where it stands: the feet's middle, on the line under the body)
	local target = nxt - nu * (nxt - p):Dot(nu)
	-- a step up ahead (front feet higher than the middle, on a floor): the body lifted to the front feet's height - held
	-- at the middle, its box ran into the step's edge, could not get over it and tipped up over it, its back end in the
	-- air, for seconds (a step 5 high inside a building on freespace)
	if frontTop and up.z > 0.7 and nu.z > 0.7 then
		local rise = frontTop - p:Dot(up)
		if rise > 0.5 and rise < 34 then target = target + nu * (rise + 1) end
	end
	-- lifted only once its front feet stood on the step, its body's front still ran into the step's edge and scraped up
	-- it. It feels the floor ahead along its way - one and two body radii on - and glides up before it gets there: at two
	-- radii a third of the step's height, at one nearly all of it; over a staircase that is one smooth slope.
	-- (Walls - higher than 34 - as always.)
	if moving and up.z > 0.7 and nu.z > 0.7 and not (R.TestOff and R.TestOff.glide) then
		local base = p:Dot(nu)
		local have = (target - p):Dot(nu)
		local want = 0
		for _, k in ipairs({ 1.0, 1.9 }) do
			local q = nxt + dir * (r * k)
			local tr = surf(b, q + nu * 36, q - nu * 6)
			if tr.Hit and not tr.StartSolid and tr.HitNormal:Dot(nu) > 0.9 then
				local rise = tr.HitPos:Dot(nu) - base
				if rise > 2 and rise < 34 then want = math.max(want, (rise + 1) * math.Clamp(1 - (k - 0.7) / 1.8, 0, 1)) end
			end
		end
		if want > have then target = target + nu * (want - have) R.Stat("glided up towards a step") end
	end
	-- keep forward in the new surface
	local f = fwd - nu * fwd:Dot(nu)
	if f:LengthSqr() < 1e-4 then f = nu:Angle():Up() end
	f:Normalize()
	-- never a broken number into the physics (that crashes the game)
	if target.x ~= target.x or target.y ~= target.y or target.z ~= target.z or nu.x ~= nu.x or f.x ~= f.x then b.WalkWhy = "bad number" return Vector(pos), up, fwd end
	b.WalkWhy = "feet"   -- (which rule placed it: for the test pictures)
	return target, nu, f
end

-- one glide over steps for every walk. The leg walker felt the floor ahead and rose before a step (above); the felt
-- map, the one mover and a planned way did not - they waited till the body had run into the step's face, stalled, and
-- then popped up (sv_mover.lua "up the step"), on props they did not see the step at all. So every walk on a floor
-- goes through this before the body is set: the floor ahead along its way up to 2.6 body radii on - the map and
-- props - and a step up there (2-34) lifts the body before its front gets there: all of it within 1.3 radii, half
-- at 2. A staircase becomes one smooth slope. Every third tick it feels anew (the lift is kept between).
function R.StepGlide(b, p, u, f)
	if not p or not u or u.z < 0.7 or (R.TestOff and (R.TestOff.glide or R.TestOff.glideAll)) then b.GlideAdd = nil return p end
	-- (unseen by every player - behind him, far, a wall between: no feeling ahead,: 1 ms a tick for 50)
	if b.RepUnseen then b.GlideAdd = nil return p end
	local tk = engine.TickCount()
	if b.GlideTick and (tk + b:EntIndex()) % 3 ~= 0 and tk - b.GlideTick < 4 then
		if b.GlideAdd then return p + u * b.GlideAdd end
		return p
	end
	b.GlideTick, b.GlideAdd = tk, nil
	local dir = f - u * f:Dot(u)
	if dir:LengthSqr() < 1e-4 then return p end
	dir:Normalize()
	local filt = function(e) return e ~= b and not e.AGPReplicator and (not R.Walkable or R.Walkable(e)) end
	local fl = util.TraceLine({ start = p + u * 6, endpos = p - u * 40, mask = MASK_PLAYERSOLID, filter = filt })
	if not fl.Hit or fl.StartSolid then return p end
	local base = fl.HitPos:Dot(u)
	local have = p:Dot(u) - base
	local r = b.RepRadius or 18
	local want = 0
	-- (fully up by the time its front - a body radius on - reaches the step, half up 2 radii before: at one and two radii
	-- with a third at most, the front of a body on 24-high steps still hit each nose and the body reared up 94-102 deg,
	-- the stairs test)
	for _, k in ipairs({ 0.7, 1.3, 2.0, 2.6 }) do
		local q = fl.HitPos + dir * (r * k)
		local t = util.TraceLine({ start = q + u * 36, endpos = q - u * 6, mask = MASK_PLAYERSOLID, filter = filt })
		if t.Hit and not t.StartSolid and t.HitNormal:Dot(u) > 0.9 then
			local rise = t.HitPos:Dot(u) - base
			if rise > 2 and rise < 34 then want = math.max(want, (rise + 2) * math.Clamp((2.8 - k) / 1.5, 0, 1)) end
		end
	end
	-- (only for a real step ahead, and never pulling it back up: round a roof's edge the walk puts it under the roof's
	-- plane on its way down - with no step there it was "lifted" back up against that, into the roof; strict high edge
	-- through the wall once each)
	have = math.max(have, 0)
	if want > 0 and want > have + 0.5 then
		b.GlideAdd, b.GlideT = want - have, CurTime()
		R.Stat("glided up towards a step (every walk)")
		return p + u * b.GlideAdd
	end
	return p
end
-- kept level while it walks a floor (the stairs test: on 8-24 high steps bodies whose walk said "upright on the
-- floor" reared up and turned over, 100-166 deg - the body's front caught a step's nose and the bump turned it, the
-- controller could not hold it). After each physics step: going up a step (R.StepGlide found one ahead in the last
-- second - not the leg walker's own glide nor the "up the step" hops, those fired at the high edge's rim too) on a floor,
-- a body more than 25 deg off it is set level again, its spin stopped - pushed against a nose it slides up over it
-- instead of rearing up. Not round corners, on walls, in a jump or a fall, held, aboard - and only at steps: always on,
-- it turned bodies tipping over the high edge (428) into its face, through the wall twice each, strict 0/3 clean
-- against 3/3 without it.
local LEVEL = math.cos(math.rad(25))
hook.Add("Tick", "AGPRepKeepLevel", function()
	for b in pairs(R.bugs or {}) do
		local u = IsValid(b) and b.RepUp
		if u and u.z > 0.7 and b.GlideT and CurTime() - b.GlideT < 1 and not (b.Falling or b.Jumping or b.Boarded or b.Transit or b.PivotOn or b.Clinging or b.InTower or b.InBridge
			or b.GateRide or b.Eating or b.RepGone or (b.RightUntil and CurTime() < b.RightUntil) or (R.TestOff and R.TestOff.keepLevel)) then
			local bu = b:GetUp()
			if bu:Dot(u) < LEVEL then
				local ph = b:GetPhysicsObject()
				if IsValid(ph) and ph:IsMotionEnabled() and not b:IsPlayerHolding() then
					local f = b.RepFwd or b:GetForward()
					f = f - u * f:Dot(u)
					if f:LengthSqr() < 1e-4 then f = b:GetForward() - u * b:GetForward():Dot(u) end
					if f:LengthSqr() > 1e-4 then
						f:Normalize()
						ph:SetAngles(f:AngleEx(u))
						ph:SetAngleVelocity(Vector(0, 0, 0))
						R.Stat("kept level on a floor")
					end
				end
			end
		end
	end
end)