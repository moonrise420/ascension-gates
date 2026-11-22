--[[
	Ascension Gates: one aim for every ship - the point under the pilot's crosshair. The pilot's
	client traces from its real camera (third person behind the ship, or the bridge view on 1) through the middle of
	the screen and sends the point it hits to the server about 20 times a second. The ships' guns, drones, beams and
	volleys aim there (AGP.ShipCrosshair). Before,
	the server traced from the ship's middle along the mouse direction: in the bridge view the camera sits far from
	that middle, so shots and drones missed what the crosshair showed; and with the shield up that trace hit the
	ship's own bubble, so the drones flew into their own ship (Aurora, Destiny, O'Neill). Parts of the ship
	never count as a hit: AGP.ShipPart (the ship, anything parented to it at any depth - its shield bubble sits on the
	shield generator - and its own drones and shots). New ships: aim
	every weapon with AGP.ShipCrosshair / AGP.ShipAimDir (lua/autorun/agp_ship_shield.lua), never with an own trace from
	the ship.
]]
AddCSLuaFile()
AGP = AGP or {}

local REACH = 60000

-- e belongs to ship: the ship, anything parented to it (any depth), its shield bubble, its drones and shots
function AGP.ShipPart(ship, e)
	if not IsValid(e) or not IsValid(ship) then return false end
	if e == ship or e.Parent == ship or e.AGPShip == ship or e:GetOwner() == ship then return true end
	local p = e:GetParent()
	for _ = 1, 8 do
		if not IsValid(p) then return false end
		if p == ship then return true end
		p = p:GetParent()
	end
	return false
end

local function aimTrace(ship, ply, start, dir)
	return util.TraceLine({ start = start, endpos = start + dir * REACH, mask = MASK_SHOT,
		filter = function(e) return e ~= ply and not AGP.ShipPart(ship, e) end })
end

-- the point the pilot's client saw under its crosshair, when it is fresh (half a second); else nil
function AGP.ShipClientAim(ply, ship)
	if not IsValid(ply) then return nil end
	if CLIENT then return ply == LocalPlayer() and AGP.ShipAimHit or nil end
	local pos = ply.AGPShipAim
	if pos and CurTime() - (ply.AGPShipAimT or 0) < 0.5 and pos:DistToSqr(ship:GetPos()) < (REACH * 1.2) ^ 2 then return pos end
end

-- the point under ply's crosshair (ply: the ship's pilot when not given); nil without a pilot
function AGP.ShipCrosshair(ship, ply)
	if not IsValid(ship) then return nil end
	ply = ply or ship.Pilot or ship.Driver
	if not (IsValid(ply) and ply:IsPlayer()) then return nil end
	local seen = AGP.ShipClientAim(ply, ship)
	if seen then return seen end
	-- no fresh point from the client (HUD off, a hitch): along the mouse direction from the ship's middle
	if ship.AGPCrossTick == engine.TickCount() and ship.AGPCrossPly == ply then return ship.AGPCrossPos end
	local hit = aimTrace(ship, ply, ship:WorldSpaceCenter(), ply:GetAimVector()).HitPos
	ship.AGPCrossTick, ship.AGPCrossPly, ship.AGPCrossPos = engine.TickCount(), ply, hit
	return hit
end

-- a direction from `from` towards the crosshair, at most maxDeg away from the ship's nose (guns that sit fixed in the
-- hull: they still cover the small offset between the camera and the guns). nil maxDeg: the whole front half.
function AGP.ShipAimCone(ship, from, maxDeg)
	local fwd = ship:GetForward()
	local pos = AGP.ShipCrosshair(ship)
	if not pos then return fwd end
	local d = pos - from
	if d:LengthSqr() < 1 then return fwd end
	d:Normalize()
	local dot = d:Dot(fwd)
	if not maxDeg then return dot < 0.1 and fwd or d end
	local c = math.cos(math.rad(maxDeg))
	if dot >= c then return d end
	if dot < 0 then return fwd end
	local side = (d - fwd * dot):GetNormalized()
	return (fwd * c + side * math.sin(math.rad(maxDeg))):GetNormalized()
end

-- AGP: the same front limit for any wanted direction (a Wire target too): guns fixed in the bow fire inside maxDeg of
-- the nose, turrets (maxDeg nil) anywhere in front - never backwards or straight sideways
function AGP.ShipAimClamp(ship, d, maxDeg)
	local fwd = ship:GetForward()
	if not d or d:LengthSqr() < 1e-6 then return fwd end
	d = d:GetNormalized()
	local dot = d:Dot(fwd)
	if not maxDeg then return dot < 0.1 and fwd or d end
	local c = math.cos(math.rad(maxDeg))
	if dot >= c then return d end
	if dot < 0 then return fwd end
	local side = (d - fwd * dot):GetNormalized()
	return (fwd * c + side * math.sin(math.rad(maxDeg))):GetNormalized()
end

if SERVER then
	util.AddNetworkString("AGP.ShipAim")
	net.Receive("AGP.ShipAim", function(_, ply)
		local x, y, z = net.ReadFloat(), net.ReadFloat(), net.ReadFloat()
		if x ~= x or y ~= y or z ~= z then return end   -- NaN
		ply.AGPShipAim, ply.AGPShipAimT = Vector(x, y, z), CurTime()
	end)
else
	-- from the camera the player really looks through (EyePos in HUDPaint: the ship's CalcView result)
	local nextSend = 0
	hook.Add("HUDPaint", "AGP.ShipAim", function()
		local ply = LocalPlayer()
		local ship = IsValid(ply) and ply:GetNWEntity("ScriptedVehicle", NULL)
		if not IsValid(ship) then AGP.ShipAimHit = nil return end
		local hit = aimTrace(ship, ply, EyePos(), EyeAngles():Forward()).HitPos
		AGP.ShipAimHit = hit
		if CurTime() < nextSend then return end
		nextSend = CurTime() + 0.05
		net.Start("AGP.ShipAim", true)
		net.WriteFloat(hit.x) net.WriteFloat(hit.y) net.WriteFloat(hit.z)
		net.SendToServer()
	end)
end
