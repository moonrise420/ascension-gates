--[[
	Ha'tak console (Ascension Gates)
	A Goa'uld wall console built into the Ha'tak (computer core: self-destruct). Not in the spawn menu; the ship gives
	it its job through ENT.OnUse(console, player). Shows the countdown (networked "Countdown" end time) on its face.
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ha'tak Console"
ENT.Author = "Ascension Gates"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

if SERVER then
	AddCSLuaFile()
	function ENT:Initialize()
		self:SetModel("models/Madman07/ring_panel/goauld_panel.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
	end
	function ENT:Use(ply)
		if (self.OnUse and IsValid(ply) and ply:IsPlayer()) then self:OnUse(ply) end
	end
end

if CLIENT then
	function ENT:DrawTranslucent()
		local t = self:GetNWFloat("Countdown", 0)
		local label = self:GetNWString("Label", "")
		if (label == "" and t == 0) then return end
		local ang = self:GetAngles(); ang:RotateAroundAxis(ang:Up(), 90); ang:RotateAroundAxis(ang:Forward(), 90)
		cam.Start3D2D(self:LocalToWorld(Vector(6, 0, 34)), ang, 0.12)
			draw.SimpleText(label, "DermaLarge", 0, -30, Color(255, 190, 80), TEXT_ALIGN_CENTER)
			if (t > 0) then
				local left = math.max(0, t - CurTime())
				draw.SimpleText(string.format("%d:%02d", math.floor(left / 60), left % 60), "DermaLarge", 0, 10,
					Color(255, 60 + 60 * math.sin(CurTime() * 8), 40), TEXT_ALIGN_CENTER)
			end
		cam.End3D2D()
	end
end
