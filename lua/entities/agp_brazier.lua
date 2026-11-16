--[[
	Brazier (Ascension Gates)
	A Goa'uld brazier with a burning fire: flickering warm light (lights the gold walls around it), flames and embers.
	Used in ship interiors (agp_hatak); also in the spawn menu.
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
if (StarGate and StarGate.LifeSupportAndWire) then StarGate.LifeSupportAndWire(ENT) end
ENT.PrintName = "Brazier"
ENT.Author = "Ascension Gates"
ENT.Category = "Ascension Gates"
ENT.Spawnable = false   -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Model = "models/boba_fett/props/jaffa_brazier.mdl"
ENT.FireHeight = 66            -- top of the bowl above the origin

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Lit")
	self:NetworkVar("Bool", 1, "Alarm")   -- ship alarm (agp_hatak): the light turns red and flashes
end

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr, class)
		if (not tr.Hit) then return end
		local e = ents.Create(class)
		e:SetPos(tr.HitPos); e:Spawn(); e:Activate()
		return e
	end

	function ENT:Initialize()
		self:SetModel(self.Model)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		self:SetUseType(SIMPLE_USE)
		self:SetLit(true)
		self:EmitSound("ambient/fire/fire_small_loop1.wav", 55, 100, 0.5)
		if (self.CreateWireInputs) then
			self:CreateWireInputs("Disable Fire", "Toggle")
			self:CreateWireOutputs("Fire ON")
			self:SetWire("Fire ON", true)
		end
	end

	function ENT:SetFireOn(on)
		if (on == self:GetLit()) then return end
		self:SetLit(on)
		if (on) then self:EmitSound("ambient/fire/fire_small_loop1.wav", 55, 100, 0.5)
		else self:StopSound("ambient/fire/fire_small_loop1.wav"); self:EmitSound("ambient/fire/mtov_flame2.wav", 60) end
		if (self.SetWire) then self:SetWire("Fire ON", on) end
	end

	-- E (or the wire inputs) puts it out / lights it again
	function ENT:Use(ply) self:SetFireOn(not self:GetLit()) end

	function ENT:TriggerInput(k, v)
		if (k == "Disable Fire") then self:SetFireOn(v <= 0)
		elseif (k == "Toggle" and v > 0) then self:SetFireOn(not self:GetLit()) end
	end

	function ENT:OnRemove() self:StopSound("ambient/fire/fire_small_loop1.wav") end
end

if CLIENT then
	local matFire = Material("effects/fire_cloud1")
	local matGlow = Material("sprites/light_glow02_add")

	function ENT:Draw() self:DrawModel() end

	function ENT:DrawTranslucent()
		if (not self:GetLit()) then return end
		local top = self:LocalToWorld(Vector(0, 0, self.FireHeight))
		local t = CurTime() + self:EntIndex()
		local s = 1 + math.sin(t * 9) * 0.08 + math.sin(t * 23) * 0.05
		render.SetMaterial(matGlow)
		render.DrawSprite(top + Vector(0, 0, 8), 70 * s, 70 * s, Color(255, 150, 60, 200))
		render.SetMaterial(matFire)
		for i = 0, 2 do
			local h = (t * 1.6 + i / 3) % 1
			render.DrawSprite(top + Vector(math.sin(t * 3 + i) * 3, math.cos(t * 2 + i) * 3, 4 + h * 26), (22 - h * 12) * s, (30 - h * 14) * s, Color(255, 180 - h * 80, 80, 255 * (1 - h)))
		end
	end

	-- the warm light: a dynamic light that flickers like a real fire
	function ENT:Think()
		if (EyePos():DistToSqr(self:GetPos()) > 2500 * 2500) then return end
		if (self:GetAlarm()) then
			local d = DynamicLight(self:EntIndex())
			if (d) then
				d.pos = self:LocalToWorld(Vector(0, 0, self.FireHeight + 30))
				d.r, d.g, d.b = 255, 20, 10
				d.brightness = 4 * math.max(0, math.sin(CurTime() * 5))
				d.size = 500
				d.decay = 2000
				d.dietime = CurTime() + 0.2
			end
			self:SetNextClientThink(CurTime())
			return true
		end
		if (not self:GetLit()) then return end
		local d = DynamicLight(self:EntIndex())
		if (d) then
			local t = CurTime() + self:EntIndex()
			d.pos = self:LocalToWorld(Vector(0, 0, self.FireHeight + 14))
			d.r, d.g, d.b = 255, 140, 60
			d.brightness = 2.2 + math.sin(t * 11) * 0.25 + math.sin(t * 27) * 0.15
			d.size = 380
			d.decay = 1000
			d.dietime = CurTime() + 0.2
		end
		self:SetNextClientThink(CurTime())
		return true
	end
end
