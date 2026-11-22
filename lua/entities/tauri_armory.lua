--[[
	Tau'ri Armory - Ascension Gates' own code, no Evolution Addon Pack code left; the class name stays. An SGC ammo
	crate (Half-Life 2's ammo crate model): press USE to take a Zat, P90, GDO, Beretta and adrenaline, and the ammo
	is topped up. Works like the Goa'uld armory (goauld_armory.lua), only the contents differ.
]]
ENT.Type = "anim"
ENT.Base = "goauld_armory"
ENT.PrintName = "Tau'ri Armory"
ENT.Author = "Ascension Gates"
ENT.Purpose = "Take SGC equipment."
ENT.Instructions = "Press USE."
ENT.Category = "Others"
ENT.Spawnable = false -- in our spawn tab
ENT.AdminSpawnable = false
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
	ENT.PrintName = SGLanguage.GetMessage("ent_tauri_ammo")
	ENT.Category = SGLanguage.GetMessage("cat_others")
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

ENT.ArmoryModel = "models/Items/ammocrate_smg1.mdl"
ENT.Weapons = { "weapon_zat", "fnp90", "weapon_gdo", "weapon_beretta", "sg_adrenaline" }
ENT.Ammo = { { "GaussEnergy", 150, 50 }, { "pistol", 300, 50 } }

if SERVER then
	AddCSLuaFile()
end
