extends "res://ui/menus/shop/item_popup.gd"

# La Leyenda del Regalo: botón «Regalar» en el menú que sale al pulsar un arma
# u objeto propio en la tienda cooperativa, junto a Reciclar y Cancelar. Los
# objetos, que en el juego no tienen botones, muestran Regalar y Cancelar.

const _CLC_GIFT_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_GIFT_ID := "gift_legend"

var _clc_gift_button: Button = null


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática, así que no se llama a ._ready().
func _ready() -> void:
	if _cancel_button == null or _discard_button == null:
		return
	# Copia del botón Cancelar (mismo tema, fuente y sonidos), sin sus señales.
	var button: Button = _cancel_button.duplicate(DUPLICATE_GROUPS | DUPLICATE_SCRIPTS)
	button.name = "CaritatoGiftButton"
	if "unique_name_in_owner" in button:
		button.set("unique_name_in_owner", false)
	button.text = tr("CLC_GIFT_BUTTON")
	button.visible = false
	button.focus_mode = Control.FOCUS_NONE
	_cancel_button.get_parent().add_child_below_node(_discard_button, button)
	var _err = button.connect("pressed", self, "_clc_gift_on_pressed")
	_clc_gift_button = button
	# Con mando: Reciclar → Regalar → Cancelar.
	_discard_button.focus_neighbour_bottom = _discard_button.get_path_to(button)
	button.focus_neighbour_top = button.get_path_to(_discard_button)
	button.focus_neighbour_bottom = button.get_path_to(_cancel_button)
	_cancel_button.focus_neighbour_top = _cancel_button.get_path_to(button)
	_update_button_visibilities()


func should_show_buttons(item_data: ItemParentData, focused: bool) -> bool:
	if .should_show_buttons(item_data, focused):
		return true
	return buttons_enabled and focused and _clc_gift_offers(item_data)


func _update_button_visibilities() -> void:
	if _clc_gift_item_mode():
		# Objetos: el juego no les da botones (no se combinan ni se reciclan).
		for button in [_combine_button, _discard_button]:
			button.hide()
			button.focus_mode = FOCUS_NONE
		_cancel_button.visible = _focused
		_cancel_button.focus_mode = FOCUS_ALL if _focused else FOCUS_NONE
		_clc_gift_show(_focused)
		return
	._update_button_visibilities()
	_clc_gift_show(_focused and _cancel_button.visible and _clc_gift_offers(_item_data))


func _clc_gift_item_mode() -> bool:
	return _item_data != null and not (_item_data is WeaponData) and buttons_enabled and _clc_gift_offers(_item_data)


func _clc_gift_offers(item_data) -> bool:
	var legend = _CLC_GIFT_API.get_runtime(_CLC_GIFT_ID)
	return legend != null and legend.can_offer(item_data)


func _clc_gift_show(show: bool) -> void:
	if _clc_gift_button == null or not is_instance_valid(_clc_gift_button):
		return
	_clc_gift_button.visible = show
	_clc_gift_button.focus_mode = FOCUS_ALL if show else FOCUS_NONE


func _clc_gift_on_pressed() -> void:
	var legend = _CLC_GIFT_API.get_runtime(_CLC_GIFT_ID)
	var item_data = _item_data
	var giver: int = player_index
	# Se cierra el menú como con «Cancelar»: la tienda devuelve el foco al inventario.
	_on_CancelButton_pressed()
	if legend != null and item_data != null:
		legend.start_gift(_clc_gift_find_shop(), giver, item_data, item_data is WeaponData)


func _clc_gift_find_shop() -> Node:
	var node = get_parent()
	while node != null and not node.has_method("_clc_gift_refresh"):
		node = node.get_parent()
	return node if node != null else get_tree().current_scene
