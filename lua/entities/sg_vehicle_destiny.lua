--[[
	Destiny (the Ancient ship of Stargate Universe) - Ascension Gates' own code (2026-11-07).
	Model and code are ours (EAP's model and code are gone since 2026-11-07). The class name stays
	"sg_vehicle_destiny", so saves and dupes keep working. Built on:
	  * the ship base sg_vehicle_base (CAP, RononDex): flying, getting in / out, the camera
	  * CAP's energy_pulse (aVoN, Madman07) for the shots, in Destiny's yellow
	  * CAP's Destiny main weapon models (Madman07, Rafael De Jongh: models/madman07/main_weapon), hung under the hull
	  * our own ship systems (lua/autorun/agp_ship_shield.lua, agp_ship_hyperdrive.lua): shield, hull damage,
	    aiming, FTL drive, the Supergate / Stargate dial menu
	Weapons as in the series: the main weapon under the hull (three big barrels side by side, a shorter, wider one
	below them) fires straight ahead; the triple-barrelled turrets along the hull (dorsal and ventral) shoot at the
	crosshair. Shield in Destiny's yellow.
	Keys: Mouse1 main weapon, hold Mouse2 = turrets at the crosshair, G shield,
	H FTL drive (hold), R dial menu, 1 bridge view.
]]
ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.Spawnable = false -- in our spawn tab
ENT.PrintName = "Destiny"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.PrintName = SGLanguage.GetMessage("ent_ship_destiny") end
ENT.Author = "Ascension Gates"
ENT.Category = "Ships"
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then ENT.Category = SGLanguage.GetMessage("cat_capital_ship") end
ENT.AGPHudEntHealth = true      -- the HUD shows ship.EntHealth
ENT.AGPHullInEntHealth = true   -- AGP.ShipHullDamage keeps the hull in ship.EntHealth
ENT.AGPSupergateDHD = true      -- R: dial menu of the nearest Supergate (or Stargate)
ENT.AGPHyperRange = 30000       -- FTL drive (H): longest jump
ENT.AGPHyperFTL = true          -- Destiny's FTL sounds, the short blue-white flash
ENT.AGPCamBack, ENT.AGPCamUp = 1.1, 0.2
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- our own model, designed after the series (notes/models/agp_destiny_ship_models.py)
local MODEL = "models/agp/destiny/agp_destiny.mdl"
function ENT:AGPModel() return MODEL end

-- the shield bubble: a flat ellipsoid over the hull, wide enough for the wing tips; yellow as in the series
ENT.AGPShield = { model = "models/iziraider/shields/4x4x3.mdl", yaw = 0, offset = Vector(-2, 0, 48), scale = Vector(1.22, 0.9, 0.26), color = { 1, 0.8, 0.35 } }   -- fitted round every point of the hull (2026-11-07)
-- (2026-11-07 balance, the series' order: Ori > O'Neill > Aurora > Daedalus > Destiny > Prometheus > Al'kesh > Tel'tak)
-- the shield holds 24000 damage (a beam: 24 s)
ENT.AGPShieldHP, ENT.AGPShieldBeamTime = 24000, 24

local HULL = 24000
local YELLOW = Color(255, 210, 90)

-- the main weapon: CAP's Destiny main weapon, put together as CAP's sg_turret_destmain does (stand, turning housing
-- at +17, barrels turned round: they fire along the stand's +X), then hung upside down under the neck at GUN_SCALE,
-- the stand flush on the mounting plate of our model (owner 2026-11-07: no gap between weapon and hull).
-- Parts: { model, position on the stand, angles }; MUZZLE_AT: the muzzle of each barrel on the stand.
local GUN_ORIGIN, GUN_SCALE, GUN_FLIP = Vector(0, 0, -33.9), 0.38, Angle(0, 0, 180)
local MW = "models/madman07/main_weapon/"
local GUN_PARTS = {
	{ MW .. "main_stand.mdl", Vector(0, 0, 0), Angle(0, 0, 0) },
	{ MW .. "main_turn.mdl", Vector(0, 0, 17), Angle(0, 180, 0) },
	{ MW .. "big_barrel.mdl", Vector(20, 60, 87), Angle(0, 180, 0), MW .. "big_barrel_light.mdl", 1 },
	{ MW .. "big_barrel.mdl", Vector(20, 0, 87), Angle(0, 180, 0), MW .. "big_barrel_light.mdl", 2 },
	{ MW .. "big_barrel.mdl", Vector(20, -60, 87), Angle(0, 180, 0), MW .. "big_barrel_light.mdl", 3 },
	{ MW .. "small_barrel.mdl", Vector(20, 0, 161), Angle(0, 180, 0), MW .. "small_barrel_light.mdl", 4 },
}
local MUZZLE_AT = { Vector(712, 60, 87), Vector(712, 0, 87), Vector(712, -60, 87), Vector(336, 0, 161) }

-- a point on the weapon's stand -> ship model space
local function gunLocal(p)
	local pos = LocalToWorld(p * GUN_SCALE, Angle(), GUN_ORIGIN, GUN_FLIP)
	return pos
end

-- model space (+X = bow, +Y = port; measured on agp_destiny.mdl): the turrets with the side they face (1 = up, -1 = down)
local TURRETS = {
	{ Vector(640, -32, 39), 1 }, { Vector(640, 32, 39), 1 }, { Vector(440, -41, 40), 1 }, { Vector(440, 41, 40), 1 },
	{ Vector(240, -51, 40), 1 }, { Vector(240, 51, 40), 1 }, { Vector(40, -64, 40), 1 }, { Vector(40, 64, 40), 1 },
	{ Vector(-300, -115, 56), 1 }, { Vector(-300, 115, 56), 1 }, { Vector(-430, -220, 36), 1 }, { Vector(-430, 220, 36), 1 },
	{ Vector(-640, -420, 36), 1 }, { Vector(-640, 420, 36), 1 }, { Vector(-700, -250, 36), 1 }, { Vector(-700, 250, 36), 1 },
	{ Vector(560, -36, -27), -1 }, { Vector(560, 36, -27), -1 }, { Vector(420, -42, -27), -1 }, { Vector(420, 42, -27), -1 },
	{ Vector(-160, -90, -31), -1 }, { Vector(-160, 90, -31), -1 }, { Vector(-420, -200, -34), -1 }, { Vector(-420, 200, -34), -1 },
	{ Vector(-640, -400, -33), -1 }, { Vector(-640, 400, -33), -1 },
}

if SERVER then
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr)
		if (not tr.HitWorld) then return end
		local limit = GetConVar("CAP_ships_max")
		if (limit and ply:GetCount("CAP_ships") + 1 > limit:GetInt()) then
			ply:SendLua("GAMEMODE:AddNotify(SGLanguage.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound(\"buttons/button2.wav\")")
			return
		end
		local e = ents.Create("sg_vehicle_destiny")
		e:SetPos(tr.HitPos + Vector(0, 0, 260))
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
		self.Vehicle = "Destiny"
		self.EntHealth, self.MaxHealth = HULL, HULL
		self.ExitPos = self:GetPos() + Vector(0, 0, 250)
		self.On, self.Roll = 0, 0
		self.HoverPos, self.NextLand = self:GetPos(), CurTime()   -- what the base's Initialize sets (the LAND key needs it)
		-- flight: a long, heavy ship - slow to speed up and to turn
		self.Accel = { FWD = 0, RIGHT = 0, UP = 0, SpeedForward = 7, SpeedRight = 4, SpeedUp = 4 }
		self.ForwardSpeed, self.BackwardSpeed = 1500, -400
		self.MaxSpeed, self.RightSpeed, self.UpSpeed = 2000, 500, 500
		self.RollSpeed = 2.5
		self.Hover, self.GoesRight, self.GoesUp, self.CanRoll = true, true, true, true
		self.ShouldRotorwash = false
		self.NextMain, self.NextTurret, self.TurretIndex = 0, 0, 0
		-- the same Wire names as before (dupes keep their wiring), and a fire input
		if (self.CreateWireInputs) then self:CreateWireInputs("Fire", "Shield", "Hyperspace [VECTOR]") end
		if (self.CreateWireOutputs) then self:CreateWireOutputs("Health", "Shield Strength", "Shield Enabled") end
		local phys = self:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:SetMass(50000)
			phys:EnableMotion(true)
			phys:Wake()
		end
		self:AGPSetWire("Health", HULL)
		-- the hull mends slowly while nothing hits it
		timer.Create("AGP.DestinyRepair" .. self:EntIndex(), 2, 0, function()
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
		timer.Remove("AGP.DestinyRepair" .. self:EntIndex())
		if (AGP and AGP.ShipShieldRemove) then AGP.ShipShieldRemove(self) end
		self.BaseClass.OnRemove(self)
	end

	function ENT:ToggleShield()
		if (AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self) end
	end

	function ENT:TriggerInput(k, v)
		if (k == "Fire") then self.WireFire = (v ~= 0)
		elseif (k == "Shield" and AGP and AGP.ShipShieldToggle) then AGP.ShipShieldToggle(self, v ~= 0)
		elseif (AGP and AGP.ShipHyperdriveInput and AGP.ShipHyperdriveInput(self, k, v)) then return
		elseif (self.BaseClass.TriggerInput) then self.BaseClass.TriggerInput(self, k, v) end
	end

	local function bolt(self, from, dir, size, speed, damage)
		local e = ents.Create("energy_pulse")
		if (not IsValid(e)) then return end
		self.AGPShotsFired = (self.AGPShotsFired or 0) + 1
		e:PrepareBullet(dir, 10, speed, size, { self })
		e:SetPos(from)
		e:SetOwner(self)
		e.Owner = self
		e:Spawn()
		e:Activate()
		e:SetColor(YELLOW)
		e.Damage = damage   -- its own damage (the size only sets the look)
	end

	-- one salvo of the main weapon: the three barrels one after the other, then the wide lower one with a heavier
	-- shot (in the series it charges and fires a little after the others). Straight ahead: it cannot turn sideways.
	function ENT:FireMain()
		if (CurTime() < self.NextMain) then return end
		self.NextMain = CurTime() + 2.5
		for i, m in ipairs(MUZZLE_AT) do
			timer.Simple(i == 4 and 0.55 or (i - 1) * 0.14, function()
				if (not IsValid(self)) then return end
				local from = self:LocalToWorld(gunLocal(m))
				-- AGP 2026-11-08: still straight ahead, but within 8 degrees it meets the crosshair (the camera sits above
				-- and behind the guns, so dead ahead missed what the crosshair showed, most in the bridge view)
				local fwd = AGP.ShipAimCone and AGP.ShipAimCone(self, from, 8) or self:GetForward()
				bolt(self, from + fwd * 10, fwd, i == 4 and 40 or 25, 14000, i == 4 and 600 or 380)
				self:SetNWFloat("AGPGunShot" .. i, CurTime())
				self:EmitSound(i == 4 and "weapons/dest_main_cannon2.wav" or "weapons/dest_main_cannon.wav", 100, math.random(92, 105))
			end)
		end
	end

	-- the turrets: while Mouse2 is held, two at a time fire at the crosshair - the ones on the side (top / bottom) that
	-- faces it, taken in turn along the hull
	function ENT:FireTurrets(aim)
		if (CurTime() < self.NextTurret) then return end
		self.NextTurret = CurTime() + 0.4
		local up = self:GetUp()
		local fired = 0
		for _ = 1, #TURRETS do
			self.TurretIndex = self.TurretIndex % #TURRETS + 1
			local t = TURRETS[self.TurretIndex]
			local from = self:LocalToWorld(t[1])
			local dir = (aim - from):GetNormalized()
			if (dir:Dot(up) * t[2] > -0.05) then   -- not through the hull
				bolt(self, from + dir * 15, (dir + VectorRand() * 0.008):GetNormalized(), 10, 16000, 60)
				fired = fired + 1
				if (fired >= 2) then break end
			end
		end
		if (fired > 0) then self:EmitSound("weapons/dest_single.wav", 90, math.random(100, 115)) end
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		if (AGP and AGP.ShipShieldThink) then AGP.ShipShieldThink(self) end
		if (AGP and AGP.ShipHyperdriveThink) then AGP.ShipHyperdriveThink(self) end
		self.ExitPos = self:GetPos() + self:GetUp() * 200
		local p = self.Pilot
		if (IsValid(p) and self.Inflight) then
			if (p:KeyDown(self.Vehicle, "FIRE")) then self:FireMain() end
			local aim = AGP and AGP.ShipAimPoint and AGP.ShipAimPoint(self)
			if (aim) then self:FireTurrets(aim) end
		end
		if (self.WireFire) then self:FireMain() end
		self:AGPSetWire("Shield Enabled", self.AGPShielded and 1 or 0)
		local gen = AGP and AGP.ShipShieldGen and AGP.ShipShieldGen(self)
		self:AGPSetWire("Shield Strength", IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 0)
		self:NextThink(CurTime() + 0.1)
		return true
	end

	if (StarGate and StarGate.CAP_GmodDuplicator) then
		duplicator.RegisterEntityClass("sg_vehicle_destiny", StarGate.CAP_GmodDuplicator, "Data")
	end
end

if CLIENT then
	if (StarGate == nil or StarGate.KeyBoard == nil or StarGate.KeyBoard.New == nil) then return end
	-- the keys, the same layout as the other big ships
	local KBD = StarGate.KeyBoard:New("Destiny")
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

	ENT.Sounds = { Engine = Sound("eap/ship/moteur/destiny.wav") }

	function ENT:Initialize()
		self.BaseClass.Initialize(self)
		self.KBD = self.KBD or KBD:CreateInstance(self)
		self.Vehicle = "Destiny"
		self.Dist, self.UDist = -900, 220
		-- the main weapon hangs a little below the hull's box
		local mn, mx = self:OBBMins(), self:OBBMaxs()
		self:SetRenderBounds(mn - Vector(0, 0, 12), mx)
	end

	local function piloting(self)
		local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
		return IsValid(ship) and ship == self
	end

	-- the drive along the stern: 16 modules in a line; while it flies forward they glow blue-white, a little blurred
	-- (seen by everyone)
	local DRIVE = { Vector(-647, 626, -15), Vector(-713, 562, -9), Vector(-770, 490, -5), Vector(-814, 409, -2), Vector(-844, 321, -2),
		Vector(-866, 231, -2), Vector(-880, 139, -2), Vector(-887, 46, -2), Vector(-887, -46, -2), Vector(-880, -139, -2),
		Vector(-866, -231, -2), Vector(-844, -321, -2), Vector(-814, -409, -2), Vector(-770, -490, -5), Vector(-713, -562, -9),
		Vector(-647, -626, -15) }
	-- the main weapon's parts: client-side models of CAP's main weapon, drawn with the ship; a barrel glows for a
	-- moment after it fired
	local function gunModel(self, key, mdl)
		self.AGPGunModels = self.AGPGunModels or {}
		local cm = self.AGPGunModels[key]
		if (not IsValid(cm)) then
			cm = ClientsideModel(mdl, RENDERGROUP_OPAQUE)
			if (not IsValid(cm)) then return end
			cm:SetNoDraw(true)
			cm:SetModelScale(GUN_SCALE, 0)
			self.AGPGunModels[key] = cm
		end
		return cm
	end
	function ENT:DrawMainWeapon()
		for i, part in ipairs(GUN_PARTS) do
			local lp, la = LocalToWorld(part[2] * GUN_SCALE, part[3], GUN_ORIGIN, GUN_FLIP)
			local wp, wa = LocalToWorld(lp, la, self:GetPos(), self:GetAngles())
			local cm = gunModel(self, i, part[1])
			if (cm) then cm:SetPos(wp); cm:SetAngles(wa); cm:SetupBones(); cm:DrawModel() end
			local since = part[5] and CurTime() - self:GetNWFloat("AGPGunShot" .. part[5], -10)
			if (since and since < 0.7) then
				local glow = gunModel(self, "l" .. i, part[4])
				if (glow) then
					glow:SetPos(wp); glow:SetAngles(wa); glow:SetupBones()
					render.SetBlend(1 - since / 0.7); glow:DrawModel(); render.SetBlend(1)
				end
			end
		end
	end

	function ENT:OnRemove()
		for _, cm in pairs(self.AGPGunModels or {}) do if (IsValid(cm)) then cm:Remove() end end
		self.AGPGunModels = nil
		if (self.BaseClass.OnRemove) then self.BaseClass.OnRemove(self) end
	end

	function ENT:Draw()
		self.BaseClass.Draw(self)
		self:DrawMainWeapon()
	end
	ENT.RenderGroup = RENDERGROUP_BOTH
	function ENT:DrawTranslucent()
		self:AGPEngineLine(DRIVE, { 170, 205, 255 }, 22)
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		local mine = piloting(self)
		self.KBD:SetActive(mine)
		if (not mine) then return end
		local p = LocalPlayer()
		-- camera distance / height on the arrow keys, bridge view on 1
		if (p:KeyDown("Destiny", "Z+")) then self.Dist = self.Dist - 10 elseif (p:KeyDown("Destiny", "Z-")) then self.Dist = self.Dist + 10 end
		if (p:KeyDown("Destiny", "A+")) then self.UDist = self.UDist + 10 elseif (p:KeyDown("Destiny", "A-")) then self.UDist = self.UDist - 10 end
		local view = p:KeyDown("Destiny", "VIEW")
		if (view and not self.AGPViewHeld) then self.FirstPerson = not self.FirstPerson end
		self.AGPViewHeld = view
	end
end
