--[[
	Ascension Gates: clicking an energy tool in the SpaceGrid tab stays in the SpaceGrid tab. The energy tools
	are listed in two tabs (Stargate and SpaceGrid, lua/stargate/client/menu.lua); the SpaceGrid entry is called
	"<tool>_spacegrid". Clicking it selects the tool; the tool gun then reports its new mode and GMod looks the tool up
	by its plain name - which it finds in the Stargate tab first, and switched there. That second lookup is sent to the
	SpaceGrid entry when the SpaceGrid entry was just clicked.
]]
local lastSG, lastSGTime = nil, 0

local function hasItem(name)
	for _, v in ipairs(spawnmenu.GetTools and spawnmenu.GetTools() or {}) do
		for _, category in pairs(v.Items or {}) do
			for _, item in pairs(category) do
				if (istable(item) and item.ItemName == name) then return true end
			end
		end
	end
	return false
end

local function wrap()
	if (not spawnmenu or not spawnmenu.ActivateTool or spawnmenu.AGPStayWrapped) then return end
	spawnmenu.AGPStayWrapped = true
	local orig = spawnmenu.ActivateTool
	function spawnmenu.ActivateTool(strName, noCommand)
		if (isstring(strName)) then
			local base = strName:match("^(.+)_spacegrid$")
			if (base) then
				lastSG, lastSGTime = base, RealTime()
			elseif (noCommand and strName == lastSG and RealTime() - lastSGTime < 3 and hasItem(strName .. "_spacegrid")) then
				return orig(strName .. "_spacegrid", true)
			end
		end
		return orig(strName, noCommand)
	end
end

wrap()
hook.Add("OnGamemodeLoaded", "AGP.ToolMenuStay", wrap)
hook.Add("PopulateToolMenu", "AGP.ToolMenuStay", wrap)
