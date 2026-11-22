--[[
	Ascension Gates: one HUD for every pilotable craft.
	in the style of the Daedalus HUD (dark navy plates, light grey double frame, a cut corner, white underlined titles,
	thin bars with 0/50/100 marks), small, the keys folded away until F1 (which then does not open the spawn menu). The
	species shows in the accent colour of titles and bars.

	Bottom left: the status plate (name, hull, shield, hyperdrive, the craft's own rows, state tags).
	Bottom right: the controls plate with the keys really bound in the Keybinder (or GMod's own binds for crafts flown
	from a plain seat); folded by default, F1 opens / closes it.
	A craft is described once in AGP.HUD.Ships (lua/autorun/client/agp_ship_hud_ships.lua) or ENT.AGPHud.
]]
AGP = AGP or {}
AGP.HUD = AGP.HUD or {}
local HUD = AGP.HUD

local function L(key, fallback, ...)
	if (SGLanguage and SGLanguage.ValidMessage and SGLanguage.ValidMessage(key)) then
		-- AGP: with values GetMessage fills them in; without, the raw text (GetMessage on "%d" without a value is an error)
		if (select("#", ...) > 0) then return SGLanguage.GetMessage(key, ...) end
		local raw = SGLanguage_Messages and SGLanguage_Messages[key]
		if (raw) then return tostring(raw) end
		local ok, m = pcall(SGLanguage.GetMessage, key)
		return ok and m or fallback
	end
	if (select("#", ...) > 0) then return string.format(fallback, ...) end
	return fallback
end
HUD.L = L

--########## Species accents (the plates are the same Daedalus style for all)
HUD.Themes = {
	goauld   = { line = Color(235, 185, 80), tag = "GOA'ULD" },
	tauri    = { line = Color(120, 190, 255), tag = "TAU'RI" },
	ancient  = { line = Color(90, 225, 255), tag = "LANTEAN" },
	destiny  = { line = Color(150, 190, 255), tag = "DESTINY" },
	wraith   = { line = Color(150, 230, 110), tag = "WRAITH" },
	ori      = { line = Color(255, 225, 160), tag = "ORI" },
	asuran   = { line = Color(190, 160, 255), tag = "REPLICATOR" },
	traveler = { line = Color(255, 165, 90), tag = "TRAVELER" },
}
local BG = Color(14, 18, 30, 225)          -- navy plate
local FRAME = Color(200, 205, 212, 235)    -- light grey frame
local FRAME2 = Color(110, 118, 130, 200)   -- inner frame
local TEXT = Color(240, 244, 250)
local DIM = Color(160, 168, 182)
local GOOD, WARN, BAD = Color(120, 220, 140), Color(255, 195, 80), Color(255, 85, 75)
for _, th in pairs(HUD.Themes) do th.text, th.dim, th.good, th.warn, th.bad = TEXT, DIM, GOOD, WARN, BAD end

surface.CreateFont("AGPHudTitle", { font = "Arial", size = 17, weight = 700, antialias = true })
surface.CreateFont("AGPHudTag", { font = "Arial", size = 11, weight = 700, antialias = true })
surface.CreateFont("AGPHudText", { font = "Arial", size = 14, weight = 600, antialias = true })
surface.CreateFont("AGPHudSmall", { font = "Arial", size = 13, weight = 600, antialias = true })
surface.CreateFont("AGPHudKey", { font = "Consolas", size = 13, weight = 700, antialias = true })

--########## Drawing: the Daedalus plate
local function poly(pts, col)
	surface.SetDrawColor(col)
	draw.NoTexture()
	surface.DrawPoly(pts)
end
local function outline(pts, col)
	surface.SetDrawColor(col)
	for i = 1, #pts do
		local a, b = pts[i], pts[i % #pts + 1]
		surface.DrawLine(a.x, a.y, b.x, b.y)
	end
end
-- a plate with the top-right corner cut, a light grey frame and a thin inner frame
function HUD.Panel(x, y, w, h, th, cut)
	cut = cut or math.min(18, h * 0.5)
	local pts = { { x = x, y = y }, { x = x + w - cut, y = y }, { x = x + w, y = y + cut }, { x = x + w, y = y + h }, { x = x, y = y + h } }
	poly(pts, BG)
	outline(pts, FRAME)
	outline({ { x = x + 1, y = y + 1 }, { x = x + w - cut - 1, y = y + 1 }, { x = x + w - 1, y = y + cut + 1 }, { x = x + w - 1, y = y + h - 1 }, { x = x + 1, y = y + h - 1 } }, FRAME)
	outline({ { x = x + 4, y = y + 4 }, { x = x + w - cut - 2, y = y + 4 }, { x = x + w - 4, y = y + cut + 2 }, { x = x + w - 4, y = y + h - 4 }, { x = x + 4, y = y + h - 4 } }, FRAME2)
end

-- an underlined title like "HULL" on the Daedalus plates
function HUD.Title(text, x, y, col)
	surface.SetFont("AGPHudTitle")
	local tw, th = surface.GetTextSize(text)
	draw.SimpleText(text, "AGPHudTitle", x, y, TEXT)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y + th, tw, 2)
	return th + 4
end

-- one bar row: label left, value right, then a thin bar with 0 / 50 / 100 marks
function HUD.Bar(x, y, w, frac, col, label, value)
	frac = math.Clamp(frac or 0, 0, 1)
	draw.SimpleText(label, "AGPHudSmall", x, y, TEXT)
	if (value) then draw.SimpleText(value, "AGPHudSmall", x + w, y, col, TEXT_ALIGN_RIGHT) end
	local by = y + 17
	surface.SetDrawColor(FRAME2)
	surface.DrawOutlinedRect(x, by, w, 8)
	if (frac > 0) then
		surface.SetDrawColor(col.r, col.g, col.b, 210)
		surface.DrawRect(x + 2, by + 2, math.max(1, (w - 4) * frac), 4)
	end
	surface.SetDrawColor(FRAME)
	surface.DrawRect(x, by - 3, 1, 14); surface.DrawRect(x + w / 2, by - 2, 1, 12); surface.DrawRect(x + w - 1, by - 3, 1, 14)
	return 30
end

-- a small state tag ("CLOAKED"); returns its width
function HUD.Chip(x, y, text, col)
	surface.SetFont("AGPHudTag")
	local w = surface.GetTextSize(text) + 10
	surface.SetDrawColor(col.r, col.g, col.b, 40)
	surface.DrawRect(x, y, w, 15)
	surface.SetDrawColor(col)
	surface.DrawOutlinedRect(x, y, w, 15)
	draw.SimpleText(text, "AGPHudTag", x + 5, y + 7, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	return w
end

--########## Which craft am I flying?
HUD.Ships = HUD.Ships or {}
HUD.Extra = HUD.Extra or {}
function HUD.SpecOf(e)
	if (not IsValid(e)) then return end
	return e.AGPHud or HUD.Ships[e:GetClass()]
end

function HUD.Current()
	local ply = LocalPlayer()
	if (not IsValid(ply)) then return end
	local e = ply:GetNWEntity("ScriptedVehicle", NULL)
	if (IsValid(e) and HUD.SpecOf(e)) then return e end
	for _, c in ipairs(HUD.Extra) do
		local x = c(ply)
		if (IsValid(x) and HUD.SpecOf(x)) then return x end
	end
end

--########## Values every craft has
function HUD.Hull(e, spec)
	if (spec.hull) then return spec.hull(e) end
	local hp = e:GetNWInt(spec.hullNW or "health", -1)
	if (hp < 0) then return nil end
	local max = e:GetNWInt(spec.hullMaxNW or "maxEntHealth", 0)
	if (max <= 0) then max = spec.hullMax or math.max(hp, 1) end
	return hp, max
end

-- speed (game units per second) as text in the player's distance unit: 1 game unit = 1 inch like PowerGrid, StarCore
-- and the suit HUD (it was 1.905 cm and always km/h: 25 % too low). metres -> km/h, feet -> mph, game units -> u/s
-- (agp_unit_distance, PowerGrid's AGP.Units; without PowerGrid km/h).
function HUD.SpeedText(ups)
	if (AGP.Units and AGP.Units.Speed) then return AGP.Units.Speed(ups) end
	return string.format("%d km/h", math.floor(ups * 0.0254 * 3.6))
end

function HUD.HyperRow(e)
	local range = e:GetNWInt("AGPHyperRange", 0)
	if (range <= 0) then return end
	local name = e:GetNWBool("AGPHyperFTL", false) and L("agp_hud_ftl", "FTL drive") or L("agp_hud_hyper", "Hyperdrive")
	if (e:GetNWBool("AGPHyperJump", false)) then return name, 1, L("agp_hud_jump", "jump!") end
	local ready = e:GetNWFloat("AGPHyperReady", 0) - CurTime()
	if (ready > 0) then return name, 0, L("agp_hud_cool", "cooling %d s", math.ceil(ready)) end
	local pct = e:GetNWInt("AGPHyperCharge", 0)
	if (pct > 0) then return name, pct / 100, string.format("%d %%", pct) end
	return name, 0, L("agp_hud_ready", "ready")
end

--########## Status plate
local function drawStatus(e, spec, th)
	local acc = th.line
	local rows = {}
	local hp, max = HUD.Hull(e, spec)
	if (hp) then
		local f = hp / max
		rows[#rows + 1] = { "bar", L("agp_hud_hull", "Hull"), f, string.format("%d %%", math.ceil(f * 100)), f > 0.5 and acc or (f > 0.25 and WARN or BAD) }
	end
	if (spec.shield) then
		local on, dep = e:GetNWBool("AGPShieldOn", false), e:GetNWBool("AGPShieldDepleted", false)
		local f = e:GetNWInt("AGPShieldStrength", 100) / 100
		rows[#rows + 1] = { "bar", L("agp_hud_shield", "Shield"), on and f or 0, on and string.format("%d %%", math.Round(f * 100)) or (dep and L("agp_hud_depleted", "depleted") or L("agp_hud_off", "off")), dep and BAD or (on and acc or DIM) }
	end
	local n, f, txt = HUD.HyperRow(e)
	if (n) then rows[#rows + 1] = { "bar", n, f, txt, acc } end
	if (spec.rows) then for _, r in ipairs(spec.rows(e, th) or {}) do rows[#rows + 1] = r end end
	rows[#rows + 1] = { "text", L("agp_hud_speed", "Speed"), HUD.SpeedText(e:GetVelocity():Length()) }
	local chips = spec.chips and spec.chips(e, th) or {}

	local w, pad = 236, 12
	local h = 40
	for _, r in ipairs(rows) do h = h + (r[1] == "bar" and 30 or 18) end
	if (#chips > 0) then h = h + 20 end
	h = h + 6
	local x, y = 20, ScrH() - 20 - h
	HUD.Panel(x, y, w, h, th)
	local title = spec.title and L(spec.title[1], spec.title[2]) or e.PrintName or ""
	HUD.Title(title, x + pad, y + 9, acc)
	draw.SimpleText(spec.tag or th.tag, "AGPHudTag", x + w - 22, y + 30, DIM, TEXT_ALIGN_RIGHT)
	local cy = y + 40
	for _, r in ipairs(rows) do
		if (r[1] == "bar") then
			cy = cy + HUD.Bar(x + pad, cy, w - pad * 2, r[3], r[5] or acc, r[2], r[4])
		else
			draw.SimpleText(r[2], "AGPHudSmall", x + pad, cy, DIM)
			draw.SimpleText(r[3], "AGPHudSmall", x + w - pad, cy, r[4] or TEXT, TEXT_ALIGN_RIGHT)
			cy = cy + 18
		end
	end
	if (#chips > 0) then
		local cx = x + pad
		for _, c in ipairs(chips) do
			local cw = HUD.Chip(cx, cy + 2, c[1], c[2] or acc)
			cx = cx + cw + 5
			if (cx > x + w - 40) then break end
		end
	end
end

--########## Controls plate (folded by default; F1)
local SHORT = { MOUSE1 = "LMB", MOUSE2 = "RMB", MOUSE3 = "MMB", MOUSE4 = "M4", MOUSE5 = "M5", MWHEELUP = "WHEEL", MWHEELDOWN = "WHEEL",
	UPARROW = "↑", DOWNARROW = "↓", LEFTARROW = "←", RIGHTARROW = "→", BACKSPACE = "BKSP", CAPSLOCK = "CAPS" }
-- an action is a Keybinder action of the craft's layout ("FWD"), a GMod bind ("+forward": crafts flown from a plain
-- seat with the normal IN_ keys, e.g. the Ha'tak) or a fixed key (KEY_V)
local function keyName(layout, action)
	local k
	if (isnumber(action)) then
		k = input.GetKeyName(action)
	elseif (string.sub(action, 1, 1) == "+" or action == "invprev" or action == "invnext") then
		k = input.LookupBinding(action, true)
	else
		local kb = StarGate and StarGate.KeyBoard and StarGate.KeyBoard.Schemes and StarGate.KeyBoard.Schemes[layout]
		k = kb and kb.GetKey and kb:GetKey(action)
	end
	if (not k or k == "") then return nil end
	k = k:upper()
	return SHORT[k] or k
end

local KEYCV = CreateClientConVar("agp_hud_key", tostring(KEY_F1), true, false, "Ascension Gates: key that folds / unfolds the ship controls plate")
local OPENCV = CreateClientConVar("agp_hud_keys_open", "0", true, false, "Ascension Gates: 1 = the ship controls plate is open when you get in")
local function hudKey() local k = KEYCV:GetInt() return (k and k > 0) and k or KEY_F1 end
local function hudKeyName() return string.upper(input.GetKeyName(hudKey()) or "F1") end
local keysOpen, f1Was, lastCraft = false, false, nil
local function drawKeys(e, spec, th)
	local acc = th.line
	local head = L("agp_hud_keys", "Controls")
	surface.SetFont("AGPHudTitle")
	local hw = surface.GetTextSize(head)
	if (not keysOpen) then
		local w, h = hw + 70, 32
		local x, y = ScrW() - 20 - w, ScrH() - 20 - h
		if (spec.keysPos == "center") then x = ScrW() / 2 - w / 2 end
		HUD.Panel(x, y, w, h, th, 10)
		draw.SimpleText(head, "AGPHudTitle", x + 12, y + 16, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("[" .. hudKeyName() .. "]", "AGPHudKey", x + w - 16, y + 16, acc, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		return
	end
	local list = {}
	local keys = spec.keys
	if (isfunction(keys)) then keys = keys(e) end -- keys that depend on the craft's mode
	-- every steered craft: hold ALT (+walk) to look around without steering (AGP.SteerAim, agp_keypress.lua)
	if (not spec.noFreeLook and keys) then
		keys = table.Copy(keys)
		table.insert(keys, math.max(1, #keys - 1), { "+walk", "agp_hud_k_freelook", "Look around, ship keeps its course (hold)" })
	end
	for _, k in ipairs(keys or {}) do
		local key
		if (istable(k[1])) then
			local parts, seen = {}, {}
			for _, a in ipairs(k[1]) do local n = keyName(spec.layout, a) if (n and not seen[n]) then seen[n] = true; parts[#parts + 1] = n end end
			if (#parts > 0) then key = table.concat(parts, " ") end
		else
			key = keyName(spec.layout, k[1])
		end
		if (key) then list[#list + 1] = { key, L(k[2], k[3] or "") } end
	end
	surface.SetFont("AGPHudKey")
	local kmax = 30
	for _, r in ipairs(list) do kmax = math.max(kmax, surface.GetTextSize(r[1]) + 10) end
	kmax = math.min(kmax, 104)
	surface.SetFont("AGPHudSmall")
	local lmax = 0
	for _, r in ipairs(list) do lmax = math.max(lmax, surface.GetTextSize(r[2])) end
	local rowH = 17
	local w = math.Clamp(kmax + lmax + 36, hw + 70, 420)
	local h = 40 + #list * rowH + 6
	local x, y = ScrW() - 20 - w, ScrH() - 20 - h
	if (spec.keysPos == "center") then x = ScrW() / 2 - w / 2 end -- the Daedalus keeps its own plates left and right
	HUD.Panel(x, y, w, h, th)
	HUD.Title(head, x + 12, y + 9, acc)
	draw.SimpleText("[" .. hudKeyName() .. "]", "AGPHudKey", x + w - 24, y + 12, acc, TEXT_ALIGN_RIGHT)
	for i, r in ipairs(list) do
		local ry = y + 38 + (i - 1) * rowH
		surface.SetDrawColor(FRAME2)
		surface.DrawOutlinedRect(x + 12, ry, kmax, 15)
		draw.SimpleText(r[1], "AGPHudKey", x + 12 + kmax / 2, ry + 7, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(r[2], "AGPHudSmall", x + 12 + kmax + 8, ry + 7, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
end

--########## Gun crosshair (F-302: where the nose points; Daedalus: where the pilot aims), gliding smoothly
local mx, my
function HUD.SmoothMarker(pos)
	local sc = pos:ToScreen()
	if (not sc.visible) then mx = nil return end
	if (not mx) then mx, my = sc.x, sc.y end
	local k = math.Clamp(FrameTime() * 18, 0, 1)
	mx, my = Lerp(k, mx, sc.x), Lerp(k, my, sc.y)
	return mx, my
end
local function drawMarker(e, spec, th)
	if (not spec.marker) then return end
	local hit
	if (spec.marker == "aim" and AGP.ShipAimHit) then
		hit = AGP.ShipAimHit -- AGP: the point the guns aim at (lua/autorun/agp_ship_aim.lua)
	else
		local dir = spec.marker == "aim" and EyeAngles():Forward() or e:GetForward()
		local start = spec.marker == "aim" and EyePos() or e:GetPos() -- "aim": along the view from the camera (the guns aim there)
		-- AGP: never on the craft itself (its shield bubble and parts parented deeper held the mark on the hull)
		hit = util.TraceLine({ start = start, endpos = start + dir * 30000, filter = function(x) return x ~= LocalPlayer() and not (AGP.ShipPart and AGP.ShipPart(e, x) or x == e or x:GetParent() == e) end }).HitPos
	end
	local x, y = HUD.SmoothMarker(hit)
	if (not x) then return end
	local c = th.line
	surface.DrawCircle(x, y, 10, c.r, c.g, c.b, 220)
	surface.SetDrawColor(c)
	surface.DrawRect(x - 1, y - 1, 2, 2)
	surface.DrawRect(x - 18, y, 6, 1); surface.DrawRect(x + 13, y, 6, 1)
	surface.DrawRect(x, y - 18, 1, 6); surface.DrawRect(x, y + 13, 1, 6)
end

hook.Add("HUDPaint", "AGP.ShipHUD", function()
	local e = HUD.Current()
	if (not IsValid(e)) then lastCraft = nil return end
	local spec = HUD.SpecOf(e)
	local th = HUD.Themes[spec.theme or "tauri"] or HUD.Themes.tauri
	if (e ~= lastCraft) then lastCraft = e; keysOpen = OPENCV:GetBool() end
	local k = hudKey()
	local f1 = (k >= MOUSE_FIRST and input.IsMouseDown(k) or input.IsKeyDown(k)) and not vgui.CursorVisible()
	if (f1 and not f1Was) then keysOpen = not keysOpen end
	f1Was = f1
	if (e.HideHUD) then drawMarker(e, spec, th) return end -- the ship's HIDE key (F-302: H) hides the panels, the crosshair stays
	if (not spec.noStatus) then drawStatus(e, spec, th) end
	drawKeys(e, spec, th)
	drawMarker(e, spec, th)
	if (spec.extra) then spec.extra(e, th) end
end)

concommand.Add("agp_hud_keys", function() keysOpen = not keysOpen end) -- also bindable to any key

-- the HUD key (F1 unless set in AGP Ships settings) in a craft only folds / unfolds the controls: the key's own bind (the spawn menu, help ...) is blocked there
hook.Add("PlayerBindPress", "AGP.ShipHUDF1", function(ply, bind, pressed, code)
	if (code == hudKey() and IsValid(HUD.Current())) then return true end
end)
hook.Add("SpawnMenuOpen", "AGP.ShipHUDF1", function()
	if (input.IsKeyDown(hudKey()) and IsValid(HUD.Current())) then return false end
end)

-- the HL2 health / suit / ammo boxes are hidden while flying (they belong to the player, not the craft)
local HIDE = { CHudHealth = true, CHudBattery = true, CHudAmmo = true, CHudSecondaryAmmo = true }
hook.Add("HUDShouldDraw", "AGP.ShipHUD", function(name)
	if (HIDE[name] and IsValid(HUD.Current())) then return false end
end)
