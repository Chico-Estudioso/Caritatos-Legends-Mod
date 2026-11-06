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
	var legend = core.get_runtime(_CLC_HOOK_ID)
	if legend != null:
		legend.apply_curse_chance()


func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void:
	.fill_shop_items(player_locked_items, player_index, just_entered_shop)
	if not just_entered_shop:
		return
	var legend = _CLC_HOOK_API.get_runtime(_CLC_HOOK_ID)
	if legend != null:
		legend.on_shop_entered(_shop_items[player_index], player_locked_items.size(), player_index)
