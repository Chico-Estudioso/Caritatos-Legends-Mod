extends "res://ui/menus/shop/base_shop.gd"

# La Leyenda del Supermercado: botón en la tienda y colocación del encargo.

const _CLC_SUPER_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_SUPER_RULES = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/supermarket_legend/supermarket_rules.gd")
const _CLC_SUPER_ID := "supermarket_legend"

var _clc_super_button: Button = null


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática (primero el del juego), así que no se llama a ._ready().
func _ready() -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if legend == null:
		return
	legend.on_shop_opened()
	# Versión inicial: solo en la tienda de un jugador.
	if RunData.is_coop_run:
		return
	_clc_super_add_button()


func _clc_super_add_button() -> void:
	var reroll_button = _get_reroll_button(0)
	if reroll_button == null or reroll_button.get_parent() == null:
		return
	var button := Button.new()
	button.name = "CaritatoSupermarketButton"
	button.text = tr("CLC_SUPER_BUTTON")
	button.size_flags_vertical = reroll_button.size_flags_vertical
	button.rect_min_size = Vector2(0, reroll_button.rect_min_size.y)
	reroll_button.get_parent().add_child_below_node(reroll_button, button)
	var _err = button.connect("pressed", self, "_clc_super_on_button_pressed")
	_clc_super_button = button


func _clc_super_on_button_pressed() -> void:
	var legend = _CLC_SUPER_API.get_runtime(_CLC_SUPER_ID)
	if legend != null:
		legend.open_catalog(self, 0, _clc_super_button)


# Coloca el artículo en un hueco vacío o en el último no bloqueado y refresca
# la tienda igual que hace el juego al rerolear.
func _clc_super_place_item(item, player_index: int) -> bool:
	var container = _get_shop_items_container(player_index)
	var items: Array = _shop_items[player_index]
	var locked := []
	for index in items.size():
		locked.append(container.is_shop_item_locked_visually(index))

	var slot: int = _CLC_SUPER_RULES.target_slot(locked, ItemService.NB_SHOP_ITEMS)
	if slot < 0:
		return false

	var entry := [ItemService.apply_item_effect_modifications(item, player_index), RunData.current_wave]
	if slot >= items.size():
		items.append(entry)
	else:
		items[slot] = entry

	container.unlock_all_shop_items_visually()
	container.set_shop_items(items)
	_update_visual_locks()
	_has_bonus_free_reroll[player_index] = items.empty()
	set_reroll_button_price(player_index)
	return true
