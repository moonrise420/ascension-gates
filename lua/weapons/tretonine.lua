--[[
	Tretonin - Ascension Gates' own code and model (2026-11-06), designed after the series; no Evolution Addon Pack
	content left (the class name stays for saves). The Tok'ra drug that does a symbiote's work: it takes over the
	immune system ("Cure", "The Changeling"). The series' bottle - purple liquid, white hexagonal cap - sits in a
	Tok'ra jet injector.
	AGP 2026-11-08 (owner: "not so naked, flat and sterile"; inject like the adrenaline shot): a Goa'uld / Jaffa
	injector - the purple vial in an engraved gold cage, gold finger wings, a violet gem, the bottle's white hex cap as
	the thumb press, a needle and its cap (models/agp_weapons/w_tretonin2.mdl, notes/models/agp_injectors_*.py).
	One dose: 50 health over ten seconds (up to full health), and for two minutes poison, nerve gas, radiation and acid
	do no harm.
]]
SWEP.Base = "agp_injector_base"
SWEP.PrintName = "Tretonin"
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_misc_cat") or "Misc Weapons"   -- AGP 2026-11-10: one of our two weapon folders (was "Misc": a folder of its own)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    SWEP.PrintName = SGLanguage.GetMessage("wp_tretonine")
    SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat")
end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Ascension Gates"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_tretonine_p", "Heals you and keeps poison and sickness away for a while.") or "Heals you and keeps poison and sickness away for a while."
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_tretonine_i", "Left click: inject") or "Left click: inject"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.WorldModel = "models/agp_weapons/w_tretonin2.mdl"   -- AGP 2026-11-08: the new injector (the old model stays)
SWEP.InjectSound = "items/medshot4.wav"
SWEP.PlungerTravel = 2.75                               -- AGP 2026-11-08: the stopper to the front of the vial
SWEP.CapPivot = Vector(0, 0, 2.5)
if CLIENT then SWEP.WepSelectIcon = surface.GetTextureID("vgui/weapons/agp_tretonin2_inventory") end

local GUARD = 120        -- seconds without poison / nerve gas / radiation / acid damage
local GUARDED = bit.bor(DMG_POISON, DMG_NERVEGAS, DMG_RADIATION, DMG_ACID, DMG_PARALYZE)

if SERVER then
    AddCSLuaFile()
end

function SWEP:AGPInject(ply)
    ply:SetNW2Float("AGPTretoninUntil", CurTime() + GUARD)
    ply:SetNW2Float("AGPTretoninAt", CurTime())
    timer.Create("AGP.Tretonin" .. ply:EntIndex(), 1, 10, function()
        if (IsValid(ply) and ply:Alive()) then ply:SetHealth(math.max(ply:Health(), math.min(ply:GetMaxHealth(), ply:Health() + 5))) end
    end)
end

if SERVER then
    hook.Add("EntityTakeDamage", "AGP.Tretonin", function(ent, dmg)
        if (ent:IsPlayer() and ent:GetNW2Float("AGPTretoninUntil", 0) > CurTime() and dmg:IsDamageType(GUARDED)) then return true end
    end)
    hook.Add("PlayerDeath", "AGP.Tretonin", function(ply)
        ply:SetNW2Float("AGPTretoninUntil", 0)
        timer.Remove("AGP.Tretonin" .. ply:EntIndex())
    end)
else
    -- the dose going in: a short violet wash over the view
    hook.Add("RenderScreenspaceEffects", "AGP.Tretonin", function()
        local f = 1 - (CurTime() - LocalPlayer():GetNW2Float("AGPTretoninAt", -10)) / 1.5
        if (f <= 0) then return end
        DrawColorModify({ ["$pp_colour_addr"] = 0.05 * f, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0.08 * f,
            ["$pp_colour_brightness"] = 0.02 * f, ["$pp_colour_contrast"] = 1, ["$pp_colour_colour"] = 1,
            ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0 })
    end)
end
-- AGP 2026-11-08: no AGP.SGCWeapon any more - agp_injector_base.lua draws it on the adrenaline shot's hands
