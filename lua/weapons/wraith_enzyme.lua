--[[
	Wraith Enzyme - Ascension Gates' own code and model, designed after the series; no Evolution Addon Pack content
	left (the class name stays for saves). The enzyme a Wraith injects when it feeds: in a human it heals and lends
	strength and speed for a while (Ford in "The Lost Boys"). A bright red dose in an Earth syringe. AGP
	(inject like the adrenaline shot): a Wraith-grown injector
	- orange enzyme in a glass barrel held by a dark blue-green carapace (ribs, spine knobs, a nozzle with bone hooks
	and an amber glow), bone claws as finger grips, a bone plunger, a ribbed cap over the needle
	(models/agp_weapons/w_wraith_enzyme2.mdl). One dose: health +60 and armour
	+50 (up to 200 each), then 30 seconds faster, healing, the world tinted red. At 200 health a further dose is
	refused.
]]
SWEP.Base = "agp_injector_base"
SWEP.PrintName = "Wraith Enzyme"
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_misc_cat") or "Misc Weapons"   -- AGP: one of our two weapon folders (was "Misc": a folder of its own)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    SWEP.PrintName = SGLanguage.GetMessage("wp_wraith_enzyme")
    SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat")
end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Ascension Gates"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_wraith_enzyme_p", "Heal yourself and become stronger and faster for a while.") or "Heal yourself and become stronger and faster for a while."
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_wraith_enzyme_i", "Left click: inject") or "Left click: inject"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.WorldModel = "models/agp_weapons/w_wraith_enzyme2.mdl"   -- AGP: the new injector (the old model stays)
SWEP.PlungerTravel = 3.2                                    -- AGP: the stopper to the front of the barrel
SWEP.CapPivot = Vector(0, 0, 2.55)
if CLIENT then SWEP.WepSelectIcon = surface.GetTextureID("vgui/weapons/agp_wraith_enzyme2_inventory") end

local RUSH = 30          -- seconds of speed and healing
local CAP = 200          -- health and armour

if SERVER then
    AddCSLuaFile()
end

function SWEP:AGPCanInject(ply)
    if (ply:Health() < CAP) then return true end
    return false, (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("wp_enzyme_too_much") or "wp_enzyme_too_much"
end

function SWEP:AGPInject(ply)
    ply:SetHealth(math.min(CAP, ply:Health() + 60))
    ply:SetArmor(math.min(CAP, ply:Armor() + 50))
    ply:SetNW2Float("AGPEnzymeUntil", CurTime() + RUSH)
    timer.Create("AGP.WraithEnzyme" .. ply:EntIndex(), 1, RUSH, function()
        if (IsValid(ply) and ply:Alive() and ply:Health() < CAP) then ply:SetHealth(math.min(CAP, ply:Health() + 2)) end
    end)
end

-- the rush: faster on foot (both sides, so movement stays predicted)
hook.Add("SetupMove", "AGP.WraithEnzyme", function(ply, mv)
    if (ply:GetNW2Float("AGPEnzymeUntil", 0) > CurTime()) then
        mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * 1.3)
        mv:SetMaxSpeed(mv:GetMaxSpeed() * 1.3)
    end
end)

if SERVER then
    hook.Add("PlayerDeath", "AGP.WraithEnzyme", function(ply)
        ply:SetNW2Float("AGPEnzymeUntil", 0)
        timer.Remove("AGP.WraithEnzyme" .. ply:EntIndex())
    end)
else
    -- the world through the enzyme: tinted red, pulsing with the heartbeat, fading as the rush ends
    hook.Add("RenderScreenspaceEffects", "AGP.WraithEnzyme", function()
        local left = LocalPlayer():GetNW2Float("AGPEnzymeUntil", 0) - CurTime()
        if (left <= 0) then return end
        local f = math.Clamp(left / 5, 0, 1) * (0.85 + 0.15 * math.sin(CurTime() * 7.5))
        DrawColorModify({ ["$pp_colour_addr"] = 0.06 * f, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0, ["$pp_colour_contrast"] = 1 + 0.12 * f, ["$pp_colour_colour"] = 1 - 0.2 * f,
            ["$pp_colour_mulr"] = 0.4 * f, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
    end)
end
-- AGP: no AGP.SGCWeapon any more - agp_injector_base.lua draws it on the adrenaline shot's hands
