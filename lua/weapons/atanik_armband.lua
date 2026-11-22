--[[
	Atanik Armband
	Copyright (C) 2012 Llapp
]]
--
if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end
    AddCSLuaFile()
end


if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_atanik");
SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat");
else
SWEP.PrintName = "Atanik Armband"
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_misc_cat") or "Misc Weapons"   -- AGP: one of our two weapon folders (was "Misc Weapons": a folder of its own)
end
SWEP.Author = "Llapp"
SWEP.Contact = "llapp612@googlemail.com"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_atanik_armband_p", "Strength and speed (the Atanik armband)") or "Strength and speed (the Atanik armband)"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_atanik_armband_i", "Wear it: you are stronger and faster.") or "Wear it: you are stronger and faster."
SWEP.Base = "weapon_base"
SWEP.Slot = 1
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
-- AGP: Garry's Mod's own hands with the fists animations (agp_weapon_hands.lua): v_hands.mdl has no punch
-- (ACT_VM_HITCENTER), the punches did not show in first person
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/weapons/w_bugbait.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.AnimPrefix = "melee"
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)
SWEP.Primary.Delay = 0.9
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 15
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Delay = 0.9
SWEP.Secondary.Recoil = 0
SWEP.Secondary.Damage = 0
SWEP.Secondary.NumShots = 1
SWEP.Secondary.Cone = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

function SWEP:Initialize()
    self:SetWeaponHoldType("fist")
    self.Hit = Sound("player/pl_fallpain1.wav")
    self.NextHit = 0

    if (not IsValid(self.OldOwner)) then
        self.OldOwner = self.Owner
    end
end

-- AGP (the night's weapon sweep: "a punch into the air is silent, a hit sounds like a fall-pain grunt and leaves a
-- bullet hole"): a fist - a short trace with blunt damage (CAP fired a bullet), the whoosh of the swing always, a
-- real impact sound on a hit (HL2's own recordings).
function SWEP:Punch(damage, delay, seq, force)
    if (CurTime() < self.NextHit) then return end
    self.NextHit = CurTime() + delay
    local o = self.Owner
    o:SetAnimation(PLAYER_ATTACK1)
    if (self.AGPHandsPlay) then self:AGPHandsPlay(seq) end
    if (CLIENT) then return end
    o:EmitSound("Weapon_Crowbar.Single", 65, 85)
    local src, aim = o:GetShootPos(), o:GetAimVector()
    o:LagCompensation(true)
    local tr = util.TraceLine({ start = src, endpos = src + aim * 75, filter = o, mask = MASK_SHOT_HULL })
    if (not IsValid(tr.Entity)) then
        local tr2 = util.TraceHull({ start = src, endpos = src + aim * 75, filter = o, mins = Vector(-10, -10, -8), maxs = Vector(10, 10, 8), mask = MASK_SHOT_HULL })
        if (tr2.Hit and (IsValid(tr2.Entity) or not tr.Hit)) then tr = tr2 end
    end
    o:LagCompensation(false)
    if (not tr.Hit) then return end
    local e = tr.Entity
    local living = IsValid(e) and (e:IsPlayer() or e:IsNPC() or e:IsNextBot() or e:GetClass() == "prop_ragdoll")
    o:EmitSound(living and "Flesh.ImpactHard" or "physics/body/body_medium_impact_hard" .. math.random(1, 6) .. ".wav", 75, math.random(90, 105))
    if (IsValid(e)) then
        local d = DamageInfo()
        d:SetAttacker(o); d:SetInflictor(self)
        d:SetDamage(damage); d:SetDamageType(DMG_CLUB)
        d:SetDamagePosition(tr.HitPos); d:SetDamageForce(aim * force)
        e:TakeDamageInfo(d)
        local ph = e:GetPhysicsObject()
        if (IsValid(ph) and not living) then ph:ApplyForceOffset(aim * force * 0.5, tr.HitPos) end
    end
end

function SWEP:PrimaryAttack()
    -- a jab with the left or the right fist (GMod's fists; the same pick on client and server)
    self:Punch(55, 0.4, util.SharedRandom("AGPAtanikPunch", 0, 1) < 0.5 and "fists_left" or "fists_right", 9000)
end

function SWEP:SecondaryAttack()
    self:Punch(200, 1, "fists_uppercut", 30000)   -- the strong blow: an uppercut (GMod's fists)
end

--################### Tell a player how to use this @aVoN
function SWEP:DrawHUD()
    draw.WordBox(8, ScrW() - 315, ScrH() - 50, AGP.L("agp_ui_melee_mode_you_are_stronger_and", "Melee mode: You are stronger and faster."), "Default", Color(0, 0, 0, 80), Color(255, 220, 0, 220))
end

if SERVER then
    function SWEP:OnDrop()
        self:SetNWBool("WorldNoDraw", false)

        -- AGP: gives back the run speed, jump and armour he had (was run 500, jump 200, armour 0);
        -- StarGate.AtanikOff: stargate/shared/init.lua
        if (IsValid(self.OldOwner) and self.OldOwner.CAP_Atanik) then
            StarGate.AtanikOff(self.OldOwner)
            self.OldOwner = NULL
        end

        return true
    end

    -- AGP: taken away while worn (a ship's StripWeapons, death, remover): the boost ended there too
    function SWEP:OnRemove()
        local owner = IsValid(self:GetOwner()) and self:GetOwner() or self.OldOwner
        if (not IsValid(owner) or not owner.CAP_Atanik or not owner.GetActiveWeapon) then return end
        local active = owner:GetActiveWeapon()
        if (IsValid(active) and active != self and active:GetClass() == "atanik_armband") then return end -- another one is worn
        StarGate.AtanikOff(owner)
    end

    function SWEP:Equip()
        self:SetNWBool("WorldNoDraw", true)

        return true
    end

    function SWEP:OwnerChanged()
        -- AGP: keep the last real owner (on a drop the owner turns NULL, maybe before OnDrop runs)
        if (IsValid(self:GetOwner())) then
            self.OldOwner = self:GetOwner()
        end
    end
end

if CLIENT then
    -- Inventory Icon
    if (file.Exists("materials/VGUI/weapons/atanik_inventory.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/atanik_inventory")
    end

    function SWEP:DrawWorldModel()
        if (not self:GetNWBool("WorldNoDraw")) then
            self:DrawModel()
        end
    end

    -- AGP: the old GetViewModelPosition (10 back, 1 down) was made for v_hands.mdl; removed - GMod's hands sit where
    -- its fists do
end

-- AGP: the hands come up on deploy and rest in the fists idle (agp_weapon_hands.lua)
if (AGP and AGP.HandsWeapon) then AGP.HandsWeapon(SWEP) end
