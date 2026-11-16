-- Ascension Gates help (wiki), English. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Help",
    search = "Search...",
    size = "Text size",
    short = "IN SHORT",
    intro = "Everything about Ascension Gates: what the parts do and how you control them.",
    open = "Open the help",
},
pages = {

{ id = "start", title = "Start here", icon = "icon16/star.png", body = [[
= Ascension Gates is a Stargate pack: gates, rings, ships, weapons, shields and power. This help explains every part in short steps.
# Where things are
- **Spawn things:** press [Q], tab **Ascension Gates** (top left). Categories on the left.
- **Tools:** [Q], right side, tab **Ascension Gates** (gates, doors, weapons, keys) and tab **PowerGrid** (energy, power, life support).
- **Settings:** [Q] > Ascension Gates > Config. Ship settings: **AGP Ships**.
- **Power and life support settings:** [Q] > PowerGrid > Settings > **PowerGrid**.
- **This help:** console command **agp_wiki**, or [Q] > Ascension Gates > Config > **Help (Wiki)**.
# First steps
1. Press [Q] and open the **Ascension Gates** tab.
2. Spawn two Stargates and a DHD (category **StarGates and Rings**).
3. Look at the DHD and press [E]. Dial the other gate.
4. Walk through.
> Hover the mouse over a setting: a short line tells you what it does.
# The pages of this help
- {page:gates|Stargates, DHD and rings}
- {page:hatak|Ha'tak mothership}
- {page:glider|Death Glider}
- {page:alkesh|Al'kesh and other ships}
- {page:spacegrid|PowerGrid: power and energy}
- {page:goauldpower|Goa'uld power hub and crystals}
- {page:lifesupport|Life support and space}
- {page:weapons|Hand weapons}
- {page:keys|Change keys}
- {page:admin|Settings for admins}
- {page:problems|Problems and fixes}
]] },

{ id = "gates", title = "Stargates, DHD and rings", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Spawn a gate and a DHD, press E on the DHD, dial. Rings move you between ring platforms close by.
# Get them
- [Q] > Ascension Gates > **StarGates and Rings**: gates, DHDs, rings and ring panels.
- Tools ([Q] > right side > Ascension Gates > Tech): Mobile DHD, Supergate DHD, Iris, Goa'uld Iris.
# Dial with the DHD
1. Put the DHD near the gate (closer than 1000).
2. Look at a glyph on the DHD and press [E]: it lights up.
3. Press all glyphs of the address, then the big centre button.
- Centre button with no glyphs pressed: the dial menu opens.
- Centre button while the gate is open: the gate closes.
# Dial with the gate menu
1. Look at the gate and press [E].
2. Type the address or pick it from the list.
3. Click **Dial**. **Abort Dialling / Close Gate** stops it.
- In the same menu you set the gate's own address, group and name, and if it is private.
# Iris
- Tool **Iris**: left click on a gate. Keys: numpad [2] toggles it.
- **Iris Computer** (StarGates and Rings): touch it to a gate with an iris, [E] = menu (codes, auto close).
- **GDO** (weapon): right click = type your code, left click = send it to an open gate.
# Rings
- Ring platform + ring panel, close together (panel works for rings within 500).
- [E] on a panel button presses it. **DIAL** with no digits = to the nearest rings. With digits = to that ring address.
- [E] on the ring base: give it a name (address).
- **Ring Caller** (weapon): left click calls the nearest rings, right click opens the dial window.
! Rings crush you if you stand still where they come down. Step onto the platform or away from it.
]] },

{ id = "hatak", title = "Ha'tak mothership", icon = "icon16/house.png", body = [[
= A huge Goa'uld mothership you can walk through, fly, fight with and power up. The inside is much bigger than the outside.
# Spawn
- [Q] > Ascension Gates > **Bigger Motherships** > Ha'tak.
- It appears high above the spot you aim at (or in front of you if you aim at the sky). It hovers.
# Get in
- **Hangar:** the big door at the bottom of the pyramid. [E] on it opens it. Walk in: you are straight in the hangar inside.
- The hangar door outside and inside are one door: open or closed on both sides. A door control (gold plate) is beside it inside and outside.
- **Rings:** use rings outside near the ship, or a ring panel inside.
- [E] on a door or on the gold control beside it: door opens or closes.
- An open door: look into the doorway and press [E] to close it.
> Inside you can always leave the way you came: the hangar opening works both ways.
# The decks
1. **Hangar deck:** hangar, ring room, kel'no'reem room, Jaffa barracks, glider bay.
2. **Pel'tak (bridge):** throne, pilot chair, weapons, navigation and command consoles.
3. **Gate room:** Stargate with DHD.
4. **Command deck:** quarters with sarcophagus, armoury, computer core.
5. **Engineering:** engine room, holding cells, shield room.
- Travel between decks: [E] on a ring panel > pick the deck.
# Who may use it
- The **crew** = the owner and their friends (prop protection friends).
- Strangers can take the ship with the **control crystal**. See {page:hatak_systems|Ha'tak systems}.
# More
- {page:hatak_fly|Flying, jumping and weapons}
# Master menu (the whole ship in one window)
- Open it: [1] on the throne, in the pilot chair or as gunner, or [E] on the command console on the pel'tak.
- **SHIP:** hull, power, shields, who flies. Hyperspace, weapons, engineering, addresses.
- **DOORS:** every door: open, close, lock. All doors open or closed at once.
- **SYSTEMS:** shields, cloak, alarm, lockdown, ship log, self-destruct.
- {page:hatak_systems|Power, computer, shields, damage and rooms}
]] },

{ id = "hatak_fly", title = "Ha'tak: fly, jump, fight", icon = "icon16/arrow_up.png", body = [[
= Sit in the pilot chair on the pel'tak. W/S/A/D to fly, R for hyperspace, V for the camera. Weapons at the weapons console.
# Take the helm
1. Go to the pel'tak (bridge).
2. Sit on the **throne** ([E]) or in the pilot chair ([E] on the pilot console).
3. Leave the seat with [E].
- The throne goes first: if both are taken, the throne flies.
- [1] opens the **master menu** (also in gunner mode).
- The front of the ship is the hangar side: [W] flies that way.
# Flying keys
- [W] forward, [S] back.
- [A] / [D] turn left / right.
- [Space] up, [Ctrl] down.
- Hold [Shift]: 4x as fast.
- [V]: camera. It starts behind and above the ship (mouse wheel = distance). Then: the seat, then the view from the front tip.
- The window on the pel'tak shows the real view outside.
- [R]: hyperspace menu.
- No pilot: the ship slows down and stops.
> Nobody aboard slides around while the ship flies.
# Hyperspace jump
1. Press [R] in the pilot seat (or [E] on the navigation console).
2. Pick a target: saved marks, a Stargate or another player. Or type x y z.
3. Click **Jump**. The ship charges (3 s), a window opens, you fly through.
- **Save mark 1/2/3 here** remembers the spot.
- Needs 30 % hyperdrive power. 8 s pause between jumps.
# Weapons
- [E] on the **weapons console**: radar from above and a list of targets.
- **OFF:** no shots. **DEFEND:** shoots only what attacked the ship. **AUTO:** also NPCs and strangers.
- **FIRE:** one volley at the chosen target. **KEEP FIRING:** again and again.
- **MANUAL (GUNNER)** or sit in the gunner chair: you aim yourself.
## Gunner keys
- Mouse aims, [Mouse1] fire, hold [Mouse2] zoom.
- [R] next cannon group (top, front, sides, rear, bottom).
- [E] leave.
! Firing drops your own cloak.
]] },

{ id = "hatak_systems", title = "Ha'tak systems and rooms", icon = "icon16/cog.png", body = [[
= Crystals power everything. Pull one and a system gets weaker. The computer core runs rings, doors, sensors and messages.
# Engine room: power crystals
- The power core (hub) holds 3 crystals. Trays hold 3 crystals each: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] on a crystal: you pull it out and carry it.
- [E] at a free slot: you put it in.
- Burnt crystals (dark) come from hard hits. Put them in the **spare rack**: they recharge in 60 s.
- The two naquadah generators: [E] switches them on (+15 % each).
- **Fourth hub arm:** one more crystal (+15 %) or a **ZPM** (130 %). Bring the ZPM close with the gravity gun: it snaps on.
- **Engineering console:** shows all power. Buttons send more power to one system.
# Computer core: data crystals
- Blue crystals in 4 racks: **Rings**, **Doors**, **Sensors**, **Communication**. 2 of 3 must be in, or that function stops.
- **Self-destruct:** 1, 2 or 4 minutes. **ABORT** stops it.
- **Ship log:** what happened aboard.
- **Addresses:** every gate on the map. **DIAL** dials from the gate room.
- **Security:** alarm on/off, lockdown (all doors locked, the crew can still open them).
# Shields and cloak
- Shield room console or command console: **RAISE / LOWER SHIELDS**.
- **AUTO:** shields go up by themselves when someone attacks.
- The shield stops every weapon, also the owner's: shots stop at the golden bubble.
- **CLOAK:** the ship fades out. Needs 30 % shield power. Shields drop while cloaked.
# Life support
- Air, warmth and gravity aboard, also in space.
- It needs power from the core and a hull above 10 %. Without it, inside is like outside (no air in space).
- Master menu: status on SHIP, on/off on SYSTEMS.
# Damage
- Only heavy hits count. While the shield holds, it takes the hits.
- Explosions **inside** hurt twice as much and burn crystals nearby.
- Alarm at 50, 25 and 10 % hull. At 0 the ship explodes (admins can switch that off).
- The **repair tool** repairs the hull.
# Rooms
- **Glider bay:** 4 Death Gliders. [E] = fly. Fly out through the launch tunnel. Lost gliders come back after 60 s.
- The launch tunnels have doors inside and outside. They open by themselves when you fly a glider at them. Open or close them in the master menu.
- **Barracks:** [E] on the bunk console = you respawn aboard. Armour chest: [E] = +50 armour (once a minute).
- **Kel'no'reem:** crouch ([Ctrl]) on a mat = you heal slowly.
- **Sarcophagus:** [E] to lie in it and heal.
- **Weapons:** [E] on a staff weapon on the wall: you take it (a new one is there after 2 minutes). [E] on a zat chest: a zat.
- **Holding cells:** [E] on the panel beside a cell switches its force field (crew only).
# Taking the ship (hijack)
1. Find the **control crystal** hidden somewhere inside. [E] picks it up.
2. Go to the crystal slot on the pel'tak (right wall). [E] starts.
3. Stay close for 40 s. The alarm goes off.
4. Done: you and your friends are the new crew.
- The old crew can stop it: [E] on the slot.
]] },

{ id = "glider", title = "Death Glider", icon = "icon16/bullet_go.png", body = [[
= Small Goa'uld fighter. W to fly, mouse to steer, Mouse1 to shoot. With no key pressed it hovers.
# Get it
- [Q] > Ascension Gates > **Fleet: Ships and Fighters** > Death Glider. Or in the Ha'tak glider bay.
# Keys
- [E] on the glider: get in. [E] again: get out.
- [W] fly forward, [S] slowly back. Hold [Shift]: faster.
- Mouse: steer.
- [1]: cockpit view on / off.
- No key: it holds its place in the air.
- [Mouse1]: fire both staff cannons.
- Mouse wheel: roll. [Mouse3]: roll back to level.
- Arrow keys: camera distance and height.
- [Backspace]: self-destruct.
# Free flight (server setting)
- With **agp_glider_free_flight 1**: [S] back, [A] / [D] sideways, [Space] up, [Ctrl] down.
# HUD
- Bottom left: hull, speed, staff cannons, the keys.
- 300 hull. At 0 it explodes.
> Change the keys: {page:keys|Change keys}.
]] },

{ id = "alkesh", title = "Al'kesh and other ships", icon = "icon16/bullet_go.png", body = [[
= Every ship: E to get in and out, W/A/S/D and mouse to fly, Mouse1 to shoot.
# Al'kesh
- [Q] > Ascension Gates > **Fleet: Ships and Fighters**. Aim at the ground to spawn it.
- [W] [S] [A] [D] fly. [Space] up, [Ctrl] down. Hold [Shift]: faster.
- [Mouse1] fire. Mouse wheel roll, [Mouse3] level again.
- [Enter]: landing mode (stays level).
- [E] get out. [Backspace] self-destruct.
# Capital ships
- Aurora, Destiny, Gate Seeder, O'Neill, Ori Mothership, Prometheus, Replicator Mothership, Traveler, Wraith Cruiser.
- Same keys as the Al'kesh. Also [Mouse2] track target, [G] shield.
# Small ships
- **Puddle Jumper:** [Mouse1] drones (opens the pods by itself), [Mouse2] hold = drones follow your aim, [Alt] cloak, [2] door, [T] hover, [G] shield, [R] dial the nearest gate.
- **Tel'tak:** [Mouse2] staff cannons, [G] shield, [Alt] cloak, hold [R] hyperspace, [2] door. Ring beam: [Enter] (landing mode), then [Mouse1].
- **F-302:** [Mouse1] guns, [Mouse2] missiles, [Alt] flares, [B] boost, [2] eject.
- **Daedalus:** [Mouse1] railguns, [Mouse2] Asgard beam, [1] to [8] missiles.
- **Wraith Dart:** [C] collect people, [Alt] put them out.
> Change the keys: {page:keys|Change keys}.
]] },

{ id = "spacegrid", title = "PowerGrid: power and energy", icon = "icon16/lightning.png", body = [[
= PowerGrid is the tool tab for energy. Place power parts, link them, feed them with ZPMs or generators.
# Where
- [Q] > right side > tab **PowerGrid**.
- **PowerGrid:** the PowerGrid Parts tool (all parts in one picture grid).
- **Energy:** ZPM, ZPM hubs, naquadah generators, Goa'uld power hub, PowerGrid Connector.
- **Settings:** PowerGrid settings and this help.
# Place a part
1. Take the tool **PowerGrid Parts**.
2. Click a picture on the right (for example an energy cell).
3. Aim where it should stand. You see a ghost of it.
4. Left click [Mouse1]: placed. Right click [Mouse2]: placed turned by 90 degrees.
- Aim at a part and press [R]: that part is chosen.
- On a ship or prop it is welded to what you aim at (box **Weld to what I aim at**).
# The parts
- **Energy cells (XS to XL):** store energy.
- **Solar panels:** make energy while open sky is above them.
- **Wind turbine:** makes energy, more the higher it stands.
- **Black Hole Energy:** holds every resource (admins only, unless allowed).
- **Power nodes:** link everything placed on them. Their display shows the network.
- **Power displays:** show the network they are linked to.
- **Power valve:** on = energy flows between two networks, off = they are apart. [E] switches it.
- **Resource tanks:** hold one resource (oxygen, water ...). [E] changes the resource while empty.
- **Life support:** see {page:lifesupport|Life support}.
# Linking (how parts share energy)
- Admins choose the mode: **Manual**, **Automatic**, **Mix** or **Off** (PowerGrid settings).
- **Manual:** tool **PowerGrid Connector**: left click the parts (they turn blue), right click the part or power node to link them to. [R] clears the selection; [R] on a part removes its links.
- **Automatic:** parts welded together share by themselves.
- **Off:** everything has free energy.
! Spacebuild installed? Then Spacebuild's network is used. Our power nodes are Spacebuild nodes then: link with the PowerGrid Connector. Admins can switch on **Always PowerGrid**.
# Energy sources
- **ZPM:** tool **ZPM MK III**. Put it into a ZPM hub or a {page:goauldpower|Goa'uld power hub}.
- **Naquadah generator:** tool in Energy.
- **Goa'uld power crystals:** in the {page:goauldpower|Goa'uld power hub}.
]] },

{ id = "goauldpower", title = "Goa'uld power hub and crystals", icon = "icon16/rainbow.png", body = [[
= A brass hub with a gold power core. Its 4 arms take Goa'uld power crystals or ZPMs. The core pulses brighter the more power it has.
# Get it
- Tool: [Q] > PowerGrid > Energy > **Goa'uld Power Hub + Crystals**.
- Or spawn tab: Ascension Gates > **PowerGrid**.
# Use it
1. Left click [Mouse1] with the tool: a hub.
2. Aim at an arm and right click [Mouse2]: a crystal sits on that arm.
3. ZPM: take the ZPM tool, aim at an arm, left click: the ZPM sits on that arm.
4. Link the hub to your network like any other part ({page:spacegrid|PowerGrid}).
- Touch a crystal or ZPM to an arm (gravity gun or physics gun): it snaps on.
- [E] on a crystal or ZPM: it comes out.
- [E] on the hub: shows crystals, ZPMs and energy in the chat.
- Look at the hub: a small plate shows crystals and energy.
> A ZPM gives ten times the power of a crystal and drives the core harder.
# Slider in the tool
- **Crystal charge:** how full new crystals are (0 to 100 %).
]] },

{ id = "lifesupport", title = "Life support and space", icon = "icon16/heart.png", body = [[
= In space there is no air and it is cold. Your suit protects you for a while. Life support makes a ship or area safe.
# When is it on?
- Admins choose: space maps only (default), every map, or off ({page:admin|Settings for admins}).
# Your suit
- Three values: **air**, **energy**, **coolant**. Full when you spawn.
- No air or under water: air goes down. Good air: it fills up again.
- Cold: energy goes down. Hot: coolant goes down.
- A value at 0 hurts you.
- A box bottom left shows up only when something is wrong.
# Life Support Core
- On a ship: the whole ship gets air. [E] switches it.
- Not on a ship: a bubble of air. [E] changes the size (300 to 2000, then off).
- Needs energy and oxygen (it makes oxygen from water).
# Refill your suit
- **Suit Dispenser:** [E] refills air, energy and coolant from its network.
- **Air Compressor:** oxygen from breathable air. **Water Pump:** water while it stands in water.
# Gate report
- When a gate dials, you get a short report: air, temperature, gravity on the other side, and if you need a suit.
]] },

{ id = "weapons", title = "Hand weapons", icon = "icon16/bomb.png", body = [[
= Get them in [Q] > Ascension Gates > Weapons. Mouse1 = main use, Mouse2 = second use.
# Goa'uld
- **Zat'nik'tel:** 1st shot stuns, 2nd kills, 3rd makes it vanish.
- **Staff weapon:** [Mouse2] ready it, [Mouse1] fire.
- **Hand device:** [Mouse1] use, [Mouse2] next mode.
- **Healing device:** hold on a player to heal.
- **Mobile DHD:** put it on a gate.
# Earth (SGC)
- **P90 (PDW):** [Mouse1] fire, [Mouse2] aim, [R] reload.
- **Beretta:** [Mouse1] fire, [R] reload.
- **GDO:** [Mouse2] type code, [Mouse1] send.
# Others
- **Ori hand weapon / staff, Wraith blaster, Ronon's gun, Asuran gun.**
- **Tac:** throw, again = blow up. [Mouse2] kill / stun / smoke.
- **Repair tool:** hold on a ship, gate or DHD to repair it.
- **Control chair (Ancient, spawn tab Weapons):** [E] to sit (needs a charged ZPM in its hub). [1] = target list: lock the drones on a target, or free aim.
- **Personal shield, Sodan cloak:** [Mouse1] on, [Mouse2] off.
- **Mimetic imaging device:** hold [Mouse1] on a person close in front of you to image them, [Mouse2] projection on / off, [R] forget the image.
]] },

{ id = "keys", title = "Change keys", icon = "icon16/keyboard.png", body = [[
= Ship keys can be changed for most small ships in the Keybinders menu.
# How
1. [Q] > right side > Ascension Gates > **Keybinders**.
2. Pick the ship.
3. Click a line once, then quickly a second time (it turns orange).
4. Press the new key or mouse button. [Esc] cancels.
- Ships: Daedalus, Wraith Dart, Gate Glider, Death Glider, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- The Ha'tak uses your normal GMod keys ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) and [V].
- For your own key: bind it to **agp_hatak_camera** (console: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Settings for admins", icon = "icon16/shield.png", body = [[
= Admins (and you in single player) change the server settings. Everyone else only sees them. Hover a setting for a short tip.
# Ship settings: [Q] > Ascension Gates > Config > AGP Ships
- **Hijacking:** crew only / with the control crystal / anyone.
- **Weapons fire at owner and friends:** yes or no.
- **Weapon + radar range:** how far guns shoot and the radar sees.
- **Radar: most targets shown.**
- **Power crystals strangers may pull:** 0 to 15 (default 2). The crew has no limit.
- **Ship can be destroyed:** yes (default) or no (the hull stays at 1).
- **Hull health (new ships):** 10,000 to 1,000,000 (default 100,000).
- **Cloak allowed:** yes or no.
- **Glider bay: lost gliders come back:** yes or no, and after how many seconds (default 60).
- **Shield bubble (all ships):** only when hit or switched on or off (default), or always visible.
- **Self-destruct countdown (all ships):** 1 to 600 seconds (default 5).
# Power settings: [Q] > PowerGrid > Settings > PowerGrid
- **How parts connect:** Manual / Automatic / Mix / Off. See {page:spacegrid|PowerGrid}.
- **Always PowerGrid:** use PowerGrid even with Spacebuild (needs a map change).
- **Black Hole Energy:** admins only or everyone.
- **Space simulation:** space maps only / every map / off. See {page:lifesupport|Life support}.
- **Gate destination report:** on or off.
# Only for you (every player)
- Cables, machine sounds, gate report on your screen, units for distance, temperature and gravity.
]] },

{ id = "problems", title = "Problems and fixes", icon = "icon16/help.png", body = [[
= Something does not work? Look here first.
# Icons in the Q menu turn pink and nothing spawns
- You hold [Ctrl] (or it got stuck). [Ctrl] + click **selects** icons (pink) instead of spawning them.
- Fix: let go of [Ctrl] (press it once), click an empty spot in the icon area.
# I click an icon and nothing appears
- Look at the ground in front of you, not at the far sky.
- Big ships appear high above the ground or in front of you. Look around.
- Admins can switch parts off or limit them (Ascension Gates > Config > About & Credits > Settings).
# The glider drops
- The Death Glider holds its height when you press no key. Is it falling? It may be destroyed or out of the map.
# A Ha'tak console says "crew only"
- Only the owner and their friends may use it. Or take the ship with the control crystal ({page:hatak_systems|Ha'tak systems}).
# A ship system says OFFLINE
- Check the crystals in the engine room and the blue data crystals in the computer core.
# I am stuck in a doorway or door
- Doorways of ship interiors do not let you through when the other side is closed. Open the door first.
- Still stuck: noclip ([V]) or respawn.
# A tool shows text like #tool.something.name
- A missing text. Please tell us which tool.
]] },

},
}
