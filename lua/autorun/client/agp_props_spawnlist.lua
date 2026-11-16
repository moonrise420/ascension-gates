-- Ascension Gates: prop categories in the spawn menu (Spawnlists): the Goa'uld furnishings of the Ha'tak interior and
-- Stargate decor. Models: models/agp/hatak/props (Sketchfab + own, see CREDITS.md). Seats are in the Vehicles tab.
local CATEGORIES = {
	{ "Ascension Gates: Goa'uld", "icon16/star.png", { "peltac_console", "naq_chest", "zat_chest", "door_control", "staff_weapon",
		"goauld_grenades", "statue_ra", "statue_horus", "statue_anubis", "statue_bastet", "obelisk",
		"serpent_helmet", "ring_platform_v1", "ring_platform_v2" } },
	{ "Ascension Gates: Stargate decor", "icon16/world.png", { "atlantis_city", "atlantis_city_lowpoly", "replicator_bug" } },
}

hook.Add("PopulatePropMenu", "AGP.PropSpawnlists", function()
	for i, c in ipairs(CATEGORIES) do
		local contents = {}
		for _, n in ipairs(c[3]) do
			local m = "models/agp/hatak/props/" .. n .. ".mdl"
			if (not AGP or not AGP.ModelComplete or AGP.ModelComplete(m)) then contents[#contents + 1] = { type = "model", model = m } end   -- (no ERROR props in the list)
		end
		spawnmenu.AddPropCategory("agp_props_" .. i, c[1], contents, c[2], 9000 + i)
	end
end)
