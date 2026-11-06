extends "res://main.gd"

# La Leyenda de la Cosecha Eterna: ganchos en la escena de oleada.

const _CLC_HARVEST_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_HARVEST_COMPAT = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")

const _CLC_HARVEST_ID := "endless_harvest"


func _on_HarvestingTimer_timeout() -> void:
	var legend = _CLC_HARVEST_API.get_runtime(_CLC_HARVEST_ID)
	var mode: String = legend.get_mode() if legend != null else "vanilla"

	if mode == "grow":
		# Se reutiliza el crecimiento del juego tratando la oleada actual como
		# la última normal, y se restaura el número de oleadas al terminar.
		var normal_waves := _CLC_HARVEST_COMPAT.normal_wave_count()
		_CLC_HARVEST_COMPAT.set_normal_wave_count(int(max(normal_waves, _CLC_HARVEST_COMPAT.current_wave())))
		._on_HarvestingTimer_timeout()
		_CLC_HARVEST_COMPAT.set_normal_wave_count(normal_waves)
		return

	if mode == "decay":
		legend.apply_endless_decay()
		return

	._on_HarvestingTimer_timeout()


func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	var legend = _CLC_HARVEST_API.get_runtime(_CLC_HARVEST_ID)
	if legend != null:
		legend.on_wave_started(players.size())
