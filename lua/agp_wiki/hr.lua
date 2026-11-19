-- Ascension Gates help (wiki), Hrvatski. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Pomoć",
    search = "Traži...",
    size = "Veličina teksta",
    short = "UKRATKO",
    intro = "Sve o Ascension Gates: što dijelovi rade i kako ih upravljaš.",
    open = "Otvori pomoć",
},
pages = {

{ id = "start", title = "Počni ovdje", icon = "icon16/star.png", body = [[
= Ascension Gates je paket Stargatea: vrata, prstenje, brodovi, oružje, štitovi i energija. Ova pomoć objašnjava svaki dio u kratkim koracima.
# Gdje je što
- **Stvori stvari:** pritisni [Q], kartica **Ascension Gates** (gore lijevo). Kategorije su lijevo.
- **Alati:** [Q], desno, kartica **Ascension Gates** (vrata, vrata prostorija, oružje, ključevi) i kartica **PowerGrid** (energija, napajanje, održavanje života).
- **Postavke:** [Q] > Ascension Gates > Config. Postavke brodova: **AGP brodovi**.
- **Postavke energije i održavanja života:** [Q] > PowerGrid > Postavke > **PowerGrid**.
- **Ova pomoć:** naredba u konzoli **agp_wiki**, ili [Q] > Ascension Gates > Config > **Pomoć (Wiki)**.
# Prvi koraci
1. Pritisni [Q] i otvori karticu **Ascension Gates**.
2. Stvori dvoja Stargate vrata i jedan DHD (kategorija **Zvjezdana vrata i prstenje**).
3. Pogledaj DHD i pritisni [E]. Biraj druga vrata.
4. Prođi kroz vrata.
> Prijeđi mišem preko postavke: kratki redak kaže što radi.
# Stranice ove pomoći
- {page:gates|Stargate, DHD i prstenje}
- {page:hatak|Matični brod Ha'tak}
- {page:glider|Death Glider}
- {page:alkesh|Al'kesh i drugi brodovi}
- {page:spacegrid|PowerGrid: napajanje i energija}
- {page:goauldpower|Goa'uldsko energetsko čvorište i kristali}
- {page:lifesupport|Održavanje života i svemir}
- {page:weapons|Ručno oružje}
- {page:keys|Promjena tipki}
- {page:admin|Postavke za admine}
- {page:problems|Problemi i rješenja}
]] },

{ id = "gates", title = "Stargate, DHD i prstenje", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Stvori vrata i DHD, pritisni E na DHD-u, biraj adresu. Prstenje te prenosi između obližnjih platformi prstenja.
# Gdje ih naći
- [Q] > Ascension Gates > **Zvjezdana vrata i prstenje**: vrata, DHD-ovi, prstenje i ploče prstenja.
- Alati ([Q] > desno > Ascension Gates > Tech): Mobilni DHD, Supergate DHD, Iris, Goa'uld Iris.
# Biranje preko DHD-a
1. Stavi DHD blizu vrata (bliže od 1000 jedinica).
2. Pogledaj simbol na DHD-u i pritisni [E]: zasvijetli.
3. Pritisni sve simbole adrese, zatim veliku središnju tipku.
- Središnja tipka bez pritisnutih simbola: otvara se izbornik biranja.
- Središnja tipka dok su vrata otvorena: vrata se zatvaraju.
# Biranje preko izbornika vrata
1. Pogledaj vrata i pritisni [E].
2. Upiši adresu ili je odaberi s popisa.
3. Klikni **Dial**. **Abort Dialling / Close Gate** to zaustavlja.
- U istom izborniku postavljaš adresu vrata, grupu, ime i jesu li privatna.
# Irisa
- Alat **Irisa**: lijevi klik na vrata. Tipke: numerička [2] je prebacuje.
- **Računalo irise** (Zvjezdana vrata i prstenje): prisloni ga na vrata s irisom, [E] = izbornik (kodovi, automatsko zatvaranje).
- **GDO** (oružje): desni klik = upiši svoj kod, lijevi klik = pošalji ga na otvorena vrata.
# Prstenje
- Platforma prstenja + ploča prstenja, blizu jedna drugoj (ploča radi za prstenje do 500 jedinica).
- [E] na tipki ploče pritišće je. **DIAL** bez znamenki = do najbližeg prstenja. Sa znamenkama = do prstenja s tom adresom.
- [E] na bazi prstenja: daj mu ime (adresu).
- **Ring Caller** (oružje): lijevi klik zove najbliže prstenje, desni klik otvara prozor biranja.
! Prstenje te zgnječi ako mirno stojiš tamo gdje se spušta. Stani u sredinu platforme ili siđi s nje.
]] },

{ id = "hatak", title = "Matični brod Ha'tak", icon = "icon16/house.png", body = [[
= Golem goa'uldski matični brod. Možeš hodati po njemu, letjeti, boriti se i napajati ga. Iznutra je puno veći nego izvana.
# Stvaranje
- [Q] > Ascension Gates > **Veći matični brodovi** > Ha'tak.
- Pojavi se visoko iznad mjesta u koje ciljaš (ili ispred tebe ako ciljaš u nebo). Lebdi.
# Ulazak
- **Hangar:** velika vrata dolje na piramidi. [E] na njima ih otvara. Uđi: ravno si u hangaru unutra.
- Vrata hangara izvana i iznutra su jedna vrata: otvorena ili zatvorena s obje strane. Upravljač vrata (zlatna pločica) je pokraj njih iznutra i izvana.
- **Prstenje:** koristi prstenje vani blizu broda ili ploču prstenja unutra.
- [E] na vratima ili na zlatnom upravljaču pokraj njih: vrata se otvaraju ili zatvaraju.
- Otvorena vrata: pogledaj u otvor i pritisni [E] da ih zatvoriš.
> Iznutra uvijek možeš izaći istim putem: otvor hangara radi u oba smjera.
# Palube
1. **Hangarska paluba:** hangar, soba s prstenjem, soba kel'no'reema, vojarna Jaffa, hangar za glidere.
2. **Pel'tak (most):** prijestolje, pilotska stolica, oružje, navigacijske i zapovjedne konzole.
3. **Soba s vratima:** Stargate s DHD-om.
4. **Zapovjedna paluba:** odaje sa sarkofagom, oružarnica, jezgra računala.
5. **Strojarnica:** strojarnica, ćelije, soba sa štitovima.
- Putovanje među palubama: [E] na ploči prstenja > odaberi palubu.
# Tko ga smije koristiti
- **Posada** = vlasnik i njegovi prijatelji (prijatelji iz zaštite propova).
- Stranci mogu preuzeti brod pomoću **kristala upravljanja**. Vidi {page:hatak_systems|Sustavi Ha'taka}.
# Više
- {page:hatak_fly|Letenje, skok i oružje}
# Glavni izbornik (cijeli brod u jednom prozoru)
- Otvori ga: [1] na prijestolju, u pilotskom sjedalu ili kao strijelac, ili [E] na zapovjednoj konzoli na pel'taku.
- **SHIP:** trup, energija, štitovi, tko leti. Hipersvemir, oružje, strojarnica, adrese.
- **DOORS:** sva vrata: otvori, zatvori, zaključaj. Sva vrata odjednom otvorena ili zatvorena.
- **SYSTEMS:** štitovi, maskiranje, alarm, zaključavanje, brodski dnevnik, samouništenje.
- {page:hatak_systems|Energija, računalo, štitovi, šteta i sobe}
]] },

{ id = "hatak_fly", title = "Ha'tak: leti, skači, bori se", icon = "icon16/arrow_up.png", body = [[
= Sjedni u pilotsku stolicu na pel'taku. W/S/A/D = let, R = hipersvemir, V = kamera. Oružje je na konzoli oružja.
# Preuzmi kormilo
1. Idi na pel'tak (most).
2. Sjedni na **prijestolje** ([E]) ili u pilotsku stolicu ([E] na pilotskoj konzoli).
3. Sjedalo napuštaš s [E].
- Prijestolje ima prednost: ako su oba zauzeta, leti prijestolje.
- [1] otvara **glavni izbornik** (i u načinu strijelca).
- Prednja strana broda je strana hangara: [W] leti tamo.
# Tipke za let
- [W] naprijed, [S] natrag.
- [A] / [D] skretanje lijevo / desno.
- [Space] gore, [Ctrl] dolje.
- Drži [Shift]: 4x brže.
- [V]: kamera. Počinje iza broda i iznad njega (kotačić miša = udaljenost). Zatim: sjedalo, pa pogled s vrha broda.
- Prozor na pel'taku pokazuje pravi pogled van.
- [R]: izbornik hipersvemira.
- Bez pilota: brod usporava i staje.
> Tko je na brodu, ne klizi dok brod leti.
# Skok u hipersvemir
1. Pritisni [R] u pilotskoj stolici (ili [E] na navigacijskoj konzoli).
2. Odaberi cilj: spremljene oznake, Stargate ili drugog igrača. Ili upiši x y z.
3. Klikni **Jump**. Brod se puni (3 s), otvara se prozor, preletiš kroz njega.
- **Oznaka 1/2/3 ovdje** pamti mjesto.
- Treba 30 % snage hiperpogona. Pauza od 8 s između skokova.
# Oružje
- [E] na **konzoli oružja**: radar odozgo i popis meta.
- **OFF:** bez pucanja. **DEFEND:** puca samo na ono što je napalo brod. **AUTO:** i na NPC-ove i strance.
- **FIRE:** jedna salva na odabranu metu. **KEEP FIRING:** uvijek iznova.
- **MANUAL (GUNNER)** ili sjedni u topničku stolicu: ciljaš sam.
## Tipke topnika
- Miš cilja, [Mouse1] vatra, drži [Mouse2] za zoom.
- [R] sljedeća skupina topova (gore, naprijed, bokovi, straga, dolje).
- [E] izlaz.
! Pucanje isključuje tvoje maskiranje.
]] },

{ id = "hatak_systems", title = "Sustavi i sobe Ha'taka", icon = "icon16/cog.png", body = [[
= Kristali napajaju sve. Izvuci jedan i sustav oslabi. Jezgra računala vodi prstenje, vrata, senzore i poruke.
# Strojarnica: energetski kristali
- Energetska jezgra (hub) drži 3 kristala. Ladice drže po 3 kristala: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] na kristalu: izvučeš ga i nosiš.
- [E] kod slobodnog utora: staviš ga.
- Izgorjeli kristali (tamni) nastaju od jakih pogodaka. Stavi ih u **rezervni stalak**: pune se za 60 s.
- Dva generatora naquadaha: [E] ih uključuje (+15 % svaki).
- **Četvrti krak huba:** još jedan kristal (+15 %) ili **ZPM** (130 %). Primakni ZPM gravitacijskim pištoljem: sjedne na mjesto.
- **Inženjerska konzola:** pokazuje svu energiju. Tipke šalju više energije jednom sustavu.
# Jezgra računala: kristali podataka
- Plavi kristali u 4 stalka: **Rings**, **Doors**, **Sensors**, **Communication**. Moraju biti 2 od 3, inače ta funkcija staje.
- **Samouništenje:** 1, 2 ili 4 minute. **ABORT** ga zaustavlja.
- **Brodski dnevnik:** što se dogodilo na brodu.
- **Adrese:** sva vrata na karti. **DIAL** bira iz sobe s vratima.
- **Sigurnost:** alarm uklj/isklj, zaključavanje (sva vrata zaključana, posada ih ipak može otvoriti).
# Štitovi i maskiranje
- Konzola u sobi sa štitovima ili zapovjedna konzola: **RAISE / LOWER SHIELDS**.
- **AUTO:** štitovi se sami podignu kad netko napadne.
- Štit zaustavlja svako oružje, i vlasnikovo: hici staju na zlatnom mjehuru.
- **CLOAK:** brod nestaje. Treba 30 % snage štitova. Štitovi padaju dok je maskiran.
# Održavanje života
- Zrak, toplina i gravitacija na brodu, i u svemiru.
- Treba energiju iz jezgre i trup iznad 10 %. Bez toga je unutra kao vani (u svemiru nema zraka).
- Glavni izbornik: stanje na SHIP, uključi/isključi na SYSTEMS.
# Šteta
- Računaju se samo teški pogoci. Dok štit drži, on prima pogotke.
- Eksplozije **unutra** bole dvostruko jače i spaljuju obližnje kristale.
- Alarm kod 50, 25 i 10 % trupa. Kod 0 brod eksplodira (admini to mogu isključiti).
- **Alat za popravak** popravlja trup.
# Sobe
- **Hangar za glidere:** 4 Death Glidera. [E] = leti. Izleti kroz lansirni tunel. Izgubljeni glideri vraćaju se nakon 60 s.
- Lansirni tuneli imaju vrata iznutra i izvana. Otvaraju se sama kad letiš gliderom prema njima. Otvori ili zatvori ih u glavnom izborniku.
- **Vojarna:** [E] na konzoli ležaja = ponovno se pojaviš na brodu. Škrinja s oklopom: [E] = +50 oklopa (jednom u minuti).
- **Kel'no'reem:** čučni ([Ctrl]) na prostirci = polako se liječiš.
- **Sarkofag:** [E] za ležanje i liječenje.
- **Oružje:** [E] na štapno oružje na zidu: uzimaš ga (nakon 2 minute tu je novo). [E] na škrinju sa zatom: zat.
- **Ćelije:** [E] na ploči pokraj ćelije uključuje njezino polje sile (samo posada).
# Preuzimanje broda (hijack)
1. Nađi **kristal upravljanja** skriven negdje unutra. [E] ga podiže.
2. Idi do utora za kristal na pel'taku (desni zid). [E] pokreće.
3. Ostani blizu 40 s. Oglasi se alarm.
4. Gotovo: ti i tvoji prijatelji ste nova posada.
- Stara posada to može zaustaviti: [E] na utoru.
]] },

{ id = "glider", title = "Death Glider", icon = "icon16/bullet_go.png", body = [[
= Mali goa'uldski lovac. W = let, miš = upravljanje, Mouse1 = pucanje. Bez pritisnute tipke lebdi.
# Gdje ga naći
- [Q] > Ascension Gates > **Flota: Brodovi i lovci** > Death Glider. Ili u hangaru za glidere na Ha'taku.
# Tipke
- [E] na glideru: uđi. [E] opet: izađi.
- [W] let naprijed, [S] polako natrag. Drži [Shift]: brže.
- Miš: upravljanje.
- [1]: pogled iz kokpita uključi / isključi.
- Nijedna tipka: drži mjesto u zraku.
- [Mouse1]: pali oba štapna topa.
- Kotačić miša: nagib. [Mouse3]: natrag u ravninu.
- Strelice: udaljenost i visina kamere.
- [Backspace]: samouništenje.
# Slobodni let (postavka servera)
- S **agp_glider_free_flight 1**: [S] natrag, [A] / [D] u stranu, [Space] gore, [Ctrl] dolje.
# HUD
- Dolje lijevo: trup, brzina, štapni topovi, tipke.
- 300 trupa. Kod 0 eksplodira.
> Promjena tipki: {page:keys|Promjena tipki}.
]] },

{ id = "alkesh", title = "Al'kesh i drugi brodovi", icon = "icon16/bullet_go.png", body = [[
= Svaki brod: E = ulazak i izlazak, W/A/S/D i miš = let, Mouse1 = pucanje.
# Al'kesh
- [Q] > Ascension Gates > **Flota: Brodovi i lovci**. Ciljaj u tlo da ga stvoriš.
- [W] [S] [A] [D] let. [Space] gore, [Ctrl] dolje. Drži [Shift]: brže.
- [Mouse1] vatra. Kotačić miša nagib, [Mouse3] opet ravno.
- [Enter]: način slijetanja (drži ravno).
- [E] izlaz. [Backspace] samouništenje.
# Veliki brodovi
- Aurora, Destiny, Gate Seeder, O'Neill, matični brod Orija, Prometheus, matični brod Replikatora, brod Putnika, krstarica Wraitha.
- Iste tipke kao Al'kesh. Još [Mouse2] prati metu, [G] štit.
# Mali brodovi
- **Puddle Jumper:** [Mouse1] dronovi (sam otvara module), [Mouse2] drži = dronovi prate tvoj cilj, [Alt] maskiranje, [2] vrata, [T] lebdenje, [G] štit, [R] biraj najbliža vrata.
- **Tel'tak:** [Mouse2] štapni topovi, [G] štit, [Alt] maskiranje, drži [R] hipersvemir, [2] vrata. Prstenasti snop: [Enter] (način slijetanja), zatim [Mouse1].
- **F-302:** [Mouse1] topovi, [Mouse2] rakete, [Alt] mamci, [B] ubrzanje, [2] katapultiranje.
- **Daedalus:** [Mouse1] elektromagnetski topovi, [Mouse2] zraka Asgarda, [1] do [8] rakete.
- **Wraith Dart:** [C] skupljaj ljude, [Alt] ispusti ih.
> Promjena tipki: {page:keys|Promjena tipki}.
]] },

{ id = "spacegrid", title = "PowerGrid: napajanje i energija", icon = "icon16/lightning.png", body = [[
= PowerGrid je kartica alata za energiju. Postavi dijelove za napajanje, poveži ih, napajaj ih ZPM-ovima ili generatorima.
# Gdje
- [Q] > desno > kartica **PowerGrid**.
- **PowerGrid:** alat Dijelovi PowerGrida (svi dijelovi u jednoj mreži slika).
- **Energija:** ZPM, ZPM hubovi, generatori naquadaha, goa'uldsko energetsko čvorište, PowerGrid veza.
- **Postavke:** postavke PowerGrid i ova pomoć.
# Postavljanje dijela
1. Uzmi alat **Dijelovi PowerGrida**.
2. Klikni sliku desno (na primjer energetsku ćeliju).
3. Ciljaj gdje treba stajati. Vidiš njegov sjenoviti prikaz.
4. Lijevi klik [Mouse1]: postavljeno. Desni klik [Mouse2]: postavljeno zakrenuto za 90 stupnjeva.
- Ciljaj dio i pritisni [R]: taj dio je odabran.
- Na brodu ili propu zavari se za ono u što ciljaš (okvir **Zavari na ono na što ciljaš**).
# Dijelovi
- **Energetske ćelije (XS do XL):** pohranjuju energiju.
- **Solarni paneli:** proizvode energiju dok je iznad njih otvoreno nebo.
- **Vjetroturbina:** proizvodi energiju, više što je viša.
- **Energija crne rupe:** drži sve resurse (samo za admine, osim ako je dopušteno).
- **Čvorovi napajanja:** povezuju sve postavljeno na njih. Njihov zaslon pokazuje mrežu.
- **Zasloni napajanja:** pokazuju mrežu na koju su povezani.
- **Ventil napajanja:** uklj = energija teče između dvije mreže, isklj = razdvojene su. [E] prebacuje.
- **Spremnici resursa:** drže jedan resurs (kisik, voda ...). [E] mijenja resurs dok je prazan.
- **Održavanje života:** vidi {page:lifesupport|Održavanje života}.
# Povezivanje (kako dijelovi dijele energiju)
- Admini biraju način: **Manual**, **Automatic**, **Mix** ili **Off** (postavke PowerGrid).
- **Manual:** alat **PowerGrid veza**: lijevi klik na dijelove (postaju plavi), desni klik na dio ili energetski čvor s kojim se povezuju. [R] briše odabir; [R] na dijelu uklanja njegove veze.
- **Automatic:** dijelovi zavareni zajedno sami dijele.
- **Off:** sve ima slobodnu energiju.
! Imaš li instaliran Spacebuild? Tada se koristi Spacebuildova mreža. Energetski čvorovi PowerGrida tada rade kao Spacebuildovi čvorovi: povezuj alatom PowerGrid veza. Admini mogu uključiti **Uvijek PowerGrid**.
# Izvori energije
- **ZPM:** alat **ZPM MK III**. Stavi ga u ZPM hub ili u {page:goauldpower|Goa'uldsko energetsko čvorište}.
- **Generator naquadaha:** alat u Energy.
- **Goa'uldski energetski kristali:** u {page:goauldpower|Goa'uldskom energetskom čvorištu}.
]] },

{ id = "goauldpower", title = "Goa'uldsko energetsko čvorište i kristali", icon = "icon16/rainbow.png", body = [[
= Mjedeni hub sa zlatnom energetskom jezgrom. Njegova 4 kraka primaju goa'uldske energetske kristale ili ZPM-ove. Jezgra pulsira jače što ima više energije.
# Gdje ga naći
- Alat: [Q] > PowerGrid > Energija > **Goa'uld Power Hub + Crystals**.
- Ili kartica stvaranja: Ascension Gates > **PowerGrid**.
# Korištenje
1. Lijevi klik [Mouse1] alatom: hub.
2. Ciljaj krak i desni klik [Mouse2]: kristal sjedne na taj krak.
3. ZPM: uzmi ZPM alat, ciljaj krak, lijevi klik: ZPM sjedne na taj krak.
4. Poveži hub sa svojom mrežom kao bilo koji dio ({page:spacegrid|PowerGrid}).
- Primakni kristal ili ZPM kraku (gravitacijskim ili fizičkim pištoljem): sjedne na mjesto.
- [E] na kristalu ili ZPM-u: izlazi.
- [E] na hubu: pokazuje kristale, ZPM-ove i energiju u chatu.
- Pogledaj hub: mala pločica pokazuje kristale i energiju.
> ZPM daje deset puta više energije od kristala i jače pokreće jezgru.
# Klizač u alatu
- **Napunjenost kristala:** koliko su novi kristali puni (0 do 100 %).
]] },

{ id = "lifesupport", title = "Održavanje života i svemir", icon = "icon16/heart.png", body = [[
= U svemiru nema zraka i hladno je. Tvoje odijelo te neko vrijeme štiti. Održavanje života čini brod ili područje sigurnim.
# Kada je uključeno?
- Admini biraju: samo svemirske karte (zadano), svaka karta, ili isključeno ({page:admin|Postavke za admine}).
# Tvoje odijelo
- Tri vrijednosti: **zrak**, **energija**, **rashladno sredstvo**. Pune su kad se pojaviš.
- Nema zraka ili si pod vodom: zrak pada. Dobar zrak: opet se puni.
- Hladno: pada energija. Vruće: pada rashladno sredstvo.
- Vrijednost 0 te ozljeđuje.
- Okvir dolje lijevo pokaže se samo kad nešto nije u redu.
# Life Support Core
- Na brodu: cijeli brod dobiva zrak. [E] prebacuje.
- Ne na brodu: mjehur zraka. [E] mijenja veličinu (300 do 2000, zatim isključeno).
- Treba energiju i kisik (kisik pravi iz vode).
# Napuni odijelo
- **Dozator odijela:** [E] puni zrak, energiju i rashladno sredstvo iz svoje mreže.
- **Kompresor zraka:** kisik iz zraka za disanje. **Pumpa za vodu:** voda dok stoji u vodi.
# Izvješće vrata
- Kad vrata biraju, dobiješ kratko izvješće: zrak, temperatura, gravitacija s druge strane i trebaš li odijelo.
]] },

{ id = "weapons", title = "Ručno oružje", icon = "icon16/bomb.png", body = [[
= Uzmi ga u [Q] > Ascension Gates > Oružja. Mouse1 = glavna uporaba, Mouse2 = druga uporaba.
# Goa'uldi
- **Zat'nik'tel:** 1. hitac omamljuje, 2. ubija, 3. čini da nestane.
- **Štapno oružje:** [Mouse2] pripremi, [Mouse1] vatra.
- **Ručni uređaj:** [Mouse1] koristi, [Mouse2] sljedeći način rada.
- **Uređaj za liječenje:** drži na igraču da ga izliječiš.
- **Mobilni DHD:** stavi ga na vrata.
# Zemlja (SGC)
- **P90 (PDW):** [Mouse1] vatra, [Mouse2] nišan, [R] dopuna.
- **Beretta:** [Mouse1] vatra, [R] dopuna.
- **GDO:** [Mouse2] upiši kod, [Mouse1] pošalji.
# Ostalo
- **Ručno oružje / štap Orija, blaster Wraitha, Rononov pištolj, oružje Asurana.**
- **Tac:** baci, opet = eksplozija. [Mouse2] ubij / omami / dim.
- **Alat za popravak:** drži na brodu, vratima ili DHD-u da ih popraviš.
- **Upravljačka stolica (Drevni, kartica Oružja):** [E] za sjesti (treba napunjen ZPM u svom hubu). [1] = popis meta: zaključaj dronove na metu ili ciljaj slobodno.
- **Osobni štit, plašt Sodana:** [Mouse1] uklj, [Mouse2] isklj.
- **Mimetički uređaj za snimanje:** drži [Mouse1] na osobi tik ispred sebe da je snimiš, [Mouse2] projekcija uklj / isklj, [R] izbriši sliku.
]] },

{ id = "keys", title = "Promjena tipki", icon = "icon16/keyboard.png", body = [[
= Tipke većine malih brodova možeš promijeniti u izborniku Keybinders.
# Kako
1. [Q] > desno > Ascension Gates > **Keybinders**.
2. Odaberi brod.
3. Klikni redak jednom, pa brzo drugi put (postane narančast).
4. Pritisni novu tipku ili tipku miša. [Esc] otkazuje.
- Brodovi: Daedalus, Wraith Dart, Gate Glider, Death Glider, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- Ha'tak koristi tvoje uobičajene GMod tipke ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) i [V].
- Za vlastitu tipku: veži je na **agp_hatak_camera** (konzola: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Postavke za admine", icon = "icon16/shield.png", body = [[
= Admini (i ti u singleplayeru) mijenjaju postavke servera. Svi ostali ih samo vide. Prijeđi mišem preko postavke za kratki savjet.
# Postavke brodova: [Q] > Ascension Gates > Config > AGP brodovi
- **Otmica broda:** samo posada / s kristalom upravljanja / bilo tko.
- **Oružje puca na vlasnika i prijatelje:** da ili ne.
- **Domet oružja + radara:** koliko daleko topovi pucaju i radar vidi.
- **Radar: najviše prikazanih ciljeva.**
- **Kristali koje stranci smiju izvaditi:** 0 do 15 (zadano 2). Posada nema ograničenje.
- **Brod se može uništiti:** da (zadano) ili ne (trup ostaje na 1).
- **Izdržljivost trupa (novi brodovi):** 10 000 do 1 000 000 (zadano 100 000).
- **Maskiranje dopušteno:** da ili ne.
- **Hangar jedrilica: izgubljene se vraćaju:** da ili ne, i nakon koliko sekundi (zadano 60).
- **Mjehur štita (svi brodovi):** samo pri pogotku te pri uključivanju ili isključivanju (zadano) ili uvijek vidljiv.
- **Samouništenje: odbrojavanje (svi brodovi):** 1 do 600 sekundi (zadano 5).
# Postavke energije: [Q] > PowerGrid > Postavke > PowerGrid
- **Kako se dijelovi povezuju:** Ručno / Automatski / Mješovito / Isključeno. Vidi {page:spacegrid|PowerGrid}.
- **Uvijek PowerGrid:** koristi PowerGrid čak i sa Spacebuildom (treba promjenu karte).
- **Energija crne rupe:** samo admini ili svi.
- **Simulacija svemira:** samo svemirske karte / svaka karta / isključeno. Vidi {page:lifesupport|Održavanje života}.
- **Izvješće o odredištu vrata:** uklj ili isklj.
# Samo za tebe (svaki igrač)
- Kabeli, zvukovi strojeva, izvješće vrata na tvom zaslonu, jedinice za udaljenost, temperaturu i gravitaciju.
]] },

{ id = "problems", title = "Problemi i rješenja", icon = "icon16/help.png", body = [[
= Nešto ne radi? Prvo pogledaj ovdje.
# Ikone u Q izborniku postanu ružičaste i ništa se ne stvara
- Držiš [Ctrl] (ili se zaglavio). [Ctrl] + klik **odabire** ikone (ružičaste) umjesto da ih stvara.
- Rješenje: pusti [Ctrl] (pritisni ga jednom), klikni prazno mjesto u području ikona.
# Kliknem ikonu i ništa se ne pojavi
- Gledaj u tlo ispred sebe, ne u daleko nebo.
- Veliki brodovi se pojavljuju visoko iznad tla ili ispred tebe. Pogledaj oko sebe.
- Admini mogu isključiti dijelove ili ih ograničiti (Ascension Gates > Config > O paketu i zasluge > Postavke).
# Glider pada
- Death Glider drži visinu kad ne pritišćeš nijednu tipku. Pada li? Možda je uništen ili izvan karte.
# Konzola Ha'taka piše "crew only"
- Smiju je koristiti samo vlasnik i njegovi prijatelji. Ili preuzmi brod kristalom upravljanja ({page:hatak_systems|Sustavi Ha'taka}).
# Sustav broda piše OFFLINE
- Provjeri kristale u strojarnici i plave kristale podataka u jezgri računala.
# Lik se zaglavio u vratima ili prolazu
- Prolazi u unutrašnjosti brodova ne propuštaju te kad je druga strana zatvorena. Prvo otvori vrata.
- Još uvijek se zaglavljuje: noclip ([V]) ili ponovno pojavljivanje.
# Alat pokazuje tekst poput #tool.something.name
- Nedostaje tekst. Molim te, reci mi koji je to alat.
]] },

},
}
