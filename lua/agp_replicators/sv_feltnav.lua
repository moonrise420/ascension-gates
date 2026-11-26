-- Replicators: the way across the map on the felt map ("we know that they can climb the pillars"). The cell way
-- (sv_nav.lua) cuts the map into boxes of 48: a beam 15 thick next to them is nothing to
-- hold on to (the probe at freespace13's tower of concrete beams: air from the ground to the platform, 60 s of
-- searching for nothing), a ramp or a roof 6-16 thick has its top and its underside in the same box (the bug hung under
-- the car park's ramp and under a house's roof with its goal on top). Here the way is worked out where the bug's body
-- really goes: on the felt map's level (sv_field.lua, H off every surface - beams, plates, walls, both sides of each
-- kept apart). From a point of the level it steps 24 along the level in 8 directions, each landing found on the level
-- again (round an outside edge it bends round with it, up a beam, onto a wall); a step is a way only if the level runs
-- on between the two (no jump from under a plate to its top, no step through the air). A* over those points: floors
-- cost least, walls more, ceilings most. Used first (sv_nav.lua plan); when it finds nothing the cell way still gets its
-- turn. Waypoints as the cell way's.
local R = AGP.Rep
local N = R.FeltNav or {}
R.FeltNav = N

local S = 24            -- a step along the level
local MAXN = 40000      -- points looked at for one way at most
local JUMP = 10         -- the level between two steps' ends may lie at most this far from their middle
local floor, sqrt, cos, sin, abs = math.floor, math.sqrt, math.cos, math.sin, math.abs

local function key(p) return (floor(p.x / S) + 2048) + (floor(p.y / S) + 2048) * 4096 + (floor(p.z / S) + 2048) * 16777216 end

-- what a step onto a point of the level costs per unit: its up says floor, wall or ceiling
local function weight(m)
	if m.z > 0.7 then return 1 end
	if m.z < -0.5 then return (R.NavCost and R.NavCost[2]) or 1.8 end
	return (R.NavCost and R.NavCost[1]) or 1.25
end

-- the 8 directions along the level at a point with up m
local DIRS = {}
for a = 0, 7 do DIRS[#DIRS + 1] = { cos(a * math.pi / 4), sin(a * math.pi / 4) } end
local function tangents(m)
	local t1 = (abs(m.z) < 0.9) and Vector(0, 0, 1):Cross(m) or Vector(1, 0, 0):Cross(m)
	t1:Normalize()
	local t2 = m:Cross(t1)
	return t1, t2
end

local function yieldIfDue(F)
	local V = R.Nav
	if V and V.deadline and SysTime() > V.deadline then
		F.force = nil
		coroutine.yield()
		F.force = true
	end
end

-- the way from a bug's place to a goal (in the cell way's coroutine): waypoints, or nil and why
function N.Plan(from, goal)
	local F = R.Field
	if not (F and F.Onto and F.H) then return nil, "no felt map" end
	local H = F.H
	F.force = true
	local sp, sm = F.Onto(from)
	local gp, gm = F.Onto(goal)
	if not sp then F.force = nil return nil, "start not on the level" end
	if not gp then F.force = nil return nil, "goal not on the level" end
	local sk, gk = key(sp), key(gp)
	-- (points looked at at most, by the distance: a goal near by that it cannot reach is given up soon and the cell way
	-- has its turn - at gm_construct's lip 40 000 points took the whole 25 s of the test)
	local maxn = math.Clamp(math.floor(sp:Distance(gp) / S * 150), 3000, MAXN)
	local nodes = { [sk] = { p = sp, m = sm } }
	local gc, came, done = { [sk] = 0 }, {}, {}
	local hk, hf, hn = { sk }, { 0 }, 1
	local function push(k, v)
		hn = hn + 1
		local i = hn
		while i > 1 do
			local q = floor(i / 2)
			if hf[q] <= v then break end
			hk[i], hf[i] = hk[q], hf[q]
			i = q
		end
		hk[i], hf[i] = k, v
	end
	local function pop()
		local k = hk[1]
		local lk, lv = hk[hn], hf[hn]
		hk[hn], hf[hn] = nil, nil
		hn = hn - 1
		if hn > 0 then
			local i = 1
			while true do
				local c = i * 2
				if c > hn then break end
				if c < hn and hf[c + 1] < hf[c] then c = c + 1 end
				if hf[c] >= lv then break end
				hk[i], hf[i] = hk[c], hf[c]
				i = c
			end
			hk[i], hf[i] = lk, lv
		end
		return k
	end
	local n, found = 0, nil
	while hn > 0 do
		local cur = pop()
		if not done[cur] then
			done[cur] = true
			local nd = nodes[cur]
			if cur == gk or nd.p:DistToSqr(gp) < 30 * 30 then found = cur break end
			n = n + 1
			if n > maxn then F.force = nil return nil, "too far (" .. n .. " points)" end
			local t1, t2 = tangents(nd.m)
			for _, d in ipairs(DIRS) do
				yieldIfDue(F)
				local dir = t1 * d[1] + t2 * d[2]
				local q, qm = F.Onto(nd.p + dir * S)
				if q then
					local k = key(q)
					if k ~= cur and not done[k] then
						local len = q:Distance(nd.p)
						-- (the level runs on between them: its point nearest the middle lies near the middle)
						local ok = len > 4 and len < S * 1.8
						if ok then
							local mid = (nd.p + q) * 0.5
							local mp = F.Onto(mid)
							ok = mp and mp:DistToSqr(mid) < JUMP * JUMP
						end
						-- (and nothing of the map straight between them: past a thin wall's end the level of its two faces met and the
						-- way went through the wall - a bug inside freespace13's building stood 24 s at it, its next waypoint behind
						-- the wall, the way asked anew gave the same. Only from one face to one turned the other way: round a shelf's edge the
						-- line grazed the corner and the course's shelf fell from 5 of 6 to 3 of 9)
						if ok and nd.m:Dot(qm) < -0.3 and not (R.TestOff and R.TestOff.feltThru) and util.TraceLine({ start = nd.p, endpos = q, mask = MASK_PLAYERSOLID_BRUSHONLY }).Hit then ok = false N.thru = (N.thru or 0) + 1 end
						if ok then
							local cost = gc[cur] + len * weight(qm)
							if not gc[k] or cost < gc[k] then
								gc[k], came[k] = cost, cur
								nodes[k] = { p = q, m = qm }
								push(k, cost + q:Distance(gp) * 2)   -- (greedy towards the goal: at 1.3 the way from a player's building to the tower looked at 14 000 points, 15 s)
							end
						end
					end
				end
			end
		end
	end
	F.force = nil
	if not found then return nil, "no way (" .. n .. " points)" end
	-- the points of the way, from the start; a waypoint every 3rd one and where its up turns, on the surface (3 off it)
	local list, k = {}, found
	while k do table.insert(list, 1, nodes[k]) k = came[k] end
	-- (round a sharp edge one at every step: over a window's sill, an 8 thick wall's top, the waypoint after the sill was
	-- already on the outside face below it - 11 away straight through the wall, the felt walk went that way down the
	-- inside face and stood there 25 s, random round seed 57771 and its probe. Only round an outside edge: one at
	-- every step of an inside corner too - a wall's foot - kept it on the wall there, tilted 1.4 s, 0/3 clean down
	-- the strict high edge)
	local function outside(a, b) return a.m:Dot(b.m) < 0.95 and (b.p - a.p):Dot(a.m) < -1 end
	local w, last, fm = {}, nil, {}
	for i = 2, #list do
		local nd = list[i]
		local turn = last and nd.m:Dot(last.m) < 0.9
		local bend = outside(list[i - 1], nd) or (list[i + 1] and outside(nd, list[i + 1]))
		if i % 3 == 0 or turn or bend or i == #list then
			w[#w + 1] = nd.p - nd.m * (H - 3)
			-- (the face each waypoint lies on, its up: the walk at a seam - a ceiling's crease, a sill - knows which face its
			-- next waypoint is on instead of guessing, sv_ceiling.lua)
			fm[#w] = Vector(nd.m)
			last = nd
		end
	end
	w[#w + 1] = Vector(goal)
	w.felt = true
	w.m = fm
	R.Stat("felt way found")
	return w, n .. " points (felt)"
end
