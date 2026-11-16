-- Ayuda (wiki) de Ascension Gates, español. Markup: see lua/autorun/agp_wiki.lua. Other languages: same page ids.
return {
ui = {
    title = "Ascension Gates - Ayuda",
    search = "Buscar...",
    size = "Tamaño del texto",
    short = "EN BREVE",
    intro = "Todo sobre Ascension Gates: qué hacen las piezas y cómo las controlas.",
    open = "Abrir la ayuda",
},
pages = {

{ id = "start", title = "Empieza aquí", icon = "icon16/star.png", body = [[
= Ascension Gates es un pack de Stargate: puertas, anillos, naves, armas, escudos y energía. Esta ayuda explica cada pieza en pasos cortos.
# Dónde está cada cosa
- **Crear cosas:** pulsa [Q], pestaña **Ascension Gates** (arriba a la izquierda). Las categorías están a la izquierda.
- **Herramientas:** [Q], lado derecho, pestaña **Ascension Gates** (puertas, accesos, armas, llaves) y pestaña **PowerGrid** (energía, power, soporte vital).
- **Ajustes:** [Q] > Ascension Gates > Config. Ajustes de naves: **Naves AGP**.
- **Ajustes de energía y soporte vital:** [Q] > PowerGrid > Ajustes > **PowerGrid**.
- **Esta ayuda:** comando de consola **agp_wiki**, o [Q] > Ascension Gates > Config > **Ayuda (Wiki)**.
# Primeros pasos
1. Pulsa [Q] y abre la pestaña **Ascension Gates**.
2. Crea dos Stargates y un DHD (categoría **Portales y anillos**).
3. Mira el DHD y pulsa [E]. Marca la otra puerta.
4. Cruza.
> Pasa el ratón por un ajuste: una línea corta te dice qué hace.
# Las páginas de esta ayuda
- {page:gates|Stargates, DHD y anillos}
- {page:hatak|Nave nodriza Ha'tak}
- {page:glider|Planeador de la muerte}
- {page:alkesh|Al'kesh y otras naves}
- {page:spacegrid|PowerGrid: power y energía}
- {page:goauldpower|Hub de energía goa'uld y cristales}
- {page:lifesupport|Soporte vital y espacio}
- {page:weapons|Armas de mano}
- {page:keys|Cambiar teclas}
- {page:admin|Ajustes para admins}
- {page:problems|Problemas y soluciones}
]] },

{ id = "gates", title = "Stargates, DHD y anillos", icon = "icon16/arrow_rotate_clockwise.png", body = [[
= Crea una puerta y un DHD, pulsa E en el DHD, marca. Los anillos te mueven entre plataformas de anillos cercanas.
# Cómo conseguirlos
- [Q] > Ascension Gates > **Portales y anillos**: puertas, DHD, anillos y paneles de anillos.
- Herramientas ([Q] > lado derecho > Ascension Gates > Tech): DHD móvil, DHD del Supergate, Iris, Iris Goa'uld.
# Marcar con el DHD
1. Pon el DHD cerca de la puerta (a menos de 1000).
2. Mira un glifo del DHD y pulsa [E]: se enciende.
3. Pulsa todos los glifos de la dirección, luego el botón grande del centro.
- Botón del centro sin glifos pulsados: se abre el menú de marcado.
- Botón del centro con la puerta abierta: la puerta se cierra.
# Marcar con el menú de la puerta
1. Mira la puerta y pulsa [E].
2. Escribe la dirección o elígela de la lista.
3. Haz clic en **Dial**. **Abort Dialling / Close Gate** lo detiene.
- En el mismo menú ajustas la dirección, el grupo y el nombre de la puerta, y si es privada.
# Iris
- Herramienta **Iris**: clic izquierdo en una puerta. Tecla: [2] del teclado numérico la activa o desactiva.
- **Iris Computer** (Portales y anillos): acércalo a una puerta con iris, [E] = menú (códigos, cierre automático).
- **GDO** (arma): clic derecho = escribir tu código, clic izquierdo = enviarlo a una puerta abierta.
# Anillos
- Plataforma de anillos + panel de anillos, cerca uno del otro (el panel funciona con anillos a menos de 500).
- [E] en un botón del panel lo pulsa. **DIAL** sin dígitos = a los anillos más cercanos. Con dígitos = a esa dirección de anillos.
- [E] en la base de los anillos: ponle un nombre (dirección).
- **Ring Caller** (arma): clic izquierdo llama a los anillos más cercanos, clic derecho abre la ventana de marcado.
! Los anillos te aplastan si te quedas quieto donde bajan. Sube a la plataforma o aléjate de ella.
]] },

{ id = "hatak", title = "Nave nodriza Ha'tak", icon = "icon16/house.png", body = [[
= Una enorme nave nodriza goa'uld. Puedes recorrerla, pilotarla, luchar con ella y darle energía. Por dentro es mucho más grande que por fuera.
# Crearla
- [Q] > Ascension Gates > **Naves nodriza mayores** > Ha'tak.
- Aparece muy alta sobre el lugar al que apuntas (o delante de ti si apuntas al cielo). Flota.
# Entrar
- **Hangar:** la gran puerta abajo en la pirámide. [E] sobre ella la abre. Entra: estás directo en el hangar del interior.
- La puerta del hangar de fuera y de dentro es una sola puerta: abierta o cerrada por los dos lados. Hay un control de puerta (placa dorada) al lado, dentro y fuera.
- **Anillos:** usa anillos fuera, cerca de la nave, o un panel de anillos dentro.
- [E] en una puerta o en el control dorado de al lado: la puerta se abre o se cierra.
- Una puerta abierta: mira hacia el hueco y pulsa [E] para cerrarla.
> Dentro siempre puedes salir por donde entraste: la abertura del hangar funciona en los dos sentidos.
# Las cubiertas
1. **Cubierta del hangar:** hangar, sala de anillos, sala kel'no'reem, cuartel de los Jaffa, bahía de planeadores.
2. **Pel'tak (puente):** trono, asiento de piloto, armas, consolas de navegación y de mando.
3. **Sala de la puerta:** Stargate con DHD.
4. **Cubierta de mando:** aposentos con sarcófago, armería, núcleo informático.
5. **Ingeniería:** sala de motores, celdas, sala de escudos.
- Viajar entre cubiertas: [E] en un panel de anillos > elige la cubierta.
# Quién puede usarla
- La **tripulación** = quien es dueño de la nave y sus amigos (amigos de la protección de props).
- Los desconocidos pueden tomar la nave con el **cristal de control**. Mira {page:hatak_systems|Sistemas del Ha'tak}.
# Más
- {page:hatak_fly|Volar, saltar y armas}
# Menú maestro (toda la nave en una ventana)
- Ábrelo: [1] en el trono, en el asiento de piloto o como artillero, o [E] en la consola de mando del pel'tak.
- **SHIP:** casco, energía, escudos, quién vuela. Hiperespacio, armas, ingeniería, direcciones.
- **DOORS:** todas las puertas: abrir, cerrar, bloquear. Todas las puertas abiertas o cerradas a la vez.
- **SYSTEMS:** escudos, camuflaje, alarma, cierre total, diario de la nave, autodestrucción.
- {page:hatak_systems|Power, ordenador, escudos, daño y salas}
]] },

{ id = "hatak_fly", title = "Ha'tak: volar, saltar, luchar", icon = "icon16/arrow_up.png", body = [[
= Siéntate en el asiento de piloto del pel'tak. W/S/A/D para volar, R para el hiperespacio, V para la cámara. Armas en la consola de armas.
# Toma el timón
1. Ve al pel'tak (puente).
2. Siéntate en el **trono** ([E]) o en el asiento de piloto ([E] en la consola de piloto).
3. Deja el asiento con [E].
- El trono va primero: si los dos están ocupados, vuela el trono.
- [1] abre el **menú maestro** (también como artillero).
- El frente de la nave es el lado del hangar: [W] vuela hacia allí.
# Teclas de vuelo
- [W] adelante, [S] atrás.
- [A] / [D] girar a la izquierda / a la derecha.
- [Space] subir, [Ctrl] bajar.
- Mantén [Shift]: 4 veces más rápido.
- [V]: cámara. Empieza detrás y por encima de la nave (rueda del ratón = distancia). Después: el asiento, luego la vista desde la punta delantera.
- La ventana del pel'tak muestra la vista real del exterior.
- [R]: menú de hiperespacio.
- Sin piloto: la nave frena y se detiene.
> Quien está a bordo no resbala mientras la nave vuela.
# Salto al hiperespacio
1. Pulsa [R] en el asiento de piloto (o [E] en la consola de navegación).
2. Elige un destino: marcas guardadas, un Stargate u otra persona. O escribe x y z.
3. Haz clic en **Jump**. La nave se carga (3 s), se abre una ventana, vuelas a través.
- **Save mark 1/2/3 here** guarda el lugar.
- Necesita 30 % de power del hiperimpulsor. 8 s de pausa entre saltos.
# Armas
- [E] en la **consola de armas**: radar desde arriba y una lista de objetivos.
- **OFF:** sin disparos. **DEFEND:** dispara solo a lo que atacó la nave. **AUTO:** también a NPC y desconocidos.
- **FIRE:** una salva al objetivo elegido. **KEEP FIRING:** una y otra vez.
- **MANUAL (GUNNER)** o siéntate en el asiento de artillero: apuntas tú.
## Teclas de artillero
- El ratón apunta, [Mouse1] disparar, mantén [Mouse2] para zoom.
- [R] siguiente grupo de cañones (arriba, delante, lados, atrás, abajo).
- [E] salir.
! Disparar quita tu propio camuflaje.
]] },

{ id = "hatak_systems", title = "Sistemas y salas del Ha'tak", icon = "icon16/cog.png", body = [[
= Los cristales dan energía a todo. Saca uno y un sistema se debilita. El núcleo informático gestiona anillos, puertas, sensores y mensajes.
# Sala de motores: cristales de power
- El núcleo de energía (hub) tiene 3 cristales. Las bandejas tienen 3 cristales cada una: **Weapons**, **Hyperdrive**, **Engines**, **Shields**.
- [E] en un cristal: lo sacas y lo llevas.
- [E] en un hueco libre: lo pones.
- Los cristales quemados (oscuros) vienen de golpes fuertes. Ponlos en el **soporte de repuesto**: se recargan en 60 s.
- Los dos generadores de naquadah: [E] los enciende (+15 % cada uno).
- **Cuarto brazo del hub:** un cristal más (+15 %) o un **ZPM** (130 %). Acerca el ZPM con la pistola de gravedad: encaja.
- **Consola de ingeniería:** muestra toda la energía. Los botones envían más power a un sistema.
# Núcleo informático: cristales de datos
- Cristales azules en 4 soportes: **Rings**, **Doors**, **Sensors**, **Communication**. 2 de 3 deben estar puestos, o esa función se detiene.
- **Autodestrucción:** 1, 2 o 4 minutos. **ABORT** la detiene.
- **Registro de la nave:** lo que pasó a bordo.
- **Direcciones:** todas las puertas del mapa. **DIAL** marca desde la sala de la puerta.
- **Seguridad:** alarma sí/no, bloqueo (todas las puertas cerradas con llave, la tripulación aún puede abrirlas).
# Escudos y camuflaje
- Consola de la sala de escudos o consola de mando: **RAISE / LOWER SHIELDS**.
- **AUTO:** los escudos suben solos cuando alguien ataca.
- El escudo detiene todas las armas, también las del dueño: los disparos se paran en la burbuja dorada.
- **CLOAK:** la nave se desvanece. Necesita 30 % de power de escudo. Los escudos caen mientras estás camuflado.
# Soporte vital
- Aire, calor y gravedad a bordo, también en el espacio.
- Necesita energía del núcleo y un casco por encima del 10 %. Sin él, dentro es como fuera (sin aire en el espacio).
- Menú maestro: estado en SHIP, encender/apagar en SYSTEMS.
# Daño
- Solo cuentan los golpes fuertes. Mientras el escudo aguanta, recibe los golpes.
- Las explosiones **dentro** duelen el doble y queman los cristales cercanos.
- Alarma al 50, 25 y 10 % de casco. A 0 la nave explota (los admins pueden desactivarlo).
- La **herramienta de reparación** repara el casco.
# Salas
- **Bahía de planeadores:** 4 Planeadores de la muerte. [E] = volar. Sal volando por el túnel de lanzamiento. Los planeadores perdidos vuelven tras 60 s.
- Los túneles de lanzamiento tienen puertas por dentro y por fuera. Se abren solas cuando vuelas hacia ellas con un planeador. Ábrelas o ciérralas en el menú maestro.
- **Cuartel:** [E] en la consola de la litera = reapareces a bordo. Cofre de armadura: [E] = +50 de armadura (una vez por minuto).
- **Kel'no'reem:** agáchate ([Ctrl]) sobre una esterilla = te curas despacio.
- **Sarcófago:** [E] para tumbarte dentro y curarte.
- **Armas:** [E] sobre una Staff weapon de la pared: la coges (a los 2 minutos hay una nueva). [E] sobre un cofre de zat: una zat.
- **Celdas:** [E] en el panel junto a una celda activa o desactiva su campo de fuerza (solo tripulación).
# Tomar la nave (secuestro)
1. Busca el **cristal de control** escondido en algún lugar del interior. [E] lo recoge.
2. Ve a la ranura del cristal en el pel'tak (pared derecha). [E] empieza.
3. Quédate cerca 40 s. Suena la alarma.
4. Listo: tú y tus amigos sois la nueva tripulación.
- La tripulación anterior puede pararlo: [E] en la ranura.
]] },

{ id = "glider", title = "Planeador de la muerte", icon = "icon16/bullet_go.png", body = [[
= Pequeño caza goa'uld. W para volar, ratón para dirigir, Mouse1 para disparar. Sin pulsar tecla, flota.
# Cómo conseguirlo
- [Q] > Ascension Gates > **Flota: Naves y cazas** > Death Glider. O en la bahía de planeadores del Ha'tak.
# Teclas
- [E] en el planeador: subir. [E] otra vez: bajar.
- [W] volar hacia delante, [S] despacio hacia atrás. Mantén [Shift]: más rápido.
- Ratón: dirigir.
- [1]: vista de cabina activada / desactivada.
- Sin tecla: se queda en su sitio en el aire.
- [Mouse1]: disparar los dos cañones de bastón.
- Rueda del ratón: girar sobre sí. [Mouse3]: volver a nivelar.
- Teclas de flecha: distancia y altura de la cámara.
- [Backspace]: autodestrucción.
# Vuelo libre (ajuste del servidor)
- Con **agp_glider_free_flight 1**: [S] atrás, [A] / [D] a los lados, [Space] subir, [Ctrl] bajar.
# HUD
- Abajo a la izquierda: casco, velocidad, cañones de bastón, las teclas.
- 300 de casco. A 0 explota.
> Cambiar las teclas: {page:keys|Cambiar teclas}.
]] },

{ id = "alkesh", title = "Al'kesh y otras naves", icon = "icon16/bullet_go.png", body = [[
= En cada nave: E para subir y bajar, W/A/S/D y ratón para volar, Mouse1 para disparar.
# Al'kesh
- [Q] > Ascension Gates > **Flota: Naves y cazas**. Apunta al suelo para crearlo.
- [W] [S] [A] [D] volar. [Space] subir, [Ctrl] bajar. Mantén [Shift]: más rápido.
- [Mouse1] disparar. Rueda del ratón girar sobre sí, [Mouse3] nivelar otra vez.
- [Enter]: modo de aterrizaje (se queda nivelado).
- [E] bajar. [Backspace] autodestrucción.
# Naves capitales
- Aurora, Destiny, Gate Seeder, O'Neill, Ori Mothership, Prometheus, Replicator Mothership, Traveler, Wraith Cruiser.
- Las mismas teclas que el Al'kesh. Además [Mouse2] seguir objetivo, [G] escudo.
# Naves pequeñas
- **Puddle Jumper:** [Mouse1] drones (abre las vainas solo), [Mouse2] mantener = los drones siguen tu punto de mira, [Alt] camuflaje, [2] puerta, [T] flotar, [G] escudo, [R] marcar la puerta más cercana.
- **Tel'tak:** [Mouse2] cañones de bastón, [G] escudo, [Alt] camuflaje, mantén [R] hiperespacio, [2] puerta. Rayo de anillos: [Enter] (modo aterrizaje), luego [Mouse1].
- **F-302:** [Mouse1] cañones, [Mouse2] misiles, [Alt] bengalas, [B] impulso, [2] eyectarse.
- **Daedalus:** [Mouse1] cañones de riel, [Mouse2] rayo asgard, [1] a [8] misiles.
- **Wraith Dart:** [C] recoger gente, [Alt] soltarla.
> Cambiar las teclas: {page:keys|Cambiar teclas}.
]] },

{ id = "spacegrid", title = "PowerGrid: power y energía", icon = "icon16/lightning.png", body = [[
= PowerGrid es la pestaña de herramientas para la energía. Coloca piezas de energía, únelas, aliméntalas con ZPM o generadores.
# Dónde
- [Q] > lado derecho > pestaña **PowerGrid**.
- **PowerGrid:** la herramienta Piezas de PowerGrid (todas las piezas en una cuadrícula de imágenes).
- **Energía:** ZPM, hubs de ZPM, generadores de naquadah, hub de energía goa'uld, Enlace PowerGrid.
- **Ajustes:** ajustes de PowerGrid y esta ayuda.
# Colocar una pieza
1. Coge la herramienta **Piezas de PowerGrid**.
2. Haz clic en una imagen de la derecha (por ejemplo una celda de energía).
3. Apunta a donde debe ir. Ves un fantasma de ella.
4. Clic izquierdo [Mouse1]: colocada. Clic derecho [Mouse2]: colocada girada 90 grados.
- Apunta a una pieza y pulsa [R]: esa pieza queda elegida.
- En una nave o prop se suelda a lo que apuntas (casilla **Weld to what I aim at**).
# Las piezas
- **Celdas de energía (XS a XL):** guardan energía.
- **Paneles solares:** producen energía mientras hay cielo abierto encima.
- **Turbina eólica:** produce energía, más cuanto más alto está.
- **Energía de agujero negro:** guarda todos los recursos (solo admins, salvo que se permita).
- **Nodos de energía:** unen todo lo que se coloca sobre ellos. Su pantalla muestra la red.
- **Pantallas de energía:** muestran la red a la que están unidas.
- **Válvula de energía:** encendida = la energía fluye entre dos redes, apagada = están separadas. [E] la cambia.
- **Tanques de recursos:** guardan un recurso (oxígeno, agua ...). [E] cambia el recurso mientras está vacío.
- **Soporte vital:** mira {page:lifesupport|Soporte vital}.
# Unir (cómo comparten energía las piezas)
- Los admins eligen el modo: **Manual**, **Automatic**, **Mix** u **Off** (ajustes de PowerGrid).
- **Manual:** herramienta **Enlace PowerGrid**: clic izquierdo en las piezas (se ponen azules), clic derecho en la pieza o nodo de energía al que se unen. [R] borra la selección; [R] en una pieza quita sus uniones.
- **Automatic:** las piezas soldadas entre sí comparten solas.
- **Off:** todo tiene energía libre.
! ¿Spacebuild instalado? Entonces se usa la red de Spacebuild. Nuestros nodos de energía son entonces nodos de Spacebuild: únelos con la herramienta Enlace PowerGrid. Los admins pueden activar **Siempre PowerGrid**.
# Fuentes de energía
- **ZPM:** herramienta **ZPM MK III**. Ponlo en un hub de ZPM o en un {page:goauldpower|hub de energía goa'uld}.
- **Generador de naquadah:** herramienta en Energy.
- **Cristales de energía goa'uld:** en el {page:goauldpower|hub de energía goa'uld}.
]] },

{ id = "goauldpower", title = "Hub de energía goa'uld y cristales", icon = "icon16/rainbow.png", body = [[
= Un hub de latón con un núcleo de energía dorado. Sus 4 brazos aceptan cristales de energía goa'uld o ZPM. El núcleo brilla más cuanto más power tiene.
# Cómo conseguirlo
- Herramienta: [Q] > PowerGrid > Energía > **Goa'uld Power Hub + Crystals**.
- O pestaña de creación: Ascension Gates > **PowerGrid**.
# Usarlo
1. Clic izquierdo [Mouse1] con la herramienta: un hub.
2. Apunta a un brazo y clic derecho [Mouse2]: un cristal queda en ese brazo.
3. ZPM: coge la herramienta de ZPM, apunta a un brazo, clic izquierdo: el ZPM queda en ese brazo.
4. Une el hub a tu red como cualquier otra pieza ({page:spacegrid|PowerGrid}).
- Acerca un cristal o un ZPM a un brazo (pistola de gravedad o physgun): encaja.
- [E] en un cristal o ZPM: sale.
- [E] en el hub: muestra cristales, ZPM y energía en el chat.
- Mira el hub: una placa pequeña muestra cristales y energía.
> Un ZPM da diez veces el power de un cristal y fuerza más el núcleo.
# Control deslizante en la herramienta
- **Crystal charge:** cuán llenos están los cristales nuevos (0 a 100 %).
]] },

{ id = "lifesupport", title = "Soporte vital y espacio", icon = "icon16/heart.png", body = [[
= En el espacio no hay aire y hace frío. Tu traje te protege un tiempo. El soporte vital hace seguro una nave o una zona.
# ¿Cuándo está activo?
- Los admins eligen: solo mapas de espacio (por defecto), todos los mapas o apagado ({page:admin|Ajustes para admins}).
# Tu traje
- Tres valores: **aire**, **energía**, **refrigerante**. Llenos al aparecer.
- Sin aire o bajo el agua: el aire baja. Buen aire: se vuelve a llenar.
- Frío: la energía baja. Calor: el refrigerante baja.
- Un valor en 0 te hace daño.
- Una caja abajo a la izquierda aparece solo cuando algo va mal.
# Life Support Core
- En una nave: toda la nave recibe aire. [E] lo activa o desactiva.
- Fuera de una nave: una burbuja de aire. [E] cambia el tamaño (300 a 2000, luego apagado).
- Necesita energía y oxígeno (hace oxígeno con agua).
# Rellenar tu traje
- **Suit Dispenser:** [E] rellena aire, energía y refrigerante desde su red.
- **Air Compressor:** oxígeno a partir de aire respirable. **Water Pump:** agua mientras está en el agua.
# Informe de la puerta
- Cuando una puerta marca, recibes un informe corto: aire, temperatura, gravedad del otro lado, y si necesitas un traje.
]] },

{ id = "weapons", title = "Armas de mano", icon = "icon16/bomb.png", body = [[
= Las encuentras en [Q] > Ascension Gates > Armas. Mouse1 = uso principal, Mouse2 = segundo uso.
# Goa'uld
- **Zat'nik'tel:** el 1.er disparo aturde, el 2.º mata, el 3.º lo hace desaparecer.
- **Staff weapon:** [Mouse2] prepararla, [Mouse1] disparar.
- **Hand device:** [Mouse1] usar, [Mouse2] siguiente modo.
- **Healing device:** mantenlo sobre una persona para curarla.
- **Mobile DHD:** ponlo en una puerta.
# Tierra (SGC)
- **P90 (PDW):** [Mouse1] disparar, [Mouse2] apuntar, [R] recargar.
- **Beretta:** [Mouse1] disparar, [R] recargar.
- **GDO:** [Mouse2] escribir código, [Mouse1] enviar.
# Otras
- **Ori hand weapon / staff, Wraith blaster, Ronon's gun, Asuran gun.**
- **Tac:** lanzar, otra vez = explotar. [Mouse2] matar / aturdir / humo.
- **Repair tool:** mantenla sobre una nave, puerta o DHD para repararlo.
- **Silla de control (Antigua, pestaña Armas):** [E] para sentarte (necesita un ZPM cargado en su hub). [1] = lista de objetivos: fija los drones en un objetivo, o apunta libremente.
- **Personal shield, Sodan cloak:** [Mouse1] encender, [Mouse2] apagar.
- **Dispositivo de imagen mimética:** mantén [Mouse1] sobre una persona justo delante de ti para capturarla, [Mouse2] proyección sí / no, [R] borrar la imagen.
]] },

{ id = "keys", title = "Cambiar teclas", icon = "icon16/keyboard.png", body = [[
= Las teclas de las naves se pueden cambiar en la mayoría de las naves pequeñas, en el menú Keybinders.
# Cómo
1. [Q] > lado derecho > Ascension Gates > **Keybinders**.
2. Elige la nave.
3. Haz clic una vez en una línea y rápido otra vez (se pone naranja).
4. Pulsa la nueva tecla o botón del ratón. [Esc] cancela.
- Naves: Daedalus, Wraith Dart, Gate Glider, Death Glider, F-302, Puddle Jumper, MALP, Destiny Shuttle, Tel'tak.
# Ha'tak
- El Ha'tak usa tus teclas normales de GMod ([W] [A] [S] [D] [Space] [Ctrl] [Shift] [R]) y [V].
- Para tu propia tecla: asígnala a **agp_hatak_camera** (consola: bind KEY agp_hatak_camera).
]] },

{ id = "admin", title = "Ajustes para admins", icon = "icon16/shield.png", body = [[
= Los admins (y tú en un solo jugador) cambian los ajustes del servidor. Los demás solo los ven. Pasa el ratón por un ajuste para ver un consejo corto.
# Ajustes de naves: [Q] > Ascension Gates > Config > Naves AGP
- **Hijacking:** solo tripulación / con el cristal de control / cualquiera.
- **Weapons fire at owner and friends:** sí o no.
- **Weapon + radar range:** hasta dónde disparan los cañones y ve el radar.
- **Radar: most targets shown.**
- **Power crystals strangers may pull:** 0 a 15 (por defecto 2). La tripulación no tiene límite.
- **Ship can be destroyed:** sí (por defecto) o no (el casco se queda en 1).
- **Hull health (new ships):** 10.000 a 1.000.000 (por defecto 100.000).
- **Cloak allowed:** sí o no.
- **Glider bay: lost gliders come back:** sí o no, y tras cuántos segundos (por defecto 60).
- **Shield bubble (all ships):** solo al recibir un impacto o al encenderlo o apagarlo (por defecto), o siempre visible.
- **Self-destruct countdown (all ships):** de 1 a 600 segundos (por defecto 5).
# Ajustes de energía: [Q] > PowerGrid > Ajustes > PowerGrid
- **How parts connect:** Manual / Automatic / Mix / Off. Mira {page:spacegrid|PowerGrid}.
- **Siempre PowerGrid:** usar PowerGrid incluso con Spacebuild (necesita cambiar de mapa).
- **Energía de agujero negro:** solo admins o todos.
- **Space simulation:** solo mapas de espacio / todos los mapas / apagado. Mira {page:lifesupport|Soporte vital}.
- **Gate destination report:** sí o no.
# Solo para ti (cada jugador)
- Cables, sonidos de máquinas, informe de la puerta en tu pantalla, unidades de distancia, temperatura y gravedad.
]] },

{ id = "problems", title = "Problemas y soluciones", icon = "icon16/help.png", body = [[
= ¿Algo no funciona? Mira aquí primero.
# Los iconos del menú Q se ponen rosa y no aparece nada
- Estás pulsando [Ctrl] (o se quedó atascada). [Ctrl] + clic **selecciona** iconos (rosa) en vez de crearlos.
- Solución: suelta [Ctrl] (púlsala una vez), haz clic en un sitio vacío de la zona de iconos.
# Hago clic en un icono y no aparece nada
- Mira al suelo delante de ti, no al cielo lejano.
- Las naves grandes aparecen muy altas sobre el suelo o delante de ti. Mira alrededor.
- Los admins pueden desactivar piezas o limitarlas (Ascension Gates > Config > Acerca de y créditos > Ajustes).
# El planeador cae
- El Planeador de la muerte mantiene su altura cuando no pulsas ninguna tecla. ¿Está cayendo? Puede estar destruido o fuera del mapa.
# Una consola del Ha'tak dice "crew only"
- Solo quien es dueño de la nave y sus amigos pueden usarla. O toma la nave con el cristal de control ({page:hatak_systems|Sistemas del Ha'tak}).
# Un sistema de la nave dice OFFLINE
- Revisa los cristales en la sala de motores y los cristales de datos azules en el núcleo informático.
# Me quedo atascado en un umbral o una puerta
- Los umbrales de los interiores de naves no te dejan pasar si el otro lado está cerrado. Abre primero la puerta.
- Sigue atascado: noclip ([V]) o reaparece.
# Una herramienta muestra texto como #tool.something.name
- Falta un texto. Dinos qué herramienta es, por favor.
]] },

},
}
