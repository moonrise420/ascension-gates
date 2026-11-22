--[[
	SGC Sidearm (Beretta M9) - Ascension Gates' own code and model (CC BY 4.0, see CREDITS); no Evolution Addon Pack
	content left (the class name stays for saves). The SGC's side arm: 16 rounds, pistol ammo. The kick
	depends on how you stand: jumping kicks hardest, crouching least. First
	person: GMod's HL2 pistol animations, our model on its gun bone (agp_sgc_weapons.lua).
]]
SWEP.PrintName = "SGC Sidearm"
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_cat") or "Player Weapons"   -- AGP: one of our two weapon folders (was "Player Weapons": a folder of its own)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    SWEP.PrintName = SGLanguage.GetMessage("wp_m9_berreta")
    SWEP.Category = SGLanguage.GetMessage("weapon_cat")
end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Ascension Gates"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_weapon_beretta_p", "Kill Goa'uld, Wraith and Ori.") or "Kill Goa'uld, Wraith and Ori."
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_weapon_beretta_i", "Left click: fire\nR: reload") or "Left click: fire\nR: reload"
SWEP.Base = "weapon_base"
SWEP.Slot = 2
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl" -- GMod's HL2 pistol animations (our own model is drawn on it)
SWEP.WorldModel = "models/agp_weapons/w_sgc_sidearm.mdl"
SWEP.HoldType = "pistol"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = 16
SWEP.Primary.DefaultClip = 48
SWEP.Primary.Ammo = "pistol"
SWEP.Primary.Automatic = false
SWEP.Primary.Damage = 25
SWEP.Primary.Cone = 0.0135
SWEP.Primary.Delay = 0.5
SWEP.Primary.Kick = 1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local SHOT = Sound("Weapon_Pistol.Single")

if SERVER then
    AddCSLuaFile()
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Reload()
    self:DefaultReload(ACT_VM_RELOAD)
end

function SWEP:SecondaryAttack()
end

-- how hard the shot kicks: in the air 2.5, walking 1, standing 0.4, crouching 0.33
local function stance(o)
    if (not o:IsPlayer()) then return 0.4 end
    if (not o:IsOnGround()) then return 2.5 end
    if (o:KeyDown(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT))) then return 1 end
    return o:Crouching() and 1 / 3 or 0.4
end

function SWEP:PrimaryAttack()
    if (self:Clip1() <= 0) then
        -- AGP: nothing left to load either: the dry click (as weapon_base does); before, it stayed silent
        if (self:Ammo1() <= 0) then
            self:EmitSound("Weapon_Pistol.Empty")
            self:SetNextPrimaryFire(CurTime() + 0.2)
            return
        end
        self:Reload()
        return
    end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:TakePrimaryAmmo(1)
    self:EmitSound(SHOT, 75, math.random(95, 110))
    local o = self:GetOwner()
    local kick = self.Primary.Kick * stance(o)
    local bullet = { Num = 1, Src = o:GetShootPos(), Dir = o:GetAimVector(), Spread = Vector(self.Primary.Cone, self.Primary.Cone, 0),
        Tracer = 1, Force = 0.65 * self.Primary.Damage, Damage = self.Primary.Damage }
    -- AGP: tracer and flash leave the muzzle of OUR model (the engine used the HL2 pistol's),
    -- lua/autorun/agp_muzzle.lua; the bullet is still traced from the eye
    local ours = AGP and AGP.MuzzleShot and AGP.MuzzleShot(self, bullet, "bullet")
    o:FireBullets(bullet)
    self:SendWeaponAnim(self:Clip1() <= 0 and ACT_VM_DRYFIRE or ACT_VM_PRIMARYATTACK)
    if (not ours) then o:MuzzleFlash() end
    o:SetAnimation(PLAYER_ATTACK1)
    if (o:IsPlayer()) then
        o:ViewPunch(Angle(math.Rand(-0.5, -2.5) * kick, math.Rand(-1, 1) * kick, 0))
        if ((game.SinglePlayer() and SERVER) or (not game.SinglePlayer() and CLIENT and IsFirstTimePredicted())) then
            local a = o:EyeAngles(); a.p = a.p - kick; o:SetEyeAngles(a)
        end
    end
end

-- our own SGC sidearm model on the HL2 pistol animations
AGP.SGCWeapon(SWEP, {
    model = "models/agp_weapons/w_sgc_sidearm.mdl", icon = "vgui/weapons/agp_sgc_sidearm_inventory",
    vmBone = "ValveBiped.square", vmPos = Vector(-0.555, -0.106, -0.772),
    vmAng = select(2, LocalToWorld(vector_origin, Angle(0, 180, 0), vector_origin, Angle(-90, 90, 180))),   -- model points along +Y (HL2 pistol layout)
})
if (AGP.MuzzleTrack) then AGP.MuzzleTrack(SWEP) end   -- (where the muzzle of our model is drawn in first person)
