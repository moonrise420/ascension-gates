--[[
	Shield Core
	Copyright (C) 2011 Madman07
]]
--
include('shared.lua')
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_main_cat");
ENT.PrintName = SGLanguage.GetMessage("entity_shield_core");
end
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.SC_hud = surface.GetTextureID("VGUI/resources_hud/MCD")

function ENT:Draw()
    if self:GetNetworkedBool("ShouldClip", false) then
        self:UpdateClipping()
    else
        self:SetRenderClipPlaneEnabled(false)
    end

    self:DrawModel()
    hook.Remove("HUDPaint", tostring(self.Entity) .. "SC")

    if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
        hook.Add("HUDPaint", tostring(self.Entity) .. "SC", function()
            surface.SetTexture(self.SC_hud)
            surface.SetDrawColor(Color(255, 255, 255, 155))
            surface.DrawTexturedRect(ScrW() / 2 - 24, ScrH() / 2 - 112, 126, 90)
            draw.DrawText(AGP.L("agp_ui_shield_core", "Shield Core"), "header", ScrW() / 2 + 16, ScrH() / 2 - 103, Color(0, 255, 255, 255), 0)
            local enabled = 0

            if IsValid(self) then
                enabled = self:GetNWInt("HUD_Enable", 0)
            end

            local text = "Off"

            if (enabled == 1) then
                text = "On"
            elseif (enabled == 2) then
                text = "Depleted"
            end

            draw.DrawText(AGP.L("agp_ui_shield_73", "Shield: (") .. text .. ")", "center", ScrW() / 2 + 9, ScrH() / 2 - 77, Color(209, 238, 238, 255), 0)
            local percent = 0

            if IsValid(self) then
                percent = self:GetNWInt("HUD_Percent", 0)
            end

            percent = string.format("%G", percent)
            draw.SimpleText(percent .. "%", "center", ScrW() / 2 + 9, ScrH() / 2 - 62, Color(209, 238, 238, 255), 0)
        end)
    end
end

function ENT:UpdateClipping()
    local normal = self:GetUp()
    local distance = normal:Dot(self:GetPos() - normal)
    self:SetRenderClipPlaneEnabled(true)
    self:SetRenderClipPlane(normal, distance)
end

function ENT:OnRemove()
    hook.Remove("HUDPaint", tostring(self.Entity) .. "SC")
end

-- AGP: the old camera editor ("Advanced editor" in the E menu) keeps only what the E menu does not have: each size
-- axis, angles, position and the numpad key. Strength, immunity, look, Atlantis type, shape and colour are in the E menu.
local VGUI = {}
local e -- the core being edited
local function L(k, d, ...) if (AGP and AGP.L) then return AGP.L(k, d, ...) end return select("#", ...) > 0 and string.format(d, ...) or d end

function VGUI:Init()
    -- SHIELD CORE MENU
    local DermaPanel = vgui.Create("DFrame")
    if (AGP and AGP.ApplySkin) then AGP.ApplySkin(DermaPanel) end -- AGP: our look
    DermaPanel:SetPos(ScrW() / 10, ScrH() / 10)
    DermaPanel:SetSize(370, 350)
    DermaPanel:SetTitle(AGP.L("agp_ui_shieldcore_title", "Shield core"))
    DermaPanel:SetVisible(true)
    DermaPanel:SetDraggable(false)
    DermaPanel:ShowCloseButton(false)
    DermaPanel:MakePopup()

    DermaPanel.Paint = function(_, w, h) -- AGP: our look (was a blurred grey screen)
        draw.RoundedBox(10, 0, 0, w, h, (AGP and AGP.Colors and AGP.Colors.bg) or Color(14, 20, 30, 245))
    end

    local image = vgui.Create("DImage", DermaPanel)
    image:SetSize(10, 10)
    image:SetPos(10, 10)
    image:SetImage("gui/agp_logo_128.png")

    --///// TABS
    local Sheet = vgui.Create("DPropertySheet", DermaPanel)
    Sheet:SetPos(25, 40)
    Sheet:SetSize(320, 250)
    local sheet_col = (AGP and AGP.Colors and AGP.Colors.panel) or Color(100, 100, 100, 255) -- AGP: our look
    local sheet_x = 310
    local sheet_y = 220
    local function page()
        local p = vgui.Create("DPanel", Sheet)
        p:SetPos(0, 0)
        p:SetSize(Sheet:GetWide(), Sheet:GetTall())
        p.Paint = function() draw.RoundedBox(6, 0, 0, sheet_x, sheet_y, sheet_col) end
        return p
    end
    local Sheet_Size = page()
    local Sheet_Ang = page()
    local Sheet_Pos = page()
    local Sheet_Key = page()

    Sheet:AddSheet("Size", Sheet_Size, "icon16/user.png", false, false, "Size of the buble.")
    Sheet:AddSheet("Angle", Sheet_Ang, "icon16/user.png", false, false, "Angles of the buble.")
    Sheet:AddSheet("Position", Sheet_Pos, "icon16/user.png", false, false, "Position of the buble.")
    Sheet:AddSheet(L("agp_sc_ed_key", "Key"), Sheet_Key, "icon16/keyboard.png", false, false, L("agp_sc_ed_key_tip", "Numpad key that switches the shield on and off."))
    --////// Const
    local Slider_pos_x = 25
    local Slider_pos_y = { 20, 60, 100 }
    local Slider_size_x = 250
    local Slider_size_y = 50
    local Button_size_x = 75
    local Button_size_y = 25

    -- three sliders (x, y, z) that send their values live (the preview follows), with a reset button
    local function trio(parent, texts, lo, hi, cur, cmd, reset)
        local s = {}
        local function send()
            LocalPlayer():ConCommand(cmd .. e:EntIndex() .. " " .. s[1]:GetValue() .. " " .. s[2]:GetValue() .. " " .. s[3]:GetValue())
        end
        for i = 1, 3 do
            local sl = vgui.Create("DNumSlider", parent)
            sl:SetPos(Slider_pos_x, Slider_pos_y[i])
            sl:SetSize(Slider_size_x, Slider_size_y)
            sl:SetText(texts[i])
            sl:SetMin(lo)
            sl:SetMax(hi)
            sl:SetValue(cur[i])
            sl:SetDecimals(0)
            sl.OnValueChanged = function() if (s[3]) then send() end end
            s[i] = sl
        end
        local r = vgui.Create("DButton", parent)
        r:SetText(AGP.L("agp_ui_reset", "Reset"))
        r:SetPos(200, 160)
        r:SetSize(Button_size_x, Button_size_y)
        r.DoClick = function()
            for i = 1, 3 do s[i]:SetValue(reset) end
            send()
        end
        s.send = send
        return s
    end

    local sz = e:GetNWVector("Size", Vector(512, 512, 512))
    local an = e:GetNWAngle("Ang", Angle(0, 0, 0))
    local ps = e:GetNWVector("Pos", Vector(0, 0, 0))
    local Size = trio(Sheet_Size, { "Size x:", "Size y:", "Size z:" }, 100, 4096, { sz.x, sz.y, sz.z }, "SC_Size", 512)
    local Ang = trio(Sheet_Ang, { "Pitch:", "Yaw:", "Roll:" }, -180, 180, { an.p, an.y, an.r }, "SC_Angle", 0)
    local Pos = trio(Sheet_Pos, { "Position x:", "Position y:", "Position z:" }, -512, 512, { ps.x, ps.y, ps.z }, "SC_Pos", 0)

    --///// NUMPAD KEY
    local menudata = string.Explode(" ", e:GetNWString("MenuData", "0 0 0 0 5"))
    local NumPad = vgui.Create("CtrlNumPad", Sheet_Key)
    NumPad:SetPos(25, 30)
    NumPad.NumPad1:SetValue(tonumber(menudata[5]) or 5)
    NumPad:SetLabel1("Activate shield")
    NumPad:SetSize(150, 60)

    --//////// BUTTONS
    local MenuButtonClose = vgui.Create("DButton")
    MenuButtonClose:SetParent(DermaPanel)
    MenuButtonClose:SetText(AGP.L("agp_ui_close", "Close"))
    MenuButtonClose:SetPos(260, 300)
    MenuButtonClose:SetSize(Button_size_x, Button_size_y)

    MenuButtonClose.DoClick = function(btn)
        if (IsValid(e)) then LocalPlayer():ConCommand("SC_Close" .. e:EntIndex()) end
        DermaPanel:Remove()
    end

    local MenuButtonCreate = vgui.Create("DButton")
    MenuButtonCreate:SetParent(DermaPanel)
    MenuButtonCreate:SetText("OK")
    MenuButtonCreate:SetPos(160, 300)
    MenuButtonCreate:SetSize(Button_size_x, Button_size_y)

    MenuButtonCreate.DoClick = function(btn)
        if (IsValid(e)) then
            Size.send()
            Ang.send()
            Pos.send()
            LocalPlayer():ConCommand("SC_Apply" .. e:EntIndex() .. " " .. NumPad.NumPad1:GetValue())
        end
        DermaPanel:Remove()
    end
end

vgui.Register("ShieldCoreEntry", VGUI)

function ShieldCorePanel(um)
    e = um:ReadEntity()
    if (not IsValid(e)) then return end
    local Window = vgui.Create("ShieldCoreEntry")
    Window:SetMouseInputEnabled(true)
    Window:SetVisible(true)
end

usermessage.Hook("ShieldCorePanel", ShieldCorePanel)

--################# AGP: E menu (owner/admins): on/off, shape, size, strength, recharge speed, colour #################
-- The old camera editor above stays for position, angles, each size axis and the numpad key ("Advanced editor").
local AGPMenu

net.Receive("AGP_ShieldCoreMenu", function()
    local e = net.ReadEntity()
    local on, depleted, strength = net.ReadBool(), net.ReadBool(), net.ReadFloat()
    local power, regen = net.ReadFloat(), net.ReadFloat()
    local imm, draw, atl = net.ReadBool(), net.ReadBool(), net.ReadBool()
    local mod = net.ReadUInt(2)
    local size, col = net.ReadVector(), net.ReadVector()
    local hasRD = net.ReadBool()
    local energy, engage = net.ReadFloat(), net.ReadFloat()
    if (not IsValid(e)) then return end
    if (IsValid(AGPMenu)) then AGPMenu:Remove() end

    local C = (AGP and AGP.Colors) or { text = Color(225, 235, 245), textDim = Color(150, 165, 185), panel = Color(24, 32, 46) }
    local fr = vgui.Create("DFrame")
    AGPMenu = fr
    fr:SetTitle(L("agp_sc_title", AGP.L("agp_ui_shield_core", "Shield Core")))
    fr:SetSize(390, math.min(ScrH() - 40, 660))
    fr:Center()
    fr:MakePopup()
    if (AGP and AGP.ApplySkin) then AGP.ApplySkin(fr) end

    local function send(act, extra)
        net.Start("AGP_ShieldCoreSet")
        net.WriteEntity(e)
        net.WriteUInt(act, 2)
        if (extra) then extra() end
        net.SendToServer()
    end

    -- buttons at the bottom
    local bar = vgui.Create("DPanel", fr)
    bar:Dock(BOTTOM); bar:DockMargin(0, 6, 0, 0); bar:SetTall(30); bar:SetPaintBackground(false)
    local sc = vgui.Create("DScrollPanel", fr)
    sc:Dock(FILL)

    local function label(text, dim)
        local l = sc:Add("DLabel")
        l:Dock(TOP); l:DockMargin(4, 6, 4, 0)
        l:SetWrap(true); l:SetAutoStretchVertical(true)
        l:SetText(text); l:SetTextColor(dim and C.textDim or C.text)
        return l
    end
    -- a slider with its text on its own line above (no text cut off in long languages)
    local function slider(text, lo, hi, dec, val, hint)
        label(text)
        local s = sc:Add("DNumSlider")
        s:Dock(TOP); s:DockMargin(0, 0, 4, 0); s:SetTall(26)
        s:SetText(""); s:SetMin(lo); s:SetMax(hi); s:SetDecimals(dec); s:SetValue(val)
        s.PerformLayout = function(self2) self2.Label:SetWide(0) end
        if (IsValid(s.TextArea)) then s.TextArea:SetTextColor(C.text) end
        s.OnValueChanged = function(self2) self2.AGPTouched = true end
        if (hint) then label(hint, true) end
        return s
    end
    local function check(text, val, tip)
        local c = sc:Add("DCheckBoxLabel")
        c:Dock(TOP); c:DockMargin(4, 8, 4, 0)
        c:SetText(text); c:SetValue(val and 1 or 0); c:SetTextColor(C.text)
        if (tip) then c:SetTooltip(tip) end
        return c
    end

    -- state and on/off
    local state = label("")
    local toggle = sc:Add("DButton")
    toggle:Dock(TOP); toggle:DockMargin(4, 6, 4, 0); toggle:SetTall(28)
    toggle.DoClick = function() send(1) end
    local function stateText()
        local en = e:GetNWInt("HUD_Enable", on and 1 or 0)
        local s = (en == 1) and L("agp_sc_on", "On") or ((en == 2) and L("agp_sc_depleted", "Depleted (recharging)") or L("agp_sc_off", "Off"))
        return L("agp_sc_state", "Shield: %s - strength %s%%", s, math.floor(e:GetNWInt("HUD_Percent", strength))), en ~= 0
    end
    local lastText
    state.Think = function() -- (not the frame's Think: DFrame needs its own for dragging)
        if (not IsValid(e)) then fr:Remove() return end
        local t, isOn = stateText()
        if (t ~= lastText) then
            lastText = t
            state:SetText(t)
            toggle:SetText(isOn and L("agp_sc_switch_off", "Switch off") or L("agp_sc_switch_on", "Switch on"))
        end
    end
    if (hasRD) then
        label(L("agp_sc_energy", "Energy in the network: %s (switching on needs %s, given back when switched off).", string.Comma(math.floor(energy)), string.Comma(math.floor(engage))), true)
    else
        label(L("agp_sc_no_power", "No power network in use: the shield needs no energy."), true)
    end

    -- shape and size
    label(L("agp_sc_shape", "Shape"))
    local shape = sc:Add("DComboBox")
    shape:Dock(TOP); shape:DockMargin(4, 2, 4, 0); shape:SetTall(24)
    shape:AddChoice(L("agp_sc_sphere", "Sphere"), 1, mod == 1)
    shape:AddChoice(L("agp_sc_box", "Box"), 2, mod == 2)
    shape:AddChoice(L("agp_sc_atlantis_shape", "Atlantis (dome)"), 3, mod == 3)
    if (AGP and AGP.StyleCombo) then AGP.StyleCombo(shape) end
    local width = slider(L("agp_sc_width", "Width"), 100, 4096, 0, size.x)
    local height = slider(L("agp_sc_height", "Height"), 100, 4096, 0, size.z)

    -- strength and recharge
    local pow = slider(L("agp_sc_strength", "Strength"), -5, 5, 1, power, L("agp_sc_strength_hint", "Higher: the shield holds more, but recharges slower and uses more energy."))
    local reg = slider(L("agp_sc_regen", "Recharge speed"), 0.25, 4, 2, regen, L("agp_sc_regen_hint", "Faster recharging uses more energy."))

    -- colour
    label(L("agp_sc_colour", "Colour"))
    local mix = sc:Add("DColorMixer")
    mix:Dock(TOP); mix:DockMargin(4, 2, 4, 0); mix:SetTall(120)
    mix:SetPalette(false); mix:SetAlphaBar(false); mix:SetWangs(true)
    mix:SetColor(Color(col.x, col.y, col.z))

    -- other settings
    local cImm = check(L("agp_sc_immunity_out", "Immunity: the owner's friends may pass too, and shots of the owner and his friends get in from outside"), imm) -- the owner always passes
    local cDraw = check(L("agp_sc_draw", "Atlantis-style bubble look (bubble always shown)"), draw)
    local cAtl = check(L("agp_sc_atl", "Atlantis type: stays up as long as there is energy, uses a lot of it"), atl)
    if (not hasRD) then cAtl:SetEnabled(false) end

    local function addButton(text, fn)
        local b = vgui.Create("DButton", bar)
        b:Dock(LEFT); b:DockMargin(0, 0, 4, 0); b:SetText(text)
        b.DoClick = fn
        return b
    end
    local apply = addButton(L("agp_sc_apply", "Apply"), function()
        local _, m = shape:GetSelected()
        local c = mix:GetColor()
        local sx, sy, sz = size.x, size.y, size.z
        if (width.AGPTouched) then sx = width:GetValue(); sy = width:GetValue() end
        if (height.AGPTouched) then sz = height:GetValue() end
        send(2, function()
            net.WriteUInt(tonumber(m) or mod, 2)
            net.WriteVector(Vector(sx, sy, sz))
            net.WriteVector(Vector(c.r, c.g, c.b))
            net.WriteFloat(pow:GetValue())
            net.WriteFloat(reg:GetValue())
            net.WriteBool(cImm:GetChecked()); net.WriteBool(cDraw:GetChecked()); net.WriteBool(cAtl:GetChecked())
        end)
        size = Vector(sx, sy, sz)
        width.AGPTouched, height.AGPTouched = nil, nil
    end)
    local adv = addButton(L("agp_sc_advanced", "Advanced editor"), function() send(3); fr:Close() end)
    local close = addButton(L("agp_sc_close", "Close"), function() fr:Close() end)
    bar.PerformLayout = function(self2, w, h)
        local bw = math.floor((w - 8) / 3)
        local lines = 1
        for _, b in ipairs({ apply, adv, close }) do
            b:SetWide(bw)
            surface.SetFont(b:GetFont() or "DermaDefault")
            local tw = surface.GetTextSize(b:GetText() or "")
            if (tw > bw - 10) then b:SetWrap(true); b:SetContentAlignment(5); lines = math.max(lines, math.ceil(tw / (bw - 14)) + 0) end
        end
        local want = 14 + 16 * lines
        if (self2:GetTall() ~= want) then self2:SetTall(want) end -- a wrapped button text gets the room it needs
    end
    adv:SetTooltip(L("agp_sc_advanced_tip", "Position, angles, each size axis and a numpad key, with a camera view."))

    -- long texts wrap instead of running out of their box (every language)
    if (AGP and AGP.FitTexts) then
        timer.Simple(0, function() if (IsValid(fr)) then AGP.FitTexts(fr) end end)
        timer.Simple(0.2, function() if (IsValid(fr)) then AGP.FitTexts(fr) end end)
    end
end)
