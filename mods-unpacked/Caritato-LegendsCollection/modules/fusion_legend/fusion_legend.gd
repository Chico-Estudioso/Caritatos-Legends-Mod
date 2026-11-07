extends Node

# La Leyenda de la Fusión (recreación independiente de Genetically Modified
# Overkill, de Flabort).
#
# Al empezar una partida, cada jugador puede fusionarse con otro personaje:
# suma todos sus efectos a los del suyo. Para compensar, la fusión trae
# penalizaciones configurables (menos experiencia, objetos más caros, más
# enemigos y más rápidos). Se elige en «¡Fusión de bros!», con los personajes
# en una cuadrícula y un choque de puños al confirmar.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const FusionRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/fusion_legend/fusion_rules.gd")
const POPUP_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/fusion_legend/fusion_popup.gd"
const LOG_NAME := "Caritato-LegendsCollection:Fusion"

var core = null
var module_id := ""
# jugador -> id del personaje con el que se ha fusionado en esta partida
var fused := {}


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


func penalties() -> Array:
	var settings := {}
	for penalty in FusionRules.PENALTIES:
		settings[penalty[1]] = int(get_setting(penalty[1], 0))
	return FusionRules.penalty_values(settings)


# Al empezar la primera oleada de una partida nueva.
func should_offer(wave: int) -> bool:
	if wave != 1:
		return false
	fused.clear()
	return is_active()


# Compañeros para un jugador: [{id, name, icon, text, data}].
func partners_for(player_index: int) -> Array:
	var characters := Compat.get_characters()
	var current = Compat.get_player_character(player_index)
	var current_id: String = current.my_id if current != null and "my_id" in current else ""
	var entries := []
	for character in characters:
		entries.append({"id": str(character.my_id), "unlocked": Compat.is_character_unlocked(character)})
	var result := []
	for index in FusionRules.partner_indices(entries, current_id, bool(get_setting("allow_locked", false))):
		var character = characters[index]
		result.append({
			"id": str(character.my_id),
			"name": tr(str(character.name)),
			"icon": Compat.item_icon(character),
			"text": Compat.item_effects_text(character, player_index),
			"data": character,
		})
	return result


func make_popup(player_index: int) -> Node:
	if not is_active():
		return null
	var partners := partners_for(player_index)
	if partners.empty():
		return null
	var popup_script = load(POPUP_PATH)
	if popup_script == null:
		return null
	var popup = popup_script.new()
	popup.player_index = player_index if Compat.is_coop_run() else -1
	popup.player_number = player_index + 1
	var current = Compat.get_player_character(player_index)
	popup.own_icon = Compat.item_icon(current)
	popup.partners = partners
	popup.penalties = penalties()
	return popup


# Suma los efectos del compañero y aplica las penalizaciones.
func apply_fusion(player_index: int, partner: Dictionary) -> bool:
	var data = partner.get("data")
	if data == null or not Compat.apply_item_effects(data, player_index):
		return false
	for penalty in penalties():
		var _applied = Compat.add_player_effect(penalty[0], penalty[1], player_index)
	fused[player_index] = str(partner.get("id", ""))
	ModLoaderLog.info("Fusión: J%d se fusiona con %s" % [player_index + 1, fused[player_index]], LOG_NAME)
	return true
