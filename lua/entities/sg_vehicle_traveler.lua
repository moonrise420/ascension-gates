--[[
	Traveler ship (the Travelers' generational ship of Stargate Atlantis) - Ascension Gates' own code and model
	(2026-11-09), designed after the series (notes/models/agp_traveler_ship_*.py).
	EAP's model and code are gone; the class name stays "sg_vehicle_traveler", so saves and dupes keep working (the old
	Wire names "Health" and "Hyperspace" stay, the keyboard layout is still "Traveler"). Built on:
	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's energy_pulse (aVoN, Madman07) for the shots, in the Travelers' red (energy_pulse_traveler)
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua, agp_ship_aim.lua): shield, hull
	    damage, aiming, the Mouse2 volley, hyperdrive, the Supergate / Stargate dial menu
	As in the series: the two bows first, shields, energy weapons, hyperdrive, the two big sublight engines on the stern.
	Keys: Mouse1 the two cannons in the bows at the crosshair (a pair a second), Mouse2 three heavy bolts at the
	crosshair, G shield, H hyperdrive (hold), R dial menu, 1 view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "Traveler Ship"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_traveler") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_capital_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 25000       -- hyperdrive (H): longest jump
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own model, designed after the series (notes/models/agp_traveler_ship_models.py); +X = the two bows
local MODEL = "models/agp/traveler/agp_traveler.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble round every point of the hull (fitted on the model 2026-11-09: centre (190, 0, -30), radii
-- 826 x 528 x 198 with a margin), the Travelers' warm orange
ENT.AGPShield = { model = "models/iziraider/shields/4x4x3.mdl", yaw = 0, offset = Vector(190, 0, -30), scale = Vector(0.826, 0.529, 0.263), color = { 1, 0.7, 0.4 } }
-- (2026-11-09 balance) a battlecruiser half a Daedalus' size (series): hull 20000 + shield 16000, between the Wraith
-- cruiser and the Prometheus (EAP's 10000 + 8000 was less than an Al'kesh)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 16000, 16

local HULL = 20000
-- model space: the two cannons, low in the bows' front faces (left, right)
local CANNONS = { Vector(862, 150, -86), Vector(862, -150, -86) }
local SHOT_EVERY = 1
local SHOT = "pulse_weapon/staff_weapon.mp3"

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_traveler")
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
		self.Vehicle = "Traveler"
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
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 5000, 750, 600
		self.RollSpeed = 5
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		-- the old Wire names stay (dupes keep their wiring); fire, target and shield inputs are new
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Target [VECTOR]", "Shield", "Hyperspace [VECTOR]") end
		if (self.CreateWireOutputs) then self:CreateWireOutputs("Health", "Can Shoot", "Shield Strength", "Shield Enabled") end
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
		elseif (k == "Target") then self.WireTarget = (isvector(v) and v ~= Vector(0, 0, 0)) and Vector(v) or nil
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	-- the two cannons: one bolt each at the target (a world point), then SHOT_EVERY s until the next pair
	function ENT:FireBlast(target)
		if (CurTime() < (self.AGPNextShot or 0)) then return end
		self.AGPNextShot = CurTime() + SHOT_EVERY
		local fwd = self:GetForward()
		for _, at in ipairs(CANNONS) do
			local from = self:LocalToWorld(at)
			-- the cannons are fixed in the bow: within 10 degrees of the nose (the shared front limit, AGP.ShipAimClamp)
			local dir = AGP.ShipAimClamp(self, isvector(target) and (target - from) or fwd, 10)
			local e = ents.Create("energy_pulse_traveler")
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
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() - self:GetUp() * 200
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			-- Mouse2: three heavy bolts from the bows at the crosshair
			if (AGP and AGP.ShipVolley) then
				local before = self.AGPNextVolley
				AGP.ShipVolley(self, { class = "energy_pulse_traveler", count = 3, size = 16, cool = 7, gap = 0.3, front = 0.6, wide = 0.25, sound = SHOT })
				if (self.AGPNextVolley ~= before) then self.AGPShotsFired = (self.AGPShotsFired or 0) + 3 end
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
		self:AGPSetWire("Shield Enabled", self.AGPShielded and 1 or 0)
		local gen = AGP and AGP.ShipShieldGen and AGP.ShipShieldGen(self)
		self:AGPSetWire("Shield Strength", IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 0)
		self:NextThink(CurTime() + 0.1)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_traveler", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys (the same layout name as before, so players keep their bindings)
	local KBD = StarGate.KeyBoard:New("Traveler")
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
	ENT.Sounds = { Engine = Sound("glider/deathglideridleoutside.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "Traveler"
		self.Dist, self.UDist = -750, 120
		self.FirstPerson = false
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
		-- camera distance / height on the arrow keys, the other view on 1
		if (p:KeyDown("Traveler", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("Traveler", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("Traveler", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("Traveler", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("Traveler", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
