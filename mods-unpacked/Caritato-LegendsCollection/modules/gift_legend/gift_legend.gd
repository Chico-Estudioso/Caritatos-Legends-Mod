extends Node

# La Leyenda del Regalo (cooperativo).
#
# En la tienda cooperativa, cada jugador tiene un botón «Regalar» que abre una
# ventana con sus objetos y armas; puede dárselos a otro jugador. Las armas se
# regalan con sus mejoras, maldición o mecanización. Se respetan las reglas
# del juego del que recibe (prohibiciones, máximos, huecos de armas, tipo de
# arma, bando de evolución) y nunca se regalan el personaje, el Tumor, los
# saltos evolutivos, la torreta del Constructor ni los objetos que se
# transforman al quitarlos.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const GiftRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/gift_legend/gift_rules.gd")
const MENU_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/gift_legend/gift_menu.gd"
const LOG_NAME := "Caritato-LegendsCollection:Gift"

var core = null
var module_id := ""
# jugador -> regalos hechos en la tienda actual
var _gifts := {}


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


func on_shop_opened() -> void:
	_gifts.clear()


func gifts_left(player_index: int) -> int:
	var limit := int(get_setting("gifts_per_shop", 0))
	if limit <= 0:
		return -1
	return int(max(0, limit - int(_gifts.get(player_index, 0))))


# Lista para la ventana: Array de {data, is_weapon, label, tier, tags, recipients}
# donde recipients es Array de {index, reason}. No incluye lo que nunca se regala.
func get_offers(giver: int) -> Array:
	var offers := []
	var player_count := Compat.get_player_count()
	for weapon in Compat.get_player_weapons(giver):
		offers.append(_make_offer(giver, weapon, true, player_count))
	for item in Compat.get_player_items(giver):
		if GiftRules.is_never_giftable(item.my_id, _has_replacement(item)):
			continue
		offers.append(_make_offer(giver, item, false, player_count))
	return offers


func block_reason(giver: int, recipient: int, data, is_weapon: bool) -> String:
	var facts := {
		"legend_active": is_active() and Compat.is_coop_run(),
		"giver": giver,
		"recipient": recipient,
		"gifts_done": int(_gifts.get(giver, 0)),
		"gift_limit": int(get_setting("gifts_per_shop", 0)),
		"is_cursed": Compat.item_flag(data, "is_cursed"),
		"allow_cursed": bool(get_setting("allow_cursed", true)),
		"is_mutant": Compat.item_flag(data, "is_mutant"),
		"recipient_meca_only": Compat.player_effect_bool("meca_only", recipient),
	}
	if is_weapon:
		facts["allow_weapons"] = bool(get_setting("allow_weapons", true))
		facts["is_meca"] = Compat.item_flag(data, "is_meca")
		facts["giver_locked"] = Compat.player_effect_bool("lock_current_weapons", giver)
		facts["recipient_locked"] = Compat.player_effect_bool("lock_current_weapons", recipient)
		facts["keep_last_weapon"] = bool(get_setting("keep_last_weapon", true))
		facts["giver_weapon_count"] = Compat.get_player_weapons(giver).size()
		facts["recipient_allowed"] = Compat.is_weapon_allowed_for_player(data, recipient, false)
		facts["recipient_mutant_only"] = Compat.player_effect_bool("mutant_only", recipient)
		facts["recipient_free_slots"] = Compat.player_free_weapon_slots(recipient)
		return GiftRules.weapon_block_reason(facts)

	facts["allow_items"] = bool(get_setting("allow_items", true))
	facts["id"] = data.my_id
	facts["has_replacement"] = _has_replacement(data)
	facts["recipient_restricted"] = Compat.is_banned_by_character(recipient, data.my_id)
	facts["recipient_capacity"] = Compat.remaining_item_capacity(data, recipient)
	return GiftRules.item_block_reason(facts)


# Hace el regalo y refresca la tienda. Devuelve "" o la clave del motivo.
func gift(shop: Node, giver: int, recipient: int, data, is_weapon: bool) -> String:
	var reason := block_reason(giver, recipient, data, is_weapon)
	if reason != "":
		return reason
	var done: bool = Compat.transfer_weapon(data, giver, recipient) if is_weapon else Compat.transfer_item(data, giver, recipient)
	if not done:
		return "CLC_GIFT_REASON_NOT_OWNED"
	_gifts[giver] = int(_gifts.get(giver, 0)) + 1
	if shop != null and is_instance_valid(shop) and shop.has_method("_clc_gift_refresh"):
		shop._clc_gift_refresh([giver, recipient])
	ModLoaderLog.info("Regalo: %s de J%d a J%d" % [data.my_id, giver + 1, recipient + 1], LOG_NAME)
	return ""


func open_menu(shop: Node, giver: int, return_focus: Control) -> void:
	var menu_script = load(MENU_PATH)
	if menu_script == null:
		ModLoaderLog.error("No se pudo cargar la ventana de regalos.", LOG_NAME)
		return
	var menu = menu_script.new()
	get_tree().root.add_child(menu)
	menu.open(self, shop, giver, return_focus)


func _make_offer(giver: int, data, is_weapon: bool, player_count: int) -> Dictionary:
	var tags := []
	if Compat.item_flag(data, "is_cursed"):
		tags.append("CLC_GIFT_TAG_CURSED")
	if Compat.item_flag(data, "is_meca"):
		tags.append("CLC_GIFT_TAG_MECA")
	if Compat.item_flag(data, "is_mutant"):
		tags.append("CLC_GIFT_TAG_MUTANT")
	var recipients := []
	for index in player_count:
		if index != giver:
			recipients.append({"index": index, "reason": block_reason(giver, index, data, is_weapon)})
	return {
		"data": data,
		"is_weapon": is_weapon,
		"label": tr(data.name),
		"tier": int(data.tier),
		"tags": tags,
		"recipients": recipients,
	}


static func _has_replacement(item) -> bool:
	return "replaced_by" in item and item.replaced_by != null
