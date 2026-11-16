--[[
	Ha'tak interior (Ascension Gates)
	The walkable inside of an agp_hatak, TARDIS style: a still-standing copy of the hull (all decks + the lower deck
	rooms, exact collision) placed in free space of the map. It never moves, so the crew is never shaken and the complex
	collision cannot crash the physics engine; the flying hull outside keeps the original simple collision.
	Not in the spawn menu; agp_hatak creates and removes it. Only players near it receive it (hidden from everyone else).
]]
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ha'tak Interior"
ENT.Author = "Ascension Gates"
ENT.Spawnable = false

ENT.InteriorModel = "models/agp/hatak/agp_hatak_interior2.mdl"

if SERVER then
	AddCSLuaFile()

	function ENT:Initialize()
		self:SetModel(self.InteriorModel)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false); ph:Sleep() end
		self.Hidden = {}   -- parts placed in here (hidden together with the interior)
		-- life support: inside it is the air of the real ship's place, with the ship's gravity
		if (AGP and AGP.LS and AGP.LS.Interiors) then
			local me = self
			table.insert(AGP.LS.Interiors, { ent = self,
				contains = function(pos) return pos:WithinAABox(me:LocalToWorld(me:OBBMins()), me:LocalToWorld(me:OBBMaxs())) end,
				outside = function(pos) local ship = me.AGPShip; if IsValid(ship) then return ship:LocalToWorld(me:WorldToLocal(pos)) end end,
				inside = function(pos)   -- the Ha'tak's life support running: breathable everywhere aboard
					local ship = me.AGPShip
					if IsValid(ship) and ship.LifeSupportOK and ship:LifeSupportOK() then
						return { name = "Ha'tak", breathable = true, gravity = 1, temp = 293, space = false, interior = me }
					end
				end })
		end
		self:NextThink(CurTime() + 0.5)
	end

	function ENT:PhysgunPickup() return false end
	function ENT:CanTool() return false end
	function ENT:CanProperty() return false end

	-- send it (and its parts) only to players near it or near the ship's hangar doorway (they see it through the
	-- doorway); the client never draws it directly from outside, so nobody sees a second Ha'tak in the sky
	-- children of the parts (a gate's spinning ring and chevrons, made by the gate itself) are hidden with them
	function ENT:CollectChildren()
		local seen = {}
		for _, e in ipairs(self.Hidden) do seen[e] = true end
		local function add(e)
			for _, c in ipairs(e:GetChildren()) do
				if (IsValid(c) and not seen[c]) then seen[c] = true; table.insert(self.Hidden, c); add(c) end
			end
		end
		for i = 1, #self.Hidden do if (IsValid(self.Hidden[i])) then add(self.Hidden[i]) end end
		self.HiddenFor = nil   -- send the transmit rules again (new entries)
	end

	function ENT:Think()
		if (not self.ChildrenAt) then self.ChildrenAt = CurTime() + 3 end
		if (self.ChildrenAt and CurTime() > self.ChildrenAt) then self.ChildrenAt = CurTime() + 20; self:CollectChildren() end
		local r = self:BoundingRadius() + 3000
		local ship = self.AGPShip
		for _, p in ipairs(player.GetAll()) do
			local hide = p:GetPos():DistToSqr(self:GetPos()) > r * r
				and not (IsValid(ship) and p:GetPos():DistToSqr(ship:GetPos()) < 14000 * 14000)
			if (self.HiddenFor == nil or self.HiddenFor[p] ~= hide) then
				self.HiddenFor = self.HiddenFor or {}
				self.HiddenFor[p] = hide
				self:SetPreventTransmit(p, hide)
				for _, e in ipairs(self.Hidden) do if (IsValid(e)) then e:SetPreventTransmit(p, hide) end end
			end
		end
		if (AGP and AGP.LS and AGP.LS.SBInterior) then AGP.LS.SBInterior(self, ship) end   -- Spacebuild players: same air rule
		self:NextThink(CurTime() + 0.5)
		return true
	end
end

if CLIENT then
	ENT.AGPHiddenVolume = true   -- agp_portal: only drawn through a doorway or for someone standing inside
end
