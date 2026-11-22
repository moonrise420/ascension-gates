--[[
	Energy Beam
	Copyright (C) 2011 Madman07
]]
--
ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.DoNotDuplicate = true

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("entweapon")) then return end
    AddCSLuaFile()
    ENT.CAP_NotSave = true

    function ENT:Initialize()
        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
        self:DrawShadow(false)
        self.EndEntity = self.Entity:SpawnTarget()
        self.StartEntity = self.Entity:SpawnBeam()
        self.StartPos = Vector(1, 1, 1)
        self.Dir = Vector(1, 1, 1)
        self.EndPos = Vector(1, 1, 1)
        self.UpdateStart = false
        self.UpdateEnd = false
        self.BlastCreated = false
        self.Length = 0
        self.FireFrequency = 850
    end

    function ENT:SpawnTarget()
        local ent = ents.Create("info_target")
        ent:SetName("BeamEndPos" .. self.Entity:EntIndex())
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
        beam:SetKeyValue("width", "50")
        beam:SetKeyValue("damage", 10000)
        beam:SetKeyValue("dissolvetype", "0")
        beam:Spawn()
        beam:SetTrigger(true)
        beam:SetParent(self.Entity)

        return beam
    end

    function ENT:Setup(start, dir, speed, time, effect)
        self.Entity:SetNWInt("StartTime", time)
        self.Dir = dir
        self.StartPos = start
        self.EndPos = start
        self.Speed = speed
        self.Effect = effect
        self.Time = CurTime()
        self.UpdateEnd = true
        local fx = EffectData()
        fx:SetEntity(self.Entity)
        fx:SetNormal(self.Dir)
        fx:SetStart(self.StartPos)
        fx:SetRadius(self.Speed)

        if effect then
            if (effect == "Ori" or effect == "AG3") then
                fx:SetMagnitude(1)
            elseif effect == "Asgard" then
                fx:SetMagnitude(2)
            end
        end

        util.Effect("energy_beam", fx, true, true)

        timer.Create(self.Entity:EntIndex() .. "Start", time, 1, function()
            self.UpdateStart = true
        end)

        timer.Create(self.Entity:EntIndex() .. "Remove", 20, 1, function()
            if IsValid(self.Entity) then
                self:Remove()
            end
        end)
    end

    function ENT:OnRemove()
        if IsValid(self.EndEntity) then
            self.EndEntity:Remove()
        end

        if IsValid(self.StartEntity) then
            self.StartEntity:Remove()
        end
    end

    -- AGP: a ship weapon's beam (StarGate.MarkShot) goes through its own ship and own shield bubbles: what the trace
    -- hits of them is ignored from then on and the trace runs again
    function ENT:AGPTrace()
        local ignore = self.AGPIgnore
        if (not ignore) then
            ignore = {}
            for _, v in pairs({self, self:GetOwner(), self.EndEntity, self.StartEntity}) do -- (the ship weapons set Owner = SetOwner)
                if (IsValid(v)) then ignore[#ignore + 1] = v end
            end
            self.AGPIgnore = ignore
        end
        local tr = StarGate.Trace:New(self.EndPos, self.Dir * self.Speed, ignore)
        for _ = 1, 8 do
            if not (IsValid(tr.Entity) and StarGate.ShotPasses(self, tr.Entity)) then break end
            ignore[#ignore + 1] = tr.Entity
            tr = StarGate.Trace:New(self.EndPos, self.Dir * self.Speed, ignore)
        end
        return tr
    end

    function ENT:Think()
        if (self.AGPFrom) then
            self.StargateTrace = self.LastStargateTrace or self:AGPTrace()
        else
            self.StargateTrace = self.LastStargateTrace or StarGate.Trace:New(self.EndPos, self.Dir * self.Speed, {self.Entity, self.Owner, self.EndEntity, self.StartEntity})
        end

        if (self.UpdateStart == true) then
            self:UpdateStartPos()
        end

        if (self.UpdateEnd == true) then
            self:UpdateEndPos()
        end

        self:UpdateLaser()
        self.Entity:NextThink(CurTime() + 0.1)

        return true
    end

    function ENT:UpdateEndPos()
        -- AGP: a Ha'tak's shield (a shell, not an entity: agp_hatak.lua) stops the beam and takes its damage; it went
        -- through to the hull. The whole beam is checked, so a shield raised behind its end cuts it back too.
        if (AGP and AGP.HatakShieldOnPath) then
            local tr = self.StargateTrace
            local reach = self.EndPos + self.Dir * self.Speed
            if (tr.Hit and not tr.HitSky and tr.HitPos:Distance(self.EndPos) < self.Speed) then reach = tr.HitPos end
            local ship, at = AGP.HatakShieldOnPath(self.StartPos, reach)
            if (IsValid(ship)) then
                self.EndPos = at
                self.Length = self.StartPos:Distance(at)   -- its tail (UpdateStartPos) ends here, not inside the shield
                self:SetNWVector("EndPos", at)
                self.LastStargateTrace = nil
                AGP.HatakShieldBeamHit(ship, self, at)
                return
            end
        end
        if not (self.StargateTrace.HitSky) then
            if self.StargateTrace.Hit then
                local dist = self.StargateTrace.HitPos:Distance(self.EndPos)

                if dist < self.Speed then
                    local ent = self.StargateTrace.Entity

                    if IsValid(ent) then
                        local class = ent:GetClass()

                        if ((class == "shield" or class == "shield_core_buble" or class == "ship_shield") and (not IsValid(ent.Parent) or not ent.Parent.Depleted)) then
                            ent:Hit(self.Entity, self.StargateTrace.HitPos, 3 * (self.AGPDamageScale or 1), self.StargateTrace.HitNormal, self.FireFrequency) -- AGP: the beam's damage scale (balance)
                            self:DoUsualHit()
                            self:SetNWVector("EndPos", self.StargateTrace.HitPos)
                            self.LastStargateTrace = self.StargateTrace
                        elseif (class == "event_horizon") then
                            local remoteEH = ent.Target

                            if IsValid(remoteEH) then
                                self:OnHitEventHorizon(ent, self.StargateTrace.HitPos)
                                self.WillGoTroughtGates = true
                                self:SetNWVector("EndPos", self.StargateTrace.HitPos)
                                self.LastStargateTrace = self.StargateTrace
                            end
                        elseif (CombatDamageSystem) then
                            cds_disintigratepos(self.StargateTrace.HitPos, 1, self:GetOwner())
                            self:DoUsualHit()
                        elseif (gcombat) then
                            gcombat.nrghit(ent, 50, 50, self.StargateTrace.HitPos, self.StargateTrace.HitPos)
                            self:DoUsualHit()
                        else
                            ent:TakeDamage(10 * (self.AGPDamageScale or 1), self:GetOwner(), self.Entity)
                            self:DoUsualHit()
                        end
                    else
                        self:DoUsualHit()
                    end

                    self.EndPos = self.StargateTrace.HitPos
                    self.Length = self.Length + dist

                    if (not self.WillGoTroughtGates) then
                        -- AGP: the big ships take it by the distance to their hull (AGP.ShipBlastBegin): on a big ship's
                        -- bow the beam's blast did nothing, measured from the ship's middle
                        local agpBlast = AGP and AGP.ShipBlastBegin and AGP.ShipBlastBegin(self.EndPos, 250, 50 * (self.AGPDamageScale or 1))
                        util.BlastDamage(self.Entity, self.Entity, self.EndPos, 250, 50 * (self.AGPDamageScale or 1))
                        if (agpBlast) then AGP.ShipBlastEnd(agpBlast, self.Entity, self.Entity) end
                    end
                else
                    self.EndPos = self.EndPos + self.Dir * self.Speed
                    self.Length = self.Length + self.Speed
                end
            else
                self.EndPos = self.EndPos + self.Dir * self.Speed
                self.Length = self.Length + self.Speed
            end
        end
    end

    function ENT:DoUsualHit()
        if self.WillGoTroughtGates then return end
        local smoke = true

        if (self.StargateTrace.HitNormal == 0) then
            smoke = false
        end

        if (self.StargateTrace.MatType == MAT_FLESH or self.StargateTrace.MatType == MAT_METAL or self.StargateTrace.MatType == MAT_GLASS) then
            smoke = false
        end

        if self.StargateTrace.HitSky then
            smoke = false
        end

        if (self.Effect == "AG3") then
            if not self.BlastCreated then
                local ent = ents.Create("sat_blast_wave")
                ent:SetPos(self.StargateTrace.HitPos + Vector(0, 0, 300))
                ent:Spawn()
                ent:Activate()
                ent:SetOwner(self.Entity)
                self.BlastCreated = true
            end
        elseif ((self.AGPNextImpact or 0) > CurTime()) then
            -- AGP: the impact effect (an explosion sound and a burst of particles each) ran every 0.1 s while the beam
            -- hit: 10 explosions a second flooded the sound channels (audio stutter with the Ori mothership)
        elseif (self.Effect == "Ori") then
            self.AGPNextImpact = CurTime() + 0.4
            local fx = EffectData()
            fx:SetOrigin(self.StargateTrace.HitPos)
            fx:SetNormal(self.StargateTrace.HitNormal)
            fx:SetEntity(self.Entity)

            if (not smoke) then
                fx:SetScale(-1)
            else
                fx:SetScale(1)
            end

            fx:SetMagnitude(30)
            fx:SetAngles(Angle(240, 200, 120))
            util.Effect("energy_impact", fx, true, true)
        else
            local fx = EffectData()
            fx:SetOrigin(self.StargateTrace.HitPos)
            fx:SetNormal(self.StargateTrace.HitNormal)
            fx:SetEntity(self.Entity)

            if (not smoke) then
                fx:SetScale(-1)
            else
                fx:SetScale(1)
            end

            self.AGPNextImpact = CurTime() + 0.4
            fx:SetMagnitude(5)
            fx:SetAngles(Angle(120, 175, 255))
            util.Effect("energy_impact", fx, true, true)
        end
    end

    function ENT:OnHitEventHorizon(eventHorizon, hitPos)
        if (self.AlreadyHitEH) then return end
        local remoteEH = eventHorizon.Target

        if (eventHorizon:GetForward():DotProduct((hitPos - eventHorizon:GetPos()):GetNormalized()) < 0) then
            self.AlreadyHitEH = true

            return
        end

        if (IsValid(remoteEH) and IsValid(remoteEH:GetParent()) and remoteEH:GetParent():IsBlocked()) then
            self.AlreadyHitEH = true

            if IsValid(remoteEH:GetParent().Iris) then
                remoteEH:GetParent().Iris:EmitSound(remoteEH:GetParent().Iris.Sounds.Hit, 90, math.random(98, 103))
            end

            return
        end

        local teleportedPos, teleportedForward = StarGate.GetTeleportedVector2(eventHorizon, remoteEH, hitPos, self.Dir)
        local ent = ents.Create("energy_beam2")
        ent.Owner = self.Owner
        ent:SetPos(teleportedPos)
        ent:Spawn()
        ent:Activate()
        ent:SetOwner(self.Entity:GetOwner())
        ent:Setup(teleportedPos, teleportedForward, self.Speed, 1.5, self.Effect)
        self.AlreadyHitEH = true
    end

    function ENT:UpdateStartPos()
        self.StartPos = self.StartPos + self.Dir * self.Speed
        self.Length = self.Length - self.Speed

        if (self.Length <= 1) then
            self:Remove()
        end
    end

    function ENT:UpdateLaser()
        self.EndEntity:SetPos(self.EndPos)
        self.Entity:SetPos(self.StartPos)
        self.StartEntity:SetKeyValue("LaserTarget", self.EndEntity:GetName())
        self.StartEntity:Fire("TurnOn", 1)
    end
end

if CLIENT then
    -- from CAP: kill-feed name
    language.Add("energy_beam2", (SGLanguage and SGLanguage.GetMessage and SGLanguage.GetMessage("energy_beam_kill")) or "Energy Beam")

    function ENT:Draw()
    end
end