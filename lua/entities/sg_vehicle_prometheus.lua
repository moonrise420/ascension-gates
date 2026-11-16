--[[
	Prometheus (the BC-303 of the series) - Ascension Gates' own code and model (2026-11-07), designed after the series
	(notes/models/agp_prometheus_ship_*.py).
	EAP's model and code are gone; the class name stays "sg_vehicle_prometheus", so saves and dupes keep working (same
	Wire names, same keyboard layout "Prometheus"). Built on:
	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's F-302 missile (302missile, Zup / aVoN, the same the Daedalus fires) for the missiles
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua): shield, hull damage,
	    hyperdrive, the Supergate / Stargate dial menu
	As in the series: missiles from the hatches on top of the hull, rail guns in four turrets, shield, hyperdrive.
	Keys: Mouse1 missiles (they fly to the crosshair), Mouse2 rail guns at the crosshair (hold), G shield,
	H hyperdrive (hold), R dial menu, 1 view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "Prometheus"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_prometheus") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_capital_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 30000       -- hyperdrive (H): longest jump
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own model, designed after the series (notes/models/agp_prometheus_ship_models.py)
local MODEL = "models/agp/prometheus/agp_prometheus.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble: a long flat ellipsoid round the hull, the tower with its masts and the pods (fitted round every
-- point, 2026-11-07)
ENT.AGPShield = { model = "models/iziraider/shields/4x4x3.mdl", yaw = 0, offset = Vector(38, 0, 115), scale = Vector(0.77, 0.34, 0.42), color = { 0.6, 0.8, 1 } }
-- (2026-11-07 balance, the series' order: Ori > O'Neill > Aurora > Daedalus > Destiny > Prometheus > Al'kesh > Tel'tak)
-- the shield holds 20000 damage (a beam: 20 s)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 20000, 20

local HULL = 25000
-- model space (+X = bow; measured on agp_prometheus.mdl): the missile hatches on top of the hull, the muzzles of the
-- four rail gun turrets (two on the deck, two on the hull), the two engines' nozzles
local HATCHES = { Vector(-60, 38, 66), Vector(-60, -38, 66) }
local RAILS = { Vector(-247, 168, 135), Vector(83, 36, 73), Vector(-247, -168, 135), Vector(83, -36, 73) }
local DRIVE = { { Vector(-474, 52, -32), 34 }, { Vector(-474, -52, -32), 34 } }

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_prometheus")
		e:SetPos(tr.HitPos + Vector(0, 0, 180))
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
		self.Vehicle = "Prometheus"
		self.EntHealth, self.MaxHealth = HULL, HULL
		self:SetNWInt("health", HULL)
		self:SetNWInt("maxEntHealth", HULL)
		self.ExitPos = self:GetPos() - self:GetRight() * 250
		self.On, self.Roll = 0, 0
		self.HoverPos, self.NextLand = self:GetPos(), CurTime()   -- what the base's Initialize sets (the LAND key needs it)
		-- flight: the old Prometheus's
		self.Accel = { FWD = 0, RIGHT = 0, UP = 0, SpeedForward = 10, SpeedRight = 7, SpeedUp = 7 }
		self.ForwardSpeed, self.BackwardSpeed = 1500, -750
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 2000, 750, 600
		self.RollSpeed = 5
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		-- the missiles (302missile) read these from their ship: how long they may home, where to
		self.TrackTime, self.MissileMaxVel = 1000000, 10000000
		self.Target, self.Track = Vector(0, 0, 0), false
		self.NextMissiles, self.NextRails, self.RailPair = 0, 0, 0
		-- the old Wire name stays (dupes keep their wiring); fire, rails, target and shield are new
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Rails", "Target [VECTOR]", "Shield", "Hyperspace [VECTOR]") end
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
		elseif (k == "Rails") then self.WireRails = (v ~= 0)
		elseif (k == "Target") then self.WireTarget = (isvector(v) and v ~= Vector(0, 0, 0)) and Vector(v) or nil
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	-- two missiles out of the hatches, straight up, then they fly to the target (self.Target while self.Track is set)
	function ENT:FireMissiles()
		if (CurTime() < self.NextMissiles) then return end
		self.NextMissiles = CurTime() + 2
		for _, h in ipairs(HATCHES) do
			local e = ents.Create("302missile")
			if (not IsValid(e)) then return end
			e.Parent = self
			e:SetPos(self:LocalToWorld(h) + self:GetUp() * 20)
			e:SetAngles(self:GetUp():Angle())
			e:Spawn()
			e:Activate()
			e:SetVelocity(self:GetUp() * self.MissileMaxVel)
			e:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
			e:SetOwner(self)
			e.Damage = 400   -- (2026-11-07 balance; the F-302 missile's own 150)
			e.AGPSweep = true   -- (2026-11-08) it hits whatever lies on its path (fast, it flew through hulls)
			self.AGPShotsFired = (self.AGPShotsFired or 0) + 1
		end
		self:EmitSound("eap/ship/armes/firemissile2.wav", 100, 100)
	end

	-- the rail guns: two turrets at a time, every 0.1 s, at the target (never back through the hull); the bullets go out
	-- through the ship's own raised shield: for the moment they are fired (the bullets are traced right there) its bubble
	-- is not solid, else they hit its physics from inside (2026-11-07, shield test: no rail shot got out)
	function ENT:FireRails(target)
		if (CurTime() < self.NextRails or not target) then return end
		self.NextRails = CurTime() + 0.1
		self.RailPair = 1 - self.RailPair
		local own = AGP and AGP.ShipShieldEntity and AGP.ShipShieldEntity(self)
		local opened = IsValid(own) and own:IsSolid()
		if (opened) then own:SetNotSolid(true) end
		for i = 1 + self.RailPair, #RAILS, 2 do
			local from = self:LocalToWorld(RAILS[i])
			local dir = (target - from):GetNormalized()
			if (dir:Dot(self:GetForward()) < -0.2) then dir = self:GetForward() end
			self:FireBullets({ Num = 1, Src = from, Dir = dir, Spread = Vector(0.02, 0.02, 0), Tracer = 1, TracerName = "AirboatGunTracer",
				Force = 1, Damage = 25, IgnoreEntity = self })   -- (2026-11-08 balance: ~280 a second)
			self.AGPShotsFired = (self.AGPShotsFired or 0) + 1
		end
		if (opened and IsValid(own)) then own:SetNotSolid(false) end
		self:EmitSound("eap/ship/armes/heavyrail.wav", 85, math.random(95, 105))
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() - self:GetRight() * 250
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			-- where the pilot aims: the missiles fly there, the rail guns fire there (AGP 2026-11-08: the crosshair from
			-- the pilot's camera, lua/autorun/agp_ship_aim.lua; the old trace from the ship's middle missed in the bridge view)
			self.Target, self.Track = AGP.ShipCrosshair(self), true
			if (p:KeyDown(self.Vehicle, "FIRE")) then self:FireMissiles() end
			if (p:KeyDown(self.Vehicle, "TRACK")) then self:FireRails(self.Target) end
		elseif (self.WireTarget) then
			self.Target, self.Track = self.WireTarget, true
		else
			self.Track = false
		end
		local wired = self.WireTarget or (self:GetPos() + self:GetForward() * 20000)
		if (self.WireFire) then self:FireMissiles() end
		if (self.WireRails) then self:FireRails(wired) end
		self:AGPSetWire("Shield Enabled", self.AGPShielded and 1 or 0)
		local gen = AGP and AGP.ShipShieldGen and AGP.ShipShieldGen(self)
		self:AGPSetWire("Shield Strength", IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 0)
		self:NextThink(CurTime() + 0.05)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_prometheus", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys (the same layout name as before, so players keep their bindings)
	local KBD = StarGate.KeyBoard:New("Prometheus")
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
	ENT.Sounds = { Engine = Sound("eap/ship/moteur/bc303.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "Prometheus"
		self.Dist, self.UDist = -750, 120
		self.FirstPerson = false
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	-- the two round engines: their cores always glow softly (a warm halo round the nozzle's mouth, owner 2026-11-07: "the
	-- orange is flat and lifeless"); while it flies forward a soft orange plume as well (seen by everyone)
	local HALO = Material("sprites/light_glow02_add")
	local HALO_COL = Color(255, 140, 60, 150)
	function ENT:DrawTranslucent()
		render.SetMaterial(HALO)
		for _, n in ipairs(DRIVE) do
			render.DrawSprite(self:LocalToWorld(n[1]), n[2] * 3.4, n[2] * 3.4, HALO_COL)
		end
		self:AGPEngineNozzles(DRIVE, { 255, 150, 80 }, 240)
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		-- camera distance / height on the arrow keys, the other view on 1
		if (p:KeyDown("Prometheus", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("Prometheus", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("Prometheus", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("Prometheus", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("Prometheus", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
