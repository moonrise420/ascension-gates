--[[
	O'Neill (the Asgard warship of the series, O'Neill-class) - Ascension Gates' own code and model, designed after
	the series. EAP's model and code are gone; the class name stays
	"sg_vehicle_oneill", so saves and dupes keep working (same Wire names, same keyboard layout "Oneill"). Built on:

	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's energy_pulse (aVoN, Madman07) for the ion guns' shots, CAP's energy_beam2 for the Asgard beam
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua): shield, hull damage,
	    aiming, hyperdrive, the Supergate / Stargate dial menu
	As in the series: four ion guns (two under the head, two in pods on the wings), the Asgard beam, shield, hyperdrive.
	Keys: Mouse1 ion guns, Mouse2 Asgard beam at the crosshair (holding it aims the guns too), G shield,
	H hyperdrive (hold), R dial menu, 1 bridge view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "O'Neill"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_oneill") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_capital_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 30000       -- hyperdrive (H): longest jump
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own model, designed after the series
local MODEL = "models/agp/oneill/agp_oneill.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble: a flat ellipsoid round the hull and the fins, Asgard blue
ENT.AGPShield = { model = "models/iziraider/shields/4x4x3.mdl", yaw = 0, offset = Vector(32, 0, 98), scale = Vector(0.73, 0.94, 0.4), color = { 0.6, 0.8, 1 } }   -- fitted round every point of the hull (balance, the
-- series' order: Ori > O'Neill > Aurora > Daedalus > Destiny > Prometheus > Al'kesh > Tel'tak) the shield holds 34000
-- damage (a beam: 34 s)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 34000, 34

local HULL = 30000
local ION = Color(150, 200, 255)
-- model space (+X = bow; measured on agp_oneill.mdl): the muzzles of the four ion guns (two under the head, two at the
-- front of the wing pods), the Asgard beam emitter at the nose
local GUNS = { Vector(463, 61, -51), Vector(463, -61, -51), Vector(22, 488, 33), Vector(22, -488, 33) }
local BEAM_AT = Vector(566, 0, 6)
-- the engine stripe across the stern (points along it, port to starboard)
local DRIVE = { Vector(-460, -130, 6), Vector(-474, -98, 6), Vector(-486, -65, 6), Vector(-495, -32, 6), Vector(-498, 0, 6),
	Vector(-495, 32, 6), Vector(-486, 65, 6), Vector(-474, 98, 6), Vector(-460, 130, 6) }

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_oneill")
		e:SetPos(tr.HitPos + Vector(0, 0, 200))
		e:SetAngles(Angle(0, ply:GetAimVector():Angle().y, 0))
		e:Spawn()
		e:Activate()
		e:SetVar("Owner", ply)
		ply:AddCount("CAP_ships", e)
		return e
	end

	function ENT:Initialize()
		self:SetModel(self:AGPModel())
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:StartMotionController()
		self.Vehicle = "Oneill"
		self.EntHealth, self.MaxHealth = HULL, HULL
		self.ExitPos = self:GetPos() + Vector(0, 0, 250)
		self.On, self.Roll = 0, 0
		self.HoverPos, self.NextLand = self:GetPos(), CurTime()   -- what the base's Initialize sets (the LAND key needs it)
		-- flight: a warship, quicker on its controls than the old ships
		self.Accel = { FWD = 0, RIGHT = 0, UP = 0, SpeedForward = 10, SpeedRight = 7, SpeedUp = 7 }
		self.ForwardSpeed, self.BackwardSpeed = 1500, -700
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 2200, 750, 600
		self.RollSpeed = 4
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		self.NextGuns, self.NextBeam = 0, 0
		-- the old Wire names stay (dupes keep their wiring); fire, beam and shield inputs are new
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Beam", "Beam Target [VECTOR]", "Shield", "Hyperspace [VECTOR]") end
		if (self.CreateWireOutputs) then self:CreateWireOutputs("Health", "Shield Strength", "Shield Enabled") end
		local phys = self:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:SetMass(10000)
			phys:EnableMotion(false)   -- stays where it was spawned until someone flies it
			phys:Wake()
		end
		self:AGPSetWire("Health", HULL)
	end

	function ENT:AGPSetWire(name, v)
		if (self.SetWire) then self:SetWire(name, v) end
	end

	function ENT:OnTakeDamage(dmg)
		self:AGPHullDamage(dmg)
		self:AGPSetWire("Health", math.max(0, math.floor(self.EntHealth or 0)))
	end

	function ENT:OnRemove()
		if (AGP and AGP.ShipShieldRemove) then AGP.ShipShieldRemove(self) end
		self.BaseClass.OnRemove(self)
	end

	function ENT:ToggleShield()
		if (AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self) end
	end

	function ENT:TriggerInput(k, v)
		if (k == "Fire") then self.WireFire = (v ~= 0)
		elseif (k == "Beam") then self.WireBeam = (v ~= 0)
		elseif (k == "Beam Target") then self.WireTarget = (isvector(v) and v ~= Vector(0, 0, 0)) and Vector(v) or nil
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	-- the four ion guns, one after the other: at the target (wired: the Beam Target), else straight ahead, or at the
	-- crosshair while Mouse2 is held
	function ENT:FireGuns(target)
		if (CurTime() < self.NextGuns) then return end
		self.NextGuns = CurTime() + 1.4
		for i, m in ipairs(GUNS) do
			timer.Simple((i - 1) * 0.09, function()
				if (not IsValid(self)) then return end
				local from = self:LocalToWorld(m)
				local dir = target and (target - from):GetNormalized() or (AGP and AGP.ShipAimDir and AGP.ShipAimDir(self, from) or self:GetForward())
				if (dir:Dot(self:GetForward()) < 0.1) then dir = self:GetForward() end
				local e = ents.Create("energy_pulse")
				if (not IsValid(e)) then return end
				self.AGPShotsFired = (self.AGPShotsFired or 0) + 1
				e:PrepareBullet(dir, 10, 18000, 9, { self })
				e:SetPos(from + dir * 12)
				e:SetOwner(self)
				e.Owner = self
				e:Spawn()
				e:Activate()
				e:SetColor(ION)
				e.Damage = 350   -- (balance)
				self:EmitSound("eap/ship/armes/asgardflak.mp3", 90, math.random(95, 110))
			end)
		end
	end

	-- the Asgard beam from the head's front, at the crosshair (or a wired target), every 3 s
	function ENT:FireBeam(target)
		if (CurTime() < self.NextBeam or not target) then return end
		local from = self:LocalToWorld(BEAM_AT)
		local dir = (target - from):GetNormalized()
		if (dir:Dot(self:GetForward()) < 0.2) then dir = self:GetForward() end   -- the emitter faces forward
		local e = ents.Create("energy_beam2")
		if (not IsValid(e)) then return end
		self.NextBeam = CurTime() + 3
		self.AGPShotsFired = (self.AGPShotsFired or 0) + 1
		e.Owner = self
		e:SetPos(from)
		e:Spawn()
		e:Activate()
		e:SetOwner(self)
		e:Setup(from, dir, 1200, 1.5, "Asgard")
		self:EmitSound("eap/ship/armes/asgardcanonbeam.mp3", 100, math.random(98, 102))
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() + self:GetUp() * 250
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			if (p:KeyDown(self.Vehicle, "FIRE")) then self:FireGuns() end
			local aim = AGP and AGP.ShipAimPoint and AGP.ShipAimPoint(self)   -- set while Mouse2 is held
			if (aim) then self:FireBeam(aim) end
		end
		if (self.WireFire) then self:FireGuns(self.WireTarget) end
		if (self.WireBeam) then self:FireBeam(self.WireTarget or (self:GetPos() + self:GetForward() * 20000)) end
		self:AGPSetWire("Shield Enabled", self.AGPShielded and 1 or 0)
		local gen = AGP and AGP.ShipShieldGen and AGP.ShipShieldGen(self)
		self:AGPSetWire("Shield Strength", IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 0)
		self:NextThink(CurTime() + 0.1)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_oneill", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys (the same layout name as before, so players keep their bindings)
	local KBD = StarGate.KeyBoard:New("Oneill")
	local B = StarGate.KeyBoard.BINDS
	KBD:SetDefaultKey("FWD", B["+forward"] or "W")
	KBD:SetDefaultKey("BACK", B["+back"] or "S")
	KBD:SetDefaultKey("LEFT", B["+moveleft"] or "A")
	KBD:SetDefaultKey("RIGHT", B["+moveright"] or "D")
	KBD:SetDefaultKey("UP", B["+jump"] or "SPACE")
	KBD:SetDefaultKey("DOWN", B["+duck"] or "CTRL")
	KBD:SetDefaultKey("SPD", B["+speed"] or "SHIFT")
	KBD:SetDefaultKey("RL", "MWHEELDOWN")
	KBD:SetDefaultKey("RR", "MWHEELUP")
	KBD:SetDefaultKey("RROLL", "MOUSE3")
	KBD:SetDefaultKey("FIRE", B["+attack"] or "MOUSE1")
	KBD:SetDefaultKey("TRACK", B["+attack2"] or "MOUSE2")
	KBD:SetDefaultKey("SHIELD", "G")
	KBD:SetDefaultKey("DHD", "R")
	KBD:SetDefaultKey("HYPERSPACE", "H")
	KBD:SetDefaultKey("LAND", "ENTER")
	KBD:SetDefaultKey("BOOM", "BACKSPACE")
	KBD:SetDefaultKey("VIEW", "1")
	KBD:SetDefaultKey("Z+", "UPARROW")
	KBD:SetDefaultKey("Z-", "DOWNARROW")
	KBD:SetDefaultKey("A+", "LEFTARROW")
	KBD:SetDefaultKey("A-", "RIGHTARROW")
	KBD:SetDefaultKey("EXIT", B["+use"] or "E")

	ENT.RenderGroup = RENDERGROUP_BOTH
	ENT.Sounds = { Engine = Sound("eap/ship/moteur/asgard.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "Oneill"
		self.Dist, self.UDist = -750, 180
		self.FirstPerson = false
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	-- the engine stripe across the stern: while it flies forward it glows blue, a little blurred (seen by everyone)
	function ENT:DrawTranslucent()
		self:AGPEngineLine(DRIVE, { 150, 195, 255 }, 10)
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		-- camera distance / height on the arrow keys, bridge view on 1
		if (p:KeyDown("Oneill", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("Oneill", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("Oneill", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("Oneill", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("Oneill", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
