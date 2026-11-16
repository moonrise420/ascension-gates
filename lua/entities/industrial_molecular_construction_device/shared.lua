if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end
ENT.Type = "anim"
ENT.Base = "base_anim" --gmodentity
ENT.PrintName = "IMCD"
ENT.Author = "Llapp, Rafael De Jongh, Markjaw, AlexALX"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Industrial Molecular Construction Device"

list.Set("CAP.Entity", ENT.PrintName, ENT);