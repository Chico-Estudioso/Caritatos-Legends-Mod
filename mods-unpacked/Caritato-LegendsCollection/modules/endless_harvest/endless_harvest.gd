extends Node

# La Leyenda de la Cosecha Eterna.
#
# En el modo infinito, al final de cada oleada posterior a la 20 el juego
# quita un 20 % de la recolección (RunData.ENDLESS_HARVESTING_DECREASE) en
# lugar de hacerla crecer, y la Hucha deja de dar interés. Esta leyenda permite:
#   - elegir el porcentaje que se pierde (0 % = se mantiene),
#   - seguir creciendo como en las oleadas normales (Granjero y Corona incluidos),
#   - que la Hucha siga funcionando.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const HarvestRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/endless_harvest/harvest_rules.gd")

const HARVESTING_STAT := "stat_harvesting"
const HARVESTING_GROWTH_EFFECT := "harvesting_growth"
const PIGGY_BANK_EFFECT := "gain_pct_gold_start_wave"
const PIGGY_BANK_ID := "item_piggy_bank"
const CROWN_ID := "item_crown"
const LOG_NAME := "Caritato-LegendsCollection:EndlessHarvest"

var core = null
var module_id := ""
var _original_endless_bans = null


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func _ready() -> void:
	call_deferred("apply_endless_shop_rules")


func on_config_changed() -> void:
	apply_endless_shop_rules()


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


func grows_in_endless() -> bool:
	return bool(get_setting("grow_in_endless", false))


func decay_percent() -> int:
	return int(get_setting("decay_percent", 0))


# --- Recolección ----------------------------------------------------------------

func get_mode() -> String:
	return HarvestRules.endless_mode(
		is_active(),
		Compat.is_after_last_normal_wave(),
		grows_in_endless(),
		decay_percent(),
		Compat.vanilla_endless_harvesting_decrease()
	)


# Sustituye la pérdida del juego por la configurada (modo «decay»).
func apply_endless_decay() -> void:
	var percent := decay_percent()
	for player_index in Compat.get_player_count():
		var stat: float = Compat.get_player_stat(HARVESTING_STAT, player_index)
		var amount := HarvestRules.decay_amount(stat, percent)
		if amount > 0:
			Compat.remove_player_stat(HARVESTING_STAT, amount, player_index)


# Texto de la estadística de Recolección acorde con la configuración.
# Devuelve "" para dejar el texto del juego.
func describe_harvesting(value: int, player_index: int) -> String:
	if not is_active():
		return ""
	var growth := str(Compat.get_player_effect(HARVESTING_GROWTH_EFFECT, player_index))
	if grows_in_endless():
		return Compat.format_text("CLC_HARVEST_INFO_GROW", [str(abs(value)), growth])
	var percent := decay_percent()
	if percent <= 0:
		return Compat.format_text("CLC_HARVEST_INFO_KEEP", [str(abs(value)), growth, str(Compat.normal_wave_count())])
	return Compat.format_text(
		"INFO_POS_STAT_HARVESTING_LIMITED",
		[str(abs(value)), growth, str(Compat.normal_wave_count()), str(percent)]
	)


# --- Hucha -------------------------------------------------------------------------

# Llamado al empezar cada oleada: el juego solo da el interés positivo de la
# Hucha hasta la oleada 20, así que a partir de ahí lo da la leyenda.
func on_wave_started(player_count: int) -> void:
	if not is_active() or not bool(get_setting("piggy_bank_in_endless", false)):
		return
	if not Compat.is_after_last_normal_wave():
		return
	for player_index in player_count:
		var percent := float(Compat.get_player_effect(PIGGY_BANK_EFFECT, player_index))
		var amount := HarvestRules.piggy_bank_amount(Compat.get_player_gold(player_index), percent)
		if amount > 0:
			Compat.add_gold(amount, player_index)
			Compat.add_tracked_value(player_index, PIGGY_BANK_ID, amount)


# --- Tienda del modo infinito ----------------------------------------------------

# El juego veta la Hucha y la Corona en el modo infinito. Si la leyenda hace
# que vuelvan a servir, se permiten de nuevo; si no, se restaura la lista.
func apply_endless_shop_rules() -> void:
	var bans = Compat.get_endless_banned_items()
	if bans == null:
		return
	if _original_endless_bans == null:
		_original_endless_bans = bans.duplicate()

	var allowed_ids := []
	if is_active() and bool(get_setting("piggy_bank_in_endless", false)):
		allowed_ids.append(PIGGY_BANK_ID)
	if is_active() and grows_in_endless():
		allowed_ids.append(CROWN_ID)

	var allowed_hashes := []
	for item_id in allowed_ids:
		allowed_hashes.append(Compat.generate_hash(item_id))

	Compat.set_endless_banned_items(HarvestRules.filter_bans(_original_endless_bans, allowed_ids, allowed_hashes))
