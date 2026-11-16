--[[
	Replicators: what the swarm knows about the map (server). No navmesh needed - they learn the map by walking it:
	- cells of 128 x 128 x 96 units: how often visited, danger (Replicators destroyed there), metal seen, cover (how hidden
	  a spot is: walls and a roof around it, out of the players' sight), dead ends;
	- links between cells they walked from one to the other: the routes they know. Paths are planned over these links
	  (A*), so they find their way back, around obstacles, and - by scouting the edge of what they know - new ways;
	- kept per map in data/agp_replicators/<map>.txt (older knowledge fades a little each time), so they know a map better
	  every time it is played.
]]
local R = AGP.Rep
local M = R.Map or {}
R.Map = M
local CS, CZ = 128, 96
local MAX_CELLS = 8000

M.cells = M.cells or {}
M.links = M.links or {}
M.count = M.count or 0
M.grid = M.grid or {}   -- areas of 4 x 4 cells (512 units): searches look at the areas round a spot, not the whole map

local floor = math.floor
function M.Key(p) return floor(p.x / CS) .. ":" .. floor(p.y / CS) .. ":" .. floor(p.z / CZ) end
local function gridKey(key)
	local x, y = key:match("^(-?%d+):(-?%d+):")
	return floor(tonumber(x) / 4) .. ":" .. floor(tonumber(y) / 4)
end
local function gridAdd(key, c)
	c.k = key
	local g = gridKey(key)
	M.grid[g] = M.grid[g] or {}
	M.grid[g][key] = c
end
-- the known cells within (about) r of pos: only the areas round it are looked at
function M.Near(pos, r)
	local out = {}
	local x0, x1 = floor((pos.x - r) / 512), floor((pos.x + r) / 512)
	local y0, y1 = floor((pos.y - r) / 512), floor((pos.y + r) / 512)
	for gx = x0, x1 do
		for gy = y0, y1 do
			local g = M.grid[gx .. ":" .. gy]
			if g then for _, c in pairs(g) do out[#out + 1] = c end end
		end
	end
	return out
end
local function centre(key)
	local x, y, z = key:match("^(-?%d+):(-?%d+):(-?%d+)$")
	return Vector((tonumber(x) + 0.5) * CS, (tonumber(y) + 0.5) * CS, (tonumber(z) + 0.2) * CZ)
end
M.Centre = centre

function M.Cell(key, pos)
	local c = M.cells[key]
	if not c then
		if M.count >= MAX_CELLS then M.Prune() end
		c = { v = 0, d = 0, m = 0, h = -1, t = 0, p = pos and Vector(pos) or centre(key) }
		M.cells[key] = c
		gridAdd(key, c)
		M.count = M.count + 1
	end
	return c
end

-- a bug walked here (from the cell it was in before): the cell is known, the link between both is a route
function M.Visit(pos, prev)
	local key = M.Key(pos)
	local c = M.Cell(key, pos)
	c.v = c.v + 1
	c.t = CurTime()
	if c.v < 4 then c.p = LerpVector(0.5, c.p, pos) end   -- the spot it stood on (not the cell's middle: may be in a wall)
	if prev and prev ~= key and M.cells[prev] then
		M.links[prev] = M.links[prev] or {}
		M.links[key] = M.links[key] or {}
		M.links[prev][key] = true
		M.links[key][prev] = true
	end
	return key, c
end

function M.Mark(pos, field, amount)
	local c = M.Cell(M.Key(pos), pos)
	c[field] = (c[field] or 0) + amount
	c.t = CurTime()
end

-- forget the least useful cells (rarely visited, long ago) when the memory is full
function M.Prune()
	local list = {}
	for k, c in pairs(M.cells) do list[#list + 1] = { k, c.v + c.d * 3 + c.m * 2 + (c.h > 0 and 2 or 0) + c.t * 0.001 } end
	table.sort(list, function(a, b) return a[2] < b[2] end)
	for i = 1, math.floor(#list * 0.2) do
		local k = list[i][1]
		M.cells[k] = nil
		local g = M.grid[gridKey(k)]
		if g then g[k] = nil end
		for n in pairs(M.links[k] or {}) do if M.links[n] then M.links[n][k] = nil end end
		M.links[k] = nil
		M.count = M.count - 1
	end
end

-- A* over the known links; danger costs extra (they avoid places where many of them died). Returns spots or nil.
-- The open list is a heap (the best next cell in a few steps, not by looking at all of them).
local function search(start, goal, limit)
	local gp = M.cells[goal].p
	local came, g, f = {}, { [start] = 0 }, { [start] = M.cells[start].p:Distance(gp) }
	local hk, hf, hn = { start }, { f[start] }, 1   -- the heap: cells and their f when pushed
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
		local cur, cf = pop()
		if cf == f[cur] then   -- else an older entry of a cell that was improved since
			f[cur] = -1   -- expanded (a better way to it later opens it again, as before)
			if cur == goal then
				local path, k = {}, goal
				while k do table.insert(path, 1, M.cells[k].p) k = came[k] end
				return path
			end
			n = n + 1
			if n > (limit or 600) then return nil end
			local cp = M.cells[cur].p
			for nb in pairs(M.links[cur] or {}) do
				local c = M.cells[nb]
				if c then
					local cost = g[cur] + cp:Distance(c.p) * (1 + math.min(c.d, 5) * 0.6)
					if not g[nb] or cost < g[nb] then
						came[nb], g[nb] = cur, cost
						f[nb] = cost + c.p:Distance(gp)
						push(nb, f[nb])
					end
				end
			end
		end
	end
	return nil
end
-- the same route between the same two places is shared for a few seconds (a column of bugs going the same way asks once)
local pathCache = {}
function M.Path(from, to, limit)
	local start, goal = M.Key(from), M.Key(to)
	if start == goal then return { to } end
	if not M.cells[start] or not M.cells[goal] or not M.links[start] then return nil end
	local ck = start .. ">" .. goal .. ">" .. (limit or 600)
	local now = CurTime()
	local hit = pathCache[ck]
	if not hit or now > hit.t then
		hit = { t = now + 5, p = search(start, goal, limit) or false }
		pathCache[ck] = hit
	end
	if not hit.p then return nil end
	local path = {}
	for i = 1, #hit.p - 1 do path[i] = hit.p[i] end
	path[#hit.p] = to
	return path
end

-- a cell at the edge of what is known (few links), between min and max distance: where scouts go to find new ways
-- The hive searches once per area (512 units) and second for all bugs there and keeps the best places; each bug takes
-- the best one nobody else took (claimed for 10 s), so they spread out instead of all going to the same spot.
local frontCache, claimed = {}, setmetatable({}, { __mode = "k" })
function M.Frontier(pos, minD, maxD)
	local now = CurTime()
	local ak = floor(pos.x / 512) .. ":" .. floor(pos.y / 512) .. ":" .. floor(pos.z / 256) .. ":" .. minD .. ":" .. maxD
	local e = frontCache[ak]
	if not e or now > e.t then
		local list = {}
		for _, c in ipairs(M.Near(pos, maxD + 512)) do
			local d = c.p:Distance(pos)
			if d > minD - 400 and d < maxD + 400 then   -- the whole area's range (each bug checks its own below)
				local links = 0
				for _ in pairs(M.links[c.k] or {}) do links = links + 1 end
				if links < 4 then list[#list + 1] = { c, (4 - links) * 2 - c.v * 0.05 - c.d * 2 + math.random() * 2 } end
			end
		end
		table.sort(list, function(a, b) return a[2] > b[2] end)
		for i = #list, 25, -1 do list[i] = nil end
		e = { t = now + 1, list = list }
		frontCache[ak] = e
	end
	local first
	for _, x in ipairs(e.list) do
		local c = x[1]
		local d = c.p:DistToSqr(pos)
		if d > minD * minD and d < maxD * maxD then
			if not claimed[c] or now > claimed[c] then claimed[c] = now + 10 return c.p end
			first = first or c
		end
	end
	return first and first.p
end
timer.Create("AGPRepMapCaches", 10, 0, function()
	local now = CurTime()
	for k, e in pairs(pathCache) do if now > e.t then pathCache[k] = nil end end
	for k, e in pairs(frontCache) do if now > e.t then frontCache[k] = nil end end
end)

-- can a player see this spot?
function M.Seen(pos)
	for _, p in ipairs(player.GetAll()) do
		if p:Alive() then
			local eye = p:EyePos()
			if eye:DistToSqr(pos) < 6000 * 6000 then
				local tr = util.TraceLine({ start = eye, endpos = pos + Vector(0, 0, 8), mask = MASK_SOLID_BRUSHONLY })
				if not tr.Hit then return true end
			end
		end
	end
	return false
end

-- how hidden is a spot: walls around it, a roof above, nobody sees it (0..1); stored in the cell
function M.Cover(pos)
	local n = 0
	for a = 0, 315, 45 do
		local tr = util.TraceLine({ start = pos + Vector(0, 0, 12), endpos = pos + Vector(0, 0, 12) + Angle(0, a, 0):Forward() * 220, mask = MASK_SOLID_BRUSHONLY })
		if tr.Hit then n = n + 1 end
	end
	local roof = util.TraceLine({ start = pos + Vector(0, 0, 12), endpos = pos + Vector(0, 0, 400), mask = MASK_SOLID_BRUSHONLY }).Hit
	local h = n / 8 * 0.6 + (roof and 0.3 or 0) + (M.Seen(pos) and 0 or 0.1)
	local c = M.Cell(M.Key(pos), pos)
	c.h = c.h < 0 and h or Lerp(0.3, c.h, h)
	return h
end

-- the best hiding place: hidden, far from the enemies (a list of positions), not seen now, not where many died
function M.HideSpot(pos, enemies, minD, maxD)
	local best, bs
	for _, c in ipairs(M.Near(pos, maxD)) do
		if c.h > 0.35 then
			local d = c.p:Distance(pos)
			if d > minD and d < maxD then
				local far = 99999
				for _, e in ipairs(enemies) do far = math.min(far, c.p:Distance(e)) end
				local s = c.h * 3 + math.min(far, 4000) / 1000 - c.d * 1.5 + math.random()
				if not bs or s > bs then best, bs = c, s end
			end
		end
	end
	if best and M.Seen(best.p) then best.h = best.h * 0.8 return nil end   -- seen right now: not today
	return best and best.p
end

-- memory per map (fades a little each time it is loaded)
local function file_name() return "agp_replicators/" .. game.GetMap():lower():gsub("[^%w_]", "_") .. ".txt" end
function M.Save()
	if M.count == 0 then return end
	local out = { v = 1, cells = {}, links = {} }
	for k, c in pairs(M.cells) do out.cells[k] = { c.v, c.d, c.m, c.h, math.Round(c.p.x), math.Round(c.p.y), math.Round(c.p.z) } end
	for k, l in pairs(M.links) do out.links[k] = table.GetKeys(l) end
	file.CreateDir("agp_replicators")
	file.Write(file_name(), util.TableToJSON(out))
end
function M.Load()
	local t = util.JSONToTable(file.Read(file_name(), "DATA") or "")
	if not t or not t.cells then return end
	M.cells, M.links, M.count, M.grid = {}, {}, 0, {}
	for k, c in pairs(t.cells) do
		M.cells[k] = { v = c[1] * 0.7, d = c[2] * 0.5, m = c[3] * 0.5, h = c[4], t = 0, p = Vector(c[5], c[6], c[7]) }
		gridAdd(k, M.cells[k])
		M.count = M.count + 1
	end
	for k, l in pairs(t.links) do
		M.links[k] = {}
		for _, n in ipairs(l) do M.links[k][n] = true end
	end
end
for k, c in pairs(M.cells) do if not c.k then gridAdd(k, c) end end   -- cells known before a Lua refresh
hook.Add("InitPostEntity", "AGPRepMapLoad", M.Load)
hook.Add("ShutDown", "AGPRepMapSave", M.Save)
timer.Create("AGPRepMapSave", 300, 0, M.Save)
