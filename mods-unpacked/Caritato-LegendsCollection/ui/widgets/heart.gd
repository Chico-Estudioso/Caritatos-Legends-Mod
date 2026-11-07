extends Control

# Corazón dibujado por código: el símbolo de Caritatopc. Puede latir y brillar.

var color := Color("ff7eb6")
var pulse := false
var glow := true
var _time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect_min_size = Vector2(48, 48)


func _ready() -> void:
	set_process(pulse)


func set_pulse(value: bool) -> void:
	pulse = value
	set_process(value)
	update()


func _process(delta: float) -> void:
	_time += delta
	update()


func _draw() -> void:
	var beat := 1.0
	if pulse:
		# Dos latidos rápidos y una pausa, como un corazón.
		var phase := fmod(_time, 1.2)
		beat = 1.0 + 0.09 * max(0.0, sin(phase * PI / 0.18)) * float(phase < 0.36)
	var center := rect_size / 2.0
	var size: float = min(rect_size.x, rect_size.y) * 0.5 * beat
	if glow:
		# Dos halos claros y translúcidos: brillo, no sombra.
		var light := color.lightened(0.45)
		draw_colored_polygon(heart_points(center, size * 1.3), Color(light.r, light.g, light.b, 0.1), PoolVector2Array(), null, null, true)
		draw_colored_polygon(heart_points(center, size * 1.14), Color(light.r, light.g, light.b, 0.2), PoolVector2Array(), null, null, true)
	draw_colored_polygon(heart_points(center, size), color, PoolVector2Array(), null, null, true)
	var shine := Color(1, 1, 1, 0.35)
	draw_circle(center + Vector2(-size * 0.42, -size * 0.32), size * 0.13, shine)


static func heart_points(center: Vector2, size: float, steps: int = 48) -> PoolVector2Array:
	var points := PoolVector2Array()
	for i in steps:
		var t := TAU * float(i) / float(steps)
		var x := 16.0 * pow(sin(t), 3)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		points.append(center + Vector2(x, -y - 2.5) * (size / 17.0))
	return points
