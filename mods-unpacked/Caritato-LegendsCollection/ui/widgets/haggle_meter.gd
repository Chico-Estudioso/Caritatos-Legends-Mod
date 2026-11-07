extends Control

# Barra de regateo dibujada por código: zona roja, amarilla y verde, y una
# aguja que va y viene. stop() la detiene y devuelve dónde ha parado (0..1).

const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")

const RED := Color("ff6b6b")
const YELLOW := Color("ffc845")
const GREEN := Color("7ddc8a")

var green_center := 0.5
var green_half := 0.06
var yellow_half := 0.16
var speed := 1.15
var position := 0.0
var _direction := 1.0
var _stopped := false
var _time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_process(true)


func stop() -> float:
	_stopped = true
	return position


func is_stopped() -> bool:
	return _stopped


func _process(delta: float) -> void:
	_time += delta
	if not _stopped:
		position += _direction * speed * delta
		if position >= 1.0:
			position = 1.0
			_direction = -1.0
		elif position <= 0.0:
			position = 0.0
			_direction = 1.0
	update()


func _draw() -> void:
	var width: float = min(rect_size.x, 680.0)
	var bar := Rect2(Vector2((rect_size.x - width) / 2.0, rect_size.y / 2.0 - 22.0), Vector2(width, 44.0))
	draw_style_box(UiStyle.box(Color(RED.r, RED.g, RED.b, 0.75), 22, Vector2.ZERO), bar)
	_draw_zone(bar, green_center - yellow_half, green_center + yellow_half, YELLOW)
	_draw_zone(bar, green_center - green_half, green_center + green_half, GREEN)
	draw_style_box(UiStyle.ring(UiStyle.TEXT, 22, 2), bar)

	var x := bar.position.x + bar.size.x * position
	var pulse := 1.0 if _stopped else 0.85 + 0.15 * sin(_time * 12.0)
	var needle := PoolVector2Array([
		Vector2(x, bar.position.y + 6.0),
		Vector2(x - 12.0 * pulse, bar.position.y - 20.0),
		Vector2(x + 12.0 * pulse, bar.position.y - 20.0),
	])
	draw_colored_polygon(needle, UiStyle.TEXT, PoolVector2Array(), null, null, true)
	draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y), UiStyle.TEXT, 4.0, true)


func _draw_zone(bar: Rect2, from: float, to: float, color: Color) -> void:
	var start: float = clamp(from, 0.0, 1.0)
	var end: float = clamp(to, 0.0, 1.0)
	var rect := Rect2(bar.position.x + bar.size.x * start, bar.position.y + 4.0, bar.size.x * (end - start), bar.size.y - 8.0)
	draw_style_box(UiStyle.box(color, 14, Vector2.ZERO), rect)
