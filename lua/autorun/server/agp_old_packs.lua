-- Ascension Gates: CAP or CAP Enhanced installed next to us? Both packs use the same file and class names, so which
-- version of a part runs is random - a wall of Lua errors. One clear message instead: uninstall them, Ascension Gates
-- replaces them. Shown once per session in the server console and in the chat of the host / the superadmins.
-- (capcheck.lua shows its error window for the same case - but it is one of the shared files: with an old pack
-- installed as a folder, the old pack's copy of it may be the one that runs. This file is ours alone.)
AGP = AGP or {}

local WORKSHOP = { [3021712722] = "CAP Enhanced", [175394472] = "Carter Addon Pack" }

-- names of the old packs found: mounted Workshop items, and folders in garrysmod/addons that bring CAP's loader
function AGP.OldPacks()
    local out = {}
    for _, a in ipairs(engine.GetAddons()) do
        local name = a.mounted and WORKSHOP[tonumber(a.wsid) or 0]
        if name then out[#out + 1] = name end
    end
    local me = string.match(debug.getinfo(1, "S").source or "", "addons/([^/]+)/lua/")
    local _, dirs = file.Find("addons/*", "GAME")
    for _, d in ipairs(dirs or {}) do
        if d ~= me and file.Exists("addons/" .. d .. "/lua/stargate/shared/capcheck.lua", "GAME") then
            out[#out + 1] = "addons/" .. d
        end
    end
    return out
end

local TEXT = "An old Stargate pack is also installed: %s. Please uninstall CAP and CAP Enhanced - Ascension Gates replaces them. Together they cause errors."
local found

hook.Add("InitPostEntity", "AGP_OldPacks", function()
    found = AGP.OldPacks()
    if #found == 0 then return end
    MsgN("[Ascension Gates] " .. string.format(TEXT, table.concat(found, ", ")))
end)

hook.Add("PlayerInitialSpawn", "AGP_OldPacks", function(ply)
    timer.Simple(12, function()
        found = found or AGP.OldPacks()    -- (a Lua refresh loads this file again: the list of the first load is gone)
        if not IsValid(ply) or #found == 0 or not AGP.Say then return end
        if not (game.SinglePlayer() or ply:IsListenServerHost() or ply:IsSuperAdmin()) then return end
        if ply.AGPOldPacksTold then return end                  -- once a session (other addons run this hook again)
        ply.AGPOldPacksTold = true
        AGP.Say(ply, "agp_old_packs", TEXT, table.concat(found, ", "))
    end)
end)
