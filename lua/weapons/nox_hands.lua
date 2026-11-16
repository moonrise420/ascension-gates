--[[
	Nox Hands
	Copyright (C) 2011 Madman07
]]
--
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("base")) then return end

if SERVER then
    AddCSLuaFile()
else
    -- Inventory Icon
    if (file.Exists("materials/VGUI/weapons/nox_hands.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/nox_hands.vmt")
    end

    -- Kill Icon (AGP 2026-11-08: the icon is in VGUI/weapons/, the old path never existed - same as the ring caller)
    if (file.Exists("materials/VGUI/weapons/ring_killicon.vmt", "GAME")) then
        killicon.Add("ring_ring", "VGUI/weapons/ring_killicon", Color(255, 255, 255))
        killicon.Add("ring_base", "VGUI/weapons/ring_killicon", Color(255, 255, 255))
        killicon.Add("ring_panel", "VGUI/weapons/ring_killicon", Color(255, 255, 255))
    end
end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_nox");
SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat");
SWEP.Instructions = SGLanguage.GetMessage("weapon_misc_nox_desc")
end
SWEP.Author = "Madman07"
SWEP.Contact = "madman097@gmail.com"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_nox_hands_p", "Dial a gate and heal friends, like the Nox") or "Dial a gate and heal friends, like the Nox"
SWEP.Base = "weapon_base"
SWEP.Slot = 1
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
-- AGP 2026-11-08: Garry's Mod's own hands with the fists animations (agp_weapon_hands.lua); c_arms_animations.mdl
-- without UseHands showed no hands at all
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.WorldModel = "models/weapons/w_bugbait.mdl"
SWEP.HoldType = "normal"
-- primary.
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
-- secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
-- spawnables.
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
end

--################### Open Gate dialogue and overwrite default method @Madman07
function SWEP:PrimaryAttack()
    if (CLIENT) then return end
    local p = self.Owner
    local gate = StarGate.FindGate(p, 1000)
    if not IsValid(gate) then return end
    if (hook.Call("StarGate.Player.CanDialGate", GAMEMODE, p, gate) == false) then return end
    net.Start("StarGate.VGUI.Menu")
    net.WriteEntity(gate)
    net.WriteInt(3, 8)
    net.Send(p)
    self.Weapon:SetNextPrimaryFire(CurTime() + 1)
end

--################### Heal @Mad
function SWEP:SecondaryAttack()
    if (CLIENT) then return end
    local tr = self.Owner:GetEyeTrace()

    if (IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.HitPos:Distance(self.Owner:GetShootPos()) <= 500 and tr.Entity:Health() < 150) then
        tr.Entity:SetHealth(math.Clamp(tr.Entity:Health() + 1, 0, 150))
    end

    self:SetNextSecondaryFire(CurTime() + 0.1)
end

--################### Tell a player how to use this @aVoN
function SWEP:DrawHUD()
    draw.WordBox(8, ScrW() - 315, ScrH() - 50, AGP.L("agp_ui_primary_open_stargate_dial_menu_secondary", "Primary: open the Stargate dial menu    Secondary: heal a friend"), "Default", Color(0, 0, 0, 80), Color(255, 220, 0, 220))
end

if SERVER then
    function SWEP:OnDrop()
        self:SetNWBool("WorldNoDraw", false)

        return true
    end

    function SWEP:Equip()
        self:SetNWBool("WorldNoDraw", true)

        return true
    end
end

if CLIENT then
    function SWEP:DrawWorldModel()
        if (not self:GetNWBool("WorldNoDraw")) then
            self:DrawModel()
        end
    end
end

-- AGP 2026-11-08: the hands come up on deploy and rest in the fists idle (agp_weapon_hands.lua)
if (AGP and AGP.HandsWeapon) then AGP.HandsWeapon(SWEP) end
