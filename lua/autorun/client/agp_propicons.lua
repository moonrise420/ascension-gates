--[[
	Ascension Gates: our own pictures for the prop icons of our lists (CAP props, Ascension Gates Props). GMod renders
	spawn icons itself and cuts big models off (Ha'tak hull, buildings: blank or one-colour icons), and it keeps those
	in its cache. The pictures in materials/agp/propicons/ (rendered from outside each model, notes/test suite
	propicons) are laid over any model icon that has one.
]]
local function iconPath(m)
    local n = string.lower(m):gsub("\\", "/"):gsub("^models/", ""):gsub("%.mdl$", ""):gsub("/", "_")
    return "materials/agp/propicons/" .. n .. ".png"
end

local wrapped
local function wrap()
    local orig = spawnmenu.GetContentType("model")
    if (not orig or orig == wrapped) then return end
    wrapped = function(container, obj)
        local icon = orig(container, obj)
        if (IsValid(icon) and obj and obj.model) then
            local p = iconPath(obj.model)
            if (file.Exists(p, "GAME")) then
                local img = vgui.Create("DImage", icon)
                img:SetImage(p:gsub("^materials/", ""))
                img:Dock(FILL)
                img:DockMargin(3, 3, 3, 3)
                img:SetMouseInputEnabled(false)
                if (IsValid(icon.Icon)) then icon.Icon:SetVisible(false) end   -- GMod's own (cached) render
            end
        end
        return icon
    end
    spawnmenu.AddContentType("model", wrapped)
end
hook.Add("InitPostEntity", "AGP_PropIcons", wrap)
hook.Add("PopulatePropMenu", "AGP_PropIcons", wrap)
