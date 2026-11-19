-- Replicators: seeing the way before going it (owner 2026-11-05: "the idea and goal: knowing the exact shape, a short
-- smooth move round the edge instead of stepping blindly - like a real spider"). When the goal lies up on something,
-- behind a wall or under a lip, the bug looks at the side view of what lies between: the shapes the game hands over
-- (sv_shape.lua) cut by the upright plane through it and its goal, plus a sweep of rays in that plane (a radar for
-- whatever the shapes miss: clip walls, a prop just thrown). In that view a fine grid: solid where a surface runs, free
-- air reached from where the bug is, and the cells of air touching a surface are where its feet can be. The shortest way
-- over those cells to the goal is its path - up a wall, along a ceiling, round an edge - with the surface's own "up" at
-- every point; round an outside edge that "up" turns smoothly about the corner, so it rolls over the edge.
-- The same plan is used by every bug that starts near it for the same goal (the swarm shares what it saw).
-- agp_rep_surfnav 0 turns it off (the leg-ray walker alone, sv_walk.lua).
local R = AGP.Rep
local N = R.SurfNav or {}
R.SurfNav = N
R.cv.surfnav = R.cv.surfnav or CreateConVar("agp_rep_surfnav", "1", FCVAR_ARCHIVE, "Replicators: plan climbs from the shape of the world")
-- (owner 2026-11-07, watching the course: "the bug is running threw your wall" - on rails, its collisions off, the body
-- follows the way's straight lines through outside corners, thin boards and the course's prop walls, 15-38 times a run.
-- Solid instead (planrails 0) it went into walls half as often but looked far worse: tilted off the surface 21-47
-- times a run instead of 0-6, its body flipping 10-32 times instead of 0-1, hanging 9 times on the course - the owner:
-- "it gets worse and worse how they walk on walls". So rails stayed, until the way round corners was done properly.)
-- Done (2026-11-08, its body round corners from one stance, sv_walk.lua R.Stance): solid now went through no wall at
-- all, the sign, the wall and the roof scenes clean (on rails: 18-25 passes, those three unclean) - owner: "go solid".
-- Rails only with agp_rep_solidways 0. (A new name again: server.vdf keeps every archived setting's value, the old
-- agp_rep_planrails 1 would have kept the rails on.)
R.cv.solid = R.cv.solid or CreateConVar("agp_rep_solidways", "1", FCVAR_ARCHIVE, "Replicators: 1 = a bug on a planned way stays solid (it cannot go through walls); 0 = it does not collide with the world on it (the old rails)")

local C = 6   -- grid cell (units)
N.cache = N.cache or {}
local MASKW = MASK_PLAYERSOLID
local function walkable(e) return R.Walkable and R.Walkable(e) end

local function nearestOnSeg(px, py, s)
	local ax, ay, bx, by = s[1], s[2], s[3], s[4]
	local dx, dy = bx - ax, by - ay
	local l = dx * dx + dy * dy
	local t = l > 1e-6 and math.Clamp(((px - ax) * dx + (py - ay) * dy) / l, 0, 1) or 0
	return ax + dx * t, ay + dy * t
end

-- the plan: a list of surface points with their "up" and the distance along, or nil
local function none() return false end
function N.Plan(b, pos, goal, up, fwd, mapOnly)
	local walkable = mapOnly and none or walkable   -- (learning a map: its own shapes only, no props)
	local Z = Vector(0, 0, 1)
	local U = goal - pos U.z = 0
	if U:LengthSqr() < 64 then
		U = Vector(-up.x, -up.y, 0)   -- (the goal straight above: into the wall it is on)
		-- (on the floor right under it - the spot over a door: towards the nearest wall; along its own nose the cut
		-- missed the wall over the door, "no way nearer", and it stood at the foot of it)
		if U:LengthSqr() < 0.04 then
			local bd
			for a = 0, 337.5, 22.5 do
				local d = Angle(0, a, 0):Forward()
				local t = util.TraceLine({ start = pos + Vector(0, 0, 10), endpos = pos + Vector(0, 0, 10) + d * 300, mask = MASK_PLAYERSOLID_BRUSHONLY })
				if t.Hit and not t.StartSolid and math.abs(t.HitNormal.z) < 0.5 and (not bd or t.Fraction < bd) then bd, U = t.Fraction, Vector(d) end
			end
		end
		if U:LengthSqr() < 0.04 then U = Vector(fwd.x, fwd.y, 0) end
	end
	if U:LengthSqr() < 1e-4 then return end
	U:Normalize()
	local gx, gy = (goal - pos):Dot(U), goal.z - pos.z
	local x0, x1 = math.min(0, gx) - 200, math.max(0, gx) + 200
	local y0, y1 = math.min(0, gy) - 160, math.max(0, gy) + 340   -- (room above: a wall with a cap is higher than its goal)
	-- (1200 x 1000 at most: at 1500 x 1200 one plan took up to 95 ms, a hitch in the game; at 900 x 800 a way out of
	-- the pit on gm_flatgrass to its goal beyond was "too far", the pit test failed twice running)
	if x1 - x0 > 1200 or y1 - y0 > 1000 then N.why = "too far" return end
	local NX, NY = math.ceil((x1 - x0) / C), math.ceil((y1 - y0) / C)
	local segs = R.Shape.Slice(pos, U, Z, x0, x1, y0, y1, walkable)
	-- the radar: rays in the plane from the bug and from the goal; what they hit counts as surface too
	local function sweep(o, n)
		local last
		for i = 0, n - 1 do
			local a = i / n * math.pi * 2
			local d = U * math.cos(a) + Z * math.sin(a)
			local tr = util.TraceLine({ start = o, endpos = o + d * 700, mask = MASKW, filter = function(e) return e ~= b and walkable(e) end })
			if tr.Hit and not tr.StartSolid then
				local p = tr.HitPos - pos
				local px, py = p:Dot(U), p:Dot(Z)
				local e = IsValid(tr.Entity) and not tr.Entity:IsWorld() and tr.Entity or nil
				if last and (last[1] - px) ^ 2 + (last[2] - py) ^ 2 < 14 * 14 then segs[#segs + 1] = { last[1], last[2], px, py, e }
				else segs[#segs + 1] = { px, py, px, py, e } end
				last = { px, py }
			else last = nil end
		end
	end
	local rays = R.Shape.Level() == 1 and 12 or 40   -- (scan level 1: a few pings)
	sweep(pos + up * 8, rays)
	sweep(goal + Z * 10, rays)
	-- the grid: solid where a surface runs (each cell remembers which surfaces)
	local wall, wall2 = {}, {}
	for si, s in ipairs(segs) do
		local dx, dy = s[3] - s[1], s[4] - s[2]
		local n = math.max(1, math.ceil(math.sqrt(dx * dx + dy * dy) / (C * 0.3)))
		for k = 0, n do
			local x, y = s[1] + dx * k / n, s[2] + dy * k / n
			local ix, iy = math.floor((x - x0) / C), math.floor((y - y0) / C)
			if ix >= 0 and iy >= 0 and ix < NX and iy < NY then
				local i = ix + iy * NX
				if not wall[i] then wall[i] = si elseif wall[i] ~= si and not wall2[i] then wall2[i] = si end
			end
		end
	end
	local function cell(x, y) return math.floor((x - x0) / C), math.floor((y - y0) / C) end
	local function free(ix, iy) return ix >= 0 and iy >= 0 and ix < NX and iy < NY and not wall[ix + iy * NX] end
	-- the air it is in: from just above its feet
	local sx, sy = cell((up * 10):Dot(U), (up * 10):Dot(Z))
	if not free(sx, sy) then
		local found
		for r = 1, 3 do for dx = -r, r do for dy = -r, r do if not found and free(sx + dx, sy + dy) then found = { sx + dx, sy + dy } end end end end
		if not found then N.why = "no air at its feet" return end
		sx, sy = found[1], found[2]
	end
	local reach = { [sx + sy * NX] = true }
	local q, qh = { sx + sy * NX }, 1
	while qh <= #q do
		local i = q[qh] qh = qh + 1
		local ix, iy = i % NX, math.floor(i / NX)
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local jx, jy = ix + d[1], iy + d[2]
			local j = jx + jy * NX
			if free(jx, jy) and not reach[j] then reach[j] = true q[#q + 1] = j end
		end
		if #q > 120000 then return end
	end
	-- the cells its feet can be on: air touching a surface, with room for its body away from the surface
	local foot = {}
	local function footAt(i)
		local v = foot[i]
		if v ~= nil then return v end
		v = false
		if reach[i] then
			local ix, iy = i % NX, math.floor(i / NX)
			local cx, cy = x0 + (ix + 0.5) * C, y0 + (iy + 0.5) * C
			local bx, by, bd, bs
			for dx = -1, 1 do for dy = -1, 1 do
				local jx, jy = ix + dx, iy + dy
				if jx >= 0 and jy >= 0 and jx < NX and jy < NY then
					local j = jx + jy * NX
					for _, si in ipairs({ wall[j], wall2[j] }) do
						if si then
							local px, py = nearestOnSeg(cx, cy, segs[si])
							local dd = (px - cx) ^ 2 + (py - cy) ^ 2
							if not bd or dd < bd then bx, by, bd, bs = px, py, dd, si end
						end
					end
				end
			end end
			if bd and bd > 1e-4 then
				local l = math.sqrt(bd)
				local ux, uy = (cx - bx) / l, (cy - by) / l
				local ok = true
				for _, k in ipairs({ 2, 3 }) do
					local tx, ty = cell(cx + ux * C * k, cy + uy * C * k)
					if tx >= 0 and ty >= 0 and tx < NX and ty < NY and wall[tx + ty * NX] then ok = false end
				end
				if ok then v = { bx, by, ux, uy, bs } end
			end
		end
		foot[i] = v
		return v
	end
	-- from the foot cell nearest the bug, the shortest way over foot cells to the one nearest the goal
	local function nearestFoot(px, py)
		local cx, cy = cell(px, py)
		for r = 0, 6 do
			local best, bd
			for dx = -r, r do for dy = -r, r do
				if math.max(math.abs(dx), math.abs(dy)) == r then
					local jx, jy = cx + dx, cy + dy
					if jx >= 0 and jy >= 0 and jx < NX and jy < NY and footAt(jx + jy * NX) then
						local dd = dx * dx + dy * dy
						if not bd or dd < bd then best, bd = jx + jy * NX, dd end
					end
				end
			end end
			if best then return best end
		end
	end
	local st = nearestFoot(0, 0)
	if not st then N.why = "no foothold near it" return end
	local prev = { [st] = -1 }
	q, qh = { st }, 1
	local function gdist(i) local ix, iy = i % NX, math.floor(i / NX) return (x0 + (ix + 0.5) * C - gx) ^ 2 + (y0 + (iy + 0.5) * C - gy) ^ 2 end
	local bestI, bestD = st, gdist(st)
	local startD = bestD
	while qh <= #q do
		local i = q[qh] qh = qh + 1
		local d = gdist(i)
		if d < bestD then bestI, bestD = i, d end
		if d < (C * 1.5) ^ 2 then break end
		local ix, iy = i % NX, math.floor(i / NX)
		for dx = -1, 1 do for dy = -1, 1 do
			if dx ~= 0 or dy ~= 0 then
				local jx, jy = ix + dx, iy + dy
				local j = jx + jy * NX
				if jx >= 0 and jy >= 0 and jx < NX and jy < NY and prev[j] == nil and footAt(j)
					and (dx == 0 or dy == 0 or free(ix + dx, iy) or free(ix, iy + dy)) then   -- (not diagonally through a thin wall)
					prev[j] = i q[#q + 1] = j
				end
			end
		end end
	end
	if bestD > startD - 30 * 30 then N.why = string.format("no way nearer (%d foot cells reached)", #q) return end   -- (nowhere nearer the goal over the surfaces it can see)
	local cells = {}
	local i = bestI
	while i ~= -1 do table.insert(cells, 1, i) i = prev[i] end
	-- into the world: the surface point, and its "up" (smoothed over a few cells so it turns, not snaps)
	local P = { pts = {}, ups = {}, d = {}, goal = Vector(goal), U = U }
	local raw = {}
	for k, c in ipairs(cells) do raw[k] = foot[c] if segs[raw[k][5]][5] then P.built = true end end   -- (over a prop somewhere)
	for k = 1, #raw do
		-- (smoothed only with the cells round the same corner point: on a face "up" stays the face's own - turned early,
		-- the body tilted into the wall before the edge and stuck there)
		-- (an inside corner, though - floor to wall - turns over a body's length: the surface point jumps there from face
		-- to face, and its "up" with it)
		local f = raw[k]
		local ux, uy = 0, 0
		local inside = false
		for m = math.max(1, k - 3), math.min(#raw - 1, k + 3) do
			local g, h = raw[m], raw[m + 1]
			if (g[1] - h[1]) ^ 2 + (g[2] - h[2]) ^ 2 > 1 and g[3] * h[3] + g[4] * h[4] < 0.9 then inside = true end
		end
		for m = math.max(1, k - 3), math.min(#raw, k + 3) do
			local g = raw[m]
			if inside or (g[1] - f[1]) ^ 2 + (g[2] - f[2]) ^ 2 < 9 then ux = ux + g[3] uy = uy + g[4] end
		end
		local pt = pos + U * f[1] + Z * f[2]
		local u = U * ux + Z * uy
		if u:LengthSqr() < 1e-4 then u = U * f[3] + Z * f[4] end
		u:Normalize()
		-- (round an outside edge the cells keep one surface point, the corner, while "up" turns: those count too - the
		-- turn takes its time along the path, so it rolls over the edge instead of snapping round)
		local last, lu = P.pts[#P.pts], P.ups[#P.ups]
		local turn = lu and math.acos(math.Clamp(lu:Dot(u), -1, 1)) or 0
		if not last or last:DistToSqr(pt) > 1 or turn > 0.12 then
			P.pts[#P.pts + 1] = pt P.ups[#P.ups + 1] = u
			P.d[#P.d + 1] = last and (P.d[#P.d] + math.max(last:Distance(pt), turn * 10)) or 0
		end
	end
	if #P.pts < 2 then return end
	-- (never through the world: where the shapes missed a floor, the grid's air ran on under it and the way with it -
	-- on rails, its body went into the ground and fell out below the map. Each step a little above the surface must be
	-- free of the map's solid)
	for k = 1, #P.pts do
		local a = P.pts[k] + P.ups[k] * 4
		if bit.band(util.PointContents(a), CONTENTS_SOLID) ~= 0 then N.why = "through the world" return end
		if k > 1 then
			local tr = util.TraceLine({ start = P.pts[k - 1] + P.ups[k - 1] * 4, endpos = a, mask = MASK_SOLID_BRUSHONLY })
			if tr.Hit and not tr.StartSolid then N.why = "through the world" return end
		end
	end
	-- (on a wall the cut crosses aslant, the side view sees the wall's up only as far as it lies in the cut: there it is
	-- always straight across the cut, up to 85 degrees off the wall's own - the high edge's cliff, its faces at 45
	-- degrees to the way. On rails its body followed that up into the wall; solid, it stood tilted against the cliff
	-- for a second and more. Each point on a wall takes the wall's own up: a short look into it)
	local flt = function(e) return e ~= b and walkable(e) end
	for k = 1, #P.pts do
		local u = P.ups[k]
		if math.abs(u.z) < 0.3 then
			local tr = util.TraceLine({ start = P.pts[k] + u * 4, endpos = P.pts[k] - u * 8, mask = MASKW, filter = flt })
			local n = tr.HitNormal
			if tr.Hit and not tr.StartSolid and math.abs(n.z) < 0.3 and n:Dot(u) > 0.02 and tr.HitPos:DistToSqr(P.pts[k]) < 6 * 6 then P.ups[k] = Vector(n) end
		end
	end
	P.len = P.d[#P.d]
	return P
end

-- there? Near the goal is not there when a surface lies between (under a shelf, its goal on top: 40 units away)
function R.Reached(b, pos, goal)
	local up = b.RepUp or Vector(0, 0, 1)
	local tr = util.TraceLine({ start = pos + up * 6, endpos = goal + Vector(0, 0, 6), mask = MASKW, filter = function(e) return e ~= b and walkable(e) end })
	return not tr.Hit or tr.Fraction > 0.97
end

-- does it need a plan: the goal up on something, well below, or something in the way
local function needs(b, pos, up, goal)
	-- (a goal in the air - a launch spot, a target up high - is for jumping, not climbing: no surface near it)
	local fl = util.TraceLine({ start = goal + Vector(0, 0, 8), endpos = goal - Vector(0, 0, 40), mask = MASKW, filter = function(e) return e ~= b and walkable(e) end })
	if not fl.Hit then
		-- (a spot on a wall over a door, on a ceiling: the 3D way goes there - a wall or ceiling right by it)
		if not (N.Graph and R.cv.surf3d:GetBool()) then return false end
		local on = false
		for _, a in ipairs({ Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(0, 0, 1) }) do
			local t = util.TraceLine({ start = goal, endpos = goal + a * 20, mask = MASKW, filter = function(e) return e ~= b and walkable(e) end })
			if t.Hit and not t.StartSolid then on = true break end
		end
		if not on then return false end
		return true
	end
	local dz = goal.z - pos.z
	if dz > 40 or dz < -70 then return true end
	local tr = util.TraceLine({ start = pos + up * 8, endpos = goal + Vector(0, 0, 8), mask = MASKW, filter = function(e) return e ~= b and walkable(e) end })
	return tr.Hit and tr.Fraction < 0.95
end

-- on rails: following a plan whose way is known to be free, its body does not bump into the world (pivoting at an
-- inside corner, floor to wall, its 36-unit body hit the wall with its nose and stayed upright, belly down, sliding up
-- the wall). Off the plan, jumping or falling it is solid again at once (StartFall), and a check every tenth of a second
-- makes sure (never through the floor).
function N.Rails(b, on)
	if on and R.cv.solid:GetBool() then on = false end
	if (b.SurfRails or false) == on then return end
	local ph = b:GetPhysicsObject()
	if not IsValid(ph) then return end
	ph:EnableCollisions(not on)
	b.SurfRails = on or nil
end
-- (and on rails it remembers the last place where it stood in the open: inside the map's solid it goes back there at
-- once, off its plan, solid again - a body made solid inside the ground falls out below the map)
-- (deep in, not just a corner cut: rolling over an edge its body cuts the corner by a few units - that is how it goes
-- round. Deep in for two looks running)
local function inWorld(e)
	local p, u = e:GetPos(), e.RepUp or Vector(0, 0, 1)
	return bit.band(util.PointContents(p + u * 4), CONTENTS_SOLID) ~= 0 and bit.band(util.PointContents(p + u * 12), CONTENTS_SOLID) ~= 0
end
N.InWorld = inWorld
timer.Create("AGPRepRails", 0.1, 0, function()
	local now = CurTime()
	for e in pairs(R.bugs or {}) do
		if IsValid(e) and e.SurfRails then
			local deep = inWorld(e)
			e.SurfDeep = deep and (e.SurfDeep or 0) + 1 or 0
			if e.SurfDeep >= 2 then
				e.SurfDeep = 0
				e.SurfPath, e.SurfPlanT = nil, now + 2
				N.Rails(e, false)
				if e.SurfSafe then e:SetPos(e.SurfSafe) local ph = e:GetPhysicsObject() if IsValid(ph) then ph:SetVelocity(vector_origin) end end
				N.rescues = (N.rescues or 0) + 1
				R.Dbg(e, "path dropped:", "in the ground: back to where it was")
			elseif not deep then
				e.SurfSafe = e:GetPos()
				if not e.SurfPath or e.Falling or e.Boarded or e.Clinging or now - (e.SurfStepT or 0) > 0.2 then N.Rails(e, false) end
			end
		end
	end
end)

N.drops = N.drops or {}
function N.Drop(b, why)
	N.drops[why] = (N.drops[why] or 0) + 1
	R.Dbg(b, "path dropped:", why)
end

-- the swarm remembers its climbs (owner 2026-11-05: "the swarm memory is gold... really saved... pretrain a lot of maps
-- ... differ from map and player built things, so no player built thing is saved unless it's 3 times"). A way that took
-- a bug to its goal is kept: over the map's own shapes at once, over props (a player's build, which may be gone
-- tomorrow) only once it worked there 3 times. Kept per map in data/agp_replicators/<map>_climbs.txt. A bug starting
-- near a known start for a known goal goes that way without planning - after a look that every few points the surface
-- is still under it (a wall knocked down, a crate moved: forgotten, planned anew).
N.known = N.known or {}
local KQ = 48
local floor = math.floor
local function qk(p) return floor(p.x / KQ) .. ":" .. floor(p.y / KQ) .. ":" .. floor(p.z / KQ) end
-- its body's way along a plan free of the world and props, all the way (not only at its points): a way kept from
-- another shape went straight through the course's wall, the whole way along the floor - a capped wall and a low wall
-- with the same start and goal, its points every 50 units, each of them on the floor (2026-11-08: 9 of 9 passes
-- through walls on the course were that). Worked out once per plan, for kept ways when they are recalled (a fresh plan
-- is made from the shape it goes over - checked too, good ones over the course's low wall were thrown away and the bug
-- stood at its foot)
function N.Clear(plan)
	if plan.clear ~= nil then return plan.clear end
	local B = N.Body(plan, {})
	local ok = B ~= nil
	if B then
		local flt = function(e) return walkable(e) end
		for k = 1, #B.pts - 1 do
			local tr = util.TraceLine({ start = B.pts[k] + B.ups[k] * 8, endpos = B.pts[k + 1] + B.ups[k + 1] * 8, mask = MASKW, filter = flt })
			if tr.Hit and not tr.StartSolid then
				ok = false
				N.clearWhy = string.format("%s at %d of %d, %.0f along, normal %s", IsValid(tr.Entity) and tr.Entity:GetModel() or "the world", k, #B.pts, B.d[k], tostring(tr.HitNormal))
				break
			end
		end
	end
	plan.clear = ok
	return ok
end
-- a fresh way over real surfaces? (owner 2026-11-18, freespace13: "crawling up in the air as if there was a pillar but
-- there was none" - every first climb at the building was a way 340 straight up through the air in front of it, then
-- the fall. Ways are made of surface points, so each point mid-face must have its surface under it. Checked once, when
-- the way is taken - nothing while walking, so no jump, gap or bridge can be taken for air. Points where the way turns
-- round an edge are left out (there a ray can graze past the corner), and only 2 misses in a row count)
function N.OnSurfaces(plan)
	local pts, ups, miss = plan.pts, plan.ups, 0
	for k = 2, #pts - 1, 2 do
		local u = ups[k]
		if ups[k - 1]:Dot(u) > 0.99 and ups[k + 1]:Dot(u) > 0.99 then
			local p = pts[k]
			local tr = util.TraceLine({ start = p + u * 10, endpos = p - u * 14, mask = MASKW, filter = function(e) return walkable(e) end })
			if tr.Hit then miss = 0 else
				miss = miss + 1
				if miss >= 2 then return false, p end
			end
		end
	end
	return true
end
local function still(plan)
	for k = 1, #plan.pts, 4 do
		local p, u = plan.pts[k], plan.ups[k]
		if bit.band(util.PointContents(p + u * 4), CONTENTS_SOLID) ~= 0 then return false end
		local tr = util.TraceLine({ start = p + u * 10, endpos = p - u * 10, mask = MASKW, filter = function(e) return walkable(e) end })
		if not tr.Hit or tr.StartSolid then return false end
	end
	plan.clear = nil   -- (the world may have changed since)
	return N.Clear(plan)
end
-- a known way from (near) pos to (near) goal, checked; or nil
function N.Recall(pos, goal)
	local gk = qk(goal)
	local cx, cy, cz = floor(pos.x / KQ), floor(pos.y / KQ), floor(pos.z / KQ)
	for dx = -1, 1 do for dy = -1, 1 do for dz = -1, 1 do
		local key = (cx + dx) .. ":" .. (cy + dy) .. ":" .. (cz + dz) .. ">" .. gk
		local r = N.known[key]
		if r and r.plan.pts[1]:DistToSqr(pos) < 40 * 40 and r.plan.goal:DistToSqr(goal) < KQ * KQ then
			if not r.checkedT or CurTime() - r.checkedT > 20 then
				if not still(r.plan) then N.known[key] = nil N.forgot = (N.forgot or 0) + 1 return end
				r.checkedT = CurTime()
			end
			return r.plan, r
		end
	end end end
end
-- slow ways (owner 2026-11-05: "more like ways they get slowed down a lot" - only Dakara, the ARG and a kawoosh
-- really kill them; a fall only costs the ~16 s to build itself again): a bug that falls apart within 8 s of being on
-- a way, or one that took more than three times as long as walking it should, counts a slow trip for it (from about
-- there to about that goal). After 2 that way is not planned any more and a kept one is forgotten - the gap is left
-- to the bridge builders, a jump, another way. Forgotten again after 10 minutes (the bridge may be gone, the map
-- changed). Saved with the climbs. (Killed for good - the ARG, Dakara - is not the way's fault: not counted.)
N.slow = N.slow or {}
N.slowT = N.slowT or {}
local function dk(p, g) return floor(p.x / 128) .. ":" .. floor(p.y / 128) .. ":" .. floor(p.z / 128) .. ">" .. floor(g.x / 128) .. ":" .. floor(g.y / 128) .. ":" .. floor(g.z / 128) end   -- (coarse: the swarm learns, not each bug)
local function slowTrip(b, k, why)
	N.slow[k] = (N.slow[k] or 0) + 1
	N.slowT[k] = CurTime()
	if N.slow[k] >= 2 and b.SurfKnownKey then N.known[b.SurfKnownKey] = nil end
	R.Stat("slow ways learned")
	R.Dbg(b, "this way was slow (" .. why .. "):", N.slow[k], "times")
end
function N.Fell(b, dead)
	local k = b.SurfWayKey
	if dead or not k or CurTime() - (b.SurfWayT or 0) > 8 then return end
	slowTrip(b, k, "fell")
end
function N.Slow(pos, goal)
	local k = dk(pos, goal)
	if (N.slow[k] or 0) < 2 then return false end
	if CurTime() - (N.slowT[k] or CurTime()) > 600 then N.slow[k], N.slowT[k] = nil, nil return false end
	N.slowT[k] = N.slowT[k] or CurTime()
	return true
end

-- it got there that way (or the map was learned that way): keep it
function N.Remember(plan, learned)
	local key = qk(plan.pts[1]) .. ">" .. qk(plan.goal)
	local r = N.known[key]
	if r then r.n = r.n + 1 r.t = os.time() if not learned then r.walked = true end
	else
		r = { plan = plan, n = 1, t = os.time(), built = plan.built or nil, walked = not learned or nil }
		N.known[key] = r
		N.knownCount = (N.knownCount or 0) + 1
	end
	return r
end
local function fileName() return "agp_replicators/" .. game.GetMap():lower():gsub("[^%w_]", "_") .. "_climbs.txt" end
local function v3(v) return { math.Round(v.x, 1), math.Round(v.y, 1), math.Round(v.z, 1) } end
local function uv(t) return Vector(t[1], t[2], t[3]) end
-- (a player's build only once it worked there 3 times; the most used and newest first when there are too many)
function N.SaveRoutes()
	local list = {}
	for key, r in pairs(N.known) do if not r.built or r.n >= 3 then list[#list + 1] = { key = key, r = r } end end
	table.sort(list, function(a, b) return a.r.n * 1e10 + a.r.t > b.r.n * 1e10 + b.r.t end)
	local out = { v = 1, routes = {}, slow = N.slow }
	for i = 1, math.min(#list, 3000) do
		local r = list[i].r
		local pts, ups = {}, {}
		for k = 1, #r.plan.pts do pts[k] = v3(r.plan.pts[k]) ups[k] = v3(r.plan.ups[k]) end
		out.routes[#out.routes + 1] = { k = list[i].key, n = r.n, t = r.t, b = r.built and 1 or nil, w = r.walked and 1 or nil, g = v3(r.plan.goal), p = pts, u = ups, d = r.plan.d }
	end
	file.CreateDir("agp_replicators")
	file.Write(fileName(), util.TableToJSON(out))
	return #out.routes
end
function N.LoadRoutes()
	N.known, N.knownCount = {}, 0
	local t = util.JSONToTable(file.Read(fileName(), "DATA") or "")
	if not t or not t.routes then return 0 end
	N.slow = t.slow or t.danger or {} N.slowT = {}
	for _, s in ipairs(t.routes) do
		local plan = { pts = {}, ups = {}, d = s.d, goal = uv(s.g) }
		for k = 1, #s.p do plan.pts[k] = uv(s.p[k]) plan.ups[k] = uv(s.u[k]) end
		plan.len, plan.built = plan.d[#plan.d], s.b == 1 or nil
		N.known[s.k] = { plan = plan, n = s.n, t = s.t, built = plan.built, walked = s.w == 1 or nil }
		N.knownCount = N.knownCount + 1
	end
	return N.knownCount
end
hook.Add("InitPostEntity", "AGPRepRoutesLoad", function() N.LoadRoutes() end)
hook.Add("ShutDown", "AGPRepRoutesSave", function() N.SaveRoutes() end)
timer.Create("AGPRepRoutesSave", 300, 0, function() if (N.knownCount or 0) > 0 then N.SaveRoutes() end end)

-- learning a map before anyone plays it ("pretrain"): agp_rep_learnmap [how many]. Goals on the tops of the map's own
-- ledges, walls and boxes, starts on the floor below and around them; each climb planned over the map's shapes alone
-- (one a tick, in the background) and kept when a way was found. Then saved.
function N.Learn(want, done)
	local S = R.Shape
	if not S.built or S.map ~= game.GetMap() or S.level ~= S.Level() then S.Build() end
	local tops = {}
	local function take(p) if p.k ~= "clip" then local v = p.v local n = (v[2] - v[1]):Cross(v[3] - v[1]) if n:LengthSqr() > 1e-6 and n:GetNormalized().z > 0.7 and p.mx.x - p.mn.x > 24 and p.mx.y - p.mn.y > 24 then tops[#tops + 1] = p end end end
	for _, c in pairs(S.cells) do for _, p in ipairs(c) do take(p) end end
	local L = { tried = 0, found = 0, want = want or 200, t0 = SysTime() }
	N.learning = L
	if #tops == 0 then if done then done(L) end return L end
	local seen = {}
	local G = N.Graph and R.cv.surf3d:GetBool() and N.Graph
	timer.Create("AGPRepLearn", 0, 0, function()
		-- (in 3D a way can take longer than a tick to find: worked on a few milliseconds a tick)
		if L.co then
			G.deadline = SysTime() + 0.012   -- (learning is done before play: more of the tick)
			local ok, plan, why = coroutine.resume(L.co)
			G.deadline = nil
			if not ok or coroutine.status(L.co) == "dead" then
				if ok and plan and not plan.built and not plan.partial and plan.pts[#plan.pts]:DistToSqr(L.goal) < 48 * 48 then N.Remember(plan, true) L.found = L.found + 1
				else
					why = not ok and "error" or not plan and tostring(why):gsub("%(.*", "") or plan.built and "over props" or plan.partial and "not all the way" or "ends short"
					L.whys = L.whys or {} L.whys[why] = (L.whys[why] or 0) + 1
				end
				L.co = nil
			end
			return
		end
		for _ = 1, 3 do   -- (a few tries a tick: most are thrown away before planning)
			if L.found >= L.want or L.tried >= L.want * 20 then
				timer.Remove("AGPRepLearn")
				L.saved = N.SaveRoutes()
				L.ms = (SysTime() - L.t0) * 1000
				N.learning = nil
				if done then done(L) end
				return
			end
			L.tried = L.tried + 1
			local p = tops[math.random(#tops)]
			if not seen[p] or seen[p] < 3 then
				seen[p] = (seen[p] or 0) + 1
				-- a point on the top (a corner of it, pulled a little in), the goal just above it
				local v = p.v
				local c = Vector(0, 0, 0) for _, q in ipairs(v) do c = c + q end c = c / #v
				local goal = LerpVector(math.Rand(0.3, 0.8), c, v[math.random(#v)])
				local g = util.TraceLine({ start = goal + Vector(0, 0, 40), endpos = goal - Vector(0, 0, 8), mask = MASK_SOLID_BRUSHONLY })
				if g.Hit and not g.StartSolid and g.HitNormal.z > 0.7 then
					goal = g.HitPos
					-- a start: out to one side, down to the floor below (60 to 500 lower)
					local dir = Angle(0, math.Rand(0, 360), 0):Forward()
					local a = goal + dir * math.Rand(80, 260) + Vector(0, 0, 20)
					local fl = util.TraceLine({ start = a, endpos = a - Vector(0, 0, 600), mask = MASK_SOLID_BRUSHONLY })
					local dz = goal.z - fl.HitPos.z
					if fl.Hit and not fl.StartSolid and fl.HitNormal.z > 0.7 and dz > 60 and dz < 500 and not N.Recall(fl.HitPos, goal) then
						if G then
							local from, to = fl.HitPos, goal
							L.goal, L.co = to, coroutine.create(function() return G.Plan(from, Vector(0, 0, 1), to) end)
							return
						end
						local plan = N.Plan({}, fl.HitPos, goal, Vector(0, 0, 1), dir, true)
						if plan and plan.pts[#plan.pts]:DistToSqr(goal) < 48 * 48 then N.Remember(plan, true) L.found = L.found + 1 end
						return   -- (one plan a tick)
					end
				end
			end
		end
	end)
	return L
end
concommand.Add("agp_rep_learnmap", function(p, _, args)
	if IsValid(p) and not p:IsSuperAdmin() then return end
	local n = tonumber(args[1]) or 200
	print("[AGP] Replicators: learning " .. game.GetMap() .. " (" .. n .. " climbs)...")
	N.Learn(n, function(L) print(string.format("[AGP] Replicators: learned %d climbs (%d tried) in %.1f s, %d known ways saved", L.found, L.tried, (L.ms or 0) / 1000, L.saved or 0)) end)
end)

-- its body all along a plan (R.Stance, sv_walk.lua): worked out once per plan and body size (a small one is half as long)
function N.Body(plan, b)
	local L = math.Round((b.RepRadius or 18) * 1.1, 1)
	plan.body = plan.body or {}
	local B = plan.body[L]
	if B == nil then
		B = R.Stance and R.Stance(plan.pts, plan.ups, L, 3) or false
		plan.body[L] = B
	end
	return B or nil
end

local function planKey(pos, goal) return math.floor(pos.x / 32) .. ":" .. math.floor(pos.y / 32) .. ":" .. math.floor(pos.z / 32) .. ">" .. math.floor(goal.x / 48) .. ":" .. math.floor(goal.y / 48) .. ":" .. math.floor(goal.z / 48) end

-- one step along the path, or a new plan; nil: the leg-ray walker goes on as before
function N.Step(b, pos, up, fwd, goal, moving, dt)
	if not R.cv.surfnav:GetBool() then return end
	local now = CurTime()
	-- (its real goal - the steering's detour point in front of it moves all the time and threw every plan away)
	goal = b.MoveTo or goal
	local P = b.SurfPath
	-- (a goal that moves a little - the swarm's gathering point - keeps the plan while it moves less than a quarter of the
	-- way: at the bottom of a gap the climbs were thrown away 40 times and none was finished)
	local moved = P and goal and goal:DistToSqr(P.goal) > math.max(60, 0.25 * pos:Distance(P.goal)) ^ 2
	-- (the goal moved further, but not far - the swarm's gathering point: it goes on along the old way while the new one is
	-- worked out in the background, and takes the new one when it is ready. Thrown away at once, it was left to its legs
	-- alone for that time - 50 times in the bridge test - and walked up the wall and off the roof's edge)
	if moved and N.Graph and R.cv.surf3d:GetBool() and goal:DistToSqr(P.goal) < 400 * 400 and not (b.Crossing or b.BridgeJob or b.InBridge or b.InTower) then
		local key = planKey(pos, goal)
		local c = N.cache[key]
		local fresh = c and now - c.t < 10
		if fresh and c.p then N.drops["new way for the moved goal"] = (N.drops["new way for the moved goal"] or 0) + 1   -- (dropped below; the new one is taken from the cache)
		elseif not fresh then
			if now > (b.SurfReqT or 0) then b.SurfReqT = now + 0.5 N.Graph.Request(key, pos, up, goal) end
			moved = false
		end
	end
	if P and (not goal or moved or b.Crossing or b.BridgeJob or b.InBridge or b.InTower) then
		-- (its brain called it there a body's length before the plan's last point: that way worked too)
		local L = P.plan
		if not P.kept and not goal and L.pts[#L.pts]:DistToSqr(P.goal) < 48 * 48 and pos:DistToSqr(L.pts[#L.pts]) < 60 * 60 then P.kept = true local r = N.Remember(L) R.Dbg(b, "remembers the way", r.n, r.built and "(over props)" or "") end
		P = nil b.SurfPath = nil b.SurfPlanT = 0 N.Drop(b, goal and "goal moved" or "no goal") end   -- (plans anew at once, from where it is)
	if not P then
		-- (why it goes on its legs alone, for the debug log: once a second)
		local function no(why) if now > (b.SurfNoT or 0) then b.SurfNoT = now + 1 R.Dbg(b, "no planned way:", why) end end
		if not goal or b.Crossing or b.BridgeJob or b.InBridge or b.InTower or now < (b.SurfPlanT or 0) then return end
		-- (after a player or an NPC it goes as before: it jumps at them and climbs up them - that takes touching them)
		local t = b.Target
		if IsValid(t) and (t:IsPlayer() or t:IsNPC()) then return end
		if goal:DistToSqr(pos) > 1400 * 1400 then no("too far") return end
		if not needs(b, pos, up, goal) then no("not needed") return end
		if b.SurfShort and now < b.SurfShortT and b.SurfShort:DistToSqr(goal) < 48 * 48 then no("the last one ended short") return end
		if N.Slow(pos, goal) then b.SurfPlanT = now + 3 no("that way was slow") return end   -- (that way was slow: other ways - a bridge, a jump)
		-- (a way it knows: no planning, and not one of the swarm's one plan a tick)
		local known = N.Recall(pos, goal)
		if known then N.reused = (N.reused or 0) + 1 R.Dbg(b, "knows the way:", #known.pts, "points") end
		if not known and N.tick == engine.TickCount() then return end   -- (one plan a tick for the whole swarm)
		b.SurfPlanT = now + 1.5
		local key = planKey(pos, goal)
		local c = N.cache[key]
		local fresh = c and now - c.t < 10
		local plan = known
		if not plan and fresh and (c.p or c.d2 or not N.Graph or not R.cv.surf3d:GetBool()) then plan = c.p
		elseif not plan then
			-- (first the way over the 3D map of surfaces, in the background - sv_surfgraph.lua; the side view when that
			-- found nothing)
			if N.Graph and R.cv.surf3d:GetBool() and not (fresh and c.d3) then
				N.Graph.Request(key, pos, up, goal)
				-- (meanwhile the side view, at once: a whole way in it - up a crate, a plain wall - is taken, and the 3D
				-- job is dropped. Waiting for the 3D one, a bug beside a crate was up it on its legs alone before its way
				-- was ready. A side view that only gets nearer is not taken: that was the bug under its goal)
				N.side = N.side or {}
				if not N.side[key] or now - N.side[key] > 10 then
					N.side[key] = now
					N.tick = engine.TickCount()
					local p2 = N.Plan(b, pos, goal, up, fwd)
					N.plans = (N.plans or 0) + 1
					if p2 and p2.pts[#p2.pts]:DistToSqr(goal) < 48 * 48 then
						plan = p2
						N.cache[key] = { p = p2, t = now, d2 = true }
					end
				end
				if not plan then
					b.SurfPlanT = now + 0.25
					no("3D way being worked out")
					return
				end
			end
		end
		if plan == nil then   -- (the side view: 3D is off, or found nothing here)
			N.tick = engine.TickCount()
			local t0 = SysTime()
			plan = N.Plan(b, pos, goal, up, fwd)
			N.lastMs = (SysTime() - t0) * 1000
			N.cache[key] = { p = plan or false, t = now, d2 = true, d3 = fresh and c.d3 or nil }
			N.plans = (N.plans or 0) + 1
		end
		if not plan then b.SurfPlanT = now + 2.5 N.fails = (N.fails or 0) + 1 R.Dbg(b, "no plan", N.why) return end
		local B = N.Body(plan, b)
		if not B then b.SurfPlanT = now + 2.5 N.Drop(b, "no way for its body") return end
		-- (owner 2026-11-14: an open incoming gate's horizon kills - and its ring is climbable, its foot walkable: no planned
		-- way may run through the dead zone round it; the rephorz test saw bugs follow such ways across the horizon)
		-- (only steps that go INTO it count: a bug on the ring of a gate that turned inbound may leave by any way out)
		if R.DeadStep and #R.deadGates > 0 then
			local prev = pos
			for _, q in ipairs(plan.pts) do
				if R.DeadStep(prev, q, 20) then b.SurfPlanT = now + 2.5 N.Drop(b, "the way runs through an incoming gate") return end
				prev = q
			end
		end
		if not plan.surfOk then
			local ok, at = N.OnSurfaces(plan)
			if not ok then
				b.SurfPlanT = now + 2.5
				if known and N.known then for k2, r in pairs(N.known) do if r.plan == plan then N.known[k2] = nil end end end
				R.Dbg(b, "way over nothing at", tostring(at))
				N.Drop(b, "the way runs over nothing") return
			end
			plan.surfOk = true
		end
		P = { plan = plan, s = 0, goal = plan.goal, t0 = now }
		b.SurfWayKey, b.SurfKnownKey = dk(pos, goal), qk(plan.pts[1]) .. ">" .. qk(plan.goal)
		-- (start where on its body's way it is nearest)
		local bd, bk
		for k, p in ipairs(B.pts) do local dd = p:DistToSqr(pos) if not bd or dd < bd then bd, bk, P.s = dd, k, B.d[k] end end
		-- (and only from the face its body is on: at a corner of two walls - the high edge's cliff - the way it saw began
		-- on the other one, round the corner; solid, its body could not get there and stood tilted against the corner for
		-- a second and more. It goes round onto that face first, body and all (sv_walk.lua), and takes the way from
		-- there. Left to its legs instead, it fell off the cliff three times in a run)
		if b:GetUp():Dot(B.ups[bk]) < 0.7 then
			b.SurfPlanT = now + 0.1
			local cp, cu, cf
			if R.TransitTo then cp, cu, cf = R.TransitTo(b, pos, up, B.pts[bk], B.ups[bk]) end
			if cp then N.Drop(b, "begins round a corner: goes round first") return cp, cu, cf end
			b.SurfPlanT = now + 0.5 N.Drop(b, "begins on another face") return
		end
		b.SurfPath = P
		b.SurfUp = Vector(up)
		R.Dbg(b, "plan:", #plan.pts, "points", math.Round(plan.len), "long", plan.three and "(3D)" or "(side view)")
		if plan.three then N.used3 = (N.used3 or 0) + 1 else N.used2 = (N.used2 or 0) + 1 end
		if b.DumpPlan then   -- (the tests: the plan, every 3rd point relative to the spot given)
			local o = b.DumpPlan b.DumpPlan = nil
			local g = plan.goal - o
			print("AGP_RESULT", "INFO", "plan dump", "goal", string.format("%.0f %.0f %.0f", g.x, g.y, g.z), "from", tostring(pos - o), #plan.pts .. " points")
			for k2 = 1, #plan.pts, 3 do local q, u = plan.pts[k2] - o, plan.ups[k2] print("AGP_RESULT", "INFO", "plan dump", k2, string.format("%.0f %.0f %.0f", q.x, q.y, q.z), string.format("up %.2f %.2f %.2f", u.x, u.y, u.z), string.format("d %.0f", plan.d[k2])) end
			for k2 = 1, #B.pts, 2 do local q, u, f = B.pts[k2] - o, B.ups[k2], B.fw[k2] print("AGP_RESULT", "INFO", "body dump", k2, string.format("%.0f %.0f %.0f", q.x, q.y, q.z), string.format("up %.2f %.2f %.2f", u.x, u.y, u.z), string.format("fw %.2f %.2f %.2f", f.x, f.y, f.z), string.format("d %.0f", B.d[k2])) end
		end
	end
	local L = P.plan
	-- its body along the way (R.Stance, sv_walk.lua: where its back and front are on the surface, the line between them its
	-- body's, lifted over edges) - place and tilt from one thing, so round a corner it neither tilts into the wall before it
	-- gets there nor climbs on upright after it
	local B = N.Body(L, b)
	if not B then b.SurfPath = nil b.SurfPlanT = now + 2 N.Drop(b, "no way for its body") return end
	local function at(s) return R.StanceAt(B, s, P.j) end
	local tp, tu = at(P.s)
	if R.DeadStep and #R.deadGates > 0 and R.DeadStep(pos, tp, 20) then b.SurfPath = nil b.SurfPlanT = now + 2.5 N.Drop(b, "the way runs through an incoming gate") return end   -- (a gate opened on its way)
	if pos:DistToSqr(tp) > 70 * 70 then b.SurfPath = nil b.SurfPlanT = now + 1 N.Drop(b, "off the path") return end   -- (knocked off it)
	-- (and on only while its body has turned with the way, within 45 degrees: over a thin board's top the way ran on
	-- round it while the body lagged, and the body went straight for it - through the board's top. Not for ever: a body
	-- that cannot turn goes on after 0.4 s)
	local turned = b:GetUp():Dot(tu) > 0.7
	if turned then P.lagT = nil else P.lagT = P.lagT or now end
	if moving and pos:DistToSqr(tp + (b.SurfUp or up) * (P.lift or 0)) < 22 * 22 and (turned or now - P.lagT > 0.4) then
		P.s = P.s + (b.RepSpeed or 150) * (b.SpeedMul or 1) * dt
		b.LastPos, b.LastMoveT = pos, now   -- (going along its way is moving, however slowly it gets anywhere)
		P.lift = math.max(0, (P.lift or 0) - dt * 20)
	elseif moving then
		P.lift = math.min(10, (P.lift or 0) + dt * 20)   -- (held up by an edge: a little off the surface, over it)
	end
	-- (no skipping ahead round a lip or an inside corner any more - its body goes over a small lip and into a corner on the
	-- way itself: the head glitch at the top of gm_flatgrass's platform, owner 2026-11-06, and "sliding on the back on the
	-- wall", owner 2026-11-07, were the tilt and the place worked out apart)
	if P.s >= B.len then
		-- at the goal: it stays there (it does not wander on over the edge) until it has a new goal
		-- (near the goal but on the far side of the surface - under the slab the goal stands on - is not at the goal: it
		-- ends short, and goes round the edge with its legs (R.EdgeAim); it hung there for good, owner 2026-11-18)
		if L.pts[#L.pts]:DistToSqr(P.goal) < 48 * 48 and not ((P.goal - L.pts[#L.pts]):Dot(L.ups[#L.ups]) < -4 and R.Reached and not R.Reached(b, pos, P.goal)) then
			P.s = B.len
			if not P.kept and pos:DistToSqr(L.pts[#L.pts]) < 40 * 40 then
				P.kept = true
				-- (much slower than walking it should be: stuck, knocked off, waiting - a slow way)
				if now - P.t0 > 3 * L.len / ((b.RepSpeed or 150) * (b.SpeedMul or 1)) + 6 and b.SurfWayKey then slowTrip(b, b.SurfWayKey, "took " .. math.Round(now - P.t0) .. " s") end
				local r = N.Remember(L) R.Dbg(b, "remembers the way", r.n, r.built and "(over props)" or "")
			end
		else   -- (the way it saw ends short of the goal: the other ways - a jump, the steering - get their turn for a while)
			b.SurfPath = nil b.SurfPlanT = now + 4 b.SurfShort, b.SurfShortT = Vector(P.goal), now + 8
			N.Drop(b, "at the end") return
		end
	end
	local target, nup, f, j = at(P.s)
	P.j = j
	b.SurfUp = nup
	if target.x ~= target.x or nup.x ~= nup.x or f.x ~= f.x then b.SurfPath = nil N.Drop(b, "bad number") return end
	b.RepFlat, b.RepPlane = nil, nil
	-- (the last bit to its goal solid again: a gate's event horizon, food, a door it waits at - all need touching)
	N.Rails(b, pos:DistToSqr(P.goal) > 90 * 90)
	b.SurfStepT = now
	b.SurfWayT = now
	if P.lift and P.lift > 0 then target = target + nup * P.lift end
	return target, nup, f
end
