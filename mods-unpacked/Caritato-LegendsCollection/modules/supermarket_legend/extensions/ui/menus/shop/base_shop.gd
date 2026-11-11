extends "res://ui/menus/shop/base_shop.gd"

# La Leyenda del Supermercado: botón en la tienda y viaje de los encargos
# hasta la tienda siguiente (como artículos bloqueados).

const _CLC_SUPER_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_SUPER_ID := "supermarket_legend"

var _clc_super_button: Button = null


# _enter_tree se ejecuta antes que el _ready de la tienda, donde el juego la
# rellena: así la leyenda ya sabe qué encargos llegan a esta tienda.
func _enter_tree() -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if legend != null:
		legend.on_shop_opened()


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática (primero el del juego), así que no se llama a ._ready().
func _ready() -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if legend == null:
		return
	_CLC_SUPER_API.trace("Tienda: lista (Supermercado)")
	var relocked := false
	for player_index in RunData.get_player_count():
		if legend.relock_arrivals(_shop_items[player_index], player_index):
			relocked = true
	if relocked:
		_update_visual_locks()
	# La caja del encargo sale un momento después de que se vea la tienda.
	var _err = get_tree().create_timer(0.4).connect("timeout", self, "_clc_super_show_arrivals")
	# Versión inicial: solo en la tienda de un jugador.
	if RunData.is_coop_run:
		return
	_clc_super_add_button()


func _exit_tree() -> void:
	_CLC_SUPER_API.clear_popups()
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if legend != null:
		legend.on_shop_closed()


func _clc_super_show_arrivals() -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if legend == null or not is_inside_tree():
		return
	for player_index in RunData.get_player_count():
		var popup = legend.make_arrival_popup(_shop_items[player_index], player_index)
		if popup != null:
			_CLC_SUPER_API.show_popup(popup)


# Mientras se rerolea, los encargos de esta tienda salen de la lista de
# bloqueados: si no, la tienda bloqueaba a la vista una casilla nueva al azar
# por cada encargo (ver hold_pending_locks).
func _on_RerollButton_pressed(player_index: int) -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if legend == null:
		._on_RerollButton_pressed(player_index)
		return
	legend.hold_pending_locks(player_index)
	._on_RerollButton_pressed(player_index)
	legend.release_pending_locks(player_index)


func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	var locked := player_locked_items
	if legend != null:
		if just_entered_shop:
			locked = legend.fit_entering_locked(player_locked_items, player_index)
		else:
			locked = legend.filter_reroll_locked(player_locked_items, player_index)
	.fill_shop_items(locked, player_index, just_entered_shop)


func _clc_super_add_button() -> void:
	var reroll_button = _get_reroll_button(0)
	if reroll_button == null or reroll_button.get_parent() == null:
		return
	var button := Button.new()
	button.name = "CaritatoSupermarketButton"
	button.size_flags_vertical = reroll_button.size_flags_vertical
	button.rect_min_size = Vector2(0, reroll_button.rect_min_size.y)
	reroll_button.get_parent().add_child_below_node(reroll_button, button)
	var _err = button.connect("pressed", self, "_clc_super_on_button_pressed")
	_clc_super_button = button
	_clc_super_update_button()


func _clc_super_update_button() -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if _clc_super_button == null or not is_instance_valid(_clc_super_button) or legend == null:
		return
	var left: int = legend.orders_left(0)
	_clc_super_button.text = tr("CLC_SUPER_BUTTON_COUNT") % left if left > 0 else tr("CLC_SUPER_BUTTON")


func _clc_super_on_button_pressed() -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if legend != null:
		legend.open_catalog(self, 0, _clc_super_button)


# Tras encargar: el recargo ya se ha cobrado.
func _clc_super_on_ordered(player_index: int) -> void:
	_clc_super_update_button()
	set_reroll_button_price(player_index)
