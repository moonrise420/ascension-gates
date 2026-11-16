--[[
	Mimetic imaging device - Ascension Gates' own code (2026-11-10), after the series (SG-1 "Foothold": a device that
	lets its wearer look like a person it has imaged). The class name stays "mimetisor" so saves and dupes keep it.

	Mouse1: image the person in front of you (a player or a human NPC, close by): hold the aim on them for a moment.
	Mouse2: the projection on / off - you look like the imaged person, or like yourself again (the image is kept).
	Reload: forget the image.

	The projection stays on when the device is put away or dropped, and after getting out of a ship or the KINO view;
	it ends with Mouse2 (this device or any other), on death and on disconnect. Only the server changes a look, and only
	the look of the player who holds the device; the client never sends a model.
]]

if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end

local function L(key, fallback, ...)
	if (AGP and AGP.L) then return AGP.L(key, fallback, ...) end
	return fallback
end

SWEP.PrintName = L("wp_mimetisor", "Mimetic imaging device")
SWEP.Category = L("weapon_misc_cat", "Misc Weapons")
SWEP.ClassName = "mimetisor"
SWEP.Author = "Ascension Gates"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_mimetisor_p", "Look like someone else (SG-1, 'Foothold')") or "Look like someone else (SG-1, 'Foothold')"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_mimetisor_i", "Left click: image the person in front of you\nRight click: projection on / off\nReload: forget the image") or "Left click: image the person in front of you\nRight click: projection on / off\nReload: forget the image"
SWEP.Base = "weapon_base"
SWEP.Slot = 3
SWEP.SlotPos = 6
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"   -- Garry's Mod's own hands (agp_weapon_hands.lua)
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.WorldModel = "models/roltzy/w_sodan.mdl"
SWEP.HoldType = "normal"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.Primary = { ClipSize = -1, DefaultClip = -1, Automatic = true, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

local REACH = 220      -- how close the person must be
local SCAN_TIME = 1.2  -- seconds the aim must stay on them

AGP = AGP or {}
AGP.Mimic = AGP.Mimic or {}
local M = AGP.Mimic

-- who can be imaged: a living player, or an NPC with a human body (our NPCs, citizens, soldiers)
function M.CanImage(ent, by)
	if (not IsValid(ent) or ent == by) then return false end
	if (ent:IsPlayer()) then return ent:Alive() end
	if (ent:IsNPC()) then
		local mdl = string.lower(ent:GetModel() or "")
		return ent:Health() > 0 and (mdl:find("^models/player/") or mdl:find("^models/humans/") or mdl:find("^models/agp")
			or ent:LookupBone("ValveBiped.Bip01_Head1") ~= nil) and true or false
	end
	return false
end

-- the person in the device's aim (the same trace on server and client)
function M.Aimed(ply)
	local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * REACH, filter = ply, mask = MASK_SHOT })
	return (M.CanImage(tr.Entity, ply) and tr.Entity) or nil
end

function SWEP:SetupDataTables()
	self:NetworkVar("Entity", 0, "ScanTarget")
	self:NetworkVar("Float", 0, "ScanStart")
end

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
end

if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("AGP_MimicSay")

	-- (through the Entity metatable: a model enforcer on the Player metatable turns every Player:SetModel into the
	-- player's chosen model - the projection would never show)
	local SetModelRaw = FindMetaTable("Entity").SetModel

	local function say(ply, key, fallback, name)
		net.Start("AGP_MimicSay"); net.WriteString(key); net.WriteString(fallback); net.WriteString(name or ""); net.Send(ply)
	end

	local function lookOf(ent)   -- model, skin, bodygroups, colour
		local bg = {}
		for _, b in ipairs(ent:GetBodyGroups() or {}) do bg[b.id] = ent:GetBodygroup(b.id) end
		return { model = ent:GetModel(), skin = ent:GetSkin(), bg = bg, color = ent.GetPlayerColor and ent:GetPlayerColor() or nil,
			name = ent:IsPlayer() and ent:Nick() or ent:GetClass() }   -- (an NPC's class: the client names it)
	end

	local function wear(ply, look)
		SetModelRaw(ply, look.model)
		ply:SetSkin(look.skin or 0)
		for id, v in pairs(look.bg or {}) do ply:SetBodygroup(id, v) end
		if (look.color and ply.SetPlayerColor) then ply:SetPlayerColor(look.color) end
		if (ply.SetupHands) then ply:SetupHands() end   -- the hands that belong to this body
	end

	-- the state lives on the player (it outlasts the device): AGPMimic = { own = look, image = look, on = bool }
	function M.State(ply)
		ply.AGPMimic = ply.AGPMimic or {}
		return ply.AGPMimic
	end

	function M.Store(ply, target)
		local st = M.State(ply)
		st.image = lookOf(target)
		if (target:IsPlayer()) then st.image.name = target:Nick() end
		return st.image
	end

	function M.Project(ply, on)
		local st = M.State(ply)
		if (on) then
			if (not st.image or not util.IsValidModel(st.image.model or "")) then return false end
			if (not st.on) then st.own = lookOf(ply) end
			st.on = true
			wear(ply, st.image)
		else
			if (not st.on) then return false end
			st.on = false
			-- (something else changed the model meanwhile - a respawn, a model changer: that one stays)
			if (st.own and ply:GetModel() == st.image.model) then wear(ply, st.own) end
		end
		return true
	end

	function M.Clear(ply)
		if (not ply.AGPMimic) then return end
		M.Project(ply, false)
		ply.AGPMimic = nil
	end

	local function holder(ply, wep)
		return IsValid(ply) and ply:IsPlayer() and ply:Alive() and IsValid(wep) and wep:GetOwner() == ply and ply:GetActiveWeapon() == wep
	end

	function SWEP:PrimaryAttack()
		self:SetNextPrimaryFire(CurTime() + 0.05)
		local ply = self:GetOwner()
		if (not holder(ply, self)) then return end
		local t = M.Aimed(ply)
		if (t ~= self:GetScanTarget()) then
			self:SetScanTarget(t or NULL); self:SetScanStart(CurTime())
			if (t) then self:EmitSound("buttons/blip1.wav", 55, 140) end
			return
		end
		if (not t) then return end
		if (CurTime() - self:GetScanStart() >= SCAN_TIME) then
			local look = M.Store(ply, t)
			self:SetScanTarget(NULL)
			self:SetNextPrimaryFire(CurTime() + 1)
			M.Project(ply, true)
			ply:EmitSound("npc/scanner/scanner_photo1.wav", 60, 120)
			say(ply, "agp_mimic_imaged", "Image stored - you now look like %s.", look.name)
			if (self.AGPHandsPlay) then self:AGPHandsPlay("seq_admire") end
		end
	end

	function SWEP:Think()   -- a scan stops when the button is let go
		local t = self:GetScanTarget()
		if (IsValid(t) and IsValid(self:GetOwner()) and not self:GetOwner():KeyDown(IN_ATTACK)) then self:SetScanTarget(NULL) end
	end

	function SWEP:SecondaryAttack()
		self:SetNextSecondaryFire(CurTime() + 0.6)
		local ply = self:GetOwner()
		if (not holder(ply, self)) then return end
		local st = M.State(ply)
		if (not st.image) then
			ply:EmitSound("buttons/button10.wav", 60, 100)
			say(ply, "agp_mimic_noimage", "No image stored yet: hold Mouse1 on a person in front of you.")
			return
		end
		if (M.Project(ply, not st.on)) then
			ply:EmitSound(st.on and "npc/scanner/scanner_siren1.wav" or "npc/scanner/scanner_pain1.wav", 50, 150)
			if (st.on) then say(ply, "agp_mimic_on", "Projection on: you look like %s.", st.image.name)
			else say(ply, "agp_mimic_off", "Projection off: you look like yourself.") end
			if (self.AGPHandsPlay) then self:AGPHandsPlay("seq_admire") end
		end
	end

	function SWEP:Reload()
		local ply = self:GetOwner()
		if (not holder(ply, self) or not ply.AGPMimic or (self.AGPNextReload or 0) > CurTime()) then return end
		self.AGPNextReload = CurTime() + 1
		M.Clear(ply)
		say(ply, "agp_mimic_cleared", "Image forgotten.")
	end

	function SWEP:Holster() self:SetScanTarget(NULL) return true end   -- (the projection stays on)

	hook.Add("PlayerDeath", "AGP.Mimic", function(ply) M.Clear(ply) end)
	hook.Add("PlayerDisconnected", "AGP.Mimic", function(ply) M.Clear(ply) end)
	hook.Add("PlayerSpawn", "AGP.Mimic", function(ply)
		local st = ply.AGPMimic
		if (not st) then return end
		-- getting out of a ship or the KINO view is no new life: the gamemode puts the own model on, ours goes on again
		if (ply.AGPShipLeaving and st.on) then
			timer.Simple(0, function() if (IsValid(ply) and ply.AGPMimic and ply.AGPMimic.on) then wear(ply, ply.AGPMimic.image) end end)
			return
		end
		ply.AGPMimic = nil
	end)
end

if CLIENT then
	function SWEP:PrimaryAttack() return false end
	function SWEP:SecondaryAttack() return false end

	net.Receive("AGP_MimicSay", function()
		local key, fallback, name = net.ReadString(), net.ReadString(), net.ReadString()
		chat.AddText(Color(120, 200, 255), L(key, fallback, language.GetPhrase(name)))
	end)

	-- the scan: a ring that fills while the aim stays on the person
	function SWEP:DrawHUD()
		local t = self:GetScanTarget()
		local x, y = ScrW() / 2, ScrH() / 2
		if (IsValid(t)) then
			local f = math.Clamp((CurTime() - self:GetScanStart()) / SCAN_TIME, 0, 1)
			surface.SetDrawColor(120, 200, 255, 220)
			for k = 0, math.floor(36 * f) do
				local a = math.rad(k * 10 - 90)
				surface.DrawRect(x + math.cos(a) * 28 - 2, y + math.sin(a) * 28 - 2, 4, 4)
			end
			draw.SimpleTextOutlined(L("agp_mimic_scanning", "Imaging..."), "DermaDefaultBold", x, y + 40, Color(120, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 200))
		elseif (M.Aimed(LocalPlayer())) then
			draw.SimpleTextOutlined(L("agp_mimic_hint", "Hold Mouse1 to image this person"), "DermaDefault", x, y + 40, Color(220, 230, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 200))
		end
	end
end

if (AGP and AGP.HandsWeapon) then AGP.HandsWeapon(SWEP) end   -- the hands come up on deploy, fists idle
