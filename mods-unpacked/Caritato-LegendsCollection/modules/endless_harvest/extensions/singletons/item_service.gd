extends "res://singletons/item_service.gd"

# La Leyenda de la Cosecha Eterna: texto de la estadística de Recolección.

const _CLC_HARVEST_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")

const _CLC_HARVEST_ID := "endless_harvest"


func get_stat_description_text(stat_hash: int, value: int, player_index: int) -> String:
	var text: String = .get_stat_description_text(stat_hash, value, player_index)
	if value < 0 or stat_hash != Keys.stat_harvesting_hash:
		return text
	var legend = _CLC_HARVEST_API.get_runtime(_CLC_HARVEST_ID)
	if legend == null:
		return text
	var custom: String = legend.describe_harvesting(value, player_index)
	return custom if custom != "" else text
