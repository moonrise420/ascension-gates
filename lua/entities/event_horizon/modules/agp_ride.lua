--[[
	Ascension Gates: the wormhole ride (our own code; replaces the Evolution Addon Pack's DoWormHole / MoveToTarget
	by Elanis and its usermessages). What goes into a gate (with the ride on, config "doWormholeSequence") is held out
	of the world for AGP_RIDE_TIME seconds - invisible, not solid, not moving; a player frozen and unhurt - while the
	player (or a ship's pilot) sees the tunnel; then it comes out of the far gate. The tunnel picture
	(williamdefly/wormhole) and the travel sound (stargate/travelnew.mp3) are the series' (MGM).

	Kept for the rest of the pack:
	- self.Ents[e] holds the ride's data (with .AGPSince) for the whole ride: ENT:AGPPassing keeps the gate open, the
	  Replicators' pursuit (agp_replicators/sv_pursuit.lua) waits for its prey; ENT:AGPNoRide (shots, Replicators) never
	  ride - that check is at the callers.
	- every ride's timer is in self.timer_table: ENT:PauseAllRouting / ResumeAllRouting hold and release it.
	- a gate removed or destroyed during the ride: the rider comes out of the source gate (or stays where it went in).
	- players can switch the picture off (cl_stargate_wormhole 0): they then go through at once.
]]
AGP_RIDE_TIME = 3.2

if (SERVER) then
	util.AddNetworkString("AGP.WormholeRide")

	-- the tunnel on (true) or off for this player
	local function view(ply, on)
		if (not IsValid(ply) or not ply:IsPlayer()) then return end
		ply.AGPRideView = on or nil
		net.Start("AGP.WormholeRide")
		net.WriteBool(on)
		net.Send(ply)
	end

	-- a player who dies while seeing the tunnel (killed in the gate) does not keep it
	hook.Add("PostPlayerDeath", "AGP.WormholeRide", function(ply)
		if (ply.AGPRideView) then view(ply, false) end
		-- he may respawn before the ride's time is up: then he must not be pulled through the gate from his spawn point
		if (ply.AGPRide) then ply.AGPRide.AGPDied = true end
	end)

	local function stays(e)
		return IsValid(e) and not e:IsMarkedForDeletion()
	end

	-- every ship: the puddle jumper and all sg_vehicle_* (ours and the ported ones)
	local function isShip(e)
		local c = e:GetClass()
		return c == "puddle_jumper" or c:sub(1, 11) == "sg_vehicle_"
	end

	-- who sees the ride: the player, or the pilot of a ship
	local function rideViewer(e)
		if (e:IsPlayer()) then return e end
		if (isShip(e) and IsValid(e.Pilot) and e.Pilot:IsPlayer()) then return e.Pilot end
	end

	-- AGP (test: a seat with a StarCore welded behind it rode the wormhole twice - every welded part started its own
	-- ride once it was through, and the second ride moved the whole ship again from the source gate: it came out far
	-- off, under the map; the pilot in the seat saw no tunnel, only a frozen picture): a contraption rides as one. The
	-- part that is through first starts the ride; every other part of it (and what is parented to them) is held where
	-- it is - frozen, unseen, not solid - and comes along; the players in its seats are unhurt and see the tunnel.
	-- The far gate gets the whole contraption once, as without the ride.
	local function heldState(v)
		local p = v:GetPhysicsObject()
		local st = { Ent = v, Flags = v:GetSolidFlags(), Color = v:GetColor(), RenderMode = v:GetRenderMode(), Vel = v:GetVelocity() }
		if (IsValid(p)) then st.Motion = p:IsMotionEnabled(); p:EnableMotion(false) end
		return st
	end

	local function seated(v)
		if (v:IsVehicle()) then return v:GetDriver() end
		if (isShip(v)) then return v.Pilot end
	end

	-- every part of the contraption but e, its children, the players in its seats
	local function groupHold(e, r, list)
		local held, seen = {}, { [e] = true }
		local function hide(v)
			if (not IsValid(v) or seen[v] or v:IsPlayer()) then return end
			seen[v] = true
			held[#held + 1] = heldState(v)
			v.AGPRideWith = e
			v:AddSolidFlags(FSOLID_NOT_SOLID)
			v:SetRenderMode(RENDERMODE_TRANSALPHA)
			v:SetColor(Color(0, 0, 0, 0))
			for _, c in ipairs(v:GetChildren()) do hide(c) end
		end
		for _, v in ipairs(list or {}) do hide(v) end
		for _, c in ipairs(e:GetChildren()) do hide(c) end
		local riders = {}
		for _, v in ipairs({ e, unpack(list or {}) }) do
			local d = IsValid(v) and seated(v)
			if (IsValid(d) and d:IsPlayer() and not riders[d]) then
				riders[d] = { God = d:HasGodMode() }
				d:GodEnable()
				d:SetNoDraw(true)
			end
		end
		r.Group, r.Seated = held, riders
	end

	-- back into the world: the held parts at their speed as they went in (the teleport turns it to the far gate)
	local function groupFree(r)
		for _, st in ipairs(r.Group or {}) do
			local v = st.Ent
			if (IsValid(v)) then
				v.AGPRideWith = nil
				v:SetSolidFlags(st.Flags)
				v:SetColor(st.Color)
				v:SetRenderMode(st.RenderMode)
				local p = v:GetPhysicsObject()
				if (IsValid(p) and st.Motion) then
					p:EnableMotion(true)
					p:Wake()
					p:SetVelocity(st.Vel)
				end
			end
		end
		for d, st in pairs(r.Seated or {}) do
			if (IsValid(d)) then
				d:SetNoDraw(false)
				if (not st.God) then d:GodDisable() end
			end
		end
		r.Group, r.Seated = nil, nil
	end

	-- the tunnel for everyone who sees this ride
	local function viewAll(r, on)
		for _, ply in ipairs(r.Viewers or {}) do view(ply, on) end
		if (not on) then r.Viewers = nil end
	end

	-- the two gates count this ride in "Entities On Route"; once over, counted down again (once)
	local function routeDone(r)
		if (not r or not r.AGPRoute) then return end
		for _, g in pairs(r.AGPRoute) do
			if (IsValid(g) and g.EntitiesOnRoute) then g.EntitiesOnRoute = math.max(0, g.EntitiesOnRoute - 1) end
		end
		r.AGPRoute = nil
	end

	local function setMalpWheels(k, out)
		if (k:GetClass() ~= "malp" or not k.MalpWheels) then return end
		for i = 1, 6 do
			local w = k.MalpWheels[i]
			if (IsValid(w)) then
				w:SetNotSolid(not out)
				w:SetRenderMode(out and RENDERMODE_NORMAL or RENDERMODE_NONE)
				if (out) then w:SetPos(k:GetPos()) end
			end
		end
	end

	-- back into the world as it went in: seen, solid, moving; a player free again
	local function restore(k, r)
		if (k:IsPlayer()) then
			k:Freeze(false)
			k:DrawViewModel(true)
			k:DrawWorldModel(true)
			k.DisableSpawning = nil
			k.DisableSuicide = nil
			k.DisableNoclip = nil
			k:GodDisable()
			if (r.God) then k:GodEnable() end
		end
		if (r.Health) then k:SetHealth(r.Health) end
		k:SetMoveType(r.MoveType)
		k:SetSolid(r.Solid)
		k:SetColor(r.Color)
		k:SetRenderMode(r.RenderMode)
		k:SetParent(nil)
		k.AGPRideWith = nil
		setMalpWheels(k, true)
		groupFree(r)
	end

	local function gravityBack(k, r)
		local phys = k:GetPhysicsObject()
		if (not IsValid(phys)) then return end
		if (r.AGPGravity ~= nil) then phys:EnableGravity(r.AGPGravity)
		elseif (r.Gravity) then phys:EnableGravity(true) end
	end

	-- a ride that cannot be finished (a gate was removed or destroyed meanwhile): out of the source gate again, in front
	-- of it, or where it went in when that gate is gone too. Ends a ride only once (r.AGPDone).
	local function abort(k, r, eh)
		if (not r or r.AGPDone) then return end
		r.AGPDone = true
		if (r.AGPTimer) then timer.Remove(r.AGPTimer) end
		routeDone(r)
		if (IsValid(eh) and eh.Ents) then eh.Ents[k] = nil end
		viewAll(r, false)
		if (not IsValid(k)) then groupFree(r) return end
		if (k:IsPlayer()) then k.AGPRide = nil end
		local group = r.Group
		restore(k, r)
		local from = k:GetPos()
		local gate = r.AGPSource
		if (stays(gate)) then
			local fwd = gate:GetForward()
			if (k:IsPlayer() or k:IsNPC()) then
				k:SetPos(gate:GetPos() + fwd * 30 + gate:GetUp() * -80)   -- where one arrives normally
				if (k:IsPlayer()) then k:SetEyeAngles(Angle(0, fwd:Angle().y, 0)) end
			else
				k:SetPos(gate:GetPos() + fwd * (k:BoundingRadius() + 16) - (k:WorldSpaceCenter() - k:GetPos()))
			end
			-- just arrived for the horizon: not swallowed again at once
			if (stays(eh)) then
				local immunity = { __TARGET = eh, __LastTeleport = CurTime() }
				immunity[k] = true
				k.__StargateTeleport = immunity
			end
		else
			k:SetPos(k:GetPos())
		end
		local moved = k:GetPos() - from
		for _, st in ipairs(group or {}) do
			if (IsValid(st.Ent) and not IsValid(st.Ent:GetParent())) then
				st.Ent:SetPos(st.Ent:GetPos() + moved)
				local p = st.Ent:GetPhysicsObject()
				if (IsValid(p)) then p:SetVelocity(vector_origin) end
			end
		end
		gravityBack(k, r)
		local phys = k:GetPhysicsObject()
		if (IsValid(phys) and r.MoveType == MOVETYPE_VPHYSICS) then
			phys:EnableMotion(true)
			phys:SetVelocity(vector_origin)   -- it was flying into the gate
			phys:Wake()
		end
	end

	-- every ride still running from this horizon ends now (the horizon goes: ENT:OnRemove)
	function ENT:AGPAbortRides()
		for k, r in pairs(self.Ents or {}) do
			if (istable(r) and r.AGPSince) then abort(k, r, self) end
		end
	end

	-- dead / removed at once (in a closing gate, or a gate going nowhere)
	local function lost(e)
		if (e:IsPlayer()) then e:KillSilent() else e:Remove() end
	end

	--################# Into the wormhole: e went into this horizon (from the front, or from behind: totalkill)
	function ENT:DoWormHole(e, block, attached, bcfd, totalkill, gravity)
		block = false   -- looked at again when it arrives (a far iris may open or shut meanwhile; the Virgo gate's way back)
		if (e:IsPlayer() and not e:Alive()) then return end
		if (isShip(e) and IsValid(e.Pilot) and e.Pilot:IsPlayer() and not e.Pilot:Alive()) then return end
		if (e.AGPRideWith) then return end   -- a part of a contraption already on its way (it rides along)
		if (self.ShuttingDown) then lost(e) return end
		-- still forming (the kawoosh), unstable or closing with a kill: destroyed at once, as without the ride
		if (not self:IsOpen() or self.ShuttingDownKill or self.Unstable) then
			self:Teleport(e, true, attached)
			return
		end
		if (not IsValid(self.Target)) then
			-- the Virgo gate's way back; else what goes into an incoming gate dies
			local gate, caller = self:GetParent(), self:GetParent().GateCaller
			if (gate:GetClass() == "stargate_virgo" and IsValid(caller) and caller:GetClass() == "stargate_virgo" and IsValid(caller:GetChildren()[1])) then
				self.Target = caller:GetChildren()[1]
			else
				lost(e)
				return
			end
		end

		-- who sees the tunnel: the player, a ship's pilot, everyone in a seat of the contraption
		local list = istable(attached) and attached.Attached or {}
		local viewers, wants = {}, {}
		for _, v in ipairs({ e, unpack(list) }) do
			local p = IsValid(v) and (rideViewer(v) or seated(v))
			if (IsValid(p) and p:IsPlayer() and not table.HasValue(viewers, p)) then
				viewers[#viewers + 1] = p
				if (p:GetInfoNum("cl_stargate_wormhole", 1) ~= 0) then wants[#wants + 1] = p end
			end
		end
		local r = {
			MoveType = e:GetMoveType(), Solid = e:GetSolid(), Color = e:GetColor(), RenderMode = e:GetRenderMode(),
			Vel = e:GetVelocity(), Health = e:Health(), Gravity = gravity,
			AGPSince = CurTime(),          -- the gate stays open meanwhile (ENT:AGPPassing)
			AGPSource = self:GetParent(),  -- where a ride that cannot be finished comes out
			Viewers = wants,
		}
		if (e:IsPlayer()) then
			r.God = e:HasGodMode()
			e.AGPRide = r
			e.DisableSpawning = true
			e.DisableNoclip = true
			e:GodEnable()
			e:Freeze(true)
			e:DrawViewModel(false)
			e:DrawWorldModel(false)
		elseif (isShip(e) or e:GetClass() == "prop_physics") then
			e:SetHealth(2147483647)   -- unhurt on the way
		end
		setMalpWheels(e, false)
		e:SetRenderMode(RENDERMODE_TRANSALPHA)
		e:SetColor(Color(0, 0, 0, 0))
		e:SetSolid(SOLID_NONE)
		e:SetMoveType(MOVETYPE_NONE)
		self.Ents[e] = r
		e.AGPRideWith = e
		groupHold(e, r, list)

		-- through at once: from behind (destroyed), a player without the picture, one who died this very moment
		local now = totalkill or (#viewers > 0 and #wants == 0) or (e:IsPlayer() and not e:Alive())
		if (totalkill) then block = true end
		local gate = self:GetParent()
		if (gate:GetClass() ~= "mobile_gate") then
			gate.EntitiesOnRoute = (gate.EntitiesOnRoute or 0) + 1
			local tg = self.Target:GetParent()
			tg.EntitiesOnRoute = (tg.EntitiesOnRoute or 0) + 1
			r.AGPRoute = { gate, tg }
		end
		if (now) then
			self:AGPRideArrive(e, r, block, attached, bcfd)
			return
		end

		if (not e:IsPlayer()) then
			local phys = e:GetPhysicsObject()
			if (IsValid(phys)) then r.AGPGravity = phys:IsGravityEnabled(); phys:EnableGravity(false) end
		end
		viewAll(r, true)
		local name = "AGP.WormholeRide." .. gate:EntIndex() .. "." .. e:EntIndex()
		r.AGPTimer = name
		table.insert(self.timer_table, name)
		timer.Create(name, AGP_RIDE_TIME, 1, function()
			if (IsValid(self) and self.timer_table) then table.RemoveByValue(self.timer_table, name) end
			-- the source gate (with this horizon) or the rider is gone: the ride ends here
			if (not IsValid(self) or not IsValid(e)) then abort(e, r, self) return end
			self:AGPRideArrive(e, r, block, attached, bcfd)
		end)
		if (self.RoutingPaused) then timer.Pause(name) end
	end

	--################# Out of the wormhole at the far gate (or blocked by its iris / shield)
	function ENT:AGPRideArrive(k, r, block, attached, bcfd)
		local tgate = IsValid(self.Target) and self.Target:GetParent() or NULL
		if (not stays(self.Target) or not stays(tgate) or not stays(self:GetParent())) then
			abort(k, r, self)   -- the far gate (or this one) went meanwhile: back out of this one
			return
		end
		r.AGPDone = true
		if (not IsValid(k)) then viewAll(r, false) groupFree(r) routeDone(r) self.Ents[k] = nil return end
		if (k:IsPlayer()) then k.AGPRide = nil end
		-- he died during the ride (and may have respawned meanwhile): his ride is just over, no teleport
		if (k:IsPlayer() and r.AGPDied) then
			viewAll(r, false)
			restore(k, r)   -- seen and free again (the alpha 0 would outlive a respawn)
			routeDone(r)
			self.Ents[k] = nil
			return
		end

		local cfd = false   -- "came from dialing": sent back out of this gate
		if (not block) then
			if (tgate.IsStargate) then block = tgate:IsBlocked() end
			cfd = self:BlockedCFD(tgate, k) and true or false
			if (cfd) then block = false end
		end
		if (k:IsPlayer() and StarGate.CFG:Get("stargate", "nox_bypass", false) and self:GetParent().NoxDialingType and (k:IsAdmin() or k:IsSuperAdmin())) then
			block, bcfd, cfd = false, false, false
		end

		-- the one who rode (a ship's pilot for a ship) died, or the gate is shutting down
		local rider = (isShip(k) and IsValid(k.Pilot) and k.Pilot:IsPlayer()) and k.Pilot or k
		if (rider:IsPlayer() and (not rider:Alive() or (self.ShuttingDown and not self.ShuttingDownKill))) then
			restore(k, r)
			rider:StripWeapons()
			rider:KillSilent()
			viewAll(r, false)
			umsg.Start("StarGate.EventHorizon.PlayerKill")
			umsg.Entity(rider)
			umsg.End()
			if (k ~= rider) then k:Remove() end
			routeDone(r)
			self.Ents[k] = nil
			return
		elseif (self.ShuttingDown and not rider:IsPlayer()) then
			viewAll(r, false)
			groupFree(r)
			k:Remove()
			routeDone(r)
			self.Ents[k] = nil
			return
		end

		viewAll(r, false)
		restore(k, r)
		-- its speed as it went in, turned to the far gate by the teleport (was: no speed, then twice the old one in
		-- the old direction)
		if (not k:IsPlayer() and r.Vel) then
			local phys = k:GetPhysicsObject()
			if (r.MoveType == MOVETYPE_VPHYSICS and IsValid(phys)) then
				phys:EnableMotion(true)
				phys:Wake()
				phys:SetVelocity(r.Vel)
			else
				k:SetVelocity(r.Vel)
			end
		end
		self.Ents[k] = nil
		self:Teleport(k, block, attached)

		if (block) then
			-- the far iris: the "hit" sound
			if (not self.Unstable and IsValid(tgate.Iris) and tgate.Iris.IsActivated) then
				tgate.Iris:HitIris(self:GetTeleportedVector(k:GetPos(), k:GetVelocity()))
			end
		else
			local out = cfd and self or self.Target
			if (not bcfd or cfd) then
				timer.Simple(0.05, function()
					if (IsValid(out) and IsValid(k)) then
						out:EmitSound(self.Sounds.Teleport[math.random(1, #self.Sounds.Teleport)], 90, math.random(90, 110))
						out:EnterEffectEntity(k)
					end
				end)
			end
			if (IsValid(k) and not k:IsPlayer()) then gravityBack(k, r) end
			-- AGP (test: the Gate Glider stayed in the far event horizon, only its tip out, until the gate threw it out): a
			-- ship comes out at the depth it went in, and a ship without throttle then just hovers there. Every
			-- sg_vehicle_ ship comes out wholly in front of the far gate (its centre a bounding radius out).
			if (IsValid(k) and k:GetClass():sub(1, 11) == "sg_vehicle_") then
				local g = (cfd and self or self.Target):GetParent()
				if (IsValid(g)) then
					local fwd = g:GetForward()
					local need = k:BoundingRadius() + 24
					local d = (k:WorldSpaceCenter() - g:GetPos()):Dot(fwd)
					if (d < need) then k:SetPos(k:GetPos() + fwd * (need - d)) end
				end
			end
			-- a player or NPC steps out on the ground in front of the gate
			if (IsValid(k) and (k:IsPlayer() or k:IsNPC())) then
				local g = (cfd and self or self.Target):GetParent()
				k:SetPos(g:GetPos() + g:GetForward() * 30 + g:GetUp() * -80)
			end
		end
		if (IsValid(k)) then self:AGPAutoClose(k) end   -- came out (or hit the iris): the gate closes a while later
		routeDone(r)
	end
end

if (CLIENT) then
	-- players can switch the tunnel off (the server reads it): they then go through at once
	CreateClientConVar("cl_stargate_wormhole", "1", true, true)

	-- the series' tunnel (MGM), frame by frame: our own copy of the material, without its animation proxy
	local tunnel = CreateMaterial("AGPWormholeTravel", "UnlitGeneric", { ["$basetexture"] = "williamdefly/wormhole", ["$vertexcolor"] = "1" })
	local channel

	local function soundStop()
		if (IsValid(channel)) then channel:Stop() end
		channel = nil
		local p = LocalPlayer()
		if (IsValid(p)) then p:StopSound("stargate/travelnew.mp3") end
	end

	local function stop()
		soundStop()
		hook.Remove("HUDDrawScoreBoard", "AGP.WormholeRide")
		hook.Remove("EntityEmitSound", "AGP.WormholeRide")
		hook.Remove("PlayerBindPress", "AGP.WormholeRide")
	end

	local function start()
		stop()
		sound.PlayFile("sound/stargate/travelnew.mp3", "noblock", function(ch)
			if (IsValid(ch)) then channel = ch; ch:SetVolume(1); ch:Play()
			else local p = LocalPlayer(); if (IsValid(p)) then p:EmitSound("stargate/travelnew.mp3") end end
		end)
		hook.Add("EntityEmitSound", "AGP.WormholeRide", function() return false end)   -- only the wormhole is heard
		hook.Add("PlayerBindPress", "AGP.WormholeRide", function() return true end)    -- no keys on the way
		local t0 = CurTime()
		local tex = tunnel:GetTexture("$basetexture")
		local frames = (tex and not tex:IsError()) and math.max(tex:GetNumAnimationFrames(), 1) or 1
		hook.Add("HUDDrawScoreBoard", "AGP.WormholeRide", function()
			tunnel:SetInt("$frame", math.floor((CurTime() - t0) * 30) % frames)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(tunnel)
			surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
		end)
	end

	net.Receive("AGP.WormholeRide", function()
		if (net.ReadBool()) then start() else stop() end
	end)
end
