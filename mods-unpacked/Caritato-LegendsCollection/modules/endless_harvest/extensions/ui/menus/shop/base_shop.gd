extends "res://ui/menus/shop/base_shop.gd"

# La Leyenda de la Cosecha Eterna: «Cosecha dorada» al entrar en cada tienda
# del modo infinito.

const _CLC_HARVEST_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_HARVEST_ID := "endless_harvest"

# Al continuar una partida guardada en la tienda no se repite el minijuego
# (si no, salir y volver daría el premio otra vez).
var _clc_harvest_resumed := false


func _enter_tree() -> void:
	_clc_harvest_resumed = RunData.resumed_from_state_in_shop


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática, así que no se llama a ._ready().
func _ready() -> void:
	if _clc_harvest_resumed or _CLC_HARVEST_API.get_runtime(_CLC_HARVEST_ID) == null:
		return
	var _err = get_tree().create_timer(0.4).connect("timeout", self, "_clc_harvest_show_golden")


func _exit_tree() -> void:
	_CLC_HARVEST_API.clear_popups()


func _clc_harvest_show_golden() -> void:
	var legend = _CLC_HARVEST_API.get_runtime(_CLC_HARVEST_ID)
	if legend == null or not is_inside_tree():
		return
	for player_index in RunData.get_player_count():
		var popup = legend.make_golden_popup(player_index)
		if popup != null:
			var _err = popup.connect("closed", self, "_clc_harvest_on_golden", [player_index])
			_CLC_HARVEST_API.show_popup(popup)


func _clc_harvest_on_golden(result: String, player_index: int) -> void:
	var legend = _CLC_HARVEST_API.get_runtime(_CLC_HARVEST_ID)
	if legend == null or not is_inside_tree():
		return
	var _amount: int = legend.grant_golden_reward(player_index, result)
