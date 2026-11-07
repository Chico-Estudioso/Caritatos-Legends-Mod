extends "res://ui/menus/shop/base_shop.gd"

# La Leyenda del Anzuelo: ganchos en la tienda.

const _CLC_HOOK_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")

const _CLC_HOOK_ID := "hook_legend"


# _enter_tree se ejecuta antes que el _ready de la tienda, que es donde se
# generan los artículos: así la probabilidad ya está aplicada (o restaurada si
# la leyenda se ha desactivado) cuando aparecen el Anzuelo y su descripción.
func _enter_tree() -> void:
	var core = _CLC_HOOK_API.get_core()
	if core == null:
		return
	_CLC_HOOK_API.trace("Tienda: entrando (Anzuelo)")
	var legend = core.get_runtime(_CLC_HOOK_ID)
	if legend != null:
		legend.apply_curse_chance()
		_CLC_HOOK_API.trace("Tienda: probabilidad del Anzuelo aplicada")


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática, así que no se llama a ._ready().
func _ready() -> void:
	if _CLC_HOOK_API.get_runtime(_CLC_HOOK_ID) == null:
		return
	_CLC_HOOK_API.trace("Tienda: lista (Anzuelo)")
	# «¡Pica!» sale un momento después de que se vea la tienda.
	var _err = get_tree().create_timer(0.4).connect("timeout", self, "_clc_hook_show_fishing")


func _exit_tree() -> void:
	_CLC_HOOK_API.clear_popups()


func _clc_hook_show_fishing() -> void:
	var legend = _CLC_HOOK_API.get_runtime(_CLC_HOOK_ID)
	if legend == null or not is_inside_tree():
		return
	for player_index in RunData.get_player_count():
		var popup = legend.make_fishing_popup(player_index)
		if popup != null:
			var _err = popup.connect("closed", self, "_clc_hook_on_fishing", [player_index])
			_CLC_HOOK_API.show_popup(popup)


# Premio del minijuego: un reroll gratis en esta tienda.
func _clc_hook_on_fishing(result: String, player_index: int) -> void:
	if result != "caught" or not is_inside_tree():
		return
	_free_rerolls[player_index] += 1
	set_reroll_button_price(player_index)


func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void:
	if just_entered_shop:
		_CLC_HOOK_API.trace("Tienda: generando artículos de J%d" % (player_index + 1))
	.fill_shop_items(player_locked_items, player_index, just_entered_shop)
	if not just_entered_shop:
		return
	var legend = _CLC_HOOK_API.get_runtime(_CLC_HOOK_ID)
	if legend != null:
		legend.on_shop_entered(_shop_items[player_index], player_locked_items.size(), player_index)
	_CLC_HOOK_API.trace("Tienda: artículos de J%d listos" % (player_index + 1))
