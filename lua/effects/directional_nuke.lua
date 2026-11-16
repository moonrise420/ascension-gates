local matRefraction	= Material("refract_ring")
matRefraction:SetInt("$noclull", 1)

function EFFECT:Init(data)
	self.Ent = data:GetEntity();
	self.Scale = 10;

	local b = self.Ent:GetAttachment(self.Ent:LookupAttachment("Front"))
	if(not (b and b.Pos)) then return end

	self.StartPos = b.Pos;
	 self.Init 	= CurTime()
	 self.Time 	= self.Init
	 self.Relative	= 0

end

function EFFECT:Think()
	self.Time = CurTime()
	self.Relative = self.Time-self.Init
end

function EFFECT:Render()
	if self.Relative < 24 then -- Mostly TetaBonitas
		local eye = EyePos()
		local Distance = eye:Distance(self.StartPos)
		local Pos = self.StartPos+(eye-self.StartPos):GetNormal()*math.sin(self.Relative/2)*1.1*Distance
		matRefraction:SetFloat( "$refractamount", math.sin(self.Relative/2)*0.2)

		render.SetMaterial(matRefraction)
		render.UpdateRefractTexture()
		render.DrawSprite(Pos, self.Relative*1000*self.Scale, self.Relative*1000*self.Scale)
	end
end
