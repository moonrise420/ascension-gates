-- Replicators: a brain that learns which decisions pay off (owner 2026-11-02: "they need to learn what good decisions are").
-- Every kind of decision a bug can take (eat, board, tower, flank, ambush, wait, guard ...) has a learned value for each
-- situation. A situation is a few coarse facts: what kind of target (on the ground, in the air, none), how crowded it is
-- there, the enemy (none, weak, armed), the swarm's size. In Look the option's score is multiplied by that value.
-- What came of a decision is measured: metal eaten, a ship boarded, a new bug built, an enemy hurt, a shield drained are
-- good; stuck, a missed jump, being shot apart, wasted time are bad. When the bug takes its next decision (or after 15 s)
-- the value moves a little towards what that decision earned.
-- The trained default brain ships with the addon (agp_replicators/brain_default.lua, made by training runs in test
-- games); on top of it every server learns a little more, but only within limits round the default, so it can never
-- drift into stupid habits. agp_rep_learn: 0 = default brain only, 1 = learn (bounded, default), 2 = training (free, for
-- making the default brain).
local R = AGP.Rep
local Br = R.Brain or {}
R.Brain = Br
local cvLearn = CreateConVar("agp_rep_learn", "1", FCVAR_ARCHIVE, "Replicators: 0 = trained default brain only, 1 = they keep learning (within limits), 2 = training mode")
Br.def = Br.def or (include("agp_replicators/brain_default.lua") or {})
-- which mind they think with: 1 = the rules alone, 2 = + the learned values, 3 = + the Queen's network,
-- 4 = + the shared bug network (hive mind) - the setups were compared in test games; 4 is the full mind
local cvMind = CreateConVar("agp_rep_mind", "3", FCVAR_ARCHIVE, "Replicators: 1 rules, 2 + learned values, 3 + Queen's network, 4 + shared hive network")
function Br.Mind() return cvMind:GetInt() end
-- the shared bug network (hive_net.lua, trained from the training runs): how much an option earns in these details
local HIVE = file.Exists("agp_replicators/hive_net.lua", "LUA") and include("agp_replicators/hive_net.lua") or nil
local optIndex = {}
if HIVE then for i, o in ipairs(HIVE.opts) do optIndex[o] = i end end
function Br.HiveValue(f, opt)
	if not HIVE or not optIndex[opt] then return 0 end
	local nf = #HIVE.feats
	local x = {}
	for i = 1, nf do x[i] = ((f[i] or 0) - HIVE.mu[i]) / HIVE.sd[i] end
	for i = 1, #HIVE.opts do x[nf + i] = (i == optIndex[opt]) and 1 or 0 end
	local out = HIVE.b2[1]
	for j = 1, HIVE.n_h do
		local s = HIVE.b1[j]
		for i = 1, HIVE.n_in do local v = x[i] if v ~= 0 then s = s + v * HIVE.W1[(i - 1) * HIVE.n_h + j] end end
		out = out + math.tanh(s) * HIVE.W2[j]
	end
	return out
end
Br.HasHive = HIVE ~= nil
Br.w = Br.w or {}

-- the situation this bug is in, as a short key
function Br.Situation(bug, food, enemy, hive)
	local target = "none"
	if IsValid(food) then
		local air = food:NearestPoint(bug:GetPos()).z - bug:GetPos().z > 45
		target = (R.IsShip(food) or IsValid(food.AGPShip)) and (air and "shipair" or "ship") or (air and "high" or "ground")
	end
	local crowd = R.Crowd and R.Crowd(IsValid(food) and food:GetPos() or bug:GetPos()) >= 5 and "crowd" or "free"
	local foe = "none"
	if IsValid(enemy) then foe = (hive.mode == "hold") and "strong" or "weak" end
	local _, n = R.Centre(bug.RepOwner)
	local size = n < 6 and "few" or n < 30 and "many" or "swarm"
	return target .. "/" .. crowd .. "/" .. foe .. "/" .. size
end

local LIMIT = 0.3   -- learning on a server stays within this of the default
local LO, HI = 0.6, 1.6   -- a value can tip decisions, never switch something essential (like eating) off
Br.cnt = Br.cnt or {}
function Br.Weight(sit, opt)
	if cvMind:GetInt() < 2 then return 1 end
	local k = sit .. "|" .. opt
	return Br.w[k] or Br.def[k] or 1
end

-- a decision was taken: remember it with the bug's score so far
function Br.Decided(bug, sit, opt, feats)
	Br.Settle(bug)
	bug.BrainDec = { sit = sit, opt = opt, t0 = CurTime(), s0 = bug.BrainScore or 0, f = feats }
end
-- the details a decision is taken in (for the shared bug network): numbers, the same order every time
Br.FEATS = { "dist", "dz", "crowd", "hp", "stock", "enemy", "edist", "armed", "plan", "swarm", "big", "ship", "air", "role" }
function Br.Features(bug, food, enemy, edist, hive)
	local pos = bug:GetPos()
	local hp = math.Clamp(bug:Health() / math.max(1, bug.RepHealth or 1), 0, 1)
	local _, n = R.Centre(bug.RepOwner)
	local fp = IsValid(food) and food:NearestPoint(pos) or pos
	return {
		IsValid(food) and math.min(fp:Distance(pos), 4000) or 4000,
		IsValid(food) and math.Clamp(fp.z - pos.z, -1000, 1000) or 0,
		R.Crowd and R.Crowd(IsValid(food) and food:GetPos() or pos) or 0,
		hp, math.min(bug.RepStock or 0, 24),
		IsValid(enemy) and 1 or 0, IsValid(enemy) and math.min(edist or 4000, 4000) or 4000,
		IsValid(enemy) and R.EnemyStrength and R.EnemyStrength(enemy, bug.RepOwner) or 0,
		hive.mode == "strike" and 1 or (hive.mode == "hold" and -1 or 0),
		n, IsValid(food) and R.IsBig(food) and 1 or 0, IsValid(food) and R.IsShip(food) and 1 or 0,
		IsValid(food) and (fp.z - pos.z > 45) and 1 or 0,
		bug.Role == "hunter" and 1 or (bug.Role == "scout" and 2 or (bug.Role == "worker" and 3 or 0)),
	}
end
Br.log = Br.log or {}
-- what came of the last decision moves its value
function Br.Settle(bug)
	local d = bug.BrainDec
	if not d then return end
	bug.BrainDec = nil
	local mode = cvLearn:GetInt()
	if mode == 0 then return end
	local dt = CurTime() - d.t0
	if dt < 0.5 then return end
	local r = (bug.BrainScore or 0) - d.s0 - 0.04 * math.min(dt, 20)   -- time is a cost too
	if mode == 2 and d.f and #Br.log < 200000 then Br.log[#Br.log + 1] = d.opt .. "," .. table.concat(d.f, ",") .. "," .. string.format("%.2f", r) end
	Br.Judge(d.sit, d.opt, r)
end
-- what came of a decision (r: good > 0, bad < 0) moves its value; also for outcomes measured elsewhere (an ambush)
function Br.Judge(sit, opt, r)
	local mode = cvLearn:GetInt()
	if mode == 0 then return end
	local k = sit .. "|" .. opt
	local cur = Br.w[k] or Br.def[k] or 1
	local rate = mode == 2 and 0.08 or 0.02
	local v = cur + rate * math.Clamp(r, -3, 3)
	local base = Br.def[k] or 1
	if mode == 1 then v = math.Clamp(v, base - LIMIT, base + LIMIT) end
	Br.w[k] = math.Clamp(v, LO, HI)
	Br.cnt[k] = (Br.cnt[k] or 0) + 1
	Br.n = (Br.n or 0) + 1
end
-- something good or bad happened to this bug
function R.Reward(bug, amount)
	if not IsValid(bug) then return end
	bug.BrainScore = (bug.BrainScore or 0) + amount
end

-- training mode: now and then the second best option, to find out whether it is better (curiosity)
function Br.Explore() return cvLearn:GetInt() == 2 and math.random() < 0.15 end
Br.Log = true   -- details are recorded (only used in training mode)

-- what it learned is kept (data/agp_replicators/brain.txt); the training runs turn it into the default brain
local function bfile() return "agp_replicators/brain.txt" end
function Br.Save()
	file.CreateDir("agp_replicators")
	file.Write(bfile(), util.TableToJSON({ w = Br.w, cnt = Br.cnt }))
end
function Br.Load()
	local t = util.JSONToTable(file.Read(bfile(), "DATA") or "")
	if istable(t) and istable(t.w) then Br.w, Br.cnt = t.w, t.cnt or {} end
end
-- the learned values as the Lua file of the default brain (for the training runs)
function Br.Export()
	local keys = {}
	for k in pairs(Br.w) do keys[#keys + 1] = k end
	table.sort(keys)
	local out = { "-- Replicators: the trained default brain (made by training runs, agp_replicators/sv_brain.lua)", "return {" }
	for _, k in ipairs(keys) do
		local n = Br.cnt[k] or 0
		local v = 1 + (Br.w[k] - 1) * n / (n + 25)   -- 25 examples = half way to what it learned
		if math.abs(v - 1) > 0.02 then out[#out + 1] = string.format("\t[%q] = %.3f,   -- %d", k, v, n) end
	end
	out[#out + 1] = "}"
	return table.concat(out, "\n")
end
hook.Add("InitPostEntity", "AGPRepBrainLoad", Br.Load)
hook.Add("ShutDown", "AGPRepBrainSave", Br.Save)
timer.Create("AGPRepBrainSave", 300, 0, Br.Save)
