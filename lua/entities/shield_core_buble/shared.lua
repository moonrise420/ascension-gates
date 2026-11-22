if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Shield Core Buble"
ENT.WireDebugName = "Shield Core Buble"
ENT.Author = "Madman07"
ENT.Instructions= ""
ENT.Contact = "madman097@gmail.com"
ENT.Category = "Ascension Gates"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

function ENT:GetTraceSize()
	return self.Entity:GetNWVector("TraceSize",Vector(1,1,1));
end

--################# AGP: the shield core bubble as a hard wall (server and client, so the client predicts it too) #################
-- The author's rule: nothing from outside gets in (players, NPCs, props, shots, blasts); what was inside when the
-- bubble went up, shots from there, and the owner (immunity on) may pass. Both realms use the same shape and the
-- same rule: the server from its own fields, the client from the networked values (cached in the bubble's client Think).
AGP_SC = AGP_SC or {}
local SC = AGP_SC

-- Exact shape, the same numbers as the collision mesh (modules/*.lua) and the models (scale 1 = 512 units menu size):
-- 1 sphere radius 200, 2 box half size 200, 3 Atlantis dome (widest 279 at height 62, top 208, flat bottom at 2).
local ATL_R, ATL_Z0, ATL_UP, ATL_DN, ATL_FLOOR = 279, 62, 146, 86, 2
SC.Extent = {
	[1] = { Vector(-202, -202, -202), Vector(202, 202, 202) },
	[2] = { Vector(-202, -202, -202), Vector(202, 202, 202) },
	[3] = { Vector(-281, -281, -2), Vector(281, 281, 211) },
}

-- shape id (1-3, 0 = not built yet) and per-axis scale of a bubble
function SC.Shape(b)
	local t = b.AGPShapeCache
	if (t) then return t[1], t[2] end
	local m = b:GetNWInt("PhysicModel", 0)
	local s = b:GetNWVector("PhysicScale", Vector(0, 0, 0))
	if (m < 1 or m > 3 or s.x <= 0) then return 0, s end
	b.AGPShapeCache = { m, Vector(s.x, s.y, s.z) } -- a bubble is never reshaped (a new one is made)
	return m, b.AGPShapeCache[2]
end

-- how far the bubble reaches from its origin (for quick distance checks)
function SC.Reach(b)
	local m, s = SC.Shape(b)
	if (m == 0) then return 0 end
	return 290 * math.max(s.x, s.y, s.z) -- (the dome is 279 wide at height 62: still under 290 from the origin)
end

-- centre the shape is scaled around (local)
local function shapeCentre(m, s)
	if (m == 3) then return Vector(0, 0, ATL_Z0 * s.z) end
	return Vector(0, 0, 0)
end

-- p: local position. Returns a "size" value (< 1 inside, 1 on the surface, > 1 outside) and the outward normal (local).
-- pad makes the shape that many units bigger (the size of the thing that is tested).
local function metricLocal(m, s, p, pad)
	if (m == 2) then
		local a, b, c = math.max(200 * s.x + pad, 1), math.max(200 * s.y + pad, 1), math.max(200 * s.z + pad, 1)
		local dx, dy, dz = math.abs(p.x) / a, math.abs(p.y) / b, math.abs(p.z) / c
		if (dx >= dy and dx >= dz) then return dx, Vector(p.x >= 0 and 1 or -1, 0, 0) end
		if (dy >= dz) then return dy, Vector(0, p.y >= 0 and 1 or -1, 0) end
		return dz, Vector(0, 0, p.z >= 0 and 1 or -1)
	elseif (m == 3) then
		local a, b = math.max(ATL_R * s.x + pad, 1), math.max(ATL_R * s.y + pad, 1)
		local dz = p.z - ATL_Z0 * s.z
		local c = math.max(((dz >= 0) and ATL_UP or ATL_DN) * s.z + pad, 1)
		local v = math.sqrt((p.x / a) ^ 2 + (p.y / b) ^ 2 + (dz / c) ^ 2)
		local floor = ATL_FLOOR * s.z - pad
		if (p.z < floor) then -- under the flat bottom: outside
			local f = 1 + (floor - p.z) / c
			if (f > v) then return f, Vector(0, 0, -1) end
		end
		local n = Vector(p.x / (a * a), p.y / (b * b), dz / (c * c))
		if (n:LengthSqr() < 1e-12) then n = Vector(0, 0, 1) end
		n:Normalize()
		return v, n
	else
		local a, b, c = math.max(200 * s.x + pad, 1), math.max(200 * s.y + pad, 1), math.max(200 * s.z + pad, 1)
		local v = math.sqrt((p.x / a) ^ 2 + (p.y / b) ^ 2 + (p.z / c) ^ 2)
		local n = Vector(p.x / (a * a), p.y / (b * b), p.z / (c * c))
		if (n:LengthSqr() < 1e-12) then n = Vector(0, 0, 1) end
		n:Normalize()
		return v, n
	end
end

-- world position: < 1 inside the bubble (grown by pad), > 1 outside
function SC.Metric(b, pos, pad)
	local m, s = SC.Shape(b)
	if (m == 0) then return 2 end
	return (metricLocal(m, s, b:WorldToLocal(pos), pad or 0))
end

function SC.Inside(b, pos, pad)
	return SC.Metric(b, pos, pad) < 1
end

-- outward normal (world) at/near a world position
function SC.Normal(b, pos, pad)
	local m, s = SC.Shape(b)
	if (m == 0) then return Vector(0, 0, 1) end
	local _, n = metricLocal(m, s, b:WorldToLocal(pos), pad or 0)
	n = b:LocalToWorld(n) - b:GetPos()
	n:Normalize()
	return n
end

-- the centre of the shape in the world (the dome is scaled around a point above its base)
function SC.Centre(b)
	local m, s = SC.Shape(b)
	if (m == 0) then return b:GetPos() end
	return b:LocalToWorld(shapeCentre(m, s))
end

-- the point on the surface between the centre and pos
function SC.SurfacePoint(b, pos)
	local c = SC.Centre(b)
	local v = SC.Metric(b, pos, 0)
	if (v < 0.001) then return c end
	return c + (pos - c) / v
end

-- first point outside (shape grown by pad) when going from pos along dir (world, normalised); nil if none in reach
function SC.ExitPoint(b, pos, pad, dir)
	local reach = SC.Reach(b) * 2 + 64 + (pad or 0)
	local d = 0
	while (d <= reach) do
		local q = pos + dir * d
		if (SC.Metric(b, q, pad) >= 1) then
			-- step back a little for a closer point, then go 2 units beyond
			local lo, hi = math.max(d - 8, 0), d
			for _ = 1, 4 do
				local mid = (lo + hi) / 2
				if (SC.Metric(b, pos + dir * mid, pad) >= 1) then hi = mid else lo = mid end
			end
			return pos + dir * (hi + 2)
		end
		d = d + 8
	end
end

-- ray from outside: distance to where it enters the bubble (pad 0), or nil
local function ellRoots(o, d, a, b, c)
	local px, py, pz = o.x / a, o.y / b, o.z / c
	local qx, qy, qz = d.x / a, d.y / b, d.z / c
	local A = qx * qx + qy * qy + qz * qz
	if (A < 1e-12) then return end
	local B = 2 * (px * qx + py * qy + pz * qz)
	local C = px * px + py * py + pz * pz - 1
	local disc = B * B - 4 * A * C
	if (disc < 0) then return end
	local sq = math.sqrt(disc)
	return (-B - sq) / (2 * A), (-B + sq) / (2 * A)
end

function SC.RayEnter(b, src, dir, maxd)
	local m, s = SC.Shape(b)
	if (m == 0) then return end
	local o = b:WorldToLocal(src)
	local d = b:WorldToLocal(src + dir) - o
	local best
	local function take(t) if (t and t >= 0 and t <= maxd and (not best or t < best)) then best = t end end
	if (m == 1) then
		local t1 = ellRoots(o, d, 200 * s.x, 200 * s.y, 200 * s.z)
		take(t1)
	elseif (m == 2) then
		local tmin, tmax = -math.huge, math.huge
		for _, ax in ipairs({ "x", "y", "z" }) do
			local h = 200 * s[ax]
			if (math.abs(d[ax]) < 1e-9) then
				if (math.abs(o[ax]) > h) then return end
			else
				local t1, t2 = (-h - o[ax]) / d[ax], (h - o[ax]) / d[ax]
				if (t1 > t2) then t1, t2 = t2, t1 end
				if (t1 > tmin) then tmin = t1 end
				if (t2 < tmax) then tmax = t2 end
				if (tmin > tmax) then return end
			end
		end
		take(tmin)
	else
		local z0 = ATL_Z0 * s.z
		local oc = Vector(o.x, o.y, o.z - z0)
		local a, bb = ATL_R * s.x, ATL_R * s.y
		local floor = ATL_FLOOR * s.z
		local t = ellRoots(oc, d, a, bb, ATL_UP * s.z)          -- upper half
		if (t and oc.z + d.z * t >= 0) then take(t) end
		t = ellRoots(oc, d, a, bb, ATL_DN * s.z)                -- lower half, above the floor
		if (t and oc.z + d.z * t < 0 and o.z + d.z * t >= floor) then take(t) end
		if (d.z > 1e-9 and o.z < floor) then                    -- through the flat bottom
			t = (floor - o.z) / d.z
			local p = o + d * t
			if (metricLocal(3, s, p + Vector(0, 0, 0.01), 0) < 1) then take(t) end
		end
	end
	return best
end

-- the player behind a thing: shooter of a shot, driver of a vehicle, owner of a prop
function SC.OwnerOf(e)
	if (not IsValid(e)) then return end
	if (e:IsPlayer()) then return e end
	if (e:IsVehicle() and e.GetDriver) then
		local d = e:GetDriver()
		if (IsValid(d)) then return d end
	end
	local o = e:GetOwner()
	if (IsValid(o)) then
		if (o:IsPlayer()) then return o end
		local oo = o:GetOwner()
		if (IsValid(oo) and oo:IsPlayer()) then return oo end
	end
	local lo = e.Owner
	if (isentity(lo) and IsValid(lo) and lo:IsPlayer()) then return lo end
	if (e.CPPIGetOwner) then
		local c = e:CPPIGetOwner()
		if (isentity(c) and IsValid(c) and c:IsPlayer()) then return c end
	end
end

-- is the bubble up?
function SC.Active(b)
	if (SERVER) then return b.Enabled == true and not b.Depleted and IsValid(b.Parent) end
	return b.AGPEnabled == true
end

-- immunity on, and whose shield it is
function SC.Immunity(b)
	if (SERVER) then
		local c = b.Parent
		if (not IsValid(c)) then return false end
		local own = c.Owner
		if (not IsValid(own) and c.CPPIGetOwner) then own = c:CPPIGetOwner() end
		return c.Immunity == true, own
	end
	return b.AGPImm == true, b.AGPOwn
end

local function inSet(b, e)
	if (SERVER) then
		local s = b.AGPAllowed
		return s ~= nil and s[e] == true
	end
	local s = b.AGPAllowedIdx
	return s ~= nil and s[e:EntIndex()] == true
end

-- may this thing be inside / pass the bubble?
function SC.Allowed(b, e)
	if (not isentity(e) or not IsValid(e)) then return false end
	if (inSet(b, e)) then return true end
	if (e.AGPBornIn == b) then return true end -- made inside after the bubble went up (server, init.lua)
	-- AGP: a shot of a weapon of the core's own ship (StarGate.MarkShot: pulses, drones) passes, in and out
	if (SERVER and e.AGPFrom and StarGate.SameShip and StarGate.SameShip(e.AGPFrom, b.Parent)) then return true end
	local o = e:GetOwner() -- shot by someone who may be inside
	if (IsValid(o) and o ~= b and inSet(b, o)) then return true end
	if (e:IsVehicle() and e.GetDriver) then
		local d = e:GetDriver()
		if (IsValid(d) and inSet(b, d)) then return true end
	end
	local imm, own = SC.Immunity(b)
	if (imm and isentity(own) and IsValid(own)) then
		local who = SC.OwnerOf(e)
		if (who == own) then return true end
		if (IsValid(who) and own.CPPIGetFriends) then
			local fr = own:CPPIGetFriends()
			if (istable(fr) and table.HasValue(fr, who)) then return true end
		end
	end
	return false
end

-- the owner may always walk (or drive) in and out, immunity or not. Only his body: his shots pass while he is inside
-- (the server then has him in the allowed set), from outside only with immunity.
function SC.OwnerPass(b, e)
	if (not isentity(e) or not IsValid(e)) then return false end
	local _, own = SC.Immunity(b)
	if (not (isentity(own) and IsValid(own))) then return false end
	if (e == own) then return true end
	if (e:IsVehicle() and e.GetDriver) then return e:GetDriver() == own end
	return false
end

-- may this body (player, vehicle) walk into the bubble?
function SC.BodyAllowed(b, e)
	return SC.Allowed(b, e) or SC.OwnerPass(b, e)
end

-- all bubbles (refreshed 4 times a second)
local list, listNext = {}, 0
function SC.List()
	local now = CurTime()
	if (now >= listNext or now < listNext - 1) then
		listNext = now + 0.25
		list = ents.FindByClass("shield_core_buble")
	end
	return list
end

-- collisions: allowed things pass through the mesh, everything else is stopped by it
hook.Add("ShouldCollide", "ShieldCoreShouldCollide", function(e1, e2)
	if (not IsValid(e1) or not IsValid(e2)) then return end
	local b1, b2 = e1:GetClass() == "shield_core_buble", e2:GetClass() == "shield_core_buble"
	if (not (b1 or b2)) then return end
	if (b1 and b2) then return false end
	local sh, other = e1, e2
	if (b2) then sh, other = e2, e1 end
	if (other:IsWorld()) then return false end
	if (not SC.Active(sh)) then return false end
	local core = SERVER and sh.Parent or sh:GetNWEntity("AGPCore")
	if (other == core) then return false end
	if (SC.Allowed(sh, other) or SC.OwnerPass(sh, other)) then return false end
	return true
end)

-- players: a hard wall. Who may not be inside cannot step into the bubble at all (the client predicts the same, so it
-- does not jitter). Someone already deep inside who may not be there is pushed out by the server (bubble Think).
hook.Add("FinishMove", "AGP.ShieldCoreWall", function(ply, mv)
	local L = SC.List()
	if (#L == 0 or not ply:Alive() or ply:InVehicle() or ply:GetMoveType() == MOVETYPE_OBSERVER) then return end
	local old, new = ply:GetPos(), mv:GetOrigin()
	if (old == new) then return end
	local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
	local off = (mins + maxs) * 0.5
	local pad = math.max(maxs.x - mins.x, maxs.y - mins.y) * 0.5 + 2
	for i = 1, #L do
		local b = L[i]
		if (IsValid(b) and SC.Active(b)) then
			local r = SC.Reach(b) + pad + 96
			if (new:DistToSqr(b:GetPos()) < r * r and not SC.BodyAllowed(b, ply)) then
				local m1 = SC.Metric(b, new + off, pad)
				if (m1 < 1) then
					local m0 = SC.Metric(b, old + off, pad)
					if (m1 < m0) then -- moving into it: slide along the wall instead
						local n = SC.Normal(b, new + off, pad)
						local d = new - old
						local dn = d:Dot(n)
						local try = old
						if (dn < 0) then
							try = old + (d - n * dn)
							if (SC.Metric(b, try + off, pad) < math.min(m0, 1)) then try = old end
						end
						mv:SetOrigin(try)
						new = try
						local v = mv:GetVelocity()
						local vn = v:Dot(n)
						if (vn < 0) then mv:SetVelocity(v - n * vn + n * 40) end
						if (SERVER and SC.TouchFx) then SC.TouchFx(b, ply, try + off - n * pad, n) end
					end
				end
			end
		end
	end
end)

-- bullets: shots from outside stop at the bubble and drain it; shots from inside (and from the owner with immunity)
-- pass. Done for the real bullet direction before the engine fires it (traces alone missed the hollow mesh).
local function bulletFilter(a, b, c)
	local f = {}
	if (IsValid(a)) then f[#f + 1] = a end
	if (IsValid(b)) then f[#f + 1] = b end
	if (IsValid(c)) then f[#f + 1] = c end
	return f
end
hook.Add("EntityFireBullets", "AGP.ShieldCoreBullets", function(shooter, data)
	local L = SC.List()
	if (#L == 0 or not data or not data.Src or not data.Dir) then return end
	local src = data.Src
	local dir = data.Dir:GetNormalized()
	if (dir:LengthSqr() < 0.5) then return end
	local dist = data.Distance or 56756
	local bestT, bestB, passB
	for i = 1, #L do
		local b = L[i]
		if (IsValid(b) and SC.Active(b)) then
			local reach = SC.Reach(b)
			local rel = b:GetPos() - src
			local along = rel:Dot(dir)
			if (along > -reach and rel:LengthSqr() - along * along < reach * reach) then
				if (SC.Inside(b, src)) then
					passB = passB or b -- from inside: goes out
				elseif (SC.Allowed(b, shooter)) then
					passB = passB or b -- the owner with immunity
				else
					local t = SC.RayEnter(b, src, dir, dist)
					if (t and (not bestT or t < bestT)) then bestT, bestB = t, b end
				end
			end
		end
	end
	if (bestB) then
		-- something solid in front of the shield takes the bullet itself
		local tr = util.TraceLine({ start = src, endpos = src + dir * bestT, filter = bulletFilter(shooter, data.IgnoreEntity, bestB), mask = MASK_SHOT })
		if (tr.Hit and not (IsValid(tr.Entity) and tr.Entity:GetClass() == "shield_core_buble")) then return end
		if (SERVER and SC.BulletHit) then SC.BulletHit(bestB, shooter, data, src, src + dir * bestT, dir) end
		return false
	end
	if (passB and not IsValid(data.IgnoreEntity)) then
		-- the hollow mesh would stop it from the inside: let the bullet through it
		local tr = util.TraceLine({ start = src, endpos = src + dir * dist, filter = bulletFilter(shooter), mask = MASK_SHOT })
		if (IsValid(tr.Entity) and tr.Entity:GetClass() == "shield_core_buble" and (tr.Entity == passB or SC.Allowed(tr.Entity, shooter) or SC.Inside(tr.Entity, src))) then
			data.IgnoreEntity = tr.Entity
			return true
		end
	end
end)

-- CAP's own traceline class (staff weapons, beams, CAP bullets): hit the bubble unless the shooter may pass.
-- AGP: a trace that starts inside always goes out (like real bullets above), whoever shoots (a turret placed inside later).
if (StarGate and StarGate.Trace and StarGate.Trace.Add) then
	StarGate.Trace:Add("shield_core_buble", function(e, values, trace, in_box)
		if (not SC.Active(e)) then return false end
		local start = values and values[1]
		if (isvector(start) and SC.Inside(e, start)) then return false end
		local ig = values and values[3]
		if (istable(ig)) then ig = ig[1] end
		if (isentity(ig) and IsValid(ig) and SC.Allowed(e, ig)) then return false end
		return true
	end)
end
