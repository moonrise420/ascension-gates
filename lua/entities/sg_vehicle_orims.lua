--[[
	Ori mothership (the Ori warship of the series) - Ascension Gates' own code and model, designed
	after the series. EAP's model and code are gone; the class
	name stays "sg_vehicle_orims", so saves and dupes keep working (same Wire names, same keyboard layout "OriMs").
	Built on:
	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's energy_beam2 for the main beam, CAP's energy_pulse for the volley
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua): shield, hull damage,
	    aiming, the Mouse2 volley, hyperdrive, the Supergate / Stargate dial menu
	As in the series: the main beam from the round emitter low on the bow, a golden shield, hyperdrive.
	Keys: Mouse1 main beam (straight ahead; at the crosshair while Mouse2 is held), Mouse2 volley at the crosshair,
	G shield, H hyperdrive (hold), R dial menu, 1 view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "Ori Mothership"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_orims") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_capital_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 30000       -- hyperdrive (H): longest jump
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own model, designed after the series
local MODEL = "models/agp/orims/agp_orims.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble: a flat ellipsoid round the hull and the core, Ori gold
-- (fitted round every point of the hull; on the 4x4x3 bubble the O'Neill uses - the 6x6x6 one did not show)
ENT.AGPShield = { model = "models/iziraider/shields/4x4x3.mdl", yaw = 0, offset = Vector(293, 0, -268), scale = Vector(1.924, 1.231, 0.802), color = { 1, 0.95, 0.75 } }
-- (balance, the series' order: Ori > O'Neill > Aurora > Daedalus > Destiny > Prometheus > Al'kesh > Tel'tak) the shield
-- holds 40000 damage (a beam: 40 s)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 40000, 40

local HULL = 32000
-- (balance) the main beam burns 2.5 s, 2400 damage a second, and fires again 4.6 s after it started: ~1300 a
-- second, the strongest ship
local BEAM_DELAY, BEAM_TIME = 4.6, 2.5
-- model space (+X = bow; measured on agp_orims.mdl): the main beam's emitter low on the bow
local BEAM_AT = Vector(1684, 0, -500)
-- the two engine blocks at the stern: their glowing back faces (points across each)
local DRIVE_L = { Vector(-1102, 134, -136), Vector(-1102, 158, -136), Vector(-1102, 182, -136), Vector(-1102, 206, -136), Vector(-1102, 228, -136) }
local DRIVE_R = { Vector(-1102, -134, -136), Vector(-1102, -158, -136), Vector(-1102, -182, -136), Vector(-1102, -206, -136), Vector(-1102, -228, -136) }

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_orims")
		e:SetPos(tr.HitPos + Vector(0, 0, 750))
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
		self.Vehicle = "OriMs"
		self.EntHealth, self.MaxHealth = HULL, HULL
		self:SetNWInt("health", HULL)
		self:SetNWInt("maxEntHealth", HULL)
		self:SetNWInt("CanFire", 1)
		self.CanShoot = true
		self.ExitPos = self:GetPos() + self:GetForward() * 2000 - self:GetUp() * 750
		self.On, self.Roll = 0, 0
		self.HoverPos, self.NextLand = self:GetPos(), CurTime()   -- what the base's Initialize sets (the LAND key needs it)
		-- flight: the old Ori mothership's
		self.Accel = { FWD = 0, RIGHT = 0, UP = 0, SpeedForward = 10, SpeedRight = 7, SpeedUp = 7 }
		self.ForwardSpeed, self.BackwardSpeed = 1500, -750
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 2000, 750, 600
		self.RollSpeed = 5
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		-- the old Wire names stay (dupes keep their wiring); fire, beam target and shield inputs are new
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Beam Target [VECTOR]", "Shield", "Hyperspace [VECTOR]") end
		if (self.CreateWireOutputs) then self:CreateWireOutputs("Health", "Can Shoot", "Shooting", "Shield Strength", "Shield Enabled") end
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
		timer.Remove("CanShootOri" .. self:EntIndex())
		if (AGP and AGP.ShipShieldRemove) then AGP.ShipShieldRemove(self) end
		self.BaseClass.OnRemove(self)
	end

	function ENT:ToggleShield()
		if (AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self) end
	end

	function ENT:TriggerInput(k, v)
		if (k == "Fire") then self.WireFire = (v ~= 0)
		elseif (k == "Beam Target") then self.WireTarget = (isvector(v) and v ~= Vector(0, 0, 0)) and Vector(v) or nil
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	-- the main beam from the emitter on the bow at the target, then BEAM_DELAY s until the next (the HUD shows it)
	function ENT:FireBeam(target)
		if (not self.CanShoot or not target) then return end
		local from = self:LocalToWorld(BEAM_AT)
		local dir = (target - from):GetNormalized()
		if (dir:Dot(self:GetForward()) < 0.2) then dir = self:GetForward() end   -- the emitter faces forward
		local e = ents.Create("energy_beam2")
		if (not IsValid(e)) then return end
		self.CanShoot = false
		self:SetNWInt("CanFire", 0)
		self.AGPShotsFired = (self.AGPShotsFired or 0) + 1
		e.Owner = self
		e:SetPos(from)
		e:Spawn()
		e:Activate()
		e:SetOwner(self)
		e.AGPDamageScale = 4   -- (balance) the Ori's main beam: four times a normal beam
		e.AGPOriBeam = true   -- AGP: a Ha'tak's shield fails within one burn, as in the series (agp_hatak.lua)
		e:Setup(from, dir, 1200, BEAM_TIME, "Ori")
		self:EmitSound("weapons/ori_beam.wav", 90, math.random(90, 110))
		self:AGPSetWire("Shooting", 1)
		timer.Create("CanShootOri" .. self:EntIndex(), BEAM_DELAY, 1, function()
			if (not IsValid(self)) then return end
			self.CanShoot = (self.EntHealth or 0) > 500
			self:SetNWInt("CanFire", self.CanShoot and 1 or 0)
		end)
		timer.Simple(BEAM_TIME, function() if (IsValid(self)) then self:AGPSetWire("Shooting", 0) end end)
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() + self:GetForward() * 2000 - self:GetUp() * 750
		if ((self.EntHealth or 0) <= 500) then   -- too badly hit to fire the main beam
			self.CanShoot = false
			self:SetNWInt("CanFire", 0)
		end
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			-- Mouse2: a volley of golden bolts from the bow at the crosshair (holding it aims the main beam)
			if (AGP and AGP.ShipVolley) then
				local before = self.AGPNextVolley
				AGP.ShipVolley(self, { class = "energy_pulse", count = 6, size = 7, damage = 500, cool = 6, front = 0.9, wide = 0.3, color = Color(255, 210, 120), sound = "weapons/ori_beam.wav" })
				if (self.AGPNextVolley ~= before) then self.AGPShotsFired = (self.AGPShotsFired or 0) + 6 end
			end
			if (p:KeyDown(self.Vehicle, "FIRE")) then
				-- AGP: at the crosshair (from the pilot's camera, lua/autorun/agp_ship_aim.lua); it went straight ahead
				-- unless Mouse2 was held
				self:FireBeam(AGP and AGP.ShipCrosshair and AGP.ShipCrosshair(self) or (self:GetPos() + self:GetForward() * 30000))
			end
		end
		if (self.WireFire) then self:FireBeam(self.WireTarget or (self:GetPos() + self:GetForward() * 30000)) end
		local left = timer.Exists("CanShootOri" .. self:EntIndex()) and timer.TimeLeft("CanShootOri" .. self:EntIndex()) or 0
		self:SetNWInt("WeaponsTimer", math.ceil(left or 0))
		self:AGPSetWire("Can Shoot", self.CanShoot and 1 or 0)
		self:AGPSetWire("Shield Enabled", self.AGPShielded and 1 or 0)
		local gen = AGP and AGP.ShipShieldGen and AGP.ShipShieldGen(self)
		self:AGPSetWire("Shield Strength", IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 0)
		self:NextThink(CurTime() + 0.1)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_orims", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys (the same layout name as before, so players keep their bindings)
	local KBD = StarGate.KeyBoard:New("OriMs")
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
	ENT.Sounds = { Engine = Sound("eap/ship/moteur/wraithcruiser.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "OriMs"
		self.Dist, self.UDist = -750, 120
		self.FirstPerson = false
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	-- the core always glows: a soft warm-white halo round the sphere, the same whether it flies or not; the
	-- sphere itself hides the halo's middle, so it shows as light round its edge
	local CORE, CORE_GLOW = Vector(740, 0, -215), Material("sprites/light_glow02_add")
	local HALO_WIDE, HALO_NEAR = Color(255, 236, 200, 90), Color(255, 244, 222, 160)

	-- the core's halo; the engine blocks' back faces glow gold while it flies forward, a little blurred (seen by everyone)
	function ENT:DrawTranslucent()
		local c = self:LocalToWorld(CORE)
		render.SetMaterial(CORE_GLOW)
		render.DrawSprite(c, 2400, 2400, HALO_WIDE)
		render.DrawSprite(c, 1500, 1500, HALO_NEAR)
		self:AGPEngineLine(DRIVE_L, { 255, 215, 150 }, 26)
		self:AGPEngineLine(DRIVE_R, { 255, 215, 150 }, 26)
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		-- camera distance / height on the arrow keys, the other view on 1
		if (p:KeyDown("OriMs", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("OriMs", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("OriMs", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("OriMs", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("OriMs", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
