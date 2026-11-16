-- Ascension Gates: suggests good gate spots on maps without a gate spawner file.
-- Scans the map in a grid (every floor of every column, water and open air), tests each spot with the real gate size
-- (no wall touches it, room in front for the kawoosh, room for a DHD), then picks spots spread over the whole map.
-- The gates are only a suggestion: the admin checks them, moves or removes some and presses "Save map" in the editor.
AGP = AGP or {}
AGP.AutoPlace = AGP.AutoPlace or {}
local AP = AGP.AutoPlace

local GATE_UP = 90           -- gate centre above the ground (as the spawn menu places it)
local GATE_HALF = Vector(32, 150, 150) -- half size of a gate standing at yaw 0 (x = depth, y = width, z = height)
local KAWOOSH = 420          -- free room in front of the gate
local DHD_DIST = 260         -- DHD in front of the gate
local MIN_SPACING = 1500     -- gates at least this far apart
local TYPES = {              -- mixed gate types, matching DHD, group
    { gate = "stargate_sg1", dhd = "dhd_sg1", group = "M@" },
    { gate = "stargate_atlantis", dhd = "dhd_atlantis", group = "P@" },
    { gate = "stargate_universe", dhd = "dhd_universe", group = "U@#" },
    { gate = "stargate_movie", dhd = "dhd_sg1", group = "M@" },
}
local MASK = MASK_SOLID_BRUSHONLY

-- the long scans can run a slice at a time (AP.SuggestAsync): inside a coroutine they let the game go on
local sliceEnd = 0
local function breathe()
    if coroutine.running() and SysTime() > sliceEnd then coroutine.yield() end
end

local function mapBounds()
    local ok, mins, maxs = pcall(function() return game.GetWorld():GetModelBounds() end)
    if ok and mins and maxs and (maxs - mins):Length() > 100 then return mins, maxs end
    return Vector(-16000, -16000, -16000), Vector(16000, 16000, 16000)
end

-- space maps get floating gates too (water and sky are fine everywhere, but ground is preferred on normal maps)
function AP.IsSpaceMap(map)
    map = (map or game.GetMap()):lower()
    return map:find("^sb_") or map:find("^sbd_") or map:find("space") or map:find("freespace") or map:find("galax")
        or map:find("solarsystem") or map:find("universe") or map:find("planet") or map:find("orbit")
end

-- every floor in one column (top to bottom)
local function floors(x, y, mins, maxs)
    local out, start = {}, Vector(x, y, maxs.z - 4)
    local stop = Vector(x, y, mins.z + 4)
    -- some maps' bounds reach far above the real sky (gm_construct): a trace from outside the world is solid all
    -- the way, so first step down until the start point is inside the world
    while not util.IsInWorld(start) and start.z - 256 > stop.z do start = start - Vector(0, 0, 256) end
    -- up to 8 floors; thick brushes (e.g. the 3D skybox far above gm_construct) are passed in bigger steps
    local tries, lastZ = 0, nil
    while #out < 8 and tries < 64 do
        tries = tries + 1
        local tr = util.TraceLine({ start = start, endpos = stop, mask = MASK })
        if tr.StartSolid then
            if tr.FractionLeftSolid >= 1 then break end
            start = start + (stop - start) * tr.FractionLeftSolid + Vector(0, 0, -2)
        elseif not tr.Hit then
            break
        else
            -- a "floor" just below the last one is the same thick brush, not a new floor
            local same = lastZ and lastZ - tr.HitPos.z < 32
            if not same and tr.HitNormal.z > 0.8 and not tr.HitSky and not tr.HitNoDraw then
                out[#out + 1] = { pos = tr.HitPos, ceiling = start.z }
            end
            lastZ = tr.HitPos.z
            start = tr.HitPos + Vector(0, 0, same and -32 or -4)
        end
        if start.z <= stop.z then break end
    end
    return out
end

-- gate box free of brushes and of props/entities. A ground gate sits 60 units deep in the floor (like the spawn menu
-- places it), so its box is tested from just above the floor to its top.
local function boxFree(center, yaw, floating, groundZ)
    local half = (yaw % 180 == 0) and GATE_HALF or Vector(GATE_HALF.y, GATE_HALF.x, GATE_HALF.z)
    local c = center
    if not floating then
        local bottom, top = (groundZ or (center.z - GATE_UP)) + 4, center.z + GATE_HALF.z
        half = Vector(half.x, half.y, (top - bottom) / 2)
        c = Vector(center.x, center.y, (top + bottom) / 2)
    end
    local tr = util.TraceHull({ start = c, endpos = c + Vector(0, 0, 1), mins = -half, maxs = half, mask = MASK_SOLID })
    return not tr.Hit and not tr.StartSolid
end

-- free room in front (kawoosh), returns how far it is free (0..KAWOOSH*2)
local function frontFree(center, fwd)
    local tr = util.TraceHull({ start = center + fwd * 40, endpos = center + fwd * (KAWOOSH * 2), mins = Vector(-60, -60, -60), maxs = Vector(60, 60, 60), mask = MASK_SOLID })
    if tr.StartSolid then return 0 end
    return tr.Fraction * (KAWOOSH * 2 - 40)
end

-- how open a spot is: mean free distance in 8 directions at gate height (capped)
local function openness(center)
    local sum = 0
    for i = 0, 7 do
        local a = math.rad(i * 45)
        local dir = Vector(math.cos(a), math.sin(a), 0)
        local tr = util.TraceLine({ start = center, endpos = center + dir * 3000, mask = MASK })
        sum = sum + tr.Fraction * 3000
    end
    return sum / 8
end

-- DHD spot in front of the gate: flat ground near the gate's ground height
local function dhdSpot(ground, fwd)
    local p = ground + fwd * DHD_DIST
    local tr = util.TraceLine({ start = p + Vector(0, 0, 100), endpos = p - Vector(0, 0, 160), mask = MASK_SOLID })
    if tr.Hit and not tr.StartSolid and tr.HitNormal.z > 0.75 and math.abs(tr.HitPos.z - ground.z) < 80 then return tr.HitPos end
end

local SPAWNS = { "info_player_start", "info_player_deathmatch", "info_player_combine", "info_player_rebel", "info_player_terrorist",
    "info_player_counterterrorist", "gmod_player_start" }

-- reachable for players: open sky above (normal outdoor ground, also under water) or on the height level of a player
-- spawn (bunker maps like the SGC). A closed room below the map that nobody can enter fails both.
local function reachable(ground)
    local up = util.TraceLine({ start = ground + Vector(0, 0, 20), endpos = ground + Vector(0, 0, 32000), mask = MASK })
    if up.HitSky then return true end
    for _, cls in ipairs(SPAWNS) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            if math.abs(e:GetPos().z - ground.z) < 700 then return true end
        end
    end
    return false
end

local function nearSpawn(pos)
    for _, cls in ipairs(SPAWNS) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            if e:GetPos():Distance(pos) < 500 then return true end
        end
    end
    return false
end


--##################################
--#### Static props from the map file (trees without collision are invisible to traces)
--##################################
-- reads the "sprp" game lump of the BSP: position + model of every static prop. Cached per map.
local TREE = { "tree", "pine", "fir", "spruce", "birch", "oak", "palm", "bush", "shrub", "foliage", "hedge", "fern", "leaf", "leaves", "plant" }
function AP.StaticProps()
    if AP._sp and AP._spMap == game.GetMap() then return AP._sp end
    AP._spMap, AP._sp = game.GetMap(), {}
    local f = file.Open("maps/" .. game.GetMap() .. ".bsp", "rb", "GAME")
    if not f then return AP._sp end
    local ok, err = pcall(function()
        if f:Read(4) ~= "VBSP" then return end
        f:Seek(8 + 35 * 16) -- lump 35 = game lump
        local glOfs, glLen = f:ReadLong(), f:ReadLong()
        f:Seek(glOfs)
        local n = f:ReadLong()
        local spOfs, spLen, spVer
        for _ = 1, n do
            local id = f:Read(4)
            f:ReadShort() -- flags
            local ver = f:ReadShort()
            local ofs, len = f:ReadLong(), f:ReadLong()
            if id == "prps" then spOfs, spLen, spVer = ofs, len, ver end -- "sprp" stored little endian
        end
        if not spOfs then return end
        f:Seek(spOfs)
        local dict = {}
        for i = 1, f:ReadLong() do dict[i - 1] = f:Read(128):gsub("%z.*", ""):lower() end
        local leaves = f:ReadLong()
        f:Skip(leaves * 2)
        local count = f:ReadLong()
        if count <= 0 then return end
        local used = f:Tell() - spOfs
        local size = math.floor((spLen - used) / count)
        if size < 28 then return end
        for _ = 1, count do
            local start = f:Tell()
            local pos = Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
            f:Skip(12) -- angles
            local model = dict[f:ReadUShort()] or ""
            local tree = false
            for _, w in ipairs(TREE) do if model:find(w, 1, true) then tree = true break end end
            AP._sp[#AP._sp + 1] = { pos = pos, tree = tree, model = model }
            f:Seek(start + size)
        end
    end)
    f:Close()
    if not ok then MsgN("[Ascension Gates] could not read static props: " .. tostring(err)) end
    return AP._sp
end

-- size of a model on the ground (a "tree cluster" prop can be hundreds of units wide): measured once per model
local modelRadius = {}
local function radiusOf(model)
    if modelRadius[model] then return modelRadius[model] end
    local r = 60
    util.PrecacheModel(model)
    local e = ents.Create("prop_dynamic")
    if IsValid(e) then
        e:SetModel(model)
        local mn, mx = e:OBBMins(), e:OBBMaxs()
        r = math.max(math.abs(mn.x), math.abs(mn.y), math.abs(mx.x), math.abs(mx.y), 30)
        e:Remove()
    end
    modelRadius[model] = r
    return r
end

-- trees (static props, also without collision) around a spot; looked up in a 512-unit grid (maps have thousands)
local TB = 512
local function treeBuckets()
    if AP._tb and AP._tbMap == game.GetMap() then return AP._tb, AP._tbMaxR end
    AP._tbMap, AP._tb, AP._tbMaxR = game.GetMap(), {}, 0
    for _, sp in ipairs(AP.StaticProps()) do
        if sp.tree then
            local r = radiusOf(sp.model)
            AP._tbMaxR = math.max(AP._tbMaxR, r)
            local k = math.floor(sp.pos.x / TB) .. ":" .. math.floor(sp.pos.y / TB)
            local b = AP._tb[k]
            if not b then b = {}; AP._tb[k] = b end
            b[#b + 1] = { pos = sp.pos, r = r }
        end
    end
    return AP._tb, AP._tbMaxR
end

-- how many trees reach into the circle around pos (tree footprint counts, not only its centre)
local function treesNear(pos, radius)
    local buckets, maxR = treeBuckets()
    local n = 0
    local reach = math.ceil((radius + maxR) / TB)
    local cx, cy = math.floor(pos.x / TB), math.floor(pos.y / TB)
    for bx = cx - reach, cx + reach do
        for by = cy - reach, cy + reach do
            for _, t in ipairs(buckets[bx .. ":" .. by] or {}) do
                local dx, dy, d = t.pos.x - pos.x, t.pos.y - pos.y, radius + t.r
                if dx * dx + dy * dy < d * d and math.abs(t.pos.z - pos.z) < 800 then n = n + 1 end
            end
        end
    end
    return n
end


-- how far a gate's ring reaches below its centre (to stand it on a jetty): measured once per type on a real gate,
-- with a trace from below that only hits that gate
local gateBottoms = {}
local function gateBottom(cls)
    if gateBottoms[cls] then return gateBottoms[cls] end
    local b = 130
    local e = ents.Create(cls)
    if IsValid(e) then
        local mins, maxs = mapBounds()
        local c = Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, maxs.z - 600)
        e:SetPos(c)
        e:Spawn()
        e:Activate()
        local tr = util.TraceLine({ start = c - Vector(0, 0, 400), endpos = c, ignoreworld = true, filter = function(x) return x == e end })
        if tr.Hit and tr.HitPos.z < c.z then b = c.z - tr.HitPos.z end
        e:Remove()
    end
    gateBottoms[cls] = math.Clamp(b, 60, 200)
    return gateBottoms[cls]
end
local function maxGateBottom()
    local m = 0
    for _, t in ipairs(TYPES) do m = math.max(m, gateBottom(t.gate)) end
    return m
end

-- a jetty / pier: water right below the floor. There a gate stands on the planks instead of sinking into them.
local function thinFloor(ground)
    for _, d in ipairs({ 12, 40, 90, 150 }) do
        if bit.band(util.PointContents(ground - Vector(0, 0, d)), CONTENTS_WATER) ~= 0 then return true end
    end
    return false
end

-- test one candidate at all 4 directions; the best direction wins
local function evaluate(ground, floating, walked)
    local best
    local thin = not floating and thinFloor(ground)
    local center = ground + Vector(0, 0, floating and 0 or (thin and (maxGateBottom() + 2) or GATE_UP))
    if not util.IsInWorld(center) or nearSpawn(center) then return end
    if not floating and not walked and not reachable(ground) then return end -- walked floors are known to be reachable
    for _, yaw in ipairs({ 0, 90, 180, 270 }) do
        if boxFree(center, yaw, floating, ground.z) then
            local fwd = Angle(0, yaw, 0):Forward()
            local front = frontFree(center, fwd)
            if front >= KAWOOSH then
                local dhd = not floating and dhdSpot(ground, fwd) or nil
                local score = front / (KAWOOSH * 2) + (dhd and 1 or (floating and 0.6 or 0))
                if not best or score > best.score then
                    best = { pos = center, ground = ground, yaw = yaw, dhd = dhd, score = score, floating = floating or false, thin = thin }
                end
            end
        end
    end
    if best then
        -- no gate in a forest: trees right at the gate or in front of it (static props, often without collision)
        -- forest is fine, but no tree may stick into the gate or stand in the kawoosh / DHD area
        local near = treesNear(center, 170)
        local front = treesNear(center + Angle(0, best.yaw, 0):Forward() * 260, 140)
        if near > 0 or front > 0 then return end
        best.trees = treesNear(center, 900)
        best.open = openness(center)
        best.water = bit.band(util.PointContents(center), CONTENTS_WATER) ~= 0
        best.score = best.score + math.min(best.open, 2000) / 1000
        -- (2026-11-12, owner: "there are cool far away places left - the underground pool, the big pedestal with ramps -
        -- and no gate there") what kind of place this is: the picks are spread over the kinds, not only over the map
        if floating then
            best.kind = "air"
        else
            local up = util.TraceLine({ start = ground + Vector(0, 0, 20), endpos = ground + Vector(0, 0, 6000), mask = MASK })
            -- inside = a ceiling not far above AND walls around (under a bridge or an overhang is not inside)
            local indoor = up.Hit and not up.HitSky and (up.HitPos.z - ground.z) < 1700 and best.open < 1700
            best.ceil = up.Hit and (up.HitPos.z - ground.z) or 99999
            local lower, higher, wet = 0, 0, 0
            for i = 0, 7 do
                local a = math.rad(i * 45)
                for _, r in ipairs({ 420, 760 }) do
                    local q = ground + Vector(math.cos(a), math.sin(a), 0) * r
                    local tr = util.TraceLine({ start = q + Vector(0, 0, 70), endpos = q - Vector(0, 0, 900), mask = MASK })
                    if tr.StartSolid or (tr.Hit and tr.HitPos.z > ground.z + 60) then higher = higher + 1
                    elseif not tr.Hit or tr.HitPos.z < ground.z - 70 then lower = lower + 1 end
                    local wq = Vector(q.x, q.y, (tr.Hit and not tr.StartSolid) and (tr.HitPos.z + 12) or (ground.z - 30))
                    if bit.band(util.PointContents(wq), CONTENTS_WATER) ~= 0 then wet = wet + 1 end
                end
            end
            if best.water or wet >= 3 then best.kind = "water"            -- in or beside water (a pool, a lake shore)
            elseif lower >= 9 then best.kind = "platform"                 -- raised above what lies around it (a pedestal, a roof, a hill top)
            else best.kind = "open" end
            -- a hall, a cave, an underground room: kinds of their own ("indoor water" = a pool hall, "indoor platform"
            -- = a pedestal in a hall), so each of them gets a gate before a second open field
            if indoor then best.kind = (best.kind == "open") and "indoor" or ("indoor " .. best.kind) end
            best.indoor = indoor
        end
    end
    return best
end


-- walk the map like a player from every spawn point (on foot or swimming): which floors can players reach?
-- Grid of CELL units; a step to the next cell is allowed when the height difference is climbable and a player-sized
-- box fits through (walls, trees, invisible map borders and player clips stop it). Falling down is fine.
local CELL = 128
local CLIMB = 100          -- higher than this per cell = too steep
local PHULL_MIN, PHULL_MAX = Vector(-16, -16, 0), Vector(16, 16, 60)

-- doors, breakables and players do not stop a walking player for long; walls, static props (trees) and clips do
local function passable(e)
    if not IsValid(e) then return true end
    local c = e:GetClass()
    if e:IsPlayer() or c:find("door", 1, true) or c:find("breakable", 1, true) or c == "func_brush" or c:find("^prop_physics") then return false end
    return true
end

AP._floors = function(...) return floors(...) end   -- for the self-test
local function walkable(mins, maxs)
    local nx, ny = math.floor((maxs.x - mins.x) / CELL), math.floor((maxs.y - mins.y) / CELL)
    local cache = {}
    local function cellFloors(ix, iy)
        local key = ix * 100000 + iy
        local f = cache[key]
        if not f then
            f = floors(mins.x + (ix + 0.5) * CELL, mins.y + (iy + 0.5) * CELL, mins, maxs)
            cache[key] = f
        end
        return f
    end
    local seen, queue, reached = {}, {}, {}
    local function add(ix, iy, fi)
        local key = (ix * 100000 + iy) * 16 + fi
        if seen[key] then return end
        seen[key] = true
        queue[#queue + 1] = { ix, iy, fi }
    end
    -- start: the floor right below every player spawn
    for _, cls in ipairs(SPAWNS) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            local p = e:GetPos()
            local ix, iy = math.floor((p.x - mins.x) / CELL), math.floor((p.y - mins.y) / CELL)
            local best, bd
            for fi, f in ipairs(cellFloors(ix, iy)) do
                local d = p.z - f.pos.z
                if d > -40 and (not bd or d < bd) then best, bd = fi, d end
            end
            if best then add(ix, iy, best) end
        end
    end
    AP.LastWalk = { starts = #queue, spawns = 0, blocked = 0, steep = 0 }
    local W = AP.LastWalk
    for _, cls in ipairs(SPAWNS) do AP.LastWalk.spawns = AP.LastWalk.spawns + #ents.FindByClass(cls) end
    local head, limit = 1, 200000
    while head <= #queue and head < limit do
        local q = queue[head]; head = head + 1
        if head % 64 == 0 then breathe() end
        local ix, iy, fi = q[1], q[2], q[3]
        local here = cellFloors(ix, iy)[fi]
        reached[#reached + 1] = { pos = here.pos, ceiling = here.ceiling, ix = ix, iy = iy }
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local jx, jy = ix + d[1], iy + d[2]
            if jx >= 0 and jy >= 0 and jx <= nx and jy <= ny then
                for fj, f in ipairs(cellFloors(jx, jy)) do
                    local dz = f.pos.z - here.pos.z
                    if dz <= CLIMB then
                        local a = here.pos + Vector(0, 0, math.max(18, dz + 18))
                        local b = Vector(f.pos.x, f.pos.y, a.z)
                        local tr = util.TraceHull({ start = a, endpos = b, mins = PHULL_MIN, maxs = PHULL_MAX, mask = MASK_PLAYERSOLID, filter = passable })
                        if not tr.Hit and not tr.StartSolid then add(jx, jy, fj) else W.blocked = W.blocked + 1 end
                    else
                        W.steep = W.steep + 1
                    end
                end
            end
        end
    end
    AP.LastWalk.reached = #reached
    return reached
end

-- scan the map and pick the spots; returns the list of picks (nothing is spawned)
function AP.Find(opts)
    opts = opts or {}
    local mins, maxs = mapBounds()
    local size = maxs - mins
    local steps = opts.steps or (opts.manual and 56 or 28)   -- (a finer grid when an admin asks for gates: rooms are small)
    local space = AP.IsSpaceMap()
    local cands, scanned = {}, 0
    -- the outer edge of a map is decoration (tree walls, cliffs without collision): stay away from it
    local function edgeDist(pos)
        return math.min(pos.x - mins.x, maxs.x - pos.x, pos.y - mins.y, maxs.y - pos.y)
    end
    local EDGE_NO, EDGE_SOFT = 1200, 3000
    local function consider(f, walked)
        scanned = scanned + 1
        breathe()
        if edgeDist(f.pos) < EDGE_NO then return end
        -- "Place gates" pressed by an admin (opts.manual): a room with a ceiling counts even when no way into it was
        -- found on foot (ladders, lifts, doors) - the admin looks at every gate before saving
        if opts.manual and not walked and f.ceiling and f.ceiling - f.pos.z < 1700 and f.ceiling - f.pos.z > 200 then walked = true end
        local c = evaluate(f.pos, false, walked)
        if c then
            local ed = edgeDist(c.pos)
            if ed < EDGE_SOFT then c.score = c.score - (EDGE_SOFT - ed) / EDGE_SOFT * 1.5 end
            cands[#cands + 1] = c
        end
        -- open air above a floor: a floating gate (space maps)
        if space and f.ceiling - f.pos.z > 1600 then
            local air = evaluate(f.pos + Vector(0, 0, math.min(900, (f.ceiling - f.pos.z) / 2)), true)
            if air then air.score = air.score - 0.3; cands[#cands + 1] = air end
        end
    end
    local reachedArea
    if space then
        -- space maps: everything can be reached by flying, scan the whole map
        for ix = 0, steps do
            for iy = 0, steps do
                local x = mins.x + size.x * (ix + 0.5) / (steps + 1)
                local y = mins.y + size.y * (iy + 0.5) / (steps + 1)
                for _, f in ipairs(floors(x, y, mins, maxs)) do consider(f) end
            end
        end
        -- ... and every floor players can walk to from a spawn point: halls and underground rooms without sky above
        -- them (the grid above only takes floors under the open sky or on a spawn point's level)
        local reached = walkable(mins, maxs)
        for _, f in ipairs(reached) do
            if f.ix % 3 == 0 and f.iy % 3 == 0 then
                local up = util.TraceLine({ start = f.pos + Vector(0, 0, 20), endpos = f.pos + Vector(0, 0, 6000), mask = MASK })
                if up.Hit and not up.HitSky then consider(f, true) end
            end
        end
    else
        -- only floors players can walk or swim to from a spawn point (no map borders, no closed rooms)
        local reached = walkable(mins, maxs)
        reachedArea = #reached * CELL * CELL
        for _, f in ipairs(reached) do
            if f.ix % 4 == 0 and f.iy % 4 == 0 then consider(f, true) end
        end
    end
    -- how many gates: by usable map size
    local area = reachedArea or (math.max(size.x, 1) * math.max(size.y, 1))
    local count = opts.count or math.Clamp(math.Round(math.sqrt(area) / 7000) + 1, 2, 6)
    -- farthest point picking, weighted by score - and by the kind of place: a kind not picked yet counts more, one
    -- picked often counts less (so the pool, the pedestal and the hall each get a gate before a second open field)
    table.sort(cands, function(a, b) return a.score > b.score end)
    local picks, kinds = {}, {}
    local avoid = opts.avoid or {}   -- positions that already have a gate
    local function far(c)
        local md = math.huge
        for _, p in ipairs(picks) do md = math.min(md, c.pos:Distance(p.pos)) end
        for _, q in ipairs(avoid) do md = math.min(md, c.pos:Distance(q)) end
        return md
    end
    -- water is fine: gates may stand fully underwater on the ground (also on water maps)
    while #picks < count do
        breathe()
        local bestC, bestV
        for _, c in ipairs(cands) do
            local md = far(c)
            if md >= MIN_SPACING then
                local n = kinds[c.kind or "open"] or 0
                local v = math.min(md, 12000) * math.max(0.1, 0.5 + c.score) * (n == 0 and 2.2 or 1 / (1 + 0.6 * n))
                if not bestV or v > bestV then bestC, bestV = c, v end
            end
        end
        if not bestC then break end
        picks[#picks + 1] = bestC
        kinds[bestC.kind or "open"] = (kinds[bestC.kind or "open"] or 0) + 1
    end
    return picks, { scanned = scanned, candidates = #cands, count = count, space = space and true or false, mins = mins, maxs = maxs, reachedArea = reachedArea, kinds = kinds }
end

local LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local function randomAddress(used, group)
    local base = LETTERS:gsub("[" .. (group or ""):gsub("[%^%]%-%%]", "%%%0") .. "]", "")
    for _ = 1, 100 do
        local s, pool = "", base
        for _ = 1, 6 do
            local i = math.random(1, #pool)
            s = s .. pool:sub(i, i)
            pool = pool:sub(1, i - 1) .. pool:sub(i + 1)
        end
        if not used[s] then used[s] = true return s end
    end
end

-- remove earlier suggestions that were not saved
function AP.Clear()
    for _, e in ipairs(ents.GetAll()) do
        if e.AGPSuggested and not e.GateSpawnerSpawned then e:Remove() end
    end
end

-- spawn the picks as normal (not yet saved) gates + DHDs
-- count: how many gates (nil = by the map's size); never next to a gate the map already has
function AP.Suggest(ply, count)
    AP.Clear()
    local used, made, avoid = {}, {}, {}
    for _, g in ipairs(ents.FindByClass("stargate_*")) do
        if g.GetGateAddress then used[g:GetGateAddress()] = true end
        if g.IsStargate and not g.AGPSuggested then avoid[#avoid + 1] = g:GetPos() end
    end
    local picks, info = AP.Find({ count = count, avoid = avoid, manual = true })
    for i, p in ipairs(picks) do
        local t = TYPES[(i - 1) % #TYPES + 1]
        local gate = ents.Create(t.gate)
        if IsValid(gate) then
            gate:SetPos(p.thin and Vector(p.pos.x, p.pos.y, p.ground.z + gateBottom(t.gate) + 2) or p.pos)
            gate:SetAngles(Angle(0, p.yaw, 0))
            gate:Spawn()
            gate:Activate()
            if IsValid(gate:GetPhysicsObject()) then gate:GetPhysicsObject():EnableMotion(false) end
            if gate.SetGateGroup then gate:SetGateGroup(t.group) end
            if gate.SetLocale then gate:SetLocale(false) end
            local addr = randomAddress(used, t.group)
            if addr and gate.SetGateAddress then gate:SetGateAddress(addr) end
            if gate.SetGateName then gate:SetGateName("Gate " .. i) end
            gate.AGPSuggested = true
            made[#made + 1] = gate
            if p.dhd then
                local d = ents.Create(t.dhd)
                if IsValid(d) then
                    d:SetPos(p.dhd - Vector(0, 0, 14.8))
                    d:SetAngles(Angle(15, p.yaw, 0))
                    d:Spawn()
                    d:Activate()
                    if IsValid(d:GetPhysicsObject()) then d:GetPhysicsObject():EnableMotion(false) end
                    d.AGPSuggested = true
                    made[#made + 1] = d
                end
            end
        end
    end
    local kl = {}
    for k, n in pairs(info.kinds or {}) do kl[#kl + 1] = n .. " " .. k end
    MsgN(("[Ascension Gates] Gate suggestions for %s: %d gate(s) from %d good spots (%d floors scanned%s; %s)."):format(
        game.GetMap(), #picks, info.candidates, info.scanned, info.space and ", space map" or "", table.concat(kl, ", ")))
    return picks, info, made
end

-- the same without stopping the game: the scan runs a few milliseconds a tick, done(picks) is called at the end
-- (a big space map took 40 s in one go). One scan at a time.
function AP.SuggestAsync(ply, count, done)
    if AP.Scanning then return false end
    AP.Scanning = true
    local co = coroutine.create(function() return AP.Suggest(ply, count) end)
    hook.Add("Think", "AGP.AutoPlace.Scan", function()
        sliceEnd = SysTime() + 0.006
        local ok, picks = coroutine.resume(co)
        if coroutine.status(co) == "dead" then
            hook.Remove("Think", "AGP.AutoPlace.Scan")
            AP.Scanning = nil
            if not ok then ErrorNoHalt("[Ascension Gates] gate placing failed: " .. tostring(picks) .. "\n") end
            if done then done(ok and picks or {}) end
        end
    end)
    return true
end

concommand.Add("agp_gatespawner_suggest", function(p)
    if IsValid(p) and not (p:IsAdmin() or game.SinglePlayer()) then return end
    AP.Suggest(p)
end)

--##################################
--#### Automatic: a map without any spawner file gets its gates on its own
--##################################
local cvAuto = CreateConVar("stargate_gatespawner_auto", "1", { FCVAR_ARCHIVE }, "Ascension Gates: place gates by itself on maps without a gate spawner file (1 = on)")

local function system() return GetConVar("stargate_group_system"):GetBool() and "group" or "galaxy" end

function AP.AutoFile()
    return "agp_gatespawner/auto/" .. system() .. "/" .. game.GetMap():lower() .. ".txt"
end

-- the picks as a normal spawner file (same format as "Save map")
function AP.BuildFile(picks)
    local group = system() == "group"
    local used = {}
    local f = "[gatespawner]\nversion = " .. (group and "3 Group" or "3") .. "\n\n\n"
    for i, p in ipairs(picks) do
        local t = TYPES[(i - 1) % #TYPES + 1]
        local ang = Angle(0, p.yaw, 0)
        local pos = p.thin and Vector(p.pos.x, p.pos.y, p.ground.z + gateBottom(t.gate) + 2) or p.pos -- stands on a jetty
        f = f .. "[stargate]\nclassname=" .. t.gate .. "\nposition=" .. tostring(pos) .. "\nangles=" .. tostring(ang)
            .. "\naddress=" .. (randomAddress(used, t.group) or "") .. "\nname=Gate " .. i .. "\nprivate=false\n"
        if group then
            f = f .. "group=" .. string.Replace(t.group, "#", "!") .. "\nlocale=false\n"
        else
            f = f .. "galaxy=false\n"
        end
        if p.dhd then
            f = f .. "[dhd]\nclassname=" .. t.dhd .. "\nposition=" .. tostring(p.dhd - Vector(0, 0, 14.8)) .. "\nangles=" .. tostring(Angle(15, p.yaw, 0)) .. "\ndestroyed=false\n"
        end
    end
    return f
end

-- called by the gate spawner when the map has no own and no pack file. Returns the automatic file when there is one.
-- Nothing happens when switched off or when the map already has gates of its own.
function AP.EnsureAuto()
    if not cvAuto:GetBool() then return end
    local path = AP.AutoFile()
    if file.Exists(path, "DATA") then return path end
    for _, g in ipairs(ents.FindByClass("stargate_*")) do
        if IsValid(g) and g.IsStargate and not g.GateSpawnerSpawned and not g.AGPSuggested then return end
    end
    local picks, info = AP.Find()
    if #picks < 2 then
        local w = AP.LastWalk or {}
        MsgN("[Ascension Gates] No automatic gates for " .. game.GetMap() .. ": only " .. #picks .. " good spot(s) found (spawn points "
            .. tostring(w.spawns) .. ", walk starts " .. tostring(w.starts) .. ", reachable floors " .. tostring(w.reached) .. ", blocked steps " .. tostring(w.blocked) .. ", too steep " .. tostring(w.steep) .. ", tested " .. info.scanned .. ", good " .. info.candidates .. ").")
        return
    end
    file.CreateDir("agp_gatespawner/auto/" .. system())
    file.Write(path, AP.BuildFile(picks))
    local w = AP.LastWalk or {}
    MsgN(("[Ascension Gates] %s has no gate spawner file: placed %d gates by itself (%d good spots, %s reachable floors). Saved as data/%s"):format(
        game.GetMap(), #picks, info.candidates, tostring(w.reached), path))
    return path
end
