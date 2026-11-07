extends Reference

# Acceso estático al núcleo para las extensiones de scripts del juego.
#
# Uso en una extensión:
#   const LegendsAPI = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
#   var hook = LegendsAPI.get_runtime("hook_legend")  # null si la leyenda no está activa
#
# Todas las funciones toleran que el núcleo no exista (por ejemplo, si falló
# al arrancar): en ese caso las extensiones se comportan como el juego base.

const CORE_PATH := "/root/ModLoader/Caritato-LegendsCollection/LegendsCore"


static func get_core() -> Node:
	var loop = Engine.get_main_loop()
	if loop == null or not loop is SceneTree:
		return null
	return loop.root.get_node_or_null(CORE_PATH)


static func is_active(module_id: String) -> bool:
	var core = get_core()
	return core != null and core.is_module_active(module_id)


# Devuelve el runtime de la leyenda solo si está cargada y activada.
static func get_runtime(module_id: String) -> Node:
	var core = get_core()
	if core == null or not core.is_module_active(module_id):
		return null
	return core.get_runtime(module_id)


static func get_setting(module_id: String, key: String, fallback = null):
	var core = get_core()
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


static func open_menu(context: String = "title", return_focus: Control = null) -> Node:
	var core = get_core()
	if core == null:
		return null
	return core.open_menu(context, return_focus)


# Muestra una ventana de leyenda cuando no haya otra abierta. Si no hay
# núcleo, la ventana se descarta.
static func show_popup(popup: Node) -> void:
	var core = get_core()
	if core == null:
		if popup != null and is_instance_valid(popup):
			popup.free()
		return
	core.show_popup(popup)


static func clear_popups() -> void:
	var core = get_core()
	if core != null:
		core.clear_popups()


# Marca de diagnóstico en el registro de ModLoader (modloader.log). Ese archivo
# se escribe línea a línea, así que, si el juego se cierra de golpe, la última
# marca dice en qué paso estaba el mod. Solo se usa en momentos puntuales
# (entrar en la tienda, preparar un menú), no en cada fotograma.
static func trace(text: String) -> void:
	ModLoaderLog.info("[diag] " + text, "Caritato-LegendsCollection:Diag")
