# Compatibilidad

No se declara compatibilidad por intuición. «Verificado en código» significa que las funciones y rutas usadas existen con esa firma en el código del juego; «probado en el juego» significa que se ha ejecutado dentro de Brotato.

## Entorno objetivo

| Componente | Versión | Estado | Evidencia / notas |
|---|---|---|---|
| Brotato | **1.2.x** (actual, con el DLC Primal Dread) | Adaptado con la información pública de la 1.2; **no probado en el juego** | No hay código de la 1.2 publicado. Fuentes: guía de migración 1.1→1.2 de mojimoon (`docs/MIGRATION-1.2.md` de mojimoon/BrotatoMods) y mods ya actualizados (BrotatoOnline, FengAddMods, QuickEquip) |
| Brotato | 1.1.15.4 | Verificado en código; **no probado en el juego** | `ProgressData.VERSION = "1.1.15.4"` en el código de referencia (actualización «All Pain No Gain», 2026) |
| Abyssal Terrors (DLC) | datos de 1.1.14.5 | Verificado en código | Rutas `res://dlcs/dlc_1/...`; el código de 1.1.15.4 disponible no incluye el DLC |
| Godot | 3.x (GDScript 3) | Verificado | El juego es un proyecto Godot 3 |
| ModLoader | 6.3.0 | Verificado en código | `MODLOADER_VERSION = "6.3.0"` integrado en el juego; perfil Steam con Workshop activado |
| Mod Options | 0.6.2 (MIT) | Evaluado, no se usa | Requiere instalar otro mod; ver `docs/DECISIONES.md` |
| ContentLoader | 6.2.3 | Evaluado, sin decidir | Sin licencia publicada |

## Cambios de Brotato 1.2 que afectan al mod

| Cambio en 1.2 | Efecto | Cómo se resuelve |
|---|---|---|
| `base_shop.gd` (1.2.0.1) infiere tipos de `RunData` con `:=`; durante `_init` de los mods `RunData` aún no existe | Cargar una extensión de la tienda en `_init` rompe la compilación y el CrashReporter **desactiva todos los mods** en el siguiente arranque | Las extensiones de scripts de escenas se instalan en `mod_main._ready()`; solo las de autoloads (`res://singletons/...`) se instalan en `_init` (`core/legends_core.gd`) |
| `ItemService.items/weapons/characters` pasan a ser una caché que se construye la primera vez que se consulta | Consultarla antes de que `ProgressData` sepa qué DLC hay la deja sin objetos de DLC para toda la sesión | Ninguna leyenda consulta `ItemService.items` al arrancar; el Anzuelo aplica su probabilidad al entrar en la tienda |
| Los DLC pasan a ser «conjuntos de objetos»; `RunData.enabled_dlcs` significa «DLC comprados» | Comprobar si un DLC está en la partida con `enabled_dlcs` da falsos positivos | `Compat.is_dlc_enabled_in_run()` usa `RunData.active_update_data_ids` si existe |
| `ProgressData.get_dlc_data()` desaparece (ahora `ItemService.get_dlc_data_by_id()`) | — | El mod no lo usa |
| `RunData.remove_item(item, p, by_id, apply_replacement = true)` | Quitar un objeto con sustituto añade el sustituto | El Regalo no transfiere objetos con `replaced_by` |
| Nuevo DLC Primal Dread: armas meca (`is_meca`), objetos mutantes (`is_mutant`), Tumor (`item_tumor`), personajes `meca_only` / `mutant_only` | Reglas nuevas para transferir objetos | Ver La Leyenda del Regalo |

Pendiente: verificar dentro de Brotato 1.2 las firmas de `BaseShop.fill_shop_items`, `Main._on_HarvestingTimer_timeout`, `ItemService.get_value/get_reroll_price/get_stat_description_text` y `banned_items_for_endless`, que no aparecen en las fuentes públicas de la 1.2.

## Cómo se carga un mod

El juego elige el perfil de opciones del ModLoader por plataforma (`addons/mod_loader/options/options.tres`, verificado en código 1.1.15.4; la 1.2 sigue con ModLoader 6.3.0):

- **Steam** (perfil `steam.tres`, `steam_workshop_enabled = true`): `ModLoader._load_mod_zips()` solo recorre `steamapps/workshop/content/1942280/`, y Blobfish modificó `_ModLoaderSteam.load_steam_workshop_zips()` para cargar únicamente las carpetas cuyo número está en `Platform.get_subscribed_mods()` (objetos suscritos). Dentro de cada carpeta carga todos los `.zip` y `.pck`. **La carpeta `<instalación>/mods/` y `--mods-path` se ignoran.**
- **GOG, Epic y versión local** (`steam_workshop_enabled = false`): carga los ZIP de `<instalación de Brotato>/mods/` o de `--mods-path=<ruta>`.

Para probar en Steam sin publicar, el ZIP se copia en la carpeta de un objeto suscrito (procedimiento en `docs/PRUEBAS.md`).
- Dentro del ZIP: `mods-unpacked/<Namespace>-<Nombre>/manifest.json` y `mod_main.gd`.
- Registro de ModLoader: `user://logs/modloader.log` (en Windows `%APPDATA%\Brotato\logs\modloader.log`).

## API del juego usada

| Uso | API | Archivo del juego | Desde |
|---|---|---|---|
| Botón del menú principal | `MainMenu.mods_button` (`%ModsButton`) | `ui/menus/pages/main_menu.gd` | 0.1.0 |
| Botón del menú de pausa | `%OptionsButton`, `_buttons_array` | `ui/menus/ingame/ingame_main_menu.gd` | 0.1.0 |
| Acciones de cancelar/pausa | `ui_cancel*`, `ui_pause*` en `InputMap` | `project.godot` | 0.1.0 |
| Versión del juego | constante `ProgressData.VERSION` | `singletons/progress_data.gd` | 0.1.0 |
| DLC disponible / en la partida | `ProgressData.is_dlc_available()`, `RunData.enabled_dlcs` | `singletons/progress_data.gd`, `singletons/run_data.gd` | 0.1.0 |
| Objetos y prohibiciones | `ItemService.items`, `ItemService.get_element()`, `RunData.get_player_items()`, `players_data[i].banned_items`, `CharacterData.banned_items` | `singletons/item_service.gd`, `singletons/run_data.gd` | 0.1.0 |
| Oleadas | `RunData.current_wave`, `RunData.nb_of_waves`, `RunData.get_player_count()` | `singletons/run_data.gd` | 0.1.0 |
| Tienda: generar artículos al entrar | `BaseShop.fill_shop_items(locked, player_index, just_entered_shop)`, `_shop_items[player_index]` = `[[ItemParentData, oleada], ...]` (bloqueados primero) | `ui/menus/shop/base_shop.gd` | Anzuelo |
| Tienda: aplicar modificaciones de DLC a un objeto | `ItemService.apply_item_effect_modifications(item, player_index)` | `singletons/item_service.gd` | Anzuelo |
| Anzuelo | `item_fish_hook`, efecto `curse_locked_items` (`Effect.key`, `Effect.value`), `max_nb` | `dlcs/dlc_1/items/fish_hook/` | Anzuelo |
| Maldición de bloqueados al salir de la tienda | `BaseShop._on_tree_exited()` (no se reemplaza; solo se cambia el valor del efecto) | `ui/menus/shop/base_shop.gd` | Anzuelo |
| Recolección al final de la oleada | `Main._on_HarvestingTimer_timeout()`, `RunData.ENDLESS_HARVESTING_DECREASE` (20), `RunData.remove_stat()`, `Utils.get_stat()` | `main.gd`, `singletons/run_data.gd`, `singletons/utils.gd` | Cosecha Eterna |
| Inicio de oleada (Hucha) | `Main._on_EntitySpawner_players_spawned(players)`, efecto `gain_pct_gold_start_wave`, `RunData.add_gold()`, `RunData.add_tracked_value()` | `main.gd`, `singletons/run_data.gd` | Cosecha Eterna |
| Objetos vetados en infinito | `ItemService.banned_items_for_endless` | `singletons/item_service.gd` | Cosecha Eterna |
| Texto de la estadística | `ItemService.get_stat_description_text(stat_hash, value, player_index)`, `Text.text()`, clave `INFO_POS_STAT_HARVESTING_LIMITED` | `singletons/item_service.gd`, `singletons/text.gd` | Cosecha Eterna |
| Precios de la tienda | `ItemService.get_value(wave, base_value, player_index, affected_by_items_price_stat, is_weapon, item_id)`, `ItemService.get_reroll_price(wave, reroll_count, player_index)` → `[precio, descuento]` | `singletons/item_service.gd` | Mercader |
| Catálogo del Supermercado | `ItemService.get_pool(tier, TierData)`, `ItemService.item_groups`, `RunData.get_remaining_max_nb_item()`, efectos `no_melee_weapons`, `no_ranged_weapons`, `min/max_weapon_tier`, `remove_shop_items`, `EntityService.is_weapon_spawning_structure()` | `singletons/item_service.gd`, `singletons/run_data.gd`, `singletons/entity_service.gd` | Supermercado |
| Colocar artículos en la tienda | `BaseShop._get_reroll_button()`, `_get_shop_items_container()`, `ShopItemsContainer.set_shop_items()`, `is_shop_item_locked_visually()`, `unlock_all_shop_items_visually()`, `BaseShop._update_visual_locks()`, `set_reroll_button_price()`, `ItemService.NB_SHOP_ITEMS` | `ui/menus/shop/base_shop.gd`, `ui/menus/shop/shop_items_container.gd` | Supermercado |
| Encargos del Supermercado | `RunData.elites_spawn` (`[oleada, EliteType, id]`), `elites_killed_this_run`, `bosses_killed_this_run`, `nb_of_waves`, `lock_player_shop_item(item, oleada, i)`, `locked_shop_items`; `BaseShop.fill_shop_items(..., just_entered_shop)`, `_update_visual_locks()`; `_on_GoButton_pressed` avanza `current_wave` antes de salir de la tienda | `singletons/run_data.gd`, `ui/menus/shop/base_shop.gd`, `entities/units/enemies/boss/boss.gd` | Supermercado |
| Reroll gratis del «¡Pica!» | `BaseShop._free_rerolls[i]`, `set_reroll_button_price(i)` (se guardan con `ProgressData.save_run_state`) | `ui/menus/shop/base_shop.gd` | Anzuelo |
| Regateo del Mercader | `ItemService.get_value(..., item_id)` (los artículos de la tienda pasan su id; el reciclaje no), `ShopItemsContainer.reload_shop_items()`, `update_buttons_color()`, `BaseShop._get_reroll_button(i)`, `Utils.focus_player_control()` | `singletons/item_service.gd`, `ui/menus/shop/shop_items_container.gd`, `ui/menus/shop/base_shop.gd` | Mercader |
| Cosecha dorada | `RunData.add_gold()` (emite `gold_changed`, la tienda actualiza el contador), `RunData.resumed_from_state_in_shop` | `singletons/run_data.gd` | Cosecha Eterna |
| Cobro en la moneda del jugador | `RunData.get_player_currency()`, `RunData.remove_currency()` | `singletons/run_data.gd` | Supermercado |
| Tienda cooperativa | `_get_gear_container(i)` (`items_container` / `weapons_container` → `_elements`, `_on_weapons_changed()`, y `set_items_data()/set_weapons_data()` solo como último recurso), `Inventory.remove_element(dato, 1, true)` / `add_element(dato, agrupar)` (como al reciclar y comprar), `_popup_manager.reset_focus(i)`, `_update_stats(i)`, `ShopItemsContainer.reload_shop_items()`, `set_reroll_button_price(i)`. No se rehacen los inventarios enteros con el foco encima: `Inventory.clear_elements()` destruye las casillas y el `FocusEmulator` de cada jugador sigue apuntando a ellas (cierre en la versión publicada) | `ui/menus/shop/coop_shop.gd`, `base_shop.gd`, `inventory.gd`, `player_gear_container.gd`, `ui/menus/global/popup_manager.gd` | Regalo |
| Transferir objetos y armas | `RunData.remove_item(item, p)` / `add_item(item, p)`, `remove_weapon_by_index(i, p)` / `add_weapon(w, p)` (confirmadas en 1.2 por QuickEquip; `add_weapon` guarda y devuelve una copia, así que la casilla de un arma recién comprada no muestra el mismo objeto que RunData), `ItemService.is_same_weapon(a, b)` / `is_same_item(a, b)`, `get_remaining_max_nb_item()`, efectos `weapon_slot`, `lock_current_weapons`, `meca_only`, `mutant_only` | `singletons/run_data.gd` | Regalo |
| Menú del arma u objeto en la tienda | `ItemPopup` (`_combine_button`, `_discard_button`, `_cancel_button`, `should_show_buttons()`, `_update_button_visibilities()`, `_on_CancelButton_pressed()`, `buttons_enabled`, `player_index`, `_item_data`, `_focused`); `CoopItemPopup` hereda de él y es el script que se extiende (ModLoader solo recarga las clases hijas de las extensiones instaladas al arrancar, no de las que se instalan en `_ready`); `RunData.can_combine()` solo admite armas | `ui/menus/shop/item_popup.gd`, `ui/menus/shop/coop_item_popup.gd`, `ui/menus/global/popup_manager.gd` | Regalo |
| Entrada por jugador en cooperativo | Acciones por dispositivo `ui_accept_<n>`, `ui_cancel_<n>`…, `CoopService.get_remapped_player_device(i)`, `is_player_using_gamepad(i)`, `get_player_color(i)` | `singletons/coop_service.gd`, `ui/menus/global/focus_emulator.gd` | Regalo |
| Foco por jugador en cooperativo | Nodos `FocusEmulator1..4` de la escena (se ocultan y dejan de leer la entrada mientras la ventana está abierta, como hace el juego al pausar), `Utils.focus_player_control()` (diferido), `Utils.get_focus_emulator(i).focused_control` (al asignarlo se aplica al momento; el emulador redibuja el control enfocado cada vez que alguien cambia de foco) | `ui/menus/global/focus_emulator.gd`, `singletons/utils.gd` | Regalo |
| Cajas por abrir al terminar la oleada | `Main._on_EndWaveTimer_timeout()`, `_is_run_lost`, `_is_run_won`, `_is_wave_failed`, `_consumables_to_process[i]` (lista de `UpgradesUI.ConsumableToProcess` con `consumable_data` y `player_index`), `_things_to_process_player_containers[i].consumables.add_element()/remove_element()`, `ItemService.consumables` + `get_element()`, `Keys.consumable_item_box_hash`, `Keys.consumable_legendary_item_box_hash` (confirmadas en mods de la 1.2: BroEditor, NewContentLoader) | `main.gd`, `ui/menus/upgrades/upgrades_ui.gd` | Cajas |
| Fusión de personajes | `RunData.apply_item_effects(item, i)`, `RunData.get_player_character(i)`, `RunData.get_player_effects(i)[hash] += valor`, `Utils.reset_stat_cache(i)`, `ItemService.characters`, `ProgressData.characters_unlocked`, `ItemParentData.get_effects_text(i)`, `Player.update_player_stats(reset)`, `EffectBehaviorService.update_active_effect_behaviors()`, `Main._players`, efectos `xp_gain`, `items_price`, `number_of_enemies`, `enemy_speed` | `singletons/run_data.gd`, `main.gd`, `entities/units/player/player.gd` | Fusión |
| Tus tatos en la partida | `Player` → nodo `Animation/Sprite` (los aspectos del juego son `Sprite` hijos de él, de 150 × 150), `res://entities/units/player/potato.png` | `entities/units/player/player.tscn`, `player.gd` | Taller |
| Otros mods cargados | `ModLoaderStore.mod_data[id]` (`is_loadable`, `is_active`) | `addons/mod_loader/mod_loader_store.gd` | Taller |
| Iconos de BroEditor | Carpeta `user://Mojimoon-BroEditor/icons/` (PNG que BroEditor ofrece como iconos) | BroEditor | Taller |
| Tema y fuentes de la interfaz | `res://resources/themes/base_theme.tres`, `res://resources/fonts/actual/base/*.tres` (opcionales) | recursos del juego | 0.1.0 |

`tools/game_scripts.txt` contiene las rutas de scripts del juego que existen en la versión objetivo; la validación falla si una extensión apunta a otra ruta. Para regenerarlo tras una actualización, con una copia local descompilada del juego (fuera del repositorio):

```bash
cd <copia-del-juego> && find . -name "*.gd" -not -path "./addons/*" | sed 's#^\./#res://#' | sort
```

## Estado por leyenda

| Leyenda | Brotato | Estado |
|---|---|---|
| La Leyenda del Anzuelo | 1.1.15.4 (DLC: datos de 1.1.14.5) | Verificado en código; no probado en el juego |
| La Leyenda de la Cosecha Eterna | 1.1.15.4 | Verificado en código; no probado en el juego |
| La Leyenda del Mercader | 1.1.15.4 | Verificado en código; no probado en el juego |
| La Leyenda del Supermercado | 1.1.15.4 | Verificado en código; no probado en el juego; solo tienda de un jugador |
| La Leyenda del Regalo | 1.2.0.1 | Probado en el juego por Mauro (cooperativo) |
| La Leyenda de las Cajas | 1.1.15.4; API confirmada en mods de la 1.2 | Verificado en código; no probado en el juego |
| La Leyenda de la Fusión | 1.1.15.4; API confirmada en mods de la 1.2 | Verificado en código; no probado en el juego |
| El Taller de los Tatos | 1.2 (con BroEditor 3.0.6) | Verificado en código; no probado en el juego |

## Otros mods

| Mod | Qué pasa | Qué hacer |
|---|---|---|
| FoxLab (JonathanFox, Primal Dread) | Carga `base_shop.gd` durante su `_init`. En la 1.2 eso rompe la compilación de la tienda (`base_shop.gdc:212`, «the variable type can't be inferred») y la tienda deja de funcionar, con o sin Caritatopc. | No usarlo junto a este mod hasta que su autor lo corrija. |
| BroEditor (Mojimoon, Workshop 3817655214) | Compatible y recomendado: es el editor de personajes, objetos y armas que usa El Taller de los Tatos. Extiende `main.gd`, `RunData`, `ItemService`, la selección de personaje, arma y dificultad y las tiendas. Coincide con Caritatopc en `Main._on_EntitySpawner_players_spawned` (las dos extensiones llaman a la del juego, así que se encadenan) y en las tiendas (BroEditor cambia reroll y compra; Caritatopc, otras funciones). No hay miembros con el mismo nombre (`_be_*` frente a `_clc_*`). Su fusión de personajes (GMO) y nuestra Leyenda de la Fusión se suman si se usan las dos. | Instalarlo para crear personajes y objetos. Probar juntos en el juego. |
| PerfectHook (AzazelRabbit) | Cambia el Anzuelo y la tienda, igual que nuestra Leyenda del Anzuelo, y está hecho para versiones anteriores. | Usar solo uno de los dos: la Leyenda del Anzuelo ya da la probabilidad configurable y el Anzuelo garantizado. |

## Historial de pruebas

| Fecha | Brotato | ModLoader | Versión del mod | Resultado | Leyendas probadas | Notas |
|---|---|---|---|---|---|---|
| 2026-11-06 | — | — | 0.1.0 | Solo pruebas automáticas | — | Validación, sintaxis (gdparse), pruebas de herramientas y del núcleo. Pendiente de probar dentro de Brotato. |
| 2026-11-07 | 1.2.0.1 (Steam) | 6.3.0 | 0.2.0 + Regalo | No cargó | — | El ZIP estaba en `Brotato/mods`, que la versión de Steam no lee. Corregidas las instrucciones de instalación. |
| 2026-11-07 | 1.2.0.1 (Steam) | 6.3.0 | 1.0.0 candidata (con la extensión de `ItemPopup`) | Cooperativo bien; en solitario el juego se cierra al entrar en la primera tienda | Anzuelo (probabilidad 45 %), Cosecha Eterna, Regalo | El último paso registrado es «Probabilidad por anzuelo» al entrar en la tienda. Solo en solitario se usaba la extensión de `ItemPopup` (en cooperativo no llegaba); se retiró y la del menú cooperativo se hizo más prudente. En otras sesiones también estaba FoxLab, que rompe la tienda por su cuenta (ver «Otros mods»). |
| 2026-11-07 | 1.2.0.1 (Steam) | 6.3.0 | 1.0.0 candidata (menú cooperativo prudente) | En solitario ya no se cierra | Anzuelo, Cosecha Eterna, Regalo | Confirmado por Mauro: «Ahora ha funcionado perfectamente». |
| 2026-11-08 | 1.2.0.1 (Steam) | 6.3.0 | Sin publicar (Cajas, Fusión, Taller) + BroEditor | Cooperativo: el juego se cierra justo después de aceptar un regalo | Anzuelo, Cosecha Eterna, Regalo, Cajas, Taller | El regalo se completa («Regalo: item_tentacle de J2 a J1») y el juego se cierra después. Causa: se rehacían los inventarios y el foco de quien recibía seguía en una casilla destruida. Corregido; pendiente de volver a probar. |
