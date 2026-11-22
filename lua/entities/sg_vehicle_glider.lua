--[[
	DeathGlider for GarrysMod 10
	Copyright (C) 2009 RononDex

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
--
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Author = "RononDex, Iziraider, Rafael De Jongh"
ENT.PrintName = "Death Glider"
ENT.Category = "Ships"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

if SERVER then
    --########Header########--
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
    AddCSLuaFile()
    -- model since 2026-10: Death Glider by Ska-Ara (Sketchfab, CC BY-NC-SA, see CREDITS.md)
    ENT.Model = Model("models/agp/hatak/props/ship_glider.mdl")

    ENT.Sounds = {
        Staff = Sound("pulse_weapon/staff_weapon.mp3")
    }

    -- AGP (our own): optional free flight (hover, strafe, climb/descend, reverse). Off by default: the classic glider
    -- flies forward only, like in the show.
    local agp_glider_free_flight = CreateConVar("agp_glider_free_flight", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "1 = Death Gliders can hover, strafe, climb and fly backwards (free flight); 0 = classic forward-only flight", 0, 1)

    --######## Pretty useless unless we can spawn it @RononDex
    function ENT:SpawnFunction(ply, tr)
        if (!tr.Hit) then return end
        local PropLimit = GetConVar("CAP_ships_max"):GetInt()
        local ang = ply:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y) % 360;
        if (ply:GetCount("CAP_ships") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")") -- fix: message text was unquoted (client Lua error)

            return
        end

        local e = ents.Create("sg_vehicle_glider")
        e:SetAngles(ang);
        e:SetPos(tr.HitPos + Vector(0, 0, 10))
        e:Spawn()
        e:Activate()
        ply:AddCount("CAP_ships", e)

        return e
    end

    --######## What happens when it first spawns(Set Model, Physics etc.) @RononDex
    function ENT:Initialize()
        self:SetModel(self.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:StartMotionController()
        self.Vehicle = "DeathGlider"
        self.EntHealth = 300
        self.MaxHealth = self.EntHealth
        self.BlastMaxVel = 10000000
        self.Blasts = {}
        self.BlastCount = 0
        self.MaxBlasts = (4)
        self.BlastsFired = 0
        self.Delay = 10
        --######### Flight Vars
        self.Accel = {}
        self.Accel.FWD = 0
        self.Accel.RIGHT = 0
        self.Accel.UP = 0
        self.ForwardSpeed = 2000
        self.BackwardSpeed = 0
        self.UpSpeed = 0
        self.MaxSpeed = 2750
        self.RightSpeed = 0
        self.Accel.SpeedForward = 20
        self.Accel.SpeedRight = 0
        self.Accel.SpeedUp = 0
        self.RollSpeed = 5
        self.num = 0
        self.num2 = 0
        self.num3 = 0
        self.Roll = 0
        self.Hover = false
        self.GoesRight = false
        self.GoesUp = false
        self.CanRoll = true
        self:ApplyFlightModel()
        self:CreateWireOutputs("Health")
        self:SetWire("Health", self.EntHealth)
        self:SetNWInt("health", self.EntHealth)   -- the pilot's HUD
        local phys = self:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(10000)
        end
    end

    -- AGP (our own values): the optional free flight (agp_glider_free_flight) of a light, quick fighter - faster
    -- forward than a cargo ship, quick to strafe and climb, slow in reverse; the fire delay stays CAP's
    function ENT:ApplyFlightModel()
        if (agp_glider_free_flight:GetBool()) then
            self.ForwardSpeed = 2200
            self.BackwardSpeed = -500
            self.UpSpeed = 850
            self.MaxSpeed = 2900
            self.RightSpeed = 900
            self.Accel.SpeedForward = 12
            self.Accel.SpeedRight = 9
            self.Accel.SpeedUp = 9
            self.Hover = true
            self.GoesRight = true
            self.GoesUp = true
        else
            self.ForwardSpeed = 2000
            self.BackwardSpeed = -600   -- AGP: S flies backwards slowly
            self.UpSpeed = 0
            self.MaxSpeed = 2750
            self.RightSpeed = 0
            self.Accel.SpeedForward = 20
            self.Accel.SpeedRight = 0
            self.Accel.SpeedUp = 0
            self.Hover = true   -- AGP: without W the glider holds its place in the air instead of dropping
            self.GoesRight = false
            self.GoesUp = false
            -- reset leftover strafe/lift so a glider switched back to classic mode does not keep drifting
            self.num2 = 0
            self.num3 = 0
        end
    end

    function ENT:Enter(p)
        -- pick up a changed agp_glider_free_flight setting when a pilot gets in
        if (not self.Inflight and self.Accel) then
            self:ApplyFlightModel()
        end
        self:SetNWBool("AGPFreeFlight", agp_glider_free_flight:GetBool())

        self.BaseClass.Enter(self, p)
    end

    --########## Gliders aren't invincible are they? @RononDex
    function ENT:OnTakeDamage(dmg)
        self.EntHealth = self.EntHealth - dmg:GetDamage()
        self:SetWire("Health", self.EntHealth)
        self:SetNWInt("health", math.max(0, self.EntHealth))

        if (self.EntHealth <= 0) then -- fix: the damage was subtracted twice here (exploded one hit early)
            self:Bang() -- Go boom
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
        self:SetNWInt("health", health)
    end

    function ENT:OnRemove()
        self.BaseClass.OnRemove(self)
    end

    function ENT:Think()
        self.BaseClass.Think(self)
        -- AGP: close to a narrow doorway (the Ha'tak's glider slots): fly level, wings flat, so the glider fits through
        local level = false
        if (IsValid(self.Pilot)) then
            for _, P in ipairs(ents.FindInSphere(self:GetPos(), 900)) do
                if (P:GetClass() == "agp_portal" and P:GetPortalHeight() < 260) then level = true break end
            end
        end
        self.ForceLevel = level

        if (self.StartDelay) then
            self.Delay = math.Approach(self.Delay, 10, 3)
        end

        if (self.Delay >= 10) then
            self.StartDelay = false
        end

        if (IsValid(self.Pilot)) then
            if ((self.Pilot:KeyDown(self.Vehicle, "FIRE"))) then
                if (self.Delay >= 10) then
                    self:FireBlast(self:GetRight() * -130)
                    self:FireBlast(self:GetRight() * 130)
                    self.Delay = 0
                end
                self:SetNWFloat("AGPGunReady", CurTime() + 0.4)

                self.StartDelay = true
            end
        end
    end

    function ENT:Exit(kill)
        self.BaseClass.Exit(self, kill)
        self.ExitPos = self:GetPos() + Vector(0, 0, 100)
    end

    function ENT:FireBlast(diff)
        local e = ents.Create("energy_pulse")

        e:PrepareBullet(self:GetForward(), 10, 16000, 6, {self.Entity})

        e:SetPos(self:GetPos() + diff + self:GetUp()*100)
        e:SetOwner(self)
        e.Owner = self
        e:Spawn()
        e:Activate()
        self:EmitSound(self.Sounds.Staff, 90, math.random(90, 110))
    end

    function ENT:ShowOutput()
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("sg_vehicle_glider", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    ENT.Sounds = {
        Engine = Sound("glider/deathglideridleoutside.wav")
    }

    if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
    --########## Keybinder stuff
    local KBD = StarGate.KeyBoard:New("DeathGlider")
    --Navigation
    KBD:SetDefaultKey("FWD", StarGate.KeyBoard.BINDS["+forward"] or "W") -- Forward
    KBD:SetDefaultKey("SPD", StarGate.KeyBoard.BINDS["+speed"] or "SHIFT")
    -- (only used when the server enables agp_glider_free_flight)
    KBD:SetDefaultKey("LEFT", StarGate.KeyBoard.BINDS["+moveleft"] or "A")
    KBD:SetDefaultKey("RIGHT", StarGate.KeyBoard.BINDS["+moveright"] or "D")
    KBD:SetDefaultKey("BACK", StarGate.KeyBoard.BINDS["+back"] or "S")
    KBD:SetDefaultKey("UP", StarGate.KeyBoard.BINDS["+jump"] or "SPACE")
    KBD:SetDefaultKey("DOWN", StarGate.KeyBoard.BINDS["+duck"] or "CTRL")
    --Roll
    KBD:SetDefaultKey("RL", "MWHEELDOWN") -- Roll left
    KBD:SetDefaultKey("RR", "MWHEELUP") -- Roll right
    KBD:SetDefaultKey("RROLL", "MOUSE3") -- Reset Roll
    --Attack
    KBD:SetDefaultKey("FIRE", StarGate.KeyBoard.BINDS["+attack"] or "MOUSE1") -- Fire blasts
    --Special Actions
    KBD:SetDefaultKey("RROLL", "MOUSE3") -- Reset roll
    KBD:SetDefaultKey("BOOM", "BACKSPACE")
    --View
    KBD:SetDefaultKey("Z+", "UPARROW")
    KBD:SetDefaultKey("Z-", "DOWNARROW")
    KBD:SetDefaultKey("A+", "LEFTARROW")
    KBD:SetDefaultKey("A-", "RIGHTARROW")
    KBD:SetDefaultKey("VIEW", "1")
    KBD:SetDefaultKey("EXIT", StarGate.KeyBoard.BINDS["+use"] or "E")

    function ENT:Initialize()
        self.Dist = -850
        self.UDist = 250
        self.FirstPerson = false
        self.lastswitch = CurTime()
        self.on1 = 0
        self.KBD = self.KBD or KBD:CreateInstance(self)
        self.BaseClass.Initialize(self)
        self.Vehicle = "DeathGlider"
    end

    --######## Mainly Keyboard stuff @RononDex
    function ENT:Think()
        self.BaseClass.Think(self)
        local p = LocalPlayer()
        local vehicle = p:GetNetworkedEntity("ScriptedVehicle", NULL)

        if ((vehicle) and ((vehicle) == self) and (vehicle:IsValid())) then
            self.KBD:SetActive(true)
            self:StartClientsideSound("Normal")
        else
            self.KBD:SetActive(false)
            self:StopClientsideSound("Normal")
        end

        if ((vehicle) and ((vehicle) == self) and (vehicle:IsValid())) then
            local v = p:KeyDown(self.Vehicle, "VIEW")   -- AGP: 1 = cockpit view on / off
            if (v and not self.ViewWas) then
                self.FirstPerson = not self.FirstPerson
                self.IsSGVehicleCustomView = self.FirstPerson
            end
            self.ViewWas = v
            if (p:KeyDown(self.Vehicle, "Z+")) then
                self.Dist = self.Dist - 5
            elseif (p:KeyDown(self.Vehicle, "Z-")) then
                self.Dist = self.Dist + 5
            end

            if (p:KeyDown(self.Vehicle, "A+")) then
                self.UDist = self.UDist + 5
            elseif (p:KeyDown(self.Vehicle, "A-")) then
                self.UDist = self.UDist - 5
            end
        end
    end
    -- AGP: cockpit view (key 1): from the canopy, looking where the pilot aims; the glider itself is not drawn for him
    hook.Add("CalcView", "AGP.GliderCockpit", function(ply, pos, ang, fov)
        local g = ply:GetNetworkedEntity("ScriptedVehicle", NULL)
        if (not IsValid(g) or g:GetClass() ~= "sg_vehicle_glider" or not g.FirstPerson) then return end
        local mn, mx = g:OBBMins(), g:OBBMaxs()
        local eye = g:LocalToWorld(Vector(mx.x * 0.25, 0, mn.z + (mx.z - mn.z) * 0.7))
        local turned = AGP_PortalTurnAim and AGP_PortalTurnAim()   -- (agp_portal: the aim turned by a doorway, this frame)
        local o, a = eye, turned and Angle(turned.p, turned.y, 0) or ply:GetAimVector():Angle()
        if (AGP_PortalCamera) then o, a = AGP_PortalCamera(g:WorldSpaceCenter(), o, a) end   -- (the canopy ahead through a launch slot first)
        return { origin = o, angles = a, fov = fov, drawviewer = false }
    end)
    function ENT:Draw()
        local g = LocalPlayer():GetNetworkedEntity("ScriptedVehicle", NULL)
        if (g == self and self.FirstPerson) then return end
        self:DrawModel()
    end

    -- AGP: the pilot's HUD in Goa'uld gold: hull, speed, guns, flight mode and the keys
    local function L(k, d) return AGP and AGP.L and AGP.L(k, d) or d end
    local GOLD, GOLD2, DARK = Color(235, 190, 90), Color(160, 120, 50), Color(25, 16, 6, 215)
    surface.CreateFont("AGPGliderBig", { font = "Trebuchet MS", size = 26, weight = 800 })
    surface.CreateFont("AGPGliderSmall", { font = "Trebuchet MS", size = 17, weight = 600 })
    hook.Add("HUDPaint", "AGP.GliderHUD", function()
        local g = LocalPlayer():GetNetworkedEntity("ScriptedVehicle", NULL)
        if (not IsValid(g) or g:GetClass() ~= "sg_vehicle_glider") then return end
        local w, h = 300, 150
        local x, y = 24, ScrH() - h - 24
        draw.RoundedBox(10, x, y, w, h, DARK)
        surface.SetDrawColor(GOLD2); surface.DrawOutlinedRect(x, y, w, h, 2)
        draw.SimpleText(L("agp_glider_hud", "DEATH GLIDER"), "AGPGliderBig", x + 14, y + 8, GOLD)
        local hp = math.Clamp(g:GetNWInt("health", 300) / 300, 0, 1)
        local col = hp < 0.3 and Color(235, 70, 50) or (hp < 0.6 and Color(240, 170, 60) or GOLD)
        draw.SimpleText(L("agp_glider_hull", "Hull"), "AGPGliderSmall", x + 14, y + 44, GOLD)
        surface.SetDrawColor(60, 40, 15, 255); surface.DrawRect(x + 80, y + 47, 200, 14)
        surface.SetDrawColor(col); surface.DrawRect(x + 80, y + 47, 200 * hp, 14)
        draw.SimpleText(math.ceil(hp * 100) .. " %", "AGPGliderSmall", x + 180, y + 45, color_black, TEXT_ALIGN_CENTER)
        local speed = AGP and AGP.Units and AGP.Units.Speed and AGP.Units.Speed(g:GetVelocity():Length()) or string.format("%d km/h", g:GetVelocity():Length() * 0.0254 * 3.6)
        draw.SimpleText(L("agp_glider_speed", "Speed") .. ": " .. speed, "AGPGliderSmall", x + 14, y + 68, GOLD)
        local firing = g:GetNWFloat("AGPGunReady", 0) > CurTime()
        draw.SimpleText(L("agp_glider_guns", "Staff cannons") .. ": " .. (firing and L("agp_glider_firing", "firing") or L("agp_glider_ready", "ready")), "AGPGliderSmall", x + 14, y + 90, firing and Color(255, 230, 140) or GOLD)
        local free = g:GetNWBool("AGPFreeFlight")
        draw.SimpleText(free and L("agp_glider_keysfree", "W/S fly  A/D side  Space/Ctrl up/down") or L("agp_glider_keys", "W fly  S back  Shift faster  no key = hover"), "AGPGliderSmall", x + 14, y + 112, GOLD2)
        draw.SimpleText(L("agp_glider_keys2", "Mouse1 fire  wheel roll  1 cockpit  E out"), "AGPGliderSmall", x + 14, y + 126, GOLD2)
    end)
end