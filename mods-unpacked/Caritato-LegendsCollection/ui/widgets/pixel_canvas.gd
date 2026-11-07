extends Control

# Lienzo de píxeles de 50 × 50 para «Tus tatos». Encima de la patata del juego
# (como guía, no se guarda) se pinta con el ratón o, con el foco en el lienzo,
# moviendo un cursor con las flechas o el mando y pulsando Aceptar.
# Herramientas: lápiz, goma, cubo de relleno y cuentagotas; se puede deshacer.

signal changed
signal color_picked(color)

const SIZE := 50
const MAX_UNDO := 40
const TOOL_PENCIL := "pencil"
const TOOL_ERASER := "eraser"
const TOOL_FILL := "fill"
const TOOL_PICKER := "picker"
const CHECKER_A := Color("201c2b")
const CHECKER_B := Color("27223a")

var image: Image = null
var color := Color("a970ff")
var tool := TOOL_PENCIL
var guide: Texture = null
var show_grid := true
var cursor := Vector2(SIZE / 2, SIZE / 2)

var _texture := ImageTexture.new()
var _undo := []
var _stroke := false


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	rect_min_size = Vector2(500, 500)
	image = Image.new()
	image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	_refresh()


func get_image() -> Image:
	var copy := Image.new()
	copy.copy_from(image)
	return copy


func set_image(new_image: Image) -> void:
	if new_image == null:
		return
	_push_undo()
	image = Image.new()
	image.copy_from(new_image)
	image.convert(Image.FORMAT_RGBA8)
	if image.get_width() != SIZE or image.get_height() != SIZE:
		image.resize(SIZE, SIZE, Image.INTERPOLATE_NEAREST)
	_refresh()
	emit_signal("changed")


func clear() -> void:
	_push_undo()
	image.fill(Color(0, 0, 0, 0))
	_refresh()
	emit_signal("changed")


func is_empty() -> bool:
	return image.is_invisible()


func undo() -> void:
	if _undo.empty():
		return
	image = _undo.pop_back()
	_refresh()
	emit_signal("changed")


func can_undo() -> bool:
	return not _undo.empty()


func pixel(cell: Vector2) -> Color:
	image.lock()
	var value := image.get_pixel(int(cell.x), int(cell.y))
	image.unlock()
	return value


# --- Pintar ------------------------------------------------------------------------

func apply_at(cell: Vector2, new_stroke: bool = true) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= SIZE or cell.y >= SIZE:
		return
	if tool == TOOL_PICKER:
		var picked := pixel(cell)
		if picked.a > 0.0:
			color = picked
			emit_signal("color_picked", picked)
		return
	if new_stroke:
		_push_undo()
	if tool == TOOL_FILL:
		flood_fill(cell, color)
	else:
		image.lock()
		image.set_pixel(int(cell.x), int(cell.y), Color(0, 0, 0, 0) if tool == TOOL_ERASER else color)
		image.unlock()
	_refresh()
	emit_signal("changed")


# Relleno de la zona del mismo color (4 vecinos), sin recursión.
func flood_fill(start: Vector2, new_color: Color) -> void:
	image.lock()
	var target := image.get_pixel(int(start.x), int(start.y))
	if target.is_equal_approx(new_color):
		image.unlock()
		return
	var pending := [start]
	while not pending.empty():
		var cell: Vector2 = pending.pop_back()
		var x := int(cell.x)
		var y := int(cell.y)
		if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
			continue
		if not image.get_pixel(x, y).is_equal_approx(target):
			continue
		image.set_pixel(x, y, new_color)
		pending.append(Vector2(x + 1, y))
		pending.append(Vector2(x - 1, y))
		pending.append(Vector2(x, y + 1))
		pending.append(Vector2(x, y - 1))
	image.unlock()


# Dentro del lienzo mueve el cursor; en el borde deja que el foco pase a los
# botones de al lado (así se sale del lienzo con el mando).
func _step(dx: int, dy: int) -> void:
	var target := cursor + Vector2(dx, dy)
	if target.x < 0 or target.y < 0 or target.x >= SIZE or target.y >= SIZE:
		return
	move_cursor(dx, dy)
	accept_event()


func move_cursor(dx: int, dy: int) -> void:
	cursor = Vector2(clamp(cursor.x + dx, 0, SIZE - 1), clamp(cursor.y + dy, 0, SIZE - 1))
	update()


func _push_undo() -> void:
	var copy := Image.new()
	copy.copy_from(image)
	_undo.append(copy)
	if _undo.size() > MAX_UNDO:
		_undo.pop_front()


func _refresh() -> void:
	_texture.create_from_image(image, 0)
	update()


# --- Entrada -------------------------------------------------------------------------

func cell_size() -> float:
	return min(rect_size.x, rect_size.y) / SIZE


func cell_at(local: Vector2) -> Vector2:
	var size := cell_size()
	return Vector2(floor(local.x / size), floor(local.y / size))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			grab_focus()
			_stroke = true
			cursor = cell_at(event.position)
			apply_at(cursor, true)
		else:
			_stroke = false
		accept_event()
	elif event is InputEventMouseMotion and _stroke and tool != TOOL_FILL:
		var cell := cell_at(event.position)
		if cell != cursor:
			cursor = cell
			apply_at(cell, false)
		accept_event()
	elif event.is_action_pressed("ui_left"):
		_step(-1, 0)
	elif event.is_action_pressed("ui_right"):
		_step(1, 0)
	elif event.is_action_pressed("ui_up"):
		_step(0, -1)
	elif event.is_action_pressed("ui_down"):
		_step(0, 1)
	elif event.is_action_pressed("ui_accept"):
		apply_at(cursor, true)
		accept_event()


# --- Dibujo -----------------------------------------------------------------------

func _draw() -> void:
	var size := cell_size()
	var full := size * SIZE
	var area := Rect2(Vector2.ZERO, Vector2(full, full))
	# Cuadros de fondo (como en los editores de imágenes).
	var block := full / 10.0
	for row in 10:
		for column in 10:
			var tint: Color = CHECKER_A if (row + column) % 2 == 0 else CHECKER_B
			draw_rect(Rect2(column * block, row * block, block, block), tint)
	if guide != null:
		draw_texture_rect(guide, area, false, Color(1, 1, 1, 0.55))
	draw_texture_rect(_texture, area, false)
	if show_grid:
		var line := Color(1, 1, 1, 0.05)
		for index in SIZE + 1:
			var offset: float = index * size
			draw_line(Vector2(offset, 0), Vector2(offset, full), line)
			draw_line(Vector2(0, offset), Vector2(full, offset), line)
	if has_focus():
		var cursor_rect := Rect2(cursor * size, Vector2(size, size))
		draw_rect(cursor_rect.grow(1), Color(1, 1, 1, 0.9), false, 2.0)
	draw_rect(area, Color(1, 1, 1, 0.12), false, 2.0)
