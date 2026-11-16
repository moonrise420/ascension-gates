--[[
	Goa'uld Sarcophagus - Ascension Gates' own code (2026-11-06), no Evolution Addon Pack code left. The class name
	stays "sarcophagus" (saves, dupes, the Ha'tak interior). Model: ours, designed after the series,
	models/agp/props/agp_sarcophagus.mdl (series size since 2026-11-06: 151 x 42 x 40 units, about 3.8 m long).
	USE: the lid halves slide apart, you lie down inside, the lid closes and you heal (up to 150 health, fire goes
	out). USE again - or when you are healed - and the lid opens and you climb out beside it. While inside you see the
	sarcophagus from above. Wire: input "Eject"; outputs "Active", "Player Health", "Entity [ENTITY]".
]]
-- AGP 2026-11-08: gives the entity CreateWireInputs/Outputs, SetWire and Wire links in dupes; without it the Wire
-- ports promised above never existed (Initialize only makes them when these functions are there)
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then StarGate.LifeSupportAndWire(ENT) end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Goa'uld Sarcophagus"
ENT.Author = "Ascension Gates"
ENT.Purpose = "For a Goa'uld long life."
ENT.Instructions = "Press USE to enter and to leave."
ENT.Category = "Others"
ENT.Spawnable = false -- in our spawn tab
ENT.AdminSpawnable = false
ENT.WireDebugName = "Sarcophagus"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
	ENT.PrintName = SGLanguage.GetMessage("ent_goauld_sarcophage")
	ENT.Category = SGLanguage.GetMessage("cat_others")
end
list.Set("CAP.Entity", ENT.PrintName, ENT)

local MODEL = "models/agp/props/agp_sarcophagus.mdl"
local MAX_HEAL = 150
local HEAL = 3           -- per quarter second
local LID_TIME = 0.8     -- seconds for the lid to open or close
local SOUND = "eap/entities/sarcophage.wav"   -- from the series

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "LidOpen")      -- 0 closed .. 1 open (target; the client eases towards it)
	self:NetworkVar("Entity", 0, "Occupant")
end

if SERVER then
	if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("extra")) then return end
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr, class)
		if (not tr.Hit) then return end
		local ang = ply:GetAimVector():Angle(); ang.p = 0; ang.r = 0; ang.y = (ang.y + 180) % 360
		local e = ents.Create(class or self.ClassName)
		e:SetPos(tr.HitPos + Vector(0, 0, 8))
		e:SetAngles(ang)
		e:Spawn()
		e:Activate()
		e.Owner = ply
		return e
	end

	function ENT:Initialize()
		self:SetModel(MODEL)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		local phys = self:GetPhysicsObject()
		if (IsValid(phys)) then phys:SetMass(3000); phys:Wake() end
		self.Hull = 600
		self:SetLidOpen(0)
		if (self.CreateWireInputs) then self:CreateWireInputs("Eject") end
		if (self.CreateWireOutputs) then self:CreateWireOutputs("Active", "Player Health", "Entity [ENTITY]") end
	end

	function ENT:AGPWire(k, v) if (self.SetWire) then self:SetWire(k, v) end end

	function ENT:TriggerInput(k, v)
		if (k == "Eject" and v ~= 0) then self:LetOut() end
	end

	-- where the occupant lies (model space: the body between the drums) and where they climb out
	function ENT:InsidePos() return self:LocalToWorld(Vector(40, 0, 5)) end
	function ENT:ExitPos(ply)
		local mn, mx = ply:OBBMins(), ply:OBBMaxs()
		for _, side in ipairs({ 1, -1 }) do
			local want = self:LocalToWorld(Vector(40, side * 44, 4))   -- beside the body (model -Y / +Y are its sides)
			local tr = util.TraceHull({ start = want + Vector(0, 0, 40), endpos = want, mins = mn, maxs = mx, filter = { self, ply } })
			if (not tr.StartSolid) then return tr.HitPos end
		end
		return self:GetPos() + Vector(0, 0, 60)
	end

	function ENT:Use(ply)
		if (not IsValid(ply) or not ply:IsPlayer() or not ply:Alive()) then return end
		local occ = self:GetOccupant()
		if (IsValid(occ)) then
			if (occ == ply) then self:LetOut() end
			return
		end
		if (ply:InVehicle() or IsValid(ply.AGPSarcophagus) or (self.NextUse or 0) > CurTime()) then return end
		self:TakeIn(ply)
	end

	function ENT:TakeIn(ply)
		self.NextUse = CurTime() + LID_TIME * 2
		self:SetLidOpen(1)
		self:EmitSound(SOUND, 75, 100)
		self:SetOccupant(ply)
		ply.AGPSarcophagus = self
		ply:SetNWEntity("AGPSarcophagus", self)
		-- hidden inside: not drawn, not solid, frozen; keys still reach us (USE to get out)
		ply:SetPos(self:InsidePos())
		ply:SetNoDraw(true)
		ply:SetNotSolid(true)
		ply:DrawWorldModel(false)
		ply:DrawViewModel(false)
		ply:Freeze(true)
		ply:Extinguish()
		self:AGPWire("Active", 1); self:AGPWire("Entity", ply)
		timer.Simple(LID_TIME + 0.3, function() if (IsValid(self) and self:GetOccupant() == ply) then self:SetLidOpen(0) end end)
	end

	function ENT:LetOut()
		local ply = self:GetOccupant()
		self:SetOccupant(NULL)
		self.NextUse = CurTime() + LID_TIME * 2
		self:AGPWire("Active", 0); self:AGPWire("Entity", NULL)
		if (not IsValid(ply)) then return end
		ply.AGPSarcophagus = nil
		ply:SetNWEntity("AGPSarcophagus", NULL)
		ply:Freeze(false)
		-- (2026-11-12) died inside: un-hiding a dead player draws his model next to the body - he becomes visible again
		-- when he respawns (autorun/server/agp_one_body.lua), and is not moved
		local alive = ply:Alive()
		if (alive) then ply:SetNoDraw(false) else ply.AGPHiddenAtDeath = true end
		ply:SetNotSolid(false)
		ply:DrawWorldModel(true)
		ply:DrawViewModel(true)
		if (IsValid(self)) then
			self:SetLidOpen(1)
			self:EmitSound(SOUND, 75, 100)
			if (alive) then ply:SetPos(self:ExitPos(ply)) end
			timer.Simple(LID_TIME + 1.5, function() if (IsValid(self) and not IsValid(self:GetOccupant())) then self:SetLidOpen(0) end end)
		end
	end

	function ENT:Think()
		local ply = self:GetOccupant()
		if (IsValid(ply)) then
			if (not ply:Alive()) then self:LetOut()
			else
				ply:SetPos(self:InsidePos())                     -- moves with the sarcophagus (a ship flying it)
				if (ply:Health() < MAX_HEAL) then
					ply:SetHealth(math.min(MAX_HEAL, ply:Health() + HEAL))
				elseif (CurTime() > (self.NextUse or 0)) then
					self:LetOut()                                -- healed: out you come
				end
				self:AGPWire("Player Health", ply:Health())
			end
		end
		self:NextThink(CurTime() + 0.25)
		return true
	end

	function ENT:OnTakeDamage(dmg)
		self.Hull = self.Hull - dmg:GetDamage()
		if (self.Hull <= 0 and not self.AGPBroken) then
			self.AGPBroken = true
			self:LetOut()
			local fx = EffectData(); fx:SetOrigin(self:GetPos()); util.Effect("Explosion", fx)
			self:Remove()
		end
	end

	function ENT:OnRemove()
		if (IsValid(self:GetOccupant())) then self:LetOut() end
		if (StarGate.WireRD and StarGate.WireRD.OnRemove) then StarGate.WireRD.OnRemove(self) end -- AGP 2026-11-08: Wire clean-up
	end

	-- the occupant leaves the game or a USE press comes while they are frozen inside
	hook.Add("PlayerDisconnected", "AGP.Sarcophagus", function(ply)
		if (IsValid(ply.AGPSarcophagus)) then ply.AGPSarcophagus:LetOut() end
	end)
	hook.Add("KeyPress", "AGP.Sarcophagus", function(ply, key)
		if (key == IN_USE and IsValid(ply.AGPSarcophagus) and CurTime() > (ply.AGPSarcophagus.NextUse or 0)) then ply.AGPSarcophagus:LetOut() end
	end)

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sarcophagus", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	-- the lid halves slide apart (bones of our model), a golden glow while someone lies inside
	function ENT:Draw()
		local target = self:GetLidOpen()
		self.AGPLid = math.Approach(self.AGPLid or target, target, FrameTime() / LID_TIME)
		local e = math.sin(self.AGPLid * math.pi / 2)
		for name, side in pairs({ lid_l = -1, lid_r = 1 }) do
			local b = self:LookupBone(name)
			-- bone space: the export turns the model by 90 degrees, so the bones' X is the model's side (Y)
			if (b) then self:ManipulateBonePosition(b, Vector(side * 16 * e, 0, -1.2 * e), false) end
		end
		self:DrawModel()
		if (IsValid(self:GetOccupant()) or self.AGPLid > 0.05) then
			local d = DynamicLight(self:EntIndex())
			if (d) then
				d.pos = self:LocalToWorld(Vector(40, 0, 25)); d.r, d.g, d.b = 255, 190, 90
				d.brightness = 0.5 + 1.5 * self.AGPLid; d.size = 90; d.decay = 600; d.dietime = CurTime() + 0.2
			end
		end
	end

	-- inside: the view from above and beside the sarcophagus, looking down at it
	hook.Add("CalcView", "AGP.Sarcophagus", function(ply, origin, angles, fov)
		local s = ply:GetNWEntity("AGPSarcophagus")
		if (not IsValid(s)) then return end
		local eye = s:LocalToWorld(Vector(40, -100, 105))
		return { origin = eye, angles = (s:LocalToWorld(Vector(40, 0, 12)) - eye):Angle(), fov = fov, drawviewer = false }
	end)
end
