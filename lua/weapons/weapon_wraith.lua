if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.Category = SGLanguage.GetMessage("weapon_cat");
SWEP.PrintName = SGLanguage.GetMessage("weapon_wraith");
end
SWEP.Author = "Ronon Dex"
SWEP.Contact = ""
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_weapon_wraith_p", "Feed on a human (Wraith)") or "Feed on a human (Wraith)"
SWEP.Instructions = ""
SWEP.Base = "weapon_base"
SWEP.Slot = 1
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/pg_props/pg_weapons/pg_wraith_hands.mdl"
SWEP.WorldModel = "models/Weapons/w_bugbait.mdl"

if SERVER then
    AddCSLuaFile()
end

if CLIENT then
    if (file.Exists("materials/VGUI/weapons/wraith_hands.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/wraith_hands.vmt")
    end
end

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
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

SWEP.HitDistance = 67
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

function SWEP:Deploy()
    self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
end

function SWEP:Holster()
    -- AGP: the run speed and jump the player had before feeding come back (CAP set run 500 / jump 200 on every
    -- holster, also when he had never fed - faster than sandbox's 400)
    if SERVER then
        self:AGPFeedSpeed(nil)
    end

    return true
end

function SWEP:Initialize()
    self.NextHit = 0
    self.Hit = Sound("player/pl_fallpain1.wav")
    self:SetWeaponHoldType("fist")
end

function SWEP:PrimaryAttack()
    if (CurTime() < self.NextHit) then return end
    self.NextHit = (CurTime() + 0.65)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)

    timer.Simple(0.57, function()
        if (IsValid(self)) then
            self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
        end
    end)

    if (SERVER) then
        self.Owner:EmitSound(self.Sounds.SwingSound)
        self:DealDamage()
    end
end

function SWEP:SecondaryAttack()
    if (CurTime() < self.NextHit) then return end
    self.NextHit = (CurTime() + 0.55)

    timer.Simple(0.47, function()
        if (IsValid(self)) then
            self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
        end
    end)

    timer.Simple(0.1, function()
        if (IsValid(self)) then
            self.Owner:SetAnimation(PLAYER_ATTACK1)
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK_2)
            self.Weapon:SetNextSecondaryFire(CurTime() + 0.5)
        end
    end)
end

function SWEP:DealDamage()
    local tr = util.TraceLine({
        start = self.Owner:GetShootPos(),
        endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
        filter = self.Owner
    })

    if (not IsValid(tr.Entity)) then
        tr = util.TraceHull({
            start = self.Owner:GetShootPos(),
            endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
            filter = self.Owner,
            mins = self.Owner:OBBMins() / 3,
            maxs = self.Owner:OBBMaxs() / 3
        })
    end

    if (tr.Hit) then
        self.Owner:EmitSound(self.Sounds.HitSound)
    end

    if (IsValid(tr.Entity)) then
        local dmginfo = DamageInfo()
        dmginfo:SetDamage(20)
        dmginfo:SetDamageForce(self.Owner:GetRight() * 49125 + self.Owner:GetForward() * 99984)
        dmginfo:SetInflictor(self)
        local attacker = self.Owner

        if (not IsValid(attacker)) then
            attacker = self
        end

        dmginfo:SetAttacker(attacker)
        tr.Entity:TakeDamageInfo(dmginfo)
    end
end

if SERVER then
    local col = 255

    -- AGP: feeding speeds by health, highest first (CAP's numbers; at 401+ the run speed of 301+ stays)
    local FEED_STEPS = {
        { hp = 500, run = 1000, jump = 800 },
        { hp = 401, run = 850, jump = 400 },
        { hp = 301, run = 850 },
        { hp = 201, run = 750 },
    }

    function SWEP:Think()
        if self.Owner:KeyDown(IN_ATTACK2) then
            local eye_trace = self.Owner:GetEyeTrace()
            local e = eye_trace.Entity
            local pos = self.Owner:GetPos()

            if IsValid(e) then
                local target_pos = e:GetPos()
                local dist = (pos - target_pos):Length()

                if dist < 100 then
                    if self.Owner:Health() < 500 then
                        if e:IsNPC() then
                            local class = e:GetClass()
                            if class == "npc_manhack" then return end
                            if class == "npc_rollermine" then return end
                            e:TakeDamage(1, self.Owner)
                            self.Owner:SetHealth(self.Owner:Health() + 1)

                            if col > 90 then
                                col = col - 0.2
                            end

                            if (not self.Sound) then
                                self.Owner:EmitSound(self.Sounds.feeling, 100, 100)
                                self.Sound = true
                                self.SoundTime = CurTime() + 2
                            end
                        elseif e:IsPlayer() then
                            if (not e:HasGodMode()) then
                                e:TakeDamage(1, self.Owner)

                                if (not e.pShielded) then
                                    self.Owner:SetHealth(self.Owner:Health() + 1)
                                end
                            end

                            if (not self.Sound) then
                                self.Owner:EmitSound(self.Sounds.feeling, 100, 100)
                                self.Sound = true
                                self.SoundTime = CurTime() + 2
                            end
                        end
                    end
                end
            end
        else
            if (self.SoundTime and self.SoundTime < CurTime()) then
                self.Sound = false
            end
        end

        -- AGP: the feeding steps checked from the top (CAP asked "> 200" first, so 300 / 400 / 500 never came); set
        -- only when the step changes, and below 201 health the own speeds come back
        local hp = self:GetOwner():Health()
        local step

        for _, s in ipairs(FEED_STEPS) do
            if (hp >= s.hp) then
                step = s
                break
            end
        end

        if (step != self.AGPFeedStep) then
            self:AGPFeedSpeed(step)
        end
    end

    -- AGP: one feeding step on (the speeds he had before are kept aside), or nil: those speeds back
    function SWEP:AGPFeedSpeed(step)
        self.AGPFeedStep = step

        if (step) then
            local ply = self:GetOwner()
            if (not IsValid(ply) or not ply:IsPlayer()) then return end

            if (not self.AGPFeedBase) then
                self.AGPFeedBase = { ply = ply, run = StarGate.BaseRunSpeed(ply), jump = ply:GetJumpPower() }
            end

            StarGate.SetBaseRunSpeed(ply, step.run)
            ply:SetJumpPower(step.jump or self.AGPFeedBase.jump)
        elseif (self.AGPFeedBase) then
            local base = self.AGPFeedBase
            self.AGPFeedBase = nil

            if (IsValid(base.ply)) then
                StarGate.SetBaseRunSpeed(base.ply, base.run)
                base.ply:SetJumpPower(base.jump)
            end
        end
    end

    -- AGP: dropped, taken away or given to someone else while fed: the speeds come back too
    function SWEP:OnDrop()
        self:AGPFeedSpeed(nil)
    end

    function SWEP:OnRemove()
        self:AGPFeedSpeed(nil)
    end

    function SWEP:OwnerChanged()
        self:AGPFeedSpeed(nil)
    end

    function SWEP:TestAnim()
        local vm = self.Owner:GetViewModel()
        local seq = vm:LookupSequence("attackRight")
        vm:SetSequence(seq)
    end
end
-- AGP: the player's own hands (GMod's hands of the player model) instead of the arms built into the old view model
if (AGP and AGP.OwnHands) then AGP.OwnHands(SWEP, { "pg_wraith_hands_v2" }) end
