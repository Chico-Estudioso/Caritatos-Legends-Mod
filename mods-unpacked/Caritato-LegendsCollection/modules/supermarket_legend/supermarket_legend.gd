extends Node

# La Leyenda del Supermercado.
#
# Un botón en la tienda abre un catálogo con los objetos y armas que el juego
# podría ofrecerte (desbloqueados, no prohibidos, dentro de los límites y de
# las restricciones del personaje) hasta el tier elegido. El artículo elegido
# se coloca en un hueco libre de tu tienda (o en el último no bloqueado) y se
# compra como cualquier otro, con el precio y las reglas del juego.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const SupermarketRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/supermarket_legend/supermarket_rules.gd")
const MENU_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/supermarket_legend/supermarket_menu.gd"
const LOG_NAME := "Caritato-LegendsCollection:Supermarket"

var core = null
var module_id := ""
# player_index -> encargos hechos en la tienda actual
var _orders := {}


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


func on_shop_opened() -> void:
	_orders.clear()


func orders_left(player_index: int) -> int:
	return int(max(0, int(get_setting("orders_per_shop", 1)) - int(_orders.get(player_index, 0))))


func can_order(player_index: int) -> bool:
	return SupermarketRules.can_order(int(_orders.get(player_index, 0)), int(get_setting("orders_per_shop", 1)))


func price_of(item, player_index: int) -> int:
	return Compat.get_shop_price(item, player_index)


func fee_of(item, player_index: int) -> int:
	return SupermarketRules.order_fee(price_of(item, player_index), int(get_setting("order_fee_percent", 0)))


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


# Cobra el encargo y pide a la tienda que coloque el artículo. Devuelve "" si
# todo ha ido bien o la clave del texto de error.
func order(shop: Node, item, player_index: int) -> String:
	if not is_active():
		return "CLC_SUPER_ERROR_INACTIVE"
	if not can_order(player_index):
		return "CLC_SUPER_ERROR_NO_ORDERS"
	var fee := fee_of(item, player_index)
	if Compat.get_player_currency(player_index) < fee:
		return "CLC_SUPER_ERROR_NO_GOLD"
	if not shop.has_method("_clc_super_place_item") or not shop._clc_super_place_item(item, player_index):
		return "CLC_SUPER_ERROR_NO_SLOT"
	if fee > 0:
		Compat.remove_currency(fee, player_index)
	_orders[player_index] = int(_orders.get(player_index, 0)) + 1
	ModLoaderLog.info("Encargo: %s (jugador %d, coste %d)" % [item.my_id, player_index + 1, fee], LOG_NAME)
	return ""


func open_catalog(shop: Node, player_index: int, return_focus: Control) -> void:
	var menu_script = load(MENU_PATH)
	if menu_script == null:
		ModLoaderLog.error("No se pudo cargar el catálogo del Supermercado.", LOG_NAME)
		return
	var menu = menu_script.new()
	get_tree().root.add_child(menu)
	menu.open(self, shop, player_index, return_focus)
