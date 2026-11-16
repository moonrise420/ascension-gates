--[[
	Force field (Ascension Gates)
	A flat blue energy wall, any size: the Ha'tak's holding cells and the field in front of the cargo hold's Stargate.
	Use (E) or Wire: On (1 on / 0 off), Toggle (each press). Output: On. Solid only while on.
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then StarGate.LifeSupportAndWire(ENT) end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Force Field"
ENT.Author = "Ascension Gates"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Force Field"
ENT.Spawnable = false   -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "FieldWidth")
	self:NetworkVar("Float", 1, "FieldHeight")
	self:NetworkVar("Bool", 0, "On")
end

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.Hit) then return end
		local e = ents.Create("agp_force_field")
		e:SetPos(tr.HitPos)
		e:SetAngles(Angle(0, ply:GetAimVector():Angle().y, 0))
		e:Setup(128, 128)
		e:Spawn(); e:Activate()
		e.Owner = ply
		if (e.CPPISetOwner) then e:CPPISetOwner(ply) end
		local ph = e:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(false) end
		return e
	end

	-- size (units): width along local Y, height up from the origin; the field is a plane facing local X
	function ENT:Setup(w, h)
		self.SetupSize = { w, h }
		if (self.Initialized) then self:BuildPhysics() end
	end

	function ENT:BuildPhysics()
		local w, h = unpack(self.SetupSize or { 128, 128 })
		self:SetFieldWidth(w); self:SetFieldHeight(h)
		local frozen = IsValid(self:GetPhysicsObject()) and not self:GetPhysicsObject():IsMotionEnabled()
		-- a real model with box collision where one exists for this size (notes/hatak/mkfield.py): a physics box made
		-- here stays behind when the parent ship moves, and players walked through the field
		local mdl = string.format("models/agp/hatak/props/field_%dx%dx4.mdl", math.Round(w), math.Round(h))
		if (file.Exists(mdl, "GAME")) then
			self:SetModel(mdl)
			self:PhysicsInit(SOLID_VPHYSICS)
		else
			self:PhysicsInitBox(Vector(-2, -w / 2, 0), Vector(2, w / 2, h))
			self:SetCollisionBounds(Vector(-2, -w / 2, 0), Vector(2, w / 2, h))
		end
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetMass(200); if (frozen) then ph:EnableMotion(false) end end
		self:SetOnState(self:GetOn())
	end

	function ENT:Initialize()
		self:SetModel("models/hunter/blocks/cube025x025x025.mdl")   -- the field itself is drawn on the client
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(false)
		self:SetOn(true)
		if (self.CreateWireInputs) then
			self:CreateWireInputs("On", "Toggle")
			self:CreateWireOutputs("On")
		end
		self.Initialized = true
		self:BuildPhysics()
	end

	function ENT:SetOnState(on)
		local was = self:GetOn()
		self:SetOn(on)
		self:SetNotSolid(not on)
		self:SetCollisionGroup(on and COLLISION_GROUP_NONE or COLLISION_GROUP_WORLD)
		if (self.SetWire) then self:SetWire("On", on and 1 or 0) end
		if (was ~= on) then self:EmitSound(on and "buttons/combine_button1.wav" or "buttons/combine_button2.wav", 70, on and 90 or 70) end
	end

	function ENT:Use(ply)
		self:SetOnState(not self:GetOn())
	end

	function ENT:TriggerInput(name, v)
		if (name == "On") then self:SetOnState(v ~= 0)
		elseif (name == "Toggle" and v ~= 0) then self:SetOnState(not self:GetOn()) end
	end
end

if CLIENT then
	local mat = Material("models/props_combine/com_shield001a")
	function ENT:Draw() end
	function ENT:DrawTranslucent()
		local w, h = self:GetFieldWidth(), self:GetFieldHeight()
		local mx = Vector(4, w / 2, h)
		self:SetRenderBounds(Vector(-4, -w / 2, 0), mx)
		if (not self:GetOn()) then return end
		-- flicker a little, as on low power in the series
		local a = 150 + 40 * math.sin(CurTime() * 7 + self:EntIndex())
		local c = self:LocalToWorld(Vector(0, 0, h / 2))
		render.SetMaterial(mat)
		render.DrawQuadEasy(c, self:GetForward(), w, h, Color(120, 170, 255, a), 0)
		render.DrawQuadEasy(c, -self:GetForward(), w, h, Color(120, 170, 255, a), 0)
	end
end
