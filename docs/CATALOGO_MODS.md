# Catálogo de leyendas

Mods clásicos candidatos a entrar en la colección. Una leyenda puede agrupar varios mods originales que tocan la misma mecánica.

Estados: `Por investigar` · `Pendiente de permiso` · `Apto para reutilización` · `Recreación independiente` · `En desarrollo` · `Incluida (sin probar en el juego)` · `Recuperado y probado` · `Bloqueado`.

Fuentes consultadas el 2026-11-06: repositorios públicos de GitHub y buscadores. Steam Workshop y la wiki de Brotato no eran accesibles desde el entorno de desarrollo, así que los datos de Workshop proceden de resultados de búsqueda y deben confirmarse en su página.

## Pedidas por Mauro

| Leyenda | Mods originales | Autor | Workshop / código | Qué hacía | Licencia | Vía | Estado |
|---|---|---|---|---|---|---|---|
| **La Leyenda del Anzuelo** (`hook_legend`) | Mod de anzuelo garantizado en la tienda de la oleada 4 | Por identificar | Por identificar | El Anzuelo (Abyssal Terrors) aparece sí o sí en la tienda de la oleada 4 | — | Recreación independiente | Incluida (sin probar en el juego) |
| | Mod de probabilidad del anzuelo configurable | Por identificar | Por identificar | Cambia la probabilidad de maldición de cada anzuelo | — | Recreación independiente | Incluida (sin probar en el juego) |
| | Guaranteed Curse | Xterionix | [GitHub](https://github.com/Xterionix/BrotatoMod-GuaranteedCurse) | Garantiza que al menos un objeto bloqueado se maldiga | Sin licencia | Recreación (cubierta con probabilidad 100 %) | Referencia |
| | ImperfectHook (obsoleto) | mojimoon | [GitHub](https://github.com/mojimoon/BrotatoMods/tree/main/deprecated/Mojimoon-ImperfectHook) | El anzuelo maldice siempre los objetos bloqueados | Sin licencia | Referencia | Referencia |
| **La Leyenda de la Cosecha Eterna** (`endless_harvest`) | No Harvesting Decay | Windows98 | Workshop 3120330525 (retirado, «OUTDATED») | Sin pérdida de recolección tras la oleada 20 | — | Recreación independiente | Incluida (sin probar en el juego) |
| | Infinite Bank and Harvesting | Hypermarine_AuT | Workshop (página no localizada) | Hucha y recolección siguen funcionando tras la oleada 20 | — | Recreación independiente | Incluida (sin probar en el juego) |
| | Piggy Bank And Harvest Work After 20 Waves | dreadhead | Workshop 3638873783 | Igual que el anterior, actualizado | — | Recreación independiente | Referencia |
| | Endless-less | dami | Workshop 2938652633 | Hucha/recolección en infinito y deslizadores de escalado infinito | — | Recreación independiente | Referencia |
| | Stronger Harvesting | CommanderAstern | [GitHub](https://github.com/CommanderAstern/brotato-stronger-harvesting), Workshop 3780496839 | Crecimiento base de recolección configurable y crecimiento en infinito | Sin licencia | Referencia | Referencia |

## Leyendas propias

| Leyenda | Origen | Qué hace | Estado |
|---|---|---|---|
| **La Leyenda del Regalo** (`gift_legend`) | Petición de Mauro | Regalar objetos y armas entre jugadores en cooperativo | Incluida (sin probar en el juego) |
| Mejora de cajas a legendaria | Idea de Mauro (pendiente) | Con 3 cajas, opción de convertir una en legendaria; después cada 6 y cada 9 | Pendiente de valorar |

## Candidatas para siguientes versiones

| Mod | Autor | Workshop / código | Qué hace | Licencia | Dificultad | Estado |
|---|---|---|---|---|---|---|
| Supermarket (超市) | duyang97 | Workshop 2993532272 (retirado por Steam) | Botón en la tienda que muestra más artículos a la venta | Desconocida | Media | Incluida como **La Leyenda del Supermercado** (recreación) |
| Rainbow Crate | Pasha (boardengineer) | [GitHub](https://github.com/boardengineer/Brotato-Rainbow-Crate) | Cajas arcoíris que permiten elegir cualquier objeto | **Apache-2.0** | Media | Apto para reutilización |
| SIFD's Mod (sin inflación / reroll fijo) | SIFD | Workshop | Precios de tienda y de reroll sin escalar por oleada | Desconocida | Baja | Incluida como **La Leyenda del Mercader** (recreación) |
| FreeRerolls | — | Workshop | Rerolls gratis | Desconocida | Baja | Incluida como **La Leyenda del Mercader** (recreación) |
| Shoptato | — | Workshop | Todas las armas comprables en la tienda | Desconocida | Media | Por investigar |
| Second Chance | Nailim | [GitHub](https://github.com/Nailim/brotato-mod-secondchance) | Al morir, vuelve una oleada atrás en vez de perder la partida | **MIT** | Media | Apto para reutilización |
| DPS Meter | LRueckert | [GitHub](https://github.com/LRueckert/brotato-mod-dps-meter) | Medidor de daño por arma durante la oleada | Sin licencia | Media | Por investigar (recreación) |
| Damage Meter / QuickEquip | Oudstand | [GitHub](https://github.com/Oudstand/Brotato-Mods) | Medidor de daño y equipamiento rápido | Sin licencia | Media | Por investigar |
| Widescreen support | DawidFrankiewicz | [GitHub](https://github.com/DawidFrankiewicz/brotato-hax-widescreen-support) | Soporte de pantallas panorámicas | **MIT** | Baja | Apto para reutilización |
| Full-map camera | L1SC | [GitHub](https://github.com/L1SC/brotato-full-map-camera) | Cámara que muestra todo el mapa | **MIT** | Baja | Apto para reutilización |
| Rolls Left | otDan | [GitHub](https://github.com/otDan/Brotato-RollsLeft) | Contador de rerolls en la tienda | Sin licencia | Baja | Por investigar (recreación) |
| Invasion | Darkly77 | [GitHub](https://github.com/BrotatoMods/Brotato-Invasion-Mod) | Gran expansión de contenido (Space Gladiators) | Sin licencia | Alta | Pendiente de permiso |

## Pruebas por leyenda

### La Leyenda del Anzuelo (`hook_legend`)

Cómo funciona en el juego (verificado en el código de 1.1.14.5 con Abyssal Terrors):
- El Anzuelo (`item_fish_hook`, tier 2, máximo 3) da el efecto `curse_locked_items` (20 por anzuelo en esos datos) y +1 de Maldición.
- Al salir de la tienda, cada objeto o arma bloqueado tiene `(pity + curse_locked_items) %` de maldecirse. Si no se maldice ninguno, el «pity» sube `bloqueados_sin_maldecir × curse_locked_items / 4`.
- La leyenda cambia el valor de ese efecto, así que la probabilidad, el «pity» y el texto del objeto usan el valor configurado. Los anzuelos ya comprados conservan el valor con el que se compraron.
- «Tienda al terminar la oleada N» es la tienda en la que `RunData.current_wave == N` (su botón dice «Ir (Oleada N+1)»).

- **Rasgo propio: «¡Pica!».** En la tienda donde se garantiza el Anzuelo aparece una escena de pesca: el corcho flota entre 1,4 y 3,2 s y se hunde 0,75 s. Pulsar Aceptar (o clic) mientras está hundido pesca y la tienda suma un reroll gratis (`BaseShop._free_rerolls`, que el juego guarda con la partida). Un intento; ajuste «Minijuego «¡Pica!»».

Pruebas manuales (Brotato con Abyssal Terrors activo):
- [ ] Partida nueva, valores por defecto: en la tienda tras la oleada 4 aparece el Anzuelo sustituyendo un objeto (no un arma ni un artículo bloqueado).
- [ ] Al rerolear desaparece como cualquier artículo (salvo que se bloquee).
- [ ] Con «Repetir hasta tener uno»: si no se compra, vuelve en la tienda 5, 6…; tras comprarlo deja de forzarse.
- [ ] Con el Anzuelo prohibido (sistema de prohibiciones) o con 3 anzuelos, no se fuerza.
- [ ] Con «Probabilidad personalizada» al 100 %: el texto del Anzuelo indica 100 % y al salir de la tienda se maldicen todos los artículos bloqueados.
- [ ] Al apagar la probabilidad personalizada, el texto vuelve al valor del juego.
- [ ] Sin el DLC activo, la leyenda no hace nada y la pantalla avisa de que necesita Abyssal Terrors.
- [ ] Cooperativo: cada jugador recibe su Anzuelo en su tienda.
- [ ] «¡Pica!»: al aparecer el Anzuelo garantizado sale la escena de pesca; pulsar con el corcho hundido da un reroll gratis (el botón de reroll muestra 0).
- [ ] Pulsar antes o después no da nada; Atrás cierra sin pescar. Con el ajuste apagado no sale.

### La Leyenda de la Cosecha Eterna (`endless_harvest`)

Cómo funciona en el juego (verificado en el código de 1.1.15.4):
- Al final de cada oleada, `Main._on_HarvestingTimer_timeout()` hace crecer la recolección un `harvesting_growth` % (5 % base, más Granjero y Corona). Si `RunData.current_wave > RunData.nb_of_waves` (oleada 21 en adelante del modo infinito), en su lugar quita `ceil(recolección × 20 %)` (`RunData.ENDLESS_HARVESTING_DECREASE`).
- La Hucha (`gain_pct_gold_start_wave`) solo da su interés positivo hasta la oleada 20 (`Main._on_EntitySpawner_players_spawned`).
- La leyenda: con «Seguir creciendo» ejecuta el crecimiento del propio juego tratando la oleada como la última normal; con un porcentaje distinto del 20 % quita ese porcentaje en lugar del del juego; con la Hucha activada, da el interés al empezar cada oleada posterior a la 20. Con 20 % y sin crecer, deja actuar al juego tal cual.
- La Hucha y la Corona figuran en `ItemService.banned_items_for_endless`; la leyenda las retira de esa lista cuando vuelven a servir.

Pruebas manuales (modo infinito, pasando de la oleada 20):
- [ ] Por defecto (0 %): tras la oleada 21 la recolección no baja; el texto de la estadística dice que se mantiene.
- [ ] Con 10 %: baja aproximadamente la mitad que en el juego base.
- [ ] Con «Seguir creciendo»: sube como en las oleadas normales; con la Corona, su contador también avanza.
- [ ] Con la Hucha activada y materiales guardados: al empezar la oleada 21 se recibe el interés y el contador de la Hucha aumenta.
- [ ] Antes de la oleada 21, todo funciona exactamente como en el juego base.
- [ ] Desactivar la leyenda en pausa: en la siguiente oleada vuelve el 20 % del juego.
- [ ] Cooperativo: se aplica a cada jugador con su propia recolección y su Hucha.

### La Leyenda del Mercader (`merchant_legend`)

Cómo funciona en el juego (verificado en el código de 1.1.15.4):
- El precio de un artículo sale de `ItemService.get_value(oleada, valor_base, …)`: `(valor + oleada + valor × oleada × 0,1) × modificadores × factor infinito`.
- El del reroll, de `ItemService.get_reroll_price(oleada, rerolls, …)`, que sube con la oleada y con cada reroll de la misma tienda.
- La leyenda calcula esos precios con la oleada 1 si se eligen precios fijos y aplica después el porcentaje configurado. El reciclaje usa `get_value`, así que cambia en la misma proporción.

Pruebas manuales:
- [ ] Con los valores por defecto, los precios coinciden con los del juego.
- [ ] Artículos al 50 %: los precios de la tienda se reducen a la mitad y se cobra ese precio.
- [ ] Rerolls al 0 %: el botón muestra 0 y rerolear no cuesta materiales.
- [ ] «Los artículos no se encarecen»: en la oleada 15 cuestan lo mismo que en la 1.
- [ ] «Los rerolls no se encarecen»: el primer reroll de cada tienda cuesta lo mismo que en la oleada 1.
- [ ] Cambiar los valores desde la pausa se refleja en la siguiente tienda.

### La Leyenda del Supermercado (`supermarket_legend`)

Diseño:
- El catálogo sale de `ItemService.get_pool(tier, ITEMS/WEAPONS)` (solo lo desbloqueado y de los DLC activos) y se filtra con las mismas restricciones que usa el juego al generar la tienda: prohibiciones del jugador y del personaje, grupos vetados, etiquetas retiradas, máximo por objeto, armas cuerpo a cuerpo/a distancia, tier mínimo y máximo de armas y estructuras.
- **Equilibrio (pedido por Mauro)**:
  - **Aviso**: la leyenda viene apagada por defecto y la ficha avisa de que es muy fuerte.
  - **Cuándo se gana un encargo**: por defecto, en la tienda que sigue a una oleada en la que se derrotó a un élite o a un jefe. Se mira con `RunData.elites_killed_this_run` y `bosses_killed_this_run`: se toma una foto al salir de la tienda anterior y se compara al entrar. Al continuar una partida guardada no hay foto, y basta con que la oleada fuera de élite (`RunData.elites_spawn`) o la del jefe.
  - **Modo «en cada tienda»**: los élites solo aparecen desde el Peligro 2; para quien juegue en Peligro 0 y 1, este modo da los encargos en cada tienda.
  - **Precio**: cada encargo cuesta un recargo (por defecto, el 50 % del precio del artículo) que se paga al encargar.
  - **Entrega**: el artículo no aparece en la tienda actual; llega **bloqueado a la siguiente**, donde se compra a su precio normal.
- **Cómo viaja el encargo**:
  - Se añade a la lista de bloqueados del juego con `RunData.lock_player_shop_item`, así que se guarda con la partida.
  - La extensión de la tienda lo quita de los bloqueados al rerolear en la tienda en la que se hizo.
  - Si al entrar en la siguiente tienda hay más bloqueados que huecos, se descartan antes los que no son encargos.
  - Los encargos que llegan se vuelven a bloquear aunque el jugador tenga desactivado «mantener bloqueados».
- El precio mostrado sale de `ItemService.get_value()`, así que incluye la Leyenda del Mercader si está activa.
- **Rasgo propio: la caja del encargo.** En la tienda a la que llega un encargo aparece «¡Tu encargo ha llegado!»: una caja de cartón que tiembla con cada toque (Aceptar o clic) y al tercero se abre con confeti y muestra el artículo. Es solo visual; ajuste «Abrir la caja del encargo».
- Limitaciones conocidas:
  - Si se sale al menú en mitad de una tienda y se continúa la partida, se puede volver a encargar en esa tienda (pagando de nuevo el recargo).
  - En ese caso, el encargo ya hecho podría aparecer al rerolear esa misma tienda.

Pruebas manuales (Peligro 2 o más):
- [ ] La leyenda aparece apagada con el aviso de que es muy fuerte; al encenderla pide reiniciar.
- [ ] Antes del primer élite, el catálogo dice «Sin encargos» y no deja encargar.
- [ ] Tras derrotar a un élite: el botón muestra «Supermercado (1)» y se puede encargar una vez; el recargo (50 %) se descuenta al momento.
- [ ] El encargo no aparece en la tienda actual, ni al rerolear.
- [ ] En la siguiente tienda aparece **bloqueado**; se compra a su precio normal.
- [ ] En una oleada de élite en la que el élite no muere, no se gana encargo.
- [ ] Con 4 artículos bloqueados, encargar avisa de que no cabría.
- [ ] Modo «en cada tienda»: se puede encargar en todas las tiendas.
- [ ] Un personaje sin armas cuerpo a cuerpo no ve armas cuerpo a cuerpo; los objetos prohibidos no aparecen.
- [ ] «Atrás» cierra el catálogo sin abrir la pausa.
- [ ] Guardar y salir tras encargar y continuar: el encargo sigue llegando a la siguiente tienda.
- [ ] Al llegar el encargo aparece la caja; tiembla con cada toque y a los tres se abre con confeti. Con mando, teclado y ratón.
- [ ] Con «Abrir la caja del encargo» apagado no aparece la caja.

### La Leyenda del Regalo (`gift_legend`)

Diseño:
- Botón **Regalar** en la fila superior del panel de cada jugador de la tienda cooperativa (junto al reroll). Solo aparece con 2 o más jugadores.
- La ventana lista armas y objetos del jugador, con un botón por cada posible receptor; si no se puede, el botón aparece desactivado con el motivo.
- Transferencia con la API del juego: `RunData.remove_item` + `add_item` (retiran y aplican efectos) y `remove_weapon_by_index` + `add_weapon` (el arma conserva mejoras, maldición, mecanización y daño acumulado).
- Nunca se regalan: el personaje (figura como objeto), `item_tumor`, `item_meca_evolved_leap`, `item_mut_evolved_leap`, `item_builder_turret*` y los objetos con `replaced_by` (quitarlos dejaría su sustituto a quien regala).
- Reglas de quien recibe: huecos de arma libres, máximo por objeto, objetos prohibidos y grupos vetados de su personaje (las prohibiciones de tienda que elige cada jugador no impiden recibir regalos), sin cuerpo a cuerpo / sin distancia, tier de armas, armas bloqueadas (`lock_current_weapons`), y bando de evolución (no se da un arma meca a un personaje `mutant_only` ni un objeto mutado a uno `meca_only`).
- Mientras la ventana está abierta, se pausan los `FocusEmulator` de la tienda (igual que hace el juego al pausar) y la ventana gestiona la navegación: arriba/izquierda y abajo/derecha recorren los botones, aceptar regala y atrás cierra.
- **Rasgo propio: quien recibe confirma.** Al elegir a quién regalar se abre «¡Un regalo de tu Cari!» con un corazón que late y corazones que suben, el objeto y los botones Aceptar/Rechazar. Solo responde el mando o teclado de quien recibe (el juego crea acciones por dispositivo, `ui_accept_<dispositivo>`, que se leen con `CoopService.get_remapped_player_device`); el ratón solo vale si quien recibe juega con teclado y ratón. Quien regala puede retirarlo con Atrás. Al aceptar se hace el regalo y sale una lluvia de corazones.

Pruebas manuales (partida cooperativa de 2 jugadores):
- [ ] Cada jugador ve su botón **Regalar** en la tienda.
- [ ] J1 regala un objeto a J2: se abre la confirmación; solo el mando de J2 puede aceptar o rechazar.
- [ ] Al aceptar sale la lluvia de corazones, el objeto desaparece de J1, aparece en J2 y las estadísticas de ambos cambian.
- [ ] Al rechazar, o si J1 lo retira con Atrás, no cambia nada y la ventana de regalos lo indica.
- [ ] J1 regala un arma a J2 con hueco libre; con J2 sin huecos, el botón aparece desactivado con el motivo.
- [ ] Un arma mecanizada (Primal Dread) conserva su mecanización al regalarla.
- [ ] El Tumor y el propio personaje no aparecen en la lista.
- [ ] Un objeto con máximo (por ejemplo, el Anzuelo con 3) no se puede regalar a quien ya tiene el máximo.
- [ ] Con «Regalos por jugador en cada tienda» = 1, el segundo regalo se rechaza.
- [ ] La ventana se maneja con mando (arriba/abajo, aceptar, atrás) y con ratón; al cerrar, el mando vuelve a la tienda.
- [ ] Al pasar a la siguiente oleada, las armas regaladas aparecen equipadas en quien las recibió.
