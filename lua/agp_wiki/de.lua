-- Ascension Gates Hilfe (Wiki), Deutsch. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Hilfe",
    search = "Suchen...",
    size = "Textgröße",
    short = "KURZ",
    intro = "Alles über Ascension Gates: was die Teile tun und wie du sie steuerst.",
    open = "Hilfe öffnen",
},
pages = {

{ id = "start", title = "Hier starten", icon = "icon16/star.png", body = [[
= Ascension Gates ist ein Stargate-Paket: Gates, Ringe, Schiffe, Waffen, Schilde und Energie. Diese Hilfe erklärt jeden Teil in kurzen Schritten.
# Wo ist was
- **Dinge spawnen:** Drücke [Q], Tab **Ascension Gates** (oben links). Die Kategorien sind links.
- **Werkzeuge:** [Q], rechte Seite, Tab **Ascension Gates** (Gates, Türen, Waffen, Tastenbelegung) und Tab **PowerGrid** (Energie, Power, Lebenserhaltung).
- **Einstellungen:** [Q] > Ascension Gates > Config. Schiffs-Einstellungen: **AGP-Schiffe**.
- **Power- und Lebenserhaltungs-Einstellungen:** [Q] > PowerGrid > Einstellungen > **PowerGrid**.
- **Diese Hilfe:** Konsolenbefehl **agp_wiki**, oder [Q] > Ascension Gates > Config > **Hilfe (Wiki)**.
# Erste Schritte
1. Drücke [Q] und öffne den Tab **Ascension Gates**.
2. Spawne zwei Stargates und ein DHD (Kategorie **Gates und Ringe**).
3. Sieh das DHD an und drücke [E]. Wähle das andere Gate an.
4. Geh durch.
> Halte die Maus über eine Einstellung: Eine kurze Zeile sagt dir, was sie tut.
# Die Seiten dieser Hilfe
- {page:gates|Stargates, DHD und Ringe}
- {page:hatak|Ha'tak-Mutterschiff}
- {page:glider|Todesgleiter}
- {page:alkesh|Al'kesh und andere Schiffe}
- {page:spacegrid|PowerGrid: Power und Energie}
- {page:goauldpower|Goa'uld-Powerhub und Kristalle}
- {page:lifesupport|Lebenserhaltung und Weltraum}
- {page:weapons|Handwaffen}
- {page:keys|Tasten ändern}
- {page:admin|Einstellungen für Admins}
- {page:problems|Probleme und Lösungen}
]] },

{ id = "gates", title = "Stargates, DHD und Ringe", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Spawne ein Gate und ein DHD, drücke E am DHD, wähle an. Ringe bringen dich zwischen Ringplattformen in der Nähe.
# So bekommst du sie
- [Q] > Ascension Gates > **Gates und Ringe**: Gates, DHDs, Ringe und Ringpanels.
- Werkzeuge ([Q] > rechte Seite > Ascension Gates > Tech): Mobiles DHD, Supergate DHD, Iris, Goa'uld Iris.
# Anwählen mit dem DHD
1. Stelle das DHD nahe ans Gate (näher als 1000 Einheiten).
2. Sieh ein Symbol am DHD an und drücke [E]: Es leuchtet.
3. Drücke alle Symbole der Adresse, dann den großen Knopf in der Mitte.
- Mittelknopf ohne gedrückte Symbole: Das Wahlmenü öffnet sich.
- Mittelknopf bei offenem Gate: Das Gate schließt sich.
# Anwählen mit dem Gate-Menü
1. Sieh das Gate an und drücke [E].
2. Tippe die Adresse oder wähle sie aus der Liste.
3. Klicke **Dial**. **Abort Dialling / Close Gate** stoppt es.
- Im selben Menü stellst du Adresse, Gruppe und Namen des Gates ein, und ob es privat ist.
# Iris
- Werkzeug **Iris**: Linksklick auf ein Gate. Taste: Ziffernblock [2] schaltet sie um.
- **Iris Computer** (Gates und Ringe): Berühre damit ein Gate mit Iris, [E] = Menü (Codes, automatisch schließen).
- **GDO** (Waffe): Rechtsklick = Code eingeben, Linksklick = an ein offenes Gate senden.
# Ringe
- Ringplattform + Ringpanel, nah beieinander (das Panel schaltet Ringe im Umkreis von 500 Einheiten).
- [E] auf einen Panelknopf drückt ihn. **DIAL** ohne Ziffern = zu den nächsten Ringen. Mit Ziffern = zu dieser Ringadresse.
- [E] auf der Ringbasis: Gib ihr einen Namen (Adresse).
- **Ring Caller** (Waffe): Linksklick ruft die nächsten Ringe, Rechtsklick öffnet das Wahlfenster.
! Ringe zerquetschen dich, wenn du still stehst, wo sie herunterkommen. Stell dich in die Mitte der Plattform oder geh von ihr runter.
]] },

{ id = "hatak", title = "Ha'tak-Mutterschiff", icon = "icon16/house.png", body = [[
= Ein riesiges Goa'uld-Mutterschiff. Du kannst hindurchgehen, es fliegen, damit kämpfen und es mit Energie versorgen. Innen ist es viel größer als außen.
# Spawnen
- [Q] > Ascension Gates > **Größere Mutterschiffe** > Ha'tak.
- Es erscheint hoch über der Stelle, auf die du zielst (oder vor dir, wenn du in den Himmel zielst). Es schwebt.
# Einsteigen
- **Hangar:** die große Tür unten an der Pyramide. [E] darauf öffnet sie. Geh hinein: Du stehst direkt im Hangar.
- Die Hangar-Tür außen und innen ist eine Tür: auf beiden Seiten offen oder zu. Ein Türschalter (goldene Platte) ist innen und außen daneben.
- **Ringe:** Nutze Ringe außen nahe am Schiff oder ein Ringpanel innen.
- [E] auf eine Tür oder auf das goldene Bedienfeld daneben: Die Tür öffnet oder schließt sich.
- Eine offene Tür: Sieh in die Türöffnung und drücke [E], um sie zu schließen.
> Innen kannst du immer so hinaus, wie du hereingekommen bist: Die Hangaröffnung geht in beide Richtungen.
# Die Decks
1. **Hangardeck:** Hangar, Ringraum, Kel'no'reem-Raum, Jaffa-Kaserne, Gleiterbucht.
2. **Pel'tak (Brücke):** Thron, Pilotensitz, Waffen-, Navigations- und Kommandokonsolen.
3. **Gate-Raum:** Stargate mit DHD.
4. **Kommandodeck:** Quartiere mit Sarkophag, Waffenkammer, Computerkern.
5. **Maschinenraum:** Triebwerksraum, Zellen, Schildraum.
- Zwischen den Decks reisen: [E] auf ein Ringpanel > wähle das Deck.
# Wer darf es nutzen
- Die **Besatzung** = die Besitzerin oder der Besitzer und die Freunde (Freunde im Prop-Schutz).
- Fremde können das Schiff mit dem **Kontrollkristall** übernehmen. Siehe {page:hatak_systems|Ha'tak-Systeme}.
# Mehr
- {page:hatak_fly|Fliegen, springen und Waffen}
# Hauptmenü (das ganze Schiff in einem Fenster)
- Öffnen: [1] auf dem Thron, im Pilotensitz oder als Schütze, oder [E] auf die Kommandokonsole im Pel'tak.
- **SHIP:** Rumpf, Energie, Schilde, wer fliegt. Hyperraum, Waffen, Technik, Adressen.
- **DOORS:** jede Tür: öffnen, schließen, sperren. Alle Türen auf einmal auf oder zu.
- **SYSTEMS:** Schilde, Tarnung, Alarm, Sperre, Schiffslog, Selbstzerstörung.
- {page:hatak_systems|Power, Computer, Schilde, Schaden und Räume}
]] },

{ id = "hatak_fly", title = "Ha'tak: fliegen, springen, kämpfen", icon = "icon16/arrow_up.png", body = [[
= Setz dich auf den Pilotensitz im Pel'tak. W/S/A/D zum Fliegen, R für Hyperraum, V für die Kamera. Waffen an der Waffenkonsole.
# Das Steuer übernehmen
1. Geh zum Pel'tak (Brücke).
2. Setz dich auf den **Thron** ([E]) oder auf den Pilotensitz ([E] auf die Pilotenkonsole).
3. Verlasse den Sitz mit [E].
- Der Thron hat Vorrang: Sind beide besetzt, fliegt der Thron.
- [1] öffnet das **Hauptmenü** (auch im Schützenmodus).
- Die Vorderseite des Schiffs ist die Hangarseite: [W] fliegt in diese Richtung.
# Flugtasten
- [W] vorwärts, [S] rückwärts.
- [A] / [D] nach links / rechts drehen.
- [Space] hoch, [Ctrl] runter.
- [Shift] halten: 4x so schnell.
- [V]: Kamera. Sie startet hinter und über dem Schiff (Mausrad = Abstand). Danach: der Sitz, dann die Sicht von der vorderen Spitze.
- Das Fenster im Pel'tak zeigt die echte Sicht nach draußen.
- [R]: Hyperraum-Menü.
- Kein Pilot: Das Schiff wird langsamer und hält an.
> Wer an Bord ist, rutscht nicht herum, während das Schiff fliegt.
# Hyperraumsprung
1. Drücke [R] auf dem Pilotensitz (oder [E] auf der Navigationskonsole).
2. Wähle ein Ziel: gespeicherte Marken, ein Stargate oder eine andere Person. Oder tippe x y z.
3. Klicke **Jump**. Das Schiff lädt auf (3 s), ein Fenster öffnet sich, du fliegst hindurch.
- **Marke 1/2/3 hier** merkt sich die Stelle.
- Braucht 30 % Hyperantrieb-Power. 8 s Pause zwischen den Sprüngen.
# Waffen
- [E] auf die **Waffenkonsole**: Radar von oben und eine Zielliste.
- **OFF:** keine Schüsse. **DEFEND:** schießt nur auf das, was das Schiff angegriffen hat. **AUTO:** auch auf NPCs und Fremde.
- **FIRE:** eine Salve auf das gewählte Ziel. **KEEP FIRING:** immer wieder.
- **MANUAL (GUNNER)** oder setz dich auf den Schützensitz: Du zielst selbst.
## Schützentasten
- Die Maus zielt, [Mouse1] feuern, [Mouse2] halten für Zoom.
- [R] nächste Kanonengruppe (oben, vorne, seitlich, hinten, unten).
- [E] verlassen.
! Feuern schaltet deine eigene Tarnung ab.
]] },

{ id = "hatak_systems", title = "Ha'tak-Systeme und Räume", icon = "icon16/cog.png", body = [[
= Kristalle versorgen alles. Zieh einen heraus, und ein System wird schwächer. Der Computerkern steuert Ringe, Türen, Sensoren und Nachrichten.
# Maschinenraum: Power-Kristalle
- Der Powerkern (Hub) hält 3 Kristalle. Ablagen halten je 3 Kristalle: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] auf einen Kristall: Du ziehst ihn heraus und trägst ihn.
- [E] an einem freien Platz: Du setzt ihn ein.
- Verbrannte Kristalle (dunkel) entstehen durch harte Treffer. Leg sie in das **Ersatzregal**: Sie laden in 60 s wieder auf.
- Die zwei Naquadah-Generatoren: [E] schaltet sie ein (je +15 %).
- **Vierter Hub-Arm:** ein weiterer Kristall (+15 %) oder ein **ZPM** (130 %). Bring das ZPM mit der Gravity Gun nah heran: Es rastet ein.
- **Maschinenkonsole:** zeigt die ganze Power. Knöpfe schicken mehr Power an ein System.
# Computerkern: Datenkristalle
- Blaue Kristalle in 4 Regalen: **Rings**, **Doors**, **Sensors**, **Communication**. 2 von 3 müssen drin sein, sonst stoppt diese Funktion.
- **Selbstzerstörung:** 1, 2 oder 4 Minuten. **ABORT** stoppt sie.
- **Schiffslog:** was an Bord passiert ist.
- **Adressen:** jedes Gate auf der Karte. **DIAL** wählt vom Gate-Raum aus an.
- **Sicherheit:** Alarm an/aus, Lockdown (alle Türen verriegelt, die Besatzung kann sie noch öffnen).
# Schilde und Tarnung
- Konsole im Schildraum oder Kommandokonsole: **RAISE / LOWER SHIELDS**.
- **AUTO:** Die Schilde gehen von selbst hoch, wenn jemand angreift.
- Der Schild hält jede Waffe auf, auch die des Besitzers: Schüsse stoppen an der goldenen Blase.
- **CLOAK:** Das Schiff wird unsichtbar. Braucht 30 % Schild-Power. Die Schilde fallen aus, solange getarnt ist.
# Lebenserhaltung
- Luft, Wärme und Schwerkraft an Bord, auch im Weltraum.
- Sie braucht Energie vom Kern und eine Hülle über 10 %. Ohne sie ist es innen wie außen (im Weltraum keine Luft).
- Hauptmenü: Status unter SHIP, an/aus unter SYSTEMS.
# Schaden
- Nur schwere Treffer zählen. Solange das Schild hält, fängt es die Treffer ab.
- Explosionen **im Inneren** tun doppelt so weh und verbrennen Kristalle in der Nähe.
- Alarm bei 50, 25 und 10 % Hülle. Bei 0 explodiert das Schiff (Admins können das ausschalten).
- Das **Reparaturwerkzeug** repariert die Hülle.
# Räume
- **Gleiterbucht:** 4 Todesgleiter. [E] = fliegen. Flieg durch den Starttunnel hinaus. Verlorene Gleiter kommen nach 60 s zurück.
- Die Starttunnel haben Türen innen und außen. Sie öffnen sich von selbst, wenn du mit einem Gleiter auf sie zufliegst. Öffne oder schließe sie im Hauptmenü.
- **Kaserne:** [E] auf die Pritschenkonsole = du respawnst an Bord. Rüstungstruhe: [E] = +50 Rüstung (einmal pro Minute).
- **Kel'no'reem:** Dich auf einer Matte ducken ([Ctrl]) = du heilst langsam.
- **Sarkophag:** [E], um dich hineinzulegen und zu heilen.
- **Waffen:** [E] auf eine Staff weapon an der Wand: Du nimmst sie (nach 2 Minuten hängt eine neue da). [E] auf eine Zat-Kiste: eine Zat.
- **Zellen:** [E] auf das Panel neben einer Zelle schaltet ihr Kraftfeld um (nur Besatzung).
# Das Schiff übernehmen (Kapern)
1. Finde den **Kontrollkristall**, der irgendwo drinnen versteckt ist. [E] hebt ihn auf.
2. Geh zum Kristallplatz im Pel'tak (rechte Wand). [E] startet.
3. Bleib 40 s in der Nähe. Der Alarm geht los.
4. Fertig: Du und deine Freunde seid die neue Besatzung.
- Die alte Besatzung kann es stoppen: [E] auf den Platz.
]] },

{ id = "glider", title = "Todesgleiter", icon = "icon16/bullet_go.png", body = [[
= Kleiner Goa'uld-Jäger. W zum Fliegen, Maus zum Lenken, Mouse1 zum Schießen. Ohne gedrückte Taste schwebt er.
# So bekommst du ihn
- [Q] > Ascension Gates > **Flotte: Schiffe und Jäger** > Death Glider. Oder in der Gleiterbucht des Ha'tak.
# Tasten
- [E] auf den Gleiter: einsteigen. Nochmal [E]: aussteigen.
- [W] vorwärts fliegen, [S] langsam zurück. [Shift] halten: schneller.
- Maus: lenken.
- [1]: Cockpit-Ansicht an / aus.
- Keine Taste: Er hält seine Position in der Luft.
- [Mouse1]: beide Stabkanonen feuern.
- Mausrad: rollen. [Mouse3]: zurück in die Waagerechte rollen.
- Pfeiltasten: Kameraabstand und -höhe.
- [Backspace]: Selbstzerstörung.
# Freier Flug (Server-Einstellung)
- Mit **agp_glider_free_flight 1**: [S] rückwärts, [A] / [D] seitwärts, [Space] hoch, [Ctrl] runter.
# HUD
- Unten links: Hülle, Tempo, Stabkanonen, die Tasten.
- 300 Hülle. Bei 0 explodiert er.
> Tasten ändern: {page:keys|Tasten ändern}.
]] },

{ id = "alkesh", title = "Al'kesh und andere Schiffe", icon = "icon16/bullet_go.png", body = [[
= Bei jedem Schiff: E zum Ein- und Aussteigen, W/A/S/D und Maus zum Fliegen, Mouse1 zum Schießen.
# Al'kesh
- [Q] > Ascension Gates > **Flotte: Schiffe und Jäger**. Ziel auf den Boden, um es zu spawnen.
- [W] [S] [A] [D] fliegen. [Space] hoch, [Ctrl] runter. [Shift] halten: schneller.
- [Mouse1] feuern. Mausrad rollen, [Mouse3] wieder waagerecht.
- [Enter]: Landemodus (bleibt waagerecht).
- [E] aussteigen. [Backspace] Selbstzerstörung.
# Große Schiffe
- Aurora, Destiny, Gate Seeder, O'Neill, Ori Mothership, Prometheus, Replicator Mothership, Traveler, Wraith Cruiser.
- Dieselben Tasten wie beim Al'kesh. Dazu [Mouse2] Ziel verfolgen, [G] Schild.
# Kleine Schiffe
- **Puddle Jumper:** [Mouse1] Drohnen (öffnet die Pods von selbst), [Mouse2] halten = Drohnen folgen deinem Zielpunkt, [Alt] Tarnung, [2] Tür, [T] schweben, [G] Schild, [R] nächstes Tor anwählen.
- **Tel'tak:** [Mouse2] Stabkanonen, [G] Schild, [Alt] Tarnung, [R] halten: Hyperraum, [2] Tür. Ringstrahl: [Enter] (Landemodus), dann [Mouse1].
- **F-302:** [Mouse1] Bordkanonen, [Mouse2] Raketen, [Alt] Täuschkörper, [B] Boost, [2] Schleudersitz.
- **Daedalus:** [Mouse1] Railguns, [Mouse2] Asgard-Strahl, [1] bis [8] Raketen.
- **Wraith Dart:** [C] Leute einsammeln, [Alt] wieder rauslassen.
> Tasten ändern: {page:keys|Tasten ändern}.
]] },

{ id = "spacegrid", title = "PowerGrid: Power und Energie", icon = "icon16/lightning.png", body = [[
= PowerGrid ist der Werkzeug-Tab für Energie. Platziere Power-Teile, verbinde sie, versorge sie mit ZPMs oder Generatoren.
# Wo
- [Q] > rechte Seite > Tab **PowerGrid**.
- **PowerGrid:** das Werkzeug PowerGrid Teile (alle Teile in einem Bilderraster).
- **Energie:** ZPM, ZPM-Hubs, Naquadah-Generatoren, Goa'uld-Powerhub, PowerGrid-Verbinder.
- **Einstellungen:** PowerGrid-Einstellungen und diese Hilfe.
# Ein Teil platzieren
1. Nimm das Werkzeug **PowerGrid Teile**.
2. Klicke rechts auf ein Bild (zum Beispiel eine Energiezelle).
3. Ziele dorthin, wo es stehen soll. Du siehst einen Geist davon.
4. Linksklick [Mouse1]: platziert. Rechtsklick [Mouse2]: um 90 Grad gedreht platziert.
- Ziele auf ein Teil und drücke [R]: Dieses Teil ist gewählt.
- Auf einem Schiff oder Prop wird es an das angeschweißt, worauf du zielst (Kästchen **An das Ziel schweißen**).
# Die Teile
- **Energiezellen (XS bis XL):** speichern Energie.
- **Solarpanels:** machen Energie, solange offener Himmel über ihnen ist.
- **Windturbine:** macht Energie, mehr je höher sie steht.
- **Schwarzes-Loch-Energie:** hält jede Ressource (nur Admins, außer es ist erlaubt).
- **Power-Knoten:** verbinden alles, was auf ihnen steht. Ihr Display zeigt das Netz.
- **Power-Displays:** zeigen das Netz, mit dem sie verbunden sind.
- **Power-Ventil:** an = Energie fließt zwischen zwei Netzen, aus = sie sind getrennt. [E] schaltet es um.
- **Ressourcentanks:** halten eine Ressource (Sauerstoff, Wasser ...). [E] ändert die Ressource, solange er leer ist.
- **Lebenserhaltung:** siehe {page:lifesupport|Lebenserhaltung}.
# Verbinden (wie Teile Energie teilen)
- Admins wählen den Modus: **Manual**, **Automatic**, **Mix** oder **Off** (PowerGrid-Einstellungen).
- **Manual:** Werkzeug **PowerGrid-Verbinder**: Linksklick auf die Teile (sie werden blau), Rechtsklick auf das Teil oder den Power-Knoten, mit dem sie verbunden werden. [R] löscht die Auswahl; [R] auf ein Teil entfernt seine Verbindungen.
- **Automatic:** Teile, die zusammengeschweißt sind, teilen von selbst.
- **Off:** Alles hat freie Energie.
! Spacebuild installiert? Dann wird das Netz von Spacebuild benutzt. Die Power-Knoten von PowerGrid arbeiten dann als Spacebuild-Knoten: verbinde mit dem Werkzeug PowerGrid-Verbinder. Admins können **Immer PowerGrid** einschalten.
# Energiequellen
- **ZPM:** Werkzeug **ZPM MK III**. Setze es in einen ZPM-Hub oder einen {page:goauldpower|Goa'uld-Powerhub}.
- **Naquadah-Generator:** Werkzeug unter Energy.
- **Goa'uld-Powerkristalle:** im {page:goauldpower|Goa'uld-Powerhub}.
]] },

{ id = "goauldpower", title = "Goa'uld-Powerhub und Kristalle", icon = "icon16/rainbow.png", body = [[
= Ein Messing-Hub mit goldenem Powerkern. Seine 4 Arme nehmen Goa'uld-Powerkristalle oder ZPMs auf. Der Kern pulsiert heller, je mehr Power er hat.
# So bekommst du ihn
- Werkzeug: [Q] > PowerGrid > Energie > **Goa'uld Power Hub + Crystals**.
- Oder Spawn-Tab: Ascension Gates > **PowerGrid**.
# Benutzen
1. Linksklick [Mouse1] mit dem Werkzeug: ein Hub.
2. Ziele auf einen Arm und Rechtsklick [Mouse2]: Ein Kristall sitzt auf diesem Arm.
3. ZPM: Nimm das ZPM-Werkzeug, ziele auf einen Arm, Linksklick: Das ZPM sitzt auf diesem Arm.
4. Verbinde den Hub wie jedes andere Teil mit deinem Netz ({page:spacegrid|PowerGrid}).
- Halte einen Kristall oder ein ZPM an einen Arm (Gravity Gun oder Physics Gun): Er rastet ein.
- [E] auf einen Kristall oder ein ZPM: Er kommt heraus.
- [E] auf den Hub: zeigt Kristalle, ZPMs und Energie im Chat.
- Sieh den Hub an: Ein kleines Schild zeigt Kristalle und Energie.
> Ein ZPM gibt zehnmal so viel Power wie ein Kristall und treibt den Kern stärker an.
# Regler im Werkzeug
- **Kristallladung:** wie voll neue Kristalle sind (0 bis 100 %).
]] },

{ id = "lifesupport", title = "Lebenserhaltung und Weltraum", icon = "icon16/heart.png", body = [[
= Im Weltraum gibt es keine Luft, und es ist kalt. Dein Anzug schützt dich eine Weile. Die Lebenserhaltung macht ein Schiff oder einen Bereich sicher.
# Wann ist sie an?
- Admins wählen: nur Weltraum-Karten (Standard), jede Karte oder aus ({page:admin|Einstellungen für Admins}).
# Dein Anzug
- Drei Werte: **Luft**, **Energie**, **Kühlmittel**. Beim Spawnen sind sie voll.
- Keine Luft oder unter Wasser: Die Luft sinkt. Gute Luft: Sie füllt sich wieder.
- Kälte: Die Energie sinkt. Hitze: Das Kühlmittel sinkt.
- Ein Wert bei 0 verletzt dich.
- Ein Kasten unten links erscheint nur, wenn etwas nicht stimmt.
# Life Support Core
- Auf einem Schiff: Das ganze Schiff bekommt Luft. [E] schaltet ihn um.
- Nicht auf einem Schiff: eine Luftblase. [E] ändert die Größe (300 bis 2000, dann aus).
- Braucht Energie und Sauerstoff (er macht Sauerstoff aus Wasser).
# Anzug auffüllen
- **Suit Dispenser:** [E] füllt Luft, Energie und Kühlmittel aus seinem Netz auf.
- **Air Compressor:** Sauerstoff aus atembarer Luft. **Water Pump:** Wasser, solange er im Wasser steht.
# Gate-Bericht
- Wenn ein Gate anwählt, bekommst du einen kurzen Bericht: Luft, Temperatur, Schwerkraft auf der anderen Seite und ob du einen Anzug brauchst.
]] },

{ id = "weapons", title = "Handwaffen", icon = "icon16/bomb.png", body = [[
= Du findest sie unter [Q] > Ascension Gates > Waffen. Mouse1 = Hauptfunktion, Mouse2 = zweite Funktion.
# Goa'uld
- **Zat'nik'tel:** 1. Schuss betäubt, 2. tötet, 3. lässt es verschwinden.
- **Stabwaffe:** [Mouse2] bereit machen, [Mouse1] feuern.
- **Handgerät:** [Mouse1] benutzen, [Mouse2] nächster Modus.
- **Heilgerät:** auf eine Person halten, um zu heilen.
- **Mobile DHD:** auf ein Gate legen.
# Erde (SGC)
- **P90 (PDW):** [Mouse1] feuern, [Mouse2] zielen, [R] nachladen.
- **Beretta:** [Mouse1] feuern, [R] nachladen.
- **GDO:** [Mouse2] Code eingeben, [Mouse1] senden.
# Andere
- **Ori-Handwaffe und Ori-Stab, Wraith-Betäuber, Ronons Waffe, Asuranische Waffe.**
- **Tac:** werfen, nochmal = sprengen. [Mouse2] töten / betäuben / Rauch.
- **Reparaturwerkzeug:** auf ein Schiff, Gate oder DHD halten, um es zu reparieren.
- **Kontrollstuhl (Antiker, Spawn-Tab Waffen):** [E] zum Sitzen (braucht einen geladenen ZPM in seinem Hub). [1] = Zielliste: Lenke die Drohnen auf ein Ziel, oder ziele frei.
- **Persönlicher Schild, Sodan-Tarnung:** [Mouse1] an, [Mouse2] aus.
- **Mimetisches Abbildungsgerät:** [Mouse1] auf eine Person dicht vor dir halten bildet sie ab, [Mouse2] Projektion an / aus, [R] Abbild löschen.
]] },

{ id = "keys", title = "Tasten ändern", icon = "icon16/keyboard.png", body = [[
= Die Schiffstasten kannst du bei den meisten kleinen Schiffen im Keybinders-Menü ändern.
# So geht es
1. [Q] > rechte Seite > Ascension Gates > **Keybinders**.
2. Wähle das Schiff.
3. Klicke einmal auf eine Zeile, dann schnell ein zweites Mal (sie wird orange).
4. Drücke die neue Taste oder Maustaste. [Esc] bricht ab.
- Schiffe: Daedalus, Wraith Dart, Gate Glider, Death Glider, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- Das Ha'tak nutzt deine normalen GMod-Tasten ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) und [V].
- Für eine eigene Taste: Binde sie an **agp_hatak_camera** (Konsole: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Einstellungen für Admins", icon = "icon16/shield.png", body = [[
= Admins (und du im Einzelspieler) ändern die Server-Einstellungen. Alle anderen sehen sie nur. Halte die Maus über eine Einstellung für einen kurzen Tipp.
# Schiffs-Einstellungen: [Q] > Ascension Gates > Config > AGP-Schiffe
- **Kapern:** nur Besatzung / mit dem Kontrollkristall / alle.
- **Waffen schießen auf Besitzer und Freunde:** ja oder nein.
- **Waffen- + Radarreichweite:** wie weit die Kanonen schießen und das Radar sieht.
- **Radar: max. angezeigte Ziele.**
- **Energiekristalle, die Fremde ziehen dürfen:** 0 bis 15 (Standard 2). Die Besatzung hat kein Limit.
- **Schiff kann zerstört werden:** ja (Standard) oder nein (die Hülle bleibt bei 1).
- **Hüllenstärke (neue Schiffe):** 10.000 bis 1.000.000 (Standard 100.000).
- **Tarnung erlaubt:** ja oder nein.
- **Gleiterhangar: verlorene Gleiter kommen zurück:** ja oder nein, und nach wie vielen Sekunden (Standard 60).
- **Schildblase (alle Schiffe):** nur bei Treffern und beim Ein- oder Ausschalten (Standard) oder immer sichtbar.
- **Selbstzerstörung: Countdown (alle Schiffe):** 1 bis 600 Sekunden (Standard 5).
# Power-Einstellungen: [Q] > PowerGrid > Einstellungen > PowerGrid
- **Wie Teile verbunden werden:** Manuell / Automatisch / Mix / Aus. Siehe {page:spacegrid|PowerGrid}.
- **Immer PowerGrid:** PowerGrid auch mit Spacebuild benutzen (braucht einen Kartenwechsel).
- **Schwarzes-Loch-Energie:** nur Admins oder alle.
- **Weltraum-Simulation:** nur Weltraum-Karten / jede Karte / aus. Siehe {page:lifesupport|Lebenserhaltung}.
- **Gate-Zielbericht:** an oder aus.
# Nur für dich (jeder Spieler)
- Kabel, Maschinengeräusche, Gate-Bericht auf deinem Bildschirm, Einheiten für Entfernung, Temperatur und Schwerkraft.
]] },

{ id = "problems", title = "Probleme und Lösungen", icon = "icon16/help.png", body = [[
= Etwas geht nicht? Sieh zuerst hier nach.
# Symbole im Q-Menü werden rosa und nichts spawnt
- Du hältst [Ctrl] (oder es hängt fest). [Ctrl] + Klick **wählt** Symbole aus (rosa), statt sie zu spawnen.
- Lösung: Lass [Ctrl] los (einmal drücken), klicke auf eine leere Stelle im Symbolbereich.
# Ich klicke ein Symbol und nichts erscheint
- Sieh auf den Boden vor dir, nicht in den weiten Himmel.
- Große Schiffe erscheinen hoch über dem Boden oder vor dir. Sieh dich um.
- Admins können Teile ausschalten oder begrenzen (Ascension Gates > Config > Über & Credits > Einstellungen).
# Der Gleiter fällt
- Der Todesgleiter hält seine Höhe, wenn du keine Taste drückst. Fällt er? Dann ist er vielleicht zerstört oder außerhalb der Karte.
# Eine Ha'tak-Konsole sagt "crew only"
- Nur die Besitzerin oder der Besitzer und die Freunde dürfen sie nutzen. Oder übernimm das Schiff mit dem Kontrollkristall ({page:hatak_systems|Ha'tak-Systeme}).
# Ein Schiffssystem sagt OFFLINE
- Prüfe die Kristalle im Maschinenraum und die blauen Datenkristalle im Computerkern.
# Ich stecke in einem Durchgang oder einer Tür fest
- Durchgänge in Schiffsinnenräumen lassen dich nicht durch, wenn die andere Seite zu ist. Öffne zuerst die Tür.
- Immer noch fest: Noclip ([V]) oder respawne.
# Ein Werkzeug zeigt Text wie #tool.something.name
- Ein Text fehlt. Sag mir bitte, welches Werkzeug es ist.
]] },

},
}
