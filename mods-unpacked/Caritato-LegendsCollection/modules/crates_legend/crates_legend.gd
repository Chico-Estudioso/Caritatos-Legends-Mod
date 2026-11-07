extends Node

# La Leyenda de las Cajas.
#
# Al terminar una oleada, si un jugador ha acumulado cajas normales para abrir,
# puede fusionar varias en una caja legendaria. La primera fusión pide 3 cajas
# y cada fusión hecha sube el precio (6, 9…) hasta un máximo; todo se ajusta.
# La fusión se ofrece en una ventana con las cajas dibujadas que se juntan.
#
# Las cajas por abrir viven en main.gd (_consumables_to_process y el contador
# de la interfaz, _things_to_process_player_containers): se quitan las cajas
# fusionadas y se añade una caja legendaria, que se abre con las demás.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const CratesRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/crates_legend/crates_rules.gd")
const POPUP_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/crates_legend/crates_popup.gd"
const LOG_NAME := "Caritato-LegendsCollection:Crates"
const CRATE_KEY := "consumable_item_box_hash"
const LEGENDARY_KEY := "consumable_legendary_item_box_hash"

var core = null
var module_id := ""
# jugador -> fusiones hechas en la partida actual
var _fusions := {}
var _last_wave := 0


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


func fusions_done(player_index: int) -> int:
	return int(_fusions.get(player_index, 0))


func cost_for(player_index: int, extra_fusions: int = 0) -> int:
	return CratesRules.fusion_cost(
		int(get_setting("first_cost", 3)),
		int(get_setting("cost_step", 3)),
		int(get_setting("max_cost", 9)),
		fusions_done(player_index) + extra_fusions
	)


# Llamado al terminar cada oleada: una partida nueva vuelve a empezar desde la
# primera oleada, y entonces se reinician las fusiones hechas.
func on_wave_end(wave: int) -> void:
	if wave <= 1 or wave < _last_wave:
		_fusions.clear()
	_last_wave = wave


# Ventana para ofrecer la fusión, o null si no hay cajas suficientes.
func make_popup(player_index: int, crates: int) -> Node:
	if not is_active():
		return null
	var cost := cost_for(player_index)
	if not CratesRules.can_fuse(crates, cost):
		return null
	var popup_script = load(POPUP_PATH)
	if popup_script == null:
		return null
	var popup = popup_script.new()
	popup.player_index = player_index if Compat.is_coop_run() else -1
	popup.player_number = player_index + 1
	popup.crates = crates
	popup.cost = cost
	popup.next_cost = cost_for(player_index, 1)
	return popup


func register_fusion(player_index: int, cost: int) -> void:
	_fusions[player_index] = fusions_done(player_index) + 1
	ModLoaderLog.info("Fusión de cajas: %d cajas → 1 legendaria (jugador %d, fusión %d)" % [cost, player_index + 1, fusions_done(player_index)], LOG_NAME)


# Cajas normales por abrir en una lista de ConsumableToProcess.
static func count_crates(to_process: Array, crate_hash: int) -> int:
	var total := 0
	for entry in to_process:
		if entry != null and entry.consumable_data != null and entry.consumable_data.my_id_hash == crate_hash:
			total += 1
	return total


# Quita «cost» cajas normales de la lista (y de su contador en la interfaz) y
# añade una caja legendaria. Devuelve false sin tocar nada si no se puede.
static func fuse_crates(to_process: Array, ui_container, player_index: int, cost: int, crate_hash: int, legendary_data) -> bool:
	if legendary_data == null or cost <= 0:
		return false
	var hashes := []
	for entry in to_process:
		var data = entry.consumable_data if entry != null else null
		hashes.append(data.my_id_hash if data != null else 0)
	var picked := CratesRules.pick_crates(hashes, crate_hash, cost)
	if picked.empty():
		return false
	var template = to_process[picked[0]]
	for index in picked:
		var entry = to_process[index]
		to_process.remove(index)
		if ui_container != null and ui_container.has_method("remove_element"):
			ui_container.remove_element(entry.consumable_data)
	# Misma clase que las demás cajas por abrir (UpgradesUI.ConsumableToProcess),
	# sin nombrarla: así este script no carga clases del juego al arrancar.
	var fused = template.get_script().new()
	fused.consumable_data = legendary_data
	fused.player_index = player_index
	to_process.push_back(fused)
	if ui_container != null and ui_container.has_method("add_element"):
		ui_container.add_element(legendary_data)
	return true
