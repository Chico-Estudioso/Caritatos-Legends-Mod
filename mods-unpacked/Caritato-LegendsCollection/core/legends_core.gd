extends Node

# Núcleo de Caritatos Legends.
#
# - Lee las definiciones de leyendas (modules/<id>/module.json).
# - Carga la configuración del jugador y decide qué leyendas se cargan.
# - Instala las extensiones de scripts y crea el runtime de cada leyenda cargada.
# - Ofrece la API que usan las extensiones y la pantalla de configuración.
#
# Un error en una leyenda se registra con su id y solo desactiva esa leyenda.

signal settings_changed(module_id)
signal enabled_changed(module_id, enabled)
signal menu_closed

const ModuleRegistry = preload("res://mods-unpacked/Caritato-LegendsCollection/core/module_registry.gd")
const ConfigStore = preload("res://mods-unpacked/Caritato-LegendsCollection/core/config_store.gd")
const I18n = preload("res://mods-unpacked/Caritato-LegendsCollection/core/i18n.gd")

const LOG_NAME := "Caritato-LegendsCollection:Core"
const CONFIG_PATH := "user://caritato_legends/settings.json"
const STRINGS_PATH := "i18n/strings.json"
const MODULES_INDEX_PATH := "modules/modules.json"
const MENU_SCRIPT_PATH := "ui/legends_menu.gd"

var mod_dir := ""
var version := ""
var registry = null
var config = null
# id -> {state, reason, detail} decidido al arrancar
var boot_state := {}
# id -> Node con la lógica de la leyenda
var runtimes := {}
var config_save_error := ""

# Extensiones de scripts de escenas (tienda, main.gd, menús) pendientes de
# instalar en mod_main._ready(). Ver install_late_extensions().
var _late_extensions := []
var _late_extensions_installed := false
var _menu: Node = null
# Ventanas interactivas de las leyendas: se muestran de una en una.
var _popup_queue := []
var _popup_current: Node = null

# Scripts del juego que otros scripts extienden: se instalan antes para que las
# extensiones de sus hijos (shop.gd, coop_shop.gd) hereden de la versión ya extendida.
const LATE_EXTENSION_PRIORITY := [
	"ui/menus/shop/base_shop.gd",
]


func boot(p_mod_dir: String, p_version: String) -> void:
	mod_dir = p_mod_dir
	version = p_version

	for error in I18n.register_file(mod_dir.plus_file(STRINGS_PATH)):
		ModLoaderLog.error("Textos: %s" % error, LOG_NAME)

	registry = ModuleRegistry.new()
	_load_definitions()
	registry.validate_references()

	for error in registry.global_errors:
		ModLoaderLog.error(error, LOG_NAME)
	for id in registry.order:
		for error in registry.module_errors[id]:
			ModLoaderLog.error("[%s] %s" % [id, error], LOG_NAME)

	config = ConfigStore.new(CONFIG_PATH)
	if not config.load_from_disk():
		ModLoaderLog.warning(
			"Configuración inválida (%s). Se usan los valores por defecto; copia en %s.invalido.bak"
			% [config.last_error, CONFIG_PATH], LOG_NAME
		)
	config.apply_registry(registry)

	var enabled := {}
	for id in registry.order:
		enabled[id] = config.is_enabled(id)
	boot_state = registry.resolve_load_set(enabled)

	for id in registry.order:
		if boot_state[id].state == ModuleRegistry.STATE_LOADED:
			_load_module(id)
		_log_module_state(id)

	if not config.save_to_disk():
		ModLoaderLog.warning("No se pudo guardar la configuración: %s" % config.last_error, LOG_NAME)


# --- Consultas -----------------------------------------------------------

func get_module_ids() -> Array:
	return registry.order.duplicate() if registry != null else []


func get_definition(id: String) -> Dictionary:
	return registry.get_definition(id) if registry != null else {}


func get_boot_state(id: String) -> Dictionary:
	return boot_state.get(id, {"state": ModuleRegistry.STATE_ERROR, "reason": "unknown", "detail": ""})


func is_module_loaded(id: String) -> bool:
	return get_boot_state(id).state == ModuleRegistry.STATE_LOADED


func is_module_enabled(id: String) -> bool:
	return config != null and config.is_enabled(id)


# Cargada al arrancar y activada ahora mismo.
func is_module_active(id: String) -> bool:
	return is_module_loaded(id) and is_module_enabled(id)


# Activada por el jugador, pero sus extensiones no se instalaron al arrancar.
func needs_restart(id: String) -> bool:
	if not is_module_enabled(id) or is_module_loaded(id):
		return false
	var state: String = get_boot_state(id).state
	return state == ModuleRegistry.STATE_DISABLED or state == ModuleRegistry.STATE_BLOCKED


func any_needs_restart() -> bool:
	for id in get_module_ids():
		if needs_restart(id):
			return true
	return false


func get_runtime(id: String) -> Node:
	return runtimes.get(id)


func get_setting(id: String, key: String, fallback = null):
	if config == null:
		return fallback
	return config.get_value(id, key, fallback)


# --- Cambios desde la interfaz --------------------------------------------

func set_setting(id: String, key: String, value):
	var stored = config.set_value(registry, id, key, value)
	_notify_runtime(id)
	emit_signal("settings_changed", id)
	return stored


func set_module_enabled(id: String, enabled: bool) -> void:
	config.set_enabled(id, enabled)
	_notify_runtime(id)
	emit_signal("enabled_changed", id, enabled)


func reset_defaults() -> void:
	config.reset_all(registry)
	_notify_all()


func snapshot() -> Dictionary:
	return config.snapshot()


func restore(snapshot_data: Dictionary) -> void:
	config.restore(snapshot_data)
	config.apply_registry(registry)
	_notify_all()


func save_config() -> bool:
	config_save_error = ""
	if config.save_to_disk():
		ModLoaderLog.info("Configuración guardada.", LOG_NAME)
		return true
	config_save_error = config.last_error
	ModLoaderLog.error("No se pudo guardar la configuración: %s" % config_save_error, LOG_NAME)
	return false


func open_menu(context: String = "title", return_focus: Control = null) -> Node:
	if _menu != null and is_instance_valid(_menu):
		return _menu
	var menu_script = load(mod_dir.plus_file(MENU_SCRIPT_PATH))
	if menu_script == null:
		ModLoaderLog.error("No se pudo cargar la pantalla de configuración.", LOG_NAME)
		return null
	_menu = menu_script.new()
	get_tree().root.add_child(_menu)
	var _err = _menu.connect("closed", self, "_on_menu_closed")
	_menu.open(self, context, return_focus)
	return _menu


# Muestra una ventana de leyenda (ui/legend_popup.gd) o la deja en cola si ya
# hay otra abierta.
func show_popup(popup: Node) -> void:
	if popup == null:
		return
	_popup_queue.append(popup)
	_show_next_popup()


func is_popup_open() -> bool:
	return _popup_current != null and is_instance_valid(_popup_current)


# Descarta las ventanas en cola (por ejemplo, al salir de la tienda).
func clear_popups() -> void:
	for popup in _popup_queue:
		if is_instance_valid(popup) and not popup.is_inside_tree():
			popup.free()
	_popup_queue.clear()


func _show_next_popup() -> void:
	if is_popup_open():
		return
	_popup_current = null
	while not _popup_queue.empty():
		var popup = _popup_queue.pop_front()
		if popup == null or not is_instance_valid(popup):
			continue
		_popup_current = popup
		get_tree().root.add_child(popup)
		var _err = popup.connect("closed", self, "_on_popup_closed", [], CONNECT_ONESHOT)
		popup.popup_open()
		return


func _on_popup_closed(_result: String) -> void:
	_popup_current = null
	call_deferred("_show_next_popup")


func is_menu_open() -> bool:
	return _menu != null and is_instance_valid(_menu)


# --- Interno ---------------------------------------------------------------

func _load_definitions() -> void:
	var index = _read_json(mod_dir.plus_file(MODULES_INDEX_PATH))
	if not index is Dictionary or not index.get("modules") is Array:
		registry.global_errors.append("%s no es válido" % MODULES_INDEX_PATH)
		return

	for module_dir in index.modules:
		if not module_dir is String:
			registry.global_errors.append("%s contiene una entrada que no es texto" % MODULES_INDEX_PATH)
			continue
		var base_dir := mod_dir.plus_file("modules").plus_file(module_dir)
		var definition_path := base_dir.plus_file("module.json")
		var raw = _read_json(definition_path)
		if raw == null:
			registry.global_errors.append("no se pudo leer %s" % definition_path)
			continue
		var id: String = registry.register_definition(raw, definition_path)
		if id == "":
			continue
		registry.definitions[id]["dir"] = base_dir
		if id != module_dir:
			registry.module_errors[id].append("la carpeta '%s' no coincide con el id" % module_dir)


func _load_module(id: String) -> bool:
	var definition: Dictionary = registry.definitions[id]
	var base_dir: String = definition.dir

	# Se comprueba todo antes de instalar nada: o se carga entera o no se carga.
	var extension_paths := []
	for extension in definition.extensions:
		var extension_path := base_dir.plus_file(extension)
		if not _file_exists(extension_path):
			return _fail_module(id, "missing_file", extension_path)
		extension_paths.append(extension_path)

	var runtime_script = null
	if definition.runtime != "":
		var runtime_path := base_dir.plus_file(definition.runtime)
		if not _file_exists(runtime_path):
			return _fail_module(id, "missing_file", runtime_path)
		runtime_script = load(runtime_path)
		if runtime_script == null:
			return _fail_module(id, "load_failed", runtime_path)

	for extension_path in extension_paths:
		var target := extension_target(extension_path)
		if is_early_target(target):
			ModLoaderMod.install_script_extension(extension_path)
		else:
			_late_extensions.append({"path": extension_path, "target": target, "module": id})

	if runtime_script != null:
		var runtime = runtime_script.new()
		runtime.name = "Runtime_%s" % id
		add_child(runtime)
		if runtime.has_method("setup"):
			runtime.setup(self, id)
		runtimes[id] = runtime

	return true


# Instala las extensiones de scripts de escenas. Se llama desde mod_main._ready():
# en Brotato 1.2.0.1, cargar base_shop.gd durante _init falla (infiere tipos de
# RunData, que aún no existe) y el CrashReporter desactiva todos los mods en el
# siguiente arranque. Las escenas se cargan después, así que instalar aquí es seguro.
func install_late_extensions() -> void:
	if _late_extensions_installed:
		return
	_late_extensions_installed = true
	for entry in sort_late_extensions(_late_extensions):
		ModLoaderMod.install_script_extension(entry.path)
	_late_extensions.clear()


func get_pending_late_extensions() -> Array:
	return _late_extensions.duplicate()


# Las extensiones replican la ruta del script que extienden:
# modules/<id>/extensions/ui/menus/shop/base_shop.gd -> ui/menus/shop/base_shop.gd
static func extension_target(extension_path: String) -> String:
	var marker := "/extensions/"
	var index := extension_path.find(marker)
	if index == -1:
		return ""
	return extension_path.substr(index + marker.length())


# Los autoloads (singletons) se crean justo después de ModLoader: sus
# extensiones deben instalarse durante _init o ya no surten efecto.
static func is_early_target(target: String) -> bool:
	return target.begins_with("singletons/")


static func sort_late_extensions(entries: Array) -> Array:
	var first := []
	var rest := []
	for entry in entries:
		if LATE_EXTENSION_PRIORITY.has(entry.target):
			first.append(entry)
		else:
			rest.append(entry)
	return first + rest


func _fail_module(id: String, reason: String, detail: String) -> bool:
	boot_state[id] = ModuleRegistry._state(ModuleRegistry.STATE_ERROR, reason, detail)
	return false


func _log_module_state(id: String) -> void:
	var state: Dictionary = boot_state[id]
	if state.state == ModuleRegistry.STATE_LOADED:
		ModLoaderLog.info("[%s] cargada" % id, LOG_NAME)
	elif state.state == ModuleRegistry.STATE_DISABLED:
		ModLoaderLog.info("[%s] desactivada por el jugador" % id, LOG_NAME)
	elif state.state == ModuleRegistry.STATE_BLOCKED:
		ModLoaderLog.warning("[%s] no se carga (%s: %s)" % [id, state.reason, state.detail], LOG_NAME)
	else:
		ModLoaderLog.error("[%s] no se carga por un error (%s: %s)" % [id, state.reason, state.detail], LOG_NAME)


func _notify_runtime(id: String) -> void:
	var runtime = runtimes.get(id)
	if runtime != null and is_instance_valid(runtime) and runtime.has_method("on_config_changed"):
		runtime.on_config_changed()


func _notify_all() -> void:
	for id in get_module_ids():
		_notify_runtime(id)
		emit_signal("settings_changed", id)


func _on_menu_closed() -> void:
	_menu = null
	emit_signal("menu_closed")


static func _file_exists(path: String) -> bool:
	return File.new().file_exists(path) or ResourceLoader.exists(path)


static func _read_json(path: String):
	var file := File.new()
	if not file.file_exists(path):
		return null
	if file.open(path, File.READ) != OK:
		return null
	var parsed := JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK:
		return null
	return parsed.result
