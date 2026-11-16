--[[
	Shield Core Buble
	Copyright (C) 2011 Madman07
]]--

include('shared.lua');
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
language.Add("tokra_shield",SGLanguage.GetMessage("tshield_desc"));
end
include("box.lua")
include("bullets.lua");

if (StarGate==nil or StarGate.Trace==nil) then return end
StarGate.Trace:Add("tokra_shield",
	function(e,values,trace,in_box)
		return true;
	end
);

function ENT:Initialize()
	self.Created = false;
	self.RayModel = {};
	self.DrawMesh = false;
end

function ENT:Think()
	if (self:GetNetworkedBool("DoClientSide", false) and not self.Created) then
		self.Created = true
		self:DoCollision();
	end
end

function ENT:DoCollision()
	-- AGP: the same turned slab as on the server (tokra_shield/init.lua CreateCollision), so traces match
	local mins, maxs = self:GetNWVector("WallMins", Vector(0,0,0)), self:GetNWVector("WallMaxs", Vector(0,0,0))
	if (maxs.x - mins.x < 1) then self.Created = false return end
	self.Entity:PhysicsInitBox(mins, maxs);
	self.Entity:EnableCustomCollisions(true);
	self.Entity:SetCollisionBounds(mins, maxs);
end
