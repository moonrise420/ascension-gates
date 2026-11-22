--[[
	Ascension Gates: the names and descriptions of the Stargate tools follow a language switch. About 40 tool
	files (weapons/gmod_tool/stools) read their texts ONCE when they load:
	TOOL.Name = SGLanguage.GetMessage("stool_cloak"), language.Add("Tool.<mode>.name", ...) through the base tool, a few
	language.Add(...) of their own. After a switch of sg_language (SGLanguage.ReloadSGLanguages) the old texts stayed until
	the next game start.
	Instead of editing every tool file: while the tools load (before InitPostEntity) this file notes which language KEY
	produced which text (SGLanguage.GetMessage called from a gmod_tool file) and which tool field / language phrase received
	it. When the Stargate languages are reloaded, every noted field and phrase is set again from its key.
	  - A text that two different keys produced is only set again when all of those keys give the same new text.
	  - Texts that did not come from a key (a fixed English string) stay as they are.
	The spawn menu has to be rebuilt afterwards to show the new TOOL.Name in its tool list (spawnmenu_reload; the
	language pages / tests do that); the tool gun's own texts (name, description, left / right click) show at once.
	AGP.ToolTextInfo() returns how many fields / phrases follow the language.
]]
AGP = AGP or {}

if not SGLanguage or not SGLanguage.GetMessage or not language or not language.Add then return end

local origGet, origAdd = SGLanguage.GetMessage, language.Add
local recording = true
local byText = {}     -- text -> { key = true }
local adds = {}       -- language.Add calls made by tool files: { placeholder, text }
local fields = {}     -- after InitPostEntity: { tools = { tool tables }, keys = { ... } } for TOOL.Name
local phrases = {}    -- after InitPostEntity: { ph = placeholder, keys = { ... } }

-- is a tool file (or something it called) on the Lua stack? Returns true and the tool's file name (= its mode) when a
-- file of weapons/gmod_tool/stools is on the stack
local function inToolFile()
	local found = false
	for lv = 2, 9 do
		local info = debug.getinfo(lv, "S")
		if not info then break end
		local src = string.lower(info.short_src or "")
		if string.find(src, "gmod_tool", 1, true) then
			found = true
			local f = string.match(src, "stools/([%w_]+)%.lua$")
			if f then return true, f end
		end
	end
	return found, nil
end

local function myGet(message, ...)
	local r = origGet(message, ...)
	if recording and select("#", ...) == 0 and isstring(r) and r ~= "" and r ~= message then
		local ok, file = inToolFile()
		if ok then
			local t = byText[r]
			if not t then t = {}; byText[r] = t end
			local k = t[message]
			if not k then k = {}; t[message] = k end
			k[file or "?"] = true
		end
	end
	return r
end
SGLanguage.GetMessage = myGet

local function myAdd(placeholder, text)
	origAdd(placeholder, text)
	if recording and isstring(text) and byText[text] then
		local ok, file = inToolFile()
		if ok then adds[#adds + 1] = { placeholder, text, file } end
	end
end
language.Add = myAdd

-- the keys that produced this text; when several did, those that were read by the same tool file (when known)
local function keysOf(text, file)
	local t = byText[text]
	if not t then return nil end
	local list, mine = {}, {}
	for k, files in pairs(t) do
		list[#list + 1] = k
		if file and files[file] then mine[#mine + 1] = k end
	end
	if #list > 1 and #mine > 0 then return mine end
	return list
end

-- the text for a list of keys: only when they all agree
local function valueOf(keys)
	local v
	for _, k in ipairs(keys) do
		local x = origGet(k)
		if v ~= nil and x ~= v then return nil end
		v = x
	end
	return v
end

-- the exact key each field of a tool file asks for, read from the file's own lines:
--   TOOL.Name = SGLanguage.GetMessage("key")      TOOL.Topic["name"] = ...      TOOL.Language["Undone"] = ...
-- (two keys with the same text in the start language cannot be told apart by their text, but they can by this)
local function sourceKeys(mode)
	local src = file.Read("weapons/gmod_tool/stools/" .. mode .. ".lua", "LUA")
	if not src then return nil end
	local r = { topic = {}, lang = {} }
	for line in string.gmatch(src, "[^\r\n]+") do
		local key = string.match(line, "SGLanguage%.GetMessage%(%s*[\"']([%w_]+)[\"']%s*%)")
		if key then
			if string.match(line, "^%s*TOOL%.Name%s*=") then r.name = key
			else
				local t = string.match(line, "^%s*TOOL%.Topic%[%s*[\"']?([%w_]+)[\"']?%s*%]%s*=")
				if t then r.topic[t] = key end
				local l = string.match(line, "^%s*TOOL%.Language%[%s*[\"']([%w_]+)[\"']%s*%]%s*=")
				if l then r.lang[l] = key end
			end
		end
	end
	return r
end

local function finish()
	if not recording then return end
	recording = false
	local stored = weapons.GetStored("gmod_tool")
	local exact = {}   -- placeholder -> the key its line asked for
	for mode, tool in pairs(list.Get("CAP.Tool") or {}) do
		local sk = istable(tool) and sourceKeys(mode)
		if sk then
			for k, key in pairs(sk.topic) do exact["Tool." .. mode .. "." .. k] = key end
			local class = istable(tool.Entity) and tool.Entity.Class or nil
			for k, key in pairs(sk.lang) do exact[k .. "_" .. (class or mode)] = key end
		end
		if istable(tool) and isstring(tool.Name) and string.sub(tool.Name, 1, 1) ~= "#" then
			local keys = keysOf(tool.Name, mode)
			if sk and sk.name and keys and #keys > 1 then keys = { sk.name } end
			if keys then
				local tools = { tool }
				local other = stored and stored.Tool and stored.Tool[mode]
				if istable(other) and other ~= tool then tools[2] = other end
				fields[#fields + 1] = { tools = tools, keys = keys }
			end
		end
	end
	for _, a in ipairs(adds) do
		local keys = keysOf(a[2], a[3])
		if keys and #keys > 1 and exact[a[1]] then keys = { exact[a[1]] } end
		if keys then phrases[#phrases + 1] = { ph = a[1], keys = keys } end
	end
	byText, adds = {}, {}
	-- (our notes are done; take the wrappers out unless somebody wrapped them again)
	if SGLanguage.GetMessage == myGet then SGLanguage.GetMessage = origGet end
	if language.Add == myAdd then language.Add = origAdd end
end

function AGP.RefreshToolTexts()
	finish()
	local nf, np, skipped = 0, 0, 0
	local why = {}
	for _, f in ipairs(fields) do
		local v = valueOf(f.keys)
		if v then
			for _, t in ipairs(f.tools) do t.Name = v end
			nf = nf + 1
		else skipped = skipped + 1; why[#why + 1] = "Name:" .. table.concat(f.keys, "/") end
	end
	for _, p in ipairs(phrases) do
		local v = valueOf(p.keys)
		if v then language.Add(p.ph, v); np = np + 1 else skipped = skipped + 1; why[#why + 1] = p.ph .. ":" .. table.concat(p.keys, "/") end
	end
	AGP.ToolTextRefreshed = { names = nf, phrases = np, skipped = skipped, why = why }
	return nf, np, skipped
end

function AGP.ToolTextInfo()
	return #fields, #phrases
end

-- the Stargate languages were reloaded (sg_language_reload, after the language was switched): set the texts again
local function wrapReload()
	if SGLanguage.AGPToolTextsWrapped or not SGLanguage.ReloadSGLanguages then return end
	SGLanguage.AGPToolTextsWrapped = true
	local orig = SGLanguage.ReloadSGLanguages
	SGLanguage.ReloadSGLanguages = function(...)
		local r = orig(...)
		if not recording then
			AGP.RefreshToolTexts()
			hook.Run("AGP.ToolTextsRefreshed")
		end
		return r
	end
end
wrapReload()

hook.Add("InitPostEntity", "AGP.ToolTexts", function()
	wrapReload()
	finish()
end)
