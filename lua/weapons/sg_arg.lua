AddCSLuaFile() --Makes it show up in singleplayer
-- AGP: the loader's own SWEP table (a local one registered by a 0.1 s timer came after the spawn menu was built: the
-- weapon had no class name there yet and was left out of the weapons tab) AGP: name,
-- purpose and how to use it in the player's language (texts agp_arg_* in stargate_agp.lua)
local function LT(k, f) return (AGP and AGP.L) and AGP.L(k, f) or f end

SWEP.PrintName = LT("agp_arg_name", "Anti Replicator Gun")
-- AGP: in our weapons folder (player weapons), like the other Stargate guns
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then SWEP.Category = SGLanguage.GetMessage("weapon_cat") else SWEP.Category = "Stargate" end
list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

--Credits to CryptAlchemy for the ARG model
SWEP.Author = "Nova Astral & CryptAlchemy (Gun Model)"
SWEP.Purpose = LT("agp_arg_purpose", "Destroy those bugs")
SWEP.Instructions = LT("agp_arg_instr", "LMB - Fire Anti Replicator Wave, hold R - search a new frequency")
SWEP.DrawCrosshair = true
SWEP.SlotPos = 10
SWEP.Slot = 2
SWEP.Spawnable = true
SWEP.Weight = 1
SWEP.WorldModel = "models/agp/arg_remaster/replicator_disruptor.mdl" -- remastered (same mesh, bone and size as the CryptAlchemy original at models/cryptalchemy/humans/weapons/)
SWEP.ViewModel = "models/agp/arg_remaster/replicator_disruptor.mdl"
SWEP.ViewModelFOV = 50

SWEP.HoldType = "normal"
SWEP.Primary.Ammo = "none" --This stops it from giving pistol ammo when you get the swep
SWEP.Primary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false

-- AGP: the gun works on one frequency. After a few shots the Replicators adapt to it and only shudder
-- (agp_replicators.lua R.ArgHit); hold R and it searches a new one - sometimes it locks on quickly, sometimes it takes
-- long. The display shows the frequency, its wave, the search and when they have adapted.
local function newFreq(old)
    local R = AGP and AGP.Rep
    for _ = 1, 30 do
        local f = string.format("%.2f", math.Rand(120, 980))
        local known = f == old
        if not known and R and R.adapt then for _, a in pairs(R.adapt) do if a.arg and a.arg[f] then known = true break end end end
        if not known then return f end
    end
    return string.format("%.2f", math.Rand(120, 980))
end

function SWEP:CanPrimaryAttack() return false end
function SWEP:Reload() end
-- AGP: the gun is worn over the right forearm like an arm cannon (the series' gun has a sleeve at the back): the model
-- sits rigidly on the forearm bone (client, DrawWorldModel), the hand inside it is made invisible (bone scale) while the
-- gun is in the hand, and given back when it is put away, dropped, or its owner changes.
local ARM_HAND = "ValveBiped.Bip01_R_Hand"
local function armHand(own, hide)
    if not IsValid(own) or not own.LookupBone then return end
    local b = own:LookupBone(ARM_HAND)
    if b then own:ManipulateBoneScale(b, hide and Vector(0.001, 0.001, 0.001) or Vector(1, 1, 1)) end
end
local function armRelease(self)
    if SERVER and self.ArmOwner then armHand(self.ArmOwner, false); self.ArmOwner = nil end
end
function SWEP:Deploy()
    if SERVER then
        local o = self:GetOwner()
        if IsValid(o) then armHand(o, true); self.ArmOwner = o end
    end
    return true
end
function SWEP:Equip(newOwner)   -- (an NPC is handed the gun: it never "deploys" it)
    if SERVER and IsValid(newOwner) and newOwner:IsNPC() then armHand(newOwner, true); self.ArmOwner = newOwner end
end
function SWEP:OnDrop() armRelease(self) end
function SWEP:OwnerChanged() if SERVER and self.ArmOwner ~= self:GetOwner() then armRelease(self) end end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() armRelease(self) return true end
function SWEP:ShouldDropOnDie() return true end

function SWEP:Initialize()
    if(self.SetHoldType) then
        -- AGP: "pistol": the right arm held out straight at the target, the gun worn over the forearm (it was "physgun",
        -- the gun carried in both hands before the chest)
        self:SetHoldType("pistol")
    end

    self:DrawShadow(false)
    if SERVER then self:SetNWString("ARGFreq", newFreq()) end

    self.IronX = Vector(0,0,0)   -- (the kick when it fires, see PrimaryAttack)
end

-- AGP: where the gun sits. The model's barrel is its +y, its top +z, the grip at its origin (a world model with a
-- single R_Hand bone); its emitter plate in front is 15 units across. To try other places in game:
-- agp_arg_vm "forward right up pitch yaw roll" (first person, from the eye),
-- agp_arg_wm "forward right up pitch yaw roll scale" (third person, from the right hand
-- bone).: the original place (lower right, rolled, running off the bottom-right screen edge: the open rear end is never in view),
-- fitted at fov 100; the screen is on the first-person stand FP_DEF (the collar stand lies below the picture in this pose).
local VM_POSE = { 18, 11, -12, 5, 4, -60 }
-- worn over the right forearm: forward / right / up (along the forearm bone, units of the fitted model's forearm), pitch yaw
-- roll, scale, spin. Yaw -90 turns the barrel (+y) along the forearm (bone +x); the sleeve's bottom plate sits at the wrist.
local WM_BONE, WM_LREF = "ValveBiped.Bip01_R_Forearm", 11
local WM_POSE = { 10.5, 0, 0, 0, -90, 0, 0.7 }
-- how far the gun is turned on its own barrel axis in the hand (degrees; agp_arg_wm's 8th number): its top, with the screen
-- on its stand, then faces up and out instead of into the body
local WM_SPIN = 90
-- the screen on the gun, in the model's own frame.: it sat in the air beside the body and half inside it (the old place cut
-- through the hull, 2900 vertices of the model in front of it). Now it is a small lectern on top of the rear collar: a dark
-- stand (wedge) set into the hull, its slanted face leaning back at 50 degrees to the shooter, the screen flat on that face
-- (nothing of the model in front of it, checked against every triangle of the model, tools in notes). The stand's
-- bottom is inside the hull, so no gap shows; the screen's own bottom edge rests on the hull's surface.
local STAND_TILT = 50
local SCR_POS, SCR_ANG, SCR_SCALE = Vector(0, -1.253, 4.879), Angle(0, 0, STAND_TILT), 0.012   -- (the screen's centre; 4.08 x 2.35 units)
local function standQuads()
    local t = math.rad(STAND_TILT)
    local up = Vector(0, math.cos(t), math.sin(t))
    local A = Vector(0, -2, 3.88)               -- the screen's bottom edge, on the hull
    local B = A + up * 2.4                      -- its top edge
    local W = 2.14                              -- half width of the stand (a little more than the screen's frame)
    local lo = 3.1                              -- the stand's bottom, inside the hull
    local function P(x, p) return Vector(x, p.y, p.z) end
    local a2, b2 = A - up * 0.06, B + up * 0.06
    local top = { P(-W, a2), P(W, a2), P(W, b2), P(-W, b2) }
    local ok = 1
    return {
        { top, ok },                                                                                -- the face under the screen
        { { P(-W, A), P(-W, B), Vector(-W, B.y, lo), Vector(-W, A.y, lo) }, 0.7 },                  -- left side
        { { P(W, A), P(W, B), Vector(W, B.y, lo), Vector(W, A.y, lo) }, 0.7 },                      -- right side
        { { P(-W, B), P(W, B), Vector(W, B.y, lo), Vector(-W, B.y, lo) }, 0.55 },                   -- front
        { { P(-W, A), P(W, A), Vector(W, A.y, lo), Vector(-W, A.y, lo) }, 0.55 },                   -- back
    }
end
local STAND = standQuads()
-- the first-person view has its own stand (the same kind of dark block with the screen on its face, set in the hull) placed
-- where the gun's view model pose shows it: on the hull top further forward, its face turned straight to the eye. In the
-- view model pose the gun's open rear end must run off the screen (never hang in the air), and the collar's stand
-- near the rear end is then out of view. C = the screen's centre, n = its normal (to the eye), u = its up.
local FP_DEF = { 3.387, 5.608, 5.377, 0.013, -0.888, 0.460, 0.893, 0.217, 0.393 }
local cvFp = CLIENT and CreateClientConVar("agp_arg_fpst", "", false, false) or nil   -- "cx cy cz nx ny nz ux uy uz": the first-person stand, for trying
local function standBox(C, n, up, W, Hh, depth)
    n = n:GetNormalized(); up = (up - n * up:Dot(n)):GetNormalized()
    local r = up:Cross(n)
    local function pt(a, b, d) return C + r * a + up * b - n * d end
    local f = { pt(-W, -Hh, 0.04), pt(W, -Hh, 0.04), pt(W, Hh, 0.04), pt(-W, Hh, 0.04) }
    local b = { pt(-W, -Hh, depth), pt(W, -Hh, depth), pt(W, Hh, depth), pt(-W, Hh, depth) }
    return {
        { f, 1 },
        { { f[1], f[4], b[4], b[1] }, 0.7 }, { { f[2], f[3], b[3], b[2] }, 0.7 },
        { { f[3], f[4], b[4], b[3] }, 0.55 }, { { f[1], f[2], b[2], b[1] }, 0.55 },
        { b, 0.4 },
    }, r
end
local STAND_COL = Color(30, 33, 38)
-- toWorld(localVector) -> world position; the stand is drawn with both windings (so it needs no culling set-up)
local function drawStand(toWorld, quads)
    render.SetColorMaterial()
    for _, q in ipairs(quads or STAND) do
        local c = Color(STAND_COL.r * q[2], STAND_COL.g * q[2], STAND_COL.b * q[2])
        local v = q[1]
        local p1, p2, p3, p4 = toWorld(v[1]), toWorld(v[2]), toWorld(v[3]), toWorld(v[4])
        render.DrawQuad(p1, p2, p3, p4, c)
        render.DrawQuad(p4, p3, p2, p1, c)
    end
end
local cvVM = CLIENT and CreateClientConVar("agp_arg_vm", "", false, false) or nil
local cvWM = CLIENT and CreateClientConVar("agp_arg_wm", "", false, false) or nil
local cvScr = CLIENT and CreateClientConVar("agp_arg_scr", "", false, false) or nil   -- "x y z pitch yaw roll": the screen elsewhere (no stand), for trying places
local function nums(cv, n, def)
    if not cv then return def end
    local t = {}
    for v in cv:GetString():gmatch("%S+") do t[#t + 1] = tonumber(v) or 0 end
    return #t >= n and t or def
end

local fpCache = {}
local function fpStand()
    local o = nums(cvFp, 9, FP_DEF)
    local key = table.concat(o, " ")
    local c = fpCache[key]
    if not c then
        local C, n, up = Vector(o[1], o[2], o[3]), Vector(o[4], o[5], o[6]), Vector(o[7], o[8], o[9])
        local quads, r = standBox(C, n, up, 2.14, 1.26, 4.2)
        c = { quads = quads, pos = C + n:GetNormalized() * 0.03, ang = r:AngleEx(n:GetNormalized()) }
        fpCache = { [key] = c }
    end
    return c
end
local function scrPose()
    local o = nums(cvScr, 6, nil)
    if o then return Vector(o[1], o[2], o[3]), Angle(o[4], o[5], o[6]), false end
    return SCR_POS, SCR_ANG, true
end

-- the view model is projected with a field of view that follows the player's: the lower fov_desired, the further out and the bigger
-- the gun is drawn (at fov 75 it had slid off the screen, at 100 it sits as framed; a player plays at 100). The framing is made the
-- same at every FOV by moving the gun away along the view (towards the eye at fov > 100). The shifts were measured in game
-- (agp_arg_fova "s<units>" tries one): the screen on the stand lands where it does at fov 100, at the same size.
local FOV_SHIFT = { { 60, 55 }, { 70, 35 }, { 75, 26 }, { 80, 17 }, { 90, 6 }, { 100, 0 }, { 110, -4.7 }, { 120, -7.5 }, { 140, -12 } }
local cvFovA = CLIENT and CreateClientConVar("agp_arg_fova", "", false, false) or nil
local function fovShift()   -- how many units the gun is moved away along the view at the player's current FOV
    local lp = LocalPlayer()
    if not IsValid(lp) then return 0 end
    local f = lp:GetFOV()
    if not f or f <= 1 then return 0 end
    local str = cvFovA:GetString()
    if str == "off" then return 0 end
    if str:sub(1, 1) == "s" then return tonumber(str:sub(2)) or 0 end   -- (test: "s12" = 12 units away)
    local t = FOV_SHIFT
    if f <= t[1][1] then return t[1][2] end
    for i = 2, #t do
        if f <= t[i][1] then return Lerp((f - t[i - 1][1]) / (t[i][1] - t[i - 1][1]), t[i - 1][2], t[i][2]) end
    end
    return t[#t][2]
end

function SWEP:GetViewModelPosition(EyePos, EyeAng)
    local o = nums(cvVM, 6, VM_POSE)
    local F, R, U = EyeAng:Forward(), EyeAng:Right(), EyeAng:Up()
    local kick = self.IronX and self.IronX.x or 0   -- (when it fires: back and up a little)
    local a = Angle(EyeAng.p, EyeAng.y, EyeAng.r)
    a:RotateAroundAxis(U, o[5] - 90)   -- the barrel (+y) along the view
    a:RotateAroundAxis(R, o[4] + kick * 0.6)
    a:RotateAroundAxis(F, o[6])
    return EyePos + F * ((o[1] - kick * 0.4) + fovShift()) + R * o[2] + U * o[3], a
end

if SERVER then
    function SWEP:OnRemove() armRelease(self) end   -- (stripped, killed, removed: the owner's hand comes back)
    -- AGP: holding R searches a new frequency; let go and the search slowly falls back (and the old one stays)
    function SWEP:Think()
        local ply = self:GetOwner()
        if not IsValid(ply) or not ply:IsPlayer() then return end   -- (an NPC holding it has no keys)
        local held = ply:KeyDown(IN_RELOAD) and ply:GetActiveWeapon() == self   -- (only the gun in the hand searches)
        if not held then self.TuneDone = nil end
        local t = self.Tune
        if held and not t and not self.TuneDone then -- (a new search only after R was let go)
            local r = math.random()
            t = { p = 0, dur = (r < 0.3 and math.Rand(1.2, 2.5)) or (r < 0.75 and math.Rand(3, 5.5)) or math.Rand(6.5, 10), target = newFreq(self:GetNWString("ARGFreq")) }
            self.Tune = t
            self:SetNWString("ARGTarget", t.target)
            self:SetNWBool("ARGTuning", true)
            self:EmitSound("buttons/blip1.wav", 55, 70, 0.5)
        end
        if not t then return end
        local now = CurTime()
        local dt = math.min(1, now - (t.last or now))
        t.last = now
        t.p = held and (t.p + dt / t.dur) or (t.p - dt * 0.25)
        if t.p <= 0 and not held then
            self.Tune = nil
            self:SetNWBool("ARGTuning", false); self:SetNWFloat("ARGTune", 0)
            return
        end
        self:SetNWFloat("ARGTune", math.Clamp(t.p, 0, 1))
        self:SetNWBool("ARGHeld", held)
        if t.p >= 1 then
            self.Tune, self.TuneDone = nil, true
            self:SetNWString("ARGFreq", t.target)
            self:SetNWFloat("ARGLockT", CurTime())
            self:SetNWBool("ARGTuning", false); self:SetNWBool("ARGStale", false); self:SetNWFloat("ARGTune", 0)
            self:EmitSound("buttons/combine_button1.wav", 60, 120, 0.7)
        end
    end

    -- AGP: one wave, for the player's click and for an NPC's shot: a properly spawned entity (position, angles, owner and
    -- frequency set first, then Spawn: Initialize runs once there). The owner does not collide with it.
    local function launch(self, owner, pos, ang, dir)
        local ent = ents.Create("sg_arg_projectile")
        if not IsValid(ent) then return end
        ent.ARGFreq = self:GetNWString("ARGFreq") -- AGP: the wave carries the gun's frequency
        ent:SetOwner(owner)
        ent:SetPos(pos)
        ent:SetAngles(ang)
        ent:Spawn()
        ent:Activate()
        ent:SetColor(Color(255,255,255,0))
        local Phys = ent:GetPhysicsObject()
        if(IsValid(Phys)) then
            Phys:EnableGravity(false)
            Phys:SetVelocity(dir * 800)
        end
        local sw = self
        timer.Simple(0.01,function() --i dont know why, but the sound only works in a timer
            if IsValid(sw) then sw:EmitSound("weapons/arg_fire.mp3",75,100,1) end
        end)
        return ent
    end

    function SWEP:PrimaryAttack()
        local ply = self:GetOwner()
        if(not IsValid(ply)) then return end
        if ply:IsNPC() then return end -- (an NPC fires through NPCShoot_Primary)
        if self.Tune and ply:KeyDown(IN_RELOAD) then return end -- AGP: searching a frequency
        self:SetNextPrimaryFire(CurTime()+2)

        local eyeang = ply:EyeAngles()
        launch(self, ply, ply:EyePos() + eyeang:Forward()*10 - eyeang:Right()*5 - eyeang:Up()*5, eyeang, ply:GetAimVector()) -- AGP: eye-relative (was world Vector(10,5,-5))
    end

    -- AGP: an NPC holding it shoots at its enemy (the wave only carries ~900 units: it does not fire from further)
    function SWEP:GetCapabilities() return CAP_WEAPON_RANGE_ATTACK1 end
    function SWEP:NPCShoot_Primary(shootPos, shootDir)
        local npc = self:GetOwner()
        if not IsValid(npc) then return end
        local en = npc.GetEnemy and npc:GetEnemy()
        if IsValid(en) and npc:GetPos():DistToSqr(en:GetPos()) > 1000 * 1000 then return end
        if CurTime() < (self.NPCNextShot or 0) then return end
        self.NPCNextShot = CurTime() + 2   -- (the player's rate)
        shootPos = shootPos or npc:EyePos()
        shootDir = shootDir or npc:GetAimVector()
        launch(self, npc, shootPos + shootDir * 10, shootDir:Angle(), shootDir)
    end
    function SWEP:GetNPCRestTimes() return 1.5, 2.5 end        -- pause between bursts
    function SWEP:GetNPCBurstSettings() return 1, 1, 2 end      -- one wave at a time (min, max, delay between them)
    function SWEP:GetNPCBulletSpread(prof) return 1 end         -- (no bullets; the wave flies where it is aimed)
else --client
    -- AGP: the frequency display, a small screen on the gun: frequency, its wave on a scope, the band with the search
    -- sweeping across it, the search's progress and the state (locked / searching / adapted)
    surface.CreateFont("AGPArgFreq", { font = "Consolas", size = 30, weight = 700, antialias = true })
    surface.CreateFont("AGPArgUnit", { font = "Consolas", size = 14, weight = 700, antialias = true })
    surface.CreateFont("AGPArgTag", { font = "Arial", size = 11, weight = 800, antialias = true })
    surface.CreateFont("AGPArgText", { font = "Arial", size = 13, weight = 700, antialias = true })
    local C = { bg = Color(14, 20, 30, 228), scope = Color(8, 12, 20, 240), grid = Color(44, 70, 110, 70), edge = Color(44, 70, 110, 255),
        blue = Color(56, 150, 240), orange = Color(255, 160, 50), red = Color(240, 72, 60), text = Color(225, 235, 245), dim = Color(150, 165, 185) }
    local function L(k, f) return (AGP and AGP.L) and AGP.L(k, f) or f end
    local function noise(i, t) return math.sin(i * 91.7 + t * 37) * 0.55 + math.sin(i * 13.3 - t * 23) * 0.45 end
    -- a line with a soft glow under it
    local function wave(pts, col, a)
        for pass = 1, 2 do
            local w = pass == 1 and 2 or 0
            surface.SetDrawColor(col.r, col.g, col.b, pass == 1 and 50 * a or 255 * a)
            for i = 2, #pts do
                local p, q = pts[i - 1], pts[i]
                if w > 0 then
                    surface.DrawLine(p[1], p[2] - 1, q[1], q[2] - 1); surface.DrawLine(p[1], p[2] + 1, q[1], q[2] + 1)
                else
                    surface.DrawLine(p[1], p[2], q[1], q[2])
                end
            end
        end
    end
    local function drawPanel(self, x, y)
        local w, h = 330, 186
        local t = RealTime()
        local ct = CurTime()
        local freq = self:GetNWString("ARGFreq", "")
        local target = self:GetNWString("ARGTarget", freq)
        local tuning = self:GetNWBool("ARGTuning", false)
        local prog = self:GetNWFloat("ARGTune", 0)
        local held = self:GetNWBool("ARGHeld", false)
        local stale = self:GetNWBool("ARGStale", false)
        local lockAge = ct - self:GetNWFloat("ARGLockT", -10)
        local resAge = ct - self:GetNWFloat("ARGResistT", -10)
        local col = tuning and C.orange or (stale and C.red or C.blue)
        local blink = (math.sin(t * 8) > 0) and 1 or 0.35

        draw.RoundedBox(13, x - 5, y - 5, w + 10, h + 10, Color(26, 29, 34, 255))   -- the screen's frame on the gun
        draw.RoundedBox(10, x, y, w, h, Color(10, 15, 23, 252))
        if resAge < 0.6 then draw.RoundedBox(10, x - 2, y - 2, w + 4, h + 4, Color(C.red.r, C.red.g, C.red.b, 120 * (1 - resAge / 0.6))) draw.RoundedBox(10, x, y, w, h, C.bg) end
        if lockAge < 1 then draw.RoundedBox(10, x - 2, y - 2, w + 4, h + 4, Color(C.blue.r, C.blue.g, C.blue.b, 140 * (1 - lockAge))) draw.RoundedBox(10, x, y, w, h, C.bg) end
        surface.SetDrawColor(col.r, col.g, col.b, 255); surface.DrawRect(x + 12, y, w - 24, 3)
        draw.SimpleText(L("agp_arg_title", "ANTI-REPLICATOR DISRUPTOR"), "AGPArgTag", x + 14, y + 10, C.dim)
        draw.SimpleText(L("agp_arg_band", "SUBSPACE FREQUENCY"), "AGPArgTag", x + w - 14, y + 10, C.dim, TEXT_ALIGN_RIGHT)

        -- the frequency: while searching, the digits of the new one lock in from the left, the rest still runs
        local shown = freq
        if tuning then
            local n = #target
            local fixed = math.floor(prog * n)
            local out = {}
            for i = 1, n do
                local ch = target:sub(i, i)
                if i > fixed and ch ~= "." then ch = tostring((math.floor(t * 23 + i * 7)) % 10) end
                out[i] = ch
            end
            shown = table.concat(out)
        end
        local fcol = tuning and C.orange or (stale and Color(C.red.r, C.red.g, C.red.b, 255 * (0.6 + 0.4 * blink)) or C.text)
        draw.SimpleText(shown, "AGPArgFreq", x + 14, y + 24, fcol)
        surface.SetFont("AGPArgFreq")
        local fw = surface.GetTextSize(shown)
        draw.SimpleText("THz", "AGPArgUnit", x + 20 + fw, y + 38, C.dim)

        -- the scope
        local sx, sy, sw, sh = x + 14, y + 62, w - 28, 66
        draw.RoundedBox(4, sx, sy, sw, sh, C.scope)
        surface.SetDrawColor(C.grid)
        for i = 1, 7 do surface.DrawLine(sx + sw * i / 8, sy + 2, sx + sw * i / 8, sy + sh - 2) end
        surface.DrawLine(sx + 2, sy + sh / 2, sx + sw - 2, sy + sh / 2)
        local fnum = tonumber(tuning and target or freq) or 500
        local k = 0.08 + (fnum - 120) / 860 * 0.32   -- each frequency its own wavelength
        local pts = {}
        local N = 110
        for i = 0, N do
            local px = sx + 3 + (sw - 6) * i / N
            local v
            if tuning then
                local kk = Lerp(prog, 0.05 + (math.sin(t * 3) * 0.5 + 0.5) * 0.4, k)
                v = math.sin(i * kk * 3 + t * 9) * prog * 0.8 + noise(i, t) * (1 - prog) * 0.7
            elseif stale then
                v = math.sin(i * k * 3 + t * 7) * 0.75 * (0.4 + 0.6 * math.abs(math.sin(t * 13))) + noise(i, t) * 0.25
            else
                v = math.sin(i * k * 3 + t * 7) * 0.8
            end
            pts[#pts + 1] = { px, sy + sh / 2 - v * (sh / 2 - 4) }
        end
        wave(pts, col, 1)
        if tuning then   -- the sweep scanning across the scope
            local sxp = sx + 3 + (sw - 6) * ((t * 0.9) % 1)
            surface.SetDrawColor(C.orange.r, C.orange.g, C.orange.b, 90); surface.DrawRect(sxp - 1, sy + 2, 3, sh - 4)
        end

        -- the band: where on it the frequency sits; while searching a marker sweeps it, the new one shows more and more
        local bx, by, bw = x + 14, y + 138, w - 28
        surface.SetDrawColor(C.edge); surface.DrawRect(bx, by + 4, bw, 1)
        for i = 0, 20 do local hh = (i % 5 == 0) and 6 or 3 surface.DrawRect(bx + bw * i / 20, by + 5 - hh / 2, 1, hh) end
        local function mark(f, c, a)
            local mx = bx + bw * math.Clamp((f - 120) / 860, 0, 1)
            surface.SetDrawColor(c.r, c.g, c.b, 255 * a); surface.DrawRect(mx - 1, by - 2, 3, 13)
        end
        mark(tonumber(freq) or 500, stale and C.red or C.blue, tuning and 0.4 or 1)
        if tuning then
            mark(120 + 860 * (math.sin(t * 2.7) * 0.5 + 0.5), C.orange, 0.8)
            mark(tonumber(target) or 500, C.orange, prog)
        end

        -- the search's progress and the state
        local px, py, pw = x + 14, y + 155, w - 28
        local seg = 30
        for i = 0, seg - 1 do
            local on = tuning and (i + 1) / seg <= prog
            local c = on and C.orange or Color(36, 52, 76)
            surface.SetDrawColor(c.r, c.g, c.b, 255); surface.DrawRect(px + i * pw / seg, py, pw / seg - 2, 5)
        end
        local msg, mcol
        if tuning and held then msg, mcol = L("agp_arg_searching", "SEARCHING FREQUENCY") .. "  " .. math.floor(prog * 100) .. " %", C.orange
        elseif tuning then msg, mcol = L("agp_arg_hold", "HOLD R TO KEEP SEARCHING"), Color(C.orange.r, C.orange.g, C.orange.b, 255 * blink)
        elseif lockAge < 2 then msg, mcol = L("agp_arg_locked", "NEW FREQUENCY LOCKED"), C.blue
        elseif stale then msg, mcol = L("agp_arg_adapted", "THEY HAVE ADAPTED - HOLD R TO RETUNE"), Color(C.red.r, C.red.g, C.red.b, 255 * blink)
        else msg, mcol = L("agp_arg_ready", "READY  -  hold R: new frequency"), C.dim end
        draw.SimpleText(msg, "AGPArgText", x + 14, y + 164, mcol)

        -- ticks while searching (faster and higher as it closes in)
        if tuning and held and t > (self.ArgTick or 0) then
            self.ArgTick = t + 0.16 - prog * 0.1
            surface.PlaySound("buttons/blip1.wav")
        end
    end

    -- the screen on top of the gun (right, behind the emitter), fixed to the gun model: it moves with every sway and
    -- the kick when it fires (depth tested: parts of the gun in front of it hide it, as they would)
    -- (the night's weapon sweep: "the gun floats in first person, no hands") the player's own hands on the gun's grip:
    -- GMod's pistol grip (the hand pose of c_pistol's idle) is laid on the gun where HAND_POSE says - the hand bone's
    -- place in the gun model's own frame (forward right up pitch yaw roll; to try others in game:
    -- agp_arg_hand "f r u p y r"). The hands are the hands model of the player (sleeve, skin).
    local HAND_POSE = { 0, 0, 0, 0, 0, 0 }
    local cvHand = CreateClientConVar("agp_arg_hand", "", false, false)
    local donor, arms, boneIn
    local function drawHands(vm, ply)
        local hands = IsValid(ply) and ply.GetHands and ply:GetHands()
        local model = (IsValid(hands) and hands:GetModel()) or "models/weapons/c_arms_citizen.mdl"
        if not IsValid(donor) then
            donor = ClientsideModel("models/weapons/c_pistol.mdl", RENDERGROUP_OPAQUE)
            if not IsValid(donor) then return end
            donor:SetNoDraw(true)
            local seq = donor:SelectWeightedSequence(ACT_VM_IDLE)
            if seq and seq >= 0 then donor:ResetSequence(seq) end
            donor:SetPos(vector_origin); donor:SetAngles(angle_zero); donor:SetupBones()
            local b = donor:LookupBone("ValveBiped.Bip01_R_Hand")
            local m = b and donor:GetBoneMatrix(b)
            if not m then donor:Remove(); donor = nil return end
            local ip, ia = WorldToLocal(vector_origin, angle_zero, m:GetTranslation(), m:GetAngles())   -- the donor's origin seen from its hand bone
            boneIn = { ip, ia }
        end
        if not IsValid(arms) or arms:GetModel() ~= model then
            if IsValid(arms) then arms:Remove() end
            arms = ClientsideModel(model, RENDERGROUP_OPAQUE)
            if not IsValid(arms) then return end
            arms:SetNoDraw(true); arms:SetParent(donor); arms:AddEffects(EF_BONEMERGE)
        end
        local h = nums(cvHand, 6, HAND_POSE)
        local gp, ga = LocalToWorld(Vector(h[1], -h[2], h[3]), Angle(h[4], h[5], h[6]), vm:GetPos(), vm:GetAngles())   -- where the hand bone goes
        local dp, da = LocalToWorld(boneIn[1], boneIn[2], gp, ga)
        donor:SetPos(dp); donor:SetAngles(da); donor:SetupBones()
        if IsValid(hands) then
            arms:SetSkin(hands:GetSkin() or 0)
            for i = 0, #(arms:GetMaterials() or {}) - 1 do
                local mat = hands:GetSubMaterial(i)
                arms:SetSubMaterial(i, (mat and mat ~= "") and mat or nil)
            end
        end
        arms:SetupBones(); arms:DrawModel()
    end

    function SWEP:PostDrawViewModel(vm, wep, ply)
        -- (not on yet: with the gun where it sits, its grip - and so the hand on it - lies below the view; a visible
        -- support hand on the top handle is still to be made. agp_arg_hand "f r u p y r" shows the grip hand for tuning.)
        if (cvHand:GetString() ~= "") then drawHands(vm, ply or LocalPlayer()) end
        local spos, sang, stand = scrPose()
        local k = 1
        if stand then local fp = fpStand(); spos, sang = fp.pos, fp.ang; drawStand(function(v) return vm:LocalToWorld(v * k) end, fp.quads) end
        cam.Start3D2D(vm:LocalToWorld(spos * k), vm:LocalToWorldAngles(sang), SCR_SCALE * k)
        drawPanel(self, -165, -93)
        cam.End3D2D()
    end
    -- in someone's hand (others see it, and he in third person): the model drawn at his right hand, level along the
    -- arm and a bit smaller (bone-merged as it comes it pointed 40 degrees down and outwards, at full size)
    function SWEP:OnRemove() if IsValid(self.AGPWM) then self.AGPWM:Remove() end end
    function SWEP:DrawWorldModel()
        local own = self:GetOwner()
        if not IsValid(own) then   -- lying on the ground: the screen on its stand, as in the hand
            self:DrawModel()
            if self:GetPos():DistToSqr(EyePos()) > 600 * 600 then return end
            local spos, sang, stand = scrPose()
            if stand then drawStand(function(v) return self:LocalToWorld(v) end) end
            local sp, sa = self:LocalToWorld(spos), self:LocalToWorldAngles(sang)
            if (EyePos() - sp):Dot(sa:Up()) > 0 or not stand then   -- (not from behind: it would read mirrored)
                cam.Start3D2D(sp, sa, SCR_SCALE)
                drawPanel(self, -165, -93)
                cam.End3D2D()
            end
            return
        end
        if own == LocalPlayer() and not own:ShouldDrawLocalPlayer() then return end
        local fb, hb = own:LookupBone(WM_BONE), own:LookupBone("ValveBiped.Bip01_R_Hand")
        local m, hm = fb and own:GetBoneMatrix(fb), hb and own:GetBoneMatrix(hb)
        if not m or not hm then self:DrawModel() return end
        local w = nums(cvWM, 7, WM_POSE)
        local k = m:GetTranslation():Distance(hm:GetTranslation()) / WM_LREF   -- (this model's forearm vs the one it was fitted on)
        local cs = self.AGPWM
        if not IsValid(cs) then cs = ClientsideModel(self.WorldModel, RENDERGROUP_OPAQUE); cs:SetNoDraw(true); self.AGPWM = cs end
        local pos, ang = LocalToWorld(Vector(w[1] * k, -w[2] * k, w[3] * k), Angle(w[4], w[5], w[6]), m:GetTranslation(), m:GetAngles())
        ang:RotateAroundAxis(-ang:Right(), w[8] or WM_SPIN)   -- (the barrel is the model's +y)
        local sc = w[7] * k
        pos = pos + ang:Up() * (0.35 * sc)   -- (the sleeve's axis runs 0.35 below the model's origin)
        if cs.AGPScale ~= sc then local mat = Matrix(); mat:Scale(Vector(sc, sc, sc)); cs:EnableMatrix("RenderMultiply", mat); cs.AGPScale = sc end
        cs:SetPos(pos); cs:SetAngles(ang); cs:SetupBones(); cs:DrawModel()
        if own:GetPos():DistToSqr(EyePos()) > 600 * 600 then return end
        local spos, sang, stand = scrPose()
        if stand then drawStand(function(v) return (LocalToWorld(v * sc, angle_zero, pos, ang)) end) end
        local sp, sa = LocalToWorld(spos * sc, sang, pos, ang)
        if (EyePos() - sp):Dot(sa:Up()) > 0 or not stand then   -- (not from behind: it would read mirrored)
            cam.Start3D2D(sp, sa, SCR_SCALE * sc)
            drawPanel(self, -165, -93)
            cam.End3D2D()
        end
    end

    function SWEP:PrimaryAttack() --fire anim
        timer.Simple(0.2,function()
            local movedir = 0.5
            local x = 5
            self.IronX = Vector(x,0,0)

            timer.Create("ARG_FireAnim"..self:EntIndex(),0.01,200,function()
                x = x + movedir
                if(x <= 0) then
                    timer.Remove("ARG_FireAnim"..self:EntIndex())
                    x = 0
                    movedir = 0
                elseif(x >= 10) then
                    movedir = -0.5
                end

                self.IronX = Vector(x + movedir,0,0)
            end)
        end)
    end
end
