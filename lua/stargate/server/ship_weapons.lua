--[[
	Ship weapons: own ship never hit, and the weapons' energy setting

	a player picked 11 weapons that player-built ships (SpaceGrid hulls, StarCore cores) fire. Their shots carry the
	weapon that fired them (shot.AGPFrom, set by StarGate.MarkShot); pulses, drones, beams, bullets and blasts pass or
	spare everything of that weapon's own ship and its own shield.
	agp_weapon_energy (stargate/shared/init.lua) decides whether they need energy: StarGate.WeaponEnergy.
]]

-- the weapons a ship fires (StarCore's list, starcore/sv_combat.lua)
StarGate.ShipWeapons = {
	asgard_beam = true, hatak_staff_cannon = true, launcher_drones = true, ori_beam_cannon = true,
	sg_turret_destmain = true, sg_turret_destmed = true, sg_turret_destsmall = true, sg_turret_shiprail = true,
	sg_turret_tollan = true, vanir_plasma_cannon = true, wraith_plasma_cannon = true,
}

function StarGate.IsShipWeapon(e)
	return IsValid(e) and StarGate.ShipWeapons[e:GetClass()] == true
end

--################# Same ship?

-- the top of the parent chain
local function root(e)
	local p = e:GetParent()
	for _ = 1, 16 do
		if (not IsValid(p)) then break end
		e = p
		p = e:GetParent()
	end
	return e
end

-- everything welded / constrained to a SpaceGrid hull, cached per hull for 2 s (no constraint scan per tick)
local welded = setmetatable({}, { __mode = "k" })
local function weldedTo(hull)
	local c = welded[hull]
	local now = CurTime()
	if (not c or c.t < now) then
		local set = {}
		for _, v in pairs(constraint.GetAllConstrainedEntities(hull) or {}) do set[v] = true end
		c = { t = now + 2, set = set }
		welded[hull] = c
	end
	return c.set
end

-- a and b belong to the same ship: the same entity, parts of one StarCore core, the same root parent, or one of
-- them is a SpaceGrid hull the other is welded or parented to. (Also a CAP part and its weapon: part.Parent.)
function StarGate.SameShip(a, b)
	if (not (IsValid(a) and IsValid(b))) then return false end
	if (a == b or b.Parent == a or a.Parent == b) then return true end
	local ra, rb = root(a), root(b)
	if (ra == rb) then return true end
	local pc = StarCore and StarCore.PartCore
	if (pc) then
		local ca = pc[a] or pc[ra]
		if (IsValid(ca) and ca == (pc[b] or pc[rb])) then return true end
	end
	if (rb.SpaceGridHull and weldedTo(rb)[ra]) then return true end
	if (ra.SpaceGridHull and weldedTo(ra)[rb]) then return true end
	return false
end

-- e is a shield bubble whose generator belongs to the ship of weapon `from`
local BUBBLES = { shield = true, shield_core_buble = true, ship_shield = true }
function StarGate.OwnShield(from, e)
	if (not (IsValid(from) and IsValid(e) and BUBBLES[e:GetClass()])) then return false end
	local gen = e.Parent
	if (not (isentity(gen) and IsValid(gen))) then gen = e:GetParent() end
	return IsValid(gen) and StarGate.SameShip(from, gen)
end

-- the weapon a shot (or the env_laser of a beam: its parent) came from; a ship weapon itself counts as its own
local function shotFrom(e)
	if (not IsValid(e)) then return end
	local f = e.AGPFrom
	if (f == nil) then
		local p = e:GetParent()
		if (IsValid(p)) then f = p.AGPFrom end
	end
	if (f == nil and StarGate.ShipWeapons[e:GetClass()]) then f = e end
	if (isentity(f) and IsValid(f)) then return f end
end
StarGate.ShotFrom = shotFrom

-- a shot passes through this entity: its own ship or its own ship's shield bubble
function StarGate.ShotPasses(shot, e)
	local from = shotFrom(shot)
	return from ~= nil and (StarGate.SameShip(from, e) or StarGate.OwnShield(from, e))
end

-- called by the ship weapons where they create a pulse, drone or beam (before Spawn)
function StarGate.MarkShot(shot, weapon)
	if (not (IsValid(shot) and IsValid(weapon))) then return end
	shot.AGPFrom = weapon
	shot:SetCustomCollisionCheck(true) -- the ShouldCollide hook below is asked for it
end

-- pulses and drones fly through their own ship
hook.Add("ShouldCollide", "AGP.OwnShipShots", function(e1, e2)
	local f1 = IsValid(e1) and e1.AGPFrom
	local f2 = IsValid(e2) and e2.AGPFrom
	if (not (f1 or f2)) then return end
	if ((f1 and StarGate.SameShip(f1, e2)) or (f2 and StarGate.SameShip(f2, e1))) then return false end
end)

-- damage from a ship weapon's shot (blast, beam, env_laser, bullet) to its own ship. Other damage hooks that act on
-- a hit (StarCore's hull, the shield drains) should ask this first: the order of hooks is not fixed.
function StarGate.OwnShipDamage(target, dmg)
	if (not IsValid(target)) then return false end
	local from = shotFrom(dmg:GetInflictor()) or shotFrom(dmg:GetAttacker())
	return from ~= nil and StarGate.SameShip(from, target)
end

hook.Add("EntityTakeDamage", "AGP.OwnShipShots", function(target, dmg)
	if (StarGate.OwnShipDamage(target, dmg)) then return true end
end)

--################# Weapons against ships: "Series power" or "AGP sandbox" (agp_weapon_balance) Series power (1,
-- the default): the weapons rank against a ship's hull as in the series - Ori, Asgard and Ancient weapons on top,
-- Goa'uld and Wraith warship guns in the middle, Earth's railguns low, hand weapons 5 % (they scratch a hull, they do
-- not sink it). AGP sandbox (0): every weapon's own AGP damage. A factor is
-- "the AGP sandbox damage per second measured in the game" -> "the series target": the time one weapon takes to destroy a
-- test ship (Gate hall + cockpit, StarCore hull 227,220): S 25 s, A 45 s, B 80 s, turrets 2.5 - 6 min, manned
-- ground guns 10 - 15 min. Measured (SpaceGrid suite keelfire) Used by StarCore's hull (starcore/sv_crew.lua); a weapon
-- not in the list keeps its own damage.
local HATAK_HULL = 2.06   -- (SpaceGrid suite pthatak: 3669 a second in AGP sandbox -> the test ship in 30 s)
local HATAK_SHIELD = HATAK_HULL * 0.14 / 0.74   -- (its pulses are the staff cannon's: the same shield-to-hull ratio)
StarGate.HullBalance = {
	ori_beam_cannon = 15.7, asgard_beam = 80, launcher_drones = 9.9,               -- S: ship-killers (25 s)
	sg_turret_destmain = 9.1, sg_turret_tollan = 1.54, vanir_plasma_cannon = 4.6,  -- A: heavy guns (45 s)
	hatak_staff_cannon = 0.74, wraith_plasma_cannon = 1.17,                        -- B: warship guns (80 s)
	agp_hatak = HATAK_HULL,                                                        -- a Ha'tak's volley of 7 cannons (30 s)
	sg_turret_destmed = 2.9, sg_turret_destsmall = 2.2, sg_turret_shiprail = 1.9,  -- turrets (2.5 / 4 / 6 min)
	staff_stationary = 0.35, stationary_railgun = 1.9,                             -- manned ground guns (10 / 15 min)
}
StarGate.HandHullFactor = 0.05

function StarGate.SeriesBalance()
	local cv = GetConVar("agp_weapon_balance")
	return not cv or cv:GetInt() ~= 0
end

-- what a hit came from: a weapon class of the list, "hand" (a player's own weapon or its shot), or nil (anything else:
-- explosions of props, physics, the kawoosh, other addons - they keep their damage)
function StarGate.HitSource(inf, att)
	local from = shotFrom(inf) or shotFrom(att)
	if (from and StarGate.HullBalance[from:GetClass()]) then return from:GetClass() end
	for _, e in ipairs({ inf, att }) do
		if (IsValid(e)) then
			if (StarGate.HullBalance[e:GetClass()]) then return e:GetClass() end
			-- a turret's moving part (its barrel fires the bullets: sg_turret_part, .Parent = the turret)
			local par = e.Parent
			if (isentity(par) and IsValid(par) and StarGate.HullBalance[par:GetClass()]) then return par:GetClass() end
			-- a shot that knows its gun (the stationary staff weapon's pulses)
			local o = e.Owner
			if (not (isentity(o) and IsValid(o))) then o = e:GetOwner() end
			if (IsValid(o) and not o:IsPlayer() and StarGate.HullBalance[o:GetClass()]) then return o:GetClass() end
		end
	end
	if (IsValid(att) and att:IsPlayer()) then
		if (not IsValid(inf) or inf == att or inf:IsWeapon()) then return "hand" end
		-- a shot fired by the player himself (a staff weapon's pulse, a grenade)
		if (inf.Owner == att or inf:GetOwner() == att) then return "hand" end
	end
end

-- Ship shields (a shield generator that is a part of a StarCore ship): their own factors, as AGP's shields drain by
-- their own rules (1..20 "strength" a hit, not the damage). Same tiers, measured by the time a weapon takes to bring a
-- shield down (SpaceGrid suite keelshieldfire). A weapon not in the list: 1; hand weapons: HandHullFactor.
-- Target: a quarter of the hull's time (S 6 s, A 11 s, B 20 s, turrets 38 s / 1 / 1.5 min); manned ground guns and hand
-- weapons wear a ship's shield but never bring it down alone. Under a ship weapon's fire the shield does not recharge
-- (ShieldHitPause): factor = (100 / target) / the % a second the weapon's hits take in AGP sandbox (test ship's
-- shield_generator, size 1100, keelshieldfire). One run alone can be 2-3x off for the Destiny main weapon,
-- Ha'tak and Wraith cannons, drones and the Asgard beam (aim, drones' paths).
StarGate.ShieldBalance = {
	ori_beam_cannon = 1.64, asgard_beam = 6.3, launcher_drones = 0.8,                -- S (6 s)
	sg_turret_destmain = 0.75, sg_turret_tollan = 0.14, vanir_plasma_cannon = 0.39,  -- A (11 s)
	hatak_staff_cannon = 0.14, wraith_plasma_cannon = 0.41,                          -- B (20 s)
	agp_hatak = HATAK_SHIELD,                                                        -- a Ha'tak's volley (about 8 s; from the hull factor, not measured)
	sg_turret_destmed = 0.32, sg_turret_destsmall = 0.15, sg_turret_shiprail = 0.063, -- turrets (38 / 60 / 90 s)
	staff_stationary = 0.31, stationary_railgun = 0.77,                              -- ground guns: wear it slowly
}
-- a hit of a ship weapon (not a ground gun, not a hand weapon) stops the shield's recharge this long, so the time to
-- bring a shield down follows the weapons' damage (shield_generator / ship_shield_generator ENT:Regenerate). Before,
-- the weaker ship guns drained only just faster than the recharge, and a run with a few more misses took a shield
-- down 50x slower (a Ha'tak cannon: 18 minutes instead of 20 s). Ground guns and hand weapons never pause it: alone
-- they wear a shield, they never bring it down.
StarGate.ShieldHitPause = 3
StarGate.ShieldNoPause = { staff_stationary = true, stationary_railgun = true }

-- the factor for a hit on a shield bubble: e = what hit it (a shot, a player, a prop), gen = the bubble's generator
function StarGate.ShieldFactor(e, gen)
	if (not StarGate.SeriesBalance() or not IsValid(e)) then return 1 end
	if (not (IsValid(gen) and StarCore and StarCore.PartCore and IsValid(StarCore.PartCore[gen]))) then return 1 end
	local att = e:IsPlayer() and e or e.Owner
	if (not (isentity(att) and IsValid(att))) then att = e:GetOwner() end
	local src = StarGate.HitSource(e, att)
	if (src == "hand") then return StarGate.HandHullFactor end
	local f = src and StarGate.ShieldBalance[src]
	if (f and not StarGate.ShieldNoPause[src]) then gen.AGPRechargePause = CurTime() + StarGate.ShieldHitPause end
	return f or 1
end

-- the factor for a hit on a ship's hull (1 in AGP sandbox), and where it came from
function StarGate.HullFactor(dmg)
	if (not StarGate.SeriesBalance()) then return 1 end
	local src = StarGate.HitSource(dmg:GetInflictor(), dmg:GetAttacker())
	if (src == "hand") then return StarGate.HandHullFactor, src end
	return (src and StarGate.HullBalance[src]) or 1, src
end

--################# Weapons' energy (agp_weapon_energy)

-- does this weapon use energy right now? No: setting 0 (free), no resource network, PowerGrid off
-- (agp_power_mode 0 = free energy), or setting 1 and the weapon not connected to a network
function StarGate.WeaponEnergyUsed(ent)
	local cv = GetConVar("agp_weapon_energy")
	local m = cv and cv:GetInt() or 1
	if (m <= 0) then return false end
	if (not (IsValid(ent) and ent.HasRD and StarGate.HasResourceDistribution)) then return false end
	-- (PowerGrid switched off - agp_power_mode 0 - means free energy; with Spacebuild installed its own network counts,
	-- as for every other device of the pack)
	if (PowerGrid and not PowerGrid.SpacebuildInstalled) then
		local pm = GetConVar("agp_power_mode")
		if (pm and pm:GetInt() == 0) then return false end
	end
	if (m == 1 and not StarGate.WireRD.Connected(ent)) then return false end
	return true
end

-- may the weapon fire (or charge)? When it uses energy it needs `amount` and takes it (not with check_only)
function StarGate.WeaponEnergy(ent, amount, check_only)
	if (not StarGate.WeaponEnergyUsed(ent)) then return true end
	amount = amount or 0
	if (ent:GetResource("energy") < amount) then return false end
	if (not check_only and amount > 0) then ent:ConsumeResource("energy", amount) end
	return true
end

--################# Shields on a StarCore ship use the ship's energy

-- "if i weld the shield core to the ship it does not use its energy its saying 500 needed 0 available, also with the
-- tool gun agp shield". A shield asks its own network for energy; welded on a ship and not linked by cable it was a
-- network of its own, with nothing in it. Now a shield on a StarCore ship that is not linked to a network itself takes
-- the energy of the ship: what its linked networks hold (StarCore's power page) and what every power source welded on
-- the ship holds by itself, linked or not (a ZPM, a generator, a battery: on a ship, the ship is its cable). A shield
-- that is linked uses its own network as before; a shield not on a ship is unchanged.
local function loneStores(core, nets, inNet)
	local list = {}
	for _, e in ipairs(core.OwnParts or core.Parts or {}) do
		local r = IsValid(e) and not (inNet and inNet[e]) and e.AGPRes and e.AGPRes.energy
		if (r and (r.max or 0) > 1) then list[#list + 1] = e end   -- (a shield's own 1-unit store is no source)
	end
	return list
end
local function shipEnergy(core)
	local nets, inNet = StarCore.PowerNets(core)
	local have = 0
	for _, n in ipairs(nets or {}) do have = have + (n.energy or 0) end
	for _, e in ipairs(loneStores(core, nets, inNet)) do have = have + math.max(e.AGPRes.energy.amount or 0, 0) end
	return have, nets, inNet
end
local function shipPay(core, amount)
	local have, nets, inNet = shipEnergy(core)
	local left = math.min(amount, have)
	if (left <= 0) then return 0 end
	local paid = left
	local fromNets = 0
	for _, n in ipairs(nets or {}) do fromNets = fromNets + (n.energy or 0) end
	local a = math.min(left, fromNets)
	if (a > 0) then StarCore.PayJump(core, a) left = left - a end
	for _, e in ipairs(loneStores(core, nets, inNet)) do
		if (left <= 0) then break end
		local r = e.AGPRes.energy
		local take = math.min(left, math.max(r.amount or 0, 0))
		if (take > 0) then r.amount = r.amount - take left = left - take end
	end
	return paid - math.max(left, 0)
end
local function shipOf(ent)
	if (not (StarCore and StarCore.PartCore and StarCore.PowerNets and StarCore.PayJump)) then return nil end
	if (StarGate.WireRD and StarGate.WireRD.Connected and StarGate.WireRD.Connected(ent)) then return nil end
	local core = StarCore.PartCore[ent]
	if (not IsValid(core)) then return nil end
	return core
end
StarGate.ShieldShip = shipOf
StarGate.ShipEnergy = function(core) return (shipEnergy(core)) end

-- What the ship itself gives a shield, as it gives its weapons: a shield on a ship without any store runs on the
-- ship's own power, at its plain recharge (ZPMs and generators on board make that faster). Not with "Always"
-- (agp_weapon_energy 2) or agp_ship_power 0, and not for a shield core in Atlantis mode (its strength is the energy
-- itself).
--
local SHIP_OWN = 5000
local function shipOwn(self)
	local on, cv = GetConVar("agp_ship_power"), GetConVar("agp_weapon_energy")
	return on and on:GetBool() and (not cv or cv:GetInt() ~= 2) and not self.Atlantis
end

-- called by the shields' Initialize (shield_core, shield_generator)
function StarGate.ShipPowered(ent)
	local own = { get = ent.GetResource, use = ent.ConsumeResource, give = ent.SupplyResource }
	if (not (own.get and own.use)) then return end
	ent.GetResource = function(self, res, default)
		if (res == "energy") then
			local core = shipOf(self)
			if (core) then
				-- (read a few times a tick by a shield: the sum is kept a tenth of a second; paying makes it anew)
				local now = CurTime()
				if ((core.AGPShipEAt or 0) < now) then core.AGPShipE, core.AGPShipEAt = shipEnergy(core), now + 0.1 end
				local have = core.AGPShipE or 0
				if (have < SHIP_OWN and shipOwn(self)) then return SHIP_OWN end
				return have
			end
		end
		return own.get(self, res, default)
	end
	ent.ConsumeResource = function(self, res, amount)
		if (res == "energy") then
			local core = shipOf(self)
			if (core) then
				local n = tonumber(amount) or 0
				local paid = shipPay(core, n)
				-- (what switching on took from the ship's stores: only that comes back when switched off - on the ship's own
				-- power it took nothing, the release chat's rcrefund)
				if (n > 0 and n == tonumber(self.EngageEnergy)) then self.AGPEngagePaid = paid end
				core.AGPShipEAt = 0
				return
			end
		end
		return own.use(self, res, amount)
	end
	if (own.give) then
		ent.SupplyResource = function(self, res, amount)
			if (res == "energy") then
				local core = shipOf(self)
				if (core) then
					-- (the engage energy given back when switched off: into the ship's first store, as much as it took)
					amount = math.min(tonumber(amount) or 0, self.AGPEngagePaid or 0)
					self.AGPEngagePaid = 0
					if (amount <= 0) then return end
					local _, nets, inNet = shipEnergy(core)
					local p = nets and nets[1] and nets[1].part
					if (IsValid(p) and p ~= self and p.SupplyResource) then p:SupplyResource("energy", amount) return end
					local lone = loneStores(core, nets, inNet)[1]
					if (lone) then
						local r = lone.AGPRes.energy
						r.amount = math.min((r.amount or 0) + (tonumber(amount) or 0), r.max or 0)
					end
					return
				end
			end
			return own.give(self, res, amount)
		end
	end
end

--################# Charging per second

-- The charging weapons paid their charge cost on every Think (CAP's values: up to 14,000 each time), so the cost grew
-- with the server's tick rate - the Ha'tak staff cannon took about 30,000 a second, eleven Naquadah generators (Mk1:
-- about 2,600 a second). Now they pay per second while they charge, and the shot itself is paid with it.
StarGate.ChargeRate = {
	hatak_staff_cannon = 2600, wraith_plasma_cannon = 2600,   -- one Naquadah generator Mk1
	vanir_plasma_cannon = 1300,                               -- half of one
	asgard_beam = 5200, ori_beam_cannon = 5200,               -- two
}

-- may the weapon go on charging this Think? Pays rate x time since its last charging step (at most half a second)
function StarGate.WeaponCharge(ent)
	local now = CurTime()
	local dt = math.Clamp(now - (ent.AGPChargeAt or now), 0, 0.5)
	ent.AGPChargeAt = now
	if (StarGate.WeaponEnergyUsed(ent) and ent:GetResource("energy") <= 0) then return false end
	return StarGate.WeaponEnergy(ent, (StarGate.ChargeRate[ent:GetClass()] or 0) * dt)
end

--################# Weapons on a StarCore ship use the ship's power

-- "if i spawn and weld a agp weapon onto the ship it still is not using the ships power ... i thought of more connecting
-- the weapon to the hull its using the ships own power and for that also some admin settings with on off and default
-- on". A weapon on a StarCore ship that is not linked to a network itself is linked to the ship (as the shields above):
-- it pays its shots and charging from what the ship holds - its networks and every ZPM, generator and battery welded on,
-- linked or not. When that is not enough, the ship's own power fires it (the ship flies without a power system too);
-- only "Always" (agp_weapon_energy 2) needs the stores. agp_ship_power 0, "Never (free)", a linked weapon or a weapon
-- off a ship: as before.
local plainEnergy, plainCharge = StarGate.WeaponEnergy, StarGate.WeaponCharge
local function weaponShip(ent)
	local on = GetConVar("agp_ship_power")
	if (not (on and on:GetBool()) or not IsValid(ent)) then return nil end
	local cv = GetConVar("agp_weapon_energy")
	local m = cv and cv:GetInt() or 1
	if (m <= 0) then return nil end
	local core = shipOf(ent)
	if (not core) then return nil end
	return core, m
end
StarGate.WeaponShip = weaponShip
function StarGate.WeaponEnergy(ent, amount, check_only)
	local core, m = weaponShip(ent)
	if (not core) then return plainEnergy(ent, amount, check_only) end
	amount = amount or 0
	local now = CurTime()
	if ((core.AGPShipEAt or 0) < now) then core.AGPShipE, core.AGPShipEAt = shipEnergy(core), now + 0.1 end
	if ((core.AGPShipE or 0) >= amount) then
		if (not check_only and amount > 0) then shipPay(core, amount) core.AGPShipEAt = 0 end
		return true
	end
	return m == 1   -- (the ship's own power; "Always" needs the stores)
end
function StarGate.WeaponCharge(ent)
	if (not weaponShip(ent)) then return plainCharge(ent) end
	local now = CurTime()
	local dt = math.Clamp(now - (ent.AGPChargeAt or now), 0, 0.5)
	ent.AGPChargeAt = now
	return StarGate.WeaponEnergy(ent, (StarGate.ChargeRate[ent:GetClass()] or 0) * dt)
end
