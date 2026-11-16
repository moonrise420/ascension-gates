--[[
	Ha'tak (Ascension Gates)
	The Ha'tak hull with everything built in, placed where the 2026 Ha'tak dupe has it:
	- a ring transporter and Goa'uld ring panel on each deck (bridge, gate room, hangar); the decks are only linked by
	  the rings, as in the series. The panel's menu rings to any deck or to the nearest ring outside the ship.
	- the Stargate in the gate room
	- Goa'uld doors at the corridor entrances of the gate deck and the hangar deck, and the hangar door
	- the lower deck in the hollow pyramid under the hangar (part of the hull model, notes/hatak/rooms.py): cargo hold
	  (second Stargate in clamps behind a force field, DHD, sarcophagus), corridor, engine room (power core,
	  control-crystal trays), computer core (self-destruct console), holding cells (force fields); each room has a ring
	Everything is welded to the hull. Spawns frozen.
]]
if (StarGate ~= nil and StarGate.LifeSupportAndWire ~= nil) then StarGate.LifeSupportAndWire(ENT) end
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Ha'tak"
ENT.Author = "Ascension Gates"
ENT.Category = "Capital Ships"   -- our spawn tab (Ascension Gates > Capital Ships), not the Entities tab
if (SGLanguage ~= nil and SGLanguage.GetMessage ~= nil) then
	ENT.Category = SGLanguage.GetMessage("cat_capital_ship")
	ENT.PrintName = SGLanguage.GetMessage("ent_ship_hatak")
end
ENT.Spawnable = false
ENT.AdminSpawnable = false
list.Set("CAP.Entity", ENT.PrintName, ENT)

ENT.HullModel = "models/agp/hatak/agp_hatak_hull.mdl"   -- original hull + 2 glider exit slots (notes/hatak/hull_slots.py)
ENT.Decks = { "Bridge (pel'tak)", "Gate room", "Hangar" }
ENT.LowerDecks = { "Cargo hold", "Engine room", "Computer core", "Holding cells" }
-- TARDIS style: the walkable inside is a separate, still-standing copy (agp_hatak_interior: all decks + the lower deck
-- rooms, exact collision) somewhere free on the map; the flying hull keeps the original simple collision. Players get
-- in and out through the hangar mouth or the rings. Maps without room for it: everything on the hull, upper decks only.
ENT.HangarIn = { Vector(-760, -200, -660), Vector(-600, 200, -200) }     -- outside: walking into the hangar mouth
ENT.HangarOut = { Vector(-820, -200, -760), Vector(-700, 200, -300) }    -- inside: walking out past the hangar door
-- the hangar mouth as a see-through doorway (agp_portal): hull space, just outside the hangar door, the exact opening
ENT.HangarPortal = { pos = Vector(-612, 2, -400), w = 404, h = 400 }

-- the interior (notes/hatak/interior2.py, design.md): bigger than the hull, built room by room
ENT.InteriorModel2 = "models/agp/hatak/agp_hatak_interior2.mdl"
ENT.Decks2 = { "Hangar deck", "Pel'tak", "Gate room", "Command deck", "Engineering" }
ENT.Layout2 = {   -- generated: notes/hatak/interior2_parts.lua
	rings = { Vector(820.0, 251.0, -600.3), Vector(700.0, 376.0, 100.0), Vector(640.0, 476.0, -1400.0), Vector(700.0, -749.0, 100.0), Vector(1500.0, 251.0, -1400.0) },
	panels = { { Vector(932.0, 251.0, -538.3), 180 }, { Vector(812.0, 376.0, 162.0), 180 }, { Vector(752.0, 476.0, -1338.0), 180 }, { Vector(812.0, -749.0, 162.0), 180 }, { Vector(1612.0, 251.0, -1338.0), 180 } },
	braziers = { Vector(702.0, 133.0, -600.3), Vector(938.0, 133.0, -600.3), Vector(702.0, 369.0, -600.3), Vector(938.0, 369.0, -600.3), Vector(560.0, 45.0, -600.3), Vector(1000.0, -45.0, -600.3), Vector(1400.0, 45.0, -600.3), Vector(1512.0, -45.0, -600.3), Vector(150.0, 140.0, -600.3), Vector(150.0, -140.0, -600.3), Vector(340.0, -131.0, -600.3), Vector(1660.0, -131.0, -600.3), Vector(340.0, -1251.0, -600.3), Vector(1660.0, -1251.0, -600.3), Vector(530.0, -165.0, 100.0), Vector(530.0, 165.0, 100.0), Vector(582.0, 258.0, 100.0), Vector(818.0, 258.0, 100.0), Vector(582.0, 494.0, 100.0), Vector(818.0, 494.0, 100.0), Vector(340.0, -255.0, -1400.0), Vector(340.0, 255.0, -1400.0), Vector(1010.0, -250.0, -1400.0), Vector(1010.0, 250.0, -1400.0), Vector(620.0, -250.0, -1400.0), Vector(522.0, 358.0, -1400.0), Vector(758.0, 358.0, -1400.0), Vector(522.0, 594.0, -1400.0), Vector(758.0, 594.0, -1400.0), Vector(582.0, -867.0, 100.0), Vector(818.0, -867.0, 100.0), Vector(582.0, -631.0, 100.0), Vector(818.0, -631.0, 100.0), Vector(420.0, -955.0, 100.0), Vector(900.0, -1045.0, 100.0), Vector(1240.0, -955.0, 100.0), Vector(620.0, -1375.0, 100.0), Vector(1195.0, -1119.0, 100.0), Vector(940.0, -877.0, 100.0), Vector(1220.0, -877.0, 100.0), Vector(400.0, 253.0, -590.3), Vector(268.0, 363.0, -600.3), Vector(532.0, 363.0, -600.3), Vector(1030.0, 123.0, -600.3), Vector(1470.0, 123.0, -600.3), Vector(1382.0, 133.0, -1400.0), Vector(1618.0, 133.0, -1400.0), Vector(1382.0, 369.0, -1400.0), Vector(1618.0, 369.0, -1400.0), Vector(1330.0, -123.0, -1400.0), Vector(1700.0, -123.0, -1400.0), Vector(1380.0, 45.0, -1400.0), Vector(1820.0, -45.0, -1400.0), Vector(1730.0, 127.0, -1400.0), Vector(2270.0, 127.0, -1400.0), Vector(1850.0, -123.0, -1400.0), Vector(2270.0, -123.0, -1400.0), Vector(1850.0, -406.0, -1400.0), Vector(2270.0, -406.0, -1400.0) },
	seat = { Vector(625.0, 0.0, 100.0), -90 },
	gunnerSeat = { Vector(535.0, 125.0, 100.0), -90 },
	ents = { { "sarcophagus", Vector(470.0, -1331.0, 100.0), 90 }, { "goauld_armory", Vector(1160.0, -1271.0, 100.0), 180 }, { "naquadah_generator", Vector(1360.0, -331.0, -1400.0), 0 }, { "naquadah_generator", Vector(1715.0, -361.0, -1400.0), 180 } },
	throne = { Vector(355.0, 0.0, 132.0), 0 },
	gliders = { { Vector(850.0, -391.0, -592.3), 180 }, { Vector(850.0, -991.0, -592.3), 180 }, { Vector(1150.0, -391.0, -592.3), 0 }, { Vector(1150.0, -991.0, -592.3), 0 } },
	kelnoreem = { Vector(300.0, 253.0, -600.3), Vector(500.0, 253.0, -600.3), Vector(400.0, 161.0, -600.3), Vector(400.0, 345.0, -600.3) },
	cells = { { Vector(1802.5, 257.0, -1400.0), 153, 190, "cell 1" }, { Vector(1992.5, 257.0, -1400.0), 153, 190, "cell 2" }, { Vector(2182.5, 257.0, -1400.0), 153, 190, "cell 3" } },
	slots = { { bay = Vector(300.0, -691.0, -450.3), bayYaw = 0, hull = Vector(-1585.3, -2595.3, -510.0), hullYaw = 240.24, w = 650, h = 180 }, { bay = Vector(1700.0, -691.0, -450.3), bayYaw = 180, hull = Vector(-1588.1, 2600.1, -510.0), hullYaw = 119.76, w = 650, h = 180 } },
	-- (2026-11-10: two spots lay under a brazier - the crystal could not be seen or taken there; moved clear)
	crystalSpots = { Vector(380.0, -35.0, -600.3), Vector(1120.0, 25.0, -600.3), Vector(1600.0, -35.0, -600.3), Vector(650.0, 430.0, -600.3), Vector(920.0, 170.0, -600.3), Vector(590.0, 480.0, 100.0), Vector(790.0, 480.0, 100.0), Vector(720.0, 150.0, 100.0), Vector(560.0, 640.0, -1400.0), Vector(700.0, 650.0, -1400.0), Vector(1030.0, 120.0, -1400.0), Vector(720.0, -200.0, -1400.0), Vector(840.0, -990.0, 100.0), Vector(650.0, -1211.0, 100.0), Vector(1100.0, -1191.0, 100.0), Vector(1780.0, 25.0, -1400.0), Vector(1650.0, -141.0, -1400.0) },
	window = { pos = Vector(779.0, 0.0, 225.0), w = 280, h = 140 },
	power = { core = { Vector(1540.0, -379.0, -1379.0), Vector(1452.0, -291.0, -1379.0), Vector(1628.0, -291.0, -1379.0) }, weapons = { Vector(1328.0, -474.0, -1336.0), Vector(1358.0, -474.0, -1336.0), Vector(1388.0, -474.0, -1336.0) }, hyperdrive = { Vector(1472.0, -474.0, -1336.0), Vector(1502.0, -474.0, -1336.0), Vector(1532.0, -474.0, -1336.0) }, engines = { Vector(1590.0, -474.0, -1336.0), Vector(1620.0, -474.0, -1336.0), Vector(1650.0, -474.0, -1336.0) }, shields = { Vector(2010.0, -434.0, -1336.0), Vector(2060.0, -434.0, -1336.0), Vector(2110.0, -434.0, -1336.0) }, spare = { Vector(1761.0, -241.0, -1336.0), Vector(1761.0, -211.0, -1336.0), Vector(1761.0, -181.0, -1336.0), Vector(1761.0, -151.0, -1336.0) }, zpm = { Vector(1540.0, -203.0, -1379.0) }, rings = { Vector(939.0, -628.0, 174.0), Vector(963.0, -628.0, 174.0), Vector(987.0, -628.0, 174.0) }, doors = { Vector(1022.0, -628.0, 174.0), Vector(1046.0, -628.0, 174.0), Vector(1070.0, -628.0, 174.0) }, sensors = { Vector(1105.0, -628.0, 174.0), Vector(1129.0, -628.0, 174.0), Vector(1153.0, -628.0, 174.0) }, comms = { Vector(1188.0, -628.0, 174.0), Vector(1212.0, -628.0, 174.0), Vector(1236.0, -628.0, 174.0) } },
	props = {
	  { "door_control", Vector(902.0, 73.4, -554.3), -90, door = "ring room A" },
	  { "door_control", Vector(902.0, 92.6, -554.3), 90, door = "ring room A" },
	  { "statue_ra", Vector(1678.0, 0.0, -600.3), 180 },
	  { "door_control", Vector(-587.4, 258.0, -554.3), 0, door = "hangar" },
	  { "door_control", Vector(-587.4, -258.0, -554.3), 0, door = "hangar" },
	  { "door_control", Vector(1182.0, -73.4, -554.3), 90, door = "glider bay" },
	  { "door_control", Vector(1182.0, -92.6, -554.3), -90, door = "glider bay" },
	  { "peltac_console", Vector(690.0, 0.0, 100.0), 0, role = "pilot" },
	  { "peltac_console", Vector(590.0, 125.0, 100.0), 0, role = "weapons" },
	  { "peltac_console", Vector(590.0, -125.0, 100.0), 0, role = "navigation" },
	  { "peltac_console", Vector(740.0, -115.0, 100.0), 0, role = "command" },
	  { "door_control", Vector(470.0, -198.4, 150.0), 90, role = "crystal_slot" },
	  { "statue_horus", Vector(362.0, -145.0, 158.0), 50 },
	  { "statue_anubis", Vector(362.0, 145.0, 158.0), -50 },
	  { "door_control", Vector(618.0, 198.4, 146.0), -90, door = "ring room B (peltak)" },
	  { "door_control", Vector(618.0, 217.6, 146.0), 90, door = "ring room B (peltak)" },
	  { "door_control", Vector(722.0, 298.4, -1354.0), -90, door = "ring room C (gate room)" },
	  { "door_control", Vector(722.0, 317.6, -1354.0), 90, door = "ring room C (gate room)" },
	  { "zat_chest", Vector(556.0, -285.0, -1400.0), 90 },
	  { "zat_chest", Vector(812.0, -285.0, -1400.0), 90 },
	  { "zat_chest", Vector(500.0, 285.0, -1400.0), 90 },
	  { "zat_chest", Vector(775.0, 285.0, -1400.0), 90 },
	  { "naq_chest", Vector(885.0, -270.0, -1400.0), 90 },
	  { "naq_chest", Vector(990.0, -150.0, -1400.0), 180 },
	  { "staff_weapon", Vector(600.0, -295.0, -1400.0), 90 },
	  { "staff_weapon", Vector(615.0, -295.0, -1400.0), 90 },
	  { "staff_weapon", Vector(630.0, -295.0, -1400.0), 90 },
	  { "goauld_grenades", Vector(990.0, -196.0, -1400.0), 0 },
	  { "door_control", Vector(782.0, -926.6, 146.0), -90, door = "ring room D (command deck)" },
	  { "door_control", Vector(782.0, -907.4, 146.0), 90, door = "ring room D (command deck)" },
	  { "door_control", Vector(642.0, -1073.4, 146.0), 90, door = "Goa'uld quarters" },
	  { "door_control", Vector(642.0, -1092.6, 146.0), -90, door = "Goa'uld quarters" },
	  { "serpent_helmet", Vector(745.0, -1149.0, 140.0), 0 },
	  { "door_control", Vector(1152.0, -1073.4, 146.0), 90, door = "armoury" },
	  { "door_control", Vector(1152.0, -1092.6, 146.0), -90, door = "armoury" },
	  { "staff_weapon", Vector(950.0, -1346.0, 100.0), 90 },
	  { "staff_weapon", Vector(965.0, -1346.0, 100.0), 90 },
	  { "staff_weapon", Vector(980.0, -1346.0, 100.0), 90 },
	  { "staff_weapon", Vector(995.0, -1346.0, 100.0), 90 },
	  { "zat_chest", Vector(935.0, -1181.0, 100.0), 0 },
	  { "zat_chest", Vector(935.0, -1251.0, 100.0), 0 },
	  { "naq_chest", Vector(1150.0, -1141.0, 100.0), 0 },
	  { "goauld_grenades", Vector(1040.0, -1321.0, 100.0), 0 },
	  { "door_control", Vector(1162.0, -926.6, 146.0), -90, door = "computer core" },
	  { "door_control", Vector(1162.0, -907.4, 146.0), 90, door = "computer core" },
	  { "peltac_console", Vector(1010.0, -814.0, 100.0), 0, role = "self_destruct" },
	  { "peltac_console", Vector(1150.0, -814.0, 100.0), 0, role = "ship_log" },
	  { "peltac_console", Vector(1010.0, -724.0, 100.0), 0, role = "database" },
	  { "peltac_console", Vector(1150.0, -724.0, 100.0), 0, role = "security" },
	  { "door_control", Vector(482.0, 73.4, -554.3), -90, door = "kel'no'reem room" },
	  { "door_control", Vector(482.0, 92.6, -554.3), 90, door = "kel'no'reem room" },
	  { "door_control", Vector(1332.0, 73.4, -554.3), -90, door = "Jaffa barracks" },
	  { "door_control", Vector(1332.0, 92.6, -554.3), 90, door = "Jaffa barracks" },
	  { "goauld_grenades", Vector(1215.0, 233.0, -564.3), 0 },
	  { "serpent_helmet", Vector(1285.0, 233.0, -564.3), 0 },
	  { "peltac_console", Vector(1060.0, 186.0, -600.3), 0, role = "bunks" },
	  { "naq_chest", Vector(1460.0, 186.0, -600.3), 180, role = "armour" },
	  { "staff_weapon", Vector(1495.0, 241.0, -600.3), 0 },
	  { "staff_weapon", Vector(1495.0, 256.0, -600.3), 0 },
	  { "staff_weapon", Vector(1495.0, 271.0, -600.3), 0 },
	  { "staff_weapon", Vector(1495.0, 286.0, -600.3), 0 },
	  { "door_control", Vector(1582.0, 73.4, -1354.0), -90, door = "ring room E (engineering)" },
	  { "door_control", Vector(1582.0, 92.6, -1354.0), 90, door = "ring room E (engineering)" },
	  { "door_control", Vector(1622.0, -73.4, -1354.0), 90, door = "engine room" },
	  { "door_control", Vector(1622.0, -92.6, -1354.0), -90, door = "engine room" },
	  { "power_hub", Vector(1540.0, -291.0, -1400.0), 0, role = "power_hub" },
	  { "power_core", Vector(1540.0, -291.0, -1370.0), 0 },
	  { "peltac_console", Vector(1380.0, -181.0, -1400.0), 0, role = "engineering" },
	  { "door_control", Vector(2082.0, 73.4, -1354.0), -90, door = "holding cells" },
	  { "door_control", Vector(2082.0, 92.6, -1354.0), 90, door = "holding cells" },
	  { "door_control", Vector(1897.0, 213.4, -1338.0), -90, role = "cell", cell = 1 },
	  { "door_control", Vector(2087.0, 213.4, -1338.0), -90, role = "cell", cell = 2 },
	  { "door_control", Vector(2277.0, 213.4, -1338.0), -90, role = "cell", cell = 3 },
	  { "door_control", Vector(2142.0, -73.4, -1354.0), 90, door = "shield room" },
	  { "door_control", Vector(2142.0, -92.6, -1354.0), -90, door = "shield room" },
	  { "peltac_console", Vector(1890.0, -181.0, -1400.0), 0, role = "shields" },
	},
	gate = { Vector(400.0, 0.0, -1211.0), 0 },
	dhd = { Vector(900.0, 170.0, -1400.0), 200 },
	doors = {
	  { pos = Vector(-598, 0, -600), w = 408, h = 404, thick = 16, hangar = true, name = "hangar" },
	  { pos = Vector(220, 3.5, -600.3), w = 112, h = 113, name = "hangar back door" },
	  { pos = Vector(820.0, 83.0, -600.3), w = 120, h = 140, yaw = 90, name = "ring room A" },
	  { pos = Vector(1100.0, -83.0, -600.3), w = 120, h = 140, yaw = 90, name = "glider bay" },
	  { pos = Vector(700.0, 208.0, 100.0), w = 120, h = 140, yaw = 90, name = "ring room B (peltak)" },
	  { pos = Vector(640.0, 308.0, -1400.0), w = 120, h = 140, yaw = 90, name = "ring room C (gate room)" },
	  { pos = Vector(700.0, -917.0, 100.0), w = 120, h = 140, yaw = 90, name = "ring room D (command deck)" },
	  { pos = Vector(560.0, -1083.0, 100.0), w = 120, h = 140, yaw = 90, name = "Goa'uld quarters" },
	  { pos = Vector(1070.0, -1083.0, 100.0), w = 120, h = 140, yaw = 90, name = "armoury" },
	  { pos = Vector(1080.0, -917.0, 100.0), w = 120, h = 140, yaw = 90, name = "computer core" },
	  { pos = Vector(400.0, 83.0, -600.3), w = 120, h = 140, yaw = 90, name = "kel'no'reem room" },
	  { pos = Vector(1250.0, 83.0, -600.3), w = 120, h = 140, yaw = 90, name = "Jaffa barracks" },
	  { pos = Vector(1500.0, 83.0, -1400.0), w = 120, h = 140, yaw = 90, name = "ring room E (engineering)" },
	  { pos = Vector(1540.0, -83.0, -1400.0), w = 120, h = 140, yaw = 90, name = "engine room" },
	  { pos = Vector(2000.0, 83.0, -1400.0), w = 120, h = 140, yaw = 90, name = "holding cells" },
	  { pos = Vector(2060.0, -83.0, -1400.0), w = 120, h = 140, yaw = 90, name = "shield room" },
	},
}

-- hull-space layout (the hull's own axes; +X = the pyramid's front)
ENT.Layout = {
	rings = { Vector(69.5, 6.8, 384.9), Vector(-279.6, 2.2, -39.1), Vector(576, 3.5, -600),
		Vector(-600, 250, -1060), Vector(-20, -540, -960), Vector(-270, 540, -960), Vector(480, 0, -960) },
	panels = { { Vector(-23.5, 3, 416.7), 2.1 }, { Vector(-193.2, -40.9, -30.6), 161.7 }, { Vector(578.1, -88.2, -581.1), 91.6 },
		{ Vector(-697, 370, -1020), 0 }, { Vector(57, -460, -920), 180 }, { Vector(-180, 657, -920), -90 }, { Vector(423, -150, -920), 0 } },
	gate = { Vector(-394.5, 2.9, -8.2), 0 },
	seat = { Vector(-235, 10, 386), -90 },   -- pilot seat on the pel'tak, facing the front
	doors = {
		{ pos = Vector(220, 2, -40), w = 112, h = 113, name = "gate deck corridor" },
		{ pos = Vector(220, 4, -600), w = 112, h = 113, name = "hangar deck corridor" },
		{ pos = Vector(-598, 0, -600), w = 408, h = 404, thick = 16, hangar = true, name = "hangar" },
		{ pos = Vector(-488, 600, -960), w = 112, h = 113, name = "cargo hold" },
		{ pos = Vector(-382, -540, -960), w = 112, h = 113, name = "engine room" },
		{ pos = Vector(-382, 540, -960), w = 112, h = 113, name = "computer core" },
	},
	-- lower deck
	cargoGate = { Vector(-640, -400, -1028), 0 },
	cargoDHD = { Vector(-530, -110, -1060), 200 },
	sarcophagus = { Vector(-600, 20, -1060), 90 },
	fields = {   -- { pos (bottom centre), yaw, width, height, name }
		{ Vector(-585, -400, -1060), 0, 300, 262, "cargo gate" },
		{ Vector(558, -160, -960), 0, 148, 260, "cell 1" },
		{ Vector(558, 0, -960), 0, 148, 260, "cell 2" },
		{ Vector(558, 160, -960), 0, 148, 260, "cell 3" },
	},
	selfDestruct = { Vector(-178, 540, -960), 180 },   -- console in front of the computer core
}

-- staff cannon points on the hull (shared: the gunner's view is made on the client)
ENT.Cannons = {   -- hull space: where the staff blasts leave the hull, and which way that cannon looks out
	{ pos = Vector(0, 0, 1400), out = Vector(0, 0, 1) },          -- 1 top
	{ pos = Vector(1450, 0, 250), out = Vector(1, 0, 0.3) },      -- 2 front
	{ pos = Vector(400, 1350, 300), out = Vector(0, 1, 0.2) },    -- 3 left side
	{ pos = Vector(400, -1350, 300), out = Vector(0, -1, 0.2) },  -- 4 right side
	{ pos = Vector(-1500, 2500, -450), out = Vector(-0.4, 1, 0) },  -- 5 rear arm left
	{ pos = Vector(-1500, -2500, -450), out = Vector(-0.4, -1, 0) }, -- 6 rear arm right
	{ pos = Vector(800, 0, -1300), out = Vector(0.3, 0, -1) },    -- 7 bottom
}
-- the ship's front is the hangar side (-X of the hull model; owner 2026-10-24): FrontYaw turns "forward" around
ENT.FrontYaw = 180
ENT.CannonGroups = { { "Top", { 1 } }, { "Front", { 5, 6 } }, { "Sides", { 3, 4 } }, { "Rear", { 2 } }, { "Bottom", { 7 } } }

local hkTell   -- (set below: one player's message in their language)
if SERVER then
	AddCSLuaFile()
	util.AddNetworkString("AGP_HatakRingMenu")
	util.AddNetworkString("AGP_HatakRingGo")
	util.AddNetworkString("AGP_HatakJumpMenu")
	util.AddNetworkString("AGP_HatakJumpGo")
	-- AGP 2026-11-10: the ship's messages in each player's own language (lua/data/language/*/stargate_agp.lua, keys
	-- agp_hkm_*): the server sends the key, the English text and the values; a value that is itself a key
	-- ("agp_hkm_p_weapons", or "key<31>value" for one with its own value) is translated on the player's side too.
	-- The ship log keeps the English line as well (the server and the tests read it).
	util.AddNetworkString("AGP_HatakSay")
	local HKM_EN = {
		["agp_hkm_c_w_auto"] = "auto",
		["agp_hkm_c_w_defend"] = "defend",
		["agp_hkm_c_w_off"] = "off",
		["agp_hkm_k_burnt"] = "a burnt power crystal",
		["agp_hkm_k_data"] = "a data crystal",
		["agp_hkm_k_power"] = "a power crystal",
		["agp_hkm_p_comms"] = "communication",
		["agp_hkm_p_core"] = "power core",
		["agp_hkm_p_doors"] = "doors",
		["agp_hkm_p_engines"] = "sublight engines",
		["agp_hkm_p_hyperdrive"] = "hyperdrive",
		["agp_hkm_p_rings"] = "ring transporters",
		["agp_hkm_p_sensors"] = "sensors",
		["agp_hkm_p_shields"] = "shields",
		["agp_hkm_p_spare"] = "spare rack",
		["agp_hkm_p_weapons"] = "weapons",
		["agp_hkm_p_zpm"] = "fourth arm of the hub",
		["agp_hkm_r_blast"] = "explosion aboard",
		["agp_hkm_r_hull"] = "hull damage",
		["agp_hkm_r_intruder"] = "intruder at the crystal slot",
		["agp_hkm_r_ls"] = "life support failed",
		["agp_hkm_r_raised"] = "raised by %s",
		["agp_hkm_r_sabotage"] = "sabotage: %s pulls crystals",
		agp_hatak_ls_nopower = "no power", agp_hatak_ls_breach = "hull breached",
	}
	local function hkmArgEN(a)
		if (not isstring(a)) then return a end
		local parts = string.Explode("\31", a)
		local key = parts[1]
		if (HKM_EN[key]) then
			table.remove(parts, 1)
			local ok, t = pcall(string.format, HKM_EN[key], unpack(parts))
			return ok and t or HKM_EN[key]
		end
		return a
	end
	local function hkmEnglish(fallback, args)
		local en = {}
		for i, a in ipairs(args) do en[i] = hkmArgEN(a) end
		local ok, t = pcall(string.format, fallback, unpack(en))
		return ok and t or fallback
	end
	local function hkSend(to, where, key, fallback, args, center)
		net.Start("AGP_HatakSay")
		net.WriteString(where or ""); net.WriteString(key); net.WriteString(fallback)
		net.WriteUInt(#args, 4)
		for _, a in ipairs(args) do net.WriteString(tostring(a)) end
		net.WriteBool(center and true or false)
		net.Send(to)
	end
	-- one player, in the chat ("[Ha'tak] ...")
	hkTell = function(ply, key, fallback, ...)
		if (IsValid(ply) and ply:IsPlayer()) then hkSend(ply, "", key, fallback, { ... }, false) end
	end

	local function fakeTrace(pos)
		return { Hit = true, HitPos = pos, HitNormal = Vector(0, 0, 1), Entity = game.GetWorld(), HitWorld = true, StartPos = pos + Vector(0, 0, 50) }
	end

	-- spawn a pack entity the way the spawn menu does (keeps its own defaults, e.g. the gate's random address)
	local function spawnPart(ply, class, pos)
		local stored = scripted_ents.GetStored(class)
		local e
		if (stored and stored.t.SpawnFunction) then e = stored.t:SpawnFunction(ply, fakeTrace(pos), class) end
		if (not IsValid(e)) then
			e = ents.Create(class)
			if (not IsValid(e)) then return end
			e:SetPos(pos); e:Spawn(); e:Activate()
		end
		return e
	end

	-- unused ring address made of the panel's glyphs 1-5, no glyph twice
	local function freeRingAddress()
		local used = {}
		for _, v in ipairs(ents.FindByClass("ring_base_*")) do if (v.Address) then used[v.Address] = true end end
		for a = 1, 5 do for b = 1, 5 do for c = 1, 5 do
			if (a ~= b and b ~= c and a ~= c) then
				local s = a .. b .. c
				if (not used[s]) then return s end
			end
		end end end
	end

	function ENT:SpawnFunction(ply, tr)
		local e = ents.Create("agp_hatak")
		local yaw = ply:EyeAngles().y
		e:SetAngles(Angle(0, yaw + (self.FrontYaw or 180), 0))   -- its front (hangar side) looks where the player looks
		if (tr.Hit) then
			e:SetPos(tr.HitPos + Vector(0, 0, 1700))   -- the hull reaches ~1680 below its origin
		else   -- aimed at the sky: in the air in front of the player (it hovers, frozen)
			e:SetPos(ply:EyePos() + Angle(0, yaw, 0):Forward() * 4000)
		end
		if (StarGate and StarGate.SpawnClear) then StarGate.SpawnClear(ply, e, 3300) end   -- not on top of the player
		e.Owner = ply
		e:Spawn(); e:Activate()
		if (e.CPPISetOwner) then e:CPPISetOwner(ply) end
		e:BuildInterior(ply)
		return e
	end

	function ENT:Initialize()
		self:SetModel(self.HullModel)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false); ph:SetMass(50000) end
		self.Parts = {}
		self.Rings = {}
		self.NoDissolve = true
		self:StartMotionController()
		local hc = GetConVar("agp_hatak_health")
		self.MaxHealth = hc and hc:GetInt() or 100000   -- hull health (admin settings; EntHealth / MaxHealth: the repair tool)
		self.EntHealth = self.MaxHealth
		self:SetNWFloat("AGPHull", 1)
		self.WireCtl = {}
		if (self.CreateWireInputs) then
			self:CreateWireInputs("Fly", "Forward", "Up", "Turn", "Boost", "Jump", "Jump Target [VECTOR]", "Shield", "Cloak")
			self:CreateWireOutputs("Flying", "Speed", "Pilot [ENTITY]", "Charging", "Power", "Weapons Power", "Hyperdrive Power", "Engines Power", "Shield", "Shield Strength", "Cloaked", "Hull", "Hull %", "Life Support")
		end
	end

	function ENT:AddPart(e)
		if (not IsValid(e)) then return end
		e.AGPShip = self
		e.NoDissolve = true   -- the kawoosh of the gate aboard never dissolves or hurts the ship
		if (self.CPPIGetOwner and e.CPPISetOwner and IsValid(self:CPPIGetOwner())) then e:CPPISetOwner(self:CPPIGetOwner()) end
		e.Owner = e.Owner or self.Owner
		if (IsValid(self.Interior)) then
			table.insert(self.Interior.Hidden, e)   -- stands still in the interior, hidden together with it
		else
			constraint.Weld(e, self, 0, 0, 0, true, false)
		end
		local ph = e:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(false) end
		self.Parts[#self.Parts + 1] = e
		return e
	end

	function ENT:Frame() return IsValid(self.Interior) and self.Interior or self end

	function ENT:Place(e, lpos, lyaw)
		local fr = self:Frame()
		e:SetPos(fr:LocalToWorld(lpos))
		e:SetAngles(fr:LocalToWorldAngles(Angle(0, lyaw or 0, 0)))
	end

	-- free space for the interior: high up, far from the ship (it is hidden from players who are not near it)
	function ENT:FindInteriorSpot()
		local mn, mx = game.GetWorld():GetModelBounds()
		local hb = self.HullBox
		local best
		for z = mx.z - hb[2].z - 200, mn.z - hb[1].z + 200, -2000 do
			for x = mn.x - hb[1].x + 500, mx.x - hb[2].x - 500, 3500 do
				for y = mn.y - hb[1].y + 500, mx.y - hb[2].y - 500, 3500 do
					local p = Vector(x, y, z)
					if (p:Distance(self:GetPos()) > 9000 and self:SpotIsFree(p)) then return p end
				end
			end
		end
	end

	-- the interior: all rooms of interior2.py
	function ENT:BuildInteriorV2(ply, spot)
		local L = self.Layout2
		local it = ents.Create("agp_hatak_interior")
		it.InteriorModel = self.InteriorModel2
		it:SetPos(spot); it:SetAngles(Angle(0, 0, 0)); it:Spawn(); it:Activate()
		it.AGPShip = self
		it.NoDissolve = true
		if (it.CPPISetOwner and IsValid(ply)) then it:CPPISetOwner(ply) end
		self.Interior = it
		self:SetNWEntity("AGPInterior", it)
		self:BuildHangarPortal()
		self:BuildWindow()
		self.Decks = table.Copy(self.Decks2)
		for i, lp in ipairs(L.rings) do
			local r = spawnPart(ply, "ring_base_goauld", self:Frame():LocalToWorld(lp))
			if (IsValid(r)) then
				self:Place(r, lp, 0)
				local adr = freeRingAddress()
				if (adr and r.SetRingAddress) then r:SetRingAddress(adr) end
				r.AGPDeck = i
				self.Rings[i] = self:AddPart(r)
			end
			local pd = L.panels[i]
			local p = spawnPart(ply, "ring_panel_goauld", self:Frame():LocalToWorld(pd[1]))
			if (IsValid(p)) then
				self:Place(p, pd[1], pd[2])
				p.AGPDeck = i
				p.Use = function(pan, user) if (IsValid(self)) then self:OpenRingMenu(user, pan) end end
				self:AddPart(p)
			end
		end
		-- Stargate + DHD in the gate room, pilot seat on the pel'tak
		if (L.gate) then
			local g = spawnPart(ply, "stargate_sg1", self:Frame():LocalToWorld(L.gate[1]))
			if (IsValid(g)) then
				self:Place(g, L.gate[1], L.gate[2]); self.Gate = self:AddPart(g)
				timer.Simple(0.2, function()
					if (IsValid(g) and (g:GetGateAddress() or "") == "" and StarGate.RandomGateName) then StarGate.RandomGateName(nil, g, nil, true) end
				end)
			end
		end
		if (L.dhd) then
			local d = spawnPart(ply, "dhd_sg1", self:Frame():LocalToWorld(L.dhd[1]))
			if (IsValid(d)) then self:Place(d, L.dhd[1], L.dhd[2]); self:AddPart(d) end
		end
		if (L.seat) then
			local seat = ents.Create("prop_vehicle_prisoner_pod")
			if (IsValid(seat)) then
				-- the gold pharaoh chair is the vehicle itself (lua/autorun/agp_seats.lua): Wire pod controllers can link it
				local sv = list.Get("Vehicles").agp_seat_pharaoh
				seat:SetModel(sv.Model)
				seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
				seat:SetKeyValue("limitview", "0")
				seat.HandleAnimation = sv.Members.HandleAnimation
				self:Place(seat, L.seat[1], L.seat[2])
				seat:Spawn(); seat:Activate()
				seat.AGPHatakSeat = true
				seat:SetNWEntity("AGPHatak", self)
				self.Seat = self:AddPart(seat)
			end
		end
		for _, bp in ipairs(L.braziers or {}) do
			local b = ents.Create("agp_brazier")
			if (IsValid(b)) then self:Place(b, bp, 0); b:Spawn(); b:Activate(); self:AddPart(b) end
		end
		local doorByName = {}
		for _, d in ipairs(L.doors) do
			local e = ents.Create("agp_goauld_door")
			if (IsValid(e)) then
				e:Setup(d.w, d.h, d.thick or 10, d.hangar)
				self:Place(e, d.pos, d.yaw or 0)
				e:Spawn(); e:Activate()
				e.Owner = ply
				e.AGPDoorName = d.name
				self:AddPart(e)
				doorByName[d.name] = e
				if (d.hangar) then self:BuildHullHangarDoor(e, d) end
			end
		end
		-- furnishings (Sketchfab models): consoles, throne, chests; door panels open their door with E
		for _, pd in ipairs(L.props or {}) do
			local e = ents.Create(pd[1] == "power_core" and "agp_goauld_power_core" or "agp_hatak_prop")   -- the core column pulses
			if (IsValid(e)) then
				e.PropModel = "models/agp/hatak/props/" .. pd[1] .. ".mdl"
				self:Place(e, pd[2], pd[3])
				e:Spawn(); e:Activate()
				e.AGPPropName = pd[1]
				if (pd[1] == "power_core") then self.CoreColumn = e end
				e.AGPRole = pd.role
				if (pd.role == "pilot") then          -- pilot console: E takes the pilot seat behind it
					e.OnUse = function(_, user)
						if (not self:MayCommand(user)) then hkTell(user, "agp_hkm_t_pilot_crew", "The pilot console does not answer you (crew only).") return end
						if (IsValid(self.Seat) and not IsValid(self.Seat:GetDriver()) and not user:InVehicle()) then user:EnterVehicle(self.Seat) end
					end
				elseif (pd.role == "crystal_slot") then -- control crystal slot (hijacking)
					e.OnUse = function(slot, user) self:CrystalSlotUse(user, slot) end
				elseif (pd.role == "weapons") then    -- weapons console: radar, targets, staff cannon volleys
					e.OnUse = function(_, user) self:OpenWeapons(user) end
				elseif (pd.role == "self_destruct" or pd.role == "ship_log" or pd.role == "database" or pd.role == "security") then
					e.OnUse = function(_, user) self:OpenComputer(user, pd.role) end   -- computer core consoles
				elseif (pd.role == "cell") then        -- holding cell panel: force field on/off (crew)
					e.OnUse = function(_, user) self:CellUse(user, pd.cell) end
				elseif (pd.role == "command") then     -- pel'tak command console: every system's window from the bridge
					e.OnUse = function(_, user) self:SendCommand(user) end
				elseif (pd.role == "shields") then     -- shield console
					e.OnUse = function(_, user) self:OpenComputer(user, "shields") end
				elseif (pd.role == "bunks") then       -- barracks: sleep here = respawn aboard (crew)
					self.BunkConsole = e
					e.OnUse = function(_, user) self:BunkUse(user) end
				elseif (pd.role == "armour") then      -- barracks: Jaffa armour
					e.OnUse = function(_, user) self:ArmourUse(user) end
				elseif (pd.role == "engineering") then -- engineering console: power monitor and routing
					e.OnUse = function(_, user) self:OpenPower(user) end
				elseif (pd.role == "power_hub") then   -- the power core's hub: crystals go onto its arms
					e.OnUse = function(_, user)
						if (IsValid(user.AGPPowerCarry)) then return end   -- the KeyPress hook puts the carried crystal in
						local n, total = self:CrystalsGood("core")
						local on = self:Generators()
						hkTell(user, "agp_hkm_t_core", "Power core %d %% (%d of %d crystals, naquadah generators running: %d)", math.Round(self:CorePower() * 100), n, total, on)
					end
				elseif (pd.role == "navigation") then -- navigation console: hyperspace jump menu
					e.OnUse = function(_, user)
						if (not self:MayCommand(user)) then hkTell(user, "agp_hkm_t_nav_crew", "The navigation console does not answer you (crew only).") return end
						self.NavUsers = self.NavUsers or {}
						self.NavUsers[user] = CurTime()
						self:OpenJumpMenu(user)
					end
				end
				local give = ({ staff_weapon = "weapon_staff", zat_chest = "weapon_zat" })[pd[1]]
				if (give) then e.OnUse = function(prop, user) self:TakeWeapon(prop, user, give) end end
				if (pd.door) then
					local door = doorByName[pd.door]
					e.AGPDoorName = pd.door
					e.OnUse = function(_, user) if (IsValid(door)) then self:DoorPanelUse(door, user) end end
				end
				self:AddPart(e)
			end
		end
		-- gunner seat behind the weapons console: sitting down = manual gunner, standing up ends it
		if (L.gunnerSeat) then
			local sv = list.Get("Vehicles").agp_seat_pharaoh
			local seat = ents.Create("prop_vehicle_prisoner_pod")
			if (IsValid(seat)) then
				seat:SetModel(sv.Model)
				seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
				seat:SetKeyValue("limitview", "0")
				seat.HandleAnimation = sv.Members.HandleAnimation
				self:Place(seat, L.gunnerSeat[1], L.gunnerSeat[2])
				seat:Spawn(); seat:Activate()
				seat.AGPGunnerSeatOf = self
				self.GunnerSeat = self:AddPart(seat)
			end
		end
		-- working pack entities in the rooms (sarcophagus, armoury, naquadah generators): frozen, standing on the floor
		for _, ed in ipairs(L.ents or {}) do
			local e = ents.Create(ed[1])
			if (IsValid(e)) then
				self:Place(e, ed[2], ed[3])
				e:Spawn(); e:Activate()
				e:SetPos(e:GetPos() + e:GetUp() * -e:OBBMins().z)
				e.Owner = ply
				if (e.CPPISetOwner and IsValid(ply)) then e:CPPISetOwner(ply) end
				e.AGPEntName = ed[1]
				self:AddPart(e)
			end
		end
		-- the throne is a real seat as well (Goa'uld Throne vehicle)
		if (L.throne) then
			local tv = list.Get("Vehicles").agp_seat_throne
			local seat = ents.Create("prop_vehicle_prisoner_pod")
			if (IsValid(seat)) then
				seat:SetModel(tv.Model)
				seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
				seat:SetKeyValue("limitview", "0")
				seat.HandleAnimation = tv.Members.HandleAnimation
				self:Place(seat, L.throne[1], L.throne[2] - 90)
				seat:Spawn(); seat:Activate()
				seat.AGPThroneSeat = true
				seat:SetNWEntity("AGPHatak", self)   -- the throne is a helm too (pilot HUD, camera, hyperspace)
				self.ThroneSeat = self:AddPart(seat)
			end
		end
		self:SetNWInt("AGPRings", #self.Rings)
		self:StartWeaponsTimer()
		self:SpawnCrystal()
		self:BuildPower()
		self:BuildGliderBay(ply)
		self:BuildCells(ply)
	end

	-- holding cells: a force field closes each cell; crew switches it at the panel beside the cell (or on the field)
	function ENT:BuildCells(ply)
		self.CellFields = {}
		for i, c in ipairs(self.Layout2.cells or {}) do
			local e = ents.Create("agp_force_field")
			if (IsValid(e)) then
				e:Setup(c[2], c[3])
				self:Place(e, c[1], 90)
				e:Spawn(); e:Activate()
				e.Owner = ply
				e.AGPFieldName = c[4]
				local use = e.Use
				e.Use = function(f, user, ...)   -- prisoners do not switch their own field off
					if (IsValid(user) and user:IsPlayer() and not self:IsCrew(user)) then hkTell(user, "agp_hkm_t_field", "The force field does not answer you.") return end
					return use(f, user, ...)
				end
				self.CellFields[i] = self:AddPart(e)
			end
		end
	end
	function ENT:CellUse(ply, i)
		local f = self.CellFields and self.CellFields[i]
		if (not IsValid(f)) then return end
		if (not self:IsCrew(ply)) then hkTell(ply, "agp_hkm_t_cell_crew", "The cell panel does not answer you (crew only).") return end
		f:SetOnState(not f:GetOn())
		f:EmitSound(f:GetOn() and "button/ring_button1.mp3" or "button/ring_button2.mp3", 70)
		self:LogL(f:GetOn() and "agp_hkm_l_cell_closed" or "agp_hkm_l_cell_opened", f:GetOn() and "%s closed %s" or "%s opened %s", ply:Nick(), f.AGPFieldName or "a cell")
	end

	-- glider bay: the two hull slots are doorways into the bay's launch tunnels (a map carries them across the
	-- interior); 4 Death Gliders wait frozen on their rack pads (E = board and fly), a lost one comes back after a while
	-- (admin settings agp_hatak_glider_respawn on/off, agp_hatak_glider_respawn_time seconds, default 60)
	function ENT:BuildGliderBay(ply)
		local L = self.Layout2
		if (not L.slots or not IsValid(self.Interior)) then return end
		self.SlotPortals = {}
		for _, sl in ipairs(L.slots) do
			local function make(frame, pos, yaw)
				local p = ents.Create("agp_portal")
				p:SetPos(frame:LocalToWorld(pos)); p:SetAngles(frame:LocalToWorldAngles(Angle(0, yaw, 0)))
				p:SetPortalWidth(sl.w); p:SetPortalHeight(sl.h)
				p:Spawn(); p:SetParent(frame)
				return p
			end
			local out, inn = make(self, sl.hull, sl.hullYaw), make(self.Interior, sl.bay, sl.bayYaw)
			out:SetExit(inn); out:SetFrameSelf(self); out:SetFrameExit(self.Interior)
			inn:SetExit(out); inn:SetFrameSelf(self.Interior); inn:SetFrameExit(self)
			out:SetMapTo(sl.hull, sl.hullYaw, sl.bay, sl.bayYaw)
			inn:SetMapInverseOf(out)
			table.insert(self.SlotPortals, out); table.insert(self.SlotPortals, inn)
			self:BuildSlotDoors(sl, #self.SlotPortals / 2)
		end
		self.GliderPads = {}
		for i, g in ipairs(L.gliders or {}) do
			self.GliderPads[i] = { pos = g[1], yaw = g[2] }
			self:SpawnGlider(i, ply)
		end
		local id = "AGPHatakGliders" .. self:EntIndex()
		timer.Create(id, 5, 0, function()
			if (not IsValid(self)) then timer.Remove(id) return end
			for i, pad in ipairs(self.GliderPads) do
				if (not IsValid(pad.glider)) then
					pad.lostAt = pad.lostAt or CurTime()
					local on, wait = GetConVar("agp_hatak_glider_respawn"), GetConVar("agp_hatak_glider_respawn_time")
					if ((not on or on:GetBool()) and CurTime() - pad.lostAt >= (wait and wait:GetInt() or 60)) then self:SpawnGlider(i) end
				end
			end
		end)
	end
	-- the launch slots get hangar doors like the hangar: one in the glider bay in front of the slot, its twin outside on
	-- the hull; they open and close together (master menu, E on a door), and open by themselves for a glider flying at them
	ENT.SlotDoorGap = 16
	function ENT:BuildSlotDoors(sl, k)
		local name = k == 1 and "glider slot left" or "glider slot right"
		local function make(frame, pos, yaw, parent)
			local e = ents.Create("agp_goauld_door")
			if (not IsValid(e)) then return end
			e:Setup(sl.w + 8, sl.h + 8, 12, true)
			local f = Angle(0, yaw, 0):Forward()
			e:SetPos(frame:LocalToWorld(pos + f * self.SlotDoorGap - Vector(0, 0, sl.h / 2 + 4))); e:SetAngles(frame:LocalToWorldAngles(Angle(0, yaw, 0)))
			e:Spawn(); e:Activate()
			local ph = e:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(false) end
			e.AGPDoorName = name
			return e
		end
		local inner = make(self.Interior, sl.bay, sl.bayYaw)
		if (not IsValid(inner)) then return end
		self:AddPart(inner)
		local outer = make(self, sl.hull, sl.hullYaw)
		if (IsValid(outer)) then
			outer:SetParent(self)
			outer.AGPShip, outer.NoDissolve, outer.AGPOuterTwin = self, true, true
			outer.AGPDoorName = name .. " (outside)"
			if (outer.CPPISetOwner and IsValid(self:ShipOwner())) then outer:CPPISetOwner(self:ShipOwner()) end
			outer.AGPTwin, inner.AGPTwin = inner, outer
			self.Parts[#self.Parts + 1] = outer
		end
		self.SlotDoors = self.SlotDoors or {}
		table.insert(self.SlotDoors, { inner = inner, outer = outer })
	end
	function ENT:SlotDoorsThink()   -- a piloted glider close to a closed slot door: it opens
		if ((self.NextSlotCheck or 0) > CurTime()) then return end
		self.NextSlotCheck = CurTime() + 0.5
		for _, sd in ipairs(self.SlotDoors or {}) do
			local d = sd.inner
			if (IsValid(d) and not d:GetOpened() and not d:GetLocked()) then
				for _, g in ipairs(ents.FindByClass("sg_vehicle_glider")) do
					if (IsValid(g.Pilot) and ((g:GetPos():DistToSqr(d:GetPos()) < 800 * 800) or (IsValid(sd.outer) and g:GetPos():DistToSqr(sd.outer:GetPos()) < 800 * 800))) then
						d:SetDoorOpen(true)
						break
					end
				end
			end
		end
	end

	function ENT:SpawnGlider(i, ply)
		local pad = self.GliderPads[i]
		local g = ents.Create("sg_vehicle_glider")
		if (not IsValid(g)) then return end
		self:Place(g, pad.pos, pad.yaw)
		g:Spawn(); g:Activate()
		local ph = g:GetPhysicsObject()
		if (IsValid(ph)) then ph:EnableMotion(false) end   -- waits on its pad; boarding unfreezes it
		local own = IsValid(ply) and ply or self:ShipOwner()
		if (g.CPPISetOwner and IsValid(own)) then g:CPPISetOwner(own) end
		g.Owner = own
		g.AGPGliderOf = self
		pad.glider, pad.lostAt = g, nil
		return g
	end

	function ENT:BuildInterior(ply)
		local L = self.Layout
		local spot = self:FindInteriorSpot()
		if (spot) then return self:BuildInteriorV2(ply, spot) end
		-- no free room on the map for the interior: the upper decks on the hull itself
		self.Decks = table.Copy(self.Decks)   -- the class list, then this ship's own
		self.LowerDeckOn = false
		-- rings and panels, one per deck
		for i, lp in ipairs(L.rings) do
			if (i > #self.Decks) then break end
			local r = spawnPart(ply, "ring_base_goauld", self:Frame():LocalToWorld(lp))
			if (IsValid(r)) then
				self:Place(r, lp, 0)
				local adr = freeRingAddress()
				if (adr and r.SetRingAddress) then r:SetRingAddress(adr) end
				r.AGPDeck = i
				self.Rings[i] = self:AddPart(r)
			end
			local pd = L.panels[i]
			local p = spawnPart(ply, "ring_panel_goauld", self:Frame():LocalToWorld(pd[1]))
			if (IsValid(p)) then
				self:Place(p, pd[1], pd[2])
				p.AGPDeck = i
				p.Use = function(pan, user) if (IsValid(self)) then self:OpenRingMenu(user, pan) end end
				self:AddPart(p)
			end
		end
		-- the Stargate in the gate room
		local g = spawnPart(ply, "stargate_sg1", self:Frame():LocalToWorld(L.gate[1]))
		if (IsValid(g)) then
			self:Place(g, L.gate[1], L.gate[2]); self.Gate = self:AddPart(g)
			-- an address like the gate tool gives one (the spawn menu path leaves it empty)
			timer.Simple(0.2, function()
				if (IsValid(g) and (g:GetGateAddress() or "") == "" and StarGate.RandomGateName) then StarGate.RandomGateName(nil, g, nil, true) end
			end)
		end
		-- doors
		for _, d in ipairs(L.doors) do
			if (d.pos.z < -700 and not self.LowerDeckOn) then continue end
			local e = ents.Create("agp_goauld_door")
			if (IsValid(e)) then
				e:Setup(d.w, d.h, d.thick or 10, d.hangar)
				self:Place(e, d.pos, 0)
				e:Spawn(); e:Activate()
				e.Owner = ply
				e.AGPDoorName = d.name
				self:AddPart(e)
			end
		end
		if (self.LowerDeckOn) then self:BuildLowerDeck(ply) end
		-- pilot seat on the pel'tak
		local seat = ents.Create("prop_vehicle_prisoner_pod")
		if (IsValid(seat)) then
			seat:SetModel("models/nova/airboat_seat.mdl")
			seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
			self:Place(seat, L.seat[1], L.seat[2])
			seat:Spawn(); seat:Activate()
			seat.AGPHatakSeat = true
			seat:SetNWEntity("AGPHatak", self)
			self.Seat = self:AddPart(seat)
		end
		self:SetNWInt("AGPRings", #self.Rings)
	end

	-- the lower deck's furniture (the rooms themselves are part of the hull model)
	function ENT:BuildLowerDeck(ply)
		local L = self.Layout
		local g = spawnPart(ply, "stargate_sg1", self:Frame():LocalToWorld(L.cargoGate[1]))
		if (IsValid(g)) then
			self:Place(g, L.cargoGate[1], L.cargoGate[2]); self.CargoGate = self:AddPart(g)
			timer.Simple(0.2, function()
				if (IsValid(g) and (g:GetGateAddress() or "") == "" and StarGate.RandomGateName) then StarGate.RandomGateName(nil, g, nil, true) end
			end)
		end
		local d = spawnPart(ply, "dhd_sg1", self:Frame():LocalToWorld(L.cargoDHD[1]))
		if (IsValid(d)) then self:Place(d, L.cargoDHD[1], L.cargoDHD[2]); self:AddPart(d) end
		local s = spawnPart(ply, "sarcophagus", self:Frame():LocalToWorld(L.sarcophagus[1]))
		if (IsValid(s)) then self:Place(s, L.sarcophagus[1], L.sarcophagus[2]); self:AddPart(s) end
		self.Fields = {}
		for _, f in ipairs(L.fields) do
			local e = ents.Create("agp_force_field")
			if (IsValid(e)) then
				e:Setup(f[3], f[4])
				self:Place(e, f[1], f[2])
				e:Spawn(); e:Activate()
				e.Owner = ply
				e.AGPFieldName = f[5]
				self.Fields[#self.Fields + 1] = self:AddPart(e)
			end
		end
		local c = ents.Create("agp_hatak_console")
		if (IsValid(c)) then
			self:Place(c, L.selfDestruct[1], L.selfDestruct[2])
			c:Spawn(); c:Activate()
			c:SetNWString("Label", "Self-destruct")
			c.OnUse = function(con, user) if (IsValid(self)) then self:ToggleSelfDestruct(user) end end
			self.SelfDestructConsole = self:AddPart(c)
		end
	end

	--################# Self-destruct from the computer core: E starts the countdown, E again aborts it
	ENT.SelfDestructTime = 240   -- the series' voiced countdown is about four minutes (5x01, 6x03)

	function ENT:CrewNear()   -- everyone near the hull or inside the interior
		local it, to = self.Interior, {}
		for _, p in ipairs(player.GetAll()) do
			if (p:GetPos():Distance(self:GetPos()) < 6000 or (IsValid(it) and p:GetPos():Distance(it:GetPos()) < 6000)) then to[#to + 1] = p end
		end
		return to
	end
	function ENT:CrewSay(msg, force)   -- (an English line as it is: other addons' calls)
		if (self.Log) then self:Log((msg:gsub("^Ha'tak[^:]*: ", ""))) end
		if (not force and self.ComputerOK and not self:ComputerOK("comms")) then return end   -- communication crystals pulled
		for _, p in ipairs(self:CrewNear()) do p:PrintMessage(HUD_PRINTCENTER, msg); p:PrintMessage(HUD_PRINTTALK, msg) end
	end
	-- a crew announcement in everyone's language: where = "" / "engine" / "computer" / "alert" / "weapons" (the
	-- "Ha'tak engine room:" in front), key = agp_hkm_c_*, then the values
	function ENT:CrewSayL(where, key, fallback, force, ...)
		local args = { ... }
		if (self.LogL) then self:LogL(key, fallback, ...) end
		if (not force and self.ComputerOK and not self:ComputerOK("comms")) then return end
		local to = self:CrewNear()
		if (#to > 0) then hkSend(to, where, key, fallback, args, true) end
	end

	function ENT:ToggleSelfDestruct(ply, seconds)
		local con = self.SelfDestructConsole
		local id = "AGPHatakDestruct" .. self:EntIndex()
		if (self.DestructAt) then
			self.DestructAt = nil; timer.Remove(id)
			if (IsValid(con)) then con:SetNWFloat("Countdown", 0); con:EmitSound("button/ring_button1.mp3") end
			self:SetNWFloat("AGPDestructAt", 0)
			self:CrewSayL("", "agp_hkm_c_sd_abort", "self-destruct aborted", true)
			return false
		end
		self.DestructAt = CurTime() + (seconds or self.SelfDestructTime)
		if (IsValid(con)) then con:SetNWFloat("Countdown", self.DestructAt); con:EmitSound("button/ring_button1.mp3") end
		self:SetNWFloat("AGPDestructAt", self.DestructAt)
		self:CrewSayL("", "agp_hkm_c_sd_in", "self-destruct in %s seconds", true, math.Round(self.DestructAt - CurTime()))
		local last = math.huge
		timer.Create(id, 1, 0, function()
			if (not IsValid(self) or not self.DestructAt) then timer.Remove(id) return end
			local left = math.ceil(self.DestructAt - CurTime())
			if (left <= 0) then timer.Remove(id); self:SelfDestruct() return end
			if ((left % 60 == 0 or left == 30 or left <= 10) and left < last) then
				self:CrewSayL("", "agp_hkm_c_sd_in", "self-destruct in %s seconds", true, left); last = left
				if (IsValid(con)) then con:EmitSound("buttons/blip1.wav", 90, 80) end
			end
		end)
		return true
	end

	function ENT:SelfDestruct()
		if (self.AGPBlowing) then return end
		self.AGPBlowing = true
		self.Destroying = true   -- its own chain of blasts must not start the hull's destruction a second time
		local pos, r = self:GetPos(), self:BoundingRadius()
		local it = self.Interior
		-- (2026-11-12, owner: "I got killed first, glitched through the interior, and then the ship exploded") the people
		-- aboard die IN the last blast, not three seconds before it: until then the ship breaks up around them
		local function aboard()
			local t = {}
			if (IsValid(it)) then
				for _, p in ipairs(player.GetAll()) do
					if (p:Alive() and p:GetPos():DistToSqr(it:GetPos()) < 25000000) then t[#t + 1] = p end
				end
			end
			return t
		end
		-- a chain of blasts across the hull, then one big flash: a 700 m ship does not go with a pop
		util.ScreenShake(pos, 25, 5, 6, r * 4)
		for k = 0, 23 do
			timer.Simple(k * 0.12, function()
				local p = pos + Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-0.5, 0.5)) * r * 0.6
				local fx = EffectData(); fx:SetOrigin(p); fx:SetScale(10); fx:SetMagnitude(10)
				util.Effect("Explosion", fx, true, true)
				util.Effect("HelicopterMegaBomb", fx, true, true)
				if (k % 3 == 0) then util.BlastDamage(game.GetWorld(), game.GetWorld(), p, 1500, 500) end
				-- inside: the same break-up around the crew (fire and shaking, no damage yet)
				if (k % 2 == 0) then
					for _, c in ipairs(aboard()) do
						local q = c:GetPos() + Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0):GetNormalized() * math.Rand(120, 320) + Vector(0, 0, math.Rand(20, 120))
						local f2 = EffectData(); f2:SetOrigin(q); f2:SetScale(2); f2:SetMagnitude(2)
						util.Effect("Explosion", f2, true, true)
						util.ScreenShake(c:GetPos(), 14, 8, 0.5, 600)
					end
				end
			end)
		end
		timer.Simple(2.9, function()
			for k = 1, 6 do
				local fx = EffectData(); fx:SetOrigin(pos + VectorRand() * r * 0.2); fx:SetScale(30); fx:SetMagnitude(30)
				util.Effect("HelicopterMegaBomb", fx, true, true)
			end
			-- nobody aboard survives the ship: taken to the matching place in the real hull and killed by the blast there
			-- (the interior is a copy parked elsewhere - a body left in it fell through the floor when it was removed)
			for _, c in ipairs(aboard()) do
				if (c:InVehicle()) then c:ExitVehicle() end
				c:ScreenFade(SCREENFADE.IN, Color(255, 240, 200, 255), 1.2, 0.3)
				if (IsValid(self) and IsValid(it)) then c:SetPos(self:LocalToWorld(it:WorldToLocal(c:GetPos()))) end
				if (c:HasGodMode()) then c:GodDisable() end
				local d = DamageInfo()
				d:SetDamage(100000); d:SetDamageType(DMG_BLAST)
				d:SetAttacker(game.GetWorld()); d:SetInflictor(game.GetWorld()); d:SetDamagePosition(pos)
				d:SetDamageForce((c:GetPos() - pos):GetNormalized() * 40000 + Vector(0, 0, 12000))
				c:TakeDamageInfo(d)
				if (c:Alive()) then c:Kill() end
			end
			-- the end: a naquadah blast like the pack's naquadah bomb (gate_nuke: flash, fire ball, shock wave, sound)
			local nuke = ents.Create("gate_nuke")
			if (IsValid(nuke)) then
				nuke:Setup(pos, math.Clamp(r / 23 * self:BlastScale(), 40, 600))
				nuke:Spawn(); nuke:Activate()
			end
			sound.Play("ambient/explosions/explode_" .. math.random(1, 9) .. ".wav", pos, 150, 70)
			if (IsValid(self)) then self:DeathBlast(pos, r) end
			-- other ships around: the blast on their shields and, past those, their hulls (AGP.ShipBlast). At the hull it is
			-- this ship's own hull; it reaches as far as the blast hurts people.
			if (IsValid(self) and AGP and AGP.ShipBlast) then
				AGP.ShipBlast(pos, r * self:BlastScale() * self.DeathHurt, (self.MaxHealth or 100000), game.GetWorld(), game.GetWorld(), self)
			end
			if (IsValid(self)) then self:Remove() end
		end)
	end

	-- the ship's last blast: everyone around the hull dies (DeathKill x its size), further out it hurts less and less
	-- (DeathHurt x its size), loose things fly away
	ENT.DeathKill, ENT.DeathHurt, ENT.DeathHurtMax = 1.0, 2.5, 250
	-- blast size setting (agp_hatak_blast_size): small, medium (as before 2026-10-25), large (default), XL, XXL
	ENT.BlastScales = { 0.6, 1.0, 1.4, 2.0, 3.0 }
	function ENT:BlastScale()
		local cv = GetConVar("agp_hatak_blast_size")
		return self.BlastScales[cv and cv:GetInt() or 3] or 1.4
	end
	function ENT:DeathBlast(pos, r)
		r = r * self:BlastScale()
		local kill, hurt = r * self.DeathKill, r * self.DeathHurt
		for _, e in ipairs(ents.FindInSphere(pos, hurt)) do
			if (not IsValid(e) or e == self or e.AGPShip == self or e == self.Interior) then continue end
			local d = e:WorldSpaceCenter():Distance(pos)
			if (e:IsPlayer() or e:IsNPC() or e:IsNextBot() or e:IsVehicle()) then
				if (e:IsPlayer() and not e:Alive()) then continue end
				local dmg = DamageInfo()
				dmg:SetDamage(d <= kill and 100000 or math.ceil(self.DeathHurtMax * (1 - (d - kill) / (hurt - kill))))
				dmg:SetDamageType(DMG_BLAST); dmg:SetAttacker(game.GetWorld()); dmg:SetInflictor(game.GetWorld())
				dmg:SetDamagePosition(pos); dmg:SetDamageForce((e:WorldSpaceCenter() - pos):GetNormalized() * 40000)
				e:TakeDamageInfo(dmg)
			else
				local ph = e:GetPhysicsObject()
				if (IsValid(ph) and ph:IsMotionEnabled()) then
					ph:ApplyForceCenter((e:WorldSpaceCenter() - pos):GetNormalized() * ph:GetMass() * 2000 * (1 - d / hurt))
				end
			end
		end
	end

	--################# Flight: the pilot seat on the pel'tak flies the whole ship
	-- W/S forward/back, A/D turn, Space/Ctrl up/down, Shift faster. Without a pilot it stops, holds still and freezes.
	ENT.Flight = { speed = 700, boost = 2800, back = 300, vertical = 350, turn = 18, accel = 400, boostAccel = 1400 }   -- Shift: 4x

	function ENT:SetPartsMoving(moving)
		for _, e in ipairs(IsValid(self.Interior) and { self } or table.Add({ self }, self.Parts or {})) do
			if (IsValid(e)) then
				for i = 0, e:GetPhysicsObjectCount() - 1 do
					local ph = e:GetPhysicsObjectNum(i)
					if (IsValid(ph)) then
						ph:EnableGravity(not moving)
						ph:EnableMotion(moving)
						if (moving) then ph:Wake() else ph:Sleep() end
					end
				end
			end
		end
	end

	function ENT:StartFlying()
		if (self.FlyTarget) then return end
		self:SetPartsMoving(true)
		if (self.SetWire) then self:SetWire("Flying", 1) end
		local a = self:GetAngles()
		self.FlyTarget = { pos = self:GetPos(), ang = Angle(0, a.y, 0) }
		self.FlyVel = Vector(0, 0, 0)
		self:EmitSound("vehicles/hatakengine.wav", 100, 100)
	end

	function ENT:StopFlying()
		if (not self.FlyTarget) then return end
		self.FlyTarget = nil
		self:SetPartsMoving(false)
		if (self.SetWire) then self:SetWire("Flying", 0); self:SetWire("Speed", 0) end
		self:StopSound("vehicles/hatakengine.wav")
	end

	-- Wire: Fly 1 = engines on (hover), Forward/Up/Turn -1..1, Boost 1 = faster; a pilot in the seat overrides Wire
	function ENT:TriggerInput(k, v)
		self.WireCtl[k] = v
		if (k == "Jump" and v > 0 and isvector(self.WireCtl["Jump Target"])) then self:Jump(self.WireCtl["Jump Target"]) end
		if (k == "Shield" and self.SetShield) then self:SetShield(v > 0) end
		if (k == "Cloak" and self.SetCloak) then self:SetCloak(v > 0) end
	end

	-- the hangar door on the flying hull as well: the twin of the interior's hangar door (they open and close together).
	-- It stands just outside the hangar doorway: closed, it is a solid wall seen from outside, E on it works from there.
	ENT.HullHangarDoorX = -624   -- hull space; the doorway is at x -612 (HangarPortal), the door 16 thick in front of it
	function ENT:BuildHullHangarDoor(inner, d)
		local e = ents.Create("agp_goauld_door")
		if (not IsValid(e)) then return end
		e:Setup(d.w, d.h, d.thick or 10, true)
		e:SetPos(self:LocalToWorld(Vector(self.HullHangarDoorX, d.pos.y, d.pos.z))); e:SetAngles(self:LocalToWorldAngles(Angle(0, d.yaw or 0, 0)))
		e:Spawn(); e:Activate()
		local ph = e:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(false) end
		e:SetParent(self)
		e.AGPShip, e.NoDissolve, e.AGPDoorName, e.AGPOuterTwin = self, true, "hangar (outside)", true
		e.Owner = inner.Owner
		if (e.CPPISetOwner and IsValid(self:ShipOwner())) then e:CPPISetOwner(self:ShipOwner()) end
		e.AGPTwin, inner.AGPTwin = inner, e
		self.HullHangarDoor = e
		self.Parts[#self.Parts + 1] = e		-- door controls outside too: on the side walls of the hangar mouth, in front of the door (owner 2026-10-25)
		for _, side in ipairs({ 1, -1 }) do
			local c = ents.Create("agp_hatak_prop")
			if (IsValid(c)) then
				c.PropModel = "models/agp/hatak/props/door_control.mdl"
				c:SetPos(self:LocalToWorld(Vector(self.HullHangarDoorX - 56, side * (d.w / 2 - 1.6), d.pos.z + 46)))
				c:SetAngles(self:LocalToWorldAngles(Angle(0, -90 * side, 0)))
				c:Spawn(); c:Activate()
				local ph = c:GetPhysicsObject(); if (IsValid(ph)) then ph:EnableMotion(false) end
				c:SetParent(self)
				c.AGPShip, c.NoDissolve, c.AGPPropName, c.AGPDoorName = self, true, "door_control", "hangar (outside)"
				if (c.CPPISetOwner and IsValid(self:ShipOwner())) then c:CPPISetOwner(self:ShipOwner()) end
				c.OnUse = function(_, user) if (IsValid(e)) then self:DoorPanelUse(e, user) end end
				self.Parts[#self.Parts + 1] = c
			end
		end
	end

	-- TARDIS doors: the hangar mouth outside leads into the interior hangar and back
	local function inBox(l, b) return l.x > b[1].x and l.x < b[2].x and l.y > b[1].y and l.y < b[2].y and l.z > b[1].z and l.z < b[2].z end
	-- seamless hangar: a doorway pair, outside (on the flying hull, facing out) <-> interior hangar (facing in)
	-- the pel'tak window: a view-only doorway (nothing passes) in the window wall of the interior, its far side a point
	-- just in front of the hull's bow looking ahead - the crew sees out as the ship flies
	ENT.Window = { pos = Vector(939, 0, 255), w = 210, h = 148, hull = Vector(-3210, 0, 150) }   -- hull: in front of the front tip
	function ENT:BuildWindow()
		local W = table.Copy(self.Window)
		local LW = self.Layout2 and self.Layout2.window   -- the window of the generated interior (interior2.py)
		if (LW) then W.pos, W.w, W.h = LW.pos, LW.w, LW.h end
		local inn = ents.Create("agp_portal")
		inn:SetPos(self.Interior:LocalToWorld(W.pos)); inn:SetAngles(self.Interior:LocalToWorldAngles(Angle(0, 180, 0)))
		inn:SetPortalWidth(W.w); inn:SetPortalHeight(W.h)
		inn:Spawn(); inn:SetParent(self.Interior)
		local out = ents.Create("agp_portal")   -- far side only (not linked itself: never drawn, never carries)
		out:SetPos(self:LocalToWorld(W.hull)); out:SetAngles(self:LocalToWorldAngles(Angle(0, self.FrontYaw, 0)))
		out:SetPortalWidth(W.w); out:SetPortalHeight(W.h)
		out:Spawn(); out:SetParent(self)
		inn:SetExit(out); inn:SetFrameSelf(self.Interior); inn:SetFrameExit(self)
		local ma = Angle(0, self.FrontYaw, 0)   -- the interior's +X (window) looks along the ship's front
		inn:SetMapPos(W.hull - LocalToWorld(W.pos, Angle(0, 0, 0), Vector(0, 0, 0), ma)); inn:SetMapAng(ma)
		inn:SetViewOnly(true)
		self.WindowPortals = { inn, out }
	end

	function ENT:BuildHangarPortal()
		local hp = self.HangarPortal
		local function make(frame, yaw)
			local p = ents.Create("agp_portal")
			p:SetPos(frame:LocalToWorld(hp.pos)); p:SetAngles(frame:LocalToWorldAngles(Angle(0, yaw, 0)))
			p:SetPortalWidth(hp.w); p:SetPortalHeight(hp.h)
			p:Spawn(); p:SetParent(frame)
			return p
		end
		local out, inn = make(self, 180), make(self.Interior, 0)
		out:SetExit(inn); out:SetFrameSelf(self); out:SetFrameExit(self.Interior)
		inn:SetExit(out); inn:SetFrameSelf(self.Interior); inn:SetFrameExit(self)
		self.Portals = { out, inn }
	end

	function ENT:HangarTransfer()
		local it = self.Interior
		if (self.Portals and IsValid(self.Portals[1])) then return end   -- the doorway does it
		if (not IsValid(it) or (self.NextTransfer or 0) > CurTime()) then return end
		self.NextTransfer = CurTime() + 0.1
		for _, p in ipairs(player.GetAll()) do
			if (p:Alive() and not p:InVehicle() and (p.AGPTransferWait or 0) < CurTime()) then
				local lo = self:WorldToLocal(p:GetPos())
				local li = it:WorldToLocal(p:GetPos())
				if (inBox(lo, self.HangarIn) and p:GetPos():DistToSqr(self:GetPos()) < 4000 * 4000) then
					-- in: same spot in the interior hangar, a bit further in, same direction relative to the ship
					p:SetPos(it:LocalToWorld(Vector(-560, lo.y, -600 + 4)))
					local ea = p:EyeAngles(); ea.y = it:GetAngles().y + math.AngleDifference(ea.y, self:GetAngles().y); p:SetEyeAngles(ea)
					p:SetVelocity(-p:GetVelocity())
					p.AGPTransferWait = CurTime() + 1
				elseif (inBox(li, self.HangarOut)) then
					-- out: in front of the real ship's hangar mouth (if the ship flies, you step out into the air)
					p:SetPos(self:LocalToWorld(Vector(-900, li.y, -760)))
					local ea = p:EyeAngles(); ea.y = self:GetAngles().y + math.AngleDifference(ea.y, it:GetAngles().y); p:SetEyeAngles(ea)
					p:SetVelocity(-p:GetVelocity())
					p.AGPTransferWait = CurTime() + 1
				end
			end
		end
	end

	-- who flies: the crew member on the throne, else the one in the pilot chair
	function ENT:Pilot()
		local t = IsValid(self.ThroneSeat) and self.ThroneSeat:GetDriver()
		if (IsValid(t) and t:IsPlayer() and self:MayCommand(t)) then return t end
		local p = IsValid(self.Seat) and self.Seat:GetDriver()
		return IsValid(p) and p or nil
	end

	function ENT:Think()
		self:HangarTransfer()
		self:SlotDoorsThink()
		local pilot = self:Pilot()
		if (IsValid(pilot) and pilot:IsPlayer() and not self:MayCommand(pilot)) then   -- sitting is fine, flying is for the crew
			if ((pilot.AGPHatakDenied or 0) < CurTime()) then hkTell(pilot, "agp_hkm_t_ship_crew", "The ship does not answer you (crew only)."); pilot.AGPHatakDenied = CurTime() + 5 end
			pilot = nil
		end
		local wired = (self.WireCtl.Fly or 0) > 0
		if (IsValid(pilot) or wired) then
			self:StartFlying()
			self.Parked = nil
		end
		if (self.FlyTarget) then
			local dt = FrameTime()
			local F = self.Flight
			local want = Vector(0, 0, 0)
			local turn = 0
			if (IsValid(pilot)) then
				local fwd = Angle(0, self.FlyTarget.ang.y + self.FrontYaw, 0):Forward()
				local spd = pilot:KeyDown(IN_SPEED) and F.boost or F.speed
				if (pilot:KeyDown(IN_FORWARD)) then want = want + fwd * spd end
				if (pilot:KeyDown(IN_BACK)) then want = want - fwd * F.back end
				if (pilot:KeyDown(IN_JUMP)) then want = want + Vector(0, 0, F.vertical) end
				if (pilot:KeyDown(IN_DUCK)) then want = want - Vector(0, 0, F.vertical) end
				if (pilot:KeyDown(IN_MOVELEFT)) then turn = turn + F.turn end
				if (pilot:KeyDown(IN_MOVERIGHT)) then turn = turn - F.turn end
				local r = pilot:KeyDown(IN_RELOAD)
				if (r and not self.LastR) then self:OpenJumpMenu(pilot) end
				self.LastR = r
			elseif (wired) then
				local W = self.WireCtl
				local fwd = Angle(0, self.FlyTarget.ang.y + self.FrontYaw, 0):Forward()
				local f = math.Clamp(W.Forward or 0, -1, 1)
				want = fwd * (f > 0 and f * ((W.Boost or 0) > 0 and F.boost or F.speed) or f * F.back) + Vector(0, 0, math.Clamp(W.Up or 0, -1, 1) * F.vertical)
				turn = math.Clamp(W.Turn or 0, -1, 1) * F.turn
			end
			-- engine room: the sublight engines push as hard as their power allows
			local ep = self:SystemPower("engines")
			if (ep <= 0 and want:LengthSqr() > 0 and IsValid(pilot) and (pilot.AGPHatakNoThrust or 0) < CurTime()) then
				hkTell(pilot, "agp_hkm_t_no_thrust", "The sublight engines have no power (engine room)."); pilot.AGPHatakNoThrust = CurTime() + 5
			end
			want = want * math.min(ep, 1.3)
			-- smooth speed changes (a 700 m ship does not jerk); during a jump the hyperdrive flies
			if (not self.Jumping) then
				local acc = (want:Length() > F.speed * 1.5 or self.FlyVel:Length() > F.speed * 1.5) and F.boostAccel or F.accel
				self.FlyVel = self.FlyVel + (want - self.FlyVel):GetNormalized() * math.min((want - self.FlyVel):Length(), acc * dt)
			else
				turn = 0
				if (self.JumpVel) then   -- the hyperdrive pulls the ship into the window: strong but not instant
					local d = self.JumpVel - self.FlyVel
					self.FlyVel = self.FlyVel + d:GetNormalized() * math.min(d:Length(), 800 * dt)
				end
			end
			self.FlyTarget.ang.y = self.FlyTarget.ang.y + turn * dt
			local p = self.FlyTarget.pos + self.FlyVel * dt
			-- do not run away from a ship that is stuck on something
			local off = p - self:GetPos()
			if (off:Length() > 400 and not self.Jumping) then p = self:GetPos() + off:GetNormalized() * 400; self.FlyVel = self.FlyVel * 0.5 end
			self.FlyTarget.pos = p
			if (self.SetWire) then self:SetWire("Speed", self:GetVelocity():Length()); self:SetWire("Pilot", IsValid(pilot) and pilot or NULL) end
			self:InertialDampers()
			-- no pilot and no Wire: once it has stopped, freeze it where it is
			if (not IsValid(pilot) and not wired and not self.Jumping) then
				self.Parked = self.Parked or CurTime()
				if (self.FlyVel:Length() < 5 and CurTime() - self.Parked > 3) then self:StopFlying() end
			end
		end
		self:NextThink(CurTime())
		return true
	end

	--################# Hyperspace jump (as in the series: a window opens in front, the ship flies into it and comes out of
	-- a second window at the target). Targets: saved marks, Stargates, players, coordinates (pilot: R key menu), Wire.
	ENT.Hyper = { charge = 3, enterTime = 2.2, cooldown = 8, windowRadius = 2600 }

	-- the ship's own extent (hull space) for the free-space check, a bit larger than the hull
	ENT.HullBox = { Vector(-3150, -3150, -1700), Vector(3150, 3150, 1550) }

	function ENT:SpotIsFree(pos)
		local mn, mx = self.HullBox[1], self.HullBox[2]
		for _, x in ipairs({ mn.x, mx.x }) do for _, y in ipairs({ mn.y, mx.y }) do for _, z in ipairs({ mn.z, mx.z }) do
			if (not util.IsInWorld(pos + Vector(x, y, z))) then return false end
		end end end
		local tr = util.TraceHull({ start = pos, endpos = pos, mins = mn, maxs = mx, mask = MASK_SOLID,
			filter = function(e) return not (e == self or e.AGPShip == self or e:IsPlayer()) end })
		return not (tr.Hit or tr.StartSolid)
	end

	-- the target itself if free, else the nearest free spot above it, then around it
	function ENT:FindSafeSpot(dest)
		if (self:SpotIsFree(dest)) then return dest end
		for up = 500, 8000, 500 do
			if (self:SpotIsFree(dest + Vector(0, 0, up))) then return dest + Vector(0, 0, up) end
		end
		for r = 3500, 14000, 3500 do
			for a = 0, 315, 45 do
				local p = dest + Angle(0, a, 0):Forward() * r
				for up = 0, 4000, 1000 do
					if (self:SpotIsFree(p + Vector(0, 0, up))) then return p + Vector(0, 0, up) end
				end
			end
		end
	end

	function ENT:HyperWindow(pos, normal, life)
		local fx = EffectData()
		fx:SetOrigin(pos); fx:SetNormal(normal); fx:SetScale(self.Hyper.windowRadius); fx:SetMagnitude(life)
		util.Effect("agp_hyperwindow", fx, true, true)
	end

	-- loose things inside the decks travel with the ship (players, NPCs, unconstrained props)
	function ENT:Passengers()
		local list = {}
		local mn, mx = self.InsideBox[1], self.InsideBox[2]
		local parts = {}
		for _, e in ipairs(self.Parts) do parts[e] = true end
		for _, e in ipairs(ents.FindInSphere(self:GetPos(), 2000)) do
			if (e ~= self and not parts[e] and not IsValid(e:GetParent()) and (e:IsPlayer() or e:IsNPC() or e:GetMoveType() == MOVETYPE_VPHYSICS)) then
				local l = self:WorldToLocal(e:GetPos())
				if (l.x > mn.x and l.x < mx.x and l.y > mn.y and l.y < mx.y and l.z > mn.z and l.z < mx.z) and not (e:IsPlayer() and e:InVehicle()) then
					list[#list + 1] = e
				end
			end
		end
		return list
	end

	-- move the whole ship (hull, built-in parts, passengers) to dest, keeping everything's place inside the ship
	function ENT:MoveShipTo(dest)
		local carry = {}
		for _, e in ipairs(table.Add(table.Add({}, IsValid(self.Interior) and {} or self.Parts), self:Passengers())) do
			if (IsValid(e)) then carry[#carry + 1] = { e, self:WorldToLocal(e:GetPos()), self:WorldToLocalAngles(e:GetAngles()) } end
		end
		local ang = self:GetAngles()
		self:SetPos(dest)
		local ph = self:GetPhysicsObject()
		if (IsValid(ph)) then ph:SetPos(dest); ph:SetAngles(ang); ph:SetVelocity(Vector(0, 0, 0)) end
		for _, c in ipairs(carry) do
			local e, lp, la = c[1], c[2], c[3]
			if (IsValid(e)) then
				local wp, wa = self:LocalToWorld(lp), self:LocalToWorldAngles(la)
				if (e:IsPlayer() or e:IsNPC()) then
					e:SetPos(wp); e:SetVelocity(-e:GetVelocity())
				else
					e:SetPos(wp); e:SetAngles(wa)
					local p2 = e:GetPhysicsObject()
					if (IsValid(p2)) then p2:SetPos(wp); p2:SetAngles(wa); p2:SetVelocity(Vector(0, 0, 0)) end
				end
			end
		end
		if (self.FlyTarget) then self.FlyTarget.pos = dest; self.FlyVel = Vector(0, 0, 0) end
		-- the dampers must not "carry" everyone back by the jump distance on the next tick
		self.LastPos, self.LastAng, self.LastVel = dest, ang, Vector(0, 0, 0)
	end

	function ENT:Jump(dest, who)
		local H = self.Hyper
		if (self.Jumping or (self.NextJump or 0) > CurTime()) then
			if (IsValid(who)) then hkTell(who, "agp_hkm_t_hyper_notready", "Hyperdrive not ready.") end
			return false
		end
		local hp = self:SystemPower("hyperdrive")   -- engine room: offline under 30 %, weaker = longer charge
		if (hp < 0.3) then
			if (IsValid(who)) then hkTell(who, "agp_hkm_t_hyper_nopower", "The hyperdrive has no power (engine room).") end
			return false
		end
		local charge = H.charge / math.min(hp, 1.3)
		local spot = dest and self:FindSafeSpot(dest)
		if (not spot) then
			if (IsValid(who)) then hkTell(who, "agp_hkm_t_no_space", "No free space for the ship at that target.") end
			self:EmitSound("button/ring_button2.mp3", 90)
			return false
		end
		self.Jumping = true
		self:SetNWBool("AGPHatakJumping", true)   -- the helm HUD (lua/autorun/client/agp_ship_hud_ships.lua)
		if (self.SetWire) then self:SetWire("Charging", 1) end
		if (self.Log) then if (IsValid(who)) then self:LogL("agp_hkm_l_jump_by", "hyperspace jump (%s) to %s", who:Nick(), string.format("%d %d %d", spot.x, spot.y, spot.z)) else self:LogL("agp_hkm_l_jump", "hyperspace jump to %s", string.format("%d %d %d", spot.x, spot.y, spot.z)) end end
		-- an open gate on board closes first (a wormhole cannot follow the ship into hyperspace)
		for _, g in ipairs({ self.Gate, self.CargoGate }) do
			if (IsValid(g) and (g.IsOpen or g.Active) and g.EmergencyShutdown) then pcall(g.EmergencyShutdown, g) end
		end
		self:StartFlying()
		self:EmitSound("vehicles/hatakengine.wav", 110, 120)
		local fwd = Angle(0, self:GetAngles().y + self.FrontYaw, 0):Forward()
		timer.Simple(charge - 1, function()
			if (not IsValid(self)) then return end
			local wpos = self:GetPos() + fwd * 3600
			self:HyperWindow(wpos, -fwd, H.enterTime + 1.6)
			self:EmitSound("eap/hyperespace/hyper_window_open.wav", 140)
		end)
		timer.Simple(charge, function()   -- into the window (speeding up, the dampers keep the crew in place)
			if (not IsValid(self)) then return end
			self.JumpVel = fwd * self.Flight.boost
		end)
		timer.Simple(charge + H.enterTime, function()   -- through hyperspace to the target
			if (not IsValid(self)) then return end
			local arriveFwd = Angle(0, self:GetAngles().y + self.FrontYaw, 0):Forward()
			self:MoveShipTo(spot)
			-- AGP 2026-11-08: the window it came out of stays behind the stern (owner: it has left hyperspace; was ahead)
			local ld, back = self:WorldToLocal(self:GetPos() + arriveFwd), 0
			local mn, mx = self:OBBMins(), self:OBBMaxs()
			for _, x in ipairs({ mn.x, mx.x }) do for _, y in ipairs({ mn.y, mx.y }) do
				back = math.max(back, -(x * ld.x + y * ld.y))
			end end
			self:HyperWindow(self:GetPos() - arriveFwd * (back + 300), arriveFwd, 2.4)
			sound.Play("eap/hyperespace/hyper_window_close.wav", spot, 140)
			self.FlyVel = Vector(0, 0, 0)
			self.JumpVel = nil
			self.Jumping = nil
			self.NextJump = CurTime() + H.cooldown
			self:SetNWBool("AGPHatakJumping", false); self:SetNWFloat("AGPHatakJumpReady", self.NextJump)
			if (self.SetWire) then self:SetWire("Charging", 0) end
		end)
		return true
	end

	-- pilot menu (R): marks, Stargates, players, coordinates
	function ENT:JumpTargets(ply)
		local t = {}
		self.Marks = self.Marks or {}
		for i = 1, 3 do t[#t + 1] = { "Mark " .. i, self.Marks[i] } end
		for _, g in ipairs(ents.GetAll()) do
			if (g.IsStargate and g ~= self.Gate and g ~= self.CargoGate and g.GetGateAddress) then
				local name = (g.GetGateName and g:GetGateName() or "")
				t[#t + 1] = { "Gate " .. (name ~= "" and name or g:GetGateAddress()) .. " (" .. g:GetClass():gsub("stargate_", "") .. ")", g:GetPos() }
			end
		end
		for _, p in ipairs(player.GetAll()) do
			if (p ~= ply) then t[#t + 1] = { "Player " .. p:Nick(), p:GetPos() } end
		end
		return t
	end

	function ENT:OpenJumpMenu(ply)
		local t = self:JumpTargets(ply)
		self.MenuTargets = self.MenuTargets or {}
		self.MenuTargets[ply] = t
		net.Start("AGP_HatakJumpMenu")
		net.WriteEntity(self)
		net.WriteUInt(#t, 10)
		for _, v in ipairs(t) do net.WriteString(v[1]); net.WriteBool(v[2] ~= nil) end
		net.Send(ply)
	end

	net.Receive("AGP_HatakJumpGo", function(len, ply)
		local ship = net.ReadEntity()
		local kind = net.ReadString()
		if (not IsValid(ship) or ship:GetClass() ~= "agp_hatak") then return end
		-- the pilot, or someone who opened the menu on the navigation console a moment ago (and still stands at it)
		local nav = ship.NavUsers and ship.NavUsers[ply]
		local pilot = ship:Pilot() == ply
		if (not pilot and not (nav and CurTime() - nav < 120 and ply:Alive() and not ply:InVehicle())) then return end
		if (not ship:MayCommand(ply)) then return end
		ship.Marks = ship.Marks or {}
		if (kind == "save") then
			local i = math.Clamp(net.ReadUInt(2), 1, 3)
			ship.Marks[i] = ship:GetPos()
			hkTell(ply, "agp_hkm_t_mark_saved", "Mark %s saved.", i)
		elseif (kind == "target") then
			local i = net.ReadUInt(10)
			local t = ship.MenuTargets and ship.MenuTargets[ply] and ship.MenuTargets[ply][i]
			if (t and t[2]) then ship:Jump(t[2] + Vector(0, 0, 2500), ply) end
		elseif (kind == "coord") then
			ship:Jump(net.ReadVector(), ply)
		end
	end)

	-- inertial dampers (as in the series): whatever is loose inside the decks gets the ship's change of velocity,
	-- so crew and cargo do not slide when the ship speeds up, brakes or turns
	ENT.InsideBox = { Vector(-950, -700, -720), Vector(1250, 700, 560) }   -- hull space: the pyramid core with the decks
	function ENT:InertialDampers()
		local v = self:GetVelocity()
		local dv = v - (self.LastVel or v)
		self.LastVel = v
		local pos, ang = self:GetPos(), self:GetAngles()
		local ppos, pang = self.LastPos or pos, self.LastAng or ang
		self.LastPos, self.LastAng = pos, ang
		local moved = pos:DistToSqr(ppos) > 0.0001 or math.abs(math.AngleDifference(ang.y, pang.y)) > 0.001
		local mn, mx = self.InsideBox[1], self.InsideBox[2]
		local parts = {}
		for _, e in ipairs(self.Parts) do parts[e] = true end
		for _, e in ipairs(ents.FindInSphere(pos, 2000)) do
			if (e ~= self and not parts[e] and not IsValid(e:GetParent())) then
				local l = self:WorldToLocal(e:GetPos())
				if (l.x > mn.x and l.x < mx.x and l.y > mn.y and l.y < mx.y and l.z > mn.z and l.z < mx.z) then
					if (e:IsPlayer() or e:IsNPC()) then
						-- moving platform: carry the crew exactly as far as the ship moved and turned since the last tick
						if (moved and not (e:IsPlayer() and (e:InVehicle() or e:GetMoveType() == MOVETYPE_NOCLIP))) then
							local lp = WorldToLocal(e:GetPos(), Angle(0, 0, 0), ppos, pang)
							local np = LocalToWorld(lp, Angle(0, 0, 0), pos, ang)
							e:SetPos(np)
							if (e:IsPlayer()) then
								local ea = e:EyeAngles(); ea.y = ea.y + math.AngleDifference(ang.y, pang.y); e:SetEyeAngles(ea)
							end
						end
					elseif (e:GetMoveType() == MOVETYPE_VPHYSICS and dv:LengthSqr() > 0.01) then
						-- cargo gets the ship's change of speed (the floor carries the rest)
						local ph = e:GetPhysicsObject()
						if (IsValid(ph) and ph:IsMotionEnabled() and not constraint.HasConstraints(e)) then
							ph:Wake()   -- a resting prop sleeps and would ignore the added speed
							ph:AddVelocity(dv)
						end
					end
				end
			end
		end
	end

	function ENT:PhysicsSimulate(phys, dt)
		if (not self.FlyTarget) then
			-- unfrozen and not flying: a Ha'tak never lies on its side; it rights itself (gravity still pulls it down)
			if (self.Destroying or not phys:IsMotionEnabled()) then return SIM_NOTHING end
			local a = phys:GetAngles()
			if (math.abs(math.NormalizeAngle(a.p)) < 0.3 and math.abs(math.NormalizeAngle(a.r)) < 0.3) then return SIM_NOTHING end
			phys:Wake()
			phys:ComputeShadowControl({ secondstoarrive = 1, pos = phys:GetPos(), angle = Angle(0, a.y, 0),
				maxangular = 60, maxangulardamp = 600, maxspeed = 0, maxspeeddamp = 0, dampfactor = 0.8,
				teleportdistance = 0, deltatime = dt })
			return SIM_NOTHING
		end
		phys:Wake()
		phys:ComputeShadowControl({ secondstoarrive = 0.4, pos = self.FlyTarget.pos, angle = self.FlyTarget.ang,
			maxangular = 400, maxangulardamp = 4000, maxspeed = 100000, maxspeeddamp = 100000, dampfactor = 0.85,
			teleportdistance = 0, deltatime = dt })
		return SIM_NOTHING
	end

	function ENT:OnRemove()
		for _, pad in ipairs(self.GliderPads or {}) do   -- gliders still on their pads go with the ship; flown ones stay
			local g = pad.glider
			if (IsValid(g) and not IsValid(g.Pilot)) then g:Remove() end
		end
		for _, e in ipairs(ents.GetAll()) do   -- anything of this ship's interior that is not a listed part (crystals carried off, ...)
			if (IsValid(e) and e.AGPShip == self and not e:IsPlayer()) then e:Remove() end
		end
		if (IsValid(self.Interior)) then self.Interior:Remove() end
		for _, p in ipairs(self.Portals or {}) do if (IsValid(p)) then p:Remove() end end
		for _, p in ipairs(self.WindowPortals or {}) do if (IsValid(p)) then p:Remove() end end
		for _, p in ipairs(self.SlotPortals or {}) do if (IsValid(p)) then p:Remove() end end
		timer.Remove("AGPHatakGliders" .. self:EntIndex())
		timer.Remove("AGPHatakDestruct" .. self:EntIndex())
		timer.Remove("AGPHatakWeapons" .. self:EntIndex())
		timer.Remove("AGPHatakCrystal" .. self:EntIndex())
		if (IsValid(self.Gunner)) then self:SetGunner(nil) end
		self:StopSound("vehicles/hatakengine.wav")
		for _, e in ipairs(self.Parts or {}) do if (IsValid(e)) then e:Remove() end end
	end

	-- ring panel menu: decks of this ship + nearest ring outside
	function ENT:OpenRingMenu(ply, panel)
		if (not IsValid(ply) or not IsValid(panel)) then return end
		if (self.ComputerOK and not self:ComputerOK("rings")) then hkTell(ply, "agp_hkm_t_rings_off", "The rings do not answer (computer core: ring crystals missing).") return end
		net.Start("AGP_HatakRingMenu")
		net.WriteEntity(panel)
		net.WriteUInt(panel.AGPDeck or 0, 4)
		net.WriteUInt(#self.Decks, 4)
		for i, name in ipairs(self.Decks) do
			net.WriteString(name)
			net.WriteString(IsValid(self.Rings[i]) and (self.Rings[i].Address or "") or "")
		end
		net.Send(ply)
	end

	function ENT:NearestOutsideRing(from)
		-- measured from where that ring would be on the real ship (the interior stands somewhere else on the map)
		local origin = from:GetPos()
		if (IsValid(self.Interior)) then origin = self:LocalToWorld(self.Interior:WorldToLocal(origin)) end
		local best, bd
		for _, v in ipairs(ents.FindByClass("ring_base_*")) do
			if (v ~= from and v.IsRings and v.AGPShip ~= self and not v.Busy) then
				local d = v:GetPos():DistToSqr(origin)
				if (not bd or d < bd) then best, bd = v, d end
			end
		end
		return best
	end

	net.Receive("AGP_HatakRingGo", function(len, ply)
		local panel = net.ReadEntity()
		local choice = net.ReadInt(8)
		if (not IsValid(panel) or not IsValid(panel.AGPShip) or not IsValid(ply)) then return end
		if (ply:GetPos():Distance(panel:GetPos()) > 200) then return end
		local ship = panel.AGPShip
		if (ship.ComputerOK and not ship:ComputerOK("rings")) then return end
		local from = ship.Rings[panel.AGPDeck or 0]
		if (not IsValid(from)) then return end
		if (choice == -1) then   -- the panel's own glyph pad
			local stored = scripted_ents.Get("ring_panel_goauld")
			if (stored and stored.Use) then stored.Use(panel, ply) end
			return
		end
		local target = (choice == 0) and ship:NearestOutsideRing(from) or ship.Rings[choice]
		if (IsValid(target)) then from:DialEntity(target) else from:EmitSound("common/warning.wav", 100, 70) end
	end)

	-- ===== weapons (weapons console on the pel'tak): staff cannon volleys from the hull, radar, modes, manual gunner =====
	-- modes: 0 off, 1 defend (only what attacked the ship in the last 30 s), 2 auto (NPCs, strangers, attackers).
	-- Never at the ship itself, its parts or anyone inside its interior. Owner + friends only when the admin allows it
	-- (agp_hatak_friendly_fire). Crew = owner + prop-protection friends, or the hijacker + friends after a takeover.
	-- Server settings: lua/autorun/server/agp_ship_settings.lua (Stargate > Config > AGP Ships).
	ENT.WeaponCooldown = 1.2
	local function cv(n, d) local c = GetConVar(n) return c and c:GetInt() or d end
	function ENT:WeaponRange() return cv("agp_hatak_weapon_range", 15000) end

	function ENT:ShipOwner() return (self.CPPIGetOwner and IsValid(self:CPPIGetOwner()) and self:CPPIGetOwner()) or self.Owner end
	-- crew: whoever controls the ship now (owner, or the hijacker with the control crystal) and his friends
	function ENT:Commander() return IsValid(self.Hijacker) and self.Hijacker or self:ShipOwner() end
	function ENT:IsCrew(ply)
		if (not IsValid(ply) or not ply:IsPlayer()) then return false end
		local own = self:Commander()
		if (not IsValid(own) or ply == own) then return true end
		if (own.CPPIGetFriends) then
			for _, f in ipairs(own:CPPIGetFriends() or {}) do if (f == ply) then return true end end
		end
		return false
	end
	-- may this player use the consoles? (agp_hatak_hijack 2 = anyone)
	function ENT:MayCommand(ply) return self:IsCrew(ply) or cv("agp_hatak_hijack", 1) == 2 end

	-- remember who shoots at the ship (defend mode)
	local function isKawoosh(dmg)   -- the gate's kawoosh (event horizon) never hurts the ship it stands in
		local inf = dmg:GetInflictor()
		return IsValid(inf) and (inf:GetClass() == "kawoosh_hurt" or inf:GetClass() == "event_horizon")
	end
	-- continuous beams (the Asuran gate weapon's energy_laser: a blast of ~50 at the hit point every 0.1 s, env_laser
	-- beams): many small hits. They count against the hull (no per-hit minimum), but at most BeamMaxDPS per second.
	ENT.BeamMaxDPS = 600
	function ENT:IsBeamDamage(dmg)
		local inf = dmg:GetInflictor()
		local c = IsValid(inf) and inf:GetClass() or ""
		return c == "energy_laser" or c == "env_laser" or dmg:IsDamageType(DMG_ENERGYBEAM)
	end
	function ENT:BeamBudget(amount)
		local now = CurTime()
		if (now - (self.BeamSince or -99) >= 1) then self.BeamSince, self.BeamTaken = now, 0 end
		local take = math.min(amount, math.max(0, self.BeamMaxDPS - self.BeamTaken))
		self.BeamTaken = self.BeamTaken + take
		return take
	end
	-- AGP 2026-11-08 (as in the series, owner's wish): the Ori mothership's main beam is far beyond a Ha'tak. In
	-- "Camelot" the Ori ships wiped out the Jaffa fleet in minutes; a Ha'tak's shield did not stop their beam. Its
	-- hits (energy_beam2 with AGPOriBeam) do not use the beam budget above (600 a second: one Ori beam could never
	-- drain the shield, the recharge was faster). They count by time instead: a full shield fails within one burn of
	-- the beam (OriShieldBurn seconds), then the hull holds about three burns (OriHullBurn seconds in all, a share of
	-- the hull the admin set). Several hits in the same moment (the shield hit, the beam's damage and its blast)
	-- count once. Returns what the shield and the hull take now (0, 0: nothing more this moment).
	ENT.OriShieldBurn, ENT.OriHullBurn = 2.2, 7
	function ENT:OriBeamHit(dmg)
		local now = CurTime()
		local dt = math.Clamp(now - (self.OriBeamLast or (now - 0.1)), 0, 0.25)
		self.OriBeamLast = now
		if (dt <= 0) then return 0, 0 end
		local beam = self:IsBeamDamage(dmg)
		local shield = self.ShieldAbsorb * 100 / self.OriShieldBurn * dt / (beam and self.ShieldBeamDrain or 1)
		local hull = (self.MaxHealth or 100000) / self.OriHullBurn * dt / (beam and self.HullBeamFactor or 1)
		return shield, hull
	end
	function ENT:OnTakeDamage(dmg)
		if (isKawoosh(dmg) or self.Destroying) then return end
		local amount, hullAmount = dmg:GetDamage(), nil
		local inf = dmg:GetInflictor()
		if (IsValid(inf) and inf.AGPOriBeam) then
			amount, hullAmount = self:OriBeamHit(dmg)
			if (amount <= 0) then return end
		elseif (self:IsBeamDamage(dmg)) then
			amount = self:BeamBudget(amount)
			if (amount <= 0) then return end
		end
		local took, rest
		if (self.ShieldHit) then took, rest = self:ShieldHit(dmg, amount) end
		if (took) then   -- the shield took it: no crystal burns
			local a = dmg:GetAttacker()
			if (IsValid(a) and a ~= self and not self:IsCrew(a)) then self.Attackers = self.Attackers or {}; self.Attackers[a] = CurTime() end
			return
		end
		if (rest) then amount = rest; if (hullAmount) then hullAmount = math.min(hullAmount, rest) end end   -- what broke through the failing shield
		-- engine room: hits that count against the hull burn power crystals out (a rifle that cannot dent the hull
		-- does not burn crystals either)
		self.BurnDamage = (self.BurnDamage or 0) + (tonumber(self:HullDamage(hullAmount or amount, dmg)) or 0)
		-- AGP: at most 20 crystals per hit; inf / NaN damage (other addons) froze the game in the old while loop
		if (self.BurnDamage ~= self.BurnDamage or self.BurnDamage == math.huge) then self.BurnDamage = self.CrystalBurnDamage * 20 end
		local burns = math.min(math.floor(self.BurnDamage / self.CrystalBurnDamage), 20)
		self.BurnDamage = self.BurnDamage % self.CrystalBurnDamage
		for _ = 1, burns do
			if (math.random() < 0.5) then self:BurnCrystal() end
		end
		local a = dmg:GetAttacker()
		if (IsValid(a) and a ~= self and not self:IsCrew(a)) then
			self.Attackers = self.Attackers or {}
			if (CurTime() - (self.Attackers[a] or -99) > 15 and self.Log) then
				self:LogL("agp_hkm_l_attacked", "attacked by %s", (a:IsPlayer() and a:Nick() or ((a.PrintName or "") ~= "" and a.PrintName) or a:GetClass()))
			end
			self.Attackers[a] = CurTime()
		end
	end

	-- one scan of the space around the ship (FindInSphere: cost grows with what is near, not with the whole map)
	function ENT:WeaponTargets()
		local t, pos, range = {}, self:GetPos(), self:WeaponRange()
		if (self.ComputerOK and not self:ComputerOK("sensors")) then return t end   -- sensor crystals pulled: radar blind
		local ff = cv("agp_hatak_friendly_fire", 0) == 1
		local it = self.Interior
		local function inside(e) return IsValid(it) and e:GetPos():DistToSqr(it:GetPos()) < 25000000 end   -- 5000 around the interior
		local seen = {}
		local function add(e, kind)
			if (seen[e] or e == self or e.AGPShip == self or inside(e)) then return end
			seen[e] = true
			t[#t + 1] = { ent = e, kind = kind, dist = e:GetPos():Distance(pos) }
		end
		for _, e in ipairs(ents.FindInSphere(pos, range)) do
			if (e:IsPlayer()) then
				if (e:Alive() and (ff or not self:IsCrew(e))) then add(e, "player") end
			elseif (e:IsNPC() or e:IsNextBot()) then add(e, "npc")
			elseif (e:GetClass() == "agp_hatak") then
				if (not e.Cloaked and (ff or not self:IsCrew(e:Commander()))) then add(e, "ship") end
			elseif (e:IsVehicle() or e:GetClass():find("^sg_vehicle_")) then
				local d = e.GetDriver and e:GetDriver() or e.Pilot
				if (IsValid(d) and d:IsPlayer() and (ff or not self:IsCrew(d))) then add(e, "ship") end
			end
		end
		table.SortByMember(t, "dist", true)
		return t
	end

	-- fire the given cannons (default: all) at a point; each cannon needs a free line (never through the own hull)
	function ENT:FireAt(aim, target, list)
		if ((self.NextVolley or 0) > CurTime() or self.Jumping) then return 0 end
		local wp = self:SystemPower("weapons")   -- engine room: no power, no shots; less power, slower recharge
		if (wp <= 0) then self.LastVolley = 0 return 0 end
		if (self.Cloaked) then self:SetCloak(false) end   -- a cloaked ship shows itself to fire
		local n = 0
		for _, i in ipairs(list or { 1, 2, 3, 4, 5, 6, 7 }) do
			local c = self.Cannons[i]
			local from = self:LocalToWorld(c.pos)
			local tr = util.TraceLine({ start = from, endpos = aim, filter = function(e) return e ~= self end, mask = MASK_SHOT })
			-- AGP 2026-11-15: the target's own raised shield counts as the target (a shielded ship was never fired at: every
			-- line of fire met its bubble first)
			local tshield = IsValid(target) and AGP.ShipShieldEntity and AGP.ShipShieldEntity(target)
			if (not tr.Hit or (IsValid(target) and (tr.Entity == target or (IsValid(tshield) and tr.Entity == tshield))) or tr.Fraction > 0.97) then
				local e = ents.Create("hatak_pulse")
				if (IsValid(e)) then
					local ign = { self }
					for _, pt in ipairs(self.Parts or {}) do ign[#ign + 1] = pt end
					e:PrepareBullet((aim - from):GetNormal(), 2, 2600, 60, ign)
					e:SetPos(from); e:SetOwner(self); e.Owner = self:Commander() or self
					e:Spawn(); e:Activate()
					e.Damage = 650 -- AGP 2026-10-30 balance: 7 x 650 per volley (size 60 gave 2300 each: a ship shield in one volley)
					e:SetColor(Color(250, 190, 100, 215))
					n = n + 1
				end
			end
		end
		if (n > 0) then
			self:EmitSound("weapons/hatak_fire.mp3", 140, math.random(88, 102))
			self.NextVolley = CurTime() + self.WeaponCooldown / math.max(wp, 0.25)
		end
		self.LastVolley = n
		return n
	end
	function ENT:FireVolley(target)
		if (not IsValid(target)) then return 0 end
		return self:FireAt(target:WorldSpaceCenter(), target)
	end

	function ENT:WeaponsThink()
		local mode = self.WeaponMode or 0
		local tgt = self.WeaponTarget
		if (IsValid(tgt) and self.WeaponHold and tgt:GetPos():Distance(self:GetPos()) <= self:WeaponRange()) then return self:FireVolley(tgt) end
		if (mode == 0) then return end
		local best
		for _, t in ipairs(self:WeaponTargets()) do
			local atk = self.Attackers and self.Attackers[t.ent] and CurTime() - self.Attackers[t.ent] < 30
			if (atk or (mode == 2 and t.kind ~= "ship")) then best = t.ent break end
		end
		if (best) then self:FireVolley(best) end
	end

	util.AddNetworkString("AGP_HatakWeapons")
	util.AddNetworkString("AGP_HatakWeaponsCmd")
	-- purpose: 0 open/update the console menu, 1 radar on the pilot's / gunner's screen only
	function ENT:SendWeapons(ply, purpose)
		local t = self:WeaponTargets()
		local n = math.min(#t, cv("agp_hatak_radar_max", 60), 255)
		net.Start("AGP_HatakWeapons")
		net.WriteEntity(self)
		net.WriteUInt(purpose or 0, 2)
		net.WriteUInt(self.WeaponMode or 0, 2)
		net.WriteBool(self.WeaponHold and true or false)
		net.WriteEntity(IsValid(self.WeaponTarget) and self.WeaponTarget or NULL)
		net.WriteFloat(math.max(0, (self.NextVolley or 0) - CurTime()))
		net.WriteFloat(self:WeaponRange())
		net.WriteUInt(n, 8)
		local npcs = list.GetForEdit("NPC")   -- list.Get copies the whole list: once per send at most, never per target
		for i = 1, n do
			local e = t[i].ent
			local lp = WorldToLocal(e:GetPos(), Angle(0, 0, 0), self:GetPos(), self:LocalToWorldAngles(Angle(0, self.FrontYaw, 0)))   -- radar: the front (hangar side) up
			local npc = npcs[e:GetClass()]
			local name = e:IsPlayer() and e:Nick() or (e:IsVehicle() and IsValid(e:GetDriver()) and e:GetDriver():Nick()) or (npc and npc.Name) or e.PrintName or e:GetClass()
			net.WriteEntity(e); net.WriteString(name); net.WriteString(t[i].kind)
			net.WriteFloat(t[i].dist); net.WriteFloat(lp.x); net.WriteFloat(lp.y); net.WriteFloat(lp.z)
			net.WriteBool((self.Attackers and self.Attackers[e] and CurTime() - self.Attackers[e] < 30) and true or false)
			net.WriteBool(e:IsPlayer() and self:IsCrew(e))
		end
		net.Send(ply)
	end

	-- one timer per ship: modes / keep firing, radar for the pilot and the gunner (twice a second)
	function ENT:StartWeaponsTimer()
		local id = "AGPHatakWeapons" .. self:EntIndex()
		if (timer.Exists(id)) then return end
		timer.Create(id, 0.5, 0, function()
			if (not IsValid(self)) then timer.Remove(id) return end
			self:WeaponsThink()
			local pilot = self:Pilot()
			if (IsValid(pilot)) then self:SendWeapons(pilot, 1) end
			if (IsValid(self.Gunner)) then self:SendWeapons(self.Gunner, 1) end
		end)
	end

	function ENT:OpenWeapons(ply)
		if (not self:MayCommand(ply)) then
			hkTell(ply, "agp_hkm_t_weap_crew", "The weapons console does not answer you (crew only).")
			return
		end
		self.WeaponUsers = self.WeaponUsers or {}
		self.WeaponUsers[ply] = CurTime()
		self:StartWeaponsTimer()
		self:SendWeapons(ply, 0)
	end

	-- manual gunner: look out of a cannon group, aim with the mouse, left click fires, R next group, E leaves
	function ENT:SetGunner(ply)
		local old = self.Gunner
		if (IsValid(old)) then
			old:SetNWEntity("AGPGunShip", NULL); old.AGPGunShip = nil
			self.Gunner = nil
			local v = old:GetVehicle()
			if (IsValid(v) and v.AGPGunnerSeatOf == self and ply ~= old) then old:ExitVehicle() end   -- E in the gunner seat: stand up
		end
		self.Gunner = ply
		if (IsValid(ply)) then
			ply.AGPGunShip = self; ply.AGPGunFrom = ply:GetPos()
			ply:SetNWEntity("AGPGunShip", self); ply:SetNWInt("AGPGunGroup", 2)
			ply.AGPGunUseFree = CurTime() + 0.6   -- the E that opened the console does not leave again
		end
	end
	function ENT:GunnerView(ply)   -- where the gunner looks from (also used for the PVS)
		local g = self.CannonGroups[math.Clamp(ply:GetNWInt("AGPGunGroup", 2), 1, #self.CannonGroups)]
		local c = self.Cannons[g[2][1]]
		return self:LocalToWorld(c.pos + c.out:GetNormalized() * 420), g
	end

	hook.Add("PlayerEnteredVehicle", "AGP.HatakGunnerSeat", function(ply, veh)
		local ship = veh.AGPGunnerSeatOf
		if (not IsValid(ship)) then return end
		if (not ship:MayCommand(ply)) then hkTell(ply, "agp_hkm_t_cannon_crew", "The cannons do not answer you (crew only).") return end
		ship.WeaponUsers = ship.WeaponUsers or {}
		ship.WeaponUsers[ply] = CurTime()
		ship:StartWeaponsTimer()
		ship:SetGunner(ply)
	end)
	hook.Add("PlayerLeaveVehicle", "AGP.HatakGunnerSeat", function(ply, veh)
		local ship = veh.AGPGunnerSeatOf
		if (IsValid(ship) and ship.Gunner == ply) then ship:SetGunner(nil) end
	end)
	hook.Add("SetupPlayerVisibility", "AGP.HatakGunner", function(ply)
		local ship = ply.AGPGunShip
		if (IsValid(ship)) then AddOriginToPVS((ship:GunnerView(ply))) end
	end)
	-- the gunner stands still at the console; his clicks come as net commands (gunfire / gunnext / gunleave)
	hook.Add("StartCommand", "AGP.HatakGunner", function(ply, cmd)
		local ship = ply.AGPGunShip
		if (not IsValid(ship)) then return end
		if (not ply:Alive() or ship.Gunner ~= ply or ply:GetPos():Distance(ply.AGPGunFrom or ply:GetPos()) > 120) then ship:SetGunner(nil) return end
		cmd:ClearMovement()
		cmd:SetButtons(0)
	end)
	function ENT:GunnerFire(ply, dir)
		local from, g = self:GunnerView(ply)
		-- the client's view direction (in a seat, EyeAngles are relative to the seat: shots went beside the crosshair)
		dir = (dir and dir:LengthSqr() > 0.5) and dir:GetNormalized() or ply:GetAimVector()
		local tr = util.TraceLine({ start = from, endpos = from + dir * self:WeaponRange(),
			filter = function(e) return e ~= self and e.AGPShip ~= self end, mask = MASK_SHOT })
		return self:FireAt(tr.HitPos, tr.Entity, g[2])
	end

	net.Receive("AGP_HatakWeaponsCmd", function(len, ply)
		local ship = net.ReadEntity()
		local cmd = net.ReadString()
		if (not IsValid(ship) or ship:GetClass() ~= "agp_hatak") then return end
		local used = ship.WeaponUsers and ship.WeaponUsers[ply]
		if (not used or CurTime() - used > 600 or not ship:MayCommand(ply)) then return end
		if (cmd == "mode") then
			ship.WeaponMode = math.Clamp(net.ReadUInt(2), 0, 2)
			ship:CrewSayL("weapons", ({ [0] = "agp_hkm_c_w_off", "agp_hkm_c_w_defend", "agp_hkm_c_w_auto" })[ship.WeaponMode], ({ [0] = "off", "defend", "auto" })[ship.WeaponMode])
		elseif (cmd == "target") then
			local e = net.ReadEntity()
			ship.WeaponTarget = IsValid(e) and e or nil
		elseif (cmd == "fire") then
			if (ship:SystemPower("weapons") <= 0) then hkTell(ply, "agp_hkm_t_weap_nopower", "The weapons have no power (engine room).")
			elseif (IsValid(ship.WeaponTarget)) then ship:FireVolley(ship.WeaponTarget) end
		elseif (cmd == "hold") then
			ship.WeaponHold = net.ReadBool()
		elseif (cmd == "manual") then
			ship:SetGunner(ply)
			return
		elseif (cmd == "gunfire" or cmd == "gunnext" or cmd == "gunleave") then
			if (ship.Gunner ~= ply) then return end
			if (cmd == "gunfire") then ship:GunnerFire(ply, net.ReadNormal())
			elseif (cmd == "gunnext") then ply:SetNWInt("AGPGunGroup", ply:GetNWInt("AGPGunGroup", 2) % #ship.CannonGroups + 1)
			elseif (CurTime() > (ply.AGPGunUseFree or 0)) then ship:SetGunner(nil) end
			return
		end
		ship:SendWeapons(ply, 0)
	end)

	-- ===== hijacking with the control crystal (admin setting agp_hatak_hijack = 1) =====
	-- the crystal hides at a random spot of the interior; a stranger carries it to the slot on the pel'tak and holds
	-- it there for 40 s; then he (and his friends) command the ship. The original crew takes it out at the slot.
	ENT.CrystalInsertTime = 40
	function ENT:IsOriginalCrew(ply)
		if (not IsValid(ply) or not ply:IsPlayer()) then return false end
		local own = self:ShipOwner()
		if (not IsValid(own) or ply == own) then return true end
		if (own.CPPIGetFriends) then for _, f in ipairs(own:CPPIGetFriends() or {}) do if (f == ply) then return true end end end
		return false
	end

	function ENT:SpawnCrystal()
		local L = self.Layout2
		if (IsValid(self.CrystalCarrier)) then self.CrystalCarrier.AGPCrystalShip = nil; self.CrystalCarrier:SetNWFloat("AGPCrystalInsert", 0) end
		self.CrystalCarrier, self.Inserting = nil, nil
		if (cv("agp_hatak_hijack", 1) ~= 1 or not IsValid(self.Interior) or not L.crystalSpots) then
			if (IsValid(self.Crystal)) then self.Crystal:Remove() end
			return
		end
		local c = self.Crystal
		if (not IsValid(c)) then
			c = ents.Create("agp_hatak_crystal")
			if (not IsValid(c)) then return end
			c:Spawn(); c:Activate()
			self.Crystal = self:AddPart(c)
		end
		c.Inserted = nil
		c:SetNoDraw(false); c:SetNotSolid(false)
		self:Place(c, L.crystalSpots[math.random(#L.crystalSpots)], math.random(0, 359))
	end

	function ENT:CrystalPickUp(ply)
		local c = self.Crystal
		if (not IsValid(c) or IsValid(self.CrystalCarrier)) then return end
		self.CrystalCarrier = ply
		ply.AGPCrystalShip = self
		c:SetNoDraw(true); c:SetNotSolid(true)
		c:EmitSound("button/ring_button1.mp3", 60, 140)
		if (self:IsCrew(ply)) then hkTell(ply, "agp_hkm_t_carry_own", "You carry the ship's control crystal.") else hkTell(ply, "agp_hkm_t_found", "You found a Goa'uld control crystal. Insert it in the crystal slot on the pel'tak to take the ship.") end
	end

	function ENT:CrystalSlotUse(ply, slot)
		if (cv("agp_hatak_hijack", 1) ~= 1) then hkTell(ply, "agp_hkm_t_slot_sealed", "The crystal slot is sealed (server setting).") return end
		if (IsValid(self.Hijacker)) then
			if (self:IsOriginalCrew(ply)) then   -- the original crew pulls the crystal: control is back
				local who = self.Hijacker
				self.Hijacker = nil
				self:SetNWEntity("AGPHijacker", NULL)
				self:SpawnCrystal()
				slot:EmitSound("button/ring_button2.mp3", 70)
				if (IsValid(who)) then self:CrewSayL("", "agp_hkm_c_crystal_removed_by", "control crystal removed - the ship obeys its crew again (%s lost it)", false, who:Nick()) else self:CrewSayL("", "agp_hkm_c_crystal_removed", "control crystal removed - the ship obeys its crew again", false) end
			else
				hkTell(ply, "agp_hkm_t_slot_taken", "The control crystal sits in the slot. Only the original crew can pull it.")
			end
			return
		end
		if (self.Inserting) then
			if (self:IsOriginalCrew(ply)) then   -- the crew stops an insertion
				local h = self.Inserting.ply
				self.Inserting = nil
				if (IsValid(h)) then h:SetNWFloat("AGPCrystalInsert", 0) end
				self:SpawnCrystal()
				self:CrewSayL("", "agp_hkm_c_crew_pulled", "the crew pulled the control crystal out of the slot in time", false)
			end
			return
		end
		if (self.CrystalCarrier ~= ply) then hkTell(ply, "agp_hkm_t_slot_what", "Crystal slot: it takes the ship's control crystal.") return end
		if (self:IsCrew(ply)) then hkTell(ply, "agp_hkm_t_already", "The ship already obeys you.") return end
		self.Inserting = { ply = ply, t0 = CurTime(), pos = ply:GetPos() }
		ply:SetNWFloat("AGPCrystalInsert", CurTime() + self.CrystalInsertTime)
		slot:EmitSound("ambient/machines/teleport1.wav", 70, 140)
		self:CrewSayL("alert", "agp_hkm_c_intruder", "an intruder is inserting a control crystal on the pel'tak!", false)
		if (self.SetAlarm) then self:SetAlarm(true, "agp_hkm_r_intruder") end
		local id = "AGPHatakCrystal" .. self:EntIndex()
		timer.Create(id, 0.5, 0, function()
			local ins = IsValid(self) and self.Inserting
			if (not ins) then timer.Remove(id) return end
			local p = ins.ply
			if (not IsValid(p) or not p:Alive() or p:GetPos():Distance(ins.pos) > 120) then   -- left the slot: try again
				self.Inserting = nil
				if (IsValid(p)) then p:SetNWFloat("AGPCrystalInsert", 0); hkTell(p, "agp_hkm_t_left_slot", "You left the slot - insertion stopped.") end
				timer.Remove(id)
				return
			end
			if (CurTime() - ins.t0 >= self.CrystalInsertTime) then
				timer.Remove(id)
				self.Inserting = nil
				p:SetNWFloat("AGPCrystalInsert", 0)
				self.Hijacker = p
				self:SetNWEntity("AGPHijacker", p)
				self.CrystalCarrier = nil; p.AGPCrystalShip = nil
				local c = self.Crystal
				if (IsValid(c)) then   -- the crystal now sits in the slot, visible
					c.Inserted = true
					c:SetNoDraw(false); c:SetNotSolid(true)
					c:SetPos(slot:LocalToWorld(Vector(4, 0, 30))); c:SetAngles(slot:LocalToWorldAngles(Angle(0, 90, 0)))
				end
				self.WeaponMode = 0; self.WeaponHold = nil; self.WeaponTarget = nil
				for _, st in ipairs({ self.Seat, self.ThroneSeat }) do
					if (IsValid(st) and IsValid(st:GetDriver()) and not self:IsCrew(st:GetDriver())) then st:GetDriver():ExitVehicle() end
				end
				self:CrewSayL("", "agp_hkm_c_taken", "%s has taken command of the ship!", false, p:Nick())
			end
		end)
	end

	hook.Add("PlayerDeath", "AGP.HatakCrystal", function(ply)
		local ship = ply.AGPCrystalShip
		if (IsValid(ship) and ship.CrystalCarrier == ply) then ship:SpawnCrystal() end
	end)
	hook.Add("PlayerDisconnected", "AGP.HatakCrystal", function(ply)
		local ship = ply.AGPCrystalShip
		if (IsValid(ship) and ship.CrystalCarrier == ply) then ship:SpawnCrystal() end
		for _, s in ipairs(ents.FindByClass("agp_hatak")) do
			if (s.Hijacker == ply) then s.Hijacker = nil; s:SetNWEntity("AGPHijacker", NULL); s:SpawnCrystal() end
		end
	end)

	-- ===== engine room: power (like Atlantis' ZPM hub: the core's hub feeds the ship, the trays run the systems) =====
	-- Core power: 3 crystals on the hub (a third each) + running naquadah generators of the room (backup, 15 % each).
	-- Systems: weapons, hyperdrive, sublight engines, 3 crystals per tray. A system gets (good crystals in its tray / 3)
	-- x core power x the routing chosen on the engineering console. Weapons recharge slower (no shots at 0), engines
	-- push less (no thrust at 0), the hyperdrive charges longer (offline under 30 %). Anyone can pull crystals (E) -
	-- sabotage, as in the series. Hits on the hull burn crystals out; burnt ones recharge in the spare rack.
	-- Ships without the engine room (old interior) always have full power.
	ENT.PowerSystems = { "weapons", "hyperdrive", "engines", "shields" }
	ENT.PowerNames = { core = "Power core", weapons = "Weapons", hyperdrive = "Hyperdrive", engines = "Sublight engines", spare = "Spare rack",
		rings = "Ring transporters", doors = "Doors", sensors = "Sensors", comms = "Communication", zpm = "Fourth arm of the hub", shields = "Shields" }
	ENT.ArmCrystalPower = 0.15   -- one more crystal on the hub's 4th arm (like a running generator)
	ENT.ZPMPower = 1.3           -- a ZPM on the 4th arm: full power and 30 % more, as long as it has energy
	ENT.ZPMDrain = 40000         -- ZPM energy per second while it powers the ship
	ENT.DataGroups = { rings = true, doors = true, sensors = true, comms = true }   -- computer core racks: blue data crystals
	ENT.PowerRoutes = { balanced = true, weapons = true, hyperdrive = true, engines = true, shields = true }
	ENT.CrystalRecharge = 60       -- s for a burnt crystal in the spare rack
	ENT.CrystalBurnDamage = 1500   -- every this much damage to the hull: a 50 % chance that one crystal burns out
	ENT.GeneratorPower = 0.15
	util.AddNetworkString("AGP_HatakPower")
	util.AddNetworkString("AGP_HatakPowerCmd")

	function ENT:BuildPower()
		local P = self.Layout2.power
		if (not P) then return end
		self.PowerSlots = {}
		for group, list in pairs(P) do
			self.PowerSlots[group] = {}
			for i, lp in ipairs(list) do
				local slot = { group = group, pos = lp, data = self.DataGroups[group] or false }
				self.PowerSlots[group][i] = slot
				if ((group ~= "spare" or i <= 2) and group ~= "zpm") then   -- 2 spares in the rack, 2 free places; the 4th arm starts free
					local c = ents.Create("agp_hatak_powercrystal")
					if (IsValid(c)) then
						c:SetData(self.DataGroups[group] or false)
						c:Spawn(); c:Activate()
						self:AddPart(c)
						self:PowerSlotPut(slot, c)
					end
				end
			end
		end
		self.PowerRoute = "balanced"
		local id = "AGPHatakPower" .. self:EntIndex()
		timer.Create(id, 1, 0, function()
			if (not IsValid(self)) then timer.Remove(id) return end
			self:PowerThink()
		end)
		self:PowerThink()
	end

	function ENT:PowerSlotPut(slot, c)
		slot.crystal = c
		c.Slot, c.Carrier, c.RechargeAt, c.StrangerPulled = slot, nil, nil, nil
		c:SetNoDraw(false); c:SetNotSolid(false)
		if (slot.group == "core" or slot.group == "zpm" or slot.data) then   -- hub arms and data racks: standing upright (long axis X, centred)
			local fr = self:Frame()
			c:SetPos(fr:LocalToWorld(slot.pos + Vector(0, 0, slot.data and 12 or 18)))
			c:SetAngles(fr:LocalToWorldAngles(Angle(-90, 0, 0)))
		else   -- lying across the tray / rack
			self:Place(c, slot.pos, slot.group == "spare" and 0 or 90)
		end
		c.NoTakeUntil = CurTime() + 0.5   -- the E that put it in does not pull it out again
	end

	function ENT:PowerCrystalTake(ply, c)
		if (IsValid(ply.AGPPowerCarry) or (c.NoTakeUntil or 0) > CurTime() or IsValid(c.Carrier)) then return end
		local slot = c.Slot
		if (slot and not self:IsCrew(ply)) then   -- strangers: only so many crystals out at once (admin setting)
			local out, limit = 0, cv("agp_hatak_crystal_pull", 2)
			for _, e in ipairs(self.Parts) do if (IsValid(e) and e.StrangerPulled) then out = out + 1 end end
			if (out >= limit) then
				if (limit == 0) then hkTell(ply, "agp_hkm_t_locked_all", "The crystals are locked in place (server setting).") else hkTell(ply, "agp_hkm_t_locked_n", "The other crystals are locked: strangers can pull only %s at once (server setting).", limit) end
				return
			end
			c.StrangerPulled = true
			if (self.SetAlarm) then self:SetAlarm(true, "agp_hkm_r_sabotage", ply:Nick()) end
		end
		if (slot and self.Log) then self:LogL("agp_hkm_l_pulled", "%s pulled a crystal (%s)", ply:Nick(), ("agp_hkm_p_" .. slot.group)) end
		if (slot) then slot.crystal = nil; c.Slot = nil end
		c:SetNoDraw(true); c:SetNotSolid(true)
		c.Carrier = ply
		ply.AGPPowerCarry, ply.AGPPowerCarryAt = c, CurTime()
		ply:SetNWInt("AGPPowerCarry", c:GetData() and 3 or (c:GetBurnt() and 2 or 1))   -- 1 good, 2 burnt (the HUD hint)
		c:EmitSound("button/ring_button1.mp3", 60, 120)
		-- the HUD shows what is carried; the chat line explains it once
		if (AGP.FirstTime and AGP.FirstTime(ply, "hatak_crystal_carry")) then
			hkTell(ply, "agp_hkm_t_carry", "You carry %s. E at a free slot puts it in.", (c:GetData() and "agp_hkm_k_data" or (c:GetBurnt() and "agp_hkm_k_burnt" or "agp_hkm_k_power")))
		end
		self:PowerThink()
	end

	-- E while carrying a crystal: into the nearest free slot where the player looks (within reach)
	function ENT:PowerCrystalInsert(ply)
		local c = ply.AGPPowerCarry
		if (not self.PowerSlots or CurTime() - (ply.AGPPowerCarryAt or 0) < 0.3) then return end
		local tr = ply:GetEyeTrace()
		local at = tr.HitPos:Distance(ply:EyePos()) < 150 and tr.HitPos or ply:EyePos() + ply:GetAimVector() * 60
		local best, bd = nil, 70
		for _, list in pairs(self.PowerSlots) do
			for _, s in ipairs(list) do
				if (not IsValid(s.crystal) and (s.data == c:GetData() or s.group == "spare") and not (s.group == "zpm" and IsValid(self.HubZPM))) then   -- the spare rack recharges both kinds   -- power crystals into power slots, data into the racks
					local d = self:Frame():LocalToWorld(s.pos):Distance(at)
					if (d < bd) then best, bd = s, d end
				end
			end
		end
		if (not best) then return end
		ply.AGPPowerCarry = nil
		ply:SetNWInt("AGPPowerCarry", 0)
		self:PowerSlotPut(best, c)
		c:EmitSound("button/ring_button2.mp3", 60, 110)
		self:LogL("agp_hkm_l_put", "%s put a crystal in (%s)", ply:Nick(), ("agp_hkm_p_" .. best.group))
		if (best.group == "spare" and c:GetBurnt()) then hkTell(ply, "agp_hkm_t_recharge", "The burnt crystal recharges in the rack (%s s).", self.CrystalRecharge) end
		self:PowerThink()
	end
	-- a carried crystal falls to the floor when its carrier dies or leaves
	function ENT:PowerCrystalDrop(ply)
		local c = ply.AGPPowerCarry
		ply.AGPPowerCarry = nil
		ply:SetNWInt("AGPPowerCarry", 0)
		if (not IsValid(c)) then return end
		c.Carrier = nil
		c:SetPos(ply:GetPos() + Vector(0, 0, 2)); c:SetAngles(Angle(0, math.random(0, 359), 0))
		c:SetNoDraw(false); c:SetNotSolid(false)
	end
	hook.Add("KeyPress", "AGP.HatakPowerCrystal", function(ply, key)
		if (key ~= IN_USE or not ply.AGPPowerCarry) then return end
		local c = ply.AGPPowerCarry
		if (not IsValid(c) or not IsValid(c.AGPShip)) then ply.AGPPowerCarry = nil; ply:SetNWInt("AGPPowerCarry", 0) return end
		c.AGPShip:PowerCrystalInsert(ply)
	end)
	hook.Add("PlayerDeath", "AGP.HatakPowerCrystal", function(ply)
		local c = ply.AGPPowerCarry
		if (IsValid(c) and IsValid(c.AGPShip)) then c.AGPShip:PowerCrystalDrop(ply) end
	end)
	hook.Add("PlayerDisconnected", "AGP.HatakPowerCrystal", function(ply)
		local c = ply.AGPPowerCarry
		if (IsValid(c) and IsValid(c.AGPShip)) then c.AGPShip:PowerCrystalDrop(ply) end
	end)

	function ENT:CrystalsGood(group)
		local list = self.PowerSlots and self.PowerSlots[group] or {}
		local n = 0
		for _, s in ipairs(list) do if (IsValid(s.crystal) and not s.crystal:GetBurnt()) then n = n + 1 end end
		return n, #list
	end
	function ENT:Generators()
		local on, all = 0, 0
		for _, e in ipairs(self.Parts or {}) do
			if (IsValid(e) and e:GetClass() == "naquadah_generator") then
				all = all + 1
				if (e.enabled and not e.depleted) then on = on + 1 end
			end
		end
		return on, all
	end
	function ENT:CorePower()
		if (not self.PowerSlots) then return 1 end
		if (self:ZPMActive()) then return self.ZPMPower end
		local n, total = self:CrystalsGood("core")
		local arm = (self:CrystalsGood("zpm")) * self.ArmCrystalPower
		return math.min(1, (total > 0 and n / total or 1) + (self:Generators()) * self.GeneratorPower + arm)
	end
	function ENT:ZPMActive()
		local z = self.HubZPM
		return IsValid(z) and (z.Energy or 0) > 0
	end
	-- the 4th arm: a ZPM brought close (gravity gun / physgun) sits down on it; pulled away again = out
	function ENT:ZPMThink(dt)
		local slot = self.PowerSlots.zpm and self.PowerSlots.zpm[1]
		if (not slot) then return end
		local spot = self:Frame():LocalToWorld(slot.pos)
		local z = self.HubZPM
		if (IsValid(z)) then
			local held = z.IsPlayerHolding and z:IsPlayerHolding()
			if (held or z:GetPos():Distance(z.AGPHubSpot or spot) > 20) then   -- taken out
				self.HubZPM, z.AGPHubShip = nil, nil
				self:CrewSayL("engine", "agp_hkm_c_zpm_out", "the ZPM was taken out of the power core", false)
			else
				local e = math.max(0, (z.Energy or 0) - self.ZPMDrain * dt)
				z.Energy = e
				if (e <= 0 and not z.AGPHubEmpty) then z.AGPHubEmpty = true; self:CrewSayL("engine", "agp_hkm_c_zpm_empty", "the ZPM is empty", false) end
			end
			return
		end
		if (IsValid(slot.crystal)) then return end
		for _, e in ipairs(ents.FindInSphere(spot, 40)) do
			if (e.IsZPM and not IsValid(e:GetParent()) and not (e.IsPlayerHolding and e:IsPlayerHolding()) and not IsValid(e.AGPHubShip)) then
				local ph = e:GetPhysicsObject()
				if (IsValid(ph)) then ph:EnableMotion(false) end
				local up = e:OBBMins().z
				e:SetAngles(self:Frame():LocalToWorldAngles(Angle(0, 90, 0)))
				e:SetPos(spot - self:Frame():GetUp() * up)
				e.AGPHubSpot = e:GetPos()
				e.AGPHubShip, e.AGPHubEmpty = self, nil
				self.HubZPM = e
				e:EmitSound("button/ring_button2.mp3", 70, 90)
				self:CrewSayL("engine", "agp_hkm_c_zpm_in", "a ZPM sits in the power core - power %s %%", false, math.Round(self.ZPMPower * 100))
				return
			end
		end
	end
	-- 0 .. 1.3 (1 = full power; the routing gives one system 130 %, the others 85 %)
	function ENT:SystemPower(name)
		if (not self.PowerSlots or not self.PowerSlots[name]) then return 1 end
		local n, total = self:CrystalsGood(name)
		local route = self.PowerRoute or "balanced"
		local mul = (route == "balanced") and 1 or (route == name and 1.3 or 0.85)
		return (total > 0 and n / total or 1) * self:CorePower() * mul
	end

	function ENT:PowerThink()
		if (not self.PowerSlots) then return end
		if (self.Cloaked and not self:CanCloak()) then self:SetCloak(false) end   -- power lost or switched off by the admin
		self:ZPMThink(math.min(CurTime() - (self.LastPowerThink or CurTime()), 2))
		self.LastPowerThink = CurTime()
		for _, s in ipairs(self.PowerSlots.spare or {}) do   -- burnt crystals recharge in the rack
			local c = s.crystal
			if (IsValid(c) and c:GetBurnt()) then
				c.RechargeAt = c.RechargeAt or CurTime() + self.CrystalRecharge
				if (CurTime() >= c.RechargeAt) then
					c:SetBurnt(false); c:UpdateLook(); c.RechargeAt = nil
					c:EmitSound("ambient/energy/whiteflash.wav", 55, 160)
				end
			end
		end
		self.PowerLevel = self.PowerLevel or {}
		self:SetNWFloat("AGPPowerCore", self:CorePower())
		if (IsValid(self.CoreColumn)) then self.CoreColumn:SetPower(self:CorePower()) end
		for _, name in ipairs(self.PowerSystems) do
			local p = self:SystemPower(name)
			local old = self.PowerLevel[name]
			self.PowerLevel[name] = p
			self:SetNWFloat("AGPPower_" .. name, p)
			if (old and (old > 0) ~= (p > 0)) then
				if (p > 0) then self:CrewSayL("engine", "agp_hkm_c_online", "%s back online", false, ("agp_hkm_p_" .. name)) else self:CrewSayL("engine", "agp_hkm_c_offline_power", "%s OFFLINE - no power", false, ("agp_hkm_p_" .. name)) end
			end
		end
		self.ComputerState = self.ComputerState or {}
		for _, name in ipairs(self.ComputerSystems) do
			local ok = self:ComputerOK(name)
			if (self.ComputerState[name] ~= nil and self.ComputerState[name] ~= ok) then
				if (ok) then self:CrewSayL("computer", "agp_hkm_c_online", "%s back online", true, ("agp_hkm_p_" .. name)) else self:CrewSayL("computer", "agp_hkm_c_offline_crystals", "%s OFFLINE - crystals missing", true, ("agp_hkm_p_" .. name)) end
				if (name == "doors") then self:UpdateDoorLocks() end
				if (name == "comms" and not ok) then self:SetAlarm(false) end
			end
			self.ComputerState[name] = ok
		end
		self:TrackAboard()
		self:KelnoreemThink()
		self:ShieldThink(math.min(CurTime() - (self.LastShieldThink or CurTime()), 2))
		self:LifeSupportThink()
		self.LastShieldThink = CurTime()
		if (self.SetWire) then
			self:SetWire("Power", math.Round(self:CorePower() * 100))
			self:SetWire("Weapons Power", math.Round(self.PowerLevel.weapons * 100))
			self:SetWire("Hyperdrive Power", math.Round(self.PowerLevel.hyperdrive * 100))
			self:SetWire("Engines Power", math.Round(self.PowerLevel.engines * 100))
		end
	end

	function ENT:BurnCrystal()
		if (not self.PowerSlots) then return end
		local good = {}
		for _, g in ipairs({ "core", "weapons", "hyperdrive", "engines", "shields" }) do
			for _, s in ipairs(self.PowerSlots[g] or {}) do
				if (IsValid(s.crystal) and not s.crystal:GetBurnt()) then good[#good + 1] = s end
			end
		end
		if (#good == 0) then return end
		local s = good[math.random(#good)]
		local c = s.crystal
		c:SetBurnt(true); c:UpdateLook()
		local fx = EffectData(); fx:SetOrigin(c:WorldSpaceCenter()); fx:SetMagnitude(2); fx:SetScale(1); fx:SetRadius(4)
		util.Effect("ElectricSpark", fx, true, true)
		c:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 75)
		self:CrewSayL("engine", "agp_hkm_c_burnt", "%s: a crystal burnt out", false, ("agp_hkm_p_" .. s.group))
		self:PowerThink()
	end

	-- engineering console: the power monitor
	function ENT:SendPower(ply)
		local function st(s)
			local c = s.crystal
			if (not IsValid(c)) then return 0, 0 end
			if (not c:GetBurnt()) then return 1, 0 end
			return 2, c.RechargeAt and math.max(0, c.RechargeAt - CurTime()) or 0
		end
		net.Start("AGP_HatakPower")
		net.WriteEntity(self)
		net.WriteString(self.PowerRoute or "balanced")
		net.WriteFloat(self:CorePower())
		net.WriteFloat(self:GetNWFloat("AGPHull", 1))
		local on, all = self:Generators()
		net.WriteUInt(on, 4); net.WriteUInt(all, 4)
		local arm = self.PowerSlots.zpm and self.PowerSlots.zpm[1]   -- 4th arm: 0 free, 1 crystal, 2 burnt crystal, 3 ZPM
		local z = self.HubZPM
		net.WriteUInt(IsValid(z) and 3 or (arm and IsValid(arm.crystal) and (arm.crystal:GetBurnt() and 2 or 1) or 0), 2)
		net.WriteFloat(IsValid(z) and (z.Energy or 0) / math.max(z.MaxEnergy or 1, 1) * 100 or 0)
		for _, g in ipairs({ "core", "weapons", "hyperdrive", "engines", "shields", "spare" }) do
			local list = self.PowerSlots[g] or {}
			net.WriteUInt(#list, 4)
			for _, s in ipairs(list) do
				local k, t = st(s)
				net.WriteUInt(k, 2); net.WriteFloat(t)
			end
			net.WriteFloat(g ~= "spare" and g ~= "core" and self:SystemPower(g) or 0)
		end
		net.WriteBool(self:MayCommand(ply))
		net.Send(ply)
	end
	function ENT:OpenPower(ply)
		if (not self.PowerSlots) then return end
		self.PowerUsers = self.PowerUsers or {}
		self.PowerUsers[ply] = CurTime()
		self:SendPower(ply)
	end
	net.Receive("AGP_HatakPowerCmd", function(len, ply)
		local ship = net.ReadEntity()
		local cmd = net.ReadString()
		if (not IsValid(ship) or ship:GetClass() ~= "agp_hatak" or not ship.PowerSlots) then return end
		local used = ship.PowerUsers and ship.PowerUsers[ply]
		if (not used or CurTime() - used > 600) then return end
		if (cmd == "route") then
			local r = net.ReadString()
			if (not ship:MayCommand(ply)) then hkTell(ply, "agp_hkm_t_eng_crew", "The engineering console does not answer you (crew only).") return end
			if (ship.PowerRoutes[r] and r ~= ship.PowerRoute) then
				ship.PowerRoute = r
				ship:PowerThink()
				if (r == "balanced") then ship:CrewSayL("engine", "agp_hkm_c_route_bal", "power balanced", false) else ship:CrewSayL("engine", "agp_hkm_c_route", "power to: %s", false, ("agp_hkm_p_" .. r)) end
			end
		end
		ship:SendPower(ply)
	end)

	-- ===== computer core: data crystal racks, ship log, address database, security (alarm, lockdown), self-destruct =====
	-- Racks (Layout2.power rings / doors / sensors / comms, blue data crystals): a function works while at least 2 of
	-- its 3 crystals sit in the rack. Rings: no ring transport. Doors: every door stays as it is (locked). Sensors:
	-- the radar is blind (no auto targets; manual gunner still fires). Communication: no crew messages, no alarm
	-- (self-destruct and system warnings still come through).
	ENT.ComputerSystems = { "rings", "doors", "sensors", "comms" }
	util.AddNetworkString("AGP_HatakComputer")
	util.AddNetworkString("AGP_HatakComputerCmd")

	function ENT:ComputerOK(name)
		if (not self.PowerSlots or not self.PowerSlots[name]) then return true end   -- no computer core (old interior)
		return (self:CrystalsGood(name)) >= 2
	end

	-- ship log: everything the crew is told, plus who comes aboard / leaves, crystal pulls, attacks, jumps
	function ENT:Log(msg, key, fallback, args)   -- { time, English line, key, English text, values }
		self.ShipLog = self.ShipLog or {}
		table.insert(self.ShipLog, 1, { os.date("%H:%M:%S"), msg, key, fallback, args })
		self.ShipLog[201] = nil
	end
	function ENT:LogL(key, fallback, ...)
		local args = { ... }
		self:Log(hkmEnglish(fallback, args), key, fallback, args)
	end
	function ENT:TrackAboard()
		local it = self.Interior
		if (not IsValid(it)) then return end
		local now = {}
		for _, p in ipairs(player.GetAll()) do
			if (p:Alive() and p:GetPos():DistToSqr(it:GetPos()) < 25000000) then   -- within 5000 of the interior: aboard
				now[p] = true
				if (self.Aboard and not self.Aboard[p]) then if (self:IsCrew(p)) then self:LogL("agp_hkm_l_aboard", "%s came aboard", p:Nick()) else self:LogL("agp_hkm_l_aboard_stranger", "%s came aboard (stranger)", p:Nick()) end end
			end
		end
		for p in pairs(self.Aboard or {}) do
			if (not now[p] and IsValid(p)) then self:LogL("agp_hkm_l_left", "%s left the ship", p:Nick()) end
		end
		self.Aboard = now
	end

	-- alarm: red flashing light in every brazier and the klaxon for everyone aboard (needs the communication crystals)
	function ENT:SetAlarm(on, why, ...)   -- why: a key agp_hkm_r_* (its values after it) or an English line
		on = on and true or false
		if (on and not self:ComputerOK("comms")) then return false end
		if (on == (self.Alarm or false)) then return true end
		self.Alarm = on
		self:SetNWBool("AGPAlarm", on)
		for _, e in ipairs(self.Parts or {}) do
			if (IsValid(e) and e:GetClass() == "agp_brazier") then e:SetAlarm(on) end
		end
		if (not on) then self:CrewSayL("", "agp_hkm_c_alarm_off", "alarm off", true) elseif (why) then self:CrewSayL("", "agp_hkm_c_alarm_why", "ALARM - %s", true, table.concat({ why, ... }, "\31")) else self:CrewSayL("", "agp_hkm_c_alarm", "ALARM", true) end
		return true
	end
	-- lockdown: every door but the hangar door closes and locks; crew still opens them at the door panels
	function ENT:UpdateDoorLocks()
		local lock = self.Lockdown or not self:ComputerOK("doors")
		for _, e in ipairs(self.Parts or {}) do
			if (IsValid(e) and e:GetClass() == "agp_goauld_door" and e.AGPDoorName ~= "hangar") then
				if (self.Lockdown and e:GetOpened()) then e:SetLocked(false); e:SetDoorOpen(false, true) end   -- close first
				e:SetLocked(lock)
			end
		end
	end
	function ENT:SetLockdown(on)
		self.Lockdown = on and true or false
		self:SetNWBool("AGPLockdown", self.Lockdown)
		self:UpdateDoorLocks()
		if (self.Lockdown) then self:CrewSayL("", "agp_hkm_c_lockdown", "LOCKDOWN - all doors closed and locked", true) else self:CrewSayL("", "agp_hkm_c_lockdown_off", "lockdown lifted", true) end
	end
	function ENT:DoorPanelUse(door, ply)
		if (not self:ComputerOK("doors")) then hkTell(ply, "agp_hkm_t_door_off", "The door does not answer (computer core: door crystals missing).") return end
		if (self.Lockdown) then
			if (not self:IsCrew(ply)) then door:EmitSound("button/ring_button2.mp3", 70); hkTell(ply, "agp_hkm_t_door_locked", "Lockdown: the door is locked.") return end
			door:SetLocked(false); door:SetDoorOpen(not door:GetOpened()); door:SetLocked(true)   -- crew passes, the door stays locked
			return
		end
		door:Use(ply, ply)
	end

	-- ===== weapons aboard: a staff weapon from the wall, a zat from a chest =====
	ENT.WeaponBack = 120   -- seconds until a taken staff weapon is back on the wall
	function ENT:TakeWeapon(prop, ply, class)
		if (not weapons.GetStored(class)) then return end
		if (ply:HasWeapon(class)) then ply:SelectWeapon(class) hkTell(ply, "agp_hkm_t_have_one", "You already carry one.") return end
		ply:Give(class); ply:SelectWeapon(class)
		prop:EmitSound("items/ammo_pickup.wav", 60)
		if (class == "weapon_staff") then   -- the staff leaves the wall (a chest stays)
			prop:SetNoDraw(true); prop:SetNotSolid(true); prop.AGPTaken = true
			timer.Simple(self.WeaponBack, function()
				if (IsValid(prop)) then prop:SetNoDraw(false); prop:SetNotSolid(false); prop.AGPTaken = nil end
			end)
		end
		if (class == "weapon_staff") then self:LogL("agp_hkm_l_took_staff", "%s took a staff weapon", ply:Nick()) else self:LogL("agp_hkm_l_took_zat", "%s took a zat", ply:Nick()) end
	end

	-- ===== Jaffa barracks: bunks (respawn aboard), armour chest, kel'no'reem room =====
	ENT.ArmourCooldown = 60
	function ENT:BunkUse(ply)
		if (not self:IsCrew(ply)) then hkTell(ply, "agp_hkm_t_bunk_crew", "These bunks are for the crew.") return end
		if (ply.AGPBunkShip == self) then
			ply.AGPBunkShip = nil
			hkTell(ply, "agp_hkm_t_bunk_off", "You gave up your bunk - you respawn where you normally do.")
		else
			ply.AGPBunkShip = self
			hkTell(ply, "agp_hkm_t_bunk_on", "Your bunk in the Jaffa barracks: you respawn aboard this ship.")
			self:LogL("agp_hkm_l_bunk", "%s took a bunk in the barracks", ply:Nick())
		end
	end
	hook.Add("PlayerSpawn", "AGP.HatakBunk", function(ply)
		if (ply.AGPShipLeaving) then return end   -- AGP 2026-11-08: getting out of a ship is no respawn (AGP.ShipRespawnPilot)
		local ship = ply.AGPBunkShip
		if (not IsValid(ship) or not IsValid(ship.BunkConsole) or not ship:IsCrew(ply) or ship.Destroying) then return end   -- (not into a ship that is blowing up)
		timer.Simple(0, function()
			if (not IsValid(ply) or not IsValid(ship) or not IsValid(ship.BunkConsole)) then return end
			local c = ship.BunkConsole
			ply:SetPos(c:LocalToWorld(Vector(-70, 0, 4)))
			ply:SetEyeAngles(c:GetAngles())
		end)
	end)
	function ENT:ArmourUse(ply)
		ply.AGPArmourAt = ply.AGPArmourAt or {}
		local last = ply.AGPArmourAt[self] or -999
		if (CurTime() - last < self.ArmourCooldown) then
			hkTell(ply, "agp_hkm_t_armour_wait", "The armour chest is empty for you - %d s.", math.ceil(self.ArmourCooldown - (CurTime() - last)))
			return
		end
		if (ply:Armor() >= 100) then hkTell(ply, "agp_hkm_t_armour_full", "You already wear full Jaffa armour.") return end
		ply.AGPArmourAt[self] = CurTime()
		ply:SetArmor(math.min(100, ply:Armor() + 50))
		ply:EmitSound("items/battery_pickup.wav", 70)
		hkTell(ply, "agp_hkm_t_armour", "Jaffa armour: +50.")
	end
	-- kel'no'reem: kneel (crouch) on a mat; every second +3 health up to the maximum
	function ENT:KelnoreemThink()
		local mats, it = self.Layout2.kelnoreem, self.Interior
		if (not mats or not IsValid(it)) then return end
		for _, p in ipairs(player.GetAll()) do
			local on = false
			if (p:Alive() and p:Crouching() and not p:InVehicle() and p:GetPos():DistToSqr(it:GetPos()) < 25000000) then
				local l = it:WorldToLocal(p:GetPos())
				for _, m in ipairs(mats) do
					if (math.abs(l.x - m.x) < 40 and math.abs(l.y - m.y) < 40 and math.abs(l.z - m.z) < 20) then on = true break end
				end
			end
			if (on) then
				if (p:Health() < p:GetMaxHealth()) then p:SetHealth(math.min(p:GetMaxHealth(), p:Health() + 3)) end
				if (not p:GetNWBool("AGPKelnoreem")) then p:SetNWBool("AGPKelnoreem", true) end
			elseif (p:GetNWBool("AGPKelnoreem") and p.AGPKelShip == self) then
				p:SetNWBool("AGPKelnoreem", false)
			end
			if (on) then p.AGPKelShip = self end
		end
	end

	-- ===== shields (shield room): a golden shell around the hull takes the hits while it holds =====
	-- Strength 0..100. Every hit costs damage / ShieldAbsorb; at 0 the shield fails and comes back on its own at 25.
	-- Recharge per second: ShieldRecharge x shield power (the shield room's crystal tray x core x routing).
	-- Console in the shield room (crew), Wire input Shield, outputs Shield / Shield Strength.
	ENT.ShieldAbsorb = 400 -- AGP 2026-10-30 balance: 100 % = 40000 damage (was 6000: one volley of another Ha'tak)
	ENT.ShieldBeamDrain = 0.7   -- continuous beams (IsBeamDamage) drain it gentler: the Asuran gate weapon ~25 s, not ~15 s
	ENT.ShieldRecharge = 2
	util.AddNetworkString("AGP_HatakShieldHit")
	function ENT:ShieldUp() return self.ShieldOn and not self.ShieldDown and self:SystemPower("shields") > 0 end
	function ENT:SetShield(on, who)
		on = on and true or false
		if (on and not self.ShieldOn and self:SystemPower("shields") <= 0) then   -- no power for the emitter: nothing to raise
			if (IsValid(who) and who:IsPlayer()) then AGP.Say(who, "agp_hatak_shield_nopower", "[Ha'tak] The shields have no power (engine room).") end
			self:ShieldThink(0)
			return
		end
		if (on and self.Cloaked) then self:SetCloak(false) end   -- shields and cloak share the emitter
		if (on == (self.ShieldOn or false)) then return end
		self.ShieldOn = on
		self:EmitSound(on and "shields/shield_engage.mp3" or "shields/shield_disengage.mp3", 120)
		if (on) then self:CrewSayL("", "agp_hkm_c_shields_raised", "shields raised", false) else self:CrewSayL("", "agp_hkm_c_shields_lowered", "shields lowered", false) end
		self:ShieldThink(0)
	end
	function ENT:ShieldHit(dmg, amount)
		local a = dmg:GetAttacker()
		if (not self.ShieldOn and self.ShieldAuto ~= false and not self.Cloaked and IsValid(a) and a ~= self and not self:IsCrew(a)
			and self:SystemPower("shields") > 0) then
			self:SetShield(true)   -- auto: raised when the ship is attacked (the first hit still lands; not without power)
			return false
		end
		if (not self:ShieldUp()) then return false end
		amount = (amount or dmg:GetDamage()) * (self:IsBeamDamage(dmg) and self.ShieldBeamDrain or 1)
		-- (2026-11-12) a hit bigger than what the shield has left: the shield fails and the rest goes on to the hull
		local left = (self.ShieldStrength or 100) * self.ShieldAbsorb
		local rest = (not self:IsBeamDamage(dmg)) and (amount - left) or 0
		self.ShieldStrength = math.max(0, (self.ShieldStrength or 100) - amount / self.ShieldAbsorb)
		net.Start("AGP_HatakShieldHit"); net.WriteEntity(self); net.WriteVector(dmg:GetDamagePosition()); net.SendPVS(dmg:GetDamagePosition())
		if (self.ShieldStrength <= 0) then
			self.ShieldDown = true
			self:EmitSound("shields/shield_disengage.mp3", 140, 70)
			self:CrewSayL("", "agp_hkm_c_shields_failed", "SHIELDS FAILED", true)
		end
		self:ShieldThink(0)
		if (rest > 1) then return false, rest end
		return true
	end
	-- projectiles from outside stop at the shield bubble (the ellipsoid the client draws), they do not fly through it to
	-- the hull; the ship's own shots (first seen inside the bubble) go out. Every weapon counts, the owner's as well.
	ENT.ShieldShape = { 3300, 3300, 2150, -75 }   -- radii x, y, z and the centre's height (client: AGP.HatakShield)
	local function projectile(e)
		local c = e:GetClass()
		if (c:find("launcher") or c:find("platform") or c:find("turret") or c:find("cannon")) then return false end
		return c:find("pulse") or c:find("missile") or c:find("drone") or c:find("projectile") or c:find("rocket") or c:find("bolt")
			or c == "grenade_ar2" or c == "npc_grenade_frag" or c == "prop_combine_ball" or c == "tac_bomb"
	end
	-- AGP 2026-11-08: beams stop on the shield too. It is a shell the client draws, not an entity, so the beams' traces
	-- never met it: the Ori mothership's beam went through to the hull (owner: "a no-go"). For a beam from a to b: the
	-- first point where it enters the raised shield of a Ha'tak it started outside of (its own beams go out), with the
	-- ship and the outward normal there; nil when it enters none. energy_beam2 / energy_laser call it.
	function AGP.HatakShieldOnPath(a, b)
		local best, bestShip, bestNormal
		for _, ship in ipairs(ents.FindByClass("agp_hatak")) do
			if (ship.ShieldUp and ship:ShieldUp()) then
				local S = ship.ShieldShape
				local function unit(p) local l = ship:WorldToLocal(p) - Vector(0, 0, S[4]); return Vector(l.x / S[1], l.y / S[2], l.z / S[3]) end
				local pa, pb = unit(a), unit(b)
				local d = pb - pa
				local A, B, C = d:Dot(d), 2 * pa:Dot(d), pa:Dot(pa) - 1
				if (C > 0 and A > 0 and B * B - 4 * A * C >= 0) then   -- starts outside, the line meets the shell
					local t = (-B - math.sqrt(B * B - 4 * A * C)) / (2 * A)
					if (t >= 0 and t <= 1 and (not best or t < best)) then
						local u = pa + d * t
						best, bestShip = t, ship
						bestNormal = (ship:LocalToWorld(Vector(u.x / S[1], u.y / S[2], u.z / S[3])) - ship:GetPos()):GetNormalized()
					end
				end
			end
		end
		if (best) then return bestShip, a + (b - a) * best, bestNormal end
	end
	-- a beam on the shield: the same damage as when it reached the hull with the shield up (a beam's damage, held to
	-- BeamMaxDPS by OnTakeDamage; the shield takes it, gentler for beams), the client shows the flash where it hits
	function AGP.HatakShieldBeamHit(ship, beam, at, amount)
		local dmg = DamageInfo()
		dmg:SetDamage(amount or 10000); dmg:SetDamagePosition(at); dmg:SetDamageType(DMG_ENERGYBEAM)
		local owner = IsValid(beam) and beam:GetOwner() or nil
		dmg:SetAttacker(IsValid(owner) and owner or (IsValid(beam) and beam or game.GetWorld())); dmg:SetInflictor(IsValid(beam) and beam or game.GetWorld())
		ship:TakeDamageInfo(dmg)
	end
	hook.Add("Tick", "AGP.HatakShieldBlock", function()
		for _, ship in ipairs(ents.FindByClass("agp_hatak")) do
			if (ship:ShieldUp()) then
				local S = ship.ShieldShape
				for _, e in ipairs(ents.FindInSphere(ship:GetPos(), S[1] + 300)) do
					if (IsValid(e) and not e.AGPShieldDone and projectile(e) and e:GetOwner() ~= ship and e.Owner ~= ship) then
						local l = ship:WorldToLocal(e:GetPos()) - Vector(0, 0, S[4])
						local inside = (l.x / S[1]) ^ 2 + (l.y / S[2]) ^ 2 + (l.z / S[3]) ^ 2 < 1
						if (e.AGPShieldSeen == nil) then e.AGPShieldSeen = inside and ship or false end   -- born inside: our own shot
						if (inside and e.AGPShieldSeen ~= ship) then
							e.AGPShieldDone = true
							local dmg = DamageInfo()
							dmg:SetDamage(tonumber(e.Damage) or tonumber(e.damage) or 300); dmg:SetDamagePosition(e:GetPos())
							dmg:SetAttacker(IsValid(e.Owner) and e.Owner or (IsValid(e:GetOwner()) and e:GetOwner() or game.GetWorld())); dmg:SetInflictor(e)
							dmg:SetDamageType(DMG_BLAST)
							ship:ShieldHit(dmg)
							local fx = EffectData(); fx:SetOrigin(e:GetPos()); fx:SetNormal((e:GetPos() - ship:GetPos()):GetNormalized()); util.Effect("cball_bounce", fx, true, true)
							e:Remove()
						end
					end
				end
			end
		end
	end)
	-- ===== life support: air, warmth and gravity aboard, wherever the ship is (also in space) =====
	-- Runs while switched on, the power core gives power and the hull holds (above 10 %: below that it leaks).
	-- Off: aboard is the air of the ship's real place (vacuum in space: suits drain). Master menu + Wire "Life Support".
	ENT.LSBreach = 0.1
	function ENT:LifeSupportState()
		if (self.LSOn == false) then return false, "off" end
		if ((self.CorePower and self:CorePower() or 1) <= 0) then return false, "no power" end
		if (self:GetNWFloat("AGPHull", 1) < self.LSBreach) then return false, "hull breached" end
		return true, "running"
	end
	function ENT:LifeSupportOK() return (self:LifeSupportState()) end
	function ENT:LifeSupportThink()
		local ok, why = self:LifeSupportState()
		if (ok ~= self.LSWasOK) then
			if (self.LSWasOK ~= nil) then
				if (ok) then self:CrewSayL("", "agp_hkm_c_ls_running", "life support running", false) else self:CrewSayL("alert", "agp_hkm_c_ls_failed", "life support failed (%s)", true, (why == "no power" and "agp_hatak_ls_nopower") or (why == "hull breached" and "agp_hatak_ls_breach") or why) end
				if (not ok and self.SetAlarm and why ~= "off") then self:SetAlarm(true, "agp_hkm_r_ls") end
			end
			self.LSWasOK = ok
		end
		self:SetNWBool("AGPLifeSupport", ok); self:SetNWString("AGPLifeSupportWhy", why)
		if (self.SetWire) then self:SetWire("Life Support", ok and 1 or 0) end
	end
	function ENT:ShieldThink(dt)
		self.ShieldStrength = math.min(100, (self.ShieldStrength or 100) + self.ShieldRecharge * math.max(0, self:SystemPower("shields")) * dt)
		if (self.ShieldDown and self.ShieldStrength >= 25) then
			self.ShieldDown = nil
			if (self:ShieldUp()) then self:CrewSayL("", "agp_hkm_c_shields_back", "shields back up", false) end
		end
		local up = self:ShieldUp()
		self:SetNWBool("AGPShieldOn", up)
		self:SetNWFloat("AGPShield", self.ShieldStrength)
		if (self.SetWire) then self:SetWire("Shield", up and 1 or 0); self:SetWire("Shield Strength", math.Round(self.ShieldStrength)) end
	end

	-- ===== hull health and destruction (admin settings agp_hatak_destructible, agp_hatak_health) =====
	-- Only heavy hits count (HullMinDamage per hit: no rifle can wear a mothership down); hits on the hull while the
	-- shield holds go to the shield. Explosions inside (interior, parts) bypass the shield, burn crystals nearby and
	-- hurt the hull. At 0 the ship blows up (if the admin allows it), else it stays wrecked at 1.
	-- The pack's repair tool repairs it (0.1 % per step).
	-- Continuous beams (IsBeamDamage) are many small hits: they count without the minimum, HullBeamFactor times (a beam
	-- that burnt through the shield cuts the armour; ~100 s of the Asuran gate weapon for the default 100000).
	-- Returns the damage that counted (0: none).
	ENT.HullMinDamage = 50
	ENT.HullBeamFactor = 2
	ENT.InsideBlastRadius = 260
	function ENT:HullDamage(amount, dmg)
		if (self.Destroying or amount <= 0) then return 0 end
		local hit = amount
		if (dmg and self:IsBeamDamage(dmg)) then hit = amount * self.HullBeamFactor
		elseif (amount < self.HullMinDamage) then return 0 end
		local old = self.EntHealth or self.MaxHealth
		self.EntHealth = math.max(0, old - hit)
		local f = self.EntHealth / self.MaxHealth
		self:SetNWFloat("AGPHull", f)
		if (self.SetWire) then self:SetWire("Hull", math.Round(self.EntHealth)); self:SetWire("Hull %", math.Round(f * 100)) end
		for _, mark in ipairs({ 0.5, 0.25, 0.1 }) do
			if (old / self.MaxHealth > mark and f <= mark) then
				self:CrewSayL("alert", "agp_hkm_c_hull", "hull at %d %%", true, mark * 100)
				if (self.SetAlarm) then self:SetAlarm(true, "agp_hkm_r_hull") end
			end
		end
		if (self.EntHealth <= 0) then
			local d = GetConVar("agp_hatak_destructible")
			if (d and not d:GetBool()) then
				self.EntHealth = 1; self:SetNWFloat("AGPHull", 1 / self.MaxHealth)
				if (self.SetWire) then self:SetWire("Hull", 1); self:SetWire("Hull %", 0) end
				return amount
			end
			self.Destroying = true
			self:CrewSayL("", "agp_hkm_c_breaking", "THE HULL IS BREAKING APART", true)
			self:LogL("agp_hkm_l_destroyed", "destroyed")
			timer.Simple(3, function() if (IsValid(self)) then self:SelfDestruct() end end)
		end
		return amount
	end
	function ENT:HealthRepair(health)   -- repair tool: one step = 0.1 % of the hull
		if (self.Destroying) then return end
		self.EntHealth = math.min(self.MaxHealth, (self.EntHealth or 0) + self.MaxHealth * 0.001)
		self:SetNWFloat("AGPHull", self.EntHealth / self.MaxHealth)
		if (self.SetWire) then self:SetWire("Hull", math.Round(self.EntHealth)); self:SetWire("Hull %", math.Round(self.EntHealth / self.MaxHealth * 100)) end
	end
	-- an explosion inside: crystals near it burn out, the hull takes the damage (no shield in here)
	function ENT:InsideBlast(pos, amount)
		if (CurTime() - (self.LastInsideBlast or 0) < 0.05 and pos:DistToSqr(self.LastInsidePos or pos) < 10000) then return end   -- one blast hits many parts
		self.LastInsideBlast, self.LastInsidePos = CurTime(), pos
		self:HullDamage(amount * 2)
		local burnt = 0
		for g, list in pairs(self.PowerSlots or {}) do
			for _, sl in ipairs(list) do
				local c = sl.crystal
				if (IsValid(c) and not c:GetBurnt() and c:GetPos():Distance(pos) < self.InsideBlastRadius) then
					c:SetBurnt(true); c:UpdateLook(); burnt = burnt + 1
				end
			end
		end
		if (burnt > 0) then
			self:CrewSayL("", "agp_hkm_c_blast", "explosion aboard - crystals burnt out: %d", true, burnt)
			self:PowerThink()
		end
		if (self.SetAlarm) then self:SetAlarm(true, "agp_hkm_r_blast") end
	end
	local function shipPart(e)
		return IsValid(e) and (e:GetClass() == "agp_hatak_interior" or (e.AGPShip ~= nil and e:GetClass() ~= "agp_hatak" and not e.AGPMovable))
	end
	hook.Add("PhysgunPickup", "AGP.HatakProtect", function(_, e) if (shipPart(e)) then return false end end)
	hook.Add("GravGunPickupAllowed", "AGP.HatakProtect", function(_, e) if (shipPart(e)) then return false end end)
	hook.Add("GravGunPunt", "AGP.HatakProtect", function(_, e) if (shipPart(e)) then return false end end)
	hook.Add("CanTool", "AGP.HatakProtect", function(_, tr) if (shipPart(tr.Entity)) then return false end end)
	hook.Add("CanProperty", "AGP.HatakProtect", function(_, _, e) if (shipPart(e)) then return false end end)
	hook.Add("CanDrive", "AGP.HatakProtect", function(_, e) if (shipPart(e)) then return false end end)

	hook.Add("EntityTakeDamage", "AGP.HatakInside", function(ent, dmg)
		local ship = (ent:GetClass() == "agp_hatak_interior" and ent.AGPShip) or (ent.AGPShip ~= nil and ent:GetClass() ~= "agp_hatak" and ent.AGPShip)
		if (not IsValid(ship) or ship:GetClass() ~= "agp_hatak" or not IsValid(ship.Interior)) then return end
		if (isKawoosh(dmg)) then return true end
		if (ent:GetParent() == ship) then   -- a part outside on the flying hull (hangar door, door controls): not aboard
			-- explosions there hit the hull itself as well; direct hits and beams go to the hull (shield first)
			if (ship:IsBeamDamage(dmg) or (not dmg:IsExplosionDamage() and dmg:GetDamage() >= 100)) then ship:OnTakeDamage(dmg) end
			return
		end
		if (not dmg:IsExplosionDamage() and dmg:GetDamage() < 100) then return end
		local pos = dmg:GetDamagePosition()
		if (pos:IsZero()) then pos = dmg:GetReportedPosition() end
		if (pos:IsZero()) then pos = ent:GetPos() end
		ship:InsideBlast(pos, dmg:GetDamage())
	end)

	-- ===== cloak (admin setting agp_hatak_cloak): the hull fades out, other ships' weapons no longer find it =====
	-- Needs 30 % shield power (same emitter); shields drop while cloaked; firing or raising shields drops the cloak.
	function ENT:CanCloak()
		local c = GetConVar("agp_hatak_cloak")
		return (not c or c:GetBool()) and self:SystemPower("shields") >= 0.3
	end
	function ENT:SetCloak(on, who)
		on = on and true or false
		if (on == (self.Cloaked or false)) then return true end
		if (on and not self:CanCloak()) then
			if (IsValid(who)) then
				local c = GetConVar("agp_hatak_cloak")
				if ((c and not c:GetBool())) then hkTell(who, "agp_hkm_t_cloak_server", "Cloaking is switched off on this server.") else hkTell(who, "agp_hkm_t_cloak_power", "Not enough shield power to cloak.") end
			end
			return false
		end
		self.Cloaked = on
		if (on and self.ShieldOn) then self.ShieldOn = false; self:ShieldThink(0) end
		self:SetNWBool("AGPCloaked", on)
		self:SetNWFloat("AGPCloakT", CurTime())
		self:DrawShadow(not on)
		self:EmitSound(on and "ambient/levels/citadel/weapon_disintegrate2.wav" or "ambient/levels/citadel/weapon_disintegrate3.wav", 120, 80)
		if (on) then self:CrewSayL("", "agp_hkm_c_cloaked", "cloaked", false) else self:CrewSayL("", "agp_hkm_c_cloak_dropped", "cloak dropped", false) end
		if (self.SetWire) then self:SetWire("Cloaked", on and 1 or 0) end
		return true
	end

	-- the consoles: one window each, kept up to date while open
	function ENT:SendComputer(ply, kind)
		net.Start("AGP_HatakComputer")
		net.WriteEntity(self)
		net.WriteString(kind)
		net.WriteBool(self:IsCrew(ply))
		if (kind == "ship_log") then
			local log = self.ShipLog or {}
			net.WriteUInt(#log, 8)
			for _, l in ipairs(log) do
				net.WriteString(l[1]); net.WriteString(l[2]); net.WriteString(l[3] or ""); net.WriteString(l[4] or "")
				local a = l[5] or {}
				net.WriteUInt(#a, 4)
				for _, v in ipairs(a) do net.WriteString(tostring(v)) end
			end
		elseif (kind == "database") then
			local t = {}
			for _, g in ipairs(ents.GetAll()) do
				if (g.IsStargate and g.GetGateAddress and g ~= self.Gate and (g:GetGateAddress() or "") ~= "") then t[#t + 1] = g end
			end
			self.DatabaseGates = self.DatabaseGates or {}
			self.DatabaseGates[ply] = t
			net.WriteString(IsValid(self.Gate) and (self.Gate:GetGateAddress() or "") or "")
			net.WriteBool(IsValid(self.Gate) and (self.Gate.IsOpen or self.Gate.Dialling or self.Gate.Active) and true or false)
			net.WriteUInt(math.min(#t, 255), 8)
			for i = 1, math.min(#t, 255) do
				local g = t[i]
				net.WriteString(g.GetGateName and g:GetGateName() or "")
				net.WriteString(g:GetGateAddress())
				net.WriteString((g:GetClass():gsub("stargate_", "")))
				net.WriteFloat(g:GetPos():Distance(self:GetPos()))
			end
		elseif (kind == "security") then
			net.WriteBool(self.Alarm or false)
			net.WriteBool(self.Lockdown or false)
			for _, name in ipairs(self.ComputerSystems) do net.WriteUInt((self:CrystalsGood(name)), 2) end
			local n = 0
			for _ in pairs(self.Aboard or {}) do n = n + 1 end
			net.WriteUInt(n, 8)
			for p in pairs(self.Aboard or {}) do
				net.WriteString(IsValid(p) and p:Nick() or "?"); net.WriteBool(IsValid(p) and self:IsCrew(p))
			end
		elseif (kind == "self_destruct") then
			net.WriteFloat(self.DestructAt or 0)
		elseif (kind == "shields") then
			net.WriteBool(self.ShieldOn or false); net.WriteBool(self:ShieldUp())
			net.WriteFloat(self.ShieldStrength or 100); net.WriteFloat(self:SystemPower("shields"))
			net.WriteBool(self.ShieldAuto ~= false); net.WriteBool(self.Cloaked or false)
			local c = GetConVar("agp_hatak_cloak")
			net.WriteBool(not c or c:GetBool())
		end
		net.Send(ply)
	end
	-- what the gate room's gate dials for that gate: its address, plus its group when the groups differ (as the DHD)
	function ENT:DialAddressTo(g)
		local adr = g:GetGateAddress()
		local mine = IsValid(self.Gate) and self.Gate.GetGateGroup and self.Gate:GetGateGroup() or ""
		local grp = g.GetGateGroup and g:GetGateGroup() or ""
		if (grp ~= "" and grp ~= mine) then adr = adr .. (#grp == 3 and grp or grp:sub(1, 1)) end
		return adr
	end
	function ENT:OpenComputer(ply, kind)
		self.ComputerUsers = self.ComputerUsers or {}
		self.ComputerUsers[ply] = CurTime()
		self:SendComputer(ply, kind)
	end
	-- key 1 on the throne, in the pilot chair or as gunner: the master menu (the right mouse stays free for zooming)
	-- AGP 2026-10-31: the client sends the key as well (AGP_HatakMenuKey, read like the V camera key with input.IsKeyDown):
	-- the owner could not open the menu from the pilot chair, and PlayerButtonDown alone stops working as soon as any other
	-- addon's PlayerButtonDown hook returns a value. Both ways lead here, the first one wins (0.5 s).
	util.AddNetworkString("AGP_HatakMenuKey")
	local function menuKey(ply)
		if (not IsValid(ply) or (ply.AGPMenuKeyT or 0) > CurTime()) then return end
		local veh = ply:GetVehicle()
		local ship = IsValid(veh) and veh:GetNWEntity("AGPHatak") or NULL
		if (not IsValid(ship)) then ship = ply.AGPGunShip end
		if (not IsValid(ship) and IsValid(veh)) then ship = veh.AGPGunnerSeatOf end
		if (IsValid(ship) and ship:GetClass() == "agp_hatak") then
			ply.AGPMenuKeyT = CurTime() + 0.5
			ship:SendCommand(ply)
		end
	end
	hook.Add("PlayerButtonDown", "AGP.HatakMenuKey", function(ply, button)
		if (button == KEY_1) then menuKey(ply) end
	end)
	net.Receive("AGP_HatakMenuKey", function(len, ply) menuKey(ply) end)
	util.AddNetworkString("AGP_HatakCommand")
	util.AddNetworkString("AGP_HatakCommandOpen")
	-- the master menu (pel'tak command console, or right mouse on the throne): the whole ship in one window
	function ENT:CommandDoors()   -- the doors the crew opens (inside ones; their outside twins follow)
		local t = {}
		for _, e in ipairs(self.Parts or {}) do
			if (IsValid(e) and e:GetClass() == "agp_goauld_door" and e.AGPDoorName and not e.AGPOuterTwin) then t[#t + 1] = e end
		end
		table.sort(t, function(a, b) return a.AGPDoorName < b.AGPDoorName end)
		return t
	end
	function ENT:SendCommand(ply)
		self.CommandUsers = self.CommandUsers or {}
		self.CommandUsers[ply] = CurTime()
		net.Start("AGP_HatakCommand")
		net.WriteEntity(self)
		net.WriteBool(self:MayCommand(ply))
		local pilot = self:Pilot()
		net.WriteString(IsValid(pilot) and pilot:Nick() or "")
		net.WriteFloat(self:GetNWFloat("AGPHull", 1))
		net.WriteFloat(self.CorePower and self:CorePower() or 1)
		net.WriteBool(self.ShieldOn or false); net.WriteBool(self.Cloaked or false); net.WriteBool(self:ShieldUp())
		net.WriteBool(self.Alarm or false); net.WriteBool(self.Lockdown or false)
		local lsOK, lsWhy = self:LifeSupportState()
		net.WriteBool(lsOK); net.WriteString(lsWhy)
		local doors = self:CommandDoors()
		net.WriteUInt(#doors, 6)
		for _, d in ipairs(doors) do net.WriteString(d.AGPDoorName); net.WriteBool(d:GetOpened()); net.WriteBool(d:GetLocked()) end
		net.Send(ply)
	end
	net.Receive("AGP_HatakCommandOpen", function(len, ply)
		local ship = net.ReadEntity()
		local kind = net.ReadString()
		local arg = net.ReadString()
		if (not IsValid(ship) or ship:GetClass() ~= "agp_hatak") then return end
		local used = ship.CommandUsers and ship.CommandUsers[ply]
		if (not used or CurTime() - used > 600) then return end
		local crew = ship:MayCommand(ply)
		if (kind == "power") then ship:OpenPower(ply) return
		elseif (kind == "self_destruct" or kind == "ship_log" or kind == "database" or kind == "security" or kind == "shields") then ship:OpenComputer(ply, kind) return
		elseif (kind == "refresh") then ship:SendCommand(ply) return end
		if (not crew) then hkTell(ply, "agp_hkm_t_ship_crew", "The ship does not answer you (crew only).") return end
		if (kind == "weapons") then ship:OpenWeapons(ply) return
		elseif (kind == "jump") then ship.NavUsers = ship.NavUsers or {}; ship.NavUsers[ply] = CurTime(); ship:OpenJumpMenu(ply) return
		elseif (kind == "door" or kind == "doorlock") then
			for _, d in ipairs(ship:CommandDoors()) do
				if (d.AGPDoorName == arg) then
					if (kind == "door") then d:SetLocked(false); d:SetDoorOpen(not d:GetOpened()) else d:SetLocked(not d:GetLocked()); d:SetWire("Locked", d:GetLocked() and 1 or 0) end
				end
			end
		elseif (kind == "doors_open" or kind == "doors_close") then
			for _, d in ipairs(ship:CommandDoors()) do if (not d:GetLocked()) then d:SetDoorOpen(kind == "doors_open") end end
		elseif (kind == "shield") then ship:SetShield(not ship.ShieldOn, ply)
		elseif (kind == "cloak") then ship:SetCloak(not ship.Cloaked, ply)
		elseif (kind == "alarm") then
			if (not ship:SetAlarm(not ship.Alarm, "agp_hkm_r_raised", ply:Nick())) then hkTell(ply, "agp_hkm_t_no_alarm", "No alarm: the communication crystals are missing.") end
		elseif (kind == "lockdown") then ship:SetLockdown(not ship.Lockdown)
		elseif (kind == "lifesupport") then ship.LSOn = (ship.LSOn == false); ship:LifeSupportThink() end
		timer.Simple(0.3, function() if (IsValid(ship) and IsValid(ply)) then ship:SendCommand(ply) end end)
	end)
	net.Receive("AGP_HatakComputerCmd", function(len, ply)
		local ship = net.ReadEntity()
		local kind = net.ReadString()
		local cmd = net.ReadString()
		if (not IsValid(ship) or ship:GetClass() ~= "agp_hatak") then return end
		local used = ship.ComputerUsers and ship.ComputerUsers[ply]
		if (not used or CurTime() - used > 600) then return end
		if (cmd ~= "refresh") then
			if (not ship:IsCrew(ply)) then hkTell(ply, "agp_hkm_t_console_crew", "The console does not answer you (crew only).")
			elseif (cmd == "destruct") then
				if (not ship.DestructAt) then ship:ToggleSelfDestruct(ply, math.Clamp(net.ReadUInt(10), 10, 600)) end
			elseif (cmd == "abort") then
				if (ship.DestructAt) then ship:ToggleSelfDestruct(ply) end
			elseif (cmd == "alarm") then
				if (not ship:SetAlarm(not ship.Alarm, "agp_hkm_r_raised", ply:Nick())) then hkTell(ply, "agp_hkm_t_no_alarm", "No alarm: the communication crystals are missing.") end
			elseif (cmd == "lockdown") then
				ship:SetLockdown(not ship.Lockdown)
			elseif (cmd == "shield") then
				ship:SetShield(not ship.ShieldOn, ply)
			elseif (cmd == "shieldauto") then
				ship.ShieldAuto = (ship.ShieldAuto == false)
			elseif (cmd == "cloak") then
				ship:SetCloak(not ship.Cloaked, ply)
			elseif (cmd == "dial") then
				local g = ship.DatabaseGates and ship.DatabaseGates[ply] and ship.DatabaseGates[ply][net.ReadUInt(8)]
				if (IsValid(g) and IsValid(ship.Gate)) then
					if (ship.Gate.IsOpen or ship.Gate.Dialling) then hkTell(ply, "agp_hkm_t_gate_busy", "The gate room's gate is busy.")
					else
						ship.Gate:DialGate(ship:DialAddressTo(g), true)
						ship:CrewSayL("", "agp_hkm_c_dials", "the gate room dials %s", false, g:GetGateAddress() .. ((g.GetGateName and g:GetGateName() ~= "") and (" (" .. g:GetGateName() .. ")") or ""))
					end
				end
			end
		end
		ship:SendComputer(ply, kind)
	end)
end

-- the Ha'tak seat: Ctrl is "down", not GMod's vehicle third-person toggle (V does the camera)
hook.Add("VehicleMove", "AGP.HatakSeatNoDuckToggle", function(ply, veh, mv)
	if (IsValid(veh) and IsValid(veh:GetNWEntity("AGPHatak"))) then return true end
end)

if CLIENT then
	-- AGP 2026-11-10: the ship's messages in the player's language (the server sends key, English text and values; a
	-- value that is a key - "agp_hkm_p_weapons", or "key<31>value" - is translated too)
	local function hkmArg(a)
		local parts = string.Explode("", a)
		local key = parts[1]
		if (#parts > 1 or key:sub(1, 4) == "agp_") then
			table.remove(parts, 1)
			return AGP.L(key, key, unpack(parts))
		end
		return a
	end
	function AGP_HatakText(key, fallback, args)
		local t = {}
		for i, a in ipairs(args or {}) do t[i] = hkmArg(a) end
		return AGP.L(key, fallback, unpack(t))
	end
	local WHERE = { [""] = { "agp_hkm_w_ship", "Ha'tak" }, engine = { "agp_hkm_w_engine", "Ha'tak engine room" }, computer = { "agp_hkm_w_computer", "Ha'tak computer core" },
		alert = { "agp_hkm_w_alert", "Ha'tak ALERT" }, weapons = { "agp_hkm_w_weapons", "Ha'tak weapons" } }
	local center = { text = "", untilT = 0 }
	net.Receive("AGP_HatakSay", function()
		local where, key, fallback = net.ReadString(), net.ReadString(), net.ReadString()
		local args = {}
		for i = 1, net.ReadUInt(4) do args[i] = net.ReadString() end
		local isCenter = net.ReadBool()
		local text = AGP_HatakText(key, fallback, args)
		if (isCenter) then
			local w = WHERE[where] or WHERE[""]
			local line = AGP.L(w[1], w[2]) .. ": " .. text
			chat.AddText(Color(235, 190, 90), line)
			center.text, center.untilT = line, CurTime() + 4
		else
			chat.AddText(Color(235, 190, 90), "[" .. AGP.L("agp_hkm_w_ship", "Ha'tak") .. "] ", Color(230, 235, 240), text)
		end
	end)
	-- (like the game's own centre message: white, in the middle of the screen, 4 s)
	hook.Add("HUDPaint", "AGP.HatakSay", function()
		if (center.untilT < CurTime()) then return end
		local a = math.Clamp((center.untilT - CurTime()) * 255, 0, 255)
		draw.SimpleTextOutlined(center.text, "Trebuchet24", ScrW() / 2, ScrH() * 0.3, Color(255, 255, 255, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, a * 0.8))
	end)
	-- cloak: the hull fades out over 2 s (and back in); fully cloaked it is not drawn at all
	ENT.RenderGroup = RENDERGROUP_BOTH
	function ENT:CloakAlpha()
		local t = self:GetNWFloat("AGPCloakT", 0)
		if (t == 0) then return 1 end
		local f = math.Clamp((CurTime() - t) / 2, 0, 1)
		return self:GetNWBool("AGPCloaked") and (1 - f) or f
	end
	function ENT:Draw()
		if (self:CloakAlpha() >= 1) then self:DrawModel() end
	end
	function ENT:DrawTranslucent()
		local a = self:CloakAlpha()
		if (a <= 0.01 or a >= 1) then return end
		render.SetBlend(a)
		self:DrawModel()
		render.SetBlend(1)
	end

	-- pilot camera, V cycles: 1 bow camera (the pel'tak has no window: a view from the ship's front tip),
	-- 2 third person behind the ship (mouse wheel = distance), 3 the seat itself
	local mode, dist, lastV = 2, 9000, false   -- starts behind and above the ship
	local MODES = 3
	local function pilotShip()
		local ply = LocalPlayer()
		local veh = IsValid(ply) and ply:GetVehicle()
		local ship = IsValid(veh) and veh:GetNWEntity("AGPHatak")
		return IsValid(ship) and ship or nil
	end
	hook.Add("Think", "AGP.HatakCameraKey", function()
		if (not pilotShip()) then return end
		local down = input.IsKeyDown(KEY_V) and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible()
		if (down and not lastV) then mode = mode % MODES + 1 end
		lastV = down
	end)
	concommand.Add("agp_hatak_camera", function() mode = mode % MODES + 1 end)   -- same as V, for own key binds
	-- key 1 in a seat (helm or gunner): the master menu, sent to the server (it checks the seat; PlayerButtonDown there too).
	-- Any seat: the hull may not be sent to a client sitting in the interior, so this does not ask pilotShip()
	local last1 = false
	hook.Add("Think", "AGP.HatakMenuKey", function()
		local ply = LocalPlayer()
		if (not IsValid(ply) or not (ply:InVehicle() or IsValid(ply:GetNWEntity("AGPGunShip")))) then last1 = false return end
		local down = input.IsKeyDown(KEY_1) and not vgui.GetKeyboardFocus() and not gui.IsGameUIVisible() and not vgui.CursorVisible() and not ply:IsTyping()
		if (down and not last1) then net.Start("AGP_HatakMenuKey"); net.SendToServer() end
		last1 = down
	end)
	hook.Add("PlayerBindPress", "AGP.HatakCameraZoom", function(ply, bind, pressed)
		if (mode ~= 2 or not pilotShip()) then return end
		if (bind == "invprev") then dist = math.max(3000, dist - 600) return true end
		if (bind == "invnext") then dist = math.min(25000, dist + 600) return true end
	end)
	hook.Add("CalcView", "AGP.HatakCamera", function(ply, pos, ang, fov)
		local ship = pilotShip()
		if (not ship or mode == 3) then return end
		-- AGP 2026-10-31: the throne and the pilot chair stand in the interior, a separate room that never turns, so the
		-- view angle is in the room's frame. Turned into the hull's frame (room +X = the ship's front, FrontYaw), the
		-- camera looks where the ship flies and turns with it; before, it always faced one map direction and W looked
		-- like flying backwards whenever the ship faced the other way (owner 2026-10-31)
		local room = ship:GetNWEntity("AGPInterior")   -- the seats stand frozen in it (not parented); no interior: seats on the hull
		if (IsValid(room) and room ~= ship) then
			local _, la = WorldToLocal(Vector(0, 0, 0), ang, room:GetPos(), room:GetAngles())
			local _, ha = LocalToWorld(Vector(0, 0, 0), la, Vector(0, 0, 0), Angle(0, ship.FrontYaw or 180, 0))
			ang = ship:LocalToWorldAngles(ha)
		end
		if (mode == 1) then
			return { origin = ship:LocalToWorld(Vector(-3200, 0, 150)), angles = ang, fov = fov, drawviewer = true }   -- the front tip (hangar side)
		end
		local c = ship:WorldSpaceCenter()
		local tr = util.TraceLine({ start = c, endpos = c - ang:Forward() * dist + ship:GetUp() * dist * 0.3, filter = function(e) return false end, mask = MASK_SOLID_BRUSHONLY })
		return { origin = tr.HitPos + ang:Forward() * 40, angles = ang, fov = fov, drawviewer = true }
	end)

	-- ===== weapons console, radar and gunner view (Goa'uld look: gold on black, angled corners, glyph ring) =====
	local GOLD, GOLD2, DARK = Color(230, 182, 74), Color(140, 100, 36), Color(10, 8, 4, 245)
	local KIND = { player = Color(235, 75, 55), npc = Color(240, 210, 70), ship = Color(95, 165, 255), crew = Color(90, 220, 120) }
	local GLYPHS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#"
	surface.CreateFont("AGPHatakGlyph", { font = "AGP Glyphs SG1", size = 16, weight = 400, antialias = true })
	surface.CreateFont("AGPHatakTitle", { font = "Roboto", size = 26, weight = 800 })
	surface.CreateFont("AGPHatakText", { font = "Roboto", size = 15, weight = 600 })
	surface.CreateFont("AGPHatakSmall", { font = "Roboto", size = 13, weight = 500 })
	local function dist(u, short) return AGP and AGP.Units and AGP.Units.Distance and AGP.Units.Distance(u, short) or (math.Round(u * 0.0254) .. (short and "" or " m")) end
	local function unitName() return AGP and AGP.Units and AGP.Units.DistanceName and AGP.Units.DistanceName() or "m" end

	-- panel with cut corners (the Ha'tak's angled shapes)
	local function plate(x, y, w, h, cut, fill, line)
		local p = { { x = x + cut, y = y }, { x = x + w - cut, y = y }, { x = x + w, y = y + cut }, { x = x + w, y = y + h - cut },
			{ x = x + w - cut, y = y + h }, { x = x + cut, y = y + h }, { x = x, y = y + h - cut }, { x = x, y = y + cut } }
		draw.NoTexture(); surface.SetDrawColor(fill); surface.DrawPoly(p)
		surface.SetDrawColor(line)
		for i = 1, #p do local a, b = p[i], p[i % #p + 1]; surface.DrawLine(a.x, a.y, b.x, b.y) end
	end
	-- the small Ha'tak windows (hyperspace targets, rings) in the same Goa'uld look: gold on black, angled corners
	local function goauldWindow(fr)
		fr.Paint = function(_, w, h) plate(1, 1, w - 2, h - 2, 14, DARK, GOLD2) end
		if (IsValid(fr.lblTitle)) then fr.lblTitle:SetTextColor(GOLD); fr.lblTitle:SetFont("AGPHatakText") end
		if (IsValid(fr.btnMaxim)) then fr.btnMaxim:SetVisible(false) end
		if (IsValid(fr.btnMinim)) then fr.btnMinim:SetVisible(false) end
		if (IsValid(fr.btnClose)) then
			fr.btnClose.Paint = function(_, w, h) plate(0, 2, w, h - 4, 5, Color(40, 30, 12), GOLD); draw.SimpleText("X", "AGPHatakText", w / 2, h / 2, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
		end
	end
	local function goauldButton(b)
		b:SetFont("AGPHatakText")
		b.Paint = function(self2, bw, bh)
			local off = not self2:IsEnabled()
			plate(0, 0, bw, bh, 7, off and Color(20, 16, 8) or (self2:IsHovered() and Color(60, 45, 18) or Color(32, 25, 10)), off and GOLD2 or GOLD)
			self2:SetTextColor(off and GOLD2 or (self2:IsHovered() and Color(255, 235, 180) or GOLD))
		end
	end
	local function goauldList(list)
		list.Paint = function(_, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0)); surface.SetDrawColor(GOLD2); surface.DrawOutlinedRect(0, 0, w, h, 1) end
		for _, c in ipairs(list.Columns or {}) do
			if (IsValid(c.Header)) then c.Header:SetTextColor(GOLD); c.Header.Paint = function(_, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(40, 30, 12)) end end
		end
	end
	-- AGP 2026-11-08: a selected row's text turns light gold: red, blue and the dim gold were unreadable on the brown selection
	local function goauldLineText(ln)
		local sel = ln:IsSelected() and true or false
		if (ln.AGPSel == sel) then return end
		ln.AGPSel = sel
		for _, c in ipairs(ln.Columns) do
			c.AGPCol = c.AGPCol or c:GetTextColor()
			c:SetTextColor(sel and Color(255, 235, 180) or c.AGPCol)
		end
	end
	local function goauldLine(line, col)
		for _, c in ipairs(line.Columns) do c:SetTextColor(col) end
		line.Paint = function(ln, w, h)
			if (ln:IsSelected()) then draw.RoundedBox(0, 0, 0, w, h, Color(110, 80, 26)) elseif (ln:IsHovered()) then draw.RoundedBox(0, 0, 0, w, h, Color(45, 34, 14)) end
			goauldLineText(ln)
		end
	end
	local function goauldEntry(e)
		e:SetFont("AGPHatakText")
		e.Paint = function(s2, w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0)); surface.SetDrawColor(s2:HasFocus() and GOLD or GOLD2); surface.DrawOutlinedRect(0, 0, w, h, 1)
			if (s2:GetText() == "" and not s2:HasFocus()) then draw.SimpleText(s2:GetPlaceholderText() or "", "AGPHatakText", 5, h / 2, GOLD2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			else s2:DrawTextEntryText(GOLD, Color(130, 95, 30), GOLD) end
		end
	end

	-- hyperspace menu (pilot presses R)
	net.Receive("AGP_HatakJumpMenu", function()
		local ship = net.ReadEntity()
		local n = net.ReadUInt(10)
		local t = {}
		for i = 1, n do t[i] = { net.ReadString(), net.ReadBool() } end
		local fr = vgui.Create("DFrame")
		fr:SetTitle(AGP.L("agp_ui_hyperspace", "Hyperspace"))
		fr:SetSize(380, 520); fr:Center(); fr:MakePopup()
		goauldWindow(fr)
		local list = vgui.Create("DListView", fr)
		list:SetPos(10, 30); list:SetSize(360, 330)
		list:AddColumn(AGP.L("agp_ui_target", "Target"))
		goauldList(list)
		for i, v in ipairs(t) do
			local name = v[1]   -- (the server names them in English: "Mark 1", "Gate ...", "Player ...")
			local kind, rest = name:match("^(%a+) (.+)$")
			if (kind == "Mark") then name = AGP.L("agp_hk_t_mark", "Mark %s", rest)
			elseif (kind == "Gate") then name = AGP.L("agp_hk_gate", "Gate") .. " " .. rest
			elseif (kind == "Player") then name = AGP.L("agp_hk_t_player", "Player %s", rest) end
			local line = list:AddLine(name .. (v[2] and "" or "   " .. AGP.L("agp_ui_empty", "(empty)")))
			line.Index = i; line.Usable = v[2]
			goauldLine(line, v[2] and GOLD or GOLD2)   -- empty marks dimmed
		end
		list.OnRowSelected = function() end
		local jump = vgui.Create("DButton", fr)
		jump:SetPos(10, 366); jump:SetSize(360, 30); jump:SetText(AGP.L("agp_ui_jump_target", "Jump to the selected target")); goauldButton(jump)
		jump.DoClick = function()
			local _, line = list:GetSelectedLine()
			if (not line or not line.Usable) then return end
			net.Start("AGP_HatakJumpGo"); net.WriteEntity(ship); net.WriteString("target"); net.WriteUInt(line.Index, 10); net.SendToServer()
			fr:Close()
		end
		for i = 1, 3 do
			local b = vgui.Create("DButton", fr)
			b:SetPos(10 + (i - 1) * 122, 402); b:SetSize(116, 26); b:SetText(AGP.L("agp_ui_save_mark", "Save mark %d here", i)); goauldButton(b)
			b.DoClick = function() net.Start("AGP_HatakJumpGo"); net.WriteEntity(ship); net.WriteString("save"); net.WriteUInt(i, 2); net.SendToServer(); fr:Close() end
		end
		local coord = vgui.Create("DTextEntry", fr)
		coord:SetPos(10, 440); coord:SetSize(196, 26); coord:SetPlaceholderText("x y z"); goauldEntry(coord)
		local cb = vgui.Create("DButton", fr)
		cb:SetPos(212, 440); cb:SetSize(158, 26)   -- (room for "Springen nach x y z"); cb:SetText(AGP.L("agp_ui_jump_xyz", "Jump to x y z")); goauldButton(cb)
		cb.DoClick = function()
			local x, y, z = (coord:GetValue() or ""):match("(-?[%d%.]+)[%s,;]+(-?[%d%.]+)[%s,;]+(-?[%d%.]+)")
			if (not x) then return end
			net.Start("AGP_HatakJumpGo"); net.WriteEntity(ship); net.WriteString("coord"); net.WriteVector(Vector(tonumber(x), tonumber(y), tonumber(z))); net.SendToServer()
			fr:Close()
		end
		local hint = vgui.Create("DLabel", fr)
		hint:SetPos(10, 474); hint:SetSize(360, 36); hint:SetWrap(true); hint:SetTextColor(GOLD2); hint:SetFont("AGPHatakSmall")
		hint:SetText(AGP.L("agp_ui_jump_arrive", "The ship arrives above the target. If that space is taken, it looks for free space nearby."))
	end)

	net.Receive("AGP_HatakRingMenu", function()
		local panel = net.ReadEntity()
		local here = net.ReadUInt(4)
		local n = net.ReadUInt(4)
		local decks = {}
		for i = 1, n do decks[i] = { net.ReadString(), net.ReadString() } end
		local fr = vgui.Create("DFrame")
		fr:SetTitle(AGP.L("agp_ui_rings", "Rings"))
		fr:SetSize(300, 90 + (n + 2) * 34)
		fr:Center(); fr:MakePopup()
		goauldWindow(fr)
		local y = 30
		local function btn(text, choice, disabled)
			local b = vgui.Create("DButton", fr)
			b:SetPos(10, y); b:SetSize(280, 30); b:SetText(text)
			if (disabled) then b:SetEnabled(false) end
			goauldButton(b)
			b.DoClick = function()
				net.Start("AGP_HatakRingGo"); net.WriteEntity(panel); net.WriteInt(choice, 8); net.SendToServer()
				fr:Close()
			end
			y = y + 34
		end
		for i, d in ipairs(decks) do
			btn(d[1] .. (d[2] ~= "" and ("   [" .. d[2] .. "]") or "") .. (i == here and ("   " .. AGP.L("agp_hk_here", "(here)")) or ""), i, i == here)
		end
		btn(AGP.L("agp_hk_nearest_ring", "Nearest ring outside the ship"), 0)
		btn(AGP.L("agp_hk_glyph_pad", "Goa'uld glyph pad"), -1)
	end)

	local function marker(kind, x, y, s, col)
		draw.NoTexture(); surface.SetDrawColor(col)
		if (kind == "player") then surface.DrawPoly({ { x = x, y = y - s }, { x = x + s, y = y }, { x = x, y = y + s }, { x = x - s, y = y } })   -- diamond
		elseif (kind == "ship") then surface.DrawPoly({ { x = x, y = y - s }, { x = x + s, y = y + s }, { x = x - s, y = y + s } })               -- triangle
		else draw.RoundedBox(s, x - s, y - s, s * 2, s * 2, col) end                                                                           -- circle
	end

	-- the radar disc: ship in the middle (pyramid, nose up), targets around it
	local function drawRadar(st, cx, cy, R, big)
		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 230)
		local disc = {}
		for k = 0, 47 do local a = k / 48 * math.pi * 2; disc[#disc + 1] = { x = cx + math.cos(a) * R, y = cy + math.sin(a) * R } end
		surface.DrawPoly(disc)
		for k = 1, 3 do surface.DrawCircle(cx, cy, R * k / 3, GOLD2.r, GOLD2.g, GOLD2.b, 140) end
		surface.DrawCircle(cx, cy, R, GOLD.r, GOLD.g, GOLD.b, 255)
		surface.SetDrawColor(GOLD2.r, GOLD2.g, GOLD2.b, 90)
		for k = 0, 5 do local a = k / 6 * math.pi * 2 + math.pi / 2; surface.DrawLine(cx, cy, cx + math.cos(a) * R, cy + math.sin(a) * R) end
		-- sweep with a fading trail
		local sw = (CurTime() * 1.6) % (math.pi * 2)
		for k = 0, 14 do
			local a = sw - k * 0.035
			surface.SetDrawColor(GOLD.r, GOLD.g, GOLD.b, 170 * (1 - k / 15))
			surface.DrawLine(cx, cy, cx + math.cos(a) * R, cy + math.sin(a) * R)
		end
		if (big) then   -- glyph ring around the edge
			for k = 0, 35 do
				local a = k / 36 * math.pi * 2 - math.pi / 2
				draw.SimpleText(GLYPHS:sub(k % #GLYPHS + 1, k % #GLYPHS + 1), "AGPHatakGlyph", cx + math.cos(a) * (R + 12), cy + math.sin(a) * (R + 12), GOLD2, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		surface.SetDrawColor(GOLD)
		surface.DrawPoly({ { x = cx, y = cy - 10 }, { x = cx + 8, y = cy + 7 }, { x = cx - 8, y = cy + 7 } })   -- the ship
		local range = st.range or 15000
		for _, t in ipairs(st.list) do
			local px, py = cx - t.y / range * R, cy - t.x / range * R   -- ship's +X up, +Y left
			local col = t.crew and KIND.crew or KIND[t.kind] or GOLD
			if (t.atk and (CurTime() * 4) % 2 < 1) then col = Color(255, 255, 255) end
			marker(t.kind, px, py, big and 5 or 3, col)
			if (t.ent == st.target) then   -- target brackets
				surface.SetDrawColor(255, 255, 255)
				local b = big and 10 or 7
				for _, d in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
					surface.DrawLine(px + d[1] * b, py + d[2] * b, px + d[1] * (b - 4), py + d[2] * b)
					surface.DrawLine(px + d[1] * b, py + d[2] * b, px + d[1] * b, py + d[2] * (b - 4))
				end
			end
		end
	end

	local W = {}
	local function cmd(c, fn)
		if (not W.state or not IsValid(W.state.ship)) then return end
		net.Start("AGP_HatakWeaponsCmd"); net.WriteEntity(W.state.ship); net.WriteString(c)
		if (fn) then fn() end
		net.SendToServer()
	end
	net.Receive("AGP_HatakWeapons", function()
		local s = { ship = net.ReadEntity(), purpose = net.ReadUInt(2), mode = net.ReadUInt(2), hold = net.ReadBool(), target = net.ReadEntity(),
			cool = net.ReadFloat(), range = net.ReadFloat(), list = {}, time = CurTime() }
		for i = 1, net.ReadUInt(8) do
			s.list[i] = { ent = net.ReadEntity(), name = net.ReadString(), kind = net.ReadString(), dist = net.ReadFloat(),
				x = net.ReadFloat(), y = net.ReadFloat(), z = net.ReadFloat(), atk = net.ReadBool(), crew = net.ReadBool() }
		end
		W.state = s
		if (s.purpose == 1) then return end   -- radar on the pilot's / gunner's screen only
		if (IsValid(W.frame)) then W.frame:Refresh() return end
		local fr = vgui.Create("DFrame")
		W.frame = fr
		fr:SetTitle(""); fr:SetSize(760, 500); fr:Center(); fr:MakePopup(); fr:ShowCloseButton(false)
		fr.Paint = function(_, w, h)
			plate(0, 0, w, h, 22, DARK, GOLD)
			plate(6, 6, w - 12, h - 12, 18, Color(0, 0, 0, 0), GOLD2)
			local tw = draw.SimpleText(AGP.L("agp_hk_weapons", "WEAPONS"), "AGPHatakTitle", 30, 14, GOLD)   -- (the glyphs after the title, however long it is in the player's language)
			draw.SimpleText(AGP.L("agp_hk_staff_cannons", "STAFF CANNONS"), "AGPHatakGlyph", math.max(160, 30 + tw + 24), 20, GOLD2)
			local st = W.state
			if (st) then
				draw.SimpleText(st.cool > 0 and AGP.L("agp_hk_charging", "CHARGING") or AGP.L("agp_hk_ready", "READY"), "AGPHatakText", w - 70, 18, st.cool > 0 and Color(255, 140, 60) or Color(120, 230, 120), TEXT_ALIGN_RIGHT)
				draw.SimpleText(AGP.L("agp_hk_range", "range %s", dist(st.range)), "AGPHatakSmall", 30, h - 26, GOLD2)
			end
		end
		local close = vgui.Create("DButton", fr)
		close:SetPos(fr:GetWide() - 50, 12); close:SetSize(30, 24); close:SetText("")
		close.Paint = function(_, w, h) plate(0, 0, w, h, 6, Color(40, 30, 12), GOLD); draw.SimpleText("X", "AGPHatakText", w / 2, h / 2, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
		close.DoClick = function() fr:Close() end
		local radar = vgui.Create("DPanel", fr)
		radar:SetPos(20, 52); radar:SetSize(410, 410)
		radar.Paint = function(_, w, h) if (W.state) then drawRadar(W.state, w / 2, h / 2, w / 2 - 26, true) end end
		local list = vgui.Create("DListView", fr)
		list:SetPos(446, 56); list:SetSize(292, 232); list:SetMultiSelect(false); list:SetHeaderHeight(20)
		list:AddColumn(AGP.L("agp_ui_target", "Target")); list:AddColumn(AGP.L("agp_hk_type", "Type")):SetFixedWidth(52); list:AddColumn(unitName()):SetFixedWidth(58)
		list.Paint = function(_, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0)); surface.SetDrawColor(GOLD2); surface.DrawOutlinedRect(0, 0, w, h, 1) end
		for _, c in ipairs(list.Columns) do
			c.Header:SetTextColor(GOLD)
			c.Header.Paint = function(_, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(40, 30, 12)) end
		end
		list.OnRowSelected = function(_, _, line)
			if (fr.Filling) then return end
			cmd("target", function() net.WriteEntity(line.Ent) end)
		end
		local function button(txt, x, y, w, fn)
			local b = vgui.Create("DButton", fr)
			b:SetPos(x, y); b:SetSize(w, 30); b:SetText(""); b.Label = txt
			b.Paint = function(self2, bw, bh)
				local on = self2.On and self2:On()
				plate(0, 0, bw, bh, 7, on and Color(130, 95, 30) or (self2:IsHovered() and Color(60, 45, 18) or Color(32, 25, 10)), GOLD)
				draw.SimpleText(self2.Label, "AGPHatakText", bw / 2, bh / 2, on and Color(255, 235, 180) or GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			b.DoClick = fn
			return b
		end
		for m, name in pairs({ [0] = AGP.L("agp_hk_mode_off", "OFF"), AGP.L("agp_hk_mode_defend", "DEFEND"), AGP.L("agp_hk_mode_auto", "AUTO") }) do
			local b = button(name, 446 + m * 99, 298, 94, function() cmd("mode", function() net.WriteUInt(m, 2) end) end)
			b.On = function() return W.state and W.state.mode == m end
		end
		local fire = button(AGP.L("agp_hk_fire", "FIRE"), 446, 336, 144, function() cmd("fire") end)
		fire.On = function() return W.state and W.state.cool > 0 end
		local hold = button(AGP.L("agp_hk_keep_firing", "KEEP FIRING"), 594, 336, 144, function() cmd("hold", function() net.WriteBool(not W.state.hold) end) end)
		hold.On = function() return W.state and W.state.hold end
		button(AGP.L("agp_hk_manual", "MANUAL (GUNNER)"), 446, 374, 292, function() cmd("manual"); fr:Close() end)
		local info = vgui.Create("DLabel", fr)
		info:SetPos(446, 412); info:SetSize(292, 70); info:SetWrap(true); info:SetTextColor(GOLD2); info:SetFont("AGPHatakSmall")
		info:SetText(AGP.L("agp_ui_radar_legend", "Diamond: players, circle: NPCs, triangle: ships. Green: crew, blinking: shot at us. %s fires only at attackers, %s also at NPCs and strangers.", AGP.L("agp_hk_mode_defend", "DEFEND"), AGP.L("agp_hk_mode_auto", "AUTO")))
		function fr:Refresh()
			local st = W.state
			self.Filling = true
			list:Clear()
			for _, t in ipairs(st.list) do
				local line = list:AddLine(t.name, t.kind, dist(t.dist, true))
				line.Ent = t.ent
				local col = t.crew and KIND.crew or KIND[t.kind] or GOLD
				for _, c in ipairs(line.Columns) do c:SetTextColor(col) end   -- own colours: some skins draw list text white
				line.Paint = function(ln, w, h)
					if (ln:IsSelected()) then draw.RoundedBox(0, 0, 0, w, h, Color(110, 80, 26)) elseif (ln:IsHovered()) then draw.RoundedBox(0, 0, 0, w, h, Color(45, 34, 14)) end
					goauldLineText(ln) -- AGP 2026-11-08: light text on the selection
				end
				if (t.ent == st.target) then list:SelectItem(line) end
			end
			self.Filling = nil
		end
		fr:Refresh()
		timer.Create("AGP_HatakWeaponsRefresh", 1, 0, function()
			if (not IsValid(fr)) then timer.Remove("AGP_HatakWeaponsRefresh") return end
			cmd("refresh")
		end)
	end)

	-- pilot / gunner: small radar at the bottom right while the data is fresh
	local function gunShip() local s = LocalPlayer():GetNWEntity("AGPGunShip") return IsValid(s) and s or nil end
	hook.Add("HUDPaint", "AGP.HatakRadar", function()
		local st = W.state
		if (not st or CurTime() - st.time > 1.5 or not IsValid(st.ship)) then return end
		local veh = LocalPlayer():GetVehicle()
		local piloting = IsValid(veh) and veh:GetNWEntity("AGPHatak") == st.ship
		local gs = gunShip()
		if (not piloting and gs ~= st.ship) then return end
		local R = 110
		local cx, cy = ScrW() - R - 40, ScrH() - R - 60
		plate(cx - R - 18, cy - R - 30, R * 2 + 36, R * 2 + 52, 14, Color(10, 8, 4, 200), GOLD2)
		draw.SimpleText("RADAR  " .. dist(st.range), "AGPHatakSmall", cx - R - 6, cy - R - 26, GOLD)
		local hull, sh = st.ship:GetNWFloat("AGPHull", 1), st.ship:GetNWBool("AGPShieldOn") and st.ship:GetNWFloat("AGPShield", 0)
		draw.SimpleText(AGP.L("agp_hk_hull", "HULL %d %%", math.ceil(hull * 100)) .. (st.ship:GetNWBool("AGPCloaked") and ("   " .. AGP.L("agp_hk_cloaked", "CLOAKED")) or (sh and ("   " .. AGP.L("agp_hk_shield_pct", "SHIELD %d %%", sh)) or "")),
			"AGPHatakSmall", cx + R + 6, cy - R - 26, hull < 0.25 and Color(235, 70, 50) or GOLD, TEXT_ALIGN_RIGHT)
		drawRadar(st, cx, cy, R, false)
		if (gs) then   -- gunner: crosshair, cannon group, charge
			local x, y = ScrW() / 2, ScrH() / 2
			-- Goa'uld sight: a thin ring of short arcs, three gold pointers (pyramid shape) and a dot in the middle
			local spin = CurTime() * 0.4
			for k = 0, 11 do
				local a0, a1 = spin + k * math.pi / 6, spin + k * math.pi / 6 + math.pi / 10
				surface.SetDrawColor(GOLD.r, GOLD.g, GOLD.b, k % 2 == 0 and 230 or 90)
				surface.DrawLine(x + math.cos(a0) * 26, y + math.sin(a0) * 26, x + math.cos(a1) * 26, y + math.sin(a1) * 26)
			end
			draw.NoTexture()
			for k = 0, 2 do
				local a = -math.pi / 2 + k * 2 * math.pi / 3
				local cx2, cy2 = math.cos(a), math.sin(a)
				local px, py = -cy2, cx2
				surface.SetDrawColor(GOLD)
				surface.DrawPoly({ { x = x + cx2 * 12, y = y + cy2 * 12 }, { x = x + cx2 * 22 + px * 5, y = y + cy2 * 22 + py * 5 }, { x = x + cx2 * 22 - px * 5, y = y + cy2 * 22 - py * 5 } })
			end
			draw.RoundedBox(2, x - 2, y - 2, 4, 4, Color(255, 230, 160))
			local names = { AGP.L("agp_hk_g_top", "TOP"), AGP.L("agp_hk_g_front", "FRONT"), AGP.L("agp_hk_g_sides", "SIDES"), AGP.L("agp_hk_g_rear", "REAR"), AGP.L("agp_hk_g_bottom", "BOTTOM") }
			local g = LocalPlayer():GetNWInt("AGPGunGroup", 2)
			plate(x - 190, ScrH() - 120, 380, 64, 12, Color(10, 8, 4, 210), GOLD)
			draw.SimpleText(AGP.L("agp_hk_cannons", "CANNONS: %s", names[g] or "?"), "AGPHatakTitle", x, ScrH() - 106, GOLD, TEXT_ALIGN_CENTER)
			draw.SimpleText(AGP.L("agp_hk_gun_keys", "LMB fire   RMB zoom   R next cannons   1 ship menu   E leave"), "AGPHatakSmall", x, ScrH() - 76, GOLD2, TEXT_ALIGN_CENTER)
			local f = math.Clamp(1 - st.cool / 1.2, 0, 1)
			draw.RoundedBox(2, x - 60, y + 44, 120, 5, Color(40, 30, 12)); draw.RoundedBox(2, x - 60, y + 44, 120 * f, 5, f >= 1 and Color(120, 230, 120) or Color(255, 150, 60))
		end
	end)

	-- control crystal: insertion progress for the one at the slot
	hook.Add("HUDPaint", "AGP.HatakCrystal", function()
		local t = LocalPlayer():GetNWFloat("AGPCrystalInsert", 0)
		if (t <= CurTime()) then return end
		local f = 1 - (t - CurTime()) / 40
		local x, y = ScrW() / 2, ScrH() * 0.7
		plate(x - 200, y - 36, 400, 72, 12, Color(10, 8, 4, 220), GOLD)
		draw.SimpleText(AGP.L("agp_hk_inserting", "INSERTING CONTROL CRYSTAL - stay at the slot"), "AGPHatakText", x, y - 26, GOLD, TEXT_ALIGN_CENTER)
		draw.RoundedBox(3, x - 180, y + 4, 360, 14, Color(40, 30, 12))
		draw.RoundedBox(3, x - 180, y + 4, 360 * f, 14, Color(235, 70, 50))
		draw.SimpleText(math.ceil(t - CurTime()) .. " s", "AGPHatakSmall", x, y + 20, GOLD2, TEXT_ALIGN_CENTER)
	end)

	-- ===== engineering console: power monitor (core hub, system trays, spare rack, routing) =====
	local PW = {}
	local GROUPS = { { "core", AGP.L("agp_hk_power_core", "POWER CORE") }, { "weapons", AGP.L("agp_hk_weapons", "WEAPONS") }, { "hyperdrive", AGP.L("agp_hk_hyperdrive", "HYPERDRIVE") }, { "engines", AGP.L("agp_hk_sublight", "SUBLIGHT ENGINES") }, { "shields", AGP.L("agp_hk_shields", "SHIELDS") }, { "spare", AGP.L("agp_hk_spare", "SPARE RACK") } }
	local function powerCmd(c, fn)
		if (not PW.state or not IsValid(PW.state.ship)) then return end
		net.Start("AGP_HatakPowerCmd"); net.WriteEntity(PW.state.ship); net.WriteString(c)
		if (fn) then fn() end
		net.SendToServer()
	end
	local function powerCol(p) return p <= 0 and Color(235, 70, 50) or (p < 0.67 and Color(255, 160, 60) or Color(120, 230, 120)) end
	local function crystalIcon(x, y, k, t)   -- k: 0 empty, 1 good, 2 burnt
		local pts = { { x = x, y = y - 14 }, { x = x + 7, y = y }, { x = x, y = y + 14 }, { x = x - 7, y = y } }
		draw.NoTexture()
		if (k == 1) then surface.SetDrawColor(255, 190, 80); surface.DrawPoly(pts)
		elseif (k == 2) then surface.SetDrawColor(70, 60, 55); surface.DrawPoly(pts) end
		surface.SetDrawColor(GOLD2)
		for i = 1, 4 do local a, b = pts[i], pts[i % 4 + 1]; surface.DrawLine(a.x, a.y, b.x, b.y) end
		if (k == 2 and t > 0) then draw.SimpleText(math.ceil(t) .. "s", "AGPHatakSmall", x, y + 18, GOLD2, TEXT_ALIGN_CENTER) end
	end
	net.Receive("AGP_HatakPower", function()
		local s = { ship = net.ReadEntity(), route = net.ReadString(), core = net.ReadFloat(), hull = net.ReadFloat(), genOn = net.ReadUInt(4), genAll = net.ReadUInt(4), g = {} }
		s.arm, s.zpm = net.ReadUInt(2), net.ReadFloat()
		for _, gr in ipairs(GROUPS) do
			local slots = {}
			for i = 1, net.ReadUInt(4) do slots[i] = { net.ReadUInt(2), net.ReadFloat() } end
			s.g[gr[1]] = { slots = slots, power = net.ReadFloat() }
		end
		s.crew = net.ReadBool()
		PW.state = s
		if (IsValid(PW.frame)) then return end
		local fr = vgui.Create("DFrame")
		PW.frame = fr
		fr:SetTitle(""); fr:SetSize(640, 540); fr:Center(); fr:MakePopup(); fr:ShowCloseButton(false)
		fr.Paint = function(_, w, h)
			plate(0, 0, w, h, 22, DARK, GOLD)
			plate(6, 6, w - 12, h - 12, 18, Color(0, 0, 0, 0), GOLD2)
			local tw = draw.SimpleText(AGP.L("agp_hk_engineering", "ENGINEERING"), "AGPHatakTitle", 30, 14, GOLD)   -- (the glyphs after the title, however long it is in the player's language)
			draw.SimpleText(AGP.L("agp_hk_power", "POWER"), "AGPHatakGlyph", math.max(210, 30 + tw + 24), 20, GOLD2)
			local st = PW.state
			if (not st) then return end
			-- the hub: core power ring with its 3 crystals, generators below
			local cx, cy, R = 130, 170, 70
			surface.DrawCircle(cx, cy, R + 8, GOLD2.r, GOLD2.g, GOLD2.b, 255)
			local f = math.Clamp(st.core, 0, 1)
			for k = 0, math.floor(f * 60) do
				local a = k / 60 * math.pi * 2 - math.pi / 2
				local c = powerCol(st.core)
				surface.SetDrawColor(c.r, c.g, c.b, 220)
				surface.DrawLine(cx + math.cos(a) * (R - 6), cy + math.sin(a) * (R - 6), cx + math.cos(a) * R, cy + math.sin(a) * R)
			end
			draw.SimpleText(math.Round(st.core * 100) .. " %", "AGPHatakTitle", cx, cy - 4, powerCol(st.core), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(AGP.L("agp_hk_power_core", "POWER CORE"), "AGPHatakSmall", cx, cy + 20, GOLD2, TEXT_ALIGN_CENTER)
			local core = st.g.core.slots
			for i, sl in ipairs(core) do
				local a = (i - 1) / math.max(#core, 1) * math.pi * 2 - math.pi / 2
				crystalIcon(cx + math.cos(a) * (R + 30), cy + math.sin(a) * (R + 30), sl[1], sl[2])
			end
			draw.SimpleText(AGP.L("agp_hk_generators", "Naquadah generators: %d of %d running (+%d %%)", st.genOn, st.genAll, st.genOn * 15), "AGPHatakSmall", 30, 290, GOLD2)
			local armTxt = ({ [0] = AGP.L("agp_hk_arm_free", "free (a ZPM or one more crystal)"), AGP.L("agp_hk_arm_crystal", "crystal (+15 %)"), AGP.L("agp_hk_arm_burnt", "burnt crystal"), AGP.L("agp_hk_arm_zpm", "ZPM %d %% - power 130 %%", math.Round(st.zpm)) })[st.arm]
			draw.SimpleText(AGP.L("agp_hk_fourth_arm", "Fourth arm: %s", armTxt), "AGPHatakSmall", 30, 308, st.arm == 3 and Color(120, 200, 255) or GOLD2)
			draw.SimpleText(AGP.L("agp_hk_hull", "HULL %d %%", math.ceil(st.hull * 100)), "AGPHatakText", 30, 336, powerCol(st.hull < 0.25 and 0 or (st.hull < 0.6 and 0.5 or 1)))
			-- systems: crystals, power bar
			local y = 64
			for _, gr in ipairs(GROUPS) do
				if (gr[1] ~= "core") then
					local g = st.g[gr[1]]
					draw.SimpleText(gr[2], "AGPHatakText", 290, y, GOLD)
					for i, sl in ipairs(g.slots) do crystalIcon(300 + (i - 1) * 26, y + 38, sl[1], sl[2]) end
					if (gr[1] ~= "spare") then
						local p = g.power
						draw.RoundedBox(2, 400, y + 30, 160, 14, Color(40, 30, 12))
						draw.RoundedBox(2, 400, y + 30, 160 * math.Clamp(p / 1.3, 0, 1), 14, powerCol(p))
						surface.SetDrawColor(GOLD2); surface.DrawLine(400 + 160 / 1.3, y + 26, 400 + 160 / 1.3, y + 48)   -- 100 % mark
						draw.SimpleText(p <= 0 and AGP.L("agp_hk_offline", "OFFLINE") or (math.Round(p * 100) .. " %"), "AGPHatakText", 570, y + 37, powerCol(p), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					else
						draw.SimpleText(AGP.L("agp_hk_recharge_here", "burnt crystals recharge here"), "AGPHatakSmall", 420, y + 37, GOLD2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					end
					y = y + 72
				end
			end
		end
		local close = vgui.Create("DButton", fr)
		close:SetPos(fr:GetWide() - 50, 12); close:SetSize(30, 24); close:SetText("")
		close.Paint = function(_, w, h) plate(0, 0, w, h, 6, Color(40, 30, 12), GOLD); draw.SimpleText("X", "AGPHatakText", w / 2, h / 2, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
		close.DoClick = function() fr:Close() end
		local routes = { { "balanced", AGP.L("agp_hk_balanced", "BALANCED") }, { "weapons", AGP.L("agp_hk_weapons", "WEAPONS") }, { "hyperdrive", AGP.L("agp_hk_hyperdrive", "HYPERDRIVE") }, { "engines", AGP.L("agp_hk_engines", "ENGINES") }, { "shields", AGP.L("agp_hk_shields", "SHIELDS") } }
		for i, r in ipairs(routes) do
			local b = vgui.Create("DButton", fr)
			b:SetPos(30 + (i - 1) * 117, 444); b:SetSize(112, 30); b:SetText("")
			b.Paint = function(self2, bw, bh)
				local on = PW.state and PW.state.route == r[1]
				plate(0, 0, bw, bh, 7, on and Color(130, 95, 30) or (self2:IsHovered() and Color(60, 45, 18) or Color(32, 25, 10)), GOLD)
				draw.SimpleText(r[2], "AGPHatakText", bw / 2, bh / 2, on and Color(255, 235, 180) or GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			b.DoClick = function() powerCmd("route", function() net.WriteString(r[1]) end) end
		end
		local info = vgui.Create("DLabel", fr)
		info:SetPos(30, 480); info:SetSize(580, 50); info:SetWrap(true); info:SetTextColor(GOLD2); info:SetFont("AGPHatakSmall")
		info:SetText(AGP.L("agp_ui_power_route", "Route power: the chosen system gets 130 %, the others 85 %. E on a crystal pulls it, E at a free slot puts it in. Hits on the hull burn crystals out - swap them for spares."))
		timer.Create("AGP_HatakPowerRefresh", 1, 0, function()
			if (not IsValid(fr)) then timer.Remove("AGP_HatakPowerRefresh") return end
			powerCmd("refresh")
		end)
	end)
	-- ===== computer core consoles: ship log, address database, security, self-destruct =====
	local CC = {}
	local function compCmd(cmd, fn)
		local st = CC.state
		if (not st or not IsValid(st.ship)) then return end
		net.Start("AGP_HatakComputerCmd"); net.WriteEntity(st.ship); net.WriteString(st.kind); net.WriteString(cmd)
		if (fn) then fn() end
		net.SendToServer()
	end
	local function compButton(parent, txt, x, y, w, fn, on)
		local b = vgui.Create("DButton", parent)
		b:SetPos(x, y); b:SetSize(w, 30); b:SetText("")
		b.Paint = function(self2, bw, bh)
			local lit = on and on()
			plate(0, 0, bw, bh, 7, lit and Color(130, 95, 30) or (self2:IsHovered() and Color(60, 45, 18) or Color(32, 25, 10)), GOLD)
			draw.SimpleText(isfunction(txt) and txt() or txt, "AGPHatakText", bw / 2, bh / 2, lit and Color(255, 235, 180) or GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		b.DoClick = fn
		return b
	end
	local function compList(parent, x, y, w, h, cols)
		local list = vgui.Create("DListView", parent)
		list:SetPos(x, y); list:SetSize(w, h); list:SetMultiSelect(false); list:SetHeaderHeight(20)
		for _, c in ipairs(cols) do local col = list:AddColumn(c[1]); if (c[2]) then col:SetFixedWidth(c[2]) end end
		list.Paint = function(_, lw, lh) draw.RoundedBox(0, 0, 0, lw, lh, Color(0, 0, 0)); surface.SetDrawColor(GOLD2); surface.DrawOutlinedRect(0, 0, lw, lh, 1) end
		for _, c in ipairs(list.Columns) do
			c.Header:SetTextColor(GOLD)
			c.Header.Paint = function(_, hw, hh) draw.RoundedBox(0, 0, 0, hw, hh, Color(40, 30, 12)) end
		end
		list.AddGold = function(self2, col, ...)
			local line = self2:AddLine(...)
			for _, c in ipairs(line.Columns) do c:SetTextColor(col or GOLD) end   -- own colours: some skins draw list text white
			line.Paint = function(ln, lw, lh)
				if (ln:IsSelected()) then draw.RoundedBox(0, 0, 0, lw, lh, Color(110, 80, 26)) elseif (ln:IsHovered()) then draw.RoundedBox(0, 0, 0, lw, lh, Color(45, 34, 14)) end
				goauldLineText(ln) -- AGP 2026-11-08: light text on the selection
			end
			return line
		end
		return list
	end
	local TITLES = { ship_log = { AGP.L("agp_hk_ship_log", "SHIP LOG"), 640, 470 }, database = { AGP.L("agp_hk_addresses", "ADDRESSES"), 640, 470 }, security = { AGP.L("agp_hk_security", "SECURITY"), 560, 430 }, self_destruct = { AGP.L("agp_hk_self_destruct", "SELF-DESTRUCT"), 480, 300 },
		shields = { AGP.L("agp_hk_shields_cloak", "SHIELDS + CLOAK"), 480, 340 } }
	local SYSNAMES = { AGP.L("agp_hk_sys_rings", "RING TRANSPORTERS"), AGP.L("agp_hk_sys_doors", "DOORS"), AGP.L("agp_hk_sys_sensors", "SENSORS"), AGP.L("agp_hk_sys_comms", "COMMUNICATION") }

	net.Receive("AGP_HatakComputer", function()
		local s = { ship = net.ReadEntity(), kind = net.ReadString(), crew = net.ReadBool(), time = CurTime() }
		if (s.kind == "ship_log") then
			s.log = {}
			for i = 1, net.ReadUInt(8) do
				local l = { net.ReadString(), net.ReadString(), net.ReadString(), net.ReadString(), {} }
				for k = 1, net.ReadUInt(4) do l[5][k] = net.ReadString() end
				if (l[3] ~= "") then l.text = AGP_HatakText(l[3], l[4], l[5]) end   -- (in the player's language)
				s.log[i] = l
			end
		elseif (s.kind == "database") then
			s.own, s.busy, s.gates = net.ReadString(), net.ReadBool(), {}
			for i = 1, net.ReadUInt(8) do s.gates[i] = { name = net.ReadString(), adr = net.ReadString(), type = net.ReadString(), dist = net.ReadFloat() } end
		elseif (s.kind == "security") then
			s.alarm, s.lockdown, s.racks, s.aboard = net.ReadBool(), net.ReadBool(), {}, {}
			for i = 1, 4 do s.racks[i] = net.ReadUInt(2) end
			for i = 1, net.ReadUInt(8) do s.aboard[i] = { net.ReadString(), net.ReadBool() } end
		elseif (s.kind == "self_destruct") then
			s.at = net.ReadFloat()
		elseif (s.kind == "shields") then
			s.on, s.up, s.strength, s.power = net.ReadBool(), net.ReadBool(), net.ReadFloat(), net.ReadFloat()
			s.auto, s.cloaked, s.cloakAllowed = net.ReadBool(), net.ReadBool(), net.ReadBool()
		end
		local old = CC.state
		CC.state = s
		if (IsValid(CC.frame) and old and old.kind == s.kind) then if (CC.frame.Refresh) then CC.frame:Refresh() end return end
		if (IsValid(CC.frame)) then CC.frame:Remove() end
		local T = TITLES[s.kind]
		local fr = vgui.Create("DFrame")
		CC.frame = fr
		fr:SetTitle(""); fr:SetSize(T[2], T[3]); fr:Center(); fr:MakePopup(); fr:ShowCloseButton(false)
		fr.Paint = function(_, w, h)
			plate(0, 0, w, h, 22, DARK, GOLD)
			plate(6, 6, w - 12, h - 12, 18, Color(0, 0, 0, 0), GOLD2)
			draw.SimpleText(T[1], "AGPHatakTitle", 30, 14, GOLD)
			draw.SimpleText(AGP.L("agp_hk_computer_core", "COMPUTER CORE"), "AGPHatakGlyph", w - 70, 20, GOLD2, TEXT_ALIGN_RIGHT)
			if (not CC.state.crew) then draw.SimpleText(AGP.L("agp_hk_read_only", "read only - crew commands this console"), "AGPHatakSmall", 30, h - 26, Color(235, 120, 80)) end
		end
		compButton(fr, "X", fr:GetWide() - 50, 12, 30, function() fr:Close() end)
		local W, H = T[2], T[3]
		if (s.kind == "ship_log") then
			local list = compList(fr, 20, 52, W - 40, H - 100, { { AGP.L("agp_hk_time", "Time"), 70 }, { AGP.L("agp_hk_event", "Event") } })
			function fr:Refresh()
				list:Clear()
				for _, l in ipairs(CC.state.log) do
					local m = l[2]:lower()
					local col = (m:find("alarm") or m:find("attacked") or m:find("stranger") or m:find("offline") or m:find("self%-destruct")) and Color(235, 110, 80) or GOLD
					list:AddGold(col, l[1], l.text or l[2])   -- (the colour from the English line)
				end
			end
		elseif (s.kind == "database") then
			local list = compList(fr, 20, 72, W - 40, H - 170, { { AGP.L("agp_hk_gate", "Gate") }, { AGP.L("agp_hk_address", "Address"), 110 }, { AGP.L("agp_hk_type", "Type"), 80 }, { unitName(), 70 } })
			fr.PaintOver = function(_, w, h)
				local st = CC.state
				draw.SimpleText(AGP.L("agp_hk_own_gate", "This ship's gate: %s", st.own ~= "" and st.own or "-") .. (st.busy and ("   " .. AGP.L("agp_hk_busy", "(busy)")) or ""), "AGPHatakText", 30, 48, GOLD2)
			end
			compButton(fr, AGP.L("agp_hk_dial_room", "DIAL FROM THE GATE ROOM"), 20, H - 90, W - 40, function()
				local _, line = list:GetSelectedLine()
				if (line) then compCmd("dial", function() net.WriteUInt(line.Index, 8) end) end
			end)
			function fr:Refresh()
				local sel = list:GetSelectedLine()
				list:Clear()
				for i, g in ipairs(CC.state.gates) do
					local line = list:AddGold(nil, g.name ~= "" and g.name or AGP.L("agp_hk_no_name", "(no name)"), g.adr, g.type, dist(g.dist, true))
					line.Index = i
				end
				if (sel and list:GetLine(sel)) then list:SelectItem(list:GetLine(sel)) end
			end
		elseif (s.kind == "security") then
			compButton(fr, function() return CC.state.alarm and AGP.L("agp_hk_alarm_off", "ALARM OFF") or AGP.L("agp_hk_alarm", "ALARM") end, 20, 56, 250, function() compCmd("alarm") end, function() return CC.state.alarm end)
			compButton(fr, function() return CC.state.lockdown and AGP.L("agp_hk_lift_lockdown", "LIFT LOCKDOWN") or AGP.L("agp_hk_lockdown", "LOCKDOWN") end, 290, 56, 250, function() compCmd("lockdown") end, function() return CC.state.lockdown end)
			local list = compList(fr, 290, 140, 250, H - 190, { { AGP.L("agp_hk_aboard", "Aboard") }, { "", 60 } })
			fr.PaintOver = function(_, w, h)
				local st = CC.state
				draw.SimpleText(AGP.L("agp_hk_data_crystals", "DATA CRYSTALS"), "AGPHatakText", 30, 104, GOLD)
				for i, n in ipairs(st.racks) do
					local y = 136 + (i - 1) * 50
					draw.SimpleText(SYSNAMES[i], "AGPHatakSmall", 30, y - 8, GOLD2)
					for k = 1, 3 do crystalIcon(40 + (k - 1) * 24, y + 22, k <= n and 1 or 0, 0) end
					draw.SimpleText(n >= 2 and AGP.L("agp_hk_online", "ONLINE") or AGP.L("agp_hk_offline", "OFFLINE"), "AGPHatakText", 130, y + 22, n >= 2 and Color(120, 230, 120) or Color(235, 70, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end
				draw.SimpleText(AGP.L("agp_hk_two_of_three", "a function needs 2 of its 3 crystals"), "AGPHatakSmall", 30, h - 46, GOLD2)
			end
			function fr:Refresh()
				list:Clear()
				for _, a in ipairs(CC.state.aboard) do list:AddGold(a[2] and KIND.crew or KIND.player, a[1], a[2] and AGP.L("agp_hk_crew", "crew") or AGP.L("agp_hk_stranger", "stranger")) end
			end
		elseif (s.kind == "self_destruct") then
			fr.PaintOver = function(_, w, h)
				local st = CC.state
				local left = st.at > 0 and math.max(0, st.at - CurTime()) or 0
				draw.SimpleText(st.at > 0 and string.format("%d:%02d", math.floor(left / 60), left % 60) or AGP.L("agp_hk_safe", "SAFE"), "AGPHatakTitle", w / 2, 70,
					st.at > 0 and Color(255, 60 + 60 * math.sin(CurTime() * 8), 40) or Color(120, 230, 120), TEXT_ALIGN_CENTER)
			end
			for i, sec in ipairs({ 60, 120, 240 }) do
				compButton(fr, string.format("ARM %d:%02d", sec / 60, sec % 60), 20 + (i - 1) * 150, 130, 140, function() compCmd("destruct", function() net.WriteUInt(sec, 10) end) end)
			end
			compButton(fr, AGP.L("agp_hk_abort", "ABORT"), 20, 180, 440, function() compCmd("abort") end, function() return CC.state.at > 0 end)
		elseif (s.kind == "shields") then
			fr.PaintOver = function(_, w, h)
				local st = CC.state
				local col = st.up and Color(120, 200, 255) or (st.on and Color(235, 70, 50) or GOLD2)
				draw.SimpleText(st.cloaked and AGP.L("agp_hk_cloaked", "CLOAKED") or (st.up and AGP.L("agp_hk_shields_up", "SHIELDS UP") or (st.on and (st.power <= 0 and AGP.L("agp_hatak_shields_nopower", "SHIELDS DOWN - no power") or AGP.L("agp_hk_shields_recharging", "SHIELDS DOWN - recharging")) or AGP.L("agp_hk_shields_off", "SHIELDS OFF"))), "AGPHatakTitle", w / 2, 56, st.cloaked and Color(170, 140, 255) or col, TEXT_ALIGN_CENTER)
				draw.RoundedBox(3, 40, 100, w - 80, 18, Color(40, 30, 12))
				draw.RoundedBox(3, 40, 100, (w - 80) * math.Clamp(st.strength / 100, 0, 1), 18, Color(120, 200, 255))
				draw.SimpleText(AGP.L("agp_hk_strength", "strength %d %%     shield power %d %%", math.Round(st.strength), math.Round(st.power * 100)), "AGPHatakSmall", w / 2, 126, GOLD2, TEXT_ALIGN_CENTER)
			end
			compButton(fr, function() return CC.state.on and AGP.L("agp_hk_lower_shields", "LOWER SHIELDS") or AGP.L("agp_hk_raise_shields", "RAISE SHIELDS") end, 20, 160, 215, function() compCmd("shield") end, function() return CC.state.on end)
			compButton(fr, function() return CC.state.auto and AGP.L("agp_hk_auto_attack", "AUTO: ON ATTACK") or AGP.L("agp_hk_auto_off", "AUTO: OFF") end, 245, 160, 215, function() compCmd("shieldauto") end, function() return CC.state.auto end)
			compButton(fr, function() return CC.state.cloakAllowed and (CC.state.cloaked and AGP.L("agp_hk_drop_cloak", "DROP CLOAK") or AGP.L("agp_hk_cloak", "CLOAK")) or AGP.L("agp_hk_cloak_off_server", "CLOAK (off on this server)") end, 20, 200, 440,
				function() compCmd("cloak") end, function() return CC.state.cloaked end)
		end
		if (fr.Refresh) then fr:Refresh() end
		timer.Create("AGP_HatakComputerRefresh", 1, 0, function()
			if (not IsValid(fr)) then timer.Remove("AGP_HatakComputerRefresh") return end
			compCmd("refresh")
		end)
	end)

	-- pel'tak command console: a menu of every system's window
	-- the master menu: SHIP (status, helm, hyperspace, weapons, engineering), DOORS (every door), SYSTEMS (shields,
	-- cloak, alarm, lockdown, addresses, log, self-destruct). Opened at the command console or from the throne.
	local CMD = {}
	local function cmdSend(kind, arg) net.Start("AGP_HatakCommandOpen"); net.WriteEntity(CMD.ship); net.WriteString(kind); net.WriteString(arg or ""); net.SendToServer() end
	net.Receive("AGP_HatakCommand", function()
		local st = { ship = net.ReadEntity(), crew = net.ReadBool(), pilot = net.ReadString(), hull = net.ReadFloat(), core = net.ReadFloat(),
			shield = net.ReadBool(), cloak = net.ReadBool(), shieldUp = net.ReadBool(), alarm = net.ReadBool(), lockdown = net.ReadBool(), ls = net.ReadBool(), lsWhy = net.ReadString(), doors = {} }
		for i = 1, net.ReadUInt(6) do st.doors[i] = { name = net.ReadString(), open = net.ReadBool(), locked = net.ReadBool() } end
		local key = util.TableToJSON(st.doors) .. tostring(st.crew) .. st.pilot .. tostring(st.shield) .. tostring(st.shieldUp) .. tostring(st.cloak) .. tostring(st.alarm) .. tostring(st.lockdown) .. math.Round(st.hull * 100) .. math.Round(st.core * 100) .. tostring(st.ls) .. st.lsWhy
		CMD.ship, CMD.st = st.ship, st
		if (IsValid(CMD.frame)) then
			if (key ~= CMD.key) then CMD.key = key; CMD.frame.AGPFill() end   -- rebuild only when something changed
			return
		end
		CMD.key = key
		local fr = vgui.Create("DFrame")
		CMD.frame = fr
		fr:SetTitle(""); fr:SetSize(math.min(ScrW() - 40, 760), math.min(ScrH() - 40, 560)); fr:Center(); fr:MakePopup(); fr:ShowCloseButton(false)
		local page = CMD.page or "ship"
		fr.Paint = function(_, w, h)
			plate(0, 0, w, h, 22, DARK, GOLD)
			plate(6, 6, w - 12, h - 12, 18, Color(0, 0, 0, 0), GOLD2)
			draw.SimpleText("HA'TAK", "AGPHatakTitle", 30, 14, GOLD)
			if (not CMD.st.crew) then draw.SimpleText(AGP.L("agp_hk_view_only", "not your ship: view only"), "AGPHatakText", 150, 20, Color(220, 120, 80)) end
		end
		compButton(fr, "X", fr:GetWide() - 50, 12, 30, function() fr:Close() end)
		local body = vgui.Create("DPanel", fr); body:SetPos(20, 96); body:SetSize(fr:GetWide() - 40, fr:GetTall() - 116); body.Paint = nil
		local tabs = { { "ship", AGP.L("agp_hk_tab_ship", "SHIP") }, { "doors", AGP.L("agp_hk_sys_doors", "DOORS") }, { "systems", AGP.L("agp_hk_tab_systems", "SYSTEMS") } }
		for i, t in ipairs(tabs) do
			compButton(fr, t[2], 20 + (i - 1) * 180, 52, 170, function() page = t[1]; CMD.page = page; fr.AGPFill() end, function() return page == t[1] end)
		end
		local function line(y, txt, col) local l = vgui.Create("DLabel", body); l:SetPos(10, y); l:SetFont("AGPHatakText"); l:SetText(txt); l:SetTextColor(col or GOLD); l:SizeToContents() end
		local function on(b) return function() return b end end
		fr.AGPFill = function()
			body:Clear()
			local s2 = CMD.st
			local W = body:GetWide()
			if (page == "ship") then
				line(0, AGP.L("agp_hk_status1", "Hull %d %%     Power core %d %%", math.ceil(s2.hull * 100), math.Round(s2.core * 100)), s2.hull < 0.25 and Color(235, 70, 50) or GOLD)
				line(24, AGP.L("agp_hk_status2", "Shields: %s     Alarm: %s     Lockdown: %s", s2.cloak and AGP.L("agp_hk_st_cloaked", "cloaked") or (s2.shieldUp and AGP.L("agp_hk_st_up", "up") or AGP.L("agp_hk_st_down", "down")), s2.alarm and AGP.L("agp_hk_st_on", "ON") or AGP.L("agp_hk_st_off", "off"), s2.lockdown and AGP.L("agp_hk_st_on", "ON") or AGP.L("agp_hk_st_off", "off")))
				line(48, AGP.L("agp_hk_life_support", "Life support: %s", (s2.lsWhy == "no power" and AGP.L("agp_hatak_ls_nopower", "no power")) or (s2.lsWhy == "hull breached" and AGP.L("agp_hatak_ls_breach", "hull breached")) or (s2.lsWhy == "running" and AGP.L("agp_hk_ls_ok", "working")) or (s2.lsWhy == "off" and AGP.L("agp_hk_st_off", "off")) or s2.lsWhy), s2.ls and Color(140, 230, 140) or Color(235, 90, 60))
				line(72, AGP.L("agp_hk_helm", "Helm: %s   (throne or pilot chair: W/S/A/D, Space/Ctrl, Shift, V camera, 1 this menu)", s2.pilot ~= "" and s2.pilot or AGP.L("agp_hk_nobody", "nobody")), GOLD2)
				compButton(body, AGP.L("agp_hk_jump", "HYPERSPACE JUMP"), 0, 110, W / 2 - 6, function() cmdSend("jump") end)
				compButton(body, AGP.L("agp_hk_weapons", "WEAPONS"), W / 2 + 6, 110, W / 2 - 6, function() cmdSend("weapons") end)
				compButton(body, AGP.L("agp_hk_eng_power", "ENGINEERING - POWER"), 0, 150, W / 2 - 6, function() cmdSend("power") end)
				compButton(body, AGP.L("agp_hk_addr_dial", "ADDRESSES - DIAL THE GATE"), W / 2 + 6, 150, W / 2 - 6, function() cmdSend("database") end)
			elseif (page == "doors") then
				compButton(body, AGP.L("agp_hk_doors_open", "ALL DOORS OPEN"), 0, 0, W / 2 - 6, function() cmdSend("doors_open") end)
				compButton(body, AGP.L("agp_hk_doors_closed", "ALL DOORS CLOSED"), W / 2 + 6, 0, W / 2 - 6, function() cmdSend("doors_close") end)
				local sc = vgui.Create("DScrollPanel", body); sc:SetPos(0, 40); sc:SetSize(W, body:GetTall() - 40)
				for i, d in ipairs(s2.doors) do
					local row = sc:Add("DPanel"); row:Dock(TOP); row:SetTall(36); row:DockMargin(0, 0, 0, 4)
					row.Paint = function(_, w, h)
						plate(0, 0, w, h, 6, Color(24, 18, 8, 230), GOLD2)
						draw.SimpleText(d.name:gsub("^%l", string.upper), "AGPHatakText", 12, h / 2, GOLD, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
						draw.SimpleText(d.locked and AGP.L("agp_hk_locked", "LOCKED") or (d.open and AGP.L("agp_hk_d_open", "open") or AGP.L("agp_hk_d_closed", "closed")), "AGPHatakText", w - 330, h / 2, d.locked and Color(235, 90, 60) or (d.open and Color(140, 230, 140) or GOLD2), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					end
					compButton(row, d.open and AGP.L("agp_hk_close", "CLOSE") or AGP.L("agp_hk_open", "OPEN"), W - 240, 3, 110, function() cmdSend("door", d.name) end)
					compButton(row, d.locked and AGP.L("agp_hk_unlock", "UNLOCK") or AGP.L("agp_hk_lock", "LOCK"), W - 124, 3, 110, function() cmdSend("doorlock", d.name) end, on(d.locked))
				end
			else
				compButton(body, s2.shield and AGP.L("agp_hk_lower_shields", "LOWER SHIELDS") or AGP.L("agp_hk_raise_shields", "RAISE SHIELDS"), 0, 0, W / 2 - 6, function() cmdSend("shield") end, on(s2.shield))
				compButton(body, s2.cloak and AGP.L("agp_hk_drop_cloak", "DROP CLOAK") or AGP.L("agp_hk_cloak", "CLOAK"), W / 2 + 6, 0, W / 2 - 6, function() cmdSend("cloak") end, on(s2.cloak))
				compButton(body, s2.alarm and AGP.L("agp_hk_alarm_off", "ALARM OFF") or AGP.L("agp_hk_alarm", "ALARM"), 0, 40, W / 2 - 6, function() cmdSend("alarm") end, on(s2.alarm))
				compButton(body, s2.lockdown and AGP.L("agp_hk_lift_lockdown", "LIFT LOCKDOWN") or AGP.L("agp_hk_lockdown", "LOCKDOWN"), W / 2 + 6, 40, W / 2 - 6, function() cmdSend("lockdown") end, on(s2.lockdown))
				compButton(body, AGP.L("agp_hk_shields_details", "SHIELDS + CLOAK DETAILS"), 0, 80, W / 2 - 6, function() cmdSend("shields") end)
				compButton(body, AGP.L("agp_hk_security_details", "SECURITY DETAILS"), W / 2 + 6, 80, W / 2 - 6, function() cmdSend("security") end)
				compButton(body, AGP.L("agp_hk_ship_log", "SHIP LOG"), 0, 120, W / 2 - 6, function() cmdSend("ship_log") end)
				compButton(body, AGP.L("agp_hk_self_destruct", "SELF-DESTRUCT"), W / 2 + 6, 120, W / 2 - 6, function() cmdSend("self_destruct") end)
				compButton(body, s2.lsWhy == "off" and AGP.L("agp_hk_ls_on", "LIFE SUPPORT ON") or AGP.L("agp_hk_ls_off", "LIFE SUPPORT OFF"), 0, 160, W / 2 - 6, function() cmdSend("lifesupport") end, on(s2.ls))
			end
		end
		fr.AGPFill()
		fr.Think = function() if ((fr.NextRefresh or 0) < CurTime()) then fr.NextRefresh = CurTime() + 2; cmdSend("refresh") end end
	end)

	-- aboard a ship with the alarm on: klaxon + red flash at the screen edge; self-destruct countdown on the HUD
	local function nearShip(ship)
		local it = ship:GetNWEntity("AGPInterior")
		local pos = LocalPlayer():GetPos()
		return pos:DistToSqr(ship:GetPos()) < 6000 * 6000 or (IsValid(it) and pos:DistToSqr(it:GetPos()) < 5000 * 5000)
	end
	local nextKlaxon = 0
	hook.Add("HUDPaint", "AGP.HatakAlarm", function()
		for _, ship in ipairs(ents.FindByClass("agp_hatak")) do
			if (nearShip(ship)) then
				if (ship:GetNWBool("AGPAlarm")) then
					local a = 60 * math.max(0, math.sin(CurTime() * 5))
					surface.SetDrawColor(255, 20, 10, a)
					local w, h = ScrW(), ScrH()
					surface.DrawRect(0, 0, w, 24); surface.DrawRect(0, h - 24, w, 24); surface.DrawRect(0, 24, 24, h - 48); surface.DrawRect(w - 24, 24, 24, h - 48)
					if (CurTime() > nextKlaxon) then nextKlaxon = CurTime() + 2.4; LocalPlayer():EmitSound("ambient/alarms/klaxon1.wav", 60, 100, 0.45) end
				end
				-- AGP 2026-10-30: ship status for the crew: lockdown, life support failure (with the reason), hijacked
				local lines = {}
				if (ship:GetNWBool("AGPLockdown")) then lines[#lines + 1] = { AGP.L and AGP.L("agp_hatak_hud_lockdown", "LOCKDOWN - doors locked") or "LOCKDOWN - doors locked", Color(255, 90, 60) } end
				local why = ship:GetNWString("AGPLifeSupportWhy", "")
				if (not ship:GetNWBool("AGPLifeSupport", true) and why ~= "off") then
					local wt = (why == "no power" and AGP.L and AGP.L("agp_hatak_ls_nopower", "no power")) or (why == "hull breached" and AGP.L and AGP.L("agp_hatak_ls_breach", "hull breached")) or why
					lines[#lines + 1] = { string.format(AGP.L and AGP.L("agp_hatak_hud_ls", "LIFE SUPPORT FAILED (%s)") or "LIFE SUPPORT FAILED (%s)", wt), Color(255, 150, 60) }
				end
				local hj = ship:GetNWEntity("AGPHijacker")
				if (IsValid(hj) and hj:IsPlayer()) then lines[#lines + 1] = { string.format(AGP.L and AGP.L("agp_hatak_hud_hijack", "SHIP TAKEN OVER BY %s") or "SHIP TAKEN OVER BY %s", hj:Nick()), Color(255, 200, 80) } end
				-- AGP 2026-10-31: at the helm the ship HUD (lua/autorun/client/agp_ship_hud_ships.lua) shows the same in its status plate
				local helm = AGP.HUD and AGP.HUD.Current and AGP.HUD.Current() == ship
				if (#lines > 0 and not helm) then
					local w, x = 380, ScrW() - 400
					plate(x, 90, w, 16 + #lines * 24, 10, Color(10, 8, 4, 210), Color(235, 190, 90))
					for i, l in ipairs(lines) do draw.SimpleText(l[1], "AGPHatakSmall", x + 14, 98 + (i - 1) * 24, l[2]) end
				end
				local at = ship:GetNWFloat("AGPDestructAt", 0)
				if (at > 0) then
					local left = math.max(0, at - CurTime())
					local x = ScrW() / 2
					plate(x - 150, 20, 300, 60, 12, Color(10, 8, 4, 220), Color(235, 70, 50))
					draw.SimpleText(AGP.L("agp_hk_self_destruct", "SELF-DESTRUCT"), "AGPHatakSmall", x, 26, Color(235, 120, 80), TEXT_ALIGN_CENTER)
					draw.SimpleText(string.format("%d:%02d", math.floor(left / 60), left % 60), "AGPHatakTitle", x, 42, Color(255, 60 + 60 * math.sin(CurTime() * 8), 40), TEXT_ALIGN_CENTER)
				end
			end
		end
	end)

	-- shields: a faint golden shell around the hull, flashing where it is hit
	local matShield = Material("effects/com_shield002a")
	local matGlow2 = Material("sprites/light_glow02_add")
	local shieldHits = {}
	net.Receive("AGP_HatakShieldHit", function()
		local ship, pos = net.ReadEntity(), net.ReadVector()
		if (not IsValid(ship)) then return end
		ship.AGPShieldFlash = CurTime()
		shieldHits[#shieldHits + 1] = { pos = pos, t = CurTime() }
		sound.Play("shields/shield_hit.mp3", pos, 110, math.random(90, 110))
	end)
	hook.Add("PostDrawTranslucentRenderables", "AGP.HatakShield", function(depth, sky)
		if (sky) then return end
		for _, ship in ipairs(ents.FindByClass("agp_hatak")) do
			if (ship:GetNWBool("AGPShieldOn") and ship:GetPos():DistToSqr(EyePos()) < 40000 * 40000) then
				local flash = math.max(0, 1 - (CurTime() - (ship.AGPShieldFlash or 0)) / 0.6)
				local m = Matrix()
				m:Translate(ship:LocalToWorld(Vector(0, 0, -75)))
				m:Rotate(ship:GetAngles())
				m:Scale(Vector(3300, 3300, 2150))   -- taller: room above the pyramid tip and below the hull
				cam.PushModelMatrix(m)
				render.SetColorMaterial()
				render.DrawSphere(Vector(0, 0, 0), 1, 40, 20, Color(255, 190, 90, 22 + 90 * flash))   -- the golden bubble
				render.SetMaterial(matShield)
				render.DrawSphere(Vector(0, 0, 0), 1, 40, 20, Color(255, 210, 130, 90 + 160 * flash)) -- the energy pattern on it
				cam.PopModelMatrix()
			end
		end
		render.SetMaterial(matGlow2)
		for i = #shieldHits, 1, -1 do
			local h = shieldHits[i]
			local f = 1 - (CurTime() - h.t) / 0.8
			if (f <= 0) then table.remove(shieldHits, i)
			else render.DrawSprite(h.pos, 900 * (1.2 - f), 900 * (1.2 - f), Color(255, 200, 110, 255 * f)) end
		end
	end)

	-- kel'no'reem: meditating on a mat
	hook.Add("HUDPaint", "AGP.HatakKelnoreem", function()
		local ply = LocalPlayer()
		if (not ply:GetNWBool("AGPKelnoreem")) then return end
		local x, y = ScrW() / 2, ScrH() * 0.72
		plate(x - 170, y - 22, 340, 44, 10, Color(10, 8, 4, 200), GOLD)
		draw.SimpleText("KEL'NO'REEM - " .. (ply:Health() < ply:GetMaxHealth() and AGP.L("agp_hk_healing", "healing %d", ply:Health()) or AGP.L("agp_hk_at_peace", "at peace")), "AGPHatakText", x, y, GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end)

	-- carrying a power crystal
	hook.Add("HUDPaint", "AGP.HatakPowerCarry", function()
		local k = LocalPlayer():GetNWInt("AGPPowerCarry", 0)
		if (k == 0) then return end
		local x, y = ScrW() / 2, ScrH() * 0.78
		plate(x - 190, y - 20, 380, 40, 10, Color(10, 8, 4, 210), GOLD)
		draw.SimpleText(AGP.L("agp_hk_crystal_hint", "%s  -  E at a free slot puts it in", k == 3 and AGP.L("agp_hk_data_crystal", "DATA CRYSTAL") or (k == 2 and AGP.L("agp_hk_burnt_power_crystal", "BURNT POWER CRYSTAL") or AGP.L("agp_hk_power_crystal", "POWER CRYSTAL"))), "AGPHatakText", x, y, k == 2 and Color(170, 150, 130) or GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end)

	-- gunner: the view comes from the chosen cannon on the hull, the mouse aims, clicks go to the server
	local zoom, gunWas = false, {}
	hook.Add("CalcView", "AGP.HatakGunner", function(ply, pos, ang, fov)
		local s = gunShip()
		if (not s or ply ~= LocalPlayer()) then return end
		local g = math.Clamp(ply:GetNWInt("AGPGunGroup", 2), 1, #s.Cannons)
		local groups = s.CannonGroups
		local c = s.Cannons[groups[g][2][1]]
		W.gunAim = ang:Forward()   -- what the crosshair points at, sent with every shot
		return { origin = s:LocalToWorld(c.pos + c.out:GetNormalized() * 420), angles = ang, fov = zoom and 25 or fov, drawviewer = true }
	end)
	hook.Add("PreDrawViewModel", "AGP.HatakGunner", function() if (gunShip()) then return true end end)
	hook.Add("StartCommand", "AGP.HatakGunner", function(ply, ucmd)
		local s = gunShip()
		if (not s or ply ~= LocalPlayer()) then gunWas = {} return end
		local b = ucmd:GetButtons()
		local function edge(k) local d = bit.band(b, k) ~= 0; local e = d and not gunWas[k]; gunWas[k] = d; return e, d end
		local _, att = edge(IN_ATTACK)
		if (att and (W.nextShot or 0) < CurTime()) then W.nextShot = CurTime() + 0.25; W.state = W.state or { list = {} }; net.Start("AGP_HatakWeaponsCmd"); net.WriteEntity(s); net.WriteString("gunfire"); net.WriteNormal(W.gunAim or EyeAngles():Forward()); net.SendToServer() end
		local _, z = edge(IN_ATTACK2); zoom = z
		if (edge(IN_RELOAD)) then net.Start("AGP_HatakWeaponsCmd"); net.WriteEntity(s); net.WriteString("gunnext"); net.SendToServer() end
		if (edge(IN_USE)) then net.Start("AGP_HatakWeaponsCmd"); net.WriteEntity(s); net.WriteString("gunleave"); net.SendToServer() end
		ucmd:ClearMovement(); ucmd:SetButtons(0)
	end)
end
