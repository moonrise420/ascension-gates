--[[
	Ha'tak control crystal (Ascension Gates)
	Hidden somewhere in a Ha'tak interior when the admin setting agp_hatak_hijack is 1. A stranger picks it up (E) and
	inserts it in the crystal slot on the pel'tak (40 s at the slot): the ship then obeys him and his friends. The
	original crew takes it out again at the slot: control comes back and the crystal is hidden again. (agp_hatak)
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Control crystal"
ENT.Author = "Ascension Gates"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetModel("models/agp/hatak/props/control_crystal.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		self:SetUseType(SIMPLE_USE)
	end

	function ENT:Use(ply)
		local ship = self.AGPShip
		if (not IsValid(ship) or not IsValid(ply) or not ply:IsPlayer() or self.Inserted) then return end
		ship:CrystalPickUp(ply)
	end
end

if CLIENT then
	local glow = Material("sprites/light_glow02_add")
	function ENT:Draw() self:DrawModel() end
	function ENT:DrawTranslucent()
		render.SetMaterial(glow)
		local s = 18 + math.sin(CurTime() * 3) * 4
		render.DrawSprite(self:WorldSpaceCenter(), s, s, Color(255, 60, 40, 200))
	end
end
