if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("weapon")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_asuran");
SWEP.Category = SGLanguage.GetMessage("weapon_cat");
end
SWEP.Author = "RononDex"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_weapon_asura_p", "Asuran energy weapon (needs the ATA gene)") or "Asuran energy weapon (needs the ATA gene)"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_weapon_asura_i", "Left click: fire") or "Left click: fire"
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

list.Add("NPCUsableWeapons", {
    class = "weapon_asura",
    title = SWEP.PrintName or ""
})

SWEP.Slot = 3
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/micropro/Asuragun/v_asugun/v_asugun.mdl"
SWEP.WorldModel = "models/micropro/Asuragun/w_asugun/w_asugun.mdl"

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

function SWEP:Initialize()
    self:SetWeaponHoldType("pistol")
end

if CLIENT then
    -- Inventory Icon
    if (file.Exists("materials/VGUI/weapons/asuran_inventory.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/asuran_inventory")
    end
end

function SWEP:EquipAmmo()
    if (self.Owner.GiveAmmo) then
        self.Owner:GiveAmmo(100, "HelicopterGun")
    end
end

if SERVER then
    function SWEP:Deploy()
        if(not IsValid(self) or not IsValid(self.Owner)) then return end
        self.RequireATAGene = StarGate.CFG:Get("cap_enhanced_cfg","ATA_gene_active",false)
        if(self.RequireATAGene and StarGate.HasATA(self.Owner,false) == false) then return end
        self.Owner:EmitSound(Sound("pulse_weapon/asuran_hand_deploy.wav"), 75, math.random(75, 125))
    end
end
--###### Energy Muzzle and Recoil Effect @RononDex,aVoN
function SWEP:Effects()
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    -- AGP: a player's glow sits on the gun's muzzle as he sees it, same colour and size (lua/autorun/agp_muzzle.lua)
    if (self.Owner:IsPlayer() and AGP and AGP.MuzzleFx) then
        AGP.MuzzleFx(self, "flash", nil, "asuran")
        self.Weapon:SetNextPrimaryFire(CurTime() + 0.2)
        return true
    end
    -- Muzzle
    local fx = EffectData()
    fx:SetScale(0)
    -- AGP: an NPC's flash at the weapon in its hand
    fx:SetOrigin((SERVER and self.Owner:IsNPC() and AGP and AGP.NPCMuzzle) and AGP.NPCMuzzle(self.Owner, 12, self.Weapon) or self.Owner:GetShootPos())
    fx:SetEntity(self.Owner)
    fx:SetAngles(Angle(255, 50, 50))
    fx:SetRadius(64)
    util.Effect("energy_muzzle_asuran", fx, true)
    -- Shot
    self.Weapon:SetNextPrimaryFire(CurTime() + 0.2)

    return true
end

--###### Shoot @Ronondex, aVoN
function SWEP:PrimaryAttack()
    if(StarGate.HasATA(self.Owner,true) == false) then return end

    if self.Weapon:GetNextPrimaryFire() > CurTime() then return end
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end
    self:Effects()

    if (SERVER) then
        local p = self.Owner
        local multiply = 3 -- Default inaccuracy multiplier
        local aimvector = p:GetAimVector()
        local shootpos = p:GetShootPos()
        -- AGP: an NPC's shot leaves the weapon in its hand, not its eyes (lua/autorun/agp_npcs.lua)
        if (p:IsNPC() and AGP and AGP.NPCMuzzle) then shootpos = AGP.NPCMuzzle(p, 12, self.Weapon) end
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

        if (trace.Hit) then
            aimvector = (trace.HitPos - shootpos):GetNormalized()
        end

	        local e = ents.Create("energy_pulse")
	        e:SetPos(shootpos)
	        e:PrepareBullet(aimvector, multiply, 8000, 1)
	        e:SetOwner(p)
	        e.Owner = p
	        e.Damage = 100
	        e:Spawn()
	        e:Activate()
	        e:SetColor(Color(119, 176, 255, 215))
	        p:EmitSound(Sound("pulse_weapon/asuran_hand_fire.wav"), 90, math.random(97, 103))
        -- Take one Ammo
        if (self.Owner:IsPlayer()) then
            self:TakePrimaryAmmo(1)
        end
    end
end

function SWEP:SecondaryAttack()
    if(StarGate.HasATA(self.Owner,false) == false) then return end

    if self.Weapon:GetNextPrimaryFire() > CurTime() then return end
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end
end
-- AGP: the player's own hands (GMod's hands of the player model) instead of the arms built into the old view model
if (AGP and AGP.OwnHands) then AGP.OwnHands(SWEP, { "v_hand_sheet" }) end

-- AGP: where the shot leaves the weapon (lua/autorun/agp_muzzle.lua): the old view model's own muzzle in first person, the hand
-- plus 12 along the aim in third person
if (AGP and AGP.MuzzleTrack) then
    SWEP.AGPMuzzleSync = true
    AGP.MuzzleTrack(SWEP, { vm = true, fmt = true, reach = 12 })
end
