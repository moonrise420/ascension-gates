--[[
	Portal doorway (Ascension Gates)
	A flat, see-through doorway that links two places, TARDIS style: you see the other side through it, and when your
	eyes cross it you walk on over there with the same speed and view direction, so the crossing is not noticed.
	Used for ship interiors kept apart from the flying hull (agp_hatak: hangar mouth <-> interior hangar).

	Each portal has a partner (Exit) and two frames: FrameSelf (the entity it belongs to, e.g. the flying hull) and
	FrameExit (the partner's entity, e.g. the interior). A point is carried over by keeping its position relative to the
	frames: FrameExit:LocalToWorld(FrameSelf:WorldToLocal(p)). The portal's front (+X) faces the side you walk in from.
	Optional map (MapPos / MapAng, SetMap): the frame-local point is moved and turned on the way, so the partner can
	sit somewhere else in its frame (the Ha'tak's glider slots lead into a glider bay elsewhere in the interior). The
	partner then needs the inverse map (SetMapInverseOf).

	A frame can be a "hidden volume" (ENT.AGPHiddenVolume = true on the client): everything inside its box is only
	drawn through a portal, or when you stand inside it yourself (an interior parked in the sky stays invisible).
	Not in the spawn menu; ships create their portals.

	Seamless crossing, as World Portals / the TARDIS addon do it: the doorway is drawn as a box reaching DEPTH units
	behind its plane, so the far side still fills the view while the eye is past the plane but the server has not
	moved the player yet; the far side is rendered at full screen size with the normal tone mapping; a tilted ship's
	roll is turned out of the view smoothly after crossing.
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Portal doorway"
ENT.Author = "Ascension Gates"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.DEPTH = 64   -- the drawn box reaches this far behind the doorway's plane

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Exit")
	self:NetworkVar("Entity", 1, "FrameSelf")
	self:NetworkVar("Entity", 2, "FrameExit")
	self:NetworkVar("Float", 0, "PortalWidth")
	self:NetworkVar("Float", 1, "PortalHeight")
	self:NetworkVar("Vector", 0, "MapPos")
	self:NetworkVar("Angle", 0, "MapAng")
	self:NetworkVar("Bool", 0, "ViewOnly")   -- a window: shows the other side, nothing passes through
end

-- frame-local point / angle through the map (identity when none is set)
function ENT:MapLocal(lp, la)
	local mp, ma = self:GetMapPos(), self:GetMapAng()
	if (mp:IsZero() and ma:IsZero()) then return lp, la end
	return LocalToWorld(lp, la or Angle(0, 0, 0), mp, ma)
end

-- carry a world position / direction / angle over to the partner's side
function ENT:CarryPos(p)
	local lp = self:MapLocal(self:GetFrameSelf():WorldToLocal(p))
	return self:GetFrameExit():LocalToWorld(lp)
end
function ENT:CarryAng(a)
	local _, la = self:MapLocal(Vector(0, 0, 0), self:GetFrameSelf():WorldToLocalAngles(a))
	return self:GetFrameExit():LocalToWorldAngles(la)
end
function ENT:CarryDir(v)
	local o = self:GetFrameSelf():GetPos()
	return self:CarryPos(o + v) - self:CarryPos(o)
end
function ENT:Linked()
	return IsValid(self:GetExit()) and IsValid(self:GetFrameSelf()) and IsValid(self:GetFrameExit())
end
-- is a world point within the doorway's rectangle (ignoring depth)?
function ENT:InRect(p, pad)
	local l = self:WorldToLocal(p)
	pad = pad or 0
	return math.abs(l.y) <= self:GetPortalWidth() / 2 + pad and math.abs(l.z) <= self:GetPortalHeight() / 2 + pad, l
end

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetModel("models/hunter/plates/plate.mdl")
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_NONE)
		self:SetNotSolid(true)
		self:DrawShadow(false)
		self.Side = {}   -- player -> was the eye in front of the doorway last move?
	end
	function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
	-- map so that this portal's own spot (pos, yaw in its frame) comes out at the partner's spot, facing out of it
	function ENT:SetMapTo(fromPos, fromYaw, toPos, toYaw)
		local ang = Angle(0, toYaw + 180 - fromYaw, 0)
		local pos = toPos - LocalToWorld(fromPos, Angle(0, 0, 0), Vector(0, 0, 0), ang)
		self:SetMapPos(pos); self:SetMapAng(ang)
	end
	function ENT:SetMapInverseOf(P)
		local pos, ang = WorldToLocal(Vector(0, 0, 0), Angle(0, 0, 0), P:GetMapPos(), P:GetMapAng())
		self:SetMapPos(pos); self:SetMapAng(ang)
	end
	function ENT:PhysgunPickup() return false end
	function ENT:CanTool() return false end
	function ENT:CanProperty() return false end

	util.AddNetworkString("AGP_PortalRoll")
	util.AddNetworkString("AGP_PortalCross")

	-- does the player fit at pos (not in a wall, floor or closed door)?
	local function fits(ply, pos)
		local mn, mx = ply:GetHull()
		if (ply:Crouching()) then mn, mx = ply:GetHullDuck() end
		local tr = util.TraceHull({ start = pos, endpos = pos, mins = mn, maxs = mx, filter = ply, mask = MASK_PLAYERSOLID })
		return not tr.StartSolid
	end

	-- walk through: checked after every player move, using the eye position (so the view swaps exactly at the doorway)
	hook.Add("FinishMove", "AGP_Portal", function(ply, mv)
		if (not ply:Alive() or ply:InVehicle()) then return end
		local eye = mv:GetOrigin() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())
		for _, P in ipairs(ents.FindByClass("agp_portal")) do
			if (P:Linked() and not P:GetViewOnly()) then
				local inRect, l = P:InRect(eye, 8)
				local front = l.x > 0
				local was = P.Side[ply]
				P.Side[ply] = front
				if (was and not front and inRect and math.abs(l.x) < 200 and (ply.AGPPortalWait or 0) < CurTime()) then
					local E = P:GetExit()
					local np = P:CarryPos(mv:GetOrigin())
					-- the other side must have room: a floor a bit higher lifts you up, a closed door there is a wall here
					local free = fits(ply, np)
					for dz = 4, 20, 4 do
						if (free) then break end
						if (fits(ply, np + Vector(0, 0, dz))) then np = np + Vector(0, 0, dz); free = true end
					end
					if (not free) then
						mv:SetOrigin(mv:GetOrigin() + P:GetForward() * (2 - l.x))   -- back in front of the doorway
						local v, n = mv:GetVelocity(), P:GetForward()
						mv:SetVelocity(v - n * math.min(0, v:Dot(n)))
						P.Side[ply] = true
						return
					end
					local nv = P:CarryDir(mv:GetVelocity())
					local na = P:CarryAng(ply:EyeAngles())
					if (math.abs(na.r) > 1) then   -- from a tilted hull into the upright interior (or back): turn the roll out slowly
						net.Start("AGP_PortalRoll"); net.WriteFloat(na.r); net.Send(ply)
					end
					na.r = 0
					-- the client mends the frames in which the new view angles are in but the view still stands on the old
					-- side (or the other way round): they do not arrive in the same frame (singleplayer: the origin is
					-- interpolated, the angles are not)
					net.Start("AGP_PortalCross"); net.WriteEntity(P); net.WriteEntity(E); net.WriteAngle(na); net.Send(ply)
					mv:SetOrigin(np)
					mv:SetVelocity(nv)
					ply:SetEyeAngles(na)
					-- a teleport, not a movement: no interpolation between the old and the new spot (else a visible "blop")
					ply:AddEffects(EF_NOINTERP)
					timer.Simple(0.1, function() if IsValid(ply) then ply:RemoveEffects(EF_NOINTERP) end end)
					E.Side[ply] = true   -- arrived in front of the partner
					ply.AGPPortalWait = CurTime() + 0.2
					hook.Run("AGP_PortalCrossed", ply, P, E)
					return
				end
			end
		end
	end)

	-- everything else that moves (props, NPCs, grenades, rockets, bolts, vehicles): carried over when its centre
	-- crosses the doorway, with its speed and spin; fixed parts of the ship (frozen, parented) stay where they are
	local function movable(e, P)
		if (e:IsPlayer() or e:IsWeapon() or e:GetClass() == "agp_portal" or IsValid(e:GetParent())) then return false end
		if (e == P:GetFrameSelf() or e == P:GetFrameExit() or e:IsWorld()) then return false end
		if (e:IsNPC() or e:IsNextBot() or e:IsVehicle()) then return true end
		local mt = e:GetMoveType()
		if (mt == MOVETYPE_VPHYSICS) then
			local ph = e:GetPhysicsObject()
			return IsValid(ph) and ph:IsMotionEnabled()
		end
		return mt == MOVETYPE_FLY or mt == MOVETYPE_FLYGRAVITY or mt == MOVETYPE_STEP or mt == MOVETYPE_WALK
	end
	local function carry(P, e)
		local E = P:GetExit()
		local np, na = P:CarryPos(e:GetPos()), P:CarryAng(e:GetAngles())
		local ph = e:GetMoveType() == MOVETYPE_VPHYSICS and e:GetPhysicsObject()
		if (IsValid(ph)) then
			local v = P:CarryDir(ph:GetVelocity())   -- the spin is in the object's own axes and needs no change
			e:SetPos(np); e:SetAngles(na)
			ph:SetPos(np); ph:SetAngles(na)
			ph:SetVelocityInstantaneous(v)
			ph:Wake()
		else
			local v = P:CarryDir(e:GetVelocity())
			e:SetPos(np); e:SetAngles(na)
			if (e:IsNPC()) then e:SetLocalVelocity(v) else e:SetVelocity(v) end
		end
		-- a teleport, not a movement, for the clients too (filmed on a hosted game: a glider carried through a launch slot
		-- stood still for ~6 frames on the client, its pilot's camera with it)
		e:AddEffects(EF_NOINTERP)
		timer.Simple(0.1, function() if IsValid(e) then e:RemoveEffects(EF_NOINTERP) end end)
		E.ESide = E.ESide or {}
		E.ESide[e] = true
		e.AGPPortalWait = CurTime() + 0.2
		hook.Run("AGP_PortalCrossed", e, P, E)
	end
	hook.Add("Tick", "AGP_PortalEnts", function()
		for _, P in ipairs(ents.FindByClass("agp_portal")) do
			if (P:Linked() and not P:GetViewOnly()) then
				P.ESide = P.ESide or {}
				local r = math.max(P:GetPortalWidth(), P:GetPortalHeight()) * 0.75 + 100
				local now = {}
				for _, e in ipairs(ents.FindInSphere(P:GetPos(), r)) do
					if (movable(e, P)) then
						local c = e:WorldSpaceCenter()
						local inRect, l = P:InRect(c, 4)
						local front = l.x > 0
						now[e] = front
						if (P.ESide[e] and not front and inRect and (e.AGPPortalWait or 0) < CurTime()) then
							carry(P, e)
							now[e] = nil
						end
					end
				end
				P.ESide = now
			end
		end
	end)

	-- bullets: a shot that reaches the doorway before hitting anything goes on from the partner's side
	hook.Add("EntityFireBullets", "AGP_Portal", function(shooter, data)
		if (data.AGPPortalHop or 0) >= 4 then return end
		-- (a shot aboard a flying StarCore ship: the others on it are put right before anything asks where they are)
		if StarCore and StarCore.ShotAboard then StarCore.ShotAboard(shooter) end
		local src, dir = data.Src, data.Dir:GetNormalized()
		local dist = data.Distance or 56756
		local tr = util.TraceLine({ start = src, endpos = src + dir * dist, filter = { shooter, data.IgnoreEntity }, mask = MASK_SHOT })
		for _, P in ipairs(ents.FindByClass("agp_portal")) do
			if (P:Linked() and not P:GetViewOnly()) then
				local n = P:GetForward()
				local denom = dir:Dot(n)
				if (denom < -0.001) then   -- coming at its front
					local t = (P:GetPos() - src):Dot(n) / denom
					if (t > 1 and t < dist and t < tr.Fraction * dist + 1) then
						local hit = src + dir * t
						if (P:InRect(hit)) then
							data.Src = P:CarryPos(hit) + P:CarryDir(dir) * 1
							data.Dir = P:CarryDir(dir)
							data.Distance = dist - t
							data.IgnoreEntity = nil
							data.AGPPortalHop = (data.AGPPortalHop or 0) + 1
							return true
						end
					end
				end
			end
		end
	end)

	-- the other side has to be in the player's view set to be drawn through the doorway
	hook.Add("SetupPlayerVisibility", "AGP_Portal", function(ply)
		local eye = ply:EyePos()
		for _, P in ipairs(ents.FindByClass("agp_portal")) do
			if (P:Linked() and P:GetPos():DistToSqr(eye) < 12000 * 12000) then
				AddOriginToPVS(P:GetExit():GetPos())
			end
		end
	end)
end

if CLIENT then
	local matView = CreateMaterial("AGPPortalView", "GMODScreenspace", {
		["$basetexturetransform"] = "center .5 .5 scale -1 -1 rotate 0 translate 0 0",
		["$texturealpha"] = "0",
		["$vertexalpha"] = "1",
	})
	local DRAWDIST = 12000
	local MAXVIEWS = 4   -- doorways drawn at the same time (the nearest ones)

	function ENT:Initialize()
		self:SetRenderBounds(Vector(-self.DEPTH - 2, -1000, -1000), Vector(8, 1000, 1000))
	end

	function ENT:Think()
		local w, h = self:GetPortalWidth(), self:GetPortalHeight()
		if (w ~= self.BW or h ~= self.BH) then
			self.BW, self.BH = w, h
			self:SetRenderBounds(Vector(-self.DEPTH - 2, -w / 2, -h / 2), Vector(8, w / 2, h / 2))
		end
	end

	-- should this doorway show the other side for a camera at pos? In front of it, or inside its box behind the plane
	-- (the eye has crossed, the server moves us over in a moment)
	local function wants(P, pos)
		if (not P:Linked() or P:IsDormant()) then return false end
		local fs = P:GetFrameSelf()
		if (IsValid(fs) and fs:GetNWBool("AGPCloaked")) then return false end   -- a cloaked ship shows no doorways
		if (P:GetPos():DistToSqr(pos) > DRAWDIST * DRAWDIST) then return false end
		local inRect, l = P:InRect(pos)
		if (l.x > 0) then return true end
		return not P:GetViewOnly() and inRect and l.x > -P.DEPTH + 2
	end

	-- a tilted ship: the roll left over after crossing is turned out of the view, not cut off at once
	local roll
	net.Receive("AGP_PortalRoll", function() roll = net.ReadFloat() end)
	-- the frame(s) right after crossing: the server moved us and turned our view (the two frames - hull and interior -
	-- face different ways), but the client does not get both at once: in singleplayer the view origin is interpolated
	-- (it comes a frame or more later), the new angles are there at once. Until both are in, the view is turned to
	-- match the side the view origin still stands on - no frame looks the wrong way (the blink when crossing).
	-- (filmed frame by frame: the blink) the view ORIGIN is not moved at once either: the engine slides it from the
	-- old spot to the new one over about 0.1 s (EF_NOINTERP does not stop that for the local player), and the two
	-- sides of a doorway can be far apart on the map (the Ha'tak's interior hangs in the sky) - 2 to 3 frames showed the
	-- sky between them. crossO: for that time a view that stands near neither doorway is put where the player really is
	-- (the network origin, not slid), on the new side.
	local cross, crossO
	net.Receive("AGP_PortalCross", function()
		local P, E, na = net.ReadEntity(), net.ReadEntity(), net.ReadAngle()
		if (not IsValid(P) or not IsValid(E) or not P:Linked() or not E:Linked()) then cross = nil crossO = nil return end
		crossO = { P = P, E = E, till = CurTime() + 0.5 }
		local oa = E:CarryAng(na)   -- the same view on the old side
		if (math.abs(math.AngleDifference(oa.y, na.y)) < 3 and math.abs(math.AngleDifference(oa.p, na.p)) < 3) then cross = nil return end   -- frames face the same way
		cross = { P = P, E = E, na = na, oa = oa, till = CurTime() + 0.5 }
	end)
	local function near(P, pos)
		local inRect, l = P:InRect(pos, 64)
		return inRect and math.abs(l.x) < 200
	end
	-- The view normally trails the real eye a little (viewLag, measured every frame); across the doorway it is kept at the
	-- real eye plus that trail carried over, so the walk goes on without a jump - also not the 18-unit drop of the
	-- engine's stair smoothing, which takes the doorway for a step. Once the engine's own view stands on the new side
	-- too, the two are blended over 0.2 s.
	local viewLag, lastNetEye
	local function netEye(ply)
		return ply:GetNetworkOrigin() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())
	end
	local function mendOrigin(ply, pos)
		-- only for a player who walks through: in a seat or a craft the camera is the craft's (see AGP_PortalViewEnt)
		if (ply:InVehicle() or ply:GetViewEntity() ~= ply or ply:GetObserverMode() ~= OBS_MODE_NONE) then crossO, lastNetEye = nil, nil return end
		local eye = netEye(ply)
		-- the real position jumped through a doorway: a crossing, also when the server's message is not in yet
		if (not crossO and lastNetEye and eye:DistToSqr(lastNetEye) > 300 * 300) then
			for _, P in ipairs(ents.FindByClass("agp_portal")) do
				if (P:Linked() and not P:GetViewOnly() and near(P, lastNetEye) and near(P:GetExit(), eye)) then
					crossO = { P = P, E = P:GetExit(), till = CurTime() + 0.5 }
					break
				end
			end
		end
		lastNetEye = eye
		if (crossO and (CurTime() > crossO.till or not IsValid(crossO.P) or not IsValid(crossO.E))) then crossO = nil end
		if (not crossO) then viewLag = pos - eye return end
		if (not near(crossO.E, eye)) then return end   -- the message came first, the real position is not over yet
		crossO.lag = crossO.lag or crossO.P:CarryDir(viewLag or Vector(0, 0, 0))
		local want = eye + crossO.lag
		-- the trail can reach back past the far doorway (sprinting: the real eye is just over, the view a few units
		-- behind it): there, behind the far doorway, is the void outside the room - a black frame, 3 of 12 sprints
		-- (filmed). That spot is still on the near side: the view stays there, where the doorway shows it.
		if (crossO.E:WorldToLocal(want).x < 1) then want = crossO.E:CarryPos(want) end
		if (near(crossO.E, pos) and crossO.E:WorldToLocal(pos).x > 1 and pos:DistToSqr(want) < 40 * 40) then   -- the engine's view is over as well: hand back
			crossO.blend = crossO.blend or CurTime()
			local f = math.Clamp((CurTime() - crossO.blend) / 0.2, 0, 1)
			if (f >= 1) then crossO = nil return end
			return LerpVector(f, want, pos)
		end
		return want
	end
	-- a camera that belongs to a craft (the chase camera behind it, the cockpit eye in front of its centre): when the line
	-- from the craft to its camera passes through a doorway, the camera really stands on the doorway's other side, so it
	-- is moved through with its angles. A glider leaving a Ha'tak launch slot: its chase camera, 750 behind, was inside
	-- the hull's model (filmed); now it stays in the glider bay and sees the glider through the slot, as the moment
	-- before. Used by the AGP craft's cameras (sg_vehicle_base, the glider's cockpit view). Near a
	-- doorway the camera also stops at the walls of the ship it belongs to (hull, interior) and the map: once the glider
	-- is a little way out, the line back to its chase camera runs through the hull beside the slot (filmed too). Only
	-- there; elsewhere the craft's camera is as it always was.
	local function clipCam(from, to, frames)
		local tr = util.TraceLine({ start = from, endpos = to, mask = MASK_SOLID,
			filter = function(e) return e:IsWorld() or frames[e] == true end })
		if (tr.Hit and not tr.StartSolid) then return tr.HitPos + tr.HitNormal * 8 end
		return to
	end
	-- A chase camera sits above and behind its craft, so the line back to it soon misses the doorway's opening as the
	-- craft flies on (then the hull is in between and the camera would pop in close). While the camera is carried, that
	-- line is kept inside the opening: the camera is lowered towards the craft's axis, a little more as the craft gets
	-- further out, until the camera itself is through; then it goes back to its usual height over 0.3 s.
	local camState
	function AGP_PortalCamera(anchor, origin, angles)
		local frames, any = {}, false
		local st = camState
		if (st and (not IsValid(st.P) or CurTime() - st.seen > 0.5)) then st = nil; camState = nil end
		for _, P in ipairs(ents.FindByClass("agp_portal")) do
			if (P:Linked() and not P:GetViewOnly() and P:GetPos():DistToSqr(anchor) < 4000 * 4000) then
				frames[P:GetFrameSelf()] = true; frames[P:GetFrameExit()] = true; any = true
				local la, lo = P:WorldToLocal(anchor), P:WorldToLocal(origin)
				local w, h = P:GetPortalWidth() / 2, P:GetPortalHeight() / 2
				if (la.x > 0 and lo.x < 0) then
					local hit = la + (lo - la) * (la.x / (la.x - lo.x))
					local inside = math.abs(hit.y) <= w and math.abs(hit.z) <= h
					if (inside or (st and st.P == P and not st.out)) then
						-- the line from the craft to the camera through the opening (moved into it by up to the margin)
						local m = math.min(64, w * 0.45, h * 0.45)   -- well inside: the camera passes the frame with room
						local xp = Vector(0, math.Clamp(hit.y, -w + m, w - m), math.Clamp(hit.z, -h + m, h - m))
						local lo2 = la + (xp - la):GetNormalized() * (lo - la):Length()
						camState = { P = P, off = lo2 - la, seen = CurTime() }
						return clipCam(P:CarryPos(P:LocalToWorld(xp)), P:CarryPos(P:LocalToWorld(lo2)), frames), P:CarryAng(angles)
					end
				elseif (st and st.P == P and la.x > 0 and lo.x >= 0) then
					-- the camera came through the opening as well: back to its usual place, smoothly
					st.out = st.out or CurTime()
					st.seen = CurTime()
					local f = math.Clamp((CurTime() - st.out) / 0.3, 0, 1)
					if (f >= 1) then camState = nil else
						local off = LerpVector(f * f * (3 - 2 * f), st.off, lo - la)
						return clipCam(anchor, P:LocalToWorld(la + off), frames), angles
					end
				end
			end
		end
		if (any) then return clipCam(anchor, origin, frames), angles end
		return origin, angles
	end

	-- a player looking through an entity that went through a doorway (a glider's pilot, its chase camera): his aim is
	-- turned with it in the same frame, or the camera behind the craft swings round by the doorway's turn. The craft's
	-- camera calls this before it reads the aim and uses the angles it returns: GetAimVector() shows the turn one frame
	-- later (filmed). Every Think calls it as well (a craft without such a camera).
	local lastVE, lastVEPos, turnedFrame, turnedAng
	function AGP_PortalTurnAim()
		local ply = LocalPlayer()
		if (not IsValid(ply)) then return end
		if (turnedFrame == FrameNumber()) then return turnedAng end
		local ve = ply:GetViewEntity()
		if (not IsValid(ve) or ve == ply) then lastVE = nil return end
		local pos = ve:GetPos()
		if (ve == lastVE and lastVEPos and pos:DistToSqr(lastVEPos) > 300 * 300) then
			for _, P in ipairs(ents.FindByClass("agp_portal")) do
				if (P:Linked() and not P:GetViewOnly() and P:CarryPos(lastVEPos):DistToSqr(pos) < 400 * 400) then
					local a = P:CarryAng(ply:EyeAngles()); a.r = 0
					ply:SetEyeAngles(a)
					turnedFrame, turnedAng = FrameNumber(), a
					break
				end
			end
		end
		lastVE, lastVEPos = ve, pos
		if (turnedFrame == FrameNumber()) then return turnedAng end
	end
	hook.Add("Think", "AGP_PortalViewEnt", AGP_PortalTurnAim)
	local function turn(a, b) return math.abs(math.AngleDifference(a.y, b.y)) + math.abs(math.AngleDifference(a.p, b.p)) end
	local function mendAngles(pos, ang)
		if (not cross) then return end
		if (CurTime() > cross.till or not IsValid(cross.P) or not IsValid(cross.E)) then cross = nil return end
		local turned = turn(ang, cross.na) < turn(ang, cross.oa)   -- the new view angles are in
		if (near(cross.P, pos)) then   -- the view still stands on the old side
			if (turned) then return cross.E:CarryAng(ang) end
		elseif (near(cross.E, pos)) then   -- arrived
			if (not turned) then return cross.P:CarryAng(ang) end
			cross = nil
		end
	end
	local mended   -- this frame's mended view (the view model follows it)
	local mendedPos
	hook.Add("CalcView", "AGP_PortalRoll", function(ply, pos, ang, fov)
		mended, mendedPos = nil, nil
		local mo = mendOrigin(ply, pos)
		if (mo) then pos = mo; mendedPos = mo end
		local ma = mendAngles(pos, ang)
		if (ma) then ang = ma; mended = ma end
		if (roll) then
			roll = math.Approach(roll, 0, FrameTime() * (0.5 + math.abs(roll)) * 3.5)
			if (roll == 0) then roll = nil end
		end
		if (not roll and not ma and not mo) then return end
		return { origin = pos, angles = Angle(ang.p, ang.y, roll or ang.r), fov = fov }
	end)
	hook.Add("CalcViewModelView", "AGP_Portal", function(wep, vm, oldPos, oldAng, pos, ang)
		if (mended or mendedPos) then return mendedPos or pos, mended or ang end
	end)

	-- hidden volumes: interiors parked somewhere on the map, only drawn through a doorway or from inside
	local function inBox(p, mn, mx) return p.x >= mn.x and p.x <= mx.x and p.y >= mn.y and p.y <= mx.y and p.z >= mn.z and p.z <= mx.z end
	-- only entities we hid ourselves are shown again (things hidden on purpose stay hidden)
	local hidden, seen = {}, {}
	-- the volume's own big model - the walls - is drawn by hand: after arriving from far away (a gate trip) the engine
	-- left it out of what it draws, although it was there and not hidden. shown[f] = this volume is visible in the view
	-- being drawn now; the engine draws it too where it shows (see setHidden).
	--
	local shown = {}
	local function setHidden(list, hide)
		for _, e in ipairs(list) do
			if (IsValid(e) and e.AGPHiddenVolume) then
				shown[e] = not hide
				-- AGP: the engine draws it as well wherever it shows (opaque materials only, drawing twice is harmless).
				-- On sb_gooniverse_v4 the hand drawing alone drew nothing - a Ha'tak's pel'tak had no walls, floor or
				-- ceiling there; the engine's own drawing did. Each covers the case where the other fails.
				if (e:GetNoDraw() ~= hide) then e:SetNoDraw(hide) end
			elseif (IsValid(e) and e ~= LocalPlayer() and not e:IsWeapon() and e:GetClass() ~= "agp_portal") then
				seen[e] = true
				if (hide and not hidden[e] and not e:GetNoDraw()) then e:SetNoDraw(true); hidden[e] = true
				elseif (not hide and hidden[e]) then e:SetNoDraw(false); hidden[e] = nil end
				local kids = e:GetChildren()   -- a gate's ring and chevrons go with the gate
				if (#kids > 0) then setHidden(kids, hide) end
			end
		end
	end
	local function volumeEnts(V)
		local mn, mx = V:WorldSpaceAABB()
		return ents.FindInBox(mn, mx), mn, mx
	end

	AGP_PORTAL_DRAWING = false
	hook.Add("RenderScene", "AGP_Portal", function(origin, angles, fov)
		if (AGP_PORTAL_DRAWING) then return end
		local portals = ents.FindByClass("agp_portal")
		seen = {}
		-- which volumes exist, and is the camera inside one?
		local vols = {}
		for _, P in ipairs(portals) do
			for _, f in ipairs({ P:GetFrameSelf(), P:GetFrameExit() }) do
				if (IsValid(f) and f.AGPHiddenVolume and not vols[f]) then
					local list, mn, mx = volumeEnts(f)
					vols[f] = { list = list, inside = inBox(origin, mn, mx) }
				end
			end
		end
		-- draw the other side of the nearest doorways in view into the shared textures (render targets are never freed:
		-- a few reused ones, not one per doorway, or every spawned ship eats video memory until icons turn pink)
		local w, h = ScrW(), ScrH()
		local want = {}
		for _, P in ipairs(portals) do
			P.RT = nil
			if (wants(P, origin)) then want[#want + 1] = P end
		end
		table.sort(want, function(a, b) return a:GetPos():DistToSqr(origin) < b:GetPos():DistToSqr(origin) end)
		for i, P in ipairs(want) do
			if (i > MAXVIEWS) then break end
			do
				local E = P:GetExit()
				P.RT = GetRenderTarget("agp_portal_view" .. i .. "_" .. w .. "x" .. h, w, h)
				-- through this doorway: the far side's volume shows, any volume on our side hides
				for f, v in pairs(vols) do setHidden(v.list, f ~= P:GetFrameExit()) end
				local camPos, camAng = P:CarryPos(origin), P:CarryAng(angles)
				local n = E:GetForward()
				render.PushRenderTarget(P.RT)
				render.Clear(0, 0, 0, 255, true, true)
				local oldClip = render.EnableClipping(true)
				render.PushCustomClipPlane(n, n:Dot(E:GetPos()) - 0.5)
				AGP_PORTAL_DRAWING = true
				-- as World Portals renders: the same tone mapping as the normal view, so the doorway shows no edge
				render.RenderView({ origin = camPos, angles = camAng, x = 0, y = 0, w = w, h = h, fov = fov,
					drawviewmodel = false, drawhud = false, dopostprocess = false, drawmonitors = false,
					bloomtone = true, viewid = 1 })
				AGP_PORTAL_DRAWING = false
				render.PopCustomClipPlane()
				render.EnableClipping(oldClip)
				render.PopRenderTarget()
			end
		end
		-- the normal view: volumes show only to someone inside them
		for f, v in pairs(vols) do setHidden(v.list, not v.inside) end
		-- whatever left a volume (walked out through a doorway, volume removed) is shown again
		for e in pairs(hidden) do
			if (not seen[e]) then if (IsValid(e)) then e:SetNoDraw(false) end; hidden[e] = nil end
		end
		for f in pairs(shown) do if (not IsValid(f) or not vols[f]) then shown[f] = nil end end
	end)
	-- the volumes' own models, in every view they show in (the main view and the doorway views drawn above)
	hook.Add("PreDrawOpaqueRenderables", "AGP_PortalVolumes", function(depth, sky)
		if (sky) then return end
		for f, on in pairs(shown) do
			if (on and IsValid(f)) then
				f:DrawModel()
				if (not depth) then render.RenderFlashlights(function() f:DrawModel() end) end
			end
		end
	end)

	-- the doorway's shape: a window is a flat quad; a walk-through doorway a box behind the plane, drawn from both
	-- sides (from inside it the eye sees its back and side faces), a hair inside the opening so walls win at the edges
	local function drawShape(P, col)
		render.SetColorMaterial()
		local w, h = P:GetPortalWidth(), P:GetPortalHeight()
		if (P:GetViewOnly()) then
			render.DrawQuadEasy(P:GetPos(), P:GetForward(), w, h, col, 0)
			return
		end
		local mn, mx = Vector(-P.DEPTH, -w / 2 + 0.5, -h / 2 + 0.5), Vector(0, w / 2 - 0.5, h / 2 - 0.5)
		render.DrawBox(P:GetPos(), P:GetAngles(), mn, mx, col)
		render.CullMode(MATERIAL_CULLMODE_CW)
		render.DrawBox(P:GetPos(), P:GetAngles(), mn, mx, col)
		render.CullMode(MATERIAL_CULLMODE_CCW)
	end

	function ENT:Draw() end
	function ENT:DrawTranslucent()
		if (AGP_PORTAL_DRAWING) then return end
		if (not wants(self, EyePos()) or not self.RT) then return end
		-- mark the doorway's visible pixels in the stencil (walls in front still cover it), then paint the far side there
		render.ClearStencil()
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(1); render.SetStencilTestMask(1); render.SetStencilReferenceValue(1)
		render.SetStencilFailOperation(STENCIL_KEEP); render.SetStencilZFailOperation(STENCIL_KEEP)
		render.SetStencilPassOperation(STENCIL_REPLACE); render.SetStencilCompareFunction(STENCIL_ALWAYS)
		drawShape(self, color_black)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		matView:SetTexture("$basetexture", self.RT)
		render.SetMaterial(matView)
		render.DrawScreenQuad()
		render.SetStencilEnable(false)
	end

	-- the portal doorway itself is never hidden
	hook.Add("PreDrawHalos", "AGP_Portal", function() if (AGP_PORTAL_DRAWING) then return false end end)
end
