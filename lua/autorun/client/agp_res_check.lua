-- Ascension Gates: are Resources 1-3 there? (on the Workshop about 30 players had the code and Resources 1 but not
-- Resources 2 and 3 - Steam lets players skip required items, and then gates, ships and props show as
-- purple-black squares or ERROR with nothing telling why.) One file that only that pack has is looked for in the game's
-- files, so content from a subscription, a server download or a manual install all count. Once per game start.
AGP = AGP or {}

AGP.ResPacks = {
	{ name = "Resources 1", id = "3840679367", file = "materials/models/agp/gates/agp_alt_face.vmt" },
	{ name = "Resources 2", id = "3840680131", file = "materials/boba_fett/catwalk_build/gate_platform.vmt" },
	{ name = "Resources 3", id = "3840681290", file = "materials/cos/stargate/iris_material.vmt" },
}

local function L(key, fallback, ...) return (AGP.L and AGP.L(key, fallback, ...)) or string.format(fallback, ...) end

-- the packs whose file is missing
function AGP.MissingResPacks()
	local out = {}
	for _, p in ipairs(AGP.ResPacks) do
		if not file.Exists(p.file, "GAME") then out[#out + 1] = p end
	end
	return out
end

function AGP.ResCheck(always)
	local miss = AGP.MissingResPacks()
	if #miss == 0 then
		if always then chat.AddText(Color(255, 190, 80), "[Ascension Gates] ", color_white, L("agp_resmiss_ok", "All content is there (Resources 1, 2 and 3).")) end
		return miss
	end
	local names = {}
	for _, p in ipairs(miss) do names[#names + 1] = p.name end
	local msg = L("agp_resmiss_text", "Some Ascension Gates content is missing: %s. Things can show as purple-black squares or ERROR. Subscribe to it on the Steam Workshop, then restart the game.", table.concat(names, ", "))
	chat.AddText(Color(255, 190, 80), "[Ascension Gates] ", Color(255, 120, 100), msg)
	MsgC(Color(255, 120, 100), "[Ascension Gates] " .. msg .. "\n")
	-- one button per missing pack (at most 3) and "Later"
	local args = { msg, "Ascension Gates" }
	for _, p in ipairs(miss) do
		args[#args + 1] = L("agp_resmiss_open", "Open %s", p.name)
		args[#args + 1] = function() gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. p.id) end
	end
	args[#args + 1] = L("agp_upd_later", "Later")
	local q = Derma_Query(unpack(args))
	if (IsValid(q) and AGP.ApplySkin) then AGP.ApplySkin(q) end
	AGP.ResCheckWindow = q
	return miss
end

hook.Add("InitPostEntity", "AGP.ResCheck", function()
	-- a few seconds later: the texts are loaded and the player sees the game first
	timer.Simple(6, function() AGP.ResCheck(false) end)
end)

concommand.Add("agp_res_check", function() AGP.ResCheck(true) end, nil, "Ascension Gates: check that Resources 1, 2 and 3 are installed")
