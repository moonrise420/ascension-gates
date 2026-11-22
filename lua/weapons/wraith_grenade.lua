if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
	SWEP.Category = SGLanguage.GetMessage("weapon_cat");
	SWEP.PrintName = SGLanguage.GetMessage("weapon_wraith_grenade");
end
SWEP.Author = "Ronon Dex, AlexALX"
SWEP.Contact = ""
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_wraith_grenade_p", "Blow things up.") or "Blow things up."
SWEP.Instructions = ""
SWEP.Base = "weapon_base"
SWEP.Slot = 4
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/pg_props/pg_weapons/pg_wraith_hands_granate.mdl"
SWEP.WorldModel = "models/pg_props/pg_weapons/pg_wraith_hands_granate_w.mdl"
SWEP.ViewModelFOV = 65

if SERVER then
    AddCSLuaFile()
end

SWEP.HoldType = "grenade"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Sounds = {
    feeling = Sound("weapons/wraith_feeding.wav"),
    SwingSound = Sound("weapons/slam/throw.wav"),
    HitSound = Sound("Flesh.ImpactHard")
}

list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)
SWEP.Ammo = 3

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
end

function SWEP:Deploy()
    self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
end

if SERVER then
    local GRENADE_RADIUS = 4.0

    -- Thanks to swep-bases code
    function SWEP:CheckThrowPosition(pPlayer, vecEye, vecSrc)
        local tr
        tr = {}
        tr.start = vecEye
        tr.endpos = vecSrc
        tr.mins = -Vector(GRENADE_RADIUS + 2, GRENADE_RADIUS + 2, GRENADE_RADIUS + 2)
        tr.maxs = Vector(GRENADE_RADIUS + 2, GRENADE_RADIUS + 2, GRENADE_RADIUS + 2)
        tr.mask = MASK_PLAYERSOLID
        tr.filter = pPlayer
        tr.collision = pPlayer:GetCollisionGroup()
        local trace = util.TraceHull(tr)

        if (trace.Hit) then
            vecSrc = trace.HitPos -- AGP: where the trace stopped (was tr.endpos = the wanted spot, maybe in the wall)
        end

        return vecSrc
    end

    function SWEP:ThrowGrenade()
        if (not IsValid(self) or not IsValid(self.Owner)) then return end
        local pPlayer = self.Owner
        local vecEye = pPlayer:EyePos()
        local vForward, vRight
        -- AGP: along the aim like HL2's grenade (eye direction, then a little up); GetForward() of a player is level,
        -- so looking up or down was ignored and every throw went flat
        local eyeAng = pPlayer:EyeAngles()
        vForward = eyeAng:Forward()
        vRight = eyeAng:Right()
        local vecSrc = vecEye + vForward * 18.0 + vRight * 8.0
        vecSrc = self:CheckThrowPosition(pPlayer, vecEye, vecSrc)
        vForward = vForward + Vector(0, 0, 0.1)
        local vecThrow
        vecThrow = pPlayer:GetVelocity()
        vecThrow = vecThrow + vForward * 1200
        local pGrenade = ents.Create("wraiths_grenade")
        pGrenade:SetOwner(pPlayer)
        pGrenade:SetPos(vecSrc)
        pGrenade:SetAngles(Angle())
        pGrenade:Spawn()
        pGrenade:GetPhysicsObject():SetVelocity(vecThrow)
        pGrenade:GetPhysicsObject():AddAngleVelocity(Vector(600, math.random(-1200, 1200), 0))

        if (pGrenade) then
            if (pPlayer and not pPlayer:Alive()) then
                vecThrow = pPlayer:GetVelocity()
                local pPhysicsObject = pGrenade:GetPhysicsObject()

                if (pPhysicsObject) then
                    vecThrow = pPhysicsObject:SetVelocity()
                end
            end

            pGrenade.m_flDamage = self.Primary.Damage
            pGrenade.m_DmgRadius = GRENADE_DAMAGE_RADIUS
        end
    end

    function SWEP:Think()
        if (self.Throw and self.Throw < CurTime()) then
            self:ThrowGrenade()
            self.Throw = false
            self.Ammo = self.Ammo - 1
            self.Owner:EmitSound(self.Sounds.SwingSound, 75, math.random(80, 120))

            if (self.Ammo <= 0) then
                self:Remove()
            else
                timer.Simple(0.6, function()
                    if (IsValid(self.Weapon)) then
                        self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
                    end
                end)
            end
        end
    end
end

function SWEP:PrimaryAttack()
    if SERVER then
        timer.Simple(0.5, function()
            if (IsValid(self.Owner)) then
                self.Owner:SetAnimation(PLAYER_ATTACK1)
            end
        end)
    end

    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

    if SERVER then
        self.Throw = CurTime() + 1.0
    end

    self:SetNextPrimaryFire(CurTime() + 1.75)
end

function SWEP:SecondaryAttack()
    self.Weapon:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

    if SERVER then
        timer.Simple(1, function()
            if (not IsValid(self) or not IsValid(self.Owner)) then return end
            local ply = self.Owner
            -- AGP: put it on the ground in front of the player (it was dropped at a fixed map offset, often behind him,
            -- without a sound, so it looked like nothing happened)
            local fwd = ply:GetAimVector(); fwd.z = 0
            if (fwd:LengthSqr() < 0.01) then fwd = ply:GetForward() end
            fwd:Normalize()
            local from = ply:GetPos() + Vector(0, 0, 20)
            local front = util.TraceLine({ start = from, endpos = from + fwd * 40, filter = ply }).HitPos - fwd * 6
            local down = util.TraceLine({ start = front, endpos = front - Vector(0, 0, 200), filter = ply })
            local e = ents.Create("wraiths_grenade")
            e.Mine = true -- before Spawn: Initialize keeps it
            e.Owner = ply
            e:SetPos(down.HitPos + Vector(0, 0, 4))
            e:SetAngles(Angle(0, ply:EyeAngles().y, 0))
            e:Spawn()
            e:Activate()
            e.CanExplode = CurTime() + 2
            e:EmitSound("weapons/slam/mine_mode.wav", 45, 90, 0.4) -- a quiet click, heard only right next to it
            -- the hint goes only to this player, and only for his first mine
            if (AGP and AGP.Hint) then
                AGP.Hint(ply, "agp_wraith_mine_armed", "Wraith mine placed: armed in 2 s, it blows up when someone else comes within %s units. Press E on it to pick it up again.", e.DetectRange or 200)
            end
            local p = e:GetPhysicsObject()

            if (IsValid(p)) then
                p:Wake()
            end

            --if(IsValid(self.Owner) and self.Owner:IsPlayer()) then self:TakePrimaryAmmo(1) end; -- Take one Ammo
            self.Ammo = self.Ammo - 1

            if (self.Ammo <= 0) then
                self:Remove()
            else
                timer.Simple(1.3, function()
                    if (IsValid(self.Weapon)) then
                        self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
                    end
                end)
            end
        end)
    end

    self:SetNextSecondaryFire(CurTime() + 2.5)
end
-- AGP: the player's own hands (GMod's hands of the player model) instead of the arms built into the old view model
if (AGP and AGP.OwnHands) then AGP.OwnHands(SWEP, { "pg_wraith_hands_v2" }) end
