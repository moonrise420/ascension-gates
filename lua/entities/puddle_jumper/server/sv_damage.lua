function ENT:DoKill(ply)   --######### @ RononDex

	self.Done=true
	local velocity = self:GetForward()

	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetStart(self:GetUp())
	util.Effect( "dirtyxplo", effectdata )

	for k,v in pairs(ents.FindInSphere(self:GetPos(),500)) do
		if(v:IsPlayer() and not v:HasGodMode()) then
			local allow = hook.Call("StarGate.Jumper.KillPlayer",nil,v,self);
			if (allow==nil or allow) then
				v:Kill();
			end
		end
	end

	self:EmitSound(self.Sounds.Explosion, 100, 100)
	if (AGP and AGP.ShipExplosion) then AGP.ShipExplosion(self) end -- AGP: the shared ship explosion

	for k,v in pairs(self.Gibs) do
		local model = v
		local k = ents.Create("prop_physics")
		k:SetPos(self:GetPos())
		k:SetAngles(self:GetAngles())
		k:SetModel(model)
		k:PhysicsInit( SOLID_VPHYSICS )
		k:SetMoveType( MOVETYPE_VPHYSICS )
		k:SetSolid( SOLID_VPHYSICS )
		k:SetCollisionGroup( COLLISION_GROUP_WORLD )
		k:Activate()
		k:Spawn()
		k:Ignite(8.5,0)
		k:GetPhysicsObject():SetVelocity(velocity*1000 + VectorRand()*40000)
		k:GetPhysicsObject():ApplyForceCenter(velocity*1000 +VectorRand()*40000)
		k:SetColor(Color(255,255,255,math.Approach(255,0,15)))
		k:Fire("Kill", "", 10)
	end

	if(IsValid(self)) then
		if(self.Inflight) then
			self:ExitJumper(self.Pilot)
			if(self.Done) then
				if(IsValid(self.Pilot)) then
					self.Pilot:Kill()
				end
			end
		end
	end

	self:Remove()
end

--######## Make sure we take damage from energy shots @RononDex
function ENT:Touch(e)

	if(IsValid(e)) then
		if(e:GetClass()=="staff_pulse") then self:TakeDamage(150) end
		if(e:GetClass()=="energy_pulse") then self:TakeDamage(150) end
	end
end

-- AGP: the raised shield takes the hit and drains. Before, a raised shield ignored every hit (no drain, no bubble),
-- so it held forever. Returns true when the shield took the damage. Also called for hits on the bubble itself
-- (hook below). The drain is limited to 10 % per 0.25 s, so a beam that hits many times per second (Asuran gate
-- weapon) takes it down in a few seconds instead of in one frame.
function ENT:AGPShieldAbsorb(dmg)
	local gen = self.Shields
	if (not IsValid(gen) or not gen:Enabled() or gen.Depleted) then return false end
	local now = CurTime()
	if ((self.AGPShieldWindow or 0) + 0.25 < now) then
		self.AGPShieldWindow = now
		self.AGPShieldUsed = 0
	end
	local drain = math.min(dmg:GetDamage() * 0.04, 10 - (self.AGPShieldUsed or 0))
	if (drain > 0) then
		self.AGPShieldUsed = (self.AGPShieldUsed or 0) + drain
		gen.Strength = math.max(0, (tonumber(gen.Strength) or 0) - drain)
		if (gen.SetWire) then gen:SetWire("Strength", math.floor(gen.Strength)) end
	end
	local pos = dmg:GetDamagePosition()
	if (pos == vector_origin) then pos = self:GetPos() end
	local bubble = gen.Shield
	if (IsValid(bubble)) then
		if (gen.Strength <= 0) then
			if (bubble.Hit) then bubble:Hit(self, pos, 0) end -- empty: the bubble collapses (sets the generator depleted)
		elseif ((self.AGPShieldFx or 0) < now and bubble.HitEffect) then
			self.AGPShieldFx = now + 0.2
			bubble:HitEffect(self, pos, math.Clamp(dmg:GetDamage() / 20, 1, 10))
		end
	end
	return true
end

hook.Add("EntityTakeDamage", "AGP.JumperShieldDrain", function(ent, dmg)
	if (not IsValid(ent) or ent:GetClass() ~= "ship_shield") then return end
	local gen = ent.Parent
	local jumper = IsValid(gen) and gen:GetParent()
	if (IsValid(jumper) and jumper:GetClass() == "puddle_jumper" and jumper.Shields == gen and jumper.AGPShieldAbsorb) then
		jumper:AGPShieldAbsorb(dmg)
	end
end)

--############ What happens when we take damage, what shall happen when we've taken a lot of damage @RononDex
function ENT:OnTakeDamage(dmg)

	if(not self:AGPShieldAbsorb(dmg)) then -- AGP: was: no shield up (a raised shield ignored the hit)
		if(not(self.WaterDamage)) then
			--###### The wobble's back
			if(self.Inflight) then
				if(not(self.LiftOff)) then
					if(not(self.CollisionDmg)) then
						if(dmg:GetDamage()>50) then
							self:SetAngles(self:GetAngles()+Angle(-35,15,10))
						end
					end
				end
			end
		end
		--#### Disable systems when damaged
		if(not(self.Done)) then

			self.EntHealth = self.EntHealth-(dmg:GetDamage()/10);
			self:SetWire("Health", self.EntHealth)

			if((self.EntHealth)<=300) then
				if(self.Cloaked) then
					self:ToggleCloak();
				end
				self.CantCloak = true;
				self.CanCloak = false;
			end

			if((self.EntHealth)<=250) then
				self.CanShield = false;
				if (IsValid(self.Shields)) then
					self.Shields.CantBeEnabled = true;
					-- AGP: was self:ToggleShield(), which does nothing once CanShield is false: the shield stayed up
					if (self.Shields:Enabled()) then self.Shields:Status(false) end
				end
				self.Shielded = false
			end

			if((self.EntHealth)<=200) then
				self.CanShoot = false
			end

			if((self.EntHealth)<=100) then
				-- AGP: tell the pilot once; without engines the Jumper now falls (sv_physics.lua)
				if (self.Engine and IsValid(self.Pilot) and AGP and AGP.Say) then
					AGP.Say(self.Pilot, "agp_jumper_engine_down", "Engines damaged: the Jumper is going down!")
				end
				self.Engine=false
			end

			if((self.EntHealth)<=50) then
				self.CanHaveLS=false
				self.Hover=false
			end
		end
	end
end

function ENT:HealthRepair(health)
    self.EntHealth = health
    self:SetWire("Health", health)
    -- AGP: a repaired hull brings the systems back (they stayed off forever; a Jumper without engines cannot fly now)
    if (health > 300) then self.CantCloak = false; if (not self.Shielded) then self.CanCloak = true end end
    if (health > 250) then
        if (not self.Cloaked) then self.CanShield = true end
        if (IsValid(self.Shields)) then self.Shields.CantBeEnabled = nil end
    end
    if (health > 200) then self.CanShoot = true end
    if (health > 100) then self.Engine = true end
    if (health > 50) then self.CanHaveLS = true end
end
