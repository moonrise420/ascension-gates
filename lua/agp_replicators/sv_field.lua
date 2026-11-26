-- The felt map (prototype - the swarm feels the world once and every bug walks on what it felt, instead of each bug
-- casting its own leg rays every tick: about 10 rays of 15 us each per bug per tick, 600 a tick for 60 bugs, for walls
-- the swarm already knew).
--
-- How: a grid every G units. Each grid point, the first time anyone asks, feels the map once - 6 rays along the axes,
-- the distance to the nearest surface they hit (to its plane: exact on flat walls and floors). Kept for everyone. What a
-- bug walks on is the soft version of that: each point the mean of its 27 neighbours - corners round off, a staircase
-- becomes a slope, small lips and cracks disappear. A bug's middle glides along the level H of that soft distance
-- (R.FieldWalk): no rays at all once the grid there is felt, the same for every bug, round every corner the same way.
-- Only the map (brushes): props, open air and falling go to the leg walker as before (agp_replicator.lua).
local R = AGP.Rep
local F = R.Field or {}
R.Field = F
local G = 12           -- the grid's step (units)
local RMAX = 48        -- how far a point feels (further: "nothing near")
local H = 14           -- the level its middle walks on: this far from the soft surface
F.G, F.RMAX, F.H = G, RMAX, H
local MASKF = MASK_PLAYERSOLID_BRUSHONLY
local floor = math.floor
local band = bit.band
-- (soft values: kept in NB small tables by key, not one big one - a big Lua table that grows is rebuilt at once when full,
-- up to 48 ms at 260 000 entries, a hitch the player saw)
local NB = 64
local function buckets() local t = {} for b = 0, NB - 1 do t[b] = {} end return t end
F.soft = (F.soft and F.soft[0]) and F.soft or buckets()
F.nsoft = F.nsoft or 0
F.n = F.n or 0          -- points felt
F.cpu = F.cpu or 0
-- (the normal walk. A new setting, not the old one's default turned round: servers that had the prototype's
-- agp_rep_fieldwalk saved as 0 would have stayed on legs)
R.cv.legwalk = R.cv.legwalk or CreateConVar("agp_rep_legwalk", "0", FCVAR_ARCHIVE, "Replicators: walk with their leg rays only (1) instead of on the swarm's felt map (0, normal)")
function R.FieldOn()
	local t = R.TestOn
	if t and t.legs then return false end
	return (t and t.field) or not R.cv.legwalk:GetBool()
end
-- (the map's own fixed brushes only: a door, a moving platform or a breakable wall felt once stayed in the felt map where
-- it was - an open door felt shut. Near those, as near props, bugs walk with their legs, agp_replicator.lua)
local function worldOnly(e) return e:IsWorld() end
local function feltFilter() return not (R.TestOff and R.TestOff.feltWorld) and worldOnly or nil end   -- (TestOff: test runs only)

-- the map is felt in blocks of 4 x 4 x 4 points (48 units), not point by point - the same values, a fraction of the
-- work:
-- * air left out: a block with no face of the map within reach (sv_shape.lua reads every face, the terrain and the map's
--   own props when the map is up) is all "nothing near" - one look, no rays; one deep in the ground all solid
-- * shared rays: along each line of a block one ray serves every point up to the first face it meets (each point's own
--   ray would have met that same face) - about a quarter of the rays
-- * each block kept as 64 bytes (the distance in half units): a fraction of the memory, saved per map (F.Save) and read
--   back while the map loads (F.Load) - a map is felt once, not every game
-- * a quiet feeler fills it in round the players while there is time (the Tick hook further down)
local CS = 4                 -- points along a block's edge
local CN = CS * CS * CS
local AIR, SOLID = 1, 2      -- a whole block of one kind (else a string of CN bytes)
F.ch = F.ch or {}
F.nch = F.nch or 0           -- blocks kept as bytes
-- (a cap: on a big map explored for hours the felt map only grows. Past LIMIT blocks of bytes (about 20 MB) it starts over;
-- what is not felt again yet is walked with the legs meanwhile)
local LIMIT = 150000
local SOFTLIMIT = 800000
F.resets = F.resets or 0
local function ckey(ci, cj, ck) return (ci + 1024) + (cj + 1024) * 2048 + (ck + 1024) * 4194304 end
local char, byte = string.char, string.byte
local function enc(v) local q = floor((v + G) * 2 + 0.5) if q < 0 then q = 0 elseif q > 255 then q = 255 end return q end

-- (a key for each grid point, for the soft values: the map is at most 32768 across, 2731 steps of 12 - fits a Lua number)
local function key(i, j, k) return (i + 4096) + (j + 4096) * 8192 + (k + 4096) * 67108864 end
local AX = { Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(0, 0, 1), Vector(0, 0, -1) }

-- (feeling has a budget a tick for the whole swarm: 1.5 ms of single points at a fresh building with 60 bugs was 2 fps,
-- legs alone 12. A block costs about 1-2 ms: about one a tick when bugs ask; the quiet feeler has its own. What is not
-- felt yet is walked with the legs meanwhile)
local BUDGET = 0.001
F.tick, F.spent = 0, 0
-- (what bugs ask for: an allowance that builds up each tick, a block felt only while it has room - a block costs 1-2 ms,
-- and "only while under 1 ms this tick" still felt one every tick. A few bugs: 1 ms a tick; a big swarm walks with its
-- legs where nothing is felt yet anyway: 0.3 ms - the first minute of 60 bugs at a fresh building was 2 fps)
local askAllow, askTick = 0, 0
local function budgetLeft(b)
	local tk = engine.TickCount()
	if F.tick ~= tk then
		F.tick, F.spent = tk, 0
		local big = (R.Count and R.Count("bugs") or 0) > 20
		askAllow = math.min(askAllow + (big and 0.0003 or BUDGET) * R.Ease(), 0.003)
	end
	if F.testBudget then return F.spent < F.testBudget end   -- (test runs only)
	-- (the way across the map checks its steps on the felt map, sv_nav.lua: it has its own time budget and gives way)
	if not b and F.force then return true end
	-- (test runs only, A/B: a few bugs feel what they need at once - up to 8 ms a tick - instead of walking with their
	-- legs that tick and the felt map the next: the author's free play wobbled where nothing was felt yet)
	if not b and R.TestOn and R.TestOn.feltMust and (R.Count and R.Count("bugs") or 0) <= 5 then return F.spent < 0.008 end
	if b then return F.spent < b end
	return askAllow > 0
end

local function shapeReady()
	local S = R.Shape
	return S and S.built and S.map == game.GetMap() and not S.note and (S.level or 0) >= 4 and S
end

-- one block felt: AIR, SOLID or its CN bytes
local function feelBlock(ci, cj, ck)
	local t0 = SysTime()
	local i0, j0, k0 = ci * CS, cj * CS, ck * CS
	local res
	local S = shapeReady()
	if S then
		-- (no face within reach of any of its points: all air, or all inside the ground)
		local mn = Vector(i0 * G - RMAX - 2, j0 * G - RMAX - 2, k0 * G - RMAX - 2)
		local mx = Vector((i0 + CS - 1) * G + RMAX + 2, (j0 + CS - 1) * G + RMAX + 2, (k0 + CS - 1) * G + RMAX + 2)
		if #S.Query(mn, mx) == 0 then
			local mid = Vector((i0 + 1.5) * G, (j0 + 1.5) * G, (k0 + 1.5) * G)
			res = band(util.PointContents(mid), CONTENTS_SOLID) ~= 0 and SOLID or AIR
		end
	end
	if not res then
		local P, v, ss, done = {}, {}, {}, {}
		local filt = feltFilter()
		for n = 1, CN do
			local a = n - 1
			local p = Vector((i0 + a % CS) * G, (j0 + floor(a / CS) % CS) * G, (k0 + floor(a / (CS * CS))) * G)
			P[n], v[n], ss[n] = p, RMAX, 0
			-- (solid to PointContents and to a world-only ray: inside the map's solid. Solid to PointContents alone: inside
			-- a door or another brush entity - felt as open, see worldOnly)
			if band(util.PointContents(p), CONTENTS_SOLID) ~= 0 and util.TraceLine({ start = p, endpos = p + AX[5], mask = MASKF, filter = filt }).StartSolid then
				done[n] = -G
			end
		end
		local line = {}
		for a = 1, 6 do
			local d = AX[a]
			local along = a <= 2 and 1 or (a <= 4 and 2 or 3)
			local back = a % 2 == 0
			for u = 0, CS - 1 do for w = 0, CS - 1 do
				for s = 0, CS - 1 do
					local t = back and (CS - 1 - s) or s
					if along == 1 then line[s + 1] = 1 + t + u * CS + w * CS * CS
					elseif along == 2 then line[s + 1] = 1 + u + t * CS + w * CS * CS
					else line[s + 1] = 1 + u + w * CS + t * CS * CS end
				end
				-- (one ray from the first point not reached yet, far enough for the rest of the line plus RMAX)
				local s = 1
				while s <= CS do
					local n = line[s]
					if done[n] then s = s + 1
					else
						local len = (CS - s) * G + RMAX
						local tr = util.TraceLine({ start = P[n], endpos = P[n] + d * len, mask = MASKF, filter = filt })
						if tr.StartSolid then
							-- (under a displacement - freespace13's grass - a point is not solid to PointContents but all its rays
							-- start solid: inside the ground (strict scene 3). Only some: it lies on a wall's face - 0 away, not
							-- inside (strict scene 5))
							ss[n] = ss[n] + 1
							s = s + 1
						elseif not tr.Hit then
							break
						else
							local hd = tr.Fraction * len
							local hp, hn = tr.HitPos, tr.HitNormal
							local s2 = s
							while s2 <= CS do
								local dist = hd - (s2 - s) * G
								if dist < 0 then break end   -- (past the face: its own ray)
								local m = line[s2]
								if not done[m] and dist <= RMAX then
									local dd = (P[m] - hp):Dot(hn)
									if dd < -0.5 then ss[m] = 6   -- (the face met from behind: inside)
									elseif dd < v[m] then v[m] = math.max(dd, 0) end
								end
								s2 = s2 + 1
							end
							s = s2
						end
					end
				end
			end end
		end
		local b, allA, allS = {}, true, true
		for n = 1, CN do
			local val = done[n] or (ss[n] >= 6 and -G or v[n])
			if val ~= RMAX then allA = false end
			if val ~= -G then allS = false end
			b[n] = enc(val)
		end
		res = allA and AIR or (allS and SOLID or char(unpack(b, 1, CN)))
	end
	if F.nch >= LIMIT then F.ch, F.soft, F.nch, F.nsoft, F.resets = {}, buckets(), 0, 0, F.resets + 1 end
	if type(res) == "string" then F.nch = F.nch + 1 end
	F.ch[ckey(ci, cj, ck)] = res
	F.n = F.n + CN
	F.dirty = true
	local dt = SysTime() - t0
	F.cpu, F.spent = F.cpu + dt, F.spent + dt
	return res
end
F.FeelBlock = feelBlock

local function raw(i, j, k)
	local ci, cj, ck = floor(i / CS), floor(j / CS), floor(k / CS)
	local c = F.ch[ckey(ci, cj, ck)]
	if c == nil then
		if not budgetLeft() then return nil end
		local s0 = F.spent
		c = feelBlock(ci, cj, ck)
		askAllow = askAllow - (F.spent - s0)
	end
	local v
	if c == AIR then v = RMAX elseif c == SOLID then v = -G
	else v = byte(c, 1 + (i - ci * CS) + (j - cj * CS) * CS + (k - ck * CS) * CS * CS) * 0.5 - G end
	-- (the players' frozen props, sv_fieldprops.lua: the nearer of the two; nil - near a prop not felt yet: not felt)
	local PR = F.PropRaw
	if PR then
		local pv = PR(i, j, k)
		if pv == nil then return nil end
		if pv and pv < v then v = pv end
	end
	return v
end
F.Raw = raw

-- (nil anywhere below: not felt yet - the leg walker this tick)
local function soft(i, j, k)
	local kk = key(i, j, k)
	local sb = F.soft[kk % NB]
	local v = sb[kk]
	if v then return v end
	local s = 0
	for di = -1, 1 do for dj = -1, 1 do for dk = -1, 1 do
		local r = raw(i + di, j + dj, k + dk)
		if not r then return nil end
		s = s + r
	end end end
	-- (never further than the point itself felt: the mean of a thin thing's neighbours is too far - freespace13's
	-- concrete pillar, 16 x 20: 4 from its face the mean said 13, the level ran 4 off it and bugs climbing there had
	-- their middle in it, strict scene 5. Creases still round off: there the mean is the nearer one)
	v = math.min(s / 27, raw(i, j, k))
	if F.nsoft >= SOFTLIMIT then F.soft, F.nsoft = buckets(), 0 sb = F.soft[kk % NB] end
	sb[kk] = v
	F.nsoft = F.nsoft + 1
	return v
end

-- the soft values in a box of grid points forgotten (a prop came, moved or went there: sv_fieldprops.lua)
function F.ForgetSoft(i0, j0, k0, i1, j1, k1)
	for i = i0, i1 do for j = j0, j1 do for k = k0, k1 do
		local kk = key(i, j, k)
		local sb = F.soft[kk % NB]
		if sb[kk] then sb[kk] = nil F.nsoft = F.nsoft - 1 end
	end end end
end

-- (v2,: v1 read the soft grid 7 x 8 times per check - the slope by 6 extra distance reads - 4 checks a step and a new
-- Vector each: 60 bugs, 2 fps. Now one read of the cell's 8 corners gives the distance AND its slope (the blend's own
-- derivative), plain numbers, Vectors only for the answer)
local sqrt, abs = math.sqrt, math.abs

-- the soft distance and its slope (per unit) at x,y,z: d, gx, gy, gz - or nil (not felt yet)
local function sample(x, y, z)
	x, y, z = x / G, y / G, z / G
	local i, j, k = floor(x), floor(y), floor(z)
	local fx, fy, fz = x - i, y - j, z - k
	local a, b, c, d = soft(i, j, k), soft(i + 1, j, k), soft(i, j + 1, k), soft(i + 1, j + 1, k)
	if not (a and b and c and d) then return nil end
	local e, f, g, h = soft(i, j, k + 1), soft(i + 1, j, k + 1), soft(i, j + 1, k + 1), soft(i + 1, j + 1, k + 1)
	if not (e and f and g and h) then return nil end
	local ux, uy, uz = 1 - fx, 1 - fy, 1 - fz
	local c00, c10, c01, c11 = a * ux + b * fx, c * ux + d * fx, e * ux + f * fx, g * ux + h * fx
	local c0, c1 = c00 * uy + c10 * fy, c01 * uy + c11 * fy
	local dx = ((b - a) * uy + (d - c) * fy) * uz + ((f - e) * uy + (h - g) * fy) * fz
	local dy = (c10 - c00) * uz + (c11 - c01) * fz
	return c0 * uz + c1 * fz, dx / G, dy / G, (c1 - c0) / G
end

-- the soft distance at p (nil: not felt yet), and which way is away from the surface there
function F.Dist(p) return (sample(p.x, p.y, p.z)) end
function F.Normal(p)
	local d, gx, gy, gz = sample(p.x, p.y, p.z)
	if not d then return nil end
	local l = sqrt(gx * gx + gy * gy + gz * gz)
	if l < 1e-4 then return nil end
	return Vector(gx / l, gy / l, gz / l)
end

-- onto the level H from x,y,z, along the slope: x, y, z, nx, ny, nz - or nil and why
-- (a soft slope is less than 1 a unit: it steps by (d - H) / slope, so it lands in 1-2 steps, not 4)
local function onto3(x, y, z)
	for _ = 1, 4 do
		local d, gx, gy, gz = sample(x, y, z)
		if not d then return nil, "not felt yet" end
		if d > RMAX - 2 then return nil, "no surface near" end
		local l = sqrt(gx * gx + gy * gy + gz * gz)
		if l < 0.05 then return nil, "no slope (a thin gap or a ridge)" end
		gx, gy, gz = gx / l, gy / l, gz / l
		local off = d - H
		if abs(off) < 0.3 then return x, y, z, gx, gy, gz end
		off = off / l
		if off > 24 then off = 24 elseif off < -24 then off = -24 end
		x, y, z = x - gx * off, y - gy * off, z - gz * off
	end
	return nil, "did not settle on the level"
end
function F.Onto(p)
	local x, y, z, nx, ny, nz = onto3(p.x, p.y, p.z)
	if not x then return nil, y end
	return Vector(x, y, z), Vector(nx, ny, nz)
end

-- what the felt-map walking did lately, for tests and clips: b.FieldWhy (the last give-up), R.Stat counts, F.ms / F.steps
F.ms, F.steps = F.ms or 0, F.steps or 0
local function giveUp(b, why)
	b.FieldC, b.FieldWhy = nil, why
	-- (not felt there yet: the legs for a quarter of a second, not a new try every tick - each try asked for a planned way
	-- and found props first; with the felt map still empty that cost 7 % of the server, 5 fps against legs' 12)
	-- (only in a big swarm: a few bugs try again next tick - on its legs for a quarter of a second at an edge a bug fell,
	-- the strict cliff 0 of 3)
	if why:find("not felt yet", 1, true) and (R.Count and R.Count("bugs") or 0) > 20 then b.FieldWaitT = CurTime() + 0.25 end
	R.Stat("felt map gave up: " .. why)
	return nil
end

-- one step of a bug on the felt map: where its body goes (on the surface), its up and its forward - or nil (the leg
-- walker then: no surface near, not felt yet, a goal it cannot head for along the surface)
-- (from where its body is, every tick; the target 0.08 s ahead - the shadow controller needs that long to get there, one
-- tick ahead made them walk at a fifth of their speed, agp_replicator.lua)
function R.FieldWalk(b, pos, up, fwd, goalPos, speed, dt)
	local t0 = SysTime()
	local cx, cy, cz, nx, ny, nz = onto3(pos.x + up.x * H, pos.y + up.y * H, pos.z + up.z * H)
	if not cx then F.ms = F.ms + (SysTime() - t0) * 1000 return giveUp(b, "here: " .. cy) end
	local dx, dy, dz
	local gl
	if goalPos then
		local tx, ty, tz = goalPos.x - cx, goalPos.y - cy, goalPos.z - cz
		gl = sqrt(tx * tx + ty * ty + tz * tz)
		local s = tx * nx + ty * ny + tz * nz
		tx, ty, tz = tx - nx * s, ty - ny * s, tz - nz * s
		local tl = sqrt(tx * tx + ty * ty + tz * tz)
		-- (within 20 of the goal: stand)
		if gl >= 20 and tl > 4 then
			dx, dy, dz = tx / tl, ty / tl, tz / tl
		elseif gl >= 20 and R.WalkDir then
			-- (the goal straight out from the surface it is on - behind a wall, above a ceiling: the leg walker's rules)
			local w = R.WalkDir(b, pos, Vector(nx, ny, nz), goalPos)
			if w then dx, dy, dz = w.x, w.y, w.z end
		end
	end
	local x2, y2, z2, mx, my, mz = cx, cy, cz, nx, ny, nz
	if dx then
		-- (turning: not at once - at most about 45 degrees a step)
		local s = fwd.x * nx + fwd.y * ny + fwd.z * nz
		local fx, fy, fz = fwd.x - nx * s, fwd.y - ny * s, fwd.z - nz * s
		local fl = sqrt(fx * fx + fy * fy + fz * fz)
		if fl > 0.01 then
			fx, fy, fz = fx / fl, fy / fl, fz / fl
			local cosA = fx * dx + fy * dy + fz * dz
			if cosA < 0.7 and cosA > -0.95 then
				dx, dy, dz = fx + dx, fy + dy, fz + dz
				local l = sqrt(dx * dx + dy * dy + dz * dz)
				dx, dy, dz = dx / l, dy / l, dz / l
			end
		end
		local ahead = math.min(speed * 0.08, math.max(1, gl - 10))
		local why
		x2, y2, z2, mx, my, mz = onto3(cx + dx * ahead, cy + dy * ahead, cz + dz * ahead)
		if not x2 then
			why = y2
			-- (half as far: round a tight corner the level bends faster than one step)
			x2, y2, z2, mx, my, mz = onto3(cx + dx * ahead * 0.5, cy + dy * ahead * 0.5, cz + dz * ahead * 0.5)
			if not x2 then F.ms = F.ms + (SysTime() - t0) * 1000 return giveUp(b, "ahead: " .. why) end
		end
		-- (where a floor meets a wall the level has an inner crease: a step into it is pushed straight back. Barely moved
		-- and the goal still away: once more, the way to the goal along the surface it was pushed onto - up the wall)
		local mvx, mvy, mvz = x2 - cx, y2 - cy, z2 - cz
		if goalPos and mvx * mvx + mvy * mvy + mvz * mvz < (ahead * 0.4) ^ 2 then
			local tx, ty, tz = goalPos.x - x2, goalPos.y - y2, goalPos.z - z2
			local sm = tx * mx + ty * my + tz * mz
			tx, ty, tz = tx - mx * sm, ty - my * sm, tz - mz * sm
			local tl = sqrt(tx * tx + ty * ty + tz * tz)
			if tl > 4 then
				local x3, y3, z3, ox, oy, oz = onto3(x2 + tx / tl * ahead, y2 + ty / tl * ahead, z2 + tz / tl * ahead)
				if x3 then
					x2, y2, z2, mx, my, mz = x3, y3, z3, ox, oy, oz
					R.Stat("felt map: round an inner crease")
				end
			end
		end
	end
	b.FieldC, b.FieldWhy = Vector(x2, y2, z2), nil
	local m = Vector(mx, my, mz)
	local f = Vector(x2 - cx, y2 - cy, z2 - cz)
	f = f - m * f:Dot(m)
	if f:LengthSqr() < 1e-4 then f = fwd - m * fwd:Dot(m) end
	if f:LengthSqr() < 1e-4 then f = m:Angle():Up() end
	f:Normalize()
	-- (its body is a box about 40 long, not a point: it rests on the highest of what is under its front, its middle and its
	-- back - as its legs would reach up. On the smooth level alone a curb 8 high was only 6 up where the front met its face:
	-- the front pushed against the face for 2 s, then the bug popped over or turned along it - watching on freespace13, "it
	-- does not glide over the steps"; curb probe. Going down it stays up till its back has left the top)
	if not (R.TestOff and R.TestOff.feltLift) then
		local lift = 0
		for _, s in ipairs({ 16, -12 }) do
			local qx, qy, qz = onto3(x2 + f.x * s, y2 + f.y * s, z2 + f.z * s)
			if qx then
				local d = (qx - x2) * mx + (qy - y2) * my + (qz - z2) * mz
				if d > lift then lift = d end
			end
		end
		if lift > 20 then lift = 20 end
		if lift > 0.5 then x2, y2, z2 = x2 + mx * lift, y2 + my * lift, z2 + mz * lift R.Stat("felt map: body lifted over a step") end
	end
	F.steps = F.steps + 1
	F.ms = F.ms + (SysTime() - t0) * 1000
	return Vector(x2 - mx * H, y2 - my * H, z2 - mz * H), m, f, dx ~= nil
end

-- the felt map per map on disk (data/agp_replicators/felt_<map>.dat): written when the map ends, read back while the next
-- game on it loads - before the player is in, so it costs them nothing. "AGPFELT1", the map file's size (another version of
-- the map: not read), the grid, then each block: its key, 1 = air, 2 = solid or 3 and its CN bytes
local FVER = "AGPFELT1\n"
local function feltFile() return "agp_replicators/felt_" .. game.GetMap():lower():gsub("[^%w_]", "_") .. ".dat" end
local function mapStamp() return file.Size("maps/" .. game.GetMap() .. ".bsp", "GAME") or 0 end
function F.Save()
	if not F.dirty or (R.TestOn and R.TestOn.feltNoSave) then return end
	local t0 = SysTime()
	file.CreateDir("agp_replicators")
	local f = file.Open(feltFile(), "wb", "DATA")
	if not f then return end
	local n = 0
	for _ in pairs(F.ch) do n = n + 1 end
	f:Write(FVER)
	f:WriteULong(mapStamp())
	f:WriteULong(G * 1000 + RMAX)
	f:WriteULong(n)
	for k, c in pairs(F.ch) do
		f:WriteDouble(k)
		if c == AIR then f:WriteByte(1) elseif c == SOLID then f:WriteByte(2) else f:WriteByte(3) f:Write(c) end
	end
	f:Close()
	F.dirty = false
	F.saved = { blocks = n, ms = (SysTime() - t0) * 1000 }
end
function F.Load()
	if R.TestOn and R.TestOn.feltNoLoad then return false end
	local f = file.Open(feltFile(), "rb", "DATA")
	if not f then return false end
	local ok = f:Read(#FVER) == FVER and f:ReadULong() == mapStamp() and f:ReadULong() == G * 1000 + RMAX
	if not ok then f:Close() return false end
	local t0 = SysTime()
	local n = f:ReadULong()
	local ch, nch = {}, 0
	for _ = 1, n do
		local k = f:ReadDouble()
		local t = f:ReadByte()
		if t == 1 then ch[k] = AIR elseif t == 2 then ch[k] = SOLID
		elseif t == 3 then ch[k] = f:Read(CN) nch = nch + 1
		else break end
	end
	f:Close()
	F.ch, F.nch, F.n, F.dirty = ch, nch, n * CN, false
	F.soft, F.nsoft = buckets(), 0
	F.loaded = { blocks = n, ms = (SysTime() - t0) * 1000 }
	return true
end
-- (forgets everything felt: tests that start cold)
function F.Clear() F.ch, F.nch, F.soft, F.nsoft, F.n, F.dirty = {}, 0, buckets(), 0, 0, false end
hook.Add("InitPostEntity", "AGPRepFeltLoad", function() F.Load() end)
hook.Add("ShutDown", "AGPRepFeltSave", function() F.Save() end)

-- the quiet feeler: the blocks round the players (round the spawn points while nobody is in yet - the map loading), the
-- nearest 256-unit cells with faces of the map first. 5 ms a tick while nobody is in, 3 ms with no bug about, 0.3 ms while
-- a swarm walks (it asks for its own blocks then). So a place is mostly felt before a swarm gets there.
local CELL = 256
local cellDone = {}
local idleCo, idleSaid
-- (an allowance that builds up each tick: a block costs 1-2 ms, so "only if under 0.3 ms this tick" still felt one a tick
-- - 12 % of the server with a swarm about. Now it feels only as often as the allowance has room)
local idleAllow, idleTick = 0, 0
local function idleRate()
	if #player.GetAll() == 0 then return 0.005 end
	return next(R.bugs or {}) and 0.0002 * R.Ease() or 0.003
end
local function idleBudget()
	local tk = engine.TickCount()
	if idleTick ~= tk then idleTick = tk idleAllow = math.min(idleAllow + idleRate(), 0.006) end
	return idleAllow > 0 and 1 or -1
end
local function idleSpent(dt) idleAllow = idleAllow - dt end
local function cellHasFaces(S, x, y, z)
	local mn = Vector(x * CELL - RMAX, y * CELL - RMAX, z * CELL - RMAX)
	local mx = Vector(mn.x + CELL + 2 * RMAX, mn.y + CELL + 2 * RMAX, mn.z + CELL + 2 * RMAX)
	return #S.Query(mn, mx) > 0
end
local function centres()
	local c = {}
	for _, p in ipairs(player.GetAll()) do c[#c + 1] = p:GetPos() end
	if #c == 0 then for _, e in ipairs(ents.FindByClass("info_player_start")) do c[#c + 1] = e:GetPos() if #c >= 4 then break end end end
	return c
end
local function idleRun()
	local last
	while true do
		local S = shapeReady()
		local cs = S and centres() or {}
		-- (the list again only once someone moved a cell's width - building it every tick cost more than it saves)
		local moved = not last or #cs ~= #last
		if not moved then for i, c in ipairs(cs) do if c:DistToSqr(last[i]) > CELL * CELL then moved = true break end end end
		if not S or #cs == 0 or not moved then coroutine.yield()
		else
			last = cs
			local list = {}
			for _, c in ipairs(cs) do
				local cx, cy, cz = floor(c.x / CELL), floor(c.y / CELL), floor(c.z / CELL)
				for x = cx - 6, cx + 6 do for y = cy - 6, cy + 6 do for z = cz - 3, cz + 3 do
					local k = ckey(x, y, z)
					if not cellDone[k] then list[#list + 1] = { k, x, y, z, (x - cx) ^ 2 + (y - cy) ^ 2 + (z - cz) ^ 2 } end
				end end end
			end
			table.sort(list, function(a, b) return a[5] < b[5] end)
			for _, e in ipairs(list) do
				if not cellDone[e[1]] then
					cellDone[e[1]] = true
					while idleBudget() < 0 or not budgetLeft(0.002) do coroutine.yield() end
					local q0 = SysTime()
					local has = cellHasFaces(S, e[2], e[3], e[4])
					F.spent = F.spent + (SysTime() - q0)   -- (the look counts too: many empty cells in one tick were a hitch)
					idleSpent(SysTime() - q0)
					if has then
						local B = G * CS
						local i0, i1 = floor((e[2] * CELL - RMAX) / B), floor(((e[2] + 1) * CELL + RMAX) / B)
						local j0, j1 = floor((e[3] * CELL - RMAX) / B), floor(((e[3] + 1) * CELL + RMAX) / B)
						local k0, k1 = floor((e[4] * CELL - RMAX) / B), floor(((e[4] + 1) * CELL + RMAX) / B)
						for ci = i0, i1 do for cj = j0, j1 do for ck = k0, k1 do
							if F.ch[ckey(ci, cj, ck)] == nil then
								while idleBudget() < 0 or not budgetLeft(0.002) do coroutine.yield() end
								local f0 = SysTime()
								feelBlock(ci, cj, ck)
								idleSpent(SysTime() - f0)
								F.idleBlocks = (F.idleBlocks or 0) + 1
							end
						end end end
					end
				end
			end
		end
	end
end
hook.Add("Tick", "AGPRepFeltIdle", function()
	if not R.FieldOn() or (F.testBudget and F.testBudget < 0) or (R.TestOn and R.TestOn.feltNoIdle) then return end
	if not idleCo or coroutine.status(idleCo) == "dead" then idleCo = coroutine.create(idleRun) end
	local ok, err = coroutine.resume(idleCo)
	if not ok then
		idleCo = nil
		if not idleSaid then idleSaid = true ErrorNoHalt("AGP felt map, quiet feeler: " .. tostring(err) .. "\n") end
	end
end)
-- (a new map, or the map cleaned up and reloaded: the cells are looked at again)
hook.Add("PostCleanupMap", "AGPRepFeltIdle", function() cellDone = {} idleCo = nil end)
