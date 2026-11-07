extends Reference

# Reglas de La Leyenda del Regalo sin dependencias del juego, para poder
# probarlas con Godot en modo headless (tests/gdscript/test_gift_rules.gd).
#
# Cada función recibe un diccionario con los datos ya consultados al juego y
# devuelve "" si el regalo se permite o la clave del texto que explica por qué no.

const REASON_INACTIVE := "CLC_GIFT_REASON_INACTIVE"
const REASON_SAME_PLAYER := "CLC_GIFT_REASON_SAME_PLAYER"
const REASON_ITEMS_OFF := "CLC_GIFT_REASON_ITEMS_OFF"
const REASON_WEAPONS_OFF := "CLC_GIFT_REASON_WEAPONS_OFF"
const REASON_NOT_GIFTABLE := "CLC_GIFT_REASON_NOT_GIFTABLE"
const REASON_CURSED_OFF := "CLC_GIFT_REASON_CURSED_OFF"
const REASON_LIMIT := "CLC_GIFT_REASON_LIMIT"
const REASON_RECIPIENT_BANNED := "CLC_GIFT_REASON_RECIPIENT_BANNED"
const REASON_EVOLUTION_CAMP := "CLC_GIFT_REASON_EVOLUTION_CAMP"
const REASON_RECIPIENT_FULL := "CLC_GIFT_REASON_RECIPIENT_FULL"
const REASON_NO_SLOT := "CLC_GIFT_REASON_NO_SLOT"
const REASON_LAST_WEAPON := "CLC_GIFT_REASON_LAST_WEAPON"
const REASON_WEAPONS_LOCKED := "CLC_GIFT_REASON_WEAPONS_LOCKED"

# Objetos que nunca se regalan:
# - item_tumor: solo existe por las mutaciones (Primal Dread) y acumula sus efectos.
# - saltos evolutivos: multiplican la evolución de quien los equipa.
const NEVER_GIFT_IDS := ["item_tumor", "item_meca_evolved_leap", "item_mut_evolved_leap"]
# - character_*: el propio personaje figura como objeto en el inventario.
# - item_builder_turret*: torreta del Constructor, ligada a su nivel.
const NEVER_GIFT_PREFIXES := ["character_", "item_builder_turret"]


# has_replacement: el objeto se transforma en otro al quitarlo (reloj de arena,
# huevos de dinosaurio, escáner…); quitarlo dejaría el sustituto a quien lo regala.
static func is_never_giftable(item_id: String, has_replacement: bool) -> bool:
	if has_replacement or NEVER_GIFT_IDS.has(item_id):
		return true
	for prefix in NEVER_GIFT_PREFIXES:
		if item_id.begins_with(prefix):
			return true
	return false


static func gift_limit_reached(gifts_done: int, gift_limit: int) -> bool:
	return gift_limit > 0 and gifts_done >= gift_limit


static func item_block_reason(f: Dictionary) -> String:
	var common := _common_block_reason(f)
	if common != "":
		return common
	if not f.get("allow_items", true):
		return REASON_ITEMS_OFF
	if is_never_giftable(f.get("id", ""), f.get("has_replacement", false)):
		return REASON_NOT_GIFTABLE
	if f.get("is_cursed", false) and not f.get("allow_cursed", true):
		return REASON_CURSED_OFF
	if f.get("recipient_restricted", false):
		return REASON_RECIPIENT_BANNED
	if f.get("is_mutant", false) and f.get("recipient_meca_only", false):
		return REASON_EVOLUTION_CAMP
	if int(f.get("recipient_capacity", 1)) <= 0:
		return REASON_RECIPIENT_FULL
	return ""


static func weapon_block_reason(f: Dictionary) -> String:
	var common := _common_block_reason(f)
	if common != "":
		return common
	if not f.get("allow_weapons", true):
		return REASON_WEAPONS_OFF
	if f.get("is_cursed", false) and not f.get("allow_cursed", true):
		return REASON_CURSED_OFF
	if f.get("giver_locked", false) or f.get("recipient_locked", false):
		return REASON_WEAPONS_LOCKED
	if f.get("keep_last_weapon", true) and int(f.get("giver_weapon_count", 0)) <= 1:
		return REASON_LAST_WEAPON
	if not f.get("recipient_allowed", true):
		return REASON_RECIPIENT_BANNED
	if f.get("is_meca", false) and f.get("recipient_mutant_only", false):
		return REASON_EVOLUTION_CAMP
	if f.get("is_mutant", false) and f.get("recipient_meca_only", false):
		return REASON_EVOLUTION_CAMP
	if int(f.get("recipient_free_slots", 0)) <= 0:
		return REASON_NO_SLOT
	return ""


static func _common_block_reason(f: Dictionary) -> String:
	if not f.get("legend_active", false):
		return REASON_INACTIVE
	if int(f.get("giver", -1)) == int(f.get("recipient", -1)):
		return REASON_SAME_PLAYER
	if gift_limit_reached(int(f.get("gifts_done", 0)), int(f.get("gift_limit", 0))):
		return REASON_LIMIT
	return ""
