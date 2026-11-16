--[[
	Aurora-class battleship (Ancient warship from Stargate Atlantis) - Ascension Gates' own code (2026-11-06).
	Model and code are ours (EAP's model and code are gone since 2026-11-06). The class name stays
	"sg_vehicle_aurora", so saves and dupes keep working. Built on:
	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * the Ancient drone "drone" (CAP, Zup): the drones home in on ship.Target while ship.Track is set
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua): shield, hull damage,
	    aiming, pulse volleys, hyperdrive, the Supergate / Stargate dial menu
	Weapons as in the series: drones out of the launchers along the hull, pulse turrets on the upper deck.
	Keys: Mouse1 drones at the crosshair (a volley of 4 per press, up to 16 in flight; owner 2026-11-08: the drones
	follow the crosshair without holding Mouse2), a Mouse2 press = turret volley at the crosshair, G shield,
	H hyperdrive (hold), R dial menu, 1 bridge view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab (list below)
ENT.PrintName = "Aurora"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_aurora") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("entity_ships_cat") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 30000       -- hyperdrive: longest jump
ENT.AGPCamBack, ENT.AGPCamUp = 1.15, 0.22
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own model, designed after the series (notes/models/agp_aurora_test.py)
local MODEL = "models/agp/aurora/agp_aurora.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble: a long ellipsoid stretched round the hull
ENT.AGPShield = { model = "models/iziraider/shields/4x4x3.mdl", yaw = 0, offset = Vector(0, 0, 30), scale = Vector(1.43, 0.48, 0.24), color = { 0.6, 0.8, 1 } }   -- fitted round every point of the hull (2026-11-07)
-- (2026-11-07 balance, the series' order: Ori > O'Neill > Aurora > Daedalus > Destiny > Prometheus > Al'kesh > Tel'tak)
-- the shield holds 30000 damage (a beam: 30 s)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 30000, 30

local HULL = 30000
local MAX_DRONES = 16
local VOLLEY = 4
local DRONE_RADIUS, DRONE_DAMAGE = 350, 360   -- a battleship's drones: a bigger blast than CAP's 200 / 150 (as the Aurora had before)

if SERVER then
	AddCSLuaFile()

	-- where the drones come out (model space: +X = bow, +Y = port; measured on agp_aurora.mdl): the launcher hatches in the lower armour belt on
	-- both sides and in the face of the sponson; one volley takes the next VOLLEY of them
	local LAUNCHERS = {}
	for _, x in ipairs({ 380, 300, 220, 140, 60, -20 }) do
		LAUNCHERS[#LAUNCHERS + 1] = { pos = Vector(x, 190, -20), dir = Vector(0.3, 1, 0) }
		LAUNCHERS[#LAUNCHERS + 1] = { pos = Vector(x, -180, -20), dir = Vector(0.3, -1, 0) }
	end
	-- the pulse turrets on the upper deck
	local TURRETS = {}
	for _, x in ipairs({ 399, 309, 3, -87 }) do
		TURRETS[#TURRETS + 1] = Vector(x, 71, 118)
		TURRETS[#TURRETS + 1] = Vector(x, -61, 118)
	end

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_aurora")
		e:SetPos(tr.HitPos + Vector(0, 0, 320))
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
		self.Vehicle = "Aurora"
		self.EntHealth, self.MaxHealth = HULL, HULL
		self.ExitPos = self:GetPos() + Vector(0, 0, 300)
		self.On, self.Roll = 0, 0
		self.HoverPos, self.NextLand = self:GetPos(), CurTime()   -- what the base's Initialize sets (the LAND key needs it)
		-- flight: a battleship - slow to speed up, slow to turn, no reverse thrust worth the name
		self.Accel = { FWD = 0, RIGHT = 0, UP = 0, SpeedForward = 6, SpeedRight = 3, SpeedUp = 3 }
		self.ForwardSpeed, self.BackwardSpeed = 1500, -300
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 2200, 400, 400
		self.RollSpeed = 2
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		self.ShouldRotorwash = false
		-- the CAP drones read these off their Parent
		self.Drones, self.DroneCount = {}, 0
		self.Track, self.Target = false, nil
		self.TrackTime = 1000000      -- they follow the aim until their fuel is gone
		self.DroneMaxSpeed = 6000
		self.NextLauncher = 1
		self.NextVolley = 0
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire Drones", "Target [VECTOR]", "Shield", "Hyperspace [VECTOR]") end
		if (self.CreateWireOutputs) then self:CreateWireOutputs("Health", "Drones In Flight", "Shield") end
		local phys = self:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:SetMass(50000)
			phys:EnableMotion(true)
			phys:Wake()
		end
		self:AGPSetWire("Health", HULL)
		-- the hull mends slowly while nothing hits it
		timer.Create("AGP.AuroraRepair" .. self:EntIndex(), 2, 0, function()
			if (not IsValid(self)) then return end
			if (CurTime() - (self.AGPLastHit or 0) > 10 and self.EntHealth < HULL) then
				self.EntHealth = math.min(HULL, self.EntHealth + 50)
				self:AGPSetWire("Health", math.floor(self.EntHealth))
			end
		end)
	end

	function ENT:AGPSetWire(name, v)
		if (self.SetWire) then self:SetWire(name, v) end
	end

	function ENT:OnTakeDamage(dmg)
		self.AGPLastHit = CurTime()
		self:AGPHullDamage(dmg)
		self:AGPSetWire("Health", math.max(0, math.floor(self.EntHealth or 0)))
	end

	function ENT:OnRemove()
		timer.Remove("AGP.AuroraRepair" .. self:EntIndex())
		if (AGP and AGP.ShipShieldRemove) then AGP.ShipShieldRemove(self) end
		self.BaseClass.OnRemove(self)
	end

	function ENT:ToggleShield()
		if (AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self) end
	end

	function ENT:TriggerInput(k, v)
		if (k == "Fire Drones" and v ~= 0) then self:LaunchVolley()
		elseif (k == "Target") then self.WireTarget = (isvector(v) and v ~= vector_origin) and v or nil
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	-- one drone out of launcher i: it leaves the hatch sideways and turns towards the target on its own
	function ENT:LaunchDrone(i)
		local l = LAUNCHERS[i]
		local e = ents.Create("drone")
		if (not IsValid(e)) then return end
		local dir = self:LocalToWorld(l.dir) - self:GetPos()
		e.Parent = self
		e:SetPos(self:LocalToWorld(l.pos) + dir:GetNormalized() * 30)
		e:SetAngles(dir:Angle())
		e:SetOwner(self)
		e.Owner = self:GetVar("Owner", self)
		e:Spawn()
		e.Radius, e.Damage = DRONE_RADIUS, DRONE_DAMAGE   -- after Spawn: the drone's Initialize sets CAP's values
		e.AGPSweep = true   -- (2026-11-08) it hits whatever lies on its path (fast, it flew through hulls)
		e:SetVelocity(self:GetVelocity() + dir:GetNormalized() * 600)
		self.Drones[e] = true
		self.DroneCount = self.DroneCount + 1
	end

	function ENT:LaunchVolley()
		if (CurTime() < self.NextVolley) then return end
		self.NextVolley = CurTime() + 1.2
		for k = 0, VOLLEY - 1 do
			timer.Simple(k * 0.12, function()
				if (not IsValid(self) or self.DroneCount >= MAX_DRONES) then return end
				self:LaunchDrone(self.NextLauncher)
				self.NextLauncher = self.NextLauncher % #LAUNCHERS + 1
			end)
		end
		self:EmitSound("weapons/drone_shot.mp3", 100, math.random(90, 105))
	end

	-- the pulse turrets: a volley at the crosshair from the turrets on the deck (golden bolts)
	function ENT:TurretVolley()
		if (not IsValid(self.Pilot)) then return end
		local aim = AGP.ShipCrosshair(self)   -- AGP 2026-11-08: from the pilot's camera (lua/autorun/agp_ship_aim.lua)
		if (not aim) then return end
		for i, p in ipairs(TURRETS) do
			timer.Simple(i * 0.09, function()
				if (not IsValid(self)) then return end
				local from = self:LocalToWorld(p)
				local dir = (aim - from):GetNormalized()
				if (dir:Dot(self:GetForward()) < -0.2) then return end   -- not back through the hull
				local e = ents.Create("energy_pulse")
				if (not IsValid(e)) then return end
				e:PrepareBullet((dir + VectorRand() * 0.01):GetNormalized(), 10, 16000, 9, { self })
				e:SetPos(from + dir * 30)
				e:SetOwner(self)
				e.Owner = self
				e:Spawn()
				e:Activate()
				e:SetColor(Color(255, 200, 110))
				self:EmitSound("pulse_weapon/staff_weapon.mp3", 95, math.random(105, 120))
			end)
		end
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() + self:GetUp() * 200
		-- where the drones go: the crosshair while someone flies (AGP 2026-11-08: no Mouse2 needed any more; they flew
		-- out sideways and on without it), else a wired target, else straight on
		local aim = self.Inflight and AGP and AGP.ShipCrosshair and AGP.ShipCrosshair(self)
		self.Target = aim or self.WireTarget
		self.Track = self.Target ~= nil
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			if (p:KeyDown(self.Vehicle, "FIRE")) then self:LaunchVolley() end
			if (AGP and AGP.KeyPress and AGP.KeyPress(self, p, self.Vehicle, "TRACK") and CurTime() > (self.NextTurrets or 0)) then
				self.NextTurrets = CurTime() + 4
				self:TurretVolley()
			end
		end
		self:AGPSetWire("Drones In Flight", self.DroneCount)
		self:AGPSetWire("Shield", self.AGPShielded and 1 or 0)
		self:NextThink(CurTime() + 0.1)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_aurora", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys, the same layout as the other big ships
	local KBD = StarGate.KeyBoard:New("Aurora")
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

	ENT.Sounds = { Engine = Sound("ambient/levels/citadel/citadel_hub_ambience1.mp3") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "Aurora"
		self.Dist, self.UDist = -900, 260
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	-- the seven round engines in the stern face (measured on agp_aurora.mdl: its tail sits at y +19), a blue plume
	-- behind each while it flies forward (seen by everyone)
	local ENGINES = { { Vector(-941, -51, 10), 24 }, { Vector(-941, 89, 10), 24 }, { Vector(-941, 19, 26), 16 },
		{ Vector(-941, -106, -20), 16 }, { Vector(-941, 144, -20), 16 }, { Vector(-941, -21, -36), 13 }, { Vector(-941, 59, -36), 13 } }
	ENT.RenderGroup = RENDERGROUP_BOTH
	function ENT:DrawTranslucent()
		self:AGPEngineNozzles(ENGINES, { 90, 160, 255 }, 220)
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		-- camera distance / height on the arrow keys, bridge view on 1
		if (p:KeyDown("Aurora", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("Aurora", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("Aurora", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("Aurora", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("Aurora", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
