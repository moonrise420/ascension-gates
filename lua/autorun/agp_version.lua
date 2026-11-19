-- Ascension Gates: pack version and our own links (shown in the info screen, the Credits panel and the "Information" entry)
AGP = AGP or {}
AGP.Version = "1.0.1" -- numbers first: the update check compares them with the GitHub release tag (v0.1.0)

-- Fill these in once they exist. Empty = the buttons are not shown.
AGP.Links = {
	GitHub = "https://github.com/moonrise420/ascension-gates",
	Workshop = "https://steamcommunity.com/sharedfiles/filedetails/?id=3840679305",
}

-- list of { label, url } for the links that are set (for the menus)
function AGP.LinkList()
	local out = {}
	if AGP.Links.Workshop ~= "" then out[#out + 1] = { "Ascension Gates (Steam Workshop)", AGP.Links.Workshop } end
	if AGP.Links.GitHub ~= "" then out[#out + 1] = { "Ascension Gates (GitHub)", AGP.Links.GitHub } end
	return out
end

-- installed from the Steam Workshop? Steam then updates it by itself; the GitHub check is for manual installs
function AGP.FromWorkshop()
	for _, a in ipairs(engine.GetAddons()) do
		if a.mounted and string.find(string.lower(a.title or ""), "ascension gates", 1, true) then return true end
	end
	return false
end

-- show the "Check for updates" button? (GitHub link set, not a Workshop install)
function AGP.UpdateCheckWanted()
	return AGP.Links.GitHub ~= "" and not AGP.FromWorkshop()
end

if CLIENT then
	local function nums(v)
		local t = {}
		for n in tostring(v):gmatch("%d+") do t[#t + 1] = tonumber(n); if #t == 3 then break end end
		return t
	end

	-- is version a newer than b? (1.2.10 > 1.2.9)
	local function newer(a, b)
		local x, y = nums(a), nums(b)
		for i = 1, 3 do
			local p, q = x[i] or 0, y[i] or 0
			if p ~= q then return p > q end
		end
		return false
	end

	local function say(text) chat.AddText(Color(255, 190, 80), "[Ascension Gates] ", color_white, text) end
	local function L(key, fallback, ...) return (AGP.L and AGP.L(key, fallback, ...)) or string.format(fallback, ...) end

	-- only when the player presses the button: one request for the latest public release on GitHub, nothing about the
	-- player is sent
	function AGP.CheckForUpdate()
		local repo = AGP.Links.GitHub:match("github%.com/([^/]+/[^/#?]+)")
		if not repo then return end
		repo = repo:gsub("%.git$", "")
		say(L("agp_upd_checking", "Checking GitHub for a new version..."))
		http.Fetch("https://api.github.com/repos/" .. repo .. "/releases/latest", function(body, _, _, code)
			local t = code == 200 and util.JSONToTable(body or "")
			local tag = istable(t) and t.tag_name
			if not tag then say(L("agp_upd_failed", "Could not reach GitHub. Try again later.")) return end
			if newer(tag, AGP.Version) then
				local msg = L("agp_upd_new", "Version %s is out (you have %s).", tag, AGP.Version)
				say(msg)
				local q = Derma_Query(msg, "Ascension Gates", L("agp_upd_open", "Open the download page"),
					function() gui.OpenURL(t.html_url or AGP.Links.GitHub) end, L("agp_upd_later", "Later"))
				if AGP.ApplySkin then AGP.ApplySkin(q) end
			else
				say(L("agp_upd_current", "You have the newest version (%s).", AGP.Version))
			end
		end, function() say(L("agp_upd_failed", "Could not reach GitHub. Try again later.")) end)
	end
end

