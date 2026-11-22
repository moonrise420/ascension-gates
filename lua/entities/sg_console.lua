--[[
	Stargate Console - Ascension Gates' own code; no Evolution Addon Pack code left (the class name stays for saves and
	dupes). A console that lights up (skin 1) when a player comes within 400 units (auto mode), or a Wire button:
	USE switches it on and off and leaves auto mode. Spawned with the console tool (sg_console). Wire inputs:
	"Disable Auto-mode", "Pressed", "Disable Use"; output: "Active".
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then StarGate.LifeSupportAndWire(ENT) end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Stargate Console"
ENT.Author = "Ascension Gates"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Stargate Console"
ENT.Spawnable = false
ENT.AdminSpawnable = false

local NEAR = 400

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("extra")) then return end
    AddCSLuaFile()

    function ENT:Initialize()
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self.Auto = true
        self.On = false
        if (self.CreateWireInputs) then self:CreateWireInputs("Disable Auto-mode", "Pressed", "Disable Use") end
        if (self.CreateWireOutputs) then self:CreateWireOutputs("Active") end
    end

    function ENT:Switch(on)
        if (self.On == on) then return end
        self.On = on
        self:SetSkin(on and 1 or 0)
        if (self.SetWire) then self:SetWire("Active", on and 1 or 0) end
    end

    -- auto mode: lit while somebody is near
    function ENT:Think()
        if (self.Auto) then self:Switch(StarGate.FindPlayer(self:GetPos(), NEAR) and true or false) end
        self:NextThink(CurTime() + 0.5)
        return true
    end

    function ENT:TriggerInput(k, v)
        if (k == "Pressed") then
            if (not self.Auto) then self:Switch(v ~= 0) end
        elseif (k == "Disable Auto-mode") then
            self.Auto = v <= 0
        end
    end

    function ENT:Use()
        if (self.GetWire and (self:GetWire("Disable Use") or 0) > 0) then return end
        self.Auto = false
        self:Switch(not self.On)
    end
end
