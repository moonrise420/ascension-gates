if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.Category = SGLanguage.GetMessage("weapon_cat");
SWEP.PrintName = SGLanguage.GetMessage("weapon_wraith_blaster");
end
-- Lol, without this we can't use this weapon in mp on gmod13...
if SERVER then
    if (StarGate and StarGate.CFG and StarGate.CFG:Get("cap_disabled_swep", "wraith_blaster", false)) then return end
    AddCSLuaFile()
end

SWEP.Author = "Ronon Dex"
SWEP.Contact = ""
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_wraith_blaster_p", "The Wraith stunner") or "The Wraith stunner"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_wraith_blaster_i", "Left click: stun\nRight click: a quick, less accurate shot") or "Left click: stun\nRight click: a quick, less accurate shot"
SWEP.Base = "weapon_base"
SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/pg_props/pg_weapons/pg_wraithblaster_viewmodel.mdl"
SWEP.WorldModel = "models/pg_props/pg_weapons/pg_test_weapon_w.mdl"

if CLIENT then
    if (file.Exists("materials/VGUI/weapons/wraith_blaster.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/wraith_blaster.vmt")
    end
end

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "HelicopterGun"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

list.Add("NPCUsableWeapons", {
    class = "wraith_blaster",
    title = SWEP.PrintName or ""
})

SWEP.Sounds = Sound("weapons/wraith_stunner.wav")

function SWEP:Initialize()
    if CLIENT then
        local mat = Matrix()
        mat:Scale(Vector(0.2, 0.2, 0.2))
        self:EnableMatrix("RenderMultiply", mat)
    end

    self:SetWeaponHoldType("shotgun")
end

if CLIENT then
    --###### Energy Muzzle and Recoil Effect @RononDex,aVoN
    function SWEP:Effects()
        if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end
        -- Muzzle
        local fx = EffectData()
        fx:SetScale(0)
        fx:SetOrigin(self:GetPos())
        fx:SetEntity(self.Owner)
        fx:SetAngles(Angle(255, 50, 50))
        fx:SetRadius(64)
        util.Effect("energy_muzzle_asuran", fx, true)
        -- Shot
    end
end

--###### Shoot @Ronondex, aVoN
function SWEP:PrimaryAttack()
    if self.Weapon:GetNextPrimaryFire() > CurTime() then return end
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end

    if (self.Owner:IsPlayer() and AGP and AGP.MuzzleFx) then
        -- AGP 2026-11-14: the glow on the blaster's muzzle as the shooter sees it, in both realms (the old one was client-only: none in
        -- singleplayer, and others never saw it), same colour and size (lua/autorun/agp_muzzle.lua)
        AGP.MuzzleFx(self, "flash", nil, "asuran")
    elseif CLIENT then
        self:Effects()
    end

    if (SERVER) then
        self.Weapon:SetNextPrimaryFire(CurTime() + 0.4)
        local p = self.Owner
        local multiply = 3 -- Default inaccuracy multiplier
        local aimvector = p:GetAimVector()
        local shootpos = p:GetShootPos()
        -- AGP: an NPC's shot leaves the stunner in its hand, not its eyes (lua/autorun/agp_npcs.lua)
        if (p:IsNPC() and AGP and AGP.NPCMuzzle) then shootpos = AGP.NPCMuzzle(p, 20, self.Weapon) end
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

            -- AGP 2026-11-14: the pulse starts at the muzzle as the shooter sees it (the owner's client reports it, third person: the hand plus the
            -- weapon's reach; lua/autorun/agp_muzzle.lua), not on a fixed spot 23 right / 15 down from the eye
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

        if (trace.Hit) then
            aimvector = (trace.HitPos - shootpos):GetNormalized()
        end

        -- Add some randomness to the velocity
        local e = ents.Create("energy_pulse")
        e:PrepareBullet(aimvector, multiply, 8000, 1)
        e:SetPos(shootpos)
        e:SetOwner(p)
        e.Owner = p
        e:Spawn()
        e:Activate()
        e:SetColor(Color(119, 176, 255, 215))
        e:EmitSound(self.Sounds, math.random(90, 110), math.random(90, 110))

        -- Take one Ammo
        if (self.Owner:IsPlayer()) then
            self:TakePrimaryAmmo(1)
        end
    end
end

--###### Shoot @Ronondex, aVoN
function SWEP:SecondaryAttack()
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end

    if (self.Owner:IsPlayer() and AGP and AGP.MuzzleFx) then
        -- AGP 2026-11-14: the glow on the blaster's muzzle as the shooter sees it, in both realms (the old one was client-only: none in
        -- singleplayer, and others never saw it), same colour and size (lua/autorun/agp_muzzle.lua)
        AGP.MuzzleFx(self, "flash", nil, "asuran")
    elseif CLIENT then
        self:Effects()
    end

    if (SERVER) then
        self.Weapon:SetNextSecondaryFire(CurTime() + 0.5)
        local p = self.Owner
        local multiply = 3 -- Default inaccuracy multiplier
        local aimvector = p:GetAimVector()
        local shootpos = p:GetShootPos()
        -- AGP: an NPC's shot leaves the stunner in its hand, not its eyes (lua/autorun/agp_npcs.lua)
        if (p:IsNPC() and AGP and AGP.NPCMuzzle) then shootpos = AGP.NPCMuzzle(p, 20, self.Weapon) end
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

            -- AGP 2026-11-14: the pulse starts at the muzzle as the shooter sees it (the owner's client reports it, third person: the hand plus the
            -- weapon's reach; lua/autorun/agp_muzzle.lua), not on a fixed spot 23 right / 15 down from the eye
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

        if (trace.Hit) then
            aimvector = (trace.HitPos - shootpos):GetNormalized()
        end

        -- Add some randomness to the velocity
        local e = ents.Create("energy_pulse_stun")
        e:PrepareBullet(aimvector, multiply, 8000, 1)
        e:SetPos(shootpos)
        e:SetOwner(p)
        e.Owner = p
        e:Spawn()
        e:Activate()
        e:SetColor(Color(119, 176, 255, 215))
        e:EmitSound(self.Sounds, math.random(90, 110), math.random(90, 110))

        -- Take one Ammo
        if (self.Owner:IsPlayer()) then
            self:TakePrimaryAmmo(1)
        end
    end
end
-- AGP 2026-11-10: the player's own hands (GMod's hands of the player model) instead of the arms built into the old view model
if (AGP and AGP.OwnHands) then AGP.OwnHands(SWEP, { "pg_wraith_hands_v2" }) end

-- AGP 2026-11-14: where the shot leaves the weapon (lua/autorun/agp_muzzle.lua): the old view model's own muzzle in first person,
-- the hand plus 20 along the aim in third person
if (AGP and AGP.MuzzleTrack) then
    SWEP.AGPMuzzleSync = true
    AGP.MuzzleTrack(SWEP, { vm = true, fmt = true, reach = 20 })
end
