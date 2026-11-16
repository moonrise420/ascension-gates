-- Replicators: the Queen's plans (owner 2026-11-02). Every plan is checked before it starts (enough bugs, a known way, a
-- target that is really there); a plan runs until something clearly better comes; what failed is avoided for a while,
-- never for ever. The bugs carry the plan out with their own small decisions (agp_replicator.lua Look / Brain).
--   strength  count before you fight: own bugs (health, size) against the enemies (health, weapon, ship); outnumbered,
--             they hold back out of sight, eat and grow, and strike together when strong enough
--   danger    a shooter's spot becomes a danger zone (routes avoid it); they come from the side he is not looking at
--   nests     a big swarm sends settlers to metal far away: they build a new Queen there - one nest lost, the others go on
--   power     eaten power sources (ZPM, generators, drained shields) make the Queens build faster
--   sabotage  near threatening players: their own DHDs are eaten (no escape); guards at the map's gate
--   ambush    on walls above the paths players walk most, still and silent, then they drop on them
--   bridges   a chain of bodies over a deep gap (roof to roof); the others run over it
local R = AGP.Rep
local M = R.Map

local function key(owner) return IsValid(owner) and owner or game.GetWorld() end

-- ---------- strength ----------
local SAFE_WEAPONS = { weapon_physgun = true, gmod_tool = true, gmod_camera = true, weapon_fists = true, none = true, weapon_physcannon = true }
-- how dangerous a weapon really is to them: only the ARG kills them for good; bullets and explosions only knock them
-- apart into blocks that build themselves again (agp_rep_rebuild), energy weapons barely touch them (series), and what
-- the swarm has adapted to hurts it less still
local ENERGY = { "staff", "zat", "pulse", "laser", "plasma", "beam", "energy", "ori", "wraith" }
local function weaponPower(owner, cls)
	if cls == "sg_arg" then return 5 end
	if SAFE_WEAPONS[cls] then return 0.6 end
	for _, w in ipairs(ENERGY) do if cls:find(w, 1, true) then return 0.35 end end
	local rebuild = R.cv.rebuild and R.cv.rebuild:GetBool()
	local p = rebuild and 0.8 or 1.6
	return p * (R.Resist and R.Resist(owner, DMG_BULLET) or 1)
end
function R.EnemyStrength(e, owner)
	if not IsValid(e) then return 0 end
	local hp = math.max(e:Health(), 1) + (e:IsPlayer() and e:Armor() or 0)
	local arm = 0.6
	if e:IsPlayer() then
		if R.CraftOf and IsValid(R.CraftOf(e)) then return 10 end   -- in a ship: a lot stronger than any one of them
		-- the best weapon he carries counts (he can switch to it), the one in his hands a little more
		local best = 0.6
		for _, w in ipairs(e:GetWeapons()) do
			if IsValid(w) then best = math.max(best, weaponPower(owner, w:GetClass()) * (w == e:GetActiveWeapon() and 1 or 0.8)) end
		end
		arm = best
	elseif e:IsNPC() then
		local w = e.GetActiveWeapon and e:GetActiveWeapon()
		arm = IsValid(w) and weaponPower(owner, w:GetClass()) or 0.6
	end
	return hp / 100 * arm * 3
end
function R.OwnStrength(list)
	local s = 0
	for _, b in ipairs(list) do
		if IsValid(b) and not b.RepGone and b.Role ~= "survivor" and b.Role ~= "colonist" then
			s = s + math.Clamp(b:Health() / math.max(1, b.RepHealth or 1), 0.2, 1) * (b.RepMini and 0.5 or 1)
		end
	end
	return s
end

-- the enemies near this swarm (players and NPCs it may attack)
local function foes(list)
	local out, seen = {}, {}
	local probe = list[1]
	if not IsValid(probe) then return out end
	local cands = player.GetAll()
	for _, n in ipairs(ents.FindByClass("npc_*")) do cands[#cands + 1] = n end
	for _, e in ipairs(cands) do
		if not seen[e] and R.MayAttack(probe, e) then
			for _, b in ipairs(list) do
				if b:GetPos():DistToSqr(e:GetPos()) < 2500 * 2500 then out[#out + 1] = e; seen[e] = true break end
			end
		end
	end
	return out
end

-- ---------- player paths (for ambushes): where players walk, the map memory counts it ----------
timer.Create("AGPRepPlayerPaths", 2, 0, function()
	if not R.Awake() or R.Count("bugs") == 0 then return end
	for _, p in ipairs(player.GetAll()) do
		if p:Alive() and p:GetMoveType() == MOVETYPE_WALK and p:IsOnGround() then M.Mark(p:GetPos(), "pl", 1) end
	end
end)
-- a spot on a wall 110-160 units above a much-walked path near pos (or nil)
function R.AmbushSpot(pos, taken)
	local best, bs
	for _, c in ipairs(M.Near(pos, 2500)) do
		if (c.pl or 0) >= 3 and c.p:DistToSqr(pos) < 2500 * 2500 and not (taken and taken[c]) then
			local s = c.pl - c.p:Distance(pos) / 400 - (c.d or 0) * 2
			if not bs or s > bs then best, bs = c, s end
		end
	end
	if not best then return nil end
	for a = 0, 315, 45 do
		local dir = Angle(0, a, 0):Forward()
		local from = best.p + Vector(0, 0, 40)
		local tr = util.TraceLine({ start = from, endpos = from + dir * 260, mask = MASK_PLAYERSOLID_BRUSHONLY })
		if tr.Hit and math.abs(tr.HitNormal.z) < 0.3 then
			local spot = tr.HitPos + tr.HitNormal * 6 + Vector(0, 0, math.random(100, 150))
			local up = util.TraceLine({ start = tr.HitPos + tr.HitNormal * 6, endpos = spot, mask = MASK_PLAYERSOLID_BRUSHONLY })
			if not up.Hit then return spot, best, tr.HitNormal end
		end
	end
	if taken then taken[best] = true end
end

-- ---------- doors (owner 2026-11-04): an ambush on the wall over a door ----------
-- They know a door: a map door, or a narrow opening players walk through (walls close on both sides, a lintel above).
-- A drop from there that got someone is remembered (map memory "amb"), so that door is used again; whether doors or
-- open paths pay off more, the swarm learns (R.AmbushJudge).
local function isDoor(e)
	local cl = e:GetClass()
	return cl == "func_door" or cl == "func_door_rotating" or cl == "prop_door_rotating" or (cl:find("door", 1, true) ~= nil and not e:IsPlayer() and not e:IsWeapon())
end
-- the spot on the wall above an opening at p (axis: the way through), on side +1 / -1; top: the lintel's height
local function overDoor(p, axis, side, top)
	for _, hz in ipairs({ 20, 8, 40 }) do for _, out in ipairs({ 70, 45, 110 }) do
		local from = Vector(p.x, p.y, top + hz) + axis * side * out
		if util.IsInWorld(from) then
			local tr = util.TraceLine({ start = from, endpos = from - axis * side * (out + 70), mask = MASK_PLAYERSOLID_BRUSHONLY })
			if tr.Hit and not tr.StartSolid and math.abs(tr.HitNormal.z) < 0.3 then
				local spot = tr.HitPos + tr.HitNormal * 6
				local fl = util.TraceLine({ start = spot, endpos = spot - Vector(0, 0, 300), mask = MASK_PLAYERSOLID_BRUSHONLY })
				if fl.Hit and spot.z - fl.HitPos.z > 80 then return spot, fl.HitPos end
			end
		end
	end end
end
-- a much-walked cell in a doorway: the way through and the lintel's height (worked out once per cell)
local function doorway(c)
	if c.doorChk then return c.doorAxis, c.doorTop end
	c.doorChk = true
	local p = c.p + Vector(0, 0, 40)
	for _, a in ipairs({ 0, 90, 45, 135 }) do
		local d = Angle(0, a, 0):Forward()
		local l = util.TraceLine({ start = p, endpos = p + d * 95, mask = MASK_PLAYERSOLID_BRUSHONLY })
		local r = util.TraceLine({ start = p, endpos = p - d * 95, mask = MASK_PLAYERSOLID_BRUSHONLY })
		if l.Hit and r.Hit and not l.StartSolid and l.HitPos:Distance(r.HitPos) < 180 then
			local up = util.TraceLine({ start = p, endpos = p + Vector(0, 0, 220), mask = MASK_PLAYERSOLID_BRUSHONLY })
			if up.Hit then c.doorAxis, c.doorTop = Angle(0, a + 90, 0):Forward(), up.HitPos.z return c.doorAxis, c.doorTop end
		end
	end
end
-- the best door near pos: its spot, a key (taken), the floor in front of it
function R.DoorSpot(pos, taken)
	local best, bs, bk, bf
	local function consider(spot, floor, k, traffic, amb, d)
		if taken and taken[k] then return end
		local s = traffic + amb * 3 - d / 400
		if not bs or s > bs then best, bs, bk, bf = spot, s, k, floor end
	end
	for _, e in ipairs(ents.FindInSphere(pos, 2500)) do
		if isDoor(e) then
			local mn, mx = e:OBBMins(), e:OBBMaxs()
			local size = mx - mn
			local axis = size.x < size.y and e:GetForward() or e:GetRight()   -- the door's thin side: the way through
			axis.z = 0
			if axis:LengthSqr() > 0.01 then
				axis:Normalize()
				local c = e:WorldSpaceCenter()
				local fl = util.TraceLine({ start = c, endpos = c - Vector(0, 0, 200), mask = MASK_PLAYERSOLID_BRUSHONLY })
				local floor = fl.Hit and fl.HitPos or c
				local cell = M.cells[M.Key(floor)]
				for _, side in ipairs({ 1, -1 }) do
					local spot, below = overDoor(floor, axis, side, c.z + size.z * 0.5)
					if spot then consider(spot, below, "door" .. e:EntIndex() .. side, (cell and cell.pl or 0) + 2, cell and cell.amb or 0, floor:Distance(pos)) end
				end
			end
		end
	end
	local cells, n = M.Near(pos, 2500), 0
	table.sort(cells, function(a, b) return (a.pl or 0) > (b.pl or 0) end)
	for _, c in ipairs(cells) do
		if (c.pl or 0) < 2 or n >= 40 then break end
		if not c.doorChk then n = n + 1 end   -- (at most 40 new cells looked at per call; known ones cost nothing)
		local axis, top = doorway(c)
		if axis then
			for _, side in ipairs({ 1, -1 }) do
				local spot, below = overDoor(c.p, axis, side, top)
				if spot then consider(spot, below, c, c.pl, c.amb or 0, c.p:Distance(pos) + (c.d or 0) * 800) end
			end
		end
	end
	return best, bk, bf
end
-- a spot on a ceiling over a much-walked place indoors (owner 2026-11-05: "it also could jump from the ceiling on the
-- player"): 90-260 units over the floor, room under it to drop; the floor under it is where it lands
function R.CeilingSpot(pos, taken)
	local best, bs, bf
	for _, c in ipairs(M.Near(pos, 2500)) do
		if (c.pl or 0) >= 2 and not (taken and taken[c]) then
			local from = c.p + Vector(0, 0, 40)
			local tr = util.TraceLine({ start = from, endpos = from + Vector(0, 0, 260), mask = MASK_PLAYERSOLID_BRUSHONLY })
			if tr.Hit and not tr.StartSolid and tr.HitNormal.z < -0.7 and tr.HitPos.z - c.p.z > 90 then
				local s = c.pl + (c.amb or 0) * 3 - c.p:Distance(pos) / 400 - (c.d or 0) * 2
				if not bs or s > bs then best, bs, bf = c, s, tr.HitPos - Vector(0, 0, 8) end
			end
		end
	end
	if best then return bf, best end
end
-- an ambush is over: what it brought (the bites after the drop) against the time it waited, for its kind of spot
function R.AmbushJudge(b)
	if not IsValid(b) or not b.AmbushKind then return end
	local dt = CurTime() - (b.AmbushT0 or CurTime())
	R.Brain.Judge("ambush", b.AmbushKind, (b.BrainScore or 0) - (b.AmbushS0 or 0) - 0.01 * math.min(dt, 90))
	b.AmbushKind = nil
end
-- it dropped on someone from its spot: that spot is remembered (good place), and in 12 s it is judged
function R.AmbushDropped(b)
	R.Reward(b, 0.5)
	if b.AmbushFloor then M.Mark(b.AmbushFloor, "amb", 1) end
	if b.AmbushKind == "door" then R.Stat("door ambush drops") end
	timer.Simple(12, function() R.AmbushJudge(b) end)
end

-- ---------- power: what a swarm has eaten of power sources ----------
function R.Fed(owner, power)
	local h = R.Hive(owner)
	h.power = math.min((h.power or 0) + power, 30)
end
-- how much faster its Queens build (1 = normal, up to 2.5)
function R.PowerBoost(owner)
	return 1 + math.min(R.Hive(owner).power or 0, 30) / 20
end

-- ---------- the Queen's network (queen_net.lua, trained from the training runs): how good striking or holding back is
-- in this situation; it overrides the rules only when it is clearly sure (and never when the Queen is in danger)
local NET = file.Exists("agp_replicators/queen_net.lua", "LUA") and include("agp_replicators/queen_net.lua") or nil
local function netValue(f, plan)
	local x = {}
	for i, k in ipairs(NET.feats) do x[i] = ((f[k] or 0) - NET.mu[i]) / NET.sd[i] end
	x[#x + 1] = plan
	local out = NET.b2[1]
	for j = 1, NET.n_h do
		local s = NET.b1[j]
		for i = 1, NET.n_in do s = s + x[i] * NET.W1[(i - 1) * NET.n_h + j] end
		out = out + math.tanh(s) * NET.W2[j]
	end
	return out
end
R.QueenNet = NET and netValue or nil

-- ---------- the plan, every 3 s for each swarm with a Queen (sv_hive.lua direct) ----------
function R.Plan(h, owner, list, queens, now)
	local n = #list
	-- 1. count before you fight
	local fl = foes(list)
	local fs, own = 0, R.OwnStrength(list)
	for _, e in ipairs(fl) do fs = fs + R.EnemyStrength(e, owner) end
	h.defend = false
	for _, e in ipairs(fl) do
		for _, q in ipairs(queens) do if e:GetPos():DistToSqr(q:GetPos()) < 700 * 700 then h.defend = true end end
	end
	local was = h.mode
	if #fl == 0 then h.mode = nil
	elseif h.defend then h.mode = "strike"   -- the Queen is in danger: everyone, whatever the odds
	elseif h.mode ~= "strike" and own >= fs * 1.15 then h.mode = "strike"
	elseif h.mode == "strike" and own < fs * 0.55 then h.mode = "hold"
	elseif not h.mode then h.mode = own >= fs * 1.15 and "strike" or "hold" end
	-- the network's view (if it is clearly sure the other plan is better, that plan)
	if NET and #fl > 0 and not h.defend and R.Brain and R.Brain.Mind() >= 3 then
		local f = { n = n, own = own, foe = fs, power = h.power or 0, queens = #queens, enemies = #fl, shot = h.shot or 0, losses = #h.losses }
		local vs, vh = netValue(f, 1), netValue(f, -1)
		h.netStrike, h.netHold = vs, vh
		if vs > vh + 0.4 and h.mode == "hold" then h.mode = "strike"; R.Stat("net: strike")
		elseif vh > vs + 0.4 and h.mode == "strike" then h.mode = "hold"; R.Stat("net: hold") end
	end
	-- training: now and then the other plan for a while (so the data shows what both bring)
	if #fl > 0 and not h.defend and GetConVar("agp_rep_learn") and GetConVar("agp_rep_learn"):GetInt() == 2 then
		if now > (h.flipUntil or 0) and math.random() < 0.2 then h.flipUntil = now + 12; h.flip = true elseif now > (h.flipUntil or 0) then h.flip = false end
		if h.flip then h.mode = h.mode == "strike" and "hold" or "strike" end
	end
	-- waiting is no fun for ever: after 40 s of holding back they strike anyway when they have half his strength
	if h.mode == "hold" then
		h.holdSince = h.holdSince or now
		if now - h.holdSince > 40 and own >= fs * 0.5 then h.mode = "strike"; R.Stat("impatient strike") end
	else
		h.holdSince = nil
	end
	h.own, h.foe = own, fs
	if h.mode ~= was then
		R.Stat("plan " .. tostring(h.mode))
		R.Dbg(list[1], "plan", tostring(h.mode), "own", string.format("%.1f", own), "enemies", #fl, string.format("%.1f", fs))
		if h.mode == "strike" then   -- all together, at once
			for _, b in ipairs(list) do if b.Role ~= "survivor" and b.Role ~= "colonist" then b.NextLook = 0 end end
		end
	end
	-- while holding back, the boldest one or two still harass him: quick bites, then away (skirmishers)
	h.skirmish = h.skirmish or {}
	for b in pairs(h.skirmish) do if not IsValid(b) or b.RepGone or h.mode ~= "hold" then h.skirmish[b] = nil end end
	if h.mode == "hold" and #fl > 0 and table.Count(h.skirmish) < math.min(2, math.ceil(n / 5)) then
		local best, bb
		for _, b in ipairs(list) do
			local bold = b.Mind and b.Mind.bold or 1
			if not h.skirmish[b] and (b.Role == "hunter" or b.Role == "worker") and b.State ~= "ambush" and not b.Boarded and not b.InTower and (not bb or bold > bb) then best, bb = b, bold end
		end
		if best then h.skirmish[best] = true; R.Stat("skirmishers") end
	end
	if h.mode == "hold" then
		-- out of sight of the enemies, near the Queen: gather and grow
		if not h.rally or now > (h.rallyT or 0) then
			local fp = {}
			for _, e in ipairs(fl) do fp[#fp + 1] = e:GetPos() end
			local c = queens[1]:GetPos()
			h.rally = M.HideSpot(c, fp, 300, 1500) or c
			h.rallyT = now + 15
		end
	else
		h.rally = nil
	end

	-- 2. sabotage: threatening players' own DHDs (not the map's) are eaten - no escape through the gate
	if #fl > 0 and n >= 8 then
		h.sab = h.sab or {}
		for _, d in ipairs(ents.FindByClass("dhd_*")) do
			if IsValid(d) and not R.MapItem(d) and R.Edible(d) and not (IsValid(h.sab[d]) and h.sab[d].Target == d) then
				local close = false
				for _, e in ipairs(fl) do if e:IsPlayer() and e:GetPos():DistToSqr(d:GetPos()) < 3000 * 3000 then close = true end end
				if close then
					local best, bd
					for _, b in ipairs(list) do
						if b.Role == "worker" or b.Role == "hunter" then
							local dd = b:GetPos():DistToSqr(d:GetPos())
							if not bd or dd < bd then best, bd = b, dd end
						end
					end
					if best then
						best.Role, best.State, best.Target, best.NextLook = "saboteur", "eat", d, now + 20
						h.sab[d] = best
						R.Stat("sabotage")
						R.Dbg(best, "sabotage", d:GetClass())
					end
				end
			end
		end
	end
	-- guards at the map's gate when players are near it (the swarm needs that gate itself, it does not eat it)
	if n >= 12 then
		h.gateGuards = h.gateGuards or {}
		for _, g in ipairs(ents.GetAll()) do
			if g.IsStargate and g:GetClass():find("^stargate_") and R.MapItem(g) then
				local players = false
				for _, p in ipairs(player.GetAll()) do if p:GetPos():DistToSqr(g:GetPos()) < 1500 * 1500 then players = true end end
				local have = 0
				for _, b in ipairs(h.gateGuards[g] or {}) do if IsValid(b) and b.Role == "gateguard" then have = have + 1 end end
				if players and have < 2 then
					h.gateGuards[g] = {}
					local picked = 0
					for _, b in ipairs(list) do
						if picked < 2 and b.Role == "worker" then
							b.Role, b.GuardAt = "gateguard", g:GetPos() + g:GetForward() * 200
							table.insert(h.gateGuards[g], b)
							picked = picked + 1
						end
					end
					if picked > 0 then R.Stat("gate guards") end
				end
			end
		end
	end

	-- escorts: a tower or a bridge being built with enemies near - two bugs guard the builders (and go for whoever comes)
	local jobs = {}
	for _, T in pairs(h.towers or {}) do if T.base and #T.n > 0 then jobs[#jobs + 1] = T.base end end
	for _, T in pairs(h.bridges or {}) do if not T.done and T.a then jobs[#jobs + 1] = T.a end end
	local escorts = 0
	for _, b in ipairs(list) do
		if b.Role == "escort" then
			local still = false
			for _, j in ipairs(jobs) do if b.GuardAt and b.GuardAt:DistToSqr(j) < 300 * 300 then still = true end end
			if still and #fl > 0 then escorts = escorts + 1 else b.Role, b.GuardAt = nil, nil end
		end
	end
	if #fl > 0 and #jobs > 0 and escorts < 2 then
		for _, b in ipairs(list) do
			if escorts >= 2 then break end
			if b.Role == "hunter" and not b.InTower and not b.InBridge and b.State ~= "attack" then
				b.Role, b.GuardAt = "escort", jobs[1] + VectorRand() * 80 * Vector(1, 1, 0)
				escorts = escorts + 1
				R.Stat("escorts")
			end
		end
	end
	-- 3. ambushes: when holding back (or with nothing to do), a few hunters wait on walls above the players' paths
	local amb = 0
	for _, b in ipairs(list) do if b.State == "ambush" then amb = amb + 1 end end
	-- (owner 2026-11-05: the drop from over a door or from the ceiling "should be some form of attack they can decide
	-- on": also while they attack, when the prey is inside a building - there a drop from above is a real chance - up to
	-- two bugs go and wait on its ways, the rest hunt it)
	local indoor
	if R.cv.attack:GetInt() >= 2 and h.mode ~= "hold" then
		for _, p in ipairs(player.GetAll()) do
			if p:Alive() and #list > 0 and p:GetPos():DistToSqr(list[1]:GetPos()) < 3000 * 3000
				and util.TraceLine({ start = p:EyePos(), endpos = p:EyePos() + Vector(0, 0, 500), mask = MASK_SOLID_BRUSHONLY }).Hit then indoor = p break end
		end
	end
	local maxAmb = indoor and 2 or 3
	if amb < math.min(maxAmb, math.max(indoor and 1 or 0, math.floor(n / 6))) and (indoor or h.mode == "hold" or (#fl == 0 and R.cv.attack:GetInt() >= 2)) then
		local taken = {}
		for _, b in ipairs(list) do
			if amb >= maxAmb then break end
			if (b.Role == "hunter" or b.Role == "worker") and (b.State ~= "attack" or indoor) and b.RepClimb and not b.Boarded and not b.InTower and not b.Clinging then
				-- over a door, over an open path or on a ceiling: which pays off, the swarm learns (R.AmbushJudge);
				-- with the prey indoors the spots are looked for round it
				local near = indoor and indoor:GetPos() or b:GetPos()
				local dspot, dkey, dfloor = R.DoorSpot(near, taken)
				local pspot, pcell = R.AmbushSpot(near, taken)
				local cspot, ccell = R.CeilingSpot(near, taken)
				local kind, kw
				for _, k in ipairs({ { "door", dspot }, { "path", pspot }, { "ceiling", cspot } }) do
					if k[2] then
						local w = R.Brain.Weight("ambush", k[1]) * math.Rand(0.8, 1.2)
						if not kw or w > kw then kind, kw = k[1], w end
					end
				end
				local spot = (kind == "door") and dspot or (kind == "ceiling") and cspot or pspot
				local cell = (kind == "door") and dkey or (kind == "ceiling") and ccell or pcell
				if spot then
					taken[cell] = true
					b.State, b.Target, b.AmbushAt, b.AmbushUntil = "ambush", nil, spot, now + 90
					b.AmbushKind, b.AmbushT0, b.AmbushS0 = kind, now, b.BrainScore or 0
					b.AmbushFloor = (kind == "door") and dfloor or (kind == "ceiling" and ccell and ccell.p) or (pcell and pcell.p)
					if kind == "ceiling" then R.Stat("ceiling ambushes") end
					if kind == "door" then R.Stat("door ambushes") end
					b.Route, b.Goal = nil, nil
					b:GoTo(spot, 1.0)
					amb = amb + 1
					R.Stat("ambushes")
					R.Dbg(b, "ambush", tostring(spot))
				end
			end
		end
	end

	-- 4. nests: a big swarm sends 4 settlers to metal far from every Queen; there 3 become a new Queen, 1 her guard
	local settlers = 0
	for _, b in ipairs(list) do if b.Role == "settler" then settlers = settlers + 1 end end
	if settlers == 0 and n >= 14 and #fl == 0 and #queens < math.min(1 + math.floor(n / 14), 4) and R.Count("queens") < R.cv.queens:GetInt()
		and now > (h.nextNest or 0) then
		h.nextNest = now + 90
		local far, fd
		for _, m in ipairs(R.KnownList and R.KnownList(owner) or {}) do
			if IsValid(m) then
				local md = math.huge
				for _, q in ipairs(queens) do md = math.min(md, m:GetPos():Distance(q:GetPos())) end
				if md > 1500 and md < 6000 and (not fd or md > fd) then far, fd = m, md end
			end
		end
		if far then
			local at = far:GetPos() + VectorRand() * 120
			at.z = far:GetPos().z
			table.sort(list, function(a, b) return a:GetPos():DistToSqr(at) < b:GetPos():DistToSqr(at) end)
			local nest = { at = at, bugs = {}, untilT = now + 120, t0 = now }
			for _, b in ipairs(list) do
				if #nest.bugs < 4 and b.Role == "worker" and not b.Boarded and not b.InTower then
					b.Role, b.Nest = "settler", nest
					nest.bugs[#nest.bugs + 1] = b
				end
			end
			if #nest.bugs == 4 then
				R.Stat("nests sent")
				R.Dbg(nest.bugs[1], "settlers to", tostring(at), "metal", far:GetClass())
			else
				for _, b in ipairs(nest.bugs) do b.Role, b.Nest = nil, nil end
			end
		end
	end
end

-- settlers at their place: 3 become a Queen, the 4th her guard (one lost on the way: 3 still make her) (the same merge as a swarm without a Queen)
timer.Create("AGPRepNests", 1, 0, function()
	if R.merging then return end
	local nests = {}
	for b in pairs(R.bugs) do
		if IsValid(b) and b.Role == "settler" and b.Nest then nests[b.Nest] = true end
	end
	for nest in pairs(nests) do
		local here, alive = {}, {}
		for _, b in ipairs(nest.bugs) do
			if IsValid(b) and not b.RepGone and b.Role == "settler" then
				alive[#alive + 1] = b
				if b:GetPos():DistToSqr(nest.at) < 250 * 250 then here[#here + 1] = b end
			end
		end
		-- the way there is too hard (30 s): the nest moves to where most of the settlers are (if that is far
		-- enough from the old nest), the others come to it there - once; it fails again: back to normal work at untilT
		if #alive >= 3 and #here < 3 and not nest.moved and CurTime() - nest.t0 > 30 then
			nest.moved = true
			-- where most of them are together
			local best, bn
			for _, x in ipairs(alive) do
				local k = 0
				for _, y in ipairs(alive) do if x:GetPos():DistToSqr(y:GetPos()) < 300 * 300 then k = k + 1 end end
				if not bn or k > bn then best, bn = x, k end
			end
			local c = best:GetPos()
			local far = true
			for q in pairs(R.queens) do if IsValid(q) and q.RepOwner == alive[1].RepOwner and q:GetPos():DistToSqr(c) < 1000 * 1000 then far = false end end
			if far then nest.at = c; nest.untilT = CurTime() + 60; R.Dbg(best, "nest moves to here") end
		end
		-- still not 3 there a while after that: the Queen sends the free bugs nearest to the nest instead of the stuck ones
		if nest.moved and #here < 3 and #here >= 1 and not nest.refilled and CurTime() - nest.t0 > 55 then
			nest.refilled = true
			local me = R.Self(here[1].RepOwner)
			local cand = {}
			for _, b in ipairs(me.free) do if b.Role ~= "settler" then cand[#cand + 1] = b end end
			table.sort(cand, function(a, b) return a:GetPos():DistToSqr(nest.at) < b:GetPos():DistToSqr(nest.at) end)
			for _, b in ipairs(alive) do if b:GetPos():DistToSqr(nest.at) > 250 * 250 then b.Role, b.Nest = nil, nil end end
			nest.bugs = table.Copy(here)
			for k = 1, math.min(#cand, 4 - #here) do
				cand[k].Role, cand[k].Nest = "settler", nest
				nest.bugs[#nest.bugs + 1] = cand[k]
			end
			R.Dbg(here[1], "nest calls", 4 - #here, "more")
			alive = nest.bugs
		end
		if #alive < 3 or CurTime() > nest.untilT then   -- lost one on the way, or too long: back to normal work
			for _, b in ipairs(alive) do b.Role, b.Nest = nil, nil end
		elseif #here >= 3 and R.Count("queens") < R.cv.queens:GetInt() then   -- 3 are enough (the 4th, if there, guards her)
			R.StartMerge({ here[1], here[2], here[3] }, here[4], here[1]:GetPos())
			for _, b in ipairs(here) do b.Nest = nil; b.Role = nil end
			R.Stat("nests built")
			return
		end
	end
end)
