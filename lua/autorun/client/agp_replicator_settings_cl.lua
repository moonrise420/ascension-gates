-- Ascension Gates: Replicators settings page (Stargate > Config > Replicators). Server settings: only admins can change
-- them (lua/autorun/agp_replicators.lua); the values are replicated, so everyone sees them.
local function L(k, d) return AGP and AGP.L and AGP.L(k, d) or d end

local function set(name, value)
    net.Start("agp_rep_set"); net.WriteString(name); net.WriteInt(value, 32); net.SendToServer()
end

local function admin() return LocalPlayer():IsAdmin() or game.SinglePlayer() end

local function build(panel)
    panel:ClearControls()
    panel:Help(L("agp_rep_title", "Replicators"))
    panel:Help(L("agp_rep_intro", "Replicators are made of blocks: 12 blocks form a Replicator, the Queen builds blocks. They eat loose metal props and turn them into more Replicators. Bullets only knock them apart; the anti-replicator gun (ARG) kills them."))
    panel:Help(admin() and L("agp_ship_admin", "You can change the server settings.") or L("agp_ship_notadmin", "Server settings: only admins can change them."))
    local function cur(name) local c = GetConVar(name) return c and c:GetInt() or 0 end
    local function choice(name, label, opts, tipKey, tipText)
        local cb, lbl = panel:ComboBox(label)
        if (AGP.StyleCombo) then AGP.StyleCombo(cb) end
        cb:SetTooltip(L(tipKey, tipText)); if (IsValid(lbl)) then lbl:SetTooltip(L(tipKey, tipText)) end
        for v, t in SortedPairs(opts) do cb:AddChoice(t, v) end
        cb.AGPFilling = true; cb:ChooseOptionID(cur(name) - (opts[0] and 0 or 1) + 1); cb.AGPFilling = nil
        cb.OnSelect = function(_, _, _, v) if (not cb.AGPFilling) then set(name, v) end end
        cb:SetEnabled(admin())
    end
    local function slider(name, label, mn, mx, tipKey, tipText)
        local s = panel:NumSlider(label, nil, mn, mx, 0)
        s:SetValue(cur(name))
        s:SetTooltip(L(tipKey, tipText))
        s.OnValueChanged = function(_, v) timer.Create("agp_rep_slider_" .. name, 0.4, 1, function() set(name, math.Round(v)) end) end
        s:SetEnabled(admin())
    end
    local yesno = { [0] = L("agp_ship_no", "No"), [1] = L("agp_ship_yes", "Yes") }
    choice("agp_rep_enabled", L("agp_rep_on", "Replicators are alive"), yesno, "agp_rep_tip_on", "No: they stand still and build nothing (good for pictures or a break).")
    choice("agp_rep_attack", L("agp_rep_attack", "They attack"), {
        [0] = L("agp_rep_attack0", "Nobody"), [1] = L("agp_rep_attack1s", "Who threatens them (like in the series)"),
        [2] = L("agp_rep_attack1", "Everybody but who spawned them"), [3] = L("agp_rep_attack2", "Everybody") },
        "agp_rep_tip_attack", "Players and NPCs near them. Whoever hurts them or their Queen is always attacked (except in 'Nobody').")
    choice("agp_rep_eat", L("agp_rep_eat", "They eat metal"), {
        [0] = L("agp_rep_eat0", "No"), [1] = L("agp_rep_eat1", "Only loose props (not frozen, not welded)"), [2] = L("agp_rep_eat2", "Everything made of metal (builds and devices too)") },
        "agp_rep_tip_eat", "Eaten metal becomes new Replicator blocks.")
    choice("agp_rep_rebuild", L("agp_rep_rebuild", "Shot apart, they build themselves again"), yesno, "agp_rep_tip_rebuild", "Yes: the blocks crawl together after about 10 seconds. No: they stay loose blocks.")
    choice("agp_rep_survive", L("agp_rep_survive", "Survivors hide and start a new swarm"), yesno, "agp_rep_tip_survive", "When a swarm is losing, one or two slip away, hide out of sight and later start a new swarm there.")
    choice("agp_rep_lone_grow", L("agp_rep_lonegrow", "A lone block builds itself into a Replicator"), yesno, "agp_rep_tip_lonegrow", "Slowly: first a small Replicator that looks for metal, then a full one.")
    choice("agp_rep_gates", L("agp_rep_gates", "Big swarms send colonists through Stargates"), yesno, "agp_rep_tip_gates", "They dial a gate on the map (at its DHD), walk through and start a new swarm there.")
    slider("agp_rep_gate_swarm", L("agp_rep_gateswarm", "Swarm size for a colony"), 2, 200, "agp_rep_tip_gates", "They dial a gate on the map (at its DHD), walk through and start a new swarm there.")
    slider("agp_rep_max_bugs", L("agp_rep_maxbugs", "Most Replicators"), 0, 2000, "agp_rep_tip_max", "Higher = more Replicators; if your frame rate drops, lower it.")
    slider("agp_rep_max_blocks", L("agp_rep_maxblocks", "Most loose blocks"), 12, 10000, "agp_rep_tip_max", "Higher = more Replicators; if your frame rate drops, lower it.")
    slider("agp_rep_max_queens", L("agp_rep_maxqueens", "Most Queens"), 0, 50, "agp_rep_tip_max", "Higher = more Replicators; if your frame rate drops, lower it.")
    choice("agp_rep_lagguard", L("agp_rep_lagguard", "Lag guard"), yesno, "agp_rep_tip_lagguard", "Yes: when the game lags, the swarm stops growing and Replicators far from players rest until it runs smoothly again.")
    slider("agp_rep_lagguard_fps", L("agp_rep_lagfps", "Lag guard: lowest frame rate"), 0, 144, "agp_rep_tip_lagfps", "Below this frame rate (single player or your own listen server) the lag guard steps in. 0 = only when the server itself falls behind.")
    choice("agp_rep_navscan", L("agp_rep_navscan", "Live area scan"), yesno, "agp_rep_tip_navscan", "Yes: they learn the ways around them in the background and keep them in a file per map (a few MB on big maps).")
    local b = panel:Button(L("agp_rep_clear", "Remove all Replicators"), "agp_rep_clear")
    if (IsValid(b)) then b:SetEnabled(admin()) end
    -- (after the lag guard's emergency brake made them dormant: they wake by themselves once a quarter are gone)
    local w = panel:Button(L("agp_rep_wakebtn", "Wake them (when they went dormant)"), "agp_rep_wake")
    if (IsValid(w)) then w:SetEnabled(admin()) end
end

hook.Add("PopulateToolMenu", "AGP.ReplicatorSettings", function()
    spawnmenu.AddToolMenuOption("Stargate", "Config", "agp_rep_settings", L("agp_rep_title", "Replicators"), "", "", build)
end)
