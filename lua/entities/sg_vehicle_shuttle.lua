--[[
	Destiny Shuttle for GarrysMod 10
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
ENT.PrintName = "Destiny Shuttle"
ENT.Category = "Ships"
ENT.Author = "RononDex, Iziraider, Madman, Rafael De Jongh"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)


if SERVER then
    --########Header########--
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
    AddCSLuaFile()
    ENT.Model = Model("models/Iziraider/shuttle/shuttle.mdl")
    ENT.Shuttle = true

    --######## Pretty useless unless we can spawn it @RononDex
    function ENT:SpawnFunction(ply, tr)
        if (not tr.HitWorld) then return end
        local PropLimit = GetConVar("CAP_ships_max"):GetInt()

        if (ply:GetCount("CAP_ships") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")") -- fix: message text was unquoted (client Lua error)

            return
        end

        local e = ents.Create("sg_vehicle_shuttle")
        e:SetPos(tr.HitPos + Vector(0, 0, 90))
        e:Spawn()
        e:Activate()
        ply:AddCount("CAP_ships", e)
        e.Owner = ply

        return e
    end

    ENT.Sounds = {
        Engage = Sound("shields/shield_engage.mp3"),
        Disengage = Sound("shields/shield_disengage.mp3"),
        Fail = {Sound("buttons/button19.wav"), Sound("buttons/combine_button2.wav")},
        Railgunsound = Sound("pulse_weapon/dexgun_flyby1.mp3"),
        Explosion = Sound("jumper/JumperExplosion.mp3")
    }

    --######## What happens when it first spawns(Set Model, Physics etc.) @RononDex
    function ENT:Initialize()
        self:SetModel(self.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:StartMotionController()
        self:SpawnChairs()
        self:SpawnShieldGen()
        self:CreateWireInputs("Shield")
        self:CreateWireOutputs("Health", "Shield Strength", "Shield Enabled")
        self.IsShuttle = true
        self.Vehicle = "Shuttle"
        self.BlastCount = 0
        self.CanFire = true
        --######### Flight Vars
        self.Accel = {}
        self.Accel.FWD = 0
        self.Accel.RIGHT = 0
        self.Accel.UP = 0
        self.ForwardSpeed = 1250
        self.BackwardSpeed = -600
        self.UpSpeed = 500
        self.MaxSpeed = 1750
        self.RightSpeed = 750
        self.Accel.SpeedForward = 20
        self.Accel.SpeedRight = 8
        self.Accel.SpeedUp = 8
        self.num = 0
        self.num2 = 0
        self.num3 = 0
        self.Roll = 0
        self.Hover = true
        self.GoesRight = true
        self.GoesUp = true
        self.CanRoll = true
        self.EntHealth = 2000
        self.MaxHealth = self.EntHealth
        self:SetNWInt("maxhealth", self.MaxHealth)
        self:SetNWInt("health", self.EntHealth)
        self:SetWire("Health", self.EntHealth)
        local phys = self:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(10000)
        end
    end

    function ENT:OnRemove()
        self.BaseClass.OnRemove(self)
    end

    --########## Shuttle's aren't invincible are they? @RononDex
    function ENT:OnTakeDamage(dmg)
        -- our own: raised shields protect the hull (the old shield check did nothing)
        local shielded = IsValid(self.Shields) and self.Shields:Enabled() and not self.Shields.Depleted

        if (not shielded) then
            self.EntHealth = self.EntHealth - dmg:GetDamage() / 10
            self:SetWire("Health", self.EntHealth)
            self:SetNWInt("health", self.EntHealth)
        end

        if (self.EntHealth <= 250) then
            self.TurretDisabled = true
        end

        if (self.EntHealth <= 150) then
            self.ShieldOffline = true
        end

        if (self.EntHealth <= 0) then
            self:DoKill() -- Go boom
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
        self:SetNWInt("health", self.EntHealth) -- fix: was self.health (nil)
    end

    --######### @ RononDex
    function ENT:DoKill(ply)
        self.Done = true
        local velocity = self:GetForward()
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetStart(self:GetUp())
        util.Effect("dirtyxplo", effectdata)
        self:EmitSound(self.Sounds.Explosion, 100, 100)
        local e = ents.Create("info_particle_system")
        e:SetPos(self:GetPos())
        e:SetAngles(self:GetAngles())
        e:SetKeyValue("effect_name", "citadel_shockwave_06") -- http://developer.valvesoftware.com/wiki/Half-Life_2:_Episode_Two_Particle_Effect_List
        e:SetKeyValue("start_active", 1)
        e:Spawn()
        e:Activate()
        e:Fire("Stop", "", 0.9)
        e:Fire("kill", "", 3)

        if (IsValid(self)) then
            self:ExitShut()

            if (IsValid(self.Pilot)) then
                self.Pilot:Kill()
            end
        end

        self:Remove()
    end

    --################# Get out the jumper@RononDex
    function ENT:ExitShut()
        if (not IsValid(self.Pilot)) then return end
        self.Pilot:UnSpectate()
        self.Pilot:DrawViewModel(true)
        self.Pilot:DrawWorldModel(true)
        if (AGP and AGP.ShipRespawnPilot) then AGP.ShipRespawnPilot(self.Pilot) else self.Pilot:Spawn() end -- AGP: keeps armour and ammo, no Ha'tak bunk move (agp_ship_shield.lua)
        local want = self:GetPos() + self:GetForward() * 15 + self:GetUp() * -40
        self.Pilot:SetPos(AGP and AGP.ShipExitSpot and AGP.ShipExitSpot(self, self.Pilot, want) or want) -- AGP: a free spot
        self.Pilot:SetMoveType(MOVETYPE_WALK)
        self.Pilot:SetNetworkedEntity("ScriptedVehicle", NULL)
        self.Pilot:SetViewEntity(NULL)
    end

    function ENT:Think()
        self.BaseClass.Think(self)

        if (IsValid(self.Pilot)) then
            self:SetNWInt("shield", math.Round(self.Shields.Strength))
        end
        if (AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end -- AGP: shield up / depleted / strength for the HUD

        if (self.Inflight) then
            if ((self.Pilot) and (self.Pilot:IsValid())) then
                -- AGP: one press = one toggle (it toggled every tick while the key was held and spammed the chat)
                if (AGP.KeyPress(self, self.Pilot, "Shuttle", "SHIELD")) then -- AGP: a quick tap counts too
                    if (self.ShieldOffline) then
                        AGP.Say(self.Pilot, "agp_shuttle_shields_down", "The shuttle is too badly damaged! Shields are offline.")
                    end

                    if (self.Shields.Depleted) then
                        AGP.Say(self.Pilot, "agp_shuttle_shields_empty", "Shields depleted - wait for them to recharge.")
                    else
                        if (not (self.ShieldOffline)) then
                            self:ToggleShield()
                        end
                    end
                end
            end
        end

        self.ExitPos = self:GetPos() + self:GetForward() * 100

        if (self.Shields.Depleted) then
            self:SetWire("Shield Enabled", -1)
            self:SetWire("Shield Strength", self.Shields.Strength)
        else
            self:SetWire("Shield Enabled", self.Shields:Enabled())
            self:SetWire("Shield Strength", self.Shields.Strength)
        end

        -- AGP: the guns cool down by themselves after a burst (before only while FIRE was held, with nothing coming
        -- out); and no errors when the pilot is gone
        if (not (self.Inflight and IsValid(self.Pilot) and self.Pilot:KeyDown(self.Vehicle, "FIRE"))) then
            self.BlastCount = math.Approach(self.BlastCount or 0, 0, 1)
            if (self.BlastCount == 0) then self.CanFire = true end
        end

        if (self.Inflight and IsValid(self.Pilot)) then
            if ((self.TurretDisabled) and (self.Pilot:KeyDown(self.Vehicle, "FIRE"))) then
                AGP.Say(self.Pilot, "agp_shuttle_turrets_down", "Too much damage taken! Turrets are offline.")
            end

            if ((self.Pilot:KeyDown(self.Vehicle, "FIRE")) and (not (self.TurretDisabled))) then
                self:FireBlast(self:GetRight() * -525)
                self:FireBlast(self:GetRight() * 525)
            end
        end
    end

    --####### Fire! @Mad
    function ENT:FireBlast(diff)
        if self.BlastCount < 10 and self.CanFire then
            local e = ents.Create("energy_pulse")

            e:PrepareBullet(self:GetForward(), 10, 16000, 6, {self.Entity})

            e:SetPos(self:GetPos() + diff)
            e:SetOwner(self)
            e.Owner = self
            e:Spawn()
            e:Activate()
            e:SetColor(Color(255, 255, math.random(75, 125), 255))
            self:EmitSound(self.Sounds.Railgunsound, 100, 100)
            self.BlastCount = self.BlastCount + 1
        else
            self.BlastCount = math.Approach(self.BlastCount, 0, 0.5)
            self.CanFire = false
        end

        if self.BlastCount == 0 then
            self.CanFire = true
        end
    end

    function ENT:SpawnChairs()
    end

    function ENT:SpawnShieldGen()
        if (IsValid(self)) then
            local e = ents.Create("ship_shield_generator")
            e:SetPos(self:GetPos())
            e:SetAngles(self:GetAngles() - Angle(0, 90, 0))
            e:SetParent(self)
            e:Spawn()
            e:Activate()
            self.Shields = e
            self.AGPShieldGen = e -- AGP: lets AGP.ShipShieldThink network the shield state (HUD)

            e.StrengthMultiplier = {0.1, 0.5, -5}

            e:SetShieldColor(1, 0.6, 0)
        end
    end

    function ENT:ToggleShield()
        if (IsValid(self) and IsValid(self.Shields)) then
            self.Shields:Status(not self.Shielded)
            self.Shielded = self.Shields:Enabled() and true or false -- AGP: follows the real state (a failed start stays off)
        end
    end

    function ENT:ShowOutput()
    end

    --######### Wire Inputs @ RononDex
    function ENT:TriggerInput(k, v)
        -- AGP: 1 = shield up, 0 = down (it toggled on every 1 and never updated self.Shielded)
        if (k == "Shield" and ((v or 0) >= 1) ~= (self.Shielded == true) and not self.ShieldOffline) then
            self:ToggleShield()
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("sg_vehicle_shuttle", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    ENT.RenderGroup = RENDERGROUP_BOTH
    if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
    --########## Keybinder stuff
    local KBD = StarGate.KeyBoard:New("Shuttle")
    --Navigation
    KBD:SetDefaultKey("FWD", StarGate.KeyBoard.BINDS["+forward"] or "W") -- Forward
    KBD:SetDefaultKey("SPD", StarGate.KeyBoard.BINDS["+speed"] or "SHIFT") --  Boost
    KBD:SetDefaultKey("UP", StarGate.KeyBoard.BINDS["+jump"] or "SPACE")
    KBD:SetDefaultKey("DOWN", StarGate.KeyBoard.BINDS["+duck"] or "CTRL")
    KBD:SetDefaultKey("LEFT", StarGate.KeyBoard.BINDS["+moveleft"] or "A")
    KBD:SetDefaultKey("RIGHT", StarGate.KeyBoard.BINDS["+moveright"] or "D")
    KBD:SetDefaultKey("BACK", StarGate.KeyBoard.BINDS["+back"] or "S") -- AGP: the shuttle can fly backwards and roll (code had it, no keys)
    KBD:SetDefaultKey("RL", "MWHEELDOWN") -- Roll left
    KBD:SetDefaultKey("RR", "MWHEELUP") -- Roll right
    KBD:SetDefaultKey("RROLL", "MOUSE3") -- Reset roll
    --Attack
    KBD:SetDefaultKey("FIRE", StarGate.KeyBoard.BINDS["+attack"] or "MOUSE1")
    --View
    KBD:SetDefaultKey("Z+", "UPARROW")
    KBD:SetDefaultKey("Z-", "DOWNARROW")
    KBD:SetDefaultKey("A+", "LEFTARROW")
    KBD:SetDefaultKey("A-", "RIGHTARROW")
    --Special Actions
    KBD:SetDefaultKey("SHIELD", "G") -- AGP: G like the other ships (ALT is free look now)
    KBD:SetDefaultKey("BOOM", "BACKSPACE")
    KBD:SetDefaultKey("EXIT", StarGate.KeyBoard.BINDS["+use"] or "E")

    ENT.Sounds = {
        Engine = Sound("f302/f302_Engine.wav")
    }

    function ENT:Initialize()
        self.BaseClass.Initialize(self)
        self.Dist = -1150
        self.UDist = 400
        self.KBD = self.KBD or KBD:CreateInstance(self)
        self.Vehicle = "Shuttle"
    end

    function ENT:Effects()
        local pos = {}
        pos[1] = self:GetPos() + self:GetForward() * -390 + self:GetUp() * 40 + self:GetRight() * 270
        pos[2] = self:GetPos() + self:GetForward() * -390 + self:GetUp() * 67.5 + self:GetRight() * 190
        pos[3] = self:GetPos() + self:GetForward() * -390 + self:GetUp() * 40 + self:GetRight() * -270
        pos[4] = self:GetPos() + self:GetForward() * -390 + self:GetUp() * 67.5 + self:GetRight() * -190
        local p = LocalPlayer()
        local Shuttle = p:GetNetworkedEntity("ScriptedVehicle", NULL)
        local roll = math.Rand(-90, 90)
        local normal = (self.Entity:GetForward() * -1):GetNormalized()

        if ((Shuttle) and (Shuttle:IsValid() and (Shuttle == self))) then
            for i = 1, 4 do
                if ((p:KeyDown("Shuttle", "FWD"))) then
                    if (StarGate.VisualsShips("cl_shuttle_heatwave")) then
                        local fx = self.FXEmitter:Add("sprites/heatwave", pos[i])
                        fx:SetVelocity(normal * 2)
                        fx:SetDieTime(0.2)
                        fx:SetStartAlpha(255)
                        fx:SetEndAlpha(255)
                        fx:SetStartSize(90)
                        fx:SetEndSize(50)
                        fx:SetColor(255, 255, 255)
                        fx:SetRoll(roll)
                    end

                    if (StarGate.VisualsShips("cl_shuttle_sprites")) then
                        local fx2 = self.FXEmitter:Add("sprites/orangecore1", pos[i])
                        fx2:SetVelocity(normal * 2)
                        fx2:SetDieTime(0.02)
                        fx2:SetStartAlpha(255)
                        fx2:SetEndAlpha(255)
                        fx2:SetStartSize(60)
                        fx2:SetEndSize(35)
                        fx2:SetColor(math.Rand(200, 255), math.Rand(200, 255), 165)
                        fx2:SetRoll(roll)
                    end
                end
            end
        end
    end

    function ENT:BoostFX()
        local pos = {}
        pos[1] = self:GetPos() + self:GetRight() * 365 + self:GetForward() * -390 + self:GetUp() * 20
        pos[2] = self:GetPos() + self:GetRight() * -365 + self:GetForward() * -390 + self:GetUp() * 20
        pos[3] = self:GetPos() + self:GetRight() * 430 + self:GetForward() * -390
        pos[4] = self:GetPos() + self:GetRight() * -430 + self:GetForward() * -390
        local normal = (self.Entity:GetForward() * -1):GetNormalized()
        local roll = math.Rand(-90, 90)
        local p = LocalPlayer()
        local Shuttle = p:GetNetworkedEntity("ScriptedVehicle", NULL)

        if ((p:KeyDown("Shuttle", "SPD")) and (p:KeyDown("Shuttle", "FWD")) and ((Shuttle) and (Shuttle:IsValid()) and (Shuttle == self))) then
            local vel = Shuttle:GetVelocity()

            for i = 1, 4 do
                if (StarGate.VisualsShips("cl_shuttle_sprites")) then
                    local aftbrn = self.FXEmitter:Add("sprites/orangecore1", pos[i])
                    aftbrn:SetVelocity(normal * 2)
                    aftbrn:SetDieTime(0.05)
                    aftbrn:SetStartAlpha(255)
                    aftbrn:SetEndAlpha(100)
                    aftbrn:SetStartSize(40)
                    aftbrn:SetEndSize(13.5)
                    aftbrn:SetColor(math.Rand(220, 255), math.Rand(220, 255), 155)
                    aftbrn:SetRoll(roll)
                end

                if (StarGate.VisualsShips("cl_shuttle_heatwave")) then
                    local heatwv = self.FXEmitter:Add("sprites/heatwave", pos[i])
                    heatwv:SetVelocity(normal * 2)
                    heatwv:SetDieTime(0.2)
                    heatwv:SetStartAlpha(255)
                    heatwv:SetEndAlpha(255)
                    heatwv:SetStartSize(50)
                    heatwv:SetEndSize(18)
                    heatwv:SetColor(255, 255, 255)
                    heatwv:SetRoll(roll)
                end
            end
        end
    end

    function ENT:Draw()
        local p = LocalPlayer()
        self.BaseClass.Draw(self)

        if (p:KeyDown("Shuttle", "FWD")) then
            self:Effects()
        end

        if (p:KeyDown("Shuttle", "SPD")) then
            self:BoostFX()
        end
    end

    --######## Mainly Keyboard stuff @RononDex
    function ENT:Think()
        self.BaseClass.Think(self)
        local p = LocalPlayer()
        local Shuttle = p:GetNetworkedEntity("ScriptedVehicle", NULL)

        if ((Shuttle) and ((Shuttle) == self) and (Shuttle:IsValid())) then
            self.KBD:SetActive(true)
        else
            self.KBD:SetActive(false)
        end

        if ((Shuttle) and ((Shuttle) == self) and (Shuttle:IsValid())) then
            if (p:KeyDown("Shuttle", "Z+")) then
                self.Dist = self.Dist - 5
            elseif (p:KeyDown("Shuttle", "Z-")) then
                self.Dist = self.Dist + 5
            end

            if (p:KeyDown("Shuttle", "A+")) then
                self.UDist = self.UDist + 5
            elseif (p:KeyDown("Shuttle", "A-")) then
                self.UDist = self.UDist - 5
            end
        end
    end

    -- AGP: the "ShuttleData" usermessage was never sent (and LocalPlayer().Shield never read); the HUD reads the
    -- networked values "shield" and AGPShieldOn / AGPShieldDepleted (set in the server Think) instead.

    --########### All HUD Related stuff is below @ RononDex
    local hudpos = {
        healthw = (ScrW() / 10 * 1.5),
        healthh = (ScrH() / 10 * 2),
        shieldw = (ScrW() / 10 * 1.5),
        shieldh = (ScrH() / 10 * 3)
    }

    function PrintHUD()
        local p = LocalPlayer()
        local self = p:GetNetworkedEntity("ScriptedVehicle", NULL)
        local shuttle = p:GetNetworkedEntity("Shuttle")

        if (IsValid(self)) then
            if ((IsValid(shuttle)) and (shuttle == self)) then
                local healthpercent = math.Round(self:GetNWInt("health") / self:GetNWInt("maxhealth") * 100) -- test fix
                draw.WordBox(8, hudpos.healthw, hudpos.healthh, AGP.L("agp_ui_hull", "Hull:") .. " " .. healthpercent .. "%", "ScoreboardText", Color(50, 50, 75, 100), Color(255, 255, 255, 255))
                if (AGP.ShipShieldText) then -- AGP: shows whether the shield is up, not only its strength
                    local text, col = AGP.ShipShieldText(self)
                    draw.WordBox(8, hudpos.shieldw, hudpos.shieldh, text, "ScoreboardText", Color(50, 50, 75, 100), col)
                else
                    draw.WordBox(8, hudpos.shieldw, hudpos.shieldh, AGP.L("agp_ui_shield_933", "Shield:") .. " " .. self:GetNWInt("shield", 100) .. "%", "ScoreboardText", Color(50, 50, 75, 100), Color(255, 255, 255, 255))
                end
            end
        end
    end

    hook.Add("HUDPaint", "ShuttleHUD", PrintHUD)
end