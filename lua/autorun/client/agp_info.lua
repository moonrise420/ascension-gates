-- Ascension Gates: welcome / info screen. Opens once per pack version on the first spawn, later from the spawn menu
-- (Ascension Gates > Config > About Ascension Gates) or the console command agp_info. Includes the credits the
-- licences of CAP and CAP Enhanced ask for.
local INFO_VERSION = "1"
local cvSeen = CreateClientConVar("agp_info_seen", "", true, false, "Ascension Gates info screen version already shown")

local function L(key, fallback)
	if SGLanguage and SGLanguage.ValidMessage and SGLanguage.ValidMessage(key) then return SGLanguage.GetMessage(key) end
	return fallback or key
end

surface.CreateFont("AGPInfoTitle", { font = "Roboto", size = 30, weight = 700 })
surface.CreateFont("AGPInfoHead", { font = "Roboto", size = 20, weight = 700 })
surface.CreateFont("AGPInfoText", { font = "Roboto", size = 16, weight = 400 })

local frame
local function open()
	if IsValid(frame) then frame:Remove() end
	frame = vgui.Create("DFrame")
	if (AGP and AGP.ApplySkin) then AGP.ApplySkin(frame) end -- AGP: our look
	frame:SetSize(math.min(640, ScrW() - 40), math.min(600, ScrH() - 40))
	frame:Center()
	frame:SetTitle("")
	frame:MakePopup()
	frame.Paint = function(self, w, h)
		draw.RoundedBox(10, 0, 0, w, h, Color(14, 20, 30, 245))
		draw.RoundedBoxEx(10, 0, 0, w, 96, Color(30, 60, 100, 255), true, true, false, false)
	end

	local head = vgui.Create("DPanel", frame)
	head:Dock(TOP)
	head:SetTall(70)
	head.Paint = function(self, w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(Material("gui/agp_logo_128.png", "smooth"))
		surface.DrawTexturedRect(6, 2, 64, 64)
		draw.SimpleText(L("agp_info_title", "Welcome to Ascension Gates"), "AGPInfoTitle", 82, 6, color_white)
		draw.SimpleText(L("agp_info_intro", ""), "AGPInfoText", 84, 42, Color(190, 220, 255))
	end

	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:Dock(FILL)
	scroll:DockMargin(10, 14, 10, 4)
	local function text(t, font, col, top)
		local l = vgui.Create("DLabel", scroll)
		l:Dock(TOP)
		l:DockMargin(4, top or 2, 4, 0)
		l:SetFont(font or "AGPInfoText")
		l:SetTextColor(col or Color(220, 230, 240))
		l:SetWrap(true)
		l:SetAutoStretchVertical(true)
		l:SetText(t)
	end
	text(L("agp_info_steps", "First steps"), "AGPInfoHead", Color(255, 190, 80), 0)
	for i = 1, 4 do text("•  " .. L("agp_info_step" .. i, "")) end
	if StarCore then
		text(L("agp_info_starcore_head", "StarCore"), "AGPInfoHead", Color(120, 220, 255), 12)
		text("•  " .. L("agp_info_starcore", ""))
	end
	text(L("agp_info_credits", "Credits"), "AGPInfoHead", Color(255, 190, 80), 12)
	text("•  " .. L("agp_info_credit_cape", "CAP Enhanced: Soren MC"))
	text("•  " .. L("agp_info_credit_cap", "Carter's Addon Pack team"))
	text("•  " .. L("agp_info_credit_weapons", "SGC weapon models: Rotuma, romunql (CC BY 4.0)"))
	text("•  " .. L("agp_info_credit_reactor", "Reactor Core model: Daniel Aucar Felipe (CC BY 4.0)"))
	text(L("agp_info_licence", ""), nil, Color(170, 180, 190), 8)
	text(L("agp_info_mgm", ""), nil, Color(170, 180, 190), 2)

	local bottom = vgui.Create("DPanel", frame)
	bottom:Dock(BOTTOM)
	bottom:SetTall(34)
	bottom:DockMargin(10, 4, 10, 6)
	bottom.Paint = nil
	local dont = vgui.Create("DCheckBoxLabel", bottom)
	dont:Dock(LEFT)
	dont:SetWide(300)
	dont:SetText(L("agp_info_dontshow", "Do not show this at start again"))
	dont:SetValue(cvSeen:GetString() == INFO_VERSION and 1 or 0)
	dont.OnChange = function(_, v) RunConsoleCommand("agp_info_seen", v and INFO_VERSION or "") end
	local go = vgui.Create("DButton", bottom)
	go:Dock(RIGHT)
	go:SetWide(130)
	go:SetText(L("agp_info_btn_close", "Let's go!"))
	go.DoClick = function() frame:Close() end
	for _, l in ipairs(AGP and AGP.LinkList and AGP.LinkList() or {}) do
		local b = vgui.Create("DButton", bottom)
		b:Dock(RIGHT)
		b:DockMargin(0, 0, 8, 0)
		b:SetWide(150)
		b:SetText(l[1]:gsub("^Ascension Gates %(", ""):gsub("%)$", ""))
		b.DoClick = function() gui.OpenURL(l[2]) end
	end
	if AGP.UpdateCheckWanted and AGP.UpdateCheckWanted() then   -- manual (GitHub) installs; the Workshop updates by itself
		local upd = vgui.Create("DButton", bottom)
		upd:Dock(RIGHT)
		upd:DockMargin(0, 0, 8, 0)
		upd:SetWide(150)
		upd:SetText(L("agp_upd_button", "Check for updates"))
		upd.DoClick = function() AGP.CheckForUpdate() end
	end
	local set = vgui.Create("DButton", bottom)
	set:Dock(RIGHT)
	set:DockMargin(0, 0, 8, 0)
	set:SetWide(130)
	set:SetText(L("agp_info_btn_settings", "Settings"))
	set.DoClick = function() frame:Close(); RunConsoleCommand("stargate_settings") end
	local help = vgui.Create("DButton", bottom)   -- the in-game help (agp_wiki.lua)
	help:Dock(RIGHT)
	help:DockMargin(0, 0, 8, 0)
	help:SetWide(130)
	help:SetText(L("agp_wiki_menu", "Help (Wiki)"))
	help.DoClick = function() frame:Close(); RunConsoleCommand("agp_wiki") end
end

concommand.Add("agp_info", open)

-- first start of this pack version: show it once (then the box "do not show again" is ticked for them)
hook.Add("InitPostEntity", "AGP.Info", function()
	timer.Simple(6, function()
		if cvSeen:GetString() ~= INFO_VERSION then
			open()
			RunConsoleCommand("agp_info_seen", INFO_VERSION)
		end
	end)
end)

-- spawn menu: Ascension Gates > Config > About Ascension Gates
local function buildAbout(panel)
	panel:ClearControls()
	local logo = vgui.Create("DImage", panel)
	logo:SetImage("gui/agp_logo_256.png")
	logo:SetSize(128, 128)
	panel:AddItem(logo)
	panel:Help("Ascension Gates " .. ((AGP and AGP.Version) or ""))
	panel:Help(L("agp_info_intro", ""))
	panel:Button(L("agp_about", "About Ascension Gates"), "agp_info")
	panel:Button(L("agp_wiki_menu", "Help (Wiki)"), "agp_wiki")
	panel:Button(L("agp_info_btn_settings", "Settings"), "stargate_settings")
	if AGP.UpdateCheckWanted and AGP.UpdateCheckWanted() then
		panel:Button(L("agp_upd_button", "Check for updates")).DoClick = function() AGP.CheckForUpdate() end
	end
end


-- our tool tab never opens empty: show the Credits page until a tool is picked
local function aboutDefault()
	local tm = IsValid(g_SpawnMenu) and g_SpawnMenu.ToolMenu
	if not IsValid(tm) or not tm.GetToolPanel then return end
	local tp -- the tool tabs are stored by their number, not by name
	for k, tab in pairs(spawnmenu.GetTools()) do
		if tab.Name == "Stargate" then tp = tm:GetToolPanel(k) end
	end
	if not IsValid(tp) or tp.ActiveCPName then return end
	local cp = controlpanel.Get("Credits")
	cp:ClearControls()
	if cp.SetLabel then cp:SetLabel(L("agp_menu_about_credits", "About & Credits")) end
	if StarGate and StarGate.Update_Check then StarGate.Update_Check(cp) else buildAbout(cp) end
	tp:SetActive(cp)
	if tp.SetActiveToolText then tp:SetActiveToolText(L("agp_menu_about_credits", "About & Credits")) end
end
hook.Add("PostReloadToolsMenu", "AGP.AboutDefault", function() timer.Simple(0, aboutDefault) end)
hook.Add("OnSpawnMenuOpen", "AGP.AboutDefault", function() timer.Simple(0, aboutDefault) end)
