-- Aide (wiki) d'Ascension Gates, français. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Aide",
    search = "Rechercher...",
    size = "Taille du texte",
    short = "EN BREF",
    intro = "Tout sur Ascension Gates : ce que font les pièces et comment tu les contrôles.",
    open = "Ouvrir l'aide",
},
pages = {

{ id = "start", title = "Commencer ici", icon = "icon16/star.png", body = [[
= Ascension Gates est un pack Stargate : portes, anneaux, vaisseaux, armes, boucliers et énergie. Cette aide explique chaque pièce en étapes courtes.
# Où se trouvent les choses
- **Faire apparaître des objets :** appuie sur [Q], onglet **Ascension Gates** (en haut à gauche). Les catégories sont à gauche.
- **Outils :** [Q], côté droit, onglet **Ascension Gates** (portes, ouvertures, armes, clés) et onglet **PowerGrid** (énergie, power, survie).
- **Réglages :** [Q] > Ascension Gates > Config. Réglages des vaisseaux : **Vaisseaux AGP**.
- **Réglages de l'énergie et de la survie :** [Q] > PowerGrid > Réglages > **PowerGrid**.
- **Cette aide :** commande de console **agp_wiki**, ou [Q] > Ascension Gates > Config > **Aide (Wiki)**.
# Premiers pas
1. Appuie sur [Q] et ouvre l'onglet **Ascension Gates**.
2. Fais apparaître deux Stargates et un DHD (catégorie **Portes et anneaux**).
3. Regarde le DHD et appuie sur [E]. Compose l'autre porte.
4. Traverse.
> Passe la souris sur un réglage : une courte ligne te dit ce qu'il fait.
# Les pages de cette aide
- {page:gates|Stargates, DHD et anneaux}
- {page:hatak|Vaisseau mère Ha'tak}
- {page:glider|Planeur de la mort}
- {page:alkesh|Al'kesh et autres vaisseaux}
- {page:spacegrid|PowerGrid : power et énergie}
- {page:goauldpower|Hub d'énergie goa'uld et cristaux}
- {page:lifesupport|Survie et espace}
- {page:weapons|Armes à main}
- {page:keys|Changer les touches}
- {page:admin|Réglages pour les admins}
- {page:problems|Problèmes et solutions}
]] },

{ id = "gates", title = "Stargates, DHD et anneaux", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Fais apparaître une porte et un DHD, appuie sur E sur le DHD, compose. Les anneaux te déplacent entre des plateformes d'anneaux proches.
# Les obtenir
- [Q] > Ascension Gates > **Portes et anneaux** : portes, DHD, anneaux et panneaux d'anneaux.
- Outils ([Q] > côté droit > Ascension Gates > Tech) : DHD mobile, DHD Superporte, Iris, Iris Goa'uld.
# Composer avec le DHD
1. Place le DHD près de la porte (à moins de 1000).
2. Regarde un glyphe du DHD et appuie sur [E] : il s'allume.
3. Appuie sur tous les glyphes de l'adresse, puis sur le gros bouton du centre.
- Bouton du centre sans glyphe appuyé : le menu de composition s'ouvre.
- Bouton du centre quand la porte est ouverte : la porte se ferme.
# Composer avec le menu de la porte
1. Regarde la porte et appuie sur [E].
2. Tape l'adresse ou choisis-la dans la liste.
3. Clique sur **Dial**. **Abort Dialling / Close Gate** l'arrête.
- Dans le même menu, tu règles l'adresse, le groupe et le nom de la porte, et si elle est privée.
# Iris
- Outil **Iris** : clic gauche sur une porte. Touche : [2] du pavé numérique l'active ou la coupe.
- **Iris Computer** (Portes et anneaux) : pose-le contre une porte avec iris, [E] = menu (codes, fermeture auto).
- **GDO** (arme) : clic droit = taper ton code, clic gauche = l'envoyer à une porte ouverte.
# Anneaux
- Plateforme d'anneaux + panneau d'anneaux, proches l'un de l'autre (le panneau marche pour des anneaux à moins de 500).
- [E] sur un bouton du panneau l'appuie. **DIAL** sans chiffres = vers les anneaux les plus proches. Avec des chiffres = vers cette adresse d'anneaux.
- [E] sur la base des anneaux : donne-lui un nom (adresse).
- **Ring Caller** (arme) : clic gauche appelle les anneaux les plus proches, clic droit ouvre la fenêtre de composition.
! Les anneaux t'écrasent si tu restes immobile là où ils descendent. Monte sur la plateforme ou éloigne-toi.
]] },

{ id = "hatak", title = "Vaisseau mère Ha'tak", icon = "icon16/house.png", body = [[
= Un immense vaisseau mère goa'uld. Tu peux le traverser, le piloter, te battre avec lui et l'alimenter. L'intérieur est bien plus grand que l'extérieur.
# Le faire apparaître
- [Q] > Ascension Gates > **Grands vaisseaux-mères** > Ha'tak.
- Il apparaît très haut au-dessus de l'endroit que tu vises (ou devant toi si tu vises le ciel). Il flotte.
# Monter à bord
- **Hangar :** la grande porte en bas de la pyramide. [E] dessus l'ouvre. Entre : tu es directement dans le hangar à l'intérieur.
- La porte du hangar dehors et dedans est une seule porte : ouverte ou fermée des deux côtés. Une commande de porte (plaque dorée) est à côté, dedans et dehors.
- **Anneaux :** utilise des anneaux dehors près du vaisseau, ou un panneau d'anneaux à l'intérieur.
- [E] sur une porte ou sur la commande dorée à côté : la porte s'ouvre ou se ferme.
- Une porte ouverte : regarde dans l'embrasure et appuie sur [E] pour la fermer.
> À l'intérieur, tu peux toujours sortir par où tu es entré : l'ouverture du hangar marche dans les deux sens.
# Les ponts
1. **Pont du hangar :** hangar, salle des anneaux, salle kel'no'reem, casernes des Jaffas, baie des planeurs.
2. **Pel'tak (passerelle) :** trône, siège de pilote, armes, consoles de navigation et de commandement.
3. **Salle de la porte :** Stargate avec DHD.
4. **Pont de commandement :** quartiers avec sarcophage, armurerie, noyau informatique.
5. **Ingénierie :** salle des moteurs, cellules, salle des boucliers.
- Voyager entre les ponts : [E] sur un panneau d'anneaux > choisis le pont.
# Qui peut l'utiliser
- L'**équipage** = la personne propriétaire et ses amis (amis de la protection des props).
- Les inconnus peuvent prendre le vaisseau avec le **cristal de contrôle**. Voir {page:hatak_systems|Systèmes du Ha'tak}.
# Plus
- {page:hatak_fly|Voler, sauter et armes}
# Menu maître (tout le vaisseau dans une fenêtre)
- Ouvre-le : [1] sur le trône, dans le siège de pilote ou en tant que mitrailleur, ou [E] sur la console de commandement du pel'tak.
- **SHIP :** coque, énergie, boucliers, qui pilote. Hyperespace, armes, ingénierie, adresses.
- **DOORS :** chaque porte : ouvrir, fermer, verrouiller. Toutes les portes ouvertes ou fermées d'un coup.
- **SYSTEMS :** boucliers, camouflage, alarme, verrouillage, journal du vaisseau, autodestruction.
- {page:hatak_systems|Power, ordinateur, boucliers, dégâts et salles}
]] },

{ id = "hatak_fly", title = "Ha'tak : voler, sauter, se battre", icon = "icon16/arrow_up.png", body = [[
= Assieds-toi au siège de pilote dans le pel'tak. W/S/A/D pour voler, R pour l'hyperespace, V pour la caméra. Armes à la console d'armes.
# Prendre la barre
1. Va au pel'tak (passerelle).
2. Assieds-toi sur le **trône** ([E]) ou au siège de pilote ([E] sur la console de pilote).
3. Quitte le siège avec [E].
- Le trône passe en premier : si les deux sont pris, c'est le trône qui pilote.
- [1] ouvre le **menu maître** (aussi en mode mitrailleur).
- L'avant du vaisseau est le côté du hangar : [W] vole dans cette direction.
# Touches de vol
- [W] avancer, [S] reculer.
- [A] / [D] tourner à gauche / à droite.
- [Space] monter, [Ctrl] descendre.
- Maintiens [Shift] : 4 fois plus vite.
- [V] : caméra. Elle démarre derrière et au-dessus du vaisseau (molette = distance). Ensuite : le siège, puis la vue depuis la pointe avant.
- La fenêtre du pel'tak montre la vraie vue dehors.
- [R] : menu d'hyperespace.
- Pas de pilote : le vaisseau ralentit et s'arrête.
> Les gens à bord ne glissent pas quand le vaisseau vole.
# Saut en hyperespace
1. Appuie sur [R] au siège de pilote (ou sur [E] à la console de navigation).
2. Choisis une cible : repères enregistrés, un Stargate ou un autre joueur. Ou tape x y z.
3. Clique sur **Jump**. Le vaisseau se charge (3 s), une fenêtre s'ouvre, tu voles à travers.
- **Save mark 1/2/3 here** retient l'endroit.
- Demande 30 % de power d'hyperpropulsion. Pause de 8 s entre les sauts.
# Armes
- [E] sur la **console d'armes** : radar vu du dessus et liste de cibles.
- **OFF :** pas de tirs. **DEFEND :** tire seulement sur ce qui a attaqué le vaisseau. **AUTO :** aussi sur les PNJ et les inconnus.
- **FIRE :** une salve sur la cible choisie. **KEEP FIRING :** encore et encore.
- **MANUAL (GUNNER)** ou assieds-toi au siège de tireur : tu vises toi-même.
## Touches de tireur
- La souris vise, [Mouse1] tirer, maintiens [Mouse2] pour zoomer.
- [R] groupe de canons suivant (haut, avant, côtés, arrière, bas).
- [E] quitter.
! Tirer coupe ton propre camouflage.
]] },

{ id = "hatak_systems", title = "Systèmes et salles du Ha'tak", icon = "icon16/cog.png", body = [[
= Les cristaux alimentent tout. Retires-en un et un système s'affaiblit. Le noyau informatique gère les anneaux, les portes, les capteurs et les messages.
# Salle des moteurs : cristaux de power
- Le noyau d'énergie (hub) tient 3 cristaux. Les plateaux tiennent 3 cristaux chacun : **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] sur un cristal : tu le retires et tu le portes.
- [E] sur un emplacement libre : tu le places.
- Les cristaux brûlés (sombres) viennent de coups durs. Mets-les dans le **râtelier de rechange** : ils se rechargent en 60 s.
- Les deux générateurs de naquadah : [E] les allume (+15 % chacun).
- **Quatrième bras du hub :** un cristal de plus (+15 %) ou un **ZPM** (130 %). Approche le ZPM avec le pistolet à gravité : il s'enclenche.
- **Console d'ingénierie :** montre toute l'énergie. Les boutons envoient plus de power à un système.
# Noyau informatique : cristaux de données
- Cristaux bleus dans 4 râteliers : **Rings**, **Doors**, **Sensors**, **Communication**. 2 sur 3 doivent être en place, sinon cette fonction s'arrête.
- **Autodestruction :** 1, 2 ou 4 minutes. **ABORT** l'arrête.
- **Journal du vaisseau :** ce qui s'est passé à bord.
- **Adresses :** toutes les portes de la carte. **DIAL** compose depuis la salle de la porte.
- **Sécurité :** alarme oui/non, verrouillage (toutes les portes fermées à clé, l'équipage peut encore les ouvrir).
# Boucliers et camouflage
- Console de la salle des boucliers ou console de commandement : **RAISE / LOWER SHIELDS**.
- **AUTO :** les boucliers montent tout seuls quand quelqu'un attaque.
- Le bouclier arrête toutes les armes, même celles du propriétaire : les tirs s'arrêtent sur la bulle dorée.
- **CLOAK :** le vaisseau disparaît. Demande 30 % de power de bouclier. Les boucliers tombent pendant le camouflage.
# Survie
- Air, chaleur et gravité à bord, aussi dans l'espace.
- Elle demande de l'énergie du cœur et une coque au-dessus de 10 %. Sans elle, l'intérieur est comme l'extérieur (pas d'air dans l'espace).
- Menu maître : état sur SHIP, marche/arrêt sur SYSTEMS.
# Dégâts
- Seuls les gros coups comptent. Tant que le bouclier tient, il encaisse les coups.
- Les explosions **à l'intérieur** font deux fois plus mal et brûlent les cristaux proches.
- Alarme à 50, 25 et 10 % de coque. À 0, le vaisseau explose (les admins peuvent couper ça).
- L'**outil de réparation** répare la coque.
# Salles
- **Baie des planeurs :** 4 Planeurs de la mort. [E] = voler. Sors par le tunnel de lancement. Les planeurs perdus reviennent après 60 s.
- Les tunnels de lancement ont des portes à l'intérieur et à l'extérieur. Elles s'ouvrent toutes seules quand tu voles vers elles avec un planeur. Ouvre-les ou ferme-les dans le menu maître.
- **Casernes :** [E] sur la console de couchette = tu réapparais à bord. Coffre d'armure : [E] = +50 d'armure (une fois par minute).
- **Kel'no'reem :** accroupis-toi ([Ctrl]) sur un tapis = tu guéris lentement.
- **Sarcophage :** [E] pour t'allonger dedans et guérir.
- **Armes :** [E] sur une staff weapon au mur : tu la prends (une nouvelle est là après 2 minutes). [E] sur un coffre à zat : un zat.
- **Cellules :** [E] sur le panneau à côté d'une cellule coupe ou active son champ de force (équipage seulement).
# Prendre le vaisseau (détournement)
1. Trouve le **cristal de contrôle** caché quelque part à l'intérieur. [E] le ramasse.
2. Va à l'emplacement du cristal au pel'tak (mur de droite). [E] lance l'action.
3. Reste près pendant 40 s. L'alarme se déclenche.
4. Fini : toi et tes amis êtes le nouvel équipage.
- L'ancien équipage peut l'arrêter : [E] sur l'emplacement.
]] },

{ id = "glider", title = "Planeur de la mort", icon = "icon16/bullet_go.png", body = [[
= Petit chasseur goa'uld. W pour voler, souris pour diriger, Mouse1 pour tirer. Sans touche appuyée, il flotte.
# L'obtenir
- [Q] > Ascension Gates > **Flotte : vaisseaux et chasseurs** > Death Glider. Ou dans la baie des planeurs du Ha'tak.
# Touches
- [E] sur le planeur : monter. [E] encore : descendre.
- [W] voler vers l'avant, [S] lentement en arrière. Maintiens [Shift] : plus vite.
- Souris : diriger.
- [1] : vue cockpit activée / désactivée.
- Pas de touche : il garde sa place dans l'air.
- [Mouse1] : tirer avec les deux canons à bâton.
- Molette : rouler. [Mouse3] : revenir à l'horizontale.
- Touches fléchées : distance et hauteur de la caméra.
- [Backspace] : autodestruction.
# Vol libre (réglage du serveur)
- Avec **agp_glider_free_flight 1** : [S] reculer, [A] / [D] sur les côtés, [Space] monter, [Ctrl] descendre.
# HUD
- En bas à gauche : coque, vitesse, canons à bâton, les touches.
- 300 de coque. À 0, il explose.
> Changer les touches : {page:keys|Changer les touches}.
]] },

{ id = "alkesh", title = "Al'kesh et autres vaisseaux", icon = "icon16/bullet_go.png", body = [[
= Pour chaque vaisseau : E pour monter et descendre, W/A/S/D et souris pour voler, Mouse1 pour tirer.
# Al'kesh
- [Q] > Ascension Gates > **Flotte : vaisseaux et chasseurs**. Vise le sol pour le faire apparaître.
- [W] [S] [A] [D] voler. [Space] monter, [Ctrl] descendre. Maintiens [Shift] : plus vite.
- [Mouse1] tirer. Molette rouler, [Mouse3] à l'horizontale.
- [Enter] : mode atterrissage (reste à l'horizontale).
- [E] descendre. [Backspace] autodestruction.
# Vaisseaux mères
- Aurora, Destiny, Gate Seeder, O'Neill, Ori Mothership, Prometheus, Replicator Mothership, Traveler, Wraith Cruiser.
- Mêmes touches que l'Al'kesh. En plus [Mouse2] suivre la cible, [G] bouclier.
# Petits vaisseaux
- **Puddle Jumper :** [Mouse1] drones (ouvre les nacelles tout seul), [Mouse2] maintenu = les drones suivent ta visée, [Alt] camouflage, [2] porte, [T] vol stationnaire, [G] bouclier, [R] composer la porte la plus proche.
- **Tel'tak :** [Mouse2] canons à bâton, [G] bouclier, [Alt] camouflage, maintiens [R] hyperespace, [2] porte. Faisceau d'anneaux : [Enter] (mode atterrissage), puis [Mouse1].
- **F-302 :** [Mouse1] canons, [Mouse2] missiles, [Alt] leurres, [B] boost, [2] éjection.
- **Daedalus :** [Mouse1] canons électromagnétiques, [Mouse2] rayon asgard, [1] à [8] missiles.
- **Wraith Dart :** [C] attraper des gens, [Alt] les relâcher.
> Changer les touches : {page:keys|Changer les touches}.
]] },

{ id = "spacegrid", title = "PowerGrid : power et énergie", icon = "icon16/lightning.png", body = [[
= PowerGrid est l'onglet d'outils pour l'énergie. Place des pièces d'énergie, relie-les, alimente-les avec des ZPM ou des générateurs.
# Où
- [Q] > côté droit > onglet **PowerGrid**.
- **PowerGrid :** l'outil Pièces PowerGrid (toutes les pièces dans une grille d'images).
- **Energie :** ZPM, hubs ZPM, générateurs de naquadah, hub d'énergie goa'uld, Liaison PowerGrid.
- **Réglages :** réglages d'PowerGrid et cette aide.
# Placer une pièce
1. Prends l'outil **Pièces PowerGrid**.
2. Clique sur une image à droite (par exemple une cellule d'énergie).
3. Vise l'endroit où elle doit se tenir. Tu en vois un fantôme.
4. Clic gauche [Mouse1] : placée. Clic droit [Mouse2] : placée tournée de 90 degrés.
- Vise une pièce et appuie sur [R] : cette pièce est choisie.
- Sur un vaisseau ou un prop, elle est soudée à ce que tu vises (case **Weld to what I aim at**).
# Les pièces
- **Cellules d'énergie (XS à XL) :** stockent de l'énergie.
- **Panneaux solaires :** produisent de l'énergie tant qu'il y a du ciel dégagé au-dessus.
- **Éolienne :** produit de l'énergie, plus elle est haute, plus elle en produit.
- **Énergie de trou noir :** contient toutes les ressources (admins seulement, sauf autorisation).
- **Nœuds d'énergie :** relient tout ce qui est posé dessus. Leur écran montre le réseau.
- **Écrans d'énergie :** montrent le réseau auquel ils sont reliés.
- **Vanne d'énergie :** ouverte = l'énergie circule entre deux réseaux, fermée = ils sont séparés. [E] la bascule.
- **Réservoirs de ressources :** contiennent une ressource (oxygène, eau ...). [E] change la ressource quand il est vide.
- **Survie :** voir {page:lifesupport|Survie}.
# Relier (comment les pièces partagent l'énergie)
- Les admins choisissent le mode : **Manual**, **Automatic**, **Mix** ou **Off** (réglages d'PowerGrid).
- **Manual :** outil **Liaison PowerGrid** : clic gauche sur les pièces (elles deviennent bleues), clic droit sur la pièce ou le nœud d'énergie auquel les relier. [R] efface la sélection ; [R] sur une pièce retire ses liens.
- **Automatic :** les pièces soudées ensemble partagent toutes seules.
- **Off :** tout a de l'énergie libre.
! Spacebuild est installé ? Alors le réseau de Spacebuild est utilisé. Nos nœuds d'énergie sont alors des nœuds Spacebuild : relie avec l'outil Liaison PowerGrid. Les admins peuvent activer **Toujours PowerGrid**.
# Sources d'énergie
- **ZPM :** outil **ZPM MK III**. Mets-le dans un hub ZPM ou un {page:goauldpower|hub d'énergie goa'uld}.
- **Générateur de naquadah :** outil dans Energy.
- **Cristaux d'énergie goa'uld :** dans le {page:goauldpower|hub d'énergie goa'uld}.
]] },

{ id = "goauldpower", title = "Hub d'énergie goa'uld et cristaux", icon = "icon16/rainbow.png", body = [[
= Un hub en laiton avec un noyau d'énergie doré. Ses 4 bras prennent des cristaux d'énergie goa'uld ou des ZPM. Le noyau brille plus fort quand il a plus de power.
# L'obtenir
- Outil : [Q] > PowerGrid > Energie > **Goa'uld Power Hub + Crystals**.
- Ou onglet d'apparition : Ascension Gates > **PowerGrid**.
# L'utiliser
1. Clic gauche [Mouse1] avec l'outil : un hub.
2. Vise un bras et clic droit [Mouse2] : un cristal se pose sur ce bras.
3. ZPM : prends l'outil ZPM, vise un bras, clic gauche : le ZPM se pose sur ce bras.
4. Relie le hub à ton réseau comme n'importe quelle autre pièce ({page:spacegrid|PowerGrid}).
- Touche un bras avec un cristal ou un ZPM (pistolet à gravité ou physgun) : il s'enclenche.
- [E] sur un cristal ou un ZPM : il sort.
- [E] sur le hub : montre les cristaux, les ZPM et l'énergie dans le chat.
- Regarde le hub : une petite plaque montre les cristaux et l'énergie.
> Un ZPM donne dix fois le power d'un cristal et pousse plus fort le noyau.
# Curseur dans l'outil
- **Crystal charge :** à quel point les nouveaux cristaux sont pleins (0 à 100 %).
]] },

{ id = "lifesupport", title = "Survie et espace", icon = "icon16/heart.png", body = [[
= Dans l'espace, il n'y a pas d'air et il fait froid. Ta combinaison te protège un moment. La survie rend un vaisseau ou une zone sûr.
# Quand est-elle active ?
- Les admins choisissent : cartes spatiales seulement (par défaut), toutes les cartes, ou aucune ({page:admin|Réglages pour les admins}).
# Ta combinaison
- Trois valeurs : **air**, **énergie**, **liquide de refroidissement**. Pleines à l'apparition.
- Pas d'air ou sous l'eau : l'air baisse. Bon air : il remonte.
- Froid : l'énergie baisse. Chaud : le liquide de refroidissement baisse.
- Une valeur à 0 te blesse.
- Une boîte en bas à gauche apparaît seulement quand quelque chose ne va pas.
# Life Support Core
- Sur un vaisseau : tout le vaisseau reçoit de l'air. [E] l'active ou le coupe.
- Pas sur un vaisseau : une bulle d'air. [E] change la taille (300 à 2000, puis éteint).
- Demande de l'énergie et de l'oxygène (il fait de l'oxygène avec de l'eau).
# Remplir ta combinaison
- **Suit Dispenser :** [E] remplit l'air, l'énergie et le liquide de refroidissement depuis son réseau.
- **Air Compressor :** de l'oxygène à partir d'air respirable. **Water Pump :** de l'eau quand il est dans l'eau.
# Rapport de porte
- Quand une porte compose, tu reçois un court rapport : air, température, gravité de l'autre côté, et si tu as besoin d'une combinaison.
]] },

{ id = "weapons", title = "Armes à main", icon = "icon16/bomb.png", body = [[
= Trouve-les dans [Q] > Ascension Gates > Armes. Mouse1 = usage principal, Mouse2 = deuxième usage.
# Goa'uld
- **Zat'nik'tel :** 1er tir étourdit, 2e tue, 3e fait disparaître.
- **Staff weapon :** [Mouse2] la préparer, [Mouse1] tirer.
- **Hand device :** [Mouse1] utiliser, [Mouse2] mode suivant.
- **Healing device :** tiens-le sur un joueur pour le soigner.
- **Mobile DHD :** pose-le sur une porte.
# Terre (SGC)
- **P90 (PDW) :** [Mouse1] tirer, [Mouse2] viser, [R] recharger.
- **Beretta :** [Mouse1] tirer, [R] recharger.
- **GDO :** [Mouse2] taper le code, [Mouse1] envoyer.
# Autres
- **Ori hand weapon / staff, Wraith blaster, Ronon's gun, Asuran gun.**
- **Tac :** lancer, encore = faire exploser. [Mouse2] tuer / étourdir / fumée.
- **Repair tool :** tiens-le sur un vaisseau, une porte ou un DHD pour le réparer.
- **Fauteuil de contrôle (Anciens, onglet Armes) :** [E] pour s'asseoir (il faut un ZPM chargé dans son hub). [1] = liste de cibles : verrouille les drones sur une cible, ou vise librement.
- **Personal shield, Sodan cloak :** [Mouse1] activer, [Mouse2] couper.
- **Imageur mimétique :** maintiens [Mouse1] sur une personne juste devant toi pour la capturer, [Mouse2] projection on / off, [R] effacer l'image.
]] },

{ id = "keys", title = "Changer les touches", icon = "icon16/keyboard.png", body = [[
= Les touches des vaisseaux peuvent être changées pour la plupart des petits vaisseaux dans le menu Keybinders.
# Comment
1. [Q] > côté droit > Ascension Gates > **Keybinders**.
2. Choisis le vaisseau.
3. Clique une fois sur une ligne, puis vite une deuxième fois (elle devient orange).
4. Appuie sur la nouvelle touche ou le nouveau bouton de souris. [Esc] annule.
- Vaisseaux : Daedalus, Wraith Dart, Gate Glider, Death Glider, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- Le Ha'tak utilise tes touches GMod normales ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) et [V].
- Pour ta propre touche : associe-la à **agp_hatak_camera** (console : bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Réglages pour les admins", icon = "icon16/shield.png", body = [[
= Les admins (et toi en solo) changent les réglages du serveur. Les autres ne font que les voir. Passe la souris sur un réglage pour une courte astuce.
# Réglages des vaisseaux : [Q] > Ascension Gates > Config > Vaisseaux AGP
- **Hijacking :** équipage seulement / avec le cristal de contrôle / tout le monde.
- **Weapons fire at owner and friends :** oui ou non.
- **Weapon + radar range :** jusqu'où les canons tirent et le radar voit.
- **Radar: most targets shown.**
- **Power crystals strangers may pull :** 0 à 15 (par défaut 2). L'équipage n'a pas de limite.
- **Ship can be destroyed :** oui (par défaut) ou non (la coque reste à 1).
- **Hull health (new ships) :** 10 000 à 1 000 000 (par défaut 100 000).
- **Cloak allowed :** oui ou non.
- **Glider bay: lost gliders come back :** oui ou non, et après combien de secondes (par défaut 60).
- **Shield bubble (all ships):** seulement à l'impact et à l'activation ou la désactivation (par défaut), ou toujours visible.
- **Self-destruct countdown (all ships):** de 1 à 600 secondes (5 par défaut).
# Réglages de l'énergie : [Q] > PowerGrid > Réglages > PowerGrid
- **How parts connect :** Manual / Automatic / Mix / Off. Voir {page:spacegrid|PowerGrid}.
- **Toujours PowerGrid :** utiliser PowerGrid même avec Spacebuild (demande un changement de carte).
- **Énergie de trou noir :** admins seulement ou tout le monde.
- **Space simulation :** cartes spatiales seulement / toutes les cartes / aucune. Voir {page:lifesupport|Survie}.
- **Gate destination report :** oui ou non.
# Seulement pour toi (chaque joueur)
- Câbles, sons des machines, rapport de porte sur ton écran, unités de distance, de température et de gravité.
]] },

{ id = "problems", title = "Problèmes et solutions", icon = "icon16/help.png", body = [[
= Quelque chose ne marche pas ? Regarde d'abord ici.
# Les icônes du menu Q deviennent roses et rien n'apparaît
- Tu tiens [Ctrl] (ou elle est restée bloquée). [Ctrl] + clic **sélectionne** les icônes (roses) au lieu de les faire apparaître.
- Solution : relâche [Ctrl] (appuie une fois dessus), clique sur un endroit vide de la zone d'icônes.
# Je clique sur une icône et rien n'apparaît
- Regarde le sol devant toi, pas le ciel lointain.
- Les gros vaisseaux apparaissent très haut au-dessus du sol ou devant toi. Regarde autour.
- Les admins peuvent couper des pièces ou les limiter (Ascension Gates > Config > À propos & crédits > Réglages).
# Le planeur tombe
- Le Planeur de la mort garde sa hauteur quand tu n'appuies sur aucune touche. Il tombe ? Il est peut-être détruit ou hors de la carte.
# Une console du Ha'tak dit "crew only"
- Seuls la personne propriétaire et ses amis peuvent l'utiliser. Ou prends le vaisseau avec le cristal de contrôle ({page:hatak_systems|Systèmes du Ha'tak}).
# Un système du vaisseau dit OFFLINE
- Vérifie les cristaux dans la salle des moteurs et les cristaux de données bleus dans le noyau informatique.
# Je reste bloqué dans un passage ou une porte
- Les passages des intérieurs de vaisseau ne te laissent pas passer quand l'autre côté est fermé. Ouvre d'abord la porte.
- Toujours coincé : noclip ([V]) ou réapparais.
# Un outil affiche du texte comme #tool.something.name
- Un texte manque. Dis-nous quel outil, s'il te plaît.
]] },

},
}
