SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_misc_cat") or "Misc Weapons"   -- AGP 2026-11-10: one of our two weapon folders (was "Ascension Gates: Misc": a folder of its own)
SWEP.PrintName = "Minidrone Platform Key";
SWEP.Author = "Madman07";
SWEP.Contact = "";
SWEP.Purpose = "";
SWEP.Instructions = (AGP and AGP.L) and AGP.L("agp_wp_minidrone_key_i", "Left click: fire drones\nRight click: track drones") or "Left click: fire drones\nRight click: track drones"
SWEP.Base = "weapon_base";
SWEP.Slot = 3;
SWEP.SlotPos = 3;
SWEP.DrawAmmo	= false;
SWEP.DrawCrosshair = true;
SWEP.ViewModel = "models/Madman07/minidrone_platform/key_v.mdl";
SWEP.WorldModel = "models/Madman07/minidrone_platform/key_w.mdl";
SWEP.ViewModelFOV = 90

-- primary.
SWEP.Primary.ClipSize = -1;
SWEP.Primary.DefaultClip = -1;
SWEP.Primary.Automatic = true;
SWEP.Primary.Ammo	= "none";

-- secondary
SWEP.Secondary.ClipSize = -1;
SWEP.Secondary.DefaultClip = -1;
SWEP.Secondary.Automatic = false;
SWEP.Secondary.Ammo	= "none";

-- spawnables.
SWEP.Spawnable = false;
SWEP.AdminSpawnable = false;

function SWEP:PrimaryAttack() return false end
function SWEP:SecondaryAttack() return false end
function SWEP:Reload() return end

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("entweapon")) then return end
AddCSLuaFile();

-- AGP 2026-11-08: the owner is not set yet in Initialize, and is gone again on drop / death / cleanup: a NULL-entity
-- error every time the platform gave the key, and on every drop or death. The ATA control flag is only touched while
-- the key has a valid owner (and is taken from the last one on drop / remove).
local function setControl(self, on)
	local p = IsValid(self.Owner) and self.Owner or self.AGPLastOwner
	if (IsValid(p) and p:IsPlayer()) then p.CanMinidroneControll = on end
end

function SWEP:Initialize()
	self.ReloadingTime = CurTime();
end

function SWEP:Equip(p)
	self.AGPLastOwner = p
	if (IsValid(p)) then p.CanMinidroneControll = false end
end

function SWEP:Think()
	local p = self.Owner
	if (not IsValid(p)) then return end
	self.AGPLastOwner = p
	local tr = util.GetPlayerTrace(p)
	local trace=util.TraceLine(tr)
	p.Target = trace.HitPos

	if IsValid(p.MiniDronePlatform) then
		if(StarGate.HasATA(self.Owner,false)) then
			local len = (p:GetPos() - p.MiniDronePlatform:GetPos()):Length()
			if (len < 500) then
				p.CanMinidroneControll = true
			else
				p.CanMinidroneControll = false
			end
		else
			if(p.CanMinidroneControll == true) then
				p.CanMinidroneControll = false
			end
		end
	end
end

function SWEP:Deploy()
	if (IsValid(self.Owner)) then StarGate.HasATA(self.Owner,true) end
	return true
end

function SWEP:OnDrop()
	setControl(self, false)
end

function SWEP:OnRemove()
	setControl(self, false)
end

function SWEP:Holster()
	setControl(self, false)
	return true
end

function SWEP:PrimaryAttack()
	local p = self.Owner;
	if(p.CanMinidroneControll and IsValid(p.MiniDronePlatform)) then
		p.MiniDronePlatform:FireDrones(p);
	end

	self.Weapon:SetNextPrimaryFire(CurTime()+0.15);
end

function SWEP:Reload()
	if (self.ReloadingTime and CurTime() <= self.ReloadingTime) then return end
	self.ReloadingTime = CurTime() + 1;

	local p = self.Owner;
	local tr = util.GetPlayerTrace(p)
	local trace = util.TraceLine(tr)

	local aimvector = p:GetAimVector():GetNormal();
	local shootpos = p:GetPos() + Vector(0,0,55);

	debugoverlay.Line(shootpos, shootpos+aimvector*100, 60, Color(255,255,255), true);

	local e = ents.Create("minidrone_key_ent");
	e:SetPos(shootpos+aimvector*10);
	e:Spawn();
	e:Activate();
	e:PhysWake();
	e:SetVelocity(aimvector*10);

	e.MiniDronePlatform = p.MiniDronePlatform;
	p.MiniDronePlatform = nil;
	p.CanMinidroneControll = nil;
	p:SetNetworkedEntity("DronePlatform", NULL);

	p:SelectWeapon("weapon_crowbar");
	self:Remove();
end

end

if CLIENT then

-- Inventory Icon
-- if(file.Exists("materials/VGUI/weapons/kino_inventory.vmt"),"GAME") then
-- Kill Icon
-- if(file.Exists("materials/VGUI/weapons/kino_inventory.vmt"),"GAME") then

local default = Material("madman07/minidrone_platform/key");
local noglow = Material("madman07/minidrone_platform/key_off");
local glow = Material("madman07/minidrone_platform/key_on");

function SWEP:Think()
	local p = self.Owner;
	local platform = p:GetNetworkedEntity("DronePlatform", NULL);
	if IsValid(platform) then
		local len = (p:GetPos() - platform:GetPos()):Length();
		if (len < 500) then
			default:SetTexture( "$basetexture", glow:GetTexture("$basetexture"));
			default:SetInt( "$selfillum", 1);
		else
			default:SetTexture( "$basetexture", noglow:GetTexture("$basetexture"));
			default:SetInt( "$selfillum", 0);
		end
	else
		default:SetTexture( "$basetexture", noglow:GetTexture("$basetexture"));
		default:SetInt( "$selfillum", 0);
	end
end

end

-- AGP 2026-11-12 (owner: "CAP's is way better held in the hand - why can't we have it exactly the same way"): CAP's own
-- first-person model and animations, with the player's own hands laid onto its arm skeleton
-- (lua/autorun/agp_blueprint_arms.lua). 2026-11-10's GMod hand animations never fitted this item.
if (AGP and AGP.BlueprintArms) then
    AGP.BlueprintArms(SWEP, { vm = "models/Madman07/minidrone_platform/key_v.mdl", hide = { "v_hands" }, arms = AGP.BlueprintRigs.iziR })
end
-- (third person: the key in the hand - its world model has no hand bone, the engine left it at the feet; this half of
-- 2026-11-10's fix was lost with the first-person change of 2026-11-12 and found again by suite heldall)
if (AGP and AGP.WorldOnHand) then
    AGP.WorldOnHand(SWEP, { model = "models/Madman07/minidrone_platform/key_w.mdl", pos = Vector(3.4, 2.4, -0.6), ang = Angle(-120, 180, 0), size = 1.5 })
end
