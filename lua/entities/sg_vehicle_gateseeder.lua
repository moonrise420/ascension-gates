--[[
	Gate Seeder (the Ancients' seed ship of Stargate Universe) - Ascension Gates' own code and model (2026-11-09),
	designed after the series (notes/models/agp_seeder_ship_*.py); it wears our Destiny's materials.
	EAP's model and code are gone; the class name stays "sg_vehicle_gateseeder", so saves and dupes keep working (the old
	Wire names "Health" and "Hyperspace" stay, the keyboard layout is still "Gateseeder"). Built on:
	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's energy_pulse (aVoN, Madman07) for the shots, in Destiny's orange (energy_pulse_destiny)
	  * CAP's Universe Stargate (stargate_universe) for the gates it builds
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua, agp_ship_aim.lua): shield, hull
	    damage, aiming, the Mouse2 volley, hyperdrive, the Supergate / Stargate dial menu
	As in the series: seed ships build Stargates in a gate factory on board and set them down on planets ahead of
	Destiny (owner 2026-11-09: "can it get that function?", then "could you do the gate seeding like in the series?"):
	the factory builds one Universe gate every GATE_BUILD s and keeps up to GATE_STORE on board; B (or Wire "Seed Gate")
	while the ship hovers still over the ground brings one out of the belly into the cradle and an energy field lowers
	it to the ground. The gate belongs to the pilot like a spawned one (undo, cleanup, the server's spawn rules and
	limits) and gets a free address.
	Keys: Mouse1 the two turrets at the crosshair, Mouse2 a point-defence burst, B build a Stargate below, G shield,
	H hyperdrive (hold), R dial menu, 1 view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "Gate Seeder"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_gateseeder") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_capital_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 30000       -- hyperdrive (H): longest jump
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own model, designed after the series (notes/models/agp_seeder_ship_models.py); +X = the bow, the fan at the stern
local MODEL = "models/agp/gateseeder/agp_gateseeder.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble round every point of the hull (fitted on the model 2026-11-09: centre (-160, 0, 40), radii
-- 666 x 652 x 106 with a margin), Ancient white
ENT.AGPShield = { model = "models/iziraider/shields/4x4x3.mdl", yaw = 0, offset = Vector(-160, 0, 40), scale = Vector(0.666, 0.653, 0.141), color = { 1, 0.98, 0.94 } }
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 15000, 15

local HULL = 23000
-- model space: the two turrets' muzzles on the fan beside the spine, the engine band along the fan's curved rear edge
local TURRETS = { Vector(-376, 205, 81), Vector(-376, -205, 81) }
local DRIVE = { Vector(-515, -474, 48), Vector(-526, -422, 50), Vector(-539, -369, 51), Vector(-551, -316, 52), Vector(-557, -264, 53),
	Vector(-564, -211, 45), Vector(-569, -158, 35), Vector(-572, -105, 34), Vector(-576, -53, 35), Vector(-579, 0, 35), Vector(-576, 53, 35),
	Vector(-572, 105, 34), Vector(-569, 158, 35), Vector(-564, 211, 45), Vector(-557, 264, 53), Vector(-551, 316, 52), Vector(-539, 369, 51),
	Vector(-526, 422, 50), Vector(-515, 474, 48) }
local SHOT_EVERY = 1
local SHOT = "weapons/dest_main_cannon.wav"
-- the gate factory on board: seconds per gate, how many it keeps, how many a new ship carries; setting one down: the
-- time it takes out of the belly into the cradle, the time it is lowered; how high above the ground the belly may be
-- (game units; players see their own unit, AGP.Units.Distance), how still the ship must be
local GATE_BUILD, GATE_STORE, GATE_START = 120, 3, 1
local SEED_OUT, SEED_LOWER = 3, 4
local SEED_MIN, SEED_MAX, SEED_SPEED, SEED_DRIFT = 420, 3000, 150, 300
ENT.AGPSeedRange = { SEED_MIN, SEED_MAX }   -- (read by the HUD)
ENT.AGPGateStore = GATE_STORE
local BELLY = Vector(-100, 0, -60)    -- model space: the belly the height is measured from (under the spine's root)
local CRADLE = Vector(-100, 0, -70)   -- model space: the middle of a gate lying flat in the cradle's claws
local HOLD = Vector(-100, 0, 40)      -- model space: where the factory hands a finished gate down (inside the spine)
local GATE_UP = 90                    -- CAP's Universe gate stands with its middle this high over the ground
local GATE_MDL = "models/The_Sniper_9/Universe/Stargate/universegate.mdl"

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_gateseeder")
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
		self.Vehicle = "Gateseeder"
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
		self.AGPGatesSeeded = 0
		self:AGPSetStore(GATE_START)
		-- the old Wire names stay (dupes keep their wiring); the rest is new
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Target [VECTOR]", "Shield", "Hyperspace [VECTOR]", "Seed Gate") end
		if (self.CreateWireOutputs) then self:CreateWireOutputs("Health", "Can Shoot", "Shield Strength", "Shield Enabled", "Seeding", "Gates Seeded", "Gates On Board") end
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

	-- the gates on board; the factory builds the next while there is room (AGPGateBuildAt: when it is done, 0 = full)
	function ENT:AGPSetStore(n)
		self.AGPGatesStored = math.Clamp(n, 0, GATE_STORE)
		self:SetNWInt("AGPGatesStored", self.AGPGatesStored)
		if (self.AGPGatesStored >= GATE_STORE) then
			self.AGPGateBuildAt = 0
		elseif ((self.AGPGateBuildAt or 0) <= 0) then
			self.AGPGateBuildAt = CurTime() + GATE_BUILD
		end
		self:SetNWFloat("AGPGateBuildAt", self.AGPGateBuildAt)
		self:AGPSetWire("Gates On Board", self.AGPGatesStored)
	end

	function ENT:AGPFactoryThink()
		if (self.AGPDestroyed or (self.AGPGatesStored or 0) >= GATE_STORE) then return end
		if ((self.AGPGateBuildAt or 0) > 0 and CurTime() >= self.AGPGateBuildAt) then
			self.AGPGateBuildAt = 0
			self:AGPSetStore((self.AGPGatesStored or 0) + 1)
		end
	end

	-- a short message on the pilot's screen (translated on their side; the fallback is English); kind 0 hint, 1 error,
	-- 2 done
	-- (dists: distances in game units for the text's %s, each shown in the player's own unit)
	util.AddNetworkString("AGP_SeedNotify")
	local function notify(ply, key, fallback, kind, dists)
		if (not IsValid(ply) or not ply:IsPlayer()) then return end
		net.Start("AGP_SeedNotify")
		net.WriteString(key); net.WriteString(fallback); net.WriteUInt(kind or 0, 2)
		dists = dists or {}
		net.WriteUInt(#dists, 3)
		for _, d in ipairs(dists) do net.WriteFloat(d) end
		net.Send(ply)
	end
	local HINT, ERR, DONE = 0, 1, 2

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
		elseif (k == "Target") then self.WireTarget = (isvector(v) and v ~= Vector(0, 0, 0)) and Vector(v) or nil
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (k == "Seed Gate") then if (v ~= 0) then self:AGPSeedStart(self.Pilot) end
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	-- the two turrets: one bolt each at the target (a world point), then SHOT_EVERY s until the next pair
	function ENT:FireBlast(target)
		if (CurTime() < (self.AGPNextShot or 0)) then return end
		self.AGPNextShot = CurTime() + SHOT_EVERY
		local fwd = self:GetForward()
		for _, at in ipairs(TURRETS) do
			local from = self:LocalToWorld(at)
			-- turrets: anywhere in front of the ship, never backwards (the shared front limit, AGP.ShipAimClamp)
			local dir = AGP.ShipAimClamp(self, isvector(target) and (target - from) or fwd)
			local e = ents.Create("energy_pulse_destiny")
			if (IsValid(e)) then
				e:PrepareBullet(dir, 10, 14000, 6, { self })
				e:SetPos(from)
				e:SetOwner(self)
				e.Owner = self
				e:Spawn()
				e:Activate()
			end
		end
		self.AGPShotsFired = (self.AGPShotsFired or 0) + #TURRETS
		self:EmitSound(SHOT, 90, math.random(90, 110))
	end

	--########## Building a Stargate (the seed ship's purpose in the series)
	-- the ground under the belly: the trace, or nil and why not
	function ENT:AGPSeedGround()
		local from = self:LocalToWorld(BELLY)
		-- all the way down (2026-11-09 test: a trace only SEED_MAX deep said "no ground" to a ship hovering too high)
		-- (2026-11-10) props and ships are seen too: a gate is set on the ground only, not into a prop or a parked ship
		-- below, and not onto anyone standing there. Under water is fine (owner): on the bottom, as on dry ground.
		local filter = { self }
		for _, c in ipairs(self:GetChildren()) do filter[#filter + 1] = c end
		local tr = util.TraceLine({ start = from, endpos = from - Vector(0, 0, 32768), mask = MASK_SOLID, filter = filter })
		if (not tr.Hit or tr.HitSky) then return nil, "noground" end
		if (not tr.HitWorld) then return nil, "blocked" end
		if (tr.HitNormal.z < 0.75) then return nil, "steep" end
		local h = from.z - tr.HitPos.z
		if (h < SEED_MIN or h > SEED_MAX) then return nil, "height" end
		for _, e in ipairs(ents.FindInSphere(tr.HitPos + Vector(0, 0, 130), 150)) do
			if ((e:IsPlayer() and e:Alive()) or e:IsNPC()) then return nil, "occupied" end
		end
		return tr
	end

	local WHY = {
		busy = { "agp_seed_busy", "A Stargate is already being set down" },
		empty = { "agp_seed_empty", "No Stargate on board yet - the factory is still building one" },
		noground = { "agp_seed_noground", "No ground below to set a Stargate down on" },
		steep = { "agp_seed_steep", "The ground below is too steep for a Stargate" },
		blocked = { "agp_seed_blocked", "Something is in the way below - a Stargate is set down on the ground only" },
		occupied = { "agp_seed_occupied", "Someone is standing where the Stargate would go" },
		height = { "agp_seed_height", "Hover %s to %s above the ground to set a Stargate down", { SEED_MIN, SEED_MAX } },
		moving = { "agp_seed_moving", "Hold the ship still to build a Stargate" },
	}

	-- B / Wire: take a gate out of the factory and set it down; false and the reason when it cannot
	function ENT:AGPSeedStart(ply)
		local why
		if (self.AGPSeeding) then why = "busy"
		elseif ((self.AGPGatesStored or 0) < 1) then why = "empty"
		elseif (self:GetVelocity():Length() > SEED_SPEED) then why = "moving" end
		local tr
		if (not why) then tr, why = self:AGPSeedGround() end
		if (why) then
			notify(ply, WHY[why][1], WHY[why][2], ERR, WHY[why][3])
			return false, why
		end
		self:AGPSetStore(self.AGPGatesStored - 1)          -- out of the factory (it starts on the next one)
		self.AGPSeeding = { done = CurTime() + SEED_OUT, from = self:GetPos(), ply = IsValid(ply) and ply or nil }
		self:SetNWFloat("AGPSeedAt", self.AGPSeeding.done)
		self:SetNWVector("AGPSeedPos", tr.HitPos)
		self:AGPSetWire("Seeding", 1)
		self:EmitSound("stargate/universe/chevron2.mp3", 90, 80)
		notify(ply, "agp_seed_started", "Setting a Stargate down - hold the ship still", HINT)
		return true
	end

	-- stopped before the gate stands (moved away, no ground, not allowed): it goes back into the factory
	function ENT:AGPSeedStop(key, fallback, placed)
		local s = self.AGPSeeding
		self.AGPSeeding = nil
		if (s and not placed) then self:AGPSetStore((self.AGPGatesStored or 0) + 1) end
		self:SetNWFloat("AGPSeedAt", 0)
		self:SetNWFloat("AGPSeedLower", 0)
		self:AGPSetWire("Seeding", 0)
		if (s and key) then notify(s.ply or self.Pilot, key, fallback, ERR) end
	end

	-- the finished gate set down below, owned by the pilot who started it (or the ship's owner), like a spawned gate
	function ENT:AGPSeedPlace()
		local s = self.AGPSeeding
		local ply = (s and IsValid(s.ply)) and s.ply or self.Pilot
		if (not IsValid(ply)) then ply = self:GetVar("Owner") end
		local tr, yaw = s and s.tr, s and s.yaw   -- the spot fixed when the lowering began
		if (not tr or not IsValid(ply) or not ply:IsPlayer()) then self:AGPSeedStop() return nil end
		local cls = "stargate_universe"
		if ((StarGate and StarGate.NotSpawnable and StarGate.NotSpawnable(cls, ply)) or gamemode.Call("PlayerSpawnSENT", ply, cls) == false) then
			self:AGPSeedStop()
			notify(ply, "agp_seed_denied", "You may not place a Stargate (server rules or limit)", ERR)
			return nil
		end
		local sent = scripted_ents.Get(cls)
		local e = (sent and sent.SpawnFunction) and sent:SpawnFunction(ply, tr, cls) or nil
		if (not IsValid(e)) then self:AGPSeedStop() return nil end
		self:AGPSeedStop(nil, nil, true)
		e:SetPos(tr.HitPos + Vector(0, 0, GATE_UP))
		e:SetAngles(Angle(0, yaw or self:GetAngles().y, 0))   -- as the lowered gate stood: facing the way the ship flew
		gamemode.Call("PlayerSpawnedSENT", ply, e)        -- a random address and name when the server gives them
		if ((e.GetGateAddress and e:GetGateAddress() or "") == "" and StarGate and StarGate.RandomGateName) then
			StarGate.RandomGateName(ply, e, nil, true, 0)   -- otherwise one here: a seeded gate is ready to dial
		end
		undo.Create("SENT")
		undo.SetPlayer(ply)
		undo.AddEntity(e)
		undo.SetCustomUndoText("Undone Stargate (seed ship)")
		undo.Finish("Scripted Entity (" .. cls .. ")")
		ply:AddCleanup("sents", e)
		e:SetVar("Player", ply)
		local fx = EffectData()
		fx:SetOrigin(e:GetPos()); fx:SetScale(2); fx:SetMagnitude(2)
		util.Effect("cball_explode", fx, true, true)
		e:EmitSound("stargate/universe/chevron2.mp3", 90, 100)
		self.AGPGatesSeeded = (self.AGPGatesSeeded or 0) + 1
		self:AGPSetWire("Gates Seeded", self.AGPGatesSeeded)
		notify(ply, "agp_seed_done", "Stargate set down", DONE)
		return e
	end

	function ENT:AGPSeedThink()
		local s = self.AGPSeeding
		if (not s) then return end
		if (self.AGPDestroyed or (self.EntHealth or 1) <= 0) then return self:AGPSeedStop() end
		if (self:GetPos():Distance(s.from) > SEED_DRIFT or self:GetVelocity():Length() > SEED_SPEED * 2) then
			return self:AGPSeedStop("agp_seed_moved", "Stopped: the ship moved away - the gate went back on board")
		end
		if (not s.lower and CurTime() >= s.done) then
			-- out of the belly and in the cradle: now the energy field lowers it to the ground (the spot is fixed now)
			local tr, why = self:AGPSeedGround()
			if (not tr) then
				self:AGPSeedStop()
				return notify(s.ply or self.Pilot, WHY[why][1], WHY[why][2], ERR, WHY[why][3])
			end
			s.tr, s.yaw, s.lower = tr, self:GetAngles().y, CurTime() + SEED_LOWER
			self:SetNWVector("AGPSeedPos", tr.HitPos)
			self:SetNWFloat("AGPSeedYaw", s.yaw)
			self:SetNWFloat("AGPSeedLower", s.lower)
			self:EmitSound("stargate/universe/chevron2.mp3", 90, 70)
		elseif (s.lower and CurTime() >= s.lower) then
			self:AGPSeedPlace()
		end
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() - self:GetUp() * 200
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			-- Mouse2: a burst of bolts at the crosshair
			if (AGP and AGP.ShipVolley) then
				local before = self.AGPNextVolley
				AGP.ShipVolley(self, { class = "energy_pulse_destiny", count = 6, size = 6, cool = 7, front = 0.1, wide = 0.35, sound = SHOT })
				if (self.AGPNextVolley ~= before) then self.AGPShotsFired = (self.AGPShotsFired or 0) + 6 end
			end
			-- Mouse1: the turrets at the crosshair (from the pilot's camera, lua/autorun/agp_ship_aim.lua)
			if (p:KeyDown(self.Vehicle, "FIRE")) then
				self:FireBlast(AGP and AGP.ShipCrosshair and AGP.ShipCrosshair(self) or (self:GetPos() + self:GetForward() * 30000))
			end
			-- B: build a Stargate below
			if (AGP and AGP.KeyPress and AGP.KeyPress(self, p, self.Vehicle, "SEED")) then self:AGPSeedStart(p) end
		end
		self:AGPSeedThink()
		self:AGPFactoryThink()
		if (self.WireFire) then self:FireBlast(self.WireTarget or (self:GetPos() + self:GetForward() * 30000)) end
		local left = math.max(0, (self.AGPNextShot or 0) - CurTime())
		self:SetNWInt("WeaponsTimer", math.ceil(left))
		self:SetNWInt("CanFire", left > 0 and 0 or 1)
		self:AGPSetWire("Can Shoot", left > 0 and 0 or 1)
		self:AGPSetWire("Shield Enabled", self.AGPShielded and 1 or 0)
		local gen = AGP and AGP.ShipShieldGen and AGP.ShipShieldGen(self)
		self:AGPSetWire("Shield Strength", IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 0)
		self:NextThink(CurTime() + 0.1)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_gateseeder", StarGate.CAP_GmodDuplicator, "Data")
	end
	-- (2026-11-10) dupes and saves keep the factory: gates on board, gates seeded, the build time left
	function ENT:PreEntityCopy()
		duplicator.StoreEntityModifier(self, "AGPSeederState", { stored = self.AGPGatesStored or 0, seeded = self.AGPGatesSeeded or 0,
			left = ((self.AGPGateBuildAt or 0) > 0) and math.max(0, self.AGPGateBuildAt - CurTime()) or 0 })
		if (self.BaseClass and self.BaseClass.PreEntityCopy) then self.BaseClass.PreEntityCopy(self) end
	end
	duplicator.RegisterEntityModifier("AGPSeederState", function(ply, e, d)
		if (not IsValid(e) or e:GetClass() ~= "sg_vehicle_gateseeder" or not istable(d)) then return end
		e.AGPGatesSeeded = math.max(0, math.floor(tonumber(d.seeded) or 0))
		if (e.AGPSetWire) then e:AGPSetWire("Gates Seeded", e.AGPGatesSeeded) end
		e.AGPGateBuildAt = ((tonumber(d.left) or 0) > 0) and (CurTime() + d.left) or 0
		if (e.AGPSetStore) then e:AGPSetStore(math.floor(tonumber(d.stored) or 0)) end
	end)
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys (the same layout name as before, so players keep their bindings); B is new
	local KBD = StarGate.KeyBoard:New("Gateseeder")
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
	KBD:SetDefaultKey("SEED", "B")
	KBD:SetDefaultKey("LAND", "ENTER")
	KBD:SetDefaultKey("BOOM", "BACKSPACE")
	KBD:SetDefaultKey("VIEW", "1")
	KBD:SetDefaultKey("Z+", "UPARROW")
	KBD:SetDefaultKey("Z-", "DOWNARROW")
	KBD:SetDefaultKey("A+", "LEFTARROW")
	KBD:SetDefaultKey("A-", "RIGHTARROW")
	KBD:SetDefaultKey("EXIT", B["+use"] or "E")

	ENT.RenderGroup = RENDERGROUP_BOTH
	ENT.Sounds = { Engine = Sound("eap/ship/moteur/destiny.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "Gateseeder"
		self.Dist, self.UDist = -750, 120
		self.FirstPerson = false
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	-- a distance in the player's chosen unit (PowerGrid's setting "agp_unit_distance": m, ft or game units)
	local function dist(u)
		if (AGP and AGP.Units and AGP.Units.Distance) then return AGP.Units.Distance(u) end
		return math.Round(u * 0.0254) .. " m"
	end
	net.Receive("AGP_SeedNotify", function()
		local k, f, kind = net.ReadString(), net.ReadString(), net.ReadUInt(2)
		local n, d = net.ReadUInt(3), {}
		for i = 1, n do d[i] = dist(net.ReadFloat()) end
		-- (GetMessage fills the %s in itself and fails without them, so the distances go with it)
		local m
		if (SGLanguage and SGLanguage.ValidMessage and SGLanguage.ValidMessage(k)) then
			local fine, txt = pcall(SGLanguage.GetMessage, k, unpack(d))
			if (fine) then m = txt end
		end
		if (not m) then
			local fine, txt = pcall(string.format, f, unpack(d))
			m = fine and txt or f
		end
		notification.AddLegacy(m, kind == 1 and NOTIFY_ERROR or (kind == 2 and NOTIFY_GENERIC or NOTIFY_HINT), 4)
		surface.PlaySound(kind == 1 and "buttons/button10.wav" or "buttons/button14.wav")
	end)

	local BEAM = Material("sprites/physbeam")
	local GLOW = Material("sprites/light_glow02_add")
	local FIELD = Color(150, 195, 255)
	local SHELL = Material("effects/com_shield002a")   -- the energy pattern (as on the Ha'tak's shield bubble)

	function ENT:AGPGhost()
		if (not IsValid(self.AGPGhostMdl)) then
			self.AGPGhostMdl = ClientsideModel(GATE_MDL, RENDERGROUP_TRANSLUCENT)
			if (IsValid(self.AGPGhostMdl)) then self.AGPGhostMdl:SetNoDraw(true) end
		end
		return self.AGPGhostMdl
	end

	function ENT:OnRemove()
		if (IsValid(self.AGPGhostMdl)) then self.AGPGhostMdl:Remove() end
		if (self.BaseClass.OnRemove) then self.BaseClass.OnRemove(self) end
	end

	-- the engine band along the fan's rear edge glows blue in flight (seen by everyone, as on Destiny).
	-- Setting a gate down (as in the series the gates are built in the factory on board): a finished gate comes down out
	-- of the belly, lying flat, into the cradle's claws; then it leaves the cradle inside a glowing field, sinks to the
	-- ground and turns upright on the way, where the real gate then stands.
	function ENT:DrawTranslucent()
		self:AGPEngineLine(DRIVE, { 170, 205, 255 }, 22)
		local now = CurTime()
		local at, low = self:GetNWFloat("AGPSeedAt", 0), self:GetNWFloat("AGPSeedLower", 0)
		if (at <= now and low <= now) then return end
		local g = self:AGPGhost()
		if (not IsValid(g)) then return end
		local cradle = self:LocalToWorld(CRADLE)
		local flat = self:LocalToWorldAngles(Angle(89, 0, 0))   -- the ring lying flat (the model's ring faces +X)
		if (low > now) then
			local t = math.Clamp(1 - (low - now) / SEED_LOWER, 0, 1)
			t = t * t * (3 - 2 * t)
			local pos = LerpVector(t, cradle, self:GetNWVector("AGPSeedPos", cradle) + Vector(0, 0, GATE_UP))
			local ang = LerpAngle(t, flat, Angle(0, self:GetNWFloat("AGPSeedYaw", 0), 0))
			local pulse = math.sin(now * 6)
			-- the shaft of light the field hangs from: a soft column of glow round a bright core
			render.SetMaterial(GLOW)
			local len = cradle:Distance(pos)
			local steps = math.Clamp(math.ceil(len / 30), 1, 100)   -- close together: one even column, not a row of beads
			for k = 0, steps do
				render.DrawSprite(LerpVector(k / steps, cradle, pos), 200, 200, Color(FIELD.r, FIELD.g, FIELD.b, 10))
			end
			render.SetMaterial(BEAM)
			render.DrawBeam(cradle, pos, 70, 0, 1, Color(FIELD.r, FIELD.g, FIELD.b, 140))
			g:SetPos(pos); g:SetAngles(ang); g:SetupBones()
			render.SetColorModulation(0.8, 0.9, 1)
			g:DrawModel()
			render.SetColorModulation(1, 1, 1)
			-- the field: a flat shell round the ring (the ring faces the gate's +X), turning with it
			local m = Matrix()
			m:Translate(pos)
			m:Rotate(ang)
			m:Scale(Vector(70, 190, 190))
			cam.PushModelMatrix(m)
			render.SetColorMaterial()
			render.DrawSphere(Vector(0, 0, 0), 1, 32, 16, Color(FIELD.r, FIELD.g, FIELD.b, 28 + 8 * pulse))
			render.SetMaterial(SHELL)
			render.DrawSphere(Vector(0, 0, 0), 1, 32, 16, Color(FIELD.r, FIELD.g, FIELD.b, 150 + 50 * pulse))
			cam.PopModelMatrix()
			render.SetMaterial(GLOW)
			render.DrawSprite(pos, 520, 520, Color(FIELD.r, FIELD.g, FIELD.b, 55 + 20 * pulse))
		else
			local f = math.Clamp(1 - (at - now) / SEED_OUT, 0, 1)
			f = f * f * (3 - 2 * f)
			local pos = LerpVector(f, self:LocalToWorld(HOLD), cradle)   -- (inside the hull at first: hidden by it)
			g:SetPos(pos); g:SetAngles(flat); g:SetupBones()
			g:DrawModel()
			render.SetMaterial(GLOW)
			render.DrawSprite(self:LocalToWorld(Vector(-100, 0, -58)), 420, 140, Color(FIELD.r, FIELD.g, FIELD.b, 60 + 30 * math.sin(now * 5)))
		end
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		-- while a gate is made the drawing reaches down to the ground (else it vanishes when the ship is off screen)
		local busy = self:GetNWFloat("AGPSeedAt", 0) > CurTime() or self:GetNWFloat("AGPSeedLower", 0) > CurTime()
		if (busy ~= self.AGPSeedBounds) then
			self.AGPSeedBounds = busy
			local mn, mx = self:OBBMins(), self:OBBMaxs()
			self:SetRenderBounds(busy and (mn - Vector(0, 0, SEED_MAX + 400)) or mn, mx)
		end
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		-- camera distance / height on the arrow keys, the other view on 1
		if (p:KeyDown("Gateseeder", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("Gateseeder", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("Gateseeder", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("Gateseeder", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("Gateseeder", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
