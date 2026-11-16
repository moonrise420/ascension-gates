--[[
	Stargate Lib for GarrysMod10
	Copyright (C); 2007  aVoN

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option); any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]
StarGate.KeyBoard = StarGate.KeyBoard or {}

if SERVER then
    concommand.Add("_StarGate.KeyPressed", function(p, _, args)
        StarGate.KeyBoard:SetKeyPressed(p, args[1], args[2])
    end)

    concommand.Add("_StarGate.KeyReleased", function(p, _, args)
        StarGate.KeyBoard:SetKeyReleased(p, args[1], args[2])
    end)
end

--######################################
--############# KeyDown-Hooks
--######################################
StarGate.KeyBoard.Pressed = StarGate.KeyBoard.Pressed or {} -- Stores pressed Keys per player.
-- A recursive-metatable which creates a new "subtable" on StarGate.KeyBoard.Pressed, if it doesn't exist yet and so on. Very usefull! (I used this in my unreleased AddonLoader SySLib very often)
local recursive = {}

recursive.__index = function(t, k)
    if (not rawget(t, k)) then
        rawset(t, k, {})
        setmetatable(t[k], recursive) -- Recursive part
    end

    return rawget(t, k)
end

setmetatable(StarGate.KeyBoard.Pressed, recursive)

--################### Calls hooks and sets keys pressed or unpressed @aVoN
function StarGate.KeyBoard:SetKeyPressed(p, name, k)
    if (hook.Call("StarGate.Player.KeyEvent", GAMEMODE, p, name, k, true) == false) then return end
    if (hook.Call("StarGate.Player.KeyPressed", GAMEMODE, p, name, k) == false) then return end
    StarGate.KeyBoard.Pressed[p][name][k] = true

    if CLIENT then
        RunConsoleCommand("_StarGate.KeyPressed", name, k)
    end
end

function StarGate.KeyBoard:SetKeyReleased(p, name, k)
    if (hook.Call("StarGate.Player.KeyEvent", GAMEMODE, p, name, k, false) == false) then return end
    if (hook.Call("StarGate.Player.KeyReleased", GAMEMODE, p, name, k) == false) then return end
    StarGate.KeyBoard.Pressed[p][name][k] = nil

    if CLIENT then
        RunConsoleCommand("_StarGate.KeyReleased", name, k)
    end
end

function StarGate.KeyBoard.ResetKeys(p, name)
    if (not p or not name) then return end

    for key, v in pairs(StarGate.KeyBoard.Pressed[p][name]) do
        StarGate.KeyBoard.Pressed[p][name][key] = nil
    end
end

--################### Overwrites the player's KeyDown etc function to use our system, if two arguments are given @aVoN
local meta = FindMetaTable("Player")
if (not meta) then return end
--Backup old
meta.__KeyDown = meta.__KeyDown or meta.KeyDown

-- I'm currently not planning to add this "feature" to KeyPressed and KeyReleased because we dont use it
function meta:KeyDown(name, key)
    if (name and key) then return (StarGate.KeyBoard.Pressed[self][name][key] == true) end
    -- Old GMod behaviour

    return meta.__KeyDown(self, name)
end

-- fix by AlexALX
local function playerDies(p)
    for name, v in pairs(StarGate.KeyBoard.Pressed[p]) do
        for key, v2 in pairs(v) do
            StarGate.KeyBoard.Pressed[p][name][key] = nil
        end
    end
end

hook.Add("PlayerDeath", "StarGate.KeyBoard.Death", playerDies)
hook.Add("PlayerSilentDeath", "StarGate.KeyBoard.Death", playerDies)

-- AGP: removed CAP's hidden player statistics (a 0x0 web panel sent SteamID, name, language, OS and addon info
-- to a third-party site on the first key press) and its hidden SteamID blacklist. The table stays empty because
-- server code still looks it up.
StarGate.SlGort = {}
