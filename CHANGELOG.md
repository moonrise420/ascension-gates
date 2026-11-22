# Changelog

## 1.0.2
**New**
- Admin setting "Weapons against ships" (Stargate > Config > AGP Ships, `agp_weapon_balance`): Series power (default) ranks the weapons as in the series - Ori beam, Asgard beam and drones on top, hand weapons do 5 %. AGP sandbox keeps every weapon's own damage.
- In Series power a ship's shield pauses its recharge for 3 seconds after a hit from a ship weapon, so a shield under fire really falls.
- Admin setting "Weapons use energy": Never, When connected (default), Always.
- Admin setting "Weapons use the ship's power" (`agp_ship_power`, on by default): a weapon on a StarCore ship pays from the ship's ZPMs, generators and batteries, cabled or not, else from the ship's own power. The drone launcher too.
- 11 ship weapons for your own builds (Asgard beam, staff cannon, drone launcher, Ori beam, Destiny turrets, rail gun, ion cannon, Vanir and Wraith plasma cannons) never hit their own ship and fire out through its own shield.
- A SpaceGrid ship can fly through a Stargate; a StarCore ship docked in a carrier goes through with it.

**Replicators**
- They walk on a felt map of the ground by default (saved per map): smoother, no wobbling in corners, no sliding on their backs, and big swarms lag much less.
- They find their way by the real shape of the map: over curbs, window sills and low steps, onto roofs, out of water, out from under a roof.
- They eat a flying StarCore or SpaceGrid ship from inside until it breaks apart, without lag; the core counts as hull, resting bugs hold on to the deck, new ones made aboard stay inside.
- They walk straight through an open Stargate; colonists start a new swarm where they arrive and explore from there.
- They fall when the ground under them is gone, and glide up stairs and steps.
- The Queen walks stairs, steps over edges up to 26 high, hides from players, takes cover when seen and keeps watch at her nest.
- Bugs resting on a StarCore ship that breaks apart fall with the wreck instead of hanging in the air.

**Fixed**
- Walking through the Ha'tak's doorway (in and out) is seamless: no flash of sky, no dark frame. A glider's camera follows it through the launch slots.
- Drones, mini drones and missiles drain a shield when they hit it. A ship shield on a flying SpaceGrid ship counts as moving.
- A shield core stops the blast of staff pulses and rockets: it reached what the shield protects.
- Shields on a StarCore ship use the ship's energy; launcher drones fly through their own ship.
- A Ha'tak's volleys hit StarCore ships as a Ha'tak, not as a hand weapon.
- Charging cannons (staff cannon, Wraith and Vanir plasma, Asgard and Ori beam) paid their cost every tick - the staff cannon took as much as eleven Naquadah Generators. Now they pay per second.
- A ZPM hub on a SpaceGrid ship works: ZPMs sit in their slots and slide in and out with E, also in flight.
- One font for every entry of the tool list; the Config entries line up.
- Tel'tak and Ha'tak Staff Cannon are found by the spawn menu search; the Virgo gate's name is translated; small text fixes.

## 1.0.1
- Built ships (StarCore ships, welded props) ride the wormhole in one piece, and their pilots see the tunnel; every ship comes out wholly in front of the far gate
- Replicators: far less lag in big swarms, better paths through buildings, they plan around players' props and climb them, climb past a lip without flipping over, no more climbing up thin air
- Puddle Jumper fixes (pods, exit spot, windshield frame)
- Spawn icons for the two Goa'uld chairs; Ascension Gates, SpaceGrid and PowerGrid tabs side by side
- Clearer texts in all 12 languages

## 1.0.0
First release.

- Built on Carter's Addon Pack and CAP Enhanced, with bug fixes and many new parts
- Old saves and dupes keep working
- Walkable Ha'tak with decks, crystals, glider bay and hijacking; Replicators that build, eat metal and follow you through the gate
- All texts in 12 languages, an in-game help (agp_wiki)
- Energy and life support through PowerGrid
