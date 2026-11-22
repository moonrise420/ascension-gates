--[[
	Stargate Lib for GarrysMod10
	Copyright (C) 2007  aVoN

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
--################# DEFINES #################
StarGate.Hook = StarGate.Hook or {}

function StarGate.CheckModule(type)
    return true
end

--################# Init @aVoN
function StarGate.Init()
    -- Resource Distribution Installed?
    -- fix for client/server energy will be later @ AlexALX
    --[[(CLIENT and file.Exists("stargate/client/energy.lua","LUA") or SERVER and]]
    --Thanks to mercess2911: http://www.facepunch.com/showpost.php?p=15508150&postcount=10070
    if (StarGate.CheckModule("energy") and (Environments or #file.Find("weapons/gmod_tool/environments_tool_base.lua", "LUA") == 1 or Dev_Link or rd3_dev_link or #file.Find("weapons/gmod_tool/stools/dev_link.lua", "LUA") == 1 or #file.Find("weapons/gmod_tool/stools/rd3_dev_link.lua", "LUA") == 1)) then
        StarGate.HasResourceDistribution = true
    else
        StarGate.HasResourceDistribution = false
    end

    -- Grid Power: the energy network of the PowerGrid addon (required). PowerGrid decides whether its own network
    -- runs (no Spacebuild/RD, or "always") - StarGate.WireRD then hands every entity of the pack to it (AGP.Power).
    StarGate.AGPPower = false
    if (StarGate.CheckModule("energy") and PowerGrid and PowerGrid.Active) then
        StarGate.HasResourceDistribution = true
        StarGate.AGPPower = true
    end
    -- endless power sources (Asgard ion generator): off by default; changes right away
    if (not ConVarExists("agp_zpm_overload")) then
        CreateConVar("agp_zpm_overload", "0", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Ascension Gates: 1 = a ZPM without a hub overloads and explodes when too much energy is drawn, 0 = never (default)", 0, 1)
    end
    if (not ConVarExists("agp_allow_infinite_power")) then
        CreateConVar("agp_allow_infinite_power", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Ascension Gates: 1 = endless power sources (Asgard ion generator) may be spawned and give energy (default), 0 = not", 0, 1)
    end
    -- AGP: the ship weapons' energy (StarGate.WeaponEnergy, stargate/server/ship_weapons.lua). With a network running,
    -- an unlinked weapon had 0 energy and never fired; now it fires free unless set to 2
    if (not ConVarExists("agp_weapon_energy")) then
        CreateConVar("agp_weapon_energy", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Ascension Gates: weapons' energy - 0 = free, 1 = use energy when connected to a network (unconnected fire free), 2 = always need energy", 0, 2)
    end

    -- Wire?
    if (WireAddon or file.Exists("weapons/gmod_tool/stools/wire_adv.lua", "LUA")) then
        StarGate.HasWire = true

        if (file.IsDir("expression2", "DATA") and not file.IsDir("expression2/cap_shared", "DATA")) then
            file.CreateDir("expression2/cap_shared")
        end

        if (file.IsDir("starfall", "DATA") and not file.IsDir("starfall/cap_shared", "DATA")) then
            file.CreateDir("starfall/cap_shared")
        end
    else
        StarGate.HasWire = false
    end

    if (not file.IsDir("stargate", "DATA")) then
        file.CreateDir("stargate", "DATA")
    end
end

StarGate.Init() -- Call the Init

-- Add some usefull sounds to Wire Soundemitter
local snd = {
    -- AGP: the alarms are in sound/alarm/ (lower-case names), not in sound/: these six played nothing
    ["SGC Alarm"] = "alarm/sgc_alarm.wav",
    ["SGC Offworld Alarm"] = "alarm/sgc_offworld-alarm.wav",
    ["SGA Offworld Alarm"] = "alarm/sga_offworld-alarm.wav",
    ["SGA Selfdestruct Alarm"] = "alarm/sga_selfdestruct-alarm.wav",
    ["Midway Offworld Alarm"] = "alarm/sga_midway_alarm.wav",
    ["Midway Selfdestruct Alarm"] = "alarm/sga_midway_selfdestruct.wav",
    ["Walter: Chevron 1 encoded"] = "stargate/walter/c1.mp3",
    ["Walter: Chevron 2 encoded"] = "stargate/walter/c2.mp3",
    ["Walter: Chevron 3 encoded"] = "stargate/walter/c3.mp3",
    ["Walter: Chevron 4 encoded"] = "stargate/walter/c4.mp3",
    ["Walter: Chevron 5 encoded"] = "stargate/walter/c5.mp3",
    ["Walter: Chevron 6 encoded"] = "stargate/walter/c6.mp3",
    ["Walter: Chevron 7 encoded"] = "stargate/walter/c7.mp3",
    ["Walter: Chevron 7 locked"] = "stargate/walter/c7_locked.mp3",
    ["Walter: Chevron 7 failed"] = "stargate/walter/c7_failed.mp3",
    ["Walter: Chevron 8 locked"] = "stargate/walter/c8_locked.mp3",
    ["Walter: Unscheduled Offworld Activation"] = "stargate/walter/unscheduled_offworld_activation.mp3",
    ["Ring Transporter Button 1"] = "button/ring_button1.mp3",
    ["Ring Transporter Button 2"] = "button/ring_button2.mp3"
}

for k, v in pairs(snd) do
    list.Set("WireSounds", k, {
        wire_soundemitter_sound = v
    })
end

-- print_r function by aVoN - use it anywhere you want - Dumps data from all datatypes into console
-- ########## Recursive print @aVoN
local function do_print_r(arg, spaces, passed)
    local t = type(arg)

    --Recursion
    if (t == "table") then
        if (arg.r and arg.g and arg.b and arg.a and table.Count(arg) == 4) then
            Msg("Color(" .. arg.r .. "," .. arg.g .. "," .. arg.b .. "," .. arg.a .. ")\n")

            return
        end

        passed[arg] = true
        Msg("(table) " .. tostring(arg):gsub("table: ", "") .. " { \n")

        for k, v in pairs(arg) do
            if (not passed[v]) then
                Msg("  " .. spaces .. "(" .. type(k) .. ") " .. tostring(k) .. " => ")
                do_print_r(rawget(arg, k), spaces .. "  ", passed)
            else
                Msg("  " .. spaces .. "(" .. type(k) .. ") " .. tostring(k) .. " => [RECURSIVE TABLE: " .. tostring(v) .. "]\n")
            end
        end

        Msg(spaces .. "}\n")
    elseif (t == "function") then
        Msg("(" .. t .. ") " .. tostring(arg):gsub("function: ", "") .. "\n")
    elseif (t == "string") then
        Msg("(" .. t .. ") '" .. tostring(arg) .. "'\n")
    elseif (t == "Vector") then
        Msg(t .. "(" .. arg.x .. "," .. arg.y .. "," .. arg.z .. ")\n")
    elseif (t == "Angle") then
        Msg(t .. "(" .. arg.p .. "," .. arg.y .. "," .. arg.r .. ")\n")
    else
        Msg("(" .. t .. ") " .. tostring(arg) .. "\n")
    end
end

-- ########## print_r @aVoN
function print_r(...)
    local arg = {...}
    -- Single data input
    local passed = {} -- Every table, which already got passed is stored in here, so we won't go into an infinite-loop

    if (#arg == 1) then
        do_print_r(arg[1], "", passed)
    else
        for k = 1, #arg do
            do_print_r(arg[k], "", passed)
        end
    end
end

--###########
-- ramps.lua
--###########
--[[
	##################################
	Ramp Offset/List file, idea by AlexALX
	##################################
	Also you can write stargate_reload (not lua_reloadents) to update ramp offsets (much faster).
	But for reload stools you still need to write restart.
	All models paths must be in LOWER case.
]]
-- ################### For stools ###################
-- For reloading the stools require writen restart.
-- All models paths must be in LOWER case.
StarGate.Ramps = {} -- Remove old array if reload, idk if this needed, just added to be sure
-- For anim ramps stool
StarGate.Ramps.AnimDefault = {"models/markjaw/2010_ramp.mdl", "future_ramp", Vector(0, 0, 145)}

StarGate.Ramps.Anim = {
    ["models/markjaw/2010_ramp.mdl"] = {"future_ramp", Vector(0, 0, 145)},
    ["models/markjaw/sgu_ramp.mdl"] = {"sgu_ramp", Vector(0, 0, 150)},
    ["models/iziraider/sguramp/sgu_ramp.mdl"] = {"sgu_ramp", Vector(0, 0, 41)},
    ["models/iziraider/ramp2/ramp2.mdl"] = {"ramp_2", Vector(0, 0, -5)},
    ["models/zup/ramps/sgc_ramp.mdl"] = {"sgc_ramp", Vector(0, 0, 148)},
    ["models/zsdaniel/icarus_ramp/icarus_ramp.mdl"] = {"icarus_ramp", Vector(0, 0, 41)},
    ["models/boba_fett/ramps/ramp8.mdl"] = {"goauld_ramp"},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp.mdl"] = {"sgu_ramp"},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp_old.mdl"] = {"sgu_ramp"},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp_small.mdl"] = {"sgu_ramp"}
}

-- For non-anim ramps stool
StarGate.Ramps.NonAnimDefault = "models/iziraider/ramp1/ramp1.mdl"

StarGate.Ramps.NonAnim = {
    ["models/iziraider/ramp1/ramp1.mdl"] = {},
    ["models/iziraider/ramp2/ramp2.mdl"] = {},
    ["models/iziraider/ramp3/ramp3.mdl"] = {Vector(0, 0, 0), Angle(0, 270, 0)},
    ["models/iziraider/ramp4/ramp4.mdl"] = {},
    ["models/iziraider/sguramp/sgu_ramp.mdl"] = {},
    ["models/iziraider/sga_ramp/sga_ramp.mdl"] = {},
    ["models/zup/ramps/sgc_ramp.mdl"] = {},
    ["models/zup/ramps/brick_01.mdl"] = {},
    ["models/markjaw/sgu_ramp.mdl"] = {},
    ["models/zsdaniel/ramp/ramp.mdl"] = {},
    ["models/zsdaniel/icarus_ramp/icarus_ramp.mdl"] = {},
    ["models/madman07/ori_ramp/ori_ramp.mdl"] = {},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp.mdl"] = {},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp_old.mdl"] = {},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp_small.mdl"] = {},
    ["models/boba_fett/ramps/moebius_ramp/moebius_ramp.mdl"] = {},
    ["models/boba_fett/catwalk_build/hover_ramp.mdl"] = {},
    ["models/boba_fett/ramps/ramp.mdl"] = {},
    ["models/boba_fett/ramps/ramp2.mdl"] = {},
    ["models/boba_fett/ramps/ramp3.mdl"] = {},
    ["models/boba_fett/ramps/ramp4.mdl"] = {},
    ["models/boba_fett/ramps/ramp5.mdl"] = {},
    ["models/boba_fett/ramps/ramp6.mdl"] = {},
    ["models/boba_fett/ramps/ramp7.mdl"] = {},
    ["models/boba_fett/ramps/ramp9.mdl"] = {},
    ["models/boba_fett/ramps/ramp10.mdl"] = {},
    ["models/boba_fett/ramps/ramp11.mdl"] = {},
    ["models/boba_fett/ramps/ramp12.mdl"] = {},
    ["models/markjaw/midway/midway.mdl"] = {}
}

-- For ring ramps stool
StarGate.Ramps.RingDefault = "models/madman07/spawn_ramp/spawn_ring.mdl"

StarGate.Ramps.Ring = {
    ["models/madman07/spawn_ramp/spawn_ring.mdl"] = {},
    ["models/boba_fett/rings/ring_platform.mdl"] = {},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp.mdl"] = {},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp2.mdl"] = {},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp3.mdl"] = {}
}

-- ################### Offsets ###################
-- You can write stargate_reload (not lua_reloadents) to update ramp offsets (much faster).
-- All model paths must be in LOWER case.
-- Offsets for "InRamp"-Spawning
StarGate.RampOffset = {} -- Remove old array if reload, idk if this needed, just added to be sure

-- For StarGates
StarGate.RampOffset.Gates = {
    ["models/zup/ramps/sgc_ramp.mdl"] = {Vector(0, 0, 0)},
    ["models/zup/ramps/brick_01.mdl"] = {Vector(0, 0, -10)},
    ["models/iziraider/sguramp/sgu_ramp.mdl"] = {Vector(-105, 0, 96)},
    ["models/iziraider/ramp1/ramp1.mdl"] = {Vector(-240, 0, 128)},
    ["models/iziraider/ramp2/ramp2.mdl"] = {Vector(-270, 0, 138)},
    ["models/iziraider/ramp3/ramp3.mdl"] = {Vector(0, -120, 124.5), Angle(0, 90, 0)},
    ["models/iziraider/ramp4/ramp4.mdl"] = {Vector(-270, 0, 171)},
    ["models/iziraider/sga_ramp/sga_ramp.mdl"] = {Vector(-234, 0, 87)},
    ["models/madman07/ori_ramp/ori_ramp.mdl"] = {Vector(-338, 0, 143)},
    ["models/markjaw/2010_ramp.mdl"] = {Vector(0, 0, 0)},
    ["models/markjaw/sgu_ramp.mdl"] = {Vector(-2, 0, -1)},
    ["models/zsdaniel/ramp/ramp.mdl"] = {Vector(0, 0, 140)},
    ["models/zsdaniel/icarus_ramp/icarus_ramp.mdl"] = {Vector(-192, 0, 97.5)},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp.mdl"] = {Vector(-109, 0, 135)},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp_old.mdl"] = {Vector(-109, 0, 135)},
    ["models/boba_fett/ramps/sgu_ramp/sgu_ramp_small.mdl"] = {Vector(-92.2, 0, 142)},
    ["models/boba_fett/ramps/moebius_ramp/moebius_ramp.mdl"] = {Vector(0, 0, 149)},
    ["models/boba_fett/catwalk_build/hover_ramp.mdl"] = {Vector(-400, 0, 195)},
    ["models/boba_fett/catwalk_build/gate_platform.mdl"] = {Vector(0, 0, -2.5), Angle(-90, 0, 0)},
    ["models/boba_fett/ramps/ramp.mdl"] = {Vector(-85, 0, 159)},
    ["models/boba_fett/ramps/ramp2.mdl"] = {Vector(-65, 0, 145)},
    ["models/boba_fett/ramps/ramp3.mdl"] = {Vector(-67, 0, 225)},
    ["models/boba_fett/ramps/ramp4.mdl"] = {Vector(0, 0, 90)},
    ["models/boba_fett/ramps/ramp5.mdl"] = {Vector(0, 0, 219)},
    ["models/boba_fett/ramps/ramp6.mdl"] = {Vector(-38, 0, 159)},
    ["models/boba_fett/ramps/ramp7.mdl"] = {Vector(0, 0, 110)},
    ["models/boba_fett/ramps/ramp8.mdl"] = {Vector(0, 0, 146)},
    ["models/boba_fett/ramps/ramp9.mdl"] = {Vector(-198, 0, 142)},
    ["models/boba_fett/ramps/ramp10.mdl"] = {Vector(-184, 0, 133)},
    ["models/boba_fett/ramps/ramp11.mdl"] = {Vector(-180, 0, 126)},
    ["models/boba_fett/ramps/ramp12.mdl"] = {Vector(-50, 0, 137)},
    ["models/markjaw/midway/midway.mdl"] = {Vector(675, 0, 0), Angle(0, -180, 0), Vector(-672, 0, 0)}
}

-- For DHD's
StarGate.RampOffset.DHD = {
    ["models/iziraider/ramp1/ramp1.mdl"] = {Vector(300, 0, 5), Angle(15, 0, 0)},
    ["models/iziraider/ramp2/ramp2.mdl"] = {Vector(318, 0, 30), Angle(15, 180, 0)},
    ["models/iziraider/ramp3/ramp3.mdl"] = {Vector(0, 165, 13), Angle(0, 90, 0)}, --,Angle(15,90,0)},
    ["models/iziraider/ramp4/ramp4.mdl"] = {Vector(95, 5, 11), Angle(15, 0, 0)},
    ["models/iziraider/sga_ramp/sga_ramp.mdl"] = {Vector(-160, -163, -7), Angle(15, 35, 0)},
    ["models/madman07/ori_ramp/ori_ramp.mdl"] = {Vector(100, 0, 39), Angle(15, 0, 0)},
    ["models/boba_fett/ramps/ramp10.mdl"] = {Vector(-10, -110, 56), Angle(15, 35, 0)},
    ["models/boba_fett/catwalk_build/hover_ramp.mdl"] = {Vector(-290, -140, 97), Angle(15, 35, 0)}
}

-- For Concept DHD's
StarGate.RampOffset.DHDC = {
    ["models/boba_fett/ramps/ramp9.mdl"] = {Vector(20, 0, 20)}
}

-- For Rings
StarGate.RampOffset.Ring = {
    ["models/madman07/spawn_ramp/spawn_ring.mdl"] = {Vector(8, 0, 12)},
    ["models/boba_fett/rings/ring_platform.mdl"] = {Vector(0, 0, 20)},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp.mdl"] = {Vector(0, 0, 23)},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp2.mdl"] = {Vector(0, 0, 20)},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp3.mdl"] = {Vector(0, 0, 14)},
    ["models/boba_fett/catwalk_build/hover_ramp.mdl"] = {Vector(270, 0, 112.5)},
    ["models/boba_fett/catwalk_build/hiding_circle_rings.mdl"] = {Vector(0, 0, 0)}
}

-- For Ring Panels
StarGate.RampOffset.RingP = {
    ["models/madman07/spawn_ramp/spawn_ring.mdl"] = {Vector(-98, 0, 57.5)},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp.mdl"] = {Vector(0, -96.5, 69), Angle(0, 90, 0)},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp2.mdl"] = {Vector(-98.5, 0, 58)},
    ["models/boba_fett/ramps/ring_ramps/ring_ramp3.mdl"] = {Vector(-88.5, 0, 47)},
    ["models/boba_fett/catwalk_build/hover_ramp.mdl"] = {Vector(369.5, 0, 162.5), Angle(0, 180, 0)},
    ["models/boba_fett/catwalk_build/hiding_circle_rings.mdl"] = {Vector(88, 0, 21), Angle(0, 180, 0)}
}

--###################################
-- weapon.lua
-- Copyright (C) 2012 Llapp, AlexALX
--###################################
if (CLIENT) then
    local function DropBindPress(ply, bind, pressed)
        if ply:Alive() then
            if string.find(bind, "impulse 201") then
                RunConsoleCommand("Drop_Weapon")

                return false
            end
        end
    end

    hook.Add("PlayerBindPress", "DropBindPress", DropBindPress)
end

if (SERVER) then
    -- damn man, this should be only server-side, or there is lags in mp.
    local function Drop(ply)
        if (not StarGate.CFG:Get("cap_misc", "allow_drop_weapons", true)) then return end
        if (not ply:GetActiveWeapon():IsValid() or ply:IsTyping() or IsValid(ply.WireKeyboard) or ply:InVehicle()) then return end
        local allow = hook.Call("StarGate.Player.DropWeapon", nil, ply, ply:GetActiveWeapon())
        if (allow == false) then return end
        local tr = ply:GetEyeTraceNoCursor()
        local class = ply:GetActiveWeapon():GetClass()

        -- don't know why, but it spawn ivnisible if use class
        if (class == "sg_adrenaline") then
            local ent = ents.Create("sg_adrenaline_thrown")
            ent:SetPos(tr.StartPos + ply:GetAimVector() - Vector(0, 0, 15))
            ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
            ent:Spawn()
            ent:Activate()
            ent:PhysicsInit(SOLID_VPHYSICS)
            ent:SetMoveType(MOVETYPE_VPHYSICS)
            ent:SetSolid(SOLID_VPHYSICS)
            local phys = ent:GetPhysicsObject()

            if (IsValid(phys)) then
                phys:Wake()
                phys:AddAngleVelocity(Vector(100, 50, 100))
                phys:SetVelocity(ply:GetAimVector() * Vector(250, 250, 0))
                ply:StripWeapon(class)
            else
                ent:Remove()
                ply:DropWeapon(ply:GetActiveWeapon())
            end
        else
            local ent = ents.Create(class)
            ent:SetPos(tr.StartPos + ply:GetAimVector() - Vector(0, 0, 5))
            ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
            ent:Spawn()
            ent:Activate()
            ent:PhysicsInit(SOLID_VPHYSICS)
            ent:SetMoveType(MOVETYPE_VPHYSICS)
            ent:SetSolid(SOLID_VPHYSICS)
            ent.PhysFixEnt = true
            local phys = ent:GetPhysicsObject()

            if (IsValid(phys)) then
                phys:Wake()
                phys:AddAngleVelocity(Vector(100, 50, 100))
                phys:SetVelocity(ply:GetAimVector() * Vector(250, 250, 0))
                ply:StripWeapon(class)
                -- this is fix for player touch
                local ent2 = ents.Create(class)
                ent2:PhysWake()
                ent2:SetPos(tr.StartPos + ply:GetAimVector() - Vector(0, 0, 5))
                ent2:SetAngles(Angle(0, ply:EyeAngles().y, 0))
                ent2:Spawn()
                ent2:Activate()
                ent2:SetParent(ent)
                ent2:SetColor(Color(0, 0, 0, 0))
                ent2:SetRenderMode(RENDERMODE_TRANSALPHA)
                ent2.PhysFixEnt = true
                ent.PhysFix = ent2

                timer.Simple(1.0, function()
                    if IsValid(ent) then
                        ent.PhysFixEnt = false
                    end
                end)
            else
                ent:Remove()
                ply:DropWeapon(ply:GetActiveWeapon())
            end
        end
    end

    concommand.Add("Drop_Weapon", Drop)

    hook.Add("PlayerCanPickupWeapon", "StarGate.PlayerCanPickupWeapon.PhysFix", function(ply, wep)
        if (wep.PhysFixEnt) then return false end

        if (IsValid(wep.PhysFix)) then
            wep.PhysFix:Remove()
        end

        return
    end)

    --################# Speeds the weapons change and give back
    -- AGP: CAP gave back fixed numbers (run 500, jump 200, armour 0, after a zat / hand device hit walk 250 run 500 -
    -- sandbox is walk 200 run 400) instead of what the player had, and the zat and hand device shared ONE timer
    -- "StarGate.UnParalyze" for every victim (a second victim within 4 s cancelled the first one's restore).

    -- The run speed a player has when no zat / hand device slow-down is on. During one it is kept aside and comes back
    -- at its end, so a weapon that speeds him up (armband, wraith hands) or gives speed back changes that one.
    function StarGate.BaseRunSpeed(ply)
        return ply.AGPParalyzed and ply.AGPParalyzed.run or ply:GetRunSpeed()
    end

    function StarGate.SetBaseRunSpeed(ply, run)
        if (ply.AGPParalyzed) then
            ply.AGPParalyzed.run = run
        else
            ply:SetRunSpeed(run)
        end
    end

    -- Slows a player down for `time` seconds (a new hit starts the time again); his own speeds come back at the end.
    function StarGate.ParalyzePlayer(ply, walk, run, time)
        if (not IsValid(ply) or not ply:IsPlayer()) then return end

        if (not ply.AGPParalyzed) then
            ply.AGPParalyzed = { walk = ply:GetWalkSpeed(), run = ply:GetRunSpeed() }
        end

        ply:SetWalkSpeed(walk)
        ply:SetRunSpeed(run)

        timer.Create("StarGate.UnParalyze." .. ply:EntIndex(), time or 4, 1, function()
            StarGate.UnParalyzePlayer(ply)
        end)
    end

    function StarGate.UnParalyzePlayer(ply)
        if (not IsValid(ply)) then return end
        timer.Remove("StarGate.UnParalyze." .. ply:EntIndex())
        local old = ply.AGPParalyzed
        if (not old) then return end
        ply.AGPParalyzed = nil
        ply:SetWalkSpeed(old.walk)
        ply:SetRunSpeed(old.run)
    end

    -- Atanik armband on / off: run, jump and armour come back as they were. Armour: what he had, less what the armband's
    -- armour did not soak up (CAP set armour 200 on - less for someone with more - and 0 off, wiping real armour).
    function StarGate.AtanikOn(ply)
        if (not IsValid(ply) or ply.CAP_Atanik) then return end
        ply.CAP_AtanikOld = { run = StarGate.BaseRunSpeed(ply), jump = ply:GetJumpPower(), armor = ply:Armor() }
        StarGate.SetBaseRunSpeed(ply, 1000)
        ply:SetJumpPower(500)
        ply:SetArmor(math.max(ply:Armor(), 200))
        ply.CAP_Atanik = true
    end

    function StarGate.AtanikOff(ply)
        if (not IsValid(ply) or not ply.CAP_Atanik) then return end
        local old = ply.CAP_AtanikOld
        ply.CAP_Atanik = nil
        ply.CAP_AtanikOld = nil
        if (not old) then return end
        StarGate.SetBaseRunSpeed(ply, old.run)
        ply:SetJumpPower(old.jump)
        ply:SetArmor(math.min(ply:Armor(), old.armor))
    end

    -- A new life starts with the gamemode's speeds and armour: forget what was kept aside. (Getting out of a ship or
    -- the KINO view, AGP.ShipRespawnPilot, is no new life.)
    hook.Add("PlayerSpawn", "StarGate.WeaponSpeeds.Reset", function(ply)
        if (not IsValid(ply) or ply.AGPShipLeaving) then return end
        timer.Remove("StarGate.UnParalyze." .. ply:EntIndex())
        ply.AGPParalyzed = nil
        ply.CAP_Atanik = nil
        ply.CAP_AtanikOld = nil
    end)

    -- Instead of loading every second, this can be like hook when player changed weapon
    -- and this should be also server-side only or we have LAGS in mp.
    hook.Add("PlayerSwitchWeapon", "StarGate.WeaponCheck.Changed", function(ply, weapon1, weapon2)
        -- AGP: also when nothing was in the hand before (weapon1 NULL); the armband through
        -- StarGate.AtanikOn / AtanikOff (gives back what the player had)
        if (not ply or not IsValid(ply) or not ply:IsPlayer()) then return end

        -- if we changed to weapon atanik_armband
        if (IsValid(weapon2) and weapon2:GetClass() == "atanik_armband") then
            -- AGP: one tick later - this hook runs before the old weapon's Holster, and that may still give its own speeds
            -- back (wraith hands), which overwrote the armband's
            timer.Simple(0, function()
                if (IsValid(ply) and IsValid(weapon2) and ply:GetActiveWeapon() == weapon2) then
                    StarGate.AtanikOn(ply)
                end
            end)
            -- if we changed from weapon atanik_armband to another
        elseif (IsValid(weapon1) and weapon1:GetClass() == "atanik_armband") then
            StarGate.AtanikOff(ply)
        end
    end)
    -- PLEASE DO NOT EDIT! it works perfect in sp and mp! Don't touch code!
end