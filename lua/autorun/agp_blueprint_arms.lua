-- Ascension Gates: a weapon keeps CAP's old first-person model - the item, its grip and every animation exactly as they
-- were - and only the arms change: CAP's own arm mesh is hidden and the player's own hands (GMod's hands of the
-- player model, with our sleeve and skin) are laid onto CAP's arm skeleton joint by joint, every frame. The old
-- skeletons have other bone names and other rest poses than GMod's hands, so the pose is carried over by the joints'
-- positions (shoulder, elbow, wrist, the three joints of each finger), not by bone angles: where CAP's fingers closed
-- around the item, ours close around it too.
--
--
-- AGP.BlueprintArms(SWEP, {
--     vm = "models/.../v_item.mdl",         -- CAP's first-person model
--     hide = { "v_hands" },                 -- material names (parts, lower case) of its own arm mesh
--     arms = { R = { upper = "...", fore = "...", hand = "...", fingers = { {thumb x3}, {index x3}, ... } }, L = ... },
--     fov = 54, flip = false })   -- (both optional: only where CAP's weapon file set none)
-- An arm without `hand` (fingers hanging on the forearm bone): the wrist is taken `wrist` (0.8) of the way from the
-- elbow to the knuckles. An arm the old model does not have is not drawn.
-- A build script prints the arms table of a model.
AddCSLuaFile()
AGP = AGP or {}

local SIDES = { "R", "L" }
local FINGERS = 5

function AGP.BlueprintArms(SWEP, cfg)
    SWEP.ViewModel = cfg.vm
    SWEP.UseHands = false          -- (GMod's hands entity is not drawn: ours are, on CAP's joints)
    if (cfg.fov) then SWEP.ViewModelFOV = cfg.fov end            -- (else the weapon's own, as CAP set it)
    if (cfg.flip ~= nil) then SWEP.ViewModelFlip = cfg.flip end
    SWEP.AGPBlueprint = cfg
    if (SERVER) then return end
    local oldPre, oldPost = SWEP.PreDrawViewModel, SWEP.PostDrawViewModel
    function SWEP:PreDrawViewModel(vm, wep, ply)
        AGP.BlueprintHide(vm, cfg, true)
        if (oldPre) then return oldPre(self, vm, wep, ply) end
    end
    function SWEP:PostDrawViewModel(vm, wep, ply)
        AGP.BlueprintHide(vm, cfg, false)
        AGP.BlueprintDraw(vm, cfg, ply or LocalPlayer(), self.ViewModelFlip)
        if (oldPost) then return oldPost(self, vm, wep, ply) end
    end
end

-- the arm tables of CAP's first-person skeletons
AGP.BlueprintRigs = AGP.BlueprintRigs or {}
do
    local function f3(a, b, c) return { a, b, c } end
    -- Iziraider's / Boba Fett's / Assassin21's arms (remote, Kino remote, Ori staff, Wraith stun bomb)
    AGP.BlueprintRigs.izi = {
        R = { upper = "Right_U_Arm", fore = "Right_L_Arm", hand = "Right_Hand",
            fingers = { f3("Bone22", "Bone23", "Bone24"), f3("Bone06", "Bone07", "Bone08"), f3("Bone10", "Bone11", "Bone12"), f3("Bone14", "Bone15", "Bone16"), f3("Bone18", "Bone19", "Bone20") } },
        L = { upper = "Left_U_Arm", fore = "Left_L_Arm", hand = "Left_Hand",
            fingers = { f3("Left1", "Left2", "Left3"), f3("Left4", "Left5", "Left6"), f3("Left7", "Left8", "Left9"), f3("Left10", "Left11", "Left12"), f3("Left13", "Left14", "Left15") } },
    }
    -- the same arms where the right one is a mirrored copy of the left (LSD, minidrone key, portable DHD)
    local mirrored = { upper = "Left_U_Arm01", fore = "Left_L_Arm01", hand = "Left_Hand01",
        fingers = { f3("Left16", "Left17", "Left18"), f3("Left28", "Left29", "Left30"), f3("Left25", "Left26", "Left27"), f3("Left19", "Left20", "Left21"), f3("Left22", "Left23", "Left24") } }
    AGP.BlueprintRigs.iziR = { R = mirrored }
    AGP.BlueprintRigs.izi2 = { R = mirrored, L = AGP.BlueprintRigs.izi.L }
    -- the hand device's arm (JDM12989): no hand bone, the fingers hang on the forearm bone
    AGP.BlueprintRigs.hdevice = {
        R = { upper = "Bone01", fore = "Bone02", wrist = 0.74,
            fingers = { f3("Bone04", "Bone05", "Bone06"), f3("Bone08", "Bone09", "Bone10"), f3("Bone12", "Bone13", "Bone14"), f3("Bone16", "Bone17", "Bone18"), f3("Bone20", "Bone21", "Bone22") } },
    }
    -- the dagger's arms (a Counter-Strike knife skeleton): forearm and hand are separate chains
    AGP.BlueprintRigs.knife = {
        L = { fore = "L 26", hand = "L 03",
            fingers = { f3("L 05", "L 06", "L 07"), f3("L 09", "L 10", "L 11"), f3("L 13", "L 14", "L 15"), f3("L 17", "L 18", "L 19"), f3("L 21", "L 22", "L 23") } },
        R = { fore = "R 02", hand = "R 06",
            fingers = { f3("R 24", "R 25", "R 26"), f3("R 08", "R 09", "R 10"), { "R 12", "R 13" }, f3("R 16", "R 17", "R 18"), f3("R 20", "R 21", "R 22") } },
    }
    -- models on Valve's own arm bones, under three spellings
    local function valve(prefix, sep, sides)
        local t = {}
        for _, sd in ipairs(sides) do
            local p = prefix .. sd .. sep
            local a = { upper = p .. "UpperArm", fore = p .. "Forearm", hand = p .. "Hand", fingers = {} }
            for i = 0, 4 do a.fingers[i + 1] = { p .. "Finger" .. i, p .. "Finger" .. i .. "1", p .. "Finger" .. i .. "2" } end
            t[sd] = a
        end
        return t
    end
    AGP.BlueprintRigs.valveL = valve("ValveBiped.Bip01_", "_", { "L" })          -- staff weapon (one arm, mirrored)
    AGP.BlueprintRigs.zat = valve("Bip01 ", " ", { "R", "L" })                   -- zat
    AGP.BlueprintRigs.dexL = valve("Bip01_", "_", { "L" })                       -- Ronon's gun (its other hand has no finger bones)
end

if (SERVER) then return end

-- ------------------------------------------------------------------------------------------------ small matrix helpers
local function frame(x, y, z, p)   -- the matrix whose columns are the axes x, y, z and whose origin is p
    local m = Matrix()
    m:SetUnpacked(x.x, y.x, z.x, p.x, x.y, y.y, z.y, p.y, x.z, y.z, z.z, p.z, 0, 0, 0, 1)
    return m
end

-- an orthonormal frame from a direction and a second vector that fixes the roll around it
local function geo(dir, ref, ref2)
    local x = dir:GetNormalized()
    local z = x:Cross(ref)
    if (z:LengthSqr() < 1e-4 and ref2) then z = x:Cross(ref2) end
    if (z:LengthSqr() < 1e-8) then z = x:Cross(Vector(0, 0, 1)) end
    if (z:LengthSqr() < 1e-8) then z = x:Cross(Vector(0, 1, 0)) end
    z:Normalize()
    return x, z:Cross(x), z
end

local function rotOnly(m)
    local r = Matrix(m)
    r:SetTranslation(vector_origin)
    return r
end

-- ---------------------------------------------------------------------------------- joints -> the frames of every bone
-- J = { U, E, W, f = { [1..5] = { p1, p2, p3, tip = direction of the last joint } } } (world positions)
-- returns frames[key] = { x, y, z, pos, len } for the keys "upper", "fore", "hand", "f<finger><joint>"
local function solve(J)
    local F = {}
    local f = J.f
    -- the hand: towards the knuckles, across them (index -> pinky), the palm's normal
    local n, c = 0, Vector(0, 0, 0)
    for i = 2, FINGERS do if (f[i]) then c = c + f[i][1]; n = n + 1 end end
    if (n == 0) then return nil end
    c = c / n
    local first, last
    for i = 2, FINGERS do if (f[i]) then first = first or f[i][1]; last = f[i][1] end end
    local side = (last - first)
    if (side:LengthSqr() < 1e-6) then side = (J.W - J.E):Cross(Vector(0, 0, 1)) end
    local hx, hy, hz = geo(c - J.W, side)        -- hz = towards the knuckles x across = the palm's normal
    hy = hz:Cross(hx)
    local size = 0
    for i = 2, FINGERS do if (f[i]) then size = size + f[i][1]:Distance(J.W) end end
    size = size / n
    F.hand = { hx, hy, hz, J.W, size }
    F.size = size
    for i = 1, FINGERS do
        local fi = f[i]
        if (fi) then
            local ref, ref2 = (i == 1) and hz or hy, (i == 1) and hx or hz   -- the thumb rolls against the palm's normal
            local x, y, z = geo(fi[2] - fi[1], ref, ref2)
            F["f" .. i .. "1"] = { x, y, z, fi[1], fi[1]:Distance(fi[2]) }
            x, y, z = geo(fi[3] - fi[2], ref, ref2)
            F["f" .. i .. "2"] = { x, y, z, fi[2], fi[2]:Distance(fi[3]) }
            x, y, z = geo(fi.tip, ref, ref2)
            F["f" .. i .. "3"] = { x, y, z, fi[3] }
        end
    end
    local x, y, z = geo(J.W - J.E, hz, hy)
    F.fore = { x, y, z, J.E, J.E:Distance(J.W) }
    if (J.U) then
        x, y, z = geo(J.E - J.U, J.W - J.E, hz)
        F.upper = { x, y, z, J.U, J.U:Distance(J.E) }
    end
    return F
end

-- the joints of one arm of entity `ent` (bone matrices from `mat(bone)`), bones named by `a`
local function joints(a, idx, mat)
    local J = { f = {} }
    local function pos(name)
        local i = name and idx[name]
        local m = i and mat(i)
        return m and m:GetTranslation(), m
    end
    J.E = pos(a.fore)
    J.U = pos(a.upper)
    if (not J.E) then return nil end
    for i = 1, FINGERS do
        local fb = a.fingers[i]
        if (fb) then
            local p1, m1 = pos(fb[1])
            local p2, m2 = pos(fb[2])
            local p3, m3 = pos(fb[3])
            if (p1 and p2 and not p3) then
                -- a finger of two bones: its last joint lies where the first bone's own direction, carried on by the
                -- second bone, puts it
                local inv = rotOnly(m1); inv:InvertTR()
                local d = rotOnly(m2) * (inv * (p2 - p1))
                p3, m3 = p2 + d * 0.75, m2
                J.f[i] = { p1, p2, p3, tip = d }
            elseif (p1 and p2 and p3) then
                -- the last joint has no end bone: it points the way the middle joint points along its own bone
                local inv = rotOnly(m2); inv:InvertTR()
                local tip = rotOnly(m3) * (inv * (p3 - p2))
                if (tip:LengthSqr() < 1e-8) then tip = p3 - p2 end
                J.f[i] = { p1, p2, p3, tip = tip }
            end
        end
    end
    if (a.hand) then
        J.W = pos(a.hand)
    else
        local n, c = 0, Vector(0, 0, 0)
        for i = 2, FINGERS do if (J.f[i]) then c = c + J.f[i][1]; n = n + 1 end end
        if (n == 0) then return nil end
        J.W = J.E + (c / n - J.E) * (a.wrist or 0.8)
    end
    if (not J.W) then return nil end
    return J
end

-- ---------------------------------------------------------------------------------------- the player's hands model
local RIGS = {}   -- by hands model: its bones, the rest pose and each arm bone's turn against its joint frame

local function dstArm(s)
    local p = "ValveBiped.Bip01_" .. s .. "_"
    local a = { upper = p .. "UpperArm", fore = p .. "Forearm", hand = p .. "Hand", fingers = {} }
    for i = 0, 4 do a.fingers[i + 1] = { p .. "Finger" .. i, p .. "Finger" .. i .. "1", p .. "Finger" .. i .. "2" } end
    return a
end

local function rigOf(model)
    local R = RIGS[model]
    if (R ~= nil) then return R end
    RIGS[model] = false
    local e = ClientsideModel(model, RENDERGROUP_OPAQUE)
    if (not IsValid(e)) then return false end
    e:SetNoDraw(true); e:SetPos(vector_origin); e:SetAngles(angle_zero)
    e:SetupBones()
    local n = e:GetBoneCount() or 0
    R = { n = n, idx = {}, parent = {}, ref = {}, loc = {}, off = {}, len = {}, key = {}, arm = {}, ent = e }
    for i = 0, n - 1 do
        local name = e:GetBoneName(i)
        if (name) then R.idx[name] = i end
        R.parent[i] = e:GetBoneParent(i) or -1
        R.ref[i] = e:GetBoneMatrix(i) or Matrix()
    end
    for i = 0, n - 1 do
        local p = R.parent[i]
        if (p >= 0) then
            local inv = Matrix(R.ref[p]); inv:Invert()
            R.loc[i] = inv * R.ref[i]
        end
    end
    for _, s in ipairs(SIDES) do
        local a = dstArm(s)
        local J = joints(a, R.idx, function(i) return R.ref[i] end)
        local F = J and solve(J)
        if (F) then
            local keys = { upper = a.upper, fore = a.fore, hand = a.hand }
            for i = 1, FINGERS do for k = 1, 3 do keys["f" .. i .. k] = a.fingers[i][k] end end
            local bones = {}
            for key, name in pairs(keys) do
                local b, fr = R.idx[name], F[key]
                if (b and fr) then
                    local inv = frame(fr[1], fr[2], fr[3], vector_origin); inv:InvertTR()
                    R.off[b] = inv * rotOnly(R.ref[b])
                    R.len[b] = fr[5]
                    bones[key] = b
                end
            end
            -- every bone of this arm (to hide the arm when the old model has none)
            local root = R.idx["ValveBiped.Bip01_" .. s .. "_Clavicle"] or bones.upper
            local sub = {}
            if (root) then
                sub[root] = true
                for i = 0, n - 1 do if (sub[R.parent[i]]) then sub[i] = true end end
            end
            R.arm[s] = { bones = bones, size = F.size, sub = sub, root = root }
        end
    end
    e:AddCallback("BuildBonePositions", function(ent, count)
        local pose = ent.AGPPose
        if (not pose) then return end
        for i = 0, count - 1 do if (pose[i]) then ent:SetBoneMatrix(i, pose[i]) end end
    end)
    RIGS[model] = R
    return R
end

-- ------------------------------------------------------------------------------------------- CAP's own arms hidden
local HIDE = {}
function AGP.BlueprintHide(vm, cfg, on)
    if (AGP.BlueprintShowOld) then return end   -- (tests: CAP's arms stay, ours are drawn over them)
    local mdl = vm:GetModel()
    local t = HIDE[mdl]
    if (not t) then
        t = {}
        for i, m in ipairs(vm:GetMaterials() or {}) do
            local ml = string.lower(m)
            for _, a in ipairs(cfg.hide or {}) do if (ml:find(a, 1, true)) then t[#t + 1] = i - 1 break end end
        end
        HIDE[mdl] = t
    end
    for _, i in ipairs(t) do vm:SetSubMaterial(i, on and "models/effects/vol_light001" or nil) end
end

-- ---------------------------------------------------------------------------------------------------------- drawing
local TINY = Matrix(); TINY:SetScale(Vector(0.0001, 0.0001, 0.0001))

local function pose(vm, cfg, R)
    local idx = vm.AGPBoneIdx
    if (not idx or vm.AGPBoneIdxModel ~= vm:GetModel()) then
        idx = {}
        for i = 0, (vm:GetBoneCount() or 0) - 1 do local nme = vm:GetBoneName(i); if (nme) then idx[nme] = i end end
        vm.AGPBoneIdx, vm.AGPBoneIdxModel = idx, vm:GetModel()
    end
    local P = {}
    local anchor
    for _, s in ipairs(SIDES) do
        local da, sa = R.arm[s], cfg.arms[s]
        if (da) then
            local J = sa and joints(sa, idx, function(i) return vm:GetBoneMatrix(i) end)
            local F = J and solve(J)
            if (F) then
                local sc = F.size / da.size
                for key, b in pairs(da.bones) do
                    local fr = F[key]
                    if (fr) then
                        local sx = (fr[5] and R.len[b] and R.len[b] > 0.01) and (fr[5] / R.len[b]) or sc
                        P[b] = frame(fr[1] * sx, fr[2] * sc, fr[3] * sc, fr[4]) * R.off[b]
                    end
                end
                -- cfg.shift = { L = Vector(x, y, z) }: our arm moved this far in the old forearm bone's own directions (x along the
                -- forearm): where the old item sits ON the arm (GDO on the left forearm) and our thicker sleeve would swallow it
                local sh = cfg.shift and cfg.shift[s]
                if (sh and sa.fore and idx[sa.fore]) then
                    local fm = vm:GetBoneMatrix(idx[sa.fore])
                    if (fm) then
                        local off = rotOnly(fm) * sh
                        cfg.shiftSeen = CurTime()   -- (read by the picture tests: the shift was really applied)
                        for _, b in pairs(da.bones) do
                            if (P[b]) then P[b]:SetTranslation(P[b]:GetTranslation() + off) end
                        end
                    end
                end
                anchor = anchor or (da.bones.upper and P[da.bones.upper] and da.bones.upper) or (P[da.bones.fore] and da.bones.fore)
            else
                -- the old model has no such arm: ours shrinks to nothing
                local at = Matrix(TINY); at:SetTranslation(vm:GetPos())
                for b in pairs(da.sub) do P[b] = at end
            end
        end
    end
    if (not anchor) then return nil end
    -- the bones above the arms (spine, clavicles): as they sit against the arm in the rest pose
    local b = anchor
    while (R.parent[b] >= 0 and not P[R.parent[b]]) do
        local inv = Matrix(R.loc[b]); inv:Invert()
        P[R.parent[b]] = P[b] * inv
        b = R.parent[b]
    end
    -- every other bone (wrist and elbow helpers, a finger the old model has no bones for): rigid on its parent
    for i = 0, R.n - 1 do
        if (not P[i]) then
            local p = R.parent[i]
            if (p >= 0 and P[p] and R.loc[i]) then P[i] = P[p] * R.loc[i] end
        end
    end
    return P
end

function AGP.BlueprintDraw(vm, cfg, ply, flip)
    local hands = IsValid(ply) and ply.GetHands and ply:GetHands()
    local model = (IsValid(hands) and hands:GetModel()) or "models/weapons/c_arms_citizen.mdl"
    local R = rigOf(model)
    if (not R or not IsValid(R.ent)) then
        if (R) then RIGS[model] = nil end
        return
    end
    local e = R.ent
    local P = pose(vm, cfg, R)
    if (not P) then return end
    if (IsValid(hands)) then
        e:SetSkin(hands:GetSkin() or 0)
        for i = 0, (hands:GetNumBodyGroups() or 1) - 1 do e:SetBodygroup(i, hands:GetBodygroup(i)) end
        for i = 0, #(e:GetMaterials() or {}) - 1 do
            local m = hands:GetSubMaterial(i)
            e:SetSubMaterial(i, (m and m ~= "") and m or nil)
        end
        e:SetColor(hands:GetColor())
        if (hands.GetPlayerColor) then e.GetPlayerColor = hands.GetPlayerColor end
    end
    e.AGPPose = P
    e:SetPos(EyePos()); e:SetAngles(vm:GetAngles())   -- (lit at the eye, as the engine lights view models: a view model's own origin can lie under the floor)
    e:SetRenderBounds(Vector(-200, -200, -200), Vector(200, 200, 200))
    e:InvalidateBoneCache()
    e:SetupBones()
    if (flip) then render.CullMode(MATERIAL_CULLMODE_CW) end
    e:DrawModel()
    if (flip) then render.CullMode(MATERIAL_CULLMODE_CCW) end
end
