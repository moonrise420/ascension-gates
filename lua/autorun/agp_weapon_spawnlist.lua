-- Ascension Gates: every weapon of our own spawn tab (list "CAP.Weapon") is also in Garry's Mod's own Weapons tab,
-- all in one category, "Ascension Gates" (like our entities in GMod's Entities tab), each under the heading of
-- its group in our tab (Player Weapons, Misc Weapons, ...). Before, only the newer ones were there
-- (Spawnable), spread over GMod's generic "Player Weapons" / "Misc Weapons"; the other ~30 only in our tab.
-- Only GMod's list entry gets the category: SWEP.Category stays, our tab still groups by it (nothing twice, nothing
-- moved there). A Spawnable = false in a weapon file of our tab no longer hides it from GMod's tab.
-- What a server allows stays the same: giving or spawning one of them from GMod's tab (gm_giveswep / gm_spawnswep) goes
-- through the same Stargate restrictions (StarGate.NotSpawnable: disabled list, groups) as our tab's cap_giveswep.
AddCSLuaFile()
AGP = AGP or {}
AGP.WeaponTabCategory = "Ascension Gates"

-- is this registered weapon one of our tab's? (its SWEP table is in list CAP.Weapon)
local function packWeapon(t)
    if (not istable(t)) then return false end
    for _, v in pairs(list.GetForEdit("CAP.Weapon")) do
        if (v == t) then return true end
    end
    return false
end

function AGP.WeaponTabFix()
    local gm = list.GetForEdit("Weapon")
    for _, t in pairs(list.GetForEdit("CAP.Weapon")) do
        local class = istable(t) and t.ClassName
        local e = class and gm[class]
        -- only the registered table (adria_dialer registers its own SWEP table a moment after the file ran)
        if (e and weapons.GetStored(class) == t) then
            t.Spawnable = true
            e.Spawnable = true
            e.SubCategory = t.Category
            e.Category = AGP.WeaponTabCategory
        end
    end
end

-- weapons.Register makes GMod's list entry right after this hook: fix the entries one tick later (once for all)
hook.Add("PreRegisterSWEP", "AGP.WeaponTab", function(t)
    if (packWeapon(t)) then timer.Create("AGP.WeaponTab", 0, 1, AGP.WeaponTabFix) end
end)
hook.Add("InitPostEntity", "AGP.WeaponTab", AGP.WeaponTabFix)

if CLIENT then
    list.Set("ContentCategoryIcons", AGP.WeaponTabCategory, "gui/agp_logo.png")   -- the category's icon in GMod's tabs
end

if SERVER then
    local function blocked(ply, class)
        if (not (StarGate and StarGate.NotSpawnable) or not packWeapon(weapons.GetStored(class))) then return end
        if (StarGate.NotSpawnable(class, ply, "swep")) then return false end
    end
    hook.Add("PlayerGiveSWEP", "AGP.WeaponTab", blocked)
    hook.Add("PlayerSpawnSWEP", "AGP.WeaponTab", blocked)
end
