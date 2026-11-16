-- Stargate (Alteran), client - Ascension Gates' own code (2026-11-06); the rest comes from CAP's Stargate SG1 gate.
include("shared.lua")
ENT.ChevronColor = Color(255, 150, 50)   -- the amber of our chevron crystals (the chevrons' dynamic light)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
	ENT.Category = SGLanguage.GetMessage("stargate_category")
	ENT.PrintName = SGLanguage.GetMessage("stargate_alteran")
end
