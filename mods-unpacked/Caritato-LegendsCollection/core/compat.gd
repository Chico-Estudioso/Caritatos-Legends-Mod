extends Reference

# Capa de compatibilidad con Brotato.
#
# Reúne aquí las llamadas a la API interna del juego que comparten varias
# leyendas, para que una actualización de Brotato se adapte en un solo sitio.
# Verificado contra Brotato 1.1.15.4 (ModLoader 6.3.0) y 1.1.14.5 con
# Abyssal Terrors. Cada función devuelve un valor neutro si la API no existe.

const DLC_ABYSSAL_TERRORS := "abyssal_terrors"


static func game_version() -> String:
	return str(_script_constant(_singleton("ProgressData"), "VERSION", ""))


static func is_dlc_available(dlc_id: String) -> bool:
	var progress_data = _singleton("ProgressData")
	if progress_data == null or not progress_data.has_method("is_dlc_available"):
		return false
	return progress_data.is_dlc_available(dlc_id)


# El DLC está habilitado en la partida en curso.
# 1.2: RunData.active_update_data_ids (los «conjuntos de objetos» de la partida;
#      enabled_dlcs pasa a significar solo «DLC comprados»).
# 1.1: RunData.enabled_dlcs.
static func is_dlc_enabled_in_run(dlc_id: String) -> bool:
	var run_data = _singleton("RunData")
	if run_data == null:
		return false
	if "active_update_data_ids" in run_data:
		return run_data.active_update_data_ids.has(dlc_id)
	if "enabled_dlcs" in run_data:
		return run_data.enabled_dlcs.has(dlc_id)
	return false


static func get_player_count() -> int:
	var run_data = _singleton("RunData")
	if run_data == null:
		return 0
	return run_data.get_player_count()


static func current_wave() -> int:
	var run_data = _singleton("RunData")
	return run_data.current_wave if run_data != null else 0


static func normal_wave_count() -> int:
	var run_data = _singleton("RunData")
	return run_data.nb_of_waves if run_data != null else 20


# Cambia temporalmente el número de oleadas normales (ver La Leyenda de la
# Cosecha Eterna, que lo restaura justo después).
static func set_normal_wave_count(count: int) -> void:
	var run_data = _singleton("RunData")
	if run_data != null:
		run_data.nb_of_waves = count


# Oleadas posteriores a la última oleada normal (modo infinito).
static func is_after_last_normal_wave() -> bool:
	return current_wave() > normal_wave_count()


# Porcentaje de recolección que el juego quita en cada oleada del modo infinito.
static func vanilla_endless_harvesting_decrease() -> int:
	return int(_script_constant(_singleton("RunData"), "ENDLESS_HARVESTING_DECREASE", 20))


static func get_player_stat(stat_id: String, player_index: int) -> float:
	var utils = _singleton("Utils")
	if utils == null:
		return 0.0
	return float(utils.get_stat(generate_hash(stat_id), player_index))


static func remove_player_stat(stat_id: String, amount: int, player_index: int) -> void:
	var run_data = _singleton("RunData")
	if run_data != null:
		run_data.remove_stat(generate_hash(stat_id), amount, player_index)


static func get_player_effect(effect_id: String, player_index: int):
	var run_data = _singleton("RunData")
	if run_data == null:
		return 0
	return run_data.get_player_effect(generate_hash(effect_id), player_index)


static func get_player_gold(player_index: int) -> int:
	var run_data = _singleton("RunData")
	return run_data.get_player_gold(player_index) if run_data != null else 0


static func add_gold(amount: int, player_index: int) -> void:
	var run_data = _singleton("RunData")
	if run_data != null:
		run_data.add_gold(amount, player_index)


# Suma al contador que el juego muestra en un objeto (por ejemplo, la Hucha).
static func add_tracked_value(player_index: int, item_id: String, value: float) -> void:
	var run_data = _singleton("RunData")
	if run_data != null and run_data.has_method("add_tracked_value"):
		run_data.add_tracked_value(player_index, generate_hash(item_id), value)


# Lista de objetos que la tienda no ofrece en el modo infinito (Hucha, Corona).
static func get_endless_banned_items():
	var item_service = _singleton("ItemService")
	if item_service == null or not "banned_items_for_endless" in item_service:
		return null
	return item_service.banned_items_for_endless


static func set_endless_banned_items(items: Array) -> void:
	var item_service = _singleton("ItemService")
	if item_service != null and "banned_items_for_endless" in item_service:
		item_service.banned_items_for_endless = items


# Texto con el formato del juego (colores y porcentajes de sus claves).
static func format_text(key: String, args: Array) -> String:
	var text_singleton = _singleton("Text")
	if text_singleton != null and text_singleton.has_method("text"):
		return text_singleton.text(key, args)
	var text := TranslationServer.translate(key)
	for index in args.size():
		text = text.replace("{%d}" % index, str(args[index]))
	return text


static func generate_hash(text: String) -> int:
	var keys = _singleton("Keys")
	if keys == null:
		return 0
	return keys.generate_hash(text)


# Datos base de un objeto por id ("item_fish_hook"). null si no está cargado
# (por ejemplo, objetos de un DLC desactivado).
static func get_item_data(item_id: String):
	var item_service = _singleton("ItemService")
	if item_service == null:
		return null
	return item_service.get_element(item_service.items, generate_hash(item_id))


# Prepara un objeto base para ponerlo en la tienda igual que hace el juego con
# los objetos garantizados (aplica las modificaciones de los DLC activos).
static func prepare_shop_item(item_data, player_index: int):
	var item_service = _singleton("ItemService")
	if item_service == null or not item_service.has_method("apply_item_effect_modifications"):
		return item_data
	return item_service.apply_item_effect_modifications(item_data, player_index)


# Precio de un artículo en la tienda de la oleada actual (con los modificadores
# del juego y de otras leyendas, como el Mercader).
static func get_shop_price(item, player_index: int) -> int:
	var item_service = _singleton("ItemService")
	if item_service == null:
		return 0
	return item_service.get_value(current_wave(), item.value, player_index, true, is_weapon(item), item.my_id_hash)


static func is_weapon(item) -> bool:
	return item != null and "weapon_id" in item


# Objetos o armas desbloqueados de un tier que la tienda puede ofrecer.
static func get_shop_pool(tier: int, weapons: bool) -> Array:
	var item_service = _singleton("ItemService")
	if item_service == null or not item_service.has_method("get_pool"):
		return []
	var tier_data: Dictionary = _script_constant(item_service, "TierData", {})
	var type_key := "WEAPONS" if weapons else "ITEMS"
	if not tier_data.has(type_key):
		return []
	return item_service.get_pool(tier, tier_data[type_key])


# Mismas restricciones que aplica el juego al generar la tienda: prohibiciones,
# grupos vetados del personaje, etiquetas retiradas y máximo por objeto.
static func can_offer_item(item, player_index: int) -> bool:
	var run_data = _singleton("RunData")
	if run_data == null:
		return false
	if is_item_banned_for_player(player_index, item.my_id) or is_in_banned_item_group(player_index, item.my_id):
		return false
	if run_data.has_method("get_remaining_max_nb_item") and run_data.get_remaining_max_nb_item(item, player_index) <= 0:
		return false
	var keys = _singleton("Keys")
	if keys != null and "hash_to_string" in keys:
		for tag_hash in run_data.get_player_effect(generate_hash("remove_shop_items"), player_index):
			if keys.hash_to_string.has(tag_hash) and item.tags.has(keys.hash_to_string[tag_hash]):
				return false
	return true


static func can_offer_weapon(weapon, player_index: int) -> bool:
	var run_data = _singleton("RunData")
	if run_data == null:
		return false
	if is_item_banned_for_player(player_index, weapon.my_id):
		return false
	# WeaponData.Type: 0 = cuerpo a cuerpo, 1 = a distancia.
	if run_data.get_player_effect_bool(generate_hash("no_melee_weapons"), player_index) and weapon.type == 0:
		return false
	if run_data.get_player_effect_bool(generate_hash("no_ranged_weapons"), player_index) and weapon.type == 1:
		return false
	var min_tier = run_data.get_player_effect(generate_hash("min_weapon_tier"), player_index)
	var max_tier = run_data.get_player_effect(generate_hash("max_weapon_tier"), player_index)
	if weapon.tier < int(min_tier) or weapon.tier > int(max_tier):
		return false
	var removed: Array = run_data.get_player_effect(generate_hash("remove_shop_items"), player_index)
	var entity_service = _singleton("EntityService")
	if removed.has(generate_hash("structure")) and entity_service != null and entity_service.is_weapon_spawning_structure(weapon):
		return false
	return true


static func is_in_banned_item_group(player_index: int, item_id: String) -> bool:
	var run_data = _singleton("RunData")
	var item_service = _singleton("ItemService")
	if run_data == null or item_service == null or not run_data.has_method("get_player_character"):
		return false
	var character = run_data.get_player_character(player_index)
	if character == null or not "banned_item_groups" in character:
		return false
	for group in character.banned_item_groups:
		if item_service.item_groups.has(group) and item_service.item_groups[group].has(item_id):
			return true
	return false


static func get_player_currency(player_index: int) -> int:
	var run_data = _singleton("RunData")
	if run_data == null:
		return 0
	if run_data.has_method("get_player_currency"):
		return run_data.get_player_currency(player_index)
	return run_data.get_player_gold(player_index)


# Cobra en la moneda del jugador (materiales, o vida con los personajes que
# pagan así), igual que una compra normal.
static func remove_currency(amount: int, player_index: int) -> void:
	var run_data = _singleton("RunData")
	if run_data != null:
		run_data.remove_currency(amount, player_index)


static func tier_color(tier: int) -> Color:
	var item_service = _singleton("ItemService")
	if item_service != null and item_service.has_method("get_color_from_tier"):
		return item_service.get_color_from_tier(tier)
	return Color(1, 1, 1)


static func count_player_items(player_index: int, item_id: String) -> int:
	var run_data = _singleton("RunData")
	if run_data == null:
		return 0
	var item_hash := generate_hash(item_id)
	var count := 0
	for item in run_data.get_player_items(player_index):
		if item.my_id_hash == item_hash:
			count += 1
	return count


static func is_item_banned_for_player(player_index: int, item_id: String) -> bool:
	var run_data = _singleton("RunData")
	if run_data == null or player_index >= run_data.players_data.size():
		return false
	var item_hash := generate_hash(item_id)
	for banned in run_data.players_data[player_index].banned_items:
		if banned is String and banned == item_id:
			return true
		if banned is int and banned == item_hash:
			return true
	if run_data.has_method("get_player_character"):
		var character = run_data.get_player_character(player_index)
		if character != null and "banned_items" in character and character.banned_items.has(item_id):
			return true
	return false


# Lee una constante del script de un objeto recorriendo su cadena de herencia
# (por si otro mod ha extendido el script). Las constantes no se ven con `in`.
static func _script_constant(object: Object, constant_name: String, fallback):
	var script = object.get_script() if object != null else null
	while script != null:
		var constants: Dictionary = script.get_script_constant_map()
		if constants.has(constant_name):
			return constants[constant_name]
		script = script.get_base_script()
	return fallback


static func _singleton(singleton_name: String) -> Object:
	var loop = Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	return loop.root.get_node_or_null(singleton_name)
