--[[
	Gate Glider for GarrysMod 10
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
ENT.Base = "sg_vehicle_base"
ENT.Type = "vehicle"
ENT.Author = "RononDex, Iziraider, Rafael De Jongh"
ENT.PrintName = "Gate Glider"
ENT.AGPHudEntHealth = true -- AGP: the HUD reads its hull (sg_vehicle_base Think)
ENT.Category = "Ships"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

if SERVER then
    --########Header########--
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("ship")) then return end
    AddCSLuaFile()
    ENT.Model = Model("models/Iziraider/gateglider/gateglider.mdl")

    ENT.Sounds = {
        Staff = Sound("pulse_weapon/staff_weapon.mp3")
    }

    --######## Pretty useless unless we can spawn it @RononDex
    function ENT:SpawnFunction(ply, tr)
        if (not tr.HitWorld) then return end
        local PropLimit = GetConVar("CAP_ships_max"):GetInt()

        if (ply:GetCount("CAP_ships") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")") -- fix: message text was unquoted (client Lua error)

            return
        end

        local e = ents.Create("sg_vehicle_gate_glider")
        e:SetPos(tr.HitPos + Vector(0, 0, 80))
        e:Spawn()
        e:SetPos(tr.HitPos + Vector(0, 0, 10 - e:OBBMins().z)) -- AGP: not inside the ground (the engine then pushed it out spinning)
        e:SetVar("Owner", ply)
        e:Activate()
        ply:AddCount("CAP_ships", e)

        return e
    end

    --######## What happens when it first spawns(Set Model, Physics etc.) @RononDex
    function ENT:Initialize()
        self.Vehicle = "GateGlider"
        self:SetModel(self.Model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self.EntHealth = 300
        self.MaxHealth = self.EntHealth
        self:SetUseType(SIMPLE_USE)
        self:StartMotionController()
        --####### Attack vars
        self.LastBlast = 0
        self.Delay = 10
        --######### Flight Vars
        self.Accel = {}
        self.Accel.FWD = 0
        self.Accel.RIGHT = 0
        self.Accel.UP = 0
        self.ForwardSpeed = 1500
        self.BackwardSpeed = -750
        self.UpSpeed = 600
        self.MaxSpeed = 2000
        self.RightSpeed = 750
        self.Accel.SpeedForward = 10
        self.Accel.SpeedRight = 7
        self.Accel.SpeedUp = 7
        self.RollSpeed = 5
        self.num = 0
        self.num2 = 0
        self.num3 = 0
        self.Roll = 0
        self.Hover = true
        self.GoesRight = true
        self.GoesUp = true
        self.CanRoll = true
        self:CreateWireOutputs("Health")
        self:SetWire("Health", self.EntHealth)
        local phys = self:GetPhysicsObject()

        if (phys:IsValid()) then
            phys:Wake()
            phys:SetMass(10000)
        end
    end

    function ENT:Think()
        self.BaseClass.Think(self)
        self.ExitPos = self:GetPos() + self:GetForward() * 75

        if (self.StartDelay) then
            self.Delay = math.Approach(self.Delay, 10, 3)
        end

        if (self.Delay >= 10) then
            self.StartDelay = false
        end

        if (IsValid(self.Pilot)) then
            if (AGP.KeyPress(self, self.Pilot, self.Vehicle, "DHD")) then
                self:OpenDHD(self.Pilot)
            end

            -- AGP 2026-10-30: Mouse2 = plasma torpedo that locks on (what is under the crosshair, else the nearest craft,
            -- player or NPC ahead) and follows it; one every 2.5 s
            if (self.Pilot:KeyDown(self.Vehicle, "TORPEDO") and CurTime() >= (self.AGPNextTorp or 0)) then
                self.AGPNextTorp = CurTime() + 2.5
                self:SetNWFloat("AGPTorpReady", self.AGPNextTorp)
                self:FireTorpedo()
            end

            if (self.Pilot:KeyDown(self.Vehicle, "FIRE")) then
                if (self.Delay >= 10) then
                    self:FireBlast(self:GetRight() * 80)
                    self:FireBlast(self:GetRight() * -80)
                    self.Delay = 0
                end

                self.StartDelay = true
            end
        else
            self.StartDelay = false
        end
    end

    function ENT:OnRemove()
        self.BaseClass.OnRemove(self)
    end

    --########## Gliders aren't invincible are they? @RononDex
    function ENT:OnTakeDamage(dmg)
        self.EntHealth = self.EntHealth - dmg:GetDamage()
        self:SetWire("Health", self.EntHealth)

        if (self.EntHealth <= 0) then -- AGP: the damage was taken off twice (it blew up one hit early)
            self:Bang() -- Go boom
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
    end

    --######### @ aVoN
    function ENT:OpenDHD(p)
        if (not IsValid(p)) then return end
        local e = self:FindGate(5000)
        if (not IsValid(e)) then return end
        if (hook.Call("StarGate.Player.CanDialGate", GAMEMODE, p, e) == false) then return end
        net.Start("StarGate.VGUI.Menu")
        net.WriteEntity(e)
        net.WriteInt(1, 8)
        net.Send(p)
    end

    --######### @ aVoN
    function ENT:FindGate(dist)
        local gate
        local pos = self:GetPos()

        for _, v in pairs(ents.FindByClass("stargate_*")) do
            if (not v.IsStargate or v.IsSupergate) then continue end
            local sg_dist = (pos - v:GetPos()):Length()

            if (dist >= sg_dist) then
                dist = sg_dist
                gate = v
            end
        end

        return gate
    end

    -- AGP: the torpedo's target: what the pilot aims at, else the best craft / player / NPC in a 25 degree cone ahead
    function ENT:TorpedoTarget()
        local aim = self.Pilot:GetAimVector()
        local start = self:GetPos()
        local tr = util.TraceLine({ start = start, endpos = start + aim * 30000, filter = function(e) return e ~= self and e ~= self.Pilot and e:GetParent() ~= self end })
        if (IsValid(tr.Entity) and not tr.Entity:IsWorld()) then return tr.Entity end
        local best, bestDot = nil, math.cos(math.rad(25))
        for _, e in ipairs(ents.FindInSphere(start, 15000)) do
            if (e ~= self and e ~= self.Pilot and (e.IsSGVehicle or e:IsPlayer() or e:IsNPC() or e:IsVehicle() or e:GetClass() == "agp_hatak")) then
                local d = (e:WorldSpaceCenter() - start):GetNormalized():Dot(aim)
                if (d > bestDot) then best, bestDot = e, d end
            end
        end
        return best
    end

    function ENT:FireTorpedo()
        local target = self:TorpedoTarget()
        local e = ents.Create("energy_pulse_alkesh")
        if (not IsValid(e)) then return end
        local speed = 3000
        e:PrepareBullet(self:GetForward(), 0, speed, 12, {self.Entity})
        e:SetPos(self:GetPos() + self:GetForward() * 120 - self:GetUp() * 20)
        e:SetOwner(self)
        e.Owner = self
        e:Spawn()
        e:Activate()
        e:SetColor(Color(255, 120, 40, 255))
        self:EmitSound(self.Sounds.Staff, 95, 70)
        if (not IsValid(target)) then return end
        -- steer towards the target every 0.05 s, turning at most a part of the way each step (it can be dodged)
        local id = "AGPTorpedo" .. e:EntIndex()
        timer.Create(id, 0.05, 160, function()
            if (not IsValid(e) or not IsValid(target)) then timer.Remove(id) return end
            local ph = e:GetPhysicsObject()
            if (not IsValid(ph)) then timer.Remove(id) return end
            local want = (target:WorldSpaceCenter() - e:GetPos()):GetNormalized()
            local dir = LerpVector(0.18, e.Direction or want, want):GetNormalized()
            e.Direction = dir
            ph:SetVelocity(dir * speed)
        end)
    end

    function ENT:FireBlast(diff)
        if (self.Delay >= 10) then
            local e = ents.Create("energy_pulse")

            e:PrepareBullet((AGP.ShipAimDir and AGP.ShipAimDir(self, self:GetPos()+diff) or self:GetForward()), 10, 16000, 6, {self.Entity})

            e:SetPos(self:GetPos() + diff)
            e:SetOwner(self)
            e.Owner = self
            e:Spawn()
            e:Activate()
            self:EmitSound(self.Sounds.Staff, 90, math.random(90, 110))
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("sg_vehicle_gate_glider", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    ENT.RenderGroup = RENDERGROUP_BOTH
    if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
    --########## Keybinder stuff
    local KBD = StarGate.KeyBoard:New("GateGlider")
    --Navigation
    KBD:SetDefaultKey("FWD", StarGate.KeyBoard.BINDS["+forward"] or "W") -- Forward
    KBD:SetDefaultKey("LEFT", StarGate.KeyBoard.BINDS["+moveleft"] or "A")
    KBD:SetDefaultKey("RIGHT", StarGate.KeyBoard.BINDS["+moveright"] or "D")
    KBD:SetDefaultKey("BACK", StarGate.KeyBoard.BINDS["+back"] or "S")
    KBD:SetDefaultKey("UP", StarGate.KeyBoard.BINDS["+jump"] or "SPACE")
    KBD:SetDefaultKey("DOWN", StarGate.KeyBoard.BINDS["+duck"] or "CTRL")
    KBD:SetDefaultKey("SPD", StarGate.KeyBoard.BINDS["+speed"] or "SHIFT")
    --Roll
    KBD:SetDefaultKey("RL", "MWHEELDOWN") -- Roll left
    KBD:SetDefaultKey("RR", "MWHEELUP") -- Roll right
    KBD:SetDefaultKey("RROLL", "MOUSE3") -- Reset Roll
    --Attack
    KBD:SetDefaultKey("FIRE", StarGate.KeyBoard.BINDS["+attack"] or "MOUSE1")
    KBD:SetDefaultKey("TORPEDO", StarGate.KeyBoard.BINDS["+attack2"] or "MOUSE2") -- AGP: homing plasma torpedo (was TRACK aiming)
    --Special Actions
    KBD:SetDefaultKey("DHD", "R")
    KBD:SetDefaultKey("BOOM", "BACKSPACE")
    --View
    KBD:SetDefaultKey("VIEW", "1")
    KBD:SetDefaultKey("Z+", "UPARROW")
    KBD:SetDefaultKey("Z-", "DOWNARROW")
    KBD:SetDefaultKey("A+", "LEFTARROW")
    KBD:SetDefaultKey("A-", "RIGHTARROW")
    KBD:SetDefaultKey("EXIT", StarGate.KeyBoard.BINDS["+use"] or "E")

    ENT.Sounds = {
        Engine = Sound("glider/deathglideridleoutside.wav")
    }

    function ENT:Initialize()
        self.BaseClass.Initialize(self)
        self.Dist = -750
        self.UDist = 120
        self.KBD = self.KBD or KBD:CreateInstance(self)
        self.FirstPerson = false
        self.Vehicle = "GateGlider"
    end

    --
    --######## Mainly Keyboard stuff @RononDex
    function ENT:Think()
        self.BaseClass.Think(self)
        local p = LocalPlayer()
        local GateGlider = p:GetNetworkedEntity("ScriptedVehicle", NULL)

        if ((GateGlider) and ((GateGlider) == self) and (GateGlider:IsValid())) then
            self.KBD:SetActive(true)
        else
            self.KBD:SetActive(false)
        end

        if ((GateGlider) and ((GateGlider) == self) and (GateGlider:IsValid())) then
            if (p:KeyDown("GateGlider", "Z+")) then
                self.Dist = self.Dist - 5
            elseif (p:KeyDown("GateGlider", "Z-")) then
                self.Dist = self.Dist + 5
            end

            -- AGP: 1 = cockpit view on / off (one switch per press; before it flipped every frame and changed nothing)
            local v = p:KeyDown("GateGlider", "VIEW")
            if (v and not self.ViewWas) then
                self.FirstPerson = not self.FirstPerson
                self.IsSGVehicleCustomView = self.FirstPerson
            end
            self.ViewWas = v

            if (p:KeyDown("GateGlider", "A+")) then
                self.UDist = self.UDist + 5
            elseif (p:KeyDown("GateGlider", "A-")) then
                self.UDist = self.UDist - 5
            end
        end
    end
    -- AGP: cockpit view (key 1), like the Death Glider: from the canopy, looking where the pilot aims; the glider itself is
    -- not drawn for him. Without it: the chase camera behind the glider (sg_vehicle_base), arrows move it.
    hook.Add("CalcView", "AGP.GateGliderCockpit", function(ply, pos, ang, fov)
        local g = ply:GetNetworkedEntity("ScriptedVehicle", NULL)
        if (not IsValid(g) or g:GetClass() ~= "sg_vehicle_gate_glider" or not g.FirstPerson) then return end
        local mn, mx = g:OBBMins(), g:OBBMaxs()
        local eye = g:LocalToWorld(Vector(mx.x * 0.3, 0, mn.z + (mx.z - mn.z) * 0.7))
        return { origin = eye, angles = ply:GetAimVector():Angle(), fov = fov, drawviewer = false }
    end)

    function ENT:Draw()
        local g = LocalPlayer():GetNetworkedEntity("ScriptedVehicle", NULL)
        if (g == self and self.FirstPerson) then return end
        self:DrawModel()
    end
end