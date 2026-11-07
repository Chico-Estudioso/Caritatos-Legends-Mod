extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda del Regalo.

var GiftRules = load(MOD_PATH + "modules/gift_legend/gift_rules.gd")


func _init() -> void:
	run_case("objetos que nunca se regalan", "test_never_giftable")
	run_case("regalo de objetos", "test_items")
	run_case("regalo de armas", "test_weapons")
	run_case("límite de regalos por tienda", "test_limit")
	finish()


func base_facts() -> Dictionary:
	return {"legend_active": true, "giver": 0, "recipient": 1, "gifts_done": 0, "gift_limit": 0}


func item_facts(overrides: Dictionary = {}) -> Dictionary:
	var facts := base_facts()
	facts["id"] = "item_coupon"
	facts["recipient_capacity"] = 5
	for key in overrides:
		facts[key] = overrides[key]
	return facts


func weapon_facts(overrides: Dictionary = {}) -> Dictionary:
	var facts := base_facts()
	facts["giver_weapon_count"] = 3
	facts["recipient_free_slots"] = 2
	for key in overrides:
		facts[key] = overrides[key]
	return facts


func test_never_giftable() -> void:
	check(GiftRules.is_never_giftable("item_tumor", false), "el Tumor nunca se regala")
	check(GiftRules.is_never_giftable("character_brawler", false), "el personaje no se regala")
	check(GiftRules.is_never_giftable("item_builder_turret_2", false), "la torreta del Constructor no se regala")
	check(GiftRules.is_never_giftable("item_meca_evolved_leap", false), "los saltos evolutivos no se regalan")
	check(GiftRules.is_never_giftable("item_hourglass", true), "un objeto con sustituto no se regala")
	check(not GiftRules.is_never_giftable("item_coupon", false), "un objeto normal sí")


func test_items() -> void:
	check(GiftRules.item_block_reason(item_facts()) == "", "un objeto normal se puede regalar")
	check(GiftRules.item_block_reason(item_facts({"legend_active": false})) == GiftRules.REASON_INACTIVE, "leyenda inactiva")
	check(GiftRules.item_block_reason(item_facts({"recipient": 0})) == GiftRules.REASON_SAME_PLAYER, "a uno mismo no")
	check(GiftRules.item_block_reason(item_facts({"allow_items": false})) == GiftRules.REASON_ITEMS_OFF, "objetos desactivados")
	check(GiftRules.item_block_reason(item_facts({"id": "item_tumor"})) == GiftRules.REASON_NOT_GIFTABLE, "el Tumor no")
	check(GiftRules.item_block_reason(item_facts({"is_cursed": true, "allow_cursed": false})) == GiftRules.REASON_CURSED_OFF, "malditos desactivados")
	check(GiftRules.item_block_reason(item_facts({"is_cursed": true})) == "", "malditos permitidos por defecto")
	check(GiftRules.item_block_reason(item_facts({"recipient_restricted": true})) == GiftRules.REASON_RECIPIENT_BANNED, "prohibido para quien lo recibe")
	check(GiftRules.item_block_reason(item_facts({"is_mutant": true, "recipient_meca_only": true})) == GiftRules.REASON_EVOLUTION_CAMP, "mutado a un personaje solo meca")
	check(GiftRules.item_block_reason(item_facts({"is_mutant": true})) == "", "mutado a cualquier otro")
	check(GiftRules.item_block_reason(item_facts({"recipient_capacity": 0})) == GiftRules.REASON_RECIPIENT_FULL, "máximo alcanzado")


func test_weapons() -> void:
	check(GiftRules.weapon_block_reason(weapon_facts()) == "", "un arma normal se puede regalar")
	check(GiftRules.weapon_block_reason(weapon_facts({"is_meca": true})) == "", "un arma meca también")
	check(GiftRules.weapon_block_reason(weapon_facts({"allow_weapons": false})) == GiftRules.REASON_WEAPONS_OFF, "armas desactivadas")
	check(GiftRules.weapon_block_reason(weapon_facts({"recipient_free_slots": 0})) == GiftRules.REASON_NO_SLOT, "sin hueco")
	check(GiftRules.weapon_block_reason(weapon_facts({"giver_weapon_count": 1})) == GiftRules.REASON_LAST_WEAPON, "última arma")
	check(GiftRules.weapon_block_reason(weapon_facts({"giver_weapon_count": 1, "keep_last_weapon": false})) == "", "última arma si se permite")
	check(GiftRules.weapon_block_reason(weapon_facts({"recipient_locked": true})) == GiftRules.REASON_WEAPONS_LOCKED, "armas bloqueadas")
	check(GiftRules.weapon_block_reason(weapon_facts({"recipient_allowed": false})) == GiftRules.REASON_RECIPIENT_BANNED, "tipo de arma no permitido")
	check(GiftRules.weapon_block_reason(weapon_facts({"is_meca": true, "recipient_mutant_only": true})) == GiftRules.REASON_EVOLUTION_CAMP, "meca a un personaje solo mutante")


func test_limit() -> void:
	check(not GiftRules.gift_limit_reached(5, 0), "0 = sin límite")
	check(GiftRules.gift_limit_reached(2, 2), "límite alcanzado")
	check(GiftRules.item_block_reason(item_facts({"gifts_done": 1, "gift_limit": 1})) == GiftRules.REASON_LIMIT, "límite en objetos")
	check(GiftRules.weapon_block_reason(weapon_facts({"gifts_done": 3, "gift_limit": 3})) == GiftRules.REASON_LIMIT, "límite en armas")
