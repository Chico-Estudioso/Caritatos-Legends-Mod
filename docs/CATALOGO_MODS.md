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

- **Rasgo propio: «Cosecha dorada».** En cada tienda del modo infinito aparece un campo de trigo que madura despacio y se pasa deprisa. Al pulsar Aceptar se cosecha:
  - Dorado: +10 % de la recolección en materiales (`RunData.add_gold`).
  - Casi dorado: +5 %.
  - Verde: nada.
  - Al continuar una partida guardada en la tienda no se repite (`RunData.resumed_from_state_in_shop`), para que salir y volver no dé el premio otra vez.
  - Ajuste «Cosecha dorada en el modo infinito».

Pruebas manuales (modo infinito, pasando de la oleada 20):
- [ ] Por defecto (0 %): tras la oleada 21 la recolección no baja; el texto de la estadística dice que se mantiene.
- [ ] Con 10 %: baja aproximadamente la mitad que en el juego base.
- [ ] Con «Seguir creciendo»: sube como en las oleadas normales; con la Corona, su contador también avanza.
- [ ] Con la Hucha activada y materiales guardados: al empezar la oleada 21 se recibe el interés y el contador de la Hucha aumenta.
- [ ] Antes de la oleada 21, todo funciona exactamente como en el juego base.
- [ ] Desactivar la leyenda en pausa: en la siguiente oleada vuelve el 20 % del juego.
- [ ] Cooperativo: se aplica a cada jugador con su propia recolección y su Hucha.
- [ ] Cosecha dorada: sale en las tiendas del modo infinito (no antes); cosechar en dorado suma el 10 % de la recolección en materiales.
- [ ] Guardar y salir en esa tienda y continuar: no vuelve a salir.

### La Leyenda del Mercader (`merchant_legend`)

Cómo funciona en el juego (verificado en el código de 1.1.15.4):
- El precio de un artículo sale de `ItemService.get_value(oleada, valor_base, …)`: `(valor + oleada + valor × oleada × 0,1) × modificadores × factor infinito`.
- El del reroll, de `ItemService.get_reroll_price(oleada, rerolls, …)`, que sube con la oleada y con cada reroll de la misma tienda.
- La leyenda calcula esos precios con la oleada 1 si se eligen precios fijos y aplica después el porcentaje configurado. El reciclaje usa `get_value`, así que cambia en la misma proporción.

- **Rasgo propio: «¡A regatear!».** Botón **Regatear** junto al reroll de cada jugador. Una aguja va y viene por una barra con una zona verde (en un sitio distinto cada vez):
  - Al pulsar Aceptar se para. En verde, −10 % (configurable) en los artículos de esa tienda; en amarillo, la mitad; en rojo, nada.
  - Un intento por tienda; cancelar no lo gasta.
  - El descuento se aplica en `ItemService.get_value` solo a los artículos de la tienda (los que llevan id), así que el reciclaje no cambia.
  - La tienda refresca sus precios con `ShopItemsContainer.reload_shop_items()`.

Pruebas manuales:
- [ ] Con los valores por defecto, los precios coinciden con los del juego.
- [ ] Artículos al 50 %: los precios de la tienda se reducen a la mitad y se cobra ese precio.
- [ ] Rerolls al 0 %: el botón muestra 0 y rerolear no cuesta materiales.
- [ ] «Los artículos no se encarecen»: en la oleada 15 cuestan lo mismo que en la 1.
- [ ] «Los rerolls no se encarecen»: el primer reroll de cada tienda cuesta lo mismo que en la oleada 1.
- [ ] Cambiar los valores desde la pausa se refleja en la siguiente tienda.
- [ ] Regatear: parar en verde baja un 10 % los precios de la tienda al momento; el botón queda como «Regateado: −10 %».
- [ ] Reciclar en esa tienda da lo mismo que sin regatear.
- [ ] En la siguiente tienda los precios vuelven a la normalidad y se puede regatear otra vez. En cooperativo, cada jugador tiene su botón.

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
- **Dónde se regala**: en la tienda cooperativa, al pulsar un arma u objeto propio aparece el menú del juego (Combinar, Reciclar, Cancelar) con un botón más, **Regalar**. Es una extensión de `CoopItemPopup` (el menú de la tienda cooperativa; extender `ItemPopup` no llega a él porque se compila antes de que se instalen las extensiones). En el juego, ese menú solo tiene botones para las armas, así que para los objetos muestra Regalar y Cancelar. Con mando se llega como a Reciclar: Reciclar → Regalar → Cancelar.
- **A quién**: con dos jugadores, va directo a la confirmación. Con más, o si no se puede regalar a nadie, sale «¿A quién se lo regalas?», con un botón por jugador; los que no pueden recibirlo aparecen desactivados con el motivo.
- **Quién confirma**: quien recibe, en «¡Un regalo de tu Cari!» (corazón que late, corazones que suben y lluvia de corazones al aceptar).
  - Solo responde su mando o teclado: el juego crea acciones por dispositivo (`ui_accept_<dispositivo>`), que se leen con `CoopService.get_remapped_player_device`.
  - El ratón solo vale si quien recibe juega con teclado y ratón.
  - Quien regala puede retirarlo con Atrás.
- **Transferencia** con la API del juego: `RunData.remove_item` + `add_item` (retiran y aplican efectos) y `remove_weapon_by_index` + `add_weapon` (el arma conserva mejoras, maldición, mecanización y daño acumulado).
- **Nunca se regalan**: el personaje (figura como objeto), `item_tumor`, `item_meca_evolved_leap`, `item_mut_evolved_leap`, `item_builder_turret*` y los objetos con `replaced_by` (quitarlos dejaría su sustituto a quien regala). Para ellos el menú no muestra Regalar.
- **Reglas de quien recibe**:
  - Huecos de arma libres y máximo por objeto.
  - Objetos prohibidos y grupos vetados de su personaje. Las prohibiciones de tienda que elige cada jugador no impiden recibir regalos.
  - Sin cuerpo a cuerpo o sin distancia, tier de armas y armas bloqueadas (`lock_current_weapons`).
  - Bando de evolución: no se da un arma meca a un personaje `mutant_only` ni un objeto mutado a uno `meca_only`.
- Las ventanas se abren de una en una (`ui/legend_popup.gd`) y, mientras están abiertas, pausan los `FocusEmulator` de la tienda.

Pruebas manuales (partida cooperativa de 2 jugadores):
- [ ] Al pulsar un arma propia en la tienda, el menú muestra Reciclar, **Regalar** y Cancelar; con mando se llega a Regalar.
- [ ] Al pulsar un objeto propio, el menú muestra Regalar y Cancelar (el personaje y el Tumor no).
- [ ] Regalar abre la confirmación; solo el mando de J2 puede aceptar o rechazar.
- [ ] Al aceptar sale la lluvia de corazones, el objeto desaparece de J1, aparece en J2 y las estadísticas de ambos cambian.
- [ ] Al rechazar, o si J1 lo retira con Atrás, no cambia nada y la ventana lo indica.
- [ ] Con J2 sin huecos de arma, Regalar un arma muestra el motivo en vez de la confirmación.
- [ ] Un arma mecanizada (Primal Dread) conserva su mecanización al regalarla.
- [ ] Con «Regalos por jugador en cada tienda» = 1, el segundo regalo se rechaza.
- [ ] Tras regalar, el mando de J1 vuelve al botón de reroll y se puede seguir comprando.
- [ ] Con 3 o 4 jugadores sale «¿A quién se lo regalas?».
