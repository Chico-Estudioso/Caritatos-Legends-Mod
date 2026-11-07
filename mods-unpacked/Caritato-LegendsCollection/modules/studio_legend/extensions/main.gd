extends "res://main.gd"

# El Taller de los Tatos: al aparecer los personajes, cada jugador que lleve
# puesto un tato lo ve dibujado encima de su patata, como un aspecto más.

const _CLC_STUDIO_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_STUDIO_ID := "studio_legend"
const _CLC_STUDIO_NODE := "CaritatoTato"


func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	var legend = _CLC_STUDIO_API.get_runtime(_CLC_STUDIO_ID)
	if legend == null:
		return
	legend.forget_textures()
	for player_index in players.size():
		var texture = legend.worn_texture(player_index)
		var player = players[player_index]
		if texture == null or not is_instance_valid(player):
			continue
		var body = player.get_node_or_null("Animation/Sprite")
		if body == null or body.get_node_or_null(_CLC_STUDIO_NODE) != null:
			continue
		var sprite := Sprite.new()
		sprite.name = _CLC_STUDIO_NODE
		sprite.texture = texture
		body.add_child(sprite)
		_CLC_STUDIO_API.trace("Tus tatos: J%d lleva su tato" % (player_index + 1))
