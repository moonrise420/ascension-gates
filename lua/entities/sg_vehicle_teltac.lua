--[[
	Tel'Tak for GarrysMod 10
	Copyright (C) 2011 Madman07, RononDex

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
ENT.PrintName = "Tel'tak"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("entity_teltak") end -- AGP: was "TelTak", search for Tel'tak found nothing
ENT.Author = "RononDex, Madman07, James, Rafael De Jongh"
ENT.Category = "Ships"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.AutomaticFrameAdvance = true
ENT.IsSGVehicleCustomView = true

if SERVER then
    --########Header########--
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
    AddCSLuaFile()
    ENT.Model = Model("models/James/teltac/teltac.mdl")

    -- AGP: the shared ship shield (lua/autorun/agp_ship_shield.lua), a bubble fitted to the hull (hull about
    -- x -530..650, y +-450, z -100..300). Before it was CAP's generator with the default 200-unit bubble: it sat inside
    -- the hull and was never seen, and the hull took every hit as if no shield was up.
    ENT.AGPCabinExit = true -- AGP: hollow: the pilot gets out in the cockpit (AGP.ShipExitSpot)
    ENT.AGPShield = { model = "models/iziraider/shields/3x4x3.mdl", yaw = 0, offset = Vector(60, 0, 194), color = { 1, 0.85, 0.5 }, scale = Vector(0.87, 0.73, 0.58) }   -- fitted round every point of the hull (balance, the
    -- series' order: Ori > O'Neill > Aurora > Daedalus > Destiny > Prometheus > Al'kesh > Tel'tak) the shield holds 7000
    -- damage (a beam: 7 s)
    ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 7000, 7
    ENT.AGPHullInEntHealth = true -- the hull is self.EntHealth (sg_vehicle_base ENT:AGPHullDamage)

    ENT.Sounds = {
        Cloak = Sound("jumper/puddlejumpercloak2.wav"),
        Uncloak = Sound("jumper/JumperUnCloak.mp3"),
        Open = Sound("teltak/teltak_outterdoor_open.wav"),
        Close = Sound("teltak/teltak_outterdoor_close.wav"),
        OpenC = Sound("teltak/teltak_centerdoor_open.wav"),
        CloseC = Sound("teltak/teltak_centerdoor_close.wav")
    }

    ENT.Gibs = true

    ENT.GibTable = {
        Chair = Model("models/James/teltac/gib_chair.mdl"),
        Engine = Model("models/James/teltac/gib_engine.mdl"),
        Panel1 = Model("models/James/teltac/gib_panel1.mdl"),
        Panel2 = Model("models/James/teltac/gib_panel2.mdl"),
        Wing1 = Model("models/James/teltac/gib_wing1.mdl"),
        Wing2 = Model("models/James/teltac/gib_wing2.mdl")
    }

    local COCKPIT_POS = Vector(365.02545166016, 1.2539007663727, 74.670593261719)
    local DOOR_POS = Vector(158.8932, 5.9064, 47.4537)
    local DOORE_POS = Vector(-162.5597, 5.3606, 47.9206)
    local COCKPIT_EXIT = Vector(345, 0, 60) -- AGP: where the pilot gets out (behind the pilot's place, above the floor)

    --######## Pretty useless unless we can spawn it @RononDex
    function ENT:SpawnFunction(pl, tr)
        if (not tr.HitWorld) then return end
        local PropLimit = GetConVar("CAP_ships_max"):GetInt()

        if (pl:GetCount("CAP_ships") + 1 > PropLimit) then
            pl:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")") -- fix: message text was unquoted (client Lua error)

            return
        end

        local e = ents.Create("sg_vehicle_teltac")
        e:SetPos(tr.HitPos + Vector(0, 0, 180))
        e:Spawn()
        e:Activate()
        e:SetVar("Owner", pl)
        e:SpawnRings(pl)
        e:SpawnRingPanel(pl)
        e:SpawnDoor(pl)
        e:SpawnButtons(pl)

        pl:Give("weapon_ringcaller")
        pl:AddCount("CAP_ships", e)
        e.Owner = pl

        return e
    end

    --######## What happens when it first spawns(Set Model, Physics etc.) @RononDex
    function ENT:Initialize()
        self.BaseClass.Initialize(self)
        self.Vehicle = "Teltak"
        self.BlastMaxVel = 10000000
        self.Blasts = {}
        self.BlastCount = 0
        self.MaxBlasts = (4)
        self.BlastsFired = 0
        self.ExitPos = self:GetPos() + Vector(0, 0, 120)
        self.ShouldRotorwash = true
        self:CreateWireInputs("Hyperspace [VECTOR]", "Cloak", "Hyperspace X", "Hyperspace Y", "Hyperspace Z") -- from CAP: X/Y/Z inputs (old dupes)
        self.CanUse = false
        --######### Flight Vars
        self.Accel = {}
        self.Accel.FWD = 0
        self.Accel.RIGHT = 0
        self.Accel.UP = 0
        self.ForwardSpeed = 1000
        self.BackwardSpeed = -1000
        self.UpSpeed = 750
        self.MaxSpeed = 1750
        self.RightSpeed = 750
        self.Accel.SpeedForward = 20
        self.Accel.SpeedRight = 10
        self.Accel.SpeedUp = 10
        self.RollSpeed = 0
        self.num = 0
        self.num2 = 0
        self.num3 = 0
        self.Roll = 0
        self.Hover = true
        self.GoesRight = true
        self.GoesUp = true
        self.CanRoll = true -- AGP: the roll keys (mouse wheel, Mouse3) did nothing
        self.CanDoAnim = true
        self.CanCloak = true
        self.CanDoCloak = true
        self.ImmuneOwner = true
        self.RingBusy = false
        self.HoverPos = self:GetPos()
        self.HoverAlways = true -- let me hover always :)
        self.EntHealth = 9000   -- (balance: a cargo ship; it had 20000)
        self.MaxHealth = self.EntHealth
        self:CreateWireOutputs("Health")
        self:SetNWInt("maxhealth", self.MaxHealth)
        self:SetNWInt("health", self.EntHealth)
        self:SetWire("Health", self.EntHealth)
        local phys = self:GetPhysicsObject()
        self.HyperspaceVector = Vector(0,0,0)

        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(20000)
        end

        self.Open = false
        self.HyperspaceDist = 0
        self.MaxCharge = StarGate.CFG:Get("teltak", "jump_distance", 15000) --Max Jump Distance
        self.CanJump = true
        self.CanFire = true
        self.CooledDown = true --Beam Cooldown
        self.WeaponAllowed = StarGate.CFG:Get("teltak", "allow_beam_weapon", true)
    end

    function ENT:Bang()
        self.BaseClass.Bang(self)
        local velocity = self:GetVelocity()

        for _, v in pairs(self.GibTable) do
            local k = ents.Create("prop_physics")
            k:SetPos(self:GetPos())
            k:SetAngles(self:GetAngles())
            k:SetModel(v)
            k:PhysicsInit(SOLID_VPHYSICS)
            k:SetMoveType(MOVETYPE_VPHYSICS)
            k:SetSolid(SOLID_VPHYSICS)
            k:Activate()
            k:Spawn()
            k:Ignite(10, 10)
            k:GetPhysicsObject():SetVelocity(velocity * 1000 + VectorRand() * 40000)
            k:GetPhysicsObject():ApplyForceCenter(velocity * 1000 + VectorRand() * 40000)
            k:Fire("Kill", "", 10)
        end
    end

    --########## Gliders aren't invincible are they? @RononDex
    function ENT:OnTakeDamage(dmg)
        -- AGP: shield first, then the hull (small beam hits add up), destroyed at 0: sg_vehicle_base ENT:AGPHullDamage
        if (self:AGPHullDamage(dmg) <= 0 or self.AGPDestroyed) then return end

        -- fix: the damage was subtracted a second time in these checks, so the Tel'tak lost systems and exploded too early
        if (self.EntHealth <= 1500) then
            self.CanFire = false
        end

        if (self.EntHealth <= 1000) then
            self.CanCloak = false
        end

        if (self.EntHealth <= 500) then
            self.CanJump = false
        end

    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
        self:SetNWInt("health", self.EntHealth)
    end

    function ENT:OnRemove()
        if (AGP and AGP.ShipShieldRemove) then AGP.ShipShieldRemove(self) end
        if IsValid(self.RingPanel) then
            self.RingPanel:Remove()
        end

        if IsValid(self.InRing) then
            self.InRing:Remove()
        end

        if IsValid(self.OutRing) then
            if (self.OutRing.Laser) then
                self.OutRing:StopLaser()
            end

            self.OutRing:Remove()
        end

        if (IsValid(self.Door)) then
            self.Door:Remove()
        end

        if (IsValid(self.Door2)) then
            self.Door2:Remove()
        end

        if (IsValid(self.Door3)) then
            self.Door3:Remove()
        end

        self.BaseClass.OnRemove(self)
    end

    function ENT:Think()
        self.BaseClass.Think(self)

        if self.HasRD then
            self:LSSupport()
        end
        if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end -- AGP: shield state for the HUD

        if (IsValid(self.InRing and self.OutRing)) then
            if (self.Inflight and not self.LandingMode) then
                self.InRing.Busy = true
                self.OutRing.Busy = true
                self.RingBusy = true
            elseif (((self.LandingMode and self.Inflight) or not self.Inflight) and self.RingBusy) then
                self.InRing.Busy = false
                self.OutRing.Busy = false
                self.RingBusy = false
            end
        end

        -- AGP: landing mode holds still in PhysicsSimulate below (zeroing the speed here, 5 times a second, while the flight
        -- code sped up again every tick made it creep in jerks when W was held)

        if (self.Inflight) then
            if (IsValid(self.Pilot)) then
                if (AGP.KeyPress(self, self.Pilot, self.Vehicle, "CLOAK")) then
                    self:ToggleCloak()
                elseif (AGP.KeyPress(self, self.Pilot, self.Vehicle, "DOOR")) then
                    self:ToggleDoors("out")
                end

                if (self.CanJump) then
                    if (self.Pilot:KeyDown(self.Vehicle, "HYPERSPACE") and not (IsValid(self.OutRing) and self.OutRing.Laser)) then -- AGP: no error without the ring
                        if (self.HyperspaceDist < self.MaxCharge) then
                            self.HyperspaceDist = self.HyperspaceDist + (250 + math.Round(self.EntHealth / self.MaxHealth * 100))
                        end

                        self.Charging = true
                    else
                        self.Charging = false

                        if (self.HyperspaceDist < (self.MaxCharge / 4)) then
                            self.HyperspaceDist = 0
                        end
                    end
                end

                self.Pilot:SetNWBool("Charging", self.Charging)

                if (not self.Charging and self.HyperspaceDist > (self.MaxCharge / 4)) then
                    self:HyperSpace()
                    self.HyperspaceDist = 0
                end

                self.Pilot:SetNWInt("Charge", self.HyperspaceDist)

                -- AGP: G = shield, one toggle per press (hook AGP.ShipShieldKeys in lua/autorun/agp_ship_shield.lua). No staff
                -- cannons: in the series the Tel'tak is an unarmed cargo ship.

                if (not IsValid(self.OutRing)) then return end -- AGP: the ring parts are not there yet
                if (not self.LandingMode and self.OutRing.Laser) then
                    self.OutRing:StopLaser()
                end

                if (self.WeaponAllowed) then
                    if (self.Pilot:KeyDown(self.Vehicle, "FIRE")) then
                        if (not self.Cloaked and self.CanFire and self.CooledDown and self.LandingMode) then
                            if (not self.OutRing.Laser) then
                                self.OutRing:StartLaser()
                                self.OutRing.Busy = true

                                timer.Simple(30, function()
                                    if (IsValid(self)) then
                                        self.CooledDown = false

                                        if (IsValid(self.OutRing)) then
                                            self.OutRing.Busy = false
                                            self.OutRing:StopLaser()
                                        end

                                        if (IsValid(self.Pilot)) then
                                            self.BeamTimer = "BeamCooldown" .. self.Pilot:SteamID()
                                        else
                                            self.BeamTimer = "BeamCooldown" .. self:EntIndex()
                                        end

                                        timer.Create(self.BeamTimer, 60, 1, function()
                                            if (IsValid(self)) then
                                                self.CooledDown = true
                                            end
                                        end)
                                    end
                                end)
                            end
                        end
                    end

                    if (not self.CooledDown) then
                        self.Pilot:SetNWInt("BeamCooldown", timer.TimeLeft(self.BeamTimer))
                    end
                end
            end
        end
    end

    -- AGP: the shield (G, or E on the bubble): the shared ship shield, see ENT.AGPShield above
    function ENT:ToggleShield()
        if (AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self) end
    end

    function ENT:Enter(p)
        self.BaseClass.Enter(self, p)
        if (IsValid(self.Pilot)) then self.Pilot:SetNWInt("MaxCharge", self.MaxCharge) end -- AGP: not entered (not ready yet) = no pilot
    end

    function ENT:Exit(kill)
        -- AGP: out in the cockpit, standing on its floor. The old spot (x -40, z 40) was in the rear bulkhead door and
        -- under the floor (about z 47), and its free-spot test ignored the ship itself, so the floor never counted.
        local spot = AGP and AGP.PlayerStandSpot and AGP.PlayerStandSpot(self:LocalToWorld(COCKPIT_EXIT), self.Pilot, nil, 40, 80)
        self.ExitPos = spot or self:LocalToWorld(COCKPIT_EXIT + Vector(0, 0, 30))
        self.CanUse = false
        self.Pilot:SetNWInt("BeamCooldown", 0)
        self.HyperspaceDist = 0
        self.Charging = false
        self.PreviousPilot = self.Pilot:SteamID()
        self.BaseClass.Exit(self, kill)
    end

    ENT.Buttons = {}

    function ENT:SpawnButtons(p)
        local e = {}

        for i = 1, 5 do
            e[i] = ents.Create("teltak_button")
            e[i]:Spawn()
            e[i]:Activate()
            e[i]:SetParent(self)
            e[i]:SetRenderMode(RENDERMODE_TRANSALPHA)
            e[i].Parent = self
            e[i].TelTakPart = true
            self.Buttons[i] = e[i]

            if (i == 1) then
                e[i].RearDoor = false
                e[i].Bulkhead = true
                e[i]:SetPos(self:GetPos() - self:GetForward() * -178 + self:GetRight() * -35 + self:GetUp() * 105)
                e[i]:SetAngles(self:GetAngles() + Angle(0, 90, 84))
            elseif (i == 2) then
                e[i].RearDoor = false
                e[i].Bulkhead = true
                e[i]:SetPos(self:GetPos() - self:GetForward() * -136 + self:GetRight() * 35 + self:GetUp() * 105)
                e[i]:SetAngles(self:GetAngles() + Angle(0, 90, 90))
            elseif (i == 3) then
                e[i].RearDoor = true
                e[i].Bulkhead = false
                e[i]:SetPos(self:GetPos() - self:GetForward() * 142 + self:GetRight() * -30 + self:GetUp() * 105)
                e[i]:SetAngles(self:GetAngles() + Angle(0, 90, 90))
            elseif (i == 4) then
                e[i].RearDoor = true
                e[i].Bulkhead = false
                e[i]:SetPos(self:GetPos() - self:GetForward() * 200 + self:GetRight() * 30 + self:GetUp() * 105)
                e[i]:SetAngles(self:GetAngles() + Angle(0, 90, 90))
            elseif (i == 5) then
                e[i].RearDoor = false
                e[i].Bulkhead = false
                e[i]:SetPos(self:GetPos() - self:GetForward() * -285 + self:GetRight() * 149 + self:GetUp() * 105)
                e[i]:SetAngles(self:GetAngles() + Angle(90, 0, 90))
            end

            if CPPI and IsValid(p) and e[i].CPPISetOwner then
                e[i]:CPPISetOwner(p)
            end
        end
    end

    function ENT:ToggleDoors(d, set)
        if (d == "out" and IsValid(self.Door)) then
            if (self.Open) then
                self:SetPlaybackRate(0.4)
                self:ResetSequence("unhide")
                self.Open = false
                self.Door:SetSolid(SOLID_VPHYSICS)
                self.Door:EmitSound(self.Sounds.Open, 80, 98)
            elseif (not self.Open) then
                self:SetPlaybackRate(0.4)
                self:ResetSequence("hide")
                self.Open = true
                self.Door:SetSolid(SOLID_NONE)

                if (IsValid(self.Cloak)) then
                    self.Cloak:Cloak(self.Door, true)
                end

                self.Door:EmitSound(self.Sounds.Close, 80, 100)
            end
        elseif (d == "inc" and IsValid(self.Door2)) then
            if (self.Door2.Open) then
                timer.Simple(0.2, function()
                    if (IsValid(self)) then
                        self.Door2:SetPlaybackRate(0.5)
                        self.Door2:ResetSequence("open")
                        self.Door2.Open = false
                        self.Door2:SetSolid(SOLID_VPHYSICS)
                    end
                end)

                self.Door2:EmitSound(self.Sounds.CloseC, 80, 98)
            else
                self.Door2:SetPlaybackRate(0.5)
                self.Door2:ResetSequence("close")
                self.Door2.Open = true
                self.Door2:SetSolid(SOLID_NONE)

                if (IsValid(self.Cloak)) then
                    self.Cloak:Cloak(self.Door2, true)
                end

                self.Door2:EmitSound(self.Sounds.OpenC, 80, 100)
            end
        elseif (d == "ine" and IsValid(self.Door3)) then
            if (self.Door3.Open) then
                timer.Simple(0.2, function()
                    if (IsValid(self)) then
                        self.Door3:SetPlaybackRate(0.5)
                        self.Door3:ResetSequence("open")
                        self.Door3.Open = false
                        self.Door3:SetSolid(SOLID_VPHYSICS)
                    end
                end)

                self.Door3:EmitSound(self.Sounds.CloseC, 80, 98)
            else
                self.Door3:SetPlaybackRate(0.5)
                self.Door3:ResetSequence("close")
                self.Door3.Open = true
                self.Door3:SetSolid(SOLID_NONE)

                if (IsValid(self.Cloak)) then
                    self.Cloak:Cloak(self.Door3, true)
                end

                self.Door3:EmitSound(self.Sounds.OpenC, 80, 100)
            end
        end

        self.RunningAnim = true
    end

    function ENT:SpawnDoor(p)
        local e = ents.Create("prop_physics")
        e:SetModel("models/props_c17/door01_left.mdl")
        e:SetPos(self:GetPos() + self:GetRight() * 170 + self:GetForward() * 270 + self:GetUp() * 103)
        e:SetAngles(self:GetAngles() + Angle(0, 90, 0))
        e:Spawn()
        e:Activate()
        e:SetColor(Color(255, 255, 255, 0))
        e:SetRenderMode(RENDERMODE_TRANSALPHA)
        constraint.Weld(self, e, 0, 0, 0, true)
        constraint.NoCollide(self, e, 0, 0)
        e:SetParent(self)

        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end

        self.Door = e
        e = ents.Create("prop_physics")
        e:SetModel("models/James/teltac/inner_door.mdl")
        e:SetPos(self:GetPos() + self:GetForward() * 300)
        e:SetAngles(self:GetAngles())
        e:Spawn()
        e:Activate()
        constraint.Weld(self, e, 0, 0, 0, true)
        e:SetParent(self)
        self.Door2 = e

        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end

        local d = ents.Create("prop_physics")
        d:SetModel("models/James/teltac/inner_door.mdl")
        d:SetPos(self:GetPos() + self:GetForward() * -40)
        d:SetAngles(self:GetAngles())
        d:Spawn()
        d:Activate()
        constraint.Weld(self, d, 0, 0, 0, true)
        d:SetParent(self)
        self.Door3 = d

        if CPPI and IsValid(p) and d.CPPISetOwner then
            d:CPPISetOwner(p)
        end
    end

    function ENT:Use(p)
        if (self.LastUse and self.LastUse > CurTime()) then return end
        self.LastUse = CurTime() + 1
        self.BaseClass.Use(self, p)
        local pos = self:WorldToLocal(p:GetPos()) - COCKPIT_POS
        local d_pos = self:WorldToLocal(p:GetPos()) - DOOR_POS
        local de_pos = self:WorldToLocal(p:GetPos()) - DOORE_POS

        if (not (self.Inflight)) then
            --Allow player if he is 30 units away from COCKPIT_POS in left/right direction
            if ((pos.x > -80 and pos.x < 100) and (pos.y > -100 and pos.y < 100) and (pos.z > -30 and pos.z < 70)) then
                --Allow, if 30 units away from COCKPIT_POS in froward/backward dir
                -- Allow, if in range of -2 or + 30 in z-direction
                self.CanUse = true
                self:Enter(p)

                if (self.Open) then
                    self:ToggleDoors("out")
                end
            end
        end
    end

    function ENT:SpawnRings(p)
        local e = ents.Create("ring_base_ancient")
        e:SetModel(e.BaseModel)
        e:SetPos(self:LocalToWorld(Vector(0, 0, 7)))
        e:Spawn()
        e:Activate()
        e:SetAngles(self:GetAngles() + Angle(180, 0, 0))
        constraint.Weld(self, e, 0, 0, 0, true)
        e:SetParent(self)
        e.DirOverride = true
        e.Dir = -1
        self.OutRing = e

        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end

        local e = ents.Create("ring_base_ancient")
        e:SetModel(e.BaseModel)
        e:SetPos(self:LocalToWorld(Vector(0, -5, 44)))
        e:Spawn()
        e:Activate()
        e:SetAngles(self:GetAngles())
        constraint.Weld(self, e, 0, 0, 0, true)
        e:SetParent(self)
        e.DirOverride = true
        e.Dir = 1
        self.InRing = e

        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end
    end

    function ENT:SpawnRingPanel(p)
        local e = ents.Create("ring_panel_goauld")
        e:SetPos(self:GetPos() + self:GetForward() * 137 + self:GetRight() * -50 + self:GetUp() * 100)
        e:SetAngles(self:GetAngles() + Angle(0, 180, 0))
        e:Spawn()
        e:Activate()
        constraint.Weld(self, e, 0, 0, 0, true)
        e:SetParent(self)
        self.RingPanel = e

        if CPPI and IsValid(p) and e.CPPISetOwner then
            e:CPPISetOwner(p)
        end
    end

    --############# Cloak @ aVoN
    function ENT:Status(b, nosound)
        if (b) then
            if (not (self:Enabled())) then
                local e = ents.Create("cloaking")
                e.Size = 350
                e:SetPos(self:GetPos() + Vector(0, 0, 70))
                e:SetAngles(self:GetAngles())
                e:SetParent(self.Entity)
                e:Spawn()
                self:EmitSound(self.Sounds.Cloak, 100, math.random(80, 100))

                -- When our new cloak mentioned, that there is already a cloak
                if (e and e:IsValid() and not e.Disable) then
                    self.Cloak = e
                    self.Cloaked = e

                    return
                end
            end
        else
            if (self:Enabled()) then
                self.Cloak:Remove()
                self.Cloak = nil
                self:EmitSound(self.Sounds.Uncloak, 80, math.random(90, 110))
            end
        end

        return
    end

    function ENT:Enabled()
        return (self.Cloak and self.Cloak:IsValid())
    end

    --############# Toggle Cloak @ RononDex
    function ENT:ToggleCloak()
        if (self.CanCloak) then
            if (self.CanDoCloak) then
                if (self.Cloaked) then
                    self:Status(false)

                    if (self.Inflight) then
                        self:Rotorwash(true)
                    end

                    self.Cloaked = false
                    self.CanDoCloak = false

                    timer.Simple(2, function()
                        if (IsValid(self)) then self.CanDoCloak = true end
                    end)
                else
                    self:Status(true)
                    self.Cloaked = true

                    if (self.Inflight) then
                        self:Rotorwash(false)
                    end

                    self.CanDoCloak = false

                    timer.Simple(2, function()
                        if (IsValid(self)) then self.CanDoCloak = true end
                    end)
                end
            end
        end
    end

    -- landing mode: no forward / sideways drive, only up and down; the ship slows down smoothly and stays put
    function ENT:PhysicsSimulate(phys, deltatime)
        if (self.Inflight and self.LandingMode) then
            local f, m, b, r = self.ForwardSpeed, self.MaxSpeed, self.BackwardSpeed, self.RightSpeed
            self.ForwardSpeed, self.MaxSpeed, self.BackwardSpeed, self.RightSpeed = 0, 0, 0, 0
            self.BaseClass.PhysicsSimulate(self, phys, deltatime)
            self.ForwardSpeed, self.MaxSpeed, self.BackwardSpeed, self.RightSpeed = f, m, b, r
            return
        end
        self.BaseClass.PhysicsSimulate(self, phys, deltatime)
    end

    function ENT:HyperSpace()
        -- AGP: the window opens ahead (it pointed at the map origin without a Wire target), the jump stops before
        -- walls, and the people in the cargo room come along (AGP.ShipMove, lua/autorun/agp_ship_hyperdrive.lua)
        local dest
        if (self.DestSet and isvector(self.HyperspaceVector)) then
            local d = self.HyperspaceVector - self:GetPos()
            dest = self:GetPos() + d:GetNormalized() * math.min(d:Length(), math.max(self.HyperspaceDist or 0, 1000))
        else
            dest = self:GetPos() + self:GetForward() * self.HyperspaceDist
        end
        local tr = util.TraceLine({ start = self:GetPos(), endpos = dest, filter = self, mask = MASK_SOLID_BRUSHONLY })
        if (tr.Hit) then dest = tr.HitPos - (dest - self:GetPos()):GetNormalized() * self:BoundingRadius() end
        if (not util.IsInWorld(dest)) then return end
        local Ofs = dest - self:GetPos()
        if (Ofs:LengthSqr() < 1) then Ofs = self:GetForward() end
    

        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        fx:SetEntity(self)
        util.Effect("propspawn", fx)
        self:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 500)
        self:EmitSound("npc/turret_floor/die.wav", 450, 70)
        -- AGP: the same hyperspace windows as the other ships (agp_hyperwindow): one opens ahead and takes the ship in,
        -- the one at the target stays behind it, where it came out (the arrival window belongs behind the ship). jump_in /
        -- jump_out came from an old workshop addon (both were placed at the start).
        local dir = Ofs:GetNormalized()
        local radius = math.Clamp(self:BoundingRadius() * 0.7, 200, 3000)
        if (AGP.ShipHyperWindow) then AGP.ShipHyperWindow(self:LocalToWorld(self:OBBCenter()) + dir * radius * 1.4, -dir, radius, 1.2) end

        if (AGP.ShipMove) then AGP.ShipMove(self, dest - self:GetPos()) else self:SetPos(dest) end
        if (AGP.ShipHyperArrive) then AGP.ShipHyperArrive(self, dir, radius, 1.8) end
    end

    function ENT:TriggerInput(k, v)
        if (k == "Hyperspace") then
            self.HyperspaceVector = v
            self.DestSet = isvector(v) and v ~= Vector(0, 0, 0) -- AGP: 0 0 0 clears the target
            self.HyperVector = true
        elseif (k == "Hyperspace X" or k == "Hyperspace Y" or k == "Hyperspace Z") then
            -- our own: set the jump target one axis at a time (copy, so the wired vector is not changed)
            local vec = Vector(self.HyperspaceVector or Vector(0, 0, 0))

            if (k == "Hyperspace X") then
                vec.x = v or 0
            elseif (k == "Hyperspace Y") then
                vec.y = v or 0
            else
                vec.z = v or 0
            end

            self.HyperspaceVector = vec
            self.DestSet = vec ~= Vector(0, 0, 0)
            self.HyperVector = false
        elseif (k == "Cloak") then
            if ((v > 0) ~= (self.Cloaked and true or false)) then self:ToggleCloak() end -- AGP: 1 = cloaked, 0 = not (it toggled on every change)
        end
    end

    --####### Give us air @RononDex
    function ENT:LSSupport()
        local ent_pos = self:GetPos()

        if (IsValid(self)) then
            -- Find all players
            for _, p in pairs(player.GetAll()) do
                local pos = (p:GetPos() - ent_pos):Length() -- Where they are in relation to the jumper

                -- If they're close enough
                if (pos < 800 and p.suit) then
                    if (not (StarGate.RDThree())) then
                        p.suit.air = 100 -- They get air
                        p.suit.energy = 100 -- and energy
                        p.suit.coolant = 100 -- and coolant
                    else
                        p.suit.air = 200 -- We need double the amount of LS3(No idea why)
                        p.suit.coolant = 200
                        p.suit.energy = 200
                    end
                end
            end
        end
    end

    function ENT:PreEntityCopy()
        local dupeInfo = {}

        if IsValid(self.RingPanel) then
            dupeInfo.RingPanel = self.RingPanel:EntIndex()
        end

        if IsValid(self.InRing) then
            dupeInfo.InRing = self.InRing:EntIndex()
        end

        if IsValid(self.OutRing) then
            dupeInfo.OutRing = self.OutRing:EntIndex()
        end

        if IsValid(self.Door) then
            dupeInfo.Door = self.Door:EntIndex()
        end

        if IsValid(self.Door2) then
            dupeInfo.Door2 = self.Door2:EntIndex()
        end

        if IsValid(self.Door3) then
            dupeInfo.Door3 = self.Door3:EntIndex()
        end

        duplicator.StoreEntityModifier(self, "TelTakDupeInfo", dupeInfo)
        StarGate.WireRD.PreEntityCopy(self)
    end

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        local dupeInfo = Ent.EntityMods.TelTakDupeInfo

        if dupeInfo.RingPanel then
            self.RingPanel = CreatedEntities[dupeInfo.RingPanel]
        end

        if dupeInfo.InRing then
            self.InRing = CreatedEntities[dupeInfo.InRing]
        end

        if dupeInfo.OutRing then
            self.OutRing = CreatedEntities[dupeInfo.OutRing]
        end

        if dupeInfo.Door then
            self.Door = CreatedEntities[dupeInfo.Door]
            self.Door:SetColor(Color(255, 255, 255, 0))
            self.Door:SetRenderMode(RENDERMODE_TRANSALPHA)
        end

        if dupeInfo.Door2 then
            self.Door2 = CreatedEntities[dupeInfo.Door2]
        end

        if dupeInfo.Door3 then
            self.Door3 = CreatedEntities[dupeInfo.Door3]
        end

        self:SpawnButtons(ply)

        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        if (IsValid(ply)) then
            local PropLimit = GetConVar("CAP_ships_max"):GetInt()

            if (ply:GetCount("CAP_ships") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")") -- fix: message text was unquoted (client Lua error)
                self.Entity:Remove()

                return
            end

            ply:AddCount("CAP_ships", Ent)
        end

        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("sg_vehicle_teltac", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    ENT.ViewOverride = true

    ENT.Sounds = {
        Engine = Sound("vehicles/AlkeshEngine.wav")
    }

    if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
    --########## Keybinder stuff
    local KBD = StarGate.KeyBoard:New("Teltak")
    --Navigation
    KBD:SetDefaultKey("FWD", StarGate.KeyBoard.BINDS["+forward"] or "W") -- Forward
    KBD:SetDefaultKey("LEFT", StarGate.KeyBoard.BINDS["+moveleft"] or "A") -- Forward
    KBD:SetDefaultKey("RIGHT", StarGate.KeyBoard.BINDS["+moveright"] or "D") -- Forward
    KBD:SetDefaultKey("BACK", StarGate.KeyBoard.BINDS["+back"] or "S") -- Forward
    KBD:SetDefaultKey("UP", StarGate.KeyBoard.BINDS["+jump"] or "SPACE") -- Forward
    KBD:SetDefaultKey("DOWN", StarGate.KeyBoard.BINDS["+duck"] or "CTRL") -- Forward
    KBD:SetDefaultKey("SPD", StarGate.KeyBoard.BINDS["+speed"] or "SHIFT")
    KBD:SetDefaultKey("LAND", "ENTER")
    --Roll
    KBD:SetDefaultKey("RL", "MWHEELDOWN") -- Roll left
    KBD:SetDefaultKey("RR", "MWHEELUP") -- Roll right
    KBD:SetDefaultKey("RROLL", "MOUSE3") -- Reset Roll
    --Attack
    KBD:SetDefaultKey("FIRE", StarGate.KeyBoard.BINDS["+attack"] or "MOUSE1") -- Fire blasts
    --Special Actions
    KBD:SetDefaultKey("RROLL", "MOUSE3") -- Reset roll
    KBD:SetDefaultKey("BOOM", "BACKSPACE")
    KBD:SetDefaultKey("CLOAK", "C") -- AGP: was ALT, ALT is free look now
    KBD:SetDefaultKey("DOOR", "2")
    KBD:SetDefaultKey("HYPERSPACE", "R")
    KBD:SetDefaultKey("SHIELD", "G") -- AGP: shield
    --View
    KBD:SetDefaultKey("Z+", "UPARROW")
    KBD:SetDefaultKey("Z-", "DOWNARROW")
    KBD:SetDefaultKey("A+", "LEFTARROW")
    KBD:SetDefaultKey("A-", "RIGHTARROW")
    KBD:SetDefaultKey("FPV", "1")
    KBD:SetDefaultKey("EXIT", StarGate.KeyBoard.BINDS["+use"] or "E")
    local MaxCharge

    function ENT:Initialize()
        self.Dist = -1160
        self.UDist = 450
        self.KBD = self.KBD or KBD:CreateInstance(self)
        self.BaseClass.Initialize(self)
        self.Vehicle = "Teltak"
        self.NextPress = CurTime()
        self.FPV = 0
        MaxCharge = StarGate.CFG:Get("teltak", "jump_distance", 15000)
    end

    function SGTeltakCalcView(Player, Origin, Angles, FieldOfView)
        local view = {}
        local p = LocalPlayer()
        local self = p:GetNetworkedEntity("ScriptedVehicle", NULL)

        if (IsValid(self) and self:GetClass() == "sg_vehicle_teltac") then
            if (self.FPV == 0) then
                local pos = self:GetPos() + self:GetUp() * self.UDist + LocalPlayer():GetAimVector():GetNormal() * self.Dist
                local face = ((self:GetPos() + Vector(0, 0, 100)) - pos):Angle()
                view.origin = pos
                view.angles = face
            elseif (self.FPV == 1) then
                local pos = self.Entity:GetPos() + self.Entity:GetForward() * 500 + self.Entity:GetUp() * 130 + self:GetRight() * 30
                local angle = self.Entity:GetAngles()
                view.origin = pos
                view.angles = angle
            elseif (self.FPV == 2) then
                local pos = self:LocalToWorld(Vector(0, 0, 10))
                local angle = self.Entity:GetAngles() + Angle(90, 0, 0)
                view.origin = pos
                view.angles = angle
            end

            return view
        end
    end

    hook.Add("CalcView", "SGTeltakCalcView", SGTeltakCalcView)

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

            if (AGP.KeyPress(self, p, self.Vehicle, "FPV") and self.NextPress < CurTime()) then
                if (self.FPV == 2) then
                    self.FPV = 0
                else
                    self.FPV = self.FPV + 1
                end

                self.NextPress = CurTime() + 1
            end
        end
    end

    --########### HUD (AGP: Goa'uld gold plate with the ship's state and the keys)
    local function L(k, d) return AGP and AGP.L and AGP.L(k, d) or d end
    local GOLD, GOLD2, DARK = Color(235, 190, 90), Color(160, 120, 50), Color(25, 16, 6, 215)
    surface.CreateFont("AGPTeltakBig", { font = "Trebuchet MS", size = 26, weight = 800 })
    surface.CreateFont("AGPTeltakSmall", { font = "Trebuchet MS", size = 16, weight = 600 })
    function PrintHUD()
        local p = LocalPlayer()
        local self = p:GetNetworkedEntity("ScriptedVehicle", NULL)
        if (not IsValid(self) or self:GetClass() ~= "sg_vehicle_teltac") then return end
        local w, h = 380, 190
        local x, y = 24, ScrH() - h - 24
        draw.RoundedBox(10, x, y, w, h, DARK)
        surface.SetDrawColor(GOLD2); surface.DrawOutlinedRect(x, y, w, h, 2)
        draw.SimpleText(L("agp_teltak_hud", "TEL'TAK"), "AGPTeltakBig", x + 14, y + 8, GOLD)
        local hp = math.Clamp(self:GetNWInt("health") / math.max(1, self:GetNWInt("maxhealth")), 0, 1)
        draw.SimpleText(L("agp_glider_hull", "Hull"), "AGPTeltakSmall", x + 14, y + 44, GOLD)
        surface.SetDrawColor(60, 40, 15, 255); surface.DrawRect(x + 90, y + 47, 270, 14)
        surface.SetDrawColor(hp < 0.3 and Color(235, 70, 50) or GOLD); surface.DrawRect(x + 90, y + 47, 270 * hp, 14)
        local state = {}
        -- AGP: shield strength / depleted (shared ship shield, lua/autorun/agp_ship_shield.lua)
        if (AGP and AGP.ShipShieldText and (self:GetNWBool("AGPShieldOn") or self:GetNWBool("AGPShieldDepleted"))) then
            state[#state + 1] = (AGP.ShipShieldText(self))
        elseif (self:GetNWBool("AGPShieldOn")) then state[#state + 1] = L("agp_teltak_shield", "SHIELD UP") end
        if (p:GetNWBool("Charging")) then state[#state + 1] = string.format(L("agp_teltak_charge", "HYPERDRIVE %d %%"), math.Round(p:GetNWInt("Charge") / math.max(1, p:GetNWInt("MaxCharge", 15000)) * 100)) end
        local cool = math.Round(p:GetNWInt("BeamCooldown"))
        if (cool > 0) then state[#state + 1] = string.format(L("agp_teltak_cool", "RING BEAM %d s"), cool) end
        draw.SimpleText(#state > 0 and table.concat(state, "   ") or L("agp_teltak_ready", "ready"), "AGPTeltakSmall", x + 14, y + 68, Color(255, 230, 150))
        local keys = { L("agp_teltak_k1", "W/S/A/D fly  Space/Ctrl up/down  Shift faster"),
            L("agp_teltak_k2", "G shield  Alt cloak  mouse wheel roll"),
            L("agp_teltak_k3", "Enter landing mode, then Mouse1 ring beam"),
            L("agp_teltak_k4", "hold R hyperspace  2 doors  1 view  E out") }
        for i, k in ipairs(keys) do draw.SimpleText(k, "AGPTeltakSmall", x + 14, y + 94 + (i - 1) * 22, GOLD2) end
    end

    hook.Add("HUDPaint", "TeltakHUD", PrintHUD)
end