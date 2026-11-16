--[[
	Ha'tak power crystal (Ascension Gates)
	The crystals of the engine room (agp_hatak): three on the power core's hub feed the whole ship, three in each tray
	at the back wall run one system (weapons, hyperdrive, sublight engines), spares wait in the rack on the side wall.
	E pulls a crystal out and you carry it; E near a free slot puts it in. Hits on the hull can burn crystals out
	(dark, no power); a burnt crystal recharges in the spare rack.
	Data crystals (blue, SetData(true) before Spawn): the computer core's racks (rings, doors, sensors, communication).
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Power crystal"
ENT.Author = "Ascension Gates"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Burnt")
	self:NetworkVar("Bool", 1, "Data")
end

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetModel(self:GetData() and "models/agp/hatak/props/data_crystal.mdl" or "models/agp/hatak/props/power_crystal.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		self:SetUseType(SIMPLE_USE)
		self:UpdateLook()
	end

	function ENT:UpdateLook()
		if (self:GetBurnt()) then self:SetMaterial("models/debug/debugwhite"); self:SetColor(Color(45, 38, 34))   -- dull, no glow (the texture glows by itself)
		else self:SetMaterial(""); self:SetColor(Color(255, 255, 255)) end
	end

	function ENT:Use(ply)
		local ship = self.AGPShip
		if (IsValid(ship) and IsValid(ply) and ply:IsPlayer()) then ship:PowerCrystalTake(ply, self) end
	end
end

if CLIENT then
	local glow = Material("sprites/light_glow02_add")
	function ENT:Draw() self:DrawModel() end
	function ENT:DrawTranslucent()
		if (self:GetBurnt()) then return end
		render.SetMaterial(glow)
		local s = 14 + math.sin(CurTime() * 2 + self:EntIndex()) * 3
		render.DrawSprite(self:WorldSpaceCenter(), s, s, self:GetData() and Color(90, 170, 255, 180) or Color(255, 180, 70, 180))
	end
end
