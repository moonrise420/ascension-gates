--[[
	Energy Laser
	Copyright (C) 2011 Madman07
]]
--
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.DoNotDuplicate = true

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("entweapon")) then return end
    AddCSLuaFile()
    ENT.CAP_NotSave = true

    ENT.Sounds = {
        Loop = Sound("weapons/asuran_beam.wav")
    }

    function ENT:Initialize()
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
        self:DrawShadow(false)
        self.EndEntity = self.Entity:SpawnTarget()
        self.StartEntity = self.Entity:SpawnBeam()
        self.EndPos = Vector(1, 1, 1)
        self.FireFrequency = 575
    end

    function ENT:SpawnTarget()
        local ent = ents.Create("info_target")
        ent:SetName("LaserEndPos" .. self.Entity:EntIndex())
        ent:Spawn()
        ent:Activate()
        ent:SetPos(Vector(0, 0, 0))

        return ent
    end

    function ENT:SpawnBeam()
        local beam = ents.Create("env_laser")
        beam:SetPos(Vector(0, 0, 0))
        beam:SetAngles(self.Entity:GetAngles())
        beam:SetOwner(self.Entity:GetOwner())
        beam:SetVar("Owner", self.Entity:GetVar("Owner", nil))
        beam:SetKeyValue("width", "5000")
        beam:SetKeyValue("damage", 10000)
        beam:SetKeyValue("dissolvetype", "0")
        beam:Spawn()
        beam:SetParent(self.Entity)
        beam:SetTrigger(true)

        return beam
    end

    function ENT:Setup(startent, effect, up)
        self.Parent = startent
        self.Entity:SetPos(startent:GetPos() + startent:GetForward() * 10)
        self.Entity:SetAngles(startent:GetAngles())
        self.Entity:SetParent(startent)
        self.GoUp = up or false
        self.Sounds.LoopSound = CreateSound(self.Entity, self.Sounds.Loop)

        if self.Sounds.LoopSound then
            self.Sounds.LoopSound:Play()
        end

        -- AGP: the env_laser was made at the map origin and parented there, so its damage line ran from the middle of
        -- the map to the target: move it onto the beam's start
        if IsValid(self.StartEntity) then self.StartEntity:SetPos(self.Entity:GetPos()) end

        if (effect == "GateWep") then
            local fx = EffectData()
            fx:SetOrigin(startent:GetPos())
            fx:SetEntity(self.Entity)
            util.Effect("GateWeapon_Out", fx, true, true)
        elseif (effect == "ONeill") then
            local fx = EffectData()
            fx:SetOrigin(startent:GetPos())
            fx:SetEntity(self.Entity)
            util.Effect("ONeillBeam", fx, true, true)
        end
    end

    function ENT:OnRemove()
        if self.Sounds.LoopSound then
            self.Sounds.LoopSound:Stop()
            self.Sounds.LoopSound = nil
        end

        if IsValid(self.EndEntity) then
            self.EndEntity:Remove()
        end

        if IsValid(self.StartEntity) then
            self.StartEntity:Remove()
        end
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end

    function ENT:Think()
        if not IsValid(self.Parent) then
            self.Entity:Remove()
            return -- AGP: went on with a removed parent (error every think)
        end

        local endpos = Vector(0, 0, 0)
        local startpos = self.Parent:GetPos()

        if self.GoUp then
            startpos = self.Parent:GetPos() + self.Parent:GetUp() * 20
            endpos = self.Parent:GetPos() + self.Parent:GetUp() * 10 ^ 14
        else
            startpos = self.Parent:GetPos() + self.Parent:GetForward() * 10
            endpos = self.Parent:GetPos() + self.Parent:GetForward() * 10 ^ 14
        end

        self.StartPos = startpos
        self.StargateTrace = StarGate.Trace:New(startpos, endpos, {self.Entity, self.Owner, self.Parent})

        local gate = self.Parent:GetParent()
        self.IrisHeld = false

        if IsValid(gate) then
            if StarGate.IsIrisClosed(gate) then
                -- AGP: the iris holds the beam: an energy iris loses its energy, a metal iris heats up, until it fails
                self.IrisHeld = self:HitIris(gate, startpos)
                if self.IrisHeld then
                    self.StargateTrace.Entity = NULL
                    self.StargateTrace.HitPos = startpos
                end
            end
        end

        self:UpdateEndPos()
        self:UpdateLaser()
        self.Entity:NextThink(CurTime() + 0.1)

        return true
    end

    -- AGP: shields the beam drains and is held by until they are down (bubble shield, shield core, ship shields, Tok'ra wall)
    local SHIELDS = { shield = true, shield_core_buble = true, ship_shield = true, tokra_shield = true }

    function ENT:UpdateEndPos()
        if self.IrisHeld then
            self.EndPos = self.StartPos -- held at the iris: no beam on this side, no blast in the gate room
            return
        end
        -- AGP: a Ha'tak's shield (a shell, not an entity: agp_hatak.lua) holds the beam like the other shields
        if AGP and AGP.HatakShieldOnPath and self.StargateTrace.HitPos then
            local ship, at = AGP.HatakShieldOnPath(self.StartPos, self.StargateTrace.HitPos)
            if IsValid(ship) then
                self.EndPos = at
                AGP.HatakShieldBeamHit(ship, self, at)
                return
            end
        end
        if self.StargateTrace.Hit then
            local ent = self.StargateTrace.Entity
            local onShield = IsValid(ent) and SHIELDS[ent:GetClass()] and ent.Hit and true or false

            if onShield and not self:HitShipShield(ent) then
                ent:Hit(self.Entity, self.StargateTrace.HitPos, 3, self.StargateTrace.HitNormal, self.FireFrequency)
            end

            self.EndPos = self.StargateTrace.HitPos
            if not onShield then -- AGP: on a shield the beam is held there; its blast hurt the crew inside ship shields
                util.BlastDamage(self.Entity, self.Entity, self.EndPos, 250, 50)
                self:HitShipHull(ent)
            end
            self:BeamDamage(onShield)
        end
    end

    -- AGP: the bubble of a ship (sg_vehicle_base ships: Tel'tak, Wraith cruiser, Al'kesh, Daedalus, ...): drained by time
    -- (AGP.ShipShieldBeam, a full shield holds ~20 s). The CAP generator took 12-60 % per 0.1 s hit. Returns true when handled.
    function ENT:HitShipShield(ent)
        if ent:GetClass() ~= "ship_shield" or not (AGP and AGP.ShipShieldBeam and AGP.ShipOf) then return false end
        local gen = ent.Parent
        local ship = IsValid(gen) and AGP.ShipOf(gen:GetParent())
        if not IsValid(ship) then return false end -- not a ship (Puddle Jumper: its own hook in sv_damage.lua)
        AGP.ShipShieldBeam(ship, gen, self.StargateTrace.HitPos)
        return true
    end

    -- AGP: the beam on a ship's hull (or a part parented to it). Its blast reaches only what has its centre within 250
    -- units, so a big ship's hull never took any damage: hit the ship directly (50 every 0.1 s; the ship counts beam
    -- hits without a minimum, limited per second, see sg_vehicle_base ENT:AGPHullDamage).
    function ENT:HitShipHull(ent)
        local ship = IsValid(ent) and AGP and AGP.ShipOf and AGP.ShipOf(ent)
        if not IsValid(ship) or ship.Done then return end
        local weapon = self.Owner
        local d = DamageInfo()
        d:SetDamage(50)
        d:SetDamageType(DMG_ENERGYBEAM)
        d:SetAttacker(IsValid(weapon) and IsValid(weapon.Owner) and weapon.Owner or (IsValid(weapon) and weapon or self.Entity))
        d:SetInflictor(self.Entity)
        d:SetDamagePosition(self.EndPos)
        ship:TakeDamageInfo(d)
    end

    -- AGP: the beam itself burns whatever stands in it. Players died from the blast, NPCs often did not: hit players,
    -- NPCs and nextbots along the beam directly (disintegrating, like the series). Stops short of a shield it hits.
    function ENT:BeamDamage(onShield)
        local s, e = self.StartPos, self.EndPos
        if not (s and e) then return end
        local dir = e - s
        if dir:Length() < 1 then return end
        dir:Normalize()
        e = e - dir * (onShield and 60 or 40) -- not through a shield or wall to those right behind it
        local weapon = self.Owner
        local attacker = IsValid(weapon) and IsValid(weapon.Owner) and weapon.Owner or (IsValid(weapon) and weapon or self.Entity)
        local r = Vector(40, 40, 40)
        local list = ents.FindAlongRay(s, e, -r, r)
        local hit = self.StargateTrace and self.StargateTrace.Entity
        if IsValid(hit) then list[#list + 1] = hit end -- the one the beam stops on
        local done = {}
        for _, v in ipairs(list) do
            if IsValid(v) and not done[v] and v ~= self.Parent and ((v:IsPlayer() and v:Alive()) or v:IsNPC() or v:IsNextBot()) then
                done[v] = true
                local d = DamageInfo()
                d:SetDamage(60) -- every 0.1 s
                d:SetDamageType(bit.bor(DMG_ENERGYBEAM, DMG_DISSOLVE))
                d:SetAttacker(attacker)
                d:SetInflictor(self.Entity)
                d:SetDamagePosition(v:WorldSpaceCenter())
                d:SetDamageForce(dir * 5000)
                v:TakeDamageInfo(d)
            end
        end
    end

    -- AGP: the beam on a closed iris. Returns true while the iris still holds.
    -- Energy iris (Atlantis shield, Goa'uld iris): takes energy from the gate's network and holds IRIS_ENERGY_TIME
    -- seconds at most (sooner when the energy runs out), then it collapses and the beam goes through.
    -- Metal (trinium) iris: glows hotter and hotter, steams, and gives way after IRIS_HEAT_TIME seconds.
    -- Both recover slowly when the beam stops (cool down / recharge, half as fast as they were loaded).
    local IRIS_ENERGY_TIME = 30
    local IRIS_HEAT_TIME = 25
    local IRIS_DRAIN = 50000 -- energy per second from the gate's network

    function ENT:FindIris(gate)
        for _, v in ipairs(ents.FindInSphere(gate:GetPos(), 10)) do
            if v.IsIris and v.IsActivated then return v end
        end
    end

    local function heatColor(load)
        return Color(255, math.floor(255 - 150 * load), math.floor(255 - 230 * load), 255)
    end

    function ENT:HitIris(gate, pos)
        local iris = self:FindIris(gate)
        if not IsValid(iris) then return true end -- blocked by something else: held, as before
        local now = CurTime()
        local energyIris = iris:GetClass() == "goauld_iris" or iris:GetModel() == "models/zup/stargate/sga_shield.mdl"
        local hold = energyIris and IRIS_ENERGY_TIME or IRIS_HEAT_TIME
        local last = iris.AGPLaserLast or now
        local load = iris.AGPLaserLoad or 0
        if now - last > 0.5 then load = math.max(0, load - (now - last) / (hold * 2)) end -- recovered meanwhile
        load = math.min(1, load + math.min(now - last, 0.5) / hold)
        iris.AGPLaserLast = now
        iris.AGPLaserLoad = load
        local fail = load >= 1

        if energyIris then
            if gate.HasRD then
                local en = gate:GetResource("energy") or 0
                local want = IRIS_DRAIN * 0.1
                gate:ConsumeResource("energy", math.min(en, want))
                if en < want then fail = true end -- no energy left to hold it
            end
            if (iris.AGPLaserSound or 0) < now and iris.HitIris then
                iris.AGPLaserSound = now + 0.6
                iris:HitIris(self.Entity, pos)
            end
        else
            self:HeatIris(iris, load, pos)
        end

        if fail then
            if not (iris.IsBusy and iris:IsBusy()) and iris.TrueActivate then
                if not energyIris then
                    iris:EmitSound("physics/metal/metal_box_break" .. math.random(1, 2) .. ".wav", 100, 80)
                    local fx = EffectData()
                    fx:SetOrigin(pos); fx:SetNormal(gate:GetForward()); fx:SetMagnitude(4); fx:SetScale(2); fx:SetRadius(8)
                    util.Effect("Sparks", fx, true, true)
                end
                iris:TrueActivate(true) -- opens (an energy iris with its "out of energy" sound)
            end
            return false
        end
        return true
    end

    -- the metal iris glows (white -> orange -> red), throws a light, sizzles and steams when it gets hot
    function ENT:HeatIris(iris, load, pos)
        if IsValid(iris.Iris) then iris.Iris:SetColor(heatColor(load)) end -- the visible iris model (stargate_iris modules)
        local now = CurTime()
        if (iris.AGPGlowNext or 0) < now and load > 0.15 then
            iris.AGPGlowNext = now + 0.5
            local fx = EffectData()
            fx:SetEntity(iris)
            fx:SetStart(iris:WorldToLocal(pos))
            fx:SetAngles(Angle(255, math.floor(160 - 110 * load), 40)) -- colour
            fx:SetScale(40 + 120 * load)
            fx:SetMagnitude(0.6)
            util.Effect("energy_glow", fx, true, true)
            if load > 0.4 then
                iris:EmitSound("ambient/levels/canals/toxic_slime_sizzle" .. math.random(2, 4) .. ".wav", 75, 100)
            end
        end
        if load > 0.4 and not IsValid(iris.AGPSteam) then
            local st = ents.Create("env_steam")
            if IsValid(st) then
                st:SetPos(pos + iris:GetForward() * 8)
                st:SetAngles(iris:GetForward():Angle())
                st:SetKeyValue("InitialState", "1")
                st:SetKeyValue("SpreadSpeed", "40")
                st:SetKeyValue("Speed", "120")
                st:SetKeyValue("StartSize", "20")
                st:SetKeyValue("EndSize", "80")
                st:SetKeyValue("Rate", "30")
                st:SetKeyValue("JetLength", "160")
                st:SetKeyValue("renderamt", "160")
                st:SetKeyValue("rendercolor", "220 220 220")
                st:Spawn()
                st:Activate()
                st:SetParent(iris)
                iris.AGPSteam = st
            end
        end
        -- cooling once the beam stopped: colour back, steam off
        local id = "AGPIrisCool" .. iris:EntIndex()
        if not timer.Exists(id) then
            timer.Create(id, 1, 0, function()
                if not IsValid(iris) then timer.Remove(id) return end
                local since = CurTime() - (iris.AGPLaserLast or 0)
                if since < 1 then return end -- still being hit
                local l = math.max(0, (iris.AGPLaserLoad or 0) - since / (IRIS_HEAT_TIME * 2))
                if IsValid(iris.Iris) then iris.Iris:SetColor(heatColor(l)) end
                if l < 0.4 and IsValid(iris.AGPSteam) then iris.AGPSteam:Remove() end
                if l <= 0 then
                    if IsValid(iris.AGPSteam) then iris.AGPSteam:Remove() end
                    timer.Remove(id)
                end
            end)
        end
    end

    function ENT:UpdateLaser()
        self.EndEntity:SetPos(self.EndPos)
        self.StartEntity:SetKeyValue("LaserTarget", self.EndEntity:GetName())
        self.StartEntity:Fire("TurnOn", 1)
    end
end

if CLIENT then
    function ENT:Draw()
    end
end