-- Ascension Gates: our own Derma skin (dark, flat, rounded, blue/orange accents) for the pack's windows.
-- Built on the default skin, only the look changes. Use AGP.ApplySkin(panel) on a window.
AGP = AGP or {}
AGP.Colors = {
	bg = Color(14, 20, 30, 245),       -- window background
	panel = Color(24, 32, 46, 255),    -- boxes inside
	edge = Color(44, 70, 110, 255),    -- box border
	button = Color(36, 52, 76, 255),
	hover = Color(52, 80, 118, 255),
	accent = Color(56, 150, 240, 255), -- blue
	accent2 = Color(255, 160, 50, 255), -- orange
	text = Color(225, 235, 245, 255),
	textDim = Color(150, 165, 185, 255),
	field = Color(10, 14, 22, 255),
	tabbar = Color(10, 15, 24, 250),
	select = Color(36, 98, 168, 255),   -- AGP 2026-11-08: selected rows, pressed buttons (white text on accent was only 3:1)
	textOnBright = Color(20, 24, 30, 255), -- AGP 2026-11-08: text on bright ground (Garry's Mod's own white tool pages)
}

-- AGP 2026-11-08: readable text everywhere (owner: "dark background - white text, bright background - black text").
-- Relative luminance, 0 = black .. 1 = white (the WCAG contrast formula).
local function lum(c)
	local function ch(v) v = (v or 0) / 255 return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
	return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b)
end
AGP.Luminance = lum

-- A text colour that reads on dark ground (onDark true or nil) or on bright ground (false). On dark: black/grey text becomes
-- our light text, a dark colour is lifted toward white and keeps its hue (red stays red). On bright: a light colour darkens.
function AGP.ReadableText(c, onDark)
	if not c then return c end
	local light = (AGP.Colors and AGP.Colors.text) or Color(225, 235, 245)
	local grey = math.max(c.r, c.g, c.b) - math.min(c.r, c.g, c.b) < 48
	if onDark ~= false then
		if lum(c) >= 0.3 then return c end
		if grey then return Color(light.r, light.g, light.b, c.a) end
		for i = 1, 10 do
			local t = i / 10
			local m = Color(math.floor(c.r + (255 - c.r) * t), math.floor(c.g + (255 - c.g) * t), math.floor(c.b + (255 - c.b) * t), c.a)
			if lum(m) >= 0.3 then return m end
		end
	else
		if lum(c) <= 0.18 then return c end
		if grey then return Color(20, 24, 30, c.a) end
		for i = 9, 0, -1 do
			local k = i / 10
			local m = Color(math.floor(c.r * k), math.floor(c.g * k), math.floor(c.b * k), c.a)
			if lum(m) <= 0.18 then return m end
		end
	end
	return c
end

-- Does this panel's skin put its form texts on dark ground? Our skin and dark menu skins ("Dark UI Spawnmenu": light "Dark"
-- labels on dark pages) yes; Garry's Mod's default skin (black "Dark" labels on white tool pages) no.
function AGP.SkinIsDark(panel)
	local sk = IsValid(panel) and panel:GetSkin()
	local c = sk and sk.Colours and sk.Colours.Label and sk.Colours.Label.Dark
	return not c or lum(c) > 0.3
end

local function makeSkin()
	local base = derma.GetNamedSkin("Default")
	if not base then return false end
	local C = AGP.Colors
	local SKIN = table.Copy(base)
	SKIN.PrintName = "Ascension Gates"
	SKIN.Author = "moonrise420"

	SKIN.Colours = table.Copy(base.Colours or {})
	local col = SKIN.Colours
	col.Label = col.Label or {}
	-- AGP 2026-11-08: "Dark" labels light too (list rows, form labels, colour mixer): every ground in our skin is dark
	col.Label.Default, col.Label.Bright, col.Label.Dark, col.Label.Highlight = C.text, Color(255, 255, 255), C.text, C.accent2
	col.Button = col.Button or {}
	col.Button.Normal, col.Button.Hover, col.Button.Down, col.Button.Disabled = C.text, Color(255, 255, 255), Color(255, 255, 255), C.textDim
	col.Tab = col.Tab or {}
	col.Tab.Active = { Normal = C.text, Hover = Color(255, 255, 255), Down = Color(255, 255, 255), Disabled = C.textDim }
	col.Tab.Inactive = { Normal = C.textDim, Hover = C.text, Down = C.text, Disabled = C.textDim }
	-- AGP 2026-11-08: window titles (an unfocused one was 36 % white) and category lists (grey text) light on our boxes
	col.Window = { TitleActive = C.text, TitleInactive = C.textDim }
	local function catLine(alt)
		return { Text = C.text, Text_Hover = Color(255, 255, 255), Text_Selected = Color(255, 255, 255), Text_Disabled = C.textDim,
			Button = alt and Color(255, 255, 255, 6) or Color(0, 0, 0, 0), Button_Hover = C.hover, Button_Selected = C.select, Button_Disabled = Color(0, 0, 0, 0) }
	end
	col.Category = { Header = C.text, Header_Closed = C.text, Line = catLine(false), LineAlt = catLine(true) }
	-- AGP 2026-11-08: text fields: code that asks the skin for their colours gets ours (the default was dark grey text)
	SKIN.colTextEntryText, SKIN.colTextEntryTextHighlight, SKIN.colTextEntryTextCursor, SKIN.colTextEntryTextPlaceholder = C.text, C.select, C.text, C.textDim
	-- property lists (the config editor): dark rows, light text, like the rest of the window
	col.Properties = {
		Line_Selected = C.accent, Line_Hover = C.hover, Title = C.accent2, Border = C.edge,
		Column_Normal = C.panel, Column_Selected = Color(36, 60, 92), Column_Hover = C.button, Column_Disabled = Color(30, 36, 46),
		Label_Normal = C.text, Label_Selected = Color(255, 255, 255), Label_Hover = Color(255, 255, 255), Label_Disabled = C.textDim,
	}

	function SKIN:PaintFrame(p, w, h) draw.RoundedBox(10, 0, 0, w, h, C.bg) end
	function SKIN:PaintPanel(p, w, h)
		if not p.m_bBackground then return end
		draw.RoundedBox(8, 0, 0, w, h, C.panel)
	end
	function SKIN:PaintPropertySheet(p, w, h)
		local tab = p:GetActiveTab()
		local offset = IsValid(tab) and tab:GetTall() - 8 or 20
		draw.RoundedBoxEx(10, 0, 0, w, offset + 10, C.tabbar, true, true, false, false) -- dark bar behind the tabs: no gap shows the world
		draw.RoundedBox(10, 0, offset, w, h - offset, C.bg)
	end
	function SKIN:PaintTab(p, w, h)
		local active = p:IsActive()
		draw.RoundedBoxEx(8, 0, 0, w, active and h - 4 or h - 8, active and C.panel or C.button, true, true, false, false)
		if active then surface.SetDrawColor(C.accent2) surface.DrawRect(6, 0, w - 12, 3) end
	end
	function SKIN:PaintButton(p, w, h)
		if not p.m_bBackground then return end
		local c = C.button
		-- AGP 2026-11-08: pressed / selected / switched on in the deeper blue: white text read 3:1 on the light accent
		if p:GetDisabled() then c = Color(30, 36, 46) elseif p.Depressed or p:IsSelected() or p:GetToggle() then c = C.select elseif p.Hovered then c = C.hover end
		draw.RoundedBox(6, 0, 0, w, h, c)
	end
	function SKIN:PaintCheckBox(p, w, h)
		draw.RoundedBox(4, 0, 0, w, h, C.field)
		surface.SetDrawColor(C.edge)
		surface.DrawOutlinedRect(0, 0, w, h)
		if p:GetChecked() then draw.RoundedBox(3, 3, 3, w - 6, h - 6, p:GetDisabled() and C.textDim or C.accent) end
	end
	function SKIN:PaintTextEntry(p, w, h)
		if p.m_bBackground then
			draw.RoundedBox(4, 0, 0, w, h, p:HasFocus() and Color(16, 24, 36) or C.field)
			surface.SetDrawColor(p:HasFocus() and C.accent or C.edge)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		-- AGP 2026-11-08: a field's own text colour is kept when it reads on our dark field (a dark one is lifted: the colour
		-- mixer's red/green/blue numbers), an empty field shows its hint, multi-line fields keep their lines (the one-line
		-- draw below put a whole config file on one line)
		local txtCol = p:IsEnabled() and AGP.ReadableText(p.m_colText or C.text, true) or C.textDim
		local font = p:GetFont() or "DermaDefault"
		local text = p:GetText() or ""
		if text == "" and not p:HasFocus() then
			local hint = p.GetPlaceholderText and p:GetPlaceholderText()
			if isstring(hint) and hint:Trim() ~= "" then
				if hint:sub(1, 1) == "#" then hint = language.GetPhrase(hint:sub(2)) end
				local multi = p:IsMultiline()
				draw.SimpleText(hint, font, 3, multi and 2 or h / 2, AGP.ReadableText(p.m_colPlaceholder or C.textDim, true), TEXT_ALIGN_LEFT, multi and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
			end
			return
		end
		-- engine text drawing ignored our colour in some fields (old Stargate drop-downs, number boxes): draw it ourselves unless typing
		if p:HasFocus() or p:IsMultiline() then
			p:DrawTextEntryText(txtCol, C.select, C.text)
		else
			draw.SimpleText(text, font, 3, h / 2, txtCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
	function SKIN:PaintComboBox(p, w, h)
		draw.RoundedBox(6, 0, 0, w, h, p.Hovered and C.hover or C.button)
	end
	function SKIN:PaintMenu(p, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
	function SKIN:PaintMenuOption(p, w, h)
		if p.Hovered or p.Highlight then draw.RoundedBox(4, 2, 0, w - 4, h, C.hover) end
	end
	function SKIN:PaintListView(p, w, h) draw.RoundedBox(6, 0, 0, w, h, C.field) end
	-- AGP 2026-11-08: list rows: every column's text reads on our dark rows, not only under the mouse. A colour the code set
	-- itself (the dial menu drew its addresses black for CAP's white list) is lifted to a light one of the same hue; a
	-- selected row is white on the selection blue. Hover and selection are dark enough for light text.
	local WHITE = Color(255, 255, 255)
	local function lineLabelColour(lbl)
		local want = lbl:GetTextColor() or lbl:GetTextStyleColor()
		if not want then return end
		local line = lbl:GetParent()
		local c = (IsValid(line) and line.IsLineSelected and line:IsLineSelected()) and WHITE or AGP.ReadableText(want, true)
		lbl:SetFGColor(c.r, c.g, c.b, c.a)
	end
	function SKIN:PaintListViewLine(p, w, h)
		if p:IsSelected() then draw.RoundedBox(0, 0, 0, w, h, C.select)
		elseif p.Hovered then draw.RoundedBox(0, 0, 0, w, h, C.button)
		elseif p.m_bAlt then draw.RoundedBox(0, 0, 0, w, h, Color(18, 26, 38)) end
		-- each text column once: from then on every colour change of it goes through lineLabelColour
		for _, lbl in pairs(p.Columns or {}) do
			if IsValid(lbl) and not lbl.AGPReadable and lbl.UpdateFGColor and lbl.GetTextStyleColor then
				lbl.AGPReadable = true
				local upd = lbl.UpdateFGColor
				lbl.UpdateFGColor = function(self2) upd(self2) lineLabelColour(self2) end
				lbl:UpdateFGColor()
			end
		end
	end
	function SKIN:PaintCollapsibleCategory(p, w, h) draw.RoundedBox(6, 0, 0, w, 20, C.button) end
	function SKIN:PaintCategoryList(p, w, h) draw.RoundedBox(6, 0, 0, w, h, C.panel) end
	function SKIN:PaintNumSlider(p, w, h)
		surface.SetDrawColor(C.edge)
		surface.DrawRect(8, h / 2 - 1, w - 16, 2)
	end
	function SKIN:PaintSliderKnob(p, w, h) draw.RoundedBox(h / 2, 0, 0, w, h, p.Hovered and C.accent2 or C.accent) end

	derma.DefineSkin("AscensionGates", "Ascension Gates", SKIN)
	return true
end

-- apply to a window (and so to everything inside it)
function AGP.ApplySkin(panel)
	if not IsValid(panel) then return end
	if not derma.GetNamedSkin("AscensionGates") and not makeSkin() then return end
	panel:SetSkin("AscensionGates")
	-- children remember the skin they saw first (text fields look it up while being created): make them look again
	local function reset(p)
		p.m_Skin, p.m_iSkinIndex = nil, nil
		for _, k in ipairs(p:GetChildren()) do reset(k) end
	end
	reset(panel)
	timer.Simple(0, function() if IsValid(panel) then reset(panel) end end)
end

-- the same rounded box style for hand-painted boxes in our windows
function AGP.Box(x, y, w, h)
	local C = AGP.Colors
	draw.RoundedBox(10, x - 2, y - 2, w + 4, h + 4, C.edge)
	draw.RoundedBox(9, x, y, w, h, C.panel)
end

-- clear modern font for the settings windows (Roboto ships with Garry's Mod)
surface.CreateFont("AGPSettings", { font = "Roboto", size = 15, weight = 500 })

-- drop-down fields in the settings pages (tool menu): our own dark field with light text. The tool menu uses the
-- player's skin, and some skins (dark themes) draw a white field with white text - unreadable.
function AGP.StyleCombo(cb)
	if not IsValid(cb) then return end
	local C = AGP.Colors
	if cb.SetTextColor then cb:SetTextColor(C.text) end
	cb.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, (not self:IsEnabled()) and Color(30, 36, 46) or (self.Hovered and C.hover or C.field))
		surface.SetDrawColor(self.Hovered and C.accent or C.edge)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
	local open = cb.OpenMenu
	cb.OpenMenu = function(self, ...)
		open(self, ...)
		if IsValid(self.Menu) then AGP.ApplySkin(self.Menu) end
	end
end

-- No text outside its box, in every language (owner 2026-10-25): after a page is built, every one-line text that is
-- wider than its room wraps onto more lines and its row grows. Slider labels go on their own line above the slider,
-- checkbox and button texts wrap. Runs on all pages of our tool tabs (Stargate, SpaceGrid) and on our windows.
local function textWidth(p, t)
    surface.SetFont(p:GetFont() or "DermaDefault")
    local w, h = surface.GetTextSize(t)
    return w, h
end
local function tooWide(p, room)
    if not (IsValid(p) and p.GetText and p:IsVisible()) then return false end
    local t = p:GetText()
    if not isstring(t) or t == "" then return false end
    local w = textWidth(p, t)
    return w > room
end
local function wrapLabel(lbl, w)
    lbl:SetWrap(true)
    lbl:SetWide(w)
    lbl:SetAutoStretchVertical(true)
    lbl:SizeToContentsY()
end
function AGP.FitTexts(root)
    if not IsValid(root) then return end
    local rootX = root:LocalToScreen(0, 0)
    local rootR = rootX + root:GetWide()
    -- AGP 2026-11-08: is the page dark (our windows, dark menu skins) or bright (Garry's Mod's own white tool pages)? A box
    -- that paints its own ground says so with p.AGPDark = true / false (for everything inside it)
    local function visit(p, onDark)
        if not IsValid(p) or not p:IsVisible() then return end
        if p.AGPDark ~= nil then onDark = p.AGPDark end
        local cls = p.ClassName or ""
        local x = p:LocalToScreen(0, 0)
        if cls == "DNumSlider" and IsValid(p.Label) and p:GetWide() > 80 and tooWide(p.Label, p.Label:GetWide() - 4) and not p.AGPFitted then
            -- the label on its own line(s) above the slider; the height comes from the text (auto-stretch measured a
            -- narrow label once and made the slider row hundreds of pixels tall)
            p.AGPFitted = true
            local lbl = p.Label
            local _, lh = textWidth(lbl, "Ay")
            local lines = math.max(1, math.ceil(textWidth(lbl, lbl:GetText()) / (p:GetWide() - 12)))
            lbl:Dock(TOP)
            lbl:SetWrap(true); lbl:SetAutoStretchVertical(false)
            lbl:SetTall(lines * lh + 4)
            p:SetTall(lbl:GetTall() + 30)
            p:InvalidateLayout(true)
        elseif cls == "DCheckBoxLabel" and IsValid(p.Label) and (x + p.Label.x + textWidth(p.Label, p.Label:GetText()) > rootR - 4) then
            local w = math.max(40, rootR - (x + p.Label.x) - 6)
            wrapLabel(p.Label, w)
            p:SetTall(math.max(p:GetTall(), p.Label:GetTall()))
            p.PerformLayout = function(self2) if IsValid(self2.Button) then self2.Button:SetPos(0, 2) end end
        elseif (cls == "DButton" or cls == "DImageButton") and p.GetText and tooWide(p, p:GetWide() - 8) then
            local _, lh = textWidth(p, "Ay")
            p:SetWrap(true); p:SetContentAlignment(5)
            local lines = math.ceil(textWidth(p, p:GetText()) / math.max(20, p:GetWide() - 12)) + 1
            p:SetTall(math.max(p:GetTall(), lines * lh + 6))
        elseif cls == "DLabel" and not (p:GetParent() and (p:GetParent().ClassName == "DNumSlider" or p:GetParent().ClassName == "DCheckBoxLabel")) then
            local room = math.min(p:GetWide(), rootR - x) - 4
            local _, lh = textWidth(p, "Ay")
            if p:GetTall() < lh * 1.6 and tooWide(p, room) then
                -- a label beside a control (drop-down, text box) wraps in its own column; the row grows
                local par, beside = p:GetParent(), false
                for _, c in ipairs(IsValid(par) and par:GetChildren() or {}) do
                    if c ~= p and (c.AddChoice or c.SetUpdateOnType) then beside = true end
                end
                if beside and not p.AGPFitted then
                    -- the form docks it LEFT beside the field, its height followed the row and wrapped lines were
                    -- cut off: the label goes on its own lines above the field (like the slider labels), full width
                    p.AGPFitted = true
                    p:Dock(TOP)
                    wrapLabel(p, math.max(60, par:GetWide() - 20))
                    for _, c in ipairs(par:GetChildren()) do
                        if c ~= p then c:Dock(TOP); c:DockMargin(0, 3, 0, 0); c:SetTall(math.max(c:GetTall(), 20)) end
                    end
                    par:InvalidateLayout(true)
                else
                    wrapLabel(p, math.max(40, rootR - x - 6))
                end
            end
        end
        -- readable fields everywhere (owner 2026-10-25: white drop-downs with white text on some pages)
        -- by what they can do, not by class name (old Stargate pages use CtrlListBox and other DComboBox copies)
        local isCombo = p.AddChoice and p.ChooseOption and p.OpenMenu
        if isCombo and not p.AGPStyled then p.AGPStyled = true; AGP.StyleCombo(p)
        elseif p.SetUpdateOnType and not isCombo and not p.AGPStyled then
            p.AGPStyled = true
            local C = AGP.Colors
            p.Paint = function(self2, w, h)
                draw.RoundedBox(4, 0, 0, w, h, self2:IsEnabled() and C.field or Color(30, 36, 46))
                surface.SetDrawColor(self2:HasFocus() and C.accent or C.edge); surface.DrawOutlinedRect(0, 0, w, h)
                self2:DrawTextEntryText(self2:IsEnabled() and C.text or C.textDim, C.accent, C.text)
            end
        -- AGP 2026-11-08: slider labels and texts with their own colour follow the page's ground: light on dark pages, dark
        -- on bright ones (the forced light slider label and the orange / green hints were bright on bright there)
        elseif cls == "DNumSlider" and IsValid(p.Label) then p.Label:SetTextColor(onDark and AGP.Colors.text or (AGP.Colors.textOnBright or Color(20, 24, 30)))
        elseif cls == "DLabel" and p.m_colText then p:SetTextColor(AGP.ReadableText(p.m_colText, onDark)) end
        for _, c in ipairs(p:GetChildren()) do visit(c, onDark) end
    end
    visit(root, AGP.SkinIsDark(root))
    root:InvalidateLayout(true)
end

-- every page of our tool tabs gets the fitting pass once it has its size: the build function is wrapped where the page
-- is registered (the menu copies it when it loads, so later is too late)
local function patch()
    if not spawnmenu or spawnmenu.AGPFitPatched then return end
    spawnmenu.AGPFitPatched = true
    local orig = spawnmenu.AddToolMenuOption
    spawnmenu.AddToolMenuOption = function(tab, cat, item, text, cmd, cfg, cpanel, tbl)
        if isfunction(cpanel) and (tab == "Stargate" or tab == "SpaceGrid") then
            local f = cpanel
            cpanel = function(cp, ...)
                f(cp, ...)
                timer.Simple(0.05, function() AGP.FitTexts(cp) end)
                timer.Simple(0.5, function() AGP.FitTexts(cp) end)
            end
        end
        local r = orig(tab, cat, item, text, cmd, cfg, cpanel, tbl)
        if tab == "Stargate" or tab == "SpaceGrid" then AGP.SortToolCategory(tab, cat) end
        return r
    end
end

-- our pages in a fixed order (GMod sorts them by text: "Über" came last in German); the rest by name after them
local FIRST = { Credits = 1, ["Settings/Language"] = 2, agp_wiki = 3, agp_ship_settings = 4 }
function AGP.SortToolCategory(tab, cat)
    for _, c in ipairs(spawnmenu.GetToolMenu(tab) or {}) do
        if c.ItemName == cat then
            table.sort(c, function(a, b)
                local fa, fb = FIRST[a.ItemName] or 99, FIRST[b.ItemName] or 99
                if fa ~= fb then return fa < fb end
                return utf8.force(string.Trim(a.Text or "")):lower() < utf8.force(string.Trim(b.Text or "")):lower()
            end)
        end
    end
end
patch()
hook.Add("OnGamemodeLoaded", "AGP.FitTexts", patch)
