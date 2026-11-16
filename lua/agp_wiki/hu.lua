-- Ascension Gates help (wiki), Magyar. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Súgó",
    search = "Keresés...",
    size = "Szövegméret",
    short = "RÖVIDEN",
    intro = "Minden az Ascension Gates-ről: mit csinálnak az elemek, és hogyan irányítod őket.",
    open = "Súgó megnyitása",
},
pages = {

{ id = "start", title = "Kezdd itt", icon = "icon16/star.png", body = [[
= Az Ascension Gates egy Stargate csomag: kapuk, gyűrűk, hajók, fegyverek, pajzsok és energia. Ez a súgó minden részt rövid lépésekben elmagyaráz.
# Hol találod
- **Tárgyak lerakása:** nyomd meg a [Q] gombot, fül: **Ascension Gates** (bal felül). A kategóriák balra vannak.
- **Eszközök:** [Q], jobb oldal, fül: **Ascension Gates** (kapuk, ajtók, fegyverek, billentyűk) és fül: **PowerGrid** (energia, áram, életfenntartás).
- **Beállítások:** [Q] > Ascension Gates > Config. Hajó beállítások: **AGP hajók**.
- **Energia és életfenntartás beállítások:** [Q] > PowerGrid > Beállítások > **PowerGrid**.
- **Ez a súgó:** konzolparancs **agp_wiki**, vagy [Q] > Ascension Gates > Config > **Súgó (Wiki)**.
# Első lépések
1. Nyomd meg a [Q] gombot, és nyisd meg az **Ascension Gates** fület.
2. Rakj le két Stargate-et és egy DHD-t (kategória: **Kapuk és Gyűrűk**).
3. Nézz a DHD-ra, és nyomd meg az [E] gombot. Tárcsázd a másik kaput.
4. Sétálj át.
> Vidd az egeret egy beállítás fölé: egy rövid sor megmondja, mit csinál.
# A súgó oldalai
- {page:gates|Stargate, DHD és gyűrűk}
- {page:hatak|Ha'tak anyahajó}
- {page:glider|Halálsikló}
- {page:alkesh|Al'kesh és más hajók}
- {page:spacegrid|PowerGrid: áram és energia}
- {page:goauldpower|Goa'uld energiacsomópont és kristályok}
- {page:lifesupport|Életfenntartás és világűr}
- {page:weapons|Kézi fegyverek}
- {page:keys|Billentyűk átállítása}
- {page:admin|Beállítások adminoknak}
- {page:problems|Hibák és megoldások}
]] },

{ id = "gates", title = "Stargate, DHD és gyűrűk", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Rakj le egy kaput és egy DHD-t, nyomj E-t a DHD-n, tárcsázz. A gyűrűk a közeli gyűrűplatformok között visznek.
# Honnan szerzed
- [Q] > Ascension Gates > **Kapuk és Gyűrűk**: kapuk, DHD-k, gyűrűk és gyűrűpanelek.
- Eszközök ([Q] > jobb oldal > Ascension Gates > Tech): Mobil tárcsázó, Szuperkapu tárcsázó, Iris, Goa'uld Iris.
# Tárcsázás a DHD-vel
1. Tedd a DHD-t a kapu közelébe (1000-nél közelebb).
2. Nézz egy jelre a DHD-n, és nyomd meg az [E] gombot: kigyullad.
3. Nyomd meg a cím összes jelét, utána a nagy középső gombot.
- Középső gomb, ha egy jel sincs megnyomva: megnyílik a tárcsázó menü.
- Középső gomb, amíg a kapu nyitva van: a kapu bezárul.
# Tárcsázás a kapu menüjével
1. Nézz a kapura, és nyomd meg az [E] gombot.
2. Írd be a címet, vagy válaszd ki a listából.
3. Kattints a **Dial** gombra. **Abort Dialling / Close Gate** leállítja.
- Ugyanebben a menüben beállítod a kapu saját címét, csoportját és nevét, és hogy privát-e.
# Iris
- Eszköz **Iris**: bal kattintás egy kapura. Billentyű: numpad [2] ki-be kapcsolja.
- **Iris Computer** (Kapuk és Gyűrűk): érintsd egy irises kapuhoz, [E] = menü (kódok, automatikus zárás).
- **GDO** (fegyver): jobb kattintás = írd be a kódod, bal kattintás = küldd el egy nyitott kapunak.
# Gyűrűk
- Gyűrűplatform + gyűrűpanel, közel egymáshoz (a panel 500-on belüli gyűrűkhöz működik).
- [E] egy panelgombon megnyomja azt. **DIAL** számjegyek nélkül = a legközelebbi gyűrűkhöz. Számjegyekkel = ahhoz a gyűrűcímhez.
- [E] a gyűrűtalpon: adj neki nevet (címet).
- **Ring Caller** (fegyver): bal kattintás hívja a legközelebbi gyűrűket, jobb kattintás megnyitja a tárcsázó ablakot.
! A gyűrűk összezúznak, ha mozdulatlanul állsz ott, ahol leereszkednek. Lépj a platformra, vagy menj el onnan.
]] },

{ id = "hatak", title = "Ha'tak anyahajó", icon = "icon16/house.png", body = [[
= Egy hatalmas Goa'uld anyahajó. Átsétálhatsz rajta, repülhetsz vele, harcolhatsz vele, és tölthetsz neki energiát. A belseje sokkal nagyobb, mint a külseje.
# Lerakás
- [Q] > Ascension Gates > **Nagyobb anyahajók** > Ha'tak.
- Magasan a célzott hely fölött jelenik meg (vagy előtted, ha az égre célzol). Lebeg.
# Beszállás
- **Hangár:** a nagy ajtó a piramis alján. [E] rajta kinyitja. Sétálj be: egyenesen a belső hangárban vagy.
- A hangár ajtaja kívül és belül egy ajtó: mindkét oldalon nyitva vagy zárva. Ajtókapcsoló (arany lap) van mellette kívül és belül.
- **Gyűrűk:** használj gyűrűket a hajó közelében kint, vagy egy gyűrűpanelt bent.
- [E] egy ajtón vagy a mellette lévő arany vezérlőn: az ajtó kinyílik vagy bezárul.
- Nyitott ajtó: nézz az ajtónyílásba, és nyomd meg az [E] gombot a bezáráshoz.
> Bent mindig kimehetsz ott, ahol bejöttél: a hangárnyílás mindkét irányba működik.
# A szintek
1. **Hangár szint:** hangár, gyűrűszoba, kel'no'reem szoba, Jaffa laktanya, siklóhangár.
2. **Pel'tak (híd):** trón, pilótaszék, fegyverek, navigációs és parancsnoki konzolok.
3. **Kapuszoba:** Stargate DHD-vel.
4. **Parancsnoki szint:** lakosztályok szarkofággal, fegyvertár, számítógépmag.
5. **Gépház:** gépterem, fogdák, pajzsterem.
- Szintek közti utazás: [E] egy gyűrűpanelen > válaszd ki a szintet.
# Ki használhatja
- A **legénység** = a tulajdonos és a barátai (prop protection barátok).
- Idegenek a **vezérlőkristállyal** átvehetik a hajót. Lásd {page:hatak_systems|Ha'tak rendszerek}.
# Továbbiak
- {page:hatak_fly|Repülés, ugrás és fegyverek}
# Főmenü (az egész hajó egy ablakban)
- Nyisd meg: [1] a trónon, a pilótaülésben vagy lövészként, vagy [E] a pel'tak parancskonzolján.
- **SHIP:** törzs, energia, pajzsok, ki repül. Hiperűr, fegyverek, gépház, címek.
- **DOORS:** minden ajtó: nyitás, zárás, zárolás. Az összes ajtó egyszerre nyitva vagy zárva.
- **SYSTEMS:** pajzsok, álcázás, riasztás, zárlat, hajónapló, önmegsemmisítés.
- {page:hatak_systems|Energia, számítógép, pajzsok, sérülés és szobák}
]] },

{ id = "hatak_fly", title = "Ha'tak: repülés, ugrás, harc", icon = "icon16/arrow_up.png", body = [[
= Ülj a pilótaszékbe a pel'takon. W/S/A/D repülés, R hiperűr, V kamera. A fegyverek a fegyverkonzolnál vannak.
# Vedd át a kormányt
1. Menj a pel'takra (hídra).
2. Ülj a **trónra** ([E]) vagy a pilótaszékbe ([E] a pilótakonzolon).
3. Az ülésből az [E] gombbal szállsz ki.
- A trón az első: ha mindkettő foglalt, a trón repül.
- [1] megnyitja a **főmenüt** (lövész módban is).
- A hajó eleje a hangár oldala: [W] arra repül.
# Repülés billentyűi
- [W] előre, [S] hátra.
- [A] / [D] balra / jobbra fordul.
- [Space] fel, [Ctrl] le.
- Tartsd nyomva a [Shift] gombot: 4x gyorsabb.
- [V]: kamera. A hajó mögött és fölött indul (egérgörgő = távolság). Utána: az ülés, majd a nézet az orr hegyéről.
- Az ablak a pel'takon a valódi kinti nézetet mutatja.
- [R]: hiperűr menü.
- Nincs pilóta: a hajó lassul és megáll.
> Aki nincs a hajón, csúszkál, amíg a hajó repül.
# Hiperűr ugrás
1. Nyomd meg az [R] gombot a pilótaülésben (vagy [E] a navigációs konzolon).
2. Válassz célt: mentett jelölők, egy Stargate vagy egy másik játékos. Vagy írd be: x y z.
3. Kattints a **Jump** gombra. A hajó tölt (3 mp), megnyílik egy ablak, átrepülsz rajta.
- **Save mark 1/2/3 here** megjegyzi a helyet.
- 30 % hiperhajtómű energia kell. 8 mp szünet két ugrás között.
# Fegyverek
- [E] a **fegyverkonzolon**: radar felülről és a célpontok listája.
- **OFF:** nincs lövés. **DEFEND:** csak arra lő, ami megtámadta a hajót. **AUTO:** NPC-kre és idegenekre is.
- **FIRE:** egy sorozat a kiválasztott célpontra. **KEEP FIRING:** újra és újra.
- **MANUAL (GUNNER)** vagy ülj a lövészszékbe: te célzol.
## Lövész billentyűk
- Az egér céloz, [Mouse1] tűz, tartsd a [Mouse2] gombot: nagyítás.
- [R] következő ágyúcsoport (felső, első, oldalsó, hátsó, alsó).
- [E] kiszállás.
! A lövés leveszi a saját álcázásodat.
]] },

{ id = "hatak_systems", title = "Ha'tak rendszerek és szobák", icon = "icon16/cog.png", body = [[
= A kristályok adnak mindent. Húzz ki egyet, és egy rendszer gyengébb lesz. A számítógépmag vezérli a gyűrűket, ajtókat, szenzorokat és üzeneteket.
# Gépterem: energiakristályok
- Az energiamag (csomópont) 3 kristályt tart. A tálcák 3-3 kristályt tartanak: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] egy kristályon: kihúzod és viszed.
- [E] egy üres foglalatnál: beteszed.
- Az elégett (sötét) kristályok erős találatoktól lesznek. Tedd őket a **tartalék állványra**: 60 mp alatt újratöltődnek.
- A két naquadah generátor: [E] bekapcsolja őket (+15 % mindegyik).
- **Negyedik csomópontkar:** még egy kristály (+15 %) vagy egy **ZPM** (130 %). Vidd a ZPM-et közel a gravitációs fegyverrel: rápattan.
- **Gépészeti konzol:** megmutatja az összes energiát. A gombok több energiát küldenek egy rendszernek.
# Számítógépmag: adatkristályok
- Kék kristályok 4 állványon: **Rings**, **Doors**, **Sensors**, **Communication**. A 3-ból 2 kell, különben az a funkció leáll.
- **Önmegsemmisítés:** 1, 2 vagy 4 perc. **ABORT** leállítja.
- **Hajónapló:** mi történt a fedélzeten.
- **Címek:** a térkép minden kapuja. **DIAL** a kapuszobából tárcsáz.
- **Biztonság:** riasztás be/ki, zárlat (minden ajtó zárva, a legénység még kinyithatja).
# Pajzsok és álcázás
- Pajzsterem konzol vagy parancsnoki konzol: **RAISE / LOWER SHIELDS**.
- **AUTO:** a pajzsok maguktól felmennek, ha valaki támad.
- A pajzs minden fegyvert megállít, a tulajdonosét is: a lövések az arany buboréknál megállnak.
- **CLOAK:** a hajó eltűnik. 30 % pajzsenergia kell. Álcázás közben a pajzsok leesnek.
# Életfenntartás
- Levegő, hő és gravitáció a fedélzeten, a világűrben is.
- Energia kell hozzá a magból, és 10 % feletti törzs. Nélküle bent olyan, mint kint (a világűrben nincs levegő).
- Főmenü: állapot a SHIP oldalon, be/ki a SYSTEMS oldalon.
# Sérülés
- Csak az erős találatok számítanak. Amíg a pajzs bírja, az fogja fel a találatokat.
- A **belső** robbanások kétszer annyira fájnak, és megégetik a közeli kristályokat.
- Riasztás 50, 25 és 10 % törzsnél. 0-nál a hajó felrobban (az adminok ezt kikapcsolhatják).
- A **javítóeszköz** javítja a törzset.
# Szobák
- **Siklóhangár:** 4 Halálsikló. [E] = repülés. Repülj ki az indítóalagúton. Az elveszett siklók 60 mp után visszajönnek.
- Az indítóalagutaknak belül és kívül is van ajtajuk. Maguktól kinyílnak, ha siklóval repülsz feléjük. Nyisd ki vagy zárd be őket a főmenüben.
- **Laktanya:** [E] az ágykonzolon = a hajón éledsz újra. Páncélláda: [E] = +50 páncél (percenként egyszer).
- **Kel'no'reem:** guggolj ([Ctrl]) egy szőnyegen = lassan gyógyulsz.
- **Szarkofág:** [E] a belefekvéshez és gyógyuláshoz.
- **Fegyverek:** [E] egy botfegyveren a falon: elveszed (2 perc múlva új van ott). [E] egy zat ládán: egy zat.
- **Fogdák:** [E] a cella melletti panelen kapcsolja az erőterét (csak legénység).
# A hajó átvétele (eltérítés)
1. Keresd meg a bent elrejtett **vezérlőkristályt**. [E] felveszi.
2. Menj a kristályfoglalathoz a pel'takon (jobb fal). [E] elindítja.
3. Maradj közel 40 mp-ig. Megszólal a riasztás.
4. Kész: te és a barátaid vagytok az új legénység.
- A régi legénység megállíthatja: [E] a foglalaton.
]] },

{ id = "glider", title = "Halálsikló", icon = "icon16/bullet_go.png", body = [[
= Kis Goa'uld vadász. W repülés, egér kormányzás, Mouse1 lövés. Ha nem nyomsz gombot, lebeg.
# Honnan szerzed
- [Q] > Ascension Gates > **Flotta: Hajók és vadászok** > Death Glider. Vagy a Ha'tak siklóhangárjában.
# Billentyűk
- [E] a siklón: beszállsz. [E] újra: kiszállsz.
- [W] repülés előre, [S] lassan hátra. Tartsd nyomva a [Shift] gombot: gyorsabb.
- Egér: kormányzás.
- [1]: pilótafülke-nézet be / ki.
- Nincs gomb: a helyén marad a levegőben.
- [Mouse1]: mindkét botágyú tüzel.
- Egérgörgő: dőlés. [Mouse3]: vissza vízszintesbe.
- Nyílbillentyűk: kamera távolsága és magassága.
- [Backspace]: önmegsemmisítés.
# Szabad repülés (szerverbeállítás)
- **agp_glider_free_flight 1** esetén: [S] hátra, [A] / [D] oldalra, [Space] fel, [Ctrl] le.
# HUD
- Bal alul: törzs, sebesség, botágyúk, a billentyűk.
- 300 törzs. 0-nál felrobban.
> A billentyűk átállítása: {page:keys|Billentyűk átállítása}.
]] },

{ id = "alkesh", title = "Al'kesh és más hajók", icon = "icon16/bullet_go.png", body = [[
= Minden hajón: E a be- és kiszálláshoz, W/A/S/D és egér a repüléshez, Mouse1 a lövéshez.
# Al'kesh
- [Q] > Ascension Gates > **Flotta: Hajók és vadászok**. Célozz a földre a lerakásához.
- [W] [S] [A] [D] repülés. [Space] fel, [Ctrl] le. Tartsd nyomva a [Shift] gombot: gyorsabb.
- [Mouse1] tűz. Egérgörgő dőlés, [Mouse3] újra vízszintes.
- [Enter]: leszállómód (vízszintes marad).
- [E] kiszállás. [Backspace] önmegsemmisítés.
# Nagy hadihajók
- Aurora, Destiny, Gate Seeder, O'Neill, Ori anyahajó, Prometheus, Replikátor anyahajó, Traveler, Wraith cirkáló.
- Ugyanazok a billentyűk, mint az Al'keshen. Továbbá [Mouse2] célkövetés, [G] pajzs.
# Kis hajók
- **Puddle Jumper:** [Mouse1] drónok (a tartók maguktól kinyílnak), [Mouse2] tartva = a drónok követik a célzásod, [Alt] álcázás, [2] ajtó, [T] lebegés, [G] pajzs, [R] a legközelebbi kapu tárcsázása.
- **Tel'tak:** [Mouse2] botágyúk, [G] pajzs, [Alt] álcázás, tartsd a [R] gombot: hiperűr, [2] ajtó. Gyűrűsugár: [Enter] (leszállás mód), utána [Mouse1].
- **F-302:** [Mouse1] gépágyúk, [Mouse2] rakéták, [Alt] csalik, [B] gyorsítás, [2] katapult.
- **Daedalus:** [Mouse1] sínágyúk, [Mouse2] Asgard sugár, [1] - [8] rakéták.
- **Wraith Dart:** [C] embereket gyűjt, [Alt] kiteszi őket.
> A billentyűk átállítása: {page:keys|Billentyűk átállítása}.
]] },

{ id = "spacegrid", title = "PowerGrid: áram és energia", icon = "icon16/lightning.png", body = [[
= A PowerGrid az energia eszközfüle. Rakd le az energiaelemeket, kösd össze őket, tápláld ZPM-ekkel vagy generátorokkal.
# Hol van
- [Q] > jobb oldal > fül: **PowerGrid**.
- **PowerGrid:** a PowerGrid alkatrészek eszköz (minden elem egy képrácsban).
- **Energia:** ZPM, ZPM csomópontok, naquadah generátorok, Goa'uld energiacsomópont, PowerGrid összekötő.
- **Beállítások:** PowerGrid beállítások és ez a súgó.
# Elem lerakása
1. Vedd elő az **PowerGrid alkatrészek** eszközt.
2. Kattints egy képre jobbra (például egy energiacella).
3. Célozd meg, hol álljon. Látsz egy szellemképet róla.
4. Bal kattintás [Mouse1]: lerakva. Jobb kattintás [Mouse2]: 90 fokkal elforgatva rakja le.
- Célozz egy elemre, és nyomd meg az [R] gombot: az az elem lesz kiválasztva.
- Hajón vagy propon ahhoz hegeszti, amire célzol (négyzet: **Weld to what I aim at**).
# Az elemek
- **Energiacellák (XS - XL):** energiát tárolnak.
- **Napelemek:** energiát termelnek, amíg nyílt ég van fölöttük.
- **Szélturbina:** energiát termel, annál többet, minél magasabban áll.
- **Fekete lyuk energia:** minden erőforrást tárol (csak adminoknak, hacsak nem engedik).
- **Energiacsomópontok:** összekötnek mindent, ami rajtuk áll. A kijelzőjük a hálózatot mutatja.
- **Energiakijelzők:** a hálózatot mutatják, amelyhez kötve vannak.
- **Energiaszelep:** be = az energia két hálózat között folyik, ki = külön vannak. [E] kapcsolja.
- **Erőforrás tartályok:** egy erőforrást tárolnak (oxigén, víz ...). [E] cseréli az erőforrást, amíg üres.
- **Életfenntartás:** lásd {page:lifesupport|Életfenntartás}.
# Összekötés (hogyan osztják meg az elemek az energiát)
- Az adminok választják a módot: **Manual**, **Automatic**, **Mix** vagy **Off** (PowerGrid beállítások).
- **Manual:** **PowerGrid összekötő** eszköz: bal kattintás az elemeken (kékek lesznek), jobb kattintás arra az elemre vagy energiacsomópontra, amelyhez kötöd őket. [R] törli a kijelölést; [R] egy elemen törli a kötéseit.
- **Automatic:** az összehegesztett elemek maguktól megosztják.
- **Off:** mindennek van szabad energiája.
! Spacebuild telepítve? Akkor a Spacebuild hálózata fut. A mi energiacsomópontjaink ilyenkor Spacebuild csomópontok: kösd össze a PowerGrid összekötő eszközzel. Az adminok bekapcsolhatják az **Mindig PowerGrid** opciót.
# Energiaforrások
- **ZPM:** eszköz **ZPM MK III**. Tedd egy ZPM csomópontba vagy egy {page:goauldpower|Goa'uld energiacsomópontba}.
- **Naquadah generátor:** eszköz az Energy alatt.
- **Goa'uld energiakristályok:** a {page:goauldpower|Goa'uld energiacsomópontban}.
]] },

{ id = "goauldpower", title = "Goa'uld energiacsomópont és kristályok", icon = "icon16/rainbow.png", body = [[
= Egy sárgaréz csomópont arany energiamaggal. A 4 karja Goa'uld energiakristályokat vagy ZPM-eket fogad. A mag annál fényesebben lüktet, minél több energiája van.
# Honnan szerzed
- Eszköz: [Q] > PowerGrid > Energia > **Goa'uld Power Hub + Crystals**.
- Vagy a lerakó fül: Ascension Gates > **PowerGrid**.
# Használat
1. Bal kattintás [Mouse1] az eszközzel: egy csomópont.
2. Célozz egy karra, és jobb kattintás [Mouse2]: egy kristály kerül arra a karra.
3. ZPM: vedd elő a ZPM eszközt, célozz egy karra, bal kattintás: a ZPM arra a karra kerül.
4. Kösd a csomópontot a hálózatodhoz, mint bármely más elemet ({page:spacegrid|PowerGrid}).
- Érints egy kristályt vagy ZPM-et egy karhoz (gravitációs fegyverrel vagy physics gun-nal): rápattan.
- [E] egy kristályon vagy ZPM-en: kijön.
- [E] a csomópontón: kiírja a kristályokat, ZPM-eket és az energiát a chatbe.
- Nézz a csomópontra: egy kis tábla mutatja a kristályokat és az energiát.
> Egy ZPM tízszer annyi energiát ad, mint egy kristály, és jobban hajtja a magot.
# Csúszka az eszközben
- **Crystal charge:** mennyire teltek az új kristályok (0 - 100 %).
]] },

{ id = "lifesupport", title = "Életfenntartás és világűr", icon = "icon16/heart.png", body = [[
= A világűrben nincs levegő, és hideg van. A ruhád egy ideig véd. Az életfenntartás biztonságossá tesz egy hajót vagy területet.
# Mikor van bekapcsolva?
- Az adminok választják: csak űrtérképeken (alapértelmezett), minden térképen, vagy ki ({page:admin|Beállítások adminoknak}).
# A ruhád
- Három érték: **levegő**, **energia**, **hűtőfolyadék**. Újraéledéskor tele vannak.
- Nincs levegő vagy víz alatt vagy: a levegő csökken. Jó levegő: újra megtelik.
- Hideg: az energia csökken. Meleg: a hűtőfolyadék csökken.
- Ha egy érték 0, sebez.
- Bal alul egy doboz csak akkor jelenik meg, ha valami baj van.
# Life Support Core
- Hajón: az egész hajó levegőt kap. [E] kapcsolja.
- Nem hajón: egy levegőbuborék. [E] változtatja a méretét (300 - 2000, aztán ki).
- Energia és oxigén kell hozzá (vízből csinál oxigént).
# Ruha feltöltése
- **Suit Dispenser:** [E] feltölti a levegőt, energiát és hűtőfolyadékot a hálózatából.
- **Air Compressor:** oxigén a belélegezhető levegőből. **Water Pump:** víz, amíg vízben áll.
# Kapu jelentés
- Amikor egy kapu tárcsáz, rövid jelentést kapsz: levegő, hőmérséklet, gravitáció a másik oldalon, és hogy kell-e ruha.
]] },

{ id = "weapons", title = "Kézi fegyverek", icon = "icon16/bomb.png", body = [[
= Itt szerzed meg őket: [Q] > Ascension Gates > Fegyverek. Mouse1 = fő használat, Mouse2 = második használat.
# Goa'uld
- **Zat'nik'tel:** 1. lövés elkábít, 2. megöl, 3. eltünteti.
- **Botfegyver:** [Mouse2] felkészít, [Mouse1] tűz.
- **Kézi eszköz:** [Mouse1] használat, [Mouse2] következő mód.
- **Gyógyító eszköz:** tartsd egy játékosra, hogy gyógyítsd.
- **Mobil DHD:** tedd egy kapura.
# Föld (SGC)
- **P90 (PDW):** [Mouse1] tűz, [Mouse2] célzás, [R] újratöltés.
- **Beretta:** [Mouse1] tűz, [R] újratöltés.
- **GDO:** [Mouse2] kód beírása, [Mouse1] küldés.
# Mások
- **Ori kézi fegyver / bot, Wraith blaster, Ronon fegyvere, Asuran fegyver.**
- **Tac:** dobd el, újra = felrobban. [Mouse2] öl / kábít / füst.
- **Javítóeszköz:** tartsd egy hajóra, kapura vagy DHD-re, hogy megjavítsd.
- **Vezérlőszék (Ősi, Fegyverek fül):** [E] a leüléshez (egy feltöltött ZPM kell a hubjában). [1] = célpontlista: zárold a drónokat egy célpontra, vagy célozz szabadon.
- **Személyi pajzs, Sodan köpeny:** [Mouse1] be, [Mouse2] ki.
- **Mimetikus képalkotó eszköz:** tartsd a [Mouse1]-et egy közvetlenül előtted álló személyen a leképezéshez, [Mouse2] kivetítés be / ki, [R] kép törlése.
]] },

{ id = "keys", title = "Billentyűk átállítása", icon = "icon16/keyboard.png", body = [[
= A legtöbb kis hajó billentyűit át tudod állítani a Keybinders menüben.
# Hogyan
1. [Q] > jobb oldal > Ascension Gates > **Keybinders**.
2. Válaszd ki a hajót.
3. Kattints egyszer egy sorra, majd gyorsan még egyszer (narancssárga lesz).
4. Nyomd meg az új billentyűt vagy egérgombot. [Esc] megszakítja.
- Hajók: Daedalus, Wraith Dart, Gate Glider, Halálsikló, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- A Ha'tak a normál GMod billentyűidet használja ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) és a [V] gombot.
- Saját billentyűhöz: kösd az **agp_hatak_camera** parancshoz (konzol: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Beállítások adminoknak", icon = "icon16/shield.png", body = [[
= Az adminok (és te egyjátékos módban) változtatják a szerver beállításait. Mindenki más csak látja őket. Vidd az egeret egy beállítás fölé egy rövid tippért.
# Hajó beállítások: [Q] > Ascension Gates > Config > AGP hajók
- **Hijacking:** csak a legénység / a vezérlőkristállyal / bárki.
- **Weapons fire at owner and friends:** igen vagy nem.
- **Weapon + radar range:** milyen messze lőnek az ágyúk és lát a radar.
- **Radar: most targets shown.**
- **Power crystals strangers may pull:** 0 - 15 (alapértelmezett 2). A legénységnek nincs korlátja.
- **Ship can be destroyed:** igen (alapértelmezett) vagy nem (a törzs 1-en marad).
- **Hull health (new ships):** 10 000 - 1 000 000 (alapértelmezett 100 000).
- **Cloak allowed:** igen vagy nem.
- **Glider bay: lost gliders come back:** igen vagy nem, és hány másodperc után (alapértelmezett 60).
- **Shield bubble (all ships):** csak találatkor és be- vagy kikapcsoláskor (alapértelmezett), vagy mindig látható.
- **Self-destruct countdown (all ships):** 1 és 600 másodperc között (alapértelmezett 5).
# Energia beállítások: [Q] > PowerGrid > Beállítások > PowerGrid
- **How parts connect:** Manual / Automatic / Mix / Off. Lásd {page:spacegrid|PowerGrid}.
- **Mindig PowerGrid:** a PowerGrid használata Spacebuild mellett is (térképváltás kell).
- **Fekete lyuk energia:** csak adminok vagy mindenki.
- **Space simulation:** csak űrtérképek / minden térkép / ki. Lásd {page:lifesupport|Életfenntartás}.
- **Gate destination report:** be vagy ki.
# Csak neked (minden játékos)
- Kábelek, gépek hangjai, kapu jelentés a képernyődön, mértékegységek a távolsághoz, hőmérséklethez és gravitációhoz.
]] },

{ id = "problems", title = "Hibák és megoldások", icon = "icon16/help.png", body = [[
= Valami nem működik? Először itt nézd meg.
# A Q menü ikonjai rózsaszínek lesznek, és semmi sem jelenik meg
- Nyomva tartod a [Ctrl] gombot (vagy beragadt). [Ctrl] + kattintás **kijelöli** az ikonokat (rózsaszín) a lerakás helyett.
- Megoldás: engedd el a [Ctrl] gombot (nyomd meg egyszer), kattints egy üres helyre az ikonok területén.
# Rákattintok egy ikonra, és semmi sem jelenik meg
- A talajra nézz előtted, ne a távoli égre.
- A nagy hajók magasan a talaj fölött vagy előtted jelennek meg. Nézz körül.
- Az adminok kikapcsolhatnak vagy korlátozhatnak elemeket (Ascension Gates > Config > Névjegy és köszönet > Beállítások).
# A sikló leesik
- A Halálsikló tartja a magasságát, ha nem nyomsz gombot. Esik? Lehet, hogy megsemmisült, vagy kiesett a térképről.
# Egy Ha'tak konzol azt írja: "crew only"
- Csak a tulajdonos és a barátai használhatják. Vagy vedd át a hajót a vezérlőkristállyal ({page:hatak_systems|Ha'tak rendszerek}).
# Egy hajórendszer azt mondja: OFFLINE
- Nézd meg a kristályokat a gépteremben és a kék adatkristályokat a számítógépmagban.
# Beragadtam egy ajtónyílásba vagy ajtóba
- A hajóbelsők ajtónyílásai nem engednek át, ha a másik oldal zárva van. Előbb nyisd ki az ajtót.
- Még mindig beragadtál: noclip ([V]) vagy éledj újra.
# Egy eszköz ilyen szöveget mutat: #tool.something.name
- Hiányzó szöveg. Kérjük, told meg nekünk, melyik eszköz.
]] },

},
}
