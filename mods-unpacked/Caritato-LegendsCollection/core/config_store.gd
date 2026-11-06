extends Reference

# Preferencias persistentes del jugador (leyendas activadas y sus ajustes).
#
# Se guardan en user:// (en Windows, %APPDATA%/Brotato/), fuera de la carpeta
# de instalación, así que sobreviven a las actualizaciones del mod. Si el
# archivo está dañado se guarda una copia de seguridad y se arranca con los
# valores por defecto sin bloquear el juego.
#
# Lógica pura: no depende de Brotato ni de ModLoader.

const FORMAT_VERSION := 1

var path := ""
var data := {}
var last_error := ""
var recovered_from_error := false


func _init(p_path: String = "") -> void:
	path = p_path
	data = empty_data()


static func empty_data() -> Dictionary:
	return {"format_version": FORMAT_VERSION, "modules": {}}


# Devuelve true si se ha leído correctamente o si todavía no existía (primer
# arranque). Devuelve false si había un archivo inválido y se ha recuperado.
func load_from_disk() -> bool:
	last_error = ""
	recovered_from_error = false

	var file := File.new()
	if path == "" or not file.file_exists(path):
		data = empty_data()
		return true

	var open_error := file.open(path, File.READ)
	if open_error != OK:
		return _recover("no se pudo abrir (error %d)" % open_error, "")

	var text := file.get_as_text()
	file.close()
	return load_from_text(text)


func load_from_text(text: String) -> bool:
	last_error = ""
	recovered_from_error = false

	var parsed := JSON.parse(text)
	if parsed.error != OK or not parsed.result is Dictionary:
		return _recover("JSON inválido", text)

	var result: Dictionary = parsed.result
	if not result.get("modules") is Dictionary:
		return _recover("falta la sección 'modules'", text)

	data = result
	data["format_version"] = FORMAT_VERSION
	return true


func save_to_disk() -> bool:
	if path == "":
		last_error = "sin ruta de guardado"
		return false

	var dir := Directory.new()
	var base_dir := path.get_base_dir()
	if not dir.dir_exists(base_dir):
		var mkdir_error := dir.make_dir_recursive(base_dir)
		if mkdir_error != OK:
			last_error = "no se pudo crear %s (error %d)" % [base_dir, mkdir_error]
			return false

	var file := File.new()
	var open_error := file.open(path, File.WRITE)
	if open_error != OK:
		last_error = "no se pudo escribir (error %d)" % open_error
		return false

	file.store_string(to_text())
	file.close()
	return true


func to_text() -> String:
	return JSON.print(data, "\t")


# Completa y corrige la configuración según las definiciones registradas:
# añade módulos y ajustes nuevos con su valor por defecto, corrige tipos y
# rangos y descarta ajustes que ya no existen. Los módulos desconocidos se
# conservan tal cual por si vuelven en una versión posterior.
func apply_registry(registry) -> void:
	var modules: Dictionary = data.modules
	for id in registry.order:
		var definition: Dictionary = registry.definitions[id]
		var entry = modules.get(id)
		if not entry is Dictionary:
			entry = {}

		var enabled = entry.get("enabled")
		entry["enabled"] = enabled if enabled is bool else definition.enabled_by_default

		var stored_settings = entry.get("settings")
		if not stored_settings is Dictionary:
			stored_settings = {}

		var clean_settings := {}
		for setting in definition.settings:
			if stored_settings.has(setting.key):
				clean_settings[setting.key] = sanitize_value(setting, stored_settings[setting.key])
			else:
				clean_settings[setting.key] = setting.default
		entry["settings"] = clean_settings
		modules[id] = entry


func is_enabled(id: String) -> bool:
	var entry = data.modules.get(id)
	return entry is Dictionary and entry.get("enabled") == true


func set_enabled(id: String, enabled: bool) -> void:
	var entry = data.modules.get(id)
	if not entry is Dictionary:
		entry = {"settings": {}}
		data.modules[id] = entry
	entry["enabled"] = enabled


func get_value(id: String, key: String, fallback = null):
	var entry = data.modules.get(id)
	if not entry is Dictionary:
		return fallback
	var settings = entry.get("settings")
	if not settings is Dictionary or not settings.has(key):
		return fallback
	return settings[key]


# Guarda un ajuste ya saneado. Devuelve el valor que ha quedado guardado.
func set_value(registry, id: String, key: String, value):
	var setting: Dictionary = registry.get_setting_definition(id, key)
	if setting.empty():
		return null
	var entry = data.modules.get(id)
	if not entry is Dictionary:
		entry = {"enabled": registry.definitions[id].enabled_by_default, "settings": {}}
		data.modules[id] = entry
	if not entry.get("settings") is Dictionary:
		entry["settings"] = {}
	var clean = sanitize_value(setting, value)
	entry.settings[key] = clean
	return clean


func reset_module(registry, id: String) -> void:
	data.modules.erase(id)
	apply_registry(registry)


func reset_all(registry) -> void:
	for id in registry.order:
		data.modules.erase(id)
	apply_registry(registry)


func snapshot() -> Dictionary:
	return data.duplicate(true)


func restore(snapshot_data: Dictionary) -> void:
	data = snapshot_data.duplicate(true)


static func sanitize_value(setting: Dictionary, value):
	match setting.type:
		"bool":
			if value is bool:
				return value
			if value is int or value is float:
				return value != 0
			if value is String:
				return ["true", "1", "yes", "si", "sí"].has(value.to_lower())
			return setting.default
		"int":
			var number = _to_number(value)
			if number == null:
				return setting.default
			var int_value := int(round(float(number)))
			return int(clamp(int_value, setting.min, setting.max))
		"float":
			var number = _to_number(value)
			if number == null:
				return setting.default
			return clamp(float(number), setting.min, setting.max)
		"enum":
			if value is String and setting.options.has(value):
				return value
			return setting.default
	return setting.get("default")


static func _to_number(value):
	if value is int or value is float:
		return value
	if value is String and value.is_valid_float():
		return float(value)
	return null


func _recover(reason: String, original_text: String) -> bool:
	last_error = reason
	recovered_from_error = true
	if original_text != "" and path != "":
		var backup := File.new()
		if backup.open(path + ".invalido.bak", File.WRITE) == OK:
			backup.store_string(original_text)
			backup.close()
	data = empty_data()
	return false
