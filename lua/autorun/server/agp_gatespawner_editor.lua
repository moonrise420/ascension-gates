-- Ascension Gates: gate spawner editor (server side). The "Gate Spawner" page in the tools tab talks to this.
-- Admins (or the player in single player) can save the map's gates as this map's spawner, remove single spawner
-- parts, reload, go back to the pack's file and teleport to a part. Saved files: data/agp_gatespawner/<group|galaxy>/<map>.txt
AGP = AGP or {}
AGP.GateSpawnerEditor = AGP.GateSpawnerEditor or {}
local ED = AGP.GateSpawnerEditor

util.AddNetworkString("agp_gs_state")
util.AddNetworkString("agp_gs_do")

-- everything the spawner file can hold (props stay out: a player's own props must never be removed)
local CLASSES = { "stargate_*", "*_iris", "dhd_*", "mobile_dhd", "ring_*", "bearing", "brazier", "floorchevron", "destiny_timer",
    "destiny_console", "kino_dispenser", "ramp", "ramp_2", "future_ramp", "sgc_ramp", "icarus_ramp", "sgu_ramp", "goauld_ramp",
    "gravitycontroller", "atlantis_light", "atlantis_transporter", "cap_doors*", "cap_console" }

local function GS() return StarGate and StarGate.GateSpawner end

function ED.Allowed(p)
    return not IsValid(p) or p:IsAdmin() or game.SinglePlayer()
end

function ED.OwnFile()
    local sys = GetConVar("stargate_group_system"):GetBool() and "group" or "galaxy"
    return "agp_gatespawner/" .. sys .. "/" .. game.GetMap():lower() .. ".txt"
end

-- gate parts on the map that are not spawner parts yet (they would be added by "save")
function ED.Unsaved()
    local n, seen = 0, {}
    for _, pat in ipairs(CLASSES) do
        for _, e in ipairs(ents.FindByClass(pat)) do
            if not seen[e] and not e.GateSpawnerSpawned and not IsValid(e:GetParent()) then seen[e] = true; n = n + 1 end
        end
    end
    return n
end

function ED.List()
    local list, gs = {}, GS()
    for k, v in pairs(gs and gs.Ents or {}) do
        local e = v.Entity
        if IsValid(e) then
            list[#list + 1] = {
                k = k, class = e:GetClass(), pos = e:GetPos(),
                address = e.IsStargate and e.GetGateAddress and e:GetGateAddress() or "",
                name = e.IsStargate and e.GetGateName and e:GetGateName() or "",
            }
        end
    end
    table.sort(list, function(a, b) return a.k < b.k end)
    return list
end

-- save everything on the map as this map's spawner; the saved parts become spawner parts (no doubles after reload)
function ED.Save(p)
    local gs = GS()
    if not gs then return false end
    gs.CreateFile(p)
    if not file.Exists(ED.OwnFile(), "DATA") then return false end
    for _, pat in ipairs(CLASSES) do
        for _, e in ipairs(ents.FindByClass(pat)) do
            if IsValid(e) and not e.GateSpawnerSpawned and not IsValid(e:GetParent()) then e:Remove() end
        end
    end
    if GetConVar("stargate_gatespawner_enabled"):GetBool() then
        timer.Simple(0.2, function() if GS() then GS().InitialSpawn(true) end end)
    else
        -- a switched-off spawner would not bring the saved parts back: switch it on (its callback reloads)
        RunConsoleCommand("stargate_gatespawner_enabled", "1")
    end
    return true
end

-- take one part out of the spawner (it is removed now and is gone from the file after the next save)
function ED.RemovePart(k)
    local gs = GS()
    local v = gs and gs.Ents[k]
    if not v then return false end
    gs.Ents[k] = nil -- first: otherwise the auto respawn brings it back
    if IsValid(v.Entity) then v.Entity:Remove() end
    ED.Dirty = true
    return true
end

function ED.Reload()
    if GS() then GS().InitialSpawn(true) end
    ED.Dirty = false
end

-- forget this map's own file: the pack's file (or none) is used again
function ED.Reset()
    file.Delete(ED.OwnFile())
    ED.Reload()
end

function ED.SendState(p)
    local gs = GS()
    if not IsValid(p) or not gs then return end
    local list = ED.List()
    net.Start("agp_gs_state")
    net.WriteString(game.GetMap())
    net.WriteBool(GetConVar("stargate_gatespawner_enabled"):GetBool())
    net.WriteString(gs.Source or "")
    net.WriteBool(file.Exists(ED.OwnFile(), "DATA"))
    net.WriteBool(ED.Dirty == true)
    net.WriteUInt(ED.Unsaved(), 12)
    net.WriteBool(ED.Allowed(p))
    local cvAuto = GetConVar("stargate_gatespawner_auto")
    net.WriteBool(cvAuto and cvAuto:GetBool() or false)
    net.WriteUInt(#list, 12)
    for _, e in ipairs(list) do
        net.WriteUInt(e.k, 12)
        net.WriteString(e.class)
        net.WriteString(e.address)
        net.WriteString(e.name)
        net.WriteVector(e.pos)
    end
    net.Send(p)
end

net.Receive("agp_gs_do", function(_, p)
    local what = net.ReadString()
    local k = net.ReadUInt(12)
    if what ~= "state" and what ~= "goto" and not ED.Allowed(p) then
        AGP.Say(p, "agp_gs_admin_only", "Only admins can change the gate spawner.")
        return ED.SendState(p)
    end
    if what == "save" then
        ED.Save(p)
        ED.Dirty = false
    elseif what == "remove" then
        ED.RemovePart(k)
    elseif what == "reload" then
        ED.Reload()
    elseif what == "reset" then
        ED.Reset()
    elseif what == "suggest" and AGP.AutoPlace then
        -- (k: the slider "how many", 0 = by the map's size) the scan runs in the background, the game goes on
        local started = AGP.AutoPlace.SuggestAsync(p, (k and k > 0) and math.min(k, 30) or nil, function(picks)
            if IsValid(p) then
                AGP.Say(p, "agp_gs_suggested", "%s gate(s) placed. Check them, move or remove some, then press \"Save map\".", #picks)
                ED.SendState(p)
            end
        end)
        AGP.Say(p, "agp_gs_scanning", "Looking for good places on this map ... the gates appear when the scan is done.")
        if not started then return end
    elseif what == "clear_suggest" and AGP.AutoPlace then
        AGP.AutoPlace.Clear()
    elseif what == "toggle_auto" then
        local cv = GetConVar("stargate_gatespawner_auto")
        if cv then RunConsoleCommand("stargate_gatespawner_auto", cv:GetBool() and "0" or "1") end
    elseif what == "redo_auto" and AGP.AutoPlace then
        file.Delete(AGP.AutoPlace.AutoFile()) -- scan again on the next load
        timer.Simple(0.2, ED.Reload)
    elseif what == "toggle" then
        RunConsoleCommand("stargate_gatespawner_enabled", GetConVar("stargate_gatespawner_enabled"):GetBool() and "0" or "1")
    elseif what == "goto" and ED.Allowed(p) then
        local v = GS() and GS().Ents[k]
        if v and IsValid(v.Entity) then
            local e = v.Entity
            p:SetPos(e:GetPos() + e:GetForward() * 220 + Vector(0, 0, 10))
            p:SetEyeAngles((e:GetPos() - p:GetPos()):Angle())
        end
    end
    -- answer after the change has happened (reloads spawn with a short delay)
    timer.Simple(what == "state" and 0 or 1, function() if IsValid(p) then ED.SendState(p) end end)
end)
