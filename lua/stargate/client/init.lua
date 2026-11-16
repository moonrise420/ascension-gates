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
	Stargate Lib for GarrysMod10
	Copyright (C) 2010 Madman07
]]
--
--################# Header ###################
--################# CODE ###################
--#########################################
--						Error report
--#########################################
-- AGP: CAP's online part (version check, stats call, links) is gone; this only sends load errors to the server (again every 20 min)
function StarGate.Hook.SendErrorReport(_, key)
    if (key ~= "+menu") then return end
    hook.Remove("PlayerBindPress", "StarGate.Hook.SendErrorReport")
    local installed = StarGate.InstalledOnClient()

    if (installed and StarGate_Group.Error and not game.SinglePlayer()) then
        net.Start("CL_CAP_ERROR")
        net.WriteTable(StarGate_Group.ErrorMSG)
        net.WriteTable(StarGate_Group.ErrorMSG_HTML)
        net.SendToServer()

        timer.Create("CL_CAP_ERROR", 1200.0, 0, function()
            net.Start("CL_CAP_ERROR")
            net.WriteTable(StarGate_Group.ErrorMSG)
            net.WriteTable(StarGate_Group.ErrorMSG_HTML)
            net.SendToServer()
        end)
    end
end

hook.Add("PlayerBindPress", "StarGate.Hook.SendErrorReport", StarGate.Hook.SendErrorReport)

--#########################################
--						Config Part
--#########################################
--################# Getting synced data from the server @aVoN
function StarGate.CFG.GetSYNC(len)
    local name = net.ReadString()

    -- fix for reload
    if (name == "_CFG_RELOAD_") then
        if (StarGate.CFG.Get and type(StarGate.CFG.Get) == "function") then
            local copy = StarGate.CFG.Get
            StarGate.CFG = {}
            StarGate.CFG.Get = copy
        end

        return
    end

    StarGate.CFG[name] = {}
    local count = net.ReadUInt(8)

    for i = 1, count do
        local k = net.ReadString()
        local t = net.ReadUInt(8) -- What type are we?

        if (t == 0) then
            StarGate.CFG[name][k] = util.tobool(net.ReadBit())
        elseif (t == 1) then
            StarGate.CFG[name][k] = net.ReadString()
        elseif (t == 2) then
            StarGate.CFG[name][k] = net.ReadDouble()
        elseif (t == 3) then
            StarGate.CFG[name][k] = net.ReadInt(8)
        elseif (t == 4) then
            StarGate.CFG[name][k] = net.ReadInt(16)
        elseif (t == 5) then
            StarGate.CFG[name][k] = net.ReadInt(32)
        end
    end
end

net.Receive("StarGate_CFG", StarGate.CFG.GetSYNC)

--################# Adds LifeSupport,ResourceDistribution and WireSupport to an entity when getting called - HAS TO BE CALLED BEFORE ANY OTHERTHING IS DONE IN A SENT (like includes) @aVoN
-- My suggestion is to put this on the really top of the shared.lua
function StarGate.LifeSupportAndWire(ENT)
    -- Currently a dummy, but maybe I need this sometime later?
end

--#########################################
--						Material Helpers
--#########################################
--################# Creates a new Material according to a given VMT String @aVoN
-- This is necessary, because sometimes you need to edit a material in an effect which results into conflicts with other scripts using that material too
function StarGate.MaterialFromVMT(name, VMT)
    if (type(VMT) ~= "string" or type(name) ~= "string") then return Material(" ") end -- Return a dummy Material
    local t = util.KeyValuesToTable("\"material\"{" .. VMT .. "}")

    for shader, params in pairs(t) do
        return CreateMaterial(name, shader, params)
    end
end

--################# Creates a copy of an existing Material and returns it @aVoN
function StarGate.MaterialCopy(name, filename)
    if (type(filename) ~= "string" or type(name) ~= "string") then return Material(" ") end -- Return a dummy Material
    filename = "materials/" .. filename:Trim():gsub(".vmt$", "") .. ".vmt"

    return StarGate.MaterialFromVMT(name, file.Read(filename, "GAME"))
end

StarGate.GroupSystem = StarGate.GroupSystem or 1

-- Get stargate system type
net.Receive("stargate_systemtype", function(len)
    StarGate.GroupSystem = net.ReadBit()
end)

-- is the pack's content installed on this client (not only the Lua sent by a server)?
function StarGate.InstalledOnClient()
    return file.Exists("materials/gui/agp_logo_256.png", "GAME")
end

function StarGate.ShowCapMotd(title, text)
    local TACFrame = vgui.Create("DFrame")
    if (AGP and AGP.ApplySkin) then AGP.ApplySkin(TACFrame) end -- AGP: our look
    TACFrame:SetPos(50, 50)
    TACFrame:SetSize(ScrW() - 100, ScrH() - 100)
    TACFrame:SetTitle(title)
    TACFrame:SetVisible(true)
    TACFrame:SetDraggable(false)
    TACFrame:ShowCloseButton(true)
    TACFrame:SetBackgroundBlur(false)
    TACFrame:MakePopup()

    TACFrame.Paint = function(self, w, h) -- AGP: our look (was a blurred grey screen)
        local C = AGP and AGP.Colors
        draw.RoundedBox(10, 0, 0, w, h, C and C.bg or Color(14, 20, 30, 245))
        draw.RoundedBox(8, 20, 35, w - 40, h - 55, C and C.panel or Color(24, 32, 46))
    end

    local MOTDHTMLFrame = vgui.Create("HTML", TACFrame)
    MOTDHTMLFrame:SetPos(25, 40)
    MOTDHTMLFrame:SetSize(TACFrame:GetWide() - 50, TACFrame:GetTall() - 65)
    local html = [[<html>
	<head>
	<style type='text/css'>
		body {
			background-color: #18202e;
			font-family: Roboto, Verdana, sans-serif;
			color: #e1ebf5;
		}
		h2 { color: #ffa032; }
		b { color: #38a0f0;
		}
		a:link {
			text-decoration: underline;
			color: #ffa032;
		}
		a:visited {
			text-decoration: underline;
			color: #ffa032;
		}
		a:active {
			text-decoration: underline;
		}
		a:hover {
			text-decoration: underline;
			color: #FFF;
		}
	</style>
	</head>
	<body>]] .. text .. "</body></html>"
    MOTDHTMLFrame:SetHTML(html)
end

net.Receive("CAP_GATESPAWNER", function(length)
    local map = net.ReadString()
    local path = net.ReadString()
    -- AGP: the file is saved where the spawner loads it by itself, no copying needed (was CAP's window with CAP links)
    local text = SGLanguage.GetMessage("agp_gtsp_saved", map)
    GAMEMODE:AddNotify(text, NOTIFY_GENERIC, 8)
    chat.AddText(Color(255, 190, 80), "[Ascension Gates] ", color_white, text)
    surface.PlaySound("buttons/button9.wav")
end)

--################
-- cl_convars.lua
--################
--################################ DON'T EDIT THIS FILE YOU CAN MAKE CHANGES IN THE GAME!!!!!!!!!!!!!
-- Defines
CreateClientConVar("cl_stargate_visualsship", 1, true, false) -- Global - Turns on or off all visuals which may suck FPS. Turning this to off will turn of all. If it's on, the one below will be used
CreateClientConVar("cl_stargate_visualsmisc", 1, true, false) -- Global - Turns on or off all visuals which may suck FPS. Turning this to off will turn of all. If it's on, the one below will be used
CreateClientConVar("cl_stargate_visualsweapon", 1, true, false) -- Global - Turns on or off all visuals which may suck FPS. Turning this to off will turn of all. If it's on, the one below will be used
CreateClientConVar("cl_stargate_dynlights", 0, true, false)
CreateClientConVar("cl_stargate_un_dynlights", 0, true, false)
-- AGP 2026-11-09: the horizon's refraction is on by default (owner's choice; CAP had it off for 2007 frame rates)
CreateClientConVar("cl_stargate_ripple", 1, true, false)
CreateClientConVar("cl_stargate_kenter", 1, true, false)
CreateClientConVar("cl_stargate_effects", 1, true, false)
CreateClientConVar("cl_kawoosh_material", 1, true, false)
CreateClientConVar("cl_draw_huds", 1, true, false)
CreateClientConVar("cl_dhd_letters", 1, true, false)
CreateClientConVar("cl_shield_hitradius", 1, true, false)
CreateClientConVar("cl_shield_hiteffect", 1, true, false)
CreateClientConVar("cl_shield_dynlights", 0, true, false)
CreateClientConVar("cl_shield_bubble", 1, true, false)
CreateClientConVar("cl_shield_design", 1, true, false)
CreateClientConVar("cl_harvester_dynlights", 1, true, false)
CreateClientConVar("cl_cloaking_shader", 1, true, false)
CreateClientConVar("cl_cloaking_hitshader", 1, true, false)
CreateClientConVar("cl_supergate_dynlights", 0, true, false)
CreateClientConVar("cl_applecore_light", 1, true, false)
CreateClientConVar("cl_applecore_smoke", 1, true, false)
CreateClientConVar("cl_shieldcore_refract", 1, true, false)
CreateClientConVar("cl_jumper_dynlights", 1, true, false)
CreateClientConVar("cl_jumper_heatwave", 1, true, false)
CreateClientConVar("cl_jumper_sprites", 1, true, false)
CreateClientConVar("cl_f302_heatwave", 1, true, false)
CreateClientConVar("cl_f302_sprites", 1, true, false)
CreateClientConVar("cl_shuttle_heatwave", 1, true, false)
CreateClientConVar("cl_shuttle_sprites", 1, true, false)
CreateClientConVar("cl_dart_heatwave", 1, true, false)
CreateClientConVar("cl_chair_dynlights", 1, true, false)
CreateClientConVar("cl_zat_dynlights", 1, true, false)
CreateClientConVar("cl_zat_hiteffect", 1, true, false)
CreateClientConVar("cl_zat_dissolveeffect", 1, true, false)
CreateClientConVar("cl_staff_dynlights", 0, true, false)
CreateClientConVar("cl_staff_dynlights_flight", 0, true, false)
CreateClientConVar("cl_staff_scorch", 1, true, false)
CreateClientConVar("cl_staff_smoke", 1, true, false)
CreateClientConVar("cl_drone_glow", 1, true, false)
CreateClientConVar("cl_gate_nuke_sunbeams", 1, true, false)
CreateClientConVar("cl_gate_nuke_rings", 1, true, false)
CreateClientConVar("cl_gate_nuke_shieldrings", 1, true, false)
CreateClientConVar("cl_gate_nuke_dynlights", 0, true, false)
CreateClientConVar("cl_gate_nuke_plasma", 1, true, false)
CreateClientConVar("cl_overloader_refract", 1, true, false)
CreateClientConVar("cl_overloader_particle", 1, true, false)
CreateClientConVar("cl_overloader_dynlights", 0, true, false)
CreateClientConVar("cl_asuran_laser", 1, true, false)
CreateClientConVar("cl_asuran_dynlights", 0, true, false)
CreateClientConVar("cl_dakara_rings", 1, true, false)
CreateClientConVar("cl_dakara_refract", 1, true, false)