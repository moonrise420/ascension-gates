--[[
	Goa'uld Pain Stick - Ascension Gates' own code and model, designed after the series; no Evolution Addon Pack
	content left (the class name stays for saves). The Goa'uld torture rod: on contact it sends a jolt through the
	victim, whose eyes and mouth flare with light ("The Serpent's Venom", "The Other Guys"). Left click: a
	jolt. Hold right click: keep it on the victim, pain every quarter second. First person:
	GMod's hands on the stun stick animations, our model in the hand (agp_sgc_weapons.lua).
]]
SWEP.PrintName = "Goa'uld Pain Stick"
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_cat") or "Player Weapons"   -- AGP: one of our two weapon folders (was "Weapons": a folder of its own)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    SWEP.PrintName = SGLanguage.GetMessage("wp_goauld_stick")
    SWEP.Category = SGLanguage.GetMessage("weapon_cat")
end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Ascension Gates"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_goauld_pain_stick_p", "Torture those beneath you.") or "Torture those beneath you."
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_goauld_pain_stick_i", "Left click: a jolt\nHold Right click: keep the pain on") or "Left click: a jolt\nHold Right click: keep the pain on"
SWEP.Base = "weapon_base"
SWEP.Slot = 0
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_stunstick.mdl"   -- GMod's stun stick animations (our model is drawn in the hand)
-- AGP: at 70 the sleeve's loose end (the open back of the DoD arms' sleeve, which is meant to stay below the screen) swung
-- into view during the attack as a torn, see-through wedge (pictures wppain_before_*). 60 keeps the hand in view and the
-- loose end below the edge (pictures wppainfix2_b60_*; $nocull on the sleeve materials only made the hidden upper-arm bags
-- visible: tried, removed)
SWEP.ViewModelFOV = 60   -- (GMod's stun stick keeps the hand below the screen edge; see GetViewModelPosition)
SWEP.WorldModel = "models/agp_weapons/w_goauld_pain_stick.mdl"
SWEP.HoldType = "melee"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"

local REACH = 72
local JOLT, JOLT_DELAY = 12, 0.6         -- left click
local HOLD, HOLD_TICK = 5, 0.25          -- right click held on the victim
local GLOW = CLIENT and Material("sprites/light_glow02_add")

if SERVER then
    AddCSLuaFile()
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "GlowUntil")   -- the crystal and the prongs flare until then
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
    self:EmitSound("Weapon_StunStick.Activate")
    return true
end

function SWEP:Holster()
    self.AGPHolding = nil
    return true
end

-- what the prongs touch: a short hull trace along the aim
function SWEP:Touching()
    local o = self:GetOwner()
    if (o:IsPlayer()) then o:LagCompensation(true) end
    local src = o:GetShootPos()
    local tr = util.TraceHull({ start = src, endpos = src + o:GetAimVector() * REACH, filter = o,
        mins = Vector(-4, -4, -4), maxs = Vector(4, 4, 4), mask = MASK_SHOT_HULL })
    if (o:IsPlayer()) then o:LagCompensation(false) end
    return tr
end

local function living(e) return IsValid(e) and (e:IsPlayer() or e:IsNPC() or e:GetClass() == "prop_ragdoll") end

-- one jolt into whatever the prongs touch; returns true on a hit
function SWEP:Jolt(dmg, quiet)
    local o = self:GetOwner()
    local tr = self:Touching()
    if (not tr.Hit) then return false end
    self:SetGlowUntil(CurTime() + 0.35)
    local e = tr.Entity
    if (SERVER) then
        if (IsValid(e)) then
            local d = DamageInfo()
            d:SetDamage(dmg); d:SetDamageType(DMG_SHOCK); d:SetAttacker(o); d:SetInflictor(self)
            d:SetDamagePosition(tr.HitPos); d:SetDamageForce(o:GetAimVector() * 600)
            e:TakeDamageInfo(d)
        end
        if (living(e) and e:GetClass() ~= "prop_ragdoll") then
            -- the victim's eyes and mouth flare (agp_pain_glow), a player also sees it
            local fx = EffectData(); fx:SetEntity(e); fx:SetMagnitude(0.6)
            util.Effect("agp_pain_glow", fx, true, true)
            if (e:IsPlayer()) then
                e:ScreenFade(SCREENFADE.IN, Color(255, 150, 60, 80), 0.4, 0)
                e:ViewPunch(Angle(math.Rand(-4, 4), math.Rand(-4, 4), math.Rand(-3, 3)))
            end
        end
        local fx = EffectData(); fx:SetOrigin(tr.HitPos); fx:SetNormal(tr.HitNormal); fx:SetMagnitude(1); fx:SetScale(1); fx:SetRadius(2)
        util.Effect("ElectricSpark", fx, true, true)
    end
    if (quiet) then
        self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav", 60, math.random(110, 130))
    else
        self:EmitSound(living(e) and "Weapon_StunStick.Melee_Hit" or "Weapon_StunStick.Melee_HitWorld")
    end
    return true
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + JOLT_DELAY)
    self:SetNextSecondaryFire(CurTime() + JOLT_DELAY)
    local o = self:GetOwner()
    o:SetAnimation(PLAYER_ATTACK1)
    if (self:Jolt(JOLT)) then
        self:SendWeaponAnim(ACT_VM_HITCENTER)
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        self:EmitSound("Weapon_StunStick.Melee_Miss")
    end
end

-- held: the first press thrusts, then the stick stays on the victim and hurts every tick while it touches
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + HOLD_TICK)
    self:SetNextPrimaryFire(CurTime() + HOLD_TICK)
    local again = (self.AGPHolding or 0) > CurTime()
    self.AGPHolding = CurTime() + HOLD_TICK + 0.15
    if (not again) then
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)
        self:SendWeaponAnim(ACT_VM_HITCENTER)
    end
    self:Jolt(HOLD, again)
end

AGP.SGCWeapon(SWEP, {
    model = "models/agp_weapons/w_goauld_pain_stick.mdl", icon = "vgui/weapons/agp_goauld_pain_stick_inventory",
    vmBone = "ValveBiped.Bip01_R_Hand", vmHand = true,
    -- our hand bone on the stun stick's hand bone: HL2's baton and ours line up (agp_goauld_weapons_build.py)
    vmPos = Vector(0.742, -0.070, 0.503), vmAng = Angle(9.58, 0.89, 5.74),
    after = CLIENT and function(self, ent, fp)
        local glow = math.Clamp(((self.GetGlowUntil and self:GetGlowUntil() or 0) - CurTime()) / 0.35, 0, 1)
        local tip = ent:GetAttachment(ent:LookupAttachment("tip"))
        local cr = ent:GetAttachment(ent:LookupAttachment("crystal"))
        if (not tip or not cr) then return end
        render.SetMaterial(GLOW)
        local pulse = 0.8 + 0.2 * math.sin(CurTime() * 7)
        render.DrawSprite(cr.Pos, 3 + 5 * glow, 3 + 5 * glow, Color(255, 150, 50, 120 * pulse + 135 * glow))
        if (glow > 0) then
            render.DrawSprite(tip.Pos, 10 * glow, 10 * glow, Color(255, 180, 90, 255 * glow))
            if (not fp) then
                local d = DynamicLight(self:EntIndex())
                if (d) then
                    d.pos = tip.Pos; d.r, d.g, d.b = 255, 150, 60; d.brightness = 2 * glow; d.size = 120; d.decay = 1000; d.dietime = CurTime() + 0.1
                end
            end
        end
    end or nil,
})

-- AGP: the hand on the stick in view - a little higher and tilted up (chosen from pictures of several positions,
-- suite vmoff)
if (CLIENT) then
    function SWEP:GetViewModelPosition(p, a)
        local b = Angle(a.p, a.y, a.r)
        b:RotateAroundAxis(b:Right(), 4)
        return p + a:Forward() * 4 + a:Up() * 2, b
    end
end
