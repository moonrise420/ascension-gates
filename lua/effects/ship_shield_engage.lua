/*
	Stargate Shield for GarrysMod10
	Copyright (C) 2007  aVoN

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

EFFECT.Materiala = Material("effects/shielda");
EFFECT.Materialb = Material("effects/shieldb");

--################# Init @aVoN
function EFFECT:Init(data)
	if(not StarGate.VisualsMisc("cl_shield_bubble")) then return end;
	self.Radius = data:GetScale();
	self.Alpha = 0;
	local e = data:GetEntity();
	if(not e:IsValid()) then return end;
	-- Color (also needed for the other shield bubble
	local color = e:GetNetworkedVector("shield_color",Vector(1,1,1));
	self.Color = Color(color.x,color.y,color.z);
	local magnitude = math.ceil(data:GetMagnitude());
	local hit = false;
	if(magnitude == 2) then hit = true end;
	if(magnitude == 1) then self.TurnOff = true end;
	-- We already have one bubble. Do not this effect, rather extend the other older...
	local shield = e.ShieldBubble;
	if(IsValid(shield)) then
		if(self.TurnOff) then
			shield:Remove();
		elseif(hit) then
			if((CurTime()-shield.Created)/shield.LifeTime > 0.04) then
				shield.StartWithFullAlpha = true; -- Start at full alpha instead to avoid ugly side effects
			end
			shield.Created = CurTime();
			self:Remove();
			return;
		end
	end
	e.ShieldBubble = self.Entity;
	-- This above was the old method. Sadly, it looks ugly when the hit effect does the same barrel roll like your ship
	self.JumperLast = false;
	self.IsJumper = false;
	local model = e:GetNWString("shield_model","");
	-- fix: same models as the ship_shield entity (hatak/daedalus/aurora models were never shipped: big bubble instead of ERROR,
	-- and the big ships now get the big bubble here too)
	local function pick(m, fallback) return util.IsValidModel(m) and m or fallback end
	-- AGP: a big ship's own bubble, sized to its hull (see lua/autorun/agp_ship_shield.lua)
	local agpModel = e:GetNWString("AGPShieldModel","");
	if (agpModel ~= "" and util.IsValidModel(agpModel)) then self.Entity:SetModel(agpModel);
	elseif (model == "sg_vehicle_shuttle") then self.Entity:SetModel(pick("models/Madman07/shields/destiny_shield.mdl", "models/zup/shields/1024_shield.mdl"));
	elseif (model == "sg_vehicle_hatak") then self.Entity:SetModel(pick("models/Madman07/shields/hatak_shield.mdl", "models/zup/shields/1024_shield.mdl"));
	elseif (model == "sg_vehicle_daedalus") then self.Entity:SetModel(pick("models/Madman07/shields/daedalus_shield.mdl", "models/zup/shields/1024_shield.mdl"));
	elseif (model == "sg_vehicle_aurora") then self.Entity:SetModel(pick("models/Madman07/shields/aurora_shield.mdl", "models/zup/shields/1024_shield.mdl"));
	elseif (model == "puddle_jumper") then self.IsJumper = true;
	elseif (model == "puddle_jumperv4") then self.IsJumper = true;
	elseif (model == "sg_vehicle_destiny" or model == "sg_vehicle_gateseeder" or model == "sg_vehicle_orims" or model == "sg_vehicle_oneill") then self.Entity:SetModel("models/zup/shields/1024_shield.mdl");
	else self.Entity:SetModel("models/zup/shields/200_shield.mdl"); end
	if self.IsJumper then
		if e:GetNWBool("shield_jumper_open") then
			self.Entity:SetModel("models/Madman07/shields/jumper_shield_open.mdl");
		else
			self.Entity:SetModel("models/Madman07/shields/jumper_shield_close.mdl");
		end
		self.JumperLast = e:GetNWBool("shield_jumper_open");
	end

	self.Entity:SetPos(e:GetPos());
	self.Entity:SetColor(Color(color.x*255,color.y*255,color.z*255,1));
	-- AGP: a stretched bubble (a hull longer than any bubble model, e.g. the Daedalus)
	local sc = e:GetNWVector("AGPShieldScale", Vector(1, 1, 1));
	if (sc ~= Vector(1, 1, 1) and not sc:IsZero()) then
		local m = Matrix(); m:Scale(sc);
		self.Entity:EnableMatrix("RenderMultiply", m);
		local mn, mx = self.Entity:GetModelBounds();
		self.Entity:SetRenderBounds(mn * math.max(sc.x, sc.y, sc.z), mx * math.max(sc.x, sc.y, sc.z));
	end
	self.Entity:SetRenderMode( RENDERMODE_TRANSALPHA );
	self.Draw = true;
	self.Created = CurTime();
	self.LifeTime = 1;
	self.Parent = e;
end

--################# Think @aVoN
function EFFECT:Think()
	if self.IsJumper then
		if(IsValid(self.Parent)) then
			local status = self.Parent:GetNWBool("shield_jumper_open");
			if self.JumperLast != status then
				if status then
					self.Entity:SetModel("models/Madman07/shields/jumper_shield_open.mdl");
				else
				self.Entity:SetModel("models/Madman07/shields/jumper_shield_close.mdl");
				end
				self.JumperLast = status;
			end
		end
	end

	-- AGP 2026-11-12 (owner: an admin setting "ship shields always visible"): the bubble stays, faint, while the shield is up
	self.Hold = GetGlobalBool("AGPShipShieldVisible", false) and not self.TurnOff and IsValid(self.Parent) and not self.Parent:GetNWBool("depleted", false);
	if (self.Hold and self.Draw) then return true end
	return (self.Draw and self.Created + self.LifeTime > CurTime());
end

--################# Render @aVoN
function EFFECT:Render()
	if(not (self.Parent and self.Parent:IsValid())) then self.Draw = nil end;
	if(not self.Draw) then return end;
	self.Entity:SetPos(self.Parent:GetPos()); -- Instead of parenting (look in Init why I'm doing it)
	--################# This is actually the part which makes the effect in different sizes.
	-- It is created a new render target which's size is simply changed
	local multiply = (CurTime()-self.Created)/self.LifeTime;
	if(multiply >= 0) then
		if(self.StartWithFullAlpha and multiply < 0.5) then
			multiply = 0.5;
		end
		local alpha = math.Clamp(math.Clamp(math.sin(multiply*math.pi)*1.3,0,1)*70,1,70);
		local size = self.SizeMultiplier;
		if(self.TurnOff) then
			-- When the shield collapes, we will add a shrinking effect
			alpha = math.Clamp(140*(1-multiply)^10,1,140);
		end
		if (self.Hold and not self.TurnOff) then alpha = math.max(alpha, (multiply > 0.5) and 16 or 1) end -- AGP: the steady glow of "always visible"
		self.Entity:SetColor(Color(self.Color.r*255,self.Color.g*255,self.Color.b*255,alpha));
		-- AGP 2026-11-12 (owner: "in the cockpit, shield on / off is not visible"): the bubble's faces look outward, so an eye
		-- inside it (cockpit, bridge, on foot under the shield) saw nothing - from inside the inner faces are drawn
		local inside = false;
		do
			local mn, mx = self.Entity:GetModelBounds();
			local sc = self.Parent:GetNWVector("AGPShieldScale", Vector(1, 1, 1));
			if (sc:IsZero()) then sc = Vector(1, 1, 1) end
			local l = self.Entity:WorldToLocal(EyePos());
			local rx, ry, rz = math.max(mx.x * sc.x, 1), math.max(mx.y * sc.y, 1), math.max(mx.z * sc.z, 1);
			inside = (l.x / rx) ^ 2 + (l.y / ry) ^ 2 + (l.z / rz) ^ 2 < 1;
		end
		if (inside) then render.CullMode(MATERIAL_CULLMODE_CW) end
		render.MaterialOverride(self.Materiala);
		-- Thanks to catdaemon telling me the existance about this function. Makes everything easier compared with difficult cam3D and normal resize
		self.Entity:SetAngles(self.Parent:GetAngles());
		self.Entity:DrawModel();

		-- Turn off or fail effect
		render.MaterialOverride(self.Materialb);
		self.Entity:SetAngles(self.Parent:GetAngles());
		self.Entity:DrawModel();

		render.MaterialOverride(nil);
		if (inside) then render.CullMode(MATERIAL_CULLMODE_CCW) end
	end
end
