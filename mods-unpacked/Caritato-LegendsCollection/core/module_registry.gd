extends Reference

# Registro y validación de las definiciones de leyendas (módulos internos).
#
# Lógica pura: no usa Brotato ni ModLoader, de modo que se puede probar con
# Godot en modo headless (ver tests/gdscript/). Cada leyenda se describe en
# modules/<id>/module.json y aquí se normaliza y valida.

const ID_PATTERN := "^[a-z][a-z0-9_]{2,47}$"
const SETTING_KEY_PATTERN := "^[a-z][a-z0-9_]{0,47}$"
const VALID_CATEGORIES := ["mechanics", "shop", "economy", "balance", "content", "quality_of_life"]
const VALID_SETTING_TYPES := ["bool", "int", "float", "enum"]
const VALID_COMPAT_STATUS := ["tested", "untested", "needs_adaptation", "incompatible"]

const STATE_LOADED := "loaded"
const STATE_DISABLED := "disabled"
const STATE_ERROR := "error"
const STATE_BLOCKED := "blocked"

# id -> definición normalizada
var definitions := {}
# ids en el orden en que se declararon
var order := []
# id -> Array de mensajes de error propios del módulo
var module_errors := {}
# errores que no se pueden atribuir a un módulo concreto
var global_errors := []

var _id_regex := RegEx.new()
var _key_regex := RegEx.new()


func _init() -> void:
	var _err = _id_regex.compile(ID_PATTERN)
	_err = _key_regex.compile(SETTING_KEY_PATTERN)


# Registra una definición. Devuelve el id registrado o "" si se rechaza por
# completo (id inválido o duplicado). Los demás problemas se guardan en
# module_errors[id] para que el módulo quede marcado con error sin afectar al resto.
func register_definition(raw, source: String = "") -> String:
	if not raw is Dictionary:
		global_errors.append("%s: la definición no es un objeto JSON" % source)
		return ""

	var id = raw.get("id", "")
	if not id is String or _id_regex.search(id) == null:
		global_errors.append("%s: id de módulo inválido (%s)" % [source, str(id)])
		return ""

	if definitions.has(id):
		global_errors.append("%s: id de módulo duplicado '%s'" % [source, id])
		return ""

	var errors := []
	var definition := _normalize(raw, errors)
	definition["source"] = source
	definitions[id] = definition
	order.append(id)
	module_errors[id] = errors
	return id


func has_module(id: String) -> bool:
	return definitions.has(id)


func get_definition(id: String) -> Dictionary:
	return definitions.get(id, {})


func get_setting_definition(id: String, key: String) -> Dictionary:
	var definition: Dictionary = definitions.get(id, {})
	for setting in definition.get("settings", []):
		if setting.key == key:
			return setting
	return {}


func has_errors(id: String) -> bool:
	return module_errors.get(id, []).size() > 0


# Comprueba referencias entre módulos: dependencias inexistentes, dependencias
# de sí mismo y ciclos. Debe llamarse después de registrar todas las definiciones.
func validate_references() -> void:
	for id in order:
		var definition: Dictionary = definitions[id]
		for dependency in definition.dependencies:
			if dependency == id:
				module_errors[id].append("depende de sí mismo")
			elif not definitions.has(dependency):
				module_errors[id].append("dependencia inexistente '%s'" % dependency)
		for conflict in definition.conflicts:
			if conflict == id:
				module_errors[id].append("declara un conflicto consigo mismo")

	for id in order:
		if _depends_on(id, id, {}):
			module_errors[id].append("dependencia circular")


# Decide qué módulos se cargan a partir de su estado activado/desactivado.
# enabled_lookup: id -> bool. Devuelve id -> {state, reason, detail}.
#   state: loaded | disabled | error | blocked
#   reason (si blocked): dependency | conflict
func resolve_load_set(enabled_lookup: Dictionary) -> Dictionary:
	var states := {}
	var loaded := []
	for id in order:
		var _is_loaded = _resolve(id, enabled_lookup, states, loaded)
	return states


func _resolve(id: String, enabled_lookup: Dictionary, states: Dictionary, loaded: Array) -> bool:
	if states.has(id):
		return states[id].state == STATE_LOADED

	if has_errors(id):
		states[id] = _state(STATE_ERROR, "invalid_definition", module_errors[id][0])
		return false

	if not bool(enabled_lookup.get(id, false)):
		states[id] = _state(STATE_DISABLED)
		return false

	var definition: Dictionary = definitions[id]
	for dependency in definition.dependencies:
		if not _resolve(dependency, enabled_lookup, states, loaded):
			states[id] = _state(STATE_BLOCKED, "dependency", dependency)
			return false

	for other in loaded:
		var other_definition: Dictionary = definitions[other]
		if definition.conflicts.has(other) or other_definition.conflicts.has(id):
			states[id] = _state(STATE_BLOCKED, "conflict", other)
			return false

	states[id] = _state(STATE_LOADED)
	loaded.append(id)
	return true


static func _state(state: String, reason: String = "", detail: String = "") -> Dictionary:
	return {"state": state, "reason": reason, "detail": detail}


func _depends_on(start: String, target: String, visited: Dictionary) -> bool:
	var definition: Dictionary = definitions.get(start, {})
	for dependency in definition.get("dependencies", []):
		if dependency == target:
			return true
		if visited.has(dependency):
			continue
		visited[dependency] = true
		if _depends_on(dependency, target, visited):
			return true
	return false


func _normalize(raw: Dictionary, errors: Array) -> Dictionary:
	var definition := {
		"id": raw.id,
		"version": _string_field(raw, "version", "0.0.0", errors),
		"category": _string_field(raw, "category", "mechanics", errors),
		"name_key": _string_field(raw, "name_key", "", errors),
		"description_key": _string_field(raw, "description_key", "", errors),
		"short_name_key": _string_field(raw, "short_name_key", "", errors),
		"warning_key": _string_field(raw, "warning_key", "", errors),
		"accent": _string_field(raw, "accent", "", errors),
		"enabled_by_default": _bool_field(raw, "enabled_by_default", true, errors),
		"dependencies": _string_array_field(raw, "dependencies", errors),
		"conflicts": _string_array_field(raw, "conflicts", errors),
		"requires_dlc": _string_array_field(raw, "requires_dlc", errors),
		"extensions": _string_array_field(raw, "extensions", errors),
		"runtime": _string_field(raw, "runtime", "", errors),
		"compatibility": {"status": "untested", "game_versions": []},
		"origin": raw.get("origin", {}) if raw.get("origin", {}) is Dictionary else {},
		"settings": [],
		"actions": [],
	}

	if definition.name_key == "":
		errors.append("falta name_key")
	if definition.description_key == "":
		errors.append("falta description_key")
	if not VALID_CATEGORIES.has(definition.category):
		errors.append("categoría desconocida '%s'" % definition.category)
	if definition.short_name_key == "":
		definition.short_name_key = definition.name_key
	if definition.accent != "" and not _is_hex_color(definition.accent):
		errors.append("accent debe ser un color #rrggbb ('%s')" % definition.accent)
		definition.accent = ""

	var compatibility = raw.get("compatibility", {})
	if compatibility is Dictionary:
		var status = compatibility.get("status", "untested")
		if status is String and VALID_COMPAT_STATUS.has(status):
			definition.compatibility.status = status
		else:
			errors.append("estado de compatibilidad desconocido '%s'" % str(status))
		var versions = compatibility.get("game_versions", [])
		if versions is Array:
			for version in versions:
				if version is String:
					definition.compatibility.game_versions.append(version)
	else:
		errors.append("compatibility debe ser un objeto")

	var raw_settings = raw.get("settings", [])
	if not raw_settings is Array:
		errors.append("settings debe ser una lista")
		raw_settings = []

	var seen_keys := {}
	for index in raw_settings.size():
		var setting := _normalize_setting(raw_settings[index], index, errors)
		if setting.empty():
			continue
		if seen_keys.has(setting.key):
			errors.append("ajuste duplicado '%s'" % setting.key)
			continue
		seen_keys[setting.key] = true
		definition.settings.append(setting)

	# Acciones: botones de la ficha que llaman a un método del runtime
	# (abrir un editor, un enlace…). No guardan ningún valor.
	var raw_actions = raw.get("actions", [])
	if not raw_actions is Array:
		errors.append("actions debe ser una lista")
		raw_actions = []
	for index in raw_actions.size():
		var action := _normalize_action(raw_actions[index], index, errors)
		if not action.empty():
			definition.actions.append(action)

	return definition


func _normalize_action(raw, index: int, errors: Array) -> Dictionary:
	if not raw is Dictionary:
		errors.append("la acción #%d no es un objeto" % index)
		return {}
	var method = raw.get("method", "")
	var label_key = raw.get("label_key", "")
	if not method is String or _key_regex.search(method) == null:
		errors.append("la acción #%d tiene un método inválido (%s)" % [index, str(method)])
		return {}
	if not label_key is String or label_key == "":
		errors.append("la acción '%s' no tiene label_key" % method)
		return {}
	var help_key = raw.get("help_key", "")
	var style = raw.get("style", "primary")
	return {
		"method": method,
		"label_key": label_key,
		"help_key": help_key if help_key is String else "",
		"style": style if style is String and ["primary", "ghost"].has(style) else "primary",
	}


func _normalize_setting(raw, index: int, errors: Array) -> Dictionary:
	if not raw is Dictionary:
		errors.append("el ajuste #%d no es un objeto" % index)
		return {}

	var key = raw.get("key", "")
	if not key is String or _key_regex.search(key) == null:
		errors.append("el ajuste #%d tiene una clave inválida (%s)" % [index, str(key)])
		return {}

	var type = raw.get("type", "")
	if not type is String or not VALID_SETTING_TYPES.has(type):
		errors.append("el ajuste '%s' tiene un tipo desconocido (%s)" % [key, str(type)])
		return {}

	var setting := {
		"key": key,
		"type": type,
		"label_key": raw.get("label_key", "") if raw.get("label_key", "") is String else "",
		"help_key": raw.get("help_key", "") if raw.get("help_key", "") is String else "",
		"suffix": raw.get("suffix", "") if raw.get("suffix", "") is String else "",
		"depends_on": raw.get("depends_on", "") if raw.get("depends_on", "") is String else "",
	}

	if setting.label_key == "":
		errors.append("el ajuste '%s' no tiene label_key" % key)

	var default_value = raw.get("default")
	match type:
		"bool":
			if not default_value is bool:
				errors.append("el ajuste '%s' necesita un valor por defecto booleano" % key)
				return {}
			setting["default"] = default_value
		"int", "float":
			var min_value = raw.get("min")
			var max_value = raw.get("max")
			var step = raw.get("step", 1)
			if not _is_number(min_value) or not _is_number(max_value) or not _is_number(default_value) or not _is_number(step):
				errors.append("el ajuste '%s' necesita min, max, step y default numéricos" % key)
				return {}
			if float(min_value) > float(max_value):
				errors.append("el ajuste '%s' tiene min mayor que max" % key)
				return {}
			if float(default_value) < float(min_value) or float(default_value) > float(max_value):
				errors.append("el valor por defecto de '%s' está fuera de rango" % key)
				return {}
			if float(step) <= 0.0:
				errors.append("el ajuste '%s' necesita un step positivo" % key)
				return {}
			if type == "int":
				setting["min"] = int(min_value)
				setting["max"] = int(max_value)
				setting["step"] = int(max(1, int(step)))
				setting["default"] = int(default_value)
			else:
				setting["min"] = float(min_value)
				setting["max"] = float(max_value)
				setting["step"] = float(step)
				setting["default"] = float(default_value)
		"enum":
			var options = raw.get("options", [])
			if not options is Array or options.empty():
				errors.append("el ajuste '%s' necesita opciones" % key)
				return {}
			for option in options:
				if not option is String:
					errors.append("el ajuste '%s' tiene opciones que no son texto" % key)
					return {}
			if not default_value is String or not options.has(default_value):
				errors.append("el valor por defecto de '%s' no está entre sus opciones" % key)
				return {}
			setting["options"] = options.duplicate()
			setting["default"] = default_value

	return setting


static func _is_hex_color(value: String) -> bool:
	if value.length() != 7 or not value.begins_with("#"):
		return false
	return value.substr(1).is_valid_hex_number()


static func _is_number(value) -> bool:
	return value is int or value is float


func _string_field(raw: Dictionary, field: String, fallback: String, errors: Array) -> String:
	if not raw.has(field):
		return fallback
	var value = raw[field]
	if value is String:
		return value
	errors.append("%s debe ser texto" % field)
	return fallback


func _bool_field(raw: Dictionary, field: String, fallback: bool, errors: Array) -> bool:
	if not raw.has(field):
		return fallback
	var value = raw[field]
	if value is bool:
		return value
	errors.append("%s debe ser booleano" % field)
	return fallback


func _string_array_field(raw: Dictionary, field: String, errors: Array) -> Array:
	var result := []
	if not raw.has(field):
		return result
	var value = raw[field]
	if not value is Array:
		errors.append("%s debe ser una lista" % field)
		return result
	for item in value:
		if item is String:
			result.append(item)
		else:
			errors.append("%s solo admite texto" % field)
	return result
