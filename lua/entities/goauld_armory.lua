--[[
	Goa'uld Armory - Ascension Gates' own code (2026-11-06), no Evolution Addon Pack code left; the class name stays.
	A Goa'uld weapons chest (our Zat chest model by Ska-Ara, see CREDITS): press USE to take a Zat'nik'tel and a staff
	weapon, and the ammo is topped up. Other armories derive from it and set their own ENT.ArmoryModel,
	ENT.Weapons and ENT.Ammo ({ ammo type, top up while below, amount }).
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Goa'uld Armory"
ENT.Author = "Ascension Gates"
ENT.Purpose = "Take Goa'uld weapons."
ENT.Instructions = "Press USE."
ENT.Category = "Others"
ENT.Spawnable = false -- in our spawn tab
ENT.AdminSpawnable = false
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
	ENT.PrintName = SGLanguage.GetMessage("ent_goauld_ammo")
	ENT.Category = SGLanguage.GetMessage("cat_others")
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

ENT.ArmoryModel = "models/agp/hatak/props/zat_chest.mdl"
ENT.Weapons = { "weapon_zat", "weapon_staff" }
ENT.Ammo = { { "GaussEnergy", 150, 50 }, { "CombineCannon", 200, 100 } }
ENT.TakeSound = "items/ammo_pickup.wav"

if SERVER then
	if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("extra")) then return end
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr, class)
		if (not tr.Hit) then return end
		local ang = ply:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y + 180) % 360
		local e = ents.Create(class or self.ClassName)
		e:SetPos(tr.HitPos + Vector(0, 0, 4))
		e:SetAngles(ang)
		e:Spawn()
		e:Activate()
		e.Owner = ply
		return e
	end

	function ENT:Initialize()
		self:SetModel(self.ArmoryModel)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if (IsValid(phys)) then phys:SetMass(800); phys:Wake() end
		self.Hull = 200
	end

	-- hands out what is missing; one press a second
	function ENT:Use(ply)
		if (not IsValid(ply) or not ply:IsPlayer() or CurTime() < (self.NextTake or 0)) then return end
		self.NextTake = CurTime() + 1
		local gave = false
		for _, w in ipairs(self.Weapons) do
			if (weapons.GetStored(w) and not ply:HasWeapon(w)) then ply:Give(w); gave = true end
		end
		for _, a in ipairs(self.Ammo) do
			if (ply:GetAmmoCount(a[1]) < a[2]) then ply:GiveAmmo(a[3], a[1], true); gave = true end
		end
		if (gave) then self:EmitSound(self.TakeSound, 70, 100) end
	end

	function ENT:OnTakeDamage(dmg)
		self.Hull = self.Hull - dmg:GetDamage()
		if (self.Hull <= 0 and not self.AGPBroken) then
			self.AGPBroken = true
			local fx = EffectData(); fx:SetOrigin(self:GetPos()); util.Effect("Explosion", fx)
			self:Remove()
		end
	end
end
