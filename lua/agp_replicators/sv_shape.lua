-- Replicators: the shape of the world, read instead of felt (owner 2026-11-05: "can we let it see and understand - not
-- guessing?"). The game hands over the shapes: the map's faces (GetBrushSurfaces), its terrain and the props built into
-- it (both from the map file itself), and every prop's physics shape. They go into a grid of 256-unit cells, read once
-- when the map is up (some 20-100 ms); props are read when a bug needs them (a few hundredths of a ms each).
-- R.Shape.Slice cuts all of it with a plane: the side view a bug plans its way over (sv_surfnav.lua).
-- The faces nothing is drawn on and the invisible clip walls come from the map's brushes (readBrushes).
-- Not read (the rays of sv_surfnav.lua find these): lumps the map stores packed.
local R = AGP.Rep
local S = R.Shape or {}
R.Shape = S

local CELL = 256
local function ck(x, y, z) return (x + 512) * 1048576 + (y + 512) * 1024 + (z + 512) end
local function bounds(v)
	local mn, mx = Vector(v[1]), Vector(v[1])
	for i = 2, #v do
		local q = v[i]
		if q.x < mn.x then mn.x = q.x end if q.y < mn.y then mn.y = q.y end if q.z < mn.z then mn.z = q.z end
		if q.x > mx.x then mx.x = q.x end if q.y > mx.y then mx.y = q.y end if q.z > mx.z then mx.z = q.z end
	end
	return mn, mx
end

local function add(v, kind)
	if #v < 3 then return end
	local mn, mx = bounds(v)
	local p = { v = v, mn = mn, mx = mx, k = kind }
	local x0, y0, z0 = math.floor(mn.x / CELL), math.floor(mn.y / CELL), math.floor(mn.z / CELL)
	local x1, y1, z1 = math.floor(mx.x / CELL), math.floor(mx.y / CELL), math.floor(mx.z / CELL)
	-- (a huge face - a whole flat map's floor - would fill thousands of cells: it goes on the short list of the big ones)
	if (x1 - x0 + 1) * (y1 - y0 + 1) * (z1 - z0 + 1) > 27 then S.big[#S.big + 1] = p
	else
		for x = x0, x1 do for y = y0, y1 do for z = z0, z1 do
			local k = ck(x, y, z)
			local c = S.cells[k]
			if not c then c = {} S.cells[k] = c end
			c[#c + 1] = p
		end end end
	end
	S.count[kind] = (S.count[kind] or 0) + 1
end

-- the map file: lumps, read with the game's own file access (works for Workshop maps too)
local function openBsp()
	local f = file.Open("maps/" .. game.GetMap() .. ".bsp", "rb", "GAME")
	if not f then return end
	if f:Read(4) ~= "VBSP" then f:Close() return end
	f:ReadLong()
	local L = {}
	for i = 0, 63 do L[i] = { ofs = f:ReadLong(), len = f:ReadLong(), ver = f:ReadLong(), packed = f:ReadLong() ~= 0 } end
	return f, L
end

-- terrain (displacements): each piece is a face of 4 corners with a grid of offsets; built here as quads. Which way the
-- grid runs over the corners is checked against the real terrain with a ray (both ways are in use in the tools' code)
local function readTerrain(f, L)
	for _, i in ipairs({ 3, 7, 12, 13, 26, 33 }) do if L[i].packed then S.note = (S.note or "") .. " terrain lump packed" return end end
	local function vec() return Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat()) end
	f:Seek(L[3].ofs) local verts = {} for i = 0, L[3].len / 12 - 1 do verts[i] = vec() end
	f:Seek(L[12].ofs) local edges = {} for i = 0, L[12].len / 4 - 1 do edges[i] = { f:ReadUShort(), f:ReadUShort() } end
	f:Seek(L[13].ofs) local se = {} for i = 0, L[13].len / 4 - 1 do se[i] = f:ReadLong() end
	local nd = math.floor(L[26].len / 176)
	if nd == 0 then return end
	local disp = {}
	for i = 0, nd - 1 do
		f:Seek(L[26].ofs + i * 176)
		local st = vec()
		local vs = f:ReadLong() f:ReadLong()
		local pow = f:ReadLong() f:ReadLong() f:ReadFloat() f:ReadLong()
		disp[i] = { st = st, vs = vs, pow = pow, face = f:ReadUShort() }
	end
	local bad = 0
	for i = 0, nd - 1 do
		local d = disp[i]
		f:Seek(L[7].ofs + d.face * 56 + 4)
		local fe, ne = f:ReadLong(), f:ReadShort()
		if ne == 4 and d.pow >= 1 and d.pow <= 4 then
			local c = {}
			for k = 0, 3 do
				local e = se[fe + k] or 0
				local ed = edges[math.abs(e)] or { 0, 0 }
				c[k] = verts[e >= 0 and ed[1] or ed[2]] or Vector()
			end
			-- the corner nearest the start comes first
			local best, bd = 0, math.huge
			for k = 0, 3 do local dd = c[k]:DistToSqr(d.st) if dd < bd then best, bd = k, dd end end
			local cr = {} for k = 0, 3 do cr[k] = c[(best + k) % 4] end
			local n = 2 ^ d.pow + 1
			f:Seek(L[33].ofs + d.vs * 20)
			local off = {}
			for k = 0, n * n - 1 do
				local v = vec() local dist = f:ReadFloat() f:ReadFloat()
				off[k] = v * dist
			end
			local function grid(way)
				local g = {}
				for y = 0, n - 1 do
					local t = y / (n - 1)
					local a, b
					if way == 1 then a, b = LerpVector(t, cr[0], cr[1]), LerpVector(t, cr[3], cr[2])
					else a, b = LerpVector(t, cr[0], cr[3]), LerpVector(t, cr[1], cr[2]) end
					for x = 0, n - 1 do g[y * n + x] = LerpVector(x / (n - 1), a, b) + off[y * n + x] end
				end
				return g
			end
			-- the check: a ray through a point inside the piece must hit the terrain there
			local nrm = (cr[1] - cr[0]):Cross(cr[3] - cr[0]) nrm:Normalize()
			local function err(g)
				local e = 0
				for _, k in ipairs({ math.floor(n * n / 2), n + 1, n * n - n - 2 }) do
					local p = g[k]
					local tr = util.TraceLine({ start = p + nrm * 48, endpos = p - nrm * 48, mask = MASK_PLAYERSOLID_BRUSHONLY })
					local tr2 = util.TraceLine({ start = p - nrm * 48, endpos = p + nrm * 48, mask = MASK_PLAYERSOLID_BRUSHONLY })
					local h = math.min(tr.Hit and tr.HitPos:Distance(p) or 99, tr2.Hit and tr2.HitPos:Distance(p) or 99)
					e = e + h
				end
				return e / 3
			end
			local g = grid(1)
			local e1 = err(g)
			if e1 > 3 then
				local g2 = grid(2)
				local e2 = err(g2)
				if e2 < e1 then g, e1 = g2, e2 end
			end
			if e1 > 6 then bad = bad + 1 end
			for y = 0, n - 2 do for x = 0, n - 2 do
				add({ g[y * n + x], g[y * n + x + 1], g[(y + 1) * n + x + 1], g[(y + 1) * n + x] }, "terrain")
			end end
		end
	end
	S.terrainBad = bad
	S.terrainPieces = nd
end

-- a model's physics shape as triangles in its own frame (a hidden prop of it, read once per model)
S.models = S.models or {}
function S.ModelTris(m, ph)
	local c = S.models[m]
	if c ~= nil then return c or nil end
	local e
	if not IsValid(ph) then
		e = ents.Create("prop_physics")
		if not IsValid(e) then return end
		e:SetModel(m) e:SetPos(Vector(0, 0, -16000)) e:Spawn()
		ph = e:GetPhysicsObject()
	end
	local t = false
	if IsValid(ph) then
		t = {}
		for _, h in ipairs(ph:GetMeshConvexes() or {}) do
			for i = 1, #h - 2, 3 do
				local a, b, cc = h[i], h[i + 1], h[i + 2]
				t[#t + 1] = { Vector(a.pos or a), Vector(b.pos or b), Vector(cc.pos or cc) }
			end
		end
	end
	if IsValid(e) then e:Remove() end
	S.models[m] = t
	return t or nil
end

-- props built into the map (trees, rocks, furniture): model, place and angle from the map file, their shape from the model
local function readStatic(f, L)
	if L[35].packed then S.note = (S.note or "") .. " game lump packed" return end
	f:Seek(L[35].ofs)
	local sp
	for i = 1, f:ReadLong() do
		local gid, fl, gv, go, gl = f:ReadLong(), f:ReadUShort(), f:ReadUShort(), f:ReadLong(), f:ReadLong()
		if gid == 1936749168 then sp = { fl = fl, v = gv, ofs = go, len = gl } end
	end
	if not sp or sp.fl ~= 0 then return end
	f:Seek(sp.ofs)
	local nd = f:ReadLong() local names = {}
	for i = 1, nd do names[i] = f:Read(128):gsub("%z.*", "") end
	local nl = f:ReadLong() f:Skip(nl * 2)
	local np = f:ReadLong()
	if np <= 0 then return end
	local size = math.floor((sp.len - (12 + nd * 128 + nl * 2)) / np)
	local list = {}
	for i = 1, np do
		local st = f:Tell()
		local p = Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
		local a = Angle(f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
		local mi = f:ReadUShort() f:ReadUShort() f:ReadUShort()
		local so = f:ReadByte()
		f:Seek(st + size)
		if so ~= 0 and names[mi + 1] then list[#list + 1] = { p, a, names[mi + 1] } end
	end
	local none = 0
	for _, q in ipairs(list) do
		local t = S.ModelTris(q[3])
		if t then
			local m = Matrix() m:Translate(q[1]) m:Rotate(q[2])
			for _, tri in ipairs(t) do add({ m * tri[1], m * tri[2], m * tri[3] }, "static") end
		else none = none + 1 end
	end
	S.staticProps, S.staticNoShape = #list, none
end

-- what the faces miss (2026-11-05: a fifth of gm_construct's walls): sides the map's compiler drops because nothing is
-- drawn on them (a "nodraw" back of a wall, a ledge's top no one sees) and the invisible clip walls. Both are only in
-- the map's brushes - solid boxes, each a set of planes. A side is the plane cut down by the brush's other planes.
-- Only the world's own brushes (walked from the map's tree; a door's would sit where it was built, not where it is now)
local NODRAW, SKY = 0x80, 0x6
local SOLIDISH, CLIP = bit.bor(CONTENTS_SOLID, CONTENTS_WINDOW, CONTENTS_GRATE), CONTENTS_PLAYERCLIP
local function clipPoly(v, n, d)   -- keeps the part behind the plane (n . x <= d)
	local o = {}
	for i = 1, #v do
		local a, b = v[i], v[i % #v + 1]
		local da, db = n:Dot(a) - d, n:Dot(b) - d
		if da <= 0.01 then o[#o + 1] = a end
		if (da < -0.01 and db > 0.01) or (da > 0.01 and db < -0.01) then o[#o + 1] = a + (b - a) * (da / (da - db)) end
	end
	return o
end
local function readBrushes(f, L)
	for _, i in ipairs({ 1, 5, 6, 10, 14, 17, 18, 19 }) do if L[i].packed then S.note = (S.note or "") .. " brush lumps packed" return end end
	f:Seek(L[1].ofs) local planes = {}
	for i = 0, L[1].len / 20 - 1 do planes[i] = { n = Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat()), d = f:ReadFloat() } f:ReadLong() end
	f:Seek(L[6].ofs) local tflags = {}
	for i = 0, L[6].len / 72 - 1 do f:Skip(64) tflags[i] = f:ReadLong() f:ReadLong() end
	-- the world's brushes: down its tree from model 0 to the leaves, and each leaf's list of brushes
	f:Seek(L[14].ofs + 36) local head = f:ReadLong()
	local nodes = L[5].ofs
	local lsize = L[10].ver == 0 and 56 or 32
	local f17 = L[17].ofs
	local mine, stack, n = {}, { head }, 0
	while #stack > 0 do
		local k = table.remove(stack)
		if k >= 0 then
			f:Seek(nodes + k * 32 + 4) stack[#stack + 1] = f:ReadLong() stack[#stack + 1] = f:ReadLong()
		else
			f:Seek(L[10].ofs + (-1 - k) * lsize + 24)
			local fb, nb = f:ReadUShort(), f:ReadUShort()
			if nb > 0 then f:Seek(f17 + fb * 2) for _ = 1, nb do mine[f:ReadUShort()] = true end end
		end
		n = n + 1 if n > 400000 then break end
	end
	local made, sides = 0, {}
	for bi in pairs(mine) do
		f:Seek(L[18].ofs + bi * 12)
		local first, num, cont = f:ReadLong(), f:ReadLong(), f:ReadLong()
		local solid, clip = bit.band(cont, SOLIDISH) ~= 0, bit.band(cont, CLIP) ~= 0
		if (solid or clip) and num >= 4 and num <= 64 then
			f:Seek(L[19].ofs + first * 8)
			for s = 1, num do local pn, ti = f:ReadUShort(), f:ReadShort() f:ReadShort() local bev = f:ReadShort() sides[s] = { pn = pn, ti = ti, bev = bit.band(bev, 0xFF) ~= 0 } end
			for s = 1, num do
				local sd = sides[s]
				local fl = tflags[sd.ti] or 0
				if not sd.bev and bit.band(fl, SKY) == 0 and (bit.band(fl, NODRAW) ~= 0 or not solid) then
					local P = planes[sd.pn]
					if P then
						local nv = P.n
						local a = math.abs(nv.z) < 0.9 and Vector(0, 0, 1) or Vector(1, 0, 0)
						local u = a:Cross(nv) u:Normalize()
						local w = nv:Cross(u)
						local c = nv * P.d
						local v = { c + u * 32768 + w * 32768, c - u * 32768 + w * 32768, c - u * 32768 - w * 32768, c + u * 32768 - w * 32768 }
						for o = 1, num do
							if o ~= s and #v >= 3 then local Q = planes[sides[o].pn] if Q then v = clipPoly(v, Q.n, Q.d) end end
						end
						if #v >= 3 then
							local mn, mx = bounds(v)
							if mx.x - mn.x < 20000 and mx.y - mn.y < 20000 and mx.z - mn.z < 20000 then add(v, clip and not solid and "clip" or "nodraw") made = made + 1 end
						end
					end
				end
			end
		end
	end
	S.brushFaces = made
end

-- how much the swarm looks (owner 2026-11-05: "4 steps... 4 is full scan... 1 is only some ping"), agp_rep_scan:
--   1 ping   a few rays round the bug and its goal, nothing read
--   2 radar  the full ring of rays, and the shapes of props near the way
--   3 map    and the map's faces and terrain
--   4 full   and the props built into the map, the faces nothing is drawn on, the invisible clip walls (the default)
R.cv.scan = R.cv.scan or CreateConVar("agp_rep_scan", "4", FCVAR_ARCHIVE, "Replicators: how much they see of the world's shape (1 ping, 2 radar, 3 map, 4 full)")
function S.Level() return math.Clamp(R.cv.scan:GetInt(), 1, 4) end

function S.Build()
	local t0 = SysTime()
	S.cells, S.big, S.count, S.note = {}, {}, {}, nil
	local lvl = S.Level()
	if lvl >= 3 then
		for _, f in ipairs(game.GetWorld():GetBrushSurfaces() or {}) do
			if not f:IsSky() and not f:IsWater() then add(f:GetVertices(), "world") end
		end
		local f, L = openBsp()
		if f then
			local ok, e = pcall(readTerrain, f, L) if not ok then S.note = (S.note or "") .. " terrain: " .. tostring(e) end
			if lvl >= 4 then
				ok, e = pcall(readStatic, f, L) if not ok then S.note = (S.note or "") .. " static: " .. tostring(e) end
				ok, e = pcall(readBrushes, f, L) if not ok then S.note = (S.note or "") .. " brushes: " .. tostring(e) end
			end
			f:Close()
		else S.note = "map file not readable" end
	end
	S.built, S.map, S.level, S.buildMs = true, game.GetMap(), lvl, (SysTime() - t0) * 1000
end

hook.Add("InitPostEntity", "AGPRepShape", function() timer.Simple(1, function() if not S.built then S.Build() end end) end)

-- every face near a box (map, terrain, map props)
local stamp = 0
function S.Query(mn, mx)
	if not S.built or S.map ~= game.GetMap() or S.level ~= S.Level() then S.Build() end
	stamp = stamp + 1
	local out = {}
	local function take(p)
		if p.s ~= stamp and p.mx.x >= mn.x and p.mn.x <= mx.x and p.mx.y >= mn.y and p.mn.y <= mx.y and p.mx.z >= mn.z and p.mn.z <= mx.z then
			p.s = stamp out[#out + 1] = p
		end
	end
	for x = math.floor(mn.x / CELL), math.floor(mx.x / CELL) do for y = math.floor(mn.y / CELL), math.floor(mx.y / CELL) do for z = math.floor(mn.z / CELL), math.floor(mx.z / CELL) do
		for _, p in ipairs(S.cells[ck(x, y, z)] or {}) do take(p) end
	end end end
	for _, p in ipairs(S.big) do take(p) end
	return out
end

-- a prop's triangles where it stands now (kept until it moves)
function S.EntTris(e)
	local c = e.AGPShape
	local p, a = e:GetPos(), e:GetAngles()
	if c and c.p == p and c.a == a then return c.t end
	local ph = e:GetPhysicsObject()
	local t = S.ModelTris(e:GetModel() or "", IsValid(ph) and ph or nil)
	if not t then e.AGPShape = { p = p, a = a, t = {} } return e.AGPShape.t end
	local w = {}
	for i, tri in ipairs(t) do w[i] = { e:LocalToWorld(tri[1]), e:LocalToWorld(tri[2]), e:LocalToWorld(tri[3]) } end
	e.AGPShape = { p = p, a = a, t = w }
	return w
end

-- the cut through everything with the plane through O spanned by U (along) and Z (up): segments in (along, up) numbers.
-- skip(e): props not to count (the bug itself, other bugs, players - R.Walkable decides)
function S.Slice(O, U, Z, x0, x1, y0, y1, walkable)
	local W = U:Cross(Z) W:Normalize()
	local d0 = W:Dot(O)
	local mn, mx = Vector(1e9, 1e9, 1e9), Vector(-1e9, -1e9, -1e9)
	for _, x in ipairs({ x0, x1 }) do for _, y in ipairs({ y0, y1 }) do
		local p = O + U * x + Z * y
		for _, q in ipairs({ p - W * 4, p + W * 4 }) do
			mn.x = math.min(mn.x, q.x) mn.y = math.min(mn.y, q.y) mn.z = math.min(mn.z, q.z)
			mx.x = math.max(mx.x, q.x) mx.y = math.max(mx.y, q.y) mx.z = math.max(mx.z, q.z)
		end
	end end
	local segs = {}
	local from   -- (which prop a cut comes from: a way over props is a player's build, not the map)
	local function cut(v)
		local pts = {}
		local nv = #v
		for i = 1, nv do
			local a, b = v[i], v[i % nv + 1]
			local da, db = W:Dot(a) - d0, W:Dot(b) - d0
			if (da <= 0 and db > 0) or (da > 0 and db <= 0) then
				local t = da / (da - db)
				local p = a + (b - a) * t - O
				pts[#pts + 1] = p:Dot(U) pts[#pts + 1] = p:Dot(Z)
			end
		end
		for i = 1, #pts - 3, 4 do segs[#segs + 1] = { pts[i], pts[i + 1], pts[i + 2], pts[i + 3], from } end
	end
	-- (scan level, agp_rep_scan: 1 and 2 do not read the map's shapes, 1 not even the props' - the rays alone)
	local lvl = S.Level()
	local polys = lvl >= 3 and S.Query(mn, mx) or {}
	for _, p in ipairs(polys) do cut(p.v) end
	if lvl >= 2 then
		for _, e in ipairs(ents.FindInBox(mn, mx)) do
			if IsValid(e) and e:GetSolid() ~= SOLID_NONE and walkable(e) and not e:IsWorld() then
				from = e
				for _, tri in ipairs(S.EntTris(e)) do cut(tri) end
			end
		end
	end
	return segs, #polys
end
