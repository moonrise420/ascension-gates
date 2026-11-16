-- Ascension Gates (2026-11-14): where a hand weapon's visible shot leaves the weapon.
-- Owner (O2 P90, O3 SGC sidearm, O5 Ronon's gun): "its not accurate were the bullets come out when shooting".
-- Cause: our guns are the HL2 view model's gun hidden and OUR model drawn on its gun bone (agp_sgc_weapons.lua), but the
-- engine starts every first-person tracer and the muzzle flash on the HL2 gun's own muzzle attachment (somewhere else
-- than the barrel tip of our model), and Ronon's pulse was spawned on a fixed offset from the eye.
-- What this file does, for a player's weapon:
--   * first person: the muzzle is the "muzzle" attachment of the model that is DRAWN in the hand (wep.AGPModel); it is
--     seen through the view model's field of view (fov 54 ..), the world through the player's (fov_desired, owner: 100),
--     so the point is carried over to the world projection: the same place on the screen (AGP.MuzzlePos)
--   * third person (also other players): the "muzzle" attachment of the world model
--   * a tracer / flash of ours starts there and ends on the hit point of the bullet (which is still traced from the eye)
-- AGP.MuzzleTrack(SWEP)               after AGP.SGCWeapon(...): remembers where the muzzle was drawn (first person)
-- AGP.MuzzlePos(wep)                  CLIENT: world position, angles of the muzzle as the local player sees it (nil: unknown)
-- AGP.MuzzleShot(wep, bullet, prof)   both realms, before FireBullets: our tracer + flash instead of the engine's; false for an NPC
-- AGP.MuzzleFx(wep, kind, hit, prof)  kind "flash" | "tracer" | "both"; the owner draws his own (CLIENT), the others get it by net
-- AGP.MuzzleWorld(wep)                SERVER: where the owner's weapon muzzle is in the world now (for projectiles); the owner's
--                                     client reports it (SWEP.AGPMuzzleSync = true), else the world model's attachment
-- AGP.MuzzleProfiles[name] = { mat, size, color, life, dlight, tracer }
AddCSLuaFile()
AGP = AGP or {}

AGP.MuzzleProfiles = AGP.MuzzleProfiles or {}
AGP.MuzzleProfiles.bullet = { mat = "effects/muzzleflash2", size = 14, color = Color(255, 220, 160), life = 0.05, dlight = Color(255, 190, 100), tracer = "Tracer" }
-- (red, as CAP's glow of Ronon's gun was: energy_muzzle with the colour 255 50 50 - the first version here was yellow)
AGP.MuzzleProfiles.energy = { mat = "sprites/light_glow02_add", size = 48, color = Color(255, 60, 50), life = 0.18, dlight = Color(255, 50, 40) }

-- the glow of the staff and of the Asuran / Wraith guns: CAP's energy_muzzle / energy_muzzle_asuran effects (a 64 sprite that shrinks
-- to nothing in 0.43 s, a light of 300) - the same look, drawn where the weapon's muzzle really is (they sat on attachment 1 of the old
-- model, which the staff's and the blaster's third person models do not have)
AGP.MuzzleProfiles.staff = { mat = "sprites/light_glow02_add", size = 64, color = Color(255, 200, 120), life = 0.43, linear = true, dlight = Color(255, 200, 120), dlsize = 300 }
AGP.MuzzleProfiles.asuran = { mat = "sprites/light_glow02_add", size = 64, color = Color(119, 176, 255, 215), life = 0.43, linear = true, dlight = Color(119, 176, 255), dlsize = 300 }

local MAXREACH = 130   -- a muzzle further than this from the eye is no muzzle (the longest: a staff's head)

-- Ronon's gun: CAP's "muzzle" attachment of models/w_dexgun.mdl lies 2.7 units beside the mesh and half way along it (measured
-- from the model's vertices, 2026-11-14: the glow and the pulse came out beside / above the gun); the barrel tip is at
-- (2.82, 10.4, -0.74) in model space = this offset on the hand bone (the model's first bone)
AGP.MuzzleTips = AGP.MuzzleTips or {}
-- 2026-11-14: the gun in the hand is now the ORIGINAL one (models/weapons/v_dexgun.mdl laid on the hand bone, weapon_dexgun.lua):
-- its barrel tip (the "barreltip" mesh, Python-bone space (0.46, -0.12, 7.27)) in the same hand bone space, barrel along +x
AGP.MuzzleTips["models/w_dexgun.mdl"] = { bone = "ValveBiped.Bip01_R_Hand", pos = Vector(14.74, -1.49, -3.92), dir = Vector(1, 0, 0) }
-- the Ori staff's first-person model has no attachment: its staff is one mesh on the bone Sphere002, the head at the +y end
-- (local y 7.0 = the last vertex; measured from the model's vertices)
-- the third person models of the staff and the Ori staff have no attachment either: their head (the end with the most detail, measured from
-- the vertices) as an offset on the hand bone, the models' first bone
AGP.MuzzleTips["models/zup/staff/w_staff.mdl"] = { bone = "ValveBiped.Bip01_R_Hand", pos = Vector(-32.4, -1.7, 6.45), dir = Vector(-1, 0, 0) }
AGP.MuzzleTips["models/boba_fett/ori_staff/w_ori_staff.mdl"] = { bone = "ValveBiped.Bip01_R_Hand", pos = Vector(29, 0.9, -7.8), dir = Vector(1, 0, -0.2) }
AGP.MuzzleTips["models/boba_fett/ori_staff/v_ori_staff.mdl"] = { bone = "Sphere002", pos = Vector(-0.2, 6.5, 0.03), dir = Vector(0, 1, 0) }

-- 2026-11-14 (staffs, Wraith / Asuran guns, Ori staff): a world model with no muzzle attachment of its own (or one on the hand):
-- the hand plus the weapon's reach along the aim - the same spot AGP.NPCMuzzle gives an NPC (agp_npcs.lua: staff 50, Wraith
-- stunner 20, Asuran 12, Ori staff 48). `o` = the owner (a player).
function AGP.HandMuzzle(o, reach)
    local b = o:LookupBone("ValveBiped.Bip01_R_Hand")
    local hand = b and o:GetBonePosition(b)
    if (not hand) then return end
    local aim = o:GetAimVector()
    local tr = util.TraceLine({ start = hand, endpos = hand + aim * reach, filter = o, mask = MASK_SHOT })
    return tr.Hit and (tr.HitPos - aim * 2) or tr.HitPos
end

-- the muzzle of a model entity (the world model, or the clientside model drawn in the hand): position, angles
function AGP.MuzzleOf(ent)
    local tip = AGP.MuzzleTips[string.lower(ent:GetModel() or "")]
    if (tip) then
        local b = ent:LookupBone(tip.bone)
        local m = b and ent:GetBoneMatrix(b)
        if (m) then
            local p = m * tip.pos
            return p, ((m * (tip.pos + tip.dir)) - p):Angle()
        end
    end
    local i = ent:LookupAttachment("muzzle")
    if (not i or i <= 0) then i = 1 end
    local a = ent:GetAttachment(i)
    if (a) then return a.Pos, a.Ang end
end

if (SERVER) then
    util.AddNetworkString("agp_muzzle_fx")
    util.AddNetworkString("agp_muzzle_rep")

    -- the owner's client says where it sees the muzzle (relative to the eye: forward, right, up of the view angles)
    net.Receive("agp_muzzle_rep", function(_, ply)
        local w = net.ReadEntity()
        local f, r, u = net.ReadFloat(), net.ReadFloat(), net.ReadFloat()
        local fp = net.ReadBool()
        if (not IsValid(w) or not IsValid(ply) or w:GetOwner() ~= ply) then return end
        if (f ~= f or r ~= r or u ~= u or math.abs(f) > MAXREACH or math.abs(r) > MAXREACH or math.abs(u) > MAXREACH) then return end
        w.AGPMuzzleRep = { f = f, r = r, u = u, fp = fp, at = CurTime() }
    end)

    local function attachment(w)
        w:SetupBones()
        local p, a = AGP.MuzzleOf(w)
        return p and { Pos = p, Ang = a }
    end

    function AGP.MuzzleWorld(w)
        local o = IsValid(w) and w:GetOwner()
        if (not IsValid(o) or not o:IsPlayer()) then return end
        local eye = o:GetShootPos()
        local rep = w.AGPMuzzleRep
        local pos
        if (rep and rep.at > CurTime() - 1.5) then
            local a = o:EyeAngles()
            pos = eye + a:Forward() * rep.f + a:Right() * rep.r + a:Up() * rep.u
        else
            local cfg = w.AGPMuzzleCfg
            if (cfg and cfg.reach and not AGP.MuzzleTips[string.lower(w:GetModel() or "")]) then
                pos = AGP.HandMuzzle(o, cfg.reach)
            else
                local at = attachment(w)
                pos = at and at.Pos
            end
        end
        if (not pos or pos:DistToSqr(eye) > MAXREACH * MAXREACH) then return end
        -- never inside a wall in front of the eye
        local tr = util.TraceLine({ start = eye, endpos = pos, filter = { o, w }, mask = MASK_SHOT })
        if (tr.Hit) then pos = tr.HitPos - (pos - eye):GetNormalized() * 2 end
        return pos
    end

    -- tests: where a projectile starts, relative to the eye (set AGP.MuzzleDebugServer)
    function AGP.MuzzleDebugPulse(w, pos, used)
        if (not AGP.MuzzleDebugServer) then return end
        local o = w:GetOwner()
        local ea, d = o:EyeAngles(), pos - o:GetShootPos()
        print("AGP_RESULT", "INFO", "pulse start " .. w:GetClass(), string.format("eye-relative f=%.1f r=%.1f u=%.1f", d:Dot(ea:Forward()), d:Dot(ea:Right()), d:Dot(ea:Up())), used and "from the owner's muzzle" or "old offset")
    end

    function AGP.MuzzleFx(w, kind, hit, prof)
        local o = IsValid(w) and w:GetOwner()
        if (not IsValid(o) or not o:IsPlayer()) then return end
        net.Start("agp_muzzle_fx")
        net.WriteEntity(w); net.WriteString(kind); net.WriteVector(hit or vector_origin); net.WriteString(prof or "bullet")
        -- the owner's own client draws it from its prediction, except where it does not predict (singleplayer)
        if (game.SinglePlayer()) then net.Send(o) else net.SendOmit(o) end
    end
end

if (SERVER) then
    function AGP.MuzzleTrack(SWEP, cfg) SWEP.AGPMuzzleCfg = cfg end
    function AGP.MuzzlePos() end
end

-- shared: one shot's tracer and flash instead of the engine's (players only; an NPC keeps the engine's, see agp_npcs.lua)
function AGP.MuzzleShot(w, bullet, prof, noFlash)
    local o = IsValid(w) and w:GetOwner()
    if (not IsValid(o) or not o:IsPlayer()) then return false end
    prof = prof or "bullet"
    bullet.Tracer = 0
    local old = bullet.Callback
    bullet.Callback = function(att, tr, dmg)
        if (AGP.MuzzleDebug or AGP.MuzzleDebugServer) then print("AGP_RESULT", "INFO", "muzzle callback", SERVER and "SERVER" or "CLIENT", w:GetClass(), tostring(tr.HitPos)) end
        AGP.MuzzleFx(w, "tracer", tr.HitPos, prof)
        if (old) then return old(att, tr, dmg) end
    end
    if (not noFlash) then AGP.MuzzleFx(w, "flash", nil, prof) end
    return true
end

if (SERVER) then return end

-- ----------------------------------------------------------------------------------------------------- client side
local FLASHES = {}

-- the point as the view model's field of view shows it -> the same place on the screen in the world's field of view.
-- eye frame: f = forward, r = right, u = up; the screen position is (r, u) / f / tan(fov / 2) in both
local function carry(f, r, u, vmFov, worldFov)
    local s = math.tan(math.rad(worldFov) / 2) / math.tan(math.rad(vmFov) / 2)
    return f, r * s, u * s
end

local function fovs(w)
    local v = render.GetViewSetup and render.GetViewSetup() or {}
    local wf = v.fov_unscaled or v.fov or LocalPlayer():GetFOV()
    local vf = v.fovviewmodel_unscaled or v.fovviewmodel or w.ViewModelFOV or 62
    return wf, vf
end

local function muzzleAtt(ent)
    local p, a = AGP.MuzzleOf(ent)
    return p and { Pos = p, Ang = a }
end

local DBGMAT = Material("sprites/light_glow02_add")
local function fovKeys()   -- tests: what the renderer reports about the fields of view
    local t = {}
    for k, x in pairs(render.GetViewSetup()) do
        if (isnumber(x) and k:lower():find("fov")) then t[#t + 1] = k .. "=" .. math.Round(x, 2) end
    end
    table.sort(t)
    return t
end
-- after AGP.SGCWeapon: the muzzle of the model in the hand, as drawn this frame, kept relative to the eye
-- cfg (optional) = { vm = true: the muzzle is on the view model itself (an old CAP model: its attachment / AGP.MuzzleTips),
-- fmt = true: that attachment is already placed for the world's field of view; reach = the third person muzzle is the hand
-- plus this much along the aim (AGP.HandMuzzle) }
function AGP.MuzzleTrack(SWEP, cfg)
    cfg = cfg or {}
    SWEP.AGPMuzzleCfg = cfg
    local oldPost = SWEP.PostDrawViewModel
    function SWEP:PostDrawViewModel(vm, wep, ply)
        if (oldPost) then oldPost(self, vm, wep, ply) end
        local m = cfg.vm and vm or self.AGPModel
        if (IsValid(m)) then
            local at = muzzleAtt(m)
            if (at) then
                if (AGP.MuzzleDebug) then   -- tests: the model's own muzzle where the view model pass draws it (green), its direction (line)
                    render.SetMaterial(DBGMAT)
                    cam.IgnoreZ(true)
                    render.DrawSprite(at.Pos, 1.2, 1.2, Color(0, 255, 0, 255))
                    render.DrawBeam(at.Pos, at.Pos + at.Ang:Forward() * 4, 0.3, 0, 1, Color(0, 255, 0, 255))
                    cam.IgnoreZ(false)
                end
                -- (the view as it is drawn: with the view punch of a shot; EyeAngles() has none and put the point off by the punch)
                local vs = render.GetViewSetup()
                local ea, ep = vs.angles, vs.origin
                local d = at.Pos - ep
                local wf, vf = fovs(self)
                if (AGP.MuzzleDebug and not AGP.MuzzleDumped) then
                    AGP.MuzzleDumped = true
                    local t = fovKeys()
                    print("AGP_RESULT", "INFO", "muzzle viewsetup in PostDrawViewModel", table.concat(t, " "), "ViewModelFOV", tostring(self.ViewModelFOV), "used world/vm", wf, vf)
                end
                local k = { f = d:Dot(ea:Forward()), r = d:Dot(ea:Right()), u = d:Dot(ea:Up()), wf = wf, vf = vf, at = RealTime() }
                local f, r, u = k.f, k.r, k.u
                if (not cfg.fmt) then f, r, u = carry(k.f, k.r, k.u, vf, wf) end
                k.cf, k.cr, k.cu = f, r, u   -- carried over to the world's field of view
                k.pos = ep + ea:Forward() * f + ea:Right() * r + ea:Up() * u   -- ... and in the world, as drawn this frame
                self.AGPMuzzleVM = k
            end
        end
        -- (the old hook's return value is the engine's "do not draw" flag: ours returns nothing)
    end
end

-- the muzzle of `w` as the local player sees it: world position, direction
-- live = true inside a render hook: the point follows the camera of that very frame
function AGP.MuzzlePos(w, live)
    if (not IsValid(w)) then return end
    local o = w:GetOwner()
    if (not IsValid(o)) then return end
    if (o == LocalPlayer() and not o:ShouldDrawLocalPlayer() and GetViewEntity() == o) then
        local k = w.AGPMuzzleVM
        if (not k or k.at < RealTime() - 0.5) then return end
        if (live) then
            local vs = render.GetViewSetup()
            local ea = vs.angles
            return vs.origin + ea:Forward() * k.cf + ea:Right() * k.cr + ea:Up() * k.cu, ea
        end
        return k.pos, EyeAngles()
    end
    local cfg = w.AGPMuzzleCfg
    if (cfg and cfg.reach and not AGP.MuzzleTips[string.lower(w:GetModel() or "")]) then
        local p = AGP.HandMuzzle(o, cfg.reach)
        return p, o:EyeAngles()
    end
    local at = muzzleAtt(w)
    if (at) then return at.Pos, at.Ang end
end

-- the owner's client tells the server where the muzzle is (Ronon's projectile is made there)
local nextRep, lastRep = 0, Vector()
hook.Add("Think", "AGP.MuzzleReport", function()
    local p = LocalPlayer()
    if (not IsValid(p)) then return end
    local w = p:GetActiveWeapon()
    if (not IsValid(w) or not w.AGPMuzzleSync or RealTime() < nextRep) then return end
    local pos = AGP.MuzzlePos(w)
    if (not pos) then return end
    local ea, d = EyeAngles(), pos - EyePos()
    local rep = Vector(d:Dot(ea:Forward()), d:Dot(ea:Right()), d:Dot(ea:Up()))
    if (rep:DistToSqr(lastRep) < 0.04 and RealTime() < nextRep + 1) then return end
    nextRep, lastRep = RealTime() + 0.1, rep
    net.Start("agp_muzzle_rep")
    net.WriteEntity(w); net.WriteFloat(rep.x); net.WriteFloat(rep.y); net.WriteFloat(rep.z)
    net.WriteBool(not p:ShouldDrawLocalPlayer())
    net.SendToServer()
end)

local matCache = {}
local function mat(name)
    local m = matCache[name]
    if (not m) then m = Material(name); matCache[name] = m end
    return m
end

local function addFx(w, kind, hit, profName)
    local prof = AGP.MuzzleProfiles[profName] or AGP.MuzzleProfiles.bullet
    if (kind == "flash" or kind == "both") then
        FLASHES[#FLASHES + 1] = { w = w, prof = prof, t0 = CurTime() }
        if (#FLASHES > 16) then table.remove(FLASHES, 1) end
        if (AGP.MuzzleDebug) then
            AGP.MuzzleMarkUntil = CurTime() + 0.6
            local pos = AGP.MuzzlePos(w)
            local ea, ep = EyeAngles(), EyePos()
            local d = pos and (pos - ep)
            local k = w.AGPMuzzleVM
            print("AGP_RESULT", "INFO", "muzzle " .. w:GetClass(), LocalPlayer():ShouldDrawLocalPlayer() and "tp" or "fp",
                d and string.format("eye-relative f=%.1f r=%.1f u=%.1f", d:Dot(ea:Forward()), d:Dot(ea:Right()), d:Dot(ea:Up())) or "no pos",
                k and string.format("drawn f=%.1f r=%.1f u=%.1f fovs world %.1f vm %.1f", k.f, k.r, k.u, k.wf, k.vf) or "")
        end
    end
    if ((kind == "tracer" or kind == "both") and prof.tracer) then
        local pos = AGP.MuzzlePos(w)
        if (pos and hit) then
            local ed = EffectData()
            ed:SetStart(pos); ed:SetOrigin(hit); ed:SetScale(5000); ed:SetEntity(NULL); ed:SetFlags(0); ed:SetAttachment(0)
            util.Effect(prof.tracer, ed)
            if (AGP.MuzzleDebug) then AGP.MuzzleMarkUntil = CurTime() + 0.6 end
        end
    end
end

-- called by the weapons (both realms; here the owner's own prediction)
function AGP.MuzzleFx(w, kind, hit, prof)
    if (not IsValid(w) or w:GetOwner() ~= LocalPlayer() or game.SinglePlayer()) then return end
    if (not IsFirstTimePredicted()) then return end
    addFx(w, kind, hit, prof)
end

net.Receive("agp_muzzle_fx", function()
    local w, kind, hit, prof = net.ReadEntity(), net.ReadString(), net.ReadVector(), net.ReadString()
    if (IsValid(w)) then addFx(w, kind, hit, prof) end
end)

hook.Add("PostDrawTranslucentRenderables", "AGP.MuzzleFlash", function(depth, sky)
    if (sky) then return end
    local now = CurTime()
    for i = #FLASHES, 1, -1 do
        local f = FLASHES[i]
        local life = f.prof.life or 0.05
        local k = (now - f.t0) / life
        if (k >= 1 or not IsValid(f.w)) then
            table.remove(FLASHES, i)
        else
            local pos = AGP.MuzzlePos(f.w, true)
            if (pos) then
                local c = f.prof.color
                local size, alpha = f.prof.size * (1 - 0.5 * k), 255 * (1 - k)
                if (f.prof.linear) then size, alpha = f.prof.size * (1 - k), c.a or 255 end   -- (CAP's glow: shrinks, does not fade)
                render.SetMaterial(mat(f.prof.mat))
                render.DrawSprite(pos, size, size, Color(c.r, c.g, c.b, alpha))
                local dl = f.prof.dlight
                if (dl and k < 0.6) then
                    local d = DynamicLight(f.w:EntIndex())
                    if (d) then d.pos = pos; d.r, d.g, d.b = dl.r, dl.g, dl.b; d.brightness = 2; d.size = f.prof.dlsize or 120; d.decay = 2000; d.dietime = now + 0.06 end
                end
            end
        end
    end
    -- tests: a marker on the spot every shot leaves from (agp_wpmark 1)
    if (AGP.MuzzleDebug and (AGP.MuzzleMarkUntil or 0) > now) then
        local w = LocalPlayer():GetActiveWeapon()
        local pos = IsValid(w) and AGP.MuzzlePos(w, true)
        if (pos) then
            render.SetMaterial(mat("sprites/light_glow02_add"))
            cam.IgnoreZ(true)
            render.DrawSprite(pos, 1.5, 1.5, Color(255, 0, 255, 255))
            local k = w.AGPMuzzleVM
            if (k and AGP.MuzzleDebugRaw) then   -- (the same point WITHOUT the field of view carried over: cyan)
                local vs = render.GetViewSetup()
                local ea = vs.angles
                render.DrawSprite(vs.origin + ea:Forward() * k.f + ea:Right() * k.r + ea:Up() * k.u, 1.5, 1.5, Color(0, 255, 255, 255))
            end
            cam.IgnoreZ(false)
        end
    end
end)
