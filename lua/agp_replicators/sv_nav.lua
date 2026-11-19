-- Replicators: the way across the whole map (owner 2026-11-06: "we have the map data - each bug only needs to know where
-- it is"; and the lesson of the Antwork game: a fixed way-finding layer under the brain, the legs only for the next
-- steps). The ways they had were the ones they once walked (sv_map.lua) and short climbs seen from the side
-- (sv_surfnav.lua): on a map new to them they found no way out of a building to a ship above it, none round a
-- building, none down a drop behind a wall.
-- The map as cells of 48 units, worked out where a way is asked for, and kept:
--  * room for a bug: nothing solid at the cell's middle;
--  * something to hold on to: a surface within 40 of the middle, straight down (a floor), up (a ceiling) or to a side
--    (a wall) - six short rays;
--  * which of its 26 neighbours it reaches: both cells hold-on cells, nothing solid between their middles.
-- A way is A* over those cells - over floors, up walls, along ceilings, through windows and doors, round buildings.
-- Open air between two roofs is no way (a gap: a bridge or a jump, ENT:Bridge). Floors cost least, walls more,
-- ceilings most (a spider walks the floor when it can). The way becomes the bug's waypoints (self.Route), each set on
-- the surface it runs along; its legs (sv_walk.lua) and the short-range planner (sv_surfnav.lua) do the rest.
-- Bounded: number arrays per block of 16 x 16 x 16 cells, at most MAXB blocks (the least used dropped), worked out a
-- couple of milliseconds a tick for the whole swarm, one way shared by every bug with the same start and end cell.
-- agp_rep_nav: 1 on, 0 off (only the ways they walked).
local R = AGP.Rep
local V = R.Nav or {}
R.Nav = V
R.cv.nav = R.cv.nav or CreateConVar("agp_rep_nav", "1", FCVAR_ARCHIVE, "Replicators: find ways across the whole map (1) or only use the ways they walked (0)")

local C = 48          -- a cell
local B = 16          -- cells along a block's side
local MAXB = 160      -- blocks kept while ways are worked out as needed (with the live area scan: LIVEB)
local REACH = 40      -- a surface this near the middle is something to hold on to
local GAP = 26        -- a slot between two walls narrower than this has no room for a bug
local MAXX = 20000    -- cells looked at for one way at most (6000: from the ground floor of a 6-storey building on freespace13 to its roof no way was found, "too far", 14 times in a run - they walked straight at the roof into the ceiling; owner 2026-11-16. Worked out in slices of BUDGET a tick, so more is only slower, not more lag)
local BUDGET = 0.002  -- seconds a tick for all the ways being worked out
local MASK = MASK_PLAYERSOLID_BRUSHONLY
local floor, band, bor, sqrt, lshift = math.floor, bit.band, bit.bor, math.sqrt, bit.lshift
-- the live area scan (below): blocks read round the Replicators are kept, up to LIVEB
local LIVEB = 600        -- blocks kept with the live scan (~64 KB each in memory; open air almost nothing)
local LIVET = 0.001      -- seconds a tick for it, only while no way is being worked out
local SAVET = 600        -- seconds between saves while it learns something new (and when the map ends)
R.cv.navscan = R.cv.navscan or CreateConVar("agp_rep_navscan", "1", FCVAR_ARCHIVE, "Replicators: live area scan (1) or only as ways are needed (0)")

V.blocks = V.blocks or {}
V.nblocks = V.nblocks or 0
V.clock = V.clock or 0
V.routes = V.routes or {}
V.jobs = V.jobs or {}
V.order = V.order or {}

-- the 26 neighbours: offsets and length
local NB = {}
for dx = -1, 1 do for dy = -1, 1 do for dz = -1, 1 do
	if dx ~= 0 or dy ~= 0 or dz ~= 0 then NB[#NB + 1] = { dx, dy, dz, sqrt(dx * dx + dy * dy + dz * dz) * C } end
end end end
-- the six rays for something to hold on to: direction and what it is (1 floor, 2 ceiling, 4 wall)
local AX = { { Vector(0, 0, -1), 1 }, { Vector(0, 0, 1), 2 }, { Vector(1, 0, 0), 4 }, { Vector(-1, 0, 0), 4 }, { Vector(0, 1, 0), 4 }, { Vector(0, -1, 0), 4 } }

local function cellKey(cx, cy, cz) return (cx + 512) + (cy + 512) * 1024 + (cz + 512) * 1048576 end
local function centre(cx, cy, cz) return Vector((cx + 0.5) * C, (cy + 0.5) * C, (cz + 0.5) * C) end
local function cellOf(p) return floor(p.x / C), floor(p.y / C), floor(p.z / C) end

-- the block a cell is in (made when first needed; the least used one goes when there are too many) and the cell's
-- place in it
local function block(cx, cy, cz)
	local bx, by, bz = floor(cx / B), floor(cy / B), floor(cz / B)
	local k = (bx + 64) + (by + 64) * 128 + (bz + 64) * 16384
	local b = V.blocks[k]
	if not b then
		if V.nblocks >= (R.cv.navscan:GetBool() and LIVEB or MAXB) then
			local oldK, oldU
			for kk, bb in pairs(V.blocks) do if not oldU or bb.used < oldU then oldK, oldU = kk, bb.used end end
			V.blocks[oldK] = nil
			V.nblocks = V.nblocks - 1
		end
		b = { st = {}, lq = {}, lm = {}, used = V.clock }
		V.blocks[k] = b
		V.nblocks = V.nblocks + 1
	end
	b.used = V.clock
	return b, (cx - bx * B) + (cy - by * B) * B + (cz - bz * B) * B * B + 1
end

-- a cell: -1 no room, 0 room but nothing to hold on to, above 0 what it holds on to (1 floor, 2 ceiling, 4 wall)
local function state(cx, cy, cz)
	local b, i = block(cx, cy, cz)
	if b.air then return 0 end   -- (a block of open air: the live scan below)
	local s = b.st[i]
	if s then return s end
	local c = centre(cx, cy, cz)
	if band(util.PointContents(c), MASK) ~= 0 then s = -1
	else
		s = 0
		local fr = {}
		for k, a in ipairs(AX) do
			local t = util.TraceLine({ start = c, endpos = c + a[1] * REACH, mask = MASK })
			if t.Hit and not t.StartSolid then s = bor(s, a[2]) fr[k] = t.Fraction end
		end
		-- a slot between two walls narrower than a bug: no room (its middle was free, so a way led up a gap 11 wide
		-- between a building and the next wall on freespace13 - the bug jammed in it, flipping from one wall to the other
		-- for seconds; repfs13, the roof corner, 2026-11-17)
		if (fr[3] and fr[4] and (fr[3] + fr[4]) * REACH < GAP) or (fr[5] and fr[6] and (fr[5] + fr[6]) * REACH < GAP) then s = -1 end
		V.cells = (V.cells or 0) + 1
	end
	b.st[i] = s
	return s
end
V.State = function(p) return state(cellOf(p)) end

-- from one hold-on cell to its neighbour d: both hold on, nothing solid between their middles (and for a diagonal step
-- the straight steps beside it free as well: no cutting a corner through the world)
local function link(cx, cy, cz, d)
	local b, i = block(cx, cy, cz)
	local m = lshift(1, d - 1)   -- (each cell's 26 links: which are known, which are open - two numbers, not a table each)
	local q = b.lq[i] or 0
	if band(q, m) ~= 0 then return band(b.lm[i] or 0, m) ~= 0 end
	local n = NB[d]
	local ok = false
	if state(cx + n[1], cy + n[2], cz + n[3]) > 0 then
		local t = util.TraceLine({ start = centre(cx, cy, cz), endpos = centre(cx + n[1], cy + n[2], cz + n[3]), mask = MASK })
		ok = not t.Hit
		if ok and (n[1] ~= 0 and 1 or 0) + (n[2] ~= 0 and 1 or 0) + (n[3] ~= 0 and 1 or 0) > 1 then
			-- (a diagonal: at least one way round the corner through the straight neighbours has room. Where another side
			-- is solid, the way gets a waypoint in the free corner cell - waypoints() below: out of a window first, then
			-- up; up a wall first, then over a roof's edge. Every side free, tried 2026-11-16 for the owner's window
			-- wobble on freespace13, let no way over any roof's edge: the cell beside the edge holds on to nothing)
			local any = false
			for _, s2 in ipairs({ { n[1], 0, 0 }, { 0, n[2], 0 }, { 0, 0, n[3] } }) do
				if (s2[1] ~= 0 or s2[2] ~= 0 or s2[3] ~= 0) and state(cx + s2[1], cy + s2[2], cz + s2[3]) >= 0 then any = true break end
			end
			ok = any
		end
	end
	b.lq[i] = bor(q, m)
	if ok then b.lm[i] = bor(b.lm[i] or 0, m) end
	return ok
end

-- what a step onto a cell costs: a floor least, a wall more, only a ceiling most
-- (R.NavCost: { wall, ceiling } - tried against each other in the tests, owner 2026-11-17: from inside a building to
-- its roof up the outside wall, not under every floor's ceiling)
R.NavCost = R.NavCost or { 1.25, 1.8 }
local function weight(s)
	if band(s, 1) ~= 0 then return 1 end
	if band(s, 4) ~= 0 then return R.NavCost[1] end
	return R.NavCost[2]
end

-- a cell of air beside one of the players' frozen props (within REACH of it): something to hold on to as well - the
-- plan's cells read only the map; without this a wall of props was in the way but nothing to climb, and the way went
-- round its far end instead of over it (repcourse c3 on gm_construct, 2026-11-16). Filled in below (propsTick).
local propHold = function() return false end

-- the hold-on cell nearest a point (its own, else one of the 26 round it)
local function nearHold(p)
	local cx, cy, cz = cellOf(p)
	if state(cx, cy, cz) > 0 or propHold(cx, cy, cz) then return cx, cy, cz end
	local best, bd
	for _, n in ipairs(NB) do
		local x, y, z = cx + n[1], cy + n[2], cz + n[3]
		if state(x, y, z) > 0 or propHold(x, y, z) then
			local d = centre(x, y, z):DistToSqr(p)
			if not bd or d < bd then best, bd = { x, y, z }, d end
		end
	end
	if best then return best[1], best[2], best[3] end
end

-- a waypoint on the surface a cell holds on to (the nearest of its rays' hits), else its middle
local function onSurface(cx, cy, cz)
	local c = centre(cx, cy, cz)
	local best, bd
	for _, a in ipairs(AX) do
		local t = util.TraceLine({ start = c, endpos = c + a[1] * REACH, mask = MASK })
		if t.Hit and not t.StartSolid and (not bd or t.Fraction < bd) then best, bd = t.HitPos + t.HitNormal * 3, t.Fraction end
	end
	return best or c
end

-- the players' builds in the plan (owner 2026-11-16: "if its player prop it will eat the door or wall away ... if its
-- somehow protected it will search for some other way"): the cells read only the map (brushes); frozen props of the
-- players are put on top of them, looked at every PROPT s. A step through one is a step through it only if it can be
-- eaten (R.Edible: metal, the eat setting), and costs EATCOST more - a short way round is still taken first; one that
-- cannot be eaten (wood, a protected part) is no way at all - the way goes round it. The bug eats it when it gets there
-- (agp_replicator.lua, Route.eats).
local PROPT = 2
local EATCOST = 10 * C
local PROPCELLS = 6000   -- cells one prop may cover at most (bigger ones are left out, as before)
V.pcell, V.psig, V.propsN = V.pcell or {}, V.psig or {}, V.propsN or 0
R.cv.navprops = R.cv.navprops or CreateConVar("agp_rep_navprops", "1", FCVAR_ARCHIVE, "Replicators: their ways know the players' frozen props - through what they can eat, round what they cannot (1), or not (0)")
local function propOk(e)
	if e:CreatedByMap() or e.AGPReplicator or IsValid(e.AGPShip) or IsValid(e:GetParent()) or e:GetSolid() == SOLID_NONE then return false end
	local cg = e:GetCollisionGroup()
	if cg == COLLISION_GROUP_DEBRIS or cg == COLLISION_GROUP_DEBRIS_TRIGGER or cg == COLLISION_GROUP_WORLD or cg == COLLISION_GROUP_IN_VEHICLE or cg == COLLISION_GROUP_PASSABLE_DOOR then return false end
	local ph = e:GetPhysicsObject()
	return IsValid(ph) and not ph:IsMotionEnabled() and e:BoundingRadius() > 24
end
local nextProps = 0
local function propsTick()
	local now = CurTime()
	if now < nextProps then return end
	nextProps = now + PROPT
	if not R.cv.navprops:GetBool() then
		if next(V.psig) ~= nil then V.pcell, V.psig, V.propsN = {}, {}, 0 V.routes = {} end
		return
	end
	local sig, n, changed = {}, 0, false
	for _, e in ipairs(ents.FindByClass("prop_physics")) do
		if propOk(e) then
			local p, a = e:GetPos(), e:GetAngles()
			local v = floor(p.x) .. " " .. floor(p.y) .. " " .. floor(p.z) .. " " .. floor(a.p) .. " " .. floor(a.y) .. " " .. floor(a.r)
			sig[e] = v
			n = n + 1
			if V.psig[e] ~= v then changed = true end
		end
	end
	if not changed then for e in pairs(V.psig) do if not sig[e] then changed = true break end end end
	if not changed then return end
	local pc = {}
	for e in pairs(sig) do
		local lo, hi = e:WorldSpaceAABB()
		local x0, y0, z0 = cellOf(lo - Vector(REACH, REACH, REACH))   -- (the cells it crosses and those within reach of it)
		local x1, y1, z1 = cellOf(hi + Vector(REACH, REACH, REACH))
		if (x1 - x0 + 1) * (y1 - y0 + 1) * (z1 - z0 + 1) <= PROPCELLS then
			for x = x0, x1 do for y = y0, y1 do for z = z0, z1 do
				local k = cellKey(x, y, z)
				local l = pc[k]
				if not l then l = {} pc[k] = l end
				l[e] = true
			end end end
		end
	end
	V.pcell, V.psig, V.propsN = pc, sig, n
	V.routes = {}   -- (the ways known so far may run through what is new, or round what is gone)
	V.cand = {}
end
propHold = function(x, y, z)
	local l = V.pcell[cellKey(x, y, z)]
	if not l or state(x, y, z) ~= 0 then return false end
	local c = centre(x, y, z)
	for e in pairs(l) do
		if IsValid(e) and e:NearestPoint(c):DistToSqr(c) < REACH * REACH then return true end
	end
	return false
end
local function hitIn(l, a, d)
	if not l then return nil end
	for e in pairs(l) do
		if IsValid(e) and util.IntersectRayWithOBB(a, d, e:GetPos(), e:GetAngles(), e:OBBMins(), e:OBBMaxs()) then return e end
	end
end
-- the player's build part a step from point a to point b runs into (nil: none)
local function propOnFrom(a, b, ck, k)
	local la, lb = V.pcell[ck], V.pcell[k]
	if not la and not lb then return nil end
	local d = b - a
	return hitIn(la, a, d) or hitIn(lb, a, d)
end
-- where a bug stands on the props in a cell, seen from each of the cell's six sides: a cell's middle can be behind a
-- thin plate while the bug is on its front - the step past a lip 12 out (the upper wall's bottom) then ran through the
-- plate from middle to middle, and the way went round the wall's far end; replip on gm_construct, 2026-11-18. p: the
-- waypoint (SOFF off the face), w: the point steps are checked from (SWAY off: a bug reaches out over a lip)
local SOFF, SWAY = 8, 16
V.cand = V.cand or {}
local function standPoints(x, y, z, k)
	local l = V.pcell[k]
	if not l then return nil end
	local cs = V.cand[k]
	if cs then return cs end
	cs = {}
	local c = centre(x, y, z)
	for _, a in ipairs(AX) do
		local st, d = c - a[1] * (C * 0.5), a[1] * (C + SWAY)
		local bh, bn, bf
		for e in pairs(l) do
			if IsValid(e) then
				local h, n, f = util.IntersectRayWithOBB(st, d, e:GetPos(), e:GetAngles(), e:OBBMins(), e:OBBMaxs())
				if h and f and f > 0 and (not bf or f < bf) then bh, bn, bf = h, n, f end
			end
		end
		if bh and band(util.PointContents(bh + bn * SOFF), MASK) == 0 then cs[#cs + 1] = { p = bh + bn * SOFF, w = bh + bn * SWAY } end
	end
	V.cand[k] = cs
	return cs
end

-- A* from cell to cell (in a coroutine: it gives way when the tick's time is used up)
local function search(s, g)
	local sk, gk = cellKey(s[1], s[2], s[3]), cellKey(g[1], g[2], g[3])
	local pos, gc, came = { [sk] = s }, { [sk] = 0 }, {}
	local done, eat = {}, {}   -- (eat: the player's build part a cell is reached through)
	local hk, hf, hn = { sk }, { 0 }, 1
	local function push(k, v)
		hn = hn + 1
		local i = hn
		while i > 1 do
			local p = floor(i / 2)
			if hf[p] <= v then break end
			hk[i], hf[i] = hk[p], hf[p]
			i = p
		end
		hk[i], hf[i] = k, v
	end
	local function pop()
		local k, v = hk[1], hf[1]
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
		return k, v
	end
	local n = 0
	while hn > 0 do
		local cur = pop()
		if not done[cur] then
			done[cur] = true
			if cur == gk then
				local path, eats, k = {}, {}, gk
				while k do
					table.insert(path, 1, pos[k])
					if eat[k] then table.insert(eats, 1, eat[k]) end
					k = came[k]
				end
				return path, n, eats
			end
			n = n + 1
			if n > MAXX then return nil, n end
			local c = pos[cur]
			for d, o in ipairs(NB) do
				-- (its time checked at every neighbour: a cell new to it costs up to 8 rays - checked only every 8 cells,
				-- one tick took 44 ms)
				if V.deadline and SysTime() > V.deadline then coroutine.yield() end
				local x, y, z = c[1] + o[1], c[2] + o[2], c[3] + o[3]
				local k = cellKey(x, y, z)
				local through = nil
				local ok = not done[k] and link(c[1], c[2], c[3], d)
				-- (onto a cell that holds on to a player's prop: nothing of the map between the two middles)
				if not ok and not done[k] and V.pcell[k] and propHold(x, y, z) then
					ok = not util.TraceLine({ start = centre(c[1], c[2], c[3]), endpos = centre(x, y, z), mask = MASK }).Hit
				end
				local sp = nil
				if ok then
					local a = c.w or centre(c[1], c[2], c[3])   -- (from where the bug is in this cell: on a prop's face, else its middle)
					through = propOnFrom(a, centre(x, y, z), cur, k)
					if not through and c.w and util.TraceLine({ start = a, endpos = centre(x, y, z), mask = MASK }).Hit then through = false end
					-- (in the way of the middle, or a cell that holds on to a prop only - its middle is in the air up to 40 off the
					-- prop, and the bug stood on the floor under such a waypoint for seconds, then went off another way and fell
					-- off the edge; replip 2026-11-18, owner watching: onto a face of the next cell's props instead, the side it
					-- comes from)
					if through ~= nil or state(x, y, z) == 0 then
						local best, bd
						for _, s2 in ipairs(standPoints(x, y, z, k) or {}) do
							local dd = s2.w:DistToSqr(a)
							if (not bd or dd < bd) and not propOnFrom(a, s2.w, cur, k) and not util.TraceLine({ start = a, endpos = s2.w, mask = MASK }).Hit then best, bd = s2, dd end
						end
						if best then through, sp = nil, best end
					end
					if through and not R.Edible(through) then through = false end
				else through = false end
				if through ~= false then
					local st = state(x, y, z)
					local cost = gc[cur] + o[4] * weight(st > 0 and st or 4) + (through and EATCOST or 0)   -- (beside a prop: as on a wall)
					if not gc[k] or cost < gc[k] then
						gc[k], came[k], pos[k] = cost, cur, { x, y, z, w = sp and sp.w, p = sp and sp.p }
						eat[k] = through
						local h = sqrt((x - g[1]) ^ 2 + (y - g[2]) ^ 2 + (z - g[3]) ^ 2) * C
						push(k, cost + h * 2)   -- (greedy towards the goal: at 1.3 a way 400 up took 7 s to work out)
					end
				end
			end
		end
	end
	return nil, n
end

-- the cells of a way as the bug's waypoints: one where the way turns or changes what it holds on to, at most every 2
-- cells, each on its surface; the last one the goal itself. (Every 4 cells, up to 190 apart, the straight line from one
-- to the next ran through the wall above a window or a door the way went through - out of a building's ground floor to
-- its roof they wobbled under the ceiling there for a minute, owner 2026-11-16 on freespace13; a bug goes on to the next
-- waypoint only when it sees it, agp_replicator.lua)
-- the free corner cell of a diagonal step that cuts past something solid (nil: nothing solid beside it); one that
-- holds on to something before one in the air
local function corner(a, dx, dy, dz)
	local free, cut = nil, false
	for _, s2 in ipairs({ { dx, 0, 0 }, { 0, dy, 0 }, { 0, 0, dz } }) do
		if s2[1] ~= 0 or s2[2] ~= 0 or s2[3] ~= 0 then
			local x, y, z = a[1] + s2[1], a[2] + s2[2], a[3] + s2[3]
			local st = state(x, y, z)
			if st < 0 then cut = true
			elseif not free or (st > 0 and free[4] == 0) then free = { x, y, z, st } end
		end
	end
	if not (cut and free) then return nil end
	return free[4] > 0 and onSurface(free[1], free[2], free[3]) or centre(free[1], free[2], free[3])
end

local function waypoints(path, goal)
	local out = {}
	local lastI, lastD, lastS = 1, nil, nil
	for i = 2, #path do
		local a, b = path[i - 1], path[i]
		local dx, dy, dz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
		local d = dx .. dy .. dz
		local s = state(b[1], b[2], b[3])
		if i < #path and ((lastD and d ~= lastD) or (lastS and s ~= lastS) or i - lastI >= 2) then
			out[#out + 1] = a.p or onSurface(a[1], a[2], a[3])
			lastI = i - 1
		end
		-- a diagonal step past something solid: first into the free corner cell (a waypoint there), then on
		local cut = (dx ~= 0 and 1 or 0) + (dy ~= 0 and 1 or 0) + (dz ~= 0 and 1 or 0) > 1 and corner(a, dx, dy, dz)
		if cut then
			if lastI ~= i - 1 then out[#out + 1] = a.p or onSurface(a[1], a[2], a[3]) end
			out[#out + 1] = cut
			lastI = i - 1
		end
		lastD, lastS = d, s
	end
	out[#out + 1] = Vector(goal)
	return out
end

local function plan(from, goal)
	local sx, sy, sz = nearHold(from)
	if not sx then return nil, "no hold at the start" end
	local gx, gy, gz = nearHold(goal)
	if not gx then return nil, "nothing to hold on to at the goal" end
	local path, n, eats = search({ sx, sy, sz }, { gx, gy, gz })
	if not path then return nil, (n > MAXX and "too far" or "no way") .. " (" .. n .. " cells)" end
	local w = waypoints(path, goal)
	if eats and #eats > 0 then w.eats = eats R.Stat("way through a player's build (to be eaten)") end
	return w, n .. " cells"
end

-- can a bug at a see b: nothing of the map between, and none of the players' builds the plan knows (ign: the one it
-- goes for). On along a way only to a waypoint it sees: with the map alone it saw a waypoint through a wooden wall
-- the way went round, went straight at it and pressed against the wall (2026-11-16, repwall)
function V.Sees(a, b, ign)
	if util.TraceLine({ start = a, endpos = b, mask = MASK }).Hit then return false end
	if next(V.psig) == nil then return true end
	return not util.TraceLine({ start = a, endpos = b, mask = MASK_SOLID, filter = function(e) return V.psig[e] ~= nil and e ~= ign end }).Hit
end

-- worth asking for (a way across the map): far, or much higher or lower, or nothing straight between
function V.Wanted(pos, goal)
	if not R.cv.nav:GetBool() then return false end
	local d = goal:Distance(pos)
	if d < 150 then return false end
	-- (a goal on nothing - a wander spot in the air - has no way to it: 529 of 879 asks in a test were such. On a
	-- floor, a wall or a ceiling - an ambush spot over a door - it has)
	if not nearHold(goal) then return false end
	if d > 600 or math.abs(goal.z - pos.z) > 120 then return true end
	if util.TraceLine({ start = pos + Vector(0, 0, 12), endpos = goal + Vector(0, 0, 12), mask = MASK }).Hit then return true end
	-- (a player's build straight between: the plan knows it, the straight line does not)
	if next(V.psig) == nil then return false end
	local t = util.TraceLine({ start = pos + Vector(0, 0, 12), endpos = goal + Vector(0, 0, 12), mask = MASK_SOLID, filter = function(e) return V.psig[e] ~= nil end })
	return t.Hit and V.psig[t.Entity] ~= nil
end

-- the way from here to there: the waypoints, false when there is none, nil while it is being worked out (asking again
-- keeps the job wanted; one nobody asked for in 3 s is dropped)
function V.Request(from, goal)
	local sx, sy, sz = cellOf(from)
	local gx, gy, gz = cellOf(goal)
	local key = cellKey(sx, sy, sz) .. ">" .. cellKey(gx, gy, gz)
	local now = CurTime()
	local r = V.routes[key]
	if r and now < r.t then return r.r end
	local j = V.jobs[key]
	if j then j.want = now return nil end
	local f, g = Vector(from), Vector(goal)
	V.jobs[key] = { co = coroutine.create(function() return plan(f, g) end), want = now, t0 = SysTime() }
	V.order[#V.order + 1] = key
	while #V.order > 8 do V.jobs[table.remove(V.order, 1)] = nil end
	return nil
end

local liveTick
hook.Add("Tick", "AGPRepNav", function()
	propsTick()
	if #V.order == 0 then if liveTick then liveTick() end return end
	V.clock = V.clock + 1
	-- (a crowded swarm, its walking shares ticks - agp_replicator.lua R.walkDiv: half the time for the ways, they come a
	-- little later; the game keeps its frame rate - owner 2026-11-17, 60 bugs at a building on freespace13)
	local stop = SysTime() + BUDGET / ((R.walkDiv or 1) > 1 and 2 or 1)
	local now = CurTime()
	while #V.order > 0 and SysTime() < stop do
		local key = V.order[#V.order]
		local j = V.jobs[key]
		if not j or now - j.want > 3 then V.jobs[key] = nil table.remove(V.order) V.dropped = (V.dropped or 0) + 1
		else
			V.deadline = stop
			local ok, way, why = coroutine.resume(j.co)
			if not ok then
				ErrorNoHalt("[AGP] Replicators way across the map: " .. tostring(way) .. "\n")
				way, why = nil, "error"
			end
			if not ok or coroutine.status(j.co) == "dead" then
				V.jobs[key] = nil
				table.RemoveByValue(V.order, key)
				V.routes[key] = { r = way or false, t = now + 30, why = why }
				V.made = (V.made or 0) + 1
				if not way then V.failed = (V.failed or 0) + 1 end
				V.lastWhy = why
			else break end   -- (its time is up for this tick)
		end
	end
	V.deadline = nil
end)

-- the live area scan (owner 2026-11-16: not the whole map - that reached freespace13's whole city, 930 000 cells and
-- 450 MB - but "only what is around a Replicator, up to the highest structure near it, and wherever it is carried"; an
-- admin setting, on by default): in the background, a little every tick while no way is being worked out, the blocks
-- round each Replicator are read cell by cell - what each cell holds on to, the 7 rays a way's search would otherwise
-- cast when it first reaches the cell (the links between cells stay as needed: one ray each). A block of open air
-- (nothing within reach of any of its cells) takes one box trace. Kept in a file per map
-- (data/agp_replicators/nav_<map>.dat, 4 KB a block read) and read back at the next start.
local BW = B * C         -- a block's side in units (768)
local function keyBlock(k) return k % 128 - 64, floor(k / 128) % 128 - 64, floor(k / 16384) - 64 end
local function navFile() return "agp_replicators/nav_" .. game.GetMap():lower():gsub("[^%w_]", "_") .. ".dat" end
local function mapStamp() return file.Size("maps/" .. game.GetMap() .. ".bsp", "GAME") or 0 end
V.live = V.live or { q = {}, cur = nil, nextList = 0, dirty = false, nextSave = 0, read = 0, air = 0, cpu = 0 }
local LV = V.live

-- the highest thing (its top) over a point: straight down from high above (from inside a building: from over its roof)
local function topAt(q)
	for h = 3000, 200, -400 do
		local s = q + Vector(0, 0, h)
		if band(util.PointContents(s), CONTENTS_SOLID) == 0 then
			local t = util.TraceLine({ start = s, endpos = q - Vector(0, 0, 64), mask = MASK })
			if not t.StartSolid then return t.Hit and t.HitPos.z or nil end
		end
	end
end

-- the blocks round one bug that are not read yet: its own and those beside it it is near (a quarter block), from just
-- under it up to the highest top within 300 of it (a roof, the building next door), at most 2000 up
local function wanted(p, out, seen)
	local top = p.z
	for _, o in ipairs({ Vector(0, 0, 0), Vector(300, 0, 0), Vector(-300, 0, 0), Vector(0, 300, 0), Vector(0, -300, 0) }) do
		local z = topAt(p + o)
		if z and z > top then top = z end
	end
	top = math.min(top, p.z + 2000)
	local m = BW * 0.25
	for bx = floor((p.x - m) / BW), floor((p.x + m) / BW) do
		for by = floor((p.y - m) / BW), floor((p.y + m) / BW) do
			for bz = floor((p.z - 96) / BW), floor((top + 96) / BW) do
				local k = (bx + 64) + (by + 64) * 128 + (bz + 64) * 16384
				local b = V.blocks[k]
				if not seen[k] and not (b and b.full) then seen[k] = true out[#out + 1] = k end
			end
		end
	end
end

liveTick = function()
	if not R.cv.navscan:GetBool() or (R.lag and (R.lag.behind or R.lag.dormant)) or (R.walkDiv or 1) > 1 then return end   -- (crowded: later)
	local now = CurTime()
	local t0 = SysTime()
	local stop = t0 + (V.liveBudget or LIVET)
	-- what is wanted, every 2 s: the blocks round the Replicators (32 of them at most each time, the rest next time)
	if not LV.cur and #LV.q == 0 and now > LV.nextList then
		LV.nextList = now + 2
		local seen, n = {}, 0
		for e in pairs(R.bugs) do
			if IsValid(e) and not e.RepGone then
				wanted(e:GetPos(), LV.q, seen)
				n = n + 1
				if n >= 32 or SysTime() > stop then break end
			end
		end
	end
	while SysTime() < stop do
		local c = LV.cur
		if not c then
			local k = table.remove(LV.q, 1)
			if not k then break end
			local bx, by, bz = keyBlock(k)
			local b = block(bx * B, by * B, bz * B)
			if not b.full then
				-- open air (nothing solid within reach of any of its cells): all at once
				local half = Vector(BW * 0.5 + REACH, BW * 0.5 + REACH, BW * 0.5 + REACH)
				local mid = Vector((bx + 0.5) * BW, (by + 0.5) * BW, (bz + 0.5) * BW)
				local t = util.TraceHull({ start = mid, endpos = mid, mins = -half, maxs = half, mask = MASK })
				if not t.Hit and not t.StartSolid then
					b.air, b.full, b.st = true, true, {}
					LV.air, LV.dirty = LV.air + 1, true
				else
					LV.cur = { bx = bx * B, by = by * B, bz = bz * B, i = 0, b = b }
				end
			end
		else
			local i = c.i
			state(c.bx + i % B, c.by + floor(i / B) % B, c.bz + floor(i / (B * B)))
			c.i = i + 1
			if c.i >= B * B * B then
				c.b.full = true
				LV.cur, LV.read, LV.dirty = nil, LV.read + 1, true
			end
		end
	end
	LV.cpu = LV.cpu + (SysTime() - t0)
	if LV.dirty and now > LV.nextSave and not LV.cur then LV.nextSave = now + SAVET V.SaveLive() end
end

-- the file: "AGPNAV4", the map's size (another version of the map: not read), then each block read: its key, 1 = open
-- air or 2 = its 4096 cells, a byte each (the cell's state + 1)
function V.SaveLive()
	if not R.cv.navscan:GetBool() then return end
	local t0 = SysTime()
	local list = {}
	for k, b in pairs(V.blocks) do if b.full then list[#list + 1] = k end end
	file.CreateDir("agp_replicators")
	local f = file.Open(navFile(), "wb", "DATA")
	if not f then return end
	f:Write("AGPNAV4\n")
	f:WriteULong(mapStamp())
	f:WriteULong(#list)
	local N = B * B * B
	local buf = {}
	for _, k in ipairs(list) do
		local b = V.blocks[k]
		f:WriteULong(k)
		if b.air then f:WriteByte(1)
		else
			f:WriteByte(2)
			local st = b.st
			for j = 0, N - 1, 256 do
				for i = 1, 256 do buf[i] = (st[j + i] or -2) + 2 end
				f:Write(string.char(unpack(buf, 1, 256)))
			end
		end
	end
	f:Close()
	LV.dirty = false
	LV.saved = { blocks = #list, bytes = file.Size(navFile(), "DATA"), ms = (SysTime() - t0) * 1000 }
end

function V.LoadLive()
	if not R.cv.navscan:GetBool() then return false end
	local f = file.Open(navFile(), "rb", "DATA")
	if not f then return false end
	local ok = f:Read(8) == "AGPNAV4\n" and f:ReadULong() == mapStamp()
	if not ok then f:Close() return false end
	local t0 = SysTime()
	local nb = f:ReadULong()
	local N = B * B * B
	V.blocks, V.nblocks = {}, 0
	for _ = 1, math.min(nb, LIVEB) do
		local k = f:ReadULong()
		local kind = f:ReadByte()
		local b = { st = {}, lq = {}, lm = {}, used = V.clock, full = true }
		if kind == 1 then b.air = true
		elseif kind == 2 then
			local st = b.st
			for j = 0, N - 1, 256 do
				local s = f:Read(256)
				if not s or #s < 256 then f:Close() V.blocks, V.nblocks = {}, 0 return false end
				for i = 1, 256 do
					local v = s:byte(i) - 2
					if v >= -1 then st[j + i] = v end
				end
			end
		else f:Close() V.blocks, V.nblocks = {}, 0 return false end
		V.blocks[k] = b
		V.nblocks = V.nblocks + 1
	end
	f:Close()
	LV.loaded = { blocks = V.nblocks, ms = (SysTime() - t0) * 1000 }
	return true
end

-- with the map up: what was read before comes back from the file; at the map's end it is saved
hook.Add("InitPostEntity", "AGPRepNavScan", function()
	timer.Simple(5, function() V.LoadLive() end)
end)
hook.Add("ShutDown", "AGPRepNavSave", function() if LV.dirty then V.SaveLive() end end)
-- a cleanup: what was worked out as needed goes (doors, props may stand elsewhere now), the file's blocks come back
hook.Add("PostCleanupMap", "AGPRepNavClear", function()
	if LV.dirty then V.SaveLive() end
	V.blocks, V.nblocks, V.routes, V.jobs, V.order = {}, 0, {}, {}, {}
	LV.q, LV.cur = {}, nil
	V.pcell, V.psig, V.propsN = {}, {}, 0
	timer.Simple(1, function() V.LoadLive() end)
end)
