-- Ascension Gates: ship settings page (server side), Stargate > Config > "AGP Ships". Admins (or the single player)
-- change them; everyone sees them. Read by agp_hatak (weapons, hijacking).
util.AddNetworkString("agp_ship_state")
util.AddNetworkString("agp_ship_set")

local SETTINGS = {
    -- 0 = consoles answer only owner + friends, 1 = a hijacker can take the ship with the control crystal (40 s at
    -- the bridge slot), 2 = anyone may use all consoles
    agp_hatak_hijack = { def = 1, min = 0, max = 2, help = "Ha'tak hijacking: 0 crew only, 1 control crystal, 2 anyone" },
    agp_hatak_friendly_fire = { def = 0, min = 0, max = 1, help = "Ha'tak weapons may also fire at the owner and his friends" },
    agp_hatak_weapon_range = { def = 15000, min = 2000, max = 50000, help = "Ha'tak weapons and radar range (units)" },
    agp_hatak_radar_max = { def = 60, min = 10, max = 200, help = "Ha'tak radar: most targets shown at once" },
    -- engine room sabotage: strangers (not crew) may have at most this many power crystals out of their slots
    agp_hatak_crystal_pull = { def = 2, min = 0, max = 15, help = "Ha'tak: power crystals strangers may pull out at once (crew: no limit)" },
    -- glider bay: a destroyed / lost glider comes back on its rack pad after this many seconds (0 = off)
    -- hull health: only heavy hits count (50+ per hit), explosions inside count double and bypass the shield
    agp_hatak_destructible = { def = 1, min = 0, max = 1, help = "Ha'tak: the ship can be destroyed when its hull health runs out" },
    agp_hatak_blast_size = { def = 3, min = 1, max = 5, help = "Ha'tak: size of the blast when it explodes (1 small, 2 medium, 3 large, 4 XL, 5 XXL)" },
    agp_hatak_health = { def = 100000, min = 10000, max = 1000000, help = "Ha'tak: hull health (new ships)" },
    agp_hatak_cloak = { def = 1, min = 0, max = 1, help = "Ha'tak: the cloak may be used" },
    agp_hatak_glider_respawn = { def = 1, min = 0, max = 1, help = "Ha'tak glider bay: lost gliders come back on their pads" },
    agp_hatak_glider_respawn_time = { def = 60, min = 10, max = 600, help = "Ha'tak glider bay: seconds until a lost glider comes back" },
    -- every ship with a shield: the bubble always visible while the shield is up (default: only when it is hit or
    -- switched on / off); the countdown of the ships' self-destruct key
    agp_ship_shield_visible = { def = 0, min = 0, max = 1, help = "Ships: the shield bubble stays visible while the shield is up (0 = only when hit or switched)" },
    agp_ship_destruct_time = { def = 5, min = 1, max = 600, help = "Ships: seconds of the self-destruct countdown" },
    -- the ship weapons' energy (stargate/server/ship_weapons.lua; also made in stargate/shared/init.lua)
    agp_weapon_energy = { def = 1, min = 0, max = 2, help = "Ascension Gates: weapons' energy - 0 = free, 1 = use energy when connected to a network (unconnected fire free), 2 = always need energy" },
    -- weapons against ships: 1 = series power (ranked as in the series, hand weapons 5 %), 0 = AGP sandbox (each
    -- weapon's own damage); stargate/server/ship_weapons.lua StarGate.HullFactor a weapon
    -- welded on a StarCore ship uses the ship's power (stargate/server/ship_weapons.lua)
    agp_ship_power = { def = 1, min = 0, max = 1, help = "Ascension Gates: weapons and shields on a StarCore ship use the ship's power - its ZPMs, generators and batteries first, else the ship's own power (0 = off)" },
    agp_weapon_balance = { def = 1, min = 0, max = 1, help = "Ascension Gates: weapons against ships - 1 = series power (as strong as in the series, hand weapons 5 %), 0 = AGP sandbox (each weapon's own damage)" },
}
for name, s in pairs(SETTINGS) do CreateConVar(name, tostring(s.def), FCVAR_ARCHIVE + FCVAR_NOTIFY, s.help, s.min, s.max) end

-- the client draws the bubble: it reads the setting as a global
local function shieldVisible() SetGlobalBool("AGPShipShieldVisible", GetConVar("agp_ship_shield_visible"):GetBool()) end
cvars.AddChangeCallback("agp_ship_shield_visible", shieldVisible, "AGP.ShipShieldVisible")
hook.Add("InitPostEntity", "AGP.ShipShieldVisible", shieldVisible)
shieldVisible()

local function allowed(p) return IsValid(p) and (p:IsAdmin() or game.SinglePlayer()) end

local function sendState(p)
    net.Start("agp_ship_state")
    net.WriteBool(allowed(p))
    local names = table.GetKeys(SETTINGS); table.sort(names)
    net.WriteUInt(#names, 8)
    for _, n in ipairs(names) do net.WriteString(n); net.WriteInt(GetConVar(n):GetInt(), 32) end
    net.Send(p)
end

net.Receive("agp_ship_set", function(_, p)
    local name, value = net.ReadString(), net.ReadInt(32)
    local s = SETTINGS[name]
    if (s and allowed(p)) then RunConsoleCommand(name, tostring(math.Clamp(value, s.min, s.max))) end
    timer.Simple(0.1, function() if (IsValid(p)) then sendState(p) end end)
end)
concommand.Add("agp_ship_state_request", function(p) if (IsValid(p)) then sendState(p) end end)
