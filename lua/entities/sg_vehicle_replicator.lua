--[[
	Replicator cruiser ("Replicator Mothership", the series' Replicator cruiser of "New Order" and "Reckoning") -
	Ascension Gates' own code and model, designed after the series. EAP's model and code are gone; the class name
	stays "sg_vehicle_replicator", so saves and dupes keep working (same keyboard layout "ReplicatorMS"). Built on:

	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's energy_pulse for its bolts
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua): shield, hull damage,
	    aiming, the Mouse2 volley, hyperdrive, the Supergate / Stargate dial menu
	As in the series: made of Replicator blocks, black; the inner column with the launcher at its bow turns slowly
	counter-clockwise, a purple ring of light round the launcher; blue-violet light from inside lights the spikes.
	Keys: Mouse1 bolts from the launcher (at the crosshair while Mouse2 is held), Mouse2 volley at the crosshair,
	G shield, H hyperdrive (hold), R dial menu, 1 view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "Replicator Mothership"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_replicator") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_capital_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 30000       -- hyperdrive (H): longest jump
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own models, designed after the series: the ship and its inner column
local MODEL = "models/agp/repship/agp_repship.mdl"
local COLUMN = "models/agp/repship/agp_repship_core.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble round the head, the spikes and the column (fitted round every point); cold blue
ENT.AGPShield = { model = "models/iziraider/shields/4x4x3.mdl", yaw = 0, offset = Vector(-84, 0, -27), scale = Vector(1.42, 0.471, 0.68), color = { 0.55, 0.62, 1 } }
-- (balance, the series' order: Ori > O'Neill > Aurora > Replicator cruiser > Daedalus > Destiny > Prometheus > Al'kesh >
-- Tel'tak) the shield holds 26000 damage
-- (a beam: 26 s)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 26000, 26

local HULL = 28000
local BOLT = Color(140, 120, 255)
-- model space (+X = bow; as in agp_repship_models.py): the launcher at the column's bow in the sunken ring of the head;
-- inside the bundle the points the blue-violet light comes from; the ring of light in the sunken ring; the column
-- turns about X
local LAUNCHER = Vector(710, 0, 0)
local LIGHTS = { Vector(452, 0, 46), Vector(233, 0, -46), Vector(-5, 0, 101), Vector(-243, 0, -137), Vector(-463, 0, 27) }
local RING_X, RING_R = 654, 96
local TURN = 14   -- degrees per second, counter-clockwise seen from the front

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_replicator")
		e:SetPos(tr.HitPos + Vector(0, 0, 450))
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
		self.Vehicle = "ReplicatorMS"
		self.EntHealth, self.MaxHealth = HULL, HULL
		self:SetNWInt("health", HULL)
		self:SetNWInt("maxEntHealth", HULL)
		self.ExitPos = self:GetPos() - self:GetRight() * 500
		self.On, self.Roll = 0, 0
		self.HoverPos, self.NextLand = self:GetPos(), CurTime()   -- what the base's Initialize sets (the LAND key needs it)
		-- flight: the old Replicator ship's
		self.Accel = { FWD = 0, RIGHT = 0, UP = 0, SpeedForward = 10, SpeedRight = 7, SpeedUp = 7 }
		self.ForwardSpeed, self.BackwardSpeed = 1500, -750
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 2000, 750, 600
		self.RollSpeed = 5
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		self.NextBlast = 0
		-- the old Wire names stay (dupes keep their wiring); fire, target and shield are new
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Target [VECTOR]", "Shield", "Hyperspace [VECTOR]") end
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
		elseif (k == "Target") then self.WireTarget = (isvector(v) and v ~= Vector(0, 0, 0)) and Vector(v) or nil
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	-- three bolts from the launcher, one after the other, at the target (or straight ahead); 3 x 270 every 0.7 s
	-- (balance)
	function ENT:FireBlasts(target)
		if (CurTime() < self.NextBlast) then return end
		self.NextBlast = CurTime() + 0.7
		for i = 1, 3 do
			timer.Simple((i - 1) * 0.08, function()
				if (not IsValid(self)) then return end
				local a = math.rad(CurTime() * TURN + i * 120)            -- out of the turning launcher's three points
				local from = self:LocalToWorld(LAUNCHER + Vector(0, math.cos(a) * 40, math.sin(a) * 40))
				local dir = target and (target - from):GetNormalized() or (AGP and AGP.ShipAimDir and AGP.ShipAimDir(self, from) or self:GetForward())
				if (dir:Dot(self:GetForward()) < 0.1) then dir = self:GetForward() end
				local e = ents.Create("energy_pulse")
				if (not IsValid(e)) then return end
				e:PrepareBullet(dir, 10, 17000, 8, { self })
				e:SetPos(from + dir * 15)
				e:SetOwner(self)
				e.Owner = self
				e:Spawn()
				e:Activate()
				e:SetColor(BOLT)
				e.Damage = 270
				self.AGPShotsFired = (self.AGPShotsFired or 0) + 1
			end)
		end
		self:EmitSound("eap/ship/armes/replicateurweapon.mp3", 95, math.random(95, 110))
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() - self:GetRight() * 500
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			-- Mouse2: a volley of bolts from the head at the crosshair (holding it aims the launcher)
			if (AGP and AGP.ShipVolley) then
				local before = self.AGPNextVolley
				AGP.ShipVolley(self, { class = "energy_pulse", count = 6, size = 6, damage = 200, cool = 8, front = 0.35, wide = 0.25, color = BOLT, sound = "eap/ship/armes/replicateurweapon.mp3" })
				if (self.AGPNextVolley ~= before) then self.AGPShotsFired = (self.AGPShotsFired or 0) + 6 end
			end
			if (p:KeyDown(self.Vehicle, "FIRE")) then self:FireBlasts(AGP and AGP.ShipAimPoint and AGP.ShipAimPoint(self)) end
		end
		if (self.WireFire) then self:FireBlasts(self.WireTarget) end
		self:AGPSetWire("Shield Enabled", self.AGPShielded and 1 or 0)
		local gen = AGP and AGP.ShipShieldGen and AGP.ShipShieldGen(self)
		self:AGPSetWire("Shield Strength", IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 0)
		self:NextThink(CurTime() + 0.05)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_replicator", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys (the same layout name as before, so players keep their bindings)
	local KBD = StarGate.KeyBoard:New("ReplicatorMS")
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
	ENT.Sounds = { Engine = Sound("eap/ship/moteur/destiny.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "ReplicatorMS"
		self.Dist, self.UDist = -750, 120
		self.FirstPerson = false
	end

	function ENT:OnRemove()
		if (IsValid(self.AGPColumn)) then self.AGPColumn:Remove() end
		if (self.BaseClass.OnRemove) then self.BaseClass.OnRemove(self) end
	end

	-- the inner column: its own model, turned slowly counter-clockwise (seen from the front) about the ship's long axis
	function ENT:AGPColumnThink()
		local col = self.AGPColumn
		if (not IsValid(col)) then
			col = ClientsideModel(COLUMN, RENDERGROUP_OPAQUE)
			if (not IsValid(col)) then return end
			col:SetNoDraw(false)
			self.AGPColumn = col
		end
		local ang = self:LocalToWorldAngles(Angle(0, 0, (CurTime() * TURN) % 360))   -- + roll: counter-clockwise from the front
		col:SetPos(self:GetPos())
		col:SetAngles(ang)
	end

	local GLOW = Material("sprites/light_glow02_add")
	local INSIDE = Color(110, 90, 255, 70)
	-- the ring of light: one smooth band all round - a soft halo, the band (a little brighter where it turns along with
	-- the column) and its bright middle; each a beam round the ring that takes the glow's middle line across its
	-- width, so it is soft at its edges and even along it
	local RING_N = 48
	local HALO, BAND, CORE = Color(120, 80, 255, 55), Color(160, 110, 255, 150), Color(215, 185, 255, 170)
	local ringPts, bandCol = {}, Color(0, 0, 0)
	function ENT:DrawTranslucent()
		-- the blue-violet light from inside, between the spikes
		render.SetMaterial(GLOW)
		for _, l in ipairs(LIGHTS) do
			render.DrawSprite(self:LocalToWorld(l), 520, 520, INSIDE)
		end
		local turn = math.rad(CurTime() * TURN)
		for k = 0, RING_N do
			local a = 2 * math.pi * k / RING_N
			ringPts[k + 1] = self:LocalToWorld(Vector(RING_X + 10, math.cos(a) * RING_R, math.sin(a) * RING_R))
		end
		render.StartBeam(RING_N + 1)
		for k = 1, RING_N + 1 do render.AddBeam(ringPts[k], 104, 0.5, HALO) end
		render.EndBeam()
		render.StartBeam(RING_N + 1)
		for k = 1, RING_N + 1 do
			local f = 0.8 + 0.2 * math.cos(2 * math.pi * (k - 1) / RING_N - turn)
			bandCol.r, bandCol.g, bandCol.b, bandCol.a = BAND.r * f, BAND.g * f, BAND.b * f, BAND.a * f   -- (additive: the colour is the brightness)
			render.AddBeam(ringPts[k], 58, 0.5, bandCol)
		end
		render.EndBeam()
		render.StartBeam(RING_N + 1)
		for k = 1, RING_N + 1 do render.AddBeam(ringPts[k], 20, 0.5, CORE) end
		render.EndBeam()
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		self:AGPColumnThink()
		-- the light from inside lights the black spikes; the ring of light lights the sunken ring's blocks
		for i, l in ipairs({ { LIGHTS[1], 1300, 3 }, { LIGHTS[3], 1300, 3 }, { Vector(RING_X + 30, 0, 0), 420, 4 } }) do
			local dl = DynamicLight(self:EntIndex() * 4 + i)
			if (dl) then
				dl.pos = self:LocalToWorld(l[1])
				dl.r, dl.g, dl.b = 120, 95, 255
				dl.brightness = l[3]
				dl.Decay = 1000
				dl.Size = l[2]
				dl.DieTime = CurTime() + 0.25
			end
		end
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		if (p:KeyDown("ReplicatorMS", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("ReplicatorMS", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("ReplicatorMS", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("ReplicatorMS", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("ReplicatorMS", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
