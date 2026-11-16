-- Ascension Gates help (wiki), Čeština. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Nápověda",
    search = "Hledat...",
    size = "Velikost textu",
    short = "STRUČNĚ",
    intro = "Vše o Ascension Gates: co části dělají a jak je ovládáš.",
    open = "Otevřít nápovědu",
},
pages = {

{ id = "start", title = "Začni tady", icon = "icon16/star.png", body = [[
= Ascension Gates je balíček Stargate: brány, kruhy, lodě, zbraně, štíty a energie. Tato nápověda vysvětluje každou část v krátkých krocích.
# Kde co je
- **Vytvoř věci:** stiskni [Q], záložka **Ascension Gates** (vlevo nahoře). Kategorie jsou vlevo.
- **Nástroje:** [Q], vpravo, záložka **Ascension Gates** (brány, dveře, zbraně, klíče) a záložka **PowerGrid** (energie, napájení, podpora života).
- **Nastavení:** [Q] > Ascension Gates > Config. Nastavení lodí: **Lodě AGP**.
- **Nastavení energie a podpory života:** [Q] > PowerGrid > Nastavení > **PowerGrid**.
- **Tato nápověda:** příkaz do konzole **agp_wiki**, nebo [Q] > Ascension Gates > Config > **Nápověda (Wiki)**.
# První kroky
1. Stiskni [Q] a otevři záložku **Ascension Gates**.
2. Vytvoř dvě Stargate brány a jedno DHD (kategorie **Brány a Kruhy**).
3. Podívej se na DHD a stiskni [E]. Vytoč druhou bránu.
4. Projdi bránou.
> Najeď myší na nastavení: krátký řádek ti řekne, co dělá.
# Stránky této nápovědy
- {page:gates|Stargate, DHD a kruhy}
- {page:hatak|Mateřská loď Ha'tak}
- {page:glider|Death Glider}
- {page:alkesh|Al'kesh a další lodě}
- {page:spacegrid|PowerGrid: napájení a energie}
- {page:goauldpower|Goa'uldský energetický uzel a krystaly}
- {page:lifesupport|Podpora života a vesmír}
- {page:weapons|Ruční zbraně}
- {page:keys|Změna kláves}
- {page:admin|Nastavení pro adminy}
- {page:problems|Problémy a řešení}
]] },

{ id = "gates", title = "Stargate, DHD a kruhy", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Vytvoř bránu a DHD, stiskni E na DHD, vytoč adresu. Kruhy tě přenesou mezi blízkými platformami kruhů.
# Kde je vzít
- [Q] > Ascension Gates > **Brány a Kruhy**: brány, DHD, kruhy a panely kruhů.
- Nástroje ([Q] > vpravo > Ascension Gates > Tech): Přenosné DHD, DHD Superbrány, Iris, Goa'uldká Iris.
# Vytáčení přes DHD
1. Postav DHD blízko brány (blíž než 1000).
2. Podívej se na symbol na DHD a stiskni [E]: rozsvítí se.
3. Stiskni všechny symboly adresy, potom velké střední tlačítko.
- Střední tlačítko bez stisknutých symbolů: otevře se menu vytáčení.
- Střední tlačítko u otevřené brány: brána se zavře.
# Vytáčení přes menu brány
1. Podívej se na bránu a stiskni [E].
2. Napiš adresu nebo ji vyber ze seznamu.
3. Klikni na **Dial**. **Abort Dialling / Close Gate** to zastaví.
- V tomto menu nastavíš také vlastní adresu brány, skupinu, jméno a soukromí.
# Clona
- Nástroj **Clona**: levý klik na bránu. Klávesy: numerická [2] ji přepíná.
- **Počítač clony** (Brány a Kruhy): přiložíš ho k bráně s clonou, [E] = menu (kódy, automatické zavření).
- **GDO** (zbraň): pravý klik = napsat svůj kód, levý klik = poslat ho na otevřenou bránu.
# Kruhy
- Platforma kruhů + panel kruhů, blízko sebe (panel funguje pro kruhy do 500).
- [E] na tlačítku panelu ho stiskne. **DIAL** bez číslic = k nejbližším kruhům. S číslicemi = ke kruhům s touto adresou.
- [E] na základně kruhů: dej jim jméno (adresu).
- **Ring Caller** (zbraň): levý klik zavolá nejbližší kruhy, pravý klik otevře okno vytáčení.
! Kruhy tě rozdrtí, když stojíš na místě, kam sjíždějí. Vstup na plošinu nebo od ní odejdi.
]] },

{ id = "hatak", title = "Mateřská loď Ha'tak", icon = "icon16/house.png", body = [[
= Obří goa'uldská mateřská loď. Můžeš po ní chodit, létat s ní, bojovat a napájet ji. Uvnitř je mnohem větší než zvenku.
# Vytvoření
- [Q] > Ascension Gates > **Větší mateřské lodě** > Ha'tak.
- Objeví se vysoko nad místem, kam míříš (nebo před tebou, když míříš na oblohu). Vznáší se.
# Jak se dostat dovnitř
- **Hangár:** velké dveře dole na pyramidě. [E] na ně je otevře. Vejdi: jsi rovnou v hangáru uvnitř.
- Dveře hangáru venku a uvnitř jsou jedny dveře: otevřené nebo zavřené z obou stran. Ovládání (zlatá destička) je vedle nich zevnitř i zvenku.
- **Kruhy:** použij kruhy venku u lodi, nebo panel kruhů uvnitř.
- [E] na dveřích nebo na zlatém ovladači vedle nich: dveře se otevřou nebo zavřou.
- Otevřené dveře: podívej se do průchodu a stiskni [E], dveře se zavřou.
> Zevnitř můžeš vždy odejít stejnou cestou: otvor hangáru funguje oběma směry.
# Paluby
1. **Hangárová paluba:** hangár, místnost s kruhy, místnost kel'no'reem, kasárna Jaffů, hangár pro glidery.
2. **Pel'tak (můstek):** trůn, pilotní křeslo, zbraně, navigační a velitelské konzole.
3. **Místnost s bránou:** Stargate s DHD.
4. **Velitelská paluba:** kajuty se sarkofágem, zbrojnice, jádro počítače.
5. **Strojovna:** strojovna, cely, místnost štítů.
- Cesta mezi palubami: [E] na panelu kruhů > vyber palubu.
# Kdo může loď používat
- **Posádka** = majitel a jeho přátelé (přátelé z ochrany props).
- Cizí ji mohou převzít pomocí **řídicího krystalu**. Viz {page:hatak_systems|Systémy Ha'taku}.
# Více
- {page:hatak_fly|Létání, skok a zbraně}
# Hlavní menu (celá loď v jednom okně)
- Otevři ho: [1] na trůnu, v pilotním křesle nebo jako střelec, nebo [E] na velitelské konzoli na pel'taku.
- **SHIP:** trup, energie, štíty, kdo letí. Hyperprostor, zbraně, strojovna, adresy.
- **DOORS:** všechny dveře: otevřít, zavřít, zamknout. Všechny dveře naráz otevřené nebo zavřené.
- **SYSTEMS:** štíty, maskování, poplach, uzamčení, lodní deník, sebedestrukce.
- {page:hatak_systems|Energie, počítač, štíty, poškození a místnosti}
]] },

{ id = "hatak_fly", title = "Ha'tak: leť, skákej, bojuj", icon = "icon16/arrow_up.png", body = [[
= Sedni do pilotního křesla na pel'taku. W/S/A/D = let, R = hyperprostor, V = kamera. Zbraně jsou na konzoli zbraní.
# Převezmi řízení
1. Jdi na pel'tak (můstek).
2. Sedni na **trůn** ([E]) nebo do pilotního křesla ([E] na pilotní konzoli).
3. Ze sedadla vystoupíš klávesou [E].
- Trůn má přednost: když jsou obsazené obě, letí trůn.
- [1] otevře **hlavní menu** (také v režimu střelce).
- Přední strana lodi je strana hangáru: [W] letí tím směrem.
# Klávesy letu
- [W] vpřed, [S] vzad.
- [A] / [D] zatáčení vlevo / vpravo.
- [Space] nahoru, [Ctrl] dolů.
- Drž [Shift]: 4x rychleji.
- [V]: kamera. Začíná za lodí a nad ní (kolečko myši = vzdálenost). Pak: sedadlo, potom pohled ze špičky lodi.
- Okno na pel'taku ukazuje skutečný výhled ven.
- [R]: menu hyperprostoru.
- Bez pilota: loď zpomalí a zastaví.
> Kdo je na palubě, neklouže, když loď letí.
# Skok do hyperprostoru
1. Stiskni [R] v pilotním křesle (nebo [E] na navigační konzoli).
2. Vyber cíl: uložené značky, Stargate nebo jiného hráče. Nebo napiš x y z.
3. Klikni na **Jump**. Loď se nabíjí (3 s), otevře se okno, proletíš jím.
- **Save mark 1/2/3 here** si zapamatuje místo.
- Potřebuje 30 % výkonu hyperpohonu. Mezi skoky je pauza 8 s.
# Zbraně
- [E] na **konzoli zbraní**: radar shora a seznam cílů.
- **OFF:** žádná střelba. **DEFEND:** střílí jen na to, co zaútočilo na loď. **AUTO:** i na NPC a cizí.
- **FIRE:** jedna salva na vybraný cíl. **KEEP FIRING:** pořád dokola.
- **MANUAL (GUNNER)** nebo se posaď do křesla střelce: míříš sám.
## Klávesy střelce
- Myš míří, [Mouse1] střelba, drž [Mouse2] pro přiblížení.
- [R] další skupina děl (nahoře, vpředu, po stranách, vzadu, dole).
- [E] odejít.
! Střelba ti vypne vlastní maskování.
]] },

{ id = "hatak_systems", title = "Systémy a místnosti Ha'taku", icon = "icon16/cog.png", body = [[
= Krystaly napájejí všechno. Vytáhni jeden a systém zeslábne. Jádro počítače řídí kruhy, dveře, senzory a zprávy.
# Strojovna: energetické krystaly
- Energetické jádro (hub) drží 3 krystaly. Podnosy drží po 3 krystalech: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] na krystalu: vytáhneš ho a neseš ho.
- [E] u volného slotu: vložíš ho.
- Spálené krystaly (tmavé) vznikají od tvrdých zásahů. Dej je do **záložního stojanu**: nabijí se za 60 s.
- Dva naquadahové generátory: [E] je zapne (+15 % každý).
- **Čtvrté rameno hubu:** jeden krystal navíc (+15 %) nebo **ZPM** (130 %). Přiblíž ZPM gravitační zbraní: zacvakne se.
- **Inženýrská konzole:** ukazuje všechnu energii. Tlačítka pošlou víc energie jednomu systému.
# Jádro počítače: datové krystaly
- Modré krystaly ve 4 stojanech: **Rings**, **Doors**, **Sensors**, **Communication**. Ze 3 musí být zasunuté 2, jinak ta funkce přestane.
- **Autodestrukce:** 1, 2 nebo 4 minuty. **ABORT** ji zastaví.
- **Lodní deník:** co se stalo na palubě.
- **Adresy:** každá brána na mapě. **DIAL** vytáčí z místnosti s bránou.
- **Bezpečnost:** poplach zap/vyp, uzamčení (všechny dveře zamčené, posádka je ale může otevřít).
# Štíty a maskování
- Konzole v místnosti štítů nebo velitelská konzole: **RAISE / LOWER SHIELDS**.
- **AUTO:** štíty se zvednou samy, když někdo zaútočí.
- Štít zastaví každou zbraň, i majitelovu: výstřely se zastaví na zlaté bublině.
- **CLOAK:** loď zmizí. Potřebuje 30 % výkonu štítů. Při maskování štíty klesnou.
# Podpora života
- Vzduch, teplo a gravitace na palubě, i ve vesmíru.
- Potřebuje energii z jádra a trup nad 10 %. Bez ní je uvnitř jako venku (ve vesmíru bez vzduchu).
- Hlavní menu: stav v SHIP, zapnutí/vypnutí v SYSTEMS.
# Poškození
- Počítají se jen těžké zásahy. Dokud štít drží, přijímá zásahy on.
- Výbuchy **uvnitř** bolí dvakrát víc a spalují krystaly poblíž.
- Poplach při 50, 25 a 10 % trupu. Při 0 loď exploduje (admini to mohou vypnout).
- **Opravný nástroj** opraví trup.
# Místnosti
- **Hangár pro glidery:** 4 Death Glidery. [E] = leť. Vyleť startovním tunelem. Ztracené glidery se vrátí za 60 s.
- Startovní tunely mají dveře uvnitř i venku. Otevřou se samy, když k nim letíš gliderem. Otevři nebo zavři je v hlavním menu.
- **Kasárna:** [E] na konzoli lůžka = respawnuješ na palubě. Truhla s brněním: [E] = +50 brnění (jednou za minutu).
- **Kel'no'reem:** dřepni si ([Ctrl]) na podložce = pomalu se léčíš.
- **Sarkofág:** [E] pro lehnutí a léčení.
- **Zbraně:** [E] na hůlkovou zbraň na zdi: vezmeš si ji (za 2 minuty je tam nová). [E] na truhlu se zaty: zat.
- **Cely:** [E] na panelu vedle cely přepne její silové pole (jen posádka).
# Převzetí lodi (hijack)
1. Najdi **řídicí krystal** ukrytý někde uvnitř. [E] ho zvedne.
2. Jdi ke slotu krystalu na pel'taku (pravá stěna). [E] to spustí.
3. Zůstaň poblíž 40 s. Spustí se poplach.
4. Hotovo: ty a tvoji přátelé jste nová posádka.
- Stará posádka to může zastavit: [E] na slotu.
]] },

{ id = "glider", title = "Death Glider", icon = "icon16/bullet_go.png", body = [[
= Malá goa'uldská stíhačka. W = let, myš = řízení, Mouse1 = střelba. Bez stisknuté klávesy se vznáší.
# Kde ho vzít
- [Q] > Ascension Gates > **Flotila: Lodě a stíhačky** > Death Glider. Nebo v hangáru pro glidery na Ha'taku.
# Klávesy
- [E] na gliderovi: nastoupit. [E] znovu: vystoupit.
- [W] let vpřed, [S] pomalu vzad. Drž [Shift]: rychleji.
- Myš: řízení.
- [1]: pohled z kokpitu zap / vyp.
- Žádná klávesa: drží místo ve vzduchu.
- [Mouse1]: střelba z obou hůlkových děl.
- Kolečko myši: náklon. [Mouse3]: zpět do roviny.
- Šipky: vzdálenost a výška kamery.
- [Backspace]: autodestrukce.
# Volný let (nastavení serveru)
- S **agp_glider_free_flight 1**: [S] vzad, [A] / [D] do stran, [Space] nahoru, [Ctrl] dolů.
# HUD
- Vlevo dole: trup, rychlost, hůlková děla, klávesy.
- 300 trupu. Při 0 exploduje.
> Změna kláves: {page:keys|Změna kláves}.
]] },

{ id = "alkesh", title = "Al'kesh a další lodě", icon = "icon16/bullet_go.png", body = [[
= Každá loď: E = nastoupit a vystoupit, W/A/S/D a myš = let, Mouse1 = střelba.
# Al'kesh
- [Q] > Ascension Gates > **Flotila: Lodě a stíhačky**. Zamiř na zem, aby se objevil.
- [W] [S] [A] [D] let. [Space] nahoru, [Ctrl] dolů. Drž [Shift]: rychleji.
- [Mouse1] střelba. Kolečko myši náklon, [Mouse3] zase do roviny.
- [Enter]: režim přistání (drží rovinu).
- [E] vystoupit. [Backspace] autodestrukce.
# Velké lodě
- Aurora, Destiny, Gate Seeder, O'Neill, mateřská loď Ori, Prometheus, mateřská loď Replikátorů, loď Poutníků, křižník Wraithů.
- Stejné klávesy jako Al'kesh. Navíc [Mouse2] sledovat cíl, [G] štít.
# Malé lodě
- **Puddle Jumper:** [Mouse1] drony (moduly se otevřou samy), [Mouse2] držet = drony sledují tvůj zaměřovač, [Alt] maskování, [2] dveře, [T] vznášení, [G] štít, [R] vytočit nejbližší bránu.
- **Tel'tak:** [Mouse2] tyčové kanóny, [G] štít, [Alt] maskování, drž [R] hyperprostor, [2] dveře. Kruhový paprsek: [Enter] (režim přistání), pak [Mouse1].
- **F-302:** [Mouse1] kulomety, [Mouse2] rakety, [Alt] světlice, [B] zrychlení, [2] katapultovat.
- **Daedalus:** [Mouse1] railguny, [Mouse2] paprsek Asgardů, [1] až [8] rakety.
- **Wraith Dart:** [C] sbírat lidi, [Alt] vypustit je.
> Změna kláves: {page:keys|Změna kláves}.
]] },

{ id = "spacegrid", title = "PowerGrid: napájení a energie", icon = "icon16/lightning.png", body = [[
= PowerGrid je záložka nástrojů pro energii. Umísti napájecí části, propoj je, napájej je ZPM nebo generátory.
# Kde
- [Q] > vpravo > záložka **PowerGrid**.
- **PowerGrid:** nástroj Díly PowerGrid (všechny části v jedné mřížce obrázků).
- **Energie:** ZPM, huby ZPM, naquadahové generátory, goa'uldský energetický uzel, Propojení PowerGrid.
- **Nastavení:** nastavení PowerGrid a tato nápověda.
# Umístění části
1. Vezmi nástroj **Díly PowerGrid**.
2. Klikni na obrázek vpravo (například energetický článek).
3. Zamiř tam, kde má stát. Uvidíš její přízrak.
4. Levý klik [Mouse1]: umístěno. Pravý klik [Mouse2]: umístěno otočené o 90 stupňů.
- Zamiř na část a stiskni [R]: tato část je vybrána.
- Na lodi nebo propu se přivaří k tomu, na co míříš (pole **Weld to what I aim at**).
# Části
- **Energetické články (XS až XL):** ukládají energii.
- **Solární panely:** vyrábějí energii, když nad nimi je otevřená obloha.
- **Větrná turbína:** vyrábí energii, víc čím výš stojí.
- **Energie černé díry:** drží všechny suroviny (jen pro adminy, pokud není povoleno jinak).
- **Napájecí uzly:** propojí vše, co je na nich umístěno. Jejich displej ukazuje síť.
- **Napájecí displeje:** ukazují síť, ke které jsou připojeny.
- **Napájecí ventil:** zap = energie teče mezi dvěma sítěmi, vyp = jsou oddělené. [E] přepíná.
- **Nádrže na suroviny:** drží jednu surovinu (kyslík, voda ...). [E] změní surovinu, dokud je nádrž prázdná.
- **Podpora života:** viz {page:lifesupport|Podpora života}.
# Propojování (jak části sdílí energii)
- Admini vybírají režim: **Manual**, **Automatic**, **Mix** nebo **Off** (nastavení PowerGrid).
- **Manual:** nástroj **Propojení PowerGrid**: levý klik na části (zmodrají), pravý klik na část nebo energetický uzel, se kterým se spojí. [R] zruší výběr; [R] na části odebere její spojení.
- **Automatic:** části přivařené k sobě sdílejí samy.
- **Off:** všechno má volnou energii.
! Máš nainstalovaný Spacebuild? Pak se používá síť Spacebuildu. Naše energetické uzly jsou pak uzly Spacebuildu: propoj je pomocí nástroje Propojení PowerGrid. Admini mohou zapnout **Vždy PowerGrid**.
# Zdroje energie
- **ZPM:** nástroj **ZPM MK III**. Vlož ho do hubu ZPM nebo do {page:goauldpower|Goa'uldského energetického uzlu}.
- **Naquadahový generátor:** nástroj v Energy.
- **Goa'uldské energetické krystaly:** v {page:goauldpower|Goa'uldském energetickém uzlu}.
]] },

{ id = "goauldpower", title = "Goa'uldský energetický uzel a krystaly", icon = "icon16/rainbow.png", body = [[
= Mosazný hub se zlatým energetickým jádrem. Jeho 4 ramena přijímají goa'uldské energetické krystaly nebo ZPM. Čím víc energie, tím jasněji jádro pulzuje.
# Kde ho vzít
- Nástroj: [Q] > PowerGrid > Energie > **Goa'uld Power Hub + Crystals**.
- Nebo záložka vytváření: Ascension Gates > **PowerGrid**.
# Použití
1. Levý klik [Mouse1] nástrojem: hub.
2. Zamiř na rameno a pravý klik [Mouse2]: krystal se usadí na tom rameni.
3. ZPM: vezmi nástroj ZPM, zamiř na rameno, levý klik: ZPM se usadí na tom rameni.
4. Propoj hub se svou sítí jako každou jinou část ({page:spacegrid|PowerGrid}).
- Přiblíž krystal nebo ZPM k ramenu (gravitační nebo fyzikální zbraní): zacvakne se.
- [E] na krystalu nebo ZPM: vyjde ven.
- [E] na hubu: ukáže krystaly, ZPM a energii v chatu.
- Podívej se na hub: malá tabulka ukazuje krystaly a energii.
> ZPM dává desetkrát víc energie než krystal a pohání jádro silněji.
# Posuvník v nástroji
- **Crystal charge:** jak plné jsou nové krystaly (0 až 100 %).
]] },

{ id = "lifesupport", title = "Podpora života a vesmír", icon = "icon16/heart.png", body = [[
= Ve vesmíru není vzduch a je zima. Skafandr tě chvíli chrání. Podpora života udělá loď nebo oblast bezpečnou.
# Kdy je zapnutá?
- Admini vybírají: jen vesmírné mapy (výchozí), každá mapa, nebo vypnuto ({page:admin|Nastavení pro adminy}).
# Tvůj skafandr
- Tři hodnoty: **vzduch**, **energie**, **chladivo**. Po spawnu jsou plné.
- Bez vzduchu nebo pod vodou: vzduch klesá. Dobrý vzduch: zase se plní.
- Zima: klesá energie. Horko: klesá chladivo.
- Hodnota 0 ti ubližuje.
- Okénko vlevo dole se ukáže jen tehdy, když je něco špatně.
# Life Support Core
- Na lodi: vzduch dostane celá loď. [E] přepíná.
- Ne na lodi: bublina vzduchu. [E] mění velikost (300 až 2000, potom vypnuto).
- Potřebuje energii a kyslík (kyslík vyrábí z vody).
# Dopln skafandr
- **Dávkovač skafandrů:** [E] doplní vzduch, energii a chladivo ze své sítě.
- **Vzduchový kompresor:** kyslík z dýchatelného vzduchu. **Vodní pumpa:** voda, když stojí ve vodě.
# Zpráva o bráně
- Když brána vytáčí, dostaneš krátkou zprávu: vzduch, teplota, gravitace na druhé straně a zda potřebuješ skafandr.
]] },

{ id = "weapons", title = "Ruční zbraně", icon = "icon16/bomb.png", body = [[
= Vezmi je v [Q] > Ascension Gates > Zbraně. Mouse1 = hlavní použití, Mouse2 = druhé použití.
# Goa'uldi
- **Zat'nik'tel:** 1. rána omráčí, 2. zabije, 3. způsobí zmizení.
- **Hůlková zbraň:** [Mouse2] připravit, [Mouse1] střelba.
- **Ruční zařízení:** [Mouse1] použít, [Mouse2] další režim.
- **Léčivé zařízení:** drž na hráči, aby se léčil.
- **Mobilní DHD:** polož ho na bránu.
# Země (SGC)
- **P90 (PDW):** [Mouse1] střelba, [Mouse2] míření, [R] nabít.
- **Beretta:** [Mouse1] střelba, [R] nabít.
- **GDO:** [Mouse2] napsat kód, [Mouse1] poslat.
# Ostatní
- **Ruční zbraň / hůl Ori, blaster Wraithů, Rononova zbraň, zbraň Asurana.**
- **Tac:** hoď, znovu = výbuch. [Mouse2] zabít / omráčit / kouř.
- **Opravný nástroj:** drž na lodi, bráně nebo DHD pro opravu.
- **Ovládací křeslo (Antikové, záložka Zbraně):** [E] pro sednutí (potřebuje nabitý ZPM ve svém hubu). [1] = seznam cílů: zaměř drony na cíl, nebo miř volně.
- **Osobní štít, plášť Sodanů:** [Mouse1] zap, [Mouse2] vyp.
- **Mimetické zobrazovací zařízení:** drž [Mouse1] na osobě těsně před sebou a sejmeš její obraz, [Mouse2] projekce zap / vyp, [R] smazat obraz.
]] },

{ id = "keys", title = "Změna kláves", icon = "icon16/keyboard.png", body = [[
= Klávesy většiny malých lodí můžeš změnit v menu Keybinders.
# Jak
1. [Q] > vpravo > Ascension Gates > **Keybinders**.
2. Vyber loď.
3. Klikni na řádek jednou, potom rychle podruhé (zbarví se oranžově).
4. Stiskni novou klávesu nebo tlačítko myši. [Esc] zruší.
- Lodě: Daedalus, Wraith Dart, Gate Glider, Death Glider, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- Ha'tak používá tvoje běžné klávesy GMod ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) a [V].
- Pro vlastní klávesu: přiřaď ji k **agp_hatak_camera** (konzole: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Nastavení pro adminy", icon = "icon16/shield.png", body = [[
= Admini (a ty v singleplayeru) mění nastavení serveru. Ostatní je jen vidí. Najeď na nastavení pro krátkou radu.
# Nastavení lodí: [Q] > Ascension Gates > Config > Lodě AGP
- **Převzetí lodi:** jen posádka / s řídicím krystalem / kdokoli.
- **Zbraně střílejí na majitele a přátele:** ano nebo ne.
- **Dosah zbraní a radaru:** jak daleko děla střílejí a radar vidí.
- **Radar: nejvíce zobrazených cílů.**
- **Energetické krystaly, které mohou cizí vytáhnout:** 0 až 15 (výchozí 2). Posádka nemá limit.
- **Loď lze zničit:** ano (výchozí) nebo ne (trup zůstane na 1).
- **Zdraví trupu (nové lodě):** 10 000 až 1 000 000 (výchozí 100 000).
- **Maskování povoleno:** ano nebo ne.
- **Hangár pro glidery: ztracené glidery se vrátí:** ano nebo ne, a za kolik sekund (výchozí 60).
- **Shield bubble (all ships):** jen při zásahu a při zapnutí nebo vypnutí (výchozí), nebo vždy viditelná.
- **Self-destruct countdown (all ships):** 1 až 600 sekund (výchozí 5).
# Nastavení energie: [Q] > PowerGrid > Nastavení > PowerGrid
- **Jak se části propojují:** Manual / Automatic / Mix / Off. Viz {page:spacegrid|PowerGrid}.
- **Vždy PowerGrid:** použít PowerGrid i se Spacebuildem (potřebuje změnu mapy).
- **Energie černé díry:** jen admini nebo všichni.
- **Simulace vesmíru:** jen vesmírné mapy / každá mapa / vypnuto. Viz {page:lifesupport|Podpora života}.
- **Zpráva o cíli brány:** zap nebo vyp.
# Jen pro tebe (každý hráč)
- Kabely, zvuky strojů, zpráva o bráně na tvé obrazovce, jednotky pro vzdálenost, teplotu a gravitaci.
]] },

{ id = "problems", title = "Problémy a řešení", icon = "icon16/help.png", body = [[
= Něco nefunguje? Podívej se nejdřív sem.
# Ikony v menu Q zrůžoví a nic se nevytvoří
- Držíš [Ctrl] (nebo se zasekla). [Ctrl] + klik **vybírá** ikony (růžové) místo vytváření.
- Řešení: pusť [Ctrl] (stiskni ho jednou), klikni na prázdné místo v oblasti ikon.
# Kliknu na ikonu a nic se neobjeví
- Dívej se na zem před sebou, ne na vzdálenou oblohu.
- Velké lodě se objeví vysoko nad zemí nebo před tebou. Rozhlédni se.
- Admini mohou části vypnout nebo omezit (Ascension Gates > Config > O balíčku a autoři > Nastavení).
# Glider padá
- Death Glider drží výšku, když nestiskneš žádnou klávesu. Padá? Možná je zničený nebo mimo mapu.
# Konzole Ha'taku hlásí "crew only"
- Smí ji používat jen majitel a jeho přátelé. Nebo převezmi loď pomocí řídicího krystalu ({page:hatak_systems|Systémy Ha'taku}).
# Systém lodi hlásí OFFLINE
- Zkontroluj krystaly ve strojovně a modré datové krystaly v jádru počítače.
# Postava se zasekla ve dveřích nebo průchodu
- Průchody v interiérech lodí tě nepustí, když je druhá strana zavřená. Nejdřív otevři dveře.
- Pořád se zasekává: noclip ([V]) nebo respawn.
# Nástroj ukazuje text jako #tool.something.name
- Chybí text. Prosím, napiš nám, který nástroj to je.
]] },

},
}
