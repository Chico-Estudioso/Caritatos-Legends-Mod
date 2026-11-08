extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda del Ratón.

var MouseRules = load(MOD_PATH + "modules/mouse_legend/mouse_rules.gd")


func _init() -> void:
	run_case("quién usa el ratón", "test_mouse_player")
	run_case("en qué panel está el cursor", "test_zone_at")
	run_case("qué eventos llegan a la interfaz", "test_lets_through")
	run_case("cuándo se oculta el cursor", "test_is_recent")
	run_case("a quién se atribuye lo pulsado", "test_claim")
	finish()


func test_mouse_player() -> void:
	check(MouseRules.mouse_player([false, true]) == 0, "J1 con teclado")
	check(MouseRules.mouse_player([true, false, true]) == 1, "J2 con teclado")
	check(MouseRules.mouse_player([true, true]) == 0, "todos con mando: el J1")
	check(MouseRules.mouse_player([]) == 0, "sin jugadores: el J1")


func test_zone_at() -> void:
	var zones := [
		{"player": 0, "rect": Rect2(0, 0, 100, 100)},
		{"player": 1, "rect": Rect2(100, 0, 100, 100)},
		{"player": 1, "rect": Rect2(0, 200, 300, 50)},
		{"player": 0, "rect": Rect2(0, 200, 300, 50)},
	]
	check(MouseRules.zone_at(Vector2(50, 50), zones, 0) == MouseRules.ZONE_OWN, "en su panel")
	check(MouseRules.zone_at(Vector2(150, 50), zones, 0) == MouseRules.ZONE_OTHER, "en el panel del J2")
	check(MouseRules.zone_at(Vector2(150, 50), zones, 1) == MouseRules.ZONE_OWN, "para el J2 es el suyo")
	check(MouseRules.zone_at(Vector2(50, 150), zones, 0) == MouseRules.ZONE_FREE, "fuera de los paneles")
	check(MouseRules.zone_at(Vector2(50, 220), zones, 0) == MouseRules.ZONE_OWN, "un panel compartido también es suyo")
	check(MouseRules.zone_at(Vector2(50, 50), [], 0) == MouseRules.ZONE_FREE, "sin paneles vale todo")


func test_lets_through() -> void:
	check(MouseRules.lets_through(MouseRules.ZONE_OWN, false), "en su panel sí")
	check(MouseRules.lets_through(MouseRules.ZONE_FREE, false), "fuera de los paneles sí")
	check(not MouseRules.lets_through(MouseRules.ZONE_OTHER, false), "en el de otro no")
	check(MouseRules.lets_through(MouseRules.ZONE_OTHER, true), "soltar el botón siempre llega")


func test_is_recent() -> void:
	check(not MouseRules.is_recent(1000, -1, 5), "sin usar el ratón no se ve")
	check(MouseRules.is_recent(6000, 1000, 5), "a los 5 s aún se ve")
	check(not MouseRules.is_recent(6001, 1000, 5), "pasados 5 s se oculta")
	check(MouseRules.is_recent(999999, 1000, 0), "con 0 no se oculta")


func test_claim() -> void:
	check(MouseRules.claim([0], 0) == 0, "su panel")
	check(MouseRules.claim([], 0) == 0, "fuera de los paneles")
	check(MouseRules.claim([1, 0], 0) == 0, "panel compartido")
	check(MouseRules.claim([1], 0) == -1, "solo del J2: no se atribuye")
