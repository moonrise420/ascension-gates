-- Ascension Gates: ship settings page (Stargate > Config > "AGP Ships"). Server settings: only admins can change
-- them (agp_ship_settings.lua). Distance unit: each player's own choice (agp_unit_distance, AGP.Units.Distance).
local function L(k, d) return AGP and AGP.L and AGP.L(k, d) or d end
local state = { admin = false, values = {} }
local TIPS = {
    agp_hatak_hijack = { "agp_ship_tip_hijack", "Who may fly and use the consoles of a ship that is not theirs." },
    agp_hatak_friendly_fire = { "agp_ship_tip_ff", "Yes: the ship's guns also shoot at the owner and their friends." },
    agp_hatak_weapon_range = { "agp_ship_tip_range", "How far the guns shoot and the radar sees." },
    agp_hatak_radar_max = { "agp_ship_tip_radarmax", "Most targets shown on the radar at once (fewer = faster)." },
    agp_hatak_crystal_pull = { "agp_ship_tip_crystalpull", "How many power crystals a stranger may pull out at once. The crew has no limit." },
    agp_hatak_destructible = { "agp_ship_tip_destructible", "Yes: at 0 hull health the ship explodes. No: it stays at 1." },
    agp_hatak_blast_size = { "agp_ship_tip_blast", "How far the exploding ship (also self-destruct) kills and hurts, and how big the naquadah blast is." },
    agp_hatak_health = { "agp_ship_tip_health", "Hull health of new ships. Only heavy hits (50+) count." },
    agp_hatak_cloak = { "agp_ship_tip_cloak", "Allow the cloak (needs 30 % shield power)." },
    agp_hatak_glider_respawn = { "agp_ship_tip_gliderrespawn", "Yes: a lost or destroyed glider comes back on its pad." },
    agp_hatak_glider_respawn_time = { "agp_ship_tip_gliderrespawntime", "Seconds until a lost glider comes back." },
    agp_ship_shield_visible = { "agp_ship_tip_shieldvis", "Always: every ship's shield bubble glows faintly while the shield is up. Otherwise it only shows when it is hit or switched on or off." },
    agp_ship_destruct_time = { "agp_ship_tip_destructtime", "Seconds from pressing the self-destruct key to the explosion. A second press blows the ship up at once." },
}
local page

local function set(name, value)
    net.Start("agp_ship_set"); net.WriteString(name); net.WriteInt(value, 32); net.SendToServer()
end

local function refresh()
    if (not IsValid(page)) then return end
    for _, c in ipairs(page.AGPControls or {}) do
        if (IsValid(c)) then
            c:SetEnabled(state.admin)
            if (c.AGPUpdate) then c:AGPUpdate(state.values[c.AGPName] or 0) end
        end
    end
    if (IsValid(page.AGPWho)) then
        page.AGPWho:SetText(state.admin and L("agp_ship_admin", "You can change the server settings.") or L("agp_ship_notadmin", "Server settings: only admins can change them."))
    end
end

net.Receive("agp_ship_state", function()
    state.admin = net.ReadBool()
    for i = 1, net.ReadUInt(8) do state.values[net.ReadString()] = net.ReadInt(32) end
    refresh()
end)

local function build(panel)
    panel:ClearControls()
    page = panel
    panel.AGPControls = {}
    panel:Help(L("agp_ship_title_hatak", "Ha'tak"))
    panel.AGPWho = panel:Help("")
    local function tip(ctrl, name)   -- one short line on what the setting does, shown when the mouse is over it
        local t = TIPS[name]
        if (t) then ctrl:SetTooltip(L(t[1], t[2])) end
    end
    local function choice(name, label, opts)
        local cb, lbl = panel:ComboBox(label)
        tip(cb, name); if (IsValid(lbl)) then tip(lbl, name) end
        if (AGP.StyleCombo) then AGP.StyleCombo(cb) end
        for v, t in SortedPairs(opts) do cb:AddChoice(t, v) end   -- in order: option id = value + 1
        cb.AGPName = name
        cb.OnSelect = function(_, _, _, v) if (not cb.AGPFilling) then set(name, v) end end
        cb.AGPUpdate = function(self2, v) self2.AGPFilling = true; self2:ChooseOptionID(v + 1); self2.AGPFilling = nil end
        table.insert(panel.AGPControls, cb)
    end
    choice("agp_hatak_hijack", L("agp_ship_hijack", "Hijacking"), {
        [0] = L("agp_ship_hijack0", "Crew only (owner + friends)"),
        [1] = L("agp_ship_hijack1", "Control crystal"),
        [2] = L("agp_ship_hijack2", "Anyone may use the consoles"),
    })
    choice("agp_hatak_friendly_fire", L("agp_ship_ff", "Weapons fire at owner and friends"), {
        [0] = L("agp_ship_no", "No"), [1] = L("agp_ship_yes", "Yes"),
    })
    local function slider(name, label, mn, mx)
        local s = panel:NumSlider(label, nil, mn, mx, 0)
        s.AGPName = name
        tip(s, name)
        s.OnValueChanged = function(self2, v)
            if (self2.AGPFilling) then return end
            timer.Create("agp_ship_slider_" .. name, 0.4, 1, function() set(name, math.Round(v)) end)
        end
        s.AGPUpdate = function(self2, v) self2.AGPFilling = true; self2:SetValue(v); self2.AGPFilling = nil end
        table.insert(panel.AGPControls, s)
    end
    slider("agp_hatak_weapon_range", L("agp_ship_range", "Weapon + radar range (units)"), 2000, 50000)
    slider("agp_hatak_radar_max", L("agp_ship_radarmax", "Radar: most targets shown"), 10, 200)
    slider("agp_hatak_crystal_pull", L("agp_ship_crystalpull", "Power crystals strangers may pull (crew: no limit)"), 0, 15)
    choice("agp_hatak_destructible", L("agp_ship_destructible", "Ship can be destroyed"), {
        [0] = L("agp_ship_no", "No"), [1] = L("agp_ship_yes", "Yes"),
    })
    choice("agp_hatak_blast_size", L("agp_ship_blast", "Blast when the ship explodes"), {
        [1] = L("agp_ship_blast1", "Small"), [2] = L("agp_ship_blast2", "Medium"), [3] = L("agp_ship_blast3", "Large"),
        [4] = L("agp_ship_blast4", "XL"), [5] = L("agp_ship_blast5", "XXL"),
    })
    slider("agp_hatak_health", L("agp_ship_health", "Hull health (new ships)"), 10000, 1000000)
    choice("agp_hatak_cloak", L("agp_ship_cloak", "Cloak allowed"), {
        [0] = L("agp_ship_no", "No"), [1] = L("agp_ship_yes", "Yes"),
    })
    choice("agp_hatak_glider_respawn", L("agp_ship_gliderrespawn", "Glider bay: lost gliders come back"), {
        [0] = L("agp_ship_no", "No"), [1] = L("agp_ship_yes", "Yes"),
    })
    slider("agp_hatak_glider_respawn_time", L("agp_ship_gliderrespawntime", "Glider bay: seconds until a glider comes back"), 10, 600)
    -- every ship with a shield / a self-destruct key (owner 2026-11-11)
    panel:Help(L("agp_ship_title_all", "All ships"))
    choice("agp_ship_shield_visible", L("agp_ship_shieldvis", "Shield bubble"), {
        [0] = L("agp_ship_shieldvis0", "Only when hit or switched"), [1] = L("agp_ship_shieldvis1", "Always visible"),
    })
    slider("agp_ship_destruct_time", L("agp_ship_destructtime", "Self-destruct countdown (seconds)"), 1, 600)
    panel:Help(L("agp_ship_units", "Your units (only for you):"))
    local cd = panel:ComboBox(L("agp_unit_distance", "Distance"), "agp_unit_distance")
    if (AGP.StyleCombo) then AGP.StyleCombo(cd) end
    cd:SetTooltip(L("agp_ship_tip_unit", "Metres, feet or game units on the ship screens (only for you)."))
    cd:AddChoice(L("agp_unit_auto", "Auto (your country)"), 0)
    cd:AddChoice(L("agp_unit_m", "Metres"), 1)
    cd:AddChoice(L("agp_unit_ft", "Feet"), 2)
    cd:AddChoice(L("agp_unit_hu", "Game units"), 3)
    -- ship HUD (only for you): the key that folds / unfolds the controls plate
    panel:Help(L("agp_ship_hud_head", "Ship HUD (only for you):"))
    local kb = panel:KeyBinder(L("agp_ship_hud_key", "Show / hide the controls"), "agp_hud_key")
    if (IsValid(kb)) then kb:SetTooltip(L("agp_ship_hud_key_tip", "In a ship this key folds or unfolds the controls plate (bottom right); its normal use is blocked there.")) end
    panel:CheckBox(L("agp_ship_hud_open", "Controls open when I get in"), "agp_hud_keys_open")
    RunConsoleCommand("agp_ship_state_request")
    refresh()
end

hook.Add("PopulateToolMenu", "AGP.ShipSettings", function()
    spawnmenu.AddToolMenuOption("Stargate", "Config", "agp_ship_settings", L("agp_ship_title", "AGP Ships"), "", "", build)
end)
