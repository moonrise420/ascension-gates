--[[   Copyright (C) 2010 by Llapp   ]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Asuran Satellite"
ENT.Author = "Llapp "
ENT.Category = "Ascension Gates: Weapons"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_weapon_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("devices")) then return end
    AddCSLuaFile()
    AsuranGibs = {}
    AsuranGibs[1] = "models/Iziraider/asuransat/gibs/gib1.mdl"
    AsuranGibs[2] = "models/Iziraider/asuransat/gibs/gib2.mdl"
    AsuranGibs[3] = "models/Iziraider/asuransat/gibs/gib3.mdl"
    AsuranGibs[4] = "models/Iziraider/asuransat/gibs/gib4.mdl"
    AsuranGibs[5] = "models/Iziraider/asuransat/gibs/gib5.mdl"
    AsuranGibs[6] = "models/Iziraider/asuransat/gibs/gib6.mdl"

    ENT.Sounds = {
        HyperspaceWindow = Sound("stargate/asuran/hyperwindow.wav")
    }

    local DESTROYABLE = true

    --############ @  Llapp
    function ENT:Initialize()
        self.EntHealth = 1000
        self.MaxHealth = self.EntHealth

        if (WireAddon) then
            self.Inputs = WireLib.CreateInputs(self.Entity, {"Active", "AsuranShield", "HyperDrive", "Vector [VECTOR]","Entity [ENTITY]", "X", "Y", "Z"}) -- "Iris", -- our own: X/Y/Z aim inputs
        end
        -- AGP: "Health" output (HealthRepair already wrote it, but the port did not exist); starts at the spawn health
        self:CreateWireOutputs("Health")
        self:SetWire("Health", self.EntHealth)

        self.Entity:SetModel("models/Iziraider/asuransat/asuran_sat.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Phys = self.Entity:GetPhysicsObject()

        if (self.Phys:IsValid()) then
            self.Phys:EnableMotion(false)
            self.Phys:EnableGravity(false)
            self.Phys:SetMass(35000)
            self.Phys:Wake()
        end

        self.Entity:SetGravity(0)
        self.Entity:StartMotionController()
        self.WireActive = nil
        self.WireShoot = nil
        self.WireEnt = nil
        self.WireVec = Vector(0, 0, 0)
        self.WireIris = nil
        self.WireHoverdrive = nil
        self.Shield = nil
        self.Strength = 100
        self.StrengthShield = 100
        self.ShieldColor = Vector(0, 255, 0)
        self.Time = CurTime()
        self.SatellitePhys = {}
        self.Angles = Angle(90, 0, 0)
        self.Position = self.Entity:GetPos()
        self.TouchPosition = self.Entity:GetPos()
        self.Touched = false
        self.Time = CurTime()
        self.APC = nil
        self.APCply = nil
        self.Pressed = false
        self.GoUp = 0
        self.Forw = 0
        self.Accel = 0

        self.Accel = {
            FWD = 0,
            RIGHT = 0,
            UP = 0
        }
    end

    --############ @ Madman07
    function ENT:SpawnShield()
        local e = ents.Create("shield")
        e.Size = 310
        e.DrawBubble = true
        e:SetPos(self.Entity:GetPos())
        e:SetAngles(self.Entity:GetAngles())
        e:SetColor(Color(230, 230, 230, 255))
        e:SetParent(self.Entity)
        e:Spawn()
        e:SetNWBool("containment", false)
        e:DrawBubbleEffect()
        e:SetTrigger(true)
        self.Entity:EmitSound("shields/shield_engage.mp3", 90, math.random(90, 110))

        return e
    end

    --############ @  Llapp
    function ENT:SpawnFunction(p, t)
        if (not t.HitWorld) then return end
        local e = ents.Create("stargate_asuran")
        e:SetPos(t.HitPos + Vector(0, 0, 1000))
        ang = p:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 180) % 360
        e:SetAngles(ang)
        e:DrawShadow(false)
        self.Sat = e
        e:Spawn()
        e:Activate()
        e:AddGate(p)

        return e
    end

    --############ @  Llapp
    function ENT:AddGate(p)
        local pos = self:GetPos() + self:GetForward() * (51.5)
        local l = ents.Create("stargate_atlantis")
        l:DrawShadow(false)
        l:SetParent(self.Entity)
        l:SetPos(pos)
        l:SetAngles(self.Entity:GetAngles())
        l:Spawn()
        l:Activate()
        l:SetGateName("ASURAN")
        -- AGP: intended: the built-in gate keeps the random address it gets on spawn (also with stargate_random_address off), otherwise it would have no address to dial
        l:SetLocale(true)
        l:SetGateGroup("P@")
        hook.Call("PlayerSpawnedSENT", false, p, l, 0, 0, 1)
        self.Gate = l
        local physic = self.Gate:GetPhysicsObject()

        if physic and physic:IsValid() then
            if (physic:GetMass()) then
                physic:SetMass(0.000000001)
            end

            physic:EnableMotion(true)
            physic:EnableGravity(false)
            physic:Wake()
        end

        constraint.Weld(self.Gate, self, 0, 0, 0, true)

        if CPPI and IsValid(p) and l.CPPISetOwner then
            l:CPPISetOwner(p)
        end

        return l
    end

    --
    --############ @  Llapp
    function ENT:HyperspaceOut(jumpCoords)
        local effect = {}

        if (IsValid(self)) then
            self.Entity:EmitSound(self.Sounds.HyperspaceWindow, 90, math.random(97, 103))
            effect[1] = EffectData()
            effect[1]:SetOrigin(self:GetPos() + self:GetForward() * 900)
            effect[1]:SetScale(10000)
            effect[1]:SetEntity(self.Entity)
            util.Effect("propspawn", effect[1])
            effect[2] = EffectData()
            effect[2]:SetOrigin(jumpCoords)
            effect[2]:SetScale(10000)
            effect[2]:SetEntity(self.Entity)
            util.Effect("propspawn", effect[2])
            self.Entity:SetPos(jumpCoords)
        end
    end

    --
    --
    --############ @ Madman07 and Llapp
    function ENT:TriggerInput(variable, value)
        if (variable == "Vector") then
            self.WireVec = value
        -- our own: set single components of the aim vector (new Vector so a wired Vector input is not modified)
        elseif (variable == "X" or variable == "Y" or variable == "Z") then
            local v = self.WireVec or Vector(0, 0, 0)
            self.WireVec = Vector(variable == "X" and value or v.x, variable == "Y" and value or v.y, variable == "Z" and value or v.z)
        elseif (variable == "Entity") then
            self.WireEnt = value
        elseif (variable == "AsuranShield") then
            self.WireShield = value
        elseif (variable == "HyperDrive") then
            self.WireHoverdrive = value
        elseif (variable == "Active") then
            self.WireActive = value
        end
    end

    --############ @ Madman07
    function ENT:RemoveShield()
        if (self.Shield:IsValid()) then
            self.Shield:Remove()
            self.Shield = nil
            self:EmitSound("shields/shield_disengage.mp3", 90, math.random(90, 110))
        end
    end

    --############ @ Madman07 and Llapp
    function ENT:OnRemove()
        if (self.Entity and self.Entity:IsValid()) then
            self.Entity:Remove()
        end

        if (self.Shield and self.Shield:IsValid()) then
            self.Shield:Remove()
        end

        if (self.Gate and self.Gate:IsValid()) then
            self.Gate:Remove()
        end

        if (self.e and self.e:IsValid()) then
            self.e:Remove()
        end
    end

    function ENT:Hit(strength, normal, pos)
    end

    --######### @ RononDex,aVoN
    function ENT:DoKill(ply)
        local velocity = self:GetForward()
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetStart(self:GetUp())
        util.Effect("dirtyxplo", effectdata)
        self:OnRemove()
        local e = ents.Create("info_particle_system")
        e:SetPos(self:GetPos())
        e:SetAngles(self:GetAngles())
        e:SetKeyValue("effect_name", "citadel_shockwave_06") -- http://developer.valvesoftware.com/wiki/Half-Life_2:_Episode_Two_Particle_Effect_List
        e:SetKeyValue("start_active", 1)
        e:Spawn()
        e:Activate()
        e:Fire("Stop", "", 0.9)
        e:Fire("kill", "", 1)

        for k, v in pairs(AsuranGibs) do
            local model = v
            local k = ents.Create("prop_physics")
            k:SetPos(self:GetPos())
            k:SetAngles(self:GetAngles())
            k:SetModel(model)

            -- AGP: no SetMaterial here: the old material path did not exist (it had a Lua escape in it), the gibs keep their own textures

            k:PhysicsInit(SOLID_VPHYSICS)
            k:SetMoveType(MOVETYPE_VPHYSICS)
            k:SetSolid(SOLID_VPHYSICS)
            k:SetCollisionGroup(COLLISION_GROUP_WORLD)
            k:Activate()
            k:Spawn()
            k:GetPhysicsObject():SetVelocity(velocity * 1000 + VectorRand() * 40000)
            k:GetPhysicsObject():ApplyForceCenter(velocity * 1000 + VectorRand() * 40000)
            k:Fire("Kill", "", 10)
        end
    end

    function ENT:OnTakeDamage(dmg)
        if(DESTROYABLE) then
            self.EntHealth = self.EntHealth - dmg:GetDamage()
            self:SetWire("Health", math.max(0, self.EntHealth)) -- AGP: the Health output also follows damage (was spawn + repair only)

            if(self.EntHealth < 1) then
                self:DoKill()
            end
        end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
    end

    --############ @ Madman07
    function ENT:StartTouch(ent)
        if (ent and ent:IsValid() and ent:IsVehicle()) then
            if (self.APC ~= ent) then
                local ed = EffectData()
                ed:SetEntity(ent)
                util.Effect("propspawn", ed, true, true)
            end

            self.APC = ent
        end
    end

    --############ @ Madman07 and Llapp
    function ENT:PhysicsUpdate(phys, deltatime)
        local TargetPos = nil
        local jumpCoords = nil
        local FWD = self.Entity:GetForward()
        local UP = Vector(0, 0, 1)
        local RIGHT = FWD:Cross(UP):GetNormalized()
        local strafe = 0
        local move = 0
        local up = 0
        local acc = 10
        local coords = 0

        if (self.Pressed == true) then
            timer.Simple(1, function()
                self.Pressed = false
            end)
        end

        if self.APC and self.APC:IsValid() then
            self.APCply = self.APC:GetPassenger(0)

            if (self.APCply and self.APCply:IsValid()) then
                TargetPos = self.APCply:GetEyeTrace().HitPos

                if (self.APCply:KeyDown(IN_FORWARD)) then
                    move = 400
                    acc = 20
                elseif (self.APCply:KeyDown(IN_BACK)) then
                    move = -400
                    acc = 20
                end

                self.Accel.FWD = math.Approach(self.Accel.FWD, move, acc)

                if (self.APCply:KeyDown(IN_SPEED)) then
                    up = -400
                    acc = 20
                elseif (self.APCply:KeyDown(IN_JUMP)) then
                    up = 400
                    acc = 20
                end

                self.Accel.UP = math.Approach(self.Accel.UP, up, acc)

                if (self.APCply:KeyDown(IN_MOVERIGHT)) then
                    strafe = 400
                    acc = 20
                elseif (self.APCply:KeyDown(IN_MOVELEFT)) then
                    strafe = -400
                    acc = 20
                end

                self.Accel.RIGHT = math.Approach(self.Accel.RIGHT, strafe, acc)

                if (self.APCply:KeyDown(IN_RELOAD) and TargetPos ~= nil and IsValid(self.Entity) and self.Pressed == false) then
                    if (TargetPos ~= nil and self.Entity:IsValid()) then
                        if ((TargetPos - self.Entity:GetPos()):Length() > 0) then
                            coords = -800
                        else
                            coords = 800
                        end

                        jumpCoords = Vector(TargetPos.x + coords, TargetPos.y, self.Entity:GetPos().z)
                    end

                    timer.Simple(2, function()
                        if (IsValid(self.Entity)) then
                            if ((jumpCoords - self.Entity:GetPos()):Length() > 2000) then
                                self:HyperspaceOut(jumpCoords)
                                self.Pressed = true
                            end
                        end
                    end)
                end
            end
        elseif (self.WireActive == 1) then
            if (self.WireEnt and self.WireEnt:IsValid()) then
                TargetPos = self.WireEnt:LocalToWorld(self.WireEnt:OBBCenter())
            elseif (self.WireVec) then
                TargetPos = self.WireVec
            end

            if (TargetPos ~= nil and IsValid(self.Entity)) then
                if ((TargetPos - self.Entity:GetPos()):Length() > 0) then
                    coords = -1000
                else
                    coords = 1000
                end

                jumpCoords = Vector(TargetPos.x + coords, TargetPos.y, self.Entity:GetPos().z)
            end

            if (self.WireHoverdrive == 1 and TargetPos ~= nil and IsValid(self.Entity) and self.Pressed == false) then
                timer.Simple(5, function()
                    if (IsValid(self.Entity) and (jumpCoords - self.Entity:GetPos()):Length() > 3000) then
                        self:HyperspaceOut(jumpCoords)
                        self.Pressed = true
                    end
                end)
            end
        end

        local AimVec = Angle(0, 0, 0)
        local ang = Angle(90, 00, 0)
        local pos = self.Entity:GetPos()

        if (TargetPos == nil) then
            AimVec = self.Angles or Angle(90, 0, 0)
        else
            AimVec = (TargetPos - pos):Angle() + ang
        end

        if (self.Angles) then
            self.Angles.Pitch = AimVec.Pitch
            self.Angles.Yaw = AimVec.Yaw
        else
            self.Angles = Angle(90, 0, 0)
        end

        ShootAngle = AimVec
        pit = -1 * math.NormalizeAngle(ShootAngle.Pitch)
        ya = math.NormalizeAngle(ShootAngle.Yaw)
        self.Pitch = -1 * math.NormalizeAngle(self.Entity:GetAngles().Pitch + 90)
        self.Yaw = math.NormalizeAngle(self.Entity:GetAngles().Yaw)

        if ((math.abs(self.Pitch - pit) < 15) and (math.abs(self.Yaw - ya) < 15)) then
            self.InRange = 1
        else
            self.InRange = 0
        end

        local Satellite = self.Entity:GetPhysicsObject()

        if (self.APCply and self.APCply:IsValid()) then
            Satellite:Wake()

            self.SatellitePhys = {
                secondstoarrive = 4,
                pos = self.Entity:GetPos() + (FWD * self.Accel.FWD) + (UP * self.Accel.UP) + (RIGHT * self.Accel.RIGHT),
                maxangular = 8000,
                maxangulardamp = 900,
                maxspeed = 10000000,
                maxspeeddamp = 400000,
                dampfactor = 0.6,
                angle = self.Angles - Angle(90, 0, 0),
                deltatime = deltatime
            }

            Satellite:ComputeShadowControl(self.SatellitePhys)
        else
            Satellite:Wake()

            self.SatellitePhys = {
                secondstoarrive = 3,
                maxangular = 100,
                maxangulardamp = 1000,
                maxspeed=0,
                dampfactor = 0.9,
                angle = self.Angles - Angle(90, 0, 0),
                deltatime = deltatime
            }

            Satellite:ComputeShadowControl(self.SatellitePhys)
            Satellite:AddVelocity(-1 * self.Entity:GetVelocity() / 8)
        end
    end

    --############ @ Madman07 and Llapp
    function ENT:LowPriorityThink()
        self.Strength = 100

        --
        if (self.Pressed == true) then
            timer.Simple(1, function()
                self.Pressed = false
            end)
        end

        if (self.APC and self.APC:IsValid()) then
            self.APCply = self.APC:GetPassenger(0)

            if (self.APCply and self.APCply:IsValid()) then
                self.APCply:CrosshairEnable()
                self.Rider = true

                if (AGP.KeyPressIN(self, self.APCply, IN_ATTACK2)) then -- AGP: once per click
                    if (not self.Shield and self.StrengthShield == 100 and self.Pressed == false) then
                        self.Shield = self.Entity:SpawnShield()
                        self.Pressed = true
                    elseif (self.Shield and self.Shield:IsValid() and self.Pressed == false) then
                        self.Entity:RemoveShield()
                        self.Pressed = true
                    end
                end

                if (self.APCply:KeyDown(IN_ATTACK)) then end --[[if (not self.Iris.IsActivated and self.Pressed == false ) then
				    self.Entity:SetNetworkedEntity("beamsound",false)
				    self.Iris:Toggle();
					self.Pressed = true;
				elseif (self.Iris.IsActivated  and self.Pressed == false) then
				    self.Entity:SetNetworkedEntity("beamsound",true)
    				self.Iris:Toggle();
					self.Pressed = true;
				end ]] --
                --
            end
        elseif (self.WireActive == 1) then
            if (self.WireShield == 1) then
                if (not self.Shield and self.StrengthShield == 100) then
                    self.Shield = self.Entity:SpawnShield()
                end
            else
                if (self.Shield and self.Shield:IsValid()) then
                    self.Entity:RemoveShield()
                end
            end
        else
            if (self.Shield and self.Shield:IsValid()) then
                self.Entity:RemoveShield()
            end
        end
        --
        --if(self.Gate.Active and not self.Iris.IsActivated)then self.Iris:Toggle(); end
    end

    --############ @  Llapp
    function ENT:Think(ply)
        if IsValid(self.Phys) then
            self.Phys:EnableGravity(false)
        end

        if (IsValid(self.Gate)) then
            if IsValid(self.Gate:GetPhysicsObject()) then
                self.Gate:GetPhysicsObject():EnableGravity(false)
            end
        end

        self.Entity:LowPriorityThink()
        self:NextThink(CurTime() + 0.1)

        return true
    end

    --
    function ENT:PreEntityCopy()
        local dupeInfo = {}

        if IsValid(self.Gate) then
            dupeInfo.Gate = self.Gate:EntIndex()
        end

        duplicator.StoreEntityModifier(self, "AsuranSatDupeInfo", dupeInfo)
        StarGate.WireRD.PreEntityCopy(self)
    end

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        if not Ent.EntityMods then
            self.Entity:Remove()

            return
        end

        local dupeInfo = Ent.EntityMods.AsuranSatDupeInfo

        if dupeInfo.Gate then
            self.Gate = CreatedEntities[dupeInfo.Gate]
            local physic = self.Gate:GetPhysicsObject()

            if physic and physic:IsValid() then
                if (physic:GetMass()) then
                    physic:SetMass(0.000000001)
                end

                physic:EnableMotion(true)
                physic:EnableGravity(false)
                physic:Wake()
            end
        end

        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("stargate_asuran", StarGate.CAP_GmodDuplicator, "Data")
    end
end

--
--