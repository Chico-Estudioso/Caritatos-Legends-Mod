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

var core = null
var module_id := ""


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
