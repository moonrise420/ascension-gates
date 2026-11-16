-- Ascension Gates help (wiki), Eesti. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Abi",
    search = "Otsi...",
    size = "Teksti suurus",
    short = "LÜHIDALT",
    intro = "Kõik Ascension Gates kohta: mida osad teevad ja kuidas neid juhid.",
    open = "Ava abi",
},
pages = {

{ id = "start", title = "Alusta siit", icon = "icon16/star.png", body = [[
= Ascension Gates on Stargate pakett: väravad, ringid, laevad, relvad, kilbid ja energia. See abi seletab iga osa lühikeste sammudega.
# Kus mis on
- **Asjade loomine:** vajuta [Q], sakk **Ascension Gates** (üleval vasakul). Kategooriad on vasakul.
- **Tööriistad:** [Q], parem pool, sakk **Ascension Gates** (väravad, uksed, relvad, klahvid) ja sakk **PowerGrid** (energia, vool, elutugi).
- **Seaded:** [Q] > Ascension Gates > Config. Laevade seaded: **AGP laevad**.
- **Energia ja elutugi seaded:** [Q] > PowerGrid > Seaded > **PowerGrid**.
- **See abi:** konsoolikäsk **agp_wiki** või [Q] > Ascension Gates > Config > **Abi (Wiki)**.
# Esimesed sammud
1. Vajuta [Q] ja ava sakk **Ascension Gates**.
2. Loo kaks Stargate'i ja üks DHD (kategooria **Väravad ja ringitransporterid**).
3. Vaata DHD-d ja vajuta [E]. Vali teine värav.
4. Kõnni läbi.
> Vii hiir seade peale: lühike rida ütleb, mida see teeb.
# Selle abi lehed
- {page:gates|Stargate, DHD ja ringid}
- {page:hatak|Ha'tak emalaev}
- {page:glider|Surmaliugur}
- {page:alkesh|Al'kesh ja teised laevad}
- {page:spacegrid|PowerGrid: vool ja energia}
- {page:goauldpower|Goa'uldi energiakeskus ja kristallid}
- {page:lifesupport|Elutugi ja kosmos}
- {page:weapons|Käerelvad}
- {page:keys|Klahvide muutmine}
- {page:admin|Adminide seaded}
- {page:problems|Probleemid ja lahendused}
]] },

{ id = "gates", title = "Stargate, DHD ja ringid", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Loo värav ja DHD, vajuta DHD-l E, vali aadress. Ringid viivad lähedal olevate ringiplatvormide vahel.
# Kust saad
- [Q] > Ascension Gates > **Väravad ja ringitransporterid**: väravad, DHD-d, ringid ja ringipaneelid.
- Tööriistad ([Q] > parem pool > Ascension Gates > Tech): Mobiilne DHD, Supervärava DHD, Iris, Goa'uld Iris.
# Vali aadress DHD-ga
1. Pane DHD värava lähedale (lähemale kui 1000).
2. Vaata DHD-l ühte tähist ja vajuta [E]: see süttib.
3. Vajuta kõik aadressi tähised, siis suur keskmine nupp.
- Keskmine nupp, kui ühtegi tähist pole vajutatud: avaneb valimismenüü.
- Keskmine nupp, kui värav on lahti: värav sulgub.
# Vali aadress värava menüüga
1. Vaata väravat ja vajuta [E].
2. Kirjuta aadress või vali loendist.
3. Klõpsa **Dial**. **Abort Dialling / Close Gate** peatab.
- Samas menüüs sead värava enda aadressi, grupi ja nime ning selle, kas see on privaatne.
# Iris
- Tööriist **Iris**: vasak klõps väravale. Klahv: numpad [2] lülitab seda.
- **Iris Computer** (Väravad ja ringitransporterid): puuduta sellega iirisega väravat, [E] = menüü (koodid, automaatne sulgemine).
- **GDO** (relv): parem klõps = kirjuta oma kood, vasak klõps = saada see avatud väravale.
# Ringid
- Ringiplatvorm + ringipaneel, lähestikku (paneel töötab ringidega 500 piires).
- [E] paneeli nupul vajutab seda. **DIAL** ilma numbriteta = lähimate ringideni. Numbritega = selle ringiaadressini.
- [E] ringi aluse peal: anna sellele nimi (aadress).
- **Ring Caller** (relv): vasak klõps kutsub lähimad ringid, parem klõps avab valimisakna.
! Ringid muljuvad sind, kui seisad paigal seal, kuhu nad alla tulevad. Astu platvormile või sellest eemale.
]] },

{ id = "hatak", title = "Ha'tak emalaev", icon = "icon16/house.png", body = [[
= Hiiglaslik Goa'uldi emalaev. Saad seal kõndida, sellega lennata, võidelda ja anda sellele energiat. Seest on see palju suurem kui väljast.
# Loomine
- [Q] > Ascension Gates > **Suuremad emalaevad** > Ha'tak.
- See ilmub kõrgele sihitud koha kohale (või sinu ette, kui sihid taevasse). See hõljub.
# Sisenemine
- **Angaar:** püramiidi alumine suur uks. [E] sellel avab selle. Kõnni sisse: oled otse sisemises angaaris.
- Angaari uks väljas ja sees on üks uks: mõlemal pool lahti või kinni. Ukse lüliti (kuldne plaat) on selle kõrval nii sees kui väljas.
- **Ringid:** kasuta ringe laeva lähedal väljas või ringipaneeli seespool.
- [E] uksel või selle kõrval olevas kuldses juhtimises: uks avaneb või sulgub.
- Avatud uks: vaata ukseavasse ja vajuta [E], et see sulgeda.
> Seest saad alati väljuda sealt, kust sisenesid: angaari ava töötab mõlemas suunas.
# Tekid
1. **Angaaritekk:** angaar, ringide ruum, kel'no'reemi ruum, jaffa kasarmu, liuguriangaar.
2. **Pel'tak (sild):** troon, piloodiiste, relvad, navigatsiooni- ja juhtkonsoolid.
3. **Värava ruum:** Stargate koos DHD-ga.
4. **Juhtimistekk:** kajutid sarkofaagiga, relvaladu, arvutituum.
5. **Masinaruum:** mootoriruum, vangikongid, kilbiruum.
- Tekkide vahel liikumine: [E] ringipaneelil > vali tekk.
# Kes tohib kasutada
- **Meeskond** = omanik ja tema sõbrad (prop protection sõbrad).
- Võõrad saavad laeva **juhtkristalliga** üle võtta. Vaata {page:hatak_systems|Ha'taki süsteemid}.
# Veel
- {page:hatak_fly|Lendamine, hüpe ja relvad}
# Peamenüü (kogu laev ühes aknas)
- Ava see: [1] troonil, piloodiistmel või laskurina, või [E] pel'taki käsukonsoolil.
- **SHIP:** kere, energia, kilbid, kes lendab. Hüperruum, relvad, masinaruum, aadressid.
- **DOORS:** iga uks: ava, sulge, lukusta. Kõik uksed korraga lahti või kinni.
- **SYSTEMS:** kilbid, varjamine, alarm, lukustus, laevalogi, enesehävitus.
- {page:hatak_systems|Energia, arvuti, kilbid, kahjustused ja ruumid}
]] },

{ id = "hatak_fly", title = "Ha'tak: lenda, hüppa, võitle", icon = "icon16/arrow_up.png", body = [[
= Istu pel'taki piloodiistmele. W/S/A/D lendamiseks, R hüperruum, V kaamera. Relvad on relvakonsoolil.
# Võta rool
1. Mine pel'taki (sillale).
2. Istu **troonile** ([E]) või piloodiistmele ([E] piloodikonsoolil).
3. Istmelt lahkud [E]-ga.
- Troon on esikohal: kui mõlemad on võetud, lendab troon.
- [1] avab **peamenüü** (ka laskuri režiimis).
- Laeva esiosa on angaari pool: [W] lendab sinna.
# Lendamise klahvid
- [W] edasi, [S] tagasi.
- [A] / [D] pööra vasakule / paremale.
- [Space] üles, [Ctrl] alla.
- Hoia [Shift]: 4x kiiremini.
- [V]: kaamera. See algab laeva taga ja kohal (hiirerullik = kaugus). Siis: iste, seejärel vaade ninaotsast.
- Pel'taki aken näitab päris vaadet väljas.
- [R]: hüperruumi menüü.
- Piloodita: laev aeglustub ja peatub.
> Kes pole laeval, libiseb ringi, kui laev lendab.
# Hüperruumi hüpe
1. Vajuta [R] piloodiistmel (või [E] navigatsioonikonsoolil).
2. Vali siht: salvestatud märgid, Stargate või teine mängija. Või kirjuta x y z.
3. Klõpsa **Jump**. Laev laeb (3 s), avaneb aken, sa lendad läbi.
- **Save mark 1/2/3 here** jätab koha meelde.
- Vaja on 30 % hüperajami energiat. Hüpete vahel 8 s paus.
# Relvad
- [E] **relvakonsoolil**: radar ülalt ja sihtmärkide loend.
- **OFF:** ei tulista. **DEFEND:** tulistab ainult seda, mis laeva ründas. **AUTO:** ka NPC-sid ja võõraid.
- **FIRE:** üks salv valitud sihtmärgile. **KEEP FIRING:** ikka ja jälle.
- **MANUAL (GUNNER)** või istu laskuri toolile: sihid ise.
## Laskuri klahvid
- Hiir sihib, [Mouse1] tuli, hoia [Mouse2]: suum.
- [R] järgmine kahurirühm (ülemine, esimene, küljed, tagumine, alumine).
- [E] lahku.
! Tulistamine võtab maha sinu enda varjamise.
]] },

{ id = "hatak_systems", title = "Ha'taki süsteemid ja ruumid", icon = "icon16/cog.png", body = [[
= Kristallid annavad kõigele energiat. Tõmba üks välja ja üks süsteem nõrgeneb. Arvutituum juhib ringe, uksi, andureid ja teateid.
# Mootoriruum: energiakristallid
- Energiatuum (keskus) hoiab 3 kristalli. Alused hoiavad igaüks 3 kristalli: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] kristallil: tõmbad selle välja ja kannad.
- [E] vabal pesal: paned selle sisse.
- Läbipõlenud (tumedad) kristallid tulevad tugevatest löökidest. Pane need **varuriiulile**: need laevad 60 s-ga uuesti.
- Kaks naquadah generaatorit: [E] lülitab need sisse (+15 % kumbki).
- **Neljas keskuse haar:** veel üks kristall (+15 %) või **ZPM** (130 %). Too ZPM gravitatsioonirelvaga lähedale: see klõpsab külge.
- **Inseneri konsool:** näitab kogu energiat. Nupud saadavad rohkem energiat ühele süsteemile.
# Arvutituum: andmekristallid
- Sinised kristallid 4 riiulis: **Rings**, **Doors**, **Sensors**, **Communication**. 3-st peab 2 sees olema, muidu see funktsioon seiskub.
- **Isehävitus:** 1, 2 või 4 minutit. **ABORT** peatab.
- **Laeva logi:** mis pardal juhtus.
- **Aadressid:** kõik kaardi väravad. **DIAL** valib värava ruumist.
- **Turvalisus:** alarm sees/väljas, lukustus (kõik uksed lukus, meeskond saab need ikka avada).
# Kilbid ja varjamine
- Kilbiruumi konsool või juhtkonsool: **RAISE / LOWER SHIELDS**.
- **AUTO:** kilbid tõusevad ise, kui keegi ründab.
- Kilp peatab iga relva, ka omaniku oma: lasud peatuvad kuldsel mullil.
- **CLOAK:** laev kaob. Vaja on 30 % kilbi energiat. Varjatuna kilbid langevad.
# Elutugi
- Õhk, soojus ja raskusjõud pardal, ka kosmoses.
- Vaja on tuuma energiat ja kere üle 10 %. Ilma selleta on sees nagu väljas (kosmoses pole õhku).
- Peamenüü: olek lehel SHIP, sisse/välja lehel SYSTEMS.
# Kahjustused
- Arvesse lähevad ainult rasked löögid. Kuni kilp peab, võtab see löögid.
- Plahvatused **seespool** teevad kaks korda rohkem kahju ja põletavad lähedal olevaid kristalle.
- Alarm 50, 25 ja 10 % kerel. 0 juures laev plahvatab (adminid saavad selle välja lülitada).
- **Parandustööriist** parandab keret.
# Ruumid
- **Liuguriangaar:** 4 Surmaliugurit. [E] = lenda. Lenda välja stardituneli kaudu. Kadunud liugurid tulevad 60 s pärast tagasi.
- Stardituneleil on uksed seest ja väljast. Need avanevad ise, kui lendad liuguriga nende poole. Ava või sulge need peamenüüs.
- **Kasarmu:** [E] voodikonsoolil = ärkad pardal uuesti. Soomuskirst: [E] = +50 soomust (kord minutis).
- **Kel'no'reem:** kükita ([Ctrl]) matil = paranedki aeglaselt.
- **Sarkofaag:** [E] sinna heitmiseks ja paranemiseks.
- **Relvad:** [E] seinal olevale kepprelvale: võtad selle (2 minuti pärast on seal uus). [E] zati kirstule: zat.
- **Vangikongid:** [E] kongi kõrval olevas paneelis lülitab selle jõuvälja (ainult meeskond).
# Laeva ülevõtmine (kaaperdamine)
1. Leia kuhugi sisse peidetud **juhtkristall**. [E] võtab selle.
2. Mine kristallipesa juurde pel'takil (parem sein). [E] käivitab.
3. Püsi lähedal 40 s. Alarm läheb käima.
4. Valmis: sina ja su sõbrad olete uus meeskond.
- Vana meeskond saab selle peatada: [E] pesal.
]] },

{ id = "glider", title = "Surmaliugur", icon = "icon16/bullet_go.png", body = [[
= Väike Goa'uldi hävitaja. W lendamiseks, hiir juhtimiseks, Mouse1 tulistamiseks. Kui ühtegi klahvi ei vajuta, hõljub.
# Kust saad
- [Q] > Ascension Gates > **Laevastik: Laevad ja hävitajad** > Death Glider. Või Ha'taki liuguriangaaris.
# Klahvid
- [E] liuguril: astud sisse. [E] uuesti: astud välja.
- [W] lenda edasi, [S] aeglaselt tagasi. Hoia [Shift]: kiiremini.
- Hiir: juhi.
- [1]: kabiinivaade sisse / välja.
- Klahvita: see püsib õhus paigal.
- [Mouse1]: tulista mõlemast kepikahurist.
- Hiirerullik: veere. [Mouse3]: veere tagasi sirgeks.
- Nooleklahvid: kaamera kaugus ja kõrgus.
- [Backspace]: isehävitus.
# Vaba lend (serveri seade)
- Kui **agp_glider_free_flight 1**: [S] tagasi, [A] / [D] külgedele, [Space] üles, [Ctrl] alla.
# HUD
- All vasakul: kere, kiirus, kepikahurid, klahvid.
- 300 kere. 0 juures plahvatab.
> Klahvide muutmine: {page:keys|Klahvide muutmine}.
]] },

{ id = "alkesh", title = "Al'kesh ja teised laevad", icon = "icon16/bullet_go.png", body = [[
= Iga laev: E sisse ja välja minekuks, W/A/S/D ja hiir lendamiseks, Mouse1 tulistamiseks.
# Al'kesh
- [Q] > Ascension Gates > **Laevastik: Laevad ja hävitajad**. Sihi maapinda, et see luua.
- [W] [S] [A] [D] lenda. [Space] üles, [Ctrl] alla. Hoia [Shift]: kiiremini.
- [Mouse1] tuli. Hiirerullik veeremine, [Mouse3] jälle sirgeks.
- [Enter]: maandumisrežiim (püsib sirgena).
- [E] välja. [Backspace] isehävitus.
# Suured laevad
- Aurora, Destiny, Gate Seeder, O'Neill, Ori emalaev, Prometheus, Replikaatorite emalaev, Traveler, Wraithi ristleja.
- Samad klahvid mis Al'keshil. Lisaks [Mouse2] sihtmärgi jälgimine, [G] kilp.
# Väikesed laevad
- **Puddle Jumper:** [Mouse1] droonid (kapslid avanevad ise), [Mouse2] hoia = droonid järgivad sinu sihti, [Alt] varjamine, [2] uks, [T] hõljumine, [G] kilp, [R] vali lähim värav.
- **Tel'tak:** [Mouse2] kepikahurid, [G] kilp, [Alt] varjamine, hoia [R] hüperruum, [2] uks. Rõngaskiir: [Enter] (maandumisrežiim), siis [Mouse1].
- **F-302:** [Mouse1] kahurid, [Mouse2] raketid, [Alt] pettesihtmärgid, [B] kiirendus, [2] katapult.
- **Daedalus:** [Mouse1] rööpakahurid, [Mouse2] Asgardi kiir, [1] kuni [8] raketid.
- **Wraith Dart:** [C] kogub inimesi, [Alt] paneb nad välja.
> Klahvide muutmine: {page:keys|Klahvide muutmine}.
]] },

{ id = "spacegrid", title = "PowerGrid: vool ja energia", icon = "icon16/lightning.png", body = [[
= PowerGrid on energia tööriistade sakk. Pane energiaosad kohale, ühenda need, toida neid ZPM-ide või generaatoritega.
# Kus see on
- [Q] > parem pool > sakk **PowerGrid**.
- **PowerGrid:** tööriist PowerGridi osad (kõik osad ühes pildivõrgus).
- **Energia:** ZPM, ZPM keskused, naquadah generaatorid, Goa'uldi energiakeskus, PowerGridi ühendus.
- **Seaded:** PowerGrid seaded ja see abi.
# Osa paigutamine
1. Võta tööriist **PowerGridi osad**.
2. Klõpsa paremal pildil (näiteks energiaelement).
3. Sihi, kuhu see peab jääma. Näed selle kummitusena.
4. Vasak klõps [Mouse1]: paigas. Parem klõps [Mouse2]: paigas 90 kraadi pööratult.
- Sihi osa ja vajuta [R]: see osa on valitud.
- Laeval või propil keevitatakse see selle külge, mida sihid (kast **Weld to what I aim at**).
# Osad
- **Energiaelemendid (XS kuni XL):** salvestavad energiat.
- **Päikesepaneelid:** toodavad energiat, kui nende kohal on avatud taevas.
- **Tuuleturbiin:** toodab energiat, seda rohkem, mida kõrgemal see seisab.
- **Musta augu energia:** hoiab kõiki ressursse (ainult adminidele, kui pole lubatud).
- **Energiasõlmed:** ühendavad kõik, mis nende peal on. Nende ekraan näitab võrku.
- **Energiaekraanid:** näitavad võrku, millega nad on ühendatud.
- **Energiaventiil:** sees = energia liigub kahe võrgu vahel, väljas = need on lahus. [E] lülitab.
- **Ressursimahutid:** hoiavad ühte ressurssi (hapnik, vesi ...). [E] vahetab ressurssi, kui on tühi.
- **Elutugi:** vaata {page:lifesupport|Elutugi}.
# Ühendamine (kuidas osad energiat jagavad)
- Adminid valivad režiimi: **Manual**, **Automatic**, **Mix** või **Off** (PowerGrid seaded).
- **Manual:** tööriist **PowerGridi ühendus**: vasak klõps osadel (need lähevad siniseks), parem klõps osal või energiasõlmel, millega need ühendatakse. [R] tühistab valiku; [R] osal eemaldab selle ühendused.
- **Automatic:** kokku keevitatud osad jagavad ise.
- **Off:** kõigel on vaba energia.
! Spacebuild installitud? Siis kasutatakse Spacebuildi võrku. Meie energiasõlmed on siis Spacebuildi sõlmed: ühenda tööriistaga PowerGridi ühendus. Adminid saavad sisse lülitada **Alati PowerGrid**.
# Energiaallikad
- **ZPM:** tööriist **ZPM MK III**. Pane see ZPM keskusesse või {page:goauldpower|Goa'uldi energiakeskusesse}.
- **Naquadah generaator:** tööriist jaotises Energy.
- **Goa'uldi energiakristallid:** {page:goauldpower|Goa'uldi energiakeskuses}.
]] },

{ id = "goauldpower", title = "Goa'uldi energiakeskus ja kristallid", icon = "icon16/rainbow.png", body = [[
= Messingist keskus kuldse energiatuumaga. Selle 4 haara võtavad Goa'uldi energiakristalle või ZPM-e. Tuum pulseerib seda eredamalt, mida rohkem energiat tal on.
# Kust saad
- Tööriist: [Q] > PowerGrid > Energia > **Goa'uld Power Hub + Crystals**.
- Või loomise sakk: Ascension Gates > **PowerGrid**.
# Kasutamine
1. Vasak klõps [Mouse1] tööriistaga: keskus.
2. Sihi haara ja parem klõps [Mouse2]: kristall jääb sellele haarale.
3. ZPM: võta ZPM tööriist, sihi haara, vasak klõps: ZPM jääb sellele haarale.
4. Ühenda keskus oma võrku nagu iga teine osa ({page:spacegrid|PowerGrid}).
- Puuduta kristalli või ZPM-i haaraga (gravitatsioonirelv või physics gun): see klõpsab külge.
- [E] kristallil või ZPM-il: see tuleb välja.
- [E] keskusel: näitab vestluses kristalle, ZPM-e ja energiat.
- Vaata keskust: väike silt näitab kristalle ja energiat.
> ZPM annab kümme korda rohkem energiat kui kristall ja ajab tuuma tugevamini.
# Liugur tööriistas
- **Crystal charge:** kui täis uued kristallid on (0 kuni 100 %).
]] },

{ id = "lifesupport", title = "Elutugi ja kosmos", icon = "icon16/heart.png", body = [[
= Kosmoses pole õhku ja on külm. Su ülikond kaitseb sind mõnda aega. Elutugi teeb laeva või ala ohutuks.
# Millal see sees on?
- Adminid valivad: ainult kosmosekaardid (vaikimisi), iga kaart või väljas ({page:admin|Adminide seaded}).
# Sinu ülikond
- Kolm väärtust: **õhk**, **energia**, **jahutusvedelik**. Sündides on täis.
- Õhku pole või oled vee all: õhk väheneb. Hea õhk: täitub jälle.
- Külm: energia väheneb. Kuum: jahutusvedelik väheneb.
- Väärtus 0 teeb sulle haiget.
- All vasakul olev kast ilmub ainult siis, kui midagi on valesti.
# Life Support Core
- Laeval: kogu laev saab õhku. [E] lülitab.
- Mitte laeval: õhumull. [E] muudab suurust (300 kuni 2000, siis väljas).
- Vaja on energiat ja hapnikku (see teeb veest hapnikku).
# Ülikonna täitmine
- **Suit Dispenser:** [E] täidab õhu, energia ja jahutusvedeliku oma võrgust.
- **Air Compressor:** hapnik hingatavast õhust. **Water Pump:** vesi, kui see seisab vees.
# Värava aruanne
- Kui värav valib aadressi, saad lühikese aruande: õhk, temperatuur, gravitatsioon teisel pool ja kas vajad ülikonda.
]] },

{ id = "weapons", title = "Käerelvad", icon = "icon16/bomb.png", body = [[
= Saad need: [Q] > Ascension Gates > Relvad. Mouse1 = põhikasutus, Mouse2 = teine kasutus.
# Goa'uld
- **Zat'nik'tel:** 1. lask uimastab, 2. tapab, 3. teeb kadunuks.
- **Kepprelv:** [Mouse2] valmis, [Mouse1] tuli.
- **Käeseade:** [Mouse1] kasuta, [Mouse2] järgmine režiim.
- **Ravimisseade:** hoia mängija peal, et teda ravida.
- **Mobile DHD:** pane väravale.
# Maa (SGC)
- **P90 (PDW):** [Mouse1] tuli, [Mouse2] sihtimine, [R] laadimine.
- **Beretta:** [Mouse1] tuli, [R] laadimine.
- **GDO:** [Mouse2] kirjuta kood, [Mouse1] saada.
# Teised
- **Ori käerelv / kepp, Wraithi blaster, Rononi relv, Asurani relv.**
- **Tac:** viska, uuesti = lõhkeb. [Mouse2] tapa / uimasta / suits.
- **Parandustööriist:** hoia laeva, värava või DHD peal, et seda parandada.
- **Juhtimistool (Ancient, tekitamise vaheleht Relvad):** [E] istumiseks (vajab laetud ZPM-i oma jaoturis). [1] = sihtmärkide loend: lukusta droonid sihtmärgile või sihi vabalt.
- **Isiklik kilp, Sodani keep:** [Mouse1] sisse, [Mouse2] välja.
- **Mimeetiline kujutusseade:** hoia [Mouse1] enda ees oleval inimesel, et teda kujutada, [Mouse2] projektsioon sisse / välja, [R] kustuta kujutis.
]] },

{ id = "keys", title = "Klahvide muutmine", icon = "icon16/keyboard.png", body = [[
= Enamiku väikelaevade klahve saab muuta Keybinders menüüs.
# Kuidas
1. [Q] > parem pool > Ascension Gates > **Keybinders**.
2. Vali laev.
3. Klõpsa reale üks kord, siis kiiresti teist korda (see muutub oranžiks).
4. Vajuta uut klahvi või hiirenuppu. [Esc] katkestab.
- Laevad: Daedalus, Wraith Dart, Gate Glider, Surmaliugur, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- Ha'tak kasutab sinu tavalisi GMod klahve ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) ja klahvi [V].
- Oma klahvi jaoks: seo see käsuga **agp_hatak_camera** (konsool: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Adminide seaded", icon = "icon16/shield.png", body = [[
= Adminid (ja sina ühe mängija režiimis) muudavad serveri seadeid. Kõik teised näevad neid ainult. Vii hiir seade peale, et näha lühikest vihjet.
# Laevade seaded: [Q] > Ascension Gates > Config > AGP laevad
- **Hijacking:** ainult meeskond / juhtkristalliga / igaüks.
- **Weapons fire at owner and friends:** jah või ei.
- **Weapon + radar range:** kui kaugele kahurid tulistavad ja radar näeb.
- **Radar: most targets shown.**
- **Power crystals strangers may pull:** 0 kuni 15 (vaikimisi 2). Meeskonnal piirangut pole.
- **Ship can be destroyed:** jah (vaikimisi) või ei (kere jääb 1 peale).
- **Hull health (new ships):** 10 000 kuni 1 000 000 (vaikimisi 100 000).
- **Cloak allowed:** jah või ei.
- **Glider bay: lost gliders come back:** jah või ei ja mitme sekundi pärast (vaikimisi 60).
- **Shield bubble (all ships):** ainult tabamusel ning sisse- või väljalülitamisel (vaikimisi) või alati nähtav.
- **Self-destruct countdown (all ships):** 1 kuni 600 sekundit (vaikimisi 5).
# Energia seaded: [Q] > PowerGrid > Seaded > PowerGrid
- **How parts connect:** Manual / Automatic / Mix / Off. Vaata {page:spacegrid|PowerGrid}.
- **Alati PowerGrid:** kasuta PowerGrid'it ka Spacebuildiga (vaja kaarti vahetada).
- **Musta augu energia:** ainult adminid või kõik.
- **Space simulation:** ainult kosmosekaardid / iga kaart / väljas. Vaata {page:lifesupport|Elutugi}.
- **Gate destination report:** sees või väljas.
# Ainult sinule (iga mängija)
- Kaablid, masinate helid, värava aruanne su ekraanil, ühikud kauguse, temperatuuri ja gravitatsiooni jaoks.
]] },

{ id = "problems", title = "Probleemid ja lahendused", icon = "icon16/help.png", body = [[
= Midagi ei tööta? Vaata kõigepealt siit.
# Q menüü ikoonid lähevad roosaks ja miski ei teki
- Sa hoiad [Ctrl] all (või see jäi kinni). [Ctrl] + klõps **valib** ikoone (roosa), selle asemel et neid luua.
- Lahendus: lase [Ctrl] lahti (vajuta seda üks kord), klõpsa ikoonide alal tühjal kohal.
# Klõpsan ikoonil ja miski ei ilmu
- Vaata maad enda ees, mitte kauget taevast.
- Suured laevad ilmuvad kõrgele maapinna kohale või sinu ette. Vaata ringi.
- Adminid saavad osi välja lülitada või piirata (Ascension Gates > Config > Teave ja tänud > Seaded).
# Liugur kukub
- Surmaliugur hoiab kõrgust, kui ei vajuta ühtegi klahvi. Kas see kukub? See võib olla hävinud või kaardilt väljas.
# Ha'taki konsool ütleb "crew only"
- Seda tohivad kasutada ainult omanik ja tema sõbrad. Või võta laev üle juhtkristalliga ({page:hatak_systems|Ha'taki süsteemid}).
# Laeva süsteem ütleb OFFLINE
- Kontrolli kristalle mootoriruumis ja sinisi andmekristalle arvutituumas.
# Jäin ukseavasse või ukse sisse kinni
- Laevasisemuse ukseavad ei lase läbi, kui teine pool on suletud. Ava uks kõigepealt.
- Ikka kinni: noclip ([V]) või ärka uuesti.
# Tööriist näitab teksti nagu #tool.something.name
- Puuduv tekst. Palun ütle meile, milline tööriist.
]] },

},
}
