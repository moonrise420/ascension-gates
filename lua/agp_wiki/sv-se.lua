-- Ascension Gates help (wiki), Svenska. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Hjälp",
    search = "Sök...",
    size = "Textstorlek",
    short = "KORT SAGT",
    intro = "Allt om Ascension Gates: vad delarna gör och hur du styr dem.",
    open = "Öppna hjälpen",
},
pages = {

{ id = "start", title = "Börja här", icon = "icon16/star.png", body = [[
= Ascension Gates är ett Stargate-paket: portar, ringar, skepp, vapen, sköldar och kraft. Den här hjälpen förklarar varje del i korta steg.
# Var allt finns
- **Skapa saker:** tryck [Q], fliken **Ascension Gates** (uppe till vänster). Kategorierna finns till vänster.
- **Verktyg:** [Q], höger sida, fliken **Ascension Gates** (portar, dörrar, vapen, tangenter) och fliken **PowerGrid** (energi, kraft, livsuppehållning).
- **Inställningar:** [Q] > Ascension Gates > Config. Skeppsinställningar: **AGP-skepp**.
- **Kraft- och livsuppehållningsinställningar:** [Q] > PowerGrid > Inställningar > **PowerGrid**.
- **Den här hjälpen:** konsolkommandot **agp_wiki**, eller [Q] > Ascension Gates > Config > **Hjälp (Wiki)**.
# Första stegen
1. Tryck [Q] och öppna fliken **Ascension Gates**.
2. Skapa två Stargates och en DHD (kategori **Stjärnportar och ringar**).
3. Titta på DHD:n och tryck [E]. Slå den andra porten.
4. Gå igenom.
> Håll musen över en inställning: en kort rad säger vad den gör.
# Hjälpens sidor
- {page:gates|Stargate, DHD och ringar}
- {page:hatak|Ha'tak moderskepp}
- {page:glider|Dödsglidare}
- {page:alkesh|Al'kesh och andra skepp}
- {page:spacegrid|PowerGrid: kraft och energi}
- {page:goauldpower|Goa'uld-kraftnav och kristaller}
- {page:lifesupport|Livsuppehållning och rymden}
- {page:weapons|Handvapen}
- {page:keys|Ändra tangenter}
- {page:admin|Inställningar för admins}
- {page:problems|Problem och lösningar}
]] },

{ id = "gates", title = "Stargate, DHD och ringar", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Skapa en port och en DHD, tryck E på DHD:n, slå numret. Ringar flyttar dig mellan ringplattformar i närheten.
# Skaffa dem
- [Q] > Ascension Gates > **Stjärnportar och ringar**: portar, DHD:er, ringar och ringpaneler.
- Verktyg ([Q] > höger sida > Ascension Gates > Tech): Mobil DHD, Superportens DHD, Iris, Goa'uld-iris.
# Slå med DHD:n
1. Ställ DHD:n nära porten (närmare än 1000).
2. Titta på en symbol på DHD:n och tryck [E]: den lyser.
3. Tryck alla symboler i adressen, sedan den stora mittknappen.
- Mittknappen utan tryckta symboler: slagningsmenyn öppnas.
- Mittknappen medan porten är öppen: porten stängs.
# Slå med portmenyn
1. Titta på porten och tryck [E].
2. Skriv adressen eller välj den i listan.
3. Klicka **Dial**. **Abort Dialling / Close Gate** stoppar.
- I samma meny ställer du in portens egen adress, grupp och namn, och om den är privat.
# Iris
- Verktyget **Iris**: vänsterklick på en port. Tangent: numpad [2] växlar den.
- **Iris Computer** (Stjärnportar och ringar): rör den vid en port med iris, [E] = meny (koder, automatisk stängning).
- **GDO** (vapen): högerklick = skriv din kod, vänsterklick = skicka den till en öppen port.
# Ringar
- Ringplattform + ringpanel, nära varandra (panelen fungerar för ringar inom 500).
- [E] på en panelknapp trycker på den. **DIAL** utan siffror = till de närmaste ringarna. Med siffror = till den ringadressen.
- [E] på ringbasen: ge den ett namn (adress).
- **Ring Caller** (vapen): vänsterklick kallar de närmaste ringarna, högerklick öppnar slagningsfönstret.
! Ringar krossar dig om du står still där de kommer ner. Kliv upp på plattformen eller gå därifrån.
]] },

{ id = "hatak", title = "Ha'tak moderskepp", icon = "icon16/house.png", body = [[
= Ett jättelikt Goa'uld-moderskepp. Du kan gå igenom det, flyga det, strida med det och ge det kraft. Insidan är mycket större än utsidan.
# Skapa
- [Q] > Ascension Gates > **Större moderskepp** > Ha'tak.
- Det dyker upp högt över stället du siktar på (eller framför dig om du siktar mot himlen). Det svävar.
# Gå ombord
- **Hangar:** den stora dörren nere på pyramiden. [E] på den öppnar den. Gå in: du är rakt i hangaren inuti.
- Hangardörren utanför och innanför är en och samma dörr: öppen eller stängd på båda sidor. En dörrkontroll (guldplatta) sitter bredvid, innanför och utanför.
- **Ringar:** använd ringar utanför nära skeppet, eller en ringpanel inuti.
- [E] på en dörr eller på den gyllene kontrollen bredvid: dörren öppnas eller stängs.
- En öppen dörr: titta in i dörröppningen och tryck [E] för att stänga den.
> Inifrån kan du alltid gå ut samma väg: hangaröppningen fungerar åt båda hållen.
# Däcken
1. **Hangardäck:** hangar, ringrum, kel'no'reem-rum, Jaffa-baracker, glidarhangar.
2. **Pel'tak (bryggan):** tron, pilotstol, vapen, navigations- och kommandokonsoler.
3. **Portrum:** Stargate med DHD.
4. **Kommandodäck:** bostäder med sarkofag, vapenförråd, datorkärna.
5. **Maskindäck:** maskinrum, fångceller, sköldrum.
- Res mellan däck: [E] på en ringpanel > välj däck.
# Vem får använda det
- **Besättningen** = ägaren och dennes vänner (prop protection-vänner).
- Främlingar kan ta skeppet med **kontrollkristallen**. Se {page:hatak_systems|Ha'tak-system}.
# Mer
- {page:hatak_fly|Flyga, hoppa och vapen}
# Huvudmeny (hela skeppet i ett fönster)
- Öppna den: [1] på tronen, i pilotstolen eller som skytt, eller [E] på kommandokonsolen på pel'tak.
- **SHIP:** skrov, kraft, sköldar, vem som flyger. Hyperrymd, vapen, teknik, adresser.
- **DOORS:** varje dörr: öppna, stäng, lås. Alla dörrar öppna eller stängda på en gång.
- **SYSTEMS:** sköldar, kamouflage, larm, avstängning, skeppslogg, självförstörelse.
- {page:hatak_systems|Kraft, dator, sköldar, skada och rum}
]] },

{ id = "hatak_fly", title = "Ha'tak: flyg, hoppa, strid", icon = "icon16/arrow_up.png", body = [[
= Sitt i pilotstolen på pel'tak. W/S/A/D för att flyga, R för hyperrymd, V för kameran. Vapnen finns på vapenkonsolen.
# Ta rodret
1. Gå till pel'tak (bryggan).
2. Sätt dig på **tronen** ([E]) eller i pilotstolen ([E] på pilotkonsolen).
3. Lämna sätet med [E].
- Tronen går först: är båda tagna flyger tronen.
- [1] öppnar **huvudmenyn** (även som skytt).
- Skeppets framsida är hangarsidan: [W] flyger dit.
# Flygtangenter
- [W] framåt, [S] bakåt.
- [A] / [D] sväng vänster / höger.
- [Space] upp, [Ctrl] ner.
- Håll [Shift]: 4x så snabbt.
- [V]: kamera. Den börjar bakom och ovanför skeppet (mushjul = avstånd). Sedan: sätet, sedan vyn från fören.
- Fönstret på pel'tak visar den riktiga utsikten utanför.
- [R]: hyperrymdsmeny.
- Ingen pilot: skeppet saktar ner och stannar.
> Den som är ombord glider runt medan skeppet flyger.
# Hyperrymdshopp
1. Tryck [R] i pilotsätet (eller [E] på navigationskonsolen).
2. Välj mål: sparade märken, en Stargate eller en annan spelare. Eller skriv x y z.
3. Klicka **Jump**. Skeppet laddar (3 s), ett fönster öppnas, du flyger igenom.
- **Save mark 1/2/3 here** kommer ihåg platsen.
- Kräver 30 % hyperdrivkraft. 8 s paus mellan hopp.
# Vapen
- [E] på **vapenkonsolen**: radar uppifrån och en lista med mål.
- **OFF:** inga skott. **DEFEND:** skjuter bara på det som attackerade skeppet. **AUTO:** även NPC:er och främlingar.
- **FIRE:** en salva mot det valda målet. **KEEP FIRING:** om och om igen.
- **MANUAL (GUNNER)** eller sitt i skyttestolen: du siktar själv.
## Skytteangenter
- Musen siktar, [Mouse1] eld, håll [Mouse2] zoom.
- [R] nästa kanongrupp (topp, fram, sidor, bak, botten).
- [E] lämna.
! Att skjuta tar bort din egen kamouflage.
]] },

{ id = "hatak_systems", title = "Ha'tak-system och rum", icon = "icon16/cog.png", body = [[
= Kristaller ger kraft åt allt. Dra ut en och ett system blir svagare. Datorkärnan styr ringar, dörrar, sensorer och meddelanden.
# Maskinrum: kraftkristaller
- Kraftkärnan (navet) rymmer 3 kristaller. Brickor rymmer 3 kristaller var: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] på en kristall: du drar ut den och bär den.
- [E] vid en ledig plats: du sätter in den.
- Utbrända kristaller (mörka) kommer av hårda träffar. Lägg dem i **reservstället**: de laddas om på 60 s.
- De två naquadah-generatorerna: [E] slår på dem (+15 % var).
- **Navets fjärde arm:** en kristall till (+15 %) eller en **ZPM** (130 %). För ZPM:en nära med gravitationspistolen: den snäpper fast.
- **Teknikkonsol:** visar all kraft. Knapparna skickar mer kraft till ett system.
# Datorkärna: datakristaller
- Blå kristaller i 4 stativ: **Rings**, **Doors**, **Sensors**, **Communication**. 2 av 3 måste sitta i, annars slutar funktionen.
- **Självförstörelse:** 1, 2 eller 4 minuter. **ABORT** stoppar.
- **Skeppslogg:** vad som hänt ombord.
- **Adresser:** alla portar på kartan. **DIAL** slår från portrummet.
- **Säkerhet:** larm på/av, låsning (alla dörrar låsta, besättningen kan fortfarande öppna dem).
# Sköldar och kamouflage
- Sköldrummets konsol eller kommandokonsolen: **RAISE / LOWER SHIELDS**.
- **AUTO:** sköldarna går upp av sig själva när någon attackerar.
- Skölden stoppar alla vapen, även ägarens: skotten stannar vid den gyllene bubblan.
- **CLOAK:** skeppet bleknar bort. Kräver 30 % sköldkraft. Sköldarna går ner under kamouflage.
# Livsuppehållning
- Luft, värme och tyngdkraft ombord, även i rymden.
- Den behöver kraft från kärnan och ett skrov över 10 %. Utan den är det inuti som utanför (ingen luft i rymden).
- Huvudmenyn: status på SHIP, på/av på SYSTEMS.
# Skada
- Bara hårda träffar räknas. Medan skölden håller tar den träffarna.
- Explosioner **inuti** gör dubbelt så ont och bränner kristaller i närheten.
- Larm vid 50, 25 och 10 % skrov. Vid 0 exploderar skeppet (admins kan stänga av det).
- **Reparationsverktyget** reparerar skrovet.
# Rum
- **Glidarhangar:** 4 Dödsglidare. [E] = flyg. Flyg ut genom uppskjutningstunneln. Förlorade glidare kommer tillbaka efter 60 s.
- Uppskjutningstunnlarna har dörrar på insidan och utsidan. De öppnas av sig själva när du flyger mot dem med en glidare. Öppna eller stäng dem i huvudmenyn.
- **Baracker:** [E] på kojkonsolen = du återuppstår ombord. Pansarkista: [E] = +50 pansar (en gång i minuten).
- **Kel'no'reem:** huka ([Ctrl]) på en matta = du läker långsamt.
- **Sarkofag:** [E] för att lägga dig i den och läka.
- **Vapen:** [E] på ett stavvapen på väggen: du tar det (efter 2 minuter finns ett nytt). [E] på en zat-kista: en zat.
- **Fångceller:** [E] på panelen bredvid en cell slår på dess kraftfält (bara besättningen).
# Ta skeppet (kapning)
1. Hitta **kontrollkristallen** gömd någonstans inuti. [E] plockar upp den.
2. Gå till kristallplatsen på pel'tak (höger vägg). [E] startar.
3. Stanna nära i 40 s. Larmet går.
4. Klart: du och dina vänner är den nya besättningen.
- Den gamla besättningen kan stoppa det: [E] på platsen.
]] },

{ id = "glider", title = "Dödsglidare", icon = "icon16/bullet_go.png", body = [[
= Litet Goa'uld-jaktplan. W för att flyga, musen för att styra, Mouse1 för att skjuta. Utan tryckt tangent svävar det.
# Skaffa den
- [Q] > Ascension Gates > **Flotta: Skepp och jaktplan** > Death Glider. Eller i Ha'taks glidarhangar.
# Tangenter
- [E] på glidaren: gå ombord. [E] igen: gå av.
- [W] flyg framåt, [S] sakta bakåt. Håll [Shift]: snabbare.
- Musen: styr.
- [1]: cockpitvy på / av.
- Ingen tangent: den står kvar i luften.
- [Mouse1]: skjut båda stavkanonerna.
- Mushjul: rulla. [Mouse3]: rulla tillbaka till plan.
- Piltangenter: kamerans avstånd och höjd.
- [Backspace]: självförstörelse.
# Fri flygning (serverinställning)
- Med **agp_glider_free_flight 1**: [S] bakåt, [A] / [D] åt sidan, [Space] upp, [Ctrl] ner.
# HUD
- Nere till vänster: skrov, fart, stavkanoner, tangenterna.
- 300 skrov. Vid 0 exploderar den.
> Ändra tangenterna: {page:keys|Ändra tangenter}.
]] },

{ id = "alkesh", title = "Al'kesh och andra skepp", icon = "icon16/bullet_go.png", body = [[
= Alla skepp: E för att gå på och av, W/A/S/D och musen för att flyga, Mouse1 för att skjuta.
# Al'kesh
- [Q] > Ascension Gates > **Flotta: Skepp och jaktplan**. Sikta på marken för att skapa det.
- [W] [S] [A] [D] flyg. [Space] upp, [Ctrl] ner. Håll [Shift]: snabbare.
- [Mouse1] eld. Mushjul rullar, [Mouse3] plan igen.
- [Enter]: landningsläge (håller sig plant).
- [E] gå av. [Backspace] självförstörelse.
# Stora skepp
- Aurora, Destiny, Gate Seeder, O'Neill, Ori-moderskepp, Prometheus, Replikator-moderskepp, Traveler, Wraith-kryssare.
- Samma tangenter som Al'kesh. Dessutom [Mouse2] följ mål, [G] sköld.
# Små skepp
- **Puddle Jumper:** [Mouse1] drönare (öppnar poddarna själv), [Mouse2] håll = drönarna följer ditt sikte, [Alt] kamouflage, [2] dörr, [T] sväva, [G] sköld, [R] ring närmaste port.
- **Tel'tak:** [Mouse2] stavkanoner, [G] sköld, [Alt] kamouflage, håll [R] hyperrymd, [2] dörr. Ringstråle: [Enter] (landningsläge), sedan [Mouse1].
- **F-302:** [Mouse1] kanoner, [Mouse2] robotar, [Alt] motmedel, [B] boost, [2] katapult.
- **Daedalus:** [Mouse1] rälskanoner, [Mouse2] Asgard-stråle, [1] till [8] robotar.
- **Wraith Dart:** [C] samla in människor, [Alt] släpp ut dem.
> Ändra tangenterna: {page:keys|Ändra tangenter}.
]] },

{ id = "spacegrid", title = "PowerGrid: kraft och energi", icon = "icon16/lightning.png", body = [[
= PowerGrid är verktygsfliken för energi. Placera kraftdelar, länka dem, mata dem med ZPM:er eller generatorer.
# Var
- [Q] > höger sida > fliken **PowerGrid**.
- **PowerGrid:** verktyget PowerGrid-delar (alla delar i ett bildrutnät).
- **Energi:** ZPM, ZPM-nav, naquadah-generatorer, Goa'uld-kraftnav, PowerGrid-koppling.
- **Inställningar:** PowerGrid-inställningar och den här hjälpen.
# Placera en del
1. Ta verktyget **PowerGrid-delar**.
2. Klicka på en bild till höger (till exempel en energicell).
3. Sikta där den ska stå. Du ser ett spöke av den.
4. Vänsterklick [Mouse1]: placerad. Högerklick [Mouse2]: placerad vriden 90 grader.
- Sikta på en del och tryck [R]: den delen väljs.
- På ett skepp eller en prop svetsas den fast på det du siktar på (rutan **Weld to what I aim at**).
# Delarna
- **Energiceller (XS till XL):** lagrar energi.
- **Solpaneler:** gör energi när det är öppen himmel över dem.
- **Vindkraftverk:** gör energi, mer ju högre det står.
- **Svart håls-energi:** rymmer alla resurser (bara admins, om det inte tillåts).
- **Kraftnoder:** länkar allt som står på dem. Deras display visar nätverket.
- **Kraftdisplayer:** visar nätverket de är länkade till.
- **Kraftventil:** på = energi flyter mellan två nätverk, av = de är isär. [E] växlar.
- **Resurstankar:** rymmer en resurs (syre, vatten ...). [E] byter resurs medan den är tom.
- **Livsuppehållning:** se {page:lifesupport|Livsuppehållning}.
# Länkning (hur delar delar energi)
- Admins väljer läge: **Manual**, **Automatic**, **Mix** eller **Off** (PowerGrid-inställningar).
- **Manual:** verktyget **PowerGrid-koppling**: vänsterklicka på delarna (de blir blå), högerklicka på delen eller kraftnoden de ska länkas till. [R] rensar valet; [R] på en del tar bort dess länkar.
- **Automatic:** delar som är svetsade ihop delar av sig själva.
- **Off:** allt har fri energi.
! Är Spacebuild installerat? Då används Spacebuilds nätverk. Våra kraftnoder är då Spacebuild-noder: länka med verktyget PowerGrid-koppling. Admins kan slå på **Alltid PowerGrid**.
# Energikällor
- **ZPM:** verktyget **ZPM MK III**. Sätt den i ett ZPM-nav eller ett {page:goauldpower|Goa'uld-kraftnav}.
- **Naquadah-generator:** verktyg i Energy.
- **Goa'uld-kraftkristaller:** i {page:goauldpower|Goa'uld-kraftnavet}.
]] },

{ id = "goauldpower", title = "Goa'uld-kraftnav och kristaller", icon = "icon16/rainbow.png", body = [[
= Ett mässingsnav med en gyllene kraftkärna. Dess 4 armar tar Goa'uld-kraftkristaller eller ZPM:er. Kärnan pulserar starkare ju mer kraft den har.
# Skaffa det
- Verktyg: [Q] > PowerGrid > Energi > **Goa'uld Power Hub + Crystals**.
- Eller skapa-fliken: Ascension Gates > **PowerGrid**.
# Använd det
1. Vänsterklick [Mouse1] med verktyget: ett nav.
2. Sikta på en arm och högerklicka [Mouse2]: en kristall sitter på den armen.
3. ZPM: ta ZPM-verktyget, sikta på en arm, vänsterklicka: ZPM:en sitter på den armen.
4. Länka navet till ditt nätverk som vilken annan del som helst ({page:spacegrid|PowerGrid}).
- Rör en kristall eller ZPM vid en arm (gravitationspistol eller physics gun): den snäpper fast.
- [E] på en kristall eller ZPM: den kommer ut.
- [E] på navet: visar kristaller, ZPM:er och energi i chatten.
- Titta på navet: en liten skylt visar kristaller och energi.
> En ZPM ger tio gånger så mycket kraft som en kristall och driver kärnan hårdare.
# Reglage i verktyget
- **Crystal charge:** hur fulla nya kristaller är (0 till 100 %).
]] },

{ id = "lifesupport", title = "Livsuppehållning och rymden", icon = "icon16/heart.png", body = [[
= I rymden finns ingen luft och det är kallt. Din dräkt skyddar dig en stund. Livsuppehållning gör ett skepp eller ett område säkert.
# När är den på?
- Admins väljer: bara rymdkartor (standard), alla kartor eller av ({page:admin|Inställningar för admins}).
# Din dräkt
- Tre värden: **luft**, **energi**, **kylvätska**. Fulla när du dyker upp.
- Ingen luft eller under vatten: luften minskar. Bra luft: den fylls på igen.
- Kallt: energin minskar. Varmt: kylvätskan minskar.
- Ett värde på 0 gör ont.
- En ruta nere till vänster visas bara när något är fel.
# Life Support Core
- På ett skepp: hela skeppet får luft. [E] växlar.
- Inte på ett skepp: en luftbubbla. [E] ändrar storleken (300 till 2000, sedan av).
- Kräver energi och syre (den gör syre av vatten).
# Fyll på din dräkt
- **Suit Dispenser:** [E] fyller på luft, energi och kylvätska från sitt nätverk.
- **Air Compressor:** syre från andningsbar luft. **Water Pump:** vatten medan den står i vatten.
# Portrapport
- När en port slås får du en kort rapport: luft, temperatur, gravitation på andra sidan, och om du behöver en dräkt.
]] },

{ id = "weapons", title = "Handvapen", icon = "icon16/bomb.png", body = [[
= Skaffa dem i [Q] > Ascension Gates > Vapen. Mouse1 = huvudanvändning, Mouse2 = andra användning.
# Goa'uld
- **Zat'nik'tel:** 1:a skottet bedövar, 2:a dödar, 3:e får målet att försvinna.
- **Stavvapen:** [Mouse2] gör klart, [Mouse1] eld.
- **Handenhet:** [Mouse1] använd, [Mouse2] nästa läge.
- **Läkningsenhet:** håll på en spelare för att läka.
- **Mobile DHD:** lägg den på en port.
# Jorden (SGC)
- **P90 (PDW):** [Mouse1] eld, [Mouse2] sikta, [R] ladda om.
- **Beretta:** [Mouse1] eld, [R] ladda om.
- **GDO:** [Mouse2] skriv kod, [Mouse1] skicka.
# Andra
- **Ori-handvapen / stav, Wraith-blaster, Ronons pistol, Asuran-vapen.**
- **Tac:** kasta, igen = spräng. [Mouse2] döda / bedöva / rök.
- **Reparationsverktyg:** håll på ett skepp, en port eller en DHD för att reparera.
- **Kontrollstol (Uråldrig, spawn-fliken Vapen):** [E] för att sitta (behöver en laddad ZPM i sin hubb). [1] = mållista: lås drönarna på ett mål, eller sikta fritt.
- **Personlig sköld, Sodan-mantel:** [Mouse1] på, [Mouse2] av.
- **Mimetisk avbildningsenhet:** håll [Mouse1] på en person nära framför dig för att avbilda den, [Mouse2] projektion på / av, [R] radera bilden.
]] },

{ id = "keys", title = "Ändra tangenter", icon = "icon16/keyboard.png", body = [[
= Skeppstangenter kan ändras för de flesta små skepp i menyn Keybinders.
# Så gör du
1. [Q] > höger sida > Ascension Gates > **Keybinders**.
2. Välj skeppet.
3. Klicka på en rad en gång, sedan snabbt en gång till (den blir orange).
4. Tryck den nya tangenten eller musknappen. [Esc] avbryter.
- Skepp: Daedalus, Wraith Dart, Gate Glider, Dödsglidare, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- Ha'tak använder dina vanliga GMod-tangenter ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) och [V].
- För en egen tangent: bind den till **agp_hatak_camera** (konsol: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Inställningar för admins", icon = "icon16/shield.png", body = [[
= Admins (och du i singleplayer) ändrar serverinställningarna. Alla andra ser dem bara. Håll musen över en inställning för ett kort tips.
# Skeppsinställningar: [Q] > Ascension Gates > Config > AGP-skepp
- **Hijacking:** bara besättningen / med kontrollkristallen / vem som helst.
- **Weapons fire at owner and friends:** ja eller nej.
- **Weapon + radar range:** hur långt kanonerna skjuter och radarn ser.
- **Radar: most targets shown.**
- **Power crystals strangers may pull:** 0 till 15 (standard 2). Besättningen har ingen gräns.
- **Ship can be destroyed:** ja (standard) eller nej (skrovet stannar på 1).
- **Hull health (new ships):** 10 000 till 1 000 000 (standard 100 000).
- **Cloak allowed:** ja eller nej.
- **Glider bay: lost gliders come back:** ja eller nej, och efter hur många sekunder (standard 60).
- **Shield bubble (all ships):** bara vid träff och när den slås på eller av (standard), eller alltid synlig.
- **Self-destruct countdown (all ships):** 1 till 600 sekunder (standard 5).
# Kraftinställningar: [Q] > PowerGrid > Inställningar > PowerGrid
- **How parts connect:** Manual / Automatic / Mix / Off. Se {page:spacegrid|PowerGrid}.
- **Alltid PowerGrid:** använd PowerGrid även med Spacebuild (kräver kartbyte).
- **Svart håls-energi:** bara admins eller alla.
- **Space simulation:** bara rymdkartor / alla kartor / av. Se {page:lifesupport|Livsuppehållning}.
- **Gate destination report:** på eller av.
# Bara för dig (varje spelare)
- Kablar, maskinljud, portrapport på din skärm, enheter för avstånd, temperatur och gravitation.
]] },

{ id = "problems", title = "Problem och lösningar", icon = "icon16/help.png", body = [[
= Fungerar något inte? Titta här först.
# Ikonerna i Q-menyn blir rosa och inget skapas
- Du håller [Ctrl] (eller så fastnade den). [Ctrl] + klick **markerar** ikoner (rosa) i stället för att skapa dem.
- Lösning: släpp [Ctrl] (tryck den en gång), klicka på en tom plats i ikonområdet.
# Jag klickar på en ikon och inget dyker upp
- Titta på marken framför dig, inte på den avlägsna himlen.
- Stora skepp dyker upp högt över marken eller framför dig. Titta dig omkring.
- Admins kan stänga av delar eller begränsa dem (Ascension Gates > Config > Om & tack > Inställningar).
# Glidaren faller
- Dödsglidaren håller sin höjd när du inte trycker någon tangent. Faller den? Den kan vara förstörd eller utanför kartan.
# En Ha'tak-konsol säger "crew only"
- Bara ägaren och dennes vänner får använda den. Eller ta skeppet med kontrollkristallen ({page:hatak_systems|Ha'tak-system}).
# Ett skeppssystem säger OFFLINE
- Kontrollera kristallerna i maskinrummet och de blå datakristallerna i datorkärnan.
# Jag sitter fast i en dörröppning eller dörr
- Dörröppningar i skeppsinteriörer släpper inte igenom dig när andra sidan är stängd. Öppna dörren först.
- Sitter du fortfarande fast: noclip ([V]) eller återuppstå.
# Ett verktyg visar text som #tool.something.name
- En saknad text. Berätta för oss vilket verktyg.
]] },

},
}
