--[[
	Ronon Dex's Gun for GarrysMod10
	Copyright (C) 2007  aVoN

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("weapon")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_ronongun");
SWEP.Category = SGLanguage.GetMessage("weapon_cat");
end
SWEP.Author = "aVoN"
SWEP.Contact = "http://forums.facepunchstudios.com/aVoN"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_weapon_dexgun_p", "Ronon's particle magnum") or "Ronon's particle magnum"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_weapon_dexgun_i", "Left click: fire\nRight click: switch between kill and stun") or "Left click: fire\nRight click: switch between kill and stun"
SWEP.Base = "weapon_base"
SWEP.Slot = 1
SWEP.SlotPos = 3
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/v_dexgun.mdl"
SWEP.WorldModel = "models/w_dexgun.mdl"
-- primary.
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "HelicopterGun"
-- secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
-- spawnables.
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

-- Add weapon for NPCs
list.Add("NPCUsableWeapons", {
    class = "weapon_dexgun",
    title = SWEP.PrintName or ""
})

--################### Deploy @aVoN
function SWEP:Deploy()
    if (IsValid(self.Weapon)) then
        self.Weapon:SendWeaponAnim(ACT_VM_DRAW) -- Animation
    end

    if SERVER and IsValid(self) and IsValid(self.Owner) then
        self.Owner:EmitSound(self.Sounds.Deploy, 90)
    end
end

--################### Shoot @aVoN
function SWEP:PrimaryAttack()
    if self.Weapon:GetNextPrimaryFire() > CurTime() then return end
    if (not IsValid(self.Owner) or (self.Owner:IsPlayer() and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0)) then return end
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    -- Muzzle
    if (self.Owner:IsPlayer() and AGP and AGP.MuzzleFx) then
        -- AGP 2026-11-14 (owner: "iam not sure if there the bullets come out at the right place"): the glow was drawn on the
        -- HL2 pistol's muzzle (energy_muzzle takes the view model's attachment 1), not where our model's barrel is
        AGP.MuzzleFx(self, "flash", nil, "energy")
    else
        local fx = EffectData()
        fx:SetScale(0)
        -- AGP: an NPC's flash at the weapon in its hand
        fx:SetOrigin((SERVER and self.Owner:IsNPC() and AGP and AGP.NPCMuzzle) and AGP.NPCMuzzle(self.Owner, 13, self.Weapon) or self.Owner:GetShootPos())
        fx:SetEntity(self.Owner)
        fx:SetAngles(Angle(255, 50, 50))
        fx:SetRadius(64)
        util.Effect("energy_muzzle", fx, true)
    end

    -- Shot
    if SERVER then
        self:SVPrimaryAttack()
    end

    self.Weapon:SetNextPrimaryFire(CurTime() + 0.2)

    return true
end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end
    AddCSLuaFile()

    SWEP.Sounds = {
        Shot = {Sound("pulse_weapon/dexgun1.mp3"), Sound("pulse_weapon/dexgun2.mp3")},
        Deploy = Sound("pulse_weapon/dexgun_engage.mp3")
    }

    --################### Init the SWEP @aVoN
    function SWEP:Initialize()
        -- Sets how fast and how much shots an NPC shall do
        self:SetNPCFireRate(0.6)
        self:SetNPCMinBurst(0)
        self:SetNPCMaxBurst(0)
        self:SetWeaponHoldType("pistol")
        self.NextUse = CurTime()
    end

    --################### Initialize the shot @aVoN
    function SWEP:SVPrimaryAttack()
        local p = self.Owner
        local multiply = 3 -- Default inaccuracy multiplier
        local aimvector = p:GetAimVector()
        local shootpos = p:GetShootPos()
        -- AGP: an NPC's shot leaves the weapon in its hand, not its eyes (lua/autorun/agp_npcs.lua)
        if (p:IsNPC() and AGP and AGP.NPCMuzzle) then shootpos = AGP.NPCMuzzle(p, 13, self.Weapon) end
        local vel = p:GetVelocity()
        local filter = {self.Owner, self.Weapon}

        local usedMuzzle = false
        -- Add inaccuracy for players!
        if (p:IsPlayer()) then
            local right = aimvector:Angle():Right()
            local up = aimvector:Angle():Up()
            -- AGP 2026-11-14 (owner: "iam not sure if there the bullets come out at the right place"): the pulse starts at the
            -- muzzle of the gun as the shooter sees it (his client reports it: lua/autorun/agp_muzzle.lua; third person: the
            -- world model's attachment). CAP put it on a fixed spot 23 to the right and 15 down from the eye, which
            -- ignored the field of view, the model and the pose.
            local muzzle = AGP and AGP.MuzzleWorld and AGP.MuzzleWorld(self)
            -- Check, how far we can go to right (avoids exploding shots on the wall right next to you)
            local max = util.QuickTrace(shootpos, right * 100, filter).Fraction * 100 - 10
            local trans = right:DotProduct(vel) * right / 25

            if (muzzle) then
                shootpos = muzzle
                usedMuzzle = true
                if (p:Crouching()) then multiply = 0.3 end -- We are in crouch - Make it really accurate!
            elseif (p:Crouching()) then
                multiply = 0.3 -- We are in crouch - Make it really accurate!
                -- We need to adjust shootpos or it will look strange
                shootpos = shootpos + math.Clamp(15, -10, max) * right - 4 * up + trans
            else
                -- He stands
                shootpos = shootpos + math.Clamp(23, -10, max) * right - 15 * up + trans
            end

            multiply = multiply * math.Clamp(vel:Length() / 500, 0.3, 3) -- We are moving - Make it inaccurate depending on the velocity
        else -- It's an NPC
            multiply = 0
        end

        if (AGP and AGP.MuzzleDebugServer and p:IsPlayer()) then   -- (tests: where the pulse starts, relative to the eye)
            local ea, d = p:EyeAngles(), shootpos - p:GetShootPos()
            print("AGP_RESULT", "INFO", "dex pulse start", string.format("eye-relative f=%.1f r=%.1f u=%.1f", d:Dot(ea:Forward()), d:Dot(ea:Right()), d:Dot(ea:Up())), usedMuzzle and "from the owner's muzzle" or "old offset")
        end
        -- Now, we need to correct the velocity depending on the changed shootpos above.
        local trace = util.QuickTrace(p:GetShootPos(), 16 * 1024 * aimvector, filter)

        if (trace.Hit) then
            aimvector = (trace.HitPos - shootpos):GetNormalized()
        end

        -- Add some randomness to the velocity
        if not self.Stun then
            local e = ents.Create("energy_pulse")
            e:PrepareBullet(aimvector, multiply, 8000, 1)
            e:SetPos(shootpos)
            e:SetOwner(p)
            e.Owner = p
            e:Spawn()
            e:Activate()
            e:SetColor(Color(255, 50, 50, 255))
            p:EmitSound(self.Sounds.Shot[math.random(1, #self.Sounds.Shot)], 90, math.random(97, 103))

            -- Take one Ammo
            if (self.Owner:IsPlayer()) then
                self:TakePrimaryAmmo(1)
            end
        else
            local e = ents.Create("energy_pulse_stun")
            e:PrepareBullet(aimvector, multiply, 8000, 1)
            e:SetPos(shootpos)
            e:SetOwner(p)
            e.Owner = p
            e:Spawn()
            e:Activate()
            e:SetColor(Color(255, 50, 50, 255))
            p:EmitSound(self.Sounds.Shot[math.random(1, #self.Sounds.Shot)], 90, math.random(97, 103))

            -- Take one Ammo
            if (self.Owner:IsPlayer()) then
                self:TakePrimaryAmmo(1)
            end
        end
    end

    function SWEP:SecondaryAttack()
        local p = self.Owner
        if (not IsValid(p)) then return end

        if self.NextUse < CurTime() then
            if not self.Stun then
                self.Stun = true
                p:EmitSound(self.Sounds.Deploy, 100, 115)
                self:SetNWInt("Mode", 1)
            else
                self.Stun = false
                p:EmitSound(self.Sounds.Deploy, 100, 105)
                self:SetNWInt("Mode", 2)
            end

            self.NextUse = CurTime() + 1
        end
    end
end

if CLIENT then
    -- Inventory Icon
    if (file.Exists("materials/VGUI/weapons/dexgun_inventory.vmt", "GAME")) then
        SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/dexgun_inventory")
    end

    -- Kill Icon
    if (file.Exists("materials/VGUI/weapons/dexgun_killicon.vmt", "GAME")) then
        killicon.Add("weapon_dexgun", "VGUI/weapons/dexgun_killicon", Color(255, 255, 255))
    end

    function SWEP:Initialize()
        self.NextUse = CurTime()
    end

    function SWEP:DrawHUD()
        local mode = AGP.L("agp_mode_kill", "Kill")
        local int = self:GetNetworkedInt("Mode")

        if int == 1 then
            mode = AGP.L("agp_mode_stun", "Stun")
        elseif int == 2 then
            mode = AGP.L("agp_mode_kill", "Kill")
        end

        draw.WordBox(8, ScrW() - 188, ScrH() - 120, AGP.L("agp_ui_mode", "Mode:") .. " " .. mode, "Default", Color(0, 0, 0, 80), Color(255, 220, 0, 220))
    end

    function SWEP:SecondaryAttack()
    end
end

-- AGP 2026-11-10 (owner: the hands in first person must be the player's own): GMod's hand animations (c_pistol.mdl) with the
-- player's own hands; the item's own model sits on the right hand bone the way it sits in a player's hand. The old
-- view model had arms of its own (other hands than the player's).
-- AGP 2026-11-14 (owner: "cant you restore the original froom cap? with that everything should be and work as was?" - the
-- gun pointing up while shooting is CAP's own recoil animation, "because its so powerful"): CAP's own first-person model
-- (models/weapons/v_dexgun.mdl: the original gun with the white grip, its own animations) again, with the player's own hands
-- laid onto its arm skeleton was tried first: its gun hand has no finger bones, so that hand came out wrong (owner: "first
-- person the hands are wrong ... but in the past it worked... right hand and the weapon"). So it is CAP's view model exactly
-- as CAP shipped it, with its own arms.
if (AGP) then
    if (AGP.MuzzleTrack) then AGP.MuzzleTrack(SWEP, { vm = true }) end   -- (the muzzle of CAP's view model, as drawn in first person)
    SWEP.AGPMuzzleSync = true   -- (the owner's client tells the server where it sees the muzzle: the pulse starts there)
end

-- AGP 2026-11-14 (owner: "had a white grip, was not so puny ... like the icon thumbnail and that's missing"): the gun in the hand is
-- the ORIGINAL one the icon shows (CAP's first-person model models/weapons/v_dexgun.mdl: material miriam/weapons/rononsgun, white
-- grip) instead of the small dark world model models/w_dexgun.mdl. GMod's c_pistol hand and its animations stay (the simple way,
-- owner's decision): the old model's own arm mesh (v_hand_sheet) is drawn with an invisible material, its gun (bone "Python") is
-- laid on the hand bone. The numbers were measured from both models' vertices (bbox centre, barrel forward, grip side): in the
-- hand bone's space the old gun's barrel points along +x, its grip hangs towards +z, its flat side faces -y.
-- Also in third person and dropped (the world model's hand bone is the player's hand / the entity itself).
if (CLIENT) then
    local GUN = "models/weapons/v_dexgun.mdl"
    local G0 = Matrix({ { 0, 0, 1, 7.47 }, { -1, 0, 0, -1.03 }, { 0, -1, 0, -4.04 }, { 0, 0, 0, 1 } })   -- Python bone space -> hand bone space
    local CENTRE = Vector(0.47, -1.87, 0.8)   -- the old gun's bbox centre in its Python bone's space
    -- live tuning (tests): agp_dextune dx dy dz flip(0/1) - an extra shift in the hand bone's space; flip = turned half way round its barrel
    AGP.DexTune = AGP.DexTune or { pos = Vector(0, 0, 0), flip = false }
    concommand.Add("agp_dextune", function(_, _, a)
        AGP.DexTune.pos = Vector(tonumber(a[1]) or 0, tonumber(a[2]) or 0, tonumber(a[3]) or 0)
        AGP.DexTune.flip = (tonumber(a[4]) or 0) != 0
    end)
    local gun, Pinv, bad
    local function gunModel()
        if (bad) then return end
        if (IsValid(gun)) then return gun end
        gun = ClientsideModel(GUN, RENDERGROUP_OPAQUE)
        if (not IsValid(gun)) then bad = true return end
        gun:SetNoDraw(true)
        for i, mat in ipairs(gun:GetMaterials() or {}) do
            if (string.find(string.lower(mat), "v_hand_sheet", 1, true)) then gun:SetSubMaterial(i - 1, "engine/occlusionproxy") end   -- (its old arm: draws nothing)
        end
        local sq = gun:LookupSequence("idle01")
        if (sq and sq >= 0) then gun:ResetSequence(sq) end
        gun:SetCycle(0); gun:SetPlaybackRate(0)
        gun:SetPos(vector_origin); gun:SetAngles(angle_zero); gun:SetupBones()
        local b = gun:LookupBone("Python")
        local pm = b and gun:GetBoneMatrix(b)
        if (not pm) then gun:Remove(); gun = nil; bad = true return end
        Pinv = Matrix(pm); Pinv:InvertTR()
        return gun
    end
    -- draws the old gun on the hand bone matrix `hm` (a world matrix); false: it is not available (the world model is drawn instead)
    local function drawGun(hm)
        local g = gunModel()
        if (not g or not hm) then return false end
        local t = AGP.DexTune
        local M = Matrix(hm)
        if (t.pos.x != 0 or t.pos.y != 0 or t.pos.z != 0) then M:Translate(t.pos) end
        M = M * G0
        if (t.flip) then M:Translate(CENTRE); M:Rotate(Angle(0, 180, 0)); M:Translate(-CENTRE) end
        M = M * Pinv
        g:SetPos(M:GetTranslation()); g:SetAngles(M:GetAngles())
        g:SetupBones()
        g:DrawModel()
        return true
    end
    local function handMatrix(ent)
        local b = ent:LookupBone("ValveBiped.Bip01_R_Hand")
        return b and ent:GetBoneMatrix(b)
    end
    -- (first person is CAP's own view model again, see above; this block now draws the original gun in third person and dropped)
    -- third person / dropped
    function SWEP:DrawWorldModel()
        self:SetupBones()
        if (not drawGun(handMatrix(self))) then self:DrawModel() end
    end
end
