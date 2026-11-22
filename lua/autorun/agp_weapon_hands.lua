-- Ascension Gates: weapons held in the bare hands (Nox hands, Sodan cloak, personal shield, Mimetisor, Atanik
-- armband) on Garry's Mod's own hands, like GMod's fists: the weapon file sets ViewModel = c_arms.mdl (no mesh of its
-- own, only the fists animations) and UseHands = true. CAP gave them c_arms_animations.mdl without UseHands: no
-- hands at all in first person.
-- AGP.HandsWeapon(SWEP) at the end of the weapon file (after its own Deploy / Think, which it keeps): on deploy the
-- hands come up (fists_draw), then rest in the fists idle. self:AGPHandsPlay(sequence[, rate]) plays one of c_arms'
-- sequences (fists_draw, fists_left, fists_right, fists_uppercut, seq_admire, ...) as a gesture, then the idle again.
AddCSLuaFile()
AGP = AGP or {}

local IDLE = { "fists_idle_01", "fists_idle_02" }
local deploySpeed = GetConVar("sv_defaultdeployspeed")

-- the owner's view model plays sequence `name`; returns how long it lasts (nil: no such sequence, or the device is not in
-- the hand - e.g. the personal shield switched on by console command - and the view model belongs to another weapon)
local function play(self, name, rate, deploying)
    local o = self:GetOwner()
    if (not IsValid(o) or not o:IsPlayer() or (not deploying and o:GetActiveWeapon() ~= self)) then return end
    local vm = o:GetViewModel()
    if (not IsValid(vm)) then return end
    local seq = vm:LookupSequence(name)
    if (not seq or seq < 0) then return end
    rate = rate or 1
    vm:SendViewModelMatchingSequence(seq)
    vm:SetPlaybackRate(rate)
    return vm:SequenceDuration(seq) / rate
end

-- an old first-person model with arms of its own on GMod's ValveBiped skeleton: its arms are hidden and the player's
-- own hands (GMod's hands of the player model) follow the same bones - the device, its animations and its screens stay
-- as they are. AGP.OwnHands(SWEP, { "hand", ... }) - material names (parts, lower case) of
-- the old arms
function AGP.OwnHands(SWEP, armMats)
    SWEP.UseHands = true
    if (SERVER) then return end
    local hidden = {}
    local function arms(vm)
        local mdl = vm:GetModel()
        if (hidden[mdl] == nil) then
            local t = {}
            for i, m in ipairs(vm:GetMaterials() or {}) do
                local ml = string.lower(m)
                for _, a in ipairs(armMats) do if (ml:find(a, 1, true)) then t[#t + 1] = i - 1 break end end
            end
            hidden[mdl] = t
        end
        return hidden[mdl]
    end
    local oldPre, oldPost = SWEP.PreDrawViewModel, SWEP.PostDrawViewModel
    function SWEP:PreDrawViewModel(vm, wep, ply)
        for _, i in ipairs(arms(vm)) do vm:SetSubMaterial(i, "models/effects/vol_light001") end   -- (draws nothing and writes no depth: the hands drawn after it stay visible)
        if (oldPre) then return oldPre(self, vm, wep, ply) end
    end
    function SWEP:PostDrawViewModel(vm, wep, ply)
        for _, i in ipairs(arms(vm)) do vm:SetSubMaterial(i, nil) end   -- (the view model is shared by every weapon)
        if (oldPost) then return oldPost(self, vm, wep, ply) end
    end
end

-- an item made with the SWEP Construction Kit, whose old first-person model had arms of its own: first person now
-- on GMod's hand animations (cfg.vm, e.g. c_bugbait) with the player's own hands; the item sits on the hand bone
-- exactly as its world element sits on the player's hand in third person (the kit's pos / angle / size).
-- AGP.HandItem(SWEP, { vm = "models/weapons/c_bugbait.mdl", model, bone, pos, ang, size, fov })
function AGP.HandItem(SWEP, cfg)
    SWEP.ViewModel = cfg.vm
    SWEP.UseHands = true
    SWEP.ViewModelFOV = cfg.fov or 54
    SWEP.ViewModelFlip = false
    SWEP.GetViewModelPosition = nil   -- (offsets made for the old model)
    SWEP.AGPHandItemWorld = cfg.world
    -- cfg.vmoff = Vector(forward, right, up): the whole hand moved in the view (e.g. raised, as an old model held it)
    if (CLIENT) then
        function SWEP:GetViewModelPosition(p, a)
            local t = AGP.HandItemTune and AGP.HandItemTune[self:GetClass()]
            local o = (t and t.vmoff) or cfg.vmoff
            local r = (t and t.vmang) or cfg.vmang   -- cfg.vmang = Angle(pitch, yaw, roll): the hand model tilted in the view
            if (not o and not r) then return p, a end
            local b = Angle(a.p, a.y, a.r)
            if (r) then b:RotateAroundAxis(b:Right(), r.p); b:RotateAroundAxis(b:Up(), r.y); b:RotateAroundAxis(b:Forward(), r.r) end
            o = o or vector_origin
            return p + a:Forward() * o.x + a:Right() * o.y + a:Up() * o.z, b
        end
    end
    if (SERVER) then return end
    local function item(self)
        if (not IsValid(self.AGPHandItem)) then
            self.AGPHandItem = ClientsideModel(cfg.model, RENDERGROUP_OPAQUE)
            if (IsValid(self.AGPHandItem)) then
                self.AGPHandItem:SetNoDraw(true)
                self.AGPHandItem:SetModelScale(cfg.size or 1)
            end
        end
        return self.AGPHandItem
    end
    -- the item on the hand bone of `ent` (the view model, or the player in third person)
    -- the item on the hand bone of `ent` (the view model, or the player in third person); fp = first person
    -- cfg.fp = { bone, pos, ang } another placement in first person (a hand model with other bones, e.g. c_slam's
    -- left hand); cfg.center: pos is where the model's middle goes (models whose origin lies far off the mesh).
    -- AGP.HandItemTune[class] = { pos, ang } overrides the first-person placement (tests, tuning)
    local function onHand(self, ent, fp)
        local c = (fp and cfg.fp) or cfg
        local tune = fp and AGP.HandItemTune and AGP.HandItemTune[self:GetClass()]
        local cpos, cang = (tune and tune.pos) or c.pos, (tune and tune.ang) or c.ang
        local b = ent:LookupBone((tune and tune.bone) or c.bone or cfg.bone or "ValveBiped.Bip01_R_Hand")
        local m = b and ent:GetBoneMatrix(b)
        local e = item(self)
        if (not m or not IsValid(e)) then return false end
        local pos, ang = m:GetTranslation(), m:GetAngles()
        pos = pos + ang:Forward() * cpos.x + ang:Right() * cpos.y + ang:Up() * cpos.z
        ang:RotateAroundAxis(ang:Up(), cang.y)
        ang:RotateAroundAxis(ang:Right(), cang.p)
        ang:RotateAroundAxis(ang:Forward(), cang.r)
        e:SetPos(pos); e:SetAngles(ang)
        if (c.center) then e:SetPos(pos + pos - e:LocalToWorld(e:OBBCenter())) end
        -- cfg.flip = a point of the model (where the hand holds it): the item turned end for end around it (an
        -- injector's tip points to the body, not away into the air)
        if (cfg.flip) then
            local g = e:LocalToWorld(cfg.flip)
            ang:RotateAroundAxis(ang:Forward(), 180)
            e:SetAngles(ang)
            e:SetPos(pos + g - e:LocalToWorld(cfg.flip))
        end
        e:SetupBones(); e:DrawModel()
        return true
    end
    local oldPre, oldPost, oldRemove = SWEP.PreDrawViewModel, SWEP.PostDrawViewModel, SWEP.OnRemove
    function SWEP:PreDrawViewModel(vm, wep, ply)
        if (not AGP.HandItemShowVM) then vm:SetMaterial("engine/occlusionproxy") end   -- GMod's prop in the hand (the bug bait) disappears, the hands stay (tests: shown)
        if (oldPre) then return oldPre(self, vm, wep, ply) end
    end
    function SWEP:PostDrawViewModel(vm, wep, ply)
        vm:SetMaterial("")
        onHand(self, vm, true)
        if (oldPost) then return oldPost(self, vm, wep, ply) end
    end
    -- cfg.world: the world model has no hand bone of its own (the engine left it at the feet, or the kit put it on
    -- another bone) - in third person the item sits in the player's hand the same way; dropped, the model itself
    if (cfg.world) then
        function SWEP:DrawWorldModel()
            local o = self:GetOwner()
            if (IsValid(o) and o:IsPlayer() and onHand(self, o)) then return end
            self:DrawModel()
        end
    end
    function SWEP:OnRemove(...)
        if (IsValid(self.AGPHandItem)) then self.AGPHandItem:Remove() end
        if (oldRemove) then return oldRemove(self, ...) end
    end
end

-- only the third-person half of AGP.HandItem, for an item whose first person is CAP's own model again
-- (AGP.BlueprintArms): its world model has no hand bone of its own - the engine leaves it at the player's feet - so
-- in a player's hand it is drawn on the hand bone (the kit's pos / angle / size); dropped, the model itself.
-- AGP.WorldOnHand(SWEP, { model, bone, pos, ang, size })
function AGP.WorldOnHand(SWEP, cfg)
    if (SERVER) then return end
    local oldRemove = SWEP.OnRemove
    function SWEP:DrawWorldModel()
        local o = self:GetOwner()
        local b = IsValid(o) and o:IsPlayer() and o:LookupBone(cfg.bone or "ValveBiped.Bip01_R_Hand")
        local m = b and o:GetBoneMatrix(b)
        if (not m) then self:DrawModel() return end
        if (not IsValid(self.AGPWorldItem)) then
            self.AGPWorldItem = ClientsideModel(cfg.model or self.WorldModel, RENDERGROUP_OPAQUE)
            if (not IsValid(self.AGPWorldItem)) then self:DrawModel() return end
            self.AGPWorldItem:SetNoDraw(true)
            self.AGPWorldItem:SetModelScale(cfg.size or 1)
        end
        local e = self.AGPWorldItem
        local pos, ang = m:GetTranslation(), m:GetAngles()
        pos = pos + ang:Forward() * cfg.pos.x + ang:Right() * cfg.pos.y + ang:Up() * cfg.pos.z
        ang:RotateAroundAxis(ang:Up(), cfg.ang.y)
        ang:RotateAroundAxis(ang:Right(), cfg.ang.p)
        ang:RotateAroundAxis(ang:Forward(), cfg.ang.r)
        e:SetPos(pos); e:SetAngles(ang)
        e:SetupBones(); e:DrawModel()
    end
    function SWEP:OnRemove(...)
        if (IsValid(self.AGPWorldItem)) then self.AGPWorldItem:Remove() end
        if (oldRemove) then return oldRemove(self, ...) end
    end
end

-- a world model that HAS the hand bone but was built for another hand: bone-merged as it comes, CAP's hand device
-- lies ~40 degrees turned and too far back - its finger caps stick out at the wrist in every pose. In a player's
-- hand the model is drawn by hand: on the hand bone, with a correction in the bone's own space (pos = along the
-- fingers / to the palm / to the thumb, ang = Angle).
-- AGP.WorldFitted(SWEP, { pos = Vector, ang = Angle, convar = "name" })   -- the convar "x y z p y r" overrides (tuning)
function AGP.WorldFitted(SWEP, cfg)
    if (SERVER) then return end
    local cv = cfg.convar and CreateClientConVar(cfg.convar, "", false, false)
    local oldRemove = SWEP.OnRemove
    function SWEP:DrawWorldModel()
        local o = self:GetOwner()
        local b = IsValid(o) and o:IsPlayer() and o:LookupBone("ValveBiped.Bip01_R_Hand")
        local H = b and o:GetBoneMatrix(b)
        if (not H or (cv and cv:GetString() == "off")) then self:DrawModel() return end   -- ("off": the model's own bonemerge, to compare)
        local e = self.AGPWorldItem
        if (not IsValid(e)) then
            e = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE)
            if (not IsValid(e)) then self:DrawModel() return end
            e:SetNoDraw(true)
            -- the model's own hand bone in the model's space (once, at the origin)
            e:SetPos(vector_origin); e:SetAngles(angle_zero); e:SetupBones()
            local mb = e:LookupBone("ValveBiped.Bip01_R_Hand")
            local B = mb and e:GetBoneMatrix(mb)
            e.AGPBoneInv = B and B:GetInverse() or Matrix()
            self.AGPWorldItem = e
        end
        local pos, ang = cfg.pos, cfg.ang
        local t = cv and cv:GetString() or ""
        if (t ~= "") then
            local n = {}
            for x in t:gmatch("[-%d%.]+") do n[#n + 1] = tonumber(x) end
            if (#n >= 6) then pos, ang = Vector(n[1], n[2], n[3]), Angle(n[4], n[5], n[6]) end
        end
        local M = Matrix()
        M:Set(H)
        M:Translate(pos)
        M:Rotate(ang)
        M:Mul(e.AGPBoneInv)
        e:SetPos(M:GetTranslation()); e:SetAngles(M:GetAngles())
        e:SetupBones(); e:DrawModel()
    end
    function SWEP:OnRemove(...)
        if (IsValid(self.AGPWorldItem)) then self.AGPWorldItem:Remove() end
        if (oldRemove) then return oldRemove(self, ...) end
    end
end

-- a weapon on a GMod hand model whose animations have other names (e.g. c_slam's detonator: draw, idle, the thumb
-- pressing the button): the weapon's own SendWeaponAnim(ACT_VM_...) calls play the mapped ones, deploying plays
-- map.draw, and after any of them the hand goes back to map.idle.
--
-- AGP.ActMap(SWEP, { draw = ACT_..., idle = ACT_..., [ACT_VM_PRIMARYATTACK] = ACT_..., ... })
function AGP.ActMap(SWEP, map)
    local W = FindMetaTable("Weapon")
    local function backToIdle(self, act)
        local o = self:GetOwner()
        local vm = IsValid(o) and o.GetViewModel and o:GetViewModel()
        if (not IsValid(vm) or not map.idle) then return end
        local seq = vm:SelectWeightedSequence(act)
        local d = (seq and seq >= 0) and vm:SequenceDuration(seq) or 0.5
        local id = "AGPActIdle" .. self:EntIndex()
        timer.Create(id, d, 1, function()
            if (IsValid(self) and IsValid(self:GetOwner()) and self:GetOwner():GetActiveWeapon() == self) then W.SendWeaponAnim(self, map.idle) end
        end)
    end
    -- map.thumb = { ACT_..., ... }: on these the thumb itself presses down (a button under it; the hand model has no
    -- such animation) - its joints bent for a moment on the view model, the hands follow it
    local thumbActs = {}
    for _, a in ipairs(map.thumb or {}) do thumbActs[a] = true end
    local function thumbPress(self)
        if (not CLIENT) then return end
        local o = self:GetOwner()
        if (o ~= LocalPlayer()) then return end
        local vm = o:GetViewModel()
        if (not IsValid(vm)) then return end
        local bend = AGP.ThumbAngle or Angle(0, -28, 0)
        local bones = {}
        for _, n in ipairs({ "ValveBiped.Bip01_R_Finger0", "ValveBiped.Bip01_R_Finger01", "ValveBiped.Bip01_R_Finger02" }) do
            local b = vm:LookupBone(n)
            if (b) then bones[#bones + 1] = b; vm:ManipulateBoneAngles(b, bend) end
        end
        timer.Create("AGPThumb" .. self:EntIndex(), AGP.ThumbHold and 30 or 0.3, 1, function()
            if (IsValid(vm)) then for _, b in ipairs(bones) do vm:ManipulateBoneAngles(b, angle_zero) end end
        end)
    end
    function SWEP:SendWeaponAnim(act)
        local to = map[act] or act
        W.SendWeaponAnim(self, to)
        if (thumbActs[act]) then thumbPress(self) end
        if (to ~= map.idle) then backToIdle(self, to) end
    end
    local oldDeploy = SWEP.Deploy
    function SWEP:Deploy(...)
        if (map.draw) then self:SendWeaponAnim(map.draw) end
        if (oldDeploy) then return oldDeploy(self, ...) end
        return true
    end
end

-- (the night's sweep of all weapons: "a click that is not heard feels like nothing happened") a device's buttons are
-- heard: AGP.ClickSounds(SWEP, { primary = "...", secondary = "...", reload = "...", level = 60 }) at the end of a
-- weapon file plays the sound when that button is used (CAP's own button sounds; at most every `gap` s).
function AGP.ClickSounds(SWEP, snd)
    local function wrap(name, s, gap)
        if (not s) then return end
        local old = SWEP[name]
        SWEP[name] = function(self, ...)
            local o = self:GetOwner()
            if (SERVER and IsValid(o) and (self["AGPSnd" .. name] or 0) < CurTime()) then
                self["AGPSnd" .. name] = CurTime() + (gap or snd.gap or 0.4)
                o:EmitSound(s, snd.level or 60, snd.pitch or 100, snd.volume or 0.8)
            end
            if (old) then return old(self, ...) end
        end
    end
    wrap("PrimaryAttack", snd.primary)
    wrap("SecondaryAttack", snd.secondary)
    wrap("Reload", snd.reload, 1)
end

function AGP.HandsWeapon(SWEP)
    function SWEP:AGPHandsPlay(name, rate, deploying)
        local d = play(self, name, rate, deploying)
        if (d) then self.AGPHandsIdleAt = CurTime() + d end
    end

    local oldDeploy, oldThink = SWEP.Deploy, SWEP.Think
    function SWEP:Deploy(...)
        self:AGPHandsPlay("fists_draw", deploySpeed and deploySpeed:GetFloat() or 1, true)
        if (oldDeploy) then return oldDeploy(self, ...) end
        return true
    end

    function SWEP:Think(...)
        if (self.AGPHandsIdleAt and CurTime() >= self.AGPHandsIdleAt) then
            self.AGPHandsIdleAt = nil   -- the idle loops on its own until the next gesture
            -- the same pick on the client (prediction) and the server, so the two do not fight over the sequence
            play(self, IDLE[math.floor(util.SharedRandom("AGPHandsIdle", 1, #IDLE + 0.999))])
        end
        if (oldThink) then return oldThink(self, ...) end
    end
end

-- (full check) five weapons whose world model sits ~20 units off its origin (kino remote, Asuran weapon, the MALP /
-- Jumper / ring remotes): lying on the ground, walking onto them did not pick them up (GMod's own touch never
-- fired). A player within reach of what you see picks it up - only where GMod's pickup rules allow it.
if (SERVER) then
    local CLASSES = { "kinoremote", "weapon_asura", "weapon_ringcaller", "weapon_jumper_remote", "weapon_malp_remote" }
    timer.Create("AGP.WalkPickup", 0.25, 0, function()
        for _, cls in ipairs(CLASSES) do
            for _, w in ipairs(ents.FindByClass(cls)) do
                if (IsValid(w) and not IsValid(w:GetOwner()) and not IsValid(w:GetParent())) then
                    local c = w:WorldSpaceCenter()
                    for _, p in ipairs(player.GetAll()) do
                        if (p:Alive() and not p:HasWeapon(cls) and p:GetPos():DistToSqr(Vector(c.x, c.y, p:GetPos().z)) < 32 * 32
                            and math.abs(p:GetPos().z - c.z) < 48 and hook.Run("PlayerCanPickupWeapon", p, w) ~= false) then
                            p:PickupWeapon(w)
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- AGP.WorldMerged(SWEP, { model = "...", convar = "..." }) (suite hdevab): in third person the holder wears another
-- model than the weapon's world model - one whose pieces hang on the hand's and the fingers' own bones (the
-- Goa'uld hand device: A build script agp_hdevice_build.py), so the game's bonemerge lays it on the
-- hand and bends it with the fingers on every body. The dropped weapon stays its world model. convar "off": the
-- world model as it is, to compare. the hand device: on a body without ring finger bones in
-- third person (GMod's citizens) the ring and little finger's pieces move with the middle finger
--
AGP.HandDeviceStandIn = {
    ["ValveBiped.Bip01_R_Finger3"] = "ValveBiped.Bip01_R_Finger2",
    ["ValveBiped.Bip01_R_Finger31"] = "ValveBiped.Bip01_R_Finger21",
    ["ValveBiped.Bip01_R_Finger32"] = "ValveBiped.Bip01_R_Finger22",
}
function AGP.WorldMerged(SWEP, cfg)
    if (SERVER) then return end
    local cv = cfg.convar and CreateClientConVar(cfg.convar, "", false, false)
    local oldRemove = SWEP.OnRemove
    -- a bone the holder's body does not set up (GMod's citizens drop the ring and little finger's bones in third
    -- person: bonemerge then leaves ours at the map's origin and the piece tears into a line across the sky): such
    -- a bone keeps its place of the open hand, carried by the model's first bone (the hand)
    local function mend(ent)
        local o, rel = ent:GetParent(), ent.AGPRel
        if (not IsValid(o) or not rel) then return end
        local r = o:LookupBone(ent:GetBoneName(0))
        local R = r and o:GetBoneMatrix(r)
        if (not R) then return end
        for i = 1, ent:GetBoneCount() - 1 do
            local name = ent:GetBoneName(i)
            local j = o:LookupBone(name)
            if (rel[i] and not (j and o:GetBoneMatrix(j))) then
                -- (first choice: it moves like a neighbour the body does set up - the ring finger like the middle
                -- finger -, keeping its own place beside it)
                local sub = cfg.stand_in and cfg.stand_in[name]
                local si = sub and ent:LookupBone(sub)
                local sj = sub and o:LookupBone(sub)
                local SM = sj and o:GetBoneMatrix(sj)
                local inv = si and rel[si] and rel[si]:GetInverse()
                if (SM and inv) then ent:SetBoneMatrix(i, SM * (inv * rel[i])) else ent:SetBoneMatrix(i, R * rel[i]) end
            end
        end
    end
    function SWEP:DrawWorldModel()
        local o = self:GetOwner()
        if (not IsValid(o) or (cv and cv:GetString() == "off")) then self:DrawModel() return end
        local e = self.AGPWorldItem
        if (not IsValid(e)) then
            e = ClientsideModel(cfg.model, RENDERGROUP_OPAQUE)
            if (not IsValid(e)) then self:DrawModel() return end
            e:SetNoDraw(true)
            -- every bone's place in the open hand, seen from the first bone (once, at the origin)
            e:SetPos(vector_origin); e:SetAngles(angle_zero); e:SetupBones()
            local B0 = e:GetBoneMatrix(0)
            e.AGPRel = {}
            if (B0) then
                local inv = B0:GetInverse()
                for i = 1, e:GetBoneCount() - 1 do
                    local Bi = e:GetBoneMatrix(i)
                    if (Bi and inv) then e.AGPRel[i] = inv * Bi end
                end
            end
            e:AddCallback("BuildBonePositions", mend)
            self.AGPWorldItem = e
        end
        if (e:GetParent() ~= o) then
            e:SetParent(o)
            e:AddEffects(EF_BONEMERGE)
        end
        e:SetupBones(); mend(e)
        e:DrawModel()
    end
    function SWEP:OnRemove(...)
        if (IsValid(self.AGPWorldItem)) then self.AGPWorldItem:Remove() end
        if (oldRemove) then return oldRemove(self, ...) end
    end
end
