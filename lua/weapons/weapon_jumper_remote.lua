if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("ship")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_jumper");
SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat");
end
SWEP.Author = "RononDex, Rafael De Jongh"
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_weapon_jumper_remote_p", "Use the Puddle Jumper's features") or "Use the Puddle Jumper's features"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_weapon_jumper_remote_i", "Left click: cloak\nRight click: door\nReload: self-destruct") or "Left click: cloak\nRight click: door\nReload: self-destruct"
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP);
SWEP.Base = "weapon_base"
SWEP.Slot = 3
SWEP.SlotPos = 3
SWEP.DrawAmmo	= false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/Iziraider/remote/v_remote.mdl";
SWEP.WorldModel = "models/Iziraider/remote/w_remote.mdl";
SWEP.HoldType = "slam"

-- Lol, without this we can't use this weapon in mp on gmod13...
if SERVER then
	AddCSLuaFile();
end

-- primary.
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false -- AGP: one click = one toggle (holding it toggled every tick)
SWEP.Primary.Ammo	= "none"

-- secondary
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo	= "none"

SWEP.Delay = 0.5;

function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
end

--########## Toggle Cloak @RononDex
-- AGP: with no Jumper of yours nothing happened at all - it says so now
local function AGPNoJumper(self)
	if (CLIENT or not IsValid(self.Owner)) then return false end
	for _, v in pairs(ents.FindByClass("puddle_jumper")) do
		if (IsValid(v) and v.Owner == self.Owner) then return false end
	end
	if (AGP and AGP.Say) then AGP.Say(self.Owner, "agp_jumper_none", "You have no Puddle Jumper: spawn one first.") end
	return true
end

function SWEP:PrimaryAttack()

	self:SetNextPrimaryFire(CurTime() + 1) -- AGP
	self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	if (AGPNoJumper(self)) then return end
	timer.Simple(self.Delay, function()
	for _,v in pairs(ents.FindByClass("puddle_jumper")) do
		if(IsValid(v) and IsValid(self.Owner)) then
			if(v.Owner==self.Owner) then
				if(not(self.Owner:KeyDown(IN_USE))) then
					if (IsValid(v.Shields) and v.Shields:Enabled()) then
                        v:ToggleShield()
					else
						v:ToggleCloak()
					end
				end
			end
		end
	end
	end);
end

if CLIENT then
	-- Inventory Icon
	if(file.Exists("materials/VGUI/weapons/remote_inventory.vmt","GAME")) then
		SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/remote_inventory");
	end
end

--########## Toggle Door @RononDex
function SWEP:SecondaryAttack()

	self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
	if (AGPNoJumper(self)) then return end
	timer.Simple(self.Delay, function()
	for _,v in pairs(ents.FindByClass("puddle_jumper")) do
		if(IsValid(v) and IsValid(self) and IsValid(v.Owner) and IsValid(self.Owner)) then
			if(v.Owner==self.Owner) then
				if(not(self.Owner:KeyDown(IN_USE))) then
					v:ToggleDoor()
				end
			end
		end
	end
	end);
end

--########## Go BOOM!!! @RononDex
function SWEP:Reload()

	self:SendWeaponAnim( ACT_VM_RELOAD )
	if (AGPNoJumper(self)) then return end
	timer.Simple(self.Delay, function()
	for _,v in pairs(ents.FindByClass("puddle_jumper")) do
		if(IsValid(v) and IsValid(v.Owner) and IsValid(self.Owner)) then
			if(v.Owner==self.Owner) then
				if(not(self.Owner:KeyDown(IN_USE))) then
					v:DoKill()
					self.Owner:SelectWeapon( "weapon_crowbar" )
				end
			end
		end
	end
	end);
end

--######### Repair Function & Shield Activation@RononDex
function SWEP:Think()

	local atkPress = AGP and AGP.KeyPressIN and AGP.KeyPressIN(self, self.Owner, IN_ATTACK) -- AGP: once per click
	if(self.Owner:KeyDown(IN_USE)) then
		if(atkPress) then
			timer.Simple(self.Delay, function()
				for _,v in pairs(ents.FindByClass("puddle_jumper")) do
					if(v.Owner==self.Owner) then
						v:ToggleShield()
					end
				end
			end);
		end
	end
end

-- AGP: CAP's own first-person model again - the remote, the grip and the button presses exactly as they were - with the
-- player's own hands laid onto its arm skeleton (lua/autorun/agp_blueprint_arms.lua). (GMod pistol grip never
-- fitted.)
if (AGP and AGP.BlueprintArms) then
    AGP.BlueprintArms(SWEP, { vm = "models/Iziraider/remote/v_remote.mdl", hide = { "v_hands" }, arms = AGP.BlueprintRigs.izi, fov = 62 })
end

-- AGP: its buttons are heard (agp_weapon_hands.lua)
if (AGP and AGP.ClickSounds) then AGP.ClickSounds(SWEP, { primary = "button/ring_button1.mp3", secondary = "button/ring_button2.mp3", reload = "button/ring_button1.mp3" }) end
