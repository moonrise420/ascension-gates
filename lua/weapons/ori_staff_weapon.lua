if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("weapon")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_ori_staff");
SWEP.Category = SGLanguage.GetMessage("weapon_cat");
end
SWEP.Author = "RononDex, Rafael De Jongh"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_ori_staff_weapon_p", "The Ori warriors' staff") or "The Ori warriors' staff"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_ori_staff_weapon_i", "Left click: fire") or "Left click: fire"
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

-- Add weapon for NPCs
list.Add("NPCUsableWeapons", {
    class = "ori_staff_weapon",
    title = SWEP.PrintName or ""
})

SWEP.Slot = 3
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/Boba_Fett/ori_staff/v_ori_staff.mdl"
SWEP.WorldModel = "models/Boba_Fett/ori_staff/w_ori_staff.mdl"

-- Lol, without this we can't use this weapon in mp on gmod13...
if SERVER then
    AddCSLuaFile()
end

-- primary.
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "HelicopterGun"
-- secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- AGP: Mouse2 = melee stab/bash with the staff
SWEP.MeleeRange = 75
SWEP.MeleeDamage = 30
SWEP.MeleeDelay = 0.9

function SWEP:Initialize()
    self:SetWeaponHoldType("shotgun")
end

--###### Melee strike @AGP. Overriding SecondaryAttack keeps the base weapon from playing its empty "click"
-- (weapon_base clicks because Secondary.Ammo is "none" and Clip2 is -1).
function SWEP:SecondaryAttack()
    local p = self.Owner
    if (not IsValid(p) or not p:IsPlayer()) then return end
    self:SetNextSecondaryFire(CurTime() + self.MeleeDelay)
    self:SetNextPrimaryFire(math.max(self:GetNextPrimaryFire(), CurTime() + 0.4))
    p:SetAnimation(PLAYER_ATTACK1)
    p:ViewPunch(Angle(-4, math.Rand(-1.5, 1.5), 0))

    -- the staff view model only has an idle sequence, so the thrust is done in GetViewModelPosition. The start time
    -- goes over the network (in singleplayer this function runs on the server only - the old client-only flag was
    -- never set there and right click looked like nothing happened)
    if (SERVER) then self:SetNWFloat("AGPThrust", CurTime()) end
    if (CLIENT and IsFirstTimePredicted()) then self.MeleeThrust = CurTime() end

    local src = p:GetShootPos()
    local stop = src + p:GetAimVector() * self.MeleeRange
    if (SERVER) then p:LagCompensation(true) end
    local tr = util.TraceLine({start = src, endpos = stop, filter = p, mask = MASK_SHOT_HULL})
    if (not IsValid(tr.Entity)) then
        local hull = util.TraceHull({start = src, endpos = stop, filter = p, mins = Vector(-10, -10, -8), maxs = Vector(10, 10, 8), mask = MASK_SHOT_HULL})
        if (hull.Hit) then tr = hull end
    end
    if (SERVER) then p:LagCompensation(false) end

    local ent = tr.Entity
    if (IsFirstTimePredicted()) then
        if (not tr.Hit) then
            self:EmitSound("Weapon_Crowbar.Single")
        elseif (IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll")) then
            self:EmitSound("Weapon_Crowbar.Melee_Hit")
        else
            self:EmitSound("Weapon_Crowbar.Melee_HitWorld")
        end
    end

    if (SERVER and tr.Hit and IsValid(ent)) then
        local dmg = DamageInfo()
        dmg:SetAttacker(p)
        dmg:SetInflictor(self)
        dmg:SetDamage(self.MeleeDamage)
        dmg:SetDamageType(DMG_CLUB)
        dmg:SetDamagePosition(tr.HitPos)
        dmg:SetDamageForce(p:GetAimVector() * 6000)
        ent:TakeDamageInfo(dmg)
    end
end

--###### Energy Muzzle and Recoil Effect @RononDex,aVoN
function SWEP:Effects()
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    -- Shot
    self.Weapon:SetNextPrimaryFire(CurTime() + 0.5)
end

if CLIENT then
    -- Inventory Icon
    if (file.Exists("materials/VGUI/weapons/ori_staff_weapon_inventory.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/ori_staff_weapon_inventory")
    end

    -- AGP: short forward thrust of the staff view model after a melee strike
    function SWEP:GetViewModelPosition(pos, ang)
        local t0 = math.max(self.MeleeThrust or 0, self:GetNWFloat("AGPThrust", 0))
        if (t0 <= 0) then return pos, ang end
        local dt = CurTime() - t0
        local f
        if (dt < 0) then
            return pos, ang
        elseif (dt < 0.1) then
            f = dt / 0.1
        elseif (dt < 0.45) then
            f = 1 - (dt - 0.1) / 0.35
        else
            return pos, ang
        end
        f = math.sin(f * math.pi / 2)
        pos = pos + ang:Forward() * 8 * f - ang:Up() * 1 * f   -- (16 forward showed the cut end of the arm at the screen's edge)
        ang:RotateAroundAxis(ang:Right(), -11 * f)
        return pos, ang
    end
end

--###### Shoot @Ronondex, aVoN
function SWEP:PrimaryAttack()
    if self.Weapon:GetNextPrimaryFire() > CurTime() then return end
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end
    self:Effects()

    if (SERVER) then
        local p = self.Owner
        local multiply = 3 -- Default inaccuracy multiplier
        local aimvector = p:GetAimVector()
        local shootpos = p:GetShootPos()
        -- AGP: an NPC's shot leaves the weapon in its hand, not its eyes (lua/autorun/agp_npcs.lua)
        if (p:IsNPC() and AGP and AGP.NPCMuzzle) then shootpos = AGP.NPCMuzzle(p, 48, self.Weapon) end
        local vel = p:GetVelocity()
        local filter = {self.Owner, self.Weapon}


        local usedMuzzle = false
        -- Add inaccuracy for players!
        if (p:IsPlayer()) then
            local right = aimvector:Angle():Right()
            local up = aimvector:Angle():Up()
            -- Check, how far we can go to right (avoids exploding shots on the wall right next to you)
            local max = util.QuickTrace(shootpos, right * 100, filter).Fraction * 100 - 10
            local trans = right:DotProduct(vel) * right / 25

            -- AGP: the pulse starts at the muzzle as the shooter sees it (the owner's client reports it, third person: the hand plus the weapon's
            -- reach; lua/autorun/agp_muzzle.lua), not on a fixed spot 23 right / 15 down from the eye
            local muzzle = AGP and AGP.MuzzleWorld and AGP.MuzzleWorld(self)
            if (muzzle) then
                shootpos = muzzle
                usedMuzzle = true
                if (p:Crouching()) then multiply = 0.3 end
            elseif (p:Crouching()) then
                multiply = 0.3 -- We are in crouch - Make it really accurate!
                -- We need to adjust shootpos or it will look strange
                shootpos = shootpos + math.Clamp(15, -10, max) * right - 4 * up + trans
            else
                -- He stands
                shootpos = shootpos + math.Clamp(23, -10, max) * right - 15 * up + trans
            end

            multiply = multiply * math.Clamp(vel:Length() / 500, 0.3, 3) -- We are moving - Make it inaccurate depending on the velocity
        else -- It's an NPC
            multiply = 0
        end

        if (p:IsPlayer() and AGP and AGP.MuzzleDebugPulse) then AGP.MuzzleDebugPulse(self, shootpos, usedMuzzle) end   -- (tests)
        -- Now, we need to correct the velocity depending on the changed shootpos above.
        local trace = util.QuickTrace(p:GetShootPos(), 16 * 1024 * aimvector, filter)
        local spawnpos = shootpos + p:GetForward() * 94 + p:GetRight() * -15 + p:GetUp() * 5 -- AGP: where the pulse really appears
        if (p:IsNPC()) then spawnpos = shootpos end -- AGP: an NPC's shootpos is the staff's head already (AGP.NPCMuzzle)
        if (usedMuzzle) then spawnpos = shootpos end -- AGP: a player's shootpos is now the staff's head as he sees it (AGP.MuzzleWorld)

        if (trace.Hit) then
            -- AGP: aim from the spawn point (not shootpos) so the shot meets the crosshair when looking up/down
            local to = (trace.HitPos - spawnpos):GetNormalized()
            if (to:Dot(aimvector) > 0) then aimvector = to end
        end

        local e = ents.Create("energy_pulse")
        e:SetPos(spawnpos) -- AGP
        e:PrepareBullet(aimvector, multiply, 8000, 2)
        e:SetOwner(p)
        e.Owner = p
        e.Damage = 100
        e:Spawn()
        e:Activate()
        e:SetColor(Color(119, 176, 255, 215))
        p:EmitSound(Sound("pulse_weapon/ori_staff.wav"), 90, math.random(90, 110))

        -- Take one Ammo
        if (self.Owner:IsPlayer()) then
            self:TakePrimaryAmmo(1)
        end
    end
end

-- AGP: CAP's own first-person model and animations, with the player's own hands laid onto its arm skeleton
-- (lua/autorun/agp_blueprint_arms.lua). GMod hand animations never fitted this item.
--
if (AGP and AGP.BlueprintArms) then
    AGP.BlueprintArms(SWEP, { vm = "models/Boba_Fett/ori_staff/v_ori_staff.mdl", hide = { "v_hands" }, arms = AGP.BlueprintRigs.izi })
end

-- AGP: where the shot leaves the weapon (lua/autorun/agp_muzzle.lua): the old view model's own muzzle in first person, the head
-- of the world model (AGP.MuzzleTips) in third person
if (AGP and AGP.MuzzleTrack) then
    SWEP.AGPMuzzleSync = true
    AGP.MuzzleTrack(SWEP, { vm = true })
end
