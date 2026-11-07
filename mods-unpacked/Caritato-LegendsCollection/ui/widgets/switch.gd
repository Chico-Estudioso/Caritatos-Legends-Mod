extends Button

# Interruptor de encendido/apagado dibujado por código (sustituye a las
# casillas). Es un botón con toggle_mode, así que funciona con ratón, teclado
# y mando, y emite «toggled» como cualquier botón.

const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")

var accent: Color = UiStyle.BRAND
var _t := 0.0
var _knob: Texture = null
var _knob_disabled: Texture = null


func _init() -> void:
	toggle_mode = true
	flat = true
	focus_mode = Control.FOCUS_ALL
	rect_min_size = Vector2(88, 46)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_stylebox_override("focus", StyleBoxEmpty.new())
	set_process(false)
	var _err = connect("toggled", self, "_on_toggled")


# Cambia el estado sin animación y sin emitir «toggled».
func set_on(value: bool) -> void:
	set_block_signals(true)
	pressed = value
	set_block_signals(false)
	_t = 1.0 if value else 0.0
	update()


func _on_toggled(_value: bool) -> void:
	set_process(true)


func _process(delta: float) -> void:
	var target := 1.0 if pressed else 0.0
	_t = move_toward(_t, target, delta * 7.0)
	if is_equal_approx(_t, target):
		_t = target
		set_process(false)
	update()


func _draw() -> void:
	var height: float = min(rect_size.y, rect_min_size.y - 6.0)
	var width: float = min(rect_size.x, height * 2.0)
	var origin := Vector2(rect_size.x - width, (rect_size.y - height) / 2.0)
	var track_color := UiStyle.OFF.linear_interpolate(accent, _t)
	if disabled:
		track_color = track_color.darkened(0.45)
	var track := UiStyle.box(track_color, int(height / 2.0), Vector2.ZERO)
	draw_style_box(track, Rect2(origin, Vector2(width, height)))

	var knob_size := int(height - 10.0)
	if _knob == null or _knob.get_width() != knob_size:
		_knob = UiStyle.circle_texture(knob_size, UiStyle.TEXT, UiStyle.TEXT)
		_knob_disabled = UiStyle.circle_texture(knob_size, UiStyle.MUTED, UiStyle.MUTED)
	var knob_x := origin.x + 5.0 + (width - height) * _t
	draw_texture(_knob_disabled if disabled else _knob, Vector2(knob_x, origin.y + 5.0))

	if has_focus():
		var ring := UiStyle.ring(UiStyle.TEXT, int(height / 2.0), 3)
		draw_style_box(ring, Rect2(origin, Vector2(width, height)))
