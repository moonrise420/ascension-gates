--[[
	Weapon Link Tool (from the CAP Enhanced Workshop pack 3021712722)
	Links weapons (Destiny turrets, ship railgun, Tollan turret, Asgard beam, Ori beam cannon, Vanir and Wraith plasma
	cannons) to an Apple Core. The Apple Core's Wire inputs Active, Fire, Vector and Entity then steer all of them.
	Left click: select a weapon (again: deselect). Right click on an Apple Core: link the selection to it.
	Reload: clear the selection; on an Apple Core: remove all its links.
]]
-- AGP 2026-11-08: in our Stargate tool menu like the other tools (Tab "Stargate" + AddToMenu=false: menu.lua adds it),
-- with translated texts. Before it had AddToMenu=false and no Tab, so it was in no menu at all.
TOOL.Tab = "Stargate"
TOOL.AddToMenu = false
TOOL.Category = "Weapons"
TOOL.Name = "#tool.weapons_link_tool.name"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" },
}

-- the weapons an Apple Core can steer (they read WireActive, WireShoot, WireVec, WireEnt)
local LINKABLE = {
	sg_turret_destmain = true, sg_turret_destmed = true, sg_turret_destsmall = true, sg_turret_shiprail = true,
	sg_turret_tollan = true, asgard_beam = true, ori_beam_cannon = true, vanir_plasma_cannon = true,
	wraith_plasma_cannon = true,
}
local SELECTED = Color(100, 255, 255, 255)

local function L(key, fallback)
	if (AGP and AGP.L) then return AGP.L(key, fallback) end
	return fallback
end

local function IsCore(e)
	return IsValid(e) and e:GetClass() == "apple_core"
end

-- AGP 2026-11-08: one selection per player (it was one table for everybody: player B could link A's selection).
-- [weapon] = its colour before it was selected (was always set back to white)
local function Selection(ply)
	ply.AGPWeaponLinkSel = ply.AGPWeaponLinkSel or {}
	return ply.AGPWeaponLinkSel
end

local function ClearSelection(ply)
	for e, col in pairs(ply.AGPWeaponLinkSel or {}) do
		if (IsValid(e)) then e:SetColor(col) end
	end
	ply.AGPWeaponLinkSel = {}
end

if CLIENT then
	language.Add("tool.weapons_link_tool.name", L("agp_tool_weapons_link_name", "Weapon Link Tool"))
	language.Add("tool.weapons_link_tool.desc", L("agp_tool_weapons_link_desc", "Links weapons to an Apple Core, which fires them all by Wire"))
	language.Add("tool.weapons_link_tool.left", L("agp_tool_weapons_link_left", "Select a weapon (click again to deselect)"))
	language.Add("tool.weapons_link_tool.right", L("agp_tool_weapons_link_right", "Link the selected weapons to this Apple Core"))
	language.Add("tool.weapons_link_tool.reload", L("agp_tool_weapons_link_reload", "Clear the selection (on an Apple Core: remove all its links)"))

	function TOOL.BuildCPanel(panel)
		panel:Help(L("agp_tool_weapons_link_help", "Select turrets, beam weapons and cannons with left click (they turn blue), then right click an Apple Core. Its Wire inputs Active, Fire, Vector and Entity then steer all linked weapons. Needs Wiremod."))
	end
end

if SERVER then
	-- a player leaving with weapons still selected: give them their colour back
	hook.Add("PlayerDisconnected", "AGP.WeaponLinkTool", ClearSelection)
end

function TOOL:LeftClick(tr)
	local e = tr.Entity
	-- AGP 2026-11-08: no WireLib.GetPorts call any more (unused; a Lua error without Wiremod)
	if (not IsValid(e) or not LINKABLE[e:GetClass()]) then return false end
	if (CLIENT) then return true end
	local sel = Selection(self:GetOwner())
	if (sel[e]) then
		e:SetColor(sel[e])
		sel[e] = nil
	else
		sel[e] = e:GetColor()
		e:SetColor(SELECTED)
	end
	return true
end

function TOOL:RightClick(tr)
	local core = tr.Entity
	-- AGP 2026-11-08: was "!x:GetClass() == "apple_core"" (always false): anything else gave a server error
	if (not IsCore(core)) then return false end
	if (CLIENT) then return true end
	local ply = self:GetOwner()
	core.Weapons = core.Weapons or {}
	local n = 0
	for e, col in pairs(Selection(ply)) do
		if (IsValid(e)) then
			e:SetColor(col)
			if (not table.HasValue(core.Weapons, e)) then table.insert(core.Weapons, e) end
			n = n + 1
		end
	end
	ply.AGPWeaponLinkSel = {}
	if (n == 0) then return false end
	if (core.CountWeaps) then core:CountWeaps() end
	if (AGP and AGP.Say) then AGP.Say(ply, "agp_tool_weapons_link_linked", "%d weapon(s) linked to the Apple Core.", n) end
	return true
end

function TOOL:Reload(tr)
	local core = tr.Entity
	-- AGP 2026-11-08: ClearWeaps exists only on the server (the client part errored here)
	if (CLIENT) then return IsCore(core) end
	local ply = self:GetOwner()
	if (IsCore(core)) then
		if (core.ClearWeaps) then core:ClearWeaps() end
		if (AGP and AGP.Say) then AGP.Say(ply, "agp_tool_weapons_link_cleared", "All weapon links of this Apple Core removed.") end
		return true
	end
	ClearSelection(ply)
	return false
end
