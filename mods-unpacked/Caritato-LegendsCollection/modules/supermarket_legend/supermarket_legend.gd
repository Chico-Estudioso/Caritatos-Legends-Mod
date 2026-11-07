extends Node

# La Leyenda del Supermercado.
#
# Un botón en la tienda abre un catálogo con los objetos y armas que el juego
# podría ofrecerte (desbloqueados, no prohibidos, dentro de los límites y de
# las restricciones del personaje) hasta el tier elegido.
#
# Para que no rompa la partida:
#   - Los encargos se ganan al derrotar a un élite o a un jefe (o, si se
#     configura así, en cada tienda).
#   - Encargar cuesta un recargo (por defecto, el 50 % del precio) que se paga
#     al momento.
#   - El artículo no aparece en esta tienda: llega bloqueado a la siguiente,
#     donde se compra a su precio normal. Viaja en la lista de bloqueados del
#     juego, así que se guarda con la partida.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const SupermarketRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/supermarket_legend/supermarket_rules.gd")
const MENU_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/supermarket_legend/supermarket_menu.gd"
const LOG_NAME := "Caritato-LegendsCollection:Supermarket"

var core = null
var module_id := ""

# Tienda actual
var _orders_done := {}
var _orders_allowed := 0
var _unlocked := false
# jugador -> ids encargados en esta tienda (llegan en la siguiente)
var _pending := {}
# jugador -> ids que llegan en esta tienda
var _arriving := {}
# Bajas de élites y jefes al salir de la tienda anterior.
var _snapshot_wave := -1
var _snapshot_kills := -1


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
	_arriving = _pending
	_pending = {}
	_orders_done = {}
	var wave := Compat.current_wave()
	var special_wave := Compat.was_elite_or_boss_wave(wave)
	_unlocked = SupermarketRules.unlocked_by_kills(_snapshot_wave, _snapshot_kills, wave, Compat.elite_and_boss_kills(), special_wave)
	_orders_allowed = SupermarketRules.orders_for_shop(mode(), int(get_setting("orders_per_shop", 1)), _unlocked)


func on_shop_closed() -> void:
	# Al pulsar «Ir» el juego ya ha avanzado la oleada: la foto es para la siguiente tienda.
	_snapshot_wave = Compat.current_wave()
	_snapshot_kills = Compat.elite_and_boss_kills()


# Bloqueados que la tienda pasa al rerolear: sin los encargos de esta tienda,
# que llegan en la siguiente.
func filter_reroll_locked(locked: Array, player_index: int) -> Array:
	var pending: Array = _pending.get(player_index, [])
	if pending.empty() or not is_active():
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


# --- Encargos ------------------------------------------------------------------

func orders_left(player_index: int) -> int:
	return int(max(0, _orders_allowed - int(_orders_done.get(player_index, 0))))


func is_unlocked() -> bool:
	return _orders_allowed > 0


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
	if _orders_allowed <= 0:
		return "CLC_SUPER_ERROR_LOCKED"
	if not SupermarketRules.can_order(int(_orders_done.get(player_index, 0)), _orders_allowed):
		return "CLC_SUPER_ERROR_NO_ORDERS"
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


static func _ids_of(locked: Array) -> Array:
	var ids := []
	for entry in locked:
		ids.append(entry[0].my_id if entry is Array and not entry.empty() and entry[0] != null else "")
	return ids
