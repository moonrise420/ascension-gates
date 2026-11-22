--[[
	Ascension Gates (own code): base of our one-dose injectors (Wraith enzyme, tretonin), not spawnable. AGP: they
	inject like the adrenaline / ATA gene shot, the needle towards yourself. First person: GMod's
	small-object grip (c_bugbait) with the player's own hands, our injector in the fist on its hand bone; the squeeze
	presses it, the plunger goes in and the liquid runs out, then it is gone. Third person: held in the fist like
	a dagger the wrong way round, the needle down at the thigh (the hand frame of our models); the plunger and the
	liquid move there too. A weapon sets SWEP.WorldModel (one of our injector models: bones body,
	plunger, liquid, cap), SWEP.PlungerTravel (model units), SWEP.CapPivot (the cap bone's pivot), SWEP.InjectSound
	and SWEP:AGPInject(ply) (server: what the dose does), optionally SWEP:AGPCanInject(ply) -> ok, message.

]]
SWEP.Base = "weapon_base"
SWEP.PrintName = "Injector"
SWEP.Author = "Ascension Gates"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.Slot = 4
SWEP.SlotPos = 6
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
-- AGP (the hands in first person must be the player's own): GMod's small-object grip with the player's own
-- hands (the adrenaline shot's view model had arms of its own); our injector in the fist on its hand bone
SWEP.ViewModel = "models/weapons/c_bugbait.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.HoldType = "slam"
SWEP.PlungerTravel = 0
SWEP.CapPivot = Vector(0, 0, 2.5)
SWEP.InjectSound = "items/medshot4.wav"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

-- AGP: times in the adrenaline shot's "heal" animation (91 frames at 30 fps, measured offline): the cap
-- comes off at ~0.95 s, the needle goes in at ~1.65 s, the empty injector is gone after ~2.4 s
local CAP_OFF, PUSH_AT, PUSH, DONE = 0.95, 1.65, 0.25, 3.0

if SERVER then
    AddCSLuaFile()
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "InjectAt")   -- 0 = not used yet
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

-- AGP: the shot's draw animation, then its idle (as sg_adrenaline.lua)
function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    self:SetNextPrimaryFire(CurTime() + 0.4)
    timer.Simple(0.35, function()
        if (IsValid(self) and IsValid(self:GetOwner()) and self:GetOwner():GetActiveWeapon() == self and self:GetInjectAt() <= 0) then
            self:SendWeaponAnim(ACT_VM_IDLE)
        end
    end)
    return true
end

function SWEP:PrimaryAttack()
    if (self:GetInjectAt() > 0) then return end
    local o = self:GetOwner()
    if (self.AGPCanInject) then
        local ok, msg = self:AGPCanInject(o)
        if (not ok) then
            if (SERVER and msg and o:IsPlayer()) then o:PrintMessage(HUD_PRINTTALK, msg) end
            self:SetNextPrimaryFire(CurTime() + 1)
            return
        end
    end
    -- AGP: the adrenaline shot's injection (its view model animation) instead of the hand going to the thigh
    self:SetNextPrimaryFire(CurTime() + DONE + 0.4)
    self:SetInjectAt(CurTime())
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)   -- AGP: the bug bait squeeze (the fist presses the injector)
    if (SERVER) then
        timer.Simple(CAP_OFF, function()
            if (IsValid(self)) then self:EmitSound("weapons/smg1/switch_single.wav", 45, 160) end   -- the cap pops off
        end)
        timer.Simple(PUSH_AT, function()
            if (IsValid(self)) then self:EmitSound(self.InjectSound, 60, math.random(95, 105)) end
        end)
        timer.Simple(PUSH_AT + PUSH * 0.6, function()
            if (IsValid(self) and IsValid(self:GetOwner()) and self:GetOwner():Alive()) then self:AGPInject(self:GetOwner()) end
        end)
        timer.Simple(DONE, function()
            if (IsValid(self) and IsValid(self:GetOwner())) then self:GetOwner():StripWeapon(self:GetClass()) end
        end)
    end
end

function SWEP:SecondaryAttack()
end

-- 0 .. 1: how far the dose has gone in
function SWEP:Dose()
    local a = self:GetInjectAt()
    if (a <= 0) then return 0 end
    return math.Clamp((CurTime() - a - PUSH_AT) / PUSH, 0, 1)
end

-- our model: the plunger goes in, the liquid runs out (bones "plunger" and "liquid"); the cap (bone "cap"):
-- capPos / capAng = where the pen's cap has taken it (first person, in the design frame of bone "body"),
-- else on the needle when the injector lies about, gone while it is held (the bare needle towards the body)
-- AGP: those bones have no turn of their own below "body", so the offsets act along the design axes
function SWEP:AGPPose(ent, capPos, capAng)
    local d = self:Dose()
    local b = ent:LookupBone("plunger")
    if (b) then ent:ManipulateBonePosition(b, Vector(0, 0, self.PlungerTravel * d)) end
    local l = ent:LookupBone("liquid")
    if (l) then ent:ManipulateBoneScale(l, Vector(1, 1, math.max(0.02, 1 - d))) end
    local c = ent:LookupBone("cap")
    if (not c) then return end
    if (capPos) then
        local piv = self.CapPivot
        ent:ManipulateBonePosition(c, LocalToWorld(piv, angle_zero, capPos, capAng) - piv)
        ent:ManipulateBoneAngles(c, capAng)
        ent:ManipulateBoneScale(c, Vector(1, 1, 1))
    else
        ent:ManipulateBonePosition(c, vector_origin)
        ent:ManipulateBoneAngles(c, angle_zero)
        ent:ManipulateBoneScale(c, IsValid(self:GetOwner()) and Vector(0.01, 0.01, 0.01) or Vector(1, 1, 1))
    end
end

if CLIENT then
    local HIDE = "engine/occlusionproxy"   -- as agp_sgc_weapons.lua hides the HL2 guns

    function SWEP:AGPViewModel()
        if (not IsValid(self.AGPCS)) then
            self.AGPCS = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE)
            if (IsValid(self.AGPCS)) then self.AGPCS:SetNoDraw(true) end
            self.AGPOrigin = nil
        end
        return self.AGPCS
    end

    -- the model origin seen from its hand bone (read once)
    local function originInHand(m)
        local b = m:LookupBone("ValveBiped.Bip01_R_Hand")
        if (not b) then return end
        m:SetPos(vector_origin); m:SetAngles(angle_zero); m:SetupBones()
        local bm = m:GetBoneMatrix(b)
        if (not bm) then return end
        local lp, la = WorldToLocal(vector_origin, angle_zero, bm:GetTranslation(), bm:GetAngles())
        return { lp, la }
    end

    function SWEP:PreDrawViewModel(vm)
        vm:SetMaterial(HIDE)   -- GMod's bug bait disappears, the hands stay
    end

    function SWEP:PostDrawViewModel(vm)
        vm:SetMaterial("")
        local hb = vm:LookupBone("ValveBiped.Bip01_R_Hand")
        local hm = hb and vm:GetBoneMatrix(hb)
        local m = self:AGPViewModel()
        if (not hm or not IsValid(m)) then return end
        self.AGPHandOrigin = self.AGPHandOrigin or originInHand(m)
        local o = self.AGPHandOrigin
        if (not o) then return end
        local op, oa = LocalToWorld(o[1], o[2], hm:GetTranslation(), hm:GetAngles())
        m:SetPos(op); m:SetAngles(oa)
        self:AGPPose(m)   -- (the cap is off while it is held)
        m:SetupBones()
        m:DrawModel()
    end

    function SWEP:DrawWorldModel()
        self:AGPPose(self)
        self:DrawModel()
    end

    function SWEP:Holster()
        local o = self:GetOwner()
        local vm = IsValid(o) and o.GetViewModel and o:GetViewModel()
        if (IsValid(vm)) then vm:SetMaterial("") end   -- the view model is shared
        return true
    end

    function SWEP:OnRemove()
        if (IsValid(self.AGPCS)) then self.AGPCS:Remove() end
    end
end
