extends "res://main.gd"

# La Leyenda de la Fusión: al aparecer los personajes en la primera oleada de
# una partida, cada jugador elige si se fusiona con otro personaje. El juego
# se pausa mientras se elige; después se aplican los efectos del compañero y
# las penalizaciones, y se actualizan las estadísticas de los personajes.

const _CLC_FUSION_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_FUSION_ID := "fusion_legend"


func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	var legend = _CLC_FUSION_API.get_runtime(_CLC_FUSION_ID)
	if legend == null or _CLC_FUSION_API.get_core() == null:
		return
	if legend.should_offer(RunData.current_wave):
		call_deferred("_clc_fusion_offer")


func _clc_fusion_offer() -> void:
	var legend = _CLC_FUSION_API.get_runtime(_CLC_FUSION_ID)
	if legend == null or not is_inside_tree():
		return
	var offers := []
	for player_index in RunData.get_player_count():
		var popup = legend.make_popup(player_index)
		if popup != null:
			offers.append([player_index, popup])
	if offers.empty():
		return
	_CLC_FUSION_API.trace("Inicio de partida: fusión ofrecida")
	var tree := get_tree()
	var was_paused := tree.paused
	tree.paused = true
	for offer in offers:
		var player_index: int = offer[0]
		var popup = offer[1]
		var partners: Array = popup.partners
		_CLC_FUSION_API.show_popup(popup)
		var result: String = str(yield(popup, "closed"))
		if not result.begins_with("partner:"):
			continue
		var index := int(result.trim_prefix("partner:"))
		if index >= 0 and index < partners.size() and legend.apply_fusion(player_index, partners[index]):
			_clc_fusion_refresh(player_index)
	if is_inside_tree():
		tree.paused = was_paused


# Vida, velocidad y comportamientos especiales con los efectos nuevos.
func _clc_fusion_refresh(player_index: int) -> void:
	var players = get("_players")
	if players is Array and player_index < players.size() and is_instance_valid(players[player_index]):
		var player = players[player_index]
		if player.has_method("update_player_stats"):
			player.update_player_stats(true)
	var behaviors = get_node_or_null("/root/EffectBehaviorService")
	if behaviors != null and behaviors.has_method("update_active_effect_behaviors"):
		behaviors.update_active_effect_behaviors()
