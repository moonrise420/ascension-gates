--[[
	Stargate (Alteran) - Ascension Gates' own code and models; no Evolution Addon Pack content left (the class name
	stays for saves, dupes and gate spawners). Our remaster of the Alteran gate (models/agp/gates: bronze
	stone-metal, gold glyphs in an Ancient-script style, amber chevrons) on CAP's Stargate SG1 gate - its dialling,
	ring and chevrons (aVoN, Madman07, Llapp, Rafael De Jongh, AlexALX) - with an Atlantis-style event horizon and
	without the SGC menu extras.
]]
ENT.Type = "anim"
ENT.Base = "stargate_sg1"
ENT.PrintName = "Stargate (Alteran)"
ENT.Author = "Ascension Gates; on CAP's Stargate SG1 (aVoN, Madman07, Llapp, Rafael De Jongh, AlexALX)"
ENT.Category = "Ascension Gates: Gates and Rings"

ENT.WireDebugName = "Stargate Alteran"
list.Set("CAP.Entity", ENT.PrintName, ENT)

ENT.EventHorizonData = {
	OpeningDelay = 0.9,
	OpenTime = 2.2,
	NNFix = 0,
	Type = "atlantis",
}

-- no SGC menu extras on this gate (SGC type, two points of origin, the special 9 chevron mode)
ENT.StargateHasSGCType = false
ENT.StargateTwoPoO = false
ENT.StargateHas9ChevSpecial = false
