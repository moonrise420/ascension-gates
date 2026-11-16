--[[
	Braziers
	Copyright (C) 2010 Madman07
]]--

ENT.Type = "anim"
ENT.Base = "base_anim"
if (StarGate!=nil and StarGate.LifeSupportAndWire!=nil) then StarGate.LifeSupportAndWire(ENT); end
ENT.PrintName = "Braziers"
ENT.Author = "Madman07, Rafael De Jongh"
ENT.Category = "Ascension Gates"

ENT.Spawnable = false
ENT.AdminSpawnable = false

if SERVER then

if (StarGate==nil or StarGate.CheckModule==nil or not StarGate.CheckModule("extra")) then return end
AddCSLuaFile();

function ENT:Initialize()

	self.Entity:SetName("Brazier");
	self.Entity:PhysicsInit(SOLID_VPHYSICS);
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS);
	self.Entity:SetSolid(SOLID_VPHYSICS);

	self:CreateWireInputs("Disable Fire","Toggle")
	self:CreateWireOutputs("Fire ON")

	self.Act = "5";
	if string.find(self.Entity:GetModel(), "ori") then self.Pos = Vector(0,0,self.Entity:OBBMaxs().z-25);
	else self.Pos = Vector(0,0,self.Entity:OBBMaxs().z); end

	self.Entity:MakeFire();
	self.Entity:Light();
	self:SetWire("Fire ON",true);
	self.Entity:SetUseType(SIMPLE_USE);

end

-- AGP 2026-10-30: E (and the wire input "Toggle") puts the fire out or lights it again
function ENT:SetBrazierFire(on)
	if (on) then
		self.Entity:MakeFire();
		self.Entity:Light();
		self.Entity:EmitSound("ambient/fire/ignite.wav",60);
	else
		if IsValid(self.FireEnt) then self.FireEnt:Remove() end
		if IsValid(self.LampEnt) then self.LampEnt:Remove() end
		self.Entity:EmitSound("ambient/fire/mtov_flame2.wav",60);
	end
	self:SetWire("Fire ON",on);
end

function ENT:Use(ply)
	if ((self.NextToggle or 0) > CurTime()) then return end
	self.NextToggle = CurTime()+0.5;
	self:SetBrazierFire(not IsValid(self.FireEnt));
end

function ENT:TriggerInput(k,v)
	if (k=="Disable Fire") then
		self:SetBrazierFire(v<=0);
	elseif (k=="Toggle" and v>0) then
		self:SetBrazierFire(not IsValid(self.FireEnt));
	end
end

function ENT:MakeFire()
	if (IsValid(self.FireEnt)) then return end
    local fire = ents.Create("env_fire");

	fire:SetKeyValue("health","5");
    fire:SetKeyValue("firesize",self.Act);
    fire:SetKeyValue("fireattack","1");
    fire:SetKeyValue("damagescale","5");
    fire:SetKeyValue("spawnflags","159");

	fire:SetPos(self.Entity:LocalToWorld(self.Pos));
    fire:Spawn();
    fire:Activate();
	fire:Fire("StartFire","",0);
	fire:SetParent(self.Entity);
	self.FireEnt = fire;
end

function ENT:Light()
	if (IsValid(self.LampEnt)) then return end
	local lamp = ents.Create( "gmod_light" )
	if (not IsValid(lamp)) then self:Remove(); return end

	lamp:SetColor(Color(255, 128, 0))
	if (lamp.SetBrightness) then
		lamp:SetBrightness(2)
		lamp:SetLightSize(200)
	end

	lamp:SetPos(self.Entity:LocalToWorld(self.Pos));
	lamp:Spawn()
	lamp:Toggle()
	lamp:SetRenderMode(RENDERMODE_NONE);
	lamp:SetParent(self.Entity);
	lamp:SetSolid(SOLID_NONE);

	self.LampEnt = lamp;
end

function ENT:OnRemove()
    if IsValid(self.FireEnt) then
	    self.FireEnt:Remove()
	end
	if IsValid(self.LampEnt) then
	    self.LampEnt:Remove()
	end
end

end