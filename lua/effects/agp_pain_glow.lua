--[[
	Ascension Gates (own code, 2026-11-06): the pain stick's light in a victim - eyes and mouth flare with a bright
	amber glow while the jolt lasts, as in the series. EffectData: Entity = the victim, Magnitude = seconds.
]]
local GLOW = Material("sprites/light_glow02_add")

function EFFECT:Init(d)
    self.Victim = d:GetEntity()
    self.Life = d:GetMagnitude() > 0 and d:GetMagnitude() or 0.5
    self.Die = CurTime() + self.Life
    if (IsValid(self.Victim)) then self:SetPos(self.Victim:GetPos()) end
    self:SetRenderBounds(Vector(-60, -60, -10), Vector(60, 60, 100))
end

function EFFECT:Think()
    if (not IsValid(self.Victim) or CurTime() > self.Die) then return false end
    self:SetPos(self.Victim:GetPos())
    return true
end

-- the eyes: the model's "eyes" attachment, else the head bone
local function eyes(e)
    local id = e:LookupAttachment("eyes")
    local a = id and id > 0 and e:GetAttachment(id)
    if (a) then return a.Pos, a.Ang end
    local b = e:LookupBone("ValveBiped.Bip01_Head1")
    local m = b and e:GetBoneMatrix(b)
    if (m) then return m:GetTranslation() + e:GetForward() * 4 + e:GetUp() * 2, e:GetAngles() end
end

function EFFECT:Render()
    local e = self.Victim
    if (not IsValid(e) or (e == LocalPlayer() and not e:ShouldDrawLocalPlayer())) then return end
    local pos, ang = eyes(e)
    if (not pos) then return end
    local f = math.Clamp((self.Die - CurTime()) / self.Life, 0, 1)
    local flick = 0.7 + 0.3 * math.abs(math.sin(CurTime() * 40))
    local c = Color(255, 196, 110, 255 * math.min(1, f * 1.6) * flick)
    local fwd, right, up = ang:Forward(), ang:Right(), ang:Up()
    render.SetMaterial(GLOW)
    for _, s in ipairs({ -1, 1 }) do
        render.DrawSprite(pos + right * s * 1.35 + fwd * 0.6, 5 + 6 * f, 5 + 6 * f, c)
    end
    local mid = e:LookupAttachment("mouth")
    local ma = mid and mid > 0 and e:GetAttachment(mid)
    render.DrawSprite(ma and ma.Pos + fwd * 0.6 or pos - up * 3.4 + fwd * 0.8, 7 + 7 * f, 5 + 5 * f, c)
    local dl = DynamicLight(e:EntIndex() + 8192)
    if (dl) then
        dl.pos = pos + fwd * 6; dl.r, dl.g, dl.b = 255, 160, 70; dl.brightness = 2 * f; dl.size = 90; dl.decay = 600; dl.dietime = CurTime() + 0.1
    end
end
