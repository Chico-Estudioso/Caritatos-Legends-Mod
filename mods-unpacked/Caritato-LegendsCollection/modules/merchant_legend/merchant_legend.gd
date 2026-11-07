extends Node

# La Leyenda del Mercader: precios de la tienda configurables.
#
# - Precio de los artículos en porcentaje y, opcionalmente, sin inflación por
#   oleada (todo cuesta como en la oleada 1).
# - Precio de los rerolls en porcentaje (0 % = gratis) y, opcionalmente, sin
#   subir con las oleadas.
#
# Se aplica sobre ItemService.get_value() e ItemService.get_reroll_price(), que
# el juego usa para mostrar y cobrar los precios, así que todo queda coherente.
# Como el valor de reciclaje del juego se calcula a partir del precio, también
# cambia en la misma proporción.

const MerchantRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/merchant_legend/merchant_rules.gd")

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const HAGGLE_POPUP_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/merchant_legend/haggle_popup.gd"

var core = null
var module_id := ""
# Regateo de la tienda actual: jugador -> descuento conseguido / ya intentado.
var _haggle := {}
var _haggle_used := {}


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


func item_price_wave(wave: int) -> int:
	return MerchantRules.price_wave(wave, bool(get_setting("fixed_item_prices", false)))


func reroll_price_wave(wave: int) -> int:
	return MerchantRules.price_wave(wave, bool(get_setting("fixed_reroll_prices", false)))


func scale_item_price(value: int) -> int:
	return MerchantRules.scale_item_price(value, int(get_setting("item_price_percent", 100)))


# result = [precio, descuento] como lo devuelve el juego. El descuento se deja
# igual para no alterar los contadores de objetos que registran ahorros.
func scale_reroll_result(result: Array) -> Array:
	if result.size() < 1:
		return result
	var scaled := result.duplicate()
	scaled[0] = MerchantRules.scale_reroll_price(int(result[0]), int(get_setting("reroll_price_percent", 100)))
	return scaled


# --- Regateo -------------------------------------------------------------------
# Una vez por tienda, el jugador intenta parar una aguja en la zona verde. El
# descuento se aplica a los artículos de esa tienda (no al reciclaje: el juego
# calcula el valor de reciclaje sin el id del artículo).

func on_shop_opened() -> void:
	_haggle.clear()
	_haggle_used.clear()


func on_shop_closed() -> void:
	_haggle.clear()
	_haggle_used.clear()


func haggle_enabled() -> bool:
	return is_active() and bool(get_setting("haggle", true))


func can_haggle(player_index: int) -> bool:
	return haggle_enabled() and not _haggle_used.has(player_index)


func haggle_max_percent() -> int:
	return int(get_setting("haggle_max_percent", 10))


func haggle_discount(player_index: int) -> int:
	return int(_haggle.get(player_index, 0)) if is_active() else 0


func set_haggle_result(player_index: int, zone: String) -> int:
	var percent: int = MerchantRules.haggle_percent(zone, haggle_max_percent())
	_haggle[player_index] = percent
	_haggle_used[player_index] = true
	return percent


func apply_haggle(value: int, player_index: int) -> int:
	return MerchantRules.apply_discount(value, haggle_discount(player_index))


func make_haggle_popup(player_index: int) -> Node:
	if not can_haggle(player_index):
		return null
	var popup_script = load(HAGGLE_POPUP_PATH)
	if popup_script == null:
		return null
	var popup = popup_script.new()
	popup.player_index = player_index if Compat.is_coop_run() else -1
	popup.max_percent = haggle_max_percent()
	return popup
