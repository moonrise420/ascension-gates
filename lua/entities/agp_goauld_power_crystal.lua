--[[
	Goa'uld power crystal (Ascension Gates)
	Holds energy; gives it off only in a Goa'uld power hub (agp_goauld_power_hub), as a ZPM does in its hub. Bring it
	to a hub arm (gravity gun / physgun, touch) or spawn it with the tool on the hub; E on a crystal in a hub takes it
	out again. Capacity: StarGate.CFG goauld_power_crystal / capacity.
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Goa'uld Power Crystal"
ENT.Author = "Ascension Gates"
ENT.Category = "Ascension Gates"
ENT.Spawnable = false   -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.IsGoauldPowerCrystal = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Charge")   -- 0..1
	self:NetworkVar("Bool", 0, "InHub")
end

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetModel("models/agp/hatak/props/power_crystal.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetMass(8); ph:Wake() end
		self:SetUseType(SIMPLE_USE)
		local cap = StarGate and StarGate.CFG and StarGate.CFG:Get("goauld_power_crystal", "capacity", 20000000) or 20000000
		self.MaxEnergy = cap
		self.Energy = self.Energy or cap
		self:SetCharge(self.Energy / self.MaxEnergy)
	end

	function ENT:SpawnFunction(ply, tr, cls)
		if (not tr.Hit) then return end
		local e = ents.Create(cls)
		e:SetPos(tr.HitPos + tr.HitNormal * 6)
		e:SetAngles(Angle(0, ply:EyeAngles().y, 0))
		e:Spawn(); e:Activate()
		return e
	end

	function ENT:SetEnergy(v)
		self.Energy = math.Clamp(v, 0, self.MaxEnergy)
		self:SetCharge(self.Energy / self.MaxEnergy)
		if (self.Energy <= 0) then self:SetMaterial("models/debug/debugwhite"); self:SetColor(Color(45, 38, 34)) end   -- empty: dull
	end

	function ENT:Use(ply)
		local hub = self:GetParent()
		if (IsValid(hub) and hub.EjectCrystal) then hub:EjectCrystal(self, ply) end
	end
end

if CLIENT then
	local glow = Material("sprites/light_glow02_add")
	function ENT:Draw() self:DrawModel() end
	function ENT:DrawTranslucent()
		local c = self:GetCharge()
		if (c <= 0) then return end
		render.SetMaterial(glow)
		local s = (self:GetInHub() and 30 or 18) * (0.85 + 0.15 * math.sin(CurTime() * 2 + self:EntIndex())) * (0.4 + 0.6 * c)
		render.DrawSprite(self:WorldSpaceCenter(), s, s, Color(255, 180, 70, 190))
	end
end
