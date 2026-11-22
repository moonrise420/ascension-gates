--[[
        BC-304 "Daedalus"
        Copyright (C) 2010 Madman07

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

]]--
include('shared.lua');
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
ENT.PrintName = SGLanguage.GetMessage("entity_daedalus");
end

if (StarGate==nil or StarGate.KeyBoard==nil or StarGate.KeyBoard.New==nil) then return end

local KBD = StarGate.KeyBoard:New("Daedalus")
KBD:SetDefaultKey("FWD", StarGate.KeyBoard.BINDS["+forward"] or "W") -- Forward
KBD:SetDefaultKey("LEFT", StarGate.KeyBoard.BINDS["+moveleft"] or "A") -- Move Left
KBD:SetDefaultKey("RIGHT", StarGate.KeyBoard.BINDS["+moveright"] or "D") -- Move Right
KBD:SetDefaultKey("BACK", StarGate.KeyBoard.BINDS["+back"] or "S") -- Go backwards
KBD:SetDefaultKey("UP", StarGate.KeyBoard.BINDS["+jump"] or "SPACE") -- Strafe Up
KBD:SetDefaultKey("DOWN", StarGate.KeyBoard.BINDS["+duck"] or "CTRL") -- Strafe Down
KBD:SetDefaultKey("SPD", StarGate.KeyBoard.BINDS["+speed"] or "SHIFT") -- Speed Up
KBD:SetDefaultKey("FIRE", StarGate.KeyBoard.BINDS["+attack"] or "MOUSE1") -- Fire railgun
KBD:SetDefaultKey("FIRE2", StarGate.KeyBoard.BINDS["+attack2"] or "MOUSE2") -- Fire asgard
KBD:SetDefaultKey("MODE", StarGate.KeyBoard.BINDS["+reload"] or "R") -- Target mode
KBD:SetDefaultKey("EXIT", StarGate.KeyBoard.BINDS["+use"] or "E") -- Exit
KBD:SetDefaultKey("SHIELD", "G") -- AGP: shield
KBD:SetDefaultKey("HYPERSPACE", "H") -- AGP: hold to charge the hyperdrive

-- rockets
for i = 1, 8 do
    KBD:SetDefaultKey(tostring(i), StarGate.KeyBoard.BINDS["slot" .. i] or tostring(i))
end

local BreachWarning = surface.GetTextureID("VGUI/HUD/BC304_HUD/breachwarning")
local MainHud_left = surface.GetTextureID("VGUI/HUD/BC304_HUD/mainhud_left")
local MainHud_right = surface.GetTextureID("VGUI/HUD/BC304_HUD/mainhud_right")
local WeaponsHud_middle = surface.GetTextureID("VGUI/HUD/BC304_HUD/weaponshud_middle")
local WeaponsHud_left = surface.GetTextureID("VGUI/HUD/BC304_HUD/weaponshud_left")
local WeaponsHud_right = surface.GetTextureID("VGUI/HUD/BC304_HUD/weaponshud_right")
local OnOff = surface.GetTextureID("VGUI/HUD/BC304_HUD/on_off_button")
local PHSBar = surface.GetTextureID("VGUI/HUD/BC304_HUD/power_hull_shield_bar")
local SubBar = surface.GetTextureID("VGUI/HUD/BC304_HUD/sublightengine_bar")
local WepBar = surface.GetTextureID("VGUI/HUD/BC304_HUD/weapons_bar")
local Pressed = false

function ENT:Initialize()
    self.Vehicle = "Daedalus"
    self.KBD = self.KBD or KBD:CreateInstance(self)
    self.FXEmitter = ParticleEmitter(self:GetPos())
    LocalPlayer().ViewMode = 0
    LocalPlayer().RailgunEnable = 0
    LocalPlayer().HUDEnable = true
    self.EngineSound = CreateSound(self.Entity, Sound("ships/cargo_ship_interor_idle.wav"))

    -- FIRE_RING.PCF
    -- fire_ring_01
    -- smoke_oily_01
    -- FIREFLOW.PCF
    -- bonfire
    -- FLAMETHROWERTEST.PCF
    -- flame
    self.AttLastPos = {Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0), Vector(0, 0, 0)}
end

function ENT:Think()
    -- "ELB",
    -- "ERB",
    -- "ELM1",
    -- "ELM2",
    -- "ERM1",
    -- "ERM2",
    -- "ELS1",
    -- "ELS2",
    -- "ERS1",
    -- "ERS2"
    local p = LocalPlayer()
    local IsDriver = (p:GetNetworkedEntity(self.Vehicle, NULL) == self.Entity)

    -- AGP: only the Daedalus you fly sets the keys and the HUD values (a second one on the map switched your keys off
    -- and wrote its own values into your HUD)
    if (IsDriver) then
        self.KBD:SetActive(true)
        self.AGPKbdOn = true
    elseif (self.AGPKbdOn) then
        self.KBD:SetActive(false)
        self.AGPKbdOn = nil
    end

    if (IsDriver) then
    LocalPlayer().ViewMode = self.Entity:GetNetworkedInt("ViewMode")
    LocalPlayer().Sublight = self.Entity:GetNetworkedInt("Sublight")
    LocalPlayer().Hull = self.Entity:GetNetworkedInt("Hull")
    LocalPlayer().Shield = self.Entity:GetNetworkedInt("Shield")
    LocalPlayer().Power = self.Entity:GetNetworkedInt("Power")
    LocalPlayer().Hangar = self.Entity:GetNetworkedInt("Hangar")
    LocalPlayer().PowerSource = self.Entity:GetNetworkedInt("PowerSource")
    LocalPlayer().ShieldStatus = self.Entity:GetNetworkedInt("ShieldStatus")
    LocalPlayer().Hyperdrive = self.Entity:GetNetworkedInt("Hyperdrive")
    LocalPlayer().Warning = 0
    end

    if (Pressed == true) then
        timer.Simple(1, function()
            Pressed = false
        end)
    end

    self:StartSound()
    self.EngineSound:ChangePitch(100 + self.Entity:GetNetworkedInt("Sublight") / 10, 0)
end

function ENT:StartSound()
    if (not self.EngineSoundActive) then
        self.EngineSound:PlayEx(1, 100)
        self.EngineSoundActive = true
    end
end

function ENT:OnRemove()
    if (self.EngineSound) then
        self.EngineSound:Stop()
    end
end

function ENT:Draw()
    self:DrawModel()
    self:Effects(true)
end

local font = {
    font = "Default",
    size = ScreenScale(6),
    weight = 1000,
    antialias = true,
    additive = false
}

surface.CreateFont("DaedalusFont", font)

function DaedalusHUD()
    local ply = LocalPlayer()
    local self = ply:GetNetworkedEntity("ScriptedVehicle", NULL)
    local vehicle = ply:GetNWEntity("Daedalus")

    if (self and self:IsValid() and vehicle and vehicle:IsValid() and LocalPlayer().HUDEnable) then
        surface.SetTexture(MainHud_left)
        surface.SetDrawColor(255, 255, 255, 255)
        -- AGP: only the lower part (hull, power supply): the two "Hangar Bay" plates above them are left out, this
        -- Daedalus has no hangars (the texture keeps them for the walk-in Daedalus planned later)
        local cut = 0.595
        surface.DrawTexturedRectUV(0, ScrH() - 512 + 512 * cut, 256, 512 * (1 - cut), 0, cut, 1, 1)
        -- AGP: the right plates without the top "Hyperdrive" plate; that plate moves to the left, where the hangar bays
        -- were (texture pixels: hyperdrive plate x 260-507, y 178-315 of 512 x 1024; drawn at half size)
        local rcut = 0.315
        surface.SetTexture(MainHud_right)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRectUV(ScrW() - 256, ScrH() - 512 + 512 * rcut, 256, 512 * (1 - rcut), 0, rcut, 1, 1)
        local hx, hy, hw, hh = 10, ScrH() - 512 + 212, (507 - 260) / 2, (315 - 178) / 2
        surface.DrawTexturedRectUV(hx, hy, hw, hh, 260 / 512, 178 / 1024, 507 / 512, 315 / 1024)
        -- lamp on "Online" (ready) or "Offline" (charging, jumping, cooling down), like the shield lamp
        -- (no text outside the plate: while charging the Offline lamp blinks, faster the fuller it is)
        local ready = self:GetNWFloat("AGPHyperReady", 0) <= CurTime() and not self:GetNWBool("AGPHyperJump", false) and self:GetNWInt("AGPHyperCharge", 0) == 0
        local charge = self:GetNWInt("AGPHyperCharge", 0)
        if (charge > 0 and math.sin(CurTime() * (4 + charge / 8)) < 0) then surface.SetDrawColor(255, 255, 255, 60) end
        surface.SetTexture(OnOff)
        surface.DrawTexturedRect(ready and (hx + hw * 0.31) or (hx + hw * 0.72), hy + hh * 0.7, 8, 8)

        if (LocalPlayer().ViewMode > 0) then
            surface.SetTexture(WeaponsHud_middle)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(ScrW() / 2 - 256, 0, 512, 64)
            surface.SetTexture(WeaponsHud_left)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(0, 0, 256, 64)
            surface.SetTexture(WeaponsHud_right)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(ScrW() - 256, 0, 256, 64)
            local yy = 55
            surface.SetTexture(WepBar)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(20, yy, 8, 8)
            surface.DrawTexturedRect(70, yy, 8, 8)
            surface.DrawTexturedRect(100, yy, 8, 8)
            surface.DrawTexturedRect(150, yy, 8, 8)
            surface.DrawTexturedRect(180, yy, 8, 8)
            surface.DrawTexturedRect(220, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 + 70, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 + 60, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 + 50, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 + 40, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 + 30, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 + 20, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 - 20, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 - 30, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 - 40, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 - 50, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 - 60, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() / 2 - 70, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() - 20, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() - 70, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() - 100, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() - 150, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() - 180, yy, 8, 8)
            surface.DrawTexturedRect(ScrW() - 220, yy, 8, 8)
        end

        if (LocalPlayer().Hull < 20) then
            if (LocalPlayer().Warning == 0) then
                LocalPlayer().Warning = 1

                timer.Simple(0.5, function()
                    LocalPlayer().Warning = 2
                end)
            elseif (LocalPlayer().Warning == 2) then
                LocalPlayer().Warning = 1

                timer.Simple(0.5, function()
                    LocalPlayer().Warning = 0
                end)

                surface.SetTexture(BreachWarning)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect((ScrW() - 512) / 2, (ScrH() - 128) / 2, 512, 128)
            end
        end

        if (LocalPlayer().ShieldStatus == 1) then
            surface.SetTexture(OnOff)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(ScrW() - 70, ScrH() - 90, 8, 8)
        else
            surface.SetTexture(OnOff)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(ScrW() - 40, ScrH() - 90, 8, 8)
        end

        if (LocalPlayer().PowerSource == 1) then
            draw.DrawText("ZPM", "DaedalusFont", 120, ScrH() - 90, Color(255, 255, 255, 255), 1)
        else
            draw.DrawText(AGP.L("agp_ui_naquadah", "Naquadah"), "DaedalusFont", 120, ScrH() - 90, Color(255, 255, 255, 255), 1)
        end


        for i = 1, 10 do
            if (LocalPlayer().Sublight > (i * 10)) then
                surface.SetTexture(SubBar)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(ScrW() - 93, ScrH() - 150 - i * 12, 45, 7)
            end
        end

        if (LocalPlayer().Sublight == -10) then
            surface.SetTexture(SubBar)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(ScrW() - 93, ScrH() - 135, 45, 7)
        end

        for i = 1, 15 do
            if (LocalPlayer().Hull > (i * 6.5)) then
                surface.SetTexture(PHSBar)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(141 - i * 8, ScrH() - 158, 5, 20)
            end
        end

        for i = 1, 18 do
            if (LocalPlayer().Power > (i * 5.5)) then
                surface.SetTexture(PHSBar)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(15 + i * 8, ScrH() - 48, 5, 26)
            end

            if (LocalPlayer().Shield > (i * 5.5)) then
                surface.SetTexture(PHSBar)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(ScrW() - 195 + i * 9.25, ScrH() - 48, 6, 26)
            end
        end
    end
end

hook.Add("HUDPaint", "DaedalusHUD", DaedalusHUD)

function ENT:Effects()
    local size = {}
    -- Big Engines
    -- Medium Engines
    -- Small Engines
    -- Big Engines
    size[1] = 120
    size[2] = 120
    -- Medium Engines
    size[3] = 80
    size[4] = 80
    size[5] = 80
    size[6] = 80
    -- Small Engines
    size[7] = 40
    size[8] = 40
    size[9] = 40
    size[10] = 40

    local att = {"ELB", "ERB", "ELM1", "ELM2", "ERM1", "ERM2", "ELS1", "ELS2", "ERS1", "ERS2"}

    local roll = math.Rand(-90, 90)
    local normal = (self.Entity:GetForward() * -1):GetNormalized()
    local velocity = self.Entity:GetVelocity()
    local FWD = self.Entity:GetForward()

    for i = 1, 10 do
        local data = self:GetAttachment(self:LookupAttachment(att[i]))
        if not (data and data.Pos) then return end
        local velo = (data.Pos - self.AttLastPos[i]) * 75
        self.AttLastPos[i] = data.Pos
        -- if(StarGate.Visuals("cl_F302_sprites")) then
        local aftbrn = self.FXEmitter:Add("effects/fire_cloud1", data.Pos)
        aftbrn:SetVelocity(velo - 300 * FWD)
        aftbrn:SetDieTime(0.1)
        aftbrn:SetStartAlpha(255)
        aftbrn:SetEndAlpha(100)
        aftbrn:SetStartSize(size[i] / 2)
        aftbrn:SetEndSize(size[i])
        aftbrn:SetColor(math.Rand(220, 255), math.Rand(220, 255), 185)
        aftbrn:SetRoll(roll)
        local aftbrn2 = self.FXEmitter:Add("sprites/orangecore1", data.Pos)
        aftbrn2:SetVelocity(velo - 300 * FWD)
        aftbrn2:SetDieTime(0.1)
        aftbrn2:SetStartAlpha(255)
        aftbrn2:SetEndAlpha(100)
        aftbrn2:SetStartSize(size[i] / 2)
        aftbrn2:SetEndSize(size[i])
        aftbrn2:SetColor(math.Rand(220, 255), math.Rand(220, 255), 185)
        aftbrn2:SetRoll(roll)
        -- if(StarGate.Visuals("cl_F302_heatwave")) then
    end
end

function SGDaedalusCalcView(Player, Origin, Angles, FieldOfView)
    local view = {}
    local pos = Vector(0, 0, 0)
    local face = Angle(0, 0, 0)
    local self = LocalPlayer():GetNetworkedEntity("ScriptedVehicle", NULL)

    if (IsValid(self) and self:GetClass() == "sg_vehicle_daedalus") then
        if (LocalPlayer().ViewMode == 0) then
            pos = self:GetPos() + self:GetUp() * 600 + Player:GetAimVector():GetNormal() * -5000
            face = Player:GetAimVector():Angle() -- AGP: look where the guns aim (the crosshair is the screen centre), not at the hull
        elseif (LocalPlayer().ViewMode == 1) then
            pos = self:GetPos() - self:GetUp() * 500
            face = (Player:GetAimVector()):Angle()
        else
            pos = self:GetPos() + self:GetUp() * 1000
            face = (Player:GetAimVector()):Angle()
        end

        view.origin = pos
        view.angles = face

        return view
    end
end

hook.Add("CalcView", "SGDaedalusCalcView", SGDaedalusCalcView)
