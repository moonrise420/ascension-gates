--[[
	Ori Hand Weapon - Ascension Gates' own code; no Evolution Addon Pack content left (the class name stays for saves).
	The power the Ori give their chosen, out of the bare hand: a white-gold light burns in the palm. Left click:
	a blast of Ori fire (CAP's energy pulse, the Ori staff's sound). Right click: a telekinetic shove that throws
	whoever and whatever is in front of you back, the way Adria and the Priors do in the series. First
	person: GMod's own hands with the fists animations; no model of its own.
]]
SWEP.PrintName = "Ori Hand Weapon"
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_cat") or "Player Weapons"   -- AGP: one of our two weapon folders (was "Player Weapons": a folder of its own)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    SWEP.PrintName = SGLanguage.GetMessage("wp_ori_hand")
    SWEP.Category = SGLanguage.GetMessage("weapon_cat")
end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Ascension Gates"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_ori_hand_weapon_p", "The power of the Ori in your hand.") or "The power of the Ori in your hand."
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_ori_hand_weapon_i", "Left click: Ori fire\nRight click: a telekinetic shove") or "Left click: Ori fire\nRight click: a telekinetic shove"
SWEP.Base = "weapon_base"
SWEP.Slot = 3
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"   -- GMod's own hands (the fists animations)
SWEP.ViewModelFOV = 54
SWEP.WorldModel = ""   -- nothing in the world: the palm light is drawn after the player model (PostPlayerDraw below)
SWEP.UseHands = true
SWEP.HoldType = "magic"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local BLAST_DELAY, BLAST_DAMAGE = 0.6, 100
local SHOVE_DELAY, SHOVE_RANGE, SHOVE_DAMAGE = 1.2, 320, 8
local SND_BLAST = Sound("pulse_weapon/ori_staff.wav")                    -- CAP: the Ori staff (from the series)
local SND_SHOVE = Sound("weapons/physcannon/superphys_launch2.wav")      -- Half-Life 2
local GLOW = CLIENT and Material("sprites/light_glow02_add")

if SERVER then
    AddCSLuaFile()
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "CastAt")    -- the palm flares
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- AGP: never left lying around - without a world model a dropped one was an invisible pick-up (on death or
-- dropped); GMod's fists do the same
function SWEP:ShouldDropOnDie() return false end
if SERVER then
    function SWEP:OnDrop() self:Remove() end
end

local function play(self, name)
    local o = self:GetOwner()
    local vm = IsValid(o) and o:IsPlayer() and o:GetViewModel()
    if (not IsValid(vm)) then return end
    local seq = vm:LookupSequence(name)
    if (seq and seq >= 0) then vm:SendViewModelMatchingSequence(seq); vm:SetPlaybackRate(1) end
    self.AGPIdleAt = CurTime() + (seq and seq >= 0 and vm:SequenceDuration(seq) or 0.5)
end

function SWEP:Deploy()
    play(self, "fists_draw")
    return true
end

function SWEP:Think()
    if (self.AGPIdleAt and CurTime() > self.AGPIdleAt) then
        self.AGPIdleAt = nil
        play(self, "fists_idle_0" .. math.random(1, 2)); self.AGPIdleAt = nil
    end
end

function SWEP:PrimaryAttack()
    local o = self:GetOwner()
    self:SetNextPrimaryFire(CurTime() + BLAST_DELAY)
    self:SetNextSecondaryFire(CurTime() + BLAST_DELAY)
    self:SetCastAt(CurTime())
    play(self, "fists_right")
    o:SetAnimation(PLAYER_ATTACK1)
    if (o:IsPlayer()) then o:ViewPunch(Angle(-2, 0, 0)) end
    if (CLIENT) then return end
    -- out of the right hand, towards what the crosshair is on
    local aim = o:GetAimVector()
    local from = o:GetShootPos() + aim * 30 + o:EyeAngles():Right() * 8 - Vector(0, 0, 6)
    local tr = util.QuickTrace(o:GetShootPos(), aim * 16384, { o, self })
    local dir = (tr.HitPos - from):GetNormalized()
    if (dir:Dot(aim) <= 0) then dir = aim end
    local e = ents.Create("energy_pulse")
    if (IsValid(e)) then
        e:SetPos(from)
        e:PrepareBullet(dir, o:IsPlayer() and (o:Crouching() and 0.3 or 1) or 0, 8000, 2)
        e:SetOwner(o); e.Owner = o
        e:SetColor(Color(255, 236, 190, 215))      -- white-gold Ori fire
        e:Spawn(); e:Activate()
        e.Damage = BLAST_DAMAGE
    end
    o:EmitSound(SND_BLAST, 90, math.random(95, 110))
end

-- telekinesis: everything in a cone in front of you is thrown back
function SWEP:SecondaryAttack()
    local o = self:GetOwner()
    self:SetNextSecondaryFire(CurTime() + SHOVE_DELAY)
    self:SetNextPrimaryFire(CurTime() + 0.4)
    self:SetCastAt(CurTime())
    play(self, "fists_left")
    o:SetAnimation(PLAYER_ATTACK1)
    if (o:IsPlayer()) then o:ViewPunch(Angle(-3, 2, 0)) end
    if (CLIENT) then return end
    o:EmitSound(SND_SHOVE, 80, math.random(110, 125))
    local src, aim = o:GetShootPos(), o:GetAimVector()
    for _, e in ipairs(ents.FindInSphere(src, SHOVE_RANGE)) do
        if (e == o or not IsValid(e) or e:GetOwner() == o) then continue end
        local to = e:WorldSpaceCenter() - src
        local d = to:Length()
        if (d < 1 or to:GetNormalized():Dot(aim) < 0.8) then continue end
        local push = (to:GetNormalized() + Vector(0, 0, 0.35)):GetNormalized() * 700 * (1 - 0.5 * d / SHOVE_RANGE)
        if (e:IsPlayer() or e:IsNPC()) then
            if (e:IsPlayer() or e:GetMoveType() == MOVETYPE_STEP) then e:SetVelocity(push) end
            local dmg = DamageInfo()
            dmg:SetDamage(SHOVE_DAMAGE); dmg:SetDamageType(DMG_CLUB); dmg:SetAttacker(o); dmg:SetInflictor(self)
            dmg:SetDamageForce(push * 40); dmg:SetDamagePosition(e:WorldSpaceCenter())
            e:TakeDamageInfo(dmg)
        else
            local phys = e:GetPhysicsObject()
            if (IsValid(phys) and phys:IsMotionEnabled()) then phys:ApplyForceCenter(push * phys:GetMass()) end
        end
    end
end

if CLIENT then
    -- the light in the palm: steady, flaring when you cast
    local function palm(ent, flare)
        local b = ent:LookupBone("ValveBiped.Bip01_R_Hand")
        local m = b and ent:GetBoneMatrix(b)
        if (not m) then return end
        local pos = m:GetTranslation() + m:GetForward() * 3.5 + m:GetRight() * 1.2
        local pulse = 0.8 + 0.2 * math.sin(CurTime() * 9)
        render.SetMaterial(GLOW)
        render.DrawSprite(pos, 6 + 18 * flare, 6 + 18 * flare, Color(255, 236, 190, (110 + 145 * flare) * pulse))
        render.DrawSprite(pos, 2 + 6 * flare, 2 + 6 * flare, Color(255, 255, 255, 200 * pulse))
        return pos
    end
    local function flare(self) return math.Clamp(1 - (CurTime() - self:GetCastAt()) / 0.4, 0, 1) end
    function SWEP:PostDrawViewModel(vm, wep, ply)
        local hands = IsValid(ply) and ply:GetHands()
        palm(IsValid(hands) and hands or vm, flare(self))
    end
    -- AGP: third person: drawn after the player model. With an empty WorldModel GMod never draws the weapon itself, so
    -- this was SWEP:DrawWorldModel, never called, and nobody else saw the light in the palm
    local function worldPalm(self, o)
        local f = flare(self)
        local pos = palm(o, f)
        if (pos and f > 0) then
            local d = DynamicLight(self:EntIndex())
            if (d) then d.pos = pos; d.r, d.g, d.b = 255, 230, 180; d.brightness = 2 * f; d.size = 160; d.decay = 1000; d.dietime = CurTime() + 0.1 end
        end
    end
    hook.Add("PostPlayerDraw", "AGP.OriHand.PalmLight", function(ply)
        local w = ply:GetActiveWeapon()
        if (IsValid(w) and w:GetClass() == "ori_hand_weapon") then worldPalm(w, ply) end
    end)
end
