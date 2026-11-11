# Changelog

Los cambios importantes de Caritatos Legends se documentan aquí. El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el versionado es semántico.

## [Sin publicar]

### Añadido
- **La Leyenda de las Cajas** (`crates_legend`): al terminar una oleada, si un jugador tiene cajas normales por abrir, puede fusionarlas en una caja legendaria.
  - La primera fusión de la partida pide 3 cajas; cada fusión suma 3 más (6, 9), hasta un máximo de 9. Los tres valores se ajustan.
  - Ventana «¡Fusión de cajas!»: las cajas botan, vuelan juntas, destellan y sale una caja legendaria morada y dorada que se abre con las demás.
  - El juego se pausa mientras se decide. En cooperativo responde el mando de cada jugador.
- **La Leyenda de la Fusión** (`fusion_legend`, recreación independiente de Genetically Modified Overkill, de Flabort): al empezar la partida, cada jugador puede fusionarse con otro personaje y sumar todos sus efectos.
  - Penalizaciones configurables: -10 % de experiencia, +20 % de precios, +20 % de enemigos y +10 % de velocidad enemiga.
  - Ventana «¡Fusión de bros!» con una cuadrícula de personajes, sus efectos y un choque de puños al confirmar.
  - Apagada por defecto, con aviso de que es muy fuerte.
- `docs/CATALOGO_MODS.md`: BroEditor (mojimoon) como alternativa al editor de personajes y objetos propuesto.
- **El Taller de los Tatos** (`studio_legend`), para usar junto a **BroEditor** (Mojimoon), que es quien crea y edita personajes y objetos. La ficha avisa de que hace falta y tiene un botón para descargarlo.
  - **«Tus tatos»**: editor de píxeles de 50 × 50 sobre la patata del juego, con lápiz, goma, relleno, cuentagotas, deshacer y rejilla, paleta morada y color libre, e importación de PNG.
  - Los tatos se guardan, se pueden llevar puestos en las partidas (J1–J4) y, con BroEditor, se guardan también como iconos en su carpeta.
  - **Medidor de poder**: personajes y objetos (también los de BroEditor) de más a menos fuerte, con etiquetas Equilibrado, Fuerte, Muy fuerte o Roto frente a los del juego.
- Campo `actions` en `module.json`: botones en la ficha de una leyenda que llaman a su runtime. «Atrás» cierra la ventana que abren sin cerrar el menú.
- `docs/COMPATIBILIDAD.md`: BroEditor es compatible. Se documenta dónde coincide con Caritatopc.
- **La Leyenda del Ratón** (`mouse_legend`): el ratón se ve y funciona aunque haya mandos.
  - En cooperativo, el cursor aparece al mover el ratón y ya no lo esconden las pulsaciones de los demás. Recorre toda la pantalla, pero solo pulsa, usa la rueda y resalta en el panel del jugador con teclado y ratón (el J1 si todos usan mando).
  - Lo que se pulsa con el ratón cuenta como de ese jugador (extensión de `FocusEmulatorSignal`); antes el juego suponía el J1 o se equivocaba.
  - En solitario con un mando conectado, el cursor vuelve al mover el ratón, salvo durante la oleada.
  - Se oculta tras 5 s sin mover el ratón (ajustable; 0 = nunca).

### Corregido
- **Supermercado: al rerolear tras un encargo se bloqueaba un artículo al azar.**
  - El juego bloquea a la vista tantas casillas como bloqueados tenga, y contaba el encargo, que no está en esa tienda.
  - Ahora el encargo se aparta un momento de la lista de bloqueados mientras se rerolea.
  - De paso, con 3 artículos bloqueados más un encargo ya se puede rerolear.
- **Supermercado: los encargos ganados se perdían si no se gastaban en la tienda siguiente.** Ahora cada élite o jefe derrotado da un encargo que se guarda hasta gastarlo, también al continuar la partida (`user://caritato_legends/supermarket_run.json`). En el modo «en cada tienda» siguen sin acumularse.
- **El juego se cerraba al aceptar un regalo.**
  - Causa: tras el regalo se rehacían enteros los inventarios de los dos jugadores, y el foco del cooperativo (`FocusEmulator`) de quien recibía seguía apuntando a una casilla destruida. El juego publicado se cierra de golpe al volver a dibujarla.
  - Ahora, antes de tocar nada, el foco que estuviera sobre esos inventarios pasa al botón de reroll de cada jugador.
  - Además, se quita una casilla a quien regala y se añade otra a quien recibe, como hace el juego al reciclar o comprar (`modules/gift_legend/gift_shop_sync.gd`).
- **No se podía regalar un arma comprada en esa misma tienda** (salía «no lo tienes»): el juego guarda una copia del arma comprada. Ahora el arma u objeto se busca también por igualdad, con `ItemService.is_same_weapon` / `is_same_item`.

## [1.0.0] - Versión candidata (pendiente de probar en Brotato y de publicar)

### Corregido (cierre en solitario)
- **El juego se cerraba al entrar en la primera tienda en solitario.** Los registros apuntan a la extensión del menú del objeto (`ItemPopup`) de la versión anterior: era lo único del mod que actuaba en solitario y no en cooperativo, donde nunca llegaba al menú. Esa extensión ya no existe (pendiente de confirmar en el juego). La del menú cooperativo es ahora más prudente:
  - solo se prepara si el Regalo está activo en una partida cooperativa;
  - crea un botón nuevo en lugar de copiar el de Cancelar con su script;
  - cambia los vecinos de foco de Reciclar y Cancelar solo mientras Regalar está visible.
- **Marcas de diagnóstico** `[diag]` en `modloader.log` al terminar la oleada, al entrar en la tienda y al preparar el menú del Regalo. Ese registro se escribe línea a línea, así que, si el juego se cierra de golpe, la última marca dice dónde.
- `docs/COMPATIBILIDAD.md`: sección «Otros mods». FoxLab rompe la tienda en la 1.2 al cargarla durante su `_init`; PerfectHook hace lo mismo que la Leyenda del Anzuelo.

### Publicación
- Paquete para el Workshop Uploader de Brotato (artefacto `Caritatopc-Workshop` de la CI y `python tools/build.py --workshop`): ZIP con el título como nombre, portada de 512×512 dibujada con piezas del mod y descripciones en `workshop/`. Pasos en `docs/WORKSHOP.md`.

### Corregido
- **Regalar no aparecía en el menú del objeto**: al pulsar un arma u objeto en la tienda cooperativa sonaba pero no se abría nada con Regalar. El menú de la tienda cooperativa (`CoopItemPopup`) se compilaba antes que la extensión de `ItemPopup` y no la heredaba; ahora se extiende `CoopItemPopup` directamente. Si volviera a faltar, el log de ModLoader lo indica al abrir la tienda.
- **Pantalla Caritatopc en cooperativo**: en la pausa de una partida cooperativa no respondía al teclado ni al mando, porque los `FocusEmulator` del juego se comían la entrada. Ahora se pausan mientras la pantalla está abierta, y las acciones de cada mando (`ui_up_3`…) se reenvían como las normales.

### Cambiado
- **Estilo «bros» y morado**: el morado pasa a ser el color de Caritatopc (botones, bordes, superficies con un toque morado). El corazón se sustituye por un **choque de puños** dibujado por código (cabecera de Caritatopc, ventana del regalo y portada del Workshop), las partículas son estrellas y los textos del Regalo hablan entre colegas: «¡Regalo de tu bro!», «¡Choca!», «Paso, bro», «¡Bros para siempre!».
- **Regalo desde el menú del objeto**: el botón Regalar pasa al menú que sale al pulsar un arma u objeto propio en la tienda (junto a Reciclar y Cancelar), al que se llega bien con mando. Los objetos, que en el juego no tienen botones, muestran Regalar y Cancelar. Con más de dos jugadores se elige a quién en una ventana nueva. Se quitan el botón suelto del panel (no se alcanzaba con mando) y la ventana «Regalar» con la lista.

### Añadido
- **Mercader: «¡A regatear!»**: botón Regatear junto al reroll; parar la aguja en la zona verde rebaja un 10 % (configurable) los artículos de esa tienda, la mitad en la amarilla. Un intento por tienda; el reciclaje no cambia.
- **Cosecha Eterna: «Cosecha dorada»**: en cada tienda del modo infinito, cosechar el trigo cuando está dorado da un 10 % de la recolección en materiales (5 % si casi). No se repite al continuar una partida guardada.
- **Anzuelo: minijuego «¡Pica!»**: cuando aparece el Anzuelo garantizado, una escena de pesca (agua, corcho y sedal dibujados) en la que hay que pulsar Aceptar justo cuando el corcho se hunde. Si se pesca, la tienda da un reroll gratis; antes de tiempo el pez se asusta y tarde se escapa. Un intento por tienda; se puede desactivar.
- **Ventanas interactivas de las leyendas** (`ui/legend_popup.gd`): se abren de una en una (cola en el núcleo), responden al mando del jugador que toca y pausan los `FocusEmulator` de la tienda (`ui/focus_guard.gd`, también usado por el Regalo).
- **Supermercado: «¡Tu encargo ha llegado!»**: al entrar en la tienda a la que llega un encargo, aparece una caja que se abre a toques (Aceptar o clic, tres veces) con confeti y muestra lo que había dentro. Se puede desactivar.
- **Supermercado equilibrado**: aviso de opción muy fuerte (apagada por defecto); los encargos se ganan al derrotar a un élite o a un jefe (o en cada tienda, si se configura); cada encargo cuesta un recargo (50 % por defecto) y llega **bloqueado a la siguiente tienda**, guardado con la partida. Catálogo rediseñado en dos columnas con el recargo y el precio de cada artículo, y el botón muestra los encargos disponibles.
- **Regalo: quien recibe confirma.** Ventana «¡Regalo de tu bro!» con dos puños (el color de cada jugador) que chocan entre estrellas; al aceptar chocan fuerte y sale «¡Bros para siempre!». Solo responde el mando de quien recibe; quien regala puede retirarlo. La ventana «Regalar» adopta el estilo nuevo (tarjetas por objeto, botones con el color de cada jugador).
- **Nueva pantalla de configuración con forma de biblioteca**: tarjetas por leyenda con su color, inicial y estado a la izquierda; ficha de la leyenda a la derecha con interruptores dibujados (en lugar de casillas), deslizadores con estilo propio y un recuadro que explica el ajuste seleccionado. Paleta, botones y choque de puños animado comunes en `ui/ui_style.gd` y `ui/widgets/`.
- Campos opcionales en `module.json`: `short_name_key`, `accent` y `warning_key`.
- CI: trabajo «Capturas de la interfaz» que abre las ventanas con Godot 3.6 en una pantalla virtual y guarda capturas (artefacto y rama `capturas-ui`).
- **La Leyenda del Regalo** (`gift_legend`, cooperativo): botón «Regalar» en el panel de cada jugador de la tienda cooperativa. Abre una ventana con sus armas y objetos y deja dárselos a otro jugador; las armas conservan mejoras, maldición o mecanización. Respeta huecos de arma, máximos por objeto, prohibiciones y restricciones del personaje que recibe, armas bloqueadas y el bando de evolución (solo meca / solo mutante). Nunca se regalan el personaje, el Tumor, los saltos evolutivos, la torreta del Constructor ni los objetos que se transforman al quitarlos. Ajustes: objetos, armas, última arma, malditos y regalos por tienda. La ventana se maneja con ratón, teclado o cualquier mando.

### Corregido
- **Compatibilidad con Brotato 1.2**: las extensiones de scripts de escenas (tienda, `main.gd`, menús) se instalan en `_ready` y no en `_init`. En 1.2.0.1, cargar la tienda durante `_init` rompía su compilación y el juego desactivaba todos los mods en el siguiente arranque.
- El Anzuelo ya no consulta la lista de objetos al arrancar (en 1.2 se quedaría en caché sin los objetos de los DLC).
- La comprobación de DLC en la partida usa los «conjuntos de objetos» de la 1.2 (`RunData.active_update_data_ids`).
- Instrucciones de instalación local: la versión de Steam no lee la carpeta `mods`; el ZIP de prueba va en la carpeta de un mod del Workshop al que se esté suscrito (`README.md`, `docs/PRUEBAS.md`, `docs/COMPATIBILIDAD.md`).

### Cambiado
- El botón del menú principal y del de pausa pasa a llamarse **Caritatopc**.
- Descripciones de las leyendas más breves; las explicaciones de cada ajuste aparecen al seleccionarlo.
- `compatible_game_version`: 1.2.X.X y 1.1.15.4.
- Validación: las extensiones deben replicar la ruta del script que extienden.

## [0.2.0] - 2026-11-06

Versión candidata: completa en pruebas automáticas, pendiente de probar dentro de Brotato antes de publicarla.

### Añadido
- **La Leyenda del Anzuelo** (`hook_legend`, Abyssal Terrors): Anzuelo garantizado al entrar en la tienda de la oleada elegida (por defecto, la 4), opción de repetirlo hasta tener uno y probabilidad de maldición por anzuelo configurable (1-100 %). Respeta objetos bloqueados, prohibidos y el máximo de anzuelos.
- **La Leyenda de la Cosecha Eterna** (`endless_harvest`): pérdida de recolección por oleada del modo infinito configurable (0-100 %, por defecto 0 %; el juego quita un 20 %), opción de seguir creciendo como en las oleadas 1-20 (Granjero y Corona incluidos) y Hucha que sigue dando interés tras la oleada 20. El texto de la estadística de Recolección refleja la configuración.
- **La Leyenda del Mercader** (`merchant_legend`): precio de los artículos (10-300 %) y de los rerolls (0-300 %, 0 % = gratis), con opción de que no se encarezcan con las oleadas. Valores por defecto neutros.
- **La Leyenda del Supermercado** (`supermarket_legend`): botón en la tienda (un jugador) que abre un catálogo con los objetos y armas que el juego podría ofrecerte; el elegido se coloca en un hueco libre o en el último no bloqueado y se compra con las reglas del juego. Encargos por tienda (1 por defecto), coste del encargo, tier máximo y armas configurables.
- Ajustes que dependen de que otro esté apagado (`"depends_on": "!clave"`).
- Validación: los miembros propios de las extensiones llevan prefijo `_clc_` y no pueden repetirse entre extensiones del mismo script.
- Pruebas GDScript de arranque completo del núcleo con las leyendas reales y de la pantalla de configuración, con sustitutos de ModLoader.

## [0.1.0] - 2026-11-06

### Añadido
- Mod único `Caritato-LegendsCollection` para ModLoader 6.3.0 (Brotato 1.1.15.4).
- Núcleo modular: definiciones de leyendas en `modules/<id>/module.json`, validación de ids, ajustes, dependencias, conflictos y ciclos; una leyenda con errores se desactiva sin afectar a las demás.
- Configuración persistente en `user://caritato_legends/settings.json` con valores por defecto, saneado de tipos y rangos, y recuperación (con copia de seguridad) si el archivo está dañado.
- Pantalla **Leyendas** en el menú principal y en el menú de pausa: activar/desactivar, ajustes, restaurar valores por defecto, cancelar y guardar, avisos de reinicio, dependencias, DLC y compatibilidad.
- Capa de compatibilidad `core/compat.gd` y textos en español e inglés.
- Herramientas: `tools/validate.py`, `tools/build.py` (ZIP reproducible), `tools/run_gdscript_tests.py`; pruebas en Python y GDScript; CI en GitHub Actions.
- Documentación del proyecto, catálogo inicial de leyendas y registro de decisiones.
