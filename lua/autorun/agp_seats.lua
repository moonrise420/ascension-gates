-- Ascension Gates: Goa'uld seats in the spawn menu (Vehicles tab). Real prisoner-pod vehicles, so the Wire Pod
-- Controller and the Wire Adv. Pod Controller can link them like any GMod seat. The same models are the pilot seat
-- and the throne of the Ha'tak (agp_hatak). Models from Sketchfab, see CREDITS.md.
local function HandleSitAnimation(vehicle, ply) return ply:SelectWeightedSequence(ACT_HL2MP_SIT) end

for id, v in pairs({
	agp_seat_pharaoh = { "Goa'uld Pilot Chair", "models/agp/hatak/props/pilot_chair.mdl" },
	agp_seat_throne = { "Goa'uld Throne", "models/agp/hatak/props/throne.mdl" },
}) do
	list.Set("Vehicles", id, {
		Name = v[1],
		Model = v[2],
		Class = "prop_vehicle_prisoner_pod",
		Category = "Ascension Gates",
		Author = "Ascension Gates",
		Information = "Goa'uld seat (links to a Wire pod controller)",
		KeyValues = { vehiclescript = "scripts/vehicles/prisoner_pod.txt", limitview = "0" },
		Members = { HandleAnimation = HandleSitAnimation },
	})
end
