-- Ascension Gates: gate spawner editor page (tools tab > Ascension Gates > Config > Gate Spawner).
-- Place gates, DHDs, rings ... like normal, press "Save map" and they spawn on this map every time it starts.
AGP = AGP or {}

local function L(key, fallback, ...)
    -- SGLanguage formats right away, so the values go along with the key
    if SGLanguage and SGLanguage.ValidMessage and SGLanguage.ValidMessage(key) then return SGLanguage.GetMessage(key, ...) end
    if select("#", ...) > 0 then return fallback:format(...) end
    return fallback
end

local NICE = { -- readable names for the list
    stargate_sg1 = "Stargate (SG-1)", stargate_movie = "Stargate (Movie)", stargate_atlantis = "Stargate (Atlantis)",
    stargate_universe = "Stargate (Universe)", stargate_infinity = "Stargate (Infinity)", stargate_tollan = "Stargate (Tollan)",
    stargate_orlin = "Stargate (Orlin)", stargate_supergate = "Supergate", stargate_alteran = "Stargate (Alteran)",
    stargate_virgo = "Stargate (Virgo)", stargate_iris = "Iris", goauld_iris = "Goa'uld iris", mobile_dhd = "Mobile DHD",
}
local function nice(c)
    if NICE[c] then return NICE[c] end
    if c:find("^dhd_") then return "DHD (" .. c:sub(5) .. ")" end
    return (c:gsub("_", " "))
end

local state = { list = {} }
local panelRef

local function send(what, k)
    net.Start("agp_gs_do")
    net.WriteString(what)
    net.WriteUInt(k or 0, 12)
    net.SendToServer()
end
AGP.GateSpawnerSend = send

local function refreshPanel()
    local p = panelRef
    if not IsValid(p) or not IsValid(p.AGPList) then return end
    local src
    if state.source == "" then src = L("agp_gs_src_none", "no file for this map")
    elseif state.own then src = L("agp_gs_src_own", "your saved file")
    elseif state.source:find("/auto/", 1, true) then src = L("agp_gs_src_auto", "placed automatically")
    else src = L("agp_gs_src_pack", "the pack's file") end
    p.AGPStatus:SetText(L("agp_gs_status", "Map: %s\nSpawner: %s\nUsing: %s\nParts: %d", state.map or "?",
        state.enabled and L("agp_gs_on", "on") or L("agp_gs_off", "off"), src, #state.list))
    local hint = ""
    if state.unsaved > 0 then hint = L("agp_gs_unsaved", "%d placed part(s) are not saved yet.", state.unsaved) end
    if state.dirty then hint = hint .. (hint ~= "" and "\n" or "") .. L("agp_gs_dirty", "You removed parts: save to keep it that way.") end
    p.AGPHint:SetText(hint)
    p.AGPToggle:SetText(state.enabled and L("agp_gs_turn_off", "Switch spawner off") or L("agp_gs_turn_on", "Switch spawner on"))
    p.AGPReset:SetEnabled(state.own == true)
    p.AGPAuto:SetText(state.auto and L("agp_gs_auto_off", "Auto gates on new maps: on") or L("agp_gs_auto_on", "Auto gates on new maps: off"))
    for _, b in ipairs({ p.AGPSave, p.AGPReload, p.AGPToggle, p.AGPReset, p.AGPSuggest, p.AGPClearSuggest, p.AGPAuto, p.AGPRedo }) do
        if not state.admin then b:SetEnabled(false) end
    end
    p.AGPList:Clear()
    for _, e in ipairs(state.list) do
        local line = p.AGPList:AddLine(nice(e.class), e.address, e.name)
        line.AGPKey = e.k
        -- AGP: ground AND text colours set together (the skin's own list ground came out white with white text on a
        -- player's menu skin: the rows could not be read, in every language). Dark ground, light text, same for all skins.
        local alt = (#p.AGPList:GetLines() % 2 == 0)
        line.Paint = function(s, w, h)
            if s:IsSelected() then surface.SetDrawColor(45, 85, 140) elseif s:IsHovered() then surface.SetDrawColor(50, 54, 64)
            elseif alt then surface.SetDrawColor(30, 33, 40) else surface.SetDrawColor(24, 26, 32) end
            surface.DrawRect(0, 0, w, h)
        end
        for _, c in pairs(line.Columns or {}) do c:SetTextColor(Color(225, 228, 235)) end
    end
    for _, l in ipairs({ p.AGPStatus, p.AGPHint }) do l:SizeToContentsY() end
end

net.Receive("agp_gs_state", function()
    state.map = net.ReadString()
    state.enabled = net.ReadBool()
    state.source = net.ReadString()
    state.own = net.ReadBool()
    state.dirty = net.ReadBool()
    state.unsaved = net.ReadUInt(12)
    state.admin = net.ReadBool()
    state.auto = net.ReadBool()
    state.list = {}
    for i = 1, net.ReadUInt(12) do
        state.list[i] = { k = net.ReadUInt(12), class = net.ReadString(), address = net.ReadString(), name = net.ReadString(), pos = net.ReadVector() }
    end
    refreshPanel()
end)

local function build(panel)
    panel:ClearControls()
    if panel.SetLabel then panel:SetLabel(L("agp_gs_title", "Gate Spawner")) end
    panelRef = panel
    panel:Help(L("agp_gs_help", "Place gates, DHDs, rings and ramps like normal, then press \"Save map\": they spawn on this map every time it starts. Double-click a part to go there, right-click to remove it."))
    panel.AGPStatus = panel:Help(" ")
    panel.AGPHint = panel:Help(" ")
    panel.AGPHint:SetTextColor(Color(255, 190, 80))
    local list = vgui.Create("DListView")
    list:SetTall(260)
    list:SetMultiSelect(false)
    list.Paint = function(_, w, h) surface.SetDrawColor(24, 26, 32); surface.DrawRect(0, 0, w, h) end   -- (the empty list too)
    list:AddColumn(L("agp_gs_col_part", "Part"))
    list:AddColumn(L("agp_gs_col_address", "Address")):SetFixedWidth(70)
    list:AddColumn(L("agp_gs_col_name", "Name"))
    list.DoDoubleClick = function(_, _, line) send("goto", line.AGPKey) end
    list.OnRowRightClick = function(_, _, line)
        local m = DermaMenu()
        m:AddOption(L("agp_gs_goto", "Go there"), function() send("goto", line.AGPKey) end):SetIcon("icon16/arrow_right.png")
        if state.admin then
            m:AddOption(L("agp_gs_remove", "Remove from spawner"), function() send("remove", line.AGPKey) end):SetIcon("icon16/delete.png")
        end
        m:Open()
    end
    panel:AddItem(list)
    panel.AGPList = list
    -- (a slider for how many gates one press places; 0 = as many as fit the map's size)
    panel.AGPCount = panel:NumSlider(L("agp_gs_count", "How many gates (0 = by map size)"), nil, 0, 20, 0)
    panel.AGPCount:SetValue(cookie.GetNumber("agp_gs_count", 0))
    panel.AGPCount.OnValueChanged = function(_, v) cookie.Set("agp_gs_count", tostring(math.Round(v))) end
    panel.AGPCount:SetTooltip(L("agp_gs_count_tip", "The gates are spread over the map and over different kinds of places: open ground, halls and underground rooms, raised platforms, water."))
    panel.AGPSuggest = panel:Button(L("agp_gs_suggest", "Place gates on this map"))
    panel.AGPSuggest.DoClick = function() send("suggest", math.Clamp(math.Round(panel.AGPCount:GetValue()), 0, 20)) end
    panel.AGPClearSuggest = panel:Button(L("agp_gs_clear_suggest", "Remove the suggestions"))
    panel.AGPClearSuggest.DoClick = function() send("clear_suggest") end
    panel.AGPSave = panel:Button(L("agp_gs_save", "Save map"))
    panel.AGPSave.DoClick = function() send("save") end
    panel.AGPReload = panel:Button(L("agp_gs_reload", "Reload spawner"))
    panel.AGPReload.DoClick = function() send("reload") end
    panel.AGPReset = panel:Button(L("agp_gs_reset", "Use the pack's file again"))
    panel.AGPReset.DoClick = function() send("reset") end
    panel.AGPAuto = panel:Button(" ")
    panel.AGPAuto.DoClick = function() send("toggle_auto") end
    panel.AGPRedo = panel:Button(L("agp_gs_redo_auto", "Place automatically again (new scan)"))
    panel.AGPRedo.DoClick = function() send("redo_auto") end
    panel.AGPToggle = panel:Button(" ")
    panel.AGPToggle.DoClick = function() send("toggle") end
    local refresh = panel:Button(L("agp_gs_refresh", "Refresh"))
    refresh.DoClick = function() send("state") end
    send("state")
end
AGP.GateSpawnerBuild = build

hook.Add("PopulateToolMenu", "AGP.GateSpawnerEditor", function()
    spawnmenu.AddToolMenuOption("Stargate", "Config", "agp_gatespawner", L("agp_gs_title", "Gate Spawner"), "", "", build)
end)
