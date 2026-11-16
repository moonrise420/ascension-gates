-- AGP 2026-11-12: the loader's own SWEP table (a local one registered by a 0.1 s timer came after the spawn menu was
-- built: the weapon had no class name there yet and was left out of the weapons tab)
SWEP.PrintName      = "Tollan Hands"
SWEP.DrawCrosshair	= true
SWEP.SlotPos = 1
SWEP.Slot = 1
SWEP.Spawnable = false
SWEP.Weight = 1
SWEP.HoldType = "normal"
SWEP.Primary.Ammo = "none" --This stops it from giving pistol ammo when you get the hands
SWEP.Secondary.Ammo = "none"

function SWEP:DrawWorldModel() end
function SWEP:DrawWorldModelTranslucent() end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

function SWEP:Initialize()
    if self.SetHoldType then
		self:SetHoldType("normal")
	else
		self:SetWeaponHoldType("normal") -- This makes your arms go to your sides
	end
	self:DrawShadow(false)
end

function SWEP:PreDrawViewModel() -- This stops it from displaying as a pistol in your hands
	return true
end

function SWEP:OnDrop()
    if SERVER then
		self:Remove() -- This deletes the SWEP entity if you drop it so there isn't just invisible hands somewhere
	end
end
