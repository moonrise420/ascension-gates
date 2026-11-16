if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("base")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_malp");
SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat");
end
SWEP.Author = "RononDex"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_weapon_malp_remote_p", "Control the MALP") or "Control the MALP"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_weapon_malp_remote_i", "Left click: take control\nRight click: leave") or "Left click: take control\nRight click: leave"
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP);
SWEP.Base = "weapon_base"
SWEP.Slot = 3
SWEP.SlotPos = 3
SWEP.DrawAmmo	= false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/Iziraider/remote/v_remote.mdl";
SWEP.WorldModel = "models/Iziraider/remote/w_remote.mdl"
SWEP.HoldType = "slam"

-- Lol, without this we can't use this weapon in mp on gmod13...
if SERVER then
	AddCSLuaFile();
end

if CLIENT then
	if(file.Exists("materials/VGUI/weapons/malp.vmt","GAME")) then
		SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/malp");
	end
end

-- primary.
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo	= "none"

-- secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo	= "none"

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
end

--[[
function SWEP:Initialize()

	self.MalpNum = 0
	self:FindMALP()

end

function SWEP:FindMALP()

	for _,v in pairs(ents.FindByClass("malp")) do
		if(IsValid(v)) then
			if(v.Owner==self.Owner) then
				malp = v
				self.MalpNum = self.MalpNum + 1
			end
		end
	end
	return malp
end

function SWEP:Think()

	umsg.Start("MALPSWEPDATA",self.Owner)
		umsg.Short(self.MalpNum)
	umsg.End()
end

--########### Loose control of the MALP @RononDex
function SWEP:SecondaryAttack()

	local malp = self:FindMALP()
	if(IsValid(malp)) then
		if(not(malp.Control)) then
			self.ShouldUseMALPNum = self.ShouldUseMALPNum + 1
		else
			malp:UnControl(self.Owner)
		end
	end
end





function SWEP:PrimaryAttack()

	local malp = self:FindMALP()
	if(IsValid(malp)) then
		if(malp.Control) then
			malp:StartControl(self.Owner)
		end
	end
end
]]--

--########## Take control of the MALP @RononDex
function SWEP:PrimaryAttack()

	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	self:SetNextPrimaryFire(CurTime() + 0.5)
	local found = 0
	for _,v in pairs(ents.FindByClass("malp")) do
		if(IsValid(v)) then
			if(v.Owner==self.Owner or game.SinglePlayer()) then
				found = found + 1
				if(not(v.Control)) then
					v:StartControl(self.Owner)
				end
			end
		end
	end
	-- AGP: say why nothing happens
	if (SERVER and found == 0 and AGP and AGP.Say) then AGP.Say(self.Owner, "agp_malp_none", "You have no MALP: spawn one first (Ascension Gates > Transport and Exploration).") end
end


--########### Loose control of the MALP @RononDex
function SWEP:SecondaryAttack()

	self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
	for _,v in pairs(ents.FindByClass("malp")) do
		if(IsValid(v)) then
			if(v.Owner==self.Owner or game.SinglePlayer()) then
				if(v.Control) then
					v:UnControl(self.Owner)
				end
			end
		end
	end
end

-- AGP 2026-11-12 (owner: "CAP's is way better held in the hand - why can't we have it exactly the same way"): CAP's own
-- first-person model again - the remote, the grip and the button presses exactly as they were - with the player's own
-- hands laid onto its arm skeleton (lua/autorun/agp_blueprint_arms.lua). (2026-11-10's GMod pistol grip never fitted.)
if (AGP and AGP.BlueprintArms) then
    AGP.BlueprintArms(SWEP, { vm = "models/Iziraider/remote/v_remote.mdl", hide = { "v_hands" }, arms = AGP.BlueprintRigs.izi, fov = 62 })
end

-- AGP 2026-11-12: its buttons are heard (agp_weapon_hands.lua)
if (AGP and AGP.ClickSounds) then AGP.ClickSounds(SWEP, { primary = "button/ring_button1.mp3", secondary = "button/ring_button2.mp3" }) end
