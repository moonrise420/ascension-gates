-- Ascension Gates and PowerGrid (required addon: the energy network, its parts and life support).
-- Our own power items go into PowerGrid's spawn tab and parts tool too; without PowerGrid a clear note instead of errors
-- (gates, shields and ships then run on free energy, as CAP did without Spacebuild).
local ITEMS = {
	{ "ion_generator", "generators", 150 }, { "agp_goauld_power_hub", "generators", 151 },
	{ "black_hole_power", "generators", 180 }, { "asgard_ion_generator", "generators", 185 }, { "agp_reactor_core", "generators", 186 },
	{ "powercell_small", "storage", 150 }, { "agp_goauld_power_crystal", "storage", 160 },
	{ "destiny_node", "network", 150 },
	{ "zpm_analyser", "other", 501 }, { "zpm_analyser_mk2", "other", 502 },
}

hook.Add("Initialize", "AGP.PowerGrid", function()
	if not (PowerGrid and PowerGrid.AddSpawn) then return end
	for _, it in ipairs(ITEMS) do PowerGrid.AddSpawn(it[1], it[2], it[3], "cap_spawnsent") end
end)

if CLIENT then
	hook.Add("InitPostEntity", "AGP.PowerGridMissing", function()
		if PowerGrid then return end
		timer.Simple(10, function()
			local L = AGP and AGP.L or function(_, f) return f end
			chat.AddText(Color(255, 190, 80), "[Ascension Gates] ", color_white, L("agp_need_powergrid",
				"needs the addon PowerGrid for its energy network (Steam Workshop: required item). Without it gates, shields and ships run on free energy. Please subscribe to PowerGrid and restart."))
		end)
	end)
end
