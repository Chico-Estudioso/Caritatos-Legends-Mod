# Compatibilidad

No se declara compatibilidad por intuición. «Verificado en código» significa que las funciones y rutas usadas existen con esa firma en el código del juego; «probado en el juego» significa que se ha ejecutado dentro de Brotato.

## Entorno objetivo

| Componente | Versión | Estado | Evidencia / notas |
|---|---|---|---|
| Brotato | 1.1.15.4 | Verificado en código; **no probado en el juego** | `ProgressData.VERSION = "1.1.15.4"` en el código de referencia (actualización «All Pain No Gain», 2026) |
| Abyssal Terrors (DLC) | datos de 1.1.14.5 | Verificado en código | Rutas `res://dlcs/dlc_1/...`; el código de 1.1.15.4 disponible no incluye el DLC |
| Godot | 3.x (GDScript 3) | Verificado | El juego es un proyecto Godot 3 |
| ModLoader | 6.3.0 | Verificado en código | `MODLOADER_VERSION = "6.3.0"` integrado en el juego; perfil Steam con Workshop activado |
| Mod Options | 0.6.2 (MIT) | Evaluado, no se usa | Requiere instalar otro mod; ver `docs/DECISIONES.md` |
| ContentLoader | 6.2.3 | Evaluado, sin decidir | Sin licencia publicada |

## Cómo se carga un mod

- ModLoader carga ZIPs desde `<instalación de Brotato>/mods/` y desde las carpetas de Steam Workshop (`steamapps/workshop/content/1942280/<id>/`).
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
| Cobro en la moneda del jugador | `RunData.get_player_currency()`, `RunData.remove_currency()` | `singletons/run_data.gd` | Supermercado |
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

## Historial de pruebas

| Fecha | Brotato | ModLoader | Versión del mod | Resultado | Leyendas probadas | Notas |
|---|---|---|---|---|---|---|
| 2026-11-06 | — | — | 0.1.0 | Solo pruebas automáticas | — | Validación, sintaxis (gdparse), pruebas de herramientas y del núcleo. Pendiente de probar dentro de Brotato. |
