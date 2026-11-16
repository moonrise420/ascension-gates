-- Replicators: the way in 3D (owner 2026-11-05: "why not 3D?"). The side view of sv_surfnav.lua sees only the upright
-- slice through a bug and its goal: the wall beside a door, a pillar next to a deck, the part of a wall without a
-- window lay off that slice and were never found. Here the swarm maps the surfaces themselves: points about a step
-- apart on floors, walls and ceilings, each with its own "up", linked where a bug can crawl from one to the next - along
-- a face, into an inside corner (floor to wall, wall to ceiling) or round an outside edge (onto the face beyond it).
-- The links are found by feeling with rays the way its legs do (sv_walk.lua), so a way found is a way it can walk.
-- The map is felt out only where bugs want to go and kept for the whole game (the map's own surfaces for good, a
-- player's props for a few seconds - they move). Over it the shortest way to the goal (A*), in the background, a few
-- milliseconds a tick, and handed over as the same kind of plan the side view makes (N.Step follows it on rails).
-- When the 3D way finds nothing the side view still gets its turn. agp_rep_surf3d 0 turns it off.
local R = AGP.Rep
local N = R.SurfNav
local G = N.Graph or {}
N.Graph = G
-- (off by default - owner 2026-11-06, the lag: the felt map grew to 152,000 points, 517 MB of Lua memory, and the
-- garbage collector's work on it froze the game 70-170 ms again and again; off, it is neither loaded nor fed)
R.cv.surf3d = R.cv.surf3d or CreateConVar("agp_rep_surf3d", "0", FCVAR_ARCHIVE, "Replicators: plan climbs over a 3D map of surfaces (uses a lot of memory)")
local CAP = 60000   -- points at most: more, and the map is read again from its file (what was felt since is lost)

local S = 24   -- a step along a surface
local H = 10   -- where its legs feel from, over the surface
local GRID = 12   -- points sit on this grid along a surface (ways from different starts meet on the same points)
local MAXX = 3000   -- points looked at for one way at most
local MASKW = MASK_PLAYERSOLID
local floor, abs = math.floor, math.abs
G.nodes = G.nodes or {}
G.count = G.count or 0

local function walkable(e) return R.Walkable and R.Walkable(e) end
local propHit
local function tr(a, b)
	local t = util.TraceLine({ start = a, endpos = b, mask = MASKW, filter = walkable })
	if t.Hit and IsValid(t.Entity) then propHit = true end   -- (the world is not IsValid: a prop, a door - it may move)
	G.traces = (G.traces or 0) + 1
	return t
end
local function solid(p) return bit.band(util.PointContents(p), CONTENTS_SOLID) ~= 0 end

local function nodeKey(p, n)
	return floor(p.x / 6 + 0.5) .. ":" .. floor(p.y / 6 + 0.5) .. ":" .. floor(p.z / 6 + 0.5) .. "|" .. floor(n.x * 2 + 0.5) .. floor(n.y * 2 + 0.5) .. floor(n.z * 2 + 0.5)
end
local function node(p, n)
	local k = nodeKey(p, n)
	local nd = G.nodes[k]
	if not nd then
		nd = { p = p, n = n, k = k }
		G.nodes[k] = nd
		G.count = G.count + 1
	end
	return nd
end

-- along the surface: on the grid where the surface runs along a world axis, then down onto it again
local function snap(p, n)
	local v = Vector(p)
	if abs(n.x) < 0.5 then v.x = floor(v.x / GRID + 0.5) * GRID end
	if abs(n.y) < 0.5 then v.y = floor(v.y / GRID + 0.5) * GRID end
	if abs(n.z) < 0.5 then v.z = floor(v.z / GRID + 0.5) * GRID end
	return v
end
-- a point to stand on: on the surface, with room for its body over it; or nil
local function land(p, n)
	local s, m = snap(p, n), n
	local t = tr(s + n * H, s - n * (H + 6))
	if t.Hit and not t.StartSolid and t.HitNormal:Dot(n) > 0.7 then s, m = t.HitPos, t.HitNormal
	else s = p end   -- (the grid point lies off the edge: the point it felt)
	local r = tr(s + m * 1, s + m * (H + 6))
	if r.Hit or r.StartSolid then return end
	return Vector(s), Vector(m)
end

local function basis(n)
	local t1 = n:Cross(abs(n.z) < 0.9 and Vector(0, 0, 1) or Vector(1, 0, 0))
	t1:Normalize()
	local t2 = n:Cross(t1)
	t2:Normalize()
	return t1, t2
end
-- (a ceiling costs a little more than a wall, a wall more than a floor: it takes the floor when that is as short)
local function pen(n) return n.z < -0.5 and 1.25 or (n.z < 0.7 and 1.1 or 1) end

-- where a bug can crawl from this point: { node, cost, corner point or nil }
local function expand(nd)
	local now = CurTime()
	if nd.nb and (not nd.prop or now - nd.t < 5) then return nd.nb end
	propHit = false
	local nb = {}
	local p, n = nd.p, nd.n
	local t1, t2 = basis(n)
	local o = p + n * H
	local ds = { t1, -t1, t2, -t2, (t1 + t2):GetNormalized(), (t1 - t2):GetNormalized(), (t2 - t1):GetNormalized(), (-t1 - t2):GetNormalized() }
	for _, d in ipairs(ds) do
		local np, nn, via, cost
		local f = tr(o, o + d * S)
		if f.StartSolid then   -- (its legs are in something: no way that way)
			d = nil
		elseif f.Hit then
			-- a surface across its way: onto it (floor to wall, wall to ceiling, under a lip)
			if f.HitNormal:Dot(d) < -0.3 then np, nn = land(f.HitPos, f.HitNormal) cost = S * f.Fraction + H end
		else
			local q = o + d * S
			local g = tr(q, q - n * (H + 14))
			if g.Hit and not g.StartSolid then
				if g.HitNormal:Dot(n) > 0.3 then np, nn = land(g.HitPos, g.HitNormal) cost = S end   -- (on along it: a slope, a step)
			elseif not g.StartSolid then
				-- an outside edge: the face beyond it, round the corner (a thin wall's top, a window's sill: close under it)
				for _, dd in ipairs({ 6, 16, 30 }) do
					local b0 = q - n * (H + dd)
					local e = tr(b0, b0 - d * (S + 12))
					if e.Hit and not e.StartSolid and e.HitNormal:Dot(d) > 0.3 and e.HitNormal:Dot(n) < 0.6 then
						np, nn = land(e.HitPos, e.HitNormal)
						if np then
							local den = d:Dot(nn)
							local tt = den > 0.1 and (np - p):Dot(nn) / den or 0
							via = p + d * math.Clamp(tt, 0, S + 4)
							cost = S + 16
						end
						break
					end
				end
			end
		end
		if np then nb[#nb + 1] = { node(np, nn), cost * pen(nn), via } end
	end
	nd.nb, nd.t, nd.prop = nb, now, propHit or nil
	G.expanded = (G.expanded or 0) + 1
	return nb
end

-- the surface nearest a point (a goal on a roof, a wall over a door, a ceiling)
local AX = { Vector(0, 0, -1), Vector(0, 0, 1), Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0) }
local function surfaceAt(p, first)
	local best
	if first then
		local t = tr(p + first * H, p - first * (H + 12))
		if t.Hit and not t.StartSolid then return t.HitPos, t.HitNormal end
	end
	for _, a in ipairs(AX) do
		local t = tr(p - a * 4, p + a * 34)
		if t.Hit and not t.StartSolid and (not best or t.Fraction < best.Fraction) then best = t end
	end
	if best then return best.HitPos, best.HitNormal end
end

-- a small heap for the search
local function push(h, f, v)
	local i = #h + 1
	h[i] = { f, v }
	while i > 1 do
		local pi = floor(i / 2)
		if h[pi][1] <= h[i][1] then break end
		h[pi], h[i] = h[i], h[pi]
		i = pi
	end
end
local function pop(h)
	local top = h[1]
	local last = table.remove(h)
	if #h > 0 then
		h[1] = last
		local i = 1
		while true do
			local l, r, m = i * 2, i * 2 + 1, i
			if h[l] and h[l][1] < h[m][1] then m = l end
			if h[r] and h[r][1] < h[m][1] then m = r end
			if m == i then break end
			h[m], h[i] = h[i], h[m]
			i = m
		end
	end
	return top[2]
end

-- does the straight way from a to b stay on one face (for straightening the zigzag of the grid)
local function flat(a, b, n)
	if tr(a + n * H, b + n * H).Hit then return false end
	local l = a:Distance(b)
	for s = 12, l - 6, 12 do
		local p = a + (b - a) * (s / l)
		local t = tr(p + n * H, p - n * (H + 6))
		if not t.Hit or t.StartSolid or t.HitNormal:Dot(n) < 0.95 then return false end
	end
	return true
end

G.why = nil
-- the way from pos (its feet, "up" up) to goal: a plan (pts, ups, d, goal, len), or nil and why. In a coroutine it
-- gives the tick back when G.deadline has passed.
function G.Plan(pos, up, goal)
	G.Ready()
	local co = coroutine.running()
	local t0 = SysTime()
	local sp, sn = surfaceAt(pos, up)
	if not sp then return nil, "no surface under it" end
	local lp, ln = land(sp, sn)
	if lp then sp, sn = lp, ln end
	local start = node(sp, sn)
	local gp, gn = surfaceAt(goal, Vector(0, 0, 1))
	if not gp then return nil, "no surface at the goal" end
	local gdist = { [start.k] = 0 }
	local prev, via = {}, {}
	local open = {}
	push(open, sp:Distance(gp) * 1.4, start)
	local best, bestD = start, sp:Distance(gp)
	local startD = bestD
	local closed = {}
	local found
	local n = 0
	while #open > 0 do
		local nd = pop(open)
		if not closed[nd.k] then
			closed[nd.k] = true
			local d = nd.p:Distance(gp)
			if d < bestD then best, bestD = nd, d end
			if d < S * 0.8 and not tr(nd.p + nd.n * 4, gp + gn * 4).Hit then found = nd break end
			n = n + 1
			if n > MAXX then break end
			for _, l in ipairs(expand(nd)) do
				local m = l[1]
				local g2 = gdist[nd.k] + l[2]
				if not closed[m.k] and (not gdist[m.k] or g2 < gdist[m.k]) then
					gdist[m.k], prev[m.k], via[m.k] = g2, nd, l[3]
					push(open, g2 + m.p:Distance(gp) * 1.4, m)
				end
			end
			if co and G.deadline and SysTime() > G.deadline then coroutine.yield() end
		end
	end
	G.lastLooked, G.lastMs = n, (SysTime() - t0) * 1000
	local partial
	if not found then
		-- (not all the way: as far as it got, when that is well nearer - from there it looks again)
		if bestD > startD - 100 then return nil, string.format("no way (%d points looked at)", n) end
		found, partial = best, true
	end
	-- the points back to the start
	local path = {}
	local k = found
	while k do table.insert(path, 1, k) k = prev[k.k] end
	-- straighter: on one face, skip points the straight way passes over
	local keep = { path[1] }
	local i = 1
	while i < #path do
		local j = i + 1
		for m = math.min(#path, i + 6), i + 2, -1 do
			local ok = true
			for q = i + 1, m do if via[path[q].k] or path[q].n:Dot(path[i].n) < 0.99 then ok = false break end end
			if ok and flat(path[i].p, path[m].p, path[i].n) then j = m break end
		end
		keep[#keep + 1] = path[j]
		i = j
	end
	-- into a plan: round an outside edge the corner point is there three times while "up" turns (it rolls over)
	local P = { pts = {}, ups = {}, d = {}, goal = Vector(goal), three = true, partial = partial }
	-- (over a prop somewhere - a player's build, saved only once it worked there 3 times)
	for _, nd in ipairs(path) do if nd.prop then P.built = true break end end
	local function add(pt, u)
		local last, lu = P.pts[#P.pts], P.ups[#P.ups]
		local turn = lu and math.acos(math.Clamp(lu:Dot(u), -1, 1)) or 0
		if last and last:DistToSqr(pt) < 1 and turn < 0.05 then return end
		P.pts[#P.pts + 1] = Vector(pt) P.ups[#P.ups + 1] = Vector(u)
		P.d[#P.d + 1] = last and (P.d[#P.d] + math.max(last:Distance(pt), turn * 10)) or 0
	end
	add(pos, sn)
	for idx, nd in ipairs(keep) do
		local v = via[nd.k]
		if v and idx > 1 then
			local a = keep[idx - 1].n
			add(v, a) add(v, (a + nd.n):GetNormalized()) add(v, nd.n)
		end
		add(nd.p, nd.n)
	end
	-- (not all the way: the goal stays the one asked for - set to where the way ends, the plan looked like an old one
	-- for a moved goal, and was thrown away and taken again every tick in the pit. At its end it looks again from there)
	if not partial then add(gp, gn) end
	if #P.pts < 2 then return nil, "already there" end
	-- (never through the world, as in the side view)
	for q = 2, #P.pts do
		local a = P.pts[q] + P.ups[q] * 4
		if solid(a) then return nil, "through the world" end
		local t = util.TraceLine({ start = P.pts[q - 1] + P.ups[q - 1] * 4, endpos = a, mask = MASK_SOLID_BRUSHONLY })
		if t.Hit and not t.StartSolid then return nil, "through the world" end
	end
	P.len = P.d[#P.d]
	return P, string.format("%d points looked at", n)
end

-- in the background: a few milliseconds a tick for the whole swarm, the newest asks first in line after the one at work
G.jobs = G.jobs or {}
G.order = G.order or {}
function G.Pending(key) return G.jobs[key] ~= nil end
-- (asked again and again while it waits - each ask keeps the job wanted; one nobody asked for in 2 s is dropped: its
-- bug got there on its legs, or went elsewhere. The newest ask is worked on first - an old job for a bug long gone
-- held up the new ones, and a bug beside a crate climbed it on its legs before its way was ready)
function G.Request(key, pos, up, goal)
	G.Ready()
	local j = G.jobs[key]
	if j then j.want = CurTime() return end
	local p, u, g = Vector(pos), Vector(up), Vector(goal)
	G.jobs[key] = { co = coroutine.create(function() return G.Plan(p, u, g) end), t0 = CurTime(), want = CurTime() }
	G.order[#G.order + 1] = key
	while #G.order > 8 do G.jobs[table.remove(G.order, 1)] = nil end
end
local function finish(key, plan, why)
	G.jobs[key] = nil
	table.RemoveByValue(G.order, key)
	N.cache[key] = { p = plan or false, t = CurTime(), d3 = true, why = why }
	G.plans = (G.plans or 0) + 1
	if not plan then G.fails = (G.fails or 0) + 1 end
	G.why = why
end
hook.Add("Tick", "AGPRepSurf3D", function()
	if #G.order == 0 then return end
	if G.count > CAP then G.Load() G.jobs, G.order = {}, {} return end
	local stop = SysTime() + 0.003
	local now = CurTime()
	while #G.order > 0 and SysTime() < stop do
		local key = G.order[#G.order]
		local j = G.jobs[key]
		if not j or now - j.want > 2 then G.jobs[key] = nil table.remove(G.order) G.dropped = (G.dropped or 0) + 1
		else
			G.deadline = stop
			local ok, plan, why = coroutine.resume(j.co)
			if not ok then ErrorNoHalt("[AGP] Replicators 3D way: " .. tostring(plan) .. "\n") finish(key, nil, "error")
			elseif coroutine.status(j.co) == "dead" then finish(key, plan, why)
			else break end   -- (its time is up for this tick)
		end
	end
	G.deadline = nil
end)
-- (a cleanup leaves the map as it was: only what touched a prop is felt again)
hook.Add("PostCleanupMap", "AGPRepSurf3DClear", function()
	G.jobs, G.order = {}, {}
	for _, nd in pairs(G.nodes) do if nd.prop then nd.nb = nil end end
end)

-- the map felt out once (owner 2026-11-06: "the map data... then we only have player props left and save ticks?"):
-- the points and links over the map's own surfaces are kept per map in data/agp_replicators/<map>_surf.txt and read
-- when the map is up - after that only a player's props (and doors) are felt out live. Links that touched a prop are
-- not kept: they are felt again where they are now.
local function fileName() return "agp_replicators/" .. game.GetMap():lower():gsub("[^%w_]", "_") .. "_surf.txt" end
local function r1(x) return math.Round(x, 1) end
local function r2(x) return math.Round(x, 3) end
function G.Save()
	local list, idx = {}, {}
	local function take(nd) if not idx[nd] then list[#list + 1] = nd idx[nd] = #list end end
	for _, nd in pairs(G.nodes) do if nd.nb and not nd.prop then take(nd) for _, l in ipairs(nd.nb) do take(l[1]) end end end
	if #list == 0 or #list > 200000 then return 0 end
	local out = { "agpsurf 1" }
	for i, nd in ipairs(list) do
		local p, n = nd.p, nd.n
		local line = r1(p.x) .. " " .. r1(p.y) .. " " .. r1(p.z) .. " " .. r2(n.x) .. " " .. r2(n.y) .. " " .. r2(n.z)
		if nd.nb and not nd.prop then
			local ls = {}
			for _, l in ipairs(nd.nb) do
				local v = l[3]
				ls[#ls + 1] = idx[l[1]] .. " " .. r1(l[2]) .. (v and (" " .. r1(v.x) .. " " .. r1(v.y) .. " " .. r1(v.z)) or "")
			end
			line = line .. "|" .. table.concat(ls, ";")
		end
		out[i + 1] = line
	end
	file.CreateDir("agp_replicators")
	file.Write(fileName(), table.concat(out, "\n"))
	G.saved = G.expanded or 0
	return #list
end
function G.Load()
	G.nodes, G.count = {}, 0
	local s = file.Read(fileName(), "DATA")
	if not s then return 0 end
	local lines = string.Explode("\n", s)
	if lines[1] ~= "agpsurf 1" then return 0 end
	local list, links = {}, {}
	for i = 2, #lines do
		local a, l = lines[i], nil
		local bar = a:find("|", 1, true)
		if bar then a, l = a:sub(1, bar - 1), a:sub(bar + 1) end
		local x, y, z, nx, ny, nz = a:match("^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+)")
		if x then
			local nd = node(Vector(tonumber(x), tonumber(y), tonumber(z)), Vector(tonumber(nx), tonumber(ny), tonumber(nz)))
			list[#list + 1] = nd
			links[#list] = l
		end
	end
	for i, nd in ipairs(list) do
		local l = links[i]
		if l then
			local nb = {}
			if l ~= "" then
				for _, part in ipairs(string.Explode(";", l)) do
					local f = string.Explode(" ", part)
					local m = list[tonumber(f[1])]
					if m then nb[#nb + 1] = { m, tonumber(f[2]), f[5] and Vector(tonumber(f[3]), tonumber(f[4]), tonumber(f[5])) or nil } end
				end
			end
			nd.nb, nd.t = nb, CurTime()
		end
	end
	G.loaded = #list
	return #list
end
-- (read when it is first needed - not at all while it is off)
function G.Ready()
	if not G.read then G.read = true G.Load() G.saved = 0 G.expanded = 0 end
end
hook.Add("InitPostEntity", "AGPRepSurfLoad", function() if R.cv.surf3d:GetBool() then G.Ready() end end)
hook.Add("ShutDown", "AGPRepSurfSave", function() if G.read and (G.expanded or 0) > (G.saved or 0) then G.Save() end end)
timer.Create("AGPRepSurfSave", 300, 0, function() if G.read and (G.expanded or 0) > (G.saved or 0) + 200 then G.Save() end end)
