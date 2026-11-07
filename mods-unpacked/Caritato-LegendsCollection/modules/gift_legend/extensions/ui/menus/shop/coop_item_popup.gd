extends "res://ui/menus/shop/coop_item_popup.gd"

# La Leyenda del Regalo: botón «Regalar» en el menú que sale al pulsar un arma
# u objeto propio en la tienda cooperativa, junto a Reciclar y Cancelar. Los
# objetos, que en el juego no tienen botones, muestran Regalar y Cancelar.
#
# Se extiende CoopItemPopup (el menú de la tienda cooperativa) y no ItemPopup:
# CoopItemPopup hereda de ItemPopup al cargarse, antes de que ModLoader
# instale las extensiones, así que una extensión de ItemPopup no le llega.
#
# Precauciones (en la 1.2 la extensión de ItemPopup cerraba el juego al entrar
# en la tienda en solitario):
# - Solo se prepara si la leyenda está activa en una partida cooperativa; si
#   no, el menú se comporta exactamente como el del juego.
# - El botón es nuevo, no una copia de los del juego: toma el tema y la fuente
#   de Cancelar, pero no su script ni sus nodos internos.
# - Los vecinos de foco de Reciclar y Cancelar solo se cambian mientras
#   Regalar está visible, y se restauran al ocultarlo.

const _CLC_GIFT_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_GIFT_ID := "gift_legend"

var _clc_gift_button: Button = null
var _clc_gift_updating := false
var _clc_gift_discard_bottom := NodePath()
var _clc_gift_cancel_top := NodePath()


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática, así que no se llama a ._ready().
func _ready() -> void:
	if _CLC_GIFT_API.get_runtime(_CLC_GIFT_ID) == null or not RunData.is_coop_run:
		return
	if not is_instance_valid(_cancel_button) or not is_instance_valid(_discard_button):
		return
	var container: Node = _discard_button.get_parent()
	if container == null or container != _cancel_button.get_parent():
		_CLC_GIFT_API.trace("Regalo: Reciclar y Cancelar no comparten contenedor; no se añade Regalar")
		return
	_CLC_GIFT_API.trace("Regalo: preparando el botón del menú de J%d" % (player_index + 1))
	var button := Button.new()
	button.name = "CaritatoGiftButton"
	button.text = tr("CLC_GIFT_BUTTON")
	button.theme = _cancel_button.theme
	var font = _cancel_button.get("custom_fonts/font")
	if font is Font:
		button.add_font_override("font", font)
	button.size_flags_horizontal = _cancel_button.size_flags_horizontal
	button.rect_min_size = _cancel_button.rect_min_size
	button.visible = false
	button.focus_mode = Control.FOCUS_NONE
	container.add_child(button)
	container.move_child(button, _discard_button.get_index() + 1)
	var _err = button.connect("pressed", self, "_clc_gift_on_pressed")
	_clc_gift_button = button
	_clc_gift_discard_bottom = _discard_button.focus_neighbour_bottom
	_clc_gift_cancel_top = _cancel_button.focus_neighbour_top
	# Con mando: Reciclar → Regalar → Cancelar.
	button.focus_neighbour_top = button.get_path_to(_discard_button)
	button.focus_neighbour_bottom = button.get_path_to(_cancel_button)
	_CLC_GIFT_API.trace("Regalo: botón listo")


func should_show_buttons(item_data: ItemParentData, focused: bool) -> bool:
	if .should_show_buttons(item_data, focused):
		return true
	return _clc_gift_ready() and buttons_enabled and focused and _clc_gift_offers(item_data)


func _update_button_visibilities() -> void:
	if _clc_gift_updating or not _clc_gift_ready():
		._update_button_visibilities()
		return
	_clc_gift_updating = true
	if _clc_gift_item_mode():
		# Objetos: el juego no les da botones (no se combinan ni se reciclan).
		for button in [_combine_button, _discard_button]:
			button.hide()
			button.focus_mode = FOCUS_NONE
		_cancel_button.visible = _focused
		_cancel_button.focus_mode = FOCUS_ALL if _focused else FOCUS_NONE
		_clc_gift_show(_focused)
	else:
		._update_button_visibilities()
		_clc_gift_show(_focused and _cancel_button.visible and _clc_gift_offers(_item_data))
	_clc_gift_updating = false


func _clc_gift_ready() -> bool:
	return _clc_gift_button != null and is_instance_valid(_clc_gift_button)


func _clc_gift_item_mode() -> bool:
	return _item_data != null and not (_item_data is WeaponData) and buttons_enabled and _clc_gift_offers(_item_data)


func _clc_gift_offers(item_data) -> bool:
	var legend = _CLC_GIFT_API.get_runtime(_CLC_GIFT_ID)
	return legend != null and legend.can_offer(item_data)


func _clc_gift_show(show: bool) -> void:
	if not _clc_gift_ready():
		return
	_clc_gift_button.visible = show
	_clc_gift_button.focus_mode = FOCUS_ALL if show else FOCUS_NONE
	if show:
		_discard_button.focus_neighbour_bottom = _discard_button.get_path_to(_clc_gift_button)
		_cancel_button.focus_neighbour_top = _cancel_button.get_path_to(_clc_gift_button)
	else:
		_discard_button.focus_neighbour_bottom = _clc_gift_discard_bottom
		_cancel_button.focus_neighbour_top = _clc_gift_cancel_top


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
