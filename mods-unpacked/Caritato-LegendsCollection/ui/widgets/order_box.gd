extends Control

# Caja de cartón dibujada por código: tiembla con cada toque (cada vez más
# fuerte) y, al abrirse, la tapa sale volando y brilla por dentro.

const CARDBOARD := Color("c98b4f")
const CARDBOARD_DARK := Color("a8703c")
const CARDBOARD_LIGHT := Color("dda56a")
const TAPE := Color("ead39a")
const GLOW := Color("ffe08a")

var _shake_time := 0.0
var _shake_strength := 0.0
var _opened := false
var _open_time := 0.0
var _time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_process(true)


func shake(level: int) -> void:
	_shake_time = 0.35
	_shake_strength = 4.0 + 4.0 * level


func open() -> void:
	_opened = true
	_open_time = 0.0


func is_open() -> bool:
	return _opened


func _process(delta: float) -> void:
	_time += delta
	_shake_time = max(0.0, _shake_time - delta)
	if _opened:
		_open_time += delta
	update()


func _draw() -> void:
	var size: float = min(rect_size.x, rect_size.y) * 0.62
	var center := rect_size / 2.0 + Vector2(0, size * 0.12)
	var offset := Vector2.ZERO
	if _shake_time > 0.0:
		offset.x = sin(_time * 70.0) * _shake_strength * (_shake_time / 0.35)
	elif not _opened:
		offset.y = sin(_time * 2.2) * 3.0
	var body := Rect2(center + offset - Vector2(size / 2.0, size * 0.38), Vector2(size, size * 0.76))

	if _opened:
		# Brillo que sale de la caja.
		var glow_alpha: float = clamp(_open_time * 2.0, 0.0, 1.0)
		for ring in 3:
			var radius: float = size * (0.45 + 0.18 * ring) * (1.0 + 0.04 * sin(_time * 3.0))
			draw_circle(Vector2(body.position.x + body.size.x / 2.0, body.position.y), radius, Color(GLOW.r, GLOW.g, GLOW.b, 0.12 * glow_alpha))

	draw_rect(body, CARDBOARD)
	draw_rect(Rect2(body.position + Vector2(body.size.x * 0.72, 0), Vector2(body.size.x * 0.28, body.size.y)), CARDBOARD_DARK)
	draw_rect(Rect2(body.position + Vector2(body.size.x * 0.42, 0), Vector2(body.size.x * 0.16, body.size.y)), TAPE)

	var lid_size := Vector2(size * 1.1, size * 0.22)
	var lid_origin := Vector2(body.position.x - size * 0.05, body.position.y - lid_size.y)
	if _opened:
		# La tapa sube, gira y se desvanece.
		var t: float = min(_open_time / 0.6, 1.0)
		var lift := Vector2(size * 0.35 * t, -size * 0.9 * t + size * 0.6 * t * t)
		var alpha := 1.0 - t
		var pivot := lid_origin + lid_size / 2.0 + lift
		draw_set_transform(pivot, 0.9 * t, Vector2.ONE)
		var local := Rect2(-lid_size / 2.0, lid_size)
		draw_rect(local, Color(CARDBOARD_LIGHT.r, CARDBOARD_LIGHT.g, CARDBOARD_LIGHT.b, alpha))
		draw_rect(Rect2(local.position + Vector2(lid_size.x * 0.42, 0), Vector2(lid_size.x * 0.16, lid_size.y)), Color(TAPE.r, TAPE.g, TAPE.b, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_rect(Rect2(lid_origin, lid_size), CARDBOARD_LIGHT)
		draw_rect(Rect2(lid_origin + Vector2(lid_size.x * 0.42, 0), Vector2(lid_size.x * 0.16, lid_size.y)), TAPE)
