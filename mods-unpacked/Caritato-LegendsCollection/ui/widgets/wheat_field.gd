extends Control

# Campo de trigo dibujado por código para La Leyenda de la Cosecha Eterna.
# La madurez sube despacio hasta el dorado y cae deprisa, sin parar;
# harvest() la congela y las espigas se doblan. ripeness va de 0 a 1.

const GREEN := Color("7ddc8a")
const GOLD := Color("ffc845")
const SOIL := Color("4a3424")

var ripeness := 0.0
var period := 2.0
var _time := 0.0
var _harvested := false
var _harvest_time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_process(true)


func harvest() -> float:
	_harvested = true
	_harvest_time = 0.0
	return ripeness


func is_harvested() -> bool:
	return _harvested


func color_for(value: float) -> Color:
	var color := GREEN.linear_interpolate(GOLD, clamp(value / 0.85, 0.0, 1.0))
	return color.lightened(0.25) if value >= 0.85 else color


func _process(delta: float) -> void:
	_time += delta
	if _harvested:
		_harvest_time += delta
	else:
		# Sube despacio y cae deprisa: el punto dorado dura poco.
		var phase := fmod(_time, period) / period
		ripeness = phase / 0.8 if phase < 0.8 else 1.0 - (phase - 0.8) / 0.2
		ripeness = clamp(ripeness, 0.0, 1.0)
	update()


func _draw() -> void:
	var width: float = min(rect_size.x, 640.0)
	var left := (rect_size.x - width) / 2.0
	var ground := rect_size.y - 26.0
	var soil := Rect2(left, ground, width, 18.0)
	draw_rect(soil, SOIL)
	var stalks := 13
	var color := color_for(ripeness)
	var height := 70.0 + 80.0 * ripeness
	for i in stalks:
		var x := left + 24.0 + (width - 48.0) * float(i) / float(stalks - 1)
		var sway := sin(_time * 2.0 + i * 0.7) * 6.0 * (0.4 + ripeness)
		var bend := 0.0
		if _harvested:
			bend = min(_harvest_time / 0.4, 1.0) * (30.0 if i % 2 == 0 else -30.0)
		var top := Vector2(x + sway + bend, ground - height + abs(bend) * 0.8)
		draw_line(Vector2(x, ground), top, color.darkened(0.25), 4.0, true)
		# Espiga: granos a los lados del tallo.
		for g in 5:
			var t := float(g) / 5.0
			var p := Vector2(x, ground).linear_interpolate(top, 0.62 + t * 0.38)
			var r := 6.0 + 2.0 * ripeness
			draw_circle(p + Vector2(-r * 0.7, 0), r * 0.6, color)
			draw_circle(p + Vector2(r * 0.7, 0), r * 0.6, color)
		draw_circle(top, 5.0 + 2.0 * ripeness, color.lightened(0.15))
