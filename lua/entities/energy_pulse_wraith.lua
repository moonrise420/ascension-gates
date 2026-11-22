--[[
	Wraith energy bolt - Ascension Gates' own code: CAP's energy pulse (energy_pulse: aVoN, Madman07) in the Wraith's
	pale blue, the colour of the Wraith ships' bolts in the series. Fired by our Wraith cruiser. The class name stays
	(EAP had a colour variant of the same name), so the kill feed and saves keep working.
]]
ENT.Type = "anim"
ENT.Base = "energy_pulse"
ENT.DoNotDuplicate = true
ENT.Spawnable = false

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetColor(Color(110, 160, 255, 255))   -- the base reads the bolt's colour from the entity
		baseclass.Get("energy_pulse").Initialize(self)
		if (not IsValid(self) or not self.Size) then return end   -- (the base removed a bolt spawned without PrepareBullet)
		self.Damage = 20 + 35 * self.Size   -- a little under a Goa'uld bolt of the same size, as before
	end
end
