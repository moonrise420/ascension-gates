--[[
	Replicators (Ascension Gates, own code and models) Like in
	SG-1, everything is made of small grey blocks:
	- agp_replicator_block: one block. Free blocks crawl towards each other; 12 of them close together form a Replicator.
	- agp_replicator: the bug. Walks, eats loose metal props (the metal becomes new blocks -> more Replicators), brings
	  metal to its Queen, attacks. Shot apart it falls into blocks that build it again after a while.
	- agp_replicator_queen: bigger and slower; makes new blocks in her brood chamber, faster with the metal the bugs bring.
	  Hurt the Queen and the whole swarm goes for the attacker.
	Only the anti-replicator gun (ARG), the Dakara weapon or removing them stops them for good: then the blocks are dead
	(they go dark and fade). Hard caps for bugs, blocks and queens keep the server safe (server settings below).
]]
AGP = AGP or {}
AGP.Rep = AGP.Rep or { blocks = {}, bugs = {}, queens = {} }
local R = AGP.Rep

R.BLOCKS_PER_BUG = 12
R.MODEL_BLOCK = "models/agp_replicator/agp_replicator_block.mdl"
R.MODEL_BUG = "models/agp_replicator/agp_replicator.mdl"
R.MODEL_QUEEN = "models/agp_replicator/agp_replicator_queen.mdl"

local FL = FCVAR_ARCHIVE + FCVAR_NOTIFY + FCVAR_REPLICATED
R.cv = {
	on = CreateConVar("agp_rep_enabled", "1", FL, "Replicators: 1 = alive (walk, eat, build), 0 = frozen"),
	bugs = CreateConVar("agp_rep_max_bugs", "50", FL, "Replicators: most bugs (default 50 - measured 2026-11-09 in a busy world: about 30 frames a second at 40-50 bugs going about, more while they attack; the lag guard stops the swarm growing earlier on a slower computer)"),
	blocks = CreateConVar("agp_rep_max_blocks", "2000", FL, "Replicators: most loose blocks on the server"),
	queens = CreateConVar("agp_rep_max_queens", "10", FL, "Replicators: most queens on the server"),
	survive = CreateConVar("agp_rep_survive", "1", FL, "Replicators: when a swarm is losing, survivors slip away, hide and start a new swarm (1) or not (0)"),
	gates = CreateConVar("agp_rep_gates", "1", FL, "Replicators: a big swarm sends colonists through a Stargate (they dial it) to start a new swarm elsewhere"),
	gateSwarm = CreateConVar("agp_rep_gate_swarm", "16", FL, "Replicators: how many bugs a swarm needs before it sends colonists through a Stargate"),
	lonegrow = CreateConVar("agp_rep_lone_grow", game.SinglePlayer() and "1" or "0", FL, "Replicators: a lone block slowly builds itself into a small Replicator (default: on in single player, off on servers)"),
	attack = CreateConVar("agp_rep_attack", "1", FL, "Replicators attack: 0 = nobody, 1 = like in the series (only who threatens them, their Queen or their nest), 2 = everybody but the player who spawned them, 3 = everybody"),
	eat = CreateConVar("agp_rep_eat", "2", FL, "Replicators eat metal: 0 = nothing, 1 = loose props (not frozen, not welded), 2 = everything made of metal (props, builds, devices)"),
	rebuild = CreateConVar("agp_rep_rebuild", "1", FL, "Replicators shot apart build themselves again (1) or stay blocks (0)"),
	queenHide = CreateConVar("agp_rep_queen_hide", "1", FL, "Replicators: the Queen goes with her guards to a hidden place far from the players (1) or stays where she was built (0)"),
	lagguard = CreateConVar("agp_rep_lagguard", "1", FL, "Replicators: when the game lags (its frame rate or game time falls), the swarm stops growing and far bugs rest until it runs smoothly again (1) or not (0)"),
	lagfps = CreateConVar("agp_rep_lagguard_fps", "30", FL, "Replicators: the lag guard steps in under this frame rate of the host (single player / listen server; 0 = only when the server itself falls behind)"),
	navscan = CreateConVar("agp_rep_navscan", "1", FL, "Replicators: live area scan - learn the ways around each Replicator in the background and keep them in a file per map, a few MB on big maps (1), or only as ways are needed (0)"),
}

function R.IsReplicator(e)
	return IsValid(e) and e.AGPReplicator == true
end

local function count(t)
	local n = 0
	for e in pairs(t) do if IsValid(e) then n = n + 1 else t[e] = nil end end
	return n
end
function R.Count(kind) return count(R[kind]) end

-- awake: alive (agp_rep_enabled) and not dormant (the lag guard's emergency brake, below)
function R.Awake() return R.cv.on:GetBool() and not (R.lag and R.lag.dormant) end
-- held still with its body asleep: everyone while dormant, far from every player while the game is behind
function R.Resting(b) return R.lag ~= nil and (R.lag.dormant or (b.RepFar and R.lag.behind)) end

if CLIENT then
	-- the lag guard's eyes (single player / listen server): this computer's own frame rate, once a second. The server
	-- and the picture share one computer - when the swarm costs the server too much the frame rate falls first
	-- (100 bugs, the server still kept up, the picture 1.5 frames a second). A window out of focus is held at
	-- fps_max_nofocus (20 by default): its frame rate says nothing then, unless that cap is high.
	local frames, since = 0, SysTime()
	hook.Add("PostRender", "AGPRepFps", function() frames = frames + 1 end)
	timer.Create("AGPRepFps", 1, 0, function()
		local now = SysTime()
		local fps = frames / math.max(now - since, 0.001)
		frames, since = 0, now
		if game.IsDedicated and game.IsDedicated() then return end   -- (players of a dedicated server: their own computers)
		local cap = GetConVar("fps_max_nofocus")
		local valid = system.HasFocus() or (cap ~= nil and (cap:GetFloat() <= 0 or cap:GetFloat() >= 60))
		net.Start("agp_rep_fps"); net.WriteUInt(math.Clamp(math.Round(fps), 0, 1023), 10); net.WriteBool(valid); net.SendToServer()
	end)
	return
end

-- new blocks may appear only while there is room (blocks + the blocks the bugs are made of)
function R.RoomForBlocks(n)
	return R.Count("blocks") + n <= R.cv.blocks:GetInt()
end

-- ---------- the lag guard. Once a second the swarm checks whether the game keeps up: game time against real time (a
-- busy-world test: 100 bugs needed 17 ms for a tick of 15 - game time ran at 74 %, the picture stood still). Under
-- 90 % for 2 s running it is "behind": the swarm stops growing (no new metal turned into blocks by the Queen or
-- a bug - eating and collecting go on; blocks still come together into bugs: 12 bodies become 1), bugs far from every
-- player rest with their bodies asleep (they cost
-- the physics nothing) and the walking budget halves. Keeping up again for 8 s: all goes on. A paused game or a changed
-- game speed (host_timescale) does not count, nor a game with fewer than 20 bugs (they are not what makes it lag; a
-- short hitch at a map start froze 3 test bugs mid-step). And the frame rate of the host's own game (single
-- player / listen server, sent once a second): under agp_rep_lagguard_fps (30) for 3 s it is behind
-- too, and it lets go only at 30 % above that (game time alone missed it - 100 bugs, the server kept up, the
-- picture 1.5 frames a second).
R.lag = R.lag or { behind = false, ratio = 1 }
util.AddNetworkString("agp_rep_fps")
net.Receive("agp_rep_fps", function(_, p)
	local fps, valid = net.ReadUInt(10), net.ReadBool()
	if not IsValid(p) or not (game.SinglePlayer() or p:IsListenServerHost()) then return end
	R.lag.fps, R.lag.fpsOk, R.lag.fpsT = fps, valid, SysTime()
end)
-- how much of their time the swarm's side jobs get (the ways across the map, feeling the map and the props): 1 = all of it,
-- less the lower the host's frame rate is (80 and more: all, 20 and less: a tenth), smoothed; on a dedicated server a third
-- while the game falls behind. 60 bugs at a fresh building on freespace13: 2 frames a second, the side jobs took 4 ms of
-- every 15 ms tick (replag13). Fewer than 12 bugs: all of it
local function ease(L, ratio, real)
	if R.Count("bugs") < 12 or (R.TestOff and R.TestOff.ease) then L.ease = 1 return end
	local want = ratio < 0.97 and 0.3 or 1
	if L.fpsT and real - L.fpsT < 3 and L.fpsOk then want = math.min(want, math.Clamp((L.fps - 14) / 66, 0.1, 1)) end
	L.ease = math.Clamp(Lerp(want < (L.ease or 1) and 0.6 or 0.2, L.ease or 1, want), 0.1, 1)
end
function R.Ease() return R.lag.ease or 1 end
timer.Create("AGPRepLagGuard", 1, 0, function()
	local L = R.lag
	local now, real = CurTime(), SysTime()
	if L.c then
		local ts = game.GetTimeScale() * (GetConVar("host_timescale") and GetConVar("host_timescale"):GetFloat() or 1)
		if ts <= 0 then ts = 1 end
		local ratio = (now - L.c) / math.max(real - L.s, 0.001) / ts
		L.ratio = ratio
		ease(L, ratio, real)
		-- (behind under 88 % for 3 s; keeping up again only at 97 % or more for 8 s running - let go at 88 %, the swarm
		-- grew again until it was behind again and settled where the game always lagged a little)
		local lim = R.cv.lagfps:GetFloat()
		local seen = lim > 0 and L.fpsT ~= nil and real - L.fpsT < 3 and L.fpsOk
		local fpsLow = seen and L.fps < lim
		local fpsFine = not seen or L.fps >= lim * 1.3
		if ratio < 0.88 or fpsLow then L.bad, L.good, L.why = (L.bad or 0) + 1, 0, fpsLow and "frame rate" or "game time"
		elseif ratio >= 0.97 and fpsFine then L.good, L.bad = (L.good or 0) + 1, 0
		else L.bad, L.good = 0, 0 end
		if not L.behind and L.bad >= 3 and R.cv.lagguard:GetBool() and R.Count("bugs") >= 20 then
			L.behind, L.since = true, now
			R.Stat("lag guard: the game fell behind")
			R.Stat("lag guard: by its " .. (L.why or "game time"))
		elseif L.behind and (L.good >= 8 or not R.cv.lagguard:GetBool()) then
			L.behind = false
			R.Stat("lag guard: it keeps up again")
		end
		-- the emergency brake: behind and still nearly frozen - under a third of the guard's frame rate (10) or game time
		-- under half - for 5 s running: the whole swarm goes dormant (100 bugs round the player: 3 frames a second,
		-- the guard alone could not help, its resting is for far bugs)
		--
		local worst = (seen and L.fps < math.max(5, lim / 3)) or ratio < 0.5
		L.worst = (L.behind and worst and R.cv.lagguard:GetBool()) and (L.worst or 0) + 1 or 0
		if not L.dormant and L.worst >= 5 then R.Brake(true, seen and L.fps or nil, ratio) end
		-- awake again: a quarter of them gone (removed, killed), the guard switched off
		if L.dormant and (R.Count("bugs") <= math.floor((L.dormantN or 0) * 0.75) or not R.cv.lagguard:GetBool()) then R.Brake(false) end
	end
	L.c, L.s = now, real
end)

-- dormant (on = true) or awake again. Dormant: every bug held where it is with its body asleep (R.Resting, the far-rest
-- of the guard), clinging ones let go, no brain (R.Awake false: no walking, eating, hunting), no blocks crawling
-- together, the Queen builds nothing (R.Full). The admins (single player: the player) are told what to do.
local function tellAdmins(key, text, ...)
	for _, p in ipairs(player.GetAll()) do
		if game.SinglePlayer() or p:IsAdmin() or p:IsListenServerHost() then AGP.Say(p, key, text, ...) end
	end
end
function R.Brake(on, fps, ratio)
	local L = R.lag
	if on then
		L.dormant, L.dormantN, L.worst = true, R.Count("bugs"), 0
		for b in pairs(R.bugs) do
			if IsValid(b) then
				if b.Clinging then b:Release(false) end
				b.MoveTo, b.Route, b.SurfPath = nil, nil, nil
			end
		end
		R.Stat("lag guard: dormant")
		local how = fps and (math.Round(fps) .. " fps") or (math.Round((ratio or 0) * 100) .. " %")
		tellAdmins("agp_rep_dormant", "The Replicators went dormant: the game was nearly frozen (%s) with %s of them. Remove some (Stargate > Config > Replicators, or with the ARG) or lower Most Replicators. They wake once a quarter of them are gone, or with Wake them.", how, L.dormantN)
	else
		if not L.dormant then return end
		L.dormant, L.bad, L.good, L.worst = false, 0, 0, 0
		L.behind = R.Count("bugs") >= 20   -- (and they do not grow until the game runs well for 8 s - unless only a few are left)
		for b in pairs(R.bugs) do
			if IsValid(b) then
				b.RestAt, b.RestAng, b.NextFarThink = nil, nil, 0
				local ph = b:GetPhysicsObject()
				if IsValid(ph) then ph:Wake() end
				b:NextThink(CurTime())
			end
		end
		R.Stat("lag guard: awake again")
		tellAdmins("agp_rep_awake", "The Replicators are awake again.")
	end
end
concommand.Add("agp_rep_wake", function(p)
	if IsValid(p) and not (p:IsAdmin() or game.SinglePlayer()) then return end
	R.Brake(false)
end)
-- a player coming near wakes the bugs resting there at once - walking, in noclip or unseen, any player: while the game
-- is behind a far bug looks round only every 3 s (noclipping towards them; the busy-world test found 6 of 31 still
-- standing still after 3 s, the slowest woke after 2.98 s)
timer.Create("AGPRepLagWake", 0.5, 0, function()
	if not R.lag.behind or R.lag.dormant then return end
	local ps = player.GetAll()
	if #ps == 0 then return end
	local now = CurTime()
	for b in pairs(R.bugs) do
		if IsValid(b) and b.RepFar then
			local pos = b:GetPos()
			for _, p in ipairs(ps) do
				if p:GetPos():DistToSqr(pos) < 3000 * 3000 then
					b.RepFar, b.RepMid, b.NextFarThink = false, true, 0
					b.RestAt, b.RestAng = nil, nil
					local ph = b:GetPhysicsObject()
					if IsValid(ph) and not b.Eating then ph:Wake() end
					b:NextThink(now)
					R.Stat("lag guard: woken by a player coming near")
					break
				end
			end
		end
	end
end)
-- what resting bugs stood on is removed (a ship blown up or eaten, a prop): they fall at once - asleep, they would not
-- notice it before their next think (the author's play test: bugs and Queen hung in the air where the ship had been)
hook.Add("EntityRemoved", "AGPRepRestGround", function(e)
	if not e.AGPRepRestOn then return end
	for _, kind in ipairs({ "bugs", "queens" }) do
		for b in pairs(R[kind]) do
			if IsValid(b) and b.RestOn == e and b.RestLost then b.RestOn = NULL; timer.Simple(0, function() if IsValid(b) and b.RestAt then b:RestLost() end end) end
			-- (holding on to it, parented: off it before it goes - a removed parent would take them along)
			if IsValid(b) and b.Boarded == e and b.LetGo then b:LetGo() end
		end
	end
end)
-- no new Replicator now: as many as allowed, or the game is behind, or the swarm is dormant
function R.Full()
	return R.Count("bugs") >= R.cv.bugs:GetInt() or R.lag.behind or R.lag.dormant == true
end

-- a block at pos; rest = seconds before it may join a new bug; owner = who gets the bug
function R.SpawnBlock(pos, vel, owner, rest)
	if not R.RoomForBlocks(1) then return nil end
	local b = ents.Create("agp_replicator_block")
	if not IsValid(b) then return nil end
	b:SetPos(pos)
	b:SetAngles(AngleRand())
	b:Spawn(); b:Activate()
	b.RepOwner = owner
	b.RepRest = CurTime() + (rest or 2)
	if IsValid(owner) and b.CPPISetOwner then b:CPPISetOwner(owner) end
	local ph = b:GetPhysicsObject()
	if IsValid(ph) and vel then ph:SetVelocity(vel) end
	return b
end

-- a bug falls apart / a queen breaks: blocks fly out of it.
-- (a Destiny shot kills the whole heap in one tick - 40 bugs x 12 blocks = 480 entities created in one frame, 40 sounds,
-- and the swarm timer then compared all those blocks with each other.) The blocks of a burst are made at most
-- R.BURST_PER_TICK in a tick over the whole server; the rest are queued and made in the next ticks (at the place the
-- bug was), and only a few break sounds play in a short time. setup(block) is called for every block as it is made (the
-- caller's fields).
R.BURST_PER_TICK = 40
R.burstQ = R.burstQ or {}
local burstTick, burstUsed, soundT, soundN = -1, 0, 0, 0
local function burstBudget()
	local tk = engine.TickCount()
	if burstTick ~= tk then burstTick, burstUsed = tk, 0 end
	return R.BURST_PER_TICK - burstUsed
end
local function burstSpawn(job, max)
	local made = 0
	while made < max and job.n > 0 do
		if not R.RoomForBlocks(1) then job.n = 0 break end   -- (the limit counts what is made, not what waits)
		local dir = VectorRand(); dir.z = math.abs(dir.z) + 0.3
		local b = R.SpawnBlock(job.c + VectorRand() * 6, dir:GetNormalized() * math.Rand(80, job.speed or 260), job.owner, job.rest)
		job.n = job.n - 1
		if not b then job.n = 0 break end
		made = made + 1
		job.made[#job.made + 1] = b
		if job.setup then job.setup(b) end
	end
	burstUsed = burstUsed + made
	return made
end
function R.Burst(ent, n, owner, rest, speed, setup)
	local c = ent:WorldSpaceCenter()
	local job = { c = c, n = n, owner = owner, rest = rest, speed = speed, setup = setup, made = {}, t = CurTime() }
	burstSpawn(job, math.max(0, burstBudget()))
	if job.n > 0 then R.burstQ[#R.burstQ + 1] = job; R.Stat("block bursts queued") end
	local now = CurTime()
	if now > soundT then soundT, soundN = now + 0.3, 0 end
	if soundN < 4 then soundN = soundN + 1; sound.Play("agp_replicator/rep_break.wav", c, 78, math.random(95, 110)) end
	return job.made
end
-- (a map cleanup - also the one between the self-test's suites - takes the waiting blocks with it: made after it, they
-- lay at the old places in the next test)
hook.Add("PreCleanupMap", "AGPRepBurstQueue", function() R.burstQ = {} end)
hook.Add("Tick", "AGPRepBurstQueue", function()
	local q = R.burstQ
	if #q == 0 then return end
	local k = 1
	while q[k] do
		local room = burstBudget()
		if room <= 0 then break end
		local job = q[k]
		-- (a job older than 2 s is dropped: the swarm was cleared meanwhile - the tests clear it by hand - or switched off)
		if CurTime() - job.t > 2 or not R.cv.on:GetBool() then job.n = 0 else burstSpawn(job, room) end
		if job.n <= 0 then table.remove(q, k) else k = k + 1 end
	end
end)

-- spawn tab: a bug or a Queen in front of the player, looking at him (within the limits)
function R.SpawnSent(sent, ply, tr)
	if not tr.Hit then return end
	local kind = sent.RepKind
	if R.Count(kind) >= (kind == "queens" and R.cv.queens or R.cv.bugs):GetInt() then
		if kind == "queens" then AGP.Say(ply, "agp_rep_full_queens", "There are already as many Queens as the server allows (agp_rep_max_queens).")
		else AGP.Say(ply, "agp_rep_full_bugs", "There are already as many Replicators as the server allows (agp_rep_max_bugs).") end
		return
	end
	local e = ents.Create(sent.ClassName)
	e:SetPos(tr.HitPos + tr.HitNormal * 4)
	e:SetAngles(Angle(0, ply:GetAimVector():Angle().y + 180, 0))
	e.RepOwner = ply
	e:Spawn(); e:Activate()
	if e.CPPISetOwner then e:CPPISetOwner(ply) end
	if kind == "queens" then
		AGP.Hint(ply, "agp_rep_hint_queen", "The Queen builds Replicator blocks in her brood chamber - 12 blocks form a Replicator. Her bugs bring her metal, then she builds faster. Hurt her and the whole swarm attacks.")
	else
		AGP.Hint(ply, "agp_rep_hint_bug", "Replicators eat loose metal props and turn them into new Replicators. Bullets only knock them apart into blocks that rebuild - the anti-replicator gun (ARG) kills them.")
	end
	return e
end

-- Replicators clinging to a player (agp_replicator.lua, ENT:Cling) weigh him down: 15 % slower each, at most 60 %
hook.Add("SetupMove", "AGPRepCling", function(p, mv)
	local n = p:GetNWInt("AGPRepCling", 0)
	if n > 0 then
		local f = math.max(0.4, 1 - 0.15 * n)
		mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * f)
		mv:SetMaxSpeed(mv:GetMaxSpeed() * f)
	end
end)

-- the swarm's intelligence (one swarm per the player who spawned them, or nobody)
local function key(owner) return IsValid(owner) and owner or game.GetWorld() end

-- shared memory of metal: what one bug smells, every bug of the swarm can go for (forgotten after 2 minutes)
R.metal = R.metal or {}
function R.Remember(owner, prop)
	local m = R.metal[key(owner)] or {}
	R.metal[key(owner)] = m
	m[prop] = CurTime() + 120
end
-- the swarm's shared picture (series: one mind, every Replicator knows what the others know): twice a second, for all
-- bugs at once - who eats / hunts what (planned or busy), where each swarm is, and a crowd map: how many bugs stand in
-- each 160-unit area and how many are on their way there. A bug looks at it before it picks a goal, so it does not walk
-- into a crowd in the first place (with hundreds of bugs, every bug counting all the others itself would cost too much)
R.eatCount, R.huntCount, R.centres, R.crowd = R.eatCount or {}, R.huntCount or {}, R.centres or {}, R.crowd or {}
local CROWD = 160
local function ckey(p) return math.floor(p.x / CROWD) .. ":" .. math.floor(p.y / CROWD) .. ":" .. math.floor(p.z / CROWD) end
local BG = 400
local function bkey(x, y) return math.floor(x / BG) .. ":" .. math.floor(y / BG) end
R.bugGrid = R.bugGrid or {}
timer.Create("AGPRepCounts", 0.5, 0, function()
	local eat, hunt, sum, crowd, grid = {}, {}, {}, {}, {}
	for b in pairs(R.bugs) do
		if IsValid(b) and not b.RepGone then
			local bp = b:GetPos()
			local gk = bkey(bp.x, bp.y)
			grid[gk] = grid[gk] or {}
			table.insert(grid[gk], b)
			local t = b.Target
			if IsValid(t) then
				if b.State == "eat" then eat[t] = (eat[t] or 0) + 1 elseif b.State == "attack" then hunt[t] = (hunt[t] or 0) + 1 end
			end
			local k = key(b.RepOwner)
			local s = sum[k] or { p = Vector(), n = 0 }
			s.p:Add(b:GetPos()); s.n = s.n + 1
			sum[k] = s
			local here = ckey(b:GetPos())
			crowd[here] = (crowd[here] or 0) + 1
			local goal = b.Goal or b.MoveTo
			if goal then local g = ckey(goal) if g ~= here then crowd[g] = (crowd[g] or 0) + 0.7 end end   -- on its way there
		end
	end
	for _, s in pairs(sum) do s.p:Div(s.n) end
	local nb = 0
	for _, s in pairs(sum) do nb = nb + s.n end
	R.eatCount, R.huntCount, R.centres, R.crowd, R.bugGrid, R.bugN = eat, hunt, sum, crowd, grid, nb
end)
-- how many bugs of this swarm are within r (up to 600) of pos: from the shared picture's areas (where each bug stood half
-- a second ago, two areas round it), counted where they are now
function R.Mates(bug, pos, r)
	local n, r2 = 0, r * r
	local gx, gy = math.floor(pos.x / BG), math.floor(pos.y / BG)
	for x = gx - 2, gx + 2 do
		for y = gy - 2, gy + 2 do
			for _, b in ipairs(R.bugGrid[x .. ":" .. y] or {}) do
				if b ~= bug and IsValid(b) and not b.RepGone and b.RepKind == "bugs" and b.RepOwner == bug.RepOwner and b:GetPos():DistToSqr(pos) < r2 then n = n + 1 end
			end
		end
	end
	return n
end
-- what a bug can sense (players, NPCs and things it may eat) without asking the engine for everything round it - with
-- hundreds of bugs most of what is round a bug are other bugs. Once a second the hive lists the edible things by area
-- (512 units); players, NPCs, big things (a ship: its hull reaches far from its middle) and moving things are checked
-- every time where they are now. A bug asks for the areas round it; the same checks as before decide (R.Edible, ...).
local SG = 512
local senseGrid, senseAll, senseT = {}, {}, 0
local function senseRefresh()
	local now = CurTime()
	if now < senseT then return end
	senseT = now + 1
	senseGrid, senseAll = {}, {}
	for _, e in ipairs(ents.GetAll()) do
		if e.AGPReplicator then
		elseif e:IsPlayer() or e:IsNPC() then senseAll[#senseAll + 1] = e
		elseif R.Edible(e) then
			local root = e
			while IsValid(root:GetParent()) do root = root:GetParent() end   -- a part of a ship moves with the ship
			if e:BoundingRadius() > 200 or root:GetVelocity():LengthSqr() > 100 * 100 then senseAll[#senseAll + 1] = e
			else
				local p = e:GetPos()
				local k = math.floor(p.x / SG) .. ":" .. math.floor(p.y / SG)
				senseGrid[k] = senseGrid[k] or {}
				table.insert(senseGrid[k], e)
			end
		end
	end
end
local senseBuf = {}
function R.SenseNear(pos, r)
	senseRefresh()
	local n = 0
	for _, e in ipairs(senseAll) do
		if IsValid(e) then
			local rr = r + e:BoundingRadius()
			if e:GetPos():DistToSqr(pos) < rr * rr then n = n + 1; senseBuf[n] = e end
		end
	end
	local x0, x1 = math.floor((pos.x - r - 250) / SG), math.floor((pos.x + r + 250) / SG)
	local y0, y1 = math.floor((pos.y - r - 250) / SG), math.floor((pos.y + r + 250) / SG)
	for x = x0, x1 do
		for y = y0, y1 do
			for _, e in ipairs(senseGrid[x .. ":" .. y] or {}) do
				if IsValid(e) then
					local rr = r + e:BoundingRadius()
					if e:GetPos():DistToSqr(pos) < rr * rr then n = n + 1; senseBuf[n] = e end
				end
			end
		end
	end
	for i = n + 1, #senseBuf do senseBuf[i] = nil end
	return senseBuf
end
-- how crowded a place is (bugs there and bugs on their way there)
function R.Crowd(pos) return R.crowd[ckey(pos)] or 0 end
-- how many bugs can eat a thing at the same time: one per ~35 units of its size round its hull (a barrel 2, a ship up
-- to 14) - more would only push each other
function R.BiteSlots(p) return R.IsBig(p) and math.Clamp(math.floor(p:BoundingRadius() / 35), 2, 14) or 2 end
function R.Eaters(prop) return R.eatCount[prop] or 0 end
-- a bug that picks something to eat claims its place at once (not only at the next count): many bugs choosing in the
-- same half second do not all pick the same ship and turn away again
function R.Claim(prop) if IsValid(prop) then R.eatCount[prop] = (R.eatCount[prop] or 0) + 1 end end
-- the middle of a swarm and how many it has
function R.Centre(owner) local s = R.centres[key(owner)] return s and s.p, s and s.n or 0 end
-- everything this swarm remembers as food (for the Queen's plans: where to send settlers)
function R.KnownList(owner)
	local out = {}
	for p, untilT in pairs(R.metal[key(owner)] or {}) do if IsValid(p) and untilT > CurTime() then out[#out + 1] = p end end
	return out
end
-- the map's own gate, DHD, pedestal: a start for a new swarm, not its meal - it went on eating the gate past a rocket
-- built for it on a roof. Once it is 2 or more and metal of the players' is anywhere near (6000), the map's things are
-- left alone: they go for that (further than they smell)
local playerMetal, playerMetalT = {}, 0
function R.PlayerMetal()
	if CurTime() < playerMetalT then return playerMetal end
	playerMetalT = CurTime() + 3
	playerMetal = {}
	for _, e in ipairs(ents.GetAll()) do
		if IsValid(e) and not e:CreatedByMap() and not e.GateSpawnerSpawned and not e.AGPReplicator and (e:GetClass():find("^prop_") or R.IsShip(e) or IsValid(e.AGPShip)) and R.Edible(e) then playerMetal[#playerMetal + 1] = e end
	end
	return playerMetal
end
-- the players' metal the swarm may eat, worked out once a second for every bug (the busy-world test: every bug went
-- through every prop and every ship part itself, up to twice a look - 670,000 checks in 15 s with 100 bugs, and the
-- game fell behind): where each thing is and how many may eat it at once; a bug only measures distances
local foodList, foodListT = {}, 0
local function sharedFood()
	if CurTime() < foodListT then return foodList end
	foodListT = CurTime() + 1
	foodList = {}
	for _, e in ipairs(R.PlayerMetal()) do
		if IsValid(e) and R.Edible(e) then foodList[#foodList + 1] = { e = e, p = e:GetPos(), slots = R.BiteSlots(e) } end
	end
	return foodList
end
-- (and the answer for a place is kept half a second: the bugs near one another ask the same)
local farMemo, farMemoT = {}, 0
function R.FarMetal(pos, r)
	local now = CurTime()
	if now > farMemoT then farMemo, farMemoT = {}, now + 0.5 end
	local k = math.floor(pos.x / 256) .. ":" .. math.floor(pos.y / 256) .. ":" .. math.floor(pos.z / 256) .. ":" .. (r or 6000)
	local m = farMemo[k]
	if m ~= nil then
		if m == false then return nil end
		if IsValid(m) and R.Eaters(m) < R.BiteSlots(m) then return m end
	end
	local best, bd
	local lim = (r or 6000) ^ 2
	for _, f in ipairs(sharedFood()) do
		local d = f.p:DistToSqr(pos)
		if d < lim and (not bd or d < bd) and IsValid(f.e) and R.Eaters(f.e) < f.slots then best, bd = f.e, d end
	end
	farMemo[k] = best or false
	return best
end
function R.MapFoodOk(owner, pos)
	if (R.Hive(owner).size or 0) < 2 then return true end
	return R.FarMetal(pos) == nil
end

function R.KnownMetal(owner, pos)
	local m = R.metal[key(owner)]
	if not m then return end
	local best, bd
	local mapOk
	for p, untilT in pairs(m) do
		if not IsValid(p) or untilT < CurTime() or not R.Edible(p) then m[p] = nil
		elseif R.MapItem(p) and mapOk == nil and not R.MapFoodOk(owner, pos) then mapOk = false
		elseif R.MapItem(p) and mapOk == false then
		elseif R.Eaters(p) < R.BiteSlots(p) then
			local d = p:GetPos():DistToSqr(pos)
			if d < 4000 * 4000 and (not bd or d < bd) then best, bd = p, d end
		end
	end
	return best
end

-- pack hunting: how many hunt this target; a bug that starts a fight calls the others near it
function R.Hunters(t) return R.huntCount[t] or 0 end
local BUSY_ROLES = { survivor = true, colonist = true, settler = true, saboteur = true, pursuer = true }
function R.Shout(bug, t)
	-- the Queen's plan is to hold back (too few of us): no call to arms (unless she herself is in danger)
	local h = R.Hive and R.Hive(bug.RepOwner)
	if h and h.mode == "hold" and not h.defend then return end
	for b in pairs(R.bugs) do
		if IsValid(b) and b ~= bug and b.RepOwner == bug.RepOwner and b.State ~= "attack" and not b.Eating
			and b.State ~= "ambush" and not BUSY_ROLES[b.Role or ""] and not b.InTower and not b.InBridge
			and b:GetPos():DistToSqr(bug:GetPos()) < 700 * 700 and R.MayAttack(b, t) then
			b.State, b.Target, b.NextLook = "attack", t, CurTime() + 2
		end
	end
end

-- adapting (series: the bugs became immune to the Asgard energy weapons, the anti-replicator gun had to be retuned).
-- What a swarm learns, all of it knows at once - its bugs are one network, however far apart (and swarms that meet share
-- it, AGPRepShareAdapt). Energy weapons (staff, zat, ship cannons, lasers): each hit teaches them a little, in the end
-- they do nothing at all. Bullets, explosions, blades: each bug shot apart, down to a quarter, never immune. The
-- anti-replicator gun: its frequency, after a few shots (R.ArgHit; the player holds R for a new one, sg_arg.lua).
R.adapt = R.adapt or {}
local ENERGY = bit.bor(DMG_ENERGYBEAM, DMG_PLASMA, DMG_SHOCK, DMG_BURN)
function R.IsEnergy(dtype) return bit.band(dtype or 0, ENERGY) ~= 0 end
function R.Resist(owner, dtype)
	local a = R.adapt[key(owner)]
	local n = a and a[dtype] or 0
	if R.IsEnergy(dtype) then
		local f = 0.75 ^ n
		return f < 0.05 and 0 or f
	end
	return math.max(0.25, 0.85 ^ n)
end
function R.Learn(owner, dtype, attacker, amount)
	if not dtype or dtype == 0 or dtype == DMG_DISSOLVE then return end
	local a = R.adapt[key(owner)] or {}
	R.adapt[key(owner)] = a
	local before = a[dtype] or 0
	a[dtype] = before + (amount or 1)
	if IsValid(attacker) and attacker:IsPlayer() then
		if before < 3 and a[dtype] >= 3 then
			AGP.Hint(attacker, "agp_rep_adapted", "The Replicators are adapting: this weapon hurts them less and less. Use something else - or the anti-replicator gun.")
		end
		if R.IsEnergy(dtype) and 0.75 ^ before >= 0.05 and R.Resist(owner, dtype) == 0 then
			AGP.Hint(attacker, "agp_rep_immune", "The Replicators are immune to this energy weapon now. Use bullets, explosives - or the anti-replicator gun.")
		end
	end
end
-- the anti-replicator gun works on one frequency: every shot that takes some of them apart teaches the swarm a bit of
-- it; after 4 to 9 shots on the same frequency it only makes them shudder
function R.ArgAdapted(owner, freq)
	local a = R.adapt[key(owner)]
	local f = a and a.arg and a.arg[freq]
	return f ~= nil and f.n >= f.need
end
function R.ArgHit(owner, freq, shot)
	local a = R.adapt[key(owner)] or {}
	R.adapt[key(owner)] = a
	a.arg = a.arg or {}
	local f = a.arg[freq] or { n = 0, need = math.random(4, 9), shots = {} }
	a.arg[freq] = f
	local id = IsValid(shot) and shot:EntIndex() .. ":" .. shot:GetCreationTime() or math.floor(CurTime())   -- one wave counts once
	if f.shots[id] then return end
	f.shots[id] = true
	f.n = f.n + 1
end
-- it shrugged off a shot: the shooter's gun shows it (red, "adapted"), and he is told once what to do
function R.ArgResisted(by)
	if not IsValid(by) or not by:IsPlayer() then return end
	local w = by:GetWeapon("sg_arg")
	if IsValid(w) then w:SetNWFloat("ARGResistT", CurTime()); w:SetNWBool("ARGStale", true) end
	AGP.Hint(by, "agp_rep_arg_adapted", "The Replicators have adapted to this frequency. Hold R to search for a new one.")
end
-- swarms that meet (bugs within 1500 units) share what they have learned
timer.Create("AGPRepShareAdapt", 5, 0, function()
	if not R.Awake() or not next(R.adapt) then return end
	local at = {}
	for b in pairs(R.bugs) do
		if IsValid(b) and not b.RepGone then
			local k = key(b.RepOwner)
			at[k] = at[k] or {}
			if #at[k] < 12 then table.insert(at[k], b:GetPos()) end
		end
	end
	local ks = {}
	for k in pairs(at) do ks[#ks + 1] = k end
	for i = 1, #ks do for j = i + 1, #ks do
		local met = false
		for _, p in ipairs(at[ks[i]]) do
			for _, q in ipairs(at[ks[j]]) do if p:DistToSqr(q) < 1500 * 1500 then met = true break end end
			if met then break end
		end
		if met then
			local a, b = R.adapt[ks[i]] or {}, R.adapt[ks[j]] or {}
			R.adapt[ks[i]], R.adapt[ks[j]] = a, b
			for _, pair in ipairs({ { a, b }, { b, a } }) do
				local from, to = pair[1], pair[2]
				for t, n in pairs(from) do if t ~= "arg" and (to[t] or 0) < n then to[t] = n end end
				if from.arg then
					to.arg = to.arg or {}
					for fq, f in pairs(from.arg) do
						local g = to.arg[fq] or { n = 0, need = f.need, shots = {} }
						to.arg[fq] = g
						g.n, g.need = math.max(g.n, f.n), math.min(g.need, f.need)
					end
				end
			end
		end
	end end
end)

-- a player holding the anti-replicator gun near this point
function R.ArgNear(pos, radius)
	for _, p in ipairs(player.GetAll()) do
		if p:Alive() and p:GetPos():DistToSqr(pos) < radius * radius then
			local w = p:GetActiveWeapon()
			if IsValid(w) and w:GetClass() == "sg_arg" then return p end
		end
	end
end

-- a swarm without a Queen builds one: from 4 bugs on, 3 of them walk together and become a Queen; the 4th stays with
-- her as her guard (it patrols around her, attacks what comes near and brings her metal)
function R.StartMerge(three, guard, at)
	R.merging = { bugs = three, guard = guard, at = at, owner = three[1].RepOwner, untilT = CurTime() + 15 }
	for _, b in ipairs(three) do b.State, b.Target, b.MoveTo, b.NextLook = "merge", nil, at + VectorRand() * 20, CurTime() + 20 end
end
local function mergeQueens()
	if R.Count("queens") >= R.cv.queens:GetInt() then return end
	local swarms = {}
	for b in pairs(R.bugs) do
		if IsValid(b) and not b.RepGone then
			local k = key(b.RepOwner)
			swarms[k] = swarms[k] or {}
			table.insert(swarms[k], b)
		end
	end
	for k, list in pairs(swarms) do
		local hasQueen = false
		for q in pairs(R.queens) do if IsValid(q) and key(q.RepOwner) == k then hasQueen = true end end
		if not hasQueen and #list >= 4 and not R.merging then
			local c = Vector()
			for _, b in ipairs(list) do c:Add(b:GetPos()) end
			c:Div(#list)
			table.sort(list, function(a, b) return a:GetPos():DistToSqr(c) < b:GetPos():DistToSqr(c) end)
			R.StartMerge({ list[1], list[2], list[3] }, list[4], list[1]:GetPos())
			return
		end
	end
end
local function mergeStep()
	local m = R.merging
	if not m then return end
	local here, alive = 0, 0
	for _, b in ipairs(m.bugs) do
		if IsValid(b) and b.State == "merge" then
			alive = alive + 1
			b.MoveTo = m.at
			if b:GetPos():DistToSqr(m.at) < 90 * 90 then here = here + 1 end
		end
	end
	if alive < #m.bugs then   -- one was shot or taken away: give up
		for _, b in ipairs(m.bugs) do if IsValid(b) and b.State == "merge" then b.State = "wander" end end
		R.merging = nil
		return
	end
	if here < #m.bugs and CurTime() < m.untilT then return end
	R.merging = nil
	for _, b in ipairs(m.bugs) do
		local fx = EffectData(); fx:SetOrigin(b:WorldSpaceCenter()); fx:SetMagnitude(2); fx:SetScale(1); fx:SetRadius(4)
		util.Effect("Sparks", fx, true, true)
		b.RepGone = true; b:Remove()
	end
	local q = ents.Create("agp_replicator_queen")
	if not IsValid(q) then return end
	q:SetPos(m.at + Vector(0, 0, 4)); q:SetAngles(Angle(0, math.random(0, 359), 0))
	q.RepOwner = IsValid(m.owner) and m.owner or nil
	q:Spawn(); q:Activate()
	if IsValid(m.owner) and q.CPPISetOwner then q:CPPISetOwner(m.owner) end
	if IsValid(m.guard) and not m.guard.RepGone then m.guard.RepGuard = q end
end
timer.Create("AGPRepQueens", 1, 0, function()
	if not R.Awake() then return end
	mergeStep()
	mergeQueens()
end)

-- the swarm's memory: who hurt the Queen (all bugs of that owner go for him for a while)
R.enemy = R.enemy or {}
function R.Alarm(owner, attacker)
	if not IsValid(attacker) or R.IsReplicator(attacker) then return end
	R.Threat(owner, attacker)
	R.enemy[owner or game.GetWorld()] = { ent = attacker, untilT = CurTime() + 30 }
end
function R.Enemy(owner)
	local e = R.enemy[owner or game.GetWorld()]
	if e and IsValid(e.ent) and e.untilT > CurTime() and (not e.ent:IsPlayer() or e.ent:Alive()) then return e.ent end
end

-- threats: who provoked this swarm (the series: they leave people alone until threatened). The swarm is one hive mind
-- (all of it knows); it does not forget while it lives - only in this game, and when the whole swarm is gone it is gone.
R.threats = R.threats or {}
-- who provoked the swarm stays its enemy for as long as the swarm lives - and so does his group: the players of his team
-- (when the team is a real group, not simply everyone on the server) and his prop-protection friends
local function group(t)
	local out = {}
	if not t:IsPlayer() then return out end
	local all = player.GetAll()
	local tm = t:Team()
	if tm ~= TEAM_UNASSIGNED and tm ~= TEAM_CONNECTING and tm ~= TEAM_SPECTATOR then
		local mates = team.GetPlayers(tm)
		if #mates > 1 and #mates < #all * 0.6 then for _, m in ipairs(mates) do out[#out + 1] = m end end
	end
	if t.CPPIGetFriends then
		local ok, fr = pcall(t.CPPIGetFriends, t)
		if ok and istable(fr) then for _, m in ipairs(fr) do if IsValid(m) and m:IsPlayer() then out[#out + 1] = m end end end
	end
	return out
end
function R.Threat(owner, t)
	if not IsValid(t) or not (t:IsPlayer() or t:IsNPC()) then return end
	local k = IsValid(owner) and owner or game.GetWorld()
	R.threats[k] = R.threats[k] or {}
	R.threats[k][t] = math.huge
	for _, m in ipairs(group(t)) do if m ~= owner then R.threats[k][m] = math.huge end end
end
local function threatens(rep, t)
	local k = IsValid(rep.RepOwner) and rep.RepOwner or game.GetWorld()
	if R.threats[k] and R.threats[k][t] then return true end
	for q in pairs(R.queens) do   -- too close to the Queen: the nest is defended
		if IsValid(q) and q.RepOwner == rep.RepOwner and q:GetPos():DistToSqr(t:GetPos()) < 260 * 260 then return true end
	end
	return false
end

-- provoking them: grabbing one with the physics gun, or shooting right next to them (not only hitting) - the whole swarm
-- remembers who did it (series: they leave people alone until threatened)
hook.Add("PhysgunPickup", "AGPRepProvoke", function(ply, e)
	if R.IsReplicator(e) then R.Threat(e.RepOwner, ply) end
end)
hook.Add("EntityFireBullets", "AGPRepProvoke", function(shooter, data)
	if not (IsValid(shooter) and (shooter:IsPlayer() or shooter:IsNPC())) or (R.Count("bugs") == 0 and R.Count("queens") == 0) then return end
	-- (a shot aboard a flying StarCore ship: the others on it are put right before anything asks where they are)
	if StarCore and StarCore.ShotAboard then StarCore.ShotAboard(shooter) end
	local range = (data.Distance and data.Distance > 0) and data.Distance or 56756
	local tr = util.TraceLine({ start = data.Src, endpos = data.Src + data.Dir * range, filter = shooter, mask = MASK_SHOT })
	for _, e in ipairs(ents.FindInSphere(tr.HitPos, 90)) do
		if R.IsReplicator(e) and not e.RepDead then R.Threat(e.RepOwner, shooter) break end
	end
end)

-- may this replicator attack that target?
function R.MayAttack(rep, t)
	local mode = R.cv.attack:GetInt()
	if mode == 0 or not IsValid(t) then return false end
	if t:IsPlayer() then
		if not t:Alive() or t:GetMoveType() == MOVETYPE_NOCLIP then return false end
	elseif not (t:IsNPC() and t:Health() > 0) then
		return false
	end
	if mode == 1 then return threatens(rep, t) end
	if mode == 2 and t == rep.RepOwner then return false end
	return true
end

-- may it eat this? Anything made of metal (its physics surface), with mode 1 only loose props. Ships are metal (like in the
-- series they eat ships, and what is welded or parented to them). Never: players, NPCs, weapons, other Replicators,
-- things the map made, something held with the physgun.
local NEVER = { player = true, predicted_viewmodel = true, gmod_hands = true, physgun_beam = true }
function R.IsShip(p)
	local cls = p:GetClass()
	return p.IsSGVehicle or cls:find("^sg_vehicle_") ~= nil or cls == "agp_hatak" or cls == "puddle_jumper"
end
-- the StarCore ship a part belongs to (a SpaceGrid hull, a welded prop ship), or nil: its hull is one pool for the whole
-- ship, kept by the core - bites go there, and a part of it is never simply removed when its metal is used up
function R.ShipCore(p)
	local pc = StarCore and StarCore.PartCore
	local c = pc and IsValid(p) and pc[p]
	return IsValid(c) and c or nil
end
-- map items (the gate spawner's gates and DHDs, the map's own physics props) respawn: they may be eaten ONCE per place;
-- what comes back there is left alone for the rest of the game. Players' props: no limit. Other map parts (doors ...): never.
R.eatenOnce = R.eatenOnce or {}
function R.MapItem(p)
	return p.GateSpawnerSpawned or (p:CreatedByMap() and p:GetClass():find("^prop_physics") ~= nil)
end
local function slot(p)
	if p.GateSpawnerID then return "gs:" .. p:GetClass() .. ":" .. tostring(p.GateSpawnerID) end
	local o = p.RepSpawnPos or p:GetPos()
	return "map:" .. p:GetClass() .. ":" .. math.floor(o.x / 96) .. ":" .. math.floor(o.y / 96) .. ":" .. math.floor(o.z / 96)
end
function R.AteMapItem(p) if IsValid(p) and R.MapItem(p) then R.eatenOnce[slot(p)] = true end end
hook.Add("OnEntityCreated", "AGPRepMapItemPos", function(e)
	timer.Simple(0, function() if IsValid(e) and R.MapItem(e) and not e.RepSpawnPos then e.RepSpawnPos = e:GetPos() end end)
end)
-- (asked for the same things again and again by every bug near them: the answer is kept for half a second)
local edibleMemo = setmetatable({}, { __mode = "k" })
local edibleRaw
function R.Edible(p)
	if not IsValid(p) then return false end
	local m = edibleMemo[p]
	local now = CurTime()
	if m and now < m[1] then return m[2] end
	local v = edibleRaw(p)
	edibleMemo[p] = { now + 0.5, v }
	return v
end
edibleRaw = function(p)
	local mode = R.cv.eat:GetInt()
	if mode == 0 or not IsValid(p) or p.RepEaten or p.AGPReplicator then return false end
	local cls = p:GetClass()
	if NEVER[cls] or p:IsPlayer() or p:IsNPC() or p:IsWeapon() or p:IsPlayerHolding() then return false end
	if p.IsStargate and R.GateInbound and R.GateInbound(p) then return false end   -- (the receiving gate's horizon kills; not food while it is open)
	if R.MapItem(p) then
		if R.eatenOnce[slot(p)] then return false end
	elseif p:CreatedByMap() then
		return false
	end
	if mode == 1 and cls ~= "prop_physics" then return false end
	local ph = p:GetPhysicsObject()
	if mode == 2 and (R.IsShip(p) or IsValid(p.AGPShip)) then return true end   -- a ship and every part of it (the Ha'tak's inside too)
	if mode == 2 and R.LurePower and (R.LurePower(p) or 0) >= 3 and not R.IsShield(p) then return true end   -- strong power sources (a ZPM, a generator), whatever they are made of
	if not IsValid(ph) then return false end
	if not string.find(string.lower(ph:GetMaterial() or ""), "metal", 1, true) then return false end
	if mode == 1 and (not ph:IsMotionEnabled() or constraint.HasConstraints(p) or IsValid(p:GetParent())) then return false end
	return true
end
-- shields: Replicators are drawn to energy - they press against a shield and drain it (every kind of AGP shield)
local SHIELDS = { shield = true, shield_core_buble = true, ship_shield = true, tokra_shield = true }
function R.IsShield(e) return SHIELDS[e:GetClass()] and e.Hit and not e:GetNWBool("depleted") and e.Enabled ~= false and not e.GettingDeleted end
function R.ShieldRadius(e)
	return (isnumber(e.Size) and e.Size) or (isvector(e.Size) and math.max(e.Size.x, e.Size.y, e.Size.z) * 0.5) or e:BoundingRadius() * 0.75
end
-- inside a shield that is up
function R.Shielded(e)
	local sh = R.ShieldNear(e:GetPos(), 1)
	return IsValid(sh) and e:GetPos():Distance(sh:GetPos()) < R.ShieldRadius(sh)
end
-- the shields on the map, listed once a second (not searched again by every bug)
local shieldList, shieldT = {}, 0
local function shields()
	if CurTime() < shieldT then return shieldList end
	shieldT = CurTime() + 1
	shieldList = {}
	for cls in pairs(SHIELDS) do for _, e in ipairs(ents.FindByClass(cls)) do shieldList[#shieldList + 1] = e end end
	return shieldList
end
function R.ShieldNear(pos, radius)
	local best, bd
	do
		for _, e in ipairs(shields()) do
			if IsValid(e) and e.Hit and not e:GetNWBool("depleted") and e.Enabled ~= false and not e.GettingDeleted then
				-- distance to the bubble's surface (its middle is far away: a shield is big)
				local r = (isnumber(e.Size) and e.Size) or (isvector(e.Size) and math.max(e.Size.x, e.Size.y, e.Size.z) * 0.5) or e:BoundingRadius() * 0.75
				local d = math.max(0, e:GetPos():Distance(pos) - r)
				if d < radius and (not bd or d < bd) then best, bd = e, d end
			end
		end
	end
	return best
end

-- the dial string from one gate to another (the gate groups decide the extra symbols, like the DHD does)
function R.DialString(src, dst)
	local addr = dst:GetGateAddress()
	local sg, dg = src.GetGateGroup and src:GetGateGroup() or "", dst.GetGateGroup and dst:GetGateGroup() or ""
	if dg ~= "" and sg ~= dg and not (dst.GetLocale and dst:GetLocale()) then
		if #dg == 3 then return addr .. dg end
		if #sg == 3 then return addr .. dg .. "#" end
		return addr .. dg:sub(1, 1)
	end
	return addr
end

-- counters for watching the swarm (tests, the observation scenario)
R.stats = R.stats or {}
function R.Stat(name, n) R.stats[name] = (R.stats[name] or 0) + (n or 1) end

-- debug log (agp_rep_debug 1): what the bugs decide, into the console
local cvDebug = CreateConVar("agp_rep_debug", "0", FCVAR_ARCHIVE, "Replicators: print what they decide into the console (for watching them)")
function R.Dbg(e, ...)
	if not cvDebug:GetBool() then return end
	print("AGP_RESULT", "INFO", "repdbg", IsValid(e) and e:EntIndex() or "-", ...)
end

-- a fitting of a ship (the Ha'tak's consoles, crystals, doors, braziers, props inside): eaten whole and gone like any
-- prop, every one also costs the ship hull. Not the ship's shell, its portals, force fields or seats.
local NOT_FITTING = { agp_hatak_interior = true, agp_portal = true, agp_force_field = true, prop_vehicle_prisoner_pod = true, hatak_pulse = true, gate_nuke = true }
function R.ShipFitting(p)
	return IsValid(p.AGPShip) and p.AGPShip ~= p and not R.IsShip(p) and not NOT_FITTING[p:GetClass()] and not p.AGPOuterTwin
		and p:BoundingRadius() < 150
end
-- big things (ships, big builds) are eaten piece by piece by several bugs
-- (the answer kept 2 s per thing: asked for every prop by every bug's look - 670,000 times in 15 s in a busy world)
local bigMemo = setmetatable({}, { __mode = "k" })
local function isBigRaw(p)
	if R.ShipFitting(p) then return false end
	-- every part of a StarCore ship, its core too: the bites go to the ship's one hull, the part stays. (The author's play
	-- test: a SpaceGrid ship's hidden core - small, power that draws them - was eaten whole and removed: the HUD went out,
	-- the ship fell, a new core started at 100 %; small parts eaten whole cost the hull nothing - "stopped at 99 %")
	if R.ShipCore(p) then return true end
	local ph = p:GetPhysicsObject()
	return R.IsShip(p) or IsValid(p.AGPShip) or p:BoundingRadius() > 150 or (IsValid(ph) and ph:GetMass() > 1500)
end
function R.IsBig(p)
	local m = bigMemo[p]
	local now = CurTime()
	if m and now < m[1] then return m[2] end
	local v = isBigRaw(p)
	bigMemo[p] = { now + 2, v }
	return v
end


-- assembly: every second the loose blocks are checked; 12 close together (resting long enough) crawl into one point
-- and become a bug. Lonely blocks hop towards the nearest group (that is how scattered blocks find each other).
local function assemble(group, owner)
	local c = Vector()
	for _, b in ipairs(group) do c:Add(b:GetPos()) end
	c:Div(#group)
	-- the floor they lie on: the map, a prop, a ship's deck. (The floor was looked for in the map only - through the
	-- deck to the ground under the ship - and the frozen blocks were moved in the world while the ship flew on, so they
	-- went out through its walls and the new bug was made behind it. Now all of it is worked out on what they lie on,
	-- and moves with it.)
	--
	local tr = util.TraceLine({ start = c + Vector(0, 0, 40), endpos = c - Vector(0, 0, 200), mask = MASK_SOLID,
		filter = function(e) return not e.AGPReplicator and not e:IsPlayer() and not e:IsNPC() and not e.SpaceGridKeel end })
	local on = (tr.Hit and IsValid(tr.Entity) and not tr.Entity:IsWorld()) and tr.Entity or nil
	local function toW(lp) if IsValid(on) then return on:LocalToWorld(lp) end return lp end
	local function toL(wp) if IsValid(on) then return on:WorldToLocal(wp) end return wp end
	local function angW(la) if IsValid(on) then return on:LocalToWorldAngles(la) end return la end
	local function angL(wa) if IsValid(on) then return on:WorldToLocalAngles(wa) end return wa end
	local function dirL(wv) if IsValid(on) then return on:WorldToLocal(on:GetPos() + wv) end return wv end   -- (a world offset, in its frame)
	local groundL = toL(tr.Hit and tr.HitPos or c)
	local upL = dirL(Vector(0, 0, 1))
	local hadOn = on ~= nil
	for i, b in ipairs(group) do
		b.RepClaimed = true
		b:SetNotSolid(true)
		local ph = b:GetPhysicsObject()
		if IsValid(ph) then ph:EnableMotion(false) end
		b.RepFrom, b.RepFromAng = toL(b:GetPos()), angL(b:GetAngles())
		b.RepTo = groundL + dirL(Vector(math.Rand(-6, 6), math.Rand(-9, 9), 4 + (i % 3) * 2))
		b:SetNWEntity("RepLink", i > 1 and group[1] or group[2])   -- electric arcs while they are drawn together
	end
	local t0, dur = CurTime(), 1.6
	local id = "AGPRepAssemble" .. group[1]:EntIndex()
	timer.Create(id, 0.03, 0, function()
		local f = math.min(1, (CurTime() - t0) / dur)
		local e = f * f * (3 - 2 * f)
		local alive = 0
		for _, b in ipairs(group) do
			if IsValid(b) then
				alive = alive + 1
				-- drawn together like by a magnet: a smooth glide, lifting a little off the ground
				local lift = math.sin(e * math.pi) * 5
				b:SetPos(toW(LerpVector(e, b.RepFrom, b.RepTo) + upL * lift))
				b:SetAngles(angW(LerpAngle(e, b.RepFromAng, Angle(0, b.RepFromAng.y, 0))))
			end
		end
		-- blocks were taken away meanwhile, or what they lay on is gone: give up, the rest falls down
		if alive < #group * 0.75 or (hadOn and not IsValid(on)) then
			timer.Remove(id)
			for _, b in ipairs(group) do
				if IsValid(b) then
					b.RepClaimed = nil; b:SetNotSolid(false)
					local ph = b:GetPhysicsObject(); if IsValid(ph) then ph:EnableMotion(true); ph:Wake() end
				end
			end
			return
		end
		if f < 1 then return end
		timer.Remove(id)
		for _, b in ipairs(group) do if IsValid(b) then b:Remove() end end
		if R.Count("bugs") >= R.cv.bugs:GetInt() then return end
		local bug = ents.Create("agp_replicator")
		if not IsValid(bug) then return end
		local ground = toW(groundL)
		bug:SetPos(ground + Vector(0, 0, 2))
		bug:SetAngles(Angle(0, math.random(0, 359), 0))
		bug.RepOwner = owner
		bug.RepParentMind = group[1].RepMind
		bug.FreedT = group[1].RepFreedT   -- (it just broke apart to get free: not again for 15 s, agp_replicator.lua)
		bug.RepFormerIdx = group[1].RepFormerIdx   -- (which bug it was before: a watch following that one follows this one)
		bug:Spawn(); bug:Activate()
		if IsValid(owner) and bug.CPPISetOwner then bug:CPPISetOwner(owner) end

		local fx = EffectData(); fx:SetOrigin(ground + Vector(0, 0, 6)); fx:SetMagnitude(2); fx:SetScale(1); fx:SetRadius(4)
		util.Effect("Sparks", fx, true, true)
	end)
	sound.Play("agp_replicator/rep_assemble.wav", toW(groundL), 72, math.random(95, 108))
end

-- playing dead (blocks of a bug shot apart, agp_replicator.lua), or a stuck bug that waits to fall apart (ENT:BreakFree):
-- is a player near (range, default 700) looking at this spot?
function R.Watched(pos, range)
	range = range or 700
	for _, p in ipairs(player.GetAll()) do
		if p:Alive() and p:GetPos():DistToSqr(pos) < range * range then
			local to = pos - p:EyePos()
			if p:GetAimVector():Dot(to:GetNormalized()) > 0.6 and not util.TraceLine({ start = p:EyePos(), endpos = pos + Vector(0, 0, 4), mask = MASK_SOLID_BRUSHONLY }).Hit then return true end
		end
	end
	return false
end
timer.Create("AGPRepSwarm", 1, 0, function()
	if not R.Awake() then return end
	local now = CurTime()
	local free = {}
	local seen = {}
	for b in pairs(R.blocks) do
		if IsValid(b) and b.RepFeign and (b.RepRest or 0) < now then
			if now > b.RepFeign then b.RepFeign = nil
			else
				local k = math.floor(b:GetPos().x / 200) .. ":" .. math.floor(b:GetPos().y / 200)
				if seen[k] == nil then seen[k] = R.Watched(b:GetPos()) end
				if seen[k] then b.RepRest = now + 1.5 else b.RepFeign = nil end
			end
		end
	end
	for b in pairs(R.blocks) do
		if not IsValid(b) then R.blocks[b] = nil
		elseif not b.RepClaimed and not b.RepDead and (b.RepRest or 0) < now then free[#free + 1] = b end
	end
	local need = R.BLOCKS_PER_BUG
	local room = R.Count("bugs") < R.cv.bugs:GetInt()   -- (also while the game is behind: 12 blocks becoming 1 bug is no growth)
	-- rebuilt in time (at most 20 s, sometimes 15): the blocks of a bug shot apart that have not found each other by
	-- then are drawn together where most of them lie (one that flew far off stays behind)
	local due, forced = {}, false
	for b in pairs(R.blocks) do   -- (also those still playing dead: the time is up)
		local g = IsValid(b) and not b.RepClaimed and not b.RepDead and b.RepGroup
		if g and (b.RepRebuildBy or 1e18) - 1.5 < now then due[g] = due[g] or {}; table.insert(due[g], b) end
	end
	for _, list in pairs(due) do
		for _, b in ipairs(list) do b.RepGroup = nil end
		if room and #list >= need then
			local c = Vector()
			for _, b in ipairs(list) do c:Add(b:GetPos()) end
			c:Div(#list)
			table.sort(list, function(x, y) return x:GetPos():DistToSqr(c) < y:GetPos():DistToSqr(c) end)
			local grp = {}
			for i = 1, need do if list[i]:GetPos():DistToSqr(c) < 450 * 450 then grp[#grp + 1] = list[i] end end
			if #grp == need then
				assemble(grp, grp[1].RepOwner)
				forced = true
				R.Stat("rebuilt in time")
				room = R.Count("bugs") + 1 < R.cv.bugs:GetInt()
			end
		end
	end
	if #free == 0 and not next(due) then return end
	if forced then
		local rest = {}
		for _, b in ipairs(free) do if not b.RepClaimed then rest[#rest + 1] = b end end
		free = rest
		if #free == 0 then return end
	end
	-- neighbours of every free block, found through a grid (after a Destiny shot at a heap of 40 bugs: 480 free blocks
	-- compared with each other, several times each, made this timer take a good part of a second; the cost grew with
	-- the square of the blocks). Close ones are counted in cells of 110 (3 x 3 x 3 cells), only up to the 12 a bug
	-- needs; the pull towards the others is worked out from sums per cell of 350.
	local CELL, COARSE = 110, 350
	local fine, coarse = {}, {}
	local pos, nearN = {}, {}
	local function ck(x, y, z) return (x + 2048) * 16777216 + (y + 2048) * 4096 + (z + 2048) end
	for i, b in ipairs(free) do
		local p = b:GetPos()
		pos[i] = p
		local k = ck(math.floor(p.x / CELL), math.floor(p.y / CELL), math.floor(p.z / CELL))
		local c = fine[k]
		if not c then c = {}; fine[k] = c end
		c[#c + 1] = i
	end
	local function around(i, fn)   -- fn(j) for every other free block within 110 of block i; false from fn stops
		local p = pos[i]
		local x, y, z = math.floor(p.x / CELL), math.floor(p.y / CELL), math.floor(p.z / CELL)
		for dx = -1, 1 do
			for dy = -1, 1 do
				for dz = -1, 1 do
					local c = fine[ck(x + dx, y + dy, z + dz)]
					if c then
						for n = 1, #c do
							local j = c[n]
							if j ~= i and p:DistToSqr(pos[j]) < 110 * 110 and fn(j) == false then return end
						end
					end
				end
			end
		end
	end
	for i = 1, #free do
		local n = 1
		around(i, function() n = n + 1 if n >= need then return false end end)
		nearN[i] = n
		free[i].RepNear, free[i].RepNearT = n, now   -- (a block's own think does not search for neighbours again: agp_replicator_block.lua)
	end
	local anyGlide = false
	for i = 1, #free do
		if nearN[i] < need then anyGlide = true break end
	end
	if anyGlide then
		for i = 1, #free do
			local p = pos[i]
			local k = ck(math.floor(p.x / COARSE), math.floor(p.y / COARSE), 0)
			local c = coarse[k]
			if not c then c = { w = 0, x = 0, y = 0, z = 0, r1 = i }; coarse[k] = c end
			c.w, c.x, c.y, c.z = c.w + nearN[i], c.x + p.x * nearN[i], c.y + p.y * nearN[i], c.z + p.z * nearN[i]
			if not c.r2 and c.r1 ~= i then c.r2 = i end
		end
	end
	local used, fed, fedNear = {}, 0, {}
	for i, b in ipairs(free) do
		if not used[b] then
			-- (while the game is behind - the lag guard - loose blocks make no new bug: a bug that fell apart left its metal
			-- as extra blocks, and two bugs came back for one - 204 instead of 106 in a busy-world test; its own group is
			-- still rebuilt in time, above)
			if room and not R.lag.behind and nearN[i] >= need then
				local group = { free[i] }
				around(i, function(j)
					if #group >= need then return false end
					if not used[free[j]] then group[#group + 1] = free[j] end
				end)
				if #group == need then
					for _, g in ipairs(group) do used[g] = true end
					assemble(group, b.RepOwner)
					room = R.Count("bugs") + 1 < R.cv.bugs:GetInt()
				end
			elseif nearN[i] < need then
				-- glide: towards the biggest group within reach, smoothly like drawn by a magnet (the block's Think moves
				-- it), small electric arcs between them - that is how scattered blocks find each other
				-- towards the middle of all free blocks within reach, weighted by how many are already together there
				local p = pos[i]
				local cx, cy = math.floor(p.x / COARSE), math.floor(p.y / COARSE)
				local sx, sy, sz, w, best, bd = 0, 0, 0, 0, nil, nil
				for dx = -2, 2 do
					for dy = -2, 2 do
						local c = coarse[ck(cx + dx, cy + dy, 0)]
						if c then
							sx, sy, sz, w = sx + c.x, sy + c.y, sz + c.z, w + c.w
							for _, r in ipairs({ c.r1, c.r2 or c.r1 }) do
								if r ~= i then
									local d = p:DistToSqr(pos[r])
									if d < 700 * 700 and (not bd or d < bd) then best, bd = r, d end
								end
							end
						end
					end
				end
				w = w - nearN[i]   -- (not itself)
				local c = (best and w > 0) and Vector((sx - p.x * nearN[i]) / w, (sy - p.y * nearN[i]) / w, (sz - p.z * nearN[i]) / w) or nil
				-- (not across an incoming gate's horizon: blocks are Replicators too)
				if c and R.SegDead and #R.deadGates > 0 and R.SegDead(p, c, 10) then c = nil end
				if c then
					b.RepGlideTo, b.RepGlideUntil = c, now + 1.6
					-- (on a moving thing - a flying ship's deck: the point is kept on it, it moves with it; the block's Think)
					local gt = util.TraceLine({ start = p + Vector(0, 0, 4), endpos = p - Vector(0, 0, 40), mask = MASK_SOLID,
						filter = function(e) return not e.AGPReplicator and not e:IsPlayer() and not e:IsNPC() and not e.SpaceGridKeel end })
					local on = gt.Hit and IsValid(gt.Entity) and not gt.Entity:IsWorld() and gt.Entity or nil
					b.RepGlideOn, b.RepGlideL = on, on and on:WorldToLocal(c) or nil
					b:SetNWEntity("RepLink", free[best])
				else
					b.RepGlideTo = nil
					b:SetNWEntity("RepLink", NULL)
				end
				-- a group (2 or more) with metal right next to it eats it: one more block at a time, until there are 12
				if nearN[i] >= 2 and fed < 5 and R.RoomForBlocks(1) and not fedNear[i] then
					for _, e in ipairs(ents.FindInSphere(pos[i], 220)) do
						if R.Edible(e) then
							local fph = e:GetPhysicsObject()
							e.RepLeft = e.RepLeft or math.Clamp(math.floor((IsValid(fph) and fph:GetMass() or 40) / 20), 1, 3000)
							e.RepLeft = e.RepLeft - 1
							local at = e:NearestPoint(pos[i])
							local nb = R.SpawnBlock(at + Vector(0, 0, 6), (pos[i] - at):GetNormalized() * 60, b.RepOwner, 0.5)
							if nb then nb.RepMind = b.RepMind; nb:SetNWEntity("RepLink", b) end
							local fx = EffectData(); fx:SetOrigin(at); fx:SetNormal(VectorRand()); fx:SetMagnitude(1); fx:SetScale(1); fx:SetRadius(2)
							util.Effect("MetalSpark", fx, true, true)
							if e.RepLeft <= 0 and not e.AGPShip and not R.IsShip(e) and not R.ShipCore(e) then R.AteMapItem(e); e:Remove() end
							fed = fed + 1
							for j = 1, #free do if pos[i]:DistToSqr(pos[j]) < 110 * 110 then fedNear[j] = true end end
							break
						end
					end
				end
			end
		end
	end
end)

-- settings page (Stargate > Config > Replicators): admins change the server settings
util.AddNetworkString("agp_rep_set")
local LIMITS = { agp_rep_enabled = { 0, 1 }, agp_rep_max_bugs = { 0, 1e6 }, agp_rep_max_blocks = { 12, 1e6 }, agp_rep_max_queens = { 0, 1e6 },
	agp_rep_attack = { 0, 3 }, agp_rep_eat = { 0, 2 }, agp_rep_rebuild = { 0, 1 }, agp_rep_survive = { 0, 1 }, agp_rep_lone_grow = { 0, 1 }, agp_rep_gates = { 0, 1 }, agp_rep_gate_swarm = { 2, 1e6 },
	agp_rep_lagguard = { 0, 1 }, agp_rep_lagguard_fps = { 0, 1000 }, agp_rep_navscan = { 0, 1 } }
net.Receive("agp_rep_set", function(_, p)
	local name, value = net.ReadString(), net.ReadInt(32)
	local lim = LIMITS[name]
	if lim and IsValid(p) and (p:IsAdmin() or game.SinglePlayer()) then RunConsoleCommand(name, tostring(math.Clamp(value, lim[1], lim[2]))) end
end)

-- a swarm that is completely gone takes its memory of who threatened it with it
timer.Create("AGPRepForget", 10, 0, function()
	for k in pairs(R.threats) do
		local alive = false
		for _, kind in ipairs({ "bugs", "queens", "blocks" }) do
			for e in pairs(R[kind]) do
				if IsValid(e) and not e.RepDead and (IsValid(e.RepOwner) and e.RepOwner or game.GetWorld()) == k then alive = true break end
			end
			if alive then break end
		end
		if not alive then R.threats[k] = nil end
	end
end)

-- remove every Replicator (admins; also in the settings page)
concommand.Add("agp_rep_clear", function(p)
	if IsValid(p) and not (p:IsAdmin() or game.SinglePlayer()) then return end
	R.burstQ = {}   -- (blocks still to be made of a burst: not after the clear)
	for _, kind in ipairs({ "bugs", "queens", "blocks" }) do
		for e in pairs(R[kind]) do if IsValid(e) then e.RepGone = true; e:Remove() end end
	end
end)

-- the swarm's map memory and the hive (the Queen's command)
include("agp_replicators/sv_map.lua")
include("agp_replicators/sv_hive.lua")
include("agp_replicators/sv_tactics.lua")
include("agp_replicators/sv_brain.lua")
include("agp_replicators/sv_pursuit.lua")
include("agp_replicators/sv_jump.lua")
include("agp_replicators/sv_shape.lua")
include("agp_replicators/sv_surfnav.lua")
include("agp_replicators/sv_surfgraph.lua")
include("agp_replicators/sv_nav.lua")
include("agp_replicators/sv_walk.lua")
include("agp_replicators/sv_mover.lua")   -- (one mover; agp_rep_onemover, on by default)
include("agp_replicators/sv_ceiling.lua")   -- (their own walk under ceilings; agp_rep_seamwalk, off by default)
include("agp_replicators/sv_field.lua")   -- (the felt map: the normal walk; agp_rep_legwalk 1 = legs only)
include("agp_replicators/sv_fieldprops.lua")   -- (the felt map's live layer: the players' frozen things; agp_rep_propfelt)
include("agp_replicators/sv_feltnav.lua")   -- (the way across the map on the felt map; sv_nav.lua asks it first)
