--[[
	Tollan Phase Device (Ascension Gates)
	A wrist phase shifter as worn by the Tollan: it shifts the wearer out of phase so he can walk through solid matter.
	Left click: phase through the wall, door or prop in front of you (up to PhaseMaxThick units thick).
	Right click near an open outgoing Stargate: phase through the wormhole and come out in front of the target gate,
	even when its iris is closed (as the Tollan did through Earth's iris).
	An active Anti-phase device (agp_anti_phase) near the start or the end point stops both.
	Everything is decided on the server; the client only draws the shimmer and a small HUD line.
]]
SWEP.PrintName = AGP.L("agp_wp_tollan_phase", "Tollan Phase Device")
SWEP.Category = (SGLanguage and SGLanguage.GetMessage) and SGLanguage.GetMessage("weapon_misc_cat") or "Misc Weapons"   -- AGP: one of our two weapon folders (was "Player Weapons": a folder of its own)
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
    SWEP.Category = SGLanguage.GetMessage("weapon_cat")
end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Ascension Gates"
SWEP.Purpose = AGP.L("agp_wp_tollan_phase_purpose", "Tollan wrist device: lets you pass through solid matter.")
SWEP.Instructions = AGP.L("agp_wp_tollan_phase_instr", "Left click: phase through the wall in front of you. Right click near an open outgoing Stargate: phase to the target gate, even through a closed iris.")
SWEP.Slot = 5
SWEP.SlotPos = 6
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"   -- never drawn: a wrist device, no hands on screen
SWEP.WorldModel = ""   -- nothing in the world: the wrist glow is drawn after the player model (PostPlayerDraw below)
SWEP.UseHands = false
SWEP.ViewModelFOV = 54

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.PhaseCooldown = 1.5
-- AGP: 64 left only 48 units between you and the wall (your body is 16 wide each side), so from a normal step away
-- it said "look at a wall" while you did; 100 = about two metres
SWEP.PhaseReach = 100       -- the wall must be at most this far in front of your eyes
SWEP.PhaseMaxThick = 160    -- the thickest matter you can phase through
SWEP.GateRange = 300        -- right click: an open gate must be this close
SWEP.AntiPhaseRadius = 600  -- fallback when an anti-phase device has no own radius

if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("agp_tollan_phase_fx")
end

function SWEP:Initialize()
    self:SetHoldType("normal")
end

-- AGP: the view model is no longer switched off with Player:DrawViewModel(false) on Deploy. That switch belongs to
-- the player, not to this weapon: when the device left the hand without Holster (death, dropped, stripped
-- - OnRemove then has no owner any more) it could stay off, and every weapon after it would show no hands and no
-- model in first person. ShouldDrawViewModel below hides this weapon's (empty) view model on its own.
function SWEP:Deploy()
    return true
end

function SWEP:ShouldDrawViewModel() return false end
function SWEP:Reload() end

-- AGP: never left lying around - without a world model a dropped one was an invisible pick-up (on death or
-- dropped); GMod's fists do the same
function SWEP:ShouldDropOnDie() return false end
if SERVER then
    function SWEP:OnDrop() self:Remove() end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.PhaseCooldown)
    self:SetNextSecondaryFire(CurTime() + self.PhaseCooldown)
    if (SERVER) then self:PhaseWall() end
end

function SWEP:SecondaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.PhaseCooldown)
    self:SetNextSecondaryFire(CurTime() + self.PhaseCooldown)
    if (SERVER) then self:PhaseGate() end
end

if SERVER then
    local function say(ply, key, fallback, ...)
        if (AGP and AGP.Say) then AGP.Say(ply, key, fallback, ...) elseif (IsValid(ply)) then ply:ChatPrint(fallback) end
    end

    -- an active anti-phase device covers this point?
    function SWEP:AntiPhaseAt(pos)
        for _, e in ipairs(ents.FindByClass("agp_anti_phase")) do
            if (IsValid(e) and e.GetOn and e:GetOn()) then
                local r = e.PhaseRadius or self.AntiPhaseRadius
                if (e:GetPos():DistToSqr(pos) <= r * r) then return e end
            end
        end
    end

    function SWEP:Deny(ply, key, fallback, ...)
        say(ply, key, fallback, ...)
        ply:EmitSound("buttons/button10.wav", 60, 110)
        -- a failed try costs less than a phase
        self:SetNextPrimaryFire(CurTime() + 0.5)
        self:SetNextSecondaryFire(CurTime() + 0.5)
    end

    local function hullOf(ply)
        if (ply:Crouching()) then return ply:GetHullDuck() end
        return ply:GetHull()
    end

    -- the player hull fits at feet position pos (nothing solid, inside the map)
    local function hullFits(ply, pos, mins, maxs)
        if (not util.IsInWorld(pos + Vector(0, 0, 2)) or not util.IsInWorld(pos + Vector(0, 0, maxs.z - 2))) then return false, "world" end
        local tr = util.TraceHull({ start = pos, endpos = pos, mins = mins, maxs = maxs, mask = MASK_PLAYERSOLID, filter = ply })
        if (tr.Hit or tr.StartSolid) then return false, "solid" end
        return true
    end

    -- is the point itself in free space (used to tell "too thick" from "no room")
    local function pointFree(ply, pos)
        if (not util.IsInWorld(pos)) then return false end
        local tr = util.TraceHull({ start = pos, endpos = pos, mins = Vector(-1, -1, -1), maxs = Vector(1, 1, 1), mask = MASK_PLAYERSOLID, filter = ply })
        return not (tr.Hit or tr.StartSolid)
    end

    function SWEP:Shimmer(ply, from, to)
        local rf = RecipientFilter()
        rf:AddPVS(from); rf:AddPVS(to)
        net.Start("agp_tollan_phase_fx")
        net.WriteVector(from); net.WriteVector(to)
        net.WriteEntity(ply)
        net.Send(rf)
        sound.Play("ambient/machines/teleport1.wav", from, 65, 160, 0.6)
        sound.Play("ambient/levels/citadel/weapon_disintegrate2.wav", to, 65, 140, 0.5)
    end

    function SWEP:MovePlayer(ply, dest, ang)
        local from = ply:GetPos()
        local mins, maxs = hullOf(ply)
        local center = Vector(0, 0, (mins.z + maxs.z) / 2)
        if (IsValid(ply:GetVehicle())) then ply:ExitVehicle() end
        ply:SetPos(dest)
        ply:SetVelocity(-ply:GetVelocity())
        if (ang) then ply:SetEyeAngles(ang) end
        self:Shimmer(ply, from + center, dest + center)
    end

    -- left click: through the matter in front of you
    function SWEP:PhaseWall()
        local ply = self.Owner
        if (not IsValid(ply) or not ply:IsPlayer() or not ply:Alive()) then return end
        if (IsValid(ply:GetVehicle())) then return end

        local aim = ply:GetAimVector()
        local dir = Vector(aim.x, aim.y, 0)
        if (dir:Length() < 0.3) then
            return self:Deny(ply, "agp_phase_no_wall", "Phase device: look at a wall, door or prop to phase through it.")
        end
        dir:Normalize()

        ply:LagCompensation(true)
        local eye = ply:EyePos()
        local tr = util.TraceLine({ start = eye, endpos = eye + dir * self.PhaseReach, mask = MASK_PLAYERSOLID, filter = ply })
        ply:LagCompensation(false)
        if (not tr.Hit) then
            return self:Deny(ply, "agp_phase_no_wall", "Phase device: look at a wall, door or prop to phase through it.")
        end
        if (tr.HitSky) then
            return self:Deny(ply, "agp_phase_world_edge", "Phase device: that is the edge of the world, there is nothing behind it.")
        end
        if (IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC())) then
            return self:Deny(ply, "agp_phase_no_wall", "Phase device: look at a wall, door or prop to phase through it.")
        end

        local start = ply:GetPos()
        if (self:AntiPhaseAt(start)) then
            return self:Deny(ply, "agp_phase_blocked", "Phase device: an anti-phase field stops the phase shift here.")
        end

        local mins, maxs = hullOf(ply)
        local half = math.max(maxs.x, maxs.y)
        -- horizontal distance from the player to the wall surface
        local toWall = (Vector(tr.HitPos.x, tr.HitPos.y, start.z) - start):Length()
        local first = toWall + half + 1
        local last = toWall + self.PhaseMaxThick + half + 1
        local sawRoomless = false

        for d = first, last, 4 do
            local base = start + dir * d
            for _, up in ipairs({ 0, 8, 18 }) do   -- small steps or uneven floors behind the wall
                local p = base + Vector(0, 0, up)
                local ok = hullFits(ply, p, mins, maxs)
                if (ok) then
                    -- the target must really be behind the matter (the eye line back to where you stood is blocked)
                    local eyeUp = Vector(0, 0, eye.z - start.z)
                    local back = util.TraceLine({ start = p + eyeUp, endpos = start + eyeUp, mask = MASK_PLAYERSOLID, filter = ply })
                    if (back.Hit) then
                        if (self:AntiPhaseAt(p)) then
                            return self:Deny(ply, "agp_phase_blocked_exit", "Phase device: an anti-phase field on the other side stops the phase shift.")
                        end
                        local allow = hook.Run("AGP.TollanPhase.Allow", ply, start, p, "wall")
                        if (allow == false) then return self:Deny(ply, "agp_phase_blocked", "Phase device: an anti-phase field stops the phase shift here.") end
                        self:MovePlayer(ply, p)
                        return
                    end
                elseif (pointFree(ply, p + Vector(0, 0, (maxs.z + mins.z) * 0.5))) then
                    sawRoomless = true
                end
            end
        end

        if (sawRoomless) then
            return self:Deny(ply, "agp_phase_no_room", "Phase device: there is no room for you on the other side.")
        elseif (not IsValid(tr.Entity) and not util.IsInWorld(start + dir * (last + 256) + Vector(0, 0, maxs.z * 0.5))) then
            -- world brush and still no map behind it: the outer limit of the map
            return self:Deny(ply, "agp_phase_world_edge", "Phase device: that is the edge of the world, there is nothing behind it.")
        end
        return self:Deny(ply, "agp_phase_too_thick", "Phase device: too thick, it can phase through at most %s units.", self.PhaseMaxThick)
    end

    -- the gate's wormhole is open, outgoing and leads to a valid gate
    local function openOutgoing(g)
        return IsValid(g) and g.IsStargate and g.IsOpen and g.Outbound and IsValid(g.EventHorizon)
            and g.EventHorizon.IsOpen and g.EventHorizon:IsOpen() and IsValid(g.Target) and g.Target.IsStargate
    end

    -- right click: through an open outgoing wormhole, closed iris or not
    function SWEP:PhaseGate()
        local ply = self.Owner
        if (not IsValid(ply) or not ply:IsPlayer() or not ply:Alive()) then return end
        if (IsValid(ply:GetVehicle())) then return end

        local start = ply:GetPos()
        local best, bestD, anyGate = nil, math.huge, false
        for _, g in ipairs(ents.FindInSphere(ply:EyePos(), self.GateRange)) do
            if (IsValid(g) and g.IsStargate) then
                anyGate = true
                if (openOutgoing(g)) then
                    local d = g:GetPos():DistToSqr(ply:EyePos())
                    if (d < bestD) then best, bestD = g, d end
                end
            end
        end
        if (not best) then
            if (anyGate) then
                return self:Deny(ply, "agp_phase_gate_not_open", "Phase device: this Stargate has no open outgoing wormhole.")
            end
            return self:Deny(ply, "agp_phase_no_gate", "Phase device: no open Stargate nearby (stand within %s units of an outgoing wormhole).", self.GateRange)
        end
        if (self:AntiPhaseAt(start)) then
            return self:Deny(ply, "agp_phase_blocked", "Phase device: an anti-phase field stops the phase shift here.")
        end

        local tg = best.Target
        local mins, maxs = hullOf(ply)
        local fwd = tg:GetForward()
        local flat = Vector(fwd.x, fwd.y, 0)
        if (flat:Length() < 0.1) then flat = Vector(1, 0, 0) end   -- a gate lying flat: step out to any side
        flat:Normalize()
        local radius = math.max(tg:BoundingRadius() * 0.5, 60)

        local filter = { ply, tg }
        if (IsValid(tg.EventHorizon)) then filter[#filter + 1] = tg.EventHorizon end
        if (IsValid(tg.Iris)) then filter[#filter + 1] = tg.Iris end
        local dest
        for dist = 40, 320, 20 do
            -- in front of the event horizon (along the gate's facing), then down to the floor
            local p = tg:GetPos() + fwd * dist
            if (fwd.z > 0.7 or fwd.z < -0.7) then p = tg:GetPos() + fwd * dist + flat * (radius + dist) end
            if (util.IsInWorld(p)) then
                local down = util.TraceHull({ start = p, endpos = p - Vector(0, 0, radius + 200), mins = mins, maxs = maxs, mask = MASK_PLAYERSOLID, filter = filter })
                if (not down.StartSolid) then
                    local q = down.HitPos + Vector(0, 0, 1)
                    if (hullFits(ply, q, mins, maxs)) then dest = q break end
                end
            end
        end
        if (not dest) then
            return self:Deny(ply, "agp_phase_gate_no_room", "Phase device: there is no room in front of the target gate.")
        end
        if (self:AntiPhaseAt(dest) or self:AntiPhaseAt(tg:GetPos())) then
            return self:Deny(ply, "agp_phase_blocked_exit", "Phase device: an anti-phase field on the other side stops the phase shift.")
        end
        local allow = hook.Run("AGP.TollanPhase.Allow", ply, start, dest, "gate", best, tg)
        if (allow == false) then return self:Deny(ply, "agp_phase_blocked", "Phase device: an anti-phase field stops the phase shift here.") end

        local blocked = tg.IsBlocked and tg:IsBlocked(true) or false
        best:EmitSound("ambient/machines/teleport4.wav", 70, 140, 0.6)
        self:MovePlayer(ply, dest, Angle(0, flat:Angle().y, 0))
        if (blocked) then
            say(ply, "agp_phase_gate_iris", "Phase device: you phased through the closed iris.")
        end
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")

    local function shimmerAt(pos, ply)
        local dl = DynamicLight(math.random(4096, 8192))
        if (dl) then
            dl.pos = pos; dl.r = 170; dl.g = 210; dl.b = 255
            dl.brightness = 3; dl.size = 160; dl.decay = 400; dl.dietime = CurTime() + 0.6
        end
        local em = ParticleEmitter(pos)
        if (not em) then return end
        for i = 1, 28 do
            local p = em:Add("sprites/light_glow02_add", pos + VectorRand() * Vector(14, 14, 34))
            if (p) then
                p:SetVelocity(VectorRand() * 20 + Vector(0, 0, math.Rand(10, 40)))
                p:SetDieTime(math.Rand(0.4, 0.9))
                p:SetStartAlpha(220); p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(6, 14)); p:SetEndSize(0)
                local w = math.random(180, 255)
                p:SetColor(w, math.min(255, w + 20), 255)
                p:SetAirResistance(60)
            end
        end
        em:Finish()
    end

    net.Receive("agp_tollan_phase_fx", function()
        local from, to, ply = net.ReadVector(), net.ReadVector(), net.ReadEntity()
        shimmerAt(from, ply)
        shimmerAt(to, ply)
        if (IsValid(ply)) then ply.AGPPhaseShimmer = CurTime() + 0.5 end
    end)

    -- a faint glow at the wrist; the player model shimmers right after a phase
    -- AGP: drawn after the player model: with an empty WorldModel GMod never draws the weapon itself, so this was
    -- SWEP:DrawWorldModel, never called, and nobody saw the glow
    local function wristGlow(ply)
        local bone = ply:LookupBone("ValveBiped.Bip01_L_Hand")
        if (not bone) then return end
        local m = ply:GetBoneMatrix(bone)
        if (not m) then return end
        local pos = m:GetTranslation()
        local a = 60 + 30 * math.sin(CurTime() * 4)
        if ((ply.AGPPhaseShimmer or 0) > CurTime()) then a = 255 end
        render.SetMaterial(glow)
        render.DrawSprite(pos, 6, 6, Color(170, 210, 255, a))
    end
    hook.Add("PostPlayerDraw", "AGP.TollanPhase.WristGlow", function(ply)
        local w = ply:GetActiveWeapon()
        if (IsValid(w) and w:GetClass() == "agp_tollan_phase") then wristGlow(ply) end
    end)

    function SWEP:DrawHUD()
        local left = self:GetNextPrimaryFire() - CurTime()
        local text, col
        if (left > 0) then
            text = AGP.L("agp_phase_hud_charging", "Phase device: recharging")
            col = Color(150, 160, 180, 200)
        else
            text = AGP.L("agp_phase_hud_ready", "Phase device: ready")
            col = Color(170, 210, 255, 230)
        end
        draw.SimpleTextOutlined(text, "DermaDefaultBold", ScrW() / 2, ScrH() - 90, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 180))
    end
end
