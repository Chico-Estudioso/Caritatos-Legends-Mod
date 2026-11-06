extends Node

# La Leyenda del Anzuelo (Abyssal Terrors).
#
# 1. Anzuelo garantizado: al entrar en la tienda que aparece al terminar la
#    oleada elegida (por defecto la 4), un objeto no bloqueado se sustituye por
#    el Anzuelo. Opcionalmente se repite en cada tienda posterior hasta tener uno.
# 2. Probabilidad configurable: cambia el valor del efecto «curse_locked_items»
#    que da cada Anzuelo. El juego usa ese valor para la probabilidad de
#    maldecir objetos bloqueados al salir de la tienda, para su sistema de
#    compensación («pity») y para el texto del objeto, así que todo queda
#    coherente sin reemplazar ninguna función del juego.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const HookRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/hook_legend/hook_rules.gd")

const HOOK_ITEM_ID := "item_fish_hook"
const CURSE_EFFECT_KEY := "curse_locked_items"
const ORIGINAL_VALUE_META := "clc_hook_original_value"
const LOG_NAME := "Caritato-LegendsCollection:HookLegend"

var core = null
var module_id := ""


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func _ready() -> void:
	# Los objetos del DLC pueden no estar cargados todavía; se vuelve a aplicar
	# al entrar en cada tienda y cada vez que cambia la configuración.
	call_deferred("apply_curse_chance")


func on_config_changed() -> void:
	apply_curse_chance()


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


# --- Probabilidad por anzuelo -----------------------------------------------

# Pone la probabilidad configurada en el efecto del Anzuelo, o restaura la del
# juego si la leyenda o el ajuste están apagados.
func apply_curse_chance() -> void:
	var hook = Compat.get_item_data(HOOK_ITEM_ID)
	if hook == null:
		return

	for effect in hook.effects:
		if effect.key != CURSE_EFFECT_KEY:
			continue
		if not effect.has_meta(ORIGINAL_VALUE_META):
			effect.set_meta(ORIGINAL_VALUE_META, effect.value)
		var original: int = int(effect.get_meta(ORIGINAL_VALUE_META))
		var target := original
		if is_active() and bool(get_setting("custom_chance_enabled", false)):
			target = int(get_setting("chance_per_hook", original))
		if effect.value != target:
			effect.value = target
			ModLoaderLog.info("Probabilidad por anzuelo: %d %% (juego: %d %%)" % [target, original], LOG_NAME)


func get_original_chance() -> int:
	var hook = Compat.get_item_data(HOOK_ITEM_ID)
	if hook == null:
		return -1
	for effect in hook.effects:
		if effect.key == CURSE_EFFECT_KEY:
			return int(effect.get_meta(ORIGINAL_VALUE_META)) if effect.has_meta(ORIGINAL_VALUE_META) else int(effect.value)
	return -1


# --- Anzuelo garantizado -------------------------------------------------------

# Llamado por la extensión de la tienda justo después de generar los artículos
# al entrar. shop_items: Array de [ItemParentData, oleada]; los primeros
# locked_count son los artículos bloqueados de la tienda anterior.
func on_shop_entered(shop_items: Array, locked_count: int, player_index: int) -> void:
	if not is_active() or not bool(get_setting("guaranteed_enabled", true)):
		return
	if not Compat.is_dlc_enabled_in_run(Compat.DLC_ABYSSAL_TERRORS):
		return
	if not should_guarantee(player_index):
		return

	var hook = Compat.get_item_data(HOOK_ITEM_ID)
	if hook == null:
		return
	var hook_hash: int = hook.my_id_hash
	for entry in shop_items:
		if entry[0] != null and entry[0].my_id_hash == hook_hash:
			return

	var slot := pick_slot(shop_items, locked_count)
	if slot < 0:
		return

	var new_item = Compat.prepare_shop_item(hook, player_index)
	shop_items[slot] = [new_item, shop_items[slot][1]]
	ModLoaderLog.info(
		"Anzuelo garantizado en la tienda de la oleada %d (jugador %d)" % [Compat.current_wave(), player_index + 1],
		LOG_NAME
	)


func should_guarantee(player_index: int) -> bool:
	var hook = Compat.get_item_data(HOOK_ITEM_ID)
	return HookRules.should_guarantee(
		Compat.current_wave(),
		int(get_setting("guaranteed_wave", 4)),
		bool(get_setting("guaranteed_until_owned", false)),
		Compat.count_player_items(player_index, HOOK_ITEM_ID),
		hook.max_nb if hook != null else -1,
		Compat.is_item_banned_for_player(player_index, HOOK_ITEM_ID)
	)


# Sustituye el último objeto no bloqueado; nunca toca los artículos bloqueados
# y solo cambia un arma si no queda ningún objeto.
static func pick_slot(shop_items: Array, locked_count: int) -> int:
	var kinds := []
	for entry in shop_items:
		var item = entry[0]
		if item == null:
			kinds.append("")
		elif item is WeaponData:
			kinds.append(HookRules.KIND_WEAPON)
		else:
			kinds.append(HookRules.KIND_ITEM)
	return HookRules.pick_slot(kinds, locked_count)
