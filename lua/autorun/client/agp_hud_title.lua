--[[
	Ascension Gates: the title of the small info boxes (ZPM hubs, ZPM, generators, power hub, power cell ...) drawn next to
	a device you look at. The title bar of the box picture is narrow (about 50 - 60 px). Instead of abbreviating the name,
	AGP.DrawBoxTitle draws the REAL, full device name of the player's language and makes it fit by DRAWING:
	  1. the "header" font (Arial 12) when it fits,
	  2. else the same face in a smaller size (11, 10, 9),
	  3. else on two lines (split at a space, sizes 9, 8),
	  4. else the smallest size on one line.
	Nothing is clipped; the text starts at x (right of the box's icon area is never reached: the bar ends at
	AGP.BOX_TITLE_RIGHT pixels right of the screen centre).
]]
AGP = AGP or {}

-- right end of the usable title bar, in pixels right of the screen centre (the bar's slanted end at the text's bottom)
AGP.BOX_TITLE_RIGHT = 109

local SIZES = { 12, 11, 10, 9, 8, 7 }

-- the same definition as the "header" font (entities zpm_mk3 / zpm_mk4): Arial, weight 500, antialiased
for _, s in ipairs(SIZES) do
	surface.CreateFont("AGPBoxTitle" .. s, { font = "Arial", size = s, weight = 500, antialias = true, additive = false })
end

local function width(text, size)
	surface.SetFont("AGPBoxTitle" .. size)
	local w, h = surface.GetTextSize(text)
	return w, h
end

-- the best split of text at a space (smallest widest line), or nil when there is no space
local function split(text, size)
	local best, bestw
	for pos in string.gmatch(text, "()[ ]") do
		local a, b = string.sub(text, 1, pos - 1), string.sub(text, pos + 1)
		if a ~= "" and b ~= "" then
			local m = math.max(width(a, size), width(b, size))
			if not bestw or m < bestw then best, bestw = { a, b }, m end
		end
	end
	return best, bestw
end

-- text: the title; x, y: where draw.DrawText(text, "header", x, y, color, 0) would put the top left of the text;
-- maxWidth (optional): the usable width, default = up to AGP.BOX_TITLE_RIGHT. Returns the size used and the line count.
function AGP.DrawBoxTitle(text, x, y, color, maxWidth)
	text = tostring(text or "")
	maxWidth = maxWidth or (ScrW() / 2 + AGP.BOX_TITLE_RIGHT - x)
	for _, s in ipairs(SIZES) do
		local w, h = width(text, s)
		if s >= 9 and w <= maxWidth then
			draw.DrawText(text, "AGPBoxTitle" .. s, x, y + math.floor((14 - h) / 2), color, 0) -- centred on the 12 px line
			return s, 1
		end
	end
	for _, s in ipairs({ 9, 8 }) do
		local lines, w = split(text, s)
		if lines and w <= maxWidth then
			local gap = s + 1 -- line distance; the two lines (2 * gap) fill the 22 px bar, centred on its middle (y + 5)
			local top = y + 5 - gap
			draw.DrawText(lines[1], "AGPBoxTitle" .. s, x, top, color, 0)
			draw.DrawText(lines[2], "AGPBoxTitle" .. s, x, top + gap, color, 0)
			return s, 2
		end
	end
	for _, s in ipairs({ 8, 7 }) do
		local w, h = width(text, s)
		if w <= maxWidth or s == 7 then
			draw.DrawText(text, "AGPBoxTitle" .. s, x, y + math.floor((14 - h) / 2), color, 0)
			return s, 1
		end
	end
end
