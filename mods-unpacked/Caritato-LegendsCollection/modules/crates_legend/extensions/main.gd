extends "res://main.gd"

# La Leyenda de las Cajas: antes de abrir las cajas al terminar la oleada,
# ofrece a cada jugador con cajas suficientes fusionarlas en una legendaria.
# Mientras la ventana está abierta el juego se pausa (para que el personaje no
# se mueva con el mando) y después sigue como siempre.

const _CLC_CRATES_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_CRATES_COMPAT = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const _CLC_CRATES_ID := "crates_legend"
const _CLC_CRATES_CRATE_KEY := "consumable_item_box_hash"
const _CLC_CRATES_LEGENDARY_KEY := "consumable_legendary_item_box_hash"


func _on_EndWaveTimer_timeout() -> void:
	var legend = _CLC_CRATES_API.get_runtime(_CLC_CRATES_ID)
	if legend == null or _CLC_CRATES_API.get_core() == null or _clc_crates_run_over():
		._on_EndWaveTimer_timeout()
		return
	legend.on_wave_end(RunData.current_wave)
	var crate_hash: int = _CLC_CRATES_COMPAT.key_hash(_CLC_CRATES_CRATE_KEY)
	var legendary = _CLC_CRATES_COMPAT.get_consumable_data(_CLC_CRATES_LEGENDARY_KEY)
	if crate_hash == 0 or legendary == null:
		._on_EndWaveTimer_timeout()
		return
	var offers := []
	for player_index in RunData.get_player_count():
		var crates: int = legend.count_crates(_clc_crates_list(player_index), crate_hash)
		var popup = legend.make_popup(player_index, crates)
		if popup != null:
			offers.append([player_index, popup])
	if offers.empty():
		._on_EndWaveTimer_timeout()
		return

	_CLC_CRATES_API.trace("Fin de oleada: fusión de cajas ofrecida")
	var tree := get_tree()
	var was_paused := tree.paused
	tree.paused = true
	for offer in offers:
		var player_index: int = offer[0]
		var popup = offer[1]
		var cost: int = popup.cost
		_CLC_CRATES_API.show_popup(popup)
		var result = yield(popup, "closed")
		if result == "fused" and legend.fuse_crates(_clc_crates_list(player_index), _clc_crates_ui(player_index), player_index, cost, crate_hash, legendary):
			legend.register_fusion(player_index, cost)
	if is_inside_tree():
		tree.paused = was_paused
	._on_EndWaveTimer_timeout()


func _clc_crates_run_over() -> bool:
	if get("_is_run_lost") == true or get("_is_run_won") == true:
		return true
	return get("_is_wave_failed") == true and RunData.current_wave > 0


func _clc_crates_list(player_index: int) -> Array:
	var lists = get("_consumables_to_process")
	if lists is Array and player_index < lists.size() and lists[player_index] is Array:
		return lists[player_index]
	return []


func _clc_crates_ui(player_index: int):
	var containers = get("_things_to_process_player_containers")
	if containers is Array and player_index < containers.size() and containers[player_index] != null:
		return containers[player_index].get("consumables")
	return null
