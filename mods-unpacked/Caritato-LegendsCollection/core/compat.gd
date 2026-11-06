extends Reference

# Capa de compatibilidad con Brotato.
#
# Reúne aquí las llamadas a la API interna del juego que comparten varias
# leyendas, para que una actualización de Brotato se adapte en un solo sitio.
# Verificado contra Brotato 1.1.15.4 (ModLoader 6.3.0) y 1.1.14.5 con
# Abyssal Terrors. Cada función devuelve un valor neutro si la API no existe.

const DLC_ABYSSAL_TERRORS := "abyssal_terrors"


static func game_version() -> String:
	# VERSION es una constante del script de ProgressData; las constantes no
	# aparecen con `in`, así que se leen desde el mapa de constantes del script.
	# Se recorre la cadena de herencia por si otro mod extiende progress_data.gd.
	var progress_data = _singleton("ProgressData")
	var script = progress_data.get_script() if progress_data != null else null
	while script != null:
		var constants: Dictionary = script.get_script_constant_map()
		if constants.has("VERSION"):
			return str(constants.VERSION)
		script = script.get_base_script()
	return ""


static func is_dlc_available(dlc_id: String) -> bool:
	var progress_data = _singleton("ProgressData")
	if progress_data == null or not progress_data.has_method("is_dlc_available"):
		return false
	return progress_data.is_dlc_available(dlc_id)


# El DLC está habilitado en la partida en curso (o en la próxima, desde el menú).
static func is_dlc_enabled_in_run(dlc_id: String) -> bool:
	var run_data = _singleton("RunData")
	if run_data == null or not "enabled_dlcs" in run_data:
		return false
	return run_data.enabled_dlcs.has(dlc_id)


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


# Oleadas posteriores a la última oleada normal (modo infinito).
static func is_after_last_normal_wave() -> bool:
	return current_wave() > normal_wave_count()


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


static func _singleton(singleton_name: String) -> Object:
	var loop = Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	return loop.root.get_node_or_null(singleton_name)
