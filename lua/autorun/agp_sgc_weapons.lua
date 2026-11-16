-- Ascension Gates: SGC weapons with our own models on GMod's built-in HL2 animations.
-- First person: the HL2 view model (and GMod's hands) animates; its gun is hidden and our model is drawn on its gun bone.
-- Third person / dropped: the world model itself, placed by the engine (see agp_weapons_v3_skeleton.py).
-- AGP.SGCWeapon(SWEP, cfg)  cfg = { model, icon (weapon selection), vmBone (gun bone of the HL2 view model), vmPos, vmAng, scale, extra,
--   vmHand (our model has the hand bone ValveBiped.Bip01_R_Hand: vmPos / vmAng put that bone on vmBone instead of the origin),
--   animate(self, ent, firstPerson) before drawing (bone poses), after(self, ent, firstPerson) after drawing (glows) }
AddCSLuaFile()
AGP = AGP or {}

-- live tuning (developers / tests): AGP.SGCTune[class] = { vmPos, vmAng } overrides the cfg values,
-- AGP.SGCShowHL2 = true keeps the HL2 gun visible to line our model up with it
AGP.SGCTune = AGP.SGCTune or {}
if CLIENT then
    concommand.Add("agp_wtune", function(_, _, a)   -- agp_wtune <class> <vmPos|vmAng> x y z
        local t = AGP.SGCTune[a[1]] or {}; AGP.SGCTune[a[1]] = t
        local x, y, z = tonumber(a[3]) or 0, tonumber(a[4]) or 0, tonumber(a[5]) or 0
        t[a[2]] = a[2]:find("Ang") and Angle(x, y, z) or Vector(x, y, z)
    end)
end

function AGP.SGCWeapon(SWEP, cfg)
    SWEP.WorldModel = cfg.model
    SWEP.UseHands = true
    SWEP.AGPWeapon = cfg
    if SERVER then return end
    if cfg.icon then SWEP.WepSelectIcon = surface.GetTextureID(cfg.icon) end

    local function csModel(self)
        if not IsValid(self.AGPModel) then
            self.AGPModel = ClientsideModel(cfg.model, RENDERGROUP_OPAQUE)
            if IsValid(self.AGPModel) then self.AGPModel:SetNoDraw(true); self.AGPModel:SetModelScale(cfg.scale or 1) end
        end
        return self.AGPModel
    end
    local function T(self, k) local t = AGP.SGCTune[self:GetClass()]; return (t and t[k]) or cfg[k] end
    local function place(m, pos, ang, p, a, draw)
        local _, ang2 = LocalToWorld(vector_origin, a, vector_origin, ang)   -- a = our model's angles in the bone's space
        m:SetPos(pos + ang2:Forward() * p.x + ang2:Right() * p.y + ang2:Up() * p.z)   -- offset along the gun: forward, right, up
        m:SetAngles(ang2)
        m:SetupBones()
        if draw then draw(m) else m:DrawModel() end
    end
    -- where the model origin is while it hangs in the hand: hand bone matrix + the bone's bind pose (read once)
    local originInHand
    local function handOrigin(self)
        if not originInHand then
            local m = csModel(self)
            local b = IsValid(m) and m:LookupBone("ValveBiped.Bip01_R_Hand")
            if not b then return end
            m:SetPos(vector_origin); m:SetAngles(angle_zero); m:SetupBones()
            local bm = m:GetBoneMatrix(b)
            if not bm then return end
            local lp, la = WorldToLocal(vector_origin, angle_zero, bm:GetTranslation(), bm:GetAngles())
            originInHand = { lp, la }
        end
        return originInHand
    end
    -- vmLook = { head = Vector, top = Vector } (view space: forward, left, up) with designInHand = { pos, ang } (the
    -- model's design frame in its hand bone, from its build script): once, at the first idle frame, our model is turned
    -- so its long axis points along `head` and its top along `top`, staying where the hand holds it; the result
    -- replaces vmPos / vmAng (AGP.SGCTune), so it still follows every animation of the hand
    local function solveLook(self, vm, gm)
        local cls = self:GetClass()
        if (AGP.SGCTune[cls] and AGP.SGCTune[cls].solved) then return end
        -- the hand at rest: idle, or the draw animation played out (SWEPs stay on its last frame)
        if (vm:GetSequenceActivity(vm:GetSequence()) ~= ACT_VM_IDLE and vm:GetCycle() < 0.98) then return end
        local bp, ba = gm:GetTranslation(), gm:GetAngles()
        local dih = cfg.designInHand
        local hp, ha = LocalToWorld(cfg.vmPos, cfg.vmAng, bp, ba)                  -- our hand bone now
        local dp = LocalToWorld(dih[1], dih[2], hp, ha)                            -- the grip now (stays)
        local z = cfg.vmLook.head:GetNormalized()
        local y = (cfg.vmLook.top - z * cfg.vmLook.top:Dot(z)):GetNormalized()
        local mx = Matrix(); mx:SetForward(y:Cross(z)); mx:SetRight(-y); mx:SetUp(z)
        local _, da = LocalToWorld(vector_origin, mx:GetAngles(), vector_origin, EyeAngles())
        local ip, ia = WorldToLocal(vector_origin, angle_zero, dih[1], dih[2])      -- the hand bone seen from the design frame
        local np, na = LocalToWorld(ip, ia, dp, da)
        local xp, xa = WorldToLocal(np, na, bp, ba)
        AGP.SGCTune[cls] = { vmPos = xp, vmAng = xa, solved = true }
    end
    -- optional attachment drawn on our model (e.g. the Kull disruptor), relative to the model
    local function extra(self, m)
        local e = cfg.extra
        if not e or not e.when(self) then return end
        if not IsValid(self.AGPExtra) then
            self.AGPExtra = ClientsideModel(e.model, RENDERGROUP_OPAQUE)
            if not IsValid(self.AGPExtra) then return end
            self.AGPExtra:SetNoDraw(true)
        end
        place(self.AGPExtra, m:GetPos(), m:GetAngles(), e.pos, e.ang)
    end

    local oldPre, oldPost = SWEP.PreDrawViewModel, SWEP.PostDrawViewModel
    function SWEP:PreDrawViewModel(vm, wep, ply)
        if not AGP.SGCShowHL2 then vm:SetMaterial("engine/occlusionproxy") end   -- the HL2 gun disappears, the hands are their own model
        if oldPre then return oldPre(self, vm, wep, ply) end
    end
    function SWEP:PostDrawViewModel(vm, wep, ply)
        vm:SetMaterial("")
        -- our model rides on the gun bone of the HL2 view model (like SWEP Construction Kit weapons), so it copies every animation
        local gb = vm:LookupBone(cfg.vmBone)
        local gm = gb and vm:GetBoneMatrix(gb)
        local m = csModel(self)
        -- a weapon can draw its first-person model itself (SWEP:AGPDrawVM(m), e.g. the PDW's magazine swap while reloading)
        local draw = self.AGPDrawVM and function(mdl) self:AGPDrawVM(mdl) end
        if gm and IsValid(m) then
            if cfg.vmHand then
                if cfg.vmLook then solveLook(self, vm, gm) end
                local oh = handOrigin(self)
                if oh then
                    local hp, ha = LocalToWorld(T(self, "vmPos"), T(self, "vmAng"), gm:GetTranslation(), gm:GetAngles())
                    local op, oa = LocalToWorld(oh[1], oh[2], hp, ha)
                    m:SetPos(op); m:SetAngles(oa)
                    if cfg.animate then cfg.animate(self, m, true) end
                    m:SetupBones()
                    if draw then draw(m) else m:DrawModel() end
                    if cfg.after then cfg.after(self, m, true) end
                end
            else
                place(m, gm:GetTranslation(), gm:GetAngles(), T(self, "vmPos"), T(self, "vmAng"), draw)
            end
            extra(self, m)
        end
        if oldPost then return oldPost(self, vm, wep, ply) end
    end
    -- third person / dropped: the engine places the world model itself, like the old weapons (the PDW has the hand bone
    -- of the old P90, the sidearm sits on the hand attachment like the old pistol). Only the extra attachment needs us.
    local function modelFrame(self)
        local b = self:LookupBone("ValveBiped.Bip01_R_Hand")
        local oh = b and handOrigin(self)
        if not oh then return self:GetPos(), self:GetAngles() end
        self:SetupBones()
        local hm = self:GetBoneMatrix(b)
        return LocalToWorld(oh[1], oh[2], hm:GetTranslation(), hm:GetAngles())
    end
    function SWEP:DrawWorldModel()
        if cfg.animate then cfg.animate(self, self, false) end
        self:DrawModel()
        if cfg.after then cfg.after(self, self, false) end
        if cfg.extra and cfg.extra.when(self) then
            local pos, ang = modelFrame(self)
            local m = csModel(self)
            m:SetPos(pos); m:SetAngles(ang)
            extra(self, m)
        end
    end
    local oldRemove = SWEP.OnRemove
    function SWEP:OnRemove()
        if IsValid(self.AGPModel) then self.AGPModel:Remove() end
        if IsValid(self.AGPExtra) then self.AGPExtra:Remove() end
        if oldRemove then return oldRemove(self) end
    end
end
