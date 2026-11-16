--[[
	Reactor Core: an endless generator like the Asgard ion generator (same rules: up to 100000 energy per second,
	needs no fuel, only while the server setting agp_allow_infinite_power allows it; E / Wire On, Mute, Disable Use;
	outputs Active, Energy, Health). Everything but the look comes from asgard_ion_generator.
	Model: "Reactor Core" by Daniel Aucar Felipe (@danielaucar), CC BY 4.0,
	https://sketchfab.com/3d-models/reactor-core-b982332df0374966bec4132a7fd89b66 - rescaled, glass split from the frame,
	rotors on bones, glow masks and box collision added by us (Code/notes/models/agp_reactor_core_models.py + _build.py).
	A glass case about 99 x 40 x 37 units lying flat; inside a big turbine wheel (bone rotor_big) and a capsule rotor
	with three claws (bone rotor_small) turn in opposite directions around the long axis while it runs, with a blue pulse.
]]
local function L(key, fallback, ...)
    if (AGP and AGP.L) then return AGP.L(key, fallback, ...) end
    return fallback
end

ENT.Type = "anim"
ENT.Base = "asgard_ion_generator"
ENT.PrintName = L("agp_ent_reactor_core", "Reactor Core")
ENT.Author = "Daniel Aucar Felipe (model), Ascension Gates"
ENT.Category = "AGP Power"   -- our spawn tab, group Grid Power
ENT.WireDebugName = "Reactor core"
ENT.Spawnable = false        -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
ENT.AGPInfinite = true       -- endless source: agp_allow_infinite_power
ENT.AGPModel = "models/agp_power/agp_reactor_core.mdl"
ENT.AGPPlate = { "agp_ent_reactor_core", "Reactor Core" }
ENT.RenderGroup = RENDERGROUP_BOTH   -- the glass panes are translucent: drawn after the frame and the rotors
list.Set("CAP.Entity", ENT.PrintName, ENT)

-- model space (long axis = X): the facing ends of the two rotors and the gap between them
local CORE_BIG = Vector(5.5, 0, 19.25)     -- turbine wheel hub, axis height 19.25
local CORE_SMALL = Vector(-4.2, 0, 15.6)   -- capsule rotor with the claws, axis height 15.58
local GAP = Vector(0.6, 0, 17.4)
ENT.AGPLightPos = GAP                      -- the blue dynamic light (asgard_ion_generator's client Think)

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()
    if (StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("agp_reactor_core", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")
    -- the rotors: bone, degrees per second at full speed; both turn about the long axis (the bones' own Y axis,
    -- pitch), the capsule rotor faster and the other way
    local ROTORS = { { "rotor_big", 45 }, { "rotor_small", -110 } }

    -- once per frame (Draw and DrawTranslucent both call it): run-up / coast, the pulse, the bone angles
    function ENT:AGPAnimate()
        local fn = FrameNumber()
        if (self.AGPFrame == fn) then return end
        self.AGPFrame = fn
        local on = self:GetNWInt("AGPState") == 1
        local dt = FrameTime()
        self.AGPSpeed = Lerp(math.min(1, dt * 0.6), self.AGPSpeed or 0, on and 1 or 0)
        -- a slow smooth breath; the light strips, blades and sleeve follow it (material proxy AGPGlow of
        -- agp_power_anim.lua reads self.AGPGlow), dim when it stands still
        self.AGPPulse = 0.5 + 0.5 * math.sin(CurTime() * 2.2)
        local goal = 0.15 + self.AGPSpeed * (0.7 + 0.55 * self.AGPPulse)
        self.AGPGlow = Lerp(math.min(1, dt * 4), self.AGPGlow or goal, goal)
        self.AGPRotorBones = self.AGPRotorBones or {}
        self.AGPRotorAng = self.AGPRotorAng or { 0, 0 }
        for i, r in ipairs(ROTORS) do
            local b = self.AGPRotorBones[i]
            if (b == nil) then
                b = self:LookupBone(r[1]) or false
                self.AGPRotorBones[i] = b
            end
            if (b) then
                self.AGPRotorAng[i] = (self.AGPRotorAng[i] + r[2] * self.AGPSpeed * dt) % 360
                self:ManipulateBoneAngles(b, Angle(self.AGPRotorAng[i], 0, 0), false)
            end
        end
    end

    function ENT:Draw(flags)
        self:AGPAnimate()
        self:DrawModel(flags)
    end

    function ENT:DrawTranslucent(flags)
        self:AGPAnimate()
        self:DrawModel(flags)
        local spd = self.AGPSpeed or 0
        if (spd < 0.02) then return end
        -- the cores: blue glows at the facing ends of both rotors and a softer one in the gap, pulsing together
        local p = self.AGPPulse or 0.5
        local a = spd * (150 + 90 * p)
        local s = 18 + 10 * p
        render.SetMaterial(glow)
        for _, v in ipairs({ CORE_BIG, CORE_SMALL }) do
            local pos = self:LocalToWorld(v)
            render.DrawSprite(pos, s, s, Color(80, 150, 255, a))
            render.DrawSprite(pos, s * 0.4, s * 0.4, Color(210, 235, 255, a))
        end
        local g = 34 + 12 * p
        render.DrawSprite(self:LocalToWorld(GAP), g, g * 0.7, Color(60, 120, 255, a * 0.5))
    end
end
