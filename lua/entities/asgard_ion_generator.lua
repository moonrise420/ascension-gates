--[[
	Asgard ion generator (MoonWatcher machine by Soren, finished for Ascension Gates)
	An endless energy source: it needs no fuel and gives up to 100000 energy per second to its network (Grid Power,
	Spacebuild/RD or CAP energy, link it like any other generator). Because it never runs dry, the server setting
	agp_allow_infinite_power (SpaceGrid > Settings > Grid Power, default on) decides whether it may be spawned at all;
	switched off later, generators already standing go idle.
	E or Wire "On" switches it on/off. Wire inputs: On, Mute, Disable Use. Outputs: Active, Energy, Health.
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then
    StarGate.LifeSupportAndWire(ENT)
end

local function L(key, fallback, ...)
    if (AGP and AGP.L) then return AGP.L(key, fallback, ...) end
    return fallback
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = L("agp_ent_asgard_ion_gen", "Asgard Ion Generator")
ENT.Author = "Soren, god mode"
ENT.Category = "AGP Power"   -- our spawn tab, group Grid Power
ENT.WireDebugName = "Asgard ion generator"
ENT.Spawnable = false        -- in our own spawn tab (Ascension Gates), not the Entities tab
ENT.AdminSpawnable = false
ENT.AGPInfinite = true       -- endless source: agp_allow_infinite_power
ENT.Rate = 100000            -- energy per second at most
-- also read by agp_reactor_core (ENT.Base = this class): its own model, light position and status plate name
ENT.AGPModel = "models/agp_power/agp_asgard_ion_generator.mdl"
ENT.AGPPlate = { "agp_ent_asgard_ion_gen", "Asgard Ion Generator" }
list.Set("CAP.Entity", ENT.PrintName, ENT)

local LOOP = "displacer_new/portals/loop.wav"

local function infiniteAllowed()
    local cv = GetConVar("agp_allow_infinite_power")
    return cv ~= nil and cv:GetBool()
end

if SERVER then
    if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("energy")) then return end
    AddCSLuaFile()

    local function sayOff(p)
        if (not IsValid(p) or not p:IsPlayer()) then return end
        if (AGP and AGP.Say) then
            AGP.Say(p, "agp_msg_infinite_off", "Endless power sources are switched off on this server. An admin can allow them: PowerGrid > Settings > PowerGrid.")
        else
            p:ChatPrint("Endless power sources are switched off on this server.")
        end
    end

    function ENT:SpawnFunction(p, tr, cls)
        if (not tr.Hit) then return end
        if (not infiniteAllowed()) then sayOff(p) return end
        local e = ents.Create(cls or self.ClassName or "asgard_ion_generator")
        if (not IsValid(e)) then return end
        e:SetPos(tr.HitPos)
        e:SetAngles(Angle(0, (p:GetAimVector():Angle().y + 180) % 360, 0))
        e:Spawn()
        e:Activate()
        e:SetPos(tr.HitPos - Vector(0, 0, e:OBBMins().z))
        e.Owner = p
        return e
    end

    function ENT:Initialize()
        -- AGP: our own Asgard reactor model (Code/): stepped platform, glass column with the ion core, three rings
        -- that turn while it runs (bones ring_low / ring_mid / ring_top)
        self:SetModel(self.AGPModel)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:DrawShadow(true)
        self:SetUseType(SIMPLE_USE)
        local phys = self:GetPhysicsObject()
        if (IsValid(phys)) then phys:SetMass(200); phys:Wake() end
        self:AddResource("energy", 100000)
        self.Active = false
        self.EntHealth = 300
        self.MaxHealth = self.EntHealth
        self:CreateWireInputs("On", "Mute", "Disable Use")
        self:CreateWireOutputs("Active", "Energy", "Health")
        self:SetWire("Health", self.EntHealth)
        self:SetNWInt("AGPState", 0)
        self:NextThink(CurTime() + 0.5)
    end

    function ENT:SetActive(on, ply)
        if (on and not infiniteAllowed()) then sayOff(ply or self.Owner) on = false end
        if (on == self.Active) then return end
        self.Active = on
        if (self:GetWire("Mute") <= 0) then
            self:EmitSound(on and "ambient/machines/thumper_startup1.wav" or "ambient/energy/power_off1.wav", 75, 100, 1)
        end
        self:SetWire("Active", on and 1 or 0)
        self:SetNWInt("AGPState", on and 1 or 0)
    end

    function ENT:Use(p)
        if (self:GetWire("Disable Use") > 0) then return end
        self:SetActive(not self.Active, p)
    end

    function ENT:TriggerInput(k, v)
        if (k == "On") then
            self:SetActive((v or 0) >= 1, self.Owner)
        elseif (k == "Mute") then
            self:SetNWBool("AGPMute", (v or 0) > 0)
        end
    end

    function ENT:Think()
        local dt = 0.5
        if (self.Active and not infiniteAllowed()) then
            -- the admin switched endless power off: stand idle, show why
            self.Active = false
            self:SetWire("Active", 0)
            self:EmitSound("ambient/energy/power_off1.wav", 75, 100, 1)
            sayOff(self.Owner)
        end
        if (not infiniteAllowed()) then
            self:SetNWInt("AGPState", 2)
        elseif (self:GetNWInt("AGPState") == 2) then
            self:SetNWInt("AGPState", self.Active and 1 or 0)
        end
        if (self.Active and StarGate.HasResourceDistribution) then
            local need = math.max(0, self:GetNetworkCapacity("energy") - self:GetResource("energy"))
            local give = math.min(need, self.Rate * dt)
            if (give > 0) then self:SupplyResource("energy", give) end
        end
        self:SetWire("Energy", self:GetResource("energy"))
        self:NextThink(CurTime() + dt)
        return true
    end

    function ENT:OnTakeDamage(dmg)
        self.EntHealth = self.EntHealth - dmg:GetDamage()
        self:SetWire("Health", math.max(0, self.EntHealth))
        if (self.EntHealth < 1) then self:Boom() end
    end

    function ENT:HealthRepair(health)
        self.EntHealth = health
        self:SetWire("Health", health)
    end

    function ENT:Boom()
        if (self.Boomed) then return end
        self.Boomed = true
        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        util.Effect("Explosion", fx)
        self:Remove()
    end

    function ENT:OnRemove()
        StarGate.WireRD.OnRemove(self)   -- leaves its network (LifeSupportAndWire's OnRemove, overridden here)
    end

    function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
        if (not infiniteAllowed()) then
            sayOff(ply)
            self:Remove()
            return
        end
        self.Owner = ply
        StarGate.WireRD.PostEntityPaste(self, ply, Ent, CreatedEntities)
    end

    if (StarGate and StarGate.CAP_GmodDuplicator) then
        duplicator.RegisterEntityClass("asgard_ion_generator", StarGate.CAP_GmodDuplicator, "Data")
    end
end

if CLIENT then
    local glow = Material("sprites/light_glow02_add")
    local hud = surface.GetTextureID("VGUI/resources_hud/tier_6")
    local cvSound

    local CORE = Vector(0, 0, 27)   -- the ion core in the glass column
    -- the rings: bone, degrees per second at full speed (the middle one turns the other way)
    local RINGS = { { "ring_low", 14 }, { "ring_mid", -26 }, { "ring_top", 20 } }

    function ENT:Draw()
        local on = self:GetNWInt("AGPState") == 1
        local dt = FrameTime()
        -- the rings run up slowly and coast to a stop; the core and the light strips follow on / off (material
        -- proxy AGPGlow of agp_power_anim.lua reads self.AGPGlow)
        self.AGPSpeed = Lerp(math.min(1, dt * 0.7), self.AGPSpeed or 0, on and 1 or 0)
        local goal = on and (1.2 + 0.25 * math.sin(CurTime() * 3)) or 0.2
        self.AGPGlow = Lerp(math.min(1, dt * 3), self.AGPGlow or goal, goal)
        self.AGPRingBones = self.AGPRingBones or {}
        self.AGPRingAng = self.AGPRingAng or { 0, 0, 0 }
        for i, r in ipairs(RINGS) do
            local b = self.AGPRingBones[i]
            if (b == nil) then
                b = self:LookupBone(r[1]) or false
                self.AGPRingBones[i] = b
            end
            if (b) then
                self.AGPRingAng[i] = (self.AGPRingAng[i] + r[2] * self.AGPSpeed * dt) % 360
                self:ManipulateBoneAngles(b, Angle(0, self.AGPRingAng[i], 0), false)
            end
        end
        self:DrawModel()
        if (not on) then return end
        -- the ion core: a pulsing blue glow in the column
        local t = CurTime()
        local s = 30 + math.sin(t * 4) * 5
        local pos = self:LocalToWorld(CORE)
        render.SetMaterial(glow)
        render.DrawSprite(pos, s, s, Color(90, 150, 255, 200))
        render.DrawSprite(pos, s * 0.45, s * 0.45, Color(220, 235, 255, 255))
    end

    function ENT:Think()
        local on = self:GetNWInt("AGPState") == 1
        cvSound = cvSound or GetConVar("agp_power_sounds")
        local sound = on and not self:GetNWBool("AGPMute") and (cvSound == nil or cvSound:GetBool())
        if (sound) then
            if (not self.Loop) then self.Loop = CreateSound(self, LOOP) end
            if (not self.Loop:IsPlaying()) then self.Loop:PlayEx(0.5, 100) end
        elseif (self.Loop and self.Loop:IsPlaying()) then
            self.Loop:Stop()
        end
        if (on) then
            local d = DynamicLight(self:EntIndex())
            if (d) then
                d.Pos = self:LocalToWorld(self.AGPLightPos or CORE)
                d.r, d.g, d.b = 60, 100, 255
                d.Brightness = 2
                d.Size = 400
                d.Decay = 2000
                d.DieTime = CurTime() + 0.2
            end
        end
        self:SetNextClientThink(CurTime() + 0.1)
        return true
    end

    function ENT:OnRemove()
        if (self.Loop) then self.Loop:Stop() end
    end

    -- looking at it: the Asgard status plate (also for the classes built on this one, e.g. agp_reactor_core)
    hook.Add("HUDPaint", "AGP.AsgardIonGenerator", function()
        local tr = LocalPlayer():GetEyeTrace()
        local e = tr.Entity
        if (not IsValid(e) or e.AGPPlate == nil or not e.AGPInfinite or EyePos():Distance(e:GetPos()) > 1024) then return end
        if (StarGate and StarGate.VisualsMisc and not StarGate.VisualsMisc("cl_draw_huds", true)) then return end
        local st = e:GetNWInt("AGPState")
        local w, h = 0, 260
        surface.SetTexture(hud)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(ScrW() / 2 + 6 + w, ScrH() / 2 - 50 - h, 180, 360)
        draw.SimpleText(L(e.AGPPlate[1], e.AGPPlate[2]), "DermaDefaultBold", ScrW() / 2 + 50 + w, ScrH() / 2 + 65 - h, Color(255, 255, 255, 255), 0)
        draw.SimpleText(L("agp_mw_status", "Status:"), "DermaDefault", ScrW() / 2 + 50 + w, ScrH() / 2 + 95 - h, Color(209, 238, 238, 255), 0)
        local text, col
        if (st == 1) then text, col = L("agp_mw_online", "Online"), Color(0, 255, 0)
        elseif (st == 2) then text, col = L("agp_mw_disabled", "Switched off by the admin"), Color(255, 140, 0)
        else text, col = L("agp_mw_offline", "Offline"), Color(255, 0, 0) end
        draw.SimpleText(text, "DermaDefault", ScrW() / 2 + 50 + w, ScrH() / 2 + 112 - h, col, 0)
        draw.SimpleText(L("agp_mw_endless", "Endless energy"), "DermaDefault", ScrW() / 2 + 50 + w, ScrH() / 2 + 135 - h, Color(160, 200, 255), 0)
    end)
end
