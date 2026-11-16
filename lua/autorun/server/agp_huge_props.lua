-- Ascension Gates: huge props (the Ha'tak hull is ~6000 units) spawned from the spawn menu are frozen at once.
-- Left moving, the physics engine had to push such a prop out of the map in its first step and could crash
-- (vphysics access violation on gm_freespace_13, with the old and the new hull alike). Unfreeze with the physgun.
local HUGE = 2500   -- bounding radius in units

hook.Add("PlayerSpawnedProp", "AGP.FreezeHugeProps", function(ply, mdl, ent)
	if (not IsValid(ent) or ent:BoundingRadius() < HUGE) then return end
	local ph = ent:GetPhysicsObject()
	if (IsValid(ph)) then
		ph:EnableMotion(false)
		ph:Sleep()
	end
	if (IsValid(ply) and AGP and AGP.FirstTime and AGP.FirstTime(ply, "huge_prop")) then AGP.Say(ply, "agp_huge_prop", "This prop is huge, so it spawned frozen. Unfreeze it with the physgun once it is in place.") end
end)
