if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("weapon")) then return end

if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_dagger");
SWEP.Category = SGLanguage.GetMessage("weapon_cat");
else
SWEP.PrintName = "Dagger";
end
SWEP.Author			= "Rafael De Jongh, Madman07";
SWEP.Contact		= "";
SWEP.Instructions	= "Left click to stab!";
SWEP.Purpose		= "Kill Jaffa's symbionts.";

SWEP.Slot = 3;
SWEP.SlotPos = 3;
SWEP.DrawAmmo = false;
SWEP.DrawCrosshair = true;
SWEP.ViewModelFOV	= 70
SWEP.ViewModelFlip	= false
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP);

SWEP.ViewModel      = "models/weapons/v_knife_d.mdl"
SWEP.WorldModel   = "models/weapons/w_knife_d.mdl"

SWEP.Primary.Delay			= 0.9
SWEP.Primary.Recoil			= 0
SWEP.Primary.Damage			= 35
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0
SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic   	= true
SWEP.Primary.Ammo         	= "none"

SWEP.Secondary.Delay		= 0.9
SWEP.Secondary.Recoil		= 0
SWEP.Secondary.Damage		= 70
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic   	= true
SWEP.Secondary.Ammo         = "none"

util.PrecacheSound("dagger/knife_deploy1.wav")
util.PrecacheSound("dagger/knife_hitwall1.wav")
util.PrecacheSound("dagger/knife_hit1.wav")
util.PrecacheSound("dagger/knife_hit2.wav")
util.PrecacheSound("dagger/knife_hit3.wav")
util.PrecacheSound("dagger/knife_hit4.wav")
util.PrecacheSound("dagger/knife_slash1.wav")


-- Lol, without this we can't use this weapon in mp on gmod13...
if SERVER then
   
    AddCSLuaFile()


end

function SWEP:Initialize()
    self:SetWeaponHoldType("knife")
    self.Hit = Sound("dagger/knife_hitwall1.wav")
    self.Slash = Sound("dagger/knife_slash1.wav")

    self.FleshHit = {
        [1] = Sound("dagger/knife_hit1.wav"),
        [2] = Sound("dagger/knife_hit2.wav"),
        [3] = Sound("dagger/knife_hit3.wav"),
        [4] = Sound("dagger/knife_hit4.wav")
    }

    self.NextHit = 0
end

function SWEP:PrimaryAttack()
    if (CurTime() < self.NextHit) then return end
    self.NextHit = (CurTime() + 0.5)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_HITCENTER)
    local tr = self.Owner:GetEyeTrace()

    if tr.HitPos:Distance(self.Owner:GetShootPos()) <= 75 then
        if (SERVER) then
            local ent = tr.Entity

            if (ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll") then
                self.Owner:EmitSound(self.FleshHit[math.random(1, 4)])
            else
                self.Owner:EmitSound(self.Hit)
            end
        end
-- Wire experiments
        --     --print(self:GetPorts(tr.Entity))

        self:Hurt(5)
    elseif SERVER then
        self:EmitSound(self.Slash)
    end
    
end

function SWEP:SecondaryAttack()
    if (CurTime() < self.NextHit) then return end
    self.NextHit = (CurTime() + 1)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_HITCENTER)
    local tr = self.Owner:GetEyeTrace()

    if tr.HitPos:Distance(self.Owner:GetShootPos()) <= 75 then
        if (SERVER) then
            local ent = tr.Entity

            if (ent:IsPlayer() or ent:IsNPC() or ent:GetClass() == "prop_ragdoll") then
                self.Owner:EmitSound(self.FleshHit[math.random(1, 4)])
            else
                self.Owner:EmitSound(self.Hit)
            end
        end

        self:Hurt(10)
    elseif SERVER then
        self:EmitSound(self.Slash)
    end
end

function SWEP:Hurt(damage)
    -- AGP 2026-11-12: a blade, not a bullet (CAP fired a bullet here: bullet holes in walls, bullet damage) - a short
    -- trace, slash damage, a cut mark where it meets a wall
    if (CLIENT) then return end
    local o = self.Owner
    if (not IsValid(o)) then return end
    local src, dir = o:GetShootPos(), o:GetAimVector()
    o:LagCompensation(true)
    local tr = util.TraceLine({ start = src, endpos = src + dir * 80, filter = o, mask = MASK_SHOT_HULL })
    if (not tr.Hit) then
        tr = util.TraceHull({ start = src, endpos = src + dir * 80, filter = o, mins = Vector(-6, -6, -6), maxs = Vector(6, 6, 6), mask = MASK_SHOT_HULL })
    end
    o:LagCompensation(false)
    if (not tr.Hit) then return end
    if (IsValid(tr.Entity)) then
        local d = DamageInfo()
        d:SetAttacker(o); d:SetInflictor(self)
        d:SetDamage(damage); d:SetDamageType(DMG_SLASH)
        d:SetDamagePosition(tr.HitPos); d:SetDamageForce(dir * 2000)
        tr.Entity:TakeDamageInfo(d)
    elseif (tr.HitWorld) then
        util.Decal("ManhackCut", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal, o)
    end
end

function SWEP:Deploy()
    self.Owner:EmitSound("dagger/knife_deploy1.wav")

    return true
end

function SWEP:Precache()
end

if CLIENT then
    -- Inventory Icon
    if (file.Exists("materials/VGUI/weapons/dagger_inventory.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/dagger_inventory")
    end

    -- Kill Icon (AGP 2026-11-08: knife_kill never existed and the icon was registered for "KRD" (the Kino remote's
    -- name), not for the dagger: the dagger's own picture, killicon scales it to the killfeed line like the Kino remote's)
    if (file.Exists("materials/VGUI/weapons/dagger_inventory.vmt", "GAME")) then
        killicon.Add("dagger", "VGUI/weapons/dagger_inventory", Color(255, 255, 255))
    end
end

-- AGP 2026-11-12 (owner: "CAP's is way better held in the hand - why can't we have it exactly the same way"): CAP's own
-- first-person model and animations, with the player's own hands laid onto its arm skeleton
-- (lua/autorun/agp_blueprint_arms.lua). 2026-11-10's GMod hand animations never fitted this item.
if (AGP and AGP.BlueprintArms) then
    AGP.BlueprintArms(SWEP, { vm = "models/weapons/v_knife_d.mdl", hide = { "v_hands" }, arms = AGP.BlueprintRigs.knife })
end
