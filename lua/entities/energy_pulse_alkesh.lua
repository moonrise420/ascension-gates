--[[
	Goa'uld energy bolt (Al'kesh / glider torpedo) - Ascension Gates' own code: CAP's energy pulse
	(energy_pulse: aVoN, Madman07) in the Goa'uld's golden orange, a little different from bolt to bolt. Fired by the
	gate glider's torpedo. The class name stays (EAP had a colour variant of the same name), so the kill feed and saves
	keep working.
]]
ENT.Type = "anim"
ENT.Base = "energy_pulse"
ENT.DoNotDuplicate = true
ENT.Spawnable = false

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetColor(Color(math.random(235, 255), math.random(190, 210), 110, 255))   -- the base reads the bolt's colour from the entity
		baseclass.Get("energy_pulse").Initialize(self)
	end
end
