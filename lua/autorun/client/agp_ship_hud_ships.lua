--[[
	Ascension Gates: the crafts of the ship HUD (lua/autorun/client/agp_ship_hud.lua). One entry per craft class:
	theme (species look), title, keyboard layout (for the real keys), shield bar, extra rows, state chips, keys.
]]
if (not AGP or not AGP.HUD) then return end
local HUD = AGP.HUD
local L = HUD.L

local function K(actions, key, fallback) return { actions, key, fallback } end
local FLY = K({ "FWD", "LEFT", "BACK", "RIGHT" }, "agp_hud_k_fly", "Fly")
local UPDOWN = K({ "UP", "DOWN" }, "agp_hud_k_updown", "Up / down")
local BOOST = K("SPD", "agp_hud_k_boost", "Faster")
local ROLL = K({ "RL", "RR", "RROLL" }, "agp_hud_k_roll", "Roll / level out")
local FIRE = K("FIRE", "agp_hud_k_fire", "Fire")
local AIM = K("TRACK", "agp_hud_k_aim", "Aim at the crosshair (hold)")
local SHIELD = K("SHIELD", "agp_hud_k_shield", "Shield on / off")
local DHD = K("DHD", "agp_hud_k_dhd", "Dial the nearest gate")
local HYPER = K("HYPERSPACE", "agp_hud_k_hyper", "Hyperdrive (hold, let go to jump)")
local LAND = K("LAND", "agp_hud_k_land", "Landing mode")
local VIEW = K("VIEW", "agp_hud_k_view", "Change view")
local CAM = K({ "Z+", "Z-", "A+", "A-" }, "agp_hud_k_cam", "Camera distance / height")
local BOOM = K("BOOM", "agp_hud_k_boom", "Self-destruct")
local EXIT = K("EXIT", "agp_hud_k_exit", "Get out")

local function chipsCommon(e, th)
	local c = {}
	local at = e:GetNWFloat("AGPDestructAt", 0)
	if (at > CurTime()) then c[#c + 1] = { L("agp_hud_c_destruct", "SELF-DESTRUCT %d s", math.ceil(at - CurTime())), th.bad } end
	if (e:GetNWBool("AGPCloaked")) then c[#c + 1] = { L("agp_hud_c_cloaked", "CLOAKED"), th.good } end
	if (e:GetNWBool("AGPLanding")) then c[#c + 1] = { L("agp_hud_c_landing", "LANDING MODE (NO STEERING)"), th.warn } end   -- (took a ship left in landing mode for broken controls)
	if (e:GetNWBool("AGPHyperTarget")) then c[#c + 1] = { L("agp_hud_c_wired", "JUMP TARGET SET"), th.line } end
	return c
end

-- a capital ship: hull, shield, hyperdrive, the usual keys
local function capital(theme, title, layout, opt)
	-- AGP: marker "aim": the crosshair where every gun goes (the point the camera looks at, also in the bridge
	-- view; lua/autorun/agp_ship_aim.lua). The old ring showed where the nose points, from the ship's middle.
	local spec = { theme = theme, title = title, layout = layout, shield = true, chips = chipsCommon, marker = "aim",
		keys = { FLY, UPDOWN, BOOST, ROLL, FIRE, AIM, SHIELD, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT } }
	for k, v in pairs(opt or {}) do spec[k] = v end
	return spec
end

-- the big ships' Mouse2 volley (AGP.ShipVolley): key and a ready / cooling row
local VOLLEY = K("TRACK", "agp_hud_k_volley", "Volley at the crosshair")
local VOLLEY_KEYS = { FLY, UPDOWN, BOOST, ROLL, FIRE, VOLLEY, SHIELD, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT }
local function volleyRow(e, th)
	local t = e:GetNWFloat("AGPVolleyAt", 0) - CurTime()
	return { "text", L("agp_hud_r_volley", "Volley"), t > 0 and L("agp_hud_cool", "cooling %d s", math.ceil(t)) or L("agp_hud_ready", "ready"), t > 0 and th.warn or th.good }
end
local VOLLEY_SPEC = { keys = VOLLEY_KEYS, rows = function(e, th) return { volleyRow(e, th) } end }

local S = HUD.Ships
S.sg_vehicle_alkesh = capital("goauld", { "agp_hud_n_alkesh", "Al'kesh" }, "Alkesh", {
	keys = { FLY, UPDOWN, BOOST, ROLL, FIRE, K("BOMB", "agp_hud_k_bomb", "Drop bombs (bombing run)"), SHIELD, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT } })
S.sg_vehicle_aurora = capital("ancient", { "agp_hud_n_aurora", "Aurora" }, "Aurora", {   -- AGP: Mouse1 drones go to the crosshair
	keys = { FLY, UPDOWN, BOOST, ROLL, K("FIRE", "agp_hud_k_dronesaim", "Drones at the crosshair"), K("TRACK", "agp_hud_k_turretvolley", "Turret volley at the crosshair"), SHIELD, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT } })
S.sg_vehicle_destiny = capital("destiny", { "agp_hud_n_destiny", "Destiny" }, "Destiny", {
	keys = { FLY, UPDOWN, BOOST, ROLL, FIRE, K("TRACK", "agp_hud_k_sideturrets", "Turrets at the crosshair (hold)"), SHIELD, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT } })
-- AGP: the seed ship sets Stargates down (B): its factory row (on board / coming out / lowering / building); when ready, how
-- high the belly is over the ground in the player's own unit, green inside the range the ship builds in
--
local function seedHeight(e)
	local from = e:LocalToWorld(Vector(-100, 0, -60))
	local tr = util.TraceLine({ start = from, endpos = from - Vector(0, 0, 32768), mask = MASK_SOLID_BRUSHONLY })
	if (not tr.Hit or tr.HitSky) then return nil end
	return from.z - tr.HitPos.z
end
local function seedRow(e, th)
	-- (as in the series) the factory on board keeps up to e.AGPGateStore gates; B sets one down
	local name = L("agp_hud_r_seed", "Gate factory")
	local now = CurTime()
	if (e:GetNWFloat("AGPSeedAt", 0) > now) then return { "text", name, L("agp_hud_seed_out", "gate coming out"), th.warn } end
	if (e:GetNWFloat("AGPSeedLower", 0) > now) then return { "text", name, L("agp_hud_seed_lowering", "lowering the gate"), th.warn } end
	local n = e:GetNWInt("AGPGatesStored", 0)
	if (n < 1) then
		return { "text", name, L("agp_hud_seed_building", "building %d s", math.max(0, math.ceil(e:GetNWFloat("AGPGateBuildAt", 0) - now))), th.warn }
	end
	local h, r = seedHeight(e), e.AGPSeedRange or { 420, 3000 }
	if (not h) then return { "text", name, L("agp_hud_seed_onboard", "%d on board", n), th.warn } end
	local d = (AGP and AGP.Units and AGP.Units.Distance) and AGP.Units.Distance(h) or (math.Round(h * 0.0254) .. " m")
	return { "text", name, L("agp_hud_seed_ready_n", "%d on board, %s up", n, d), (h >= r[1] and h <= r[2]) and th.good or th.warn }
end
S.sg_vehicle_gateseeder = capital("destiny", { "agp_hud_n_seeder", "Seed Ship" }, "Gateseeder", {
	keys = { FLY, UPDOWN, BOOST, ROLL, FIRE, VOLLEY, K("SEED", "agp_hud_k_seed", "Build a Stargate below"), SHIELD, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT },
	rows = function(e, th) return { volleyRow(e, th), seedRow(e, th) } end })
S.sg_vehicle_oneill = capital("tauri", { "agp_hud_n_oneill", "O'Neill" }, "Oneill", { tag = "ASGARD",
	keys = { FLY, UPDOWN, BOOST, ROLL, FIRE, K("TRACK", "agp_hud_k_asgardbeam", "Asgard beam at the crosshair (hold)"), SHIELD, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT } })
S.sg_vehicle_prometheus = capital("tauri", { "agp_hud_n_prometheus", "Prometheus" }, "Prometheus", {
	keys = { FLY, UPDOWN, BOOST, ROLL, K("FIRE", "agp_hud_k_missiles", "Missiles"), K("TRACK", "agp_hud_k_railguns", "Rail guns"), SHIELD, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT } })
S.sg_vehicle_replicator = capital("asuran", { "agp_hud_n_replicator", "Replicator Ship" }, "ReplicatorMS", VOLLEY_SPEC)
S.sg_vehicle_traveler = capital("traveler", { "agp_hud_n_traveler", "Traveler Ship" }, "Traveler", VOLLEY_SPEC)
-- AGP: the Wraith cruiser has no shield (as in the series): its hull grows back, slowly while it is being hit (6 s after
-- the last hit faster again; sg_vehicle_wraithcruiser.lua sets AGPRegrowHit)
local function regrowRow(e, th)
	local hp, max = e:GetNWInt("health", 0), math.max(1, e:GetNWInt("maxEntHealth", 1))
	if (hp >= max) then return { "text", L("agp_hud_r_regrow", "Hull regrowth"), L("agp_hud_regrow_whole", "whole") } end
	local fight = CurTime() - e:GetNWFloat("AGPRegrowHit", -99) < 6
	return { "text", L("agp_hud_r_regrow", "Hull regrowth"), fight and L("agp_hud_regrow_fight", "slow (under fire)") or L("agp_hud_regrow_calm", "regrowing"), fight and th.warn or th.good }
end
S.sg_vehicle_wraithcruiser = capital("wraith", { "agp_hud_n_cruiser", "Wraith Cruiser" }, "WraithCruiser", { shield = false,
	keys = { FLY, UPDOWN, BOOST, ROLL, FIRE, VOLLEY, DHD, HYPER, LAND, VIEW, CAM, BOOM, EXIT },
	rows = function(e, th) return { volleyRow(e, th), regrowRow(e, th) } end })
S.sg_vehicle_orims = capital("ori", { "agp_hud_n_orims", "Ori Mothership" }, "OriMs", {
	keys = VOLLEY_KEYS,
	rows = function(e, th)
		local ready = e:GetNWInt("CanFire", 1) == 1
		local t = e:GetNWInt("WeaponsTimer", 0)
		return { { "text", L("agp_hud_r_beam", "Main beam"), ready and L("agp_hud_ready", "ready") or L("agp_hud_cool", "cooling %d s", math.max(1, math.ceil(t))), ready and th.good or th.warn }, volleyRow(e, th) }
	end })

S.sg_vehicle_dart = { theme = "wraith", title = { "agp_hud_n_dart", "Wraith Dart" }, layout = "Dart", chips = chipsCommon,
	rows = function(e, th)
		local n, m = e:GetNWInt("AGPCulled", 0), math.max(1, e:GetNWInt("AGPCullMax", 10))
		return { { "bar", L("agp_hud_r_culled", "Culled aboard"), n / m, string.format("%d / %d", n, m), th.good } }
	end,
	keys = { FLY, UPDOWN, BOOST, ROLL, K("SUCK", "agp_hud_k_cull", "Culling beam (hold)"), K("SPIT", "agp_hud_k_spit", "Release one (last first)"), FIRE, DHD, CAM, BOOM, EXIT } }

S.sg_vehicle_gate_glider = { theme = "goauld", title = { "agp_hud_n_gateglider", "Gate Glider" }, layout = "GateGlider", chips = chipsCommon,
	rows = function(e, th)
		local left = e:GetNWFloat("AGPTorpReady", 0) - CurTime()
		return { { "text", L("agp_hud_r_torpedo", "Plasma torpedo"), left > 0 and L("agp_hud_cool", "cooling %d s", math.ceil(left)) or L("agp_hud_ready", "ready"), left > 0 and th.warn or th.good } }
	end,
	keys = { FLY, UPDOWN, BOOST, ROLL, FIRE, K("TORPEDO", "agp_hud_k_torpedo", "Plasma torpedo (locks on)"), DHD, VIEW, CAM, BOOM, EXIT } }

S.sg_vehicle_glider = { theme = "goauld", title = { "agp_hud_n_glider", "Death Glider" }, layout = "DeathGlider",
	chips = function(e, th)
		local c = chipsCommon(e, th)
		if (e:GetNWBool("AGPFreeFlight")) then c[#c + 1] = { L("agp_hud_c_free", "FREE FLIGHT"), th.line } end
		return c
	end,
	rows = function(e, th)
		local firing = e:GetNWFloat("AGPGunReady", 0) > CurTime()
		return { { "text", L("agp_hud_r_staff", "Staff cannons"), firing and L("agp_hud_firing", "firing") or L("agp_hud_ready", "ready"), firing and th.warn or th.good } }
	end,
	-- classic glider flight (the default): W and the mouse only; Space/Ctrl and A/D work in free flight
	keys = function(e)
		if (e:GetNWBool("AGPFreeFlight")) then return { FLY, UPDOWN, BOOST, ROLL, FIRE, VIEW, CAM, BOOM, EXIT } end
		return { K("FWD", "agp_hud_k_fly", "Fly"), BOOST, ROLL, FIRE, VIEW, CAM, BOOM, EXIT }
	end }

S.sg_vehicle_shuttle = { theme = "destiny", title = { "agp_hud_n_shuttle", "Destiny Shuttle" }, layout = "Shuttle", shield = true, hullMaxNW = "maxhealth", chips = chipsCommon,
	keys = { FLY, UPDOWN, BOOST, ROLL, FIRE, SHIELD, CAM, BOOM, EXIT } }

S.sg_vehicle_teltac = { theme = "goauld", title = { "agp_hud_n_teltak", "Tel'tak" }, layout = "Teltak", shield = true, hullMaxNW = "maxhealth", chips = chipsCommon,
	rows = function(e, th)
		local p, r = LocalPlayer(), {}
		local max = math.max(1, p:GetNWInt("MaxCharge", 15000))
		if (p:GetNWBool("Charging")) then
			local f = p:GetNWInt("Charge") / max
			r[#r + 1] = { "bar", L("agp_hud_hyper", "Hyperdrive"), f, string.format("%d %%", math.floor(f * 100)), th.line }
		end
		local cool = math.Round(p:GetNWInt("BeamCooldown"))
		r[#r + 1] = { "text", L("agp_hud_r_ringbeam", "Ring beam"), cool > 0 and L("agp_hud_cool", "cooling %d s", cool) or L("agp_hud_ready", "ready"), cool > 0 and th.warn or th.good }
		return r
	end,
	keys = { FLY, UPDOWN, BOOST, ROLL, LAND, K("FIRE", "agp_hud_k_ringbeam", "Ring beam (in landing mode)"), SHIELD, K("CLOAK", "agp_hud_k_cloak", "Cloak"),
		HYPER, K("DOOR", "agp_hud_k_door", "Doors"), K("FPV", "agp_hud_k_view", "Change view"), CAM, BOOM, EXIT } }

S.sg_vehicle_f302 = { theme = "tauri", title = { "agp_hud_n_f302", "F-302" }, layout = "F302", hullNW = "clhealth", hullMaxNW = "clmaxhealth", hullMax = 500, marker = "nose",
	chips = function(e, th)
		local p, c = LocalPlayer(), chipsCommon(e, th)
		if (e:GetNWBool("Boost")) then c[#c + 1] = { L("agp_hud_c_boost", "AFTERBURNER"), th.warn } end
		if (p.EngineDamaged) then c[#c + 1] = { L("agp_hud_c_engine", "ENGINE DAMAGED"), th.bad } end
		return c
	end,
	rows = function(e, th)
		local p = LocalPlayer()
		local m = p.Missiles or 0
		local wpn = tostring(p.Weapons or "")
		return {
			{ "text", L("agp_hud_r_weapon", "Weapon"), (wpn == "Turrets" and L("agp_hud_r_turrets", "Rail guns")) or (wpn == "Missiles" and L("agp_hud_r_missiles", "Missiles")) or (wpn ~= "" and wpn or "-"), th.text },
			{ "bar", L("agp_hud_r_missiles", "Missiles"), m / 4, p.MissilesDisabled and L("agp_hud_offline", "offline") or string.format("%d / 4", m), p.MissilesDisabled and th.bad or th.line },
			{ "text", L("agp_hud_r_turrets", "Rail guns"), p.TurretsDisabled and L("agp_hud_offline", "offline") or L("agp_hud_online", "online"), p.TurretsDisabled and th.bad or th.good },
		}
	end,
	keys = { K({ "FWD", "BACK" }, "agp_hud_k_speed", "Faster / slower"), UPDOWN, BOOST, K("BOOST", "agp_hud_k_afterburner", "Afterburner"), ROLL, FIRE,
		K("TRACK", "agp_hud_k_track", "Guide missiles (hold)"), K("CHGATK", "agp_hud_k_weapon", "Missiles / rail guns"), K("FLARES", "agp_hud_k_flares", "Flares"),
		K("WHEELS", "agp_hud_k_gear", "Landing gear"), K("BRAKE", "agp_hud_k_turn", "Air-brake turn"), K("COCKPIT", "agp_hud_k_canopy", "Canopy"),
		K("EJECT", "agp_hud_k_eject", "Eject"), K("FPV", "agp_hud_k_view", "Change view"), BOOM, EXIT } }

S.sg_vehicle_daedalus = { theme = "tauri", title = { "agp_hud_n_daedalus", "BC-304 Daedalus" }, layout = "Daedalus", shield = true, hullMaxNW = "clmaxhealth", hullMax = 20000,
	noStatus = true, marker = "aim", keysPos = "center", -- its own BC-304 HUD stays (the author likes it); here only the controls and the crosshair
	chips = function(e, th)
		local c = chipsCommon(e, th)
		local m = e:GetNWInt("ViewMode", 0)
		if (m == 1) then c[#c + 1] = { L("agp_hud_c_railguns", "RAIL GUNS"), th.line } elseif (m == 2) then c[#c + 1] = { L("agp_hud_c_missiles", "MISSILES"), th.line } end
		return c
	end,
	keys = { FLY, UPDOWN, BOOST, K("MODE", "agp_hud_k_mode", "Weapon mode"), FIRE, K("FIRE2", "agp_hud_k_beam", "Asgard beam"),
		K({ "1", "2", "3", "4", "5", "6", "7", "8" }, "agp_hud_k_rockets", "Missiles 1-8"), SHIELD, HYPER, EXIT } }

S.puddle_jumper = { theme = "ancient", title = { "agp_hud_n_jumper", "Puddle Jumper" }, layout = "PuddleJumper", shield = true,
	hull = function(e) local d = e.AGPJData return d and d.Health, 500 end,
	chips = function(e, th)
		local d, c = e.AGPJData or {}, chipsCommon(e, th)
		if ((d.Cloaked or e:GetNWBool("Cloaked")) and not e:GetNWBool("AGPCloaked")) then c[#c + 1] = { L("agp_hud_c_cloaked", "CLOAKED"), th.good } end
		if (d.Pods) then c[#c + 1] = { L("agp_hud_c_pods", "DRONE PODS OUT"), th.line } end
		if (d.Engine == false) then c[#c + 1] = { L("agp_hud_c_engine", "ENGINE DAMAGED"), th.bad } end
		return c
	end,
	rows = function(e, th)
		local n = (e.AGPJData or {}).Drones or 0
		return { { "bar", L("agp_hud_r_drones", "Drones"), n / 6, string.format("%d / 6", n), th.line } }
	end,
	keys = { FLY, UPDOWN, K("SPD", "agp_hud_k_drivepods", "Drive pods (fast flight)"), ROLL, K("FIRE", "agp_hud_k_drones", "Drones"), K("TRACK", "agp_hud_k_guide", "Guide drones to the crosshair (hold)"), K("WEPPODS", "agp_hud_k_pods", "Drone pods"), K("CLOAK", "agp_hud_k_cloak", "Cloak"), SHIELD,
		K("HOVER", "agp_hud_k_hover", "Hover"), K("AUTOPILOT", "agp_hud_k_auto", "Autopilot"), K("LIGHT", "agp_hud_k_light", "Lights"), K("DOOR", "agp_hud_k_door", "Doors"),
		DHD, K("HIDELSD", "agp_hud_k_lsd", "Life-signs detector"), VIEW, CAM, BOOM, EXIT } }

-- our walk-in Ha'tak (agp_hatak): flown from a plain seat (pilot chair or throne) with GMod's own keys, so the keys are
-- GMod binds / fixed keys, not a Keybinder layout. Its radar sits bottom right, so the controls go to the middle.
-- The crew status (lockdown, life support, hijacker) shows here for the helm instead of in the ship's own top-right plate.
S.agp_hatak = { noFreeLook = true, theme = "goauld", title = { "agp_hud_n_hatak", "Ha'tak" }, keysPos = "center",
	hull = function(e) return e:GetNWFloat("AGPHull", 1), 1 end,
	chips = function(e, th)
		local c = chipsCommon(e, th)
		if (e:GetNWBool("AGPLockdown")) then c[#c + 1] = { L("agp_hud_c_lockdown", "LOCKDOWN"), th.bad } end
		if (e:GetNWBool("AGPAlarm")) then c[#c + 1] = { L("agp_hud_c_alarm", "ALARM"), th.bad } end
		return c
	end,
	rows = function(e, th)
		local r = {}
		local sh, on = e:GetNWFloat("AGPShield", 100), e:GetNWBool("AGPShieldOn")
		r[#r + 1] = { "bar", L("agp_hud_shield", "Shield"), on and sh / 100 or 0, on and string.format("%d %%", math.Round(sh)) or (sh < 25 and L("agp_hud_depleted", "depleted") or L("agp_hud_off", "off")), on and th.line or (sh < 25 and th.bad or th.dim) }
		local core = e:GetNWFloat("AGPPowerCore", 1)
		r[#r + 1] = { "bar", L("agp_hud_r_core", "Power core"), core, string.format("%d %%", math.Round(core * 100)), core >= 0.5 and th.line or (core > 0 and th.warn or th.bad) }
		local cool = e:GetNWFloat("AGPHatakJumpReady", 0) - CurTime()
		local hyper, col
		if (e:GetNWBool("AGPHatakJumping")) then hyper, col = L("agp_hud_jump", "jump!"), th.line
		elseif (e:GetNWFloat("AGPPower_hyperdrive", 1) < 0.3) then hyper, col = L("agp_hud_offline", "offline"), th.bad
		elseif (cool > 0) then hyper, col = L("agp_hud_cool", "cooling %d s", math.ceil(cool)), th.warn
		else hyper, col = L("agp_hud_ready", "ready"), th.good end
		r[#r + 1] = { "text", L("agp_hud_hyper", "Hyperdrive"), hyper, col }
		local why = e:GetNWString("AGPLifeSupportWhy", "")
		if (not e:GetNWBool("AGPLifeSupport", true) and why ~= "off") then
			local wt = (why == "no power" and L("agp_hatak_ls_nopower", "no power")) or (why == "hull breached" and L("agp_hatak_ls_breach", "hull breached")) or why
			r[#r + 1] = { "text", L("agp_hud_r_lifesupport", "Life support"), wt, th.bad }
		end
		local hj = e:GetNWEntity("AGPHijacker")
		if (IsValid(hj) and hj:IsPlayer()) then r[#r + 1] = { "text", L("agp_hud_r_hijack", "Taken over by"), hj:Nick(), th.warn } end
		return r
	end,
	keys = { K({ "+forward", "+back", "+moveleft", "+moveright" }, "agp_hud_k_flyturn", "Forward / back, turn"), K({ "+jump", "+duck" }, "agp_hud_k_updown", "Up / down"),
		K("+speed", "agp_hud_k_boost", "Faster"), K("+reload", "agp_hud_k_jumpmenu", "Hyperspace jump (menu)"), K(KEY_1, "agp_hud_k_shipmenu", "Ship menu (doors, shields, weapons ...)"),
		K(KEY_V, "agp_hud_k_hatakview", "Camera: bow / behind / seat"), K({ "invprev", "invnext" }, "agp_hud_k_camdist", "Camera distance (behind view)"), K("+use", "agp_hud_k_exit", "Get out") } }

-- the MALP (remote controlled from the player): only the controls plate (F1), in the middle - its own camera screen
-- shows the readings in the corner
S.malp = { theme = "tauri", title = { "agp_hud_n_malp", "MALP" }, layout = "MALP", noStatus = true, noFreeLook = true, keysPos = "center",
	keys = { K({ "FWD", "BACK", "LEFT", "RIGHT" }, "agp_hud_k_malpdrive", "Drive / turn"), K("VIEW", "agp_hud_k_malpview", "Camera view"),
		K({ "CAMLEFT", "CAMRIGHT", "CAMUP", "CAMDOWN" }, "agp_hud_k_malpcam", "Turn the camera"), K("RESETCAM", "agp_hud_k_malpreset", "Camera straight ahead"),
		K("CONTROL", "agp_hud_k_malpstop", "Stop controlling") } }

-- the Jumper does not use "ScriptedVehicle"
HUD.Extra = HUD.Extra or {}
table.insert(HUD.Extra, function(ply)
	if (ply:GetNWBool("isFlyingjumper")) then return ply:GetNWEntity("jumper") end
end)
table.insert(HUD.Extra, function(ply)
	if (ply:GetNWBool("ControllingMALP")) then return ply:GetNWEntity("ControllingMALPEnt") end
end)
-- the Ha'tak's helm seats (pilot chair, throne) carry the ship as "AGPHatak"; the gunner seat has its own HUD
table.insert(HUD.Extra, function(ply)
	local veh = ply:GetVehicle()
	if (IsValid(veh)) then return veh:GetNWEntity("AGPHatak") end
end)

-- keys whose default changed: moved once for players who still have the old default saved
local KEY_UPDATES = {
	Dart = { { "SUCK", "MOUSE1" }, { "SPIT", "MOUSE2" }, { "FIRE", "MOUSE3" }, { "RROLL", "X" } },
	F302 = { { "BACK", "S" }, { "UP", "SPACE" }, { "DOWN", "CTRL" }, { "WHEELS", "G" }, { "BRAKE", "Q" }, { "FLARES", "F" } },
	Shuttle = { { "BACK", "S" }, { "RL", "MWHEELDOWN" }, { "RR", "MWHEELUP" }, { "RROLL", "MOUSE3" }, { "SHIELD", "G" } },
	PuddleJumper = { { "CLOAK", "C" } },   -- ALT is free look on every ship now
	Teltak = { { "CLOAK", "C" } },
	Daedalus = { { "HYPERSPACE", "H" } },
	GateGlider = { { "TORPEDO", "MOUSE2" } },
	Alkesh = { { "DHD", "R" }, { "HYPERSPACE", "H" }, { "BOMB", "MOUSE2" } },
}
for _, l in ipairs({ "Aurora", "Destiny", "Gateseeder", "Oneill", "OriMs", "Prometheus", "ReplicatorMS", "Traveler", "WraithCruiser" }) do
	KEY_UPDATES[l] = { { "DHD", "R" }, { "HYPERSPACE", "H" } }
end
local function updateKeys()
	local schemes = StarGate and StarGate.KeyBoard and StarGate.KeyBoard.Schemes
	if (not schemes) then return end
	for layout, list in pairs(KEY_UPDATES) do
		local kb = schemes[layout]
		if (kb and kb.AGPUpdateKey) then
			for _, k in ipairs(list) do kb:AGPUpdateKey(k[1], k[2], "2026-10-30") end
		end
	end
end
hook.Add("InitPostEntity", "AGP.ShipKeyUpdates", function() timer.Simple(1, updateKeys) end)

-- the old HUDs of these crafts are replaced by this one
local OLD = { "DrawHUDAlkesh", "DrawHUDAurora", "DrawHUDDestiny", "DrawHUDGateseeder", "AGP.GliderHUD", "DrawHUDOneill",
	"DrawHUDOriMs", "DrawHUDReplicateurMS", "ShuttleHUD", "TeltakHUD", "DrawHUDWraithCruiser", "F302HUD", "AGP.ShipHyperdriveHUD", "AGPJumperKeyHints" }
local function unhookOld() for _, n in ipairs(OLD) do hook.Remove("HUDPaint", n) end end
hook.Add("InitPostEntity", "AGP.ShipHUDReplace", function() unhookOld(); timer.Simple(2, unhookOld) end)
timer.Simple(5, unhookOld)
