--[[
	Goa'uld power core column (Ascension Gates)
	The gold column of a Goa'uld power core (model power_core: "Futuristic Pillar" by creo14, CREDITS.md). Stands on
	the power hub (agp_goauld_power_hub) or in the Ha'tak engine room (agp_hatak). It pulses with a warm light;
	the stronger the core's power (SetPower 0..1), the brighter. No power: dark.
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Goa'uld power core"
ENT.Author = "Ascension Gates"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "Power")
end

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetModel("models/agp/hatak/props/power_core.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		self:SetUseType(SIMPLE_USE)
		self:SetPower(1)
	end

	function ENT:Use(ply)
		if (self.OnUse and IsValid(ply) and ply:IsPlayer()) then self:OnUse(ply) end
	end
end

if CLIENT then
	local glow = Material("sprites/light_glow02_add")
	function ENT:Pulse() return 0.6 + 0.4 * math.sin(CurTime() * 2.2 + self:EntIndex()) end   -- slow breathing, 0.2 .. 1
	function ENT:Draw() self:DrawModel() end
	function ENT:DrawTranslucent()
		local p = self:GetPower()
		if (p <= 0.01) then return end
		local f = self:Pulse() * math.Clamp(p, 0, 1.3)   -- a ZPM in the Ha'tak hub: 130 %
		render.SetMaterial(glow)
		local up, h = self:GetUp(), self:OBBMaxs().z
		-- a ring of light around the foot, a soft glow at the top and along the column's four sides
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			local pos = self:GetPos() + up * 12 + self:GetForward() * math.cos(a) * 52 + self:GetRight() * math.sin(a) * 52
			render.DrawSprite(pos, 40 * f + 10, 40 * f + 10, Color(255, 170, 60, 200 * f))
		end
		render.DrawSprite(self:GetPos() + up * (h + 8), 120 * f + 20, 120 * f + 20, Color(255, 180, 80, 160 * f))
		for _, d in ipairs({ self:GetForward(), -self:GetForward(), self:GetRight(), -self:GetRight() }) do
			for _, z in ipairs({ 0.3, 0.55, 0.8 }) do
				render.DrawSprite(self:GetPos() + up * h * z + d * 52, 110 * f, 110 * f, Color(255, 160, 60, 130 * f))
			end
		end
	end
	function ENT:Think()
		local p = self:GetPower()
		if (p > 0.01) then
			local dl = DynamicLight(self:EntIndex())
			if (dl) then
				dl.pos = self:GetPos() + self:GetUp() * (self:OBBMaxs().z * 0.5)
				dl.r, dl.g, dl.b = 255, 160, 60
				dl.brightness = 3 * self:Pulse() * math.Clamp(p, 0, 1.3)
				dl.decay = 1000
				dl.size = 520
				dl.dietime = CurTime() + 0.2
			end
		end
		self:SetNextClientThink(CurTime())
		return true
	end
end
