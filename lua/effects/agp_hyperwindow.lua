-- Ascension Gates: hyperspace window (Goa'uld style) - a swirling blue-white window that opens, holds and closes.
-- data: origin = centre, normal = facing, scale = radius (units), magnitude = lifetime (s)
local GLOW = Material("sprites/light_glow02_add")
local RING = Material("effects/select_ring")

function EFFECT:Init(data)
	self.Pos = data:GetOrigin()
	self.Normal = data:GetNormal()
	self.Radius = math.max(data:GetScale(), 100)
	self.Life = math.max(data:GetMagnitude(), 1)
	self.Start = CurTime()
	self:SetRenderBoundsWS(self.Pos - Vector(1, 1, 1) * self.Radius * 1.5, self.Pos + Vector(1, 1, 1) * self.Radius * 1.5)
	self.Emitter = ParticleEmitter(self.Pos)
	self.NextEmit = 0
end

-- 0..1 open amount: opens fast, holds, closes fast
function EFFECT:Open()
	local t = (CurTime() - self.Start) / self.Life
	if (t < 0.2) then return t / 0.2 end
	if (t > 0.8) then return math.max(0, (1 - t) / 0.2) end
	return 1
end

function EFFECT:Think()
	if (CurTime() - self.Start > self.Life) then
		if (self.Emitter) then self.Emitter:Finish() end
		return false
	end
	-- particles spiralling into the window
	if (self.Emitter and CurTime() > self.NextEmit) then
		self.NextEmit = CurTime() + 0.02
		local o = self:Open()
		local ang = self.Normal:Angle()
		for i = 1, 6 do
			local a = math.random() * math.pi * 2
			local r = self.Radius * o * (0.6 + math.random() * 0.5)
			local off = ang:Right() * math.cos(a) * r + ang:Up() * math.sin(a) * r
			local p = self.Emitter:Add("sprites/light_glow02_add", self.Pos + off)
			if (p) then
				local tangent = ang:Right() * -math.sin(a) + ang:Up() * math.cos(a)
				p:SetVelocity(-off * 0.9 + tangent * r * 1.2 - self.Normal * self.Radius * 0.3)
				p:SetDieTime(0.8)
				p:SetStartAlpha(220); p:SetEndAlpha(0)
				p:SetStartSize(self.Radius * 0.08); p:SetEndSize(self.Radius * 0.02)
				p:SetColor(170, 200, 255)
				p:SetAirResistance(0)
			end
		end
	end
	return true
end

function EFFECT:Render()
	local o = self:Open()
	if (o <= 0) then return end
	local r = self.Radius * o
	local spin = (CurTime() - self.Start) * 90
	render.SetMaterial(GLOW)
	render.DrawQuadEasy(self.Pos, self.Normal, r * 2.4, r * 2.4, Color(150, 190, 255, 230 * o), spin)
	render.DrawQuadEasy(self.Pos, -self.Normal, r * 2.4, r * 2.4, Color(150, 190, 255, 230 * o), -spin)
	render.DrawQuadEasy(self.Pos, self.Normal, r * 1.2, r * 1.2, Color(255, 255, 255, 255 * o), 0)
	render.DrawQuadEasy(self.Pos, -self.Normal, r * 1.2, r * 1.2, Color(255, 255, 255, 255 * o), 0)
	render.SetMaterial(RING)
	for i = 1, 3 do
		local rr = r * (0.7 + i * 0.25)
		render.DrawQuadEasy(self.Pos, self.Normal, rr * 2, rr * 2, Color(120, 170, 255, 150 * o), spin * i)
		render.DrawQuadEasy(self.Pos, -self.Normal, rr * 2, rr * 2, Color(120, 170, 255, 150 * o), -spin * i)
	end
end
