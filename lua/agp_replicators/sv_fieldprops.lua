-- The felt map's live prop layer. The felt map (sv_field.lua) is the map's own brushes, felt once and kept on disk: a
-- prop felt into it would stay there when it is moved, unfrozen or eaten. So near props bugs walked with their legs -
-- slower, and at the edge of a pile of the owner's props a bug hung about 10 s (random round 87265). This layer is kept
-- apart from it and lives only while the game runs: the
-- players' frozen things (every 2 s where each one is and how it is turned) are felt round each one into their own
-- blocks, with rays that hit only those props. The felt map reads the nearer
-- of the two (F.PropRaw in sv_field.lua's raw()). A prop that comes, moves, is unfrozen or goes: its blocks are felt
-- again (a little each tick), and till then the bugs there walk with their legs as before. Props that move freely stay
-- with the legs - nothing could keep up with them. agp_rep_propfelt 0: off (the legs near props, as before). Not
-- saved (no FCVAR_ARCHIVE, a new name): stopped test runs had saved the old agp_rep_feltprops 0 into the author's server.vdf and
-- the author's game started with the layer off.
local R = AGP.Rep
local F = R.Field
if not F then return end
R.cv.feltprops = R.cv.feltprops or CreateConVar("agp_rep_propfelt", "1", FCVAR_NONE, "Replicators: the felt map also knows the players' frozen props (1) or only the map (0)")

local G, RMAX = F.G, F.RMAX
local CS = 4
local CN = CS * CS * CS
local AIR = 1
local floor, char, byte = math.floor, string.char, string.byte
local function ckey(ci, cj, ck) return (ci + 1024) + (cj + 1024) * 2048 + (ck + 1024) * 4194304 end
local function enc(v) local q = floor((v + G) * 2 + 0.5) if q < 0 then q = 0 elseif q > 255 then q = 255 end return q end
local AX = { Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(0, 0, 1), Vector(0, 0, -1) }
local BUDGET = 0.0007   -- s a tick for feeling prop blocks

local P = R.FieldProps or {}
R.FieldProps = P
P.ch = P.ch or {}         -- block key -> AIR or CN bytes (felt with the props there now)
P.want = P.want or {}     -- block key -> true: near a prop, to be felt (again)
P.queue = P.queue or {}   -- block keys waiting
P.of = P.of or {}         -- prop -> { sig, keys = { block keys } }
P.ready = P.ready or {}   -- prop -> true when all its blocks are felt with it where it is now
P.n = P.n or 0
-- (blocks a bug asked for and found not felt yet: felt before the rest - the queue had 8000 blocks of the whole map's
-- frozen things and the three test bugs stood 5-6 s each beside the crates)
P.hot = P.hot or {}
P.hotSet = P.hotSet or {}
local HOTBUDGET = 0.0015
-- (allowances that build up each tick and are paid off by what feeling really took: a block costs up to 1-2 ms, "only while
-- there is time" still felt one a tick; R.Ease)
local hotAllow, queueAllow = 0, 0

-- (which things: every frozen solid thing the players put down - not only plain props (prop_physics, the ways' own list
-- V.psig) but a Stargate, its DHD, its ramp, a SENT; the author's game: bugs by the gate ramp walked with their legs,
-- wobbled at a curb beside it. Not: what moves on its own - doors, lifts, trains, vehicles -, ships (bugs board
-- those), players, NPCs, bugs, parts fixed onto something else)
P.sig = P.sig or {}       -- thing -> where it is and how it is turned, as text (felt again when it changes)
local MOVERS = { func_door = true, func_door_rotating = true, prop_door_rotating = true, func_movelinear = true, func_tracktrain = true,
	func_rotating = true, func_platrot = true, func_train = true, func_physbox = true }
local function stillThing(e)
	if e:IsPlayer() or e:IsNPC() or e:IsVehicle() or e:IsWorld() or e.AGPReplicator or e.AGPRepBlock or e.AGPRepQueen then return false end
	if IsValid(e.AGPShip) or (R.IsShip and R.IsShip(e)) or IsValid(e:GetParent()) or e:GetSolid() == SOLID_NONE or MOVERS[e:GetClass()] then return false end
	local cg = e:GetCollisionGroup()
	if cg == COLLISION_GROUP_DEBRIS or cg == COLLISION_GROUP_DEBRIS_TRIGGER or cg == COLLISION_GROUP_WORLD or cg == COLLISION_GROUP_IN_VEHICLE or cg == COLLISION_GROUP_PASSABLE_DOOR then return false end
	local ph = e:GetPhysicsObject()
	return IsValid(ph) and not ph:IsMotionEnabled() and e:BoundingRadius() > 24
end
local function tracked(e) return P.sig[e] ~= nil end
local function propFilter(e) return tracked(e) end

-- one block felt with the props only: AIR or its CN bytes (as sv_field.lua's feelBlock, rays that hit nothing but props)
local function feelBlock(ci, cj, ck)
	local i0, j0, k0 = ci * CS, cj * CS, ck * CS
	local Pt, v, ss = {}, {}, {}
	for n = 1, CN do
		local a = n - 1
		Pt[n] = Vector((i0 + a % CS) * G, (j0 + floor(a / CS) % CS) * G, (k0 + floor(a / (CS * CS))) * G)
		v[n], ss[n] = RMAX, 0
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
			local s = 1
			while s <= CS do
				local n = line[s]
				local len = (CS - s) * G + RMAX
				local tr = util.TraceLine({ start = Pt[n], endpos = Pt[n] + d * len, mask = MASK_SOLID, filter = propFilter, ignoreworld = true })
				if tr.StartSolid then
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
						if dist < 0 then break end
						local m = line[s2]
						if dist <= RMAX then
							local dd = (Pt[m] - hp):Dot(hn)
							if dd < -0.5 then ss[m] = 6
							elseif dd < v[m] then v[m] = math.max(dd, 0) end
						end
						s2 = s2 + 1
					end
					s = s2
				end
			end
		end end
	end
	local b, allA = {}, true
	for n = 1, CN do
		local val = ss[n] >= 6 and -G or v[n]
		if val ~= RMAX then allA = false end
		b[n] = enc(val)
	end
	return allA and AIR or char(unpack(b, 1, CN))
end

-- the props' distance at grid point i,j,k: a number, false (no prop near: only the map counts) or nil (near a prop, not
-- felt yet: the legs there)
function F.PropRaw(i, j, k)
	if not R.cv.feltprops:GetBool() then return false end
	local ci, cj, ck = floor(i / CS), floor(j / CS), floor(k / CS)
	local key = ckey(ci, cj, ck)
	if not P.want[key] then return false end
	local c = P.ch[key]
	if c == nil then
		if not P.hotSet[key] then P.hotSet[key] = true P.hot[#P.hot + 1] = { key, ci, cj, ck } end
		return nil
	end
	if c == AIR then return false end
	return byte(c, 1 + (i - ci * CS) + (j - cj * CS) * CS + (k - ck * CS) * CS * CS) * 0.5 - G
end

-- the blocks within reach of a prop
local function blocksOf(e)
	local lo, hi = e:WorldSpaceAABB()
	local m = RMAX + G
	local c0 = { floor((lo.x - m) / G / CS), floor((lo.y - m) / G / CS), floor((lo.z - m) / G / CS) }
	local c1 = { floor((hi.x + m) / G / CS), floor((hi.y + m) / G / CS), floor((hi.z + m) / G / CS) }
	local n = (c1[1] - c0[1] + 1) * (c1[2] - c0[2] + 1) * (c1[3] - c0[3] + 1)
	if n > 1500 then return nil end   -- (a huge prop: left to the legs)
	local keys = {}
	for ci = c0[1], c1[1] do for cj = c0[2], c1[2] do for ck = c0[3], c1[3] do keys[#keys + 1] = { ckey(ci, cj, ck), ci, cj, ck } end end end
	return keys
end

-- a block to be felt again: its value gone, the soft values round it gone (sv_field.lua F.ForgetSoft), queued
local function refeel(kb)
	local key = kb[1]
	P.ch[key] = nil
	P.want[key] = true
	if F.ForgetSoft then F.ForgetSoft(kb[2] * CS - 1, kb[3] * CS - 1, kb[4] * CS - 1, kb[2] * CS + CS, kb[3] * CS + CS, kb[4] * CS + CS) end
	P.queue[#P.queue + 1] = kb
end

-- which props changed (every 2 s, after the ways' own look at them)
-- (what moves is not felt until it lies still for one look: the frozen things on a flying ship are put to a new place
-- every tick and were felt again and again, 107 to 119 ms a second on the server - odd_fps. Till then the bugs near it
-- walk with their legs, F.PropKnown)
P.moving = P.moving or {}   -- thing -> where it was at the last look
local nextLook = 0
local function look()
	local sigs = {}
	local iter = ents.Iterator or function() return ipairs(ents.GetAll()) end
	for _, e in iter() do
		if IsValid(e) and stillThing(e) then
			local p, a = e:GetPos(), e:GetAngles()
			sigs[e] = floor(p.x) .. " " .. floor(p.y) .. " " .. floor(p.z) .. " " .. floor(a.p) .. " " .. floor(a.y) .. " " .. floor(a.r)
		end
	end
	P.sig = sigs
	local seen = {}
	for e, sig in pairs(sigs) do
		if IsValid(e) then
			seen[e] = true
			local o = P.of[e]
			local moves = false
			if not (R.TestOff and R.TestOff.propIdle) then
				if P.moving[e] then moves = P.moving[e] ~= sig
				elseif o then moves = o.sig ~= sig
				else moves = e.SGCarryAt ~= nil or e:GetVelocity():LengthSqr() > 25 end   -- (new: on a ship, or on its way)
			end
			P.moving[e] = moves and sig or nil
			if moves then
				if o then
					if o.keys then for _, kb in ipairs(o.keys) do refeel(kb) end end   -- (where it was: felt again without it)
					P.of[e], P.ready[e] = nil, nil
				end
			elseif not o or o.sig ~= sig then
				-- (where it was: felt again without it; where it is: felt with it)
				if o and o.keys then for _, kb in ipairs(o.keys) do refeel(kb) end end
				local keys = blocksOf(e)
				P.of[e] = { sig = sig, keys = keys }
				P.ready[e] = nil
				if keys then for _, kb in ipairs(keys) do refeel(kb) end end
			end
		end
	end
	for e in pairs(P.moving) do if not seen[e] then P.moving[e] = nil end end
	for e, o in pairs(P.of) do
		if not seen[e] then
			if o.keys then for _, kb in ipairs(o.keys) do refeel(kb) end end
			P.of[e], P.ready[e] = nil, nil
		end
	end
end

-- is this prop felt where it is now (a bug near it may glide on the felt map)
function F.PropFelt(e)
	if not R.cv.feltprops:GetBool() then return false end
	if P.ready[e] then return true end
	local o = P.of[e]
	if not (o and o.keys) then return false end
	if P.sig[e] ~= o.sig then return false end
	for _, kb in ipairs(o.keys) do if P.ch[kb[1]] == nil then return false end end
	P.ready[e] = true
	return true
end

-- is this thing in the layer where it is now (felt or being felt): a bug near it walks the felt map - the blocks it
-- needs are felt first (P.hot), till then that tick it walks with its legs. Waiting till ALL of a big thing's blocks were
-- felt kept the new walk off by the map's gate ramp behind 8000 queued blocks (curb test)
function F.PropKnown(e)
	if not R.cv.feltprops:GetBool() then return false end
	local o = P.of[e]
	return o ~= nil and o.keys ~= nil and P.sig[e] == o.sig
end

hook.Add("Tick", "AGPRepFieldProps", function()
	if not R.cv.feltprops:GetBool() then
		if next(P.of) ~= nil then
			for _, o in pairs(P.of) do if o.keys then for _, kb in ipairs(o.keys) do P.want[kb[1]] = nil if F.ForgetSoft then F.ForgetSoft(kb[2] * CS - 1, kb[3] * CS - 1, kb[4] * CS - 1, kb[2] * CS + CS, kb[3] * CS + CS, kb[4] * CS + CS) end end end end
			P.of, P.ch, P.queue, P.ready, P.sig, P.hot, P.hotSet = {}, {}, {}, {}, {}, {}, {}
		end
		return
	end
	-- (no Replicator on the map: nothing is looked at or felt, what is known is kept - the first one brings a look at once)
	if next(R.bugs) == nil and next(R.queens) == nil and not (R.TestOff and R.TestOff.propIdle) then nextLook = 0 return end
	local now = CurTime()
	if now > nextLook then nextLook = now + 2 look() end
	if #P.hot > 0 then
		hotAllow = math.min(hotAllow + HOTBUDGET * R.Ease(), 0.003)
		local h0 = SysTime()
		local stopH = h0 + hotAllow
		while #P.hot > 0 and SysTime() < stopH do
			local kb = table.remove(P.hot)
			P.hotSet[kb[1]] = nil
			if P.want[kb[1]] and P.ch[kb[1]] == nil then
				P.ch[kb[1]] = feelBlock(kb[2], kb[3], kb[4])
				P.n = P.n + 1
				P.nHot = (P.nHot or 0) + 1
				if F.ForgetSoft then F.ForgetSoft(kb[2] * CS - 1, kb[3] * CS - 1, kb[4] * CS - 1, kb[2] * CS + CS, kb[3] * CS + CS, kb[4] * CS + CS) end
			end
		end
		hotAllow = hotAllow - (SysTime() - h0)
	end
	if #P.queue == 0 then return end
	queueAllow = math.min(queueAllow + BUDGET * R.Ease(), 0.0015)
	local q0 = SysTime()
	local stop = q0 + queueAllow
	while #P.queue > 0 and SysTime() < stop do
		local kb = table.remove(P.queue)
		if P.want[kb[1]] and P.ch[kb[1]] == nil then
			P.ch[kb[1]] = feelBlock(kb[2], kb[3], kb[4])
			P.n = P.n + 1
			if F.ForgetSoft then F.ForgetSoft(kb[2] * CS - 1, kb[3] * CS - 1, kb[4] * CS - 1, kb[2] * CS + CS, kb[3] * CS + CS, kb[4] * CS + CS) end
		end
	end
	queueAllow = queueAllow - (SysTime() - q0)
end)
