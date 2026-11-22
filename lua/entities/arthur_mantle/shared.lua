--[[
	Arthurs Mantle
	Copyright (C) 2010 Madman07
	Secret Code added by AlexALX
]]--

if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Arthurs Mantle"
ENT.WireDebugName = "Arthurs Mantle"
ENT.Author = "Madman07, Rafael De Jongh"
ENT.Instructions= ""
ENT.Contact = "madman097@gmail.com"
ENT.Category = "Ascension Gates"

list.Set("CAP.Entity", ENT.PrintName, ENT);

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

ENT.TFont = "AGP Ancient"
ENT.GFont = "AGP Glyphs Concept" -- AGP: as in CAP (concept font: Earth's point of origin at '#')