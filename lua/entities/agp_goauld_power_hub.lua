--[[
	Goa'uld power hub (Ascension Gates)
	The Goa'uld answer to the Ancients' ZPM hub: a brass hub (model power_hub, "Power control panel (magical)" by
	reddification) with the gold power core column on it (agp_goauld_power_core). Its four arms take Goa'uld power
	crystals (agp_goauld_power_crystal) or a ZPM: touch it to an arm (gravity gun / physgun) or spawn it with the tool
	(Goa'uld power tool / ZPM tool) aimed at an arm, it snaps onto that arm; E on it takes it out. The hub gives the crystals' energy to its power network (Grid Power or
	Spacebuild/RD, link it like any other part); the core pulses brighter the more charged crystals sit in it.
	Wire outputs: Active, Crystals, Energy %, Energy.
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then StarGate.LifeSupportAndWire(ENT) end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Goa'uld Power Hub"
ENT.Author = "Ascension Gates"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Goa'uld Power Hub"
ENT.Spawnable = false   -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
list.Set("CAP.Entity", ENT.PrintName, ENT)
-- crystal spots on the four arms (hub space; the arms point along X and Y, their tops are ~21 high): bottom centre,
-- the crystal stands upright
ENT.Arms = { Vector(88, 0, 21), Vector(0, 88, 21), Vector(-88, 0, 21), Vector(0, -88, 21) }
ENT.CoreHeight = 30     -- the column stands in the hub's crown
ENT.FlowPerCrystal = 20000   -- energy per second a crystal gives at most
ENT.FlowPerZPM = 200000      -- a ZPM gives ten times as much
ENT.ZPMHub = true            -- the ZPM tool puts a ZPM spawned on the hub onto it (zpm_mk3 tool: Touch)

if SERVER then
	if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
	AddCSLuaFile()

	function ENT:SpawnFunction(ply, tr, cls)
		if (not tr.Hit) then return end
		local e = ents.Create(cls)
		e:SetPos(tr.HitPos)
		e:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))   -- one arm points at the player
		e:Spawn(); e:Activate()
		e:SetPos(tr.HitPos - Vector(0, 0, e:OBBMins().z))
		e.Owner = ply
		return e
	end

	function ENT:Initialize()
		self:SetModel("models/agp/hatak/props/power_hub.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetMass(2000); ph:EnableMotion(false) end
		self:SetUseType(SIMPLE_USE)
		self.Slots = {}
		self:AddResource("energy", 100000)
		self:CreateWireOutputs("Active", "Crystals", "Energy %", "Energy")
		timer.Simple(0, function() if (IsValid(self)) then self:MakeCore() end end)
		self:NextThink(CurTime() + 0.5)
	end

	function ENT:MakeCore()
		local c = ents.Create("agp_goauld_power_core")
		if (IsValid(c)) then c.DoNotDuplicate = true end   -- (built by its parent, which builds it again after a save or a paste - copied as well it was there twice)
		if (not IsValid(c)) then return end
		c:SetPos(self:LocalToWorld(Vector(0, 0, self.CoreHeight))); c:SetAngles(self:GetAngles())
		c:Spawn(); c:Activate()
		c:SetPower(0)
		c.OnUse = function(_, ply) self:Use(ply) end
		c.ZPMHub = true   -- the ZPM tool aimed at the column: onto the arm nearest the aim
		c.Touch = function(_, e) if (IsValid(self)) then self:Touch(e) end end
		if (self.CPPIGetOwner and c.CPPISetOwner and IsValid(self:CPPIGetOwner())) then c:CPPISetOwner(self:CPPIGetOwner()) end
		constraint.Weld(c, self, 0, 0, 0, true, false)
		self.Core = c
	end

	local function inHub(e) if (e.GetInHub) then return e:GetInHub() end return e.AGPInGoauldHub end
	local function setInHub(e, on) if (e.SetInHub) then e:SetInHub(on) else e.AGPInGoauldHub = on end end
	local function setEnergy(e, v) if (e.SetEnergy) then e:SetEnergy(v) else e.Energy = v end end

	-- a crystal or ZPM touching the hub goes onto the nearest free arm
	function ENT:Touch(e)
		if (not IsValid(e) or not (e.IsGoauldPowerCrystal or e.IsZPM) or inHub(e) or (e.NoHubUntil or 0) > CurTime()) then return end
		if (e.IsZPM and IsValid(e:GetParent())) then return end   -- sits in another hub
		local best, bd
		for i, a in ipairs(self.Arms) do
			if (not IsValid(self.Slots[i])) then
				local d = self:LocalToWorld(a):DistToSqr(e:GetPos())
				if (not bd or d < bd) then best, bd = i, d end
			end
		end
		if (best) then self:InsertCrystal(e, best) end
	end

	function ENT:InsertCrystal(e, i)
		if (e:IsPlayerHolding()) then DropEntityIfHeld(e) end
		local ph = e:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end
		if (e.IsZPM) then   -- upright on the arm
			e:SetAngles(self:LocalToWorldAngles(Angle(0, 0, 0)))
			e:SetPos(self:LocalToWorld(self.Arms[i] - Vector(0, 0, e:OBBMins().z)))
		else
			e:SetPos(self:LocalToWorld(self.Arms[i] + Vector(0, 0, 18)))
			e:SetAngles(self:LocalToWorldAngles(Angle(-90, 0, 0)))
		end
		e:SetParent(self)
		setInHub(e, true)
		self.Slots[i] = e
		e:EmitSound("button/ring_button2.mp3", 60, 110)
		self:UpdateOutputs()
	end

	function ENT:EjectCrystal(e, ply)
		for i, c in pairs(self.Slots) do
			if (c == e) then
				self.Slots[i] = nil
				local out = (self.Arms[i] * Vector(1, 1, 0)):GetNormalized()
				e:SetParent(nil)
				e:SetPos(self:LocalToWorld(self.Arms[i] + out * 40 + Vector(0, 0, 10)))
				e:SetAngles(self:GetAngles())
				setInHub(e, false)
				e.NoHubUntil = CurTime() + 2   -- does not jump straight back in
				local ph = e:GetPhysicsObject()
				if (IsValid(ph)) then ph:EnableMotion(true); ph:Wake() end
				e:EmitSound("button/ring_button1.mp3", 60, 120)
				self:UpdateOutputs()
				return
			end
		end
	end

	function ENT:Crystals()
		local t = {}
		for i = 1, #self.Arms do
			local c = self.Slots[i]
			if (IsValid(c)) then t[#t + 1] = c else self.Slots[i] = nil end
		end
		return t
	end

	function ENT:UpdateOutputs()
		local list = self:Crystals()
		local e, m, charged, zpms = 0, 0, 0, 0
		for _, c in ipairs(list) do
			e, m = e + (c.Energy or 0), m + (c.MaxEnergy or 0)
			if ((c.Energy or 0) > 0) then charged = charged + (c.IsZPM and 1.3 or 1) end   -- a ZPM drives the core harder
			if (c.IsZPM) then zpms = zpms + 1 end
		end
		local pct = m > 0 and e / m * 100 or 0
		self:SetNWInt("AGPCrystals", #list - zpms)
		self:SetNWInt("AGPZPMs", zpms)
		self:SetNWFloat("AGPCharge", pct)
		if (IsValid(self.Core)) then self.Core:SetPower(math.min(1.3, charged / #self.Arms)) end
		self:SetWire("Active", charged > 0 and 1 or 0)
		self:SetWire("Crystals", #list)
		self:SetWire("Energy %", pct)
		self:SetWire("Energy", e)
	end

	-- give the network what it misses, shared evenly by the charged crystals
	function ENT:Think()
		local dt = 0.5
		local list = {}
		local flow = 0
		for _, c in ipairs(self:Crystals()) do
			if ((c.Energy or 0) > 0) then list[#list + 1] = c; flow = flow + (c.IsZPM and self.FlowPerZPM or self.FlowPerCrystal) end
		end
		if (#list > 0 and StarGate.HasResourceDistribution) then
			local need = math.max(0, self:GetNetworkCapacity("energy") - self:GetResource("energy"))
			local give = math.min(need, flow * dt)
			if (give > 0) then
				local given = 0
				for _, c in ipairs(list) do   -- each one its share of the flow
					local d = math.min(give * (c.IsZPM and self.FlowPerZPM or self.FlowPerCrystal) / flow, c.Energy)
					setEnergy(c, c.Energy - d)
					given = given + d
				end
				self:SupplyResource("energy", given)
			end
		end
		self:UpdateOutputs()
		self:NextThink(CurTime() + dt)
		return true
	end

	function ENT:Use(ply)
		if (not IsValid(ply) or not ply:IsPlayer()) then return end
		AGP.Say(ply, "agp_gph_status", "Goa'uld power hub: %s crystals + %s ZPM on %s arms, energy %s %%. Touch a crystal or ZPM to an arm (or spawn it aimed at an arm) to put it in, E on it takes it out.",
			self:GetNWInt("AGPCrystals"), self:GetNWInt("AGPZPMs"), #self.Arms, math.Round(self:GetNWFloat("AGPCharge")))
	end

	-- E on a ZPM sitting on a hub arm takes it out (crystals do this in their own Use)
	hook.Add("PlayerUse", "AGP.GoauldHubZPM", function(ply, e)
		if (not e.IsZPM or not e.AGPInGoauldHub) then return end
		local hub = e:GetParent()
		if (not IsValid(hub) or hub:GetClass() ~= "agp_goauld_power_hub") then return end
		if ((ply.AGPHubUseT or 0) < CurTime()) then ply.AGPHubUseT = CurTime() + 0.5; hub:EjectCrystal(e, ply) end
		return false
	end)

	function ENT:OnRemove()
		if (IsValid(self.Core)) then self.Core:Remove() end
		for _, c in pairs(self.Slots or {}) do if (IsValid(c)) then c:Remove() end end
	end
end

if CLIENT then
	-- looking at the hub (or its core): a small Goa'uld-style plate with crystals and charge
	hook.Add("HUDPaint", "AGP.GoauldPowerHub", function()
		local tr = LocalPlayer():GetEyeTrace()
		local e = tr.Entity
		if (not IsValid(e) or tr.HitPos:Distance(EyePos()) > 400) then return end
		if (e:GetClass() == "agp_goauld_power_core" or e:GetClass() == "agp_goauld_power_crystal") then
			local p = e:GetParent()
			if (IsValid(p) and p:GetClass() == "agp_goauld_power_hub") then e = p end
			if (e:GetClass() == "agp_goauld_power_core") then
				for _, h in ipairs(ents.FindInSphere(e:GetPos(), 60)) do if (h:GetClass() == "agp_goauld_power_hub") then e = h end end
			end
		end
		local x, y = ScrW() / 2 + 40, ScrH() / 2 - 40
		if (e:GetClass() == "agp_goauld_power_hub") then
			draw.RoundedBox(6, x, y, 230, 56, Color(10, 8, 4, 220))
			draw.SimpleText(AGP.L("agp_ui_goauld_power_hub", "GOA'ULD POWER HUB"), "DermaDefaultBold", x + 10, y + 8, Color(230, 182, 74))
			local z = e:GetNWInt("AGPZPMs")
			draw.SimpleText(string.format(AGP.L("agp_ui_crystals_d_s_4_energy_d", "Crystals %d%s / 4    Energy %d %%"), e:GetNWInt("AGPCrystals"), z > 0 and (" " .. AGP.L("agp_ui_zpm", "+ ZPM") .. " " .. z) or "", math.Round(e:GetNWFloat("AGPCharge"))), "DermaDefault", x + 10, y + 30, Color(200, 160, 80))
		elseif (e:GetClass() == "agp_goauld_power_crystal") then
			draw.RoundedBox(6, x, y, 200, 56, Color(10, 8, 4, 220))
			draw.SimpleText(AGP.L("agp_ui_goauld_power_crystal", "GOA'ULD POWER CRYSTAL"), "DermaDefaultBold", x + 10, y + 8, Color(230, 182, 74))
			draw.SimpleText(string.format(AGP.L("agp_ui_charge_d", "Charge %d %%"), math.Round(e:GetCharge() * 100)), "DermaDefault", x + 10, y + 30, Color(200, 160, 80))
		end
	end)
end
