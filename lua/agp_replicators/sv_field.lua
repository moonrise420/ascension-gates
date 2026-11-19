-- The felt map (prototype, owner 2026-11-17: "build the prototype" - the swarm feels the world once and every bug walks
-- on what it felt, instead of each bug casting its own leg rays every tick: about 10 rays of 15 us each per bug per tick,
-- 600 a tick for 60 bugs, for walls the swarm already knew).
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
F.raw = F.raw or {}
F.soft = F.soft or {}
F.n = F.n or 0
F.cpu = F.cpu or 0
R.cv.fieldwalk = R.cv.fieldwalk or CreateConVar("agp_rep_fieldwalk", "0", FCVAR_ARCHIVE, "Replicators: walk on the swarm's felt map (prototype, 1) or with their leg rays only (0)")

-- (a key for each grid point: the map is at most 32768 across, 2731 steps of 12 - fits a Lua number exactly)
local function key(i, j, k) return (i + 4096) + (j + 4096) * 8192 + (k + 4096) * 67108864 end
local AX = { Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(0, 0, 1), Vector(0, 0, -1) }

-- (feeling costs 6 rays a point: 60 bugs at a fresh building wanted 100 000 points in 20 s, 9 s of work - 2 fps. Now at
-- most BUDGET a tick for the whole swarm; what is not felt yet is walked with the legs as before, and filled in meanwhile)
local BUDGET = 0.0015
F.tick, F.spent = 0, 0
local function raw(i, j, k)
	local kk = key(i, j, k)
	local v = F.raw[kk]
	if v then return v end
	local tk = engine.TickCount()
	if F.tick ~= tk then F.tick, F.spent = tk, 0 end
	if F.spent > BUDGET then return nil end
	local t0 = SysTime()
	local p = Vector(i * G, j * G, k * G)
	if band(util.PointContents(p), CONTENTS_SOLID) ~= 0 then
		v = -G   -- (inside the map's solid)
	else
		v = RMAX
		for a = 1, 6 do
			local tr = util.TraceLine({ start = p, endpos = p + AX[a] * RMAX, mask = MASKF })
			if tr.Hit and not tr.StartSolid then
				local d = (p - tr.HitPos):Dot(tr.HitNormal)
				if d >= 0 and d < v then v = d end
			end
		end
	end
	F.raw[kk] = v
	F.n = F.n + 1
	local dt = SysTime() - t0
	F.cpu = F.cpu + dt
	F.spent = F.spent + dt
	return v
end

-- (nil anywhere below: not felt yet - the leg walker this tick)
local function soft(i, j, k)
	local kk = key(i, j, k)
	local v = F.soft[kk]
	if v then return v end
	local s = 0
	for di = -1, 1 do for dj = -1, 1 do for dk = -1, 1 do
		local r = raw(i + di, j + dj, k + dk)
		if not r then return nil end
		s = s + r
	end end end
	v = s / 27
	F.soft[kk] = v
	return v
end

-- (v2, 2026-11-17: v1 read the soft grid 7 x 8 times per check - the slope by 6 extra distance reads - 4 checks a step and
-- a new Vector each: 60 bugs, 2 fps. Now one read of the cell's 8 corners gives the distance AND its slope (the blend's own
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
	F.steps = F.steps + 1
	F.ms = F.ms + (SysTime() - t0) * 1000
	return Vector(x2 - mx * H, y2 - my * H, z2 - mz * H), m, f, dx ~= nil
end
