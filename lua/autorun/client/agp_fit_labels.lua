--[[
	Ascension Gates: every text on our pages readable in every language (2026-11-10 full check). GMod's tool and settings
	pages give a choice box, a text field or a slider a label column of a fixed width (100 - 125 px): a longer label
	("Weapons fire at owner and friends", "Código de cancelación:") was cut off. After one of our pages is built, a label
	that does not fit moves onto its own line(s) above its control, at the full width; the control keeps its height.
	Only our own pages (tools and settings of Ascension Gates, PowerGrid, StarCore, Black Hole Cache), not other addons'.
]]
AGP = AGP or {}

local function ours(fn)
	local src = string.lower((debug.getinfo(fn, "S") or {}).short_src or "")
	return src:find("ascension_gates", 1, true) or src:find("powergrid", 1, true) or src:find("starcore", 1, true)
		or src:find("blackhole", 1, true) or src:find("/stargate/", 1, true) or src:find("/agp", 1, true) or false
end

local function lines(lbl, width)
	local text = language.GetPhrase(lbl:GetText())
	surface.SetFont(lbl:GetFont() or "DermaDefault")
	local tw, lh = surface.GetTextSize(text)
	return tw, lh, math.max(1, math.ceil(tw / math.max(width - 6, 1)))
end

-- one label that does not fit: on its own line(s) above its control
local function fit(lbl)
	local row = lbl:GetParent()
	if not IsValid(row) then return end
	local W = row:GetWide()
	if W < 40 then return end
	-- (the height is measured again at every layout: the row may not have its full width yet, and a label measured
	-- too narrow left an empty gap under it)
	local function need(w)
		local _, lh, n = lines(lbl, w)
		return n * (lh + 1) + 4
	end
	lbl.AGPFitted = true
	lbl:SetWrap(true)
	lbl:SetContentAlignment(7)
	lbl:Dock(TOP)
	lbl:SetTall(need(W))
	local cls = row.ClassName or row:GetClassName()
	if cls == "DNumSlider" then
		-- the slider and its number field below the label (GMod's layout would give the label 1/2.4 of the width again)
		row.PerformLayout = function(self, w)
			-- (the number field is docked first, to the right, so the label has the width beside it)
			local h = need(w - (IsValid(self.TextArea) and self.TextArea:GetWide() or 0))
			self.Label:SetTall(h)
			if IsValid(self.TextArea) then self.TextArea:DockMargin(0, h, 0, 0) end
			if self:GetTall() ~= h + 24 then self:SetTall(h + 24) end
		end
		row:SetTall(need(W) + 24)
	else
		-- a choice box / text field row: the control under the label, at its own height
		for _, c in ipairs(row:GetChildren()) do
			if c ~= lbl and IsValid(c) then
				local h = c:GetTall()
				c:Dock(TOP)
				c:DockMargin(0, 1, 0, 2)
				c:SetTall(math.Clamp(h, 18, 26))
			end
		end
		row.PerformLayout = function(self, w)
			local h = need(w)
			if lbl:GetTall() ~= h then lbl:SetTall(h) end
			self:SizeToChildren(false, true)
		end
	end
	row:InvalidateLayout(true)
	local up = row:GetParent()
	if IsValid(up) then up:InvalidateLayout(true) end
end

function AGP.FitLabels(panel)
	if not IsValid(panel) then return end
	local todo = {}
	local function walk(p, depth)
		if depth > 25 or not IsValid(p) then return end
		for _, c in ipairs(p:GetChildren()) do
			if IsValid(c) and c:IsVisible() then
				local cls = c.ClassName or c:GetClassName()
				if cls == "DLabel" and not c.AGPFitted and c:GetText() ~= "" and c:GetParent() ~= panel
					and not (c.GetAutoStretchVertical and c:GetAutoStretchVertical()) then
					local tw = lines(c, c:GetWide())
					if c:GetWide() > 20 and tw > c:GetWide() + 2 then todo[#todo + 1] = c end
				end
				walk(c, depth + 1)
			end
		end
	end
	walk(panel, 0)
	for _, lbl in ipairs(todo) do fit(lbl) end
	-- a label that sizes itself to its text (a checkbox's) and so runs past the page's right edge: wrapped at the edge
	local left = panel:LocalToScreen(0, 0)
	local W = panel:GetWide()
	local over = 0
	local function edge(p, depth)
		if depth > 25 or not IsValid(p) then return end
		for _, c in ipairs(p:GetChildren()) do
			if IsValid(c) and c:IsVisible() then
				local cls = c.ClassName or c:GetClassName()
				if cls == "DLabel" and not c.AGPFitted and c:GetText() ~= "" then
					local x = c:LocalToScreen(0, 0) - left
					if x + c:GetWide() > W + 2 and W - x > 40 then
						local room = W - x - 4
						local _, lh, n = lines(c, room)
						c.AGPFitted = true
						c:SetWrap(true)
						c:SetContentAlignment(7)
						c:SetWide(room)
						c:SetTall(n * (lh + 1) + 2)
						local par = c:GetParent()
						if IsValid(par) and par ~= panel then
							local h = c:GetTall() + 2
							local keepW = room
							par.PerformLayout = function(self) if IsValid(c) then c:SetWide(keepW) end if self:GetTall() < h then self:SetTall(h) end end
							par:SetTall(math.max(par:GetTall(), h))
						end
						over = over + 1
					end
				end
				edge(c, depth + 1)
			end
		end
	end
	edge(panel, 0)
	if #todo > 0 or over > 0 then panel:InvalidateLayout(true) end
end

-- each of our pages: fit its labels once it has its width (and again a moment later, after the menu's own layout)
local function wrap(item)
	if item.AGPFitWrapped or not isfunction(item.CPanelFunction) or not ours(item.CPanelFunction) then return end
	local build = item.CPanelFunction
	item.AGPFitWrapped = true
	item.CPanelFunction = function(panel, ...)
		local r = build(panel, ...)
		timer.Simple(0, function() AGP.FitLabels(panel) end)
		timer.Simple(0.3, function() AGP.FitLabels(panel) end)
		return r
	end
end
local function wrapAll()
	for _, tab in pairs(spawnmenu.GetTools() or {}) do
		for _, cat in pairs(tab.Items or {}) do
			for _, item in pairs(cat) do if istable(item) then wrap(item) end end
		end
	end
end
hook.Add("PostReloadToolsMenu", "AGP.FitLabels", wrapAll)
hook.Add("OnSpawnMenuOpen", "AGP.FitLabels", wrapAll)
