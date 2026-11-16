--[[
	Ascension Gates: the tool tabs of the spawn menu (2026-11-13).
	1. The tool list (left column, 130 px wide) cut long names with "..." ("Goa'uld Power Hub + ...", "Schwerkraftsteue...").
	   An entry that does not fit now wraps onto a second / third line (the entry gets taller); a single word that is wider
	   than the column is drawn in a smaller font. A category heading that does not fit is drawn in a smaller font.
	   The text is never changed. It is done again when the column's width changes (the divider can be dragged).
	2. The small box beside the "hide disabled tools" checkbox at the top of every tool tab is GMod's quick-filter field.
	   Its hint text ("Quick Filter...", in the game's language) was drawn dark on dark and so the box looked empty:
	   the hint colour is now light.
]]
AGP = AGP or {}

local FONT_SIZES = { 13, 12, 11, 10, 9 }
for _, s in ipairs(FONT_SIZES) do
	surface.CreateFont("AGPToolItem" .. s, { font = "Tahoma", size = s, weight = 500, antialias = true })
	surface.CreateFont("AGPToolHead" .. s, { font = "Tahoma", size = s, weight = 800, antialias = true })
end

local function textOf(p)
	return language.GetPhrase(p:GetText() or "")
end

local function measure(font, text)
	surface.SetFont(font)
	return surface.GetTextSize(text)
end

-- the widest single word
local function widestWord(font, text)
	local m = 0
	for word in string.gmatch(text, "%S+") do
		local w = measure(font, word)
		if w > m then m = w end
	end
	return m
end

local function restore(item)
	if item.AGPFitted then
		item:SetAutoStretchVertical(false)
		item:SetWrap(false)
		if item.AGPFont0 then item:SetFont(item.AGPFont0) end
		if item.AGPTall0 then item:SetTall(item.AGPTall0) end
		item.AGPFitted = nil
	end
end

local function relayout(item)
	local cat = item:GetParent()
	if IsValid(cat) then
		cat:InvalidateLayout()
		local c = cat:GetParent()
		if IsValid(c) then c:InvalidateLayout() end
		local l = IsValid(c) and c:GetParent()
		if IsValid(l) then l:InvalidateLayout() end
	end
end

-- one entry of the tool list. The height is never estimated: the label itself is asked how tall its wrapped text is
-- (auto-stretch, at the real width, in the font it really draws), then every entry gets that height plus the same
-- padding the one-line entries have (standard height minus the text height).
local function fitItem(item)
	local W = item:GetWide()
	if W < 40 then return end
	local text = string.Trim(textOf(item))
	if text == "" then return end
	if item.AGPFitW == W and item.AGPFitText == text then return end
	item.AGPFitW, item.AGPFitText = W, text
	item.AGPFont0 = item.AGPFont0 or item:GetFont() or "DermaDefault"
	item.AGPTall0 = item.AGPTall0 or item:GetTall()
	restore(item)
	local avail = W - 8   -- (the label's own inset 4 + 4)
	if measure(item.AGPFont0, text) <= avail - 2 then return end
	-- possibly too wide: a smaller font only when one word alone does not fit, else wrap
	local font = item.AGPFont0
	if widestWord(font, text) > avail then
		for _, s in ipairs(FONT_SIZES) do
			font = "AGPToolItem" .. s
			if widestWord(font, text) <= avail then break end
		end
	end
	local _, lh0 = measure(item.AGPFont0, "Ag")
	local pad = math.max(0, item.AGPTall0 - lh0)
	item:SetFont(font)
	item:SetWrap(true)
	item:SetAutoStretchVertical(true)
	item.AGPFitted = true
	item:InvalidateLayout(true)
	timer.Simple(0.05, function()
		if not IsValid(item) or not item.AGPFitted then return end
		local th = item:GetTall()   -- the height of the text as the label lays it out
		item:SetAutoStretchVertical(false)
		local _, lh = measure(font, "Ag")
		if th <= lh * 1.5 then
			-- it fits on one line after all: the standard entry (smaller font kept when one was chosen)
			item:SetWrap(false)
			item:SetTall(item.AGPTall0)
			if font == item.AGPFont0 then item.AGPFitted = nil end
		else
			item:SetTall(th + pad)
		end
		relayout(item)
	end)
end

-- a category heading: one line, smaller font when needed
local function fitHeader(cat)
	local h = cat.Header
	if not IsValid(h) then return end
	local W = h:GetWide()
	if W < 40 then return end
	local text = string.Trim(textOf(h))
	if text == "" then return end
	h.AGPFont0 = h.AGPFont0 or h:GetFont() or "DermaDefaultBold"
	local avail = W - 16
	if measure(h.AGPFont0, text) <= avail then
		if h.AGPFitted then h:SetFont(h.AGPFont0); h.AGPFitted = nil end
		return
	end
	local use
	for _, s in ipairs(FONT_SIZES) do
		use = "AGPToolHead" .. s
		if measure(use, text) <= avail then break end
	end
	h:SetFont(use)
	h.AGPFitted = true
end

local function fitPanel(tp)
	if not IsValid(tp) or not IsValid(tp.List) or not IsValid(tp.List.pnlCanvas) then return end
	local changed = false
	for _, cat in ipairs(tp.List.pnlCanvas:GetChildren()) do
		if IsValid(cat) then
			fitHeader(cat)
			for _, item in ipairs(cat:GetChildren()) do
				if IsValid(item) and item ~= cat.Header and item.GetText and item.DoClick then
					fitItem(item)
				end
			end
			if changed then cat:InvalidateLayout() end
		end
	end
	if changed then tp.List.pnlCanvas:InvalidateLayout(); tp.List:InvalidateLayout() end
end
AGP.FitToolList = fitPanel

local function setup(tp)
	if not IsValid(tp) or tp.AGPFitSetup or not IsValid(tp.List) then return end
	tp.AGPFitSetup = true
	-- 2. the quick-filter hint, readable
	local se = tp.SearchBar
	if IsValid(se) then
		local PH = Color(190, 195, 205)
		if se.SetPlaceholderColor then
			-- (the entry sets its hint colour from the skin whenever it is laid out: keep ours after that)
			local uc = se.UpdateColours
			se.UpdateColours = function(s, skin, ...)
				if uc then uc(s, skin, ...) end
				s:SetPlaceholderColor(PH)
			end
			se:SetPlaceholderColor(PH)
		end
		-- and the hint itself on top, in case the skin's own drawing leaves it out
		se.PaintOver = function(s, w, h)
			if s:GetText() ~= "" or s:HasFocus() then return end
			local hint = language.GetPhrase("#spawnmenu.quick_filter")
			draw.SimpleText(hint, s:GetFont() or "DermaDefault", 4, h / 2, PH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
	-- 1. fit again whenever the column's width changes
	local think = tp.Think
	tp.Think = function(self, ...)
		if think then think(self, ...) end
		local w = IsValid(self.List) and self.List:GetWide() or 0
		if w ~= self.AGPFitW then
			self.AGPFitW = w
			timer.Simple(0.05, function() fitPanel(self) end)
		end
	end
end

local function all()
	local tm = IsValid(g_SpawnMenu) and g_SpawnMenu.ToolMenu
	if not IsValid(tm) or not tm.ToolPanels then return end
	for _, tp in pairs(tm.ToolPanels) do
		setup(tp)
		fitPanel(tp)
	end
end

local function later()
	timer.Simple(0.1, all)
	timer.Simple(0.6, all)
end
hook.Add("PostReloadToolsMenu", "AGP.ToolMenuFit", later)
hook.Add("OnSpawnMenuOpen", "AGP.ToolMenuFit", later)
hook.Add("InitPostEntity", "AGP.ToolMenuFit", function() timer.Simple(2, all) end)

-- 4. A language switch (the language page's button: SGLanguage.SetClientLanguage -> sg_language_reload) updates the texts
-- of the OPEN tool lists in place. Nothing is rebuilt, no hook is run and no panel of another addon is called (Wiremod
-- replaces the list with its own tree): only the label text of entries and headings that are OURS is set, and only
-- when they exist. Ours = our tool modes (list "CAP.Tool", PowerGrid's two tools) and our page / category keys below.
-- Pages that were opened before the switch keep their old-language content until the spawn menu is rebuilt.
local PAGE_KEYS = {   -- list entry name -> { text source, key, fallback }
	Credits = { "sg", "agp_menu_about_credits", "About & Credits" },
	["Settings/Language"] = { "sg", "agp_menu_settings", "Language" },
	["Weapons Visuals"] = { "sg", "agp_menu_vis_weapons", "Weapons Visuals" },
	["Misc Visuals"] = { "sg", "agp_menu_vis_misc", "Misc Visuals" },
	["Ship Visuals"] = { "sg", "agp_menu_vis_ships", "Ship Visuals" },
	agp_wiki = { "agp", "agp_wiki_menu", "Help (Wiki)" },
	agp_wiki_sg = { "agp", "agp_wiki_menu", "Help (Wiki)" },
	agp_ship_settings = { "agp", "agp_ship_title", "AGP Ships" },
	agp_rep_settings = { "agp", "agp_rep_title", "Replicators" },
	agp_gatespawner = { "agp", "agp_gs_title", "Gate Spawner" },
	powergrid_about = { "pg", "agp_pg_about_title", "About PowerGrid" },
}
local HEAD_KEYS = {   -- category headings that come from our keys
	{ "sg", "stool_cat_energy", "Energy" }, { "sg", "agp_cat_settings", "Settings" },
	{ "sg", "agp_cat_connector", "Connect Power" }, { "sg", "agp_cat_power", "PowerGrid" },
}
local lastHead = {}   -- key -> the text it had at the last pass (to find the headings that carry it)

local function text(k)
	if k[1] == "pg" then return PowerGrid and PowerGrid.L and PowerGrid.L(k[2], k[3]) or k[3] end
	if k[1] == "agp" then return AGP.L(k[2], k[3]) end
	return (SGLanguage.ValidMessage(k[2]) and SGLanguage.GetMessage(k[2])) or k[3]
end

local function remember()
	for _, k in ipairs(HEAD_KEYS) do lastHead[k[2]] = text(k) end
end

local function setText(p, new)
	local old = p:GetText() or ""
	local lead = string.match(old, "^%s*") or ""
	local want = lead .. new
	if old ~= want then p:SetText(want) end
	p.AGPFitW = nil
end

local function refreshTexts()
	local tm = IsValid(g_SpawnMenu) and g_SpawnMenu.ToolMenu
	if not IsValid(tm) or not istable(tm.ToolPanels) then return end
	local tools = list.Get("CAP.Tool") or {}
	local function newName(name)
		if PAGE_KEYS[name] then return text(PAGE_KEYS[name]) end
		local mode = string.match(name, "^(.+)_spacegrid$") or name
		local t = tools[mode]
		if t and isstring(t.Name) then return language.GetPhrase(string.gsub(t.Name, "^#", "")) end
		if mode == "agp_power_link" or mode == "agp_power_parts" then return language.GetPhrase("tool." .. mode .. ".name") end
	end
	for _, tp in pairs(tm.ToolPanels) do
		if IsValid(tp) and IsValid(tp.List) and IsValid(tp.List.pnlCanvas) then
			for _, cat in ipairs(tp.List.pnlCanvas:GetChildren()) do
				if IsValid(cat) and IsValid(cat.Header) and cat.Header.GetText then
					local ht = string.Trim(language.GetPhrase(cat.Header:GetText()))
					for _, k in ipairs(HEAD_KEYS) do
						if lastHead[k[2]] == ht then setText(cat.Header, text(k)) break end
					end
					for _, it in ipairs(cat:GetChildren()) do
						if IsValid(it) and it ~= cat.Header and isstring(it.Name) and it.SetText and it.DoClick then
							local n = newName(it.Name)
							if n and n ~= "" then setText(it, n); it.Text = n end
						end
					end
				end
			end
		end
	end
	-- the menu's own data, so a page opened later gets the new text as its heading
	for _, tab in pairs(spawnmenu.GetTools() or {}) do
		for _, cat in pairs(tab.Items or {}) do
			for _, item in pairs(cat) do
				if istable(item) and isstring(item.ItemName) then
					local n = newName(item.ItemName)
					if n and n ~= "" then item.Text = string.match(item.Text or "", "^%s*") .. n end
				end
			end
		end
	end
	remember()
	timer.Simple(0.1, all)
	timer.Simple(0.5, all)
end

local inplace = CreateClientConVar("agp_toolmenu_inplace", "1", false, false)   -- 0 = do not update the open lists (tests)

function AGP.RefreshToolMenu()
	if not inplace:GetBool() then return false end
	local ok, err = pcall(refreshTexts)
	if not ok then print("[AGP] tool list texts: " .. tostring(err)) end
	return ok
end

hook.Add("InitPostEntity", "AGP.ToolMenuRemember", function() timer.Simple(3, remember) end)
hook.Add("PostReloadToolsMenu", "AGP.ToolMenuRemember", function() timer.Simple(0.2, remember) end)
hook.Add("AGP.ToolTextsRefreshed", "AGP.ToolMenuInPlace", function()
	timer.Simple(0.2, AGP.RefreshToolMenu)
end)
