--[[
	Ascension Gates: ship explosion (owner 2026-10-30: the old one was one grey puff for every ship).
	Flash, fireball, shock ring, burning debris and a rising smoke cloud, all scaled to the ship's size.
	data: Origin, Magnitude = radius of the ship, Scale = 1 main blast / < 1 secondary blast along the hull.
]]
local FIRE = { "effects/fire_cloud1", "effects/fire_cloud2" }

function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local r = math.Clamp(data:GetMagnitude(), 60, 4000)
	local main = data:GetScale() >= 1
	local s = r / 300   -- size factor (a Dart is about 1, a Ha'tak about 10)

	local light = DynamicLight(self:EntIndex() + math.random(1, 9999))
	if (light) then
		light.pos = pos
		light.r, light.g, light.b = 255, 170, 80
		light.brightness = main and 6 or 3
		local size = r * (main and 5 or 2.5)   -- a dynamic light's fields can be set but not read back
		light.size = size
		light.decay = size * 1.2
		light.dietime = CurTime() + (main and 1.5 or 0.6)
	end

	local em = ParticleEmitter(pos)
	if (not em) then return end

	-- flash
	local p = em:Add("sprites/light_glow02_add", pos)
	if (p) then
		p:SetDieTime(main and 0.5 or 0.25)
		p:SetStartAlpha(255); p:SetEndAlpha(0)
		p:SetStartSize(r * (main and 2.2 or 1)); p:SetEndSize(r * (main and 4 or 1.6))
		p:SetColor(255, 230, 190)
	end

	-- fireball: fire clouds rolling outwards
	for i = 1, main and 46 or 14 do
		local d = VectorRand():GetNormalized()
		p = em:Add(FIRE[math.random(#FIRE)], pos + d * r * math.Rand(0, 0.35))
		if (p) then
			p:SetVelocity(d * r * math.Rand(1.2, 3) * (main and 1 or 0.6))
			p:SetAirResistance(140)
			p:SetDieTime(math.Rand(0.9, 1.8) * (main and 1.3 or 0.8))
			p:SetStartAlpha(255); p:SetEndAlpha(0)
			p:SetStartSize(r * math.Rand(0.25, 0.45)); p:SetEndSize(r * math.Rand(0.6, 1.0))
			p:SetRoll(math.Rand(0, 360)); p:SetRollDelta(math.Rand(-1.5, 1.5))
			p:SetColor(255, math.random(150, 220), math.random(90, 150))
		end
	end

	if (main) then
		-- shock ring: a flat ring of bright fire racing outwards
		local n = 48
		for i = 1, n do
			local a = i / n * math.pi * 2
			local d = Vector(math.cos(a), math.sin(a), math.Rand(-0.05, 0.05))
			p = em:Add("effects/fire_cloud1", pos)
			if (p) then
				p:SetVelocity(d * r * 6)
				p:SetAirResistance(60)
				p:SetDieTime(0.9)
				p:SetStartAlpha(220); p:SetEndAlpha(0)
				p:SetStartSize(r * 0.12); p:SetEndSize(r * 0.45)
				p:SetColor(255, 210, 160)
			end
		end

		-- burning debris: fast pieces falling with a short glow
		for i = 1, math.Clamp(math.floor(20 * s), 16, 60) do
			local d = VectorRand():GetNormalized()
			p = em:Add("effects/fire_cloud2", pos + d * r * 0.2)
			if (p) then
				p:SetVelocity(d * r * math.Rand(3, 7) + Vector(0, 0, r * 2))
				p:SetGravity(Vector(0, 0, -600))
				p:SetCollide(true); p:SetBounce(0.3)
				p:SetDieTime(math.Rand(2, 3.5))
				p:SetStartAlpha(255); p:SetEndAlpha(0)
				p:SetStartSize(math.Rand(8, 18) * math.max(1, s * 0.6)); p:SetEndSize(2)
				p:SetColor(255, 170, 90)
			end
		end

		-- sparks
		for i = 1, 60 do
			local d = VectorRand():GetNormalized()
			p = em:Add("effects/spark", pos)
			if (p) then
				p:SetVelocity(d * r * math.Rand(4, 9))
				p:SetGravity(Vector(0, 0, -400))
				p:SetDieTime(math.Rand(0.6, 1.4))
				p:SetStartAlpha(255); p:SetEndAlpha(0)
				p:SetStartSize(math.Rand(4, 10) * math.max(1, s * 0.5)); p:SetEndSize(0)
				p:SetStartLength(r * 0.3); p:SetEndLength(0)
				p:SetColor(255, 220, 160)
			end
		end
	end

	-- smoke: dark at first, rising and spreading for a long while
	for i = 1, main and 30 or 8 do
		local d = VectorRand():GetNormalized()
		p = em:Add(main and "particles/smokey" or "particle/particle_smokegrenade", pos + d * r * math.Rand(0, 0.5))
		if (p) then
			p:SetVelocity(d * r * math.Rand(0.4, 1.2) + Vector(0, 0, r * 0.3))
			p:SetAirResistance(80)
			p:SetGravity(Vector(0, 0, 25))
			p:SetDieTime(math.Rand(5, 9) * (main and 1 or 0.5))
			p:SetStartAlpha(math.random(150, 210)); p:SetEndAlpha(0)
			p:SetStartSize(r * math.Rand(0.4, 0.7)); p:SetEndSize(r * math.Rand(1.2, 2))
			p:SetRoll(math.Rand(0, 360)); p:SetRollDelta(math.Rand(-0.3, 0.3))
			local c = math.random(35, 60)
			p:SetColor(c, c, c)
		end
	end
	em:Finish()
end

function EFFECT:Think() return false end
function EFFECT:Render() end
