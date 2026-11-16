--[[
	Ha'tak interior prop (Ascension Gates)
	A still-standing furnishing in a ship interior (agp_hatak): consoles, throne, chests, door panels.
	The ship sets the model and what E does (OnUse); props never move (frozen, no physics contacts).
	Models: models/agp/hatak/props (Sketchfab, see CREDITS.md).
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ha'tak prop"
ENT.Author = "Ascension Gates"
ENT.Spawnable = false

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetModel(self.PropModel or "models/agp/hatak/props/naq_chest.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		self:SetUseType(SIMPLE_USE)
	end

	function ENT:Use(ply)
		if (self.OnUse and IsValid(ply) and ply:IsPlayer()) then self:OnUse(ply) end
	end
end

if CLIENT then
	function ENT:Draw() self:DrawModel() end
end
