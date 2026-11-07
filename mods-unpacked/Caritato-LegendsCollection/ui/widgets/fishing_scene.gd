extends Control

# Escena de pesca dibujada por código para La Leyenda del Anzuelo: agua con
# olas, sedal y corcho. Estados: «waiting» (el corcho flota), «bite» (se
# hunde y salen ondas), «caught» (salta un pez) y «missed» (todo vuelve a la
# calma).

const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")

const WATER := Color("1d5b85")
const WATER_DEEP := Color("123a59")
const FOAM := Color(1, 1, 1, 0.45)
const BOBBER_RED := Color("ff5c6c")
const BOBBER_WHITE := Color("f5f2ff")
const FISH := Color("ffc845")

var state := "waiting"
var _time := 0.0
var _state_time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_process(true)


func set_state(value: String) -> void:
	state = value
	_state_time = 0.0


func _process(delta: float) -> void:
	_time += delta
	_state_time += delta
	update()


func _draw() -> void:
	var width: float = min(rect_size.x, 700.0)
	var area := Rect2(Vector2((rect_size.x - width) / 2.0, 0), Vector2(width, rect_size.y))
	var water_y := area.position.y + area.size.y * 0.5

	# Agua
	draw_style_box(UiStyle.box(WATER_DEEP, 26, Vector2.ZERO), Rect2(area.position.x, water_y, area.size.x, area.end.y - water_y))
	draw_rect(Rect2(area.position.x + 12, water_y + 6, area.size.x - 24, 18), Color(WATER.r, WATER.g, WATER.b, 0.6))
	var wave := PoolVector2Array()
	var steps := 48
	for i in steps + 1:
		var x := area.position.x + 14.0 + (area.size.x - 28.0) * float(i) / steps
		wave.append(Vector2(x, water_y + sin(x * 0.035 + _time * 2.2) * 4.0))
	draw_polyline(wave, FOAM, 3.0, true)

	# Corcho
	var bobber_x := area.position.x + area.size.x / 2.0
	var bobber_y := water_y - 4.0 + sin(_time * 2.6) * 4.0
	if state == "bite":
		bobber_y = water_y + 14.0 + sin(_time * 30.0) * 3.0
		for ring in 3:
			var radius := 14.0 + fmod(_state_time * 70.0 + ring * 18.0, 60.0)
			var alpha := 1.0 - radius / 74.0
			draw_arc(Vector2(bobber_x, water_y + 2), radius, PI, TAU, 24, Color(1, 1, 1, alpha * 0.8), 2.0, true)
	elif state == "caught":
		bobber_y = water_y - 30.0 - 30.0 * min(_state_time / 0.4, 1.0)

	# Sedal
	draw_line(Vector2(bobber_x, area.position.y), Vector2(bobber_x, bobber_y - 14.0), Color(1, 1, 1, 0.55), 2.0, true)
	draw_circle(Vector2(bobber_x, bobber_y), 15.0, BOBBER_WHITE)
	var top := PoolVector2Array()
	for i in 17:
		var angle := PI + PI * float(i) / 16.0
		top.append(Vector2(bobber_x, bobber_y) + Vector2(cos(angle), sin(angle)) * 15.0)
	draw_colored_polygon(top, BOBBER_RED, PoolVector2Array(), null, null, true)

	# Pez que salta
	if state == "caught":
		var t: float = min(_state_time / 0.9, 1.0)
		var fish_pos := Vector2(bobber_x + 120.0 * (t - 0.5), water_y - 140.0 * sin(t * PI))
		_draw_fish(fish_pos, 1.0 - 2.0 * t, 34.0)


func _draw_fish(center: Vector2, tilt: float, size: float) -> void:
	draw_set_transform(center, -0.6 * tilt, Vector2.ONE)
	var body := PoolVector2Array()
	for i in 24:
		var angle := TAU * float(i) / 24.0
		body.append(Vector2(cos(angle) * size, sin(angle) * size * 0.5))
	draw_colored_polygon(body, FISH, PoolVector2Array(), null, null, true)
	var tail := PoolVector2Array([Vector2(-size * 0.9, 0), Vector2(-size * 1.5, -size * 0.45), Vector2(-size * 1.5, size * 0.45)])
	draw_colored_polygon(tail, FISH.darkened(0.15), PoolVector2Array(), null, null, true)
	draw_circle(Vector2(size * 0.5, -size * 0.1), size * 0.09, UiStyle.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
