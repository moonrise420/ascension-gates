--[[
	Goa'uld Healing Device - Ascension Gates' own code and model, designed after the series; no Evolution Addon Pack
	content left (the class name stays for saves). The oval device held in the palm ("Thor's Hammer", "Fair
	Game"): its red dome glows and a soft golden light falls on the one being healed. Hold
	left click on a player or NPC up to 200 units away: +10 health a second, players up to 150 (NPCs up to their full
	health). Hold right click: heal yourself. First
	person: GMod's hands on the bug bait animations, the device in the palm, the dome towards your patient;
	healing yourself, the hand turns it round, the dome towards you.
]]
SWEP.PrintName = "Goa'uld Healing Device"
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_misc_cat") or "Misc Weapons"   -- AGP: one of our two weapon folders (was "Misc": a folder of its own)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    SWEP.PrintName = SGLanguage.GetMessage("wp_goauld_medical")
    SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat")
end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Ascension Gates"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_goauld_healing_device_p", "Heal your allies.") or "Heal your allies."
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_goauld_healing_device_i", "Hold Left click on a player or NPC\nHold Right click: heal yourself") or "Hold Left click on a player or NPC\nHold Right click: heal yourself"
SWEP.Base = "weapon_base"
SWEP.Slot = 1
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_bugbait.mdl"   -- GMod's bug bait animations (our device in the palm)
SWEP.ViewModelFOV = 54
SWEP.WorldModel = "models/agp_weapons/w_goauld_healing_device.mdl"
SWEP.HoldType = "magic"
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

SWEP.HealRange = 200
SWEP.HealMax = 150
local TICK = 0.1
local HUM = "items/medcharge4.wav"                  -- Half-Life 2's health charger
local GLOW = CLIENT and Material("sprites/light_glow02_add")

if SERVER then
    AddCSLuaFile()
end

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "HealUntil")        -- glowing until then
    self:NetworkVar("Entity", 0, "Patient")         -- whom the light falls on (healing yourself)
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

local function cap(e, max) return e:IsNPC() and e:GetMaxHealth() or max end

function SWEP:Heal(e)
    self:SetHealUntil(CurTime() + TICK * 2.5)
    self:SetPatient(IsValid(e) and e or NULL)
    if (SERVER and IsValid(e) and e:Health() < cap(e, self.HealMax)) then e:SetHealth(math.min(e:Health() + 1, cap(e, self.HealMax))) end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + TICK)
    local o = self:GetOwner()
    local tr = util.TraceHull({ start = o:GetShootPos(), endpos = o:GetShootPos() + o:GetAimVector() * self.HealRange, filter = o,
        mins = Vector(-6, -6, -6), maxs = Vector(6, 6, 6), mask = MASK_SHOT_HULL })
    local e = tr.Entity
    self:Heal(IsValid(e) and ((e:IsPlayer() and e:Alive()) or e:IsNPC()) and e or nil)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + TICK)
    self:Heal(self:GetOwner())
end

function SWEP:Think()
    if (CLIENT) then return end                     -- the hum comes from the server, everyone hears it
    local on = self:GetHealUntil() > CurTime()
    if (on and not self.AGPHum) then
        self.AGPHum = CreateSound(self, HUM); self.AGPHum:PlayEx(0.45, 110)
    elseif (not on and self.AGPHum) then
        self.AGPHum:FadeOut(0.3); self.AGPHum = nil
    end
end

local resetHand   -- below, with the turn while healing yourself

function SWEP:Holster()
    if (self.AGPHum) then self.AGPHum:Stop(); self.AGPHum = nil end
    if (CLIENT) then resetHand(self) end   -- the view model is shared: the next weapon gets a straight hand
    return true
end

function SWEP:OnRemove()
    if (self.AGPHum) then self.AGPHum:Stop(); self.AGPHum = nil end
    if (CLIENT) then resetHand(self) end
end

-- the light: the dome glows, a soft golden beam falls on the patient (not when healing yourself), a warm light there
local function light(self, ent, fp)
    local on = math.Clamp((self:GetHealUntil() - CurTime()) / (TICK * 2.5), 0, 1)
    local gem = ent:GetAttachment(ent:LookupAttachment("gem"))
    if (not gem) then return end
    local pulse = 0.85 + 0.15 * math.sin(CurTime() * 6)
    render.SetMaterial(GLOW)
    render.DrawSprite(gem.Pos, 3 + 9 * on, 3 + 9 * on, Color(255, 120, 60, (70 + 185 * on) * pulse))
    if (on <= 0) then return end
    local p = self:GetPatient()
    if (IsValid(p) and p ~= self:GetOwner()) then
        local to = p:WorldSpaceCenter() + Vector(0, 0, 8)
        render.DrawBeam(gem.Pos, to, 10 * on, 0, 1, Color(255, 200, 110, 120 * on * pulse))
        render.DrawSprite(to, 28 * on, 28 * on, Color(255, 200, 110, 90 * on * pulse))
        local d = DynamicLight(self:EntIndex() + 4096)
        if (d) then d.pos = to; d.r, d.g, d.b = 255, 190, 100; d.brightness = 1.5 * on; d.size = 110; d.decay = 800; d.dietime = CurTime() + 0.1 end
    end
end

-- healing yourself (first person): 0..1, eased in and out over a quarter of a second
local TURN_SPEED = 4
local function selfTurn(self)
    local on = self:GetHealUntil() > CurTime() and self:GetPatient() == self:GetOwner()
    local now = RealTime()
    local dt = math.min(0.1, now - (self.AGPTurnAt or now)); self.AGPTurnAt = now
    self.AGPTurn = math.Approach(self.AGPTurn or 0, on and 1 or 0, dt * TURN_SPEED)
    local t = self.AGPTurn
    return t * t * (3 - 2 * t)
end

-- the hand's share of the turn: the wrist rolls (view model hand bone); the device turns the rest in the fingers
AGP.HealHandTurn = Angle(0, 0, 50)   -- chosen from in-game shots: the palm opens and presents the device
if CLIENT then
    concommand.Add("agp_healturn", function(_, _, a)   -- tuning: agp_healturn p y r
        AGP.HealHandTurn = Angle(tonumber(a[1]) or 0, tonumber(a[2]) or 0, tonumber(a[3]) or 0)
    end)
end
local function handBone(vm) return vm:LookupBone("ValveBiped.Bip01_R_Hand") end
function SWEP:PreDrawViewModel(vm)
    local b = handBone(vm)
    if (b) then
        vm:ManipulateBoneAngles(b, AGP.HealHandTurn * selfTurn(self))
        vm.AGPHealHand = b; self.AGPHandVM = vm   -- AGP: which hand bone of which view model is turned
    end
end
-- AGP: the view model this device turned, also when the owner is already gone (removed while healing yourself:
-- OnRemove found no owner and the next weapon kept the rolled hand)
function resetHand(self)
    local o = self:GetOwner()
    local vm = IsValid(self.AGPHandVM) and self.AGPHandVM or (IsValid(o) and o.GetViewModel and o:GetViewModel())
    local b = IsValid(vm) and (vm.AGPHealHand or handBone(vm))
    if (b) then vm:ManipulateBoneAngles(b, angle_zero); vm.AGPHealHand = nil end
    self.AGPTurn = 0
end
if CLIENT then
    -- AGP: and whatever way the device left the hand (in single player Holster does not run on the client): the first
    -- other weapon drawn on a view model with the turned hand straightens it
    hook.Add("PreDrawViewModel", "AGP.HealingDevice.ResetHand", function(vm, ply, wep)
        if (IsValid(vm) and vm.AGPHealHand and not (IsValid(wep) and wep:GetClass() == "goauld_healing_device")) then
            vm:ManipulateBoneAngles(vm.AGPHealHand, angle_zero)
            vm.AGPHealHand = nil
        end
    end)
end

-- turn the model about its own middle: around a world axis by deg degrees
local function turnAbout(m, centre, axis, deg)
    local r = Angle(0, 0, 0); r:RotateAroundAxis(axis, deg)
    local pos = centre + LocalToWorld(m:GetPos() - centre, angle_zero, vector_origin, r)
    local _, ang = LocalToWorld(vector_origin, m:GetAngles(), vector_origin, r)
    m:SetPos(pos); m:SetAngles(ang)
end
-- first person, healing yourself: half a turn about the view's up axis, then the dome aimed right at your eyes
local function animate(self, m, fp)
    if (not fp) then return end
    local e = selfTurn(self)
    if (e <= 0) then return end
    local centre = m:LocalToWorld(m:OBBCenter())
    turnAbout(m, centre, EyeAngles():Up(), -180 * e)
    m:SetupBones()
    local gem = m:GetAttachment(m:LookupAttachment("gem"))
    if (not gem) then return end
    local d = (gem.Pos - centre):GetNormalized()
    local want = (EyePos() - centre):GetNormalized()
    local axis = d:Cross(want)
    if (axis:LengthSqr() < 1e-6) then return end
    turnAbout(m, centre, axis:GetNormalized(), math.deg(math.acos(math.Clamp(d:Dot(want), -1, 1))) * e)
end

AGP.SGCWeapon(SWEP, {
    model = "models/agp_weapons/w_goauld_healing_device.mdl", icon = "vgui/weapons/agp_goauld_healing_device_inventory",
    vmBone = "ValveBiped.Bip01_R_Hand", vmHand = true,
    vmPos = Vector(0.992, -2.290, 0.503), vmAng = Angle(9.58, 0.89, 5.74),   -- in the palm where the bug bait's pod sits
    -- the oval upright, the dome towards whoever you look at
    vmLook = { head = Vector(0, 0.15, 1), top = Vector(1, 0, 0) },
    designInHand = { Vector(2.150, -1.470, 0.000), Angle(15.35, 180.00, -173.45) },   -- agp_goauld_weapons_build.py
    animate = CLIENT and animate or nil,
    after = CLIENT and light or nil,
})
