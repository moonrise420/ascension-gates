-- Ascension Gates help (wiki), Nederlands. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Help",
    search = "Zoeken...",
    size = "Tekstgrootte",
    short = "KORT",
    intro = "Alles over Ascension Gates: wat de onderdelen doen en hoe je ze bestuurt.",
    open = "Help openen",
},
pages = {

{ id = "start", title = "Begin hier", icon = "icon16/star.png", body = [[
= Ascension Gates is een Stargate-pakket: gates, ringen, schepen, wapens, schilden en energie. Deze help legt elk onderdeel uit in korte stappen.
# Waar staat wat
- **Dingen spawnen:** druk op [Q], tabblad **Ascension Gates** (linksboven). De categorieën staan links.
- **Gereedschap:** [Q], rechterkant, tabblad **Ascension Gates** (gates, deuren, wapens, sleutels) en tabblad **PowerGrid** (energie, power, levensondersteuning).
- **Instellingen:** [Q] > Ascension Gates > Config. Scheepsinstellingen: **AGP-schepen**.
- **Power- en levensondersteuningsinstellingen:** [Q] > PowerGrid > Instellingen > **PowerGrid**.
- **Deze help:** consolecommando **agp_wiki**, of [Q] > Ascension Gates > Config > **Help (Wiki)**.
# Eerste stappen
1. Druk op [Q] en open het tabblad **Ascension Gates**.
2. Spawn twee Stargates en een DHD (categorie **Poorten en ringen**).
3. Kijk naar de DHD en druk op [E]. Kies de andere gate.
4. Loop erdoorheen.
> Houd de muis boven een instelling: een korte regel vertelt wat ze doet.
# De pagina's van deze help
- {page:gates|Stargates, DHD en ringen}
- {page:hatak|Ha'tak moederschip}
- {page:glider|Death Glider}
- {page:alkesh|Al'kesh en andere schepen}
- {page:spacegrid|PowerGrid: power en energie}
- {page:goauldpower|Goa'uld powerhub en kristallen}
- {page:lifesupport|Levensondersteuning en ruimte}
- {page:weapons|Handwapens}
- {page:keys|Toetsen veranderen}
- {page:admin|Instellingen voor admins}
- {page:problems|Problemen en oplossingen}
]] },

{ id = "gates", title = "Stargates, DHD en ringen", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Spawn een gate en een DHD, druk op E bij de DHD, kies een adres. Ringen brengen je tussen ringplatforms dichtbij.
# Zo krijg je ze
- [Q] > Ascension Gates > **Poorten en ringen**: gates, DHD's, ringen en ringpanelen.
- Gereedschap ([Q] > rechterkant > Ascension Gates > Tech): Mobiele DHD, Supergate-DHD, Iris, Goa'uld-iris.
# Kiezen met de DHD
1. Zet de DHD dicht bij de gate (dichterbij dan 1000 eenheden).
2. Kijk naar een glyph op de DHD en druk op [E]: ze licht op.
3. Druk alle glyphs van het adres in, dan de grote knop in het midden.
- Middenknop zonder ingedrukte glyphs: het kiesmenu opent.
- Middenknop terwijl de gate open is: de gate sluit.
# Kiezen met het gatemenu
1. Kijk naar de gate en druk op [E].
2. Typ het adres of kies het uit de lijst.
3. Klik op **Dial**. **Abort Dialling / Close Gate** stopt het.
- In hetzelfde menu stel je het adres, de groep en de naam van de gate in, en of ze privé is.
# Iris
- Gereedschap **Iris**: linksklik op een gate. Toets: [2] op het cijferblok schakelt hem om.
- **Iris Computer** (Poorten en ringen): houd hem tegen een gate met iris, [E] = menu (codes, automatisch sluiten).
- **GDO** (wapen): rechtsklik = je code typen, linksklik = naar een open gate sturen.
# Ringen
- Ringplatform + ringpaneel, dicht bij elkaar (het paneel werkt voor ringen binnen 500 eenheden).
- [E] op een paneelknop drukt hem in. **DIAL** zonder cijfers = naar de dichtstbijzijnde ringen. Met cijfers = naar dat ringadres.
- [E] op de ringbasis: geef hem een naam (adres).
- **Ring Caller** (wapen): linksklik roept de dichtstbijzijnde ringen, rechtsklik opent het kiesvenster.
! Ringen pletten je als je stilstaat waar ze neerkomen. Ga in het midden van het platform staan of stap ervan af.
]] },

{ id = "hatak", title = "Ha'tak moederschip", icon = "icon16/house.png", body = [[
= Een enorm Goa'uld moederschip. Je kunt erdoorheen lopen, ermee vliegen, ermee vechten en het van power voorzien. Binnen is het veel groter dan buiten.
# Spawnen
- [Q] > Ascension Gates > **Grotere moederschepen** > Ha'tak.
- Het verschijnt hoog boven de plek waar je op richt (of voor je als je op de lucht richt). Het zweeft.
# Instappen
- **Hangar:** de grote deur onderaan de piramide. [E] erop opent hem. Loop naar binnen: je staat meteen in de hangar.
- De hangardeur buiten en binnen is één deur: aan beide kanten open of dicht. Een deurbediening (gouden plaat) zit ernaast, binnen en buiten.
- **Ringen:** gebruik ringen buiten bij het schip, of een ringpaneel binnen.
- [E] op een deur of op de gouden bediening ernaast: de deur gaat open of dicht.
- Een open deur: kijk in de deuropening en druk op [E] om hem te sluiten.
> Binnen kun je altijd weg langs dezelfde weg als je kwam: de hangaropening werkt in beide richtingen.
# De dekken
1. **Hangardek:** hangar, ringruimte, kel'no'reem-ruimte, Jaffa-barakken, glider-bay.
2. **Pel'tak (brug):** troon, pilotenstoel, wapen-, navigatie- en commandoconsoles.
3. **Gate-ruimte:** Stargate met DHD.
4. **Commandodek:** verblijven met sarcofaag, wapenkamer, computerkern.
5. **Techniek:** motorruimte, cellen, schildruimte.
- Reizen tussen dekken: [E] op een ringpaneel > kies het dek.
# Wie mag het gebruiken
- De **bemanning** = de eigenaar en de vrienden (vrienden van de prop-bescherming).
- Vreemden kunnen het schip overnemen met het **controlekristal**. Zie {page:hatak_systems|Ha'tak-systemen}.
# Meer
- {page:hatak_fly|Vliegen, springen en wapens}
# Hoofdmenu (het hele schip in één venster)
- Open het: [1] op de troon, in de pilotenstoel of als schutter, of [E] op de commandoconsole in de pel'tak.
- **SHIP:** romp, power, schilden, wie vliegt. Hyperspace, wapens, techniek, adressen.
- **DOORS:** elke deur: openen, sluiten, vergrendelen. Alle deuren tegelijk open of dicht.
- **SYSTEMS:** schilden, cloak, alarm, lockdown, scheepslog, zelfvernietiging.
- {page:hatak_systems|Power, computer, schilden, schade en ruimtes}
]] },

{ id = "hatak_fly", title = "Ha'tak: vliegen, springen, vechten", icon = "icon16/arrow_up.png", body = [[
= Ga in de pilotenstoel in de pel'tak zitten. W/S/A/D om te vliegen, R voor hyperspace, V voor de camera. Wapens bij de wapenconsole.
# Neem het roer
1. Ga naar de pel'tak (brug).
2. Ga op de **troon** zitten ([E]) of in de pilotenstoel ([E] op de pilotenconsole).
3. Verlaat de stoel met [E].
- De troon gaat voor: als beide bezet zijn, vliegt de troon.
- [1] opent het **hoofdmenu** (ook als schutter).
- De voorkant van het schip is de hangarkant: [W] vliegt die kant op.
# Vliegtoetsen
- [W] vooruit, [S] achteruit.
- [A] / [D] draai links / rechts.
- [Space] omhoog, [Ctrl] omlaag.
- Houd [Shift] ingedrukt: 4x zo snel.
- [V]: camera. Begint achter en boven het schip (muiswiel = afstand). Daarna: de stoel, dan het uitzicht vanaf de voorste punt.
- Het raam in de pel'tak toont het echte uitzicht naar buiten.
- [R]: hyperspace-menu.
- Geen piloot: het schip vertraagt en stopt.
> Wie aan boord is, schuift niet rond terwijl het schip vliegt.
# Hyperspace-sprong
1. Druk op [R] in de pilotenstoel (of [E] op de navigatieconsole).
2. Kies een doel: opgeslagen merken, een Stargate of een andere speler. Of typ x y z.
3. Klik op **Jump**. Het schip laadt op (3 s), een venster opent, je vliegt erdoorheen.
- **Markering 1/2/3 hier** onthoudt de plek.
- Heeft 30 % hyperdrive-power nodig. 8 s pauze tussen sprongen.
# Wapens
- [E] op de **wapenconsole**: radar van bovenaf en een lijst met doelen.
- **OFF:** geen schoten. **DEFEND:** schiet alleen op wat het schip aanviel. **AUTO:** ook op NPC's en vreemden.
- **FIRE:** één salvo op het gekozen doel. **KEEP FIRING:** steeds opnieuw.
- **MANUAL (GUNNER)** of ga in de schutterstoel zitten: je richt zelf.
## Schuttertoetsen
- De muis richt, [Mouse1] vuren, houd [Mouse2] ingedrukt om te zoomen.
- [R] volgende kanonnengroep (boven, voor, zijkanten, achter, onder).
- [E] verlaten.
! Vuren zet je eigen cloak uit.
]] },

{ id = "hatak_systems", title = "Ha'tak-systemen en ruimtes", icon = "icon16/cog.png", body = [[
= Kristallen geven alles power. Trek er één eruit en een systeem wordt zwakker. De computerkern regelt ringen, deuren, sensoren en berichten.
# Motorruimte: powerkristallen
- De powerkern (hub) houdt 3 kristallen vast. Laden houden elk 3 kristallen: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] op een kristal: je trekt het eruit en draagt het.
- [E] bij een vrije plek: je zet het erin.
- Verbrande kristallen (donker) komen van harde klappen. Leg ze in het **reserverek**: ze laden in 60 s weer op.
- De twee naquadah-generatoren: [E] zet ze aan (+15 % elk).
- **Vierde hubarm:** nog een kristal (+15 %) of een **ZPM** (130 %). Breng de ZPM dichtbij met het gravity gun: hij klikt vast.
- **Techniekconsole:** toont alle power. Knoppen sturen meer power naar één systeem.
# Computerkern: datakristallen
- Blauwe kristallen in 4 rekken: **Rings**, **Doors**, **Sensors**, **Communication**. 2 van 3 moeten erin zitten, anders stopt die functie.
- **Zelfvernietiging:** 1, 2 of 4 minuten. **ABORT** stopt hem.
- **Scheepslogboek:** wat er aan boord gebeurde.
- **Adressen:** elke gate op de map. **DIAL** kiest vanuit de gate-ruimte.
- **Beveiliging:** alarm aan/uit, lockdown (alle deuren op slot, de bemanning kan ze nog openen).
# Schilden en cloak
- Console in de schildruimte of commandoconsole: **RAISE / LOWER SHIELDS**.
- **AUTO:** de schilden gaan vanzelf omhoog als iemand aanvalt.
- Het schild stopt elk wapen, ook dat van de eigenaar: schoten stoppen aan de gouden bel.
- **CLOAK:** het schip vervaagt. Heeft 30 % schild-power nodig. De schilden vallen weg tijdens de cloak.
# Levensondersteuning
- Lucht, warmte en zwaartekracht aan boord, ook in de ruimte.
- Ze heeft power van de kern nodig en een romp boven 10 %. Zonder is binnen als buiten (geen lucht in de ruimte).
- Hoofdmenu: status op SHIP, aan/uit op SYSTEMS.
# Schade
- Alleen zware klappen tellen. Zolang het schild standhoudt, vangt het de klappen op.
- Explosies **binnenin** doen twee keer zoveel pijn en verbranden kristallen dichtbij.
- Alarm bij 50, 25 en 10 % romp. Bij 0 ontploft het schip (admins kunnen dat uitzetten).
- Het **reparatiegereedschap** repareert de romp.
# Ruimtes
- **Glider-bay:** 4 Death Gliders. [E] = vliegen. Vlieg naar buiten door de lanceertunnel. Verloren gliders komen na 60 s terug.
- De lanceertunnels hebben deuren aan de binnen- en buitenkant. Ze gaan vanzelf open als je er met een glider op af vliegt. Open of sluit ze in het hoofdmenu.
- **Barakken:** [E] op de britsconsole = je respawnt aan boord. Pantserkist: [E] = +50 pantser (één keer per minuut).
- **Kel'no'reem:** hurk ([Ctrl]) op een mat = je geneest langzaam.
- **Sarcofaag:** [E] om erin te liggen en te genezen.
- **Wapens:** [E] op een staff weapon aan de muur: je pakt hem (na 2 minuten hangt er een nieuwe). [E] op een zat-kist: een zat.
- **Cellen:** [E] op het paneel naast een cel schakelt het krachtveld om (alleen bemanning).
# Het schip overnemen (kapen)
1. Zoek het **controlekristal** dat ergens binnen verstopt is. [E] pakt het op.
2. Ga naar de kristalsleuf in de pel'tak (rechtermuur). [E] start.
3. Blijf 40 s dichtbij. Het alarm gaat af.
4. Klaar: jij en je vrienden zijn de nieuwe bemanning.
- De oude bemanning kan het stoppen: [E] op de sleuf.
]] },

{ id = "glider", title = "Death Glider", icon = "icon16/bullet_go.png", body = [[
= Kleine Goa'uld-jager. W om te vliegen, muis om te sturen, Mouse1 om te schieten. Zonder ingedrukte toets zweeft hij.
# Zo krijg je hem
- [Q] > Ascension Gates > **Vloot: Schepen en jagers** > Death Glider. Of in de glider-bay van de Ha'tak.
# Toetsen
- [E] op de glider: instappen. [E] nog eens: uitstappen.
- [W] vooruit vliegen, [S] langzaam achteruit. Houd [Shift] ingedrukt: sneller.
- Muis: sturen.
- [1]: cockpitzicht aan / uit.
- Geen toets: hij blijft op zijn plek in de lucht.
- [Mouse1]: beide stafkanonnen afvuren.
- Muiswiel: rollen. [Mouse3]: terug rollen naar waterpas.
- Pijltjestoetsen: cameraafstand en -hoogte.
- [Backspace]: zelfvernietiging.
# Vrije vlucht (serverinstelling)
- Met **agp_glider_free_flight 1**: [S] achteruit, [A] / [D] opzij, [Space] omhoog, [Ctrl] omlaag.
# HUD
- Linksonder: romp, snelheid, stafkanonnen, de toetsen.
- 300 romp. Bij 0 ontploft hij.
> Toetsen veranderen: {page:keys|Toetsen veranderen}.
]] },

{ id = "alkesh", title = "Al'kesh en andere schepen", icon = "icon16/bullet_go.png", body = [[
= Bij elk schip: E om in en uit te stappen, W/A/S/D en muis om te vliegen, Mouse1 om te schieten.
# Al'kesh
- [Q] > Ascension Gates > **Vloot: Schepen en jagers**. Richt op de grond om hem te spawnen.
- [W] [S] [A] [D] vliegen. [Space] omhoog, [Ctrl] omlaag. Houd [Shift] ingedrukt: sneller.
- [Mouse1] vuren. Muiswiel rollen, [Mouse3] weer waterpas.
- [Enter]: landingsmodus (blijft waterpas).
- [E] uitstappen. [Backspace] zelfvernietiging.
# Grote schepen
- Aurora, Destiny, Gate Seeder, O'Neill, Ori Mothership, Prometheus, Replicator Mothership, Traveler, Wraith Cruiser.
- Dezelfde toetsen als de Al'kesh. Ook [Mouse2] doel volgen, [G] schild.
# Kleine schepen
- **Puddle Jumper:** [Mouse1] drones (opent de pods zelf), [Mouse2] ingedrukt houden = drones volgen je richtpunt, [Alt] cloak, [2] deur, [T] zweven, [G] schild, [R] dichtstbijzijnde poort kiezen.
- **Tel'tak:** [Mouse2] stafkanonnen, [G] schild, [Alt] cloak, houd [R] ingedrukt: hyperspace, [2] deur. Ringstraal: [Enter] (landingsmodus), dan [Mouse1].
- **F-302:** [Mouse1] kanonnen, [Mouse2] raketten, [Alt] afleidingsvuurwerk, [B] boost, [2] schietstoel.
- **Daedalus:** [Mouse1] railguns, [Mouse2] Asgard-straal, [1] tot [8] raketten.
- **Wraith Dart:** [C] mensen oppakken, [Alt] ze weer loslaten.
> Toetsen veranderen: {page:keys|Toetsen veranderen}.
]] },

{ id = "spacegrid", title = "PowerGrid: power en energie", icon = "icon16/lightning.png", body = [[
= PowerGrid is het gereedschapstabblad voor energie. Plaats powerdelen, koppel ze, voed ze met ZPM's of generatoren.
# Waar
- [Q] > rechterkant > tabblad **PowerGrid**.
- **PowerGrid:** het gereedschap PowerGrid-onderdelen (alle delen in één plaatjesraster).
- **Energie:** ZPM, ZPM-hubs, naquadah-generatoren, Goa'uld powerhub, PowerGrid-koppeling.
- **Instellingen:** PowerGrid-instellingen en deze help.
# Een deel plaatsen
1. Pak het gereedschap **PowerGrid-onderdelen**.
2. Klik rechts op een plaatje (bijvoorbeeld een energiecel).
3. Richt waar het moet staan. Je ziet er een schim van.
4. Linksklik [Mouse1]: geplaatst. Rechtsklik [Mouse2]: 90 graden gedraaid geplaatst.
- Richt op een deel en druk op [R]: dat deel is gekozen.
- Op een schip of prop wordt het vastgelast aan waar je op richt (vakje **Lassen aan waar je op richt**).
# De delen
- **Energiecellen (XS tot XL):** slaan energie op.
- **Zonnepanelen:** maken energie zolang er open lucht boven is.
- **Windturbine:** maakt energie, meer naarmate hij hoger staat.
- **Zwarte-gat-energie:** bevat elke grondstof (alleen admins, tenzij toegestaan).
- **Powerknooppunten:** koppelen alles wat erop geplaatst is. Hun display toont het netwerk.
- **Powerdisplays:** tonen het netwerk waaraan ze gekoppeld zijn.
- **Powerklep:** aan = energie stroomt tussen twee netwerken, uit = ze zijn gescheiden. [E] schakelt hem om.
- **Grondstoftanks:** bevatten één grondstof (zuurstof, water ...). [E] verandert de grondstof zolang hij leeg is.
- **Levensondersteuning:** zie {page:lifesupport|Levensondersteuning}.
# Koppelen (hoe delen energie delen)
- Admins kiezen de modus: **Manual**, **Automatic**, **Mix** of **Off** (PowerGrid-instellingen).
- **Manual:** gereedschap **PowerGrid-koppeling**: linksklik op de delen (ze worden blauw), rechtsklik op het deel of de powernode waaraan ze koppelen. [R] wist de selectie; [R] op een deel haalt zijn koppelingen weg.
- **Automatic:** delen die aan elkaar vastgelast zijn, delen vanzelf.
- **Off:** alles heeft vrije energie.
! Spacebuild geïnstalleerd? Dan wordt het netwerk van Spacebuild gebruikt. De powernodes van PowerGrid werken dan als Spacebuild-nodes: koppel met het gereedschap PowerGrid-koppeling. Admins kunnen **Altijd PowerGrid** aanzetten.
# Energiebronnen
- **ZPM:** gereedschap **ZPM MK III**. Zet hem in een ZPM-hub of een {page:goauldpower|Goa'uld powerhub}.
- **Naquadah-generator:** gereedschap onder Energy.
- **Goa'uld powerkristallen:** in de {page:goauldpower|Goa'uld powerhub}.
]] },

{ id = "goauldpower", title = "Goa'uld powerhub en kristallen", icon = "icon16/rainbow.png", body = [[
= Een koperen hub met een gouden powerkern. Zijn 4 armen nemen Goa'uld powerkristallen of ZPM's. De kern pulseert feller naarmate er meer power is.
# Zo krijg je hem
- Gereedschap: [Q] > PowerGrid > Energie > **Goa'uld Power Hub + Crystals**.
- Of spawn-tabblad: Ascension Gates > **PowerGrid**.
# Gebruiken
1. Linksklik [Mouse1] met het gereedschap: een hub.
2. Richt op een arm en rechtsklik [Mouse2]: een kristal zit op die arm.
3. ZPM: pak het ZPM-gereedschap, richt op een arm, linksklik: de ZPM zit op die arm.
4. Koppel de hub aan je netwerk zoals elk ander deel ({page:spacegrid|PowerGrid}).
- Houd een kristal of ZPM tegen een arm (gravity gun of physics gun): hij klikt vast.
- [E] op een kristal of ZPM: hij komt eruit.
- [E] op de hub: toont kristallen, ZPM's en energie in de chat.
- Kijk naar de hub: een klein plaatje toont kristallen en energie.
> Een ZPM geeft tien keer de power van een kristal en drijft de kern harder aan.
# Schuif in het gereedschap
- **Kristallading:** hoe vol nieuwe kristallen zijn (0 tot 100 %).
]] },

{ id = "lifesupport", title = "Levensondersteuning en ruimte", icon = "icon16/heart.png", body = [[
= In de ruimte is geen lucht en het is koud. Je pak beschermt je een tijdje. Levensondersteuning maakt een schip of gebied veilig.
# Wanneer staat ze aan?
- Admins kiezen: alleen ruimtemaps (standaard), elke map, of uit ({page:admin|Instellingen voor admins}).
# Je pak
- Drie waarden: **lucht**, **energie**, **koelvloeistof**. Vol als je spawnt.
- Geen lucht of onder water: de lucht gaat omlaag. Goede lucht: ze vult weer aan.
- Koud: de energie gaat omlaag. Heet: de koelvloeistof gaat omlaag.
- Een waarde op 0 doet je pijn.
- Een vakje linksonder verschijnt alleen als er iets mis is.
# Life Support Core
- Op een schip: het hele schip krijgt lucht. [E] schakelt hem om.
- Niet op een schip: een luchtbel. [E] verandert de grootte (300 tot 2000, dan uit).
- Heeft energie en zuurstof nodig (hij maakt zuurstof uit water).
# Je pak bijvullen
- **Suit Dispenser:** [E] vult lucht, energie en koelvloeistof bij uit zijn netwerk.
- **Air Compressor:** zuurstof uit ademlucht. **Water Pump:** water zolang hij in water staat.
# Gaterapport
- Als een gate kiest, krijg je een kort rapport: lucht, temperatuur, zwaartekracht aan de andere kant, en of je een pak nodig hebt.
]] },

{ id = "weapons", title = "Handwapens", icon = "icon16/bomb.png", body = [[
= Je vindt ze bij [Q] > Ascension Gates > Wapens. Mouse1 = hoofdgebruik, Mouse2 = tweede gebruik.
# Goa'uld
- **Zat'nik'tel:** 1e schot verdooft, 2e doodt, 3e laat het verdwijnen.
- **Stafwapen:** [Mouse2] klaarmaken, [Mouse1] vuren.
- **Handapparaat:** [Mouse1] gebruiken, [Mouse2] volgende modus.
- **Geneesapparaat:** houd op een speler om te genezen.
- **Mobile DHD:** zet het op een gate.
# Aarde (SGC)
- **P90 (PDW):** [Mouse1] vuren, [Mouse2] richten, [R] herladen.
- **Beretta:** [Mouse1] vuren, [R] herladen.
- **GDO:** [Mouse2] code typen, [Mouse1] sturen.
# Overige
- **Ori-handwapen en Ori-staf, Wraith-verdover, Ronons wapen, Asuraans wapen.**
- **Tac:** gooien, nog eens = laten ontploffen. [Mouse2] doden / verdoven / rook.
- **Reparatiegereedschap:** houd op een schip, gate of DHD om het te repareren.
- **Controlestoel (Ancient, spawn-tab Wapens):** [E] om te gaan zitten (heeft een opgeladen ZPM in zijn hub nodig). [1] = doellijst: vergrendel de drones op een doel, of richt vrij.
- **Persoonlijk schild, Sodan-camouflage:** [Mouse1] aan, [Mouse2] uit.
- **Mimetisch beeldapparaat:** houd [Mouse1] op een persoon vlak voor je om die af te beelden, [Mouse2] projectie aan / uit, [R] beeld wissen.
]] },

{ id = "keys", title = "Toetsen veranderen", icon = "icon16/keyboard.png", body = [[
= De scheepstoetsen kun je voor de meeste kleine schepen veranderen in het Keybinders-menu.
# Hoe
1. [Q] > rechterkant > Ascension Gates > **Keybinders**.
2. Kies het schip.
3. Klik één keer op een regel, daarna snel nog een keer (ze wordt oranje).
4. Druk op de nieuwe toets of muisknop. [Esc] annuleert.
- Schepen: Daedalus, Wraith Dart, Gate Glider, Death Glider, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- De Ha'tak gebruikt je gewone GMod-toetsen ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) en [V].
- Voor een eigen toets: koppel hem aan **agp_hatak_camera** (console: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Instellingen voor admins", icon = "icon16/shield.png", body = [[
= Admins (en jij in singleplayer) veranderen de serverinstellingen. Alle anderen zien ze alleen. Houd de muis boven een instelling voor een korte tip.
# Scheepsinstellingen: [Q] > Ascension Gates > Config > AGP-schepen
- **Kapen:** alleen bemanning / met het controlekristal / iedereen.
- **Wapens schieten op eigenaar en vrienden:** ja of nee.
- **Bereik wapens + radar:** hoe ver de kanonnen schieten en de radar ziet.
- **Radar: maximaal getoonde doelen.**
- **Energiekristallen die vreemden mogen uittrekken:** 0 tot 15 (standaard 2). De bemanning heeft geen limiet.
- **Schip kan vernietigd worden:** ja (standaard) of nee (de romp blijft op 1).
- **Rompsterkte (nieuwe schepen):** 10.000 tot 1.000.000 (standaard 100.000).
- **Camouflage toegestaan:** ja of nee.
- **Zweefhangar: verloren zwevers komen terug:** ja of nee, en na hoeveel seconden (standaard 60).
- **Schildbel (alle schepen):** alleen bij een treffer en bij het in- of uitschakelen (standaard), of altijd zichtbaar.
- **Zelfvernietiging: aftellen (alle schepen):** 1 tot 600 seconden (standaard 5).
# Power-instellingen: [Q] > PowerGrid > Instellingen > PowerGrid
- **Hoe onderdelen verbinden:** Handmatig / Automatisch / Mix / Uit. Zie {page:spacegrid|PowerGrid}.
- **Altijd PowerGrid:** PowerGrid gebruiken, ook met Spacebuild (vraagt een mapwissel).
- **Zwarte-gat-energie:** alleen admins of iedereen.
- **Ruimtesimulatie:** alleen ruimtemaps / elke map / uit. Zie {page:lifesupport|Levensondersteuning}.
- **Bestemmingsrapport van de gate:** aan of uit.
# Alleen voor jou (elke speler)
- Kabels, machinegeluiden, gaterapport op je scherm, eenheden voor afstand, temperatuur en zwaartekracht.
]] },

{ id = "problems", title = "Problemen en oplossingen", icon = "icon16/help.png", body = [[
= Werkt iets niet? Kijk eerst hier.
# Pictogrammen in het Q-menu worden roze en er spawnt niets
- Je houdt [Ctrl] ingedrukt (of de toets zit vast). [Ctrl] + klik **selecteert** pictogrammen (roze) in plaats van ze te spawnen.
- Oplossing: laat [Ctrl] los (druk er één keer op), klik op een lege plek in het pictogramgebied.
# Ik klik op een pictogram en er verschijnt niets
- Kijk naar de grond voor je, niet naar de verre lucht.
- Grote schepen verschijnen hoog boven de grond of voor je. Kijk om je heen.
- Admins kunnen delen uitzetten of beperken (Ascension Gates > Config > Over & credits > Instellingen).
# De glider valt
- De Death Glider houdt zijn hoogte als je geen toets indrukt. Valt hij? Dan is hij misschien vernietigd of buiten de map.
# Een Ha'tak-console zegt "crew only"
- Alleen de eigenaar en de vrienden mogen haar gebruiken. Of neem het schip over met het controlekristal ({page:hatak_systems|Ha'tak-systemen}).
# Een scheepssysteem zegt OFFLINE
- Check de kristallen in de motorruimte en de blauwe datakristallen in de computerkern.
# Ik zit vast in een doorgang of deur
- Doorgangen in scheepsinterieurs laten je niet door als de andere kant dicht is. Open eerst de deur.
- Nog steeds vast: noclip ([V]) of respawn.
# Een gereedschap toont tekst zoals #tool.something.name
- Er mist een tekst. Vertel me alsjeblieft welk gereedschap het is.
]] },

},
}
