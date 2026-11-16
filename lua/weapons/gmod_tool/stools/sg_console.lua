--[[
	Console tool - Ascension Gates' own code (2026-11-07); no Evolution Addon Pack code left. Spawns the Stargate
	console (sg_console) with one of the console models below, welded to what you click if you like.
]]
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("extra") or SGLanguage == nil or SGLanguage.GetMessage == nil) then return end
include("weapons/gmod_tool/stargate_base_tool.lua")

TOOL.Category = "Tech"
TOOL.Name = SGLanguage.GetMessage("stool_console")
TOOL.ClientConVar["autoweld"] = 1
TOOL.ClientConVar["model"] = "models/MarkJaw/atlantis_console/console.mdl"
TOOL.List = "SGConsoleModels" -- AGP 2026-11-08: own list; "ConsoleModels" was shared with cappanel.lua (each picker showed both tools' models)
-- the two Atlantis consoles from CAP, our Destiny bar (its lights come on with the console's)
list.Set(TOOL.List, "models/MarkJaw/atlantis_console/console.mdl", {})
list.Set(TOOL.List, "models/ZsDaniel/atlantis_console/console.mdl", {})
list.Set(TOOL.List, "models/agp/props/agp_destiny_bar.mdl", {})

TOOL.Entity.Class = "sg_console"
TOOL.Entity.Keys = { "model" }   -- saved by the duplicator
TOOL.Entity.Limit = 50
TOOL.Topic["name"] = SGLanguage.GetMessage("stool_console_spawner")
TOOL.Topic["desc"] = SGLanguage.GetMessage("stool_console_create")
TOOL.Topic[0] = SGLanguage.GetMessage("stool_console_desc")
TOOL.Language["Undone"] = SGLanguage.GetMessage("stool_console_undone")
TOOL.Language["Cleanup"] = SGLanguage.GetMessage("stool_console_cleanup")
TOOL.Language["Cleaned"] = SGLanguage.GetMessage("stool_console_cleaned")
TOOL.Language["SBoxLimit"] = SGLanguage.GetMessage("stool_console_limit")

function TOOL:LeftClick(t)
    if (t.Entity and t.Entity:IsPlayer()) then return false end
    if (CLIENT) then return true end
    if (not self:CheckLimit()) then return false end
    local p = self:GetOwner()
    local e = self:SpawnSENT(p, t, self:GetClientInfo("model"))
    if (not IsValid(e)) then return false end
    local weld = self:Weld(e, t.Entity, tobool(self:GetClientNumber("autoweld")))
    self:AddUndo(p, e, weld)
    self:AddCleanup(p, weld, e)
    return true
end

function TOOL:PreEntitySpawn(p, e, model)
    e:SetModel(model)
end

function TOOL:ControlsPanel(Panel)
    Panel:AddControl("PropSelect", { Label = SGLanguage.GetMessage("stool_model"), ConVar = "sg_console_model", Category = "", Models = self.Models })
    Panel:CheckBox(SGLanguage.GetMessage("stool_autoweld"), "sg_console_autoweld")
end

TOOL:Register()
