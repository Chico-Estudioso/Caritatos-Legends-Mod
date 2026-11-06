extends "res://singletons/item_service.gd"

# La Leyenda del Mercader: precios de artículos y de rerolls.

const _CLC_MERCHANT_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")

const _CLC_MERCHANT_ID := "merchant_legend"


func get_value(wave: int, base_value: int, player_index: int, affected_by_items_price_stat: bool, is_weapon: bool, item_id: int = Keys.empty_hash) -> int:
	var legend = _CLC_MERCHANT_API.get_runtime(_CLC_MERCHANT_ID)
	if legend == null:
		return .get_value(wave, base_value, player_index, affected_by_items_price_stat, is_weapon, item_id)
	var value: int = .get_value(legend.item_price_wave(wave), base_value, player_index, affected_by_items_price_stat, is_weapon, item_id)
	return legend.scale_item_price(value)


func get_reroll_price(wave: int, reroll_count: int, player_index: int) -> Array:
	var legend = _CLC_MERCHANT_API.get_runtime(_CLC_MERCHANT_ID)
	if legend == null:
		return .get_reroll_price(wave, reroll_count, player_index)
	var result: Array = .get_reroll_price(legend.reroll_price_wave(wave), reroll_count, player_index)
	return legend.scale_reroll_result(result)
