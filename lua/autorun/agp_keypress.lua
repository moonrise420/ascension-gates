--[[
	Ascension Gates: one press = one action (2026-10-30).
	Many ship keys were read as "held" every tick and called a toggle: holding the key a moment flipped the state back
	and forth (view, cloak, lights, shield ...), or restarted a door animation every tick so nothing seemed to happen.
	AGP.KeyPress(ent, ply, layout, key) is true only in the tick the key goes down (StarGate keyboard keys).
	AGP.KeyPressIN(ent, ply, inKey) does the same for the normal player keys (IN_USE, IN_ATTACK2 ...).
]]
if SERVER then AddCSLuaFile() end
AGP = AGP or {}

-- 2026-10-30: a quick tap (press and release in ~100 ms) often fell between two server Thinks of a ship (about 5 a
-- second), so it was never seen as "down". Every press is noted here when it arrives and counts once, even if the key
-- is already up again when the ship looks (for a second at most, so an old press never fires later).
if SERVER then
	hook.Add("StarGate.Player.KeyPressed", "AGP.KeyPressTap", function(p, layout, key)
		if (not IsValid(p)) then return end
		p.AGPTap = p.AGPTap or {}
		p.AGPTap[tostring(layout) .. "/" .. tostring(key)] = CurTime()
	end)
end

function AGP.KeyPress(ent, ply, layout, key)
	if (not IsValid(ply) or not ply.KeyDown) then return false end
	local down = ply:KeyDown(layout, key) and true or false
	ent.AGPHeld = ent.AGPHeld or {}
	local id = tostring(layout) .. "/" .. key
	local was = ent.AGPHeld[id]
	ent.AGPHeld[id] = down
	local tap = ply.AGPTap and ply.AGPTap[id]
	if (tap) then ply.AGPTap[id] = nil end
	return (down and not was) or (tap ~= nil and CurTime() - tap < 1)
end

function AGP.KeyPressIN(ent, ply, inKey)
	if (not IsValid(ply)) then return false end
	local down = ply:KeyDown(inKey) and true or false
	ent.AGPHeldIN = ent.AGPHeldIN or {}
	local was = ent.AGPHeldIN[inKey]
	ent.AGPHeldIN[inKey] = down
	return down and not was
end

-- 2026-10-31: free look (owner: hold ALT to look around without steering). The ships steer toward where the pilot looks;
-- while ALT (+walk) is held they keep the direction they had when it was pressed, and the camera (which follows the
-- mouse) is free. On release the view turns back to that direction, so the ship flies on without a jerk.
function AGP.SteerAim(ship, ply)
	if (not IsValid(ply)) then return ship:GetForward() end
	if (ply:KeyDown(IN_WALK)) then
		ship.AGPFreeLook = ship.AGPFreeLook or ship.AGPSteerAim or ply:GetAimVector()
		return ship.AGPFreeLook
	end
	if (ship.AGPFreeLook) then
		if (SERVER) then ply:SetEyeAngles(ship.AGPFreeLook:Angle()) end
		ship.AGPSteerAim = ship.AGPFreeLook
		ship.AGPFreeLook = nil
		return ship.AGPSteerAim
	end
	ship.AGPSteerAim = ply:GetAimVector()
	return ship.AGPSteerAim
end
