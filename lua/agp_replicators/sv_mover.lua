-- Replicators: one mover (prototype). Till now several systems took turns moving a bug every tick - the felt-map walk, the
-- leg walker and its 20 rules, the side-view plan, the ceiling rules, and Think's waypoint rules - and at the seams (a
-- ceiling's corner, a window's sill and frame, a roof's edge) they disagreed which face the bug and its next waypoint
-- were on: it rocked between them for 5-20 s. Here one place decides, with one clock:
--
--  * FOLLOW: along the felt map to the next waypoint of its way (R.FieldWalk); the waypoint counts as reached within 18,
--    or when the one after it is nearer AND in plain sight (never through a wall: the window frame)
--  * SEAM: the next waypoint lies on another face (a felt way knows each waypoint's face, sv_feltnav.lua) and it is near
--    and no nearer: onto that face in one corner move (R.TransitTo), which runs to its end; never straight back (2.5 s)
--  * RECOVER: no 6 nearer its waypoint for 1.5 s: its way asked anew from where it is; 3.5 s: the waypoint after (if in
--    sight); 6 s: the usual walk for 2 s, then it tries again
-- Not near the players' props (the felt map knows only the map: the legs there), not in a tower, a bridge, a jump, on a
-- ship or round a corner (the corner move is one motion). agp_rep_onemover 1 (default): on; 0: the older walk.
local R = AGP.Rep
local M = R.Mover or {}
R.Mover = M
-- (on by default for the update: at the stall probes 5/6 there against 3/6 without, a random round 6/6 with no standing
-- still, the strict high edge 3/3 clean at 21-23 s. Not saved (no FCVAR_ARCHIVE): the tests had saved the
-- prototype's agp_rep_mover 0 into server.vdf, and a saved value would win over the default)
R.cv.mover = R.cv.mover or CreateConVar("agp_rep_onemover", "1", FCVAR_NONE, "Replicators: one mover decides their walking (1, default) or the older walk (0)")

local MASKW = MASK_PLAYERSOLID
local function tr(b, a, c)
	return util.TraceLine({ start = a, endpos = c, mask = MASKW, filter = function(e) return e ~= b and not e.AGPReplicator and (not R.Walkable or R.Walkable(e)) end })
end
local function brushSees(a, c) return not util.TraceLine({ start = a, endpos = c, mask = MASK_PLAYERSOLID_BRUSHONLY }).Hit end

-- does the mover own this bug's walking this tick (Think leaves its waypoints alone then)
function M.Owns(b) return b.MoverOn == true end

local function control(b, ph, p, u, f, dt, why)
	local vmax = math.max(260, (b.RepSpeed or 150) * (b.SpeedMul or 1) * 2)
	if R.DeadClamp and R.deadGates and #R.deadGates > 0 then p = R.DeadClamp(b, b:GetPos(), p) end
	b.RepUp, b.RepFwd, b.RepAt = u, f, p
	b.RepPlane, b.RepFlat = nil, nil
	b.WalkWhy = why
	ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = p, angle = f:AngleEx(u), maxangular = 4000,
		maxangulardamp = 8000, maxspeed = vmax, maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
end

local function nextWaypoint(b)
	local rt = b.Route
	b.RouteI = (b.RouteI or 1) + 1
	b.MoveTo = rt and rt[b.RouteI] or b.Goal
	if rt and not rt[b.RouteI] then b.Route = nil end
	b.MoverProg = nil
end

-- (why it left a bug to the usual walk: for the stall log below)
local function no(b, why) b.MoverWhy = why return false end

-- a crowded swarm shares the ticks (replag13: the mover's steps of 60 bugs were 2 ms of every tick): 20 bugs and more: each
-- works out its step every 2nd tick, 45 and more: every 3rd; between them it goes on straight along the even face it is on
-- (M.Step says when: b.ShareN). Near a corner, an edge, a step, its waypoint or an incoming gate every tick
local shareTick, shareDiv = 0, 1
function M.Shared(b, ph, dt)
	if not b.ShareN then return false end
	local tk = engine.TickCount()
	if shareTick ~= tk then
		shareTick = tk
		local n = 0
		for _ in pairs(R.bugs) do n = n + 1 end
		shareDiv = R.TestOn and R.TestOn.shareDiv or n >= 45 and 3 or n >= 20 and 2 or 1
	end
	if shareDiv == 1 or b.ShareN >= shareDiv - 1 or tk - b.ShareTick > 4 or not b.RepAt or not b.MoveTo or #R.deadGates > 0
		or b.Transit or b.SurfPath or b.Falling or b.Boarded or b.Eating or b.InTower or b.InBridge or b.Crossing or (R.TestOff and R.TestOff.share) then b.ShareN = nil return false end
	b.ShareN = b.ShareN + 1
	M.shared = (M.shared or 0) + 1
	local u, f = b.RepUp, b.RepFwd
	local p = b.RepAt + f * ((b.RepSpeed or 150) * (b.SpeedMul or 1) * dt)
	b.RepAt = p
	ph:ComputeShadowControl({ secondstoarrive = 0.08, pos = p, angle = f:AngleEx(u), maxangular = 4000,
		maxangulardamp = 8000, maxspeed = math.max(260, (b.RepSpeed or 150) * (b.SpeedMul or 1) * 2), maxspeeddamp = 9000, dampfactor = 0.85, teleportdistance = 0, deltatime = dt })
	return true
end

-- one tick. true: it set the body; false: the usual walk this tick
function M.Step(b, ph, pos, up, fwd, dt)
	b.MoverOn = nil
	b.ShareN = nil
	if not R.cv.mover:GetBool() then return no(b, "switched off") end
	if not b.RepClimb then return no(b, "not a climber") end
	if not (R.FieldOn and R.FieldOn()) then return no(b, "felt map off (agp_rep_legwalk 1?)") end
	if not (R.FieldWalk and R.Awake and R.Awake()) then return no(b, "felt map not awake") end
	if b.Transit then return no(b, "busy: corner move") end
	if b.InTower or b.InBridge or b.BridgeJob then return no(b, "busy: tower/bridge") end
	if b.Boarded then return no(b, "busy: on a ship") end
	if b.Falling then return no(b, "busy: falling") end
	if b.Crossing then return no(b, "busy: crossing a gap") end
	if b.Clinging then return no(b, "busy: clinging to a player") end
	if b.Eating then return no(b, "busy: eating") end
	local now = CurTime()
	-- (props near: the legs - looked at every 0.5 s as the felt walk does; what it goes for counts not, a ship does)
	-- (props the felt map knows count not - but only on a floor: on a prop wall the felt walk could not get round a lip
	-- 12 out that the legs climb, the lip test passed and failed with the prop layer. Its body's up, not its walk's: at a
	-- plate's edge that leaned 56 off while the body stood upright, the legs took it and it hung)
	if now > (b.MoverPropT or 0) then
		b.MoverPropT = now + 0.5
		b.MoverProps = false
		-- (a floor: its body upright, and its walk's up too - or its goal below it, at an edge it lets itself down from; under
		-- a plate's lip, body still nearly upright on the cube's side and the goal on top, the felt walk could not get round)
		local floorish = b:GetUp().z > 0.7 and (up.z > 0.7 or (b.Goal ~= nil and b.Goal.z < pos.z - 40))
		for _, e in ipairs(ents.FindInSphere(pos, 90)) do
			if e ~= b and not (e == b.Target and not R.IsShip(e)) and not e:IsWorld() and not e.AGPReplicator and (not R.Walkable or R.Walkable(e)) and IsValid(e:GetPhysicsObject())
				and not (floorish and R.Field and R.Field.PropKnown and R.Field.PropKnown(e)) then b.MoverProps = true b.MoverPropsWhat = e:GetClass() .. " " .. tostring(e:GetModel()) break end
		end
	end
	if b.MoverProps then return no(b, "props near: " .. tostring(b.MoverPropsWhat)) end
	if b.MoverOffT and now < b.MoverOffT then return no(b, "gave up 2 s (stuck 4 s)") end
	if not b.MoveTo then return no(b, "nowhere to go") end
	-- (a way the swarm remembers - its climbs - is gone the remembered way: the mover steps aside while there is one;
	-- the memory test failed "it planned instead")
	local SN = R.SurfNav
	if now > (b.MoverKnownT or 0) then
		b.MoverKnownT = now + 0.5
		b.MoverKnown = SN and SN.Recall and SN.Recall(pos, b.MoveTo) and true or false
	end
	if b.MoverKnown then return no(b, "a remembered way") end
	-- (a climb right here it has a side-view plan for - its goal within 300 and above it: the plan goes on. Dropped by the
	-- mover when a way across the map came in, at gm_construct's shelf it ran to and fro for 40 s, course 4.1 in 2 of 4
	-- runs)
	local SP = b.SurfPath
	if SP and SP.goal and b.Goal and SP.goal:DistToSqr(b.Goal) < 48 * 48 and SP.goal:DistToSqr(pos) < 300 * 300 and SP.goal.z > pos.z + 40 then return no(b, "a planned climb right here") end
	-- (otherwise the side-view plan is not used: one mover)
	if b.SurfPath then b.SurfPath, b.SurfPlanT = nil, now + 3 end
	b.MoverOn = true
	b.MoverWhy = nil
	local rt, i = b.Route, b.RouteI
	-- reached, or passed and the next in plain sight
	if rt and i and rt[i] then
		local wp, nx = rt[i], rt[i + 1]
		local d2 = wp:DistToSqr(pos)
		if d2 < 18 * 18 then nextWaypoint(b)
		elseif nx and d2 < 60 * 60 and nx:DistToSqr(pos) < nx:DistToSqr(wp) and brushSees(pos + up * 8, nx) then
			nextWaypoint(b) R.Stat("mover: passed a waypoint, the next in sight")
		end
	end
	local wp = b.MoveTo
	if not wp then b.MoverOn = nil return no(b, "no waypoint") end
	rt, i = b.Route, b.RouteI
	local wm = rt and rt.m and i and rt.m[i]
	-- progress towards it
	local P = b.MoverProg
	local dwp = wp:Distance(pos)
	if not P or P.wp ~= wp then P = { wp = wp, d = dwp, t = now, stage = 0 } b.MoverProg = P end
	if dwp < P.d - 6 then P.d, P.t, P.stage = dwp, now, 0 end
	local stuck = now - P.t
	-- RECOVER
	-- (close to it - 45 - and no nearer for 1 s: taken as reached. The next waypoint, or at its goal it is there and looks
	-- for the next thing to do. Round a waypoint or a goal on a wall it could not quite settle on it went to and fro for 3 s
	-- and more - 89 WOBBLEs in the stall log of the test runs) (and in plain sight of it, nothing
	-- between: under a plate's lip its goal on top lay 20 off, through the plate)
	if stuck > 1 and dwp < 45 and not util.TraceLine({ start = pos + up * 8, endpos = wp + up * 4, mask = MASKW, filter = function(e) return e ~= b and not e.AGPReplicator end }).Hit then
		if rt and i and rt[i + 1] then
			nextWaypoint(b) R.Stat("mover: close to its waypoint, no nearer 1 s - the next")
			return M.Step(b, ph, pos, up, fwd, dt)
		elseif b.Goal and wp:DistToSqr(b.Goal) < 4 then
			R.Stat("mover: close to its goal, no nearer 1 s - there")
			b.Goal, b.MoveTo, b.Route, b.MoverProg = nil, nil, nil, nil
			b.NextLook = math.min(b.NextLook or 0, now + 0.3)
			return no(b, "at its goal (close, no nearer)")
		end
	end
	-- (a way asked anew is worked out a moment later: asked again every tick till it comes - asked once, it never came
	-- and the bug waited for the 6 s at the window frame)
	if P.replan and b.Goal and R.Nav and R.Nav.Request then
		local r = R.Nav.Request(P.replan, b.Goal)
		if r and b.TakeWay then P.replan = nil b:TakeWay(r, pos) R.Stat("mover: stuck - way asked anew") b.MoverProg = nil return M.Step(b, ph, pos, up, fwd, dt)
		elseif r == false then P.replan = nil end
	end
	if stuck > 4 then
		b.MoverProg, b.MoverOffT, b.MoverOn = nil, now + 2, nil
		R.Stat("mover: stuck 4 s - the usual walk 2 s")
		R.Dbg(b, "mover: stuck, usual walk", tostring(pos))
		return no(b, "stuck 4 s, hands over")
	elseif stuck > 2.8 and P.stage < 2 then
		P.stage = 2
		if rt and rt[(i or 1) + 1] and brushSees(pos + up * 8, rt[(i or 1) + 1]) then nextWaypoint(b) R.Stat("mover: stuck - the waypoint after") end
	elseif stuck > 1.5 and P.stage < 1 and b.Goal then
		P.stage = 1
		P.replan = Vector(pos)
	end
	-- DROP: on a floor at its edge, its waypoint well below, the felt walk wants it down the edge's face (or no nearer for
	-- 0.6 s): open air beyond the edge and a real floor under its whole body within a safe drop - it lets itself down, as
	-- from a ceiling (sv_walk.lua's R.LetDown). (A plate 3.6 thick standing out over a cube: the felt walk put its up onto the
	-- plate's thin end face, the body stayed upright, 4-14 s standing bent at the edge - the plate test) (its body
	-- upright, whatever its walk's up says: at the plate's edge
	-- that already lay on the thin end face, the first try never fired) (its waypoint or its goal: the way's next point
	-- lay 36 down the cube's side and the goal
	-- 100 below, plate test) (only stuck there: its walk's up off its upright body for 0.5 s, or no nearer for 0.8 s
	-- - with "the felt walk wants it down the face" it let go at every edge it should climb down, strict's high edge 0/3
	-- clean with 2-4 falls each) (its walk's up as handed in or as kept on the bug - the stall log showed the kept one
	-- on the plate's end face while the drop never fired; and creeping: less than 10 moved in 0.8 s - a few units a
	-- second kept "no nearer" from counting)
	local wu = b.RepUp or up
	local mis = b:GetUp().z > 0.7 and (up.z < 0.7 or wu.z < 0.7)
	if mis then b.MoverMisT = b.MoverMisT or now else b.MoverMisT = nil end
	local CP = b.MoverCreep
	if not CP or CP.p:DistToSqr(pos) > 10 * 10 then CP = { p = Vector(pos), t = now } b.MoverCreep = CP end
	local creep = now - CP.t
	-- (walking off: a push from on top of the plate did nothing - it still touched the plate, "dropped" every second and
	-- stood 3-5 s at the edge. It walks straight out at its own height and lets go once there is no floor under it)
	--
	local OF = b.MoverOff
	if OF then
		local under = util.TraceLine({ start = pos + Vector(0, 0, 4), endpos = pos - Vector(0, 0, 12), mask = MASKW, filter = function(e) return e ~= b and not e.AGPReplicator end })
		if not under.Hit then
			b.MoverOff = nil
			R.Stat("mover: lets itself down off the edge")
			b.RepFallWhy = "lets itself down"   -- (the same move as from a ceiling: the tests count it as no fall)
			b:StartFall(OF.dir * 90)
			return true
		elseif now > OF.t then b.MoverOff = nil
		else
			local step = math.min(((b.RepSpeed or 150) * (b.SpeedMul or 1)) * 0.1, math.max(4, (OF.q - pos):Length2D()))
			control(b, ph, Vector(pos.x, pos.y, OF.z) + OF.dir * step, Vector(0, 0, 1), OF.dir, dt, "mover: walks off the edge")
			return true
		end
	end
	-- (once a second at most: 23 drops for 3 bugs in one plate pass - a body still over the plate landed on it at once)
	if now > (b.MoverDropT or 0) and b:GetUp().z > 0.7 and (wp.z < pos.z - 40 or (b.Goal and b.Goal.z < pos.z - 40 and wp.z < pos.z - 12)) and ((mis and now - b.MoverMisT > 0.5) or stuck > 0.8 or creep > 0.8) then
		local dir = Vector(wp.x - pos.x, wp.y - pos.y, 0)
		if dir:LengthSqr() > 1 then
			dir:Normalize()
			local fall = R.LetDown or 160
			-- (not its own kind: two bugs on the same spot at the plate's edge each found the other in the way, 3 s bent)
			local function notRep(e) return e ~= b and not e.AGPReplicator end
			local why = {}   -- (for the stall log: why each spot was no good)
			for _, ahead in ipairs({ 22, 34, 46, 60 }) do
				local q = pos + dir * ahead
				-- (past the edge: nothing under that spot down to 30 below its feet, and nothing in the way there)
				local gap = util.TraceLine({ start = Vector(q.x, q.y, pos.z + 4), endpos = Vector(q.x, q.y, pos.z - 30), mask = MASKW, filter = notRep })
				local way = util.TraceLine({ start = pos + Vector(0, 0, 4), endpos = Vector(q.x, q.y, pos.z + 4), mask = MASKW, filter = notRep })
				if gap.Hit then why[#why + 1] = ahead .. ":floor " .. math.Round(gap.HitPos.z - pos.z) elseif way.Hit then why[#why + 1] = ahead .. ":way " .. tostring(way.Entity) end
				if not gap.Hit and not way.Hit then
					local ok, lz = true, nil
					for _, o in ipairs({ Vector(0, 0, 0), Vector(14, 0, 0), Vector(-14, 0, 0), Vector(0, 14, 0), Vector(0, -14, 0) }) do
						local fl = util.TraceLine({ start = Vector(q.x, q.y, pos.z) + o, endpos = Vector(q.x, q.y, pos.z - fall) + o, mask = MASKW, filter = notRep })
						if not fl.Hit or fl.StartSolid or fl.HitNormal.z < 0.7 then ok = false why[#why + 1] = ahead .. ":land " .. (not fl.Hit and "none" or fl.StartSolid and "inside" or "steep") break end
						lz = lz and math.max(lz, fl.HitPos.z) or fl.HitPos.z
					end
					if ok and lz < pos.z - 20 then
						b.MoverMisT = nil
						b.MoverDropT = now + 1
						b.MoverOff = { q = Vector(q), dir = Vector(dir), z = pos.z + 1, t = now + 0.8 }
						R.Stat("mover: walks off the edge")
						control(b, ph, pos + dir * 8 + Vector(0, 0, 1), Vector(0, 0, 1), dir, dt, "mover: walks off the edge")
						return true
					end
					if ok then why[#why + 1] = ahead .. ":high " .. math.Round(lz - pos.z) end
					-- (not given up at the first open spot: right past the edge the landing feet still found the plate)
				end
			end
			b.MoverDropWhy = table.concat(why, ", ")
		end
	end
	-- SEAM: its waypoint on another face, near, no nearer for 0.5 s (not on a floor: there the felt walk takes a curb)
	if wm and up.z <= 0.7 and wm:Dot(up) < 0.6 and dwp < 40 and stuck > 0.5 then
		local left = b.MoverLeft
		if left and now > left.t then left, b.MoverLeft = nil, nil end
		if not (left and wm:Dot(left.n) > 0.8) then
			local t = tr(b, wp + wm * 10, wp - wm * 20)
			if t.Hit and not t.StartSolid and t.HitNormal:Dot(wm) > 0.8 then
				local p, u, f = R.TransitTo(b, pos, up, t.HitPos, t.HitNormal)
				if p then
					b.MoverLeft = { n = Vector(up), t = now + 2.5 }
					-- (held on the new face after the corner move: the felt walk pulled it straight back under the ceiling it
					-- came from - the north building's slab edge, 6 times in 10 s)
					b.MoverFace = { n = Vector(t.HitNormal), p = Vector(t.HitPos), wp = wp, t = now + 1.2 }
					P.t = now
					R.Stat("mover: seam - onto its waypoint's face")
					control(b, ph, p, u, f, dt, "mover: seam")
					return true
				end
			end
		end
	end
	local speed = (b.RepSpeed or 150) * (b.SpeedMul or 1)
	-- ON THE NEW FACE: after a seam, for 1.2 s (or till its waypoint), straight along that face's plane to the waypoint
	local Fc = b.MoverFace
	if Fc and (now > Fc.t or Fc.wp ~= wp or b.Transit) then if now > Fc.t or Fc.wp ~= wp then b.MoverFace = nil end Fc = nil end
	if Fc then
		local n = Fc.n
		local to = wp - pos
		to = to - n * to:Dot(n)
		local dl = to:Length()
		if dl > 4 then
			local dir = to / dl
			local q = pos + dir * math.min(speed * 0.08, dl)
			local g = tr(b, q + n * 12, q - n * 20)
			if g.Hit and not g.StartSolid and g.HitNormal:Dot(n) > 0.7 then
				control(b, ph, g.HitPos, g.HitNormal, dir, dt, "mover: on the new face")
				return true
			end
		end
		b.MoverFace = nil
	end
	-- FOLLOW: along the felt map
	local ft, fu, ff = R.FieldWalk(b, pos, up, fwd, wp, speed, dt)
	if not ft then b.MoverOn = nil return no(b, "felt walk found no step") end
	-- EDGE: its steps go back and forth (14 up, 14 down, ... - on a wall just under a roof's lip, its goal on the roof:
	-- the felt walk lands on one side of the edge, then the other; the author saw it "hanging on the lip, glitched
	-- with its back over it"). 4 turn-rounds within 0.6 s: round the edge in one corner move onto the face beyond it,
	-- towards its waypoint
	local stp = ft - pos
	local O = b.MoverOsc
	if not O then O = { n = 0, t = now } b.MoverOsc = O end
	if O.last and stp:LengthSqr() > 4 and O.last:Dot(stp) < -0.5 * O.last:Length() * stp:Length() then
		if now - O.t > 0.6 then O.n, O.t = 0, now end
		O.n = O.n + 1
	end
	if stp:LengthSqr() > 4 then O.last = stp end
	if O.n >= 4 then
		O.n, O.t, O.last = 0, now, nil
		local f = wp - pos
		f = f - up * f:Dot(up)
		if f:LengthSqr() > 1 then
			f:Normalize()
			-- the face beyond the edge: its normal about f, lying behind the face it is on (over a roof, from the wall)
			for _, d in ipairs({ 24, 36, 12 }) do
				local st = pos + f * d - up * 14
				local t = tr(b, st + f * 4, st - f * 40)
				if t.Hit and not t.StartSolid and t.HitNormal:Dot(f) > 0.6 then
					local p2, u2, f2 = R.TransitTo(b, pos, up, t.HitPos, t.HitNormal)
					if p2 then
						R.Stat("mover: round the edge (it went back and forth)")
						b.MoverLeft = { n = Vector(up), t = now + 2.5 }
						control(b, ph, p2, u2, f2, dt, "mover: round the edge")
						return true
					end
				end
			end
			R.Stat("mover: back and forth, no face beyond the edge found")
		end
	end
	-- (its body not round a sharp edge the felt map goes round - stood against a wall under its top: rolls round)
	local bu = b:GetUp()
	if bu:Dot(fu) < 0.7 then
		local st = b.MoverBody
		if not st or st.p:DistToSqr(pos) > 16 then b.MoverBody = { p = Vector(pos), t = now }
		elseif now - st.t > 0.3 then
			b.MoverBody = nil
			local t = tr(b, ft + fu * 8, ft - fu * 20)
			if t.Hit and not t.StartSolid and t.HitNormal:Dot(bu) < 0.7 then
				local p, u, f = R.TransitTo(b, pos, bu, t.HitPos, t.HitNormal)
				if p then control(b, ph, p, u, f, dt, "mover: body round the edge") return true end
			end
		end
	else
		b.MoverBody = nil
	end
	-- (a step at most 26 high in front of it on a floor, no nearer for 0.3 s: up onto its top - curbs. Measured from the
	-- floor under it, not from its middle - that walks 14 above the floor, so a curb under 16 never counted and the
	-- bugs stood against freespace13's stone curbs. Its own up, not the felt walk's: at the curb the felt walk
	-- already points up the curb's side)
	if up.z > 0.7 and stuck > 0.3 then
		local dir = Vector(wp.x - pos.x, wp.y - pos.y, 0)
		if dir:LengthSqr() > 100 then
			dir:Normalize()
			-- (the map and props: a prop's step was not seen)
			local g = tr(b, pos + Vector(0, 0, 4), pos - Vector(0, 0, 40))
			if g.Hit and not g.StartSolid then
				local gz = g.HitPos.z
				for _, ahead in ipairs({ 16, 26, 36 }) do
					local q = pos + dir * ahead
					local t = tr(b, Vector(q.x, q.y, gz + 34), Vector(q.x, q.y, gz - 4))
					if t.Hit and not t.StartSolid and t.HitNormal.z > 0.7 and t.HitPos.z > gz + 3 and t.HitPos.z < gz + 26 then
						R.Stat("mover: up the step")
						control(b, ph, t.HitPos + Vector(0, 0, (R.Field and R.Field.H) or 14), Vector(0, 0, 1), dir, dt, "mover: up the step")
						return true
					end
				end
			end
		end
	end
	-- (risen before a step ahead, maps and props alike - sv_walk.lua R.StepGlide)
	if R.StepGlide and fu.z > 0.7 then ft = R.StepGlide(b, ft, fu, ff) else b.GlideAdd = nil end
	control(b, ph, ft, fu, ff, dt, b.GlideAdd and "mover: follow, gliding up" or "mover: follow")
	-- (on an even face, its body on it, its waypoint not close: a crowded swarm may go on like this for a tick or two, M.Shared)
	if not b.GlideAdd and up:Dot(fu) > 0.999 and bu:Dot(fu) > 0.97 and fwd:Dot(ff) > 0.98 and dwp > 60 and stuck < 0.3 then
		b.ShareN, b.ShareTick = 0, engine.TickCount()
	end
	return true
end

-- Stall log (a player played fs13: a bug hung at a curb and in a corner, wobbling): while the file
-- data/agp_replicators/stalllog_on.txt exists, written to data/agp_replicators/stall_log.txt with
-- what moves the bug and why: STILL a bug that moved less than 12 in
--  3 s WOBBLE a bug that went more than 120 in
--  3 s but ended less than 30 from where it was (back and forth) BENT a bug whose body is more than 60
--  degrees off the surface it walks on for 1 s (hanging over a lip, on its back) QUEEN a queen that moved less than 12 in
--  5 s while she has somewhere to go, or lies tipped over and every 10 s one line how many bugs the
-- mover walks. Off (no file): nothing runs but one file check every 2 s.
M.logOn, M.logChk = M.logOn or false, 0
local function desc(b, p, now)
	local u = b.RepUp or b:GetUp()
	local bu = b:GetUp()
	local tg = b.Target
	return string.format("bug %d at %d %d %d  state %s  mover %s (%s)  walk: %s  felt: %s  walk up %.2f %.2f %.2f  body up %.2f %.2f %.2f  goal %s  moveTo %s  route %s  target %s  props %s  transit %s  ceil %s",
		b:EntIndex(), p.x, p.y, p.z, tostring(b.State), tostring(b.MoverOn == true), tostring(b.MoverWhy), tostring(b.WalkWhy), tostring(b.FieldWhy),
		u.x, u.y, u.z, bu.x, bu.y, bu.z, b.Goal and string.format("%d %d %d", b.Goal.x, b.Goal.y, b.Goal.z) or "-", b.MoveTo and string.format("%d %d %d (%.0f away)", b.MoveTo.x, b.MoveTo.y, b.MoveTo.z, b.MoveTo:Distance(p)) or "-",
		b.Route and (#b.Route .. "@" .. tostring(b.RouteI) .. (b.Route.felt and " felt" or "")) or "-", IsValid(tg) and tg:GetClass() or "-", tostring(b.FieldProps), tostring(b.Transit ~= nil), tostring(b.CeilWhy)) .. (b.MoverDropWhy and ("  drop: " .. b.MoverDropWhy) or "") .. string.format("  falling %s jump %s righting %s fallT %.1f vel %d", tostring(b.Falling), tostring(b.Jumping), tostring(b.RightUntil and CurTime() < b.RightUntil), b.FallT and (CurTime() - b.FallT) or -1, IsValid(b:GetPhysicsObject()) and b:GetPhysicsObject():GetVelocity():Length() or -1)
end
timer.Create("AGPRepStallLog", 0.5, 0, function()
	local now = CurTime()
	if now > M.logChk then M.logChk = now + 2 M.logOn = file.Exists("agp_replicators/stalllog_on.txt", "DATA") end
	if not M.logOn then return end
	local lines = {}
	local ts = os.date("%H:%M:%S")
	local cnt, own, why = 0, 0, {}
	for b in pairs(R.bugs or {}) do
		if IsValid(b) then
			cnt = cnt + 1
			if b.MoverOn then own = own + 1 else local w = tostring(b.MoverWhy) why[w] = (why[w] or 0) + 1 end
			local p = b:GetPos()
			-- STILL
			local s = b.StallLog
			if not s or s.p:DistToSqr(p) > 144 then b.StallLog = { p = p, t = now, lt = 0 }
			elseif now - s.t > 3 and now - s.lt > 2 then
				s.lt = now
				lines[#lines + 1] = string.format("%s  STILL %.0f s  ", ts, now - s.t) .. desc(b, p, now)
			end
			-- WOBBLE
			local w = b.WobLog
			if not w then w = { p0 = p, t0 = now, len = 0, lp = p } b.WobLog = w
			else
				w.len = w.len + p:Distance(w.lp) w.lp = p
				if now - w.t0 >= 3 then
					if w.len > 120 and p:Distance(w.p0) < 30 and not b.Eating then
						lines[#lines + 1] = string.format("%s  WOBBLE went %.0f in 3 s, ended %.0f from the start  ", ts, w.len, p:Distance(w.p0)) .. desc(b, p, now)
					end
					b.WobLog = { p0 = p, t0 = now, len = 0, lp = p }
				end
			end
			-- BENT
			local u = b.RepUp
			if u and b:GetUp():Dot(u) < 0.5 then
				b.BentT = b.BentT or now
				if now - b.BentT >= 1 and now - (b.BentLT or 0) > 2 then
					b.BentLT = now
					lines[#lines + 1] = string.format("%s  BENT %.1f s, %.0f deg off  ", ts, now - b.BentT, math.deg(math.acos(math.Clamp(b:GetUp():Dot(u), -1, 1)))) .. desc(b, p, now)
				end
			else b.BentT = nil end
		end
	end
	for q in pairs(R.queens or {}) do
		if IsValid(q) then
			local p = q:GetPos()
			local s = q.StallLog
			if not s or s.p:DistToSqr(p) > 144 then q.StallLog = { p = p, t = now, lt = 0 } s = nil end
			local tipped = q:GetUp().z < 0.5
			if (s and now - s.t > 5 and (q.Goal or q.MoveTo) and now - s.lt > 3) or (tipped and now - (q.TipLT or 0) > 3) then
				if s then s.lt = now end
				if tipped then q.TipLT = now end
				local qu = q:GetUp()
				local g = q.Goal or q.MoveTo
				lines[#lines + 1] = string.format("%s  QUEEN %d at %d %d %d  %s  state %s  up %.2f %.2f %.2f  goal %s  walk %s  why %s", ts, q:EntIndex(), p.x, p.y, p.z,
					tipped and "TIPPED" or string.format("still %.0f s", now - s.t), tostring(q.State), qu.x, qu.y, qu.z, g and string.format("%d %d %d (%.0f away)", g.x, g.y, g.z, g:Distance(p)) or "-", tostring(q.WalkWhy), tostring(q.Why or q.QueenWhy))
			end
		end
	end
	if now > (M.logSumT or 0) then
		M.logSumT = now + 10
		local w = {} for k, n in pairs(why) do w[#w + 1] = k .. ": " .. n end
		lines[#lines + 1] = ts .. "  SUMMARY " .. cnt .. " bugs, mover walks " .. own .. "; the others: " .. table.concat(w, "; ")
	end
	if #lines > 0 then file.Append("agp_replicators/stall_log.txt", table.concat(lines, "\n") .. "\n") end
end)
