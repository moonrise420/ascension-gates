--[[
	Replicators: through Stargates and rings (server).
	- Prey that escapes through a Stargate or by ring is followed: the hive saw where it went (series: one mind). The bugs
	  that hunted it run through the gate while it is open; when it has closed, one of them dials it again at the DHD (or
	  the gate) to the gate the prey came out of. Rings: they gather on the platform and send themselves to the ring the
	  prey arrived at. On the other side they go for it at once.
	- A big swarm also spreads by ring (besides its colonists by Stargate): a few bugs ring over to another platform and
	  start a new home there.
	- After any jump through a gate or by ring a bug forgets its old route, and the map memory does not link the two places.
]]
local R = AGP.Rep
R.escapes = R.escapes or {}   -- [prey] = { via = "gate" / "rings", src, dst, at, untilT, prey }

local FOLLOW_TIME = 120   -- how long the hive keeps after prey that escaped
local MAX_PURSUERS = 10

local function preyOf(e)
	if not IsValid(e) then return {} end
	local out = {}
	if e:IsPlayer() or e:IsNPC() then out[1] = e end
	-- a ship or vehicle carrying hunted players: the players escaped with it
	for _, p in ipairs(player.GetAll()) do if R.CraftOf and R.CraftOf(p) == e then out[#out + 1] = p end end
	return out
end

-- (who hunted whom in the last few seconds: a bug mid-pounce, or one that just lost sight of it, has no target that
-- moment - the prey stepped through a gate right then and the hive did not see it escape)
R.recentHunt = R.recentHunt or {}   -- [prey] = { [bug] = time }
timer.Create("AGPRepRecentHunt", 0.5, 0, function()
	local now = CurTime()
	for b in pairs(R.bugs or {}) do
		local t = IsValid(b) and b.Target
		if IsValid(t) and (t:IsPlayer() or t:IsNPC()) then R.recentHunt[t] = R.recentHunt[t] or {} R.recentHunt[t][b] = now end
	end
	for t, l in pairs(R.recentHunt) do if not IsValid(t) then R.recentHunt[t] = nil end end
end)
local function huntersOf(t)
	local out, seen = {}, {}
	for b in pairs(R.bugs) do if IsValid(b) and not b.RepGone and b.Target == t then out[#out + 1] = b seen[b] = true end end
	for b, at in pairs(R.recentHunt[t] or {}) do if not seen[b] and IsValid(b) and not b.RepGone and CurTime() - at < 6 then out[#out + 1] = b end end
	return out
end

local function hunted(t)
	if R.Hunters(t) > 0 then return true end
	for b in pairs(R.bugs) do if IsValid(b) and b.Target == t then return true end end
	for b, at in pairs(R.recentHunt[t] or {}) do if IsValid(b) and CurTime() - at < 6 then return true end end
	return false
end

-- an open gate one may step into: open, and its vortex (the kawoosh - it destroys what it touches) has settled. The
-- gate calls itself open while the vortex still forms.
R.gateOpenT = R.gateOpenT or setmetatable({}, { __mode = "k" })
local gateList, gateListT = {}, 0
timer.Create("AGPRepGateOpen", 0.25, 0, function()   -- when each gate opened (its vortex lasts about two seconds)
	local now = CurTime()
	if now > gateListT then
		gateListT = now + 3
		gateList = {}
		for _, g in ipairs(ents.GetAll()) do if g.IsStargate then gateList[#gateList + 1] = g end end
	end
	local dead = {}
	for _, g in ipairs(gateList) do
		if IsValid(g) then
			local eh = g.EventHorizon
			if g.IsOpen and IsValid(eh) then R.gateOpenT[g] = R.gateOpenT[g] or now else R.gateOpenT[g] = nil end
			if IsValid(eh) and R.GateInbound(g) then dead[#dead + 1] = R.DeadEntry(g)
			elseif IsValid(eh) and g.IsOpen then
				-- (an outgoing gate kills from behind: in through its back is "entering from the wrong side" -
				-- event_horizon/init.lua. A pursuer that came round the re-dialled gate walked into its back and was
				-- gone, reppursuit 2026-11-14 full check. Only its back half is kept clear, the front is the way in.)
				local e = R.DeadEntry(g)
				if e then e.back = true dead[#dead + 1] = e end
			end
		end
	end
	R.deadGates = dead
end)
function R.GateStable(g)
	local eh = IsValid(g) and g.EventHorizon
	if not (g.IsOpen and IsValid(eh) and eh.IsOpen and eh:IsOpen()) then return false end
	local t = R.gateOpenT[g]
	return t ~= nil and CurTime() - t > 3
end

-- (owner 2026-11-14: "replicators should know if a wormhole is incoming or outgoing so they only would go threw an
-- outgoing wormhole only"): the horizon of the RECEIVING gate has no Target and kills everything that touches it
-- (event_horizon/init.lua: "Do we have a valid target? If not, we are inbound"); the dialling gate has Outbound = true
-- and its horizon has a Target. Inbound = open (or still dialling in) and not the dialling side.
function R.GateInbound(g)
	if not IsValid(g) or not g.IsStargate then return false end
	local eh = g.EventHorizon
	if not (g.IsOpen or g.Dialling) and not (IsValid(eh) and eh.IsOpen and eh:IsOpen()) then return false end
	if g.Outbound == false then return true end   -- (set on the gate that is being dialled the moment the dialling starts)
	return IsValid(eh) and eh.IsOpen and eh:IsOpen() and not IsValid(eh.Target) and R.GateStable(g)
end
-- an open gate one may walk into: stable (the vortex has settled), dialling out and with somewhere to go
function R.GateGo(g)
	if not R.GateStable(g) or g.Outbound == false then return false end
	return IsValid(g.EventHorizon.Target)
end
-- the inbound gates (listed with the gate list, 4 times a second): a deadly obstacle, kept clear of; an outgoing
-- gate's back half too (e.back).
-- The zone is the HORIZON itself (its disc, from the horizon entity: the Supergate's sits 2375 above the gate's origin,
-- the gates differ in size) plus a bug's body, DEAD_ALONG thick on each side - not the ring: a bug on the ring of a
-- gate that turns inbound must be able to walk off it (2026-11-14 review: with the ring inside the zone every way
-- off it was refused and it wandered over the inner rim into the horizon).
-- Each entry: { g = gate, eh = horizon, oc = the horizon's middle (local), r = its radius }
R.deadGates = R.deadGates or {}
local DEAD_ALONG, DEAD_BODY = 30, 14
function R.DeadEntry(g)
	local eh = IsValid(g) and g.EventHorizon
	if not IsValid(eh) then return nil end
	local mn, mx = eh:OBBMins(), eh:OBBMaxs()
	local r = math.max(mx.y - mn.y, mx.z - mn.z) * 0.5
	if not (r > 40 and r < 4000) then r = 115 end   -- (a horizon without a model box yet: an SG-1 gate's)
	return { g = g, eh = eh, oc = eh:OBBCenter(), r = r }
end
-- where p is from a horizon: a = along its normal (+ in front), rad = from its middle in its plane
local function deadRel(e, p)
	local d = p - e.eh:LocalToWorld(e.oc)
	local f = e.eh:GetForward()
	local a = d:Dot(f)
	return a, (d - f * a):Length(), f
end
-- how deep p is in the zone (> 0 inside). An outgoing gate's zone (e.back) is its back half only: the front is the way in.
local function deadDepth(e, a, rad, margin)
	if e.back and a >= 0 then return -1 end
	return math.min(DEAD_ALONG + margin - math.abs(a), e.r + DEAD_BODY + margin - rad)
end
function R.InDeadZone(pos, margin)
	margin = margin or 0
	for i = 1, #R.deadGates do
		local e = R.deadGates[i]
		if IsValid(e.eh) then
			local a, rad = deadRel(e, pos)
			if deadDepth(e, a, rad, margin) > 0 then return e.g, a, rad, e end
		end
	end
end
-- does a step from p0 to p1 go into a horizon: into the zone from outside, deeper into it, or across the disc.
-- A step out of it (or along it, no deeper) is free - a bug standing in the zone can always leave.
function R.DeadStep(p0, p1, margin)
	margin = margin or 0
	for i = 1, #R.deadGates do
		local e = R.deadGates[i]
		if IsValid(e.eh) then
			local a0, r0 = deadRel(e, p0)
			local a1, r1 = deadRel(e, p1)
			-- (an outgoing gate, a step from in front of it: the way in - free)
			if not (e.back and a0 >= 0) then
				if (a0 > 0) ~= (a1 > 0) then   -- across the plane: through the disc?
					local t = a0 / (a0 - a1)
					local _, rx = deadRel(e, p0 + (p1 - p0) * t)
					if rx < e.r + DEAD_BODY + margin then return e.g, e end
				end
				local d1 = deadDepth(e, a1, r1, margin)
				if d1 > 0 and d1 > deadDepth(e, a0, r0, margin) + 0.5 then return e.g, e end
			end
		end
	end
end
-- does the straight way from a to b run into one (in 4 pieces: a way passing in front of a horizon enters and leaves it)
function R.SegDead(a, b, margin)
	if #R.deadGates == 0 then return nil end
	local d = b - a
	local prev = a
	for k = 1, 4 do
		local q = a + d * (k / 4)
		local g = R.DeadStep(prev, q, margin or 0)
		if g then return g end
		prev = q
	end
end
-- the body's next target, kept out of every inbound horizon (ENT:PhysicsSimulate - whatever set the goal: a wander spot,
-- a climb, a planned way, a pull of the swarm). The part of the step towards the horizon is taken out; if even the rest
-- goes in (along the disc's edge), it stays where it is. A bug already in the zone is let out on the side it is on.
function R.DeadClamp(b, pos, target)
	if #R.deadGates == 0 then return target end
	if b.OutOfGateT and CurTime() - b.OutOfGateT < 2.5 then return target end   -- (just came out of one: on its way out of it)
	local g, e = R.DeadStep(pos, target, 0)
	if not g then return target end
	local a0, _, f = deadRel(e, pos)
	local t2 = target - f * (target - pos):Dot(f)
	if math.abs(a0) < DEAD_ALONG then t2 = t2 + f * (a0 >= 0 and 1 or -1) * 3 end   -- (in the zone: out on its side)
	if R.DeadStep(pos, t2, 0) then return Vector(pos) end
	b.DeadKeptT = CurTime()
	return t2
end
-- a jump's arc from pos with speed v (gravity), until it reaches land or 2 s: does it go into a horizon
function R.DeadArc(pos, v, land)
	if #R.deadGates == 0 then return nil end
	local gz = physenv.GetGravity().z
	local dist = land and pos:Distance(land) or 1e9
	local prev, t = pos, 0
	for _ = 1, 40 do
		t = t + 0.05
		local q = pos + v * t + Vector(0, 0, 0.5 * gz * t * t)
		local g = R.DeadStep(prev, q, 10)
		if g then return g end
		if land and q:DistToSqr(pos) > dist * dist + 400 then break end
		prev = q
	end
end
-- the way round an inbound gate on a long straight way from a to b (owner 2026-11-14; the rephorz test: bugs whose goal lay
-- behind an inbound gate walked along its foot straight through the horizon - the 140-unit feelers of ENT:Feel found
-- no way round in time). Returns a point beside the gate, level with where the bug is, a little on towards the goal.
-- In the zone itself: straight out of it on the side it is on.
function R.RoundDead(a, b)
	if #R.deadGates == 0 then return nil end
	local d = b - a
	local len = math.min(d:Length(), 900)
	if len < 1 then return nil end
	d = d / d:Length()
	local prev = a
	for k = 0, math.floor(len / 40) do
		local q = a + d * (k * 40)
		local g, e
		if k == 0 then
			local g0, _, _, e0 = R.InDeadZone(q, 0)
			g, e = g0, e0
		else
			g, e = R.DeadStep(prev, q, 30)
		end
		if g then
			local eh = e.eh
			local c = eh:LocalToWorld(e.oc)
			local f, r, u = eh:GetForward(), eh:GetRight(), eh:GetUp()
			local rel = a - c
			local off = rel:Dot(f)
			if k == 0 then return a + f * (off >= 0 and 1 or -1) * (DEAD_ALONG + 40 - math.abs(off)), g end
			local side = rel:Dot(r) >= 0 and 1 or -1
			local goalOff = (b - c):Dot(f)
			local step = math.Clamp(goalOff - off, -220, 220)
			local w = e.r + DEAD_BODY
			if math.abs(rel:Dot(r)) < w + 40 then step = 0 end   -- (still in front of / behind the opening: out to the side first, level with where it is - a slanting way crossed the horizon)
			return c + r * side * (w + 100) + f * (off + step) + u * rel:Dot(u), g
		end
		prev = q
	end
end

-- the vortex (owner 2026-11-04: besides the anti-replicator gun and the Dakara wave the third thing that kills them):
-- the swarm knows a gate's vortex shoots out in front of it, and learns how far - it starts from a careful guess, and
-- every bug the vortex takes widens it (where that bug stood). Whenever a gate dials or its vortex forms, every bug in
-- that zone gets out of the way, and the waiting spots lie beyond it.
R.blast = R.blast or { ahead = 220, side = 110 }
function R.InBlast(g, pos, margin)
	local rel = pos - g:GetPos()
	local f = g:GetForward()
	local a = rel:Dot(f)
	margin = margin or 40
	return a > -30 and a < R.blast.ahead + margin and (rel - f * a):Length() < R.blast.side + margin
end
function R.LearnBlast(g, pos)
	local rel = pos - g:GetPos()
	local f = g:GetForward()
	local a = rel:Dot(f)
	R.blast.ahead = math.min(900, math.max(R.blast.ahead, a + 60))
	R.blast.side = math.min(500, math.max(R.blast.side, (rel - f * a):Length() + 60))
	R.Stat("lost to the vortex")
end
function R.VortexNear(pos)
	for _, g in ipairs(gateList) do if IsValid(g) and g:GetPos():DistToSqr(pos) < 700 * 700 then return g end end
end
timer.Create("AGPRepVortex", 0.3, 0, function()
	if not R.Awake() then return end
	local now = CurTime()
	for _, g in ipairs(gateList) do
		if IsValid(g) and (g.Dialling or (g.IsOpen and not R.GateStable(g))) then
			for _, b in ipairs(ents.FindInSphere(g:GetPos() + g:GetForward() * R.blast.ahead * 0.5, R.blast.ahead + R.blast.side + 100)) do
				if b.AGPReplicator and b.RepKind == "bugs" and not b.RepGone and not b.Falling and not b.Boarded and now > (b.VortexT or 0) and R.InBlast(g, b:GetPos(), 60) then
					b.VortexT = now + 2
					b:GoTo(R.GateWaitSpot(g, b), 1.5)
					-- (one with a job - a colonist, a settler - only steps aside and keeps its job)
					if not b.Pursuit and b.Role ~= "colonist" and b.Role ~= "settler" and b.Role ~= "survivor" then b.State, b.Target, b.NextLook = "flee", nil, now + 4 end
					R.Stat("out of the vortex's way")
				end
			end
		end
	end
end)

-- where a bug waits at a gate: beside it (the kawoosh shoots straight ahead), on the side with open ground (a wall or
-- an edge there: the other side; both: well in front of it)
function R.GateWaitSpot(g, bug)
	local s = (bug:EntIndex() % 2 == 0) and 1 or -1
	local off = math.max(330, R.blast.side + 160) + (bug:EntIndex() % 4) * 40
	local base = g:GetPos() + Vector(0, 0, 40)
	for _, side in ipairs({ s, -s }) do
		local at = g:GetPos() + g:GetForward() * 150 + g:GetRight() * side * off
		local tr = util.TraceHull({ start = base + g:GetForward() * 150, endpos = at + Vector(0, 0, 40), mins = Vector(-14, -14, -14), maxs = Vector(14, 14, 14), mask = MASK_PLAYERSOLID_BRUSHONLY })
		local fl = util.TraceLine({ start = at + Vector(0, 0, 40), endpos = at - Vector(0, 0, 80), mask = MASK_PLAYERSOLID_BRUSHONLY })
		if not tr.Hit and fl.Hit then return fl.HitPos end
	end
	return g:GetPos() + g:GetForward() * 420 + g:GetRight() * s * 60
end

-- a bug arrived somewhere else in one step: old route and map links are no good here
-- (sent away with a climb on: its old plan lies back at the other gate - on rails, collisions off, it pulled the body
-- straight down through the floor over here. Solid again, the plan dropped, the moment it is sent)
local function offRails(b)
	if IsValid(b) and b.AGPReplicator and R.SurfNav then b.SurfPath, b.SurfPlanT = nil, CurTime() + 1 R.SurfNav.Rails(b, false) end   -- (no new plan till it is out)
end
R.OffRails = offRails

function R.AfterJump(b, exit)
	if not IsValid(b) then return end
	offRails(b)
	if b.RingGhostT then b.RingGhostT = CurTime() end   -- (the Queen: still not in the rings' way while they go down round her over there - made solid at once, they jammed on her; solid again once she is off the platform, queen's Brain)
	-- a ring sets what it carries down a few units into the floor: back on top of it (else it was taken for being
	-- outside the world and removed)
	local p = b:GetPos()
	-- out of a gate: measured from the gate's own height (it can come out below the floor, where a trace from just
	-- above it starts inside the floor and finds nothing - it was taken for outside the world)
	local top = IsValid(exit) and math.max(p.z + 60, exit:GetPos().z + 40) or p.z + 60
	local fl = util.TraceLine({ start = Vector(p.x, p.y, top), endpos = p - Vector(0, 0, 40), mask = MASK_SOLID, filter = function(e) return not e.AGPReplicator and not e.IsStargate end })
	if fl.Hit and not fl.StartSolid and fl.HitPos.z > p.z - 2 then
		b:SetPos(fl.HitPos + Vector(0, 0, 2))
		local ph = b:GetPhysicsObject(); if IsValid(ph) then ph:SetPos(fl.HitPos + Vector(0, 0, 2)) end
	end
	-- and it comes out at walking pace (a jump into the horizon kept its speed: it hit the ground too hard over there)
	local ph = b:GetPhysicsObject()
	if IsValid(ph) and ph:GetVelocity():Length() > 150 then ph:SetVelocity(ph:GetVelocity():GetNormalized() * 150) end
	if b.Falling and b.Jumping then b.Jumping = nil; b.JumpPlan = nil end
	b.Route, b.Goal, b.MoveTo, b.SteerTo, b.MapKey, b.RepAt = nil, nil, nil, nil, nil, nil
	b.LastPos, b.LastMoveT = b:GetPos(), CurTime()
	b.NextLook = 0
	-- out of a gate: first a few steps away from it (not standing in the horizon)
	if IsValid(exit) then
		b.Goal = exit:GetPos() + exit:GetForward() * 220 + Vector(0, 0, 10)
		b.MoveTo = b.Goal
		b.NextLook = CurTime() + 1.5
	end
	R.Dbg(b, "jumped to", tostring(b:GetPos()))
end

-- a gate shut on the other side (an iris, a shield): what the swarm knows (no going through there for 5 minutes)
R.irisAt = R.irisAt or {}
function R.GateShut(g) return IsValid(g) and (R.irisAt[g] or 0) > CurTime() end
hook.Add("StarGate.Teleport", "AGPRepFollowGate", function(e, eh, attached, blocked)
	offRails(e)
	-- (blocked is also said of a horizon still forming, or one it walked into from the inbound side: those are not the
	-- far gate shut - taken for an iris, the swarm left that gate alone for 5 minutes and let its prey go)
	local far = blocked and IsValid(eh) and IsValid(eh.Target) and eh.Target:GetParent()
	if blocked and IsValid(far) and far.IsBlocked and not far:IsBlocked() then return end
	if blocked and IsValid(e) and e.AGPReplicator and IsValid(eh) then
		-- it hit the iris: the others (all one network) know at once - they do not go after it, they look for another way
		local dst = far
		if IsValid(dst) then R.irisAt[dst] = CurTime() + 300 end
		R.Stat("stopped by an iris")
		local P = e.Pursuit
		if P then
			P.esc.blocked = true
			R.Dbg(e, "the iris is shut over there: the others look for another way")
			for _, b in ipairs(P.members) do if IsValid(b) and b.Pursuit == P then R.EndPursuit(b) end end
		end
		return
	end
	if blocked or not IsValid(e) or not IsValid(eh) then return end
	if e.AGPReplicator then
		local out = eh.Target
		local dstGate = IsValid(out) and out:GetParent() or nil
		local P = e.Pursuit
		-- the wormhole ride (doWormholeSequence: 3.2 s hidden and frozen at this gate, then over there) is waited for.
		-- (Done 0.2 s after going in, it was set down at the near gate mid-ride and "came out safe" while still riding:
		-- the others followed at once into a gate that shut on them - all lost, nobody left to dial it again, 2026-11-09)
		e.GateRide = CurTime()
		-- (on its way out of the far gate - an incoming one, whose horizon kills: the dead-zone rules leave it alone a
		-- moment, or the push out of a horizon sent a bug still coming out back into it - repgatein 2026-11-14 "gone")
		e.OutOfGate, e.OutOfGateT = dstGate, CurTime()
		local name = "AGPRepRide" .. e:EntIndex()
		local t0 = CurTime()
		timer.Create(name, 0.1, 120, function()
			if not IsValid(e) or e.RepGone then timer.Remove(name) return end   -- (lost on the way: the gate shut while it rode)
			if IsValid(eh) and eh.Ents and eh.Ents[e] ~= nil and CurTime() - t0 < 10 then return end   -- still riding
			timer.Remove(name)
			e.GateRide = nil
			-- (the ride cut short - a gate removed on the way - sends it back out of this gate: not through)
			if not (IsValid(dstGate) and e:GetPos():DistToSqr(dstGate:GetPos()) < 600 * 600) then
				offRails(e)
				e.Route, e.Goal, e.MoveTo, e.NextLook = nil, nil, nil, 0
				R.Dbg(e, "came back out: the way was cut")
				return
			end
			e.OutOfGateT = CurTime()
			R.AfterJump(e, out)
			-- it came out alive on the other side: the way is safe, the others follow
			R.safeGates[dstGate] = CurTime()   -- (the Queen may go there: R.QueenEscape)
			if P then P.esc.safe = true; R.Dbg(e, "came out safe: the others follow") end
		end)
		return
	end
	local src = eh:GetParent()
	local dst = IsValid(eh.Target) and eh.Target:GetParent()
	if GetConVar("agp_rep_debug"):GetBool() then print("AGP_RESULT", "INFO", "repdbg", "gate passage", tostring(e), "hunted", tostring(#preyOf(e) > 0 and hunted(preyOf(e)[1])), tostring(src), tostring(dst)) end
	if not (IsValid(src) and IsValid(dst)) then return end
	for _, prey in ipairs(preyOf(e)) do
		if hunted(prey) then
			R.escapes[prey] = { via = "gate", src = src, dst = dst, at = CurTime(), untilT = CurTime() + FOLLOW_TIME, prey = prey, hunters = huntersOf(prey) }
			R.Stat("escapes through a gate")
		end
	end
end)

hook.Add("StarGate.Rings.TeleportEnt", "AGPRepFollowRings", function(ent, ring)
	if not IsValid(ent) then return end
	if ent.AGPReplicator then
		offRails(ent)
		local pad = IsValid(ring) and ring.Other
		timer.Simple(0, function()
			R.AfterJump(ent)
			-- (owner 2026-11-05: "step out of the rings at the new destination"): off the platform - one left on it is
			-- sent back by the next transport
			if IsValid(ent) and IsValid(pad) then
				local a = math.random() * math.pi * 2
				ent.Goal = pad:GetPos() + Vector(math.cos(a), math.sin(a), 0) * 150 + Vector(0, 0, 8)
				ent.MoveTo, ent.NextLook = ent.Goal, CurTime() + 2
			end
		end)
		return
	end
	if not IsValid(ring) or not IsValid(ring.Other) then return end
	for _, prey in ipairs(preyOf(ent)) do
		if hunted(prey) then
			R.escapes[prey] = { via = "rings", src = ring, dst = ring.Other, at = CurTime(), untilT = CurTime() + FOLLOW_TIME, prey = prey, hunters = huntersOf(prey) }
			R.Stat("escapes by ring")
		end
	end
end)

-- the players' footsteps (owner 2026-11-05: "iam inside a building and they dont find me, they are on the roof above
-- me"): every player leaves a trail - a point every 40 units, the last 2 minutes. Whoever is hunted indoors got in
-- somewhere; a bug that cannot see its prey takes that same way in (ENT:FollowTrail). A jump (respawn, teleport,
-- noclip) starts a new trail
R.trails = R.trails or {}
timer.Create("AGPRepTrails", 0.25, 0, function()
	if not R.Awake() or not next(R.bugs or {}) then return end
	local now = CurTime()
	for _, p in ipairs(player.GetAll()) do
		local t = R.trails[p] or {}
		R.trails[p] = t
		if not p:Alive() or p:GetMoveType() == MOVETYPE_NOCLIP or p:InVehicle() then
			if #t > 0 then R.trails[p] = {} end
		else
			local pos = p:GetPos()
			local last = t[#t]
			if last and last.p:DistToSqr(pos) > 400 * 400 then t = {} R.trails[p] = t last = nil end
			if not last or last.p:DistToSqr(pos) > 40 * 40 then t[#t + 1] = { p = pos, t = now } end
			while #t > 0 and (#t > 200 or now - t[1].t > 120) do table.remove(t, 1) end
		end
	end
	for p in pairs(R.trails) do if not IsValid(p) then R.trails[p] = nil end end
end)

-- the way in (owner 2026-11-05: "the replicators know every building every window, also they have radar for player
-- buildings - they should manage on their own to find the right way to the player"): a player under a roof (a house
-- of the map or a base of props) - the hive feels its way out from him through the rooms, corridors, doors and
-- windows (a coarse search through the free space, 40 units a step, props count as walls) to the first place open to
-- the sky: that is the way in, back to front. Points on the floor (a window: its sill; the bugs climb the wall to it).
-- Shared by the whole swarm, worked out again when he has moved or after 5 s. Nil: he is outdoors, or no way in
-- within reach (then the trail, ENT:FollowTrail)
local WG = 40
local WH = Vector(10, 10, 10)
local function wayFilter(e) return not (e:IsPlayer() or e:IsNPC() or e.AGPReplicator or e:GetClass():find("^stargate_") or e.IsRings) end
local function openSky(p) return not util.TraceLine({ start = p, endpos = p + Vector(0, 0, 900), mask = MASK_SOLID, filter = wayFilter }).Hit end
R.wayIn = R.wayIn or {}
function R.WayIn(t)
	local now = CurTime()
	local c = R.wayIn[t]
	local start = t:WorldSpaceCenter()
	if c and now - c.t < 5 and c.from:DistToSqr(start) < 64 * 64 then return c.way end
	c = { t = now, from = start }
	R.wayIn[t] = c
	if openSky(start) then return nil end   -- (outdoors: they simply come)
	local function key(p) return math.floor(p.x / WG + 0.5) .. ":" .. math.floor(p.y / WG + 0.5) .. ":" .. math.floor(p.z / WG + 0.5) end
	local seen, prev, q, head = { [key(start)] = true }, {}, { start }, 1
	local dirs = { Vector(WG, 0, 0), Vector(-WG, 0, 0), Vector(0, WG, 0), Vector(0, -WG, 0), Vector(0, 0, WG), Vector(0, 0, -WG) }
	local out
	while head <= #q and head < 700 do
		local p = q[head]
		head = head + 1
		for _, d in ipairs(dirs) do
			local n = p + d
			local k = key(n)
			if not seen[k] then
				seen[k] = true
				if not util.TraceHull({ start = p, endpos = n, mins = -WH, maxs = WH, mask = MASK_SOLID, filter = wayFilter }).Hit then
					prev[n] = p
					q[#q + 1] = n
					if openSky(n) then out = n break end
				end
			end
		end
		if out then break end
	end
	R.Stat("ways in worked out")
	if not out then return nil end
	-- back from the opening to him; on the floor below each point (not more than 160 down: a window's sill, a
	-- landing), every third point and every turn
	local raw = {}
	local p = out
	while p do raw[#raw + 1] = p p = prev[p] end
	local way = {}
	for k, x in ipairs(raw) do
		local turn = raw[k - 1] and raw[k + 1] and (x - raw[k - 1]):GetNormalized():Dot((raw[k + 1] - x):GetNormalized()) < 0.9
		if k == 1 or k == #raw or turn or k % 3 == 0 then
			local tr = util.TraceLine({ start = x, endpos = x - Vector(0, 0, k == 1 and 2000 or 160), mask = MASK_SOLID, filter = wayFilter })
			way[#way + 1] = tr.Hit and (tr.HitPos + Vector(0, 0, 4)) or x
		end
	end
	way.door = raw[math.min(#raw, 2)]   -- (the opening itself, just inside the edge of the roof)
	c.way = way
	R.Dbg(nil, "way in to", t:Nick(), #way, "points, opening at", tostring(way.door))
	return way
end

-- (owner 2026-11-05: "one of the replicators swam in the event horizon, half the body sticking out"): a horizon is no
-- wall - a bug can stand in it. Through it only works from the front of a gate that dials out; in the horizon of an
-- incoming one (or one it does not mean to use) it stood there. Once a second: such a bug is sent out in front of it
timer.Create("AGPRepOutOfHorizon", 0.5, 0, function()   -- (twice a second: a kill takes a touch)
	if not R.cv.on:GetBool() or not next(R.bugs or {}) then return end
	local now = CurTime()
	for _, eh in ipairs(ents.FindByClass("event_horizon")) do
		local g = IsValid(eh) and eh:GetParent()
		if IsValid(g) then
			local usable = R.GateGo(g)
			local inbound = R.GateInbound(g)   -- (its horizon kills: out at once, not after two looks)
			local de = inbound and R.DeadEntry(g)
			local c = de and eh:LocalToWorld(de.oc) or eh:GetPos()
			local f = eh:GetForward()
			for _, b in ipairs(ents.FindInSphere(c, de and de.r + 60 or 140)) do
				-- (a falling bug too when the horizon has it in its buffer: there its gravity is off - it floats, never
				-- lands, and died when the gate shut, with no damage at all - 2026-11-14 review)
				local floating = b.Falling and inbound and eh.AllBuffer and eh.AllBuffer[b:EntIndex()] == b
				local arriving = b.OutOfGate == g and now - (b.OutOfGateT or 0) < 2.5   -- (still coming out of this one)
				if b.AGPReplicator and not b.RepGone and (not b.Falling or floating) and b.RepKind == "bugs" and not arriving then
					local d = b:GetPos() - c
					local ax = d:Dot(f)
					local meant = usable and b.IntoGateAt == g and now - (b.IntoGateT or 0) < 3
					if math.abs(ax) < 30 and (not de or (d - f * ax):Length() < de.r + 14) and not meant then
						b.InHorizonT = (b.InHorizonT or 0) + 1
						if b.InHorizonT >= (inbound and 1 or 4) then
							-- (out on the side it is on: from behind the gate it was pushed round to the front, through the horizon)
							local sx = ax >= 0 and 1 or -1
							local out = c + f * 200 * sx + Vector(0, 0, 10)
							if floating then
								local ph0 = b:GetPhysicsObject()
								if IsValid(ph0) then ph0:EnableGravity(true) end
								R.Stat("floating in a horizon: out")
							end
							b.SurfPath = nil
							b:GoTo(out, 1.2)
							local ph = b:GetPhysicsObject()
							if IsValid(ph) then ph:Wake() ph:SetVelocity(f * 220 * sx + Vector(0, 0, 60)) end
							R.Stat("out of a horizon")
							R.Dbg(b, "stood in the horizon: out in front of the gate")
							b.InHorizonT = 0
						end
					else b.InHorizonT = 0 end
				end
			end
		end
	end
end)

-- once a second: the hunters of escaped prey become pursuers (the nearest to the way it took, up to 10)
timer.Create("AGPRepPursuit", 1, 0, function()
	if not R.Awake() then return end
	local now = CurTime()
	for prey, esc in pairs(R.escapes) do
		if now > esc.untilT or not IsValid(esc.src) or not IsValid(esc.dst) then   -- (the prey may be gone here: made anew on the other side)
			R.escapes[prey] = nil
		elseif esc.via == "gate" and R.GateShut(esc.dst) then
			R.escapes[prey] = nil   -- shut over there: another way (they hunt on here)
		elseif not esc.party then
			local cands = {}
			local seen = {}
			local list = esc.hunters or {}
			if IsValid(prey) then for _, b in ipairs(huntersOf(prey)) do list[#list + 1] = b end end
			-- an escape kept for later (the last one did not go alone): any of the swarm near the way, once they are enough
			if esc.minParty then
				for b in pairs(R.bugs) do
					if IsValid(b) and b.RepOwner == esc.owner and b:GetPos():DistToSqr(esc.src:GetPos()) < 2500 * 2500 then list[#list + 1] = b end
				end
			end
			for _, b in ipairs(list) do
				if not seen[b] and IsValid(b) and not b.RepGone and b.RepKind == "bugs" and not b.Pursuit and not b.Boarded and not b.InTower and not b.InBridge
					and b:GetPos():DistToSqr(esc.src:GetPos()) < 4000 * 4000 then cands[#cands + 1] = b; seen[b] = true end
			end
			if #cands > 0 and #cands >= (esc.minParty or 1) then
				table.sort(cands, function(a, b) return a:GetPos():DistToSqr(esc.src:GetPos()) < b:GetPos():DistToSqr(esc.src:GetPos()) end)
				local party = { esc = esc, members = {}, phase = "go", untilT = now + 90 }
				if esc.via == "gate" then
					for _, e in ipairs(ents.FindInSphere(esc.src:GetPos(), 700)) do if e:GetClass():find("^dhd_") then party.dhd = e break end end
				end
				for i = 1, math.min(MAX_PURSUERS, #cands) do
					local b = cands[i]
					b.Pursuit, b.PursuitRole = party, b.Role
					b.Role = "pursuer"
					party.members[#party.members + 1] = b
					party.leader = party.leader or b
				end
				esc.party = party
				R.Stat("pursuits")
				R.Dbg(party.leader, "follows its prey", esc.via, "with", #party.members)
			end
		end
	end
end)

-- a ring colony: a big swarm sends a few bugs by ring to another platform (called by the hive with the gate colonists)
function R.RingColony(h, list, n, now)
	if n < R.cv.gateSwarm:GetInt() or now < (h.nextRingColony or 0) then return end
	h.nextRingColony = now + 200
	local c = Vector()
	for _, b in ipairs(list) do c:Add(b:GetPos()) end
	c:Div(n)
	local src, sd
	for _, r in ipairs(ents.GetAll()) do
		if r.IsRings and not r.Busy and r.DialEntity then
			local d = r:GetPos():DistToSqr(c)
			if d < 3000 * 3000 and (not sd or d < sd) then src, sd = r, d end
		end
	end
	if not src then return end
	local cands = {}
	for _, r in ipairs(ents.GetAll()) do
		if r ~= src and r.IsRings and not r.Busy and r:GetPos():DistToSqr(src:GetPos()) > 1500 * 1500 then cands[#cands + 1] = r end
	end
	if #cands == 0 then return end
	local dst = cands[math.random(1, #cands)]
	local party = { esc = { via = "rings", src = src, dst = dst }, members = {}, phase = "go", untilT = now + 90, colony = true }
	for _, b in ipairs(list) do
		if #party.members < 3 and b.RepKind == "bugs" and (not b.Role or b.Role == "worker") then
			if not b.Pursuit and not b.Boarded and not b.InTower and not b.InBridge then
				b.Pursuit, b.PursuitRole = party, b.Role
				b.Role = "pursuer"
				party.members[#party.members + 1] = b
				party.leader = party.leader or b
			end
		end
	end
	if #party.members == 0 then return end
	R.Stat("ring colonies")
	R.Dbg(party.leader, "ring colony with", #party.members)
end

-- the Queen away by rings or a Stargate (owner 2026-11-05: "if we are sure that we have a 100% success so the queen
-- survives she is also allowed to search a place via stargate or rings"). Only where it is sure:
--   rings     - a platform at least 2000 away with no player within 2000 of it (rings have no iris)
--   Stargate  - a gate one of the swarm came out of alive in the last 30 minutes, no iris known there, not busy,
--               no player within 2500 of it
-- She goes with her guards (the pursuers' way: onto the platform / dial, wait for the horizon, through); over there is
-- her new nest. Nil: no sure way
R.safeGates = R.safeGates or {}
function R.QueenEscape(q, now)
	local pos = q:GetPos()
	local function clear(at, r)
		for _, p in ipairs(player.GetAll()) do if p:Alive() and p:GetPos():DistToSqr(at) < r * r then return false end end
		return true
	end
	local esc
	-- (platforms only - the single rings that rise out of one are "rings" too, hidden under it: she went for one of them)
	local pads = {}
	for _, r in ipairs(ents.GetAll()) do if r.IsRings and r.DialEntity and r:GetClass():find("^ring_base") and not r.Busy then pads[#pads + 1] = r end end
	table.sort(pads, function(a, b) return a:GetPos():DistToSqr(pos) < b:GetPos():DistToSqr(pos) end)
	for _, r in ipairs(pads) do
		if r:GetPos():DistToSqr(pos) > 1500 * 1500 or math.abs(r:GetPos().z - pos.z) > 80 then break end   -- (one she can walk onto)
		for _, o in ipairs(pads) do
			if o ~= r and o:GetPos():DistToSqr(r:GetPos()) > 2000 * 2000 and clear(o:GetPos(), 2000) then esc = { via = "rings", src = r, dst = o } break end
		end
		if esc then break end
	end
	if not esc then
		for dst, t in pairs(R.safeGates) do
			if IsValid(dst) and now - t < 1800 and not R.GateShut(dst) and not dst.IsOpen and not dst.Dialling and clear(dst:GetPos(), 2500) then
				for _, src in ipairs(ents.FindInSphere(pos, 2000)) do
					if src.IsStargate and src ~= dst and src.NoxDialGate and not src.IsOpen and not src.Dialling and src:GetPos():DistToSqr(dst:GetPos()) > 1500 * 1500 then esc = { via = "gate", src = src, dst = dst } break end
				end
			end
			if esc then break end
		end
	end
	if not esc then return end
	esc.safe = true   -- (sure already: nobody needs to go first)
	local party = { esc = esc, members = {}, phase = "go", untilT = now + 120, queen = q }
	if esc.via == "gate" then for _, e in ipairs(ents.FindInSphere(esc.src:GetPos(), 700)) do if e:GetClass():find("^dhd_") then party.dhd = e break end end end
	for b in pairs(R.bugs) do
		if IsValid(b) and b.RepGuard == q and not b.Pursuit and not b.Boarded then
			b.Pursuit, b.PursuitRole, b.Role = party, b.Role, "pursuer"
			party.members[#party.members + 1] = b
			party.leader = party.leader or b
		end
	end
	q.Pursuit = party
	party.members[#party.members + 1] = q
	party.leader = party.leader or q
	R.Stat("queen escapes")
	R.Dbg(q, "the Queen leaves by", esc.via, "with", #party.members - 1, "guards")
	return party
end

-- the end of a pursuit (arrived, prey gone, or no way through): back to the swarm's work
function R.EndPursuit(b, arrived)
	local party = b.Pursuit
	b.Pursuit = nil
	b.Role = b.PursuitRole ~= "pursuer" and b.PursuitRole or nil
	b.PursuitRole = nil
	if not party then return end
	local prey = party.esc.prey
	if arrived and party.queen then
		-- the Queen's escape: over there is the new nest (her guards with her)
		local q = party.queen
		if b == q then b.Role, b.RepHome, b.Hidden, b.HideGo, b.HideT = nil, b:GetPos(), true, nil, CurTime()
		elseif IsValid(q) then b.RepHome = q:GetPos() end
		b.State, b.Target = "wander", nil
		return
	end
	if arrived then
		if party.colony then
			b.Role, b.RepHome, b.RepHomeRadius = "worker", b:GetPos(), 1500
		elseif IsValid(prey) then
			b.State, b.Target, b.NextLook = "attack", prey, CurTime() + 3
			b.GatherT = nil
		else
			b.State, b.Target, b.NextLook = "wander", nil, 0   -- the prey was made anew here (an NPC): they look for it
		end
	end
end
