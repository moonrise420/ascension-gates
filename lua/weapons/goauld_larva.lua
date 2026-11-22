--[[
	Goa'uld Larva - Ascension Gates' own code and model, designed after the series; no Evolution Addon Pack content
	left (the class name stays for saves). A young symbiote (prim'ta) held in the hand: it wriggles all the time, and
	snaps its four-pronged jaw at whatever is in front of you. Left click: a
	bite. Right click: on a person in reach the symbiote takes them as its host (agp_goauld_host.lua); elsewhere a
	squeeze - it shrieks and lunges further and harder. First
	person: GMod's hands on the bug bait animations (the pod in the hand), our larva in the hand
	(agp_sgc_weapons.lua). The shriek is the series' sound the old larva used too.
]]
SWEP.PrintName = "Goa'uld Larva"
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_misc_cat") or "Misc Weapons"   -- AGP: one of our two weapon folders (was "Weapons": a folder of its own)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    SWEP.PrintName = SGLanguage.GetMessage("wp_goa_symb")
    SWEP.Category = SGLanguage.GetMessage("weapon_cat")
end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Ascension Gates"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_goauld_larva_p", "A young symbiote. It bites.") or "A young symbiote. It bites."
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_goauld_larva_i", "Left click: a bite\nRight click on a person: the symbiote takes them as its host\nRight click elsewhere: it shrieks and lunges") or "Left click: a bite\nRight click on a person: the symbiote takes them as its host\nRight click elsewhere: it shrieks and lunges"
SWEP.Base = "weapon_base"
SWEP.Slot = 0
SWEP.SlotPos = 6
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_bugbait.mdl"   -- GMod's bug bait animations (our larva is drawn in the hand)
SWEP.ViewModelFOV = 54
SWEP.WorldModel = "models/agp_weapons/w_goauld_larva.mdl"
SWEP.HoldType = "knife"
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

-- AGP: reach 64 / 84 from the eyes was shorter than any melee weapon (crowbar and EAP's larva: 75), so an NPC an
-- arm's length away or a small one at your feet was never reached; now 80 / 110
local BITE, BITE_REACH, BITE_DELAY = 10, 80, 0.7     -- left click
local LUNGE, LUNGE_REACH, LUNGE_DELAY = 24, 110, 1.5 -- right click
local SHRIEK = Sound("eap/weapons/larve.wav")         -- from the series

if SERVER then
    AddCSLuaFile()
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "BiteAt")     -- when the last strike started
    self:NetworkVar("Float", 1, "BiteLen")    -- how long it takes (the lunge is longer)
    self:NetworkVar("Float", 2, "BiteReach")  -- how far the head goes (model units)
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:SetBiteLen(1)
end

function SWEP:Deploy()
    self:EmitSound(SHRIEK, 72, 100)   -- (the series' sound - at its own pitch and a little louder; it was pitched up and quiet)
    return true
end

function SWEP:Strike(dmg, reach, len, stretch)
    local o = self:GetOwner()
    self:SetBiteAt(CurTime()); self:SetBiteLen(len); self:SetBiteReach(stretch)
    o:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)    -- the hand squeezes, the larva shoots forward
    if (o:IsPlayer()) then o:LagCompensation(true) end
    local src, aim = o:GetShootPos(), o:GetAimVector()
    -- AGP: first exactly where you aim, then a wider sweep (10 units, like GMod's fists) so a bite near the
    -- crosshair counts too (the 5 unit hull alone missed thin or small targets)
    local tr = util.TraceLine({ start = src, endpos = src + aim * reach, filter = o, mask = MASK_SHOT_HULL })
    if (not IsValid(tr.Entity)) then
        local tr2 = util.TraceHull({ start = src, endpos = src + aim * reach, filter = o,
            mins = Vector(-10, -10, -8), maxs = Vector(10, 10, 8), mask = MASK_SHOT_HULL })
        if (IsValid(tr2.Entity) or not tr.Hit) then tr = tr2 end
    end
    if (o:IsPlayer()) then o:LagCompensation(false) end
    local e = tr.Entity
    local living = IsValid(e) and (e:IsPlayer() or e:IsNPC() or e:IsNextBot() or e:GetClass() == "prop_ragdoll")
    if (tr.Hit and SERVER and IsValid(e)) then
        local d = DamageInfo()
        d:SetDamage(dmg); d:SetDamageType(DMG_SLASH); d:SetAttacker(o); d:SetInflictor(self)
        d:SetDamagePosition(tr.HitPos); d:SetDamageForce(aim * 300)
        e:TakeDamageInfo(d)
        -- AGP: a bite you can see: blood where it bit (TakeDamageInfo alone shows nothing), the victim's view jerks
        --
        if (living) then
            local blood = e.GetBloodColor and e:GetBloodColor() or BLOOD_COLOR_RED
            if (blood ~= DONT_BLEED) then
                local fx = EffectData()
                fx:SetOrigin(tr.HitPos); fx:SetNormal(-aim); fx:SetColor(blood); fx:SetScale(2)
                util.Effect("BloodImpact", fx, true, true)
                if (blood == BLOOD_COLOR_RED) then util.Decal("Blood", tr.HitPos + aim * -4, tr.HitPos + aim * 24, { o, self }) end
            end
            if (e:IsPlayer()) then e:ViewPunch(Angle(math.Rand(-6, -3), math.Rand(-4, 4), 0)) end
        end
    end
    if (tr.Hit and living) then
        self:EmitSound("npc/headcrab/headbite.wav", 70, math.random(120, 140))
    elseif (tr.Hit) then
        self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 60, math.random(120, 140))
    else
        self:EmitSound("npc/headcrab_poison/ph_jump" .. math.random(1, 3) .. ".wav", 55, math.random(150, 170))
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + BITE_DELAY)
    self:SetNextSecondaryFire(CurTime() + BITE_DELAY)
    self:Strike(BITE, BITE_REACH, 0.45, 2.5)
end

-- (the author's wish) right click on a person in reach: the symbiote takes him as its host
-- (lua/autorun/agp_goauld_host.lua) - the larva is gone from the hand, it is in the host now. Nobody in reach (or one
-- who is a Goa'uld already): the old shriek and lunge.
function SWEP:HostInReach()
    local o = self:GetOwner()
    if (not IsValid(o) or not o:IsPlayer()) then return end
    o:LagCompensation(true)
    local src, aim = o:GetShootPos(), o:GetAimVector()
    local tr = util.TraceLine({ start = src, endpos = src + aim * LUNGE_REACH, filter = o, mask = MASK_SHOT_HULL })
    if (not IsValid(tr.Entity)) then
        tr = util.TraceHull({ start = src, endpos = src + aim * LUNGE_REACH, filter = o, mins = Vector(-10, -10, -8), maxs = Vector(10, 10, 8), mask = MASK_SHOT_HULL })
    end
    o:LagCompensation(false)
    local e = tr.Entity
    if (not (AGP and AGP.GoauldCanTake and AGP.GoauldCanTake(e))) then return end
    -- another player: only where players may hurt each other
    if (e:IsPlayer() and hook.Run("PlayerShouldTakeDamage", e, o) == false) then return end
    return e, tr
end

function SWEP:SecondaryAttack()
    self:SetNextPrimaryFire(CurTime() + LUNGE_DELAY)
    self:SetNextSecondaryFire(CurTime() + LUNGE_DELAY)
    self:EmitSound(SHRIEK, 78, 100)
    if (SERVER) then
        local host, tr = self:HostInReach()
        if (host) then
            local o = self:GetOwner()
            self:SetBiteAt(CurTime()); self:SetBiteLen(0.7); self:SetBiteReach(4.5)
            o:SetAnimation(PLAYER_ATTACK1)
            self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
            host:EmitSound("npc/headcrab/headbite.wav", 75, math.random(95, 110))
            local fx = EffectData()
            fx:SetOrigin(tr.HitPos); fx:SetNormal(-o:GetAimVector()); fx:SetColor(BLOOD_COLOR_RED); fx:SetScale(2)
            util.Effect("BloodImpact", fx, true, true)
            AGP.GoauldTake(host, o)
            timer.Simple(0.45, function() if (IsValid(o) and IsValid(self) and o:HasWeapon("goauld_larva")) then o:StripWeapon("goauld_larva") end end)
            return
        end
    end
    self:Strike(LUNGE, LUNGE_REACH, 0.7, 4.5)
end

-- the larva's pose, every frame (bones of our model, see agp_goauld_weapons_models.py): bone axes are the larva's
-- own - Z along the body to the head, Y its back - so pitch bends it side to side, roll up and down
local TAIL = { "tail1", "tail2", "tail3", "tail4" }
local NECK = { "neck1", "neck2", "head" }
local function pose(self, ent)
    local t = CurTime() * 1.0 + self:EntIndex() * 0.37
    local held = IsValid(self:GetOwner())
    local wild = held and 1 or 1.6                                   -- dropped, it thrashes
    -- the strike: out fast with the jaw open, the jaw snaps shut, back slowly
    local k = math.Clamp((CurTime() - (self.GetBiteAt and self:GetBiteAt() or 0)) / math.max(0.1, self.GetBiteLen and self:GetBiteLen() or 1), 0, 1)
    local out = k < 1 and (k < 0.3 and math.sin(k / 0.3 * math.pi / 2) or 1 - (k - 0.3) / 0.7) or 0
    local open = k < 0.35 and math.sin(k / 0.35 * math.pi) or 0
    open = math.max(open, 0.12 * math.max(0, math.sin(t * 2.3)) ^ 6)  -- now and then it tastes the air
    for i, name in ipairs(TAIL) do
        local b = ent:LookupBone(name)
        if (b) then
            ent:ManipulateBoneAngles(b, Angle(math.sin(t * 5.5 * wild - i * 0.9) * (6 + 5 * i) * wild, 0, held and -6 or 0))
        end
    end
    for i, name in ipairs(NECK) do
        local b = ent:LookupBone(name)
        if (b) then
            local sway = (1 - out) * math.sin(t * 3.1 * wild + i * 0.8) * (4 + 2 * i) * wild
            ent:ManipulateBoneAngles(b, Angle(sway, 0, (1 - out) * math.sin(t * 1.7 + i) * 4))
        end
    end
    local hb = ent:LookupBone("head")
    if (hb) then ent:ManipulateBonePosition(hb, Vector(0, 0, out * (self.GetBiteReach and self:GetBiteReach() or 2.5))) end
    for j = 1, 4 do
        local b = ent:LookupBone("jaw_" .. j)
        if (b) then
            local phi = math.rad(45 + 90 * (j - 1))
            local a = Angle(0, 0, 0)
            a:RotateAroundAxis(Vector(-math.sin(phi), math.cos(phi), 0), open * 38)
            ent:ManipulateBoneAngles(b, a)
        end
    end
end

AGP.SGCWeapon(SWEP, {
    model = "models/agp_weapons/w_goauld_larva.mdl", icon = "vgui/weapons/agp_goauld_larva_inventory",
    vmBone = "ValveBiped.Bip01_R_Hand", vmHand = true,
    -- our hand bone on the bug bait's hand bone: the larva's middle where the pod sits (agp_goauld_weapons_build.py)
    vmPos = Vector(0.992, -2.290, 0.503), vmAng = Angle(9.58, 0.89, 5.74),
    -- ... and turned so the head points ahead of you (a little left and up), its back up
    vmLook = { head = Vector(1, 0.15, 0.12), top = Vector(0, 0, 1) },
    designInHand = { Vector(2.150, -1.470, 0.000), Angle(15.35, 180.00, -173.45) },   -- agp_goauld_weapons_build.py
    animate = CLIENT and pose or nil,
})
