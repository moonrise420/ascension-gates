--[[
	Shield Core Buble
	Copyright (C) 2011 Madman07
]]--

include('shared.lua');
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
language.Add("shield_core_buble",SGLanguage.GetMessage("ship_core_buble"));
end

include("modules/sphere.lua")
include("modules/box.lua")
include("modules/atlantis.lua")
include("modules/bullets.lua");

-- AGP: the traceline condition is in shared.lua (the two old ones here used server-only functions and errored)

function ENT:Initialize()
	self.Created = false;
	self.RayModel = {};
	self:SetCustomCollisionCheck(true);
	self.AGPAllowedIdx = {};
end

-- the bubble entity itself is invisible (the bubble graphic is the shield_core_flash / _atl effect)
function ENT:Draw() end
function ENT:DrawTranslucent() end

function ENT:Think()
	if (self:GetNWBool("DoPhysicClientside", false) and not self.Created) then
		self.Created = true
		self:SetCollisionScale()
	end

	-- AGP: the client's copy of the mesh follows the bubble (the core can be moved), for predicted movement
	local ph = self:GetPhysicsObject()
	if (IsValid(ph)) then
		ph:SetPos(self:GetPos())
		ph:SetAngles(self:GetAngles())
		ph:EnableMotion(false)
		ph:Sleep()
	end

	-- AGP: who may pass, from the networked values (same rule as on the server, see shared.lua)
	local en = self:GetNWBool("Enabled", false) and not self:GetNWBool("depleted", false)
	local ids = self:GetNWString("NoCollideID", "")
	local imm = self:GetNWBool("Immunity", false)
	local own = self:GetNWEntity("Own")
	if (en ~= self.AGPEnabled or ids ~= self.AGPIdsStr or imm ~= self.AGPImm or own ~= self.AGPOwn) then
		self.AGPEnabled = en
		self.AGPImm = imm
		self.AGPOwn = own
		if (ids ~= self.AGPIdsStr) then
			self.AGPIdsStr = ids
			local set = {}
			for _, s in ipairs(string.Explode(" ", ids)) do
				local n = tonumber(s)
				if (n) then set[n] = true end
			end
			self.AGPAllowedIdx = set
		end
		self:CollisionRulesChanged()
	end

	-- AGP: the Atlantis-style bubble look stays while the shield is up, also for players who were far away when
	-- it went up (the server's effect only reaches players nearby)
	if (en) then
		local core = self:GetNWEntity("AGPCore")
		if (IsValid(core) and core:GetNWBool("AGPDraw", false)) then
			local fx = core.AGPFx
			if (not (fx and IsValid(fx) and fx.AGPOn and not fx.Dead) and CurTime() > (self.AGPFxTry or 0)) then
				self.AGPFxTry = CurTime() + 1.5
				local d = EffectData()
				d:SetEntity(core)
				d:SetOrigin(core:GetPos())
				d:SetMagnitude(1)
				util.Effect("shield_core_flash_atl", d)
			end
		end
	end
end

function ENT:SetCollisionScale()
	local model = self:GetNWInt("PhysicModel", 1);
	local size = self:GetNWVector("PhysicScale", Vector(1,1,1));

	local vect, vec;
	local convex = {}
	local ShieldModel;

	if (model == 1) then ShieldModel = SphereModel;
	elseif (model == 2) then ShieldModel = BoxModel;
	elseif (model == 3) then ShieldModel = AtlantisModel; end
	if (not ShieldModel) then return end

	for _, vertex in pairs(ShieldModel) do
		vec = Vector(vertex.x*size.x,vertex.y*size.y,vertex.z*size.z);
		vect = Vertex(vec, 1, 1, Vector( 0, 0, 1 ) )
		table.insert(convex, vect);
		table.insert(self.RayModel, vec);
	end

	if (#convex == 0) then return end //safefail

	self.Entity:PhysicsFromMesh(convex);
	self.Entity:EnableCustomCollisions(true); -- AGP: same as the server (traces and movement use the mesh)
	local ph = self:GetPhysicsObject()
	if (IsValid(ph)) then ph:EnableMotion(false) end

	self.ShShap = model;
	self.Size = size;
end
