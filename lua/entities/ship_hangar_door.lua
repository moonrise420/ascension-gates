--[[
	Ships Hangar Doors
	Copyright (C) 2011 Madman07
]]--

if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ships Hangar Doors"
ENT.Author = "Madman07"
ENT.Category = "Ascension Gates"
ENT.WireDebugName = "Ships Hangar"

ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AutomaticFrameAdvance = true
ENT.Untouchable = true

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("ship")) then return end
AddCSLuaFile();

ENT.Sounds = {
	Door=Sound("tech/hangar_door.wav"),
}

-----------------------------------INIT----------------------------------

-- AGP: the doors are parented to the hangar and slide on it. They used to remove and re-make a weld to the hangar in
-- every physics update (heavy lag, and an unfrozen hangar floated and turned slowly).
function ENT:Initialize()
	self.Entity:SetName("Ships Hangar Door");
	self.Entity:SetModel("models/Iziraider/capbuild/hangardoor.mdl");
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_NONE);
	self.Entity:SetSolid(SOLID_VPHYSICS);
	self.Entity:SetUseType(SIMPLE_USE);
	local ph = self:GetPhysicsObject()
	if (IsValid(ph)) then ph:EnableMotion(false) end

	self.Open = false;
	self.Opened = false;
	self.Anim = false;
	self.Speed = 5;
	self.DoShake = false;
end

-- closed / open spot on the hangar (local)
function ENT:Spots()
	local center = Vector(self.Factor > 0 and 14.1 or 0, 0, 0)
	return center, center + Vector(0, -self.Factor * 400, 0)
end

-- parent to the hangar and stand at the right spot (spawn and dupe paste)
function ENT:Attach(hangar)
	self.Parent = hangar
	self:SetParent(hangar)
	self:SetLocalAngles(Angle(0, -90 - self.Factor * 90, 0))
	local center, side = self:Spots()
	self:SetLocalPos(self.Open and side or center)
end

function ENT:Toggle()
	if not self.Anim then
		self.ArriveTime = CurTime();
		self.Anim = true;
		self:EmitSound(self.Sounds.Door,100,100);
		self.DoShake = true;
		self.Opened = not self.Opened;
		timer.Create(self.Entity:EntIndex().."DoorMove", self.Speed, 1, function()
			if not IsValid(self) then return end
			self.Anim = false
			self.Open = not self.Open;
			self.DoShake = false;
			local center, side = self:Spots()
			self:SetLocalPos(self.Open and side or center)
		end);
	end
end

function ENT:OnRemove()
	timer.Remove(self.Entity:EntIndex().."DoorMove")
end

function ENT:Think()
	if not IsValid(self.Parent) or not self.Factor then return end
	if self:GetParent() ~= self.Parent then self:Attach(self.Parent) end
	-- the physics copy follows too, so ships (physics props) bump into the closed doors where they are
	local ph = self:GetPhysicsObject()
	if IsValid(ph) and ph:GetPos():DistToSqr(self:GetPos()) > 1 then ph:SetPos(self:GetPos()); ph:SetAngles(self:GetAngles()) end
	if self.Anim then
		if self.DoShake then util.ScreenShake(self:GetPos(),1,10,0.5,300) end
		local center, side = self:Spots()
		local t = math.Clamp((CurTime() - self.ArriveTime) / self.Speed, 0, 1)
		if self.Open then self:SetLocalPos(LerpVector(t, side, center)) else self:SetLocalPos(LerpVector(t, center, side)) end
		self:NextThink(CurTime())
	else
		self:NextThink(CurTime() + 0.5)
	end
	return true
end

if (StarGate and StarGate.CAP_GmodDuplicator) then
	duplicator.RegisterEntityClass( "ship_hangar_door", StarGate.CAP_GmodDuplicator, "Data" )
end

end