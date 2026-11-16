--[[
	Anti-phase device (Ascension Gates)
	A small field generator: while it is on, no Tollan phase device (agp_tollan_phase) works within PhaseRadius units,
	neither for the start nor for the end point of a phase.
	Use (E) toggles it. Wire (if installed): input On (1 on / 0 off), output On.
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then StarGate.LifeSupportAndWire(ENT) end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = AGP.L("agp_ent_anti_phase", "Anti-phase device")
ENT.Author = "Ascension Gates"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Anti-phase device"
ENT.Spawnable = false   -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.PhaseRadius = 600
list.Set("CAP.Entity", ENT.PrintName, ENT)

if CLIENT and SGLanguage ~= nil and SGLanguage.GetMessage ~= nil then
    ENT.Category = SGLanguage.GetMessage("entity_main_cat")
end

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "On")
end

if SERVER then
    AddCSLuaFile()

    function ENT:SpawnFunction(ply, tr)
        if (not tr.Hit) then return end
        local e = ents.Create("agp_anti_phase")
        if (not IsValid(e)) then return end
        e:SetPos(tr.HitPos + tr.HitNormal * 4)
        e:SetAngles(Angle(0, ply:GetAimVector():Angle().y + 180, 0))
        e:Spawn(); e:Activate()
        e.Owner = ply
        if (e.CPPISetOwner) then e:CPPISetOwner(ply) end
        local ph = e:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(false) end
        return e
    end

    function ENT:Initialize()
        self:SetModel("models/props_lab/reciever01b.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        local ph = self:GetPhysicsObject(); if (IsValid(ph)) then ph:Wake() end
        self:SetOn(false)
        if (self.CreateWireInputs) then
            self:CreateWireInputs("On")
            self:CreateWireOutputs("On")
        end
    end

    function ENT:SetOnState(on, ply)
        local was = self:GetOn()
        self:SetOn(on)
        if (self.SetWire) then self:SetWire("On", on and 1 or 0) end
        if (was == on) then return end
        self:EmitSound(on and "buttons/combine_button1.wav" or "buttons/combine_button2.wav", 65, on and 110 or 80)
        if (on) then
            self.Hum = self.Hum or CreateSound(self, "ambient/machines/combine_shield_loop3.wav")
            if (self.Hum) then self.Hum:PlayEx(0.25, 140) end
        elseif (self.Hum) then
            self.Hum:Stop()
        end
        if (IsValid(ply) and ply:IsPlayer() and AGP and AGP.Say) then
            if (on) then
                AGP.Say(ply, "agp_anti_phase_on", "Anti-phase device on: no phase device works within %s units.", self.PhaseRadius)
            else
                AGP.Say(ply, "agp_anti_phase_off", "Anti-phase device off.")
            end
        end
    end

    function ENT:Use(ply)
        self:SetOnState(not self:GetOn(), ply)
    end

    function ENT:TriggerInput(name, v)
        if (name == "On") then self:SetOnState(v ~= 0) end
    end

    local baseRemove = ENT.OnRemove
    function ENT:OnRemove()
        if (self.Hum) then self.Hum:Stop() end
        if (baseRemove) then baseRemove(self) end
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")

    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        if (not self:GetOn()) then return end
        local a = 140 + 60 * math.sin(CurTime() * 3 + self:EntIndex())
        render.SetMaterial(glow)
        render.DrawSprite(self:LocalToWorld(self:OBBCenter()) + self:GetUp() * (self:OBBMaxs().z - self:OBBCenter().z + 2), 18, 18, Color(255, 140, 90, a))
    end
end
