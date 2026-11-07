extends "res://tests/gdscript/base_test.gd"

# El Taller de los Tatos: medidor de poder, tatos guardados y lienzo.

const TEST_DIR := "user://caritato_test_tatos/"
const ICON_DIR := "user://caritato_test_icons/"

var PowerRules = load(MOD_PATH + "modules/studio_legend/power_rules.gd")
var TatoStore = load(MOD_PATH + "modules/studio_legend/tato_store.gd")
var PixelCanvas = load(MOD_PATH + "ui/widgets/pixel_canvas.gd")


func _init() -> void:
	run_case("signo de los efectos", "test_goodness")
	run_case("puntuación de efectos", "test_scores")
	run_case("etiqueta frente a los del juego", "test_rating")
	run_case("identificadores de tatos", "test_make_id")
	run_case("imágenes de 50, 150 y 96 píxeles", "test_images")
	run_case("guardar, listar, llevar puesto y borrar", "test_store")
	run_case("lienzo: pintar, rellenar, cuentagotas y deshacer", "test_canvas")
	_remove_dir(TEST_DIR)
	_remove_dir(ICON_DIR)
	finish()


func test_goodness() -> void:
	check(PowerRules.goodness(PowerRules.SIGN_POSITIVE, -3) == 1, "positivo siempre ayuda")
	check(PowerRules.goodness(PowerRules.SIGN_NEGATIVE, 5) == -1, "negativo siempre perjudica")
	check(PowerRules.goodness(PowerRules.SIGN_NEUTRAL, 5) == 0, "neutro no cuenta")
	check(PowerRules.goodness(3, 5) == 1 and PowerRules.goodness(3, -5) == -1, "según el valor")


func test_scores() -> void:
	check(PowerRules.effect_score("stat_armor", 2, 3) == 5.0, "+2 armadura = 5 puntos")
	check(PowerRules.effect_score("stat_armor", -2, 3) == -5.0, "-2 armadura resta")
	check(PowerRules.effect_score("efecto_raro", 100, 3) == 25 * PowerRules.DEFAULT_WEIGHT, "lo desconocido tiene tope")
	var total: float = PowerRules.total([["stat_max_hp", 10, 3], ["stat_speed", -10, 3]])
	check(abs(total - 1.0) < 0.001, "se suman con su peso")


func test_rating() -> void:
	var baseline := [0.0, 5.0, 10.0, 15.0, 20.0]
	check(PowerRules.rating(8.0, baseline) == PowerRules.RATING_BALANCED, "por debajo del percentil 75")
	check(PowerRules.rating(18.0, baseline) == PowerRules.RATING_STRONG, "hasta el más fuerte")
	check(PowerRules.rating(25.0, baseline) == PowerRules.RATING_VERY_STRONG, "hasta un 50 % más")
	check(PowerRules.rating(40.0, baseline) == PowerRules.RATING_BROKEN, "mucho más: roto")
	check(PowerRules.rating(40.0, []) == PowerRules.RATING_BALANCED, "sin referencia no se juzga")
	check(PowerRules.bar_fraction(5.0, 20.0) == 0.25, "barra proporcional")


func test_make_id() -> void:
	check(TatoStore.make_id("Mi Tato Morado") == "mi_tato_morado", "minúsculas y guiones bajos")
	check(TatoStore.make_id("Patatón ñ!") == "pataton_n", "sin tildes ni símbolos")
	check(TatoStore.make_id("¿?") == "tato", "nombre vacío")


func test_images() -> void:
	var big := Image.new()
	big.create(200, 100, false, Image.FORMAT_RGBA8)
	big.fill(Color(1, 0, 0))
	var normalized: Image = TatoStore.normalized(big)
	check(normalized.get_width() == 50 and normalized.get_height() == 50, "se lleva a 50 × 50")
	normalized.lock()
	check(normalized.get_pixel(25, 25).r > 0.9 and normalized.get_pixel(25, 2).a == 0.0, "mantiene la proporción y centra")
	normalized.unlock()
	check(TatoStore.overlay_image(normalized).get_width() == 150, "encima de la patata mide 150")
	check(TatoStore.icon_image(normalized, null).get_width() == 96, "el icono mide 96")


func test_store() -> void:
	_remove_dir(TEST_DIR)
	var store = TatoStore.new(TEST_DIR)
	check(store.list().empty(), "empieza vacío")
	var image := Image.new()
	image.create(50, 50, false, Image.FORMAT_RGBA8)
	image.fill(Color("a970ff"))
	check(store.save("bro", "Bro Morado", image) == OK, "se guarda")
	var entries: Array = store.list()
	check(entries.size() == 1 and entries[0].name == "Bro Morado", "aparece en la lista con su nombre")
	check(store.load_image("bro") != null, "se vuelve a abrir")
	store.set_worn(1, "bro")
	check(store.worn_by(1) == "bro" and store.worn_by(0) == "", "J2 lo lleva puesto")
	check(store.export_icon("bro", image, null, ICON_DIR) == "caritato_bro.png", "icono para BroEditor")
	check(File.new().file_exists(ICON_DIR + "caritato_bro.png"), "el icono existe")
	store.delete("bro")
	check(store.list().empty() and store.worn_by(1) == "", "al borrarlo nadie lo lleva")


func test_canvas() -> void:
	var canvas = PixelCanvas.new()
	canvas.color = Color(1, 0, 0)
	canvas.apply_at(Vector2(3, 4))
	check(canvas.pixel(Vector2(3, 4)).r == 1.0, "el lápiz pinta")
	canvas.tool = PixelCanvas.TOOL_FILL
	canvas.color = Color(0, 0, 1)
	canvas.apply_at(Vector2(0, 0))
	check(canvas.pixel(Vector2(49, 49)).b == 1.0 and canvas.pixel(Vector2(3, 4)).r == 1.0, "el relleno respeta lo pintado")
	canvas.undo()
	check(canvas.pixel(Vector2(49, 49)).a == 0.0, "deshacer quita el relleno")
	canvas.tool = PixelCanvas.TOOL_PICKER
	canvas.apply_at(Vector2(3, 4))
	check(canvas.color.r == 1.0, "el cuentagotas coge el color")
	canvas.cursor = Vector2(49, 0)
	canvas.move_cursor(5, -5)
	check(canvas.cursor == Vector2(49, 0), "el cursor no se sale")
	canvas.free()


func _remove_dir(path: String) -> void:
	var directory := Directory.new()
	if directory.open(path) != OK:
		return
	var _err = directory.list_dir_begin(true, true)
	var file_name := directory.get_next()
	while file_name != "":
		var _removed = directory.remove(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()
	var _removed_dir = Directory.new().remove(path)
