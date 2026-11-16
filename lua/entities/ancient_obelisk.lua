--[[
	Ancient Obelisk
	Copyright (C) 2010 Madman07
]]
--
ENT.Type = "anim"
ENT.Base = "base_anim"

if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.PrintName = "Ancient Obelisk"
ENT.Author = "Madman07, Rafael De Jongh"
ENT.Category = "Ascension Gates"
list.Set("CAP.Entity", ENT.PrintName, ENT)

if CLIENT then

if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
	ENT.Category = SGLanguage.GetMessage("entity_main_cat");
	ENT.PrintName = SGLanguage.GetMessage("entity_obelisk");
end

end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("devices")) then return end
    AddCSLuaFile()

    ENT.Sounds = {
        Transport = Sound("tech/gate_transport_oblisk.wav")
    }

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        self.Entity:SetModel("models/ZsDaniel/ancient-obelisk/obelisk.mdl")
        self.Entity:SetName("Ancient Obelisk")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:SetUseType(SIMPLE_USE)
        self.ObeliskTable = {}
        self.Range = 1000

        -- now global timer, not anymore bugs with few times...
        if (not timer.Exists("CAP_Obelisk_TeleportFunc")) then
            timer.Create("CAP_Obelisk_TeleportFunc", 60, 0, function()
                -- fix: only obelisks that stand at a Stargate can send (a random one without a gate did nothing)
                local obelisks = {}

                for _, v in pairs(ents.FindByClass("ancient_obelisk")) do
                    if (IsValid(v:FindGate())) then table.insert(obelisks, v) end
                end

                if (#obelisks > 1) then
                    table.Random(obelisks):PrepareTeleport()
                end
            end)
        end
    end

    -----------------------------------USE----------------------------------
    -- AGP: E starts the transport at once (CAP had no Use, it only fired every 60 s) and says what is missing
    function ENT:Use(ply)
        if (not IsValid(ply) or not ply:IsPlayer()) then return end

        if (not IsValid(self.Entity:FindGate())) then
            AGP.Say(ply, "agp_obelisk_anc_nogate", "This obelisk needs a Stargate with an address within 500 units.")
            return
        end

        local targets = 0

        for _, v in pairs(ents.FindByClass("ancient_obelisk")) do
            if (v ~= self.Entity and IsValid(v:FindGate())) then targets = targets + 1 end
        end

        if (targets == 0) then
            AGP.Say(ply, "agp_obelisk_anc_notarget", "No other Ancient Obelisk with a Stargate found: place a second obelisk at another gate.")
            return
        end

        if ((self.NextUse or 0) > CurTime()) then
            AGP.Say(ply, "agp_obelisk_anc_busy", "The obelisk is still active, wait a moment.")
            return
        end

        self.NextUse = CurTime() + 20
        AGP.Say(ply, "agp_obelisk_anc_start", "The obelisk activates: everyone within %s units is sent through the gate in a few seconds.", self.Range)
        self:PrepareTeleport()
    end

    -----------------------------------SPAWN----------------------------------
    function ENT:SpawnFunction(ply, tr)
        if (not tr.Hit) then return end
        local PropLimit = GetConVar("CAP_anc_obelisk_max"):GetInt()

        if (ply:GetCount("CAP_anc_obelisk") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_anc_obelisk\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end

        local ang = ply:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y + 180) % 360
        local ent = ents.Create("ancient_obelisk")
        ent:SetAngles(ang)
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        ent:Activate()
        ent.Owner = ply
        local phys = ent:GetPhysicsObject()

        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        ply:AddCount("CAP_anc_obelisk", ent)
        AGP.Hint(ply, "agp_obelisk_anc_hint", "Ancient Obelisk: place it within 500 units of a Stargate, and a second one at another gate. Every 60 s one sends everyone nearby to the other; press E to start it now.")

        return ent
    end

    -----------------------------------THINK----------------------------------
    function ENT:PrepareTeleport()
        self.TargetObelisk = nil

        -- well, be sure that target have stargates and its valid and adress is valid - no more manualy adres seting
        -- fix: pick only among obelisks that have a gate (a random one without a gate ended the whole try)
        self.Entity:FindObelisk()
        local targets = {}

        for _, v in pairs(self.ObeliskTable) do
            if (IsValid(v) and IsValid(v:FindGate())) then table.insert(targets, v) end
        end

        self.TargetObelisk = table.Random(targets)
        if (not IsValid(self.TargetObelisk)) then return end
        self.TargetGate = self.TargetObelisk:FindGate()
        if (not IsValid(self.TargetGate)) then return end

        self.PairGate = self.Entity:FindGate()
        if not IsValid(self.PairGate) then return end -- if there is no gates near current obelisk, then say other obelisk to transport sg-1

        if (self.PairGate.IsOpen or self.PairGate.Dialling or self.TargetGate.IsOpen or self.TargetGate.Dialling) then
            self.PairGate:AbortDialling()
            self.TargetGate:AbortDialling()

            timer.Create(self.Entity:EntIndex() .. "EmergencyAbortGates", 4, 1, function()
                if IsValid(self.PairGate) then
                    self.PairGate:AbortDialling()
                end

                if IsValid(self.TargetGate) then
                    self.TargetGate:AbortDialling()
                end
            end)

            timer.Create(self.Entity:EntIndex() .. "EmergencyAbortGates2", 8, 1, function()
                if IsValid(self.PairGate) then
                    self.PairGate:AbortDialling()
                end

                if IsValid(self.TargetGate) then
                    self.TargetGate:AbortDialling()
                end
            end)

            timer.Create(self.Entity:EntIndex() .. "EmergencyAbortGates3", 12, 1, function()
                if IsValid(self.PairGate) then
                    self.PairGate:AbortDialling()
                end

                if IsValid(self.TargetGate) then
                    self.TargetGate:AbortDialling()
                end
            end)

            timer.Create(self.Entity:EntIndex() .. "DelayedDialGates", 16, 1, function()
                self:PrepareTeleport2()
            end)
        else
            self:PrepareTeleport2()
        end
    end

    function ENT:PrepareTeleport2()
        --if obelisk isnt valid then go back to prepare, otherwise dial it!
        if IsValid(self.TargetObelisk) then
            if (IsValid(self.PairGate) and IsValid(self.TargetGate)) then
                -- fix: a gate in another galaxy/group needs its group glyphs too (like the Ha'tak gate room dials)
                local adr = self.TargetGate:GetGateAddress()
                local mine = self.PairGate.GetGateGroup and self.PairGate:GetGateGroup() or ""
                local grp = self.TargetGate.GetGateGroup and self.TargetGate:GetGateGroup() or ""
                if (grp ~= "" and grp ~= mine) then adr = adr .. (#grp == 3 and grp or grp:sub(1, 1)) end
                self.PairGate:DialGate(adr, true)

                timer.Create(self.Entity:EntIndex() .. "TeleportEffect", 10, 1, function()
                    if IsValid(self) then
                        self:Teleport()
                    end
                end)
            end
        else
            self:PrepareTeleport()
        end
    end

    function ENT:Teleport()
        if IsValid(self.Entity) and IsValid(self.TargetObelisk) and IsValid(self.TargetGate) and IsValid(self.PairGate) then
            local pos = self.Entity:GetPos()
            local oldpos = Vector(0, 0, 5)
            local newpos = Vector(0, 0, 5)
            self.Entity:EmitSound(self.Sounds.Transport, 100, math.random(90, 110))
            self.TargetObelisk:EmitSound(self.Sounds.Transport, 100, math.random(90, 110))
            local deltayaw = self.PairGate:GetAngles().Yaw - self.TargetGate:GetAngles().Yaw

            local function IsPlayerNPC(self, v)
                if IsValid(v) and (v:IsPlayer() or v:IsNPC()) then
                    local dist = (pos - v:GetPos()):Length()

                    if (dist < self.Range) then
                        timer.Create("Transport" .. v:EntIndex(), 0.5, 1, function()
                            if not IsValid(self.Entity) then return end
                            if not IsValid(v) then return end
                            oldpos = self.PairGate:WorldToLocal(v:GetPos()) + Vector(0, 0, 5)
                            newpos = self.TargetGate:LocalToWorld(oldpos)
                            v:SetPos(newpos)

                            if (not v:IsNPC()) then
                                v:SetEyeAngles(v:GetAimVector():Angle() - Angle(0, deltayaw, 0))
                            else
                                v:SetAngles(v:GetAimVector():Angle() - Angle(0, deltayaw, 0))
                            end

                            local fx3 = EffectData()
                            fx3:SetOrigin(v:GetShootPos() + v:GetAimVector() * 10)
                            fx3:SetEntity(v)
                            util.Effect("arthur_cloak", fx3, true)
                        end)

                        local fx = EffectData()
                        fx:SetOrigin(v:GetShootPos() + v:GetAimVector() * 10)
                        fx:SetEntity(v)
                        util.Effect("arthur_cloak", fx, true)
                        local fx2 = EffectData()
                        fx2:SetEntity(v)
                        util.Effect("arthur_cloak_light", fx2, true)
                    end
                end
            end

            for _, v in pairs(ents.FindByClass("player*")) do
                IsPlayerNPC(self, v)
            end

            for _, v in pairs(ents.FindByClass("npc*")) do
                IsPlayerNPC(self, v)
            end
        end

        timer.Create(self.Entity:EntIndex() .. "CloseGates", 1, 1, function()
            if not IsValid(self.Entity) then return end
            if not IsValid(self.PairGate) then return end
            if not IsValid(self.TargetGate) then return end
            self.TargetGate:AbortDialling()
        end)
    end

    function ENT:OnRemove()
        if not IsValid(self.PairGate) then
            self.PairGate = self.Entity:FindGate()
        end

        if timer.Exists(self.Entity:EntIndex() .. "CloseGates") then
            timer.Destroy(self.Entity:EntIndex() .. "CloseGates")
        end

        if timer.Exists("Transport*") then
            timer.Destroy("Transport*")
        end

        if timer.Exists(self.Entity:EntIndex() .. "TeleportEffect") then
            timer.Destroy(self.Entity:EntIndex() .. "TeleportEffect")
        end

        if timer.Exists(self.Entity:EntIndex() .. "TeleportFunc") then
            timer.Destroy(self.Entity:EntIndex() .. "TeleportFunc")
        end

        if timer.Exists(self.Entity:EntIndex() .. "EmergencyAbortGates") then
            timer.Destroy(self.Entity:EntIndex() .. "EmergencyAbortGates")
        end

        if timer.Exists(self.Entity:EntIndex() .. "EmergencyAbortGates2") then
            timer.Destroy(self.Entity:EntIndex() .. "EmergencyAbortGates2")
        end

        if timer.Exists(self.Entity:EntIndex() .. "EmergencyAbortGates3") then
            timer.Destroy(self.Entity:EntIndex() .. "EmergencyAbortGates3")
        end

        if timer.Exists(self.Entity:EntIndex() .. "DelayedDialGates") then
            timer.Destroy(self.Entity:EntIndex() .. "DelayedDialGates")
        end

        if IsValid(self.PairGate) then
            self.PairGate:AbortDialling()
        end

        if IsValid(self.TargetGate) then
            self.TargetGate:AbortDialling()
        end

        if IsValid(self.Entity) then
            self.Entity:Remove()
        end
    end

    -----------------------------------FIND RINGS----------------------------------
    function ENT:FindGate()
        local gate
        local dist = 500
        local pos = self.Entity:GetPos()

        for _, v in pairs(ents.FindByClass("stargate_*")) do
            if (v.IsGroupStargate and v:GetClass() ~= "stargate_orlin" and v:GetGateAddress() ~= "") then
                local sg_dist = (pos - v:GetPos()):Length()

                if (dist >= sg_dist) then
                    dist = sg_dist
                    gate = v
                end
            end
        end

        return gate
    end

    function ENT:FindObelisk()
        self.ObeliskTable = {}

        for _, v in pairs(ents.FindByClass("ancient_obelisk")) do
            if (not table.HasValue(self.ObeliskTable, v) and v ~= self.Entity) then
                table.insert(self.ObeliskTable, v)
            end
        end
    end

    function ENT:PreEntityCopy()
        local dupeInfo = {}

        if IsValid(self.Entity) then
            dupeInfo.EntID = self.Entity:EntIndex()
        end

        duplicator.StoreEntityModifier(self, "AncientObeliskDupeInfo", dupeInfo)
    end

    duplicator.RegisterEntityModifier("AncientObeliskDupeInfo", function() end)

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:Remove()

            return
        end

        local PropLimit = GetConVar("CAP_anc_obelisk_max"):GetInt()

        if (IsValid(ply)) then
            if (ply:GetCount("CAP_anc_obelisk") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_anc_obelisk\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:Remove()

                return
            end

            ply:AddCount("CAP_anc_obelisk", self.Entity) -- fix: was counted as a Sodan obelisk
            self.Owner = ply
        end

        local dupeInfo = Ent.EntityMods.AncientObeliskDupeInfo

        if dupeInfo.EntID then
            self.Entity = CreatedEntities[dupeInfo.EntID]
        end
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("ancient_obelisk", StarGate.CAP_GmodDuplicator, "Data")
    end
end