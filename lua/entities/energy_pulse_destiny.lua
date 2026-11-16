--[[
	Destiny-style energy bolt - Ascension Gates' own code (2026-11-09): CAP's energy pulse (energy_pulse: aVoN,
	Madman07) in Destiny's orange, a little different from bolt to bolt. Fired by our Gate Seeder's turrets. The class
	name stays (EAP had a colour variant of the same name), so the kill feed and saves keep working.
]]
ENT.Type = "anim"
ENT.Base = "energy_pulse"
ENT.DoNotDuplicate = true
ENT.Spawnable = false

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetColor(Color(math.random(235, 255), math.random(140, 165), 30, 255))   -- the base reads the bolt's colour from the entity
		baseclass.Get("energy_pulse").Initialize(self)
	end
end
