if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end

local HitImpact = function(attacker, tr, dmginfo)
    local hit = EffectData()
    hit:SetOrigin(tr.HitPos)
    hit:SetNormal(tr.HitNormal)
    hit:SetScale(20)
    util.Effect("effect_hit_fnp90", hit)

    return true
end

if SERVER then
    SWEP.Weight = 5
    SWEP.AutoSwitchTo = false -- Dont automatically switch to this weapon
    SWEP.AutoSwitchFrom = false -- Dont automatically swith from this weapon to another weapon..

    function SWEP:UnDrawModel()
        self.Owner:DrawViewModel(false)
    end

    function SWEP:ReDrawModel()
        self.Owner:DrawViewModel(true)
    end

    AddCSLuaFile()
end

if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_p90");
end

if CLIENT then
    SWEP.Slot = 2
    SWEP.SlotPos = 1
    SWEP.IconLetter = "m"
    SWEP.DrawAmmo = false -- our own ammo + fire mode panel (DrawHUD) replaces the HL2 ammo box, so they never overlap
    SWEP.DrawCrosshair = false
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
    SWEP.CSMuzzleFlashes = false

    -- fire mode bullets (HalfLife2 font), sized like the HL2 HUD (proportional to a 640x480 screen)
    local function hudFonts()
        surface.CreateFont("AGP_PDW_Mode", { font = "HalfLife2", size = math.max(12, math.Round(ScrH() / 480 * 13)), weight = 0, antialias = true, additive = true })
    end
    hudFonts()
    hook.Add("OnScreenSizeChanged", "AGP_PDW_HudFonts", hudFonts)
end

--[[---------------------------------------------------------
Muzzle Effect - Perhaps in a later rev
---------------------------------------------------------
SWEP.MuzzleEffect			= "rg_muzzle_hmg" -- This is an extra muzzleflash effect
 --Available muzzle effects: rg_muzzle_grenade, rg_muzzle_highcal, rg_muzzle_hmg, rg_muzzle_pistol, rg_muzzle_rifle, rg_muzzle_silenced, none

SWEP.MuzzleAttachment		= "1" -- Should be "1" for CSS models or "muzzle" for hl2 models
]]
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.Category = SGLanguage.GetMessage("weapon_cat");
end
SWEP.DrawWeaponInfoBox = true -- Draw Weapon Info HUD
SWEP.Author = "The Art of War, Rafael De Jongh, Gmod4phun"
SWEP.Contact = "info@sg-carterpack.com"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_fnp90_p", "The SG teams' personal defence weapon") or "The SG teams' personal defence weapon"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_fnp90_i", "Left click: fire\nRight click: aim through the red dot sight\nUse + Right click: change the firing mode\nUse + Left click: attach / detach the Kull disruptor") or "Left click: fire\nRight click: aim through the red dot sight\nUse + Right click: change the firing mode\nUse + Left click: attach / detach the Kull disruptor"
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

list.Add("NPCUsableWeapons", {
    class = "fnp90",
    title = SWEP.PrintName
})

SWEP.ViewModel = "models/weapons/c_smg1.mdl" -- GMod's HL2 SMG animations (our own model is drawn on it, see agp_sgc_weapons.lua)
SWEP.WorldModel = "models/agp_weapons/w_sgc_pdw.mdl"
SWEP.FiresUnderwater = true
SWEP.Primary.Sound = Sound("Weapon_SMG1.Single")
SWEP.Primary.Recoil = 0.275 -- Weapon recoil
SWEP.Primary.Damage = 20 -- Weapon Damage
SWEP.Primary.NumShots = 1 -- Number of bullets fired
SWEP.Primary.Cone = 0.0135 -- Bullet spread
SWEP.Primary.ClipSize = 50 -- Weapon maxclip size
SWEP.Primary.Delay = 0.066 -- Rate of fire
SWEP.Primary.DefaultClip = 300 -- Default ammo
SWEP.Primary.Automatic = true -- Weapon is automatic
SWEP.Primary.Ammo = "pistol" -- Weapon uses smg1 ammo
SWEP.Secondary.ClipSize = -1 -- No secondary attack
SWEP.Secondary.DefaultClip = -1 -- - snip -
SWEP.Secondary.Automatic = false -- - snip -
SWEP.Secondary.Ammo = "none" -- - snip -
SWEP.data = {}
SWEP.mode = "auto" -- Default firing mode
SWEP.data.ironsights = 1
SWEP.data.semi = {} -- Semi-automatic firing mode
SWEP.data.semi.FireMode = "p"
SWEP.data.auto = {} -- Automatic firing mode
SWEP.data.auto.FireMode = "ppppp"

function SWEP.data.semi.Init(self)
    self.Primary.Automatic = false
    self.Weapon:EmitSound("weapons/smg1/switch_single.wav")
    self.Weapon:SetNWInt("firemode", 3)
end

function SWEP.data.auto.Init(self)
    self.Primary.Automatic = true
    self.Weapon:EmitSound("weapons/smg1/switch_burst.wav")
    self.Weapon:SetNWInt("firemode", 1)
end

---------------------------
-- Red Dot Sight --
---------------------------
SWEP.IronSightsPos = Vector(-6.42, -4, 1.05) -- c_smg1
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.IronSightZoom = 1.2
SWEP.UseScope = true -- Use a sight instead of ironsights.
SWEP.ScopeScale = 0.4 -- The scale of the scope's reticle in relation to the player's screen size.
SWEP.ScopeZooms = {2} -- The possible magnification levels of the sight.
SWEP.DrawParabolicSights = false -- N0p

function SWEP:ResetVars()
    self.NextSecondaryAttack = 0
    self.bLastIron = false
    self.Weapon:SetNWBool("Ironsights", false)

    if self.UseScope then
        self.CurScopeZoom = 1
        self.fLastScopeZoom = 1
        self.bLastScope = false
        self.Weapon:SetNWBool("Scope", false)
        self.Weapon:SetNWBool("ScopeZoom", self.ScopeZooms[1])
    end

    if self.Owner then
        self.OwnerIsNPC = self.Owner:IsNPC() -- This ought to be better than getting it every time we fire
    end
end

-- We need to call ResetVars() on these functions so we don't whip out a weapon with scope mode or insane recoil right of the bat or whatnot
function SWEP:Holster(wep)
    self:ResetVars()
    self:SetNW2Float("AGPReloadStart", 0)
    self:SetVMRate(1)

    return true
end

function SWEP:Equip(NewOwner)
    self:ResetVars()

    return true
end

function SWEP:OnRemove()
    self:ResetVars()
    if CLIENT and IsValid(self.AGPMagEnt) then self.AGPMagEnt:Remove() end

    return true
end

function SWEP:OnDrop()
    self:ResetVars()

    return true
end

function SWEP:OwnerChanged()
    self:ResetVars()

    return true
end

function SWEP:OnRestore()
    self:ResetVars()

    return true
end

function SWEP:IronSight()
    if (not self.Owner:IsPlayer()) then return end

    if not self.Owner:KeyDown(IN_USE) then
        -- If the key E (Use Key) is not pressed, then
        if self.Owner:KeyPressed(IN_ATTACK2) then
            -- When the right click is pressed, then
            self:SetIronsights(true, self.Owner)
            if CLIENT then return end
        end
    end

    if not self.Owner:KeyDown(IN_ATTACK2) then
        -- If the right click is released, then
        self:SetIronsights(false, self.Owner)
        if CLIENT then return end
    end
end

-- the HL2 hands play slower (reload) or faster (draw); back to normal speed afterwards, also for the next weapon
function SWEP:SetVMRate(rate, untilTime)
    local ply = self.Owner
    local vm = IsValid(ply) and ply:IsPlayer() and ply:GetViewModel()
    if IsValid(vm) then vm:SetPlaybackRate(rate) end
    self.VMRateUntil = untilTime
end

function SWEP:Think()
    if self.VMRateUntil and CurTime() >= self.VMRateUntil then self:SetVMRate(1) end

    if CLIENT then
        if self.Weapon:GetNetworkedBool("Scope") then
            self.MouseSensitivity = self.Owner:GetFOV() / 60 -- scale sensitivity
            self.Owner.Crosshair = false
        else
            self.Owner.Crosshair = true
            self.MouseSensitivity = 1
        end
    end

    self:IronSight()
end

--[[---------------------------------------------------------
Initialize
---------------------------------------------------------]]
local sndZoomIn = Sound("Weapon_AR2.Special1")
local sndZoomOut = Sound("Weapon_AR2.Special2")

function SWEP:Initialize()
    self:SetWeaponHoldType("smg") -- Hold type of the 3rd person animation

    if CLIENT then
        -- We need to get these so we can scale everything to the player's current resolution.
        local iScreenWidth = surface.ScreenWidth()
        local iScreenHeight = surface.ScreenHeight()
        -- These tables are used to draw things like scopes and crosshairs to the HUD.
        self.ScopeTable = {}
        self.ScopeTable.l = iScreenHeight * self.ScopeScale
        self.ScopeTable.x1 = 0.5 * (iScreenWidth + self.ScopeTable.l)
        self.ScopeTable.y1 = 0.5 * (iScreenHeight - self.ScopeTable.l)
        self.ScopeTable.x2 = self.ScopeTable.x1
        self.ScopeTable.y2 = 0.5 * (iScreenHeight + self.ScopeTable.l)
        self.ScopeTable.x3 = 0.5 * (iScreenWidth - self.ScopeTable.l)
        self.ScopeTable.y3 = self.ScopeTable.y2
        self.ScopeTable.x4 = self.ScopeTable.x3
        self.ScopeTable.y4 = self.ScopeTable.y1
        self.ParaScopeTable = {}
        self.ParaScopeTable.x = 0.5 * iScreenWidth - self.ScopeTable.l
        self.ParaScopeTable.y = 0.5 * iScreenHeight - self.ScopeTable.l
        self.ParaScopeTable.w = 2 * self.ScopeTable.l
        self.ParaScopeTable.h = 2 * self.ScopeTable.l
        self.ScopeTable.l = (iScreenHeight + 1) * self.ScopeScale -- I don't know why this works, but it does.
        self.QuadTable = {}
        self.QuadTable.x1 = 0
        self.QuadTable.y1 = 0
        self.QuadTable.w1 = iScreenWidth
        self.QuadTable.h1 = 0.5 * iScreenHeight - self.ScopeTable.l
        self.QuadTable.x2 = 0
        self.QuadTable.y2 = 0.5 * iScreenHeight + self.ScopeTable.l
        self.QuadTable.w2 = self.QuadTable.w1
        self.QuadTable.h2 = self.QuadTable.h1
        self.QuadTable.x3 = 0
        self.QuadTable.y3 = 0
        self.QuadTable.w3 = 0.5 * iScreenWidth - self.ScopeTable.l
        self.QuadTable.h3 = iScreenHeight
        self.QuadTable.x4 = 0.5 * iScreenWidth + self.ScopeTable.l
        self.QuadTable.y4 = 0
        self.QuadTable.w4 = self.QuadTable.w3
        self.QuadTable.h4 = self.QuadTable.h3
        self.LensTable = {}
        self.LensTable.x = self.QuadTable.w3
        self.LensTable.y = self.QuadTable.h1
        self.LensTable.w = 2 * self.ScopeTable.l
        self.LensTable.h = 2 * self.ScopeTable.l
        self.CrossHairTable = {}
        self.CrossHairTable.x11 = 0
        self.CrossHairTable.y11 = 0.5 * iScreenHeight
        self.CrossHairTable.x12 = iScreenWidth
        self.CrossHairTable.y12 = self.CrossHairTable.y11
        self.CrossHairTable.x21 = 0.5 * iScreenWidth
        self.CrossHairTable.y21 = 0
        self.CrossHairTable.x22 = 0.5 * iScreenWidth
        self.CrossHairTable.y22 = iScreenHeight
    end

    self.ScopeZooms = self.ScopeZooms or {5}

    if self.UseScope then
        self.CurScopeZoom = 1 -- Another index, this time for ScopeZooms
    end

    self.NextSecondaryAttack = CurTime() + 0.3
    self:ResetVars()
    self.Weapon:SetNWBool("Ironsights", false)
    self.data[self.mode].Init(self)
end


--[[---------------------------------------------------------
Sensibility
---------------------------------------------------------]]
local LastViewAng = false

local function SimilarizeAngles(ang1, ang2)
    ang1.y = math.fmod(ang1.y, 360)
    ang2.y = math.fmod(ang2.y, 360)

    if math.abs(ang1.y - ang2.y) > 180 then
        if ang1.y - ang2.y < 0 then
            ang1.y = ang1.y + 360
        else
            ang1.y = ang1.y - 360
        end
    end
end

local function ReduceScopeSensitivity(uCmd)
    if LocalPlayer():GetActiveWeapon() and IsValid(LocalPlayer():GetActiveWeapon()) then
        local newAng = uCmd:GetViewAngles()

        if LastViewAng then
            SimilarizeAngles(LastViewAng, newAng)
            local diff = newAng - LastViewAng
            diff = diff * (LocalPlayer():GetActiveWeapon().MouseSensitivity or 1)
            uCmd:SetViewAngles(LastViewAng + diff)
        end
    end

    LastViewAng = uCmd:GetViewAngles()
end

hook.Add("CreateMove", "RSS", ReduceScopeSensitivity)

--[[---------------------------------------------------------
Reload
A P90 reload, built on the HL2 SMG hands: the gun cants to show its top, the magazine on top is
tipped up at the rear, pulled back and taken away, a new one is set in front-first under the sight
and pressed down, then (empty magazine only) the charging handle is pulled. The gun pose is in
ReloadPose (view model position), the magazine in AGPDrawVM (first-person drawing).
---------------------------------------------------------]]
SWEP.ReloadTime = 2.7          -- empty magazine: swap + charging handle
SWEP.ReloadTimeTactical = 2.2  -- magazine still has rounds: swap only
-- timeline in seconds after the reload starts (sounds, gun pose and magazine all use it)
local RT = {
    tiltIn = 0.35,              -- gun cants left and dips (0 .. tiltIn)
    release = 0.15,             -- magazine released, rear tips up
    pulled = 0.45,              -- pulled back out of the gun
    gone = 0.80,                -- taken away (down, with the left hand)
    newMag = 1.25,              -- new magazine comes up
    seated = 1.75,              -- pressed in (= the moment the HL2 hand slaps the gun)
    tiltOut = 1.80,             -- gun levels again (tiltOut .. tiltOut + 0.35)
    bolt = 2.15,                -- charging handle (empty only)
}
SWEP.ReloadTimeline = RT
-- c_smg1 reload is 1.5 s; its hand leaves at 0.1 s and slaps the gun at 1.0 s. At this rate the slap lands on RT.seated.
local RELOAD_HANDS_RATE = 1.0 / RT.seated
local RELOAD_SOUNDS = {   -- HL2 sounds, in every GMod install
    { 0, "npc/combine_soldier/gear3.wav", 60, 110 },
    { RT.release, "weapons/ar2/ar2_reload_rotate.wav", 70, 115 },          -- release + pull out
    { RT.newMag, "npc/combine_soldier/gear5.wav", 60, 105 },
    { RT.seated, "weapons/ar2/ar2_reload_push.wav", 70, 105 },            -- magazine in
    { RT.bolt + 0.03, "weapons/shotgun/shotgun_cock.wav", 65, 135, true }, -- charging handle (empty only)
}

-- reload progress (shared): time since start, length, empty reload; nil when not reloading
function SWEP:AGPReloadT()
    local st = self:GetNW2Float("AGPReloadStart", 0)
    if st <= 0 then return end
    local empty = self:GetNW2Bool("AGPReloadEmpty", false)
    local len = empty and self.ReloadTime or self.ReloadTimeTactical
    local t = CurTime() - st
    if t < 0 or t >= len then return end
    return t, len, empty
end

function SWEP:Reload()
    if (self.Reloadaftershoot and self.Reloadaftershoot > CurTime()) then return end
    local ply = self.Owner
    if not IsValid(ply) then return end

    if ply:IsNPC() then
        if self.Weapon:Clip1() < 1 then self.Weapon:DefaultReload(ACT_VM_RELOAD) end
        return
    end

    if self.Weapon:Clip1() >= self.Primary.ClipSize or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    local empty = self.Weapon:Clip1() < 1
    -- DefaultReload also plays the third person reload gesture (PLAYER_RELOAD) and fills the clip once NextPrimaryFire is reached
    if not self.Weapon:DefaultReload(ACT_VM_RELOAD) then return end

    local now = CurTime()
    local len = empty and self.ReloadTime or self.ReloadTimeTactical
    self.Weapon:SetNextPrimaryFire(now + len)
    self.Weapon:SetNextSecondaryFire(now + len)
    self:SetVMRate(RELOAD_HANDS_RATE, now + len)
    self:SetNW2Float("AGPReloadStart", now)
    self:SetNW2Bool("AGPReloadEmpty", empty)

    self:SetIronsights(false, ply)
    self:SetScope(false, ply)
    self.MouseSensitivity = 1

    if SERVER then
        ply:DrawViewModel(true)
        for _, snd in ipairs(RELOAD_SOUNDS) do
            if empty or not snd[5] then
                timer.Simple(snd[1], function()
                    -- still the same reload (not holstered / dropped meanwhile)
                    if IsValid(self) and self:GetNW2Float("AGPReloadStart", 0) == now and IsValid(self.Owner) and self.Owner:GetActiveWeapon() == self then
                        self:EmitSound(snd[2], snd[3], snd[4])
                    end
                end)
            end
        end
    end

    return true
end

--[[---------------------------------------------------------
Deploy
---------------------------------------------------------]]
SWEP.DeployTime = 0.5   -- ready to fire this long after taking the gun out (the HL2 draw animation is sped up to fit)

function SWEP:Deploy()
    self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
    local now = CurTime()
    local ply = self.Owner
    local vm = IsValid(ply) and ply:IsPlayer() and ply:GetViewModel()
    local dur = IsValid(vm) and vm:SequenceDuration() or 0
    if dur > self.DeployTime then
        self:SetVMRate(dur / self.DeployTime, now + self.DeployTime)
    else
        self:SetVMRate(1)
    end
    self.Weapon:SetNextPrimaryFire(now + self.DeployTime)
    self:SetNW2Float("AGPReloadStart", 0)
    self:SetIronsights(false, ply) -- Remove sight
    self.Reloadaftershoot = now + self.DeployTime -- no reload while drawing

    return true
end

--[[---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------]]
function SWEP:PrimaryAttack()
    if self.Weapon:GetNextPrimaryFire() > CurTime() then return end

    -- This makes you E + Left Click to attach Kull Disruptor - now its just skin, later maybe real function
    if (self.Owner:IsPlayer()) then
        if (self.Owner:KeyDown(IN_USE) and not self.Weapon:GetNWBool("HasKull", false)) then
            self.Weapon.Owner:GetViewModel():SetSkin(1)
            self.Weapon:SetNWBool("HasKull", true)
            self.Weapon:SetNextPrimaryFire(CurTime() + 1)
            self.Weapon:EmitSound("npc/combine_soldier/gear2.wav")
        elseif (self.Owner:KeyDown(IN_USE) and self.Weapon:GetNWBool("HasKull", false)) then
            self.Weapon.Owner:GetViewModel():SetSkin(0)
            self.Weapon:SetNWBool("HasKull", false)
            self.Weapon:SetNextPrimaryFire(CurTime() + 1)
            self.Weapon:EmitSound("npc/combine_soldier/gear2.wav")
        end
    end

    if (self.Owner:IsNPC() or not self.Owner:KeyDown(IN_USE)) then
        if (self.Weapon:Clip1() == 0) then
            if (self.weapon_reload) then
                self.weapon_reload = nil
                self:Reload()
            else
                self.weapon_reload = true
            end
        end

        if not self:CanPrimaryAttack() then return end
        self.Reloadaftershoot = CurTime() + self.Primary.Delay
        self.Weapon:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
        -- Set next secondary fire after firing delay
        self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        -- Set next primary fire after firing delay
        self.Weapon:EmitSound(self.Primary.Sound)
        self:RecoilPower()
        self:TakePrimaryAmmo(1)

        if ((game.SinglePlayer() and SERVER) or SERVER) then
            self.Weapon:SetNWFloat("LastShootTime", CurTime())
        end
    end
end

--[[---------------------------------------------------------
SecondaryAttack
---------------------------------------------------------]]
function SWEP:SecondaryAttack()
    if self.NextSecondaryAttack > CurTime() or self.OwnerIsNPC then return end
    self.NextSecondaryAttack = CurTime() + 0.3

    if self.Owner:KeyDown(IN_USE) then
        if self.mode == "auto" then
            self.mode = "semi"
            self.Weapon:SetNextSecondaryFire(CurTime() + 0.5)
        elseif self.mode == "semi" then
            self.mode = "auto"
        end

        self.data[self.mode].Init(self)

        if self.mode == "auto" then
            self.Weapon:SetNWInt("csef", 1)
        elseif self.mode == "semi" then
            self.Weapon:SetNWInt("csef", 3)
        end
    end
end

function SWEP:CanPrimaryAttack()
    if (self.Weapon:Clip1() <= 0) and self.Primary.ClipSize > -1 then
        self.Weapon:SetNextPrimaryFire(CurTime() + 0.5)
        self.Weapon:EmitSound("Weapon_SMG1.Empty")

        return false
    end

    return true
end

SWEP.CrossHairScale = 1

local HUD_FG, HUD_EMPTY, HUD_BG = Color(255, 220, 0, 220), Color(255, 48, 0, 230), Color(0, 0, 0, 76)

-- one compact panel bottom right: rounds in the magazine, reserve, fire mode (SWEP.DrawAmmo = false hides the HL2 box)
function SWEP:DrawAmmoPanel()
    local u = ScrH() / 480   -- HL2 HUD units (640x480 proportional)
    local mode = self.Weapon:GetNWInt("firemode") == 3 and "semi" or "auto"
    self.mode = mode
    local clip, reserve = math.max(self.Weapon:Clip1(), 0), self.Owner:GetAmmoCount(self.Primary.Ammo)
    local glyphs = self.data[mode].FireMode

    surface.SetFont("HudNumbers")
    local cw, ch = surface.GetTextSize(tostring(clip))
    surface.SetFont("HudNumbersSmall")
    local rw, rh = surface.GetTextSize(tostring(reserve))
    surface.SetFont("AGP_PDW_Mode")
    local gw, gh = surface.GetTextSize(glyphs)

    local pad, gap = math.Round(8 * u), math.Round(6 * u)
    local w = pad + cw + gap + rw + gap * 2 + gw + pad
    local h = math.max(ch, rh, gh, math.Round(36 * u))
    local x, y = ScrW() - math.Round(14 * u) - w, ScrH() - math.Round(12 * u) - h
    draw.RoundedBox(math.Round(6 * u), x, y, w, h, HUD_BG)

    local cy = y + h / 2
    local fg = clip == 0 and HUD_EMPTY or HUD_FG
    draw.SimpleText(tostring(clip), "HudNumbers", x + pad, cy, fg, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(tostring(reserve), "HudNumbersSmall", x + pad + cw + gap, cy, HUD_FG, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(glyphs, "AGP_PDW_Mode", x + w - pad, cy, HUD_FG, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

function SWEP:DrawHUD()
    if not IsValid(self.Owner) then return end
    if (CLIENT) then
        local iScreenWidth = surface.ScreenWidth()
        local iScreenHeight = surface.ScreenHeight()
        local SCOPEFADE_TIME = 0.4

        if self.UseScope then
            local bScope = self.Weapon:GetNetworkedBool("Scope")

            if bScope ~= self.bLastScope then
                self.bLastScope = bScope
                self.fScopeTime = CurTime()
            elseif bScope then
                local fScopeZoom = self.Weapon:GetNetworkedFloat("ScopeZoom")

                if fScopeZoom ~= self.fLastScopeZoom then
                    self.fLastScopeZoom = fScopeZoom
                    self.fScopeTime = CurTime()
                end
            end

            local fScopeTime = self.fScopeTime or 0

            if fScopeTime > CurTime() - SCOPEFADE_TIME then
                local Mul = 1.0
                Mul = 1 - math.Clamp((CurTime() - fScopeTime) / SCOPEFADE_TIME, 0, 1)
                surface.SetDrawColor(0, 0, 0, 255 * Mul)
                surface.DrawRect(0, 0, iScreenWidth, iScreenHeight)
            end

            if bScope then
                surface.SetDrawColor(0, 0, 0, 255)
                surface.SetTexture(surface.GetTextureID("Boba_Fett/P90/scope.vmt"))
                surface.DrawTexturedRect(self.LensTable.x, self.LensTable.y, self.LensTable.w, self.LensTable.h)
                surface.SetDrawColor(0, 0, 0, 255)
                surface.DrawRect(self.QuadTable.x1 - 2.5, self.QuadTable.y1 - 2.5, self.QuadTable.w1 + 5, self.QuadTable.h1 + 5)
                surface.DrawRect(self.QuadTable.x2 - 2.5, self.QuadTable.y2 - 2.5, self.QuadTable.w2 + 5, self.QuadTable.h2 + 5)
                surface.DrawRect(self.QuadTable.x3 - 2.5, self.QuadTable.y3 - 2.5, self.QuadTable.w3 + 5, self.QuadTable.h3 + 5)
                surface.DrawRect(self.QuadTable.x4 - 2.5, self.QuadTable.y4 - 2.5, self.QuadTable.w4 + 5, self.QuadTable.h4 + 5)
            end
        end

        self:DrawAmmoPanel()
    end

    -- No crosshair when ironsights is on
    if (not self.Owner.Crosshair) then return end
    local x, y

    -- If we're drawing the local player, draw the crosshair where theyre aiming,
    -- instead of in the center of the screen.
    if (self.Owner == LocalPlayer() and self.Owner:ShouldDrawLocalPlayer()) then
        local tr = util.GetPlayerTrace(self.Owner)
        tr.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX)
        local trace = util.TraceLine(tr)
        local coords = trace.HitPos:ToScreen()
        x, y = coords.x, coords.y
    else
        x, y = ScrW() / 2.0, ScrH() / 2.0
    end

    local scale = 10 * self.Primary.Cone
    -- Scale the size of the crosshair according to how long ago we fired our weapon
    local LastShootTime = self.Weapon:GetNetworkedFloat("LastShootTime", 0)
    scale = scale * (2 - math.Clamp((CurTime() - LastShootTime) * 5, 0.0, 1.0))
    surface.SetDrawColor(0, 255, 0, 255)
    -- Draw an awesome crosshair
    local gap = 40 * scale
    local length = gap + 20 * scale
    surface.DrawLine(x - length, y, x - gap, y)
    surface.DrawLine(x + length, y, x + gap, y)
    surface.DrawLine(x, y - length, x, y - gap)
    surface.DrawLine(x, y + length, x, y + gap)
end

function SWEP:TranslateFOV(current_fov)
    if CLIENT then
        local fScopeZoom = self.Weapon:GetNetworkedFloat("ScopeZoom")
        if self.Weapon:GetNetworkedBool("Scope") then return current_fov / fScopeZoom end
        local bIron = self.Weapon:GetNetworkedBool("Ironsights")

        if bIron ~= self.bLastIron then
            self.bLastIron = bIron
            self.fIronTime = CurTime()
        end

        local fIronTime = self.fIronTime or 0
        if not bIron and (fIronTime < CurTime() - IRONSIGHT_TIME) then return current_fov end
        local Mul = 1.0

        if fIronTime > CurTime() - IRONSIGHT_TIME then
            Mul = math.Clamp((CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1)

            if not bIron then
                Mul = 1 - Mul
            end
        end

        current_fov = current_fov * (1 + Mul / self.IronSightZoom - Mul)

        return current_fov
    end
end

IRONSIGHT_TIME = 0.15

function SWEP:GetViewModelPosition(pos, ang)
    pos, ang = self:IronSightPose(pos, ang)
    return self:ReloadPose(pos, ang)
end

function SWEP:IronSightPose(pos, ang)
    if (not self.IronSightsPos) then return pos, ang end
    local bIron = self.Weapon:GetNetworkedBool("Ironsights")

    if (bIron ~= self.bLastIron) then
        self.bLastIron = bIron
        self.fIronTime = CurTime()
    end

    local fIronTime = self.fIronTime or 0
    if (not bIron and fIronTime < CurTime() - IRONSIGHT_TIME) then return pos, ang end
    local Mul = 1.0

    if (fIronTime > CurTime() - IRONSIGHT_TIME) then
        Mul = math.Clamp((CurTime() - fIronTime) / IRONSIGHT_TIME, 0, 1)

        if not bIron then
            Mul = 1 - Mul
        end
    end

    local Offset = self.IronSightsPos

    if (self.IronSightsAng) then
        ang = ang * 1
        ang:RotateAroundAxis(ang:Right(), self.IronSightsAng.x * Mul)
        ang:RotateAroundAxis(ang:Up(), self.IronSightsAng.y * Mul)
        ang:RotateAroundAxis(ang:Forward(), self.IronSightsAng.z * Mul)
    end

    local Right = ang:Right()
    local Up = ang:Up()
    local Forward = ang:Forward()
    pos = pos + Offset.x * Right * Mul
    pos = pos + Offset.y * Forward * Mul
    pos = pos + Offset.z * Up * Mul

    return pos, ang
end

local function ease(x)
    x = math.Clamp(x, 0, 1)
    return x * x * (3 - 2 * x)
end
-- 0 before a, 1 after b, smooth in between
local function seg(t, a, b) return ease((t - a) / (b - a)) end

-- reload pose of the whole view model (hands + gun together, so the right hand stays on the grip):
-- turned around a point near the gun's grip: cant left (top towards the camera), muzzle a little up and in, lower and closer
local RP = { roll = -32, pitch = 7, yaw = 9, left = 2.2, up = -1.6, back = 0.8, pivot = Vector(20, -6.5, -4) }   -- pivot: forward, left, up from the eye (c_smg1 gun bone at rest)

function SWEP:ReloadPose(pos, ang)
    local t, _, empty = self:AGPReloadT()
    if not t then return pos, ang end
    local RT = self.ReloadTimeline
    local w = seg(t, 0, RT.tiltIn) - seg(t, RT.tiltOut, RT.tiltOut + 0.35)
    local seat = seg(t, RT.seated - 0.04, RT.seated + 0.02) - seg(t, RT.seated + 0.02, RT.seated + 0.2)   -- small jolt when the magazine snaps in
    local bolt = empty and (seg(t, RT.bolt, RT.bolt + 0.08) - seg(t, RT.bolt + 0.08, RT.bolt + 0.35)) or 0   -- charging handle: quick pull back
    if w <= 0 and seat <= 0 and bolt <= 0 then return pos, ang end

    local pivot = pos + ang:Forward() * RP.pivot.x - ang:Right() * RP.pivot.y + ang:Up() * RP.pivot.z
    local lp = WorldToLocal(pos, ang, pivot, ang)
    local na = Angle(ang.p, ang.y, ang.r)
    na:RotateAroundAxis(ang:Forward(), RP.roll * w)
    na:RotateAroundAxis(ang:Right(), RP.pitch * w + 2.5 * bolt)
    na:RotateAroundAxis(ang:Up(), RP.yaw * w)
    local np = LocalToWorld(lp, angle_zero, pivot, na)
    np = np - ang:Right() * (RP.left * w) + ang:Up() * (RP.up * w - 0.4 * seat) - ang:Forward() * (RP.back * w + 1.2 * bolt)
    return np, na
end

if CLIENT then
    -- The magazine of w_sgc_pdw is its own mesh part but not a separate bone/bodygroup, so it is cut out with clip planes:
    -- the gun is drawn without the magazine box, a second copy of the model drawn only inside the box is the magazine.
    -- Model space: +x = left side of the gun, -y = muzzle, +z = up. Box found from the model source (notes/models/build_weapons):
    -- magazine y -6.37 .. 4.72, z 4.54 .. 5.79; below z 4.78 it sits inside the receiver, behind y 4.30 inside the magazine catch,
    -- the sight mount's legs stand beside it (x < -0.24 / > 1.63) in front of y 2.5, where the magazine is narrower.
    -- A plane {n, d} keeps n . p > d (model units).
    local MAG_ONLY = {
        { { Vector(1, 0, 0), -0.24 }, { Vector(-1, 0, 0), -1.63 }, { Vector(0, 1, 0), -6.39 }, { Vector(0, -1, 0), -2.5 }, { Vector(0, 0, 1), 4.78 }, { Vector(0, 0, -1), -5.795 } },
        { { Vector(0, 1, 0), 2.5 }, { Vector(0, -1, 0), -4.30 }, { Vector(0, 0, 1), 4.78 }, { Vector(0, 0, -1), -5.795 } },
    }
    local WITHOUT_MAG = {   -- everything outside both boxes, one or two planes per pass (overlaps are drawn twice, which shows nothing)
        { { Vector(0, 0, -1), -4.78 } }, { { Vector(0, 0, 1), 5.795 } }, { { Vector(0, -1, 0), 6.39 } }, { { Vector(0, 1, 0), 4.30 } },
        { { Vector(-1, 0, 0), 0.24 }, { Vector(0, -1, 0), -2.5 } }, { { Vector(1, 0, 0), 1.63 }, { Vector(0, -1, 0), -2.5 } },
    }
    local MAG_PIVOT = Vector(0, -6.37, 4.78)   -- front lower edge: the magazine tips up around it

    local function drawClipped(ent, planes)
        local pos, ang, sc = ent:GetPos(), ent:GetAngles(), ent:GetModelScale() or 1
        for _, pl in ipairs(planes) do
            local n = Vector(pl[1])
            n:Rotate(ang)
            render.PushCustomClipPlane(n, n:Dot(pos) + pl[2] * sc)
        end
        ent:DrawModel()
        for _ = 1, #planes do render.PopCustomClipPlane() end
    end

    -- where the loose magazine is, relative to its seat: tilt (degrees, rear up) and offset (model units); nil = not in view
    local function magPose(t, RT)
        if t >= RT.release and t < RT.gone then   -- old magazine: tip up, pull back, away down with the left hand
            local tip, pull, away = seg(t, RT.release, RT.release + 0.13), seg(t, RT.release + 0.13, RT.pulled), seg(t, RT.pulled, RT.gone)
            return 10 * tip + 25 * away, Vector(3 * away, 2.5 * pull + 2 * away, 0.5 * pull - 14 * away)
        elseif t >= RT.newMag and t < RT.seated then   -- new one: up beside the gun, over the top, front in under the sight, rear pressed down
            local u1, u2 = seg(t, RT.newMag, RT.newMag + 0.2), seg(t, RT.newMag + 0.2, RT.newMag + 0.33)
            local u3, u4 = seg(t, RT.newMag + 0.33, RT.seated - 0.07), seg(t, RT.seated - 0.07, RT.seated)
            local p = LerpVector(u1, Vector(5, 3, -10), Vector(4.5, 2.5, 5))
            p = LerpVector(u2, p, Vector(0, 2.2, 0.3))
            p = LerpVector(u3, p, Vector(0, 0, 0.1))
            p = LerpVector(u4, p, Vector(0, 0, 0))
            return Lerp(u4, Lerp(u2, 30, 12), 0), p
        end
    end

    -- set AGP.PDWMagSwap = false to turn the magazine swap off (the gun then only tilts). Needs 6 clip planes: Windows (DirectX) only
    function SWEP:AGPDrawVM(m)
        local t = self:AGPReloadT()
        local RT = self.ReloadTimeline
        if not t or t < RT.release or t >= RT.seated or AGP.PDWMagSwap == false or not system.IsWindows() then
            m:DrawModel()
            return
        end
        local oldClip = render.EnableClipping(true)
        for _, planes in ipairs(WITHOUT_MAG) do drawClipped(m, planes) end

        local tilt, off = magPose(t, RT)
        if tilt then
            if not IsValid(self.AGPMagEnt) then
                self.AGPMagEnt = ClientsideModel(m:GetModel(), RENDERGROUP_OPAQUE)
                if IsValid(self.AGPMagEnt) then self.AGPMagEnt:SetNoDraw(true) end
            end
            local mag = self.AGPMagEnt
            if IsValid(mag) then
                local la = Angle(0, 0, tilt)   -- roll about the model's x axis turns +y (rear) towards +z (up)
                local rp = Vector(MAG_PIVOT)
                rp:Rotate(la)
                local wp, wa = LocalToWorld((MAG_PIVOT - rp + off) * (m:GetModelScale() or 1), la, m:GetPos(), m:GetAngles())
                mag:SetModelScale(m:GetModelScale() or 1)
                mag:SetSkin(m:GetSkin())
                mag:SetPos(wp)
                mag:SetAngles(wa)
                mag:SetupBones()
                for _, planes in ipairs(MAG_ONLY) do drawClipped(mag, planes) end
            end
        end
        render.EnableClipping(oldClip)
    end
end

function SWEP:GetIronsights()
    return self.Weapon:GetNWBool("Ironsights")
end

function SWEP:SetIronsights(b, player)
    if CLIENT then return end
    -- Send the ironsight state to the client, so it can adjust the player's FOV/Viewmodel pos accordingly
    self.Weapon:SetNWBool("Ironsights", b)

    -- If we have a scope, use it instead of ironsights
    if self.UseScope then
        if b then
            timer.Simple(IRONSIGHT_TIME, function()
                self:SetScope(true, player)
            end)
        else
            self:SetScope(false, player)
        end
    end
end

function SWEP:SetScope(b, player)
    if CLIENT then return end
    local PlaySound = b ~= self.Weapon:GetNetworkedBool("Scope", not b)
    self.CurScopeZoom = 1
    self.Weapon:SetNWFloat("ScopeZoom", self.ScopeZooms[self.CurScopeZoom])

    if b then
        if PlaySound then
            self.Weapon:EmitSound(sndZoomIn)
            self.Weapon:SendWeaponAnim(ACT_TURNLEFT45)
            self:UnDrawModel()
        end
    else
        if PlaySound then
            self.Weapon:EmitSound(sndZoomOut)
            self.Weapon:SendWeaponAnim(ACT_VM_DEPLOY_1)
            self:ReDrawModel()
        end
    end

    -- Send the scope state to the client, so it can adjust the player's fov/HUD accordingly
    self.Weapon:SetNWBool("Scope", b)
end

function SWEP:RecoilPower()
    if (not IsValid(self.Owner) or not self.Owner:IsPlayer() and not self.Owner:IsNPC()) then return end

    if not self.Owner:IsOnGround() then
        if (self:GetIronsights() == true) then
            self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil * 1.7, self.Primary.NumShots, self.Primary.Cone)

            if (self.Owner.ViewPunch) then
                self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (self.Primary.Recoil * 1.7), math.Rand(-1, 1) * (self.Primary.Recoil / 1.7), 0))
            end
        else
            self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone)

            -- Recoil * 2.5
            if (self.Owner.ViewPunch) then
                self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (self.Primary.Recoil * 2.5), math.Rand(-1, 1) * (self.Primary.Recoil * 2.5), 0))
            end
            -- Punch the screen * 2.5
        end
    elseif self.Owner:IsPlayer() and self.Owner:KeyDown(bit.bor(IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)) then
        if (self:GetIronsights() == true) then
            self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil / 1.5, self.Primary.NumShots, self.Primary.Cone)
            -- Recoil split by 2 while in the red dot sight
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (self.Primary.Recoil / 1.5), math.Rand(-1, 1) * (self.Primary.Recoil / 5), 0))
            -- Punch the screen 1.5x less while aiming through the red dot sight
        else
            self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone)
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * self.Primary.Recoil, math.Rand(-1, 1) * (self.Primary.Recoil * 1.5), 0))
        end
    elseif self.Owner:IsPlayer() and self.Owner:Crouching() then
        if (self:GetIronsights() == true) then
            self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil / 4, self.Primary.NumShots, self.Primary.Cone)
            -- Put lesser recoil while aiming through teh red dot sight
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (self.Primary.Recoil / 4), math.Rand(-1, 1) * (self.Primary.Recoil / 10), 0))
            -- Punch the screen 4 times less while aiming through the red dot sight
        else
            self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil / 3.0, self.Primary.NumShots, self.Primary.Cone)
            -- Recoil / 3
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (self.Primary.Recoil / 3), math.Rand(-1, 1) * (self.Primary.Recoil / 2), 0))
            -- Screenpunch / 3
        end
    else
        if (self:GetIronsights() == true) then
            self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil / 3.5, self.Primary.NumShots, self.Primary.Cone)
            -- Put recoil / 4 when you're in ironsight mod
            self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * (self.Primary.Recoil / 3.5), math.Rand(-1, 1) * (self.Primary.Recoil / 6), 0))
            -- Punch the screen 6x less hard when you're in ironsight mod
        else
            self:CSShootBullet(self.Primary.Damage, self.Primary.Recoil / 2.5, self.Primary.NumShots, self.Primary.Cone)

            -- Put normal recoil when you're not in ironsight mod
            if (self.Owner:IsPlayer()) then
                self.Owner:ViewPunch(Angle(math.Rand(-0.5, -2.5) * self.Primary.Recoil / 2.5, math.Rand(-1, 1) * self.Primary.Recoil, 0))
            end
            -- Punch the screen
        end
    end
end

--[[---------------------------------------------------------
ShootBullet
---------------------------------------------------------]]
function SWEP:CSShootBullet(dmg, recoil, numbul, cone)
    numbul = numbul or 1
    cone = cone or 0.01
    local bullet = {}
    bullet.Num = numbul
    bullet.Src = self.Owner:GetShootPos() -- Bullet Source (start pos)
    bullet.Dir = self.Owner:GetAimVector() -- Vector/direction of the bullet
    bullet.Spread = Vector(cone, cone, 0) -- Bullet Spread
    bullet.Tracer = 1 -- Tracers per bullet
    bullet.Force = 0.65 * dmg -- Amount of force to apply to physical objects.
    bullet.Damage = dmg -- Amount of bullet damage
    bullet.Callback = HitImpact
    -- AGP: an NPC's bullets (and tracers) leave the P90 in its hand, not its eyes - our world model has no muzzle
    -- attachment, so the tracer started at the bullet source (lua/autorun/agp_npcs.lua)
    if (SERVER and self.Owner:IsNPC() and AGP and AGP.NPCMuzzle) then
        local aimAt = util.TraceLine({ start = bullet.Src, endpos = bullet.Src + bullet.Dir * 16384, filter = { self.Owner, self }, mask = MASK_SHOT }).HitPos
        bullet.Src = AGP.NPCMuzzle(self.Owner, 14, self)
        bullet.Dir = (aimAt - bullet.Src):GetNormalized()
    end
    -- AGP 2026-11-14 (owner: "for p90 its not accurate were the bullets come out when shooting"): the engine started the
    -- tracer and the flash on the HL2 SMG's muzzle, not on the barrel of our model; ours leave the P90's own muzzle
    -- (lua/autorun/agp_muzzle.lua), the bullet is still traced from the eye
    local ours = AGP and AGP.MuzzleShot and AGP.MuzzleShot(self, bullet, "bullet")
    self.Owner:FireBullets(bullet) -- Fire the round
    if self.VMRateUntil then self:SetVMRate(1) end
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK) -- View model animation
    if (not ours) then self.Owner:MuzzleFlash() end -- Default Muzzle flash (an NPC's)
    self.Owner:SetAnimation(PLAYER_ATTACK1) -- World animation (3rd person)

    if ((game.SinglePlayer() and SERVER) or (not game.SinglePlayer() and CLIENT)) then
        local eyeang = self.Owner:EyeAngles()
        eyeang.pitch = eyeang.pitch - recoil

        if (self.Owner:IsPlayer()) then
            self.Owner:SetEyeAngles(eyeang)
        end
    end
end
-- This should be recoded to use real entity bullets, for later then..

-- our own SGC PDW model on the HL2 SMG animations; the Kull disruptor (E + left click) is mounted under the barrel
AGP.SGCWeapon(SWEP, {
    model = "models/agp_weapons/w_sgc_pdw.mdl", icon = "vgui/weapons/agp_sgc_pdw_inventory",
    vmBone = "ValveBiped.base", vmPos = Vector(-4.949, -0.404, -5.509), vmAng = Angle(-90, 90, 180),
    extra = { model = "models/boba_fett/p90/attachments/kull-zapper.mdl", pos = Vector(6.85, -0.7, 0.3), ang = Angle(0, 0, 0), when = function(w) return w:GetNWBool("HasKull", false) end },
})
if (AGP.MuzzleTrack) then AGP.MuzzleTrack(SWEP) end   -- (where the muzzle of our model is drawn in first person)
