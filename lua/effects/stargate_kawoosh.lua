/*
	Stargate Kawoosh for GarrysMod10
	Copyright (C) 2007-2008  Zup & aVoN

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

--################### Init @aVoN
function EFFECT:Init(data)
	local e = data:GetEntity();
	if(not (IsValid(e))) then return end;
	local mdl = e:GetModel();
	if(not (mdl and mdl ~= "" and mdl ~= "models/error.mdl")) then return end; -- Stops crashing ppl
	local pos = e:GetPos();
	self.Entity:SetPos(pos);
	self.Entity:SetParent(e);

	local Universe = util.tobool(math.Round(data:GetRadius()));
	local KawooshData = e.KawooshTypes[e.KawooshTypesFX[math.Round(data:GetMagnitude())]].KawooshData

	if StarGate.VisualsMisc("cl_kawoosh_material",true) then
		self.Smoke = ("particle/Smoke01_L"..(Universe and "_U" or ""))
	else
		self.Smoke = ("particle/Smoke01_G")
	end

	self.Data = KawooshData

	local emitter = ParticleEmitter(pos);
	local ang = e:GetAngles(); ang.p = ang.p + 90;
	local startsize = self.Data.Size*((self.Data.GrowCoefficient^1.5 - 1)*self.Data.Density/self.Data.Density + 1);
	local forward = e:GetForward();
	local mul = 2/self.Data.Time; -- Multiplies the velocity and gravity of the particles if we change the speed
	-- AGP: filmed frame by frame the vortex appeared in ONE frame as a ring-sized cone and was cut off in ONE frame while still
	-- a cone a quarter of its size (all particles die together; the refracting smoke cannot fade). Every gate type had this,
	-- the Supergate only showed it most. Now, unless a type says KawooshData.Smooth = false, the vortex starts flat IN the
	-- horizon, swells out of it, and at the end sinks back into it and shrinks before it is gone: the cone's depth becomes
	-- part of the flight instead of where the particles start and end.
	--
	local smooth = self.Data.Smooth ~= false;
	local born, die = CurTime(), self.Data.Time+0.05;
	local IN, OUT = 0.07, 0.86; -- share of the life: swelling up to here, shrinking from here
	--################### Add out particles
	for i=0,self.Data.Density do
		local ParticleDensity = i/self.Data.Density;
		local rad = math.rad(math.Rand(0,360));
		local radius = math.Rand(0,self.Data.Radius);
		local origin = radius*Vector(math.sin(rad),math.cos(rad),0);
		origin:Rotate(ang) --The angle dosn't seem right as it goes flat when the gate is faceing up and tilted to the side.
		--The GetForward bit in here makes the end of the kawoosh come to a cone like point, giveing it a more rounded look instead of a flat end
		local cone = -i*(radius-self.Data.Radius)/self.Data.Density; -- how far in front of the horizon the cone puts this particle
		local particle = emitter:Add(self.Smoke,origin + pos + (smooth and 0 or cone)*forward);
		if(particle) then
			particle:SetDieTime(self.Data.Time+0.05);
			particle:SetStartAlpha(255);
			particle:SetEndAlpha(0);

			local endsize = self.Data.Size*(ParticleDensity*(self.Data.GrowCoefficient^2.2 - 1) + 1);
			particle:SetStartSize(startsize);
			particle:SetEndSize(endsize);
			if (smooth) then
				particle:SetStartSize(startsize*0.3);
				particle:SetEndSize(startsize*0.3);
				particle:SetThinkFunction(function(p)
					local u = math.Clamp((CurTime()-born)/die,0,1);
					local env;
					if (u < IN) then
						env = 0.3 + 0.7*(u/IN);
					elseif (u > OUT) then
						local k = (u-OUT)/(1-OUT);
						env = 1 - 0.9*k*k*(3-2*k);
					else
						-- the middle is the engine's own straight growth: no think needed until the shrinking begins
						p:SetStartSize(startsize); p:SetEndSize(endsize);
						p:SetNextThink(born+die*OUT);
						return;
					end
					local s = (startsize + (endsize-startsize)*u)*env;
					p:SetStartSize(s); p:SetEndSize(s);
					p:SetNextThink(CurTime());
				end);
				particle:SetNextThink(CurTime());
			end

			particle:SetRoll(math.Rand((-1*self.Data.Roll),self.Data.Roll)); --The starting rolled angle
			particle:SetRollDelta(math.Rand((-1*self.Data.RollS),self.Data.RollS)); --How fast it rolls
			-- (flight: x = v*t*(1 - t/Time) - out and back to the horizon in Time, furthest v*Time/4 at half time. Smooth: the cone's
			-- depth is reached at half time too, on top of that)
			local v = self.Data.Length*ParticleDensity + (smooth and 4*cone/self.Data.Time or 0);
			particle:SetGravity(-1*forward*v*mul);
			particle:SetVelocity(forward*v);
			if (Universe) then
				particle:SetColor(209,218,234);
			else
				particle:SetColor(180,225,255);
			end
			--180,225,255
			--200,235,255 to light
		end
	end
	-- Fixes drawing issues
	local offset = Vector(1,1,1)*512;
	self.Entity:SetRenderBounds(-1*offset,offset);
end

function EFFECT:Think() return false end; -- Make it die instantly
function EFFECT:Render() end
