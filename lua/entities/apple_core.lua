--[[
	Apple Core
	Copyright (C) 2011 Madman07
]]
--
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Apple Core"
ENT.Author = "assassin21, Rafael De Jongh, Madman07"
ENT.Category = "Ascension Gates"
if CLIENT then
	if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
	ENT.Category = SGLanguage.GetMessage("entity_main_cat");
	end
end
ENT.WireDebugName = "Apple Core"
list.Set("CAP.Entity", ENT.PrintName, ENT)

if (Environments) then
    ENT.IsNode = false
else
    ENT.IsNode = true
end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("devices")) then return end
    AddCSLuaFile()

    -----------------------------------INIT----------------------------------
    function ENT:Initialize()
        self.Entity:SetName("Apple Core")
        self.Entity:SetModel("models/Assassin21/apple_core/core.mdl")
        self.Entity:PhysicsInit(SOLID_VPHYSICS)
        self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
        self.Entity:SetSolid(SOLID_VPHYSICS)
        self.Entity:SetUseType(SIMPLE_USE)
        self.HaveRD3 = false
        self.Weapons = {}
        self.WireInputs = {}
        self.WireActive = 0 
        self.WireFire = 0
        self.WireVector = nil
        self.WireEntity = nil


        --RD3 needed!
        if (CAF and CAF.GetAddon("Resource Distribution")) then
            self.HaveRD3 = true
        end

        -- AGP: the Wire inputs always (they steer the linked weapons); they were made only together with CAF's
        -- Resource Distribution, so without it weapons linked with the Weapon Link Tool could never be fired
        if (WireAddon) then
            self.Inputs = WireLib.CreateInputs(self.Entity, {"Fire", "Active", "Vector [VECTOR]", "Entity [ENTITY]"})
        end

        -- Life Support
        if self.HaveRD3 then
            if (WireAddon) then
                self.Outputs = WireLib.CreateOutputs(self.Entity, {"Water", "Steam", "Energy", "ZPH", "Oxygen"})

            end

            self.netid = CAF.GetAddon("Resource Distribution").CreateNetwork(self)
            self:SetNWInt("netid", self.netid)
            self.range = 2048
            self:SetNWInt("range", self.range)
            self.RDEnt = CAF.GetAddon("Resource Distribution")
        end
    end

    -----------------------------------SPAWN----------------------------------
    function ENT:SpawnConsole(p)
        local data = self:GetAttachment(self:LookupAttachment("Console"))
        if (not (data and data.Pos and data.Ang)) then return end
        local ent = ents.Create("destiny_console")
        ent:SetAngles(data.Ang - Angle(0, 90, 0))
        ent:SetPos(data.Pos)
        ent:SetParent(self.Entity)
        ent:Spawn()
        ent:SetModel("models/Iziraider/destiny_dhd/body2.mdl")
        ent.Core = self
        ent.HaveCore = true
        ent.Owner = self.Owner
        self.Console = ent
        self:SetNetworkedEntity("Console", self.Console)
        ent:SetNWBool("Core", true)

        if CPPI and IsValid(p) and ent.CPPISetOwner then
            ent:CPPISetOwner(p)
        end

        constraint.Weld(ent, self, 0, 0, 0, true)
    end

    -- AGP: removed weapons are skipped (writing to a removed entity is a Lua error, so one removed weapon stopped
    -- all the others)
    function ENT:TriggerInput(variable, value)
        if (variable == "Active") then
            self.WireActive = value
            for k,v in pairs(self.Weapons) do
                if IsValid(v) then v.WireActive = value end
            end
        elseif (variable == "Fire") then
            self.WireFire = value
            for k,v in pairs(self.Weapons) do
                if IsValid(v) then v.WireShoot = value end
            end
        elseif (variable == "Vector") then
            self.WireVector = value
            for k,v in pairs(self.Weapons) do
                if IsValid(v) then v.WireVec = value end
            end
        elseif (variable == "Entity") then
            self.WireEntity = value
            for k,v in pairs(self.Weapons) do
                if IsValid(v) then v.WireEnt = value end
            end
        end
    end

    function ENT:CountWeaps()
        for k,v in pairs(self.Weapons) do
            if IsValid(v) then
                v.WireActive = self.WireActive
                v.WireShoot = self.WireFire
                v.WireVec = self.WireVector
                v.WireEnt = self.WireEntity
            end
        end
    end

    function ENT:ClearWeaps()
        for k,v in pairs(self.Weapons) do
            if IsValid(v) then
                v.WireActive = 0
                v.WireShoot = 0
                v.WireVec = nil
                v.WireEnt = nil
            end
        end
        self.Weapons = {}
    end

    function ENT:UpdateWireInputs()
        --         --for k,v in pairs(v) do
        --         --end


        --         WireLib.AdjustSpecialInputs(self,v.." [NORMAL]") end
        --         WireLib.AdjustSpecialInputs(self,v.." [NORMAL]") end
        --         WireLib.AdjustSpecialInputs(self,v.." [ENTITY]") end
        --         WireLib.AdjustSpecialInputs(self,v.." [VECTOR]") end


    end

    function ENT:SpawnFunction(ply, tr)
        if (not tr.Hit) then return end
        local PropLimit = GetConVar("CAP_applecore_max"):GetInt()

        if (ply:GetCount("CAP_applecore") + 1 > PropLimit) then
            ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_app_core\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")

            return
        end

        local ang = ply:GetAimVector():Angle()
        ang.p = 0
        ang.r = 0
        ang.y = (ang.y - 60) % 360
        local ent = ents.Create("apple_core")
        ent:SetAngles(ang)
        ent:SetPos(tr.HitPos)
        ent:Spawn()
        ent:Activate()
        ent.Owner = ply
        ent:SpawnConsole(ply)
        local phys = ent:GetPhysicsObject()

        if IsValid(phys) then
            phys:EnableMotion(false)
        end

        ply:AddCount("CAP_applecore", ent)

        return ent
    end

    -----------------------------------RESOURCE DISTRIBUTION----------------------------------
    function ENT:Think()
        if self.HaveRD3 and self.RDEnt.GetNetTable then
            local nettable = self.RDEnt.GetNetTable(self.netid)

            if nettable.resources then
                if nettable.resources.water then
                    Wire_TriggerOutput(self.Entity, "Water", nettable.resources.water.value)
                end

                if nettable.resources.steam then
                    Wire_TriggerOutput(self.Entity, "Steam", nettable.resources.steam.value)
                end

                if nettable.resources.energy then
                    Wire_TriggerOutput(self.Entity, "Energy", nettable.resources.energy.value)
                end

                if nettable.resources.ZPH then
                    Wire_TriggerOutput(self.Entity, "ZPH", nettable.resources.ZPH.value)
                end

                if nettable.resources.oxygen then
                    Wire_TriggerOutput(self.Entity, "Oxygen", nettable.resources.oxygen.value)
                end
            end

            local nettable = CAF.GetAddon("Resource Distribution").GetNetTable(self.netid)

            if table.Count(nettable) > 0 then
                local entities = nettable.entities

                if table.Count(entities) > 0 then
                    for k, ent in pairs(entities) do
                        if ent and IsValid(ent) then
                            local pos = ent:GetPos()

                            if pos:Distance(self:GetPos()) > self.range then
                                CAF.GetAddon("Resource Distribution").Unlink(ent)
                                self:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
                                ent:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
                            end
                        end
                    end
                end

                local cons = nettable.cons

                if table.Count(cons) > 0 then
                    for k, v in pairs(cons) do
                        local tab = CAF.GetAddon("Resource Distribution").GetNetTable(v)

                        if tab and table.Count(tab) > 0 then
                            local ent = tab.nodeent

                            if ent and IsValid(ent) then
                                local pos = ent:GetPos()
                                local range = pos:Distance(self:GetPos())

                                if range > self.range and range > ent.range then
                                    CAF.GetAddon("Resource Distribution").UnlinkNodes(self.netid, ent.netid)
                                    self:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
                                    ent:EmitSound("physics/metal/metal_computer_impact_bullet" .. math.random(1, 3) .. ".wav", 500)
                                end
                            end
                        end
                    end
                end
            end
        end

        self.Entity:NextThink(CurTime() + 1)

        return true
    end

    function ENT:OnRemove()
        if IsValid(self.Console) then
            self.Console:Remove()
        end

        for k,v in pairs(self.Weapons or {}) do
            if IsValid(v) then -- AGP: skip removed weapons
                v.WireActive = 0
                v.WireShoot = 0
                v.WireVec = nil
                v.WireEnt = nil
            end
        end

        if IsValid(self.Light) then
            self.Light:Fire("TurnOn", "", "0")
            self.Light:Remove()
            self.Light = nil
        end

        if self.HaveRD3 and CAF then
            CAF.GetAddon("Resource Distribution").UnlinkAllFromNode(self.netid)
            CAF.GetAddon("Resource Distribution").RemoveRDEntity(self)
        end

        -- AGP: Wire clean-up whenever it has ports (they exist without RD now)
        if not (WireAddon == nil) and (self.Inputs or self.Outputs) then
            Wire_Remove(self.Entity)
        end

        if (IsValid(self.Console)) then
            self.Console:Remove()
        end

        if timer.Exists("Light" .. self:EntIndex()) then
            timer.Destroy("Light" .. self:EntIndex())
        end

        self:Remove()
    end

    function ENT:SetCustomNodeName(name)
    end

    function ENT:SetActive(value, caller)
    end

    function ENT:Repair()
    end

    function ENT:SetRange(range)
    end

    function ENT:OnRestore()
        if not (WireAddon == nil) then
            Wire_Restored(self.Entity)
        end
    end

    function ENT:PreEntityCopy()
        local dupeInfo = {}

        if IsValid(self.Entity) then
            dupeInfo.EntID = self.Entity:EntIndex()
        end

        if IsValid(self.Console) then
            dupeInfo.Console = self.Console:EntIndex()
        end

        duplicator.StoreEntityModifier(self, "APDupeInfo", dupeInfo)
        StarGate.WireRD.PreEntityCopy(self)
    end

    duplicator.RegisterEntityModifier("APDupeInfo", function() end)

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        local dupeInfo = Ent.EntityMods.APDupeInfo

        if dupeInfo.Console then
            self.Console = CreatedEntities[dupeInfo.Console]
            self:SetNWEntity("Console", self.Console)
            self.Console.Core = self
            self.Console.HaveCore = true
            self.Console.Owner = self.Owner
            self:SetNetworkedEntity("Console", self.Console)
            self.Console:SetNWBool("Core", true)
        end

        if (StarGate.NotSpawnable(Ent:GetClass(), ply)) then
            self.Entity:OnRemove()

            return
        end

        local PropLimit = GetConVar("CAP_applecore_max"):GetInt()

        if (IsValid(ply)) then
            if (ply:GetCount("CAP_applecore") + 1 > PropLimit) then
                ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_app_core\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )")
                self.Entity:OnRemove()

                return
            end
        end

        if dupeInfo.EntID then
            self.Entity = CreatedEntities[dupeInfo.EntID]
        end

        if (IsValid(ply)) then
            self.Owner = ply
            ply:AddCount("CAP_applecore", self.Entity)
        end

        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("apple_core", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    ENT.RenderGroup = RENDERGROUP_BOTH
    ENT.HoloText = surface.GetTextureID("VGUI/resources_hud/sgu_screen")

    local font = {
        font = "coolvetica",
        size = 50,
        weight = 400,
        antialias = true,
        additive = false
    }

    surface.CreateFont("AppleCore", font)

    function ENT:Initialize()
        self.Emitter = ParticleEmitter(self.Entity:GetPos())
        self.Wire = 0
        self.NameA = ""
        self.NameB = ""
        self.NameC = ""
        self.NameD = ""
        self.NameE = ""
        self.NameF = ""
        self.NameG = ""
        self.NameH = ""
        self.ValueA = 0
        self.ValueB = 0
        self.ValueC = 0
        self.ValueD = 0
        self.ValueE = 0
        self.ValueF = 0
        self.ValueG = 0
        self.ValueH = 0
        self.SmokeTime = CurTime()
    end

    function ENT:Think()
        if IsValid(self.Console) then
            self.Wire = self.Console:GetNetworkedInt("Wire", 0)
            self.NameA = self.Console:GetNWString("NameA", "")
            self.NameB = self.Console:GetNWString("NameB", "")
            self.NameC = self.Console:GetNWString("NameC", "")
            self.NameD = self.Console:GetNWString("NameD", "")
            self.NameE = self.Console:GetNWString("NameE", "")
            self.NameF = self.Console:GetNWString("NameF", "")
            self.NameG = self.Console:GetNWString("NameG", "")
            self.NameH = self.Console:GetNWString("NameH", "")
            self.ValueA = self.Console:GetNWInt("ValueA", 0)
            self.ValueB = self.Console:GetNWInt("ValueB", 0)
            self.ValueC = self.Console:GetNWInt("ValueC", 0)
            self.ValueD = self.Console:GetNWInt("ValueD", 0)
            self.ValueE = self.Console:GetNWInt("ValueE", 0)
            self.ValueF = self.Console:GetNWInt("ValueF", 0)
            self.ValueG = self.Console:GetNWInt("ValueG", 0)
            self.ValueH = self.Console:GetNWInt("ValueH", 0)
        else
            self.Console = self:GetNWEntity("Console")
        end

        if (StarGate.VisualsMisc("cl_applecore_smoke") and self.Wire > 0 and CurTime() > self.SmokeTime) then
            self.SmokeTime = CurTime() + 0.2
            self:Smoke()
        end

        if (StarGate.VisualsMisc("cl_applecore_light") and self.Wire > 0) then
            if not self.Light then
                local dlight = DynamicLight(self:EntIndex())

                if dlight then
                    dlight.Pos = self.Entity:LocalToWorld(Vector(0, 0, 100))
                    dlight.r = 255
                    dlight.g = 255
                    dlight.b = 255
                    dlight.Brightness = 7
                    dlight.Decay = 0
                    dlight.Size = 150
                    dlight.DieTime = CurTime() + 0.25
                    self.Light = dlight

                    timer.Create("Light" .. self:EntIndex(), 0.1, 0, function()
                        if IsValid(self.Entity) then
                            self.Light.Pos = self.Entity:LocalToWorld(Vector(0, 0, 100))
                            self.Light.DieTime = CurTime() + 0.25
                        end
                    end)
                end
            end
        else
            if timer.Exists("Light" .. self:EntIndex()) then
                timer.Destroy("Light" .. self:EntIndex())
            end

            self.Light = nil
        end
    end

    function ENT:Draw()
        self.Entity:DrawModel()

        if IsValid(self.Console) then
            if (self.Wire > 0) then
                local col = Color(255, 255, 255)
                local factor = 5
                local data = self:GetAttachment(self:LookupAttachment("Screen2"))
                if not (data and data.Pos and data.Ang) then return end
                local ang = data.Ang
                ang:RotateAroundAxis(data.Ang:Forward(), 90)

                for i = 1, 2 do
                    cam.Start3D2D(data.Pos, ang, 0.1)
                    surface.SetTexture(self.HoloText)
                    surface.SetDrawColor(Color(255, 255, 255, 255))
                    surface.DrawTexturedRect(-50 * factor, -30 * factor, 100 * factor, 60 * factor)
                    draw.SimpleText(self.NameA, "AppleCore", -10 * factor, -19 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.ValueA, "AppleCore", 25 * factor, -19 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.NameB, "AppleCore", -10 * factor, -8 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.ValueB, "AppleCore", 25 * factor, -8 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.NameC, "AppleCore", -10 * factor, 6 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.ValueC, "AppleCore", 25 * factor, 6 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.NameD, "AppleCore", -10 * factor, 18 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.ValueD, "AppleCore", 25 * factor, 18 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                    ang:RotateAroundAxis(self:GetAngles():Up(), 180)
                end

                local data2 = self:GetAttachment(self:LookupAttachment("Screen1"))
                if not (data2 and data2.Pos and data2.Ang) then return end
                local ang2 = data2.Ang
                ang2:RotateAroundAxis(data2.Ang:Forward(), 90)

                for i = 1, 2 do
                    cam.Start3D2D(data2.Pos, ang2, 0.1)
                    surface.SetTexture(self.HoloText)
                    surface.SetDrawColor(Color(255, 255, 255, 255))
                    surface.DrawTexturedRect(-50 * factor, -30 * factor, 100 * factor, 60 * factor)
                    draw.SimpleText(self.NameE, "AppleCore", -10 * factor, -19 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.ValueE, "AppleCore", 25 * factor, -19 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.NameF, "AppleCore", -10 * factor, -8 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.ValueF, "AppleCore", 25 * factor, -8 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.NameG, "AppleCore", -10 * factor, 6 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.ValueG, "AppleCore", 25 * factor, 6 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.NameH, "AppleCore", -10 * factor, 18 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(self.ValueH, "AppleCore", 25 * factor, 18 * factor, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                    ang2:RotateAroundAxis(self:GetAngles():Up(), 180)
                end
            end
        end
    end

    function ENT:Smoke()
        local roll = math.Rand(-90, 90)
        local ran = math.Rand(160, 200)
        local selfpos = self.Entity:GetPos()
        local up = self.Entity:GetUp() * 110
        local particle = self.Emitter:Add("Llapp/particles/Smoke01_Main", selfpos + up)
        particle:SetDieTime(3)
        particle:SetStartAlpha(50)
        particle:SetEndAlpha(10)
        particle:SetStartSize(40)
        particle:SetEndSize(40)
        particle:SetColor(ran, ran, ran)
        particle:SetRoll(roll)
        particle:SetRollDelta(1)
        particle:SetAirResistance(20)
        particle:SetGravity(Vector(0, 0, -25))
    end
end