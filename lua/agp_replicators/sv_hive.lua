--[[
	Replicators: the hive (server). One hive per swarm (per owner). The hive's commander is the QUEEN: with a Queen the
	swarm is coordinated, without one it is a loose group where every bug decides alone (its own character and the
	shared memory only) - so killing the Queen makes them much less dangerous until they have built a new one, which
	then is their first goal. Every 3 seconds the Queen looks at her swarm and decides:
	- roles: scouts (explore the edge of what they know, find metal and hiding places), workers (eat, carry metal), hunters
	  (fight), guards (stay with the Queen), survivors (see below). Roles are suggestions the bugs weigh in their own
	  decisions, not orders;
	- survival: when the swarm is losing (several destroyed within seconds), one or two slip away in the chaos - silent,
	  out of sight, as far as they decide to go - lie low, and later start a new swarm there;
	- learning: after each fight it compares what the swarm did with what it cost (damage dealt, bugs lost) and shifts its
	  boldness; it remembers per map (with the map memory) which tactics worked: rushing in or gathering first.
	Like in the series they go for technology first: power sources, ZPMs, shields, gates and ships are worth more to them
	than plain metal.
]]
local R = AGP.Rep
local M = R.Map
R.hives = R.hives or {}

local function key(owner) return IsValid(owner) and owner or game.GetWorld() end

function R.Hive(owner)
	local k = key(owner)
	local h = R.hives[k]
	if not h then
		h = { losses = {}, survivors = {}, bold = 1, gather = 0.5, fights = {}, scoutGoals = {} }
		local saved = R.LearnedTactics and R.LearnedTactics[game.GetMap()]
		if saved then h.bold, h.gather = saved.bold or 1, saved.gather or 0.5 end
		R.hives[k] = h
	end
	return h
end

-- technology is worth more than plain metal (series: they seek advanced technology)
local TECH = { "zpm", "naquadah", "generator", "reactor", "shield", "stargate", "dhd", "ship", "sg_vehicle", "hatak",
	"jumper", "power", "core", "crystal", "transporter", "asgard", "ancient", "drone", "e2", "wire", "gate", "agp_" }
function R.TechValue(e)
	local cls = e:GetClass()
	if cls == "agp_hatak_powercrystal" or (IsValid(e.AGPShip) and cls:find("zpm", 1, true)) then return 6 end   -- a ship's power core first
	if R.IsShip(e) or IsValid(e.AGPShip) then return 3 end
	for _, w in ipairs(TECH) do if cls:find(w, 1, true) then return 2 end end
	return 1
end

-- strong energy and advanced technology draw them from far away (series: they go for the most advanced technology
-- there is). Every 3 s the map's power sources are listed with how strongly they "call": a ZPM across the whole map,
-- a generator or a ship from far, an open Stargate, a shield. Close metal they smell anyway (sense in the bug).
local LURES = { { "zpm", 5 }, { "hatak", 5 }, { "naquadah", 3 }, { "generator", 3 }, { "reactor", 3 }, { "core", 3 },
	{ "shield", 3 }, { "sg_vehicle", 3 }, { "jumper", 3 }, { "stargate", 2 }, { "dhd", 2 }, { "drone", 2 }, { "asgard", 2 }, { "ancient", 2 } }
-- the PowerGrid addon's generators and cells (class agp_solar_*, agp_wind_turbine, agp_cell_*; their ENT.AGPKind)
-- matched none of the names above - the swarm never saw them
--
local POWERGRID_KINDS = { solar = 3, wind = 3, storage = 3 }
function R.LurePower(e)
	if e.AGPReplicator or e:IsPlayer() or e:IsWeapon() then return nil end
	local cls = e:GetClass()
	-- (series) aboard a ship they go for its engines: the Ha'tak's power crystals and a ZPM on the hub call them strongly
	if IsValid(e.AGPShip) then
		if cls == "agp_hatak_powercrystal" and not (e.GetBurnt and e:GetBurnt()) then return 4 end
		if cls:find("zpm", 1, true) then return 5 end
		return nil
	end
	local pg = POWERGRID_KINDS[e.AGPKind or ""]
	if pg and cls:find("^agp_") then return pg end
	for _, l in ipairs(LURES) do
		if cls:find(l[1], 1, true) then
			-- an open gate: a lot of energy - but only one that dials out; the receiving one's horizon kills
			if cls:find("stargate", 1, true) and e.IsOpen == true then
				if R.GateInbound and R.GateInbound(e) then return nil end
				return 4
			end
			return l[2]
		end
	end
end
local lureList, lureT = {}, 0
local function lures()
	if CurTime() < lureT then return lureList end
	lureT = CurTime() + 3
	lureList = {}
	for _, e in ipairs(ents.GetAll()) do
		local power = IsValid(e) and R.LurePower(e)
		if power then lureList[#lureList + 1] = { e = e, power = power } end
	end
	return lureList
end
-- the strongest call for this bug (power over distance), or nil. Only what it can do something with: eat it or drain it.
function R.Lure(bug, pos)
	local best, bs, bp
	for _, l in ipairs(lures()) do
		local e = l.e
		if IsValid(e) and not (bug.Avoid and bug.Avoid[e] and bug.Avoid[e] > CurTime()) then
			local d = e:GetPos():Distance(pos)
			local shield = R.IsShield(e)
			if d > bug.RepSmell and d < 1500 * l.power and (shield or R.Edible(e)) and R.Eaters(e) < (shield and 6 or R.BiteSlots(e)) and not (R.MapItem(e) and not R.MapFoodOk(bug.RepOwner, pos)) then
				local s = l.power / (d + 500)
				if not bs or s > bs then best, bs, bp = e, s, l.power end
			end
		end
	end
	return best, bp
end

-- what a swarm knows about itself (counted once a second): how many bugs, how many small ones, how healthy they are,
-- how tall they stand (for a tower) and which ones are free for a job (not fighting, delivering, on a ship, on a mission)
local selfKnow = setmetatable({}, { __mode = "k" })
function R.BodyHeight(b) return b.RepMini and 10 or 20 end
function R.Self(owner)
	local k = IsValid(owner) and owner or "world"
	local s = selfKnow[k]
	if s and CurTime() < s.t then return s end
	s = { t = CurTime() + 1, n = 0, mini = 0, hp = 0, free = {} }
	for b in pairs(R.bugs) do
		if IsValid(b) and not b.RepGone and b.RepOwner == owner then
			s.n = s.n + 1
			if b.RepMini then s.mini = s.mini + 1 end
			local hp = math.Clamp(b:Health() / math.max(1, b.RepHealth or 1), 0, 1)
			s.hp = s.hp + hp
			if not b.InTower and not b.InBridge and not b.BridgeJob and not b.Crossing and b.State ~= "ambush" and b.Role ~= "settler" and not b.Boarded and not b.Falling and b.Role ~= "survivor" and b.Role ~= "colonist" and not b.Pursuit
				and b.State ~= "attack" and b.State ~= "deliver" and b.State ~= "flee" and hp > 0.4 then
				s.free[#s.free + 1] = b
			end
		end
	end
	s.hp = s.n > 0 and s.hp / s.n or 0
	selfKnow[k] = s
	return s
end

-- ways to get at something out of reach, in the order the swarm tries them. After 3 jumps that missed it does not just
-- give up: the swarm (shared, the Queen leads) thinks of the next way - from a high spot nearby, from the side of a
-- building, a tower of their own bodies right below it. All tried: that target rests for a minute, then again.
R.TACTICS = { "top", "side", "tower" }
function R.Tactic(owner, target)
	local h = R.Hive(owner)
	h.tactics = h.tactics or setmetatable({}, { __mode = "k" })
	local t = h.tactics[target]
	if not t then t = { i = 1, misses = 0 }; h.tactics[target] = t end
	return R.TACTICS[t.i], t
end
function R.Missed(bug, target)
	local _, t = R.Tactic(bug.RepOwner, target)
	t.misses = t.misses + 1
	if t.misses < 3 then return end
	t.misses = 0
	t.i = t.i + 1
	R.Stat("new idea")
	if t.i > #R.TACTICS then
		t.i = 1
		return true   -- every way failed: the bug leaves it alone for a while
	end
	R.Dbg(bug, "new idea against", target:GetClass(), ":", R.TACTICS[t.i])
end

-- a bug of this swarm was destroyed (not by falling apart into blocks that rebuild: those count too, it was a loss)
function R.Lost(owner, where)
	local h = R.Hive(owner)
	h.losses[#h.losses + 1] = CurTime()
	if where and M then M.Mark(where, "d", 1) end
	if h.fight then h.fight.lost = h.fight.lost + 1 end
end
-- damage this swarm did to enemies (the hive rates its fights by it)
function R.Dealt(owner, amount)
	local h = R.Hive(owner)
	if h.fight then h.fight.dealt = h.fight.dealt + amount end
end

local function swarms()
	local s = {}
	for b in pairs(R.bugs) do
		if IsValid(b) and not b.RepGone then
			local k = key(b.RepOwner)
			s[k] = s[k] or {}
			table.insert(s[k], b)
		end
	end
	return s
end

local function enemiesNear(list)
	local out = {}
	for _, p in ipairs(player.GetAll()) do
		if p:Alive() then
			for _, b in ipairs(list) do
				if R.MayAttack(b, p) and b:GetPos():DistToSqr(p:GetPos()) < 2000 * 2000 then out[#out + 1] = p:GetPos() break end
			end
		end
	end
	return out
end

-- the hive's look at its swarm
local function direct(k, list)
	local h = R.Hive(IsValid(k) and k or nil)
	local now = CurTime()
	-- losses in the last 25 s
	local recent = 0
	for i = #h.losses, 1, -1 do
		if now - h.losses[i] < 25 then recent = recent + 1 else table.remove(h.losses, i) end
	end
	local enemies = enemiesNear(list)
	-- a fight starts / ends: rate it and learn (bolder when it paid off, more careful - gathering first - when not)
	if #enemies > 0 and not h.fight then h.fight = { t = now, dealt = 0, lost = 0, gathered = math.random() < h.gather } end
	if #enemies == 0 and h.fight and now - h.fight.t > 10 then
		local f = h.fight
		local score = f.dealt / 40 - f.lost
		h.bold = math.Clamp(h.bold + (score > 0 and 0.06 or -0.06), 0.6, 1.6)
		-- gathering before striking: learned by trial and error, 15 % of fights try the other way anyway
		if f.gathered then h.gather = math.Clamp(h.gather + (score > 0 and 0.05 or -0.05), 0.1, 0.9)
		else h.gather = math.Clamp(h.gather + (score > 0 and -0.05 or 0.05), 0.1, 0.9) end
		R.LearnedTactics = R.LearnedTactics or {}
		R.LearnedTactics[game.GetMap()] = { bold = h.bold, gather = h.gather }
		h.fight = nil
	end
	-- roles
	local n = #list
	local queens = {}
	for q in pairs(R.queens) do if IsValid(q) and not q.RepGone and key(q.RepOwner) == k then queens[#queens + 1] = q end end
	h.enemies, h.queens, h.size = enemies, queens, n
	if #queens == 0 then
		-- no Queen, no commander: no roles, no tactics; only instinct - when the losses are heavy one bug may slip away
		for _, b in ipairs(list) do if b.Role ~= "survivor" then b.Role = nil end end
		local alive = 0
		for _, s in ipairs(h.survivors) do if IsValid(s) and s.Role == "survivor" then alive = alive + 1 end end
		if R.cv.survive:GetBool() and #enemies > 0 and recent >= math.max(3, n * 0.4) and alive == 0 and n >= 2 and math.random() < 0.5 then
			local s = list[math.random(1, n)]
			s.Role, s.RepSilent, s.SurvivePhase, s.SurviveT = "survivor", true, "escape", now
			s:SetNWBool("RepSilent", true)
			h.survivors = { s }
		end
		return
	end
	local wantScouts = math.max(1, math.floor(n / 8))
	local wantHunters = #enemies > 0 and math.ceil(n * 0.55 * h.bold) or math.floor(n * 0.15)
	local scouts, hunters = 0, 0
	for _, b in ipairs(list) do
		if b.Role == "scout" then scouts = scouts + 1 elseif b.Role == "hunter" then hunters = hunters + 1 end
	end
	-- survivors: the swarm is losing - the Queen sends one or two (away from the enemies) off to start again elsewhere
	local alive = 0
	for _, s in ipairs(h.survivors) do if IsValid(s) and s.Role == "survivor" then alive = alive + 1 end end
	if R.cv.survive:GetBool() and #enemies > 0 and recent >= math.max(3, n * 0.3) and alive == 0 and n >= 2 then
		table.sort(list, function(a, b)
			local da, db = 0, 0
			for _, e in ipairs(enemies) do da = da + a:GetPos():Distance(e); db = db + b:GetPos():Distance(e) end
			return da > db
		end)
		h.survivors = {}
		for i = 1, math.min(n >= 6 and 2 or 1, n) do
			local s = list[i]
			s.Role, s.RepSilent = "survivor", true
			s:SetNWBool("RepSilent", true)
			s.SurvivePhase, s.SurviveT = "escape", now
			h.survivors[#h.survivors + 1] = s
		end
	end
	for _, b in ipairs(list) do
		if b.Role == "saboteur" and not (b.State == "eat" and IsValid(b.Target)) then b.Role = nil end   -- job done
		if b.Role ~= "survivor" and b.Role ~= "settler" and b.Role ~= "saboteur" and b.Role ~= "gateguard" and b.Role ~= "escort" and b.Role ~= "pursuer" and not IsValid(b.RepGuard) then
			if b.Role == "scout" and scouts > wantScouts + 1 then b.Role = nil; scouts = scouts - 1 end
			if not b.Role or b.Role == "worker" then
				if hunters < wantHunters and (b.Mind and b.Mind.bold or 1) > 0.9 then b.Role = "hunter"; hunters = hunters + 1
				elseif scouts < wantScouts and (b.Mind and b.Mind.curious or 1) > 0.8 then b.Role = "scout"; scouts = scouts + 1
				else b.Role = "worker" end
			elseif b.Role == "hunter" and #enemies == 0 and hunters > wantHunters then
				b.Role = "worker"; hunters = hunters - 1
			end
		elseif IsValid(b.RepGuard) then
			b.Role = "guard"
		end
	end
	-- a big swarm sends colonists through a Stargate: 4 bugs, one dials (at the DHD if there is one), all go through
	if R.cv.gates:GetBool() and n >= R.cv.gateSwarm:GetInt() and now > (h.nextColony or 0) then
		h.nextColony = now + 240
		local c = Vector()
		for _, b in ipairs(list) do c:Add(b:GetPos()) end
		c:Div(n)
		local src, sd
		for _, g in ipairs(ents.GetAll()) do
			if g.IsStargate and g.DialGate and g:GetClass():find("^stargate_") and not g.IsOpen and not g.Dialling and (g.GetGateAddress and g:GetGateAddress() or "") ~= ""
				and not (h.badGates and h.badGates[g] and h.badGates[g] > now) then
				local d = g:GetPos():DistToSqr(c)
				if d < 6000 * 6000 and (not sd or d < sd) then src, sd = g, d end
			end
		end
		local dst
		if src then
			local cands = {}
			for _, g in ipairs(ents.GetAll()) do
				if g ~= src and g.IsStargate and g.DialGate and g:GetClass():find("^stargate_") and (g:GetGateAddress() or "") ~= "" and g:GetPos():DistToSqr(src:GetPos()) > 1500 * 1500
					and not (h.badGates and h.badGates[g] and h.badGates[g] > now) then cands[#cands + 1] = g end
			end
			dst = cands[math.random(1, math.max(1, #cands))]
		end
		if src and dst then
			local dhd
			for _, e in ipairs(ents.FindInSphere(src:GetPos(), 700)) do if e:GetClass():find("^dhd_") then dhd = e break end end
			table.sort(list, function(a, b) return (a.Mind and a.Mind.curious or 1) > (b.Mind and b.Mind.curious or 1) end)
			local colony = { src = src, dst = dst, dhd = dhd, untilT = now + 180, phase = "go" }
			local picked = 0
			for _, b in ipairs(list) do
				if picked < 4 and b.Role ~= "survivor" and b.Role ~= "guard" and not b.Boarded then
					picked = picked + 1
					b.Role, b.Colony = "colonist", colony
					colony.leader = colony.leader or b
				end
			end
		end
	end
	-- and a few by ring to another ring platform (sv_pursuit.lua)
	if R.cv.gates:GetBool() and R.RingColony then R.RingColony(h, list, n, now) end
	-- the Queen's plans: strength, sabotage, guards, ambushes, new nests (sv_tactics.lua)
	if R.Plan then R.Plan(h, IsValid(k) and k or nil, list, queens, now) end
	-- a goal for each scout at the edge of what is known (spread: not two to the same place)
	h.scoutGoals = {}
	for _, b in ipairs(list) do
		if b.Role == "scout" and (not b.ScoutGoal or now > (b.ScoutUntil or 0) or b:GetPos():DistToSqr(b.ScoutGoal) < 100 * 100) then
			local g = M.Frontier(b:GetPos(), 300, 3000)
			if not g then
				local a = math.random() * math.pi * 2
				g = b:GetPos() + Vector(math.cos(a), math.sin(a), 0) * math.Rand(600, 1500)
			end
			b.ScoutGoal, b.ScoutUntil = g, now + 25
		end
	end
end

timer.Create("AGPRepHive", 3, 0, function()
	if not R.Awake() then return end
	for k, list in pairs(swarms()) do direct(k, list) end
end)

-- learned tactics are kept per map with the map memory
local function tfile() return "agp_replicators/tactics.txt" end
hook.Add("InitPostEntity", "AGPRepTacticsLoad", function()
	R.LearnedTactics = util.JSONToTable(file.Read(tfile(), "DATA") or "") or {}
end)
hook.Add("ShutDown", "AGPRepTacticsSave", function()
	file.CreateDir("agp_replicators")
	file.Write(tfile(), util.TableToJSON(R.LearnedTactics or {}))
end)
