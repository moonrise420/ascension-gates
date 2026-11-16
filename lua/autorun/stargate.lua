-- Small library loader! Therefore no GPL Header (but it's GPLed)
StarGate = StarGate or {}
StarGate.CAP = true -- for some scripts
-- Find out, if the stargate is attempt to getting loaded on a server, which does not have it installed.
StarGate.Installed = true
StarGate.Loading = false
StarGate.WorkShop = false
StarGate.CapVer = 0

-- Only loads serverside files on server,clientside files on client, shared on both and vgui on client
local function ValidToInclude(state)
    return (state == "server" and SERVER) or ((state == "client" or state == "vgui") and CLIENT) or state == "shared"
end

-- This code commented right now, it was made for workshop, but due to size limit we still can't use it(
local function ValidToExecute(fl, state)
    return true
end

if (Gmod13Lib == nil) then
    include("a_gmod13.lua")
end

function StarGate.ParseVersion(vert)
    -- support two numbers in version with safe-parse numbers
    local ver = "0"
    local i = 0

    for v in string.gmatch(vert, "[0-9]+") do
        if (i == 0) then
            ver = v
        elseif (i == 1) then
            ver = ver .. "." .. v
            break -- only two numbers support
        end

        i = i + 1
    end

    return ver
end

local function CheckVersion()
    local vert = ""

    if (file.Exists("lua/cap_ver.lua", "GAME")) then
        vert = file.Read("lua/cap_ver.lua", "GAME")
    end

    -- AGP: StarGate.CapVer stays CAP's last build number (lua/cap_ver.lua) inside the game only, because other Stargate
    -- addons compare it ("needs CAP 4xx or newer"). The server shows our own name and version (was stargate_cap_version).
    StarGate.CapVer = StarGate.ParseVersion(vert)

    if (SERVER) then
        local v = (AGP and AGP.Version) or "unknown"
        local cv = CreateConVar("ascension_gates_version", v, {FCVAR_GAMEDLL, FCVAR_NOTIFY}, "Ascension Gates version (read only)")
        if (cv:GetString() ~= v) then RunConsoleCommand("ascension_gates_version", v) end
    end
end

--################# Loads the libraries @aVoN
function StarGate.Load()
    CheckVersion()
    MsgN("=======================================================")
    MsgN("Ascension Gates: Initializing")

    MsgN("Version: " .. ((AGP and AGP.Version) or StarGate.CapVer))

    -- Addons check
    if (file.Exists("stargate/shared/capcheck.lua", "LUA")) then
        include("stargate/shared/capcheck.lua")
    end

    for _, state in pairs({"shared", "server", "client", "vgui"}) do
        -- Init always comes at first!
        if (ValidToInclude(state) and #file.Find("stargate/" .. state .. "/init.lua", "LUA") == 1) then
            include("stargate/" .. state .. "/init.lua")
        end

        for _, v in pairs(file.Find("stargate/" .. state .. "/*.lua", "LUA")) do
            if (SERVER and state ~= "server" and (v == "init.lua" or ValidToExecute(v, state))) then
                AddCSLuaFile("stargate/" .. state .. "/" .. v) -- Add clientside files
            end

            if (ValidToInclude(state) and ValidToExecute(v, state) and v:lower() ~= "init.lua" and v:lower() ~= "capcheck.lua") then
                include("stargate/" .. state .. "/" .. v)
            end
        end
    end

    if (SERVER) then
        AddCSLuaFile("autorun/stargate.lua") -- Ourself of course!
        AddCSLuaFile("weapons/gmod_tool/stargate_base_tool.lua") -- Special GMOD Basetool
    end

    MsgN("=======================================================")
end

StarGate.Load()

--################# For the concommand @aVoN
-- Override is called in stargate_base/init.lua if someone calls lua_reloadents
function StarGate.CallReload(p)
    if (not IsValid(p) or game.SinglePlayer() or p:IsAdmin()) then
        StarGate.Load()

        for _, v in pairs(player.GetAll()) do
            v:SendLua("StarGate.Load()")
        end
    else
        p:SendLua("StarGate.Load()")

        -- fix for reload cfg
        timer.Simple(0, function()
            StarGate.Hook.PlayerInitialSpawn(p)
        end)
    end
end

if SERVER then
    concommand.Add("stargate_reload", StarGate.CallReload)

    -- AGP: protection inside shields is done in lua/entities/shield/init.lua (AGP.ShieldBlocksBlasts: blasts and damage
    -- from outside do not reach inside; AGP.ShieldStopsEverything: shots stop at the surface; sources inside still hit inside)
end