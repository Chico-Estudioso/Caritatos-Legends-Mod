extends "res://ui/menus/shop/coop_shop.gd"

# La Leyenda del Regalo: botón «Regalar» en el panel de cada jugador de la
# tienda cooperativa y refresco de la interfaz tras un regalo.

const _CLC_GIFT_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_GIFT_ID := "gift_legend"

var _clc_gift_buttons := {}


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática (primero el del juego), así que no se llama a ._ready().
func _ready() -> void:
	var legend = _CLC_GIFT_API.get_runtime(_CLC_GIFT_ID)
	if legend == null:
		return
	legend.on_shop_opened()
	if RunData.get_player_count() < 2:
		return
	for player_index in RunData.get_player_count():
		_clc_gift_add_button(player_index)


func _clc_gift_add_button(player_index: int) -> void:
	var container = _get_coop_player_container(player_index)
	if container == null or not "reroll_button" in container or container.reroll_button == null:
		return
	var reroll_button: Control = container.reroll_button
	var parent: Node = reroll_button.get_parent()
	if parent == null:
		return
	var button := Button.new()
	button.name = "CaritatoGiftButton"
	button.text = tr("CLC_GIFT_BUTTON")
	button.size_flags_vertical = reroll_button.size_flags_vertical
	parent.add_child_below_node(reroll_button, button)
	var _err = button.connect("pressed", self, "_clc_gift_on_button_pressed", [player_index])
	_clc_gift_buttons[player_index] = button


func _clc_gift_on_button_pressed(player_index: int) -> void:
	var legend = _CLC_GIFT_API.get_runtime(_CLC_GIFT_ID)
	if legend != null:
		legend.open_menu(self, player_index, _clc_gift_buttons.get(player_index))


# Tras un regalo: inventario, estadísticas, precios de la tienda y del reroll
# de los jugadores implicados (los objetos pueden cambiar precios y rerolls).
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
