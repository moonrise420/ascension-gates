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
local MAXB = 160      -- blocks kept (each a few hundred KB at most, most far less)
local REACH = 40      -- a surface this near the middle is something to hold on to
local MAXX = 6000     -- cells looked at for one way at most
local BUDGET = 0.002  -- seconds a tick for all the ways being worked out
local MASK = MASK_PLAYERSOLID_BRUSHONLY
local floor, band, bor, sqrt = math.floor, bit.band, bit.bor, math.sqrt

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
		if V.nblocks >= MAXB then
			local oldK, oldU
			for kk, bb in pairs(V.blocks) do if not oldU or bb.used < oldU then oldK, oldU = kk, bb.used end end
			V.blocks[oldK] = nil
			V.nblocks = V.nblocks - 1
		end
		b = { st = {}, lk = {}, used = V.clock }
		V.blocks[k] = b
		V.nblocks = V.nblocks + 1
	end
	b.used = V.clock
	return b, (cx - bx * B) + (cy - by * B) * B + (cz - bz * B) * B * B + 1
end

-- a cell: -1 no room, 0 room but nothing to hold on to, above 0 what it holds on to (1 floor, 2 ceiling, 4 wall)
local function state(cx, cy, cz)
	local b, i = block(cx, cy, cz)
	local s = b.st[i]
	if s then return s end
	local c = centre(cx, cy, cz)
	if band(util.PointContents(c), MASK) ~= 0 then s = -1
	else
		s = 0
		for _, a in ipairs(AX) do
			local t = util.TraceLine({ start = c, endpos = c + a[1] * REACH, mask = MASK })
			if t.Hit and not t.StartSolid then s = bor(s, a[2]) end
		end
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
	local key = i * 32 + d
	local v = b.lk[key]
	if v ~= nil then return v end
	local n = NB[d]
	local ok = false
	if state(cx + n[1], cy + n[2], cz + n[3]) > 0 then
		local t = util.TraceLine({ start = centre(cx, cy, cz), endpos = centre(cx + n[1], cy + n[2], cz + n[3]), mask = MASK })
		ok = not t.Hit
		if ok and (n[1] ~= 0 and 1 or 0) + (n[2] ~= 0 and 1 or 0) + (n[3] ~= 0 and 1 or 0) > 1 then
			-- (a diagonal: at least one way round the corner through the straight neighbours has room)
			local any = false
			for _, s2 in ipairs({ { n[1], 0, 0 }, { 0, n[2], 0 }, { 0, 0, n[3] } }) do
				if (s2[1] ~= 0 or s2[2] ~= 0 or s2[3] ~= 0) and state(cx + s2[1], cy + s2[2], cz + s2[3]) >= 0 then any = true break end
			end
			ok = any
		end
	end
	b.lk[key] = ok
	return ok
end

-- what a step onto a cell costs: a floor least, a wall more, only a ceiling most
local function weight(s)
	if band(s, 1) ~= 0 then return 1 end
	if band(s, 4) ~= 0 then return 1.25 end
	return 1.8
end

-- the hold-on cell nearest a point (its own, else one of the 26 round it)
local function nearHold(p)
	local cx, cy, cz = cellOf(p)
	if state(cx, cy, cz) > 0 then return cx, cy, cz end
	local best, bd
	for _, n in ipairs(NB) do
		local x, y, z = cx + n[1], cy + n[2], cz + n[3]
		if state(x, y, z) > 0 then
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

-- A* from cell to cell (in a coroutine: it gives way when the tick's time is used up)
local function search(s, g)
	local sk, gk = cellKey(s[1], s[2], s[3]), cellKey(g[1], g[2], g[3])
	local pos, gc, came = { [sk] = s }, { [sk] = 0 }, {}
	local done = {}
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
				local path, k = {}, gk
				while k do table.insert(path, 1, pos[k]) k = came[k] end
				return path, n
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
				if not done[k] and link(c[1], c[2], c[3], d) then
					local cost = gc[cur] + o[4] * weight(state(x, y, z))
					if not gc[k] or cost < gc[k] then
						gc[k], came[k], pos[k] = cost, cur, { x, y, z }
						local h = sqrt((x - g[1]) ^ 2 + (y - g[2]) ^ 2 + (z - g[3]) ^ 2) * C
						push(k, cost + h * 2)   -- (greedy towards the goal: at 1.3 a way 400 up took 7 s to work out)
					end
				end
			end
		end
	end
	return nil, n
end

-- the cells of a way as the bug's waypoints: one where the way turns or changes what it holds on to, at most every 4
-- cells, each on its surface; the last one the goal itself
local function waypoints(path, goal)
	local out = {}
	local lastI, lastD, lastS = 1, nil, nil
	for i = 2, #path do
		local a, b = path[i - 1], path[i]
		local d = (b[1] - a[1]) .. (b[2] - a[2]) .. (b[3] - a[3])
		local s = state(b[1], b[2], b[3])
		if i < #path and ((lastD and d ~= lastD) or (lastS and s ~= lastS) or i - lastI >= 4) then
			out[#out + 1] = onSurface(a[1], a[2], a[3])
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
	local path, n = search({ sx, sy, sz }, { gx, gy, gz })
	if not path then return nil, (n > MAXX and "too far" or "no way") .. " (" .. n .. " cells)" end
	return waypoints(path, goal), n .. " cells"
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
	return util.TraceLine({ start = pos + Vector(0, 0, 12), endpos = goal + Vector(0, 0, 12), mask = MASK }).Hit
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

hook.Add("Tick", "AGPRepNav", function()
	if #V.order == 0 then return end
	V.clock = V.clock + 1
	local stop = SysTime() + BUDGET
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

-- the map changed (a cleanup): what was worked out is thrown away
hook.Add("PostCleanupMap", "AGPRepNavClear", function()
	V.blocks, V.nblocks, V.routes, V.jobs, V.order = {}, 0, {}, {}, {}
end)
