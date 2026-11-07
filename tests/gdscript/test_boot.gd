extends "res://tests/gdscript/base_test.gd"

# Arranque completo del núcleo con las leyendas reales del mod y la pantalla
# de configuración. ModLoaderLog, ModLoaderMod y WeaponData se sustituyen por
# los scripts de tests/gdscript/stubs (registrados como clases globales por
# tools/run_gdscript_tests.py). No hay Brotato: las APIs del juego devuelven
# valores neutros a través de core/compat.gd.

const CONFIG_PATH := "user://caritato_legends/settings.json"

var core = null


# _initialize se ejecuta cuando el árbol de escena ya está listo (a diferencia
# de _init), necesario para añadir el núcleo y la pantalla a la raíz.
func _initialize() -> void:
	_remove_config()
	core = load(MOD_PATH + "core/legends_core.gd").new()
	core.name = "LegendsCore"
	root.add_child(core)
	core.boot(MOD_PATH.trim_suffix("/"), "test")

	run_case("todas las leyendas cargan sin errores", "test_all_loaded")
	run_case("se instalan las extensiones de cada leyenda", "test_extensions_installed")
	run_case("los valores por defecto se guardan en disco", "test_defaults_saved")
	run_case("los ajustes se sanean y desactivar es inmediato", "test_settings_and_toggle")
	run_case("la pantalla de configuración se construye y cancela", "test_menu")
	run_case("la ventana de regalos se construye y se cierra", "test_gift_menu")
	run_case("una leyenda desactivada al arrancar no se carga", "test_disabled_not_loaded")
	_remove_config()
	finish()


func test_all_loaded() -> void:
	var ids: Array = core.get_module_ids()
	check(not ids.empty(), "no hay leyendas registradas")
	for id in ids:
		var state: Dictionary = core.get_boot_state(id)
		check(state.state == "loaded", "%s: %s (%s %s)" % [id, state.state, state.reason, state.detail])
		check(core.is_module_active(id), "%s debería estar activa" % id)
		if core.get_definition(id).runtime != "":
			check(core.get_runtime(id) != null, "%s no tiene runtime" % id)


func test_extensions_installed() -> void:
	# Tras boot() (equivale a mod_main._init) solo están las de autoloads.
	var during_init: Array = ModLoaderMod.installed_extensions().duplicate()
	var pending: Array = core.get_pending_late_extensions()
	for id in core.get_module_ids():
		var definition: Dictionary = core.get_definition(id)
		for extension in definition.extensions:
			var path: String = definition.dir.plus_file(extension)
			var early: bool = extension.begins_with("extensions/singletons/")
			check(during_init.has(path) == early, "%s: %s debería instalarse %s" % [id, path, "en _init" if early else "en _ready"])

	# install_late_extensions() (equivale a mod_main._ready) instala el resto,
	# con base_shop.gd antes que cualquier otra.
	core.install_late_extensions()
	var installed: Array = ModLoaderMod.installed_extensions()
	for id in core.get_module_ids():
		var definition: Dictionary = core.get_definition(id)
		for extension in definition.extensions:
			var path: String = definition.dir.plus_file(extension)
			check(installed.has(path), "%s: falta instalar %s" % [id, path])
	var late_installed: Array = installed.slice(during_init.size(), installed.size() - 1) if installed.size() > during_init.size() else []
	var seen_other := false
	for path in late_installed:
		if path.ends_with("ui/menus/shop/base_shop.gd"):
			check(not seen_other, "base_shop.gd debe instalarse antes que otras extensiones tardías")
		else:
			seen_other = true
	check(late_installed.size() == pending.size(), "se esperaban %d extensiones tardías" % pending.size())
	check(core.get_pending_late_extensions().empty(), "no deberían quedar extensiones pendientes")


func test_defaults_saved() -> void:
	check(File.new().file_exists(CONFIG_PATH), "no se creó settings.json")
	for id in core.get_module_ids():
		for setting in core.get_definition(id).settings:
			check(core.get_setting(id, setting.key) == setting.default, "%s.%s no tiene su valor por defecto" % [id, setting.key])


func test_settings_and_toggle() -> void:
	for id in core.get_module_ids():
		for setting in core.get_definition(id).settings:
			if setting.type == "int":
				check(core.set_setting(id, setting.key, setting.max + 1000) == setting.max, "%s.%s no se limita al máximo" % [id, setting.key])
		core.set_module_enabled(id, false)
		check(core.is_module_loaded(id), "%s debería seguir cargada" % id)
		check(not core.is_module_active(id), "%s debería dejar de estar activa" % id)
		check(not core.needs_restart(id), "desactivar no requiere reinicio")
		core.set_module_enabled(id, true)
		check(core.is_module_active(id), "%s debería volver a estar activa" % id)
	core.reset_defaults()


func test_menu() -> void:
	var menu = core.open_menu("ingame")
	check(menu != null, "no se abrió la pantalla")
	if menu == null:
		return
	check(core.is_menu_open(), "el núcleo no registra la pantalla abierta")
	check(menu._rows.size() == core.get_module_ids().size(), "falta alguna leyenda en la pantalla")

	var id: String = core.get_module_ids()[0]
	var setting: Dictionary = {}
	for candidate in core.get_definition(id).settings:
		if candidate.type == "int":
			setting = candidate
			break
	if not setting.empty():
		menu._on_number_changed(float(setting.max), id, setting.key)
		check(core.get_setting(id, setting.key) == setting.max, "el deslizador no aplica el valor")
		menu._on_cancel_pressed()
		check(core.get_setting(id, setting.key) == setting.default, "cancelar debería deshacer el cambio")
	else:
		menu._on_cancel_pressed()
	check(not core.is_menu_open(), "la pantalla debería cerrarse")


func test_gift_menu() -> void:
	var legend = core.get_runtime("gift_legend")
	check(legend != null, "falta el runtime del Regalo")
	if legend == null:
		return
	# Sin partida, no hay nada que regalar y ninguna oferta debe fallar.
	check(legend.get_offers(0).empty(), "sin partida no debería haber ofertas")
	var before: int = root.get_child_count()
	legend.open_menu(null, 0, null)
	check(root.get_child_count() == before + 1, "no se abrió la ventana")
	var menu = root.get_child(root.get_child_count() - 1)
	check(menu._nav.size() == 1, "solo debería poder enfocarse «Cerrar»")
	menu._move_focus(1)
	menu._press_focused()
	check(menu.is_queued_for_deletion(), "«Cerrar» debería cerrar la ventana")


func test_disabled_not_loaded() -> void:
	var id: String = core.get_module_ids()[0]
	core.set_module_enabled(id, false)
	check(core.save_config(), "no se pudo guardar")

	var second = load(MOD_PATH + "core/legends_core.gd").new()
	second.boot(MOD_PATH.trim_suffix("/"), "test")
	check(second.get_boot_state(id).state == "disabled", "debería arrancar desactivada")
	check(second.get_runtime(id) == null, "no debería crear su runtime")
	second.set_module_enabled(id, true)
	check(second.needs_restart(id), "activarla debería pedir reinicio")
	second.free()
	core.set_module_enabled(id, true)
	var _saved = core.save_config()


func _remove_config() -> void:
	var dir := Directory.new()
	if dir.file_exists(CONFIG_PATH):
		var _err = dir.remove(CONFIG_PATH)
