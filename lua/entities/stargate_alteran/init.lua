--[[
	Stargate (Alteran), server - Ascension Gates' own code (2026-11-06). Everything else comes from CAP's Stargate SG1
	gate (the base class): only our models and the class's own spawning and duplicator entry are set here.
]]
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("base")) then return end
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Models = {
	Base = "models/agp/gates/agp_alteran_base.mdl",
	Ring = "models/agp/gates/agp_alteran_ring.mdl",
	Chevron = "models/agp/gates/agp_alteran_chevron.mdl",
}

-- like the SG1 gate's, but straight on to the gate base: the SG1 gate calls self.BaseClass.Initialize, and for a
-- class built on the SG1 gate that is the SG1 gate's own Initialize again (endless, a stack overflow)
function ENT:Initialize()
	util.PrecacheModel(self.Models.Base)
	util.PrecacheModel(self.Models.Chevron)
	util.PrecacheModel(self.Models.Ring)
	self:SetModel(self.Models.Base)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	baseclass.Get("stargate_base").Initialize(self)
	self.DiallingSymbol = ""
	self.RingSymbol = ""
	self.RingSpeed = 0
	self.RingDir = -1
	self:AddRing()
	self:AddChevron()
	self.IsConcept = false
	self.RingInbound = false
	hook.Add("Tick", self, self.RingTickSG1)
	self.TargetGate = nil
	-- tick rate relation for the dialling, as the SG1 gate caches it
	self.tickRateRelation = 66.666668156783 / (1 / engine.TickInterval())
	self.tickSlowDial = self:tickRateCalc(17, 0.4)
	self.tickSlowerDial = self:tickRateCalc(17, 2)
end

-- like the SG1 gate's, but it spawns this class (the base's spawns an SG1 gate)
function ENT:SpawnFunction(p, t)
	if (not t.Hit) then return end
	local e = ents.Create("stargate_alteran")
	e:SetPos(t.HitPos + Vector(0, 0, 90))
	e:Spawn()
	e:Activate()
	local ang = p:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y + 180) % 360
	e:SetAngles(ang)
	e:SetGateGroup("M@")
	e:SetLocale(true)
	e:CartersRamps(t)
	e:SetWire("Dialing Mode", -1)
	return e
end

if (StarGate and StarGate.CAP_GmodDuplicator) then
	duplicator.RegisterEntityClass("stargate_alteran", StarGate.CAP_GmodDuplicator, "Data")
end
