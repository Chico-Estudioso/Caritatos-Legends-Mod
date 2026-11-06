class_name ModLoaderLog
extends Object

# Sustituto de ModLoaderLog para las pruebas fuera de Brotato.


static func fatal(message: String, mod_name: String, _only_once := false) -> void:
	print("[log fatal] %s: %s" % [mod_name, message])


static func error(message: String, mod_name: String, _only_once := false) -> void:
	print("[log error] %s: %s" % [mod_name, message])


static func warning(message: String, mod_name: String, _only_once := false) -> void:
	print("[log warning] %s: %s" % [mod_name, message])


static func info(message: String, mod_name: String, _only_once := false) -> void:
	print("[log info] %s: %s" % [mod_name, message])


static func success(message: String, mod_name: String, _only_once := false) -> void:
	print("[log success] %s: %s" % [mod_name, message])


static func debug(message: String, mod_name: String, _only_once := false) -> void:
	print("[log debug] %s: %s" % [mod_name, message])
