extends "res://singletons/focus_emulator_signal.gd"

# La Leyenda del Ratón: en cooperativo, lo que se pulsa o resalta con el
# ratón no pasa por los FocusEmulator, así que el juego no sabe de qué jugador
# es (get_player_index devuelve -1 y la tienda supone el J1 o se queja en el
# log). Si el ratón acaba de actuar en el panel de quien lo usa, se le
# atribuye a ese jugador.

const _CLC_MOUSE_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_MOUSE_ID := "mouse_legend"


func get_player_index(expected_control: Control) -> int:
	var player_index: int = .get_player_index(expected_control)
	if player_index >= 0:
		return player_index
	var legend = _CLC_MOUSE_API.get_runtime(_CLC_MOUSE_ID)
	if legend == null:
		return player_index
	return legend.claim_player(expected_control, player_index)
