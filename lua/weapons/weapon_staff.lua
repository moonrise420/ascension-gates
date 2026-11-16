--[[
	Staff Weapon for GarrysMod10
	Copyright (C) 2007  aVoN

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]
if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_staff");
SWEP.Category = SGLanguage.GetMessage("weapon_cat");
end
SWEP.Author = "aVoN"
SWEP.Contact = "http://forums.facepunchstudios.com/aVoN"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_weapon_staff_p", "The Jaffa staff weapon") or "The Jaffa staff weapon"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_weapon_staff_i", "Right click: open / close the head\nLeft click: fire (opened)") or "Right click: open / close the head\nLeft click: fire (opened)"
SWEP.Base = "weapon_base"
SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/zup/staff/v_staff.mdl"
SWEP.WorldModel = "models/zup/staff/w_staff.mdl"
SWEP.HoldType = "shotgun"
-- primary.
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "CombineCannon"
-- secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
-- spawnables.
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

-- Add weapon for NPCs
list.Add("NPCUsableWeapons", {
    class = "weapon_staff",
    title = SWEP.PrintName or ""
})

function SWEP:Initialize()
    self.Weapon:SetWeaponHoldType(self.HoldType)
end

--################### Deploy @aVoN || #tweaked by #CryptAlchemy (what's with the ##s???)
function SWEP:Deploy()
    -- Animation
    self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
    -- Muzzle
    self:Muzzle()

    if SERVER and IsValid(self) and IsValid(self.Owner) then
        self.Owner:EmitSound(self.Sounds.Deploy, math.random(90, 110), math.random(90, 110))
    end

    self.IsEngaged = true

    return true
end

--################### Muzzleflash @aVoN
function SWEP:Muzzle()
    if (not IsValid(self.Owner)) then return end
    if (not self.IsEngaged) then return end
    -- AGP 2026-11-14: a player's glow sits on the staff's head as he sees it (the old effect used the view model's attachment, and in
    -- third person the world model has none: the glow hung beside the player), same colour and size: lua/autorun/agp_muzzle.lua
    if (self.Owner:IsPlayer() and AGP and AGP.MuzzleFx) then AGP.MuzzleFx(self, "flash", nil, "staff") return end
    -- Muzzle
    local fx = EffectData()
    fx:SetScale(0)
    -- AGP: an NPC's flash at the staff's head
    fx:SetOrigin((SERVER and self.Owner:IsNPC() and AGP and AGP.NPCMuzzle) and AGP.NPCMuzzle(self.Owner, 50, self.Weapon) or self.Owner:GetShootPos())
    fx:SetEntity(self.Owner)
    fx:SetAngles(Angle(255, 200, 120))
    fx:SetRadius(64)
    util.Effect("energy_muzzle", fx, true)
end

--################### Shoot @aVoN
function SWEP:PrimaryAttack()
    if self.Weapon:GetNextPrimaryFire() > CurTime() then return end
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end
    if (not self.IsEngaged and not self.Owner:IsNPC()) then return end
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    -- Muzzle
    self:Muzzle()

    -- Shot
    if SERVER then
        self:SVPrimaryAttack()
    end

    self.Weapon:SetNextPrimaryFire(CurTime() + 0.4)

    return true
end

--################### Disengage @CryptAlchemy
function SWEP:SecondaryAttack()
    if (not IsValid(self.Owner)) then return end

    if (self.IsEngaged) then
        -- Animation
        self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

        -- Sound
        if SERVER and IsValid(self) and IsValid(self.Owner) then
            timer.Simple(0.3, function()
                if not IsValid(self) or not IsValid(self.Owner) then return end
                self.Owner:EmitSound(self.Sounds.Holster, math.random(90, 110), math.random(90, 110))
            end)
        end

        self.IsEngaged = false

        return true
    else
        -- Animation
        self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
        -- Muzzle
        self:Muzzle()

        if SERVER and IsValid(self) and IsValid(self.Owner) then
            self.Owner:EmitSound(self.Sounds.Deploy, math.random(90, 110), math.random(90, 110))
        end

        self.IsEngaged = true

        return true
    end
end

--################### We don't this stuffz @CryptAlchemy
function SWEP:ShootEffects()
    return false
end

function SWEP:ShootBullet()
    return false
end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end
    AddCSLuaFile()

    SWEP.Sounds = {
        Shot = Sound("pulse_weapon/staff_weapon.mp3"),
        Deploy = Sound("pulse_weapon/staff_engage.mp3"),
        Disengage = Sound("pulse_weapon/staff_disengage.mp3"),
        Holster = Sound("pulse_weapon/staff_holster.mp3")
    }

    --################### Init the SWEP @aVoN
    function SWEP:Initialize()
        -- Sets how fast and how much shots an NPC shall do
        self:SetNPCFireRate(0.6)
        self:SetNPCMinBurst(0)
        self:SetNPCMaxBurst(0)

        -- Set holdtype, depending on NPCs, so it doesn't look too strange
        timer.Simple(0.2, function()
            if (not (IsValid(self) and self.SetWeaponHoldType)) then return end

            if (self.Owner and self.Owner:IsValid() and self.Owner:IsNPC()) then
                local class = self.Owner:GetClass()

                if (class ~= "npc_metropolice") then
                    self:SetWeaponHoldType("ar2")
                end
            end
        end)

        self:SetWeaponHoldType(self.HoldType)
    end

    --################### Holster @aVoN
    function SWEP:Holster()
        if self.IsEngaged then
            self.Owner:EmitSound(self.Sounds.Holster, 90, math.random(90, 110))
        end

        return true
    end

    --################### Shoot @aVoN
    function SWEP:SVPrimaryAttack()
        self.Weapon:SetNextPrimaryFire(CurTime() + 0.4)
        local p = self.Owner
        local multiply = 10 -- Default inaccuracy multiplier
        local aimvector = p:GetAimVector()
        local shootpos = p:GetShootPos()
        local vel = p:GetVelocity()
        local filter = {self.Owner, self.Weapon}

        local usedMuzzle = false
        -- Player is holding the weapon
        if (p:IsPlayer()) then
            -- Some translation to make the shot look like it always comes out from the weapon's front depending how fast the player moves
            local right = aimvector:Angle():Right()
            local up = aimvector:Angle():Up()
            -- Check, how far we can go to right (avoids exploding shots on the wall right next to you)
            local max = util.QuickTrace(shootpos, right * 100, filter).Fraction * 100 - 10
            local trans = right:DotProduct(vel) * right / 25

            -- AGP 2026-11-14: the pulse starts at the muzzle as the shooter sees it (the owner's client reports it, third person: the hand plus the
            -- weapon's reach; lua/autorun/agp_muzzle.lua), not on a fixed spot 23 right / 15 down from the eye
            local muzzle = AGP and AGP.MuzzleWorld and AGP.MuzzleWorld(self)
            if (muzzle) then
                shootpos = muzzle
                usedMuzzle = true
                if (p:Crouching()) then multiply = 1 end
            elseif (p:Crouching()) then
                multiply = 1 -- We are in crouch - Make it really accurate!
                -- We need to adjust shootpos or it will look strange
                shootpos = shootpos + math.Clamp(15, -10, max) * right - 4 * up + trans
            else
                -- He stands
                shootpos = shootpos + math.Clamp(23, -10, max) * right - 15 * up + trans
            end

            multiply = multiply * math.Clamp(vel:Length() / 80, 1, 10) -- We are moving - Make it inaccurate depending on the velocity
        else -- It's an NPC
            multiply = 0
            -- AGP: out of the staff's head, not the NPC's eyes (lua/autorun/agp_npcs.lua)
            if (AGP and AGP.NPCMuzzle) then shootpos = AGP.NPCMuzzle(p, 50, self.Weapon) end
        end

        if (p:IsPlayer() and AGP and AGP.MuzzleDebugPulse) then AGP.MuzzleDebugPulse(self, shootpos, usedMuzzle) end   -- (tests)
        -- Now, we need to correct the velocity depending on the changed shootpos above.
        local t = util.QuickTrace(p:GetShootPos(), 16 * 1024 * aimvector, filter)

        if (t.Hit) then
            aimvector = (t.HitPos - shootpos):GetNormalized()
        end

        -- Add some randomness to the velocity
        local e = ents.Create("energy_pulse")
        e:PrepareBullet(aimvector, multiply, 8000, 2)
        e:SetPos(shootpos)
        e:SetOwner(p)
        e.Owner = p
        e:Spawn()
        e:Activate()
        p:EmitSound(self.Sounds.Shot, 90, math.random(90, 110))

        -- Take one Ammo
        if (self.Owner:IsPlayer()) then
            self:TakePrimaryAmmo(1)
        end
    end
end

if CLIENT then
    -- Inventory Icon
    if (file.Exists("materials/VGUI/weapons/staff_inventory.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/staff_inventory")
    end

    -- Kill Icon
    if (file.Exists("materials/VGUI/weapons/staff_killicon.vmt", "GAME")) then
        killicon.Add("weapon_staff", "VGUI/weapons/staff_killicon", Color(255, 255, 255))
        killicon.Add("staff_pulse", "VGUI/weapons/staff_killicon", Color(255, 255, 255))
    end

    --################### Positions the viewmodel correctly @aVoN
    function SWEP:GetViewModelPosition(p, a)
        p = p - 70 * a:Up() - 13 * a:Forward() + 2 * a:Right()
        a:RotateAroundAxis(a:Right(), 5)
        a:RotateAroundAxis(a:Up(), 5)

        return p, a
    end
end

-- AGP 2026-11-12 (owner: "CAP's is way better held in the hand - why can't we have it exactly the same way"): CAP's own
-- first-person model and animations, with the player's own hands laid onto its arm skeleton
-- (lua/autorun/agp_blueprint_arms.lua). 2026-11-10's GMod hand animations never fitted this item.
if (AGP and AGP.BlueprintArms) then
    AGP.BlueprintArms(SWEP, { vm = "models/zup/staff/v_staff.mdl", hide = { "v_hand_sheet" }, arms = AGP.BlueprintRigs.valveL })
end

-- AGP 2026-11-14: where the shot leaves the weapon (lua/autorun/agp_muzzle.lua): the old view model's own muzzle in first person,
-- the head of the world model (AGP.MuzzleTips) in third person
if (AGP and AGP.MuzzleTrack) then
    SWEP.AGPMuzzleSync = true
    AGP.MuzzleTrack(SWEP, { vm = true, fmt = true })
end
