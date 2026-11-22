--[[
	Goa'uld door (Ascension Gates)
	Two heavy panels that slide apart, any size (corridor door, hangar door). For the sizes the ships use they are real
	props with their own collision (agp_door_panel, gold Goa'uld panels); other sizes draw two wall-texture panels.
	Use (E) or Wire: Open (1 open / 0 close), Toggle (each press), Lock. Outputs: Open, Locked.
	Solid only while closed; it does not close on someone standing in the doorway.
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then StarGate.LifeSupportAndWire(ENT) end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Goa'uld Door"
ENT.Author = "Ascension Gates"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Goa'uld Door"
ENT.Spawnable = false   -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
list.Set("CAP.Entity", ENT.PrintName, ENT)
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.PanelModel = "models/hunter/blocks/cube1x1x1.mdl"   -- 47.45 units, centred; scaled per panel
ENT.PanelMaterial = "models/sgw/hatak/hatakwalldiffuse"
ENT.MoveTime = 1.6

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "DoorWidth")
	self:NetworkVar("Float", 1, "DoorHeight")
	self:NetworkVar("Float", 2, "DoorThick")
	self:NetworkVar("Float", 3, "MoveStart")    -- CurTime when the last movement started
	self:NetworkVar("Bool", 0, "Opened")         -- target state
	self:NetworkVar("Bool", 1, "Locked")
end

-- the real panel model for this door's size, if there is one
function ENT:RealPanelModel(w, h, t)
	local m = string.format("models/agp/hatak/props/door_%dx%dx%d.mdl", math.floor(w / 2) + 1, math.Round(h), math.Round(t))
	return file.Exists(m, "GAME") and m or nil
end

-- how far open, 0..1, the same on server and client
function ENT:OpenFraction()
	local t = math.Clamp((CurTime() - self:GetMoveStart()) / self.MoveTime, 0, 1)
	t = t * t * (3 - 2 * t)   -- slow start, slow stop
	return self:GetOpened() and t or 1 - t
end

if SERVER then
	AddCSLuaFile()

	ENT.Sounds = {
		Open = Sound("teltak/teltak_centerdoor_open.wav"),
		Close = Sound("teltak/teltak_centerdoor_close.wav"),
		HangarOpen = Sound("tech/hangar_door.wav"),
		Locked = Sound("button/ring_button2.mp3"),
	}

	function ENT:SpawnFunction(ply, tr)
		if (not tr.Hit) then return end
		local e = ents.Create("agp_goauld_door")
		e:SetPos(tr.HitPos)
		local ang = ply:GetAimVector():Angle()
		e:SetAngles(Angle(0, ang.y, 0))
		e:Setup(112, 112, 10)
		e:Spawn(); e:Activate()
		e.Owner = ply
		if (e.CPPISetOwner) then e:CPPISetOwner(ply) end
		local ph = e:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(false) end
		return e
	end

	-- size of the doorway (units); call before Spawn or any time later
	function ENT:Setup(w, h, thick, hangar)
		self.SetupSize = { w, h, thick or 10 }
		self.Hangar = hangar and true or false
		if (self:EntIndex() > 0 and self.Initialized) then self:BuildPhysics() end
	end

	function ENT:BuildPhysics()
		local w, h, t = unpack(self.SetupSize or { 112, 112, 10 })
		self:SetDoorWidth(w); self:SetDoorHeight(h); self:SetDoorThick(t)
		local frozen = IsValid(self:GetPhysicsObject()) and not self:GetPhysicsObject():IsMotionEnabled()
		self:PhysicsInitBox(Vector(-t / 2, -w / 2, 0), Vector(t / 2, w / 2, h))
		self:SetCollisionBounds(Vector(-t / 2, -w / 2, 0), Vector(t / 2, w / 2, h))
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then
			ph:SetMass(math.Clamp(w * h * t / 200, 50, 50000))
			ph:SetMaterial("metal")
			if (frozen) then ph:EnableMotion(false) end
		end
		self:BuildPanels(w, h, t)
		self:UpdateSolid()
	end

	-- the two real panels (props with their own collision); the door itself is then only their frame, not solid
	function ENT:BuildPanels(w, h, t)
		for _, p in ipairs(self.RealPanels or {}) do if (IsValid(p)) then p:Remove() end end
		self.RealPanels = nil
		local mdl = self:RealPanelModel(w, h, t)
		self:SetNWBool("AGPRealPanels", mdl ~= nil)
		if (not mdl) then return end
		self.RealPanels = {}
		for i, side in ipairs({ 1, -1 }) do
			local p = ents.Create("agp_door_panel")
			if (IsValid(p)) then p.DoNotDuplicate = true end   -- (built by its parent, which builds it again after a save or a paste - copied as well it was there twice)
			if (IsValid(p)) then
				p:SetModel(mdl)
				p:SetSide(side)
				p:SetPos(self:LocalToWorld(p:SlidePos(self))); p:SetAngles(self:GetAngles())
				p:Spawn(); p:Activate()
				p:SetParent(self)
				p.Owner = self.Owner
				self.RealPanels[i] = p
			end
		end
	end

	function ENT:Initialize()
		self:SetModel(self.PanelModel)   -- only for the entity itself; the panels are drawn on the client
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:SetMoveStart(-100)
		self:SetOpened(false)
		self:SetLocked(false)
		self:CreateWireInputs("Open", "Toggle", "Lock")
		self:CreateWireOutputs("Open", "Locked")
		self.Initialized = true
		self:BuildPhysics()
	end

	-- solid while closed or moving; not solid once fully open
	function ENT:UpdateSolid()
		local open = self:GetOpened() and self:OpenFraction() >= 1
		if (self.RealPanels) then
			self:SetNotSolid(true)
			for _, p in ipairs(self.RealPanels) do
				if (IsValid(p)) then
					p:SetLocalPos(p:SlidePos(self)); p:SetLocalAngles(Angle(0, 0, 0))
					p:SetNotSolid(open)
					local pph = p:GetPhysicsObject(); if (IsValid(pph)) then pph:EnableCollisions(not open) end
					if (p.AGPShip ~= self.AGPShip) then p.AGPShip = self.AGPShip end
					if (p.CPPISetOwner and self.CPPIGetOwner and IsValid(self:CPPIGetOwner()) and p:CPPIGetOwner() ~= self:CPPIGetOwner()) then p:CPPISetOwner(self:CPPIGetOwner()) end
				end
			end
			local ph = self:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableCollisions(false) end
			return
		end
		self:SetNotSolid(open)
		self:SetCollisionGroup(open and COLLISION_GROUP_WORLD or COLLISION_GROUP_NONE)
		local ph = self:GetPhysicsObject()   -- physics objects (a glider flying through) collide with the body itself
		if (IsValid(ph)) then ph:EnableCollisions(not open) end
	end

	function ENT:DoorwayBlocked()
		local w, h, t = self:GetDoorWidth(), self:GetDoorHeight(), self:GetDoorThick()
		local mn = self:LocalToWorld(Vector(-t / 2 - 18, -w / 2, 0))
		local mx = self:LocalToWorld(Vector(t / 2 + 18, w / 2, h))
		local a = Vector(math.min(mn.x, mx.x), math.min(mn.y, mx.y), math.min(mn.z, mx.z))
		local b = Vector(math.max(mn.x, mx.x), math.max(mn.y, mx.y), math.max(mn.z, mx.z))
		for _, e in ipairs(ents.FindInBox(a, b)) do
			if (e:IsPlayer() or e:IsNPC()) then
				local l = self:WorldToLocal(e:GetPos())
				-- really inside the door's slab (a player is 32 wide): standing at the door and pressing E does not count
				if (math.abs(l.y) < w / 2 + 8 and math.abs(l.x) < t / 2 + 10) then return true end
			end
		end
		return false
	end

	function ENT:SetDoorOpen(open, quiet)
		open = open and true or false
		if (open == self:GetOpened()) then return true end
		if (self:GetLocked()) then
			if (not quiet) then self:EmitSound(self.Sounds.Locked, 70) end
			return false
		end
		local twin = IsValid(self.AGPTwin) and self.AGPTwin or nil   -- a door linked to this one (Ha'tak hangar: hull + interior)
		if (not open and (self:DoorwayBlocked() or (twin and twin:DoorwayBlocked()))) then
			self.CloseWhenFree = true   -- someone stands in the doorway: close as soon as he is gone
			return false
		end
		self.CloseWhenFree = nil
		-- reverse from where it is now
		local f = self:OpenFraction()
		local remaining = open and (1 - f) or f
		self:SetMoveStart(CurTime() - (1 - remaining) * self.MoveTime)
		self:SetOpened(open)
		if (self.Hangar) then
			self:EmitSound(self.Sounds.HangarOpen, 90)
		else
			self:EmitSound(open and self.Sounds.Open or self.Sounds.Close, 80)
		end
		self:SetWire("Open", open and 1 or 0)
		self:UpdateSolid()
		if (twin and twin:GetOpened() ~= open) then twin:SetLocked(false); twin:SetDoorOpen(open, true) end
		return true
	end

	hook.Add("KeyPress", "AGP.GoauldDoorUse", function(ply, key)
		if (key ~= IN_USE or not ply:Alive() or ply:InVehicle()) then return end
		local eye, dir = ply:EyePos(), ply:GetAimVector()
		local best, bd
		for _, d in ipairs(ents.FindInSphere(eye, 500)) do
			if (d:GetClass() == "agp_goauld_door" and d:GetOpened()) then
				local n = d:GetForward()
				local den = dir:Dot(n)
				if (math.abs(den) > 0.05) then
					local t = (d:GetPos() - eye):Dot(n) / den
					if (t > 0 and t < 160 and (not bd or t < bd)) then
						local l = d:WorldToLocal(eye + dir * t)
						if (math.abs(l.y) < d:GetDoorWidth() / 2 and l.z > 0 and l.z < d:GetDoorHeight()) then best, bd = d, t end
					end
				end
			end
		end
		if (not IsValid(best)) then return end
		local ship = best.AGPShip
		if (IsValid(ship) and ship.DoorPanelUse) then ship:DoorPanelUse(best, ply) else best:Use(ply, ply) end
	end)

	function ENT:Use(ply)
		if (self.NextUse and self.NextUse > CurTime()) then return end
		self.NextUse = CurTime() + 0.5
		self:SetDoorOpen(not self:GetOpened())
	end

	function ENT:TriggerInput(k, v)
		if (k == "Open") then
			self:SetDoorOpen(v > 0)
		elseif (k == "Toggle") then
			if (v > 0) then self:SetDoorOpen(not self:GetOpened()) end
		elseif (k == "Lock") then
			self:SetLocked(v > 0)
			self:SetWire("Locked", v > 0 and 1 or 0)
		end
	end

	function ENT:Think()
		self:UpdateSolid()
		if (self.CloseWhenFree and not self:DoorwayBlocked()) then self:SetDoorOpen(false, true) end
		-- every tick while the panels move, else ten times a second
		local moving = self.RealPanels and CurTime() - self:GetMoveStart() < self.MoveTime + 0.1
		self:NextThink(CurTime() + (moving and 0 or 0.1))
		return true
	end

	function ENT:PreEntityCopy()
		duplicator.StoreEntityModifier(self, "AGPGoauldDoor", { size = { self:GetDoorWidth(), self:GetDoorHeight(), self:GetDoorThick() }, hangar = self.Hangar, locked = self:GetLocked() })
		if (StarGate.WireRD and StarGate.WireRD.PreEntityCopy) then StarGate.WireRD.PreEntityCopy(self) end
	end

	function ENT:PostEntityPaste(ply, ent, created)
		local d = ent.EntityMods and ent.EntityMods.AGPGoauldDoor
		if (d) then
			local function c(v) v = tonumber(v) or 64 if (v ~= v) then v = 64 end return math.Clamp(v, 1, 4096) end -- AGP: no 0 / huge physics box from a dupe
			self:Setup(c(d.size and d.size[1]), c(d.size and d.size[2]), c(d.size and d.size[3]), d.hangar)
			self:BuildPhysics()
			self:SetLocked(d.locked and true or false)
		end
		if (StarGate.WireRD and StarGate.WireRD.PostEntityPaste) then StarGate.WireRD.PostEntityPaste(self, ply, ent, created) end
	end
end

if CLIENT then
	local CUBE = 47.45

	function ENT:Initialize()
		self.Panels = {}
	end

	function ENT:PanelEnts()
		for i = 1, 2 do
			if (not IsValid(self.Panels[i])) then
				local m = ClientsideModel(self.PanelModel, RENDERGROUP_OPAQUE)
				if (not IsValid(m)) then return end
				m:SetNoDraw(true)
				m:SetMaterial(self.PanelMaterial)
				self.Panels[i] = m
			end
		end
		return self.Panels
	end

	function ENT:Think()
		local w, h, t = self:GetDoorWidth(), self:GetDoorHeight(), self:GetDoorThick()
		if (self:GetNWBool("AGPRealPanels")) then self:SetNotSolid(true) return end   -- the panels are real props
		if (w > 0) then
			self:SetRenderBounds(Vector(-t, -w, 0), Vector(t, w, h))
			-- the same collision box as on the server: else the client keeps the helper cube model's collision (an
			-- invisible cube at the door's foot) and lets you walk through the closed door
			if (self.AGPPhysSize ~= w .. "x" .. h .. "x" .. t) then
				self.AGPPhysSize = w .. "x" .. h .. "x" .. t
				self:PhysicsInitBox(Vector(-t / 2, -w / 2, 0), Vector(t / 2, w / 2, h))
				self:SetCollisionBounds(Vector(-t / 2, -w / 2, 0), Vector(t / 2, w / 2, h))
				self:SetSolid(SOLID_VPHYSICS)
				local ph = self:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(false) end
			end
			self:SetNotSolid(self:GetOpened() and self:OpenFraction() >= 1)
		end
	end

	function ENT:Draw()
		if (self:GetNWBool("AGPRealPanels")) then return end
		local par = self:GetParent()   -- a door on a cloaking ship (Ha'tak hull) fades with it
		if (IsValid(par) and par.CloakAlpha and par:CloakAlpha() < 0.5) then return end
		local panels = self:PanelEnts()
		if (not panels) then return end
		local w, h, t = self:GetDoorWidth(), self:GetDoorHeight(), self:GetDoorThick()
		if (w <= 0) then return end
		local f = self:OpenFraction()
		local half = w / 2
		-- the panels disappear into the wall: cut them off at the edges of the doorway
		local ydir = -self:GetRight()
		local c = self:GetPos()
		local oldClip = render.EnableClipping(true)
		render.PushCustomClipPlane(-ydir, (-ydir):Dot(c + ydir * half))
		render.PushCustomClipPlane(ydir, ydir:Dot(c - ydir * half))
		for i, m in ipairs(panels) do
			local side = (i == 1) and 1 or -1
			-- each panel covers half the doorway, slides sideways into the wall
			local y = side * (half / 2 + f * half * 0.98)
			m:SetPos(self:LocalToWorld(Vector(0, y, h / 2)))
			m:SetAngles(self:GetAngles())
			local mat = Matrix()
			mat:Scale(Vector(t / CUBE, (half + 1) / CUBE, h / CUBE))
			m:EnableMatrix("RenderMultiply", mat)
			m:SetupBones()
			m:DrawModel()
		end
		render.PopCustomClipPlane()
		render.PopCustomClipPlane()
		render.EnableClipping(oldClip)
	end

	function ENT:OnRemove()
		for _, m in ipairs(self.Panels or {}) do if (IsValid(m)) then m:Remove() end end
	end
end
