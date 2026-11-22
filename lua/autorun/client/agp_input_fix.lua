--[[
	Ascension Gates: spawn icons turned pink instead of spawning. GMod selects an
	icon (pink) instead of clicking it when it thinks Shift or Ctrl is held. After alt-tab the game can keep such a key
	"down" (its key-up happened in another window). From the moment the game gets the focus back until Shift and Ctrl
	are seen up once, a click on a spawn icon is a normal click.
]]
local lost, stuck = false, false

hook.Add("Think", "AGP.StuckModifiers", function()
    if not system.HasFocus() then lost = true return end
    if lost then lost = false; stuck = true end
    if stuck and not input.IsShiftDown() and not input.IsControlDown() then stuck = false end
end)

local function patch()
    local t = vgui.GetControlTable("ContentIcon")
    if not t or t.AGPStuckPatched or not t.OnMousePressed then return end
    t.AGPStuckPatched = true
    local orig = t.OnMousePressed
    t.OnMousePressed = function(self, code)
        if stuck and self.m_bSelectable then
            self.m_bSelectable = false
            local r = orig(self, code)
            self.m_bSelectable = true
            return r
        end
        return orig(self, code)
    end
end
hook.Add("OnGamemodeLoaded", "AGP.StuckModifiers", patch)
hook.Add("SpawnMenuCreated", "AGP.StuckModifiers", patch)
