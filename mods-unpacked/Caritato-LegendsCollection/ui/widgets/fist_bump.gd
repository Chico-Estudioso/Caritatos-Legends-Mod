extends Control

# Choque de puños dibujado por código: el símbolo de Caritatopc (cosas de bros).
# Dos puños de lado, uno de cada color, con un destello al chocar. Con animate
# se acercan, chocan y se separan sin parar; bump() fuerza un choque grande.
# Las formas están en unidades: el frente de los nudillos queda en x = 0.

const CYCLE := 1.8
const CONTACT := 0.3
const APART := 16.0
# [x0, y0, x1, y1, radio] de cada pieza del puño izquierdo (apunta a +x).
const SLEEVE := [-104.0, -25.0, -78.0, 23.0, 7.0]
const WRIST := [-84.0, -18.0, -52.0, 16.0, 6.0]
const PALM := [-62.0, -30.0, -16.0, 27.0, 15.0]
const FINGERS := [
	[-30.0, -31.0, 0.0, -17.0, 7.0],
	[-30.0, -17.0, 0.0, -3.0, 7.0],
	[-30.0, -3.0, 0.0, 11.0, 7.0],
	[-30.0, 11.0, -3.0, 25.0, 7.0],
]
const THUMB := [-56.0, -21.0, -24.0, -8.0, 6.5]
const OUTLINE := 2.6

var color := Color("a970ff")
var color_right := Color("d7bcff")
var spark_color := Color("ffd166")
var animate := false
var _time := 0.0
var _boost := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect_min_size = Vector2(96, 50)


func _ready() -> void:
	set_process(animate)


func set_animate(value: bool) -> void:
	animate = value
	set_process(value or _boost > 0.0)
	update()


# Choque con un destello más grande (al aceptar un regalo, por ejemplo).
func bump() -> void:
	_time = CONTACT - 0.06
	_boost = 0.8
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	_boost = max(0.0, _boost - delta * 0.7)
	if not animate and _boost <= 0.0:
		_time = CONTACT
		set_process(false)
	update()


# Separación de los puños y tamaño del destello según el momento del ciclo.
static func pose(time: float, animated: bool) -> Vector2:
	if not animated:
		return Vector2(0.0, 1.0)
	var phase := fmod(time, CYCLE)
	var gap := APART
	if phase < CONTACT:
		var approach := phase / CONTACT
		gap = APART * (1.0 - approach * approach)
	elif phase < CONTACT + 0.12:
		gap = 0.0
	elif phase < CONTACT + 0.6:
		var back := 1.0 - (phase - CONTACT - 0.12) / 0.48
		gap = APART * (1.0 - back * back)
	var spark := 0.0
	if phase >= CONTACT and phase < CONTACT + 0.5:
		var fade := (phase - CONTACT) / 0.5
		spark = (1.0 - fade) * (0.6 + 0.6 * min(1.0, fade * 6.0))
	return Vector2(gap, spark)


func _draw() -> void:
	var state: Vector2 = pose(_time, animate or _boost > 0.0)
	var unit: float = min(rect_size.x / 240.0, rect_size.y / 124.0)
	var center := rect_size / 2.0
	var spark: float = state.y * (1.0 + _boost)
	if spark > 0.01:
		_draw_spark(center, unit, spark)
	_draw_fist(center, unit, state.x, 1.0, color)
	_draw_fist(center, unit, state.x, -1.0, color_right)


func _draw_spark(center: Vector2, unit: float, scale: float) -> void:
	var tint := spark_color
	tint.a = clamp(scale, 0.0, 1.0)
	draw_colored_polygon(star_points(center, 44.0 * unit * scale, 20.0 * unit * scale, 8), tint, PoolVector2Array(), null, null, true)
	for angle in [-62.0, -90.0, -118.0, 62.0, 90.0, 118.0]:
		var direction: Vector2 = Vector2(cos(deg2rad(angle)), sin(deg2rad(angle)))
		draw_line(center + direction * 50.0 * unit * scale, center + direction * 62.0 * unit * scale, tint, max(2.0, 4.5 * unit), true)


func _draw_fist(center: Vector2, unit: float, gap: float, side: float, tint: Color) -> void:
	var outline := tint.darkened(0.62)
	var pieces := [
		[SLEEVE, tint.darkened(0.42)],
		[WRIST, tint.darkened(0.12)],
		[PALM, tint],
	]
	for finger in FINGERS:
		pieces.append([finger, tint])
	pieces.append([THUMB, tint.lightened(0.16)])
	for piece in pieces:
		var shape: Array = piece[0]
		draw_colored_polygon(_piece_points(shape, OUTLINE, center, unit, gap, side), outline, PoolVector2Array(), null, null, true)
		draw_colored_polygon(_piece_points(shape, 0.0, center, unit, gap, side), piece[1], PoolVector2Array(), null, null, true)
	# Brillo sobre los nudillos.
	draw_colored_polygon(_piece_points([-56.0, -27.0, -40.0, -24.0, 1.5], 0.0, center, unit, gap, side), Color(1, 1, 1, 0.35), PoolVector2Array(), null, null, true)


func _piece_points(shape: Array, grow: float, center: Vector2, unit: float, gap: float, side: float) -> PoolVector2Array:
	var local: PoolVector2Array = rounded_rect_points(shape[0] - grow, shape[1] - grow, shape[2] + grow, shape[3] + grow, shape[4] + grow)
	var points := PoolVector2Array()
	for point in local:
		points.append(center + Vector2(side * (point.x - gap), point.y) * unit)
	return points


static func rounded_rect_points(x0: float, y0: float, x1: float, y1: float, radius: float, steps: int = 6) -> PoolVector2Array:
	var points := PoolVector2Array()
	var corners := [Vector2(x1 - radius, y0 + radius), Vector2(x1 - radius, y1 - radius), Vector2(x0 + radius, y1 - radius), Vector2(x0 + radius, y0 + radius)]
	for i in corners.size():
		var start: float = -90.0 + 90.0 * i
		for step in steps + 1:
			var angle: float = deg2rad(start + 90.0 * step / steps)
			points.append(corners[i] + Vector2(cos(angle), sin(angle)) * radius)
	return points


static func star_points(center: Vector2, outer: float, inner: float, tips: int = 5, rotation: float = 0.0) -> PoolVector2Array:
	var points := PoolVector2Array()
	for i in tips * 2:
		var radius: float = outer if i % 2 == 0 else inner
		var angle: float = rotation + PI * i / tips - PI / 2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
