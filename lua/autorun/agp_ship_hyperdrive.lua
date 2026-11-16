-- Ascension Gates (2026-10-30): hyperdrive for the pilotable big ships (Daedalus, Prometheus, O'Neill, Aurora, Wraith
-- cruiser, Al'kesh; Destiny: FTL). Built like the Tel'tak's: hold the HYPERSPACE key (H) to charge the distance, release
-- it (or reach full charge) to jump forward by that distance, or towards the Wire "Hyperspace" target when one is set.
--  * The ship sets ENT.AGPHyperRange (max distance), optional ENT.AGPHyperChargeTime (s to full), ENT.AGPHyperFTL (Destiny
--    look and sounds), ENT.AGPHyperSharedHUD (shared, for a ship without its own HUD: a small box at the bottom).
--  * Server: AGP.ShipHyperdriveThink(ship) from the ship's Think, AGP.ShipHyperdriveInput(ship, k, v) from TriggerInput.
--  * Client: AGP.ShipHyperdriveText(ship) for the ship HUDs, hook AGP.ShipHyperdriveHUD for AGPHyperSharedHUD ships.
--  * Safety: the way is traced with the hull (a cube of its thinnest side; the long axis by its extent along the jump)
--    and the jump is shortened to the last free spot inside the map; no jump while cloaked; 10 s cooldown.
--  * The pilot (spectating the ship) and players standing aboard travel along.
-- NW values on the ship: AGPHyperCharge (0-100), AGPHyperReady (CurTime when the cooldown ends), AGPHyperJump, AGPHyperFTL.
AddCSLuaFile()
AGP = AGP or {}

local MIN_CHARGE = 0.2   -- a release under 20 % cancels (like the Tel'tak's quarter)
local COOLDOWN = 10
local DEFAULT_RANGE = 20000

if SERVER then
    local function pilotOf(ship)
        if ship.Inflight and IsValid(ship.Pilot) then return ship.Pilot end
        if ship.Active and IsValid(ship.Driver) then return ship.Driver end -- Daedalus
    end

    local function say(ply, key, fallback, ...)
        if AGP.Say and IsValid(ply) then AGP.Say(ply, key, fallback, ...) end
    end

    local function cloaked(ship)
        return ship.Cloaked or ship:GetNWBool("Cloaked", false) or ship:GetNWBool("cloaked", false)
    end

    -- what the jump test ignores: the ship, everything parented to it (any depth: its shield bubble sits on the
    -- shield generator), its welded props, its shield, players and NPCs. The shield bubble used to block the test,
    -- so a jump with the shield up was "cancelled: no free space".
    local function solidFilter(ship)
        local own = {}
        for _, e in pairs(constraint.GetAllConstrainedEntities(ship) or {}) do own[e] = true end
        return function(e)
            if not IsValid(e) then return true end
            if own[e] or e == ship or e.Parent == ship or e:IsPlayer() or e:IsNPC() then return false end
            local c = e:GetClass()
            if c == "ship_shield" or c == "ship_shield_generator" then return false end
            local p = e:GetParent()
            for _ = 1, 4 do
                if not IsValid(p) then break end
                if p == ship then return false end
                p = p:GetParent()
            end
            return true
        end
    end

    -- the hull: half extents and a cube of the thinnest side (world traces are axis-aligned)
    local function hullOf(ship)
        local mn, mx = ship:OBBMins(), ship:OBBMaxs()
        local half = (mx - mn) * 0.5
        local s = math.max(math.min(half.x, half.y, half.z) * 0.8, 24)
        return half, Vector(-s, -s, -s), Vector(s, s, s), s
    end

    -- the ship moved by delta: every hull corner inside the map, the core free of world and props
    local function spotFree(ship, delta, cmin, cmax, filter)
        local mn, mx = ship:OBBMins(), ship:OBBMaxs()
        for _, x in ipairs({ mn.x, mx.x }) do for _, y in ipairs({ mn.y, mx.y }) do for _, z in ipairs({ mn.z, mx.z }) do
            if not util.IsInWorld(ship:LocalToWorld(Vector(x, y, z)) + delta) then return false end
        end end end
        local c = ship:LocalToWorld(ship:OBBCenter()) + delta
        local tr = util.TraceHull({ start = c, endpos = c, mins = cmin, maxs = cmax, mask = MASK_SOLID, filter = filter })
        return not (tr.Hit or tr.StartSolid)
    end

    -- how far the ship can go along dir (at most dist): nil when not even a short jump is free
    function AGP.ShipHyperdriveFreeDistance(ship, dir, dist)
        local half, cmin, cmax, s = hullOf(ship)
        local f, r, u = ship:GetForward(), ship:GetRight(), ship:GetUp()
        local reach = math.abs(dir:Dot(f)) * half.x + math.abs(dir:Dot(r)) * half.y + math.abs(dir:Dot(u)) * half.z
        local filter = solidFilter(ship)
        local start = ship:LocalToWorld(ship:OBBCenter())
        local len = dist + reach
        local tr = util.TraceHull({ start = start, endpos = start + dir * len, mins = cmin, maxs = cmax, mask = MASK_SOLID, filter = filter })
        local free = dist
        if tr.Hit then free = math.min(dist, tr.Fraction * len + s - reach - 64) end
        -- step back until the whole hull fits inside the map
        local step = math.max(dist / 12, 250)
        while free >= 500 do
            if spotFree(ship, dir * free, cmin, cmax, filter) then return free end
            free = free - step
        end
    end

    local function window(pos, normal, radius, life)
        local fx = EffectData()
        fx:SetOrigin(pos); fx:SetNormal(normal); fx:SetScale(radius); fx:SetMagnitude(life)
        util.Effect("agp_hyperwindow", fx, true, true)
    end
    AGP.ShipHyperWindow = window

    -- AGP 2026-11-08: the window a ship comes out of stays BEHIND it (owner: it has left hyperspace, so the window is at
    -- its stern, not ahead of it). Call right after the ship was moved to the target; dir = the way it travelled.
    function AGP.ShipHyperArrive(ship, dir, radius, life)
        local f, r, u = ship:GetForward(), ship:GetRight(), ship:GetUp()
        local mn, mx = ship:OBBMins(), ship:OBBMaxs()
        local half = (mx - mn) * 0.5
        local reach = math.abs(dir:Dot(f)) * half.x + math.abs(dir:Dot(r)) * half.y + math.abs(dir:Dot(u)) * half.z
        window(ship:LocalToWorld(ship:OBBCenter()) - dir * (reach + radius * 0.15), dir, radius, life)
    end

    -- move the ship by delta: hull, pilot and players standing aboard
    local function moveShip(ship, delta)
        local pilot = pilotOf(ship)
        local carry = {}
        if AGP.ShipAboard then
            for _, p in ipairs(player.GetAll()) do
                if p ~= pilot and p:Alive() and not p:InVehicle() and p:GetPos():Distance(ship:GetPos()) < ship:BoundingRadius()
                    and AGP.ShipAboard(ship, p:WorldSpaceCenter(), p) then
                    carry[#carry + 1] = p
                end
            end
        end
        -- AGP 2026-10-30: props welded/constrained to the ship come along (they stayed behind before)
        local parts = {}
        for _, e in pairs(constraint.GetAllConstrainedEntities(ship) or {}) do
            if IsValid(e) and e ~= ship and not e:IsWorld() and not e:IsPlayer() and e:GetParent() ~= ship then
                parts[#parts + 1] = e
            end
        end
        local dest = ship:GetPos() + delta
        local ang = ship:GetAngles()
        ship:SetPos(dest)
        local ph = ship:GetPhysicsObject()
        if IsValid(ph) then local v = ph:GetVelocity(); ph:SetPos(dest); ph:SetAngles(ang); ph:SetVelocity(v); ph:Wake() end -- AGP: it keeps its speed
        ship.HoverPos = dest
        if IsValid(pilot) then pilot:SetPos(dest) end
        for _, e in ipairs(parts) do
            local np = e:GetPos() + delta
            e:SetPos(np)
            local eph = e:GetPhysicsObject()
            if IsValid(eph) then eph:SetPos(np); eph:SetVelocity(Vector(0, 0, 0)) end
            if e.HoverPos then e.HoverPos = np end
        end
        for _, p in ipairs(carry) do p:SetPos(p:GetPos() + delta); p:SetVelocity(-p:GetVelocity()) end
    end
    AGP.ShipMove = moveShip   -- also used by the Tel'tak's own hyperdrive

    -- the jump: a window opens in front, the ship goes through, a window at the target
    local function jump(ship, dist, target)
        local ftl = ship.AGPHyperFTL
        local radius = math.Clamp(ship:BoundingRadius() * 0.7, 200, 3000)
        local delay = ftl and 0.6 or 1.0
        ship.AGPHyperJumping = true
        ship:SetNWBool("AGPHyperJump", true)
        local fwd = ship:GetForward()
        local wdir = target and (target - ship:GetPos()):GetNormalized() or fwd
        -- AGP: the window opens where the ship will be when it jumps (a moving ship flew past a window left behind)
        local lead = ship:GetVelocity() * delay
        window(ship:LocalToWorld(ship:OBBCenter()) + lead + wdir * radius * 1.4, -wdir, radius, delay + (ftl and 0.4 or 0.8))
        ship:EmitSound(ftl and "eap/hyperespace/destiny_ftl_jump_in.wav" or "eap/hyperespace/hyper_window_open.wav", 140)
        timer.Simple(delay, function()
            if not IsValid(ship) then return end
            ship.AGPHyperJumping = nil
            ship:SetNWBool("AGPHyperJump", false)
            ship.AGPHyperNext = CurTime() + COOLDOWN
            ship:SetNWFloat("AGPHyperReady", ship.AGPHyperNext)
            if ship.Done or ship.AGPDestroyed then return end
            local pilot = pilotOf(ship)
            local dir, want = ship:GetForward(), dist
            if target then
                local d = target - ship:GetPos()
                want = math.min(dist, d:Length())
                if want < 1 then return end
                dir = d:GetNormalized()
            end
            local free = AGP.ShipHyperdriveFreeDistance(ship, dir, want)
            if not free then
                say(pilot, "agp_hyper_msg_blocked", "No free space for the ship there: the jump was cancelled.")
                ship:EmitSound("buttons/button10.wav", 90)
                return
            end
            if free < want - 1 then
                say(pilot, "agp_hyper_msg_shortened", "The way is blocked: the jump was shortened to %d units.", math.floor(free))
            end
            moveShip(ship, dir * free)
            local c = ship:LocalToWorld(ship:OBBCenter())
            AGP.ShipHyperArrive(ship, dir, radius, ftl and 0.9 or 1.8)   -- AGP 2026-11-08: behind the ship (was ahead of it)
            sound.Play(ftl and "eap/hyperespace/destiny_ftl_jump_out.wav" or "eap/hyperespace/hyper_window_close.wav", c, 140)
        end)
    end

    -- call from the ship's Think
    function AGP.ShipHyperdriveThink(ship)
        if not IsValid(ship) then return end
        local now = CurTime()
        local dt = math.Clamp(now - (ship.AGPHyperLast or now), 0, 0.5)
        ship.AGPHyperLast = now
        if ship.AGPHyperFTL and not ship.AGPHyperFTLSent then ship.AGPHyperFTLSent = true; ship:SetNWBool("AGPHyperFTL", true) end
        local range = ship.AGPHyperRange or DEFAULT_RANGE
        local pilot = pilotOf(ship)
        local held = IsValid(pilot) and pilot:KeyDown(ship.Vehicle, "HYPERSPACE") or false
        local pressed = held and not ship.AGPHyperKeyWas
        ship.AGPHyperKeyWas = held
        local dist = ship.AGPHyperDist or 0

        if not IsValid(pilot) or ship.AGPHyperJumping then
            dist = 0
        elseif held then
            if (ship.AGPHyperNext or 0) > now then
                if pressed then say(pilot, "agp_hyper_msg_cooldown", "The hyperdrive is cooling down: %d s.", math.ceil(ship.AGPHyperNext - now)) end
                dist = 0
            elseif cloaked(ship) then
                if pressed then say(pilot, "agp_hyper_msg_cloaked", "Decloak first: the hyperdrive cannot jump while the ship is cloaked.") end
                dist = 0
            else
                dist = math.min(range, dist + range / (ship.AGPHyperChargeTime or 4) * dt)
                if dist >= range then -- full: jump now (the key has to be let go before the next charge)
                    jump(ship, dist, ship.AGPHyperTarget)
                    dist = 0
                    ship.AGPHyperKeyWas = true
                    ship.AGPHyperBlockUntilRelease = true
                end
            end
            if ship.AGPHyperBlockUntilRelease then dist = 0 end
        elseif dist > 0 then -- released
            if dist >= range * MIN_CHARGE then
                jump(ship, dist, ship.AGPHyperTarget)
            else
                say(pilot, "agp_hyper_msg_short", "Hold the hyperspace key longer (at least %d %%) to jump.", MIN_CHARGE * 100)
            end
            dist = 0
        end
        if not held then ship.AGPHyperBlockUntilRelease = nil end
        ship.AGPHyperDist = dist
        local pct = math.floor(dist / range * 100)
        if ship:GetNWInt("AGPHyperCharge", 0) ~= pct then ship:SetNWInt("AGPHyperCharge", pct) end
        if ship:GetNWInt("AGPHyperRange", 0) ~= range then ship:SetNWInt("AGPHyperRange", range) end
    end

    -- Wire "Hyperspace [VECTOR]": the jump target (0 0 0 clears it). Returns true when handled.
    function AGP.ShipHyperdriveInput(ship, k, v)
        if k ~= "Hyperspace" then return false end
        if isvector(v) and v ~= Vector(0, 0, 0) then ship.AGPHyperTarget = Vector(v) else ship.AGPHyperTarget = nil end
        ship:SetNWBool("AGPHyperTarget", ship.AGPHyperTarget ~= nil)
        return true
    end
else
    local L = function(...) return (AGP.L or function(_, d, ...) return string.format(d, ...) end)(...) end

    -- HUD line: "Hyperdrive: 45 %", "... cooling down 7 s", "... ready" and a colour
    function AGP.ShipHyperdriveText(ship)
        if not IsValid(ship) then return end
        local label = ship:GetNWBool("AGPHyperFTL", false) and L("agp_hyper_label_ftl", "FTL drive") or L("agp_hyper_label", "Hyperdrive")
        if ship:GetNWBool("AGPHyperJump", false) then
            return L("agp_hyper_jumping", "%s: jump!", label), Color(255, 255, 255, 255)
        end
        local pct = ship:GetNWInt("AGPHyperCharge", 0)
        if pct > 0 then
            return L("agp_hyper_charging", "%s: %d %% (%d units)", label, pct, math.floor(pct / 100 * ship:GetNWInt("AGPHyperRange", 0))), Color(150, 200, 255, 255)
        end
        local cool = ship:GetNWFloat("AGPHyperReady", 0) - CurTime()
        if cool > 0 then
            return L("agp_hyper_cooldown", "%s: cooling down %d s", label, math.ceil(cool)), Color(255, 170, 80, 255)
        end
        if ship:GetNWBool("AGPHyperTarget", false) then
            return L("agp_hyper_ready_target", "%s: ready (Wire target)", label), Color(180, 230, 180, 255)
        end
        return L("agp_hyper_ready", "%s: ready", label), Color(180, 230, 180, 255)
    end

    -- ships without an own HUD (ENT.AGPHyperSharedHUD): a small box at the bottom, like the Tel'tak's
    hook.Add("HUDPaint", "AGP.ShipHyperdriveHUD", function()
        local ship = LocalPlayer():GetNWEntity("ScriptedVehicle", NULL)
        if not (IsValid(ship) and ship.AGPHyperSharedHUD) then return end
        local text, col = AGP.ShipHyperdriveText(ship)
        if not text then return end
        draw.WordBox(8, ScrW() / 2 - 120, ScrH() * 0.86, text, "ScoreboardText", Color(20, 30, 50, 170), col)
        if AGP.ShipShieldText then
            local s, sc = AGP.ShipShieldText(ship)
            draw.WordBox(8, ScrW() / 2 - 120, ScrH() * 0.86 - 38, s, "ScoreboardText", Color(20, 30, 50, 170), sc)
        end
    end)
end
