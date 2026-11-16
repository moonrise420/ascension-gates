-- Ascension Gates: translated texts for our own parts. AGP.L(key, fallback, ...) = the text in the player's language
-- (lua/data/language/<lang>/stargate_agp.lua), else the English fallback. AGP.Say(ply, key, fallback, ...) sends a
-- chat message that the player's own game translates.
AddCSLuaFile()
AGP = AGP or {}

function AGP.L(key, fallback, ...)
    if SGLanguage and SGLanguage.ValidMessage and SGLanguage.GetMessage and SGLanguage.ValidMessage(key) then
        local ok, s = pcall(SGLanguage.GetMessage, key, ...)   -- formats the arguments itself
        if ok and s then return s end
    end
    local text = fallback or key
    if select("#", ...) > 0 then
        local ok, s = pcall(string.format, text, ...)
        if ok then return s end
    end
    return text
end

-- resource names ("carbon dioxide" -> key agp_res_carbon_dioxide)
function AGP.ResName(res)
    return AGP.L("agp_res_" .. tostring(res):gsub("[^%w]+", "_"), res)
end

if SERVER then
    util.AddNetworkString("agp_say")
    -- how the text shows: "chat" ([AGP] line in the chat), "center" (middle of the screen), "error" / "info" / "hint"
    -- (GMod's notification at the right, with its sound for errors), "console"
    local MODES = { chat = 0, center = 1, error = 2, info = 3, hint = 4, console = 5 }
    function AGP.SayAs(ply, mode, key, fallback, ...)
        if not IsValid(ply) then return end
        local args = { ... }
        net.Start("agp_say")
        net.WriteString(key); net.WriteString(fallback or key)
        net.WriteUInt(#args, 4)
        for _, a in ipairs(args) do net.WriteString(tostring(a)) end
        net.WriteUInt(MODES[mode] or 0, 3)
        net.Send(ply)
    end
    function AGP.Say(ply, key, fallback, ...) return AGP.SayAs(ply, "chat", key, fallback, ...) end

    -- first time for this player this session? (how-to hints: once, not on every spawn/use; again after a reconnect
    -- or map change)
    function AGP.FirstTime(ply, key)
        if not IsValid(ply) then return false end
        ply.AGPHintsShown = ply.AGPHintsShown or {}
        if ply.AGPHintsShown[key] then return false end
        ply.AGPHintsShown[key] = true
        return true
    end

    -- a how-to hint, only to this player and only the first time
    function AGP.Hint(ply, key, fallback, ...)
        if AGP.FirstTime(ply, key) then AGP.Say(ply, key, fallback, ...) end
    end
else
    net.Receive("agp_say", function()
        local key, fallback = net.ReadString(), net.ReadString()
        local args = {}
        for i = 1, net.ReadUInt(4) do
            local a = net.ReadString()
            args[i] = tonumber(a) or AGP.L(a, a)     -- arguments may be keys themselves (part names)
        end
        local mode = net.ReadUInt(3)
        local text = AGP.L(key, fallback, unpack(args))
        if (mode == 1) then LocalPlayer():PrintMessage(HUD_PRINTCENTER, text)
        elseif (mode >= 2 and mode <= 4) then
            notification.AddLegacy(text, mode == 2 and NOTIFY_ERROR or mode == 4 and NOTIFY_HINT or NOTIFY_GENERIC, 6)
            surface.PlaySound(mode == 2 and "buttons/button2.wav" or "buttons/button9.wav")
        elseif (mode == 5) then print(text)
        else chat.AddText(Color(120, 200, 255), "[AGP] ", Color(230, 235, 240), text) end
    end)
end

-- 2026-11-10: names of the HL2 ammo types our weapons use (the HUD showed "#GaussEnergy_ammo"), in the player's
-- language - again when the Stargate language changes
if CLIENT then
    local AMMO = {
        HelicopterGun = { "agp_ammo_energy", "Energy charge" },   -- Ori staff, Asuran weapon, Ronon's gun, Wraith blaster
        CombineCannon = { "agp_ammo_plasma", "Plasma charge" },   -- Jaffa staff weapon
        GaussEnergy = { "agp_ammo_cell", "Energy cell" },          -- Zat'nik'tel
    }
    local function ammoNames()
        for ammo, k in pairs(AMMO) do language.Add(ammo .. "_ammo", AGP.L(k[1], k[2])) end
    end
    ammoNames()
    hook.Add("InitPostEntity", "AGP.AmmoNames", ammoNames)
    cvars.AddChangeCallback("sg_language", function() timer.Simple(0.5, ammoNames) end, "AGP.AmmoNames")
end
