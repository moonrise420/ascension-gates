--[[
	Al'kesh (the Goa'uld mid-range bomber) - Ascension Gates' own code. EAP's code is
	gone; the class name stays "sg_vehicle_alkesh", so saves and dupes keep working (same Wire names, same keyboard
	layout "Alkesh"). Built on:
	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's energy_pulse (aVoN, Madman07) for the shots and the bombs, in the Goa'uld orange
	  * the Al'kesh model by Ska-Ara (Sketchfab, CC BY-NC-SA, see CREDITS.md), converted by us
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua): shield, hull damage,
	    aiming, hyperdrive, the Supergate / Stargate dial menu
	As in the series: energy cannons in the nose, plasma bombs dropped from the belly on a bombing run, hyperdrive.
	Keys: Mouse1 cannons, Mouse2 bombs, G shield, H hyperdrive (hold), R dial menu, 1 cockpit view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "Al'kesh"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_alkesh") end
ENT.WireDebugName = ENT.PrintName
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_small_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 15000       -- hyperdrive (H): longest jump
ENT.AGPHyperChargeTime = 3
list.Set("CAP.Entity", ENT.PrintName, ENT)

local MODEL = "models/agp/hatak/props/ship_alkesh.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble, fitted to the hull (2000 x 1500 x 1500), Goa'uld gold
ENT.AGPShield = { model = "models/iziraider/shields/3x4x3.mdl", yaw = 0, offset = Vector(0, 0, 171), color = { 1, 0.85, 0.5 } }
-- (balance, the series' order: Ori > O'Neill > Aurora > Daedalus > Destiny > Prometheus > Al'kesh > Tel'tak) the shield
-- holds 12000 damage (a beam: 12 s)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 12000, 12

local HULL = 18000
-- model space (+X = the narrow bow with the cockpit; the pyramid and the four engines are at the stern; measured on
-- ship_alkesh.mdl): the two energy cannons in the nose rim, either side of the cockpit
local GUNS = { Vector(640, 110, 65), Vector(640, -110, 65) }
local BOMB_BAY = Vector(0, 0, -148)   -- under the belly
local BOMB_SPREAD = 120

local function shotColour() return Color(math.random(230, 255), 200, 120) end

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_alkesh")
		e:SetPos(tr.HitPos + Vector(0, 0, 250))
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
		self.Vehicle = "Alkesh"
		self.EntHealth, self.MaxHealth = HULL, HULL
		self.ExitPos = self:GetPos() - self:GetRight() * 560
		self.On, self.Roll = 0, 0
		self.HoverPos, self.NextLand = self:GetPos(), CurTime()   -- what the base's Initialize sets (the LAND key needs it)
		-- flight: a mid-sized bomber - quicker than the big ships, slower than a glider
		self.Accel = { FWD = 0, RIGHT = 0, UP = 0, SpeedForward = 10, SpeedRight = 7, SpeedUp = 7 }
		self.ForwardSpeed, self.BackwardSpeed = 1500, -700
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 2000, 750, 600
		self.RollSpeed = 5
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		self.NextGuns, self.NextBomb, self.GunIndex = 0, 0, 0
		-- the old Wire names stay (dupes keep their wiring); fire, bomb and shield inputs are new
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Bomb", "Shield", "Hyperspace [VECTOR]") end
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
		elseif (k == "Bomb") then self.WireBomb = (v ~= 0)
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	local function bolt(self, from, dir, size, speed, colour, damage)
		local e = ents.Create("energy_pulse")
		if (not IsValid(e)) then return end
		self.AGPShotsFired = (self.AGPShotsFired or 0) + 1
		e:PrepareBullet(dir, 10, speed, size, { self })
		e:SetPos(from)
		e:SetOwner(self)
		e.Owner = self
		e:Spawn()
		e:Activate()
		e:SetColor(colour)
		if (damage) then e.Damage = damage end   -- else the size's damage (the bombs)
	end

	-- the nose cannons, one after the other, straight ahead (they are fixed in the hull)
	function ENT:FireGuns()
		if (CurTime() < self.NextGuns) then return end
		self.NextGuns = CurTime() + 0.45
		self.GunIndex = self.GunIndex % #GUNS + 1
		local from = self:LocalToWorld(GUNS[self.GunIndex])
		-- AGP: the nose cannon meets the crosshair within 10 degrees of straight ahead (lua/autorun/agp_ship_aim.lua)
		local dir = AGP.ShipAimCone and AGP.ShipAimCone(self, from, 10) or self:GetForward()
		bolt(self, from + dir * 20, dir, 8, 16000, shotColour(), 225)   -- (balance) one every 0.5 s: ~450 a second
		self:EmitSound("pulse_weapon/staff_weapon.mp3", 90, math.random(90, 110))
	end

	-- a bombing run: a pair of plasma bombs falls out of the belly, carried forward by the ship's speed
	function ENT:DropBombs()
		if (CurTime() < self.NextBomb) then return end
		self.NextBomb = CurTime() + 1.2
		local dir = (-self:GetUp() + self:GetForward() * 0.25 + self:GetVelocity() / 3000):GetNormalized()
		for _, side in ipairs({ 1, -1 }) do
			local from = self:LocalToWorld(BOMB_BAY) + self:GetRight() * BOMB_SPREAD * side
			bolt(self, from, dir, 14, 2500, Color(255, 140, 40))
		end
		self:EmitSound("pulse_weapon/staff_weapon.mp3", 95, math.random(60, 75))
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() - self:GetRight() * 560   -- beside the hull, clear of the prongs
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			if (p:KeyDown(self.Vehicle, "FIRE")) then self:FireGuns() end
			if (p:KeyDown(self.Vehicle, "BOMB")) then self:DropBombs() end
		end
		if (self.WireFire) then self:FireGuns() end
		if (self.WireBomb) then self:DropBombs() end
		self:AGPSetWire("Shield Enabled", self.AGPShielded and 1 or 0)
		local gen = AGP and AGP.ShipShieldGen and AGP.ShipShieldGen(self)
		self:AGPSetWire("Shield Strength", IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 0)
		self:NextThink(CurTime() + 0.1)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_alkesh", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys (the same layout name as before, so players keep their bindings)
	local KBD = StarGate.KeyBoard:New("Alkesh")
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
	KBD:SetDefaultKey("BOMB", B["+attack2"] or "MOUSE2")
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
	ENT.Sounds = { Engine = Sound("glider/deathglideridleoutside.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "Alkesh"
		self.Dist, self.UDist = -1150, 220
		self.FirstPerson = false
	end

	-- the four round engines at the stern (two either side, measured on ship_alkesh.mdl): a blue plume behind each
	-- while it flies forward (seen by everyone)
	local ENGINES = { { Vector(-656, 235, 73), 23 }, { Vector(-596, 333, 73), 23 }, { Vector(-656, -235, 73), 23 }, { Vector(-596, -333, 73), 23 } }
	function ENT:DrawTranslucent()
		self:AGPEngineNozzles(ENGINES, { 140, 190, 255 }, 220)
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		-- camera distance / height on the arrow keys, cockpit view on 1
		if (p:KeyDown("Alkesh", "Z+")) then self.Dist = self.Dist - 5 elseif (p:KeyDown("Alkesh", "Z-")) then self.Dist = self.Dist + 5 end
		if (p:KeyDown("Alkesh", "A+")) then self.UDist = self.UDist + 5 elseif (p:KeyDown("Alkesh", "A-")) then self.UDist = self.UDist - 5 end
		local view = p:KeyDown("Alkesh", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
