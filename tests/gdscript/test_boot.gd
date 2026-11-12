extends "res://tests/gdscript/base_test.gd"

# Arranque completo del núcleo con las leyendas reales del mod y la pantalla
# de configuración. ModLoaderLog, ModLoaderMod y WeaponData se sustituyen por
# los scripts de tests/gdscript/stubs (registrados como clases globales por
# tools/run_gdscript_tests.py). No hay Brotato: las APIs del juego devuelven
# valores neutros a través de core/compat.gd.

const CONFIG_PATH := "user://caritato_legends/settings.json"
const SUPERMARKET_STATE_PATH := "user://caritato_test_supermarket_run.json"
# RunData de mentira con lo que usa el Supermercado.
const FAKE_RUN_DATA := """extends Node
var is_coop_run := false
var is_endless_run := false
var current_wave := 12
var nb_of_waves := 20
var current_difficulty := 3
var bosses_spawn := ["boss_a"]
var elites_spawn := [[11, 0, "elite_a"], [31, 0, "elite_endless"]]
var elites_killed_this_run := []
var bosses_killed_this_run := []
var locked_shop_items := [[], [], [], []]
var gold := 100
func get_player_count() -> int:
	return 1
func get_player_character(_player_index: int):
	return null
func get_player_currency(_player_index: int) -> int:
	return gold
func remove_currency(amount: int, _player_index: int) -> void:
	gold -= amount
func lock_player_shop_item(item, wave: int, player_index: int) -> void:
	locked_shop_items[player_index].push_back([item, wave])
"""

var core = null


# _initialize se ejecuta cuando el árbol de escena ya está listo (a diferencia
# de _init), necesario para añadir el núcleo y la pantalla a la raíz.
func _initialize() -> void:
	_remove_config()
	# Algunas leyendas vienen apagadas por defecto (el Supermercado); para
	# probarlas todas se arranca con todas encendidas.
	_write_all_enabled_config()
	core = load(MOD_PATH + "core/legends_core.gd").new()
	core.name = "LegendsCore"
	root.add_child(core)
	core.boot(MOD_PATH.trim_suffix("/"), "test")

	run_case("todas las leyendas cargan sin errores", "test_all_loaded")
	run_case("se instalan las extensiones de cada leyenda", "test_extensions_installed")
	run_case("los valores por defecto se guardan en disco", "test_defaults_saved")
	run_case("los ajustes se sanean y desactivar es inmediato", "test_settings_and_toggle")
	run_case("la pantalla de configuración se construye y cancela", "test_menu")
	run_case("la pantalla entiende los mandos de cada jugador", "test_menu_coop_actions")
	run_case("el regalo empieza desde el menú del objeto", "test_gift_start")
	run_case("la confirmación del regalo acepta, rechaza y celebra", "test_gift_confirm")
	run_case("los encargos del Supermercado viajan a la siguiente tienda", "test_supermarket_orders")
	run_case("las ventanas de las leyendas se abren de una en una", "test_popup_queue")
	run_case("la caja del encargo se abre a toques", "test_order_box")
	run_case("el minijuego «¡Pica!» premia pescar a tiempo", "test_fishing_popup")
	run_case("el regateo rebaja los artículos de la tienda", "test_haggle")
	run_case("la cosecha dorada solo sale en el modo infinito", "test_golden_harvest")
	run_case("la fusión de cajas se ofrece y se celebra", "test_crates_popup")
	run_case("la fusión de bros elige compañero o ninguno", "test_fusion_popup")
	run_case("el Taller abre «Tus tatos» y el medidor desde sus acciones", "test_studio_screens")
	run_case("el ratón solo actúa en el panel de su jugador", "test_mouse_zones")
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
	var ids: Array = core.get_module_ids()
	check(menu._cards.size() == ids.size(), "falta alguna leyenda en la biblioteca")
	check(menu._detail.id == ids[0], "al abrir debería mostrarse la primera leyenda")

	# Cada ficha se construye con un control por ajuste.
	for module_id in ids:
		menu._select(module_id)
		check(menu._detail.id == module_id, "no se abrió la ficha de %s" % module_id)
		check(menu._detail.controls.size() == core.get_definition(module_id).settings.size(), "%s: faltan ajustes en la ficha" % module_id)

	# Apagar desde el interruptor de la ficha se aplica al momento.
	menu._select(ids[0])
	menu._detail.toggle.pressed = false
	check(not core.is_module_enabled(ids[0]), "el interruptor de la ficha no apaga la leyenda")
	check(menu._cards[ids[0]].label.text == tr("CLC_CARD_OFF"), "la tarjeta no refleja que está apagada")
	menu._detail.toggle.pressed = true
	check(core.is_module_enabled(ids[0]), "el interruptor de la ficha no enciende la leyenda")

	var id: String = ids[0]
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


func _fake_gift_item():
	var fake := GDScript.new()
	fake.source_code = "extends Resource\nvar my_id := \"item_test\"\nvar name := \"ITEM_TEST\"\nvar tier := 1\nvar icon = null\n"
	var _reloaded = fake.reload()
	return fake.new()


func test_menu_coop_actions() -> void:
	# Como en cooperativo: una acción por dispositivo («ui_down_3»).
	if not InputMap.has_action("ui_down_3"):
		InputMap.add_action("ui_down_3")
	var menu = core.open_menu("ingame")
	var device_action := InputEventAction.new()
	device_action.action = "ui_down_3"
	device_action.pressed = true
	check(menu.forwardable_action(device_action) == "ui_down", "«ui_down_3» debería reenviarse como «ui_down»")
	var normal := InputEventAction.new()
	normal.action = "ui_down"
	normal.pressed = true
	check(menu.forwardable_action(normal) == "", "la acción normal no se reenvía (la interfaz ya la entiende)")
	menu._on_cancel_pressed()
	InputMap.erase_action("ui_down_3")


func test_gift_start() -> void:
	var legend = core.get_runtime("gift_legend")
	check(legend != null, "falta el runtime del Regalo")
	if legend == null:
		return
	var item = _fake_gift_item()
	# Sin partida cooperativa no se ofrece «Regalar» en el menú del objeto.
	check(not legend.can_offer(item), "fuera del cooperativo no debería ofrecerse")
	# Si no se puede regalar a nadie, se abre la ventana que lo explica.
	var offer: Dictionary = legend.make_offer(0, item, false)
	offer.recipients = [{"index": 1, "reason": "CLC_GIFT_REASON_INACTIVE"}]
	var picker = load(MOD_PATH + "modules/gift_legend/gift_recipient_popup.gd").new()
	picker.player_index = 0
	picker.offer = offer
	core.show_popup(picker)
	check(picker._choices.size() == 1, "solo debería poder elegirse «Cerrar»")
	picker._on_accept()
	check(picker.result == "cancelled", "«Cerrar» no debería regalar nada")
	core._show_next_popup()

	# Con destinatarios permitidos, elegir uno devuelve «to:<jugador>».
	offer.recipients = [{"index": 1, "reason": ""}, {"index": 2, "reason": "CLC_GIFT_REASON_NO_SLOT"}, {"index": 3, "reason": ""}]
	picker = load(MOD_PATH + "modules/gift_legend/gift_recipient_popup.gd").new()
	picker.player_index = 0
	picker.offer = offer
	core.show_popup(picker)
	check(picker._choices.size() == 3, "dos jugadores elegibles y «Cerrar»")
	picker._on_direction(1)
	picker._on_accept()
	check(picker.result == "to:3", "debería elegirse el jugador 4 (%s)" % picker.result)
	core._show_next_popup()


func test_gift_confirm() -> void:
	var legend = core.get_runtime("gift_legend")
	var offer := {"data": _fake_gift_item(), "is_weapon": false, "label": "Objeto de prueba", "tier": 1, "tags": ["CLC_GIFT_TAG_CURSED"], "recipients": []}

	# Rechazar desde la ventana.
	var confirm = _open_confirm(legend, offer)
	check(confirm._buttons.size() == 2, "deberían verse «Rechazar» y «Aceptar»")
	check(confirm._focus_index == confirm.BUTTON_ACCEPT, "el foco debería empezar en «Aceptar»")
	confirm._activate(confirm.BUTTON_DECLINE)
	check(confirm.result == "declined", "rechazar debería terminar como «declined»")
	check(confirm._buttons[1].disabled, "tras responder no deberían quedar botones")
	confirm.close_popup(confirm.result)
	core._show_next_popup()

	# Aceptar sin partida cooperativa: no se regala y se explica el motivo.
	confirm = _open_confirm(legend, offer)
	confirm.accept()
	check(confirm.result == "CLC_GIFT_REASON_INACTIVE", "sin partida el regalo no debería hacerse (%s)" % confirm.result)
	confirm.close_popup(confirm.result)
	core._show_next_popup()

	# La celebración termina como aceptado.
	confirm = _open_confirm(legend, offer)
	confirm.celebrate()
	check(confirm._title.text == tr("CLC_GIFT_RECEIVED_TITLE"), "falta el título de la celebración")
	check(confirm.result == "accepted", "la celebración debería terminar como aceptado")
	confirm.close_popup(confirm.result)
	core._show_next_popup()


func _open_confirm(legend, offer: Dictionary):
	var confirm = load(MOD_PATH + "modules/gift_legend/gift_confirm.gd").new()
	confirm.setup(legend, null, 0, 1, offer)
	core.show_popup(confirm)
	return confirm


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


func test_supermarket_orders() -> void:
	# reset_defaults() de otras pruebas la deja apagada (viene así por defecto).
	core.set_module_enabled("supermarket_legend", true)
	var legend = core.get_runtime("supermarket_legend")
	check(legend != null, "falta el runtime del Supermercado")
	if legend == null:
		return
	legend.run_state_path = SUPERMARKET_STATE_PATH
	_remove_file(SUPERMARKET_STATE_PATH)
	var fake := GDScript.new()
	fake.source_code = "extends Resource\nvar my_id := \"item_test\"\nvar name := \"ITEM_TEST\"\nvar tier := 0\nvar value := 10\nvar icon = null\n"
	var _reloaded = fake.reload()
	var ordered = fake.new()

	# Por defecto hay que derrotar a un élite o a un jefe.
	legend.on_shop_opened()
	check(legend.block_reason(0) == "CLC_SUPER_ERROR_LOCKED", "sin élite ni jefe no debería poder encargarse")

	# En el modo «en cada tienda» se puede encargar una vez.
	var _stored = core.set_setting("supermarket_legend", "order_mode", "every_shop")
	legend.on_shop_opened()
	check(legend.orders_left(0) == 1, "debería quedar un encargo")
	check(legend.order(null, ordered, 0) == "", "el encargo debería aceptarse")
	check(legend.orders_left(0) == 0, "el encargo debería gastarse")
	check(legend.block_reason(0) == "CLC_SUPER_ERROR_NO_ORDERS", "no debería haber más encargos")

	# Al rerolear, el encargo no aparece en la tienda en la que se hizo.
	var other = fake.new()
	other.my_id = "item_other"
	var locked := [[other, 1], [ordered, 1]]
	var rerolled: Array = legend.filter_reroll_locked(locked, 0)
	check(rerolled.size() == 1 and rerolled[0][0] == other, "el encargo no debería salir al rerolear")

	# En la siguiente tienda llega; si sobran bloqueados, se conserva el encargo.
	legend.on_shop_closed()
	legend.on_shop_opened()
	check(legend.arrivals(0) == 1, "el encargo debería llegar a la siguiente tienda")
	var crowded := []
	for index in 4:
		var extra = fake.new()
		extra.my_id = "item_extra_%d" % index
		crowded.append([extra, 1])
	crowded.append([ordered, 1])
	var fitted: Array = legend.fit_entering_locked(crowded, 0)
	check(fitted.size() == 4, "no debería haber más bloqueados que huecos")
	var kept_order := false
	for entry in fitted:
		if entry[0] == ordered:
			kept_order = true
	check(kept_order, "el encargo pagado debería conservarse")

	_test_supermarket_saved_orders(legend, fake)
	_remove_file(SUPERMARKET_STATE_PATH)
	core.reset_defaults()


# Modo «al derrotar un élite o un jefe» con un RunData de mentira: un
# encargo por oleada con algún élite o jefe derrotado, que se guarda hasta
# gastarlo (también al continuar la partida), y al rerolear el encargo no
# cuenta como bloqueado de la tienda.
func _test_supermarket_saved_orders(legend, fake: GDScript) -> void:
	var _stored = core.set_setting("supermarket_legend", "order_mode", "boss")
	var run_data := _fake_node(FAKE_RUN_DATA)
	run_data.name = "RunData"
	root.add_child(run_data)
	var ordered = fake.new()

	run_data.current_wave = 10
	legend.on_shop_opened()
	check(legend.orders_left(0) == 0, "sin élites ni jefes no hay encargos")
	_next_wave(legend, run_data, 1)
	check(legend.orders_left(0) == 1, "un élite derrotado da un encargo")
	check(legend.is_unlocked(0), "el catálogo debería estar abierto")
	# No lo gasta, pasa otra oleada y derrota a un jefe: se suman.
	_next_wave(legend, run_data, 1)
	check(legend.orders_left(0) == 2, "el encargo sin gastar debería guardarse (%d)" % legend.orders_left(0))
	# Dos jefes en la misma oleada (o uno que el juego cuenta dos veces): uno solo.
	_next_wave(legend, run_data, 2)
	check(legend.orders_left(0) == 3, "dos jefes en la misma oleada dan un solo encargo (%d)" % legend.orders_left(0))
	# Volver a entrar en la misma tienda no suma nada.
	legend.on_shop_opened()
	check(legend.orders_left(0) == 3, "la misma tienda no vuelve a sumar")

	# Al rerolear, el encargo sale un momento de la lista de bloqueados.
	var kept = fake.new()
	kept.my_id = "item_kept"
	run_data.locked_shop_items[0].append([kept, 12])
	check(legend.order(null, ordered, 0) == "", "debería poder encargarse")
	check(legend.orders_left(0) == 2, "quedan dos encargos")
	var live: Array = run_data.locked_shop_items[0]
	check(live.size() == 2 and live[1][0] == ordered, "el encargo va a la lista de bloqueados")
	legend.hold_pending_locks(0)
	check(live.size() == 1 and live[0][0] == kept, "durante el reroll solo cuenta lo bloqueado en la tienda")
	check(legend.filter_reroll_locked(live, 0).size() == 1, "con el encargo apartado no se quita nada más")
	legend.release_pending_locks(0)
	check(live.size() == 2 and live[1][0] == ordered, "tras el reroll el encargo vuelve a la lista")

	# Al continuar la partida (runtime nuevo que lee el archivo), lo gastado sigue gastado.
	var reloaded = load(MOD_PATH + "modules/supermarket_legend/supermarket_legend.gd").new()
	reloaded.setup(core, "supermarket_legend")
	reloaded.run_state_path = SUPERMARKET_STATE_PATH
	reloaded.on_shop_opened()
	check(reloaded.orders_left(0) == 2, "al continuar la partida deberían quedar dos (%d)" % reloaded.orders_left(0))
	reloaded.free()

	# El juego sortea más élites a mitad de partida: sigue siendo la misma.
	run_data.elites_spawn.append([21, 0, "elite_after_wave_10"])
	run_data.bosses_spawn.append("boss_b")
	legend.on_shop_opened()
	check(legend.spent_orders(0) == 1 and legend.orders_left(0) == 2, "cambiar las listas de élites y jefes no cambia la partida")

	# Otra partida (vuelve a la oleada 1, sin bajas) empieza de cero.
	run_data.elites_killed_this_run.clear()
	run_data.bosses_killed_this_run.clear()
	run_data.current_wave = 1
	legend.on_shop_opened()
	check(legend.spent_orders(0) == 0 and legend.orders_left(0) == 0, "en otra partida no hay encargos ganados ni gastados")
	run_data.free()


# Juega una oleada en la que caen `kills` élites o jefes y entra en su tienda.
func _next_wave(legend, run_data: Node, kills: int) -> void:
	legend.on_shop_closed()
	run_data.current_wave += 1
	for kill in kills:
		run_data.bosses_killed_this_run.append(kill)
	legend.on_shop_opened()


func _remove_file(path: String) -> void:
	var dir := Directory.new()
	if dir.file_exists(path):
		var _removed = dir.remove(path)


func test_popup_queue() -> void:
	var popup_script = load(MOD_PATH + "ui/legend_popup.gd")
	var first = popup_script.new()
	var second = popup_script.new()
	core.show_popup(first)
	core.show_popup(second)
	check(first.is_inside_tree(), "la primera ventana debería abrirse")
	check(not second.is_inside_tree(), "la segunda debería esperar en cola")
	first.close_popup("ok")
	core._show_next_popup()
	check(second.is_inside_tree(), "al cerrar la primera debería abrirse la segunda")
	second.close_popup("ok")
	core._show_next_popup()
	check(not core.is_popup_open(), "no deberían quedar ventanas abiertas")


func test_order_box() -> void:
	core.set_module_enabled("supermarket_legend", true)
	var legend = core.get_runtime("supermarket_legend")
	var fake := GDScript.new()
	fake.source_code = "extends Resource\nvar my_id := \"item_box\"\nvar name := \"ITEM_BOX\"\nvar tier := 2\nvar icon = null\n"
	var _reloaded = fake.reload()
	var arrived = fake.new()
	legend._arriving = {0: ["item_box"]}
	var popup = legend.make_arrival_popup([[arrived, 1]], 0)
	check(popup != null, "debería crearse la caja del encargo")
	if popup == null:
		return
	check(popup.items.size() == 1 and popup.items[0].tier == 2, "la caja debería llevar el encargo")
	core.show_popup(popup)
	for _i in 2:
		popup._on_accept()
	check(not popup.is_open(), "con dos toques la caja sigue cerrada")
	popup._on_accept()
	check(popup.is_open(), "al tercer toque la caja se abre")
	popup._on_accept()
	check(popup.is_queued_for_deletion(), "con la caja abierta, aceptar la cierra")
	core._show_next_popup()
	var _stored = core.set_setting("supermarket_legend", "unboxing", false)
	check(legend.make_arrival_popup([[arrived, 1]], 0) == null, "con el ajuste apagado no hay caja")
	legend._arriving = {}
	core.reset_defaults()


func test_fishing_popup() -> void:
	var legend = core.get_runtime("hook_legend")
	check(legend != null, "falta el runtime del Anzuelo")
	if legend == null:
		return
	check(legend.make_fishing_popup(0) == null, "sin Anzuelo garantizado no hay minijuego")

	legend._fishing_pending[0] = true
	var popup = legend.make_fishing_popup(0)
	check(popup != null, "con el Anzuelo garantizado debería salir el minijuego")
	if popup == null:
		return
	check(legend.make_fishing_popup(0) == null, "solo una vez por tienda")
	core.show_popup(popup)
	popup._bite_at = 1.0
	popup._elapsed = 1.2
	popup._on_accept()
	check(popup.result == "caught", "pulsar con el corcho hundido debería pescar (%s)" % popup.result)
	popup.close_popup(popup.result)
	core._show_next_popup()

	legend._fishing_pending[0] = true
	popup = legend.make_fishing_popup(0)
	core.show_popup(popup)
	popup._bite_at = 1.0
	popup._elapsed = 0.4
	popup._on_accept()
	check(popup.result == "early", "pulsar antes de tiempo asusta al pez")
	popup.close_popup(popup.result)
	core._show_next_popup()

	var _stored = core.set_setting("hook_legend", "fishing_minigame", false)
	legend._fishing_pending[0] = true
	check(legend.make_fishing_popup(0) == null, "con el ajuste apagado no hay minijuego")
	core.reset_defaults()


func test_haggle() -> void:
	var legend = core.get_runtime("merchant_legend")
	check(legend != null, "falta el runtime del Mercader")
	if legend == null:
		return
	legend.on_shop_opened()
	check(legend.can_haggle(0), "debería poder regatearse una vez")
	var popup = legend.make_haggle_popup(0)
	check(popup != null, "debería crearse la ventana del regateo")
	if popup == null:
		return
	core.show_popup(popup)
	popup.stop_at("green")
	check(popup.result == "green", "parar en verde debería dar «green»")
	popup.close_popup(popup.result)
	core._show_next_popup()
	check(legend.set_haggle_result(0, "green") == 10, "verde da el descuento máximo")
	check(legend.apply_haggle(40, 0) == 36, "el descuento se aplica al precio")
	check(not legend.can_haggle(0), "solo un intento por tienda")
	check(legend.make_haggle_popup(0) == null, "sin intentos no hay ventana")
	legend.on_shop_closed()
	check(legend.apply_haggle(40, 0) == 40, "al salir de la tienda se acaba el descuento")


func test_golden_harvest() -> void:
	var legend = core.get_runtime("endless_harvest")
	check(legend != null, "falta el runtime de la Cosecha Eterna")
	if legend == null:
		return
	# Sin partida no es el modo infinito: no hay cosecha dorada.
	check(not legend.golden_harvest_enabled(), "fuera del modo infinito no hay cosecha dorada")
	check(legend.make_golden_popup(0) == null, "fuera del modo infinito no hay ventana")
	var popup = load(MOD_PATH + "modules/endless_harvest/harvest_popup.gd").new()
	popup.harvesting = 150
	popup.full_reward = 15
	popup.near_reward = 7
	core.show_popup(popup)
	popup.harvest_at("gold")
	check(popup.result == "gold", "cosechar dorado debería dar «gold»")
	check(popup._hint.text == tr("CLC_HARVEST_GOLDEN_GAIN") % 15, "debería mostrar el premio")
	popup.close_popup(popup.result)
	core._show_next_popup()


func _write_all_enabled_config() -> void:
	var file := File.new()
	if file.open(MOD_PATH + "modules/modules.json", File.READ) != OK:
		return
	var index = parse_json(file.get_as_text())
	file.close()
	var modules := {}
	for id in index.modules:
		modules[id] = {"enabled": true, "settings": {}}
	var _err = Directory.new().make_dir_recursive(CONFIG_PATH.get_base_dir())
	if file.open(CONFIG_PATH, File.WRITE) == OK:
		file.store_string(to_json({"format_version": 1, "modules": modules}))
		file.close()


func _remove_config() -> void:
	var dir := Directory.new()
	if dir.file_exists(CONFIG_PATH):
		var _err = dir.remove(CONFIG_PATH)


func test_crates_popup() -> void:
	var legend = core.get_runtime("crates_legend")
	check(legend != null, "falta el runtime de las Cajas")
	if legend == null:
		return
	legend.on_wave_end(1)
	check(legend.cost_for(0) == 3, "la primera fusión pide 3 cajas")
	check(legend.make_popup(0, 2) == null, "con 2 cajas no se ofrece")
	var popup = legend.make_popup(0, 4)
	check(popup != null, "con 4 cajas se ofrece la fusión")
	if popup == null:
		return
	check(popup.cost == 3 and popup.next_cost == 6, "la ventana sabe lo que cuesta esta y la siguiente")
	core.show_popup(popup)
	popup.fuse()
	check(popup.is_closing() and popup.result == "fused", "fusionar debería dar «fused»")
	popup.close_popup(popup.result)
	core._show_next_popup()
	legend.register_fusion(0, 3)
	check(legend.cost_for(0) == 6, "la siguiente fusión pide 6")
	var later = legend.make_popup(0, 6)
	check(later != null, "con 6 cajas se vuelve a ofrecer")
	if later != null:
		core.show_popup(later)
		later.decline()
		check(later.result == "declined", "«Ahora no» debería dar «declined»")
		core._show_next_popup()
	legend.on_wave_end(1)
	check(legend.cost_for(0) == 3, "una partida nueva vuelve a empezar")


func test_fusion_popup() -> void:
	var legend = core.get_runtime("fusion_legend")
	check(legend != null, "falta el runtime de la Fusión")
	if legend == null:
		return
	# Viene apagada por defecto (y test_settings_and_toggle restaura los valores).
	core.set_module_enabled("fusion_legend", true)
	check(legend.should_offer(1), "se ofrece al empezar la partida")
	check(not legend.should_offer(2), "no se ofrece en otras oleadas")
	check(legend.penalties().size() == 4, "cuatro penalizaciones por defecto")
	# Sin juego no hay personajes: no hay ventana.
	check(legend.make_popup(0) == null, "sin personajes no se ofrece nada")
	var popup = load(MOD_PATH + "modules/fusion_legend/fusion_popup.gd").new()
	popup.partners = [
		{"id": "a", "name": "Uno", "icon": null, "text": "+5 vida"},
		{"id": "b", "name": "Dos", "icon": null, "text": "+10 % daño"},
	]
	popup.penalties = legend.penalties()
	core.show_popup(popup)
	popup._move(1, 0)
	check(popup.selected() == 1, "a la derecha elige el segundo")
	popup.fuse()
	check(popup.result == "partner:1", "fusionar devuelve el compañero elegido")
	popup.close_popup(popup.result)
	core._show_next_popup()
	var empty = load(MOD_PATH + "modules/fusion_legend/fusion_popup.gd").new()
	empty.partners = [{"id": "a", "name": "Uno", "icon": null, "text": ""}]
	core.show_popup(empty)
	empty.choose_none()
	check(empty.result == "none", "«Sin fusión» devuelve «none»")
	core._show_next_popup()


func test_studio_screens() -> void:
	var definition: Dictionary = core.get_definition("studio_legend")
	check(definition.actions.size() == 3, "el Taller tiene tres acciones")
	var legend = core.get_runtime("studio_legend")
	check(legend != null, "falta el runtime del Taller")
	if legend == null:
		return
	check(not legend.broeditor_loaded(), "sin BroEditor en las pruebas")
	var menu = core.open_menu("title")
	menu._select("studio_legend")
	check(menu._detail.actions.size() == 3, "la ficha muestra las tres acciones")
	menu._on_action_pressed("studio_legend", "open_tatos")
	var editor = menu.overlay
	check(editor != null and editor.has_method("save_tato"), "se abre «Tus tatos»")
	if editor != null:
		legend.store = load(MOD_PATH + "modules/studio_legend/tato_store.gd").new("user://caritato_test_boot_tatos/")
		editor.store = legend.store
		editor.canvas().apply_at(Vector2(10, 10))
		var id: String = editor.save_tato()
		check(id != "" and legend.store.list().size() == 1, "se guarda el tato")
		editor.toggle_worn(0)
		check(legend.worn_texture(0) != null, "J1 lo lleva puesto en las partidas")
		editor.delete_tato()
		check(legend.store.list().empty(), "se borra el tato")
		editor.close_screen()
	menu._on_action_pressed("studio_legend", "open_power_meter")
	var meter = menu.overlay
	check(meter != null and meter.has_method("show_kind"), "se abre el medidor de poder")
	if meter != null:
		check(meter.entries_for("characters").empty(), "sin juego no hay personajes que medir")
		meter.close_screen()
	menu.close()


# Cooperativo de mentira: un RunData con dos jugadores y dos FocusEmulator con
# un panel cada uno. Nadie usa teclado (no hay CoopService), así que el ratón
# es del J1.
func test_mouse_zones() -> void:
	var legend = core.get_runtime("mouse_legend")
	check(legend != null, "falta el runtime del Ratón")
	if legend == null:
		return
	var run_data := _fake_node("extends Node\nvar is_coop_run := true\nfunc get_player_count() -> int:\n\treturn 2\n")
	run_data.name = "RunData"
	root.add_child(run_data)
	var screen := Control.new()
	root.add_child(screen)
	var panels := []
	var emulators := []
	for player_index in 2:
		var panel := Control.new()
		panel.rect_position = Vector2(200 * player_index, 0)
		panel.rect_size = Vector2(200, 200)
		screen.add_child(panel)
		var button := Button.new()
		button.rect_size = Vector2(50, 50)
		panel.add_child(button)
		panels.append(panel)
		var emulator := _fake_node("extends Node2D\nvar player_index := -1\nvar _focus_base_nodes := []\n")
		emulator.player_index = player_index
		emulator._focus_base_nodes = [panel]
		screen.add_child(emulator)
		emulators.append(emulator)
	legend.emulators_override = emulators

	check(legend.coop_mouse_enabled(), "debería verse como cooperativo")
	check(legend.mouse_player() == 0, "sin teclado, el ratón es del J1")
	check(legend.visible_zones().size() == 2, "dos paneles visibles")

	legend._input(_mouse_press(Vector2(300, 50)))
	check(not legend._mouse_event_pending, "en el panel del J2 no se puede pulsar")
	legend._input(_mouse_press(Vector2(50, 50)))
	check(legend._mouse_event_pending, "en su panel sí")
	check(legend.should_show(), "tras usarlo, el cursor se ve")
	check(legend.claim_player(panels[0].get_child(0), -1) == 0, "lo pulsado en su panel es del J1")
	check(legend.claim_player(panels[1].get_child(0), -1) == -1, "lo del panel del J2 no se le atribuye")
	legend._process(0.0)
	check(legend.claim_player(panels[0].get_child(0), -1) == -1, "pasado el fotograma ya no es cosa del ratón")

	# Con los FocusEmulator ocultos (pausa, ventanas de Caritatopc) vale todo.
	for emulator in emulators:
		emulator.visible = false
	check(legend.visible_zones().empty(), "sin paneles visibles")
	legend._input(_mouse_press(Vector2(300, 50)))
	check(legend._mouse_event_pending, "con la pausa se puede pulsar en cualquier sitio")
	legend._process(0.0)

	legend.emulators_override = null
	screen.free()
	run_data.free()
	check(not legend.coop_mouse_enabled(), "sin RunData vuelve a ser solitario")


func _fake_node(source: String) -> Node:
	var script := GDScript.new()
	script.source_code = source
	var _err = script.reload()
	return script.new()


func _mouse_press(position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = BUTTON_LEFT
	event.pressed = true
	event.position = position
	return event
