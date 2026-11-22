--[[
	Wraith cruiser (the Wraith escort ship of Stargate Atlantis) - Ascension Gates' own code and model, designed
	after the series. EAP's model and code are gone; the class name
	stays "sg_vehicle_wraithcruiser", so saves and dupes keep working (the old Wire names "Health" and "Hyperspace" stay,
	the keyboard layout is still "WraithCruiser"). Built on:
	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's energy_pulse (aVoN, Madman07) for the shots, in the Wraith's pale blue (energy_pulse_wraith)
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua, agp_ship_aim.lua): hull damage,
	    aiming, the Mouse2 volley, hyperdrive, the Supergate / Stargate dial menu
	As in the series: a grown ship that flies spear point first, two plasma cannons under the bow, hyperdrive - and no
	shield: its hull grows back (slowly while it is being hit, faster once it has been left alone). Keys: Mouse1 the
	two cannons at the crosshair (a pair a second), Mouse2 a volley at the crosshair, H hyperdrive (hold), R dial
	menu, 1 view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "Wraith Cruiser"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_wraithcruiser") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_capital_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 25000       -- hyperdrive (H): longest jump
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own model, designed after the series; +X = the spear point (the bow)
local MODEL = "models/agp/wraithcruiser/agp_wraithcruiser.mdl"
function ENT:AGPModel() return MODEL end

-- no shield (Wraith ships have none in the series); blasts still count by the distance to the hull, as on the other
-- big ships (lua/autorun/agp_ship_shield.lua)
ENT.AGPSharedHull = true

-- (balance) the hull alone holds what hull and shield held before (18000 + the default shield 14400 = 32400):
-- between the Al'kesh and the Prometheus, as before
local HULL = 32000
-- the regrowth: a share of the hull per second - 0.5 % (160) while it is being hit (the old shield recharged 360 a
-- second while it held), 1.5 % (480) once REGROW_WAIT s have passed since the last hit (from empty to whole in about a
-- minute); never after it was destroyed
local REGROW_FIGHT, REGROW_CALM, REGROW_WAIT = 0.005, 0.015, 6
-- model space: the two plasma cannons, under the bow's neck (left, right)
local CANNONS = { Vector(300, 62, -56), Vector(300, -62, -56) }
local SHOT_EVERY = 1       -- s between two pairs
local SHOT = "weapons/wraith_dart_shoot.mp3"

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_wraithcruiser")
		e:SetPos(tr.HitPos + Vector(0, 0, 300))
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
		self.Vehicle = "WraithCruiser"
		self.EntHealth, self.MaxHealth = HULL, HULL
		self:SetNWInt("health", HULL)
		self:SetNWInt("maxEntHealth", HULL)
		self:SetNWInt("CanFire", 1)
		self.ExitPos = self:GetPos() - self:GetUp() * 200
		self.On, self.Roll = 0, 0
		self.HoverPos, self.NextLand = self:GetPos(), CurTime()   -- what the base's Initialize sets (the LAND key needs it)
		-- flight: as before
		self.Accel = { FWD = 0, RIGHT = 0, UP = 0, SpeedForward = 10, SpeedRight = 7, SpeedUp = 7 }
		self.ForwardSpeed, self.BackwardSpeed = 1500, -750
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 2000, 750, 600
		self.RollSpeed = 5
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		-- the old Wire names stay (dupes keep their wiring); fire and target inputs are new, "Regrowing" is 1 while it heals
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Target [VECTOR]", "Hyperspace [VECTOR]") end
		if (self.CreateWireOutputs) then self:CreateWireOutputs("Health", "Can Shoot", "Regrowing") end
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
		self.BaseClass.OnRemove(self)
	end

	-- the hull grows back (every Think, 0.1 s): a drop since the last look is a hit (every way damage comes in counts)
	function ENT:AGPRegrow()
		local now = CurTime()
		local hp = self.EntHealth or 0
		if (hp < (self.AGPLastHP or hp)) then
			self.AGPLastHit = now
			self:SetNWFloat("AGPRegrowHit", now)
		end
		local dt = math.Clamp(now - (self.AGPRegrowAt or now), 0, 0.5)
		self.AGPRegrowAt = now
		local growing = not (self.AGPDestroyed or self.Done) and hp > 0 and hp < HULL
		if (growing) then
			local calm = now - (self.AGPLastHit or -99) >= REGROW_WAIT
			hp = math.min(HULL, hp + HULL * (calm and REGROW_CALM or REGROW_FIGHT) * dt)
			self.EntHealth = hp
			self:SetNWInt("health", math.max(0, math.ceil(hp)))
			self:AGPSetWire("Health", math.floor(hp))
		end
		self.AGPLastHP = hp
		self:AGPSetWire("Regrowing", growing and 1 or 0)
	end

	function ENT:TriggerInput(k, v)
		if (k == "Fire") then self.WireFire = (v ~= 0)
		elseif (k == "Target") then self.WireTarget = (isvector(v) and v ~= Vector(0, 0, 0)) and Vector(v) or nil
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	-- the two plasma cannons: one bolt each at the target (a world point), then SHOT_EVERY s until the next pair
	function ENT:FireBlast(target)
		if (CurTime() < (self.AGPNextShot or 0)) then return end
		self.AGPNextShot = CurTime() + SHOT_EVERY
		local fwd = self:GetForward()
		for _, at in ipairs(CANNONS) do
			local from = self:LocalToWorld(at)
			-- the cannons are fixed in the bow: within 10 degrees of the nose (the shared front limit, AGP.ShipAimClamp)
			local dir = AGP.ShipAimClamp(self, isvector(target) and (target - from) or fwd, 10)
			local e = ents.Create("energy_pulse_wraith")
			if (IsValid(e)) then
				e:PrepareBullet(dir, 10, 16000, 6, { self })
				e:SetPos(from)
				e:SetOwner(self)
				e.Owner = self
				e:Spawn()
				e:Activate()
			end
		end
		self.AGPShotsFired = (self.AGPShotsFired or 0) + #CANNONS
		self:EmitSound(SHOT, 90, math.random(90, 110))
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self:AGPRegrow()
		self.ExitPos = self:GetPos() - self:GetUp() * 200
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			-- Mouse2: a volley of bolts from the bow at the crosshair
			if (AGP and AGP.ShipVolley) then
				local before = self.AGPNextVolley
				AGP.ShipVolley(self, { class = "energy_pulse_wraith", count = 8, size = 6, cool = 8, front = 0.35, wide = 0.3, sound = SHOT })
				if (self.AGPNextVolley ~= before) then self.AGPShotsFired = (self.AGPShotsFired or 0) + 8 end
			end
			-- Mouse1: the cannons at the crosshair (from the pilot's camera, lua/autorun/agp_ship_aim.lua)
			if (p:KeyDown(self.Vehicle, "FIRE")) then
				self:FireBlast(AGP and AGP.ShipCrosshair and AGP.ShipCrosshair(self) or (self:GetPos() + self:GetForward() * 30000))
			end
		end
		if (self.WireFire) then self:FireBlast(self.WireTarget or (self:GetPos() + self:GetForward() * 30000)) end
		local left = math.max(0, (self.AGPNextShot or 0) - CurTime())
		self:SetNWInt("WeaponsTimer", math.ceil(left))
		self:SetNWInt("CanFire", left > 0 and 0 or 1)
		self:AGPSetWire("Can Shoot", left > 0 and 0 or 1)
		self:NextThink(CurTime() + 0.1)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_wraithcruiser", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys (the same layout name as before, so players keep their bindings)
	local KBD = StarGate.KeyBoard:New("WraithCruiser")
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
	ENT.Sounds = { Engine = Sound("eap/ship/moteur/wraithcruiser.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "WraithCruiser"
		self.Dist, self.UDist = -750, 120
		self.FirstPerson = false
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	-- no engine glow: the series' cruiser shows none that fits (no engine lights)
	function ENT:Think()
		self.BaseClass.Think(self)
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		-- camera distance / height on the arrow keys, the other view on 1
		if (p:KeyDown("WraithCruiser", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("WraithCruiser", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("WraithCruiser", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("WraithCruiser", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("WraithCruiser", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
