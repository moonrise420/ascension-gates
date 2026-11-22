/*
	Sodan Cloaking Device for GarrysMod10
	Copyright (C) 2007  Catdaemon

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
*/

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("extra")) then return end
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_sodan");
SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat");
end
SWEP.Author = "Catdaemon"; -- And a slight modification by me (aVoN) - But it's still his code so I haven't added myself to it. Lua comment is sufficient :)
SWEP.Purpose = (AGP and AGP.L) and AGP.L("agp_wp_sodan_cloak_p", "Cloak yourself") or "Cloak yourself"
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_sodan_cloak_i", "Left click: cloak\nRight click: uncloak") or "Left click: cloak\nRight click: uncloak"
SWEP.Base = "weapon_base";
SWEP.Slot = 3;
SWEP.SlotPos = 4;
SWEP.DrawAmmo	= false;
SWEP.DrawCrosshair = true;
-- AGP: Garry's Mod's own hands with the fists animations (agp_weapon_hands.lua); c_arms_animations.mdl without
-- UseHands showed no hands at all
SWEP.ViewModel = "models/weapons/c_arms.mdl";
SWEP.ViewModelFOV = 54;
SWEP.UseHands = true;
SWEP.WorldModel = "models/roltzy/w_sodan.mdl";
SWEP.AnimPrefix = "melee";
SWEP.HoldType = "normal"

-- primary.
SWEP.Primary.ClipSize = -1;
SWEP.Primary.DefaultClip = -1;
SWEP.Primary.Automatic = true;
SWEP.Primary.Ammo	= "none";

-- secondary
SWEP.Secondary.ClipSize = -1;
SWEP.Secondary.DefaultClip = -1;
SWEP.Secondary.Automatic = false;
SWEP.Secondary.Ammo = "none";

-- spawnables.
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP);

function SWEP:Initialize()
	self.Weapon:SetWeaponHoldType(self.HoldType)
end

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("extra")) then return end
AddCSLuaFile();

SWEP.Sounds = {Engage=Sound("tech/sodan_cloak_on.mp3"),Disengage=Sound("tech/sodan_cloak_off.mp3")};

--################### Set Holdtype @aVoN
function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType);
end

--################### Primary Attack @Catdaemon
function SWEP:PrimaryAttack()
	if(not self.Owner:GetNetworkedBool("pCloaked",false)) then
		self.Owner:SetNWBool("pCloaked",true);
		self.Owner:SetNoTarget(true);
		self.Owner:EmitSound(self.Sounds.Engage,90,math.random(97,103));
		self:DoCloakEffect();
		if (self.AGPHandsPlay) then self:AGPHandsPlay("fists_draw", 1.5) end -- AGP: the hands come up (first person)
		self.Weapon:SetNextSecondaryFire(CurTime()+0.8);
	end
	return true;
end

--################### Secondary Attack @Catdaemon
function SWEP:SecondaryAttack()
	if(self.Owner:GetNWBool("pCloaked",false)) then
		self.Owner:SetNWBool("pCloaked",false);
		self.Owner:SetNoTarget(false);
		self.Owner:EmitSound(self.Sounds.Disengage,90,math.random(97,103));
		self:DoCloakEffect();
		if (self.AGPHandsPlay) then self:AGPHandsPlay("fists_draw", 1.5) end -- AGP: the hands come up (first person)
		self.Weapon:SetNextPrimaryFire(CurTime()+0.8);
	end
	return true;
end

--################### Does the cloaking effect @aVoN
function SWEP:DoCloakEffect()
	local fx = EffectData();
	fx:SetOrigin(self.Owner:GetShootPos()+self.Owner:GetAimVector()*10);
	fx:SetEntity(self.Owner);
	util.Effect("sodan_cloak",fx,true,true);
end

--################### Removes a bit health "due to the radiation" the cloak emits to get away phaseshifted insects,worms etc (which are the EVIL himself) @aVoN
-- No seriously, I added this so a person can't be cloaked infinite - http://mantis.39051.vs.webtropia.com/view.php?id=148
timer.Create("StarGate.SodanCloaking.DamagePlayerOverTime",1,0,
	function()
		for _,v in pairs(player.GetAll()) do
			-- AGP: no device, no cloak (backs up OnRemove, whose owner is gone when the weapons are stripped)
			if(IsValid(v) and v:GetNWBool("pCloaked",false) and not v:HasWeapon("sodan_cloak")) then
				v:SetNWBool("pCloaked",false); v:SetNoTarget(false);
			end
			if(IsValid(v) and v:GetNWBool("pCloaked",false)) then
				v.__Sodan = v.__Sodan or {};
				local t = v.__Sodan; -- Shorter code
				t.RandomHealthLossDelay = t.RandomHealthLossDelay or math.random(7,20);
				t.Activated = t.Activated or CurTime();
				if(t.Activated + t.RandomHealthLossDelay <= CurTime()) then
					v:TakeDamage(math.random(1,5),v,v);
					local hp = v:Health();
					if(hp > 0 and hp < 20) then
						v:SendLua("surface.PlaySound('hl1/fvox/radiation_detected.wav')");
					end
					-- For the next turn
					t.Activated = CurTime();
					t.RandomHealthLossDelay = math.random(7,20);
				end
			end
		end
	end
);

--################### PlayerDeath @aVoN
hook.Add("PlayerDeath","StarGate.SodanCloaking.PlayerDeath",
	function(p)
		if(IsValid(p)) then
			p:SetNWBool("pCloaked",false);
			timer.Simple(0.1,function()
				if (IsValid(p)) then
					p:SetNWBool("pCloaked",nil);
				end
			end)
			p:SetNoTarget(false);
		end
	end
);

hook.Add("PlayerSilentDeath","StarGate.SodanCloaking.PlayerDeath",
	function(p)
		if(IsValid(p)) then
			p:SetNWBool("pCloaked",false);
			timer.Simple(0.1,function()
				if (IsValid(p)) then
					p:SetNWBool("pCloaked",nil);
				end
			end)
			p:SetNoTarget(false);
		end
	end
);

-- AGP: the cloak stays on when the device is put away, but it ends once the player carries no Sodan cloak any more
-- (taken away, dropped, stripped): without the device nothing could switch it off - the player stayed
-- invisible with the blue tint for good
function SWEP:Equip(owner) self.AGPCloakOwner = owner end
function SWEP:OnRemove()
	local p = IsValid(self.Owner) and self.Owner or self.AGPCloakOwner
	timer.Simple(0, function()
		if (IsValid(p) and p:IsPlayer() and p:GetNWBool("pCloaked", false) and not p:HasWeapon("sodan_cloak")) then
			p:SetNWBool("pCloaked", false)
			p:SetNoTarget(false)
		end
	end)
end
function SWEP:OnDrop() self:OnRemove() end

end

if CLIENT then

-- AGP: the attacks run on the server only; without these the client used weapon_base's and played the pistol's
-- empty click in multiplayer
function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

-- Inventory Icon @aVoN
if(file.Exists("materials/VGUI/weapons/cloak_inventory.vmt","GAME")) then
	SWEP.WepSelectIcon = surface.GetTextureID("VGUI/weapons/cloak_inventory");
end

--################### Think @Catdaemon
-- code moved to arthur_mantle

--################### Color override @Catdaemon
local BlurEdges = Material("bluredges");
hook.Add("RenderScreenspaceEffects","StarGate.SodanCloaking.RenderScreenspaceEffects",
	function()
		if(LocalPlayer():GetNWBool("pCloaked",false)) then
			-- Color Modify - The "Bluish" overlay
			DrawColorModify(
				{
					["$pp_colour_addr"] = 0,
					["$pp_colour_addg"] = 0.56,
					["$pp_colour_addb"] = 0.96,
					["$pp_colour_brightness"] = -0.6,
					["$pp_colour_contrast"] = 0.93,
					["$pp_colour_colour"] = 0.19,
					["$pp_colour_mulr"] = 0,
					["$pp_colour_mulg"] = 0,
					["$pp_colour_mulb"] = 0,
				}
			);
			-- Makes view blurry
			DrawMotionBlur(0.2,0.7,0);
			-- Draw blurred edges @aVoN (AGP: "bluredges" comes only with Wiremod; without it the error texture covered
			-- the whole screen while cloaked)
			if (not BlurEdges:IsError()) then
				render.SetMaterial(BlurEdges);
				render.UpdateScreenEffectTexture();
				render.DrawScreenQuad();
			end
		end
	end
);

--################### Footsteps sound? (Hopefully comes along the next update) @aVoN
hook.Add("PlayerFootstep","StarGate.SodanCloaking.PlayerFootStep",
	function(p)
		if(IsValid(p) and p:IsPlayer()) then
			if(p:GetNWBool("pCloaked",false) and not LocalPlayer():GetNWBool("pCloaked",false)) then
				return true;
			end
		end
	end
);
       /*
-- HACKY HACKY HACKY HACKY HACKY @aVoN
-- Stops making players "recognizeable" if they are cloaked (E.g. by looking at them - Before you e.g. saw "Catdaemon - Health 100" if you lookaed at a cloaked player. Now, you dont see anything if he is cloaked
if(util._Sodan_TraceLine) then return end;
util._Sodan_TraceLine = util.TraceLine;
function util.TraceLine(...)
	local t = util._Sodan_TraceLine(...);
	if(t and IsValid(t.Entity)) then
		if(t.Entity:IsPlayer()) then
			if(not LocalPlayer():GetNetworkedBool("pCloaked",false) and t.Entity:GetNWBool("pCloaked",false)) then t.Entity = NULL end;
		end
	end
	return t;
end    */

-- Stops making players "recognizeable" if they are cloaked (E.g. by looking at them - Before you e.g. saw "Catdaemon - Health 100" if you lookaed at a cloaked player. Now, you dont see anything if he is cloaked
hook.Add("HUDDrawTargetID","StarGate.SodanCloak", function()
	local tr = util.GetPlayerTrace( LocalPlayer() )
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end
	if (!trace.HitNonWorld) then return end

	if (trace.Entity:IsPlayer()) then
		if(not LocalPlayer():GetNetworkedBool("pCloaked",false) and trace.Entity:GetNWBool("pCloaked",false)) then return false end;
	end
end);

end

-- AGP: the hands come up on deploy and rest in the fists idle (agp_weapon_hands.lua)
if (AGP and AGP.HandsWeapon) then AGP.HandsWeapon(SWEP) end
