extends SceneTree

# Pruebas de la lógica pura del núcleo (registro de leyendas y configuración).
# No necesitan Brotato: se ejecutan con Godot 3 en modo headless mediante
#   python tools/run_gdscript_tests.py --godot <ruta a Godot 3 headless>

const MOD_PATH := "res://mods-unpacked/Caritato-LegendsCollection/"

var ModuleRegistry = load(MOD_PATH + "core/module_registry.gd")
var ConfigStore = load(MOD_PATH + "core/config_store.gd")

var _passed := 0
var _failed := 0
var _current := ""


func _init() -> void:
	_run("registro acepta una definición válida", "test_registry_valid")
	_run("registro rechaza ids inválidos y duplicados", "test_registry_rejects_bad_ids")
	_run("registro detecta ajustes mal definidos", "test_registry_bad_settings")
	_run("registro detecta dependencias inexistentes y ciclos", "test_registry_references")
	_run("resolución de carga respeta estado, dependencias y conflictos", "test_registry_resolution")
	_run("configuración se recupera de un archivo inválido", "test_config_recovers")
	_run("configuración completa valores por defecto", "test_config_defaults")
	_run("configuración sanea tipos y rangos", "test_config_sanitize")
	_run("configuración guarda y vuelve a leer", "test_config_roundtrip")
	_run("restaurar valores por defecto", "test_config_reset")

	print("RESULTADO: %d correctas, %d fallidas" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _run(title: String, method: String) -> void:
	_current = title
	var failures_before := _failed
	call(method)
	if _failed == failures_before:
		_passed += 1
		print("OK   %s" % title)


func check(condition: bool, message: String) -> void:
	if not condition:
		_failed += 1
		print("FALLO %s: %s" % [_current, message])


func sample_definition(id: String = "sample_legend") -> Dictionary:
	return {
		"id": id,
		"version": "1.0.0",
		"category": "mechanics",
		"name_key": "CLC_TEST_NAME",
		"description_key": "CLC_TEST_DESC",
		"enabled_by_default": true,
		"settings": [
			{"key": "flag", "type": "bool", "default": true, "label_key": "CLC_TEST_FLAG"},
			{"key": "amount", "type": "int", "default": 4, "min": 1, "max": 20, "step": 1, "label_key": "CLC_TEST_AMOUNT"},
			{"key": "ratio", "type": "float", "default": 0.5, "min": 0.0, "max": 1.0, "step": 0.05, "label_key": "CLC_TEST_RATIO"},
			{"key": "mode", "type": "enum", "default": "a", "options": ["a", "b"], "label_key": "CLC_TEST_MODE"},
		],
	}


func make_registry(definitions: Array):
	var registry = ModuleRegistry.new()
	for definition in definitions:
		var _id = registry.register_definition(definition, "test")
	registry.validate_references()
	return registry


func test_registry_valid() -> void:
	var registry = make_registry([sample_definition()])
	check(registry.has_module("sample_legend"), "no se registró")
	check(not registry.has_errors("sample_legend"), "errores inesperados: %s" % str(registry.module_errors))
	var definition: Dictionary = registry.get_definition("sample_legend")
	check(definition.settings.size() == 4, "deberían quedar 4 ajustes")
	check(definition.dependencies.empty(), "dependencies debería ser una lista vacía")
	check(typeof(registry.get_setting_definition("sample_legend", "amount").step) == TYPE_INT, "step int debería ser entero")


func test_registry_rejects_bad_ids() -> void:
	var registry = ModuleRegistry.new()
	check(registry.register_definition({"id": "Bad-Id"}, "test") == "", "aceptó un id inválido")
	check(registry.register_definition("no es un objeto", "test") == "", "aceptó algo que no es un objeto")
	check(registry.register_definition(sample_definition(), "test") == "sample_legend", "rechazó un id válido")
	check(registry.register_definition(sample_definition(), "test") == "", "aceptó un id duplicado")
	check(registry.global_errors.size() == 3, "se esperaban 3 errores globales, hay %d" % registry.global_errors.size())


func test_registry_bad_settings() -> void:
	var definition := sample_definition()
	definition.settings = [
		{"key": "out", "type": "int", "default": 50, "min": 0, "max": 10, "label_key": "CLC_X"},
		{"key": "kind", "type": "colour", "default": 1, "label_key": "CLC_X"},
		{"key": "choice", "type": "enum", "default": "z", "options": ["a"], "label_key": "CLC_X"},
		{"key": "dup", "type": "bool", "default": true, "label_key": "CLC_X"},
		{"key": "dup", "type": "bool", "default": false, "label_key": "CLC_X"},
	]
	definition.category = "unknown"
	var registry = make_registry([definition])
	var errors: Array = registry.module_errors["sample_legend"]
	check(errors.size() == 5, "se esperaban 5 errores, hay %d: %s" % [errors.size(), str(errors)])
	check(registry.has_errors("sample_legend"), "el módulo debería quedar con errores")


func test_registry_references() -> void:
	var a := sample_definition("legend_a")
	a["dependencies"] = ["legend_b"]
	var b := sample_definition("legend_b")
	b["dependencies"] = ["legend_a"]
	var c := sample_definition("legend_c")
	c["dependencies"] = ["missing_one"]
	var registry = make_registry([a, b, c])
	check(registry.has_errors("legend_a"), "legend_a debería detectar el ciclo")
	check(registry.has_errors("legend_b"), "legend_b debería detectar el ciclo")
	check(registry.has_errors("legend_c"), "legend_c debería detectar la dependencia inexistente")


func test_registry_resolution() -> void:
	var base := sample_definition("base_legend")
	var child := sample_definition("child_legend")
	child["dependencies"] = ["base_legend"]
	var rival := sample_definition("rival_legend")
	rival["conflicts"] = ["base_legend"]
	var broken := sample_definition("broken_legend")
	broken["category"] = "nope"
	var registry = make_registry([base, child, rival, broken])

	var all_on = registry.resolve_load_set({"base_legend": true, "child_legend": true, "rival_legend": true, "broken_legend": true})
	check(all_on.base_legend.state == "loaded", "base debería cargarse")
	check(all_on.child_legend.state == "loaded", "child debería cargarse")
	check(all_on.rival_legend.state == "blocked" and all_on.rival_legend.reason == "conflict", "rival debería bloquearse por conflicto")
	check(all_on.broken_legend.state == "error", "broken debería quedar con error")

	var base_off = registry.resolve_load_set({"base_legend": false, "child_legend": true, "rival_legend": true})
	check(base_off.base_legend.state == "disabled", "base debería estar desactivada")
	check(base_off.child_legend.state == "blocked" and base_off.child_legend.detail == "base_legend", "child debería bloquearse por su dependencia")
	check(base_off.rival_legend.state == "loaded", "rival debería cargarse si base no está")


func test_config_recovers() -> void:
	var config = ConfigStore.new("")
	check(not config.load_from_text("{esto no es json"), "debería informar del error")
	check(config.recovered_from_error, "debería marcar la recuperación")
	check(config.data.modules.empty(), "debería quedar vacía")
	check(not config.load_from_text("[1, 2, 3]"), "una lista no es una configuración válida")
	check(not config.load_from_text("{\"modules\": 5}"), "modules debe ser un objeto")
	check(config.load_from_text("{\"modules\": {}}"), "una configuración mínima es válida")


func test_config_defaults() -> void:
	var off := sample_definition("off_legend")
	off["enabled_by_default"] = false
	var registry = make_registry([sample_definition(), off])
	var config = ConfigStore.new("")
	var _ok = config.load_from_text("{\"modules\": {\"sample_legend\": {\"enabled\": false, \"settings\": {\"amount\": 7, \"old_setting\": 1}}, \"future_legend\": {\"enabled\": true}}}")
	config.apply_registry(registry)
	check(not config.is_enabled("sample_legend"), "debería respetar la elección guardada")
	check(not config.is_enabled("off_legend"), "debería usar enabled_by_default")
	check(config.get_value("sample_legend", "amount") == 7, "debería conservar el valor guardado")
	check(config.get_value("sample_legend", "flag") == true, "debería añadir el valor por defecto")
	check(config.get_value("sample_legend", "old_setting", "x") == "x", "debería descartar ajustes que ya no existen")
	check(config.data.modules.has("future_legend"), "debería conservar módulos desconocidos")


func test_config_sanitize() -> void:
	var registry = make_registry([sample_definition()])
	var config = ConfigStore.new("")
	config.apply_registry(registry)
	check(config.set_value(registry, "sample_legend", "amount", 99) == 20, "debería limitar al máximo")
	check(config.set_value(registry, "sample_legend", "amount", -3) == 1, "debería limitar al mínimo")
	check(config.set_value(registry, "sample_legend", "amount", "12") == 12, "debería convertir texto numérico")
	check(config.set_value(registry, "sample_legend", "amount", 5.6) == 6, "debería redondear a entero")
	check(config.set_value(registry, "sample_legend", "amount", "abc") == 4, "debería volver al valor por defecto")
	check(config.set_value(registry, "sample_legend", "flag", 0) == false, "0 debería ser falso")
	check(config.set_value(registry, "sample_legend", "mode", "zzz") == "a", "una opción desconocida vuelve al defecto")
	check(abs(config.set_value(registry, "sample_legend", "ratio", 3.0) - 1.0) < 0.0001, "float limitado al máximo")
	check(config.set_value(registry, "sample_legend", "missing", 1) == null, "un ajuste inexistente no se guarda")


func test_config_roundtrip() -> void:
	var path := "user://clc_test_settings.json"
	var registry = make_registry([sample_definition()])
	var config = ConfigStore.new(path)
	config.apply_registry(registry)
	config.set_enabled("sample_legend", false)
	var _stored = config.set_value(registry, "sample_legend", "amount", 9)
	check(config.save_to_disk(), "debería guardar: %s" % config.last_error)

	var reloaded = ConfigStore.new(path)
	check(reloaded.load_from_disk(), "debería leer el archivo")
	reloaded.apply_registry(registry)
	check(not reloaded.is_enabled("sample_legend"), "debería conservar el estado")
	check(reloaded.get_value("sample_legend", "amount") == 9, "debería conservar el valor")

	var missing = ConfigStore.new("user://clc_no_existe.json")
	check(missing.load_from_disk(), "un archivo inexistente es un primer arranque válido")
	var _err = Directory.new().remove(path)


func test_config_reset() -> void:
	var registry = make_registry([sample_definition()])
	var config = ConfigStore.new("")
	config.apply_registry(registry)
	config.set_enabled("sample_legend", false)
	var _stored = config.set_value(registry, "sample_legend", "amount", 15)
	var snapshot: Dictionary = config.snapshot()
	config.reset_all(registry)
	check(config.is_enabled("sample_legend"), "debería volver a estar activada")
	check(config.get_value("sample_legend", "amount") == 4, "debería volver al valor por defecto")
	config.restore(snapshot)
	check(config.get_value("sample_legend", "amount") == 15, "restore debería recuperar la copia")
