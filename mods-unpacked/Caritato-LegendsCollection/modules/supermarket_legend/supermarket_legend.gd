extends Node

# La Leyenda del Supermercado.
#
# Un botón en la tienda abre un catálogo con los objetos y armas que el juego
# podría ofrecerte (desbloqueados, no prohibidos, dentro de los límites y de
# las restricciones del personaje) hasta el tier elegido.
#
# Para que no rompa la partida:
#   - Los encargos se ganan al derrotar a un élite o a un jefe, y se guardan
#     hasta gastarlos (o, si se configura así, hay encargos en cada tienda,
#     que no se acumulan).
#   - Encargar cuesta un recargo (por defecto, el 50 % del precio) que se paga
#     al momento.
#   - El artículo no aparece en esta tienda: llega bloqueado a la siguiente,
#     donde se compra a su precio normal. Viaja en la lista de bloqueados del
#     juego, así que se guarda con la partida.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const SupermarketRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/supermarket_legend/supermarket_rules.gd")
const MENU_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/supermarket_legend/supermarket_menu.gd"
const BOX_POPUP_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/supermarket_legend/order_box_popup.gd"
const LOG_NAME := "Caritato-LegendsCollection:Supermarket"
# Encargos gastados en la partida en curso (los ganados se cuentan con las
# bajas de élites y jefes, que guarda el juego).
const RUN_STATE_PATH := "user://caritato_legends/supermarket_run.json"

var core = null
var module_id := ""

# Para las pruebas: dónde se guarda el estado de la partida.
var run_state_path := RUN_STATE_PATH

# Tienda actual: jugador -> encargos hechos en ella
var _orders_done := {}
# jugador -> ids encargados en esta tienda (llegan en la siguiente)
var _pending := {}
# jugador -> ids que llegan en esta tienda
var _arriving := {}
# jugador -> encargos apartados de la lista de bloqueados mientras se rerolea
var _held := {}
# {run, kills, spent: {jugador: gastados}} de la partida en curso
var _run_state := {}


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


func mode() -> String:
	return str(get_setting("order_mode", SupermarketRules.MODE_BOSS))


# --- Ciclo de la tienda ------------------------------------------------------

# Se llama al entrar en la tienda, antes de que el juego la rellene.
func on_shop_opened() -> void:
	_release_all_held()
	_arriving = _pending
	_pending = {}
	_orders_done = {}
	sync_run_state()


func on_shop_closed() -> void:
	_release_all_held()


# Lee los encargos gastados en esta partida. Si es otra partida, empiezan de
# cero.
func sync_run_state() -> void:
	_run_state = SupermarketRules.next_run_state(_read_run_state(), Compat.run_fingerprint(), Compat.elite_and_boss_kills())
	_write_run_state()


# Al rerolear, la tienda del juego cuenta los bloqueados para saber cuántas
# casillas bloquear a la vista (las primeras) y si se puede rerolear. Los
# encargos de esta tienda no están en ella: contarlos bloqueaba una casilla
# nueva al azar y, con la tienda llena de bloqueados, impedía rerolear. Se
# apartan de la lista mientras dura el reroll y se devuelven después.
func hold_pending_locks(player_index: int) -> void:
	release_pending_locks(player_index)
	var pending: Array = _pending.get(player_index, [])
	if pending.empty() or not is_active():
		return
	var live: Array = Compat.locked_shop_items(player_index)
	var indices: Array = SupermarketRules.last_occurrences(_ids_of(live), pending)
	var taken := []
	for position in range(indices.size() - 1, -1, -1):
		var index: int = indices[position]
		taken.push_front(live[index])
		live.remove(index)
	if not taken.empty():
		_held[player_index] = taken


func release_pending_locks(player_index: int) -> void:
	if not _held.has(player_index):
		return
	Compat.locked_shop_items(player_index).append_array(_held[player_index])
	var _erased = _held.erase(player_index)


func _release_all_held() -> void:
	for player_index in _held.keys():
		release_pending_locks(player_index)


# Bloqueados que la tienda pasa al rerolear: sin los encargos de esta tienda,
# que llegan en la siguiente. Si ya se han apartado (hold_pending_locks), no
# hay nada que quitar.
func filter_reroll_locked(locked: Array, player_index: int) -> Array:
	var pending: Array = _pending.get(player_index, [])
	if pending.empty() or not is_active() or _held.has(player_index):
		return locked
	var kept_indices: Array = SupermarketRules.keep_without(_ids_of(locked), pending)
	var result := []
	for index in kept_indices:
		result.append(locked[index])
	return result


# Al entrar en la tienda: si hay más bloqueados que huecos (por ejemplo, un
# encargo más cuatro artículos bloqueados), se descartan los que no son encargos.
func fit_entering_locked(locked: Array, player_index: int) -> Array:
	var max_slots := Compat.nb_shop_items()
	if locked.size() <= max_slots:
		return locked
	var arriving: Array = _arriving.get(player_index, []).duplicate()
	var is_order := []
	for id in _ids_of(locked):
		var order: bool = arriving.has(id)
		if order:
			arriving.erase(id)
		is_order.append(order)
	var drop: Array = SupermarketRules.overflow_to_drop(is_order, max_slots)
	var kept := []
	for index in locked.size():
		if not drop.has(index):
			kept.append(locked[index])
	var live: Array = Compat.locked_shop_items(player_index)
	live.clear()
	live.append_array(kept)
	return kept


# Tras rellenar la tienda: los encargos que han llegado quedan bloqueados,
# aunque el jugador tenga desactivado «mantener los bloqueados». Devuelve si
# ha cambiado algo (la tienda debe actualizar los candados).
func relock_arrivals(shop_items: Array, player_index: int) -> bool:
	var arriving: Array = _arriving.get(player_index, [])
	if arriving.empty():
		return false
	var locked_ids := _ids_of(Compat.locked_shop_items(player_index))
	var changed := false
	for entry in shop_items:
		var id = entry[0].my_id
		if arriving.has(id) and not locked_ids.has(id):
			Compat.lock_shop_item(entry[0], int(entry[1]), player_index)
			locked_ids.append(id)
			changed = true
	return changed


func arrivals(player_index: int) -> int:
	return _arriving.get(player_index, []).size()


# Artículos de la tienda que son encargos recién llegados: [{data, label, tier}].
func arrived_entries(shop_items: Array, player_index: int) -> Array:
	var remaining: Array = _arriving.get(player_index, []).duplicate()
	var result := []
	for entry in shop_items:
		var item = entry[0] if entry is Array and not entry.empty() else null
		if item == null or not remaining.has(item.my_id):
			continue
		remaining.erase(item.my_id)
		result.append({"data": item, "label": tr(item.name), "tier": int(item.tier) if "tier" in item else 0})
	return result


# Ventana «¡Tu encargo ha llegado!» (null si está desactivada o no hay nada).
func make_arrival_popup(shop_items: Array, player_index: int) -> Node:
	if not is_active() or not bool(get_setting("unboxing", true)):
		return null
	var entries := arrived_entries(shop_items, player_index)
	if entries.empty():
		return null
	var popup_script = load(BOX_POPUP_PATH)
	if popup_script == null:
		return null
	var popup = popup_script.new()
	popup.items = entries
	popup.player_index = player_index if Compat.is_coop_run() else -1
	return popup


# --- Encargos ------------------------------------------------------------------

# Encargos que le quedan al jugador. En el modo «al derrotar un élite o un
# jefe» se acumulan durante la partida hasta gastarlos.
func orders_left(player_index: int) -> int:
	var per := int(get_setting("orders_per_shop", 1))
	if mode() == SupermarketRules.MODE_EVERY_SHOP:
		return SupermarketRules.every_shop_left(per, int(_orders_done.get(player_index, 0)))
	return SupermarketRules.boss_credits(Compat.elite_and_boss_kills(), per, spent_orders(player_index))


func spent_orders(player_index: int) -> int:
	var spent = _run_state.get("spent", {})
	return int(spent.get(str(player_index), 0)) if spent is Dictionary else 0


# ¿Tiene o ha tenido encargos en esta tienda? (si no, el catálogo explica cómo
# ganarlos).
func is_unlocked(player_index: int = 0) -> bool:
	return orders_left(player_index) > 0 or int(_orders_done.get(player_index, 0)) > 0


func price_of(item, player_index: int) -> int:
	return Compat.get_shop_price(item, player_index)


func fee_of(item, player_index: int) -> int:
	return SupermarketRules.order_fee(price_of(item, player_index), int(get_setting("order_markup_percent", 50)))


# Catálogo: Array de {item, label, tier, is_weapon} ordenado por tier y nombre.
func get_catalog(player_index: int) -> Array:
	var entries := []
	var max_tier := int(get_setting("max_tier", 4)) - 1
	var include_weapons := bool(get_setting("include_weapons", true))
	for tier in range(0, max_tier + 1):
		for item in Compat.get_shop_pool(tier, false):
			if Compat.can_offer_item(item, player_index):
				entries.append({"item": item, "label": tr(item.name), "tier": tier, "is_weapon": false})
		if include_weapons:
			for weapon in Compat.get_shop_pool(tier, true):
				if Compat.can_offer_weapon(weapon, player_index):
					entries.append({"item": weapon, "label": tr(weapon.name), "tier": tier, "is_weapon": true})
	return SupermarketRules.sort_entries(entries)


# Motivo por el que no se puede encargar ahora (sin mirar el artículo), o "".
func block_reason(player_index: int) -> String:
	if not is_active():
		return "CLC_SUPER_ERROR_INACTIVE"
	if orders_left(player_index) <= 0:
		return "CLC_SUPER_ERROR_NO_ORDERS" if int(_orders_done.get(player_index, 0)) > 0 else "CLC_SUPER_ERROR_LOCKED"
	if not SupermarketRules.fits_next_shop(Compat.locked_shop_items(player_index).size(), Compat.nb_shop_items()):
		return "CLC_SUPER_ERROR_NO_SLOT"
	return ""


# Cobra el recargo y deja el artículo bloqueado para la siguiente tienda.
# Devuelve "" si todo ha ido bien o la clave del texto de error.
func order(shop: Node, item, player_index: int) -> String:
	var reason := block_reason(player_index)
	if reason != "":
		return reason
	var fee := fee_of(item, player_index)
	if Compat.get_player_currency(player_index) < fee:
		return "CLC_SUPER_ERROR_NO_GOLD"
	if fee > 0:
		Compat.remove_currency(fee, player_index)
	Compat.lock_shop_item(item, Compat.current_wave(), player_index)
	if not _pending.has(player_index):
		_pending[player_index] = []
	_pending[player_index].append(item.my_id)
	_orders_done[player_index] = int(_orders_done.get(player_index, 0)) + 1
	if mode() != SupermarketRules.MODE_EVERY_SHOP:
		var spent = _run_state.get("spent", {})
		if not spent is Dictionary:
			spent = {}
		spent[str(player_index)] = spent_orders(player_index) + 1
		_run_state["spent"] = spent
		_write_run_state()
	if shop != null and is_instance_valid(shop) and shop.has_method("_clc_super_on_ordered"):
		shop._clc_super_on_ordered(player_index)
	ModLoaderLog.info("Encargo: %s (jugador %d, recargo %d); llega en la siguiente tienda" % [item.my_id, player_index + 1, fee], LOG_NAME)
	return ""


func open_catalog(shop: Node, player_index: int, return_focus: Control) -> void:
	var menu_script = load(MENU_PATH)
	if menu_script == null:
		ModLoaderLog.error("No se pudo cargar el catálogo del Supermercado.", LOG_NAME)
		return
	var menu = menu_script.new()
	get_tree().root.add_child(menu)
	menu.open(self, shop, player_index, return_focus)


func _read_run_state():
	var file := File.new()
	if not file.file_exists(run_state_path) or file.open(run_state_path, File.READ) != OK:
		return {}
	var parsed := JSON.parse(file.get_as_text())
	file.close()
	return parsed.result if parsed.error == OK and parsed.result is Dictionary else {}


func _write_run_state() -> void:
	var dir := Directory.new()
	var _made = dir.make_dir_recursive(run_state_path.get_base_dir())
	var file := File.new()
	if file.open(run_state_path, File.WRITE) != OK:
		ModLoaderLog.warning("No se pudo guardar %s" % run_state_path, LOG_NAME)
		return
	file.store_string(to_json(_run_state))
	file.close()


static func _ids_of(locked: Array) -> Array:
	var ids := []
	for entry in locked:
		ids.append(entry[0].my_id if entry is Array and not entry.empty() and entry[0] != null else "")
	return ids
