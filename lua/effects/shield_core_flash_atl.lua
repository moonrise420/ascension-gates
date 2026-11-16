--[[
	Shield Core flash effect Atlantis
	Copyright (C) 2011 Madman07
]]--

EFFECT.Atlantis = Material("effects/atlantisa");
EFFECT.Refract = Material("effects/atlantisb");

-- AGP: model size at scale 1 (the effect is scaled with a matrix, so its render bounds must be scaled too, or the
-- bubble is culled when its small unscaled box is out of view: it vanished when standing inside near the edge)
local function modelBounds(mod)
	if (string.find(string.lower(mod or ""), "atlantis", 1, true)) then return Vector(-281,-281,-2), Vector(281,281,211) end
	return Vector(-202,-202,-202), Vector(202,202,202)
end

function EFFECT:Init(data)
	local ent = data:GetEntity();
	if (not IsValid(ent)) then self.Dead = true return end
	self.Status = data:GetMagnitude();
	self.AGPOn = self.Status > 0.5;

	-- AGP: one bubble per core. A second "on" while one is shown is dropped; "off" ends the shown one.
	local prev = ent.AGPFx;
	local look = tostring(ent:GetNWVector("Size")) .. ent:GetNWString("Mod") .. tostring(ent:GetNWVector("Pos")) .. tostring(ent:GetNWAngle("Ang"));
	if (prev and IsValid(prev) and prev ~= self and not prev.Dead) then
		if (self.AGPOn and prev.AGPOn and prev.AGPLook == look) then self.Dead = true return end -- same bubble already shown
		prev.Dead = true;
	end
	self.AGPLook = look;
	ent.AGPFx = self; -- (ShieldBubble is the normal look's flash, shield_core_flash.lua)

	self.Siz = ent:GetNetworkedVector("Size", Vector(100,100,100)) - Vector(10,10,10);
	self.Siz = self.Siz/512;
	self.Mod = ent:GetNWString("Mod");
	if (self.Mod == "") then self.Mod = "models/Madman07/shields/sphere.mdl" end
	self.Ang = ent:GetNWAngle("Ang", Angle(0,0,0));
	self.Pos = ent:GetNWVector("Pos", Vector(0,0,0));

	self.Entity:SetModel(Model(self.Mod));
	self.Entity:SetPos(ent:LocalToWorld(self.Pos));
	self.Entity:SetAngles(ent:GetAngles()+self.Ang);
	self.Entity:SetRenderMode( RENDERMODE_TRANSALPHA );

	local mn, mx = modelBounds(self.Mod);
	self.MN, self.MX = mn, mx;
	self.Entity:SetRenderBounds(Vector(mn.x*self.Siz.x, mn.y*self.Siz.y, mn.z*self.Siz.z) - Vector(16,16,16), Vector(mx.x*self.Siz.x, mx.y*self.Siz.y, mx.z*self.Siz.z) + Vector(16,16,16));

	self.Time = 5;
	self.Born = CurTime();
	self.LifeTime = CurTime() + self.Time;
	self.Normal = Vector(0,0,-1);

	self.Parent = ent;
	self.Draw = true;
end

function EFFECT:Think()
	if (self.Dead or not IsValid(self.Parent)) then return false end
	if (self.Parent.AGPFx ~= self) then return false end -- replaced by a newer one
	if (self.AGPOn) then
		self.Pos = self.Parent:GetNWVector("Pos", self.Pos); -- (position/angles from the editor while it is shown)
		self.Ang = self.Parent:GetNWAngle("Ang", self.Ang);
		-- AGP: stays only while the bubble is really up (it stayed forever when the bubble was removed or rebuilt)
		if (CurTime() > self.Born + 1) then
			local b = self.Parent:GetNWEntity("AGPBubble");
			if (not IsValid(b) or not b:GetNWBool("Enabled", false) or b:GetNWBool("depleted", false) or not self.Parent:GetNWBool("AGPDraw", true)) then
				self.Dead = true;
				return false
			end
		end
		return true
	end
	return self.LifeTime > CurTime() -- the off animation, then gone
end

function EFFECT:Render()
	if (self.Dead) then return end
	if self.Draw then
		if not IsValid(self.Parent) then return end

		self.Entity:SetPos(self.Parent:LocalToWorld(self.Pos));
		self.Entity:SetAngles(self.Parent:GetAngles()+self.Ang);

		local mat = Matrix()
		mat:Scale(self.Siz)
		self.Entity:EnableMatrix( "RenderMultiply", mat )

		local mn = Vector(self.MN.x*self.Siz.x, self.MN.y*self.Siz.y, self.MN.z*self.Siz.z);
		local mx = Vector(self.MX.x*self.Siz.x, self.MX.y*self.Siz.y, self.MX.z*self.Siz.z);

		local Bottom =  self:GetPos() + mn;
		local Top = self:GetPos() + mx;

		local Fraction = (self.LifeTime - CurTime()) / self.Time;
		Fraction = math.Clamp( Fraction, 0, 1 );
		local Lerped = Vector(1,1,1);

		if (self.Status > 0.5) then
			Lerped = LerpVector( Fraction, Top, Bottom);
		else
			Lerped = LerpVector( Fraction, Bottom, Top);
			if (Fraction <= 0) then return end -- AGP: fully gone at the end of the off animation
		end

		local distance = self.Normal:Dot(Vector(0,0,Lerped.z));

		self:SetRenderClipPlaneEnabled(true);
		self:SetRenderClipPlane(self.Normal, distance);


		if StarGate.VisualsMisc("cl_shieldcore_refract") then
			render.MaterialOverride(self.Refract);
			self.Entity:DrawModel();
		end

		render.MaterialOverride(self.Atlantis)
		self.Entity:SetColor(Color(255,255,255,128));
		self.Entity:DrawModel();

		render.MaterialOverride(nil);
	end
end
