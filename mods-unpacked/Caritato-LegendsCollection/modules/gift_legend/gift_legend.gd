extends Node

# La Leyenda del Regalo (cooperativo).
#
# En la tienda cooperativa, al pulsar un arma u objeto propio aparece el menú
# del juego (Combinar, Reciclar, Cancelar) con un botón más: «Regalar». Si
# hay varios jugadores se elige a quién; quien recibe lo acepta o lo rechaza
# en «¡Regalo de tu bro!». Las armas se regalan con sus mejoras,
# maldición o mecanización. Se respetan las reglas del juego del que recibe
# (prohibiciones, máximos, huecos de armas, tipo de arma, bando de evolución)
# y nunca se regalan el personaje, el Tumor, los saltos evolutivos, la torreta
# del Constructor ni los objetos que se transforman al quitarlos.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const GiftRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/gift_legend/gift_rules.gd")
const PICKER_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/gift_legend/gift_recipient_popup.gd"
const CONFIRM_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/gift_legend/gift_confirm.gd"
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


# ¿Se muestra «Regalar» en el menú de este arma u objeto? (El motivo por el
# que no se pueda regalar a alguien se explica al elegir destinatario.)
func can_offer(item) -> bool:
	if item == null or not is_active() or not Compat.is_coop_run() or Compat.get_player_count() < 2:
		return false
	if Compat.is_weapon(item):
		return true
	return not GiftRules.is_never_giftable(item.my_id, _has_replacement(item))


# {data, is_weapon, label, tier, tags, recipients: [{index, reason}]}
func make_offer(giver: int, data, is_weapon: bool) -> Dictionary:
	return _make_offer(giver, data, is_weapon, Compat.get_player_count())


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


# Empieza un regalo desde el menú del arma u objeto: con un solo jugador al
# que se puede regalar, va directo a su confirmación; si no, se elige a quién.
func start_gift(shop: Node, giver: int, data, is_weapon: bool) -> void:
	var offer := make_offer(giver, data, is_weapon)
	var allowed := []
	for recipient in offer.recipients:
		if recipient.reason == "":
			allowed.append(recipient.index)
	if offer.recipients.size() == 1 and allowed.size() == 1:
		_show_confirm(shop, giver, allowed[0], offer)
		return
	var picker_script = load(PICKER_PATH)
	if picker_script == null or core == null:
		return
	var picker = picker_script.new()
	picker.player_index = giver
	picker.offer = offer
	var _err = picker.connect("closed", self, "_on_recipient_chosen", [shop, giver, offer])
	core.show_popup(picker)


func _on_recipient_chosen(result: String, shop: Node, giver: int, offer: Dictionary) -> void:
	if result.begins_with("to:"):
		_show_confirm(shop, giver, int(result.substr(3)), offer)


func _show_confirm(shop: Node, giver: int, recipient: int, offer: Dictionary) -> void:
	var confirm_script = load(CONFIRM_PATH)
	if confirm_script == null or core == null:
		return
	var confirm = confirm_script.new()
	confirm.setup(self, shop, giver, recipient, offer)
	core.show_popup(confirm)


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
