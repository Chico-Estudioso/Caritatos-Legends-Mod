extends "res://ui/menus/shop/coop_shop.gd"

# La Leyenda del Regalo: contador de regalos por tienda y refresco de la
# interfaz tras un regalo. El botón «Regalar» está en el menú de cada arma u
# objeto (extensión de coop_item_popup.gd).

const _CLC_GIFT_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_GIFT_ID := "gift_legend"


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática (primero el del juego), así que no se llama a ._ready().
func _ready() -> void:
	var legend = _CLC_GIFT_API.get_runtime(_CLC_GIFT_ID)
	if legend != null:
		_CLC_GIFT_API.trace("Tienda cooperativa: lista (Regalo)")
		legend.on_shop_opened()
		_clc_gift_check_popups()


# Si el menú del arma u objeto no tiene la extensión, «Regalar» no saldrá:
# se deja constancia en el log de ModLoader para poder diagnosticarlo.
func _clc_gift_check_popups() -> void:
	for player_index in RunData.get_player_count():
		var popup = _get_item_popup(player_index)
		if popup != null and not popup.has_method("_clc_gift_on_pressed"):
			ModLoaderLog.error("El menú del objeto de J%d no tiene el botón Regalar (%s)." % [player_index + 1, popup.get_script().resource_path if popup.get_script() != null else "?"], "Caritato-LegendsCollection:Gift")


func _exit_tree() -> void:
	_CLC_GIFT_API.clear_popups()


# Tras un regalo: inventario, estadísticas, precios de la tienda y del reroll
# de los jugadores implicados (los objetos pueden cambiar precios y rerolls).
# El foco de quien regala vuelve al reroll, porque su inventario se rehace.
func _clc_gift_refresh(player_indices: Array) -> void:
	for player_index in player_indices:
		var gear_container = _get_gear_container(player_index)
		gear_container.set_weapons_data(RunData.get_player_weapons(player_index))
		gear_container.set_items_data(RunData.get_player_items(player_index))
		_update_stats(player_index)
		_get_shop_items_container(player_index).reload_shop_items()
		var reroll: Array = ItemService.get_reroll_price(RunData.current_wave, _paid_reroll_count[player_index], player_index)
		_reroll_price[player_index] = reroll[0]
		_reroll_discount[player_index] = reroll[1]
		set_reroll_button_price(player_index)
	if not player_indices.empty():
		Utils.focus_player_control(_get_reroll_button(player_indices[0]), player_indices[0])
