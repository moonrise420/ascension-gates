-- Ascension Gates (2026-10-25): shared helpers for the big ships.
--  * Shield on the SHIELD key (G), built like the Tel'tak's: CAP's ship_shield_generator parented to the ship, NW bool
--    AGPShieldOn. The bubble is one of the ellipsoid shield models (models/iziraider/shields/AxBxC.mdl), fitted to each
--    hull: the ship sets ENT.AGPShield = { model, yaw, offset, bounds, color, scale } (ship_shield and the bubble effect read
--    the model from the generator). OnTakeDamage calls AGP.ShipShieldAbsorb (via ENT:AGPHullDamage of sg_vehicle_base),
--    Think calls AGP.ShipShieldThink. Beams on the shield: AGP.ShipShieldBeam (drained by time).
--  * (2026-10-26) AGP.PlayerStandSpot: a free spot on the floor for exits and arrivals; hook AGP.ShipProtectsCrew:
--    players aboard a ship take no damage from outside while it stands.
--  * DHD key (R) on ships with ENT.AGPSupergateDHD: opens the dial menu of the nearest Supergate in range (like the
--    Gate Glider's OpenDHD), else a short chat hint.
--  * AGP.ShipShieldText(ship) for the ship HUDs (client).
AddCSLuaFile()
AGP = AGP or {}

if SERVER then
    --########## Shield
    function AGP.ShipShieldSpawn(ship)
        if IsValid(ship.AGPShieldGen) then return ship.AGPShieldGen end
        local cfg = ship.AGPShield
        if not cfg then return end
        local ent = ents.Create("ship_shield_generator")
        if not IsValid(ent) then return end
        ent:SetPos(ship:LocalToWorld(cfg.offset or ship:OBBCenter()))
        ent:SetAngles(ship:LocalToWorldAngles(Angle(0, cfg.yaw or 0, 0)))
        ent:SetParent(ship)
        ent.AGPShieldModel = cfg.model        -- read by ship_shield when the bubble goes up
        ent.AGPShieldBounds = cfg.bounds      -- optional: bigger box for the shot traces (hull longer than the bubble)
        ent:Spawn(); ent:Activate()
        ent:AddFlags(FL_DONTTOUCH); ent:SetSolid(SOLID_NONE)
        ent:SetColor(Color(255, 255, 255, 0)); ent:SetRenderMode(RENDERMODE_TRANSALPHA)
        ent.StrengthMultiplier = { 0.1, 0.5, -5 }   -- same as the Tel'tak / Destiny
        local c = cfg.color or { 1, 1, 1 }
        if ent.SetShieldColor then ent:SetShieldColor(c[1], c[2], c[3]) end
        if cfg.model then ent:SetNWString("AGPShieldModel", cfg.model) end   -- for the bubble effect when it goes down
        ent.AGPShieldScale = cfg.scale        -- optional: stretch the bubble per axis (a hull longer than any bubble)
        if cfg.scale then ent:SetNWVector("AGPShieldScale", cfg.scale) end
        ship.AGPShieldGen = ent
        return ent
    end

    -- on = nil: toggle (at most every 0.5 s); true / false: set
    function AGP.ShipShieldToggle(ship, on)
        if on == nil then
            if (ship.AGPNextShieldToggle or 0) > CurTime() then return end
            ship.AGPNextShieldToggle = CurTime() + 0.5
            on = not ship.AGPShielded
        end
        local gen = AGP.ShipShieldSpawn(ship)
        if not IsValid(gen) then return end
        gen:Status(on)
        ship.AGPShielded = gen:Enabled() and true or false
        AGP.ShipShieldThink(ship)
    end

    -- the ship's shield generator: the shared one (AGPShieldGen) or the ship's own CAP generator (self.Shield: Destiny,
    -- Gate Seeder, CAP Ha'tak)
    function AGP.ShipShieldGen(ship)
        local gen = ship.AGPShieldGen
        if IsValid(gen) then return gen end
        gen = ship.Shield
        if IsValid(gen) and gen:GetClass() == "ship_shield_generator" then return gen end
    end

    -- the raised bubble itself (ship_shield, on the generator), or nil: a ship's own bullets must not hit its physics from
    -- inside (sg_vehicle_prometheus FireRails)
    function AGP.ShipShieldEntity(ship)
        local gen = AGP.ShipShieldGen(ship)
        if not IsValid(gen) then return end
        if IsValid(gen.Shield) and gen.Shield:GetClass() == "ship_shield" then return gen.Shield end
        for _, e in ipairs(gen:GetChildren()) do
            if IsValid(e) and e:GetClass() == "ship_shield" then return e end
        end
    end

    -- keeps the NW values for the HUD up to date (call it from the ship's Think)
    function AGP.ShipShieldThink(ship)
        local gen = AGP.ShipShieldGen(ship)
        local up = IsValid(gen) and gen:Enabled() and true or false
        local on = up and not gen.Depleted
        if ship:GetNWBool("AGPShieldOn", false) ~= on then ship:SetNWBool("AGPShieldOn", on) end
        local dep = up and gen.Depleted and true or false
        if ship:GetNWBool("AGPShieldDepleted", false) ~= dep then ship:SetNWBool("AGPShieldDepleted", dep) end
        local s = IsValid(gen) and math.floor(tonumber(gen.Strength) or 0) or 100
        if ship:GetNWInt("AGPShieldStrength", -1) ~= s then ship:SetNWInt("AGPShieldStrength", s) end
    end

    -- continuous beams (the Asuran gate weapon's energy_laser: a blast and a hit every 0.1 s, its env_laser): many small
    -- hits that must count all the same, but at most so much per second
    function AGP.IsBeamDamage(dmg)
        local inf = dmg:GetInflictor()
        local c = IsValid(inf) and inf:GetClass() or ""
        return c == "energy_laser" or c == "env_laser" or dmg:IsDamageType(DMG_ENERGYBEAM)
    end

    -- the beam on a raised ship shield: drains it by time, not per hit (the gate weapon hits 10x a second and the CAP
    -- generator took 12-60 % per hit: gone in a blink; or less than its regeneration: held forever).
    -- A full shield holds ship.AGPShieldBeamTime seconds (default 20). Shows the hit on the bubble, collapses it when empty.
    -- gen: the ship's ship_shield_generator (default ship.AGPShieldGen); k: how much heavier the beam is (default 1).
    -- Returns true while the shield holds.
    function AGP.ShipShieldBeam(ship, gen, pos, k)
        gen = gen or AGP.ShipShieldGen(ship)
        if not (IsValid(gen) and gen:Enabled() and not gen.Depleted) then return false end
        local now = CurTime()
        local dt = math.Clamp(now - (gen.AGPBeamLast or (now - 0.1)), 0, 0.25)
        gen.AGPBeamLast = now
        -- the generator regenerates 2 x 2 x RestoreMultiplier / StrengthMultiplier[2] per 0.5 s: drain that on top
        local sm = gen.StrengthMultiplier or {}
        local regen = 4 * (gen.RestoreMultiplier or 1) / math.max(0.01, sm[2] or 1)
        if (gen.AGPCap and gen:AGPCap()) then regen = 2.5 end -- AGP ship shields recharge 2.5 %/s while up
        local drain = (100 / (ship.AGPShieldBeamTime or 20) * (k or 1) + regen) * dt
        gen.Strength = math.max(0, (tonumber(gen.Strength) or 0) - drain)
        if gen.SetWire then gen:SetWire("Strength", math.floor(gen.Strength)) end
        local bubble = gen.Shield
        if IsValid(bubble) then
            if gen.Strength <= 0 then
                if bubble.Hit then bubble:Hit(ship, pos, 0) end -- empty: the bubble collapses (generator depleted)
            elseif (gen.AGPBeamFx or 0) < now and bubble.HitEffect then
                gen.AGPBeamFx = now + 0.2
                bubble:HitEffect(ship, pos, 8)
            end
        end
        AGP.ShipShieldThink(ship)
        return gen.Strength > 0
    end

    -- true when the raised shield took the hit instead of the hull (like the Destiny)
    function AGP.ShipShieldAbsorb(ship, dmg)
        local gen = AGP.ShipShieldGen(ship)
        if not (IsValid(gen) and gen:Enabled() and not gen.Depleted) then return false end
        local pos = dmg:GetDamagePosition()
        if AGP.IsBeamDamage(dmg) then -- a beam that reached the hull past the bubble: drained by time as well
            local inf = dmg:GetInflictor()
            AGP.ShipShieldBeam(ship, gen, pos, IsValid(inf) and tonumber(inf.AGPDamageScale) or 1)
            return true
        end
        -- (2026-11-12, owner: a huge blast next to a ship "did not even take the shields down") a hit bigger than what
        -- the shield has left empties it and the rest goes on to the hull - before, the shield swallowed any hit whole
        local cap = gen.AGPCap and gen:AGPCap()
        local left = cap and (math.max(0, gen.Strength or 0) / 100 * cap)
        local over = left and (dmg:GetDamage() - left) or 0
        if (gen.Strength or 0) > 0 and gen.Hit then gen:Hit(dmg:GetDamage() / 50, Vector(0, 0, 0), pos) end
        -- used up: let the bubble collapse (ship_shield:Hit sets the generator depleted)
        if (gen.Strength or 0) <= 0 and IsValid(gen.Shield) and gen.Shield.Hit then gen.Shield:Hit(ship, pos, 0) end
        AGP.ShipShieldThink(ship)
        if (over > 1) then dmg:SetDamage(over) return false end
        return true
    end

    function AGP.ShipShieldRemove(ship)
        if IsValid(ship.AGPShieldGen) then ship.AGPShieldGen:Remove() end
        ship.AGPShieldGen = nil
    end

    --########## Hull damage (2026-10-26)
    -- Shared by the ships' OnTakeDamage (sg_vehicle_base ENT:AGPHullDamage; the Daedalus calls it directly). Before, each
    -- ship subtracted the damage from the NW int "health": hits under 0.5 vanished in the rounding, and the Asuran gate
    -- weapon's beam (many small hits) never got through the hull of the Wraith cruiser and the others.
    --  * a raised shield takes the hit first (AGP.ShipShieldAbsorb; beams drain it by time)
    --  * continuous beams (AGP.IsBeamDamage) count without a minimum, at most ship.AGPBeamMaxDPS (600) per second: the
    --    beam's direct hit, its blast and its env_laser together (an 18000 hull: ~30 s of the gate weapon with the
    --    shield down; with the shield cycling down and back up about 1.5 min)
    --  * the hull: ship.AGPHullInEntHealth = true keeps it in ship.EntHealth (Tel'tak, Daedalus), else in the NW int
    --    "health" (the ship hangar and the HUDs read and write that one); fractions are kept, so small hits add up
    --  * at 0 the ship is destroyed once: ship:AGPHullDestroyed() if it has one, else ship:Bang()
    -- scale: damage multiplier (Daedalus 0.2). Returns the damage that reached the hull (0: none).
    local function beamBudget(ship, amount, dmg)
        local now = CurTime()
        if now - (ship.AGPBeamSince or -99) >= 1 then ship.AGPBeamSince, ship.AGPBeamTaken = now, 0 end
        -- (2026-11-07 balance) a heavier beam (energy_beam2's AGPDamageScale: the Ori's main beam) may do more per second
        local inf = dmg and dmg:GetInflictor()
        local k = IsValid(inf) and tonumber(inf.AGPDamageScale) or 1
        local take = math.min(amount, math.max(0, (ship.AGPBeamMaxDPS or 600) * k - ship.AGPBeamTaken))
        ship.AGPBeamTaken = ship.AGPBeamTaken + take
        return take
    end

    --########## Blasts on the big ships (2026-11-08, balance test): util.BlastDamage measures from the blast to a ship's
    -- middle (or to where its trace happens to leave the hull), so a bolt on a big ship's bow did nothing (the Ori's bow
    -- lies 1700 from its middle, a bolt's blast reaches 290) and a direct hit on the Prometheus did a third to all of
    -- its damage, by chance. StarGate.BlastDamage (bolts, drones, missiles) wraps util.BlastDamage in these two: the
    -- ships with the shared hull (ENT.AGPShield) take the blast by the distance to their hull box - a direct hit does
    -- its full damage. Ships out of util.BlastDamage's reach get their share afterwards.
    local blastNow
    function AGP.ShipBlastBegin(pos, rad, dmg)
        if not (rad and rad > 0 and dmg and dmg > 0) then return nil end
        blastNow = { pos = pos, rad = rad, dmg = dmg, done = {} }
        return blastNow
    end

    local function blastShare(b, ship)
        return b.dmg * math.max(0, 1 - ship:NearestPoint(b.pos):Distance(b.pos) / b.rad)
    end

    function AGP.ShipBlastEnd(b, inflictor, attacker)
        blastNow = nil
        for _, v in ipairs(ents.FindInSphere(b.pos, b.rad)) do
            if (v.AGPShield or v.AGPSharedHull) and not b.done[v] and not v.AGPDestroyed then   -- (AGPSharedHull: a big ship without a shield, the Wraith cruiser)
                local amount = blastShare(b, v)
                if amount > 0 then
                    b.done[v] = true
                    local d = DamageInfo()
                    d:SetDamage(amount)
                    d:SetDamageType(DMG_BLAST)
                    d:SetDamagePosition(b.pos)
                    d:SetInflictor(IsValid(inflictor) and inflictor or game.GetWorld())
                    d:SetAttacker(IsValid(attacker) and attacker or d:GetInflictor())
                    v:TakeDamageInfo(d)
                end
            end
        end
    end

    --########## A ship's own explosion (2026-11-12, owner: a ship blew up right next to another one of ours and that one
    -- took nothing): everything that flies - the ships with the shared hull, the Ha'tak, the Puddle Jumper, the small
    -- crafts - within `rad` of the blast takes `dmg` at the blast, falling off with the square of the distance to its
    -- hull (not to its middle). Each ship's own OnTakeDamage decides: the shield first, the rest to the hull.
    function AGP.ShipBlast(pos, rad, dmg, inflictor, attacker, skip)
        if not (rad and rad > 0 and dmg and dmg > 0) then return end
        for _, v in ipairs(ents.FindInSphere(pos, rad)) do
            if (IsValid(v) and v ~= skip and not v.AGPDestroyed and not v.Done and not v.Destroying
                and (v.AGPShield or v.AGPSharedHull or v.IsSGVehicle or v.AGPHullShip or v:GetClass() == "agp_hatak" or v:GetClass():find("^puddle_jumper"))) then
                local d = v:NearestPoint(pos):Distance(pos)
                local amount = dmg * math.max(0, 1 - d / rad) ^ 2
                if (amount >= 1) then
                    local di = DamageInfo()
                    di:SetDamage(amount)
                    di:SetDamageType(DMG_BLAST)
                    di:SetDamagePosition(v:NearestPoint(pos))
                    di:SetInflictor(IsValid(inflictor) and inflictor or game.GetWorld())
                    di:SetAttacker(IsValid(attacker) and attacker or di:GetInflictor())
                    v:TakeDamageInfo(di)
                end
            end
        end
    end

    function AGP.ShipHullDamage(ship, dmg, scale)
        if ship.Done or ship.AGPDestroyed then return 0 end
        if blastNow and dmg:IsExplosionDamage() then -- inside util.BlastDamage: the share by the distance to the hull
            if blastNow.done[ship] then return 0 end
            blastNow.done[ship] = true
            dmg:SetDamage(blastShare(blastNow, ship))
        end
        if AGP.ShipShieldAbsorb(ship, dmg) then return 0 end
        local amount = dmg:GetDamage() * (scale or 1)
        if AGP.IsBeamDamage(dmg) then amount = beamBudget(ship, amount, dmg) end
        if amount <= 0 then return 0 end
        local hp
        if ship.AGPHullInEntHealth then
            ship.EntHealth = (ship.EntHealth or 0) - amount
            hp = ship.EntHealth
            ship:SetNWInt("health", math.max(0, math.ceil(hp)))
        else
            local acc = (ship.AGPHullFrac or 0) + amount
            local whole = math.floor(acc)
            ship.AGPHullFrac = acc - whole
            hp = ship:GetNWInt("health") - whole
            if whole > 0 then ship:SetNWInt("health", math.max(0, hp)) end
        end
        if ship.SetWire then ship:SetWire("Health", math.max(0, math.ceil(hp))) end
        if hp <= 0 then
            ship.AGPDestroyed = true
            if ship.AGPHullDestroyed then ship:AGPHullDestroyed() elseif ship.Bang then ship:Bang() else ship:Remove() end
        end
        return amount
    end

    --########## A free spot to stand on (ship exits, ring / transporter arrivals)
    -- Finds the floor under pos (a line down from a little above it, so a pos a few units inside the floor still finds
    -- the floor's top), lifts the player 4 units above it and checks the player's hull there. Tries a few spots around pos
    -- when that one is blocked. ignore: optional { [ent] = true } that is not solid for this (players and the moving
    -- transport rings never are).
    -- The ship itself is solid on purpose: its floor is what we stand on. Returns nil when nothing is free.
    local STAND_OFFSETS = { Vector(0, 0, 0), Vector(24, 0, 0), Vector(-24, 0, 0), Vector(0, 24, 0), Vector(0, -24, 0),
        Vector(40, 40, 0), Vector(-40, 40, 0), Vector(40, -40, 0), Vector(-40, -40, 0), Vector(64, 0, 0), Vector(-64, 0, 0),
        Vector(0, 64, 0), Vector(0, -64, 0) }
    function AGP.PlayerStandSpot(pos, ply, ignore, above, below)
        above, below = above or 24, below or 72
        local mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72)
        if IsValid(ply) and ply.GetHull then mins, maxs = ply:GetHull() end
        local function skip(e)
            if not IsValid(e) then return true end
            if e == ply or e:IsPlayer() or (ignore and ignore[e]) then return false end
            if e:GetClass() == "ring_ring" then return false end -- the transport rings around the spot (not the ring bases)
            return true
        end
        for _, off in ipairs(STAND_OFFSETS) do
            local p = pos + off
            local down = util.TraceLine({ start = p + Vector(0, 0, above), endpos = p - Vector(0, 0, below), mask = MASK_PLAYERSOLID, filter = skip })
            if down.Hit and not down.StartSolid and down.HitNormal.z > 0.6 then
                local spot = down.HitPos + Vector(0, 0, 4)
                local tr = util.TraceHull({ start = spot, endpos = spot, mins = mins, maxs = maxs, mask = MASK_PLAYERSOLID, filter = skip })
                if not (tr.Hit or tr.StartSolid) then return spot end
            end
        end
    end

    --########## People aboard a ship are protected from damage from outside
    -- (the Asuran gate beam's blast went through the Tel'tak's hull and killed players in the cargo room; the Puddle
    -- Jumper has its own hook, AGP.JumperProtectsCrew). For every sg_vehicle_base ship: the pilot, players in a seat
    -- parented to the ship and players walking inside it (in its box, with the ship above and below them) take no damage
    -- from outside while the ship stands: first the shield, then the hull takes those hits. Once the ship is destroyed
    -- (Bang) the protection ends. Shots between two players aboard still hurt.
    local function shipOf(e)
        for _ = 1, 4 do
            if not IsValid(e) then return end
            if e.IsSGVehicle or e.AGPHullShip then return e end
            e = e:GetParent()
        end
    end
    AGP.ShipOf = shipOf

    local function inBox(ship, pos)
        local lp = ship:WorldToLocal(pos)
        local mi, ma = ship:OBBMins(), ship:OBBMaxs()
        return lp.x > mi.x and lp.x < ma.x and lp.y > mi.y and lp.y < ma.y and lp.z > mi.z and lp.z < ma.z
    end

    local UP, DOWN = Vector(0, 0, 1200), Vector(0, 0, -1200)
    local function underHull(ship, ply, pos)
        local function hits(d)
            local tr = util.TraceLine({ start = pos, endpos = pos + d, mask = MASK_SOLID,
                filter = function(e) return not IsValid(e) or (e ~= ply and not e:IsPlayer()) end })
            return shipOf(tr.Entity) == ship
        end
        return hits(UP) and hits(DOWN)
    end

    -- the ship pos is aboard (inside the hull), for a player: the player stands in it
    function AGP.ShipAboard(ship, pos, ply)
        return inBox(ship, pos) and underHull(ship, ply, pos)
    end

    local function protectingShip(ply)
        local v = ply:GetVehicle()
        if IsValid(v) then
            local s = shipOf(v:GetParent())
            if IsValid(s) then return s end
        end
        local sv = ply:GetNWEntity("ScriptedVehicle", NULL)
        if IsValid(sv) and (sv.IsSGVehicle or sv.AGPHullShip) and (sv.Pilot == ply or sv.Driver == ply) then return sv end
        local c = ply:WorldSpaceCenter()
        for _, s in ipairs(ents.FindByClass("sg_vehicle_*")) do
            if (s.IsSGVehicle or s.AGPHullShip) and inBox(s, c) and underHull(s, ply, c) then return s end
        end
    end

    hook.Add("EntityTakeDamage", "AGP.ShipProtectsCrew", function(ply, dmg)
        if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return end
        if dmg:IsDamageType(DMG_FALL) or dmg:IsDamageType(DMG_DROWN) then return end
        local ship = protectingShip(ply)
        if not IsValid(ship) or ship.Done or ship.AGPDestroyed then return end
        local inf = dmg:GetInflictor()
        local ic = IsValid(inf) and inf:GetClass() or ""
        local outside = (ic == "energy_laser" or ic == "env_laser") -- the gate weapon's beam and its blast come from outside
        if not outside then
            local src = dmg:GetDamagePosition()
            if src ~= vector_origin and not inBox(ship, src) then outside = true end
        end
        if not outside then
            local att = dmg:GetAttacker()
            if IsValid(att) and att ~= ply and att ~= ship and not att:IsWorld() and shipOf(att) ~= ship and not inBox(ship, att:WorldSpaceCenter()) then outside = true end
        end
        if outside then return true end
    end)

    --########## Sealed ships: the one rule "this player breathes ship air" (AGP 2026-11-14)
    -- Owner: "in our ships when entering water i should have and keep air.... i am in water now and the air countdown is
    -- counting down". A pilot is spectating (sg_vehicle_base, Daedalus, Puddle Jumper) at the ship's position, so the
    -- engine / PowerGrid saw a swimmer. AGP.ShipSealedFor(ply) = the player is the pilot of, sits in a seat of, or stands
    -- inside one of our SEALED ships (a Puddle Jumper with its rear door open is not sealed). A ship that is open to the
    -- air (a platform seat, a hover bike, ...) sets ENT.AGPOpenCockpit = true and never counts. Used by:
    --  * PowerGrid's life support (hook AGP.LS.PlayerSealed, no hard dependency either way): no air drain under water
    --  * the engine's own drowning damage (EntityTakeDamage below)
    -- Space / bad air: PowerGrid asks the same hook there (2026-11-14), except aboard a ship whose own life support is
    -- switched off (the Ha'tak's deliberate "no air on board"; decided in agp_ls_env.lua, not here).
    local function sealedShip(s) return IsValid(s) and not s.AGPOpenCockpit and not s.Done and not s.AGPDestroyed end

    function AGP.ShipSealedFor(ply)
        if not (IsValid(ply) and ply:IsPlayer()) then return false end
        local v = ply:GetVehicle()
        if IsValid(v) then
            local j = v.IsJumperSeat and v.Jumper
            if IsValid(j) then return not j.door end
            local s = shipOf(v:GetParent())
            if sealedShip(s) then return true end
        end
        local sv = ply:GetNWEntity("ScriptedVehicle", NULL)
        if sealedShip(sv) and (sv.Pilot == ply or sv.Driver == ply) then return true end
        local c = ply:WorldSpaceCenter()
        for _, j in ipairs(ents.FindByClass("puddle_jumper")) do
            if not j.door and (j.Pilot == ply or inBox(j, c)) then return true end
        end
        for _, s in ipairs(ents.FindByClass("sg_vehicle_*")) do
            if sealedShip(s) and (s.IsSGVehicle or s.AGPHullShip) and inBox(s, c) and underHull(s, ply, c) then return true end
        end
        return false
    end

    hook.Add("AGP.LS.PlayerSealed", "AGP.ShipSealed", function(ply)
        if AGP.ShipSealedFor(ply) then return true end
    end)

    -- the engine's drowning (sandbox has it too) does not hurt people aboard a sealed ship (the Jumper has its own hook)
    hook.Add("EntityTakeDamage", "AGP.ShipSealedNoDrown", function(ply, dmg)
        if not (IsValid(ply) and ply:IsPlayer() and dmg:IsDamageType(DMG_DROWN)) then return end
        if ply:WaterLevel() >= 3 and AGP.ShipSealedFor(ply) then return true end   -- (suit damage in vacuum is not water: stays)
    end)

    -- Spacebuild (CAF Life Support) next to us (owner 2026-11-14: "i see the game window and spacebuild is also counting down
    -- the air not only our addon"): CAF checks every player itself (Player:LsCheck, in its autorun on EVERY map) - under
    -- water it takes 5 air a second from the suit and then health, in space air / heat / pressure - and knows nothing of our
    -- ships. It has no hook for "this player has air" (its air exchangers are found by distance from an entity, which would
    -- also feed a swimmer beside the ship). So for a player aboard one of our sealed ships CAF's check is skipped and the
    -- suit is kept as it is (air at least 100, CAF's "breathable" value); the moment the player leaves the ship, CAF judges
    -- them again. Only wraps when CAF's function exists; put on again if CAF defines it anew.
    local function wrapCAF()
        local PLY = FindMetaTable("Player")
        local cur = PLY and PLY.LsCheck
        if not cur or cur == PLY.AGPLsCheckSealed then return end
        local orig = cur
        local function sealedCheck(ply, ...)
            if ply.suit and AGP.ShipSealedFor(ply) then
                if (ply.suit.air or 0) < 100 then ply.suit.air = 100 end
                local SB = CAF and CAF.GetAddon and CAF.GetAddon("Spacebuild")
                if ply.UpdateLSClient and (ply.environment or not (SB and SB.GetStatus and SB.GetStatus())) then ply:UpdateLSClient() end
                return
            end
            return orig(ply, ...)
        end
        PLY.LsCheck = sealedCheck
        PLY.AGPLsCheckSealed = sealedCheck
    end
    hook.Add("InitPostEntity", "AGP.ShipSealedCAF", wrapCAF)
    timer.Create("AGP.ShipSealedCAF", 15, 0, wrapCAF)   -- (CAF addons can be switched on later in its menu)
    wrapCAF()

    --########## DHD key: Supergates only
    --########## Where a pilot gets out (2026-10-30, owner: realistic, not too safe; order fixed 2026-11-08)
    -- cabin = true (hollow crafts: Puddle Jumper, Tel'tak): the cabin floor spot `want` when one can stand there.
    -- Every other craft, always in this order (owner 2026-11-08: "a little underneath; if that is blocked, to the side;
    -- if the side is blocked, above"):
    --  1. a little under the hull, below its real underside at the middle (high up you fall from there)
    --  2. beside the hull (right, left, then front, back), on the ground or whatever is below when it is near
    --  3. on top of the hull
    -- Before, "under" was measured from the hull box at the model's origin and checked against the ship's own parts
    -- (its shield bubble), and "beside" used the bounding sphere: on long ships that was far away, so it looked random.
    function AGP.ShipExitSpot(ship, ply, want, cabin)
        if cabin and want and AGP.PlayerStandSpot then
            local s = AGP.PlayerStandSpot(want, ply, nil, 40, 120)
            if s then return s end
        end
        local mins, maxs = Vector(-16, -16, 0), Vector(16, 16, 72)
        -- the hull itself counts as solid (never inside it), its parts and shield bubble do not
        local function notShip(e) return not (e == ply or (e ~= ship and AGP.ShipPart and AGP.ShipPart(ship, e))) end
        local function free(p)
            if not util.IsInWorld(p) or not util.IsInWorld(p + Vector(0, 0, 72)) then return false end
            local tr = util.TraceHull({ start = p, endpos = p, mins = mins, maxs = maxs, filter = notShip, mask = MASK_PLAYERSOLID })
            return not (tr.Hit or tr.StartSolid)
        end
        -- the hull's own surface where a line towards the ship meets it (only the ship counts)
        local function hullAt(from, to)
            local tr = util.TraceLine({ start = from, endpos = to, ignoreworld = true, filter = function(e) return e == ship end })
            return tr.Hit and tr.HitPos or nil
        end
        local c = ship:WorldSpaceCenter()
        local r = ship:BoundingRadius()
        local mn, mx = ship:OBBMins(), ship:OBBMaxs()
        local half = (mx - mn) * 0.5

        -- 1. under the hull
        local bottom = hullAt(c - Vector(0, 0, r + 300), c) or ship:LocalToWorld(Vector((mn.x + mx.x) * 0.5, (mn.y + mx.y) * 0.5, mn.z))
        local below = bottom - Vector(0, 0, 72 + 16)
        if free(below) then return below end

        -- 2. beside it, a little out from the hull box, at the height of the hull's underside; down onto the ground
        local low = math.min(bottom.z, c.z)
        local f, rt = ship:GetForward(), ship:GetRight()
        for _, dir in ipairs({ rt, -rt, f, -f }) do
            dir = Vector(dir.x, dir.y, 0)
            if dir:LengthSqr() > 0.01 then
                dir:Normalize()
                local reach = math.abs(dir:Dot(f)) * half.x + math.abs(dir:Dot(rt)) * half.y + math.abs(dir:Dot(ship:GetUp())) * half.z
                local side = Vector(c.x, c.y, low) + dir * (reach + 48)
                if free(side) then
                    local tr = util.TraceHull({ start = side, endpos = side - Vector(0, 0, 4000), mins = mins, maxs = maxs, filter = notShip, mask = MASK_PLAYERSOLID })
                    return tr.Hit and (tr.HitPos + Vector(0, 0, 2)) or side
                end
                -- the ship sits low: the spot at the underside is in the ground, try standing height above it
                local up = side + Vector(0, 0, 80)
                if free(up) then
                    local tr = util.TraceHull({ start = up, endpos = up - Vector(0, 0, 200), mins = mins, maxs = maxs, filter = notShip, mask = MASK_PLAYERSOLID })
                    return tr.Hit and (tr.HitPos + Vector(0, 0, 2)) or up
                end
            end
        end

        -- 3. on top of the hull
        local top = hullAt(c + Vector(0, 0, r + 300), c)
        if top and free(top + Vector(0, 0, 4)) then return top + Vector(0, 0, 4) end
        return want or ship:GetPos()
    end

    --########## Back from a ship, chair, MALP or KINO (2026-11-08): CAP gets the player out of spectating with Spawn(),
    -- which also runs every spawn hook: a Ha'tak bunk moved the player into its barracks after leaving any ship, and the
    -- (suit) armour and the reserve ammo were reset. Spawn hooks can tell by ply.AGPShipLeaving; armour and ammo come back.
    function AGP.ShipRespawnPilot(ply)
        if not IsValid(ply) then return end
        local armor, ammo = ply:Armor(), ply:GetAmmo()
        ply.AGPShipLeaving = true
        ply:Spawn()
        ply.AGPShipLeaving = nil
        ply:SetArmor(armor)
        timer.Simple(0, function()   -- after the craft gave the weapons back (each Give adds a clip's worth)
            if not IsValid(ply) then return end
            for id, n in pairs(ammo) do ply:SetAmmo(n, id) end
        end)
    end

    --########## A ship that hovers while parked (Tel'tak, Puddle Jumper) hovers where it was put down with the physgun or
    -- gravity gun, instead of pulling back to its old spot (it spun and lagged, like the old hangar)
    local function parkHere(_, e) if (IsValid(e) and e.HoverPos and not e.Inflight) then e.HoverPos = e:GetPos() end end
    hook.Add("PhysgunDrop", "AGP.ShipHoverHere", parkHere)
    hook.Add("GravGunOnDropped", "AGP.ShipHoverHere", parkHere)
    hook.Add("OnPhysgunFreeze", "AGP.ShipHoverHere", function(_, _, e) parkHere(nil, e) end)

    --########## Aiming (2026-11-08): every gun goes where the crosshair is - the point the pilot's camera looks at
    -- (AGP.ShipCrosshair, lua/autorun/agp_ship_aim.lua). ShipAimPoint is that point only while Mouse2 (TRACK) is held:
    -- for the weapons that fire on Mouse2 (Destiny's turrets, the O'Neill's Asgard beam). ShipAimDir always aims, only
    -- into the front half (guns do not shoot backwards through the hull).
    function AGP.ShipAimPoint(ship)
        local p = ship.Pilot
        if not (IsValid(p) and p.KeyDown and p:KeyDown(ship.Vehicle, "TRACK")) then return nil end
        return AGP.ShipCrosshair(ship)
    end

    function AGP.ShipAimDir(ship, from)
        return AGP.ShipAimCone(ship, from)
    end

    -- Mouse2 (TRACK) volley of the big ships (owner 2026-10-30: Mouse2 only aimed, so it seemed to do nothing).
    -- One press: o.count shots of o.class at the crosshair, spread over the hull's front, then o.cool seconds pause.
    -- Holding Mouse2 still aims the main guns (AGP.ShipAimDir). Call from the ship's server Think with a pilot aboard.
    function AGP.ShipVolley(ship, o)
        local p = ship.Pilot
        if not IsValid(p) or not AGP.KeyPress(ship, p, ship.Vehicle, "TRACK") then return end
        if CurTime() < (ship.AGPNextVolley or 0) then return end
        ship.AGPNextVolley = CurTime() + (o.cool or 8)
        ship:SetNWFloat("AGPVolleyAt", ship.AGPNextVolley)
        local r = ship:BoundingRadius()
        -- the crosshair point at the moment of the press (a quick tap counts; ShipAimPoint needs Mouse2 held)
        local aim = AGP.ShipCrosshair(ship, p)
        for i = 1, o.count or 6 do
            timer.Simple(i * (o.gap or 0.12), function()
                if not IsValid(ship) then return end
                local from = ship:GetPos() + ship:GetForward() * r * (o.front or 0.3) + ship:GetRight() * math.Rand(-1, 1) * r * (o.wide or 0.25)
                    + ship:GetUp() * math.Rand(-1, 1) * r * 0.08
                local dir = (aim - from):GetNormalized()
                if (dir:Dot(ship:GetForward()) < 0.1) then dir = ship:GetForward() end
                local e = ents.Create(o.class or "energy_pulse")
                if not IsValid(e) then return end
                e:PrepareBullet((dir + VectorRand() * (o.spread or 0.015)):GetNormalized(), 10, o.speed or 16000, o.size or 6, { ship })
                e:SetPos(from)
                e:SetOwner(ship)
                e.Owner = ship
                e:Spawn()
                e:Activate()
                if o.color then e:SetColor(o.color) end
                if o.damage then e.Damage = o.damage end   -- (2026-11-07 balance) the ship's own bolt damage
                if o.sound then ship:EmitSound(o.sound, 90, math.random(100, 120)) end
            end)
        end
    end

    -- the ship blows up (sg_vehicle_base ENT:Bang): one big blast (effects/agp_ship_explosion.lua) and a chain of
    -- smaller ones along the hull, sized to the ship. Only positions are kept, so the ship can be removed right away.
    local BLASTS = { "ambient/explosions/explode_1.wav", "ambient/explosions/explode_2.wav", "ambient/explosions/explode_3.wav", "ambient/explosions/explode_4.wav" }
    function AGP.ShipExplosion(ship)
        local pos = ship:WorldSpaceCenter()
        local r = math.max(80, ship:BoundingRadius())
        local function blast(at, rad, scale)
            local fx = EffectData()
            fx:SetOrigin(at)
            fx:SetMagnitude(rad)
            fx:SetScale(scale)
            util.Effect("agp_ship_explosion", fx, true, true)
        end
        blast(pos, r, 1)
        sound.Play("ambient/explosions/explode_8.wav", pos, 140, r > 1000 and 70 or 95, 1)
        util.ScreenShake(pos, r > 1000 and 16 or 8, 120, r > 1000 and 3 or 1.5, r * 8)
        local spots = {}
        for i = 1, math.Clamp(math.floor(r / 150), 3, 12) do
            spots[i] = ship:LocalToWorld(Vector(math.Rand(ship:OBBMins().x, ship:OBBMaxs().x), math.Rand(ship:OBBMins().y, ship:OBBMaxs().y), math.Rand(ship:OBBMins().z, ship:OBBMaxs().z)) * 0.8)
        end
        for i, at in ipairs(spots) do
            timer.Simple(0.12 + i * math.Rand(0.08, 0.18), function()
                blast(at, r * math.Rand(0.25, 0.4), 0.5)
                sound.Play(BLASTS[math.random(#BLASTS)], at, 120, math.random(85, 110), 0.8)
            end)
        end
    end

    function AGP.FindSupergate(pos, dist)
        local gate
        for _, v in pairs(ents.FindByClass("stargate_*")) do
            if (v.IsStargate and v.IsSupergate) then
                local d = pos:Distance(v:GetPos())
                if d <= dist then dist = d; gate = v end
            end
        end
        return gate
    end

    function AGP.OpenSupergateDHD(ship, p)
        if not IsValid(p) then return end
        if (ship.AGPNextDHD or 0) > CurTime() then return end
        ship.AGPNextDHD = CurTime() + 1
        local e = AGP.FindSupergate(ship:GetPos(), ship.AGPSupergateRange or 20000)
        if not IsValid(e) then
            -- AGP 2026-10-30: no Supergate around: the nearest normal Stargate close to the ship
            local best = 4000
            for _, v in ipairs(ents.FindInSphere(ship:GetPos(), best)) do
                if (v.IsStargate and not v.IsSupergate and v:GetClass():find("^stargate_")) then
                    local d = ship:GetPos():Distance(v:GetPos())
                    if d < best then best = d; e = v end
                end
            end
        end
        if not IsValid(e) then
            if AGP.Say then AGP.Say(p, "agp_ship_no_supergate", "No Stargate in range: the DHD key (R) dials a Supergate within 20000 units or a Stargate within 4000 units.") end
            return
        end
        if (hook.Call("StarGate.Player.CanDialGate", GAMEMODE, p, e) == false) then return end
        net.Start("StarGate.VGUI.Menu")
        net.WriteEntity(e)
        net.WriteInt(1, 8)
        net.Send(p)
    end

    -- the keys go through the StarGate keyboard: one press = one toggle / one menu (no repeat while held)
    hook.Add("StarGate.Player.KeyPressed", "AGP.ShipShieldKeys", function(p, name, k)
        if (k ~= "SHIELD" and k ~= "DHD") then return end
        local ship = p:GetNetworkedEntity("ScriptedVehicle", NULL)
        if not IsValid(ship) or ship.Vehicle ~= name then return end
        if (ship.Pilot ~= p and ship.Driver ~= p) then return end
        if (k == "SHIELD" and ship.AGPShield) then
            AGP.ShipShieldToggle(ship)
        elseif (k == "DHD" and ship.AGPSupergateDHD) then
            AGP.OpenSupergateDHD(ship, p)
        end
    end)
else
    --########## HUD text: "Shield 87 %", "Shield depleted" or "Shield off" and a colour
    function AGP.ShipShieldText(ship)
        local L = AGP.L or function(_, d, ...) return string.format(d, ...) end
        if ship:GetNWBool("AGPShieldOn", false) then
            return L("agp_ship_shield_up", "Shield: %d %%", ship:GetNWInt("AGPShieldStrength", 100)), Color(120, 200, 255, 255)
        elseif ship:GetNWBool("AGPShieldDepleted", false) then
            return L("agp_ship_shield_depleted", "Shield: depleted"), Color(255, 140, 60, 255)
        end
        return L("agp_ship_shield_off", "Shield: off"), Color(180, 180, 180, 255)
    end
end
