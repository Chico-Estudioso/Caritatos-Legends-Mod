class_name ModLoaderMod
extends Object

# Sustituto de ModLoaderMod para las pruebas: registra las extensiones que se
# instalarían en lugar de instalarlas.

const INSTALLED_META := "clc_test_installed_extensions"


static func install_script_extension(child_script_path: String) -> void:
	var loop = Engine.get_main_loop()
	var installed: Array = loop.get_meta(INSTALLED_META) if loop.has_meta(INSTALLED_META) else []
	installed.append(child_script_path)
	loop.set_meta(INSTALLED_META, installed)


static func installed_extensions() -> Array:
	var loop = Engine.get_main_loop()
	return loop.get_meta(INSTALLED_META) if loop.has_meta(INSTALLED_META) else []


static func get_unpacked_dir() -> String:
	return "res://mods-unpacked/"
