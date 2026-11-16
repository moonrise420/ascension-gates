ENT.Type 		= "anim";
ENT.Base 		= "base_anim";
ENT.PrintName	= "Wraith Grenade";
ENT.Author		= "Ronon Dex, Rafael De Jongh";
ENT.Contact		= "";
ENT.Spawnable        = false
ENT.AdminSpawnable   = false
ENT.RenderGroup = RENDERGROUP_BOTH

if SERVER then
	AddCSLuaFile();
	function ENT:Initialize()
		self:SetModel("models/pg_props/pg_weapons/pg_wraith_hands_granate_w.mdl");
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		self.DetectRange = StarGate.CFG:Get("wraith_grenade","detect_range",200);
		self.BlastRange = StarGate.CFG:Get("wraith_grenade","blast_range",200);
		self.BlastDamage = StarGate.CFG:Get("wraith_grenade","blast_damage",300);
		
		self:SetRenderMode(RENDERMODE_NORMAL);

		self.Mine = self.Mine or false; -- AGP: the weapon sets it before Spawn for a placed mine
		self:SetUseType(SIMPLE_USE);
	end

	-- AGP: a placed mine goes off when it is shot
	function ENT:OnTakeDamage(dmg)
		if (self.Mine and not self.AGPBlown and (self.CanExplode or 0) < CurTime()) then
			self.AGPBlown = true;
			timer.Simple(0, function() if (IsValid(self)) then self:Explode() end end);
		end
	end
	
	function ENT:Think()
		if(not self.Mine) then
			local delay = math.Rand(3,6);
			timer.Simple(delay, function()
				if(IsValid(self)) then
					self:Explode();
				end
			end)
			self.Entity:NextThink(CurTime()+delay+0.1);
		else
			if(self.CanExplode < CurTime()) then
				for k,v in pairs(ents.FindInSphere(self:GetPos(),self.DetectRange)) do
					if(v:IsPlayer() or v:IsNPC()) then
						if(v != self.Owner) then
							self:Explode();
						end
					end
				end
			end
			self.Entity:NextThink(CurTime()+0.2);
		end
		return true;
	end
	
	function ENT:Use(ply)
		if(self.Mine and IsValid(self.Owner) and ply == self.Owner) then
			if (!ply:HasWeapon("wraith_grenade")) then
				ply:Give("wraith_grenade");
				ply:GetWeapon("wraith_grenade").Ammo = 1;
			else
				ply:GetWeapon("wraith_grenade").Ammo = ply:GetWeapon("wraith_grenade").Ammo+1;
			end			
			self:Remove();
		end
	end
	
	function ENT:Explode()
		if (self.AGPExploded) then return end -- AGP: once (two people near the mine blew it up twice)
		self.AGPExploded = true;
		-- Much better solution!
		local att = IsValid(self.Owner) and self.Owner or (IsValid(self:GetOwner()) and self:GetOwner() or self); -- AGP: thrown ones only have SetOwner
		util.BlastDamage( self, att, self:GetPos(), self.BlastRange, self.BlastDamage)
		
		local fx = EffectData();
			fx:SetOrigin(self:GetPos());
			fx:SetMagnitude(50);
		util.Effect("Explosion", fx, true, true);
		self:Remove();
	end
	
end