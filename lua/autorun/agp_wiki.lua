-- Ascension Gates: the offline wiki (help) - opens in the game: console "agp_wiki [page]", the Ascension Gates spawn tab
-- (Help), the tool tabs (Ascension Gates > Config > Help: all pages, SpaceGrid > Settings > Help: SpaceGrid pages).
-- Pages: lua/agp_wiki/<language>.lua (en is complete, other languages fall back to it page by page). Simple markup,
-- easy to translate:
--   = text          "In short" box at the top of a page
--   # / ## text     headings
--   - text          bullet;  1. text  numbered step
--   > text          tip box;  ! text  warning box
--   [E] [Shift]     keys;  **bold**;  {page:id|text} link to another page
-- Built to be easy to read: short lines, one thing per line, big text (A+ / A-), the same layout on every page.
AGP = AGP or {}
AGP.WikiLanguages = { "en", "de", "cs", "es-es", "et", "fr", "hr", "hu", "nl", "ru", "sv-se", "tr" }

if SERVER then
    AddCSLuaFile()
    for _, l in ipairs(AGP.WikiLanguages) do
        if file.Exists("agp_wiki/" .. l .. ".lua", "LUA") then AddCSLuaFile("agp_wiki/" .. l .. ".lua") end
    end
    return
end

local cvSize = CreateClientConVar("agp_wiki_size", "17", true, false, "Ascension Gates wiki: text size", 12, 30)
local cache = {}
local function load(lang)
    if cache[lang] ~= nil then return cache[lang] end
    local ok, t = false, nil
    if file.Exists("agp_wiki/" .. lang .. ".lua", "LUA") then ok, t = pcall(include, "agp_wiki/" .. lang .. ".lua") end
    cache[lang] = (ok and istable(t)) and t or false
    return cache[lang]
end

local function lang()
    local l = SGLanguage and SGLanguage.GetClientLanguage and SGLanguage.GetClientLanguage() or GetConVarString("gmod_language")
    return load(l) and l or "en"
end

-- the pages in the player's language; a page missing there comes from English
function AGP.WikiPages()
    local en, own = load("en") or { pages = {} }, load(lang()) or { pages = {} }
    local byId = {}
    for _, p in ipairs(own.pages or {}) do byId[p.id] = p end
    local out = {}
    for _, p in ipairs(en.pages or {}) do out[#out + 1] = byId[p.id] or p end
    return out, own.ui or en.ui or {}
end

local function esc(s) return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function inline(s)
    s = esc(s)
    s = s:gsub("%*%*(.-)%*%*", "<b>%1</b>")
    s = s:gsub("%[([^%]]+)%]", "<kbd>%1</kbd>")
    s = s:gsub("{page:([%w_]+)|([^}]+)}", "<a href=\"#\" onclick=\"agp.open('%1');return false;\">%2</a>")
    return s
end

local CSS = [[
:root { --gold:#e8bd5a; --gold2:#a87d32; --text:#f2e9d8; --bg:#15110b; --box:#231b10; }
body { background:var(--bg); color:var(--text); font-family:"Segoe UI",Verdana,sans-serif; font-size:SIZEpx; line-height:1.55;
  margin:0; padding:18px 26px 40px 26px; }
h1 { color:var(--gold); font-size:1.7em; margin:0 0 10px 0; border-bottom:2px solid var(--gold2); padding-bottom:6px; }
h2 { color:var(--gold); font-size:1.25em; margin:22px 0 6px 0; }
h3 { color:#d9b46a; font-size:1.05em; margin:16px 0 4px 0; }
p { margin:6px 0; max-width:60em; }
ul, ol { margin:4px 0 8px 0; padding-left:1.6em; max-width:60em; }
li { margin:3px 0; }
kbd { display:inline-block; min-width:1.2em; text-align:center; background:#3a2c14; color:#ffe2a0; border:1px solid var(--gold2);
  border-bottom-width:3px; border-radius:5px; padding:0 6px; font-family:Consolas,monospace; font-size:0.92em; }
.short { background:#2a2110; border-left:6px solid var(--gold); padding:10px 14px; margin:4px 0 14px 0; border-radius:4px; font-size:1.05em; }
.short b.lbl { color:var(--gold); display:block; font-size:0.85em; letter-spacing:1px; }
.tip { background:#132a1c; border-left:6px solid #5fc27e; padding:8px 12px; margin:8px 0; border-radius:4px; }
.warn { background:#2e1512; border-left:6px solid #e0644e; padding:8px 12px; margin:8px 0; border-radius:4px; }
a { color:#8fc8ff; }
]]

local function render(page, ui)
    local h = { "<html><head><meta charset='utf-8'><style>", CSS:gsub("SIZE", tostring(cvSize:GetInt())), "</style></head><body>" }
    h[#h + 1] = "<h1>" .. esc(page.title) .. "</h1>"
    local list
    local function close() if list then h[#h + 1] = "</" .. list .. ">"; list = nil end end
    for line in ((page.body or "") .. "\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        local t
        if line == "" then close()
        elseif line:sub(1, 2) == "= " then close(); h[#h + 1] = "<div class='short'><b class='lbl'>" .. esc(ui.short or "IN SHORT") .. "</b>" .. inline(line:sub(3)) .. "</div>"
        elseif line:sub(1, 3) == "## " then close(); h[#h + 1] = "<h3>" .. inline(line:sub(4)) .. "</h3>"
        elseif line:sub(1, 2) == "# " then close(); h[#h + 1] = "<h2>" .. inline(line:sub(3)) .. "</h2>"
        elseif line:sub(1, 2) == "- " then
            if list ~= "ul" then close(); list = "ul"; h[#h + 1] = "<ul>" end
            h[#h + 1] = "<li>" .. inline(line:sub(3)) .. "</li>"
        elseif line:match("^%d+%. ") then
            if list ~= "ol" then close(); list = "ol"; h[#h + 1] = "<ol>" end
            h[#h + 1] = "<li>" .. inline(line:gsub("^%d+%. ", "")) .. "</li>"
        elseif line:sub(1, 2) == "> " then close(); h[#h + 1] = "<div class='tip'>" .. inline(line:sub(3)) .. "</div>"
        elseif line:sub(1, 2) == "! " then close(); h[#h + 1] = "<div class='warn'>" .. inline(line:sub(3)) .. "</div>"
        else close(); h[#h + 1] = "<p>" .. inline(line) .. "</p>" end
    end
    close()
    h[#h + 1] = "</body></html>"
    return table.concat(h)
end

local GOLD, GOLD2, DARK = Color(232, 189, 90), Color(168, 125, 50), Color(21, 17, 11)
local frame
function AGP.OpenWiki(id)
    if IsValid(frame) then frame:Remove() end
    local pages, ui = AGP.WikiPages()
    if #pages == 0 then chat.AddText(GOLD, "[Ascension Gates] ", color_white, AGP.L("agp_wiki_missing", "The help pages are missing.")) return end
    frame = vgui.Create("DFrame")
    if (AGP and AGP.ApplySkin) then AGP.ApplySkin(frame) end -- AGP: our look
    local w, h = math.min(ScrW() - 40, 1180), math.min(ScrH() - 40, 820)
    frame:SetSize(w, h); frame:Center(); frame:MakePopup()
    frame:SetTitle(""); frame:SetSizable(true); frame:SetMinWidth(640); frame:SetMinHeight(420)
    frame.Paint = function(_, pw, ph)
        draw.RoundedBox(8, 0, 0, pw, ph, DARK)
        surface.SetDrawColor(GOLD2); surface.DrawOutlinedRect(0, 0, pw, ph, 2)
        draw.SimpleText(ui.title or AGP.L("agp_ui_ascension_gates_help", "Ascension Gates - Help"), "DermaLarge", 16, 6, GOLD)
    end
    local side = vgui.Create("DPanel", frame)
    side:Dock(LEFT); side:SetWide(270); side:DockMargin(4, 22, 6, 4)
    side.Paint = function(_, pw, ph) draw.RoundedBox(6, 0, 0, pw, ph, Color(32, 25, 15)) end
    local search = vgui.Create("DTextEntry", side)
    search:Dock(TOP); search:DockMargin(6, 6, 6, 4); search:SetTall(30); search:SetFont("DermaDefaultBold")
    search:SetPlaceholderText(ui.search or AGP.L("agp_ui_search", "Search..."))
    search:SetPlaceholderColor(Color(170, 150, 110)); search:SetTextColor(Color(255, 235, 190))
    search:SetPaintBackground(false)
    search.PaintOver = function(_, pw, ph) surface.SetDrawColor(GOLD2); surface.DrawOutlinedRect(0, 0, pw, ph, 1) end
    local sizes = vgui.Create("DPanel", side)
    sizes:Dock(TOP); sizes:SetTall(28); sizes:DockMargin(6, 0, 6, 4); sizes.Paint = nil
    local list = vgui.Create("DScrollPanel", side)
    list:Dock(FILL); list:DockMargin(4, 0, 4, 4)
    local html = vgui.Create("DHTML", frame)
    html:Dock(FILL); html:DockMargin(0, 22, 4, 4)
    local current
    local function show(pid)
        for _, p in ipairs(pages) do
            if p.id == pid then current = p; html:SetHTML(render(p, ui)) end
        end
        for _, b in ipairs(list:GetCanvas():GetChildren()) do b.AGPActive = (b.AGPId == pid) end
    end
    html:AddFunction("agp", "open", function(pid) show(pid) end)
    local function fill(filter)
        list:Clear()
        filter = (filter or ""):lower()
        for _, p in ipairs(pages) do
            if filter == "" or p.title:lower():find(filter, 1, true) or (p.body or ""):lower():find(filter, 1, true) then
                local b = list:Add("DButton")
                b:Dock(TOP); b:DockMargin(2, 2, 2, 0); b:SetTall(34)
                b:SetText(""); b.AGPId = p.id
                b.Paint = function(self2, pw, ph)
                    local on = self2.AGPActive
                    draw.RoundedBox(4, 0, 0, pw, ph, on and Color(90, 66, 26) or (self2:IsHovered() and Color(58, 44, 22) or Color(40, 31, 18)))
                    draw.SimpleText(p.title, "DermaDefaultBold", 34, ph / 2, on and Color(255, 230, 160) or GOLD, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                if p.icon then
                    local img = vgui.Create("DImage", b); img:SetImage(p.icon); img:SetSize(16, 16); img:SetPos(10, 9); img:SetMouseInputEnabled(false)
                end
                b.DoClick = function() show(p.id) end
                b.AGPActive = current and current.id == p.id
            end
        end
    end
    search.OnChange = function() fill(search:GetValue()) end
    for i, d in ipairs({ { "A-", -2 }, { "A+", 2 } }) do
        local b = vgui.Create("DButton", sizes)
        b:Dock(LEFT); b:SetWide(60); b:DockMargin(0, 0, 4, 0); b:SetText(d[1]); b:SetFont("DermaDefaultBold")
        b:SetTooltip(ui.size or AGP.L("agp_ui_text_size", "Text size"))
        b.DoClick = function() RunConsoleCommand("agp_wiki_size", tostring(math.Clamp(cvSize:GetInt() + d[2], 12, 30))); timer.Simple(0.05, function() if current then show(current.id) end end) end
    end
    fill("")
    show(id and id ~= "" and id or pages[1].id)
end

concommand.Add("agp_wiki", function(_, _, args) AGP.OpenWiki(args[1]) end)

-- in the tool tabs: a page with a big button and the topics
-- SpaceGrid's help lists only the SpaceGrid pages; the Ascension Gates help lists all
local SPACEGRID = { spacegrid = true, goauldpower = true, lifesupport = true }
local function cpanel(panel, only)
    panel:ClearControls()
    local pages, ui = AGP.WikiPages()
    if only then
        local t = {}
        for _, p in ipairs(pages) do if only[p.id] then t[#t + 1] = p end end
        pages = t
    end
    panel:Help(ui.intro or AGP.L("agp_ui_everything_about_ascension_gates_what_the", "Everything about Ascension Gates: what the parts do and how you control them."))
    local b = panel:Button(ui.open or AGP.L("agp_ui_open_the_help", "Open the help"))
    b:SetTall(36)
    b.DoClick = function() AGP.OpenWiki(only and pages[1] and pages[1].id or nil) end
    for _, p in ipairs(pages) do
        local l = panel:Button(p.title)
        l.DoClick = function() AGP.OpenWiki(p.id) end
    end
end
hook.Add("PopulateToolMenu", "AGP.Wiki", function()
    local function L(k, d) return AGP and AGP.L and AGP.L(k, d) or d end
    spawnmenu.AddToolMenuOption("Stargate", "Config", "agp_wiki", " " .. L("agp_wiki_menu", "Help (Wiki)"), "", "", cpanel)
    spawnmenu.AddToolMenuOption("SpaceGrid", "Settings", "agp_wiki_sg", L("agp_wiki_menu", "Help (Wiki)"), "", "", function(p) cpanel(p, SPACEGRID) end)
end)
