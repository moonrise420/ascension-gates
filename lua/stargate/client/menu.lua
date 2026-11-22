--[[
	Stargate Lib for GarrysMod10
	Copyright (C) 2007-2009  aVoN

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]
--[[
	Carter's Addon Pack Tab for GarrysMod10
	Copyright (C) 2010  Llapp
]]
--################# Loads the menues #################
--################ Check for visuals (used in effects) @aVoN
function StarGate.VisualsShips(str)
    if (LocalPlayer() and LocalPlayer().GetInfo and util.tobool(LocalPlayer():GetInfo("cl_stargate_visualsship")) and util.tobool(LocalPlayer():GetInfo(str))) then return true end

    return false
end

function StarGate.VisualsWeapons(str)
    if (LocalPlayer() and LocalPlayer().GetInfo and util.tobool(LocalPlayer():GetInfo("cl_stargate_visualsweapon")) and util.tobool(LocalPlayer():GetInfo(str))) then return true end

    return false
end

function StarGate.VisualsMisc(str, ignore)
    if (LocalPlayer() and LocalPlayer().GetInfo and (util.tobool(LocalPlayer():GetInfo("cl_stargate_visualsmisc")) or ignore) and util.tobool(LocalPlayer():GetInfo(str))) then return true end

    return false
end

--################ Reset values to 0, if this user just updated to this version @aVoN
-- The reason is, some dynamic lights crash players. So I want to have them disabled by default.
-- But sadly they already have the necessary CVAR set to 1. So I reset it to 0 once.
-- Now if they reset it to 1 it will keep of course at 1.
local ResetDynamicLights = CreateClientConVar("cl_reset_dynamic_lights", 0, true, false)

function StarGate.Hook.ResetDynamicLights(_, key)
    if (key ~= "+menu") then return end

    if (not ResetDynamicLights:GetBool()) then
        local dynlights = {"cl_stargate_dynlights", "cl_shield_dynlights", "cl_harvester_dynlights", "cl_supergate_dynlights", "cl_applecore_light", "cl_jumper_dynlights", "cl_chair_dynlights", "cl_zat_dynlights", "cl_staff_dynlights", "cl_staff_dynlights_flight", "cl_gate_nuke_dynlights", "cl_overloader_dynlights", "cl_asuran_dynlights", "cl_oribeam_dynlights"}

        for _, v in pairs(dynlights) do
            RunConsoleCommand(v, "0")
        end

        RunConsoleCommand("cl_reset_dynamic_lights", 1)
    end

    hook.Remove("PlayerBindPress", "StarGate.Hook.ResetDynamicLights")
end

hook.Add("PlayerBindPress", "StarGate.Hook.ResetDynamicLights", StarGate.Hook.ResetDynamicLights)

-- AGP: the horizon's refraction ("Draw ripple on the Eventhorizon") became on by default. A config saved before
-- keeps CAP's old 0, so it is switched on once; a player who turns it off afterwards keeps it off.
local RippleDefaultOn = CreateClientConVar("agp_ripple_default_on", 0, true, false)
hook.Add("InitPostEntity", "AGP.RippleDefaultOn", function()
    if (RippleDefaultOn:GetBool()) then return end
    RunConsoleCommand("cl_stargate_ripple", "1")
    RunConsoleCommand("agp_ripple_default_on", "1")
end)

spawnmenu.AddContentType("cap_npc", function(container, obj)
    if (not obj.material) then return end
    if (not obj.nicename) then return end
    if (not obj.spawnname) then return end
    local gmod_npcweapon = GetConVar("gmod_npcweapon") or CreateConVar("gmod_npcweapon", "", {FCVAR_ARCHIVE})

    if (not obj.weapon) then
        obj.weapon = gmod_npcweapon:GetString()
    end

    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("npc")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)

    icon.SetAdminOnly = function(self, admin)
        if (admin) then
            self.imgAdmin = vgui.Create("DImage", self)
            self.imgAdmin:SetImage("icon16/shield.png")
            self.imgAdmin:SetSize(16, 16)
            self.imgAdmin:SetPos(self:GetWide() - 22, 5)
            self.imgAdmin:SetTooltip((AGP and AGP.L and AGP.L("agp_ui_admin_only", "Admin only") or "Admin only"))
        end
    end

    icon:SetAdminOnly(obj.admin)
    icon:SetNPCWeapon(obj.weapon)
    icon:SetColor(Color(244, 164, 96, 255))
    local Tooltip = Format("%s", obj.nicename)

    if (obj.author) then
        Tooltip = Format("%s\n" .. SGLanguage.GetMessage("cap_menu_author") .. ": %s", Tooltip, obj.author)
    end

    icon:SetTooltip(Tooltip)

    icon.DoClick = function()
        local weapon = obj.weapon

        if (gmod_npcweapon:GetString() ~= "") then
            weapon = gmod_npcweapon:GetString()
        end

        RunConsoleCommand("cap_spawnnpc", obj.spawnname, weapon)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function(icon)
        local menu = DermaMenu()
        local weapon = obj.weapon

        if (gmod_npcweapon:GetString() ~= "") then
            weapon = gmod_npcweapon:GetString()
        end

        menu:AddOption((AGP and AGP.L and AGP.L("agp_ui_copy", "Copy to clipboard") or "Copy to clipboard"), function()
            SetClipboardText(obj.spawnname)
        end)

        menu:AddOption((AGP and AGP.L and AGP.L("agp_ui_spawn_toolgun", "Spawn with the tool gun") or "Spawn with the tool gun"), function()
            RunConsoleCommand("gmod_tool", "cap_creator")
            RunConsoleCommand("cap_creator_type", "2")
            RunConsoleCommand("cap_creator_name", obj.spawnname)
            RunConsoleCommand("cap_creator_arg", weapon)
        end)

        menu:Open()
    end

    if (IsValid(container)) then
        container:Add(icon)
    end

    return icon
end)

spawnmenu.AddContentType("cap_entity", function(container, obj)
    if (not obj.material) then return end
    if (not obj.nicename) then return end
    if (not obj.spawnname) then return end
    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("entity")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)

    icon.SetAdminOnly = function(self, admin)
        if (admin) then
            self.imgAdmin = vgui.Create("DImage", self)
            self.imgAdmin:SetImage("icon16/shield.png")
            self.imgAdmin:SetSize(16, 16)
            self.imgAdmin:SetPos(self:GetWide() - 22, 5)
            self.imgAdmin:SetTooltip((AGP and AGP.L and AGP.L("agp_ui_admin_only", "Admin only") or "Admin only"))
        end
    end

    icon:SetAdminOnly(obj.admin)
    local Tooltip = Format("%s", obj.nicename)

    if (obj.author) then
        Tooltip = Format("%s\n" .. SGLanguage.GetMessage("cap_menu_author") .. ": %s", Tooltip, obj.author)
    end

    if (obj.info and obj.info ~= "") then
        Tooltip = Format("%s\n\n%s", Tooltip, obj.info)
    end

    icon:SetTooltip(Tooltip)
    icon:SetColor(Color(205, 92, 92, 255))

    icon.DoClick = function()
        RunConsoleCommand("cap_spawnsent", obj.spawnname)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function(icon)
        local menu = DermaMenu()

        menu:AddOption((AGP and AGP.L and AGP.L("agp_ui_copy", "Copy to clipboard") or "Copy to clipboard"), function()
            SetClipboardText(obj.spawnname)
        end)

        menu:AddOption((AGP and AGP.L and AGP.L("agp_ui_spawn_toolgun", "Spawn with the tool gun") or "Spawn with the tool gun"), function()
            RunConsoleCommand("gmod_tool", "cap_creator")
            RunConsoleCommand("cap_creator_type", "0")
            RunConsoleCommand("cap_creator_name", obj.spawnname)
        end)

        menu:Open()
    end

    if (IsValid(container)) then
        container:Add(icon)
    end

    return icon
end)

spawnmenu.AddContentType("cap_weapon", function(container, obj)
    if (not obj.material) then return end
    if (not obj.nicename) then return end
    if (not obj.spawnname) then return end
    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("weapon")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)

    icon.SetAdminOnly = function(self, admin)
        if (admin) then
            self.imgAdmin = vgui.Create("DImage", self)
            self.imgAdmin:SetImage("icon16/shield.png")
            self.imgAdmin:SetSize(16, 16)
            self.imgAdmin:SetPos(self:GetWide() - 22, 5)
            self.imgAdmin:SetTooltip((AGP and AGP.L and AGP.L("agp_ui_admin_only", "Admin only") or "Admin only"))
        end
    end

    icon:SetAdminOnly(obj.admin)
    local Tooltip = Format("%s", obj.nicename)

    if (obj.author) then
        Tooltip = Format("%s\n" .. SGLanguage.GetMessage("cap_menu_author") .. ": %s", Tooltip, obj.author)
    end

    if (obj.info and obj.info ~= "") then
        Tooltip = Format("%s\n\n%s", Tooltip, obj.info)
    end

    icon:SetTooltip(Tooltip)
    icon:SetColor(Color(135, 206, 250, 255))

    icon.DoClick = function()
        RunConsoleCommand("cap_giveswep", obj.spawnname)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.DoMiddleClick = function()
        RunConsoleCommand("cap_spawnswep", obj.spawnname)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function(icon)
        local menu = DermaMenu()

        menu:AddOption((AGP and AGP.L and AGP.L("agp_ui_copy", "Copy to clipboard") or "Copy to clipboard"), function()
            SetClipboardText(obj.spawnname)
        end)

        menu:AddOption((AGP and AGP.L and AGP.L("agp_ui_spawn_toolgun", "Spawn with the tool gun") or "Spawn with the tool gun"), function()
            RunConsoleCommand("gmod_tool", "cap_creator")
            RunConsoleCommand("cap_creator_type", "3")
            RunConsoleCommand("cap_creator_name", obj.spawnname)
        end)

        menu:Open()
    end

    if (IsValid(container)) then
        container:Add(icon)
    end

    return icon
end)

-- AGP: one clean set of categories for the entities of our tab. The entities set all kinds of names themselves
-- ("Ships", "Ascension Gates: Ships", "Misc devices", "Misc Devices", "Others" ...): each name goes to one group here,
-- a few classes get their own group by name.
local function msg(key, fallback)
    if (SGLanguage and SGLanguage.ValidMessage and SGLanguage.ValidMessage(key)) then return SGLanguage.GetMessage(key) end
    return fallback
end
local AGP_CLASS_GROUP = {
    control_chair = "weapons",            -- the Ancient drone chair is a weapon, not a ship
    agp_goauld_power_hub = "power", agp_goauld_power_crystal = "power",
    -- two ship categories - "capital" = walk-in motherships with a TARDIS interior (bigger inside), everything else
    -- that flies (big or small, really hollow or not) is "ships"
    agp_hatak = "capital",
    sg_vehicle_prometheus = "ships",
    -- "Misc devices" was one long list - split up; our energy devices go to SpaceGrid
    black_hole_power = "power", powercell_small = "power", zpm_analyser = "power", zpm_analyser_mk2 = "power",
    ancient_obelisk = "tech", sodan_obelisk = "tech", apple_core = "tech", arthur_mantle = "tech", lantean_holo = "tech",
    telchak = "tech", sarcophagus = "tech", comstones_stone = "tech", comstones_tablet = "tech", anti_prior = "tech",
    molecular_construction_device = "tech", industrial_molecular_construction_device = "tech", shield_core = "tech",
    destiny_console = "tech", destiny_timer = "tech",
    destiny_node = "power",   -- the Destiny Power Node is a network part of PowerGrid
    atlantis_transporter = "transport", transporter = "transport", malp = "transport", kino_dispenser = "transport",
    ship_hangar = "transport",
    call_forwarding_device = "gates", iris_computer = "gates",
    agp_brazier = "base", agp_force_field = "base", agp_goauld_door = "base", goauld_armory = "base", tauri_armory = "base",
}
local AGP_NAME_GROUP = {
    ["ascension gates: gates and rings"] = "gates", ["stargates and rings"] = "gates",
    ["ascension gates: weapons"] = "weapons", ["weapons"] = "weapons",
    ["ascension gates: ships"] = "ships", ["ships"] = "ships",
    ["capital ships"] = "ships",   -- old CAP/EAP big ships are no walk-in motherships
    ["agp power"] = "power", ["grid power"] = "power", ["powergrid"] = "power",   -- PowerGrid's parts (own addon)
    ["replicators"] = "replicators",   -- our own Replicators (block, bug, queen)
}
local AGP_GROUP_NAME = {
    gates = function() return msg("stargate_category", "StarGates and Rings") end,
    weapons = function() return msg("entity_weapon_cat", "Weapons") end,
    ships = function() return msg("agp_cat_fleet", "Fleet: Ships and Fighters") end,
    capital = function() return msg("agp_cat_walkin", "Bigger Motherships") end,
    power = function() return msg("agp_cat_spacegrid", "PowerGrid") end,
    replicators = function() return msg("agp_cat_replicators", "Replicators") end,
    tech = function() return msg("agp_cat_tech", "Ancient and Alien Tech") end,
    transport = function() return msg("agp_cat_transport", "Transport and Exploration") end,
    base = function() return msg("agp_cat_base", "Base and Ship Fittings") end,
    misc = function() return msg("entity_main_cat", "Misc devices") end,
}
function StarGate.TabCategory(ent)
    local g = AGP_CLASS_GROUP[ent.ClassName or ""]
    if (not g) then
        local c = tostring(ent.Category or ""):lower()
        g = AGP_NAME_GROUP[c]
        if (not g) then   -- already translated names
            for key, grp in pairs({ stargate_category = "gates", entity_weapon_cat = "weapons", entity_ships_cat = "ships", cat_small_ship = "ships", cat_capital_ship = "ships" }) do
                if (c == tostring(msg(key, "")):lower()) then g = grp break end
            end
        end
    end
    return AGP_GROUP_NAME[g or "misc"]()
end

-- the PowerGrid list sorted by role, inside a role by size, not by name. 1xx sources (small
-- to large, the endless ones last), 2xx storage, 3xx network, 4xx life support, 5xx tools. Classes not listed
-- here come after these, by name.
local AGP_POWER_ORDER = {}
for i, cls in ipairs({
    "agp_solar_small", "agp_solar_large", "agp_wind_turbine", "ion_generator", "agp_goauld_power_hub",
    "black_hole_power", "asgard_ion_generator", "agp_reactor_core",
}) do AGP_POWER_ORDER[cls] = 100 + i end
for i, cls in ipairs({
    "powercell_small", "agp_cell_xs", "agp_cell_small", "agp_cell_medium", "agp_cell_large", "agp_cell_xl",
    "agp_goauld_power_crystal",
    "agp_tank_xs", "agp_tank_small", "agp_tank_medium", "agp_tank_large", "agp_tank_xl",
    "agp_blackhole_cache",
}) do AGP_POWER_ORDER[cls] = 200 + i end
for i, cls in ipairs({
    "agp_power_node_xs", "agp_power_node_small", "agp_power_node_medium", "agp_power_node_large", "destiny_node",
    "agp_power_pump", "agp_display_small", "agp_display_large",
}) do AGP_POWER_ORDER[cls] = 300 + i end
for i, cls in ipairs({
    "agp_ls_core", "agp_air_compressor", "agp_water_pump", "agp_suit_dispenser",
    "agp_ls_heater_small", "agp_ls_heater", "agp_ls_heater_large", "agp_ls_heater_xl",
    "agp_ls_cooler_small", "agp_ls_cooler", "agp_ls_cooler_large", "agp_ls_cooler_xl",
}) do AGP_POWER_ORDER[cls] = 400 + i end
for i, cls in ipairs({ "zpm_analyser", "zpm_analyser_mk2" }) do AGP_POWER_ORDER[cls] = 500 + i end

-- the entities of one group in menu order: PowerGrid by AGP_POWER_ORDER, every other group by name (as before)
local function GroupOrder(CategoryName, v)
    local out = {}
    for _, ent in pairs(v) do out[#out + 1] = ent end
    local power = (CategoryName == AGP_GROUP_NAME.power())
    local function name(ent) return tostring(ent.PrintName or ent.__ClassName or "") end
    table.sort(out, function(a, b)
        if (power) then
            local ra, rb = AGP_POWER_ORDER[a.ClassName or ""] or 9000, AGP_POWER_ORDER[b.ClassName or ""] or 9000
            if (ra ~= rb) then return ra < rb end
        end
        return name(a) < name(b)
    end)
    return out
end

local function StargateAddTab(Categorised, pnlContent, tree, node)
    --
    -- Add a tree node for each category
    --
    -- AGP: groups by name as before, but PowerGrid as the last group of the entities, so it sits right above the
    -- player weapons (they follow in their own pass)
    local powerName = AGP_GROUP_NAME.power()
    local order = {}
    for CategoryName in SortedPairs(Categorised) do
        if (CategoryName ~= powerName) then order[#order + 1] = CategoryName end
    end
    if (Categorised[powerName]) then order[#order + 1] = powerName end

    for _, CategoryName in ipairs(order) do
        local v = Categorised[CategoryName]
        -- Add a node to the tree
        local icon = "icon16/bricks.png"
        local enttype = v[1].__enttype
        local adminonly, disabled = "ent_groups_only", "cap_disabled_ent"
        if (CategoryName == powerName and enttype == "cap_entity") then icon = "icon16/lightning.png" end   -- thunderbolt
        if (CategoryName == AGP_GROUP_NAME.replicators() and enttype == "cap_entity") then icon = "agp/icon16_replicator.png" end

        if (enttype == "cap_weapon") then
            icon = "icon16/gun.png"
            adminonly, disabled = "swep_groups_only", "cap_disabled_swep"
        end

        if (enttype == "cap_npc") then
            icon = "icon16/monkey.png"
            adminonly, disabled = "npc_groups_only", "cap_disabled_npc"
        end

        if (enttype == "cap_npc") then
            -- Add a node to the tree
            local node = tree:AddNode(CategoryName, icon)

            -- When we click on the node - populate it using this function
            node.DoPopulate = function(self)
                -- If we've already populated it - forget it.
                if (self.PropPanel) then return end
                -- Create the container panel
                self.PropPanel = vgui.Create("ContentContainer", pnlContent)
                self.PropPanel:SetVisible(false)
                self.PropPanel:SetTriggerSpawnlistChange(false)

                for name, ent in SortedPairsByMemberValue(v, "Name") do
                    if (StarGate.CFG:Get(disabled, ent.__ClassName, false)) then continue end
                    local adm_only = false
                    local tbl = StarGate.CFG:Get(adminonly, ent.__ClassName, ""):TrimExplode(",")

                    if (table.HasValue(tbl, "add_shield")) then
                        adm_only = true
                    end

                    local weapon = ""

                    if (ent.Weapons) then
                        weapon = ent.Weapons[1]
                    end

                    spawnmenu.CreateContentIcon("cap_npc", self.PropPanel, {
                        nicename = ent.Name,
                        spawnname = ent.__ClassName,
                        material = "entities/" .. ent.__ClassName .. ".png",
                        weapon = weapon,
                        admin = adm_only,
                        author = ent.Author
                    })
                end
            end

            -- If we click on the node populate it and switch to it.
            node.DoClick = function(self)
                self:DoPopulate()
                pnlContent:SwitchPanel(self.PropPanel)
            end
        else
            local node = tree:AddNode(CategoryName, icon)

            -- When we click on the node - populate it using this function
            node.DoPopulate = function(self)
                -- If we've already populated it - forget it.
                if (self.PropPanel) then return end
                -- Create the container panel
                self.PropPanel = vgui.Create("ContentContainer", pnlContent)
                self.PropPanel:SetVisible(false)
                self.PropPanel:SetTriggerSpawnlistChange(false)

                for _, ent in ipairs(GroupOrder(CategoryName, v)) do
                    if (ent.ClassName == nil or StarGate.CFG:Get(disabled, ent.ClassName, false)) then continue end
                    local adm_only = false
                    local tbl = StarGate.CFG:Get(adminonly, ent.ClassName, ""):TrimExplode(",")

                    if (table.HasValue(tbl, "add_shield")) then
                        adm_only = true
                    end

                    spawnmenu.CreateContentIcon(enttype, self.PropPanel, {
                        nicename = ent.PrintName or ent.__ClassName,
                        spawnname = ent.ClassName,
                        material = "entities/" .. ent.ClassName .. ".png",
                        admin = adm_only,
                        author = ent.Author,
                        info = ent.Instructions
                    })
                end
            end

            -- If we click on the node populate it and switch to it.
            node.DoClick = function(self)
                self:DoPopulate()
                pnlContent:SwitchPanel(self.PropPanel)
            end
        end
    end
end

hook.Add("StargateTab", "AddEntityContent", function(pnlContent, tree, node)
    local Categorised = {}
    -- Add this list into the tormoil
    local SpawnableEntities = list.Get("CAP.Entity")

    if (SpawnableEntities) then
        for k, v in pairs(SpawnableEntities) do
            v.__ClassName = k
            v.__enttype = "cap_entity"
            local cat = StarGate.TabCategory(v)
            Categorised[cat] = Categorised[cat] or {}
            table.insert(Categorised[cat], v)
        end
    end
    -- AGP: the Replicators get their own group right above the NPCs (after the weapons)
    local repName = AGP_GROUP_NAME.replicators()
    local Replicators = Categorised[repName]
    Categorised[repName] = nil

    StargateAddTab(Categorised, pnlContent, tree, node)
    Categorised = {}
    -- Loop through the weapons and add them to the menu
    local Weapons = list.Get("CAP.Weapon")

    -- Build into categories
    for k, weapon in pairs(Weapons) do
        weapon.__ClassName = k
        weapon.__enttype = "cap_weapon"
        Categorised[weapon.Category] = Categorised[weapon.Category] or {}
        table.insert(Categorised[weapon.Category], weapon)
    end

    StargateAddTab(Categorised, pnlContent, tree, node)
    if (Replicators) then StargateAddTab({ [repName] = Replicators }, pnlContent, tree, node) end
    Categorised = {}
    -- Get a list of available NPCs
    local NPCList = list.Get("CAP.NPC")

    -- Categorize them
    for k, v in pairs(NPCList) do
        local Category = v.Category or "Other"
        local Tab = Categorised[Category] or {}
        --Tab[ k ] = v
        v.__enttype = "cap_npc"
        v.__ClassName = k
        Categorised[Category] = Tab
        table.insert(Categorised[Category], v)
    end

    StargateAddTab(Categorised, pnlContent, tree, node)

    if (StarGate.CheckModule("misc")) then
        local node = tree:AddNode(SGLanguage.GetMessage("cap_prop_cat"), "icon16/folder.png", true)
        local self = node
        -- If we've already populated it - forget it.
        if (self.PropPanel) then return end
        self.PropPanel = vgui.Create("ContentContainer", pnlContent)
        self.PropPanel:SetVisible(false)
        local spl = {"Misc", "CapBuild", "CatWalkBuild"} -- for order

        for i = 1, 3 do
            local spawnlist = StarGate.SpawnList[spl[i]]

            if (spawnlist) then
                local models = node:AddNode(SGLanguage.GetMessage("cap_prop_cat" .. i), "icon16/page.png")

                models.DoPopulate = function(self)
                    -- If we've already populated it - forget it.
                    if (self.PropPanel) then return end
                    self.PropPanel = vgui.Create("ContentContainer", pnlContent)
                    self.PropPanel:SetVisible(false)
                    local lines = StarGate.SpawnList[spl[i]]

                    for _, l in pairs(lines) do
                        if (not l or l == "") then continue end
                        local cp = spawnmenu.GetContentType("model")

                        if (cp) then
                            cp(self.PropPanel, {
                                model = l
                            })
                        end
                    end
                end

                models.DoClick = function(self)
                    self:DoPopulate()
                    pnlContent:SwitchPanel(self.PropPanel)
                end
            end
        end
    end

    local node = tree:AddNode(SGLanguage.GetMessage("spawninfo_title"), "icon16/information.png", true)
    -- AGP: our info screen + the projects this pack is built on (credits); no news/forum/donate links of CAP
    local cats = {{(SGLanguage.ValidMessage("agp_wiki_menu") and SGLanguage.GetMessage("agp_wiki_menu")) or "Help (Wiki)", "agp_wiki", "icon16/book_open.png"},
        {(SGLanguage.ValidMessage("agp_about") and SGLanguage.GetMessage("agp_about")) or "About Ascension Gates", "agp_info", "icon16/star.png"},
        {"Carter's Addon Pack (GitHub)", "https://github.com/RafaelDeJongh/cap", "icon16/heart.png"},
        {"CAP Enhanced (Steam Workshop)", "https://steamcommunity.com/sharedfiles/filedetails/?id=3021712722", "icon16/heart.png"}}
    for i, l in ipairs(AGP and AGP.LinkList and AGP.LinkList() or {}) do table.insert(cats, 1 + i, { l[1], l[2], "icon16/world.png" }) end

    for k, v in pairs(cats) do
        local panel = node:AddNode(v[1], v[3])

        -- this code is buggy, can't understand why i can't enter data into textbox, so using steam browser instead.
        panel.DoClick = function(self)
            if (v[2] == "agp_info" or v[2] == "agp_wiki") then RunConsoleCommand(v[2]) else gui.OpenURL(v[2]) end
        end
    end

    -- Select the first node
    local FirstNode = tree:Root():GetChildNode(0)

    if (IsValid(FirstNode)) then
        FirstNode:InternalDoClick()
    end
end)


--################# Adds the tab to the spawnmenu @aVoN
--
function StarGate.Hook.AddToolTab()

    -- Add Tab
    -- local logo;
    -- if(file.Exists("materials/gui/cap_logo","GAME")) then logo = "gui/cap_logo" end;
    local cat_name = "Stargate"

    -- AGP: our own tab name and logo (the internal tool tab id stays "Stargate", every tool uses it)
    spawnmenu.AddCreationTab("Ascension Gates", function()
        local ctrl = vgui.Create("SpawnmenuContentPanel")
        ctrl:CallPopulateHook("StargateTab")

        return ctrl
    end, "gui/agp_logo.png", 60.01)   -- (Ascension Gates 60.01, SpaceGrid 60.02, PowerGrid 60.03 - right after the Vehicles tab, and after other addons' 60 such as VJ Base and Pills, so ours stay side by side)

    spawnmenu.AddToolTab(cat_name, "Ascension Gates", "gui/agp_logo.png")
    -- AGP: SpaceGrid, our own tab for everything energy and life support (like Spacebuild's tabs): the Grid Power parts,
    -- the energy tools (ZPMs, hubs, naquadah, Goa'uld power, power link) and the power settings
    spawnmenu.AddToolTab("SpaceGrid", "PowerGrid", "icon16/lightning.png") -- shown as "PowerGrid" (the id stays SpaceGrid for the tools)
    spawnmenu.AddToolCategory("SpaceGrid", "Connector", " " .. msg("agp_cat_connector", "Connect Power"))   -- the Grid Power Connector on its own, first
    spawnmenu.AddToolCategory("SpaceGrid", "Grid Power", " " .. msg("agp_cat_power", "PowerGrid"))
    spawnmenu.AddToolCategory("SpaceGrid", "Energy", " " .. msg("stool_cat_energy", "Energy"))
    spawnmenu.AddToolCategory("SpaceGrid", "Settings", " " .. msg("agp_cat_settings", "Settings"))
    -- Add Config Category
    local config_name = "Config"
    local keys_name = "Keybinders"

    if (StarGate.CheckModule("base")) then
        spawnmenu.AddToolCategory(cat_name, config_name, " " .. config_name)
    end

    if (StarGate.CheckModule("base")) then
        spawnmenu.AddToolCategory(cat_name, "Tech", "Tech")
    end


    if (StarGate.CheckModule("entweapon")) then
        spawnmenu.AddToolCategory(cat_name, "Weapons", "Weapons")
    end

    if (StarGate.CheckModule("extra")) then
        spawnmenu.AddToolCategory(cat_name, "Ramps", "Ramps")
    end

    if (StarGate.CheckModule("base") or StarGate.CheckModule("ships")) then
        spawnmenu.AddToolCategory(cat_name, keys_name, keys_name)
    end

    local function ML(k, f) return (SGLanguage.ValidMessage(k) and SGLanguage.GetMessage(k)) or f end
    -- Add the entry for config
    spawnmenu.AddToolMenuOption(cat_name, config_name, "Credits", " " .. ((SGLanguage.ValidMessage("agp_menu_about_credits") and SGLanguage.GetMessage("agp_menu_about_credits")) or "About & Credits"), "", "", StarGate.Update_Check)
    spawnmenu.AddToolMenuOption(cat_name, config_name, "Settings/Language", " " .. ML("agp_menu_settings", "Language"), "", "", StarGate_Settings)

    if (StarGate.CheckModule("entweapons") or StarGate.CheckModule("weapons")) then
        spawnmenu.AddToolMenuOption(cat_name, config_name, "Weapons Visuals", " " .. ML("agp_menu_vis_weapons", "Weapons Visuals"), "", "", StarGate.WeaponVisualSettings, {
            SwitchConVar = "cl_stargate_visualsweapon"
        })
    end

    spawnmenu.AddToolMenuOption(cat_name, config_name, "Misc Visuals", " " .. ML("agp_menu_vis_misc", "Misc Visuals"), "", "", StarGate.MiscVisualSettings, {
        SwitchConVar = "cl_stargate_visualsmisc"
    })

    if (StarGate.CheckModule("ship")) then
        spawnmenu.AddToolMenuOption(cat_name, config_name, "Ship Visuals", " " .. ML("agp_menu_vis_ships", "Ship Visuals"), "", "", StarGate.ShipVisualSettings, {
            SwitchConVar = "cl_stargate_visualsship"
        })
    end

    -- Keybinders
    if (StarGate.CheckModule("ships")) then
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "Daedalus", " " .. "Daedalus", "", "", StarGate.DaedalusSettings)
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "Dart", " " .. "Wraith Dart", "", "", StarGate.DartSettings)
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "GateGlider", " " .. "Gate Glider", "", "", StarGate.GateGliderSettings)
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "Death Glider", " " .. "Death Glider", "", "", StarGate.DeathGliderSettings)
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "F302", " " .. "F-302", "", "", StarGate.F302Settings)
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "Jumper", " " .. "Puddle Jumper", "", "", StarGate.JumperSettings)
    end

    if (StarGate.CheckModule("base")) then
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "MALP", " " .. "MALP", "", "", StarGate.MALPSettings)
    end

    if (StarGate.CheckModule("ships")) then
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "Shuttle", " " .. SGLanguage.GetMessage("stool_key_dest"), "", "", StarGate.ShuttleSettings)
        spawnmenu.AddToolMenuOption(cat_name, keys_name, "Teltak", " " .. "Tel'tak", "", "", StarGate.TeltakSettings)
    end

    -- Add our stargate tools to the tab
    local toolgun = weapons.Get("gmod_tool")

    if (toolgun and toolgun.Tool) then
        for k, v in pairs(toolgun.Tool) do
            if (not v.AddToMenu and v.Tab == "Stargate") then
                if (v.Category == "Tech") then
                    v.Category = "Tech"
                elseif (v.Category == "Energy") then
                    v.Category = "Energy"
                elseif (v.Category == "Weapons") then
                    v.Category = "Weapons"
                elseif (v.Category == "Ramps") then
                    v.Category = "Ramps"
                end

                spawnmenu.AddToolMenuOption(cat_name, v.Category or "", k, v.Name or "#" .. k, v.Command or "gmod_tool " .. k, v.ConfigName or k, v.BuildCPanel)
                -- AGP: energy tools (ZPM hubs, naquadah, power cells) also in SpaceGrid - in both tabs; an own item name
                -- there, so each tab gets its own settings panel
                if (v.Category == "Energy") then
                    spawnmenu.AddToolMenuOption("SpaceGrid", "Energy", k .. "_spacegrid", v.Name or "#" .. k, v.Command or "gmod_tool " .. k, v.ConfigName or k, v.BuildCPanel)
                end
            end
        end
    end
end

hook.Add("AddToolMenuTabs", "StarGate.Hook.AddToolTab", StarGate.Hook.AddToolTab)

-- our tool tabs side by side. GMod sorts tool tabs by their inner names (Stargate, SpaceGrid = PowerGrid's,
-- SpaceGridKit = SpaceGrid's), other addons' tabs came between them. When the tool menu is built, our tabs are
-- moved together in this order, at the place of the first of them. Only the shown tabs move: GMod's own list (tab
-- numbers) stays as it is. The same code is in Ascension Gates, PowerGrid and SpaceGrid (each works alone); the
-- first one loaded does it, once.
hook.Add("PopulateToolMenu", "AGP.OurTabOrder", function()
    local tm = vgui.GetControlTable("ToolMenu")
    if not tm or tm.AGPTabOrder then return end
    tm.AGPTabOrder = true
    local OUR = { Stargate = 1, SpaceGridKit = 2, SpaceGrid = 3 }
    local load = tm.LoadTools
    tm.LoadTools = function(self, ...)
        local r = load(self, ...)
        local rank = {}
        for i, t in ipairs(spawnmenu.GetTools()) do
            local p = self.ToolPanels and self.ToolPanels[i]
            if OUR[t.Name] and IsValid(p) then rank[p] = OUR[t.Name] end
        end
        local items, ours, first = self.Items or {}, {}, nil
        for j, it in ipairs(items) do
            if rank[it.Panel] then ours[#ours + 1] = it; first = first or j end
        end
        if #ours < 2 then return r end
        table.sort(ours, function(a, b) return rank[a.Panel] < rank[b.Panel] end)
        local new = {}
        for j, it in ipairs(items) do
            if j == first then for _, o in ipairs(ours) do new[#new + 1] = o end end
            if not rank[it.Panel] then new[#new + 1] = it end
        end
        for j = 1, #new do items[j] = new[j] end
        local sc = self.tabScroller
        if IsValid(sc) and sc.Panels then
            for j = 1, #new do sc.Panels[j] = new[j].Tab end
            sc:InvalidateLayout(true)
        end
        return r
    end
end)

--[[
	Pack Version (packversion.lua)
	Copyright (C) 2011 Madman07
]]
--
-- AGP: "Credits" panel of this pack (was CAP's online update check, CAP links and CAP's donate link)
function StarGate.Update_Check(Panel)
    local function L(k, f) return (SGLanguage.ValidMessage and SGLanguage.ValidMessage(k)) and SGLanguage.GetMessage(k) or f end
    if Panel.ClearControls then Panel:ClearControls() end   -- the menu may build this page again: never twice
    -- top: big logo (click = info screen), version, intro, About button (as before)
    local logo = vgui.Create("DPanel")
    logo:SetTall(140)
    local mat = Material("gui/agp_logo_256.png", "smooth")
    logo.Paint = function(self, w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(w / 2 - 64, 6, 128, 128)
    end
    logo:SetCursor("hand")
    logo.OnMousePressed = function() RunConsoleCommand("agp_info") end
    Panel:AddItem(logo)
    Panel:Help("Ascension Gates " .. ((AGP and AGP.Version) or ""))
    Panel:Help(L("agp_info_intro", ""))
    Panel:Button(L("agp_about", "About Ascension Gates"), "agp_info")
    Panel:Button(L("agp_info_btn_settings", "Settings"), "stargate_settings")
    if AGP and AGP.UpdateCheckWanted and AGP.UpdateCheckWanted() then   -- manual (GitHub) installs; the Workshop updates by itself
        Panel:Button(L("agp_upd_button", "Check for updates")).DoClick = function() AGP.CheckForUpdate() end
    end

    -- credits: further down, smaller, one line each (text in the menu's own colour, so it stays readable)
    surface.CreateFont("AGPCreditsHead", { font = "Roboto", size = 16, weight = 700 })
    surface.CreateFont("AGPCreditsText", { font = "Roboto", size = 14, weight = 500 })
    local function small(text, font, top)
        local l = Panel:Help(text)
        l:SetFont(font or "AGPCreditsText")
        if top then l:DockMargin(l:GetDockMargin(), top, 0, 0) end
        return l
    end
    small(L("agp_info_credits", "Credits"), "AGPCreditsHead", 40)
    small("• " .. L("agp_info_credit_cape", "CAP Enhanced: Soren MC"))
    small("• " .. L("agp_info_credit_cap", "Carter's Addon Pack team"))
    small("• " .. L("agp_info_credit_weapons", "SGC weapon models: Rotuma, romunql (CC BY 4.0)"))
    small("• " .. L("agp_info_credit_reactor", "Reactor Core model: Daniel Aucar Felipe (CC BY 4.0)"))
    -- links as small buttons in one row
    local function row(list)
        local r = vgui.Create("DPanel")
        r:SetTall(22)
        r.Paint = nil
        for _, it in ipairs(list) do
            local btn = vgui.Create("DButton", r)
            btn:SetText(it[1])
            btn.DoClick = it[2]
        end
        -- AGP: each button as wide as its text needs (equal thirds cut "Beretta 92 (romunql)")
        r.PerformLayout = function(self, w)
            local kids = self:GetChildren()
            local need, sum = {}, 0
            for i, c in ipairs(kids) do
                surface.SetFont(c:GetFont() or "DermaDefault")
                need[i] = surface.GetTextSize(c:GetText() or "") + 14
                sum = sum + need[i]
            end
            local room = w - 4 * (#kids - 1)
            local x = 0
            for i, c in ipairs(kids) do
                local bw = math.floor(room * need[i] / math.max(sum, 1))
                c:SetPos(x, 0); c:SetSize(bw, 22)
                x = x + bw + 4
            end
        end
        Panel:AddItem(r)
    end
    local function open(url) return function() gui.OpenURL(url) end end
    row({
        { "CAP", open("https://github.com/RafaelDeJongh/cap") },
        { "CAP Enhanced", open("https://steamcommunity.com/sharedfiles/filedetails/?id=3021712722") },
    })
    row({   -- CC BY 4.0: title, author and source of the weapon models
        { "P90 (Rotuma)", open("https://sketchfab.com/3d-models/p90-82d8b9f1e02b48f9b012698dcfa3352b") },
        { "Beretta 92 (romunql)", open("https://sketchfab.com/3d-models/beretta-92-clean-bf58795f626d4251b11c5e23d2922358") },
        { "CC BY 4.0", open("https://creativecommons.org/licenses/by/4.0/") },
    })
    local own = {}
    for _, l in ipairs(AGP and AGP.LinkList and AGP.LinkList() or {}) do
        own[#own + 1] = { (l[1]:gsub("^Ascension Gates %(", ""):gsub("%)$", "")), open(l[2]) }
    end
    if #own > 0 then row(own) end
    small(L("agp_info_licence", "") .. " " .. L("agp_info_mgm", ""), nil, 8)
end

--########################
-- cl_visualssettings.lua
--########################
function StarGate.MiscVisualSettings(Panel)
    local high = SGLanguage.GetMessage("vis_fps_high")
    local medium = SGLanguage.GetMessage("vis_fps_medium")
    local low = SGLanguage.GetMessage("vis_fps_low")
    Panel:ClearControls()
    -- The HELP Button
    -- Configuration
    local disable = {}
    Panel:Button(SGLanguage.GetMessage("vis_reset_menu"), "stargate_reset_menu")
    local conf = Panel:CheckBox(SGLanguage.GetMessage("vis_title"), "cl_stargate_visualsmisc")
    conf:SetToolTip(SGLanguage.GetMessage("vis_title_desc"))

    conf.OnChange = function(self, val)
        for k, v in pairs(disable) do
            if (val) then
                v:SetDisabled(false)
            else
                v:SetDisabled(true)
            end
        end
    end

    Panel:Help("")
    -- Stargates
    table.insert(disable, Panel:Help(AGP.L("agp_ui_stargate", "Stargate")))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_stargate_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)

    -- AGP: shown always; it waited for zup/stargate/effect_03.vmt, which never existed (the refraction has its own
    -- material now, effects/eventhorizon_refract.lua), so the box was never in the menu
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_ripple"), "cl_stargate_ripple"))
    table.GetLastValue(disable):SetToolTip(medium)

    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_kawoosh_eff"), "cl_stargate_kenter"))
    table.GetLastValue(disable):SetToolTip(low)
    Panel:CheckBox(SGLanguage.GetMessage("vis_kawoosh_mat"), "cl_kawoosh_material"):SetToolTip(SGLanguage.GetMessage("vis_kawoosh_mat_desc"))
    Panel:CheckBox(SGLanguage.GetMessage("vis_stargate_eff"), "cl_stargate_effects"):SetToolTip(SGLanguage.GetMessage("vis_stargate_eff_desc", medium))
    -- our own: wormhole travel animation on/off (only used when the server has doWormholeSequence on)
    Panel:CheckBox(SGLanguage.GetMessage("vis_wormhole"), "cl_stargate_wormhole"):SetToolTip(SGLanguage.GetMessage("vis_wormhole_desc"))
    -- Stargate Universe
    Panel:Help(SGLanguage.GetMessage("stargate_universe"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_stargate_un_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    -- SuperGate
    Panel:Help(SGLanguage.GetMessage("stargate_supergate"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_supergate_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    -- Shield
    Panel:Help(AGP.L("agp_ui_shield", "Shield"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_shield_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_shield_bubble"), "cl_shield_bubble"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_shield_design"), "cl_shield_design"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_hit_refl"), "cl_shield_hitradius"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_hit_eff"), "cl_shield_hiteffect"))
    table.GetLastValue(disable):SetToolTip(low)
    -- Atl Shield
    Panel:Help(SGLanguage.GetMessage("vis_atl_shield"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_refl"), "cl_shieldcore_refract"))
    table.GetLastValue(disable):SetToolTip(SGLanguage.GetMessage("vis_refl_desc", low))
    -- Harvester
    Panel:Help(AGP.L("agp_ui_harvester", "Harvester"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_harvester_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    -- Cloaking
    Panel:Help(AGP.L("agp_ui_cloaking", "Cloaking"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_cloak_pass"), "cl_cloaking_hitshader"))
    table.GetLastValue(disable):SetToolTip(high)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_cloak_eff"), "cl_cloaking_shader"))
    table.GetLastValue(disable):SetToolTip(medium)
    -- Apple Core
    Panel:Help(AGP.L("agp_ui_apple_core", "Apple Core"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_applecore_light"))
    table.GetLastValue(disable):SetToolTip(high)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_smoke"), "cl_applecore_smoke"))
    table.GetLastValue(disable):SetToolTip(medium)
    -- Huds
    Panel:Help(SGLanguage.GetMessage("vis_hud_title"))
    Panel:CheckBox(SGLanguage.GetMessage("vis_hud_energy"), "cl_draw_huds"):SetToolTip(SGLanguage.GetMessage("vis_hud_energy_desc", low))
    Panel:CheckBox(SGLanguage.GetMessage("vis_dhd_glyphs"), "cl_dhd_letters"):SetToolTip(SGLanguage.GetMessage("vis_dhd_glyphs_desc", low))
end

function StarGate.ShipVisualSettings(Panel)
    local high = SGLanguage.GetMessage("vis_fps_high")
    local medium = SGLanguage.GetMessage("vis_fps_medium")
    local low = SGLanguage.GetMessage("vis_fps_low")
    Panel:ClearControls()
    -- The HELP Button
    -- Configuration
    local disable = {}
    local conf = Panel:CheckBox(SGLanguage.GetMessage("vis_title"), "cl_stargate_visualsship")
    conf:SetToolTip(SGLanguage.GetMessage("vis_title_desc"))

    conf.OnChange = function(self, val)
        for k, v in pairs(disable) do
            if (val) then
                v:SetDisabled(false)
            else
                v:SetDisabled(true)
            end
        end
    end

    Panel:Help("")
    -- Jumper
    Panel:Help(SGLanguage.GetMessage("entity_jumper"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_jumper_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_heatwave"), "cl_jumper_heatwave"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_sprites"), "cl_jumper_sprites"))
    table.GetLastValue(disable):SetToolTip(medium)
    -- F302
    Panel:Help("F-302")
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_heatwave"), "cl_F302_heatwave"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_sprites"), "cl_F302_sprites"))
    table.GetLastValue(disable):SetToolTip(medium)
    -- Shuttle
    Panel:Help(AGP.L("agp_ui_destiny_shuttle", "Destiny Shuttle"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_heatwave"), "cl_shuttle_heatwave"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_sprites"), "cl_shuttle_sprites"))
    table.GetLastValue(disable):SetToolTip(medium)
    -- Wraith Dart
    Panel:Help(AGP.L("agp_ui_wraith_dart", "Wraith Dart"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_heatwave"), "cl_dart_heatwave"))
    table.GetLastValue(disable):SetToolTip(medium)
    -- Control Chair
    Panel:Help(AGP.L("agp_ui_control_chair", "Control Chair"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_chair_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
end

function StarGate.WeaponVisualSettings(Panel)
    local high = SGLanguage.GetMessage("vis_fps_high")
    local medium = SGLanguage.GetMessage("vis_fps_medium")
    local low = SGLanguage.GetMessage("vis_fps_low")
    Panel:ClearControls()
    -- The HELP Button
    -- Configuration
    local disable = {}
    local conf = Panel:CheckBox(SGLanguage.GetMessage("vis_title"), "cl_stargate_visualsweapon")
    conf:SetToolTip(SGLanguage.GetMessage("vis_title_desc"))

    conf.OnChange = function(self, val)
        for k, v in pairs(disable) do
            if (val) then
                v:SetDisabled(false)
            else
                v:SetDisabled(true)
            end
        end
    end

    Panel:Help("")
    -- Staff Weapon and Dexgun
    Panel:Help(SGLanguage.GetMessage("vis_weap_title"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_hit_dyn_light"), "cl_staff_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_fly_dyn_light"), "cl_staff_dynlights_flight"))
    table.GetLastValue(disable):SetToolTip(high)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_smoke"), "cl_staff_smoke"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_wall"), "cl_staff_scorch"))
    table.GetLastValue(disable):SetToolTip(low)
    -- Zat'nik'tel
    Panel:Help("Zat'nik'tel")
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_zat_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_hit_eff"), "cl_zat_hiteffect"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_diss_eff"), "cl_zat_dissolveeffect"))
    table.GetLastValue(disable):SetToolTip(medium)
    -- Drones
    Panel:Help(AGP.L("agp_ui_drones", "Drones"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_glow"), "cl_drone_glow"))
    table.GetLastValue(disable):SetToolTip(low)
    -- Naquadah Bomb
    Panel:Help(AGP.L("agp_ui_naquadah_bomb", "Naquadah Bomb"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_sunbeams"), "cl_gate_nuke_sunbeams"))
    table.GetLastValue(disable):SetToolTip(SGLanguage.GetMessage("vis_sunbeams_desc", high))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_part_rings"), "cl_gate_nuke_rings"))
    table.GetLastValue(disable):SetToolTip(high)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_shield_part"), "cl_gate_nuke_shieldrings"))
    table.GetLastValue(disable):SetToolTip(SGLanguage.GetMessage("vis_shield_part_desc", high))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_plasma"), "cl_gate_nuke_plasma"))
    table.GetLastValue(disable):SetToolTip(SGLanguage.GetMessage("vis_plasma_desc", low))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_plasma_light"), "cl_gate_nuke_dynlights"))
    table.GetLastValue(disable):SetToolTip(SGLanguage.GetMessage("vis_plasma_desc", medium))
    -- Stargate Overloader
    Panel:Help(AGP.L("agp_ui_gate_overloader", "Gate Overloader"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_refl_rings"), "cl_overloader_refract"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_part_rings"), "cl_overloader_particle"))
    table.GetLastValue(disable):SetToolTip(medium)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_overloader_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    -- Asuran Gun
    Panel:Help(AGP.L("agp_ui_asuran_gate_weapon", "Asuran Gate Weapon"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_sm_laser"), "cl_asuran_laser"))
    table.GetLastValue(disable):SetToolTip(low)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_dyn_light"), "cl_asuran_dynlights"))
    table.GetLastValue(disable):SetToolTip(high)
    -- Dakara Super Weapon
    Panel:Help(AGP.L("agp_ui_dakara_weapon", "Dakara Weapon"))
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_charge_up"), "cl_dakara_rings"))
    table.GetLastValue(disable):SetToolTip(low)
    table.insert(disable, Panel:CheckBox(SGLanguage.GetMessage("vis_refl_sphere"), "cl_dakara_refract"))
    table.GetLastValue(disable):SetToolTip(medium)
end

--##############
-- settings.lua
--##############
--[[
	Created by AlexALX (c) 2012
	Small settings tab
	For some functions what come from my addon
]]
function StarGate_Settings(Panel)
    local LAYOUT = "Convars/Limits/Language"
    local GREEN = Color(0, 255, 0, 255)
    local ORANGE = Color(255, 128, 0, 255)
    local RED = Color(255, 0, 0, 255)
    local DGREEN = Color(0, 182, 0, 255)

    -- AGP: only the language here (the server settings button is on About & Credits)
    Panel:Help(SGLanguage.GetMessage("stargate_settings_06")):SetTextColor(DGREEN)
    local clientlang = vgui.Create("DMultiChoice", Panel)
    clientlang:SetSize(50, 20)
    local lg = SGLanguage.GetLanguageName(SGLanguage.GetClientLanguage())

    if (lg ~= "Error") then
        clientlang:SetText(lg)
    else
        clientlang:SetText(SGLanguage.GetClientLanguage())
    end

    clientlang.TextEntry:SetTooltip(SGLanguage.GetMessage("stargate_settings_07"))

    clientlang.TextEntry.OnTextChanged = function(TextEntry)
        local pos = TextEntry:GetCaretPos()
        local text = TextEntry:GetValue()
        local len = text:len()
        local letters = text:lower():gsub("[^a-z-]", "") -- Lower, remove invalid chars and split!
        TextEntry:SetText(letters)
        TextEntry:SetCaretPos(math.Clamp(pos - (len - letters:len()), 0, text:len())) -- Reset the caretpos!
        timer.Remove("SG.lang_check")

        timer.Create("SG.lang_check", 0.4, 1, function()
            local lg = SGLanguage.GetLanguageName(letters)

            if (IsValid(TextEntry) and lg ~= "Error") then
                TextEntry:SetText(lg)
                TextEntry:SetCaretPos(lg:len()) -- Reset the caretpos!
            end

            if (letters ~= "") then
                SGLanguage.SetClientLanguage(letters)
            end
        end)
    end

    clientlang.OnSelect = function(panel, index, value)
        if (value ~= "") then
            local lg = SGLanguage.GetLanguageFromName(value)
            SGLanguage.SetClientLanguage(lg)
        end
    end

    -- add exists languages
    local _, langs = file.Find("lua/data/language/*", "GAME")
    local en_count, en_msgs = SGLanguage.CountMessagesInLanguage("en", true)
    local lng_arr = {}

    for i, lang in pairs(langs) do
        local count, msgs = SGLanguage.CountMessagesInLanguage(lang, true)

        --[[ and (not msgs["global_lang_similar"] or msgs["global_lang_similar"]=="false")]]
        if (lang ~= "en") then
            for k, v in pairs(msgs) do
                --[=[ or v==en_msgs[k]]=]
                -- stop cheating!
                if (not en_msgs[k]) then
                    count = count - 1
                end
            end
        end

        count = math.Round(count * 100 / en_count)
        lng_arr[lang] = {SGLanguage.GetLanguageName(lang), count}
        clientlang:AddChoice(SGLanguage.GetLanguageName(lang))
    end

    Panel:AddPanel(clientlang)
    Panel:Help(SGLanguage.GetMessage("stargate_settings_07"))
    Panel:Help(SGLanguage.GetMessage("stargate_settings_03")):SetTextColor(DGREEN)
    local VGUI = vgui.Create("DPanel")
    -- AGP: the language list on our dark box with lighter percentage colours (red / orange on the grey box were
    -- unreadable); AGPDark tells the text fitting pass that its texts sit on dark ground
    VGUI.AGPDark = true
    VGUI.Paint = function(_, w, h) draw.RoundedBox(4, 0, 0, w, h, (AGP and AGP.Colors and AGP.Colors.panel) or Color(24, 32, 46)) end
    local i = 5

    for k, v in SortedPairs(lng_arr) do
        local count = v[2]
        local col = HSVToColor((count / 100) * 120, 0.55, 1)
        local p = vgui.Create("DLabel", VGUI)
        p:SetPos(10, i)
        p:SetText(v[1] .. " (" .. k .. ") - " .. count .. "%")
        p:SetSize(150, 15)
        p:SetAutoStretchVertical(true)
        p:SetTextColor(col)
        p:SetTall(10)
        p:DockMargin(0, 0, 0, 0)
        i = i + 15
    end

    VGUI:SetSize(150, i + 5)
    Panel:AddPanel(VGUI)
    Panel:Help(SGLanguage.GetMessage("stargate_settings_04"))
    Panel:Help("")
    -- AGP: no "help translate" button (it opened CAP's wiki)
    Panel:Help("")
    Panel:Help(SGLanguage.GetMessage("stargate_settings_08"))
    Panel:Help(SGLanguage.GetMessage("stargate_settings_09"))
end