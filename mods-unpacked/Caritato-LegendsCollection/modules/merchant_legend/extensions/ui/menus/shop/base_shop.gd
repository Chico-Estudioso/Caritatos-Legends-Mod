extends "res://ui/menus/shop/base_shop.gd"

# La Leyenda del Mercader: botón «Regatear» junto al reroll de cada jugador.
# El descuento conseguido se aplica a los artículos de esta tienda.

const _CLC_MERCHANT_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_MERCHANT_ID := "merchant_legend"

var _clc_merchant_buttons := {}


func _enter_tree() -> void:
	var legend = _CLC_MERCHANT_API.get_runtime(_CLC_MERCHANT_ID)
	if legend != null:
		legend.on_shop_opened()


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática, así que no se llama a ._ready().
func _ready() -> void:
	var legend = _CLC_MERCHANT_API.get_runtime(_CLC_MERCHANT_ID)
	if legend == null or not legend.haggle_enabled():
		return
	_CLC_MERCHANT_API.trace("Tienda: añadiendo Regatear")
	for player_index in RunData.get_player_count():
		_clc_merchant_add_button(player_index)


func _exit_tree() -> void:
	_CLC_MERCHANT_API.clear_popups()
	var legend = _CLC_MERCHANT_API.get_runtime(_CLC_MERCHANT_ID)
	if legend != null:
		legend.on_shop_closed()


func _clc_merchant_add_button(player_index: int) -> void:
	var reroll_button = _get_reroll_button(player_index)
	if reroll_button == null or reroll_button.get_parent() == null:
		return
	var button := Button.new()
	button.name = "CaritatoHaggleButton%d" % player_index
	button.text = tr("CLC_MERCHANT_HAGGLE_BUTTON")
	button.size_flags_vertical = reroll_button.size_flags_vertical
	button.rect_min_size = Vector2(0, reroll_button.rect_min_size.y)
	reroll_button.get_parent().add_child_below_node(reroll_button, button)
	var _err = button.connect("pressed", self, "_clc_merchant_on_haggle_pressed", [player_index])
	_clc_merchant_buttons[player_index] = button


func _clc_merchant_on_haggle_pressed(player_index: int) -> void:
	var legend = _CLC_MERCHANT_API.get_runtime(_CLC_MERCHANT_ID)
	if legend == null:
		return
	var popup = legend.make_haggle_popup(player_index)
	if popup == null:
		return
	var _err = popup.connect("closed", self, "_clc_merchant_on_haggled", [player_index])
	_CLC_MERCHANT_API.show_popup(popup)


func _clc_merchant_on_haggled(result: String, player_index: int) -> void:
	var legend = _CLC_MERCHANT_API.get_runtime(_CLC_MERCHANT_ID)
	if legend == null or not is_inside_tree():
		return
	var button = _clc_merchant_buttons.get(player_index)
	if result != "cancelled":
		var percent: int = legend.set_haggle_result(player_index, result)
		var container = _get_shop_items_container(player_index)
		if container != null:
			container.reload_shop_items()
			container.update_buttons_color()
		if button != null and is_instance_valid(button):
			button.text = tr("CLC_MERCHANT_HAGGLE_DONE") % percent if percent > 0 else tr("CLC_MERCHANT_HAGGLE_NONE")
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE
	Utils.focus_player_control(_get_reroll_button(player_index), player_index)
