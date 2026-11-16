--[[
	ZPM MK III Spawn Tool for GarrysMod10
	Copyright (C) 2010 Llapp
]]
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy") or SGLanguage == nil or SGLanguage.GetMessage == nil) then return end
include("weapons/gmod_tool/stargate_base_tool.lua")
TOOL.Category = "Energy"
TOOL.Name = "Powercell"
TOOL.ClientConVar["autolink"] = 1
TOOL.ClientConVar["autoweld"] = 1
TOOL.ClientConVar["capacity"] = 100
-- AGP 2026-11-08: our own model, PowerGrid's smallest cell (Half-Life 2's car battery only when PowerGrid's models
-- are missing; same rule as the entity). The old one, models/props_phx/life_support/battery_small.mdl, came only with
-- Spacebuild: without it every click just said "Spacebuild is required". Always this model (players may still have
-- the old path saved in powercell_small_model).
local function cellModel()
    local own = "models/agp_power/agp_cell_xs.mdl"
    return util.IsValidModel(own) and own or "models/items/car_battery01.mdl"
end
TOOL.ClientConVar["model"] = "models/agp_power/agp_cell_xs.mdl"
TOOL.Entity.Class = "powercell_small"
TOOL.Entity.Keys = {"model"}
TOOL.Entity.Limit = 6
TOOL.Topic["name"] = "Powercell"
TOOL.Topic["desc"] = "This is a Powercell"
TOOL.Topic[0] = "Click to spawn a Powercell"
TOOL.Language["Undone"] = "Powercell removed"
TOOL.Language["Cleanup"] = "Powercell removed"
TOOL.Language["Cleaned"] = "Powercell removed"
TOOL.Language["SBoxLimit"] = "Powercell: Limit reached"

function TOOL:LeftClick(t)
    local p = self:GetOwner()
    if (t.Entity and t.Entity:IsPlayer()) then return false end
    if (t.Entity and t.Entity:GetClass() == self.Entity.Class) then return false end
    if (CLIENT) then return true end

    -- AGP 2026-11-08: no Spacebuild check any more (see cellModel above)
    if (not self:CheckLimit()) then return false end

    local e = self:SpawnSENT(p, t, cellModel())
    if (not IsValid(e)) then return false end
    local weld = util.tobool(self:GetClientNumber("autoweld"))

    if (SERVER and t.Entity and t.Entity.ZPMHub) then
        t.Entity:Touch(e)
        weld = false
    elseif (util.tobool(self:GetClientNumber("autolink"))) then
        self:AutoLink(e, t.Entity)
    end

    local c = self:Weld(e, t.Entity, weld)
    local capacity = tonumber(self:GetClientInfo("capacity")) or 100
    e.Energy = (e.Energy / 100) * math.Clamp(capacity, 0, 100)
    self:AddUndo(p, e, c)
    self:AddCleanup(p, c, e)

    return true
end

function TOOL:PreEntitySpawn(p, e, model)
    e:SetModel(cellModel()) -- AGP 2026-11-08: old dupes still carry Spacebuild's model path
end

-- AGP 2026-11-08: the ghost always shows the real model, not a path saved in the player's convar
function TOOL:DrawGhostEntity()
    if (not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= cellModel()) then
        self:MakeGhostEntity(cellModel(), Vector(0, 0, 0), Angle(0, 0, 0))
    end
    self:UpdateGhostSENT(self.GhostEntity, self:GetOwner())
end

function TOOL:ControlsPanel(Panel)
    Panel:NumSlider(AGP.L("agp_ui_powercell_capacity", "Powercell Capacity"), "powercell_small_capacity", 0, 100, 4)

    if (StarGate.HasResourceDistribution) then
        -- AGP 2026-11-08: was bound to zpm_mk3_autolink (changed the ZPM tool, not this one); own setting now
        Panel:CheckBox(AGP.L("agp_ui_autolink_short", "Autolink"), "powercell_small_autolink"):SetToolTip(AGP.L("agp_ui_autolink", "Link to a resource node automatically"))
    end
end

TOOL:Register()