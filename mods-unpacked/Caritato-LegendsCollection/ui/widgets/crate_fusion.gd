extends Control

# Fila de cajas de madera dibujadas por código. Las que se van a fusionar
# (las primeras «cost») botan un poco; con fuse() vuelan al centro, hay un
# destello y aparece una caja legendaria morada y dorada que late.

const WOOD := Color("b5793e")
const WOOD_DARK := Color("7d4f26")
const WOOD_LIGHT := Color("d39a5c")
const LEGEND := Color("8f5cf0")
const LEGEND_DARK := Color("5a32a8")
const GOLD := Color("ffd166")
const MAX_SHOWN := 12
const GATHER_TIME := 0.5
const FLASH_TIME := 0.18
const POP_TIME := 0.45

var count := 3
var cost := 3
var _time := 0.0
var _fusing := false
var _fuse_time := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect_min_size = Vector2(360, 160)


func _ready() -> void:
	set_process(true)


func setup(p_count: int, p_cost: int) -> void:
	count = int(max(0, p_count))
	cost = int(clamp(p_cost, 0, count))
	update()


func fuse() -> void:
	_fusing = true
	_fuse_time = 0.0


func is_fused() -> bool:
	return _fusing and _fuse_time >= GATHER_TIME + FLASH_TIME


func _process(delta: float) -> void:
	_time += delta
	if _fusing:
		_fuse_time += delta
	update()


# Posiciones de las cajas en una o dos filas, centradas.
static func slot_positions(total: int, area: Vector2, crate_size: float) -> Array:
	var shown: int = int(min(total, MAX_SHOWN))
	var per_row: int = int(min(shown, 6))
	var rows: int = 1 if shown <= 6 else 2
	var positions := []
	for i in shown:
		var row: int = int(i / per_row) if per_row > 0 else 0
		var in_row: int = int(min(per_row, shown - row * per_row))
		var col: int = i - row * per_row
		var gap: float = crate_size * 0.3
		var width: float = in_row * crate_size + (in_row - 1) * gap
		var x: float = area.x / 2.0 - width / 2.0 + col * (crate_size + gap) + crate_size / 2.0
		var y: float = area.y / 2.0 + (row - (rows - 1) / 2.0) * (crate_size + gap)
		positions.append(Vector2(x, y))
	return positions


func _crate_size() -> float:
	var shown: int = int(min(count, MAX_SHOWN))
	var per_row: int = int(max(1, min(shown, 6)))
	var rows: int = 1 if shown <= 6 else 2
	return min(rect_size.x / (per_row * 1.35 + 0.3), rect_size.y / (rows * 1.35 + 0.2)) * 0.95


func _draw() -> void:
	if count <= 0:
		return
	var size: float = _crate_size()
	var positions: Array = slot_positions(count, rect_size, size)
	# Las cajas fusionadas se juntan en su punto medio: la legendaria sale ahí
	# y las que no se fusionan se quedan en su sitio.
	var center := rect_size / 2.0
	var fused_count: int = int(min(cost, positions.size()))
	if fused_count > 0:
		center = Vector2.ZERO
		for index in fused_count:
			center += positions[index]
		center /= float(fused_count)
	var gather: float = clamp(_fuse_time / GATHER_TIME, 0.0, 1.0) if _fusing else 0.0
	var eased := gather * gather
	for i in positions.size():
		var pos: Vector2 = positions[i]
		var fused: bool = i < cost
		if fused:
			if _fusing:
				if gather >= 1.0:
					continue
				pos = pos.linear_interpolate(center, eased)
				_draw_crate(pos, size * (1.0 - 0.6 * eased), WOOD, WOOD_DARK, WOOD_LIGHT, 1.0, sin(_time * 30.0 + i) * 0.25 * eased)
			else:
				var hop: float = abs(sin(_time * 4.0 + i * 0.7)) * size * 0.08
				_draw_crate(pos - Vector2(0, hop), size, WOOD, WOOD_DARK, WOOD_LIGHT, 1.0, 0.0)
		else:
			_draw_crate(pos, size, WOOD, WOOD_DARK, WOOD_LIGHT, 0.4, 0.0)
	if count > MAX_SHOWN:
		var last: Vector2 = positions[positions.size() - 1]
		draw_circle(last + Vector2(size * 0.45, -size * 0.45), size * 0.22, GOLD)

	if not _fusing:
		return
	var after := _fuse_time - GATHER_TIME
	if after > 0.0 and after < FLASH_TIME * 2.0:
		var flash: float = 1.0 - abs(after - FLASH_TIME) / FLASH_TIME
		draw_circle(center, size * (0.6 + 1.2 * (after / (FLASH_TIME * 2.0))), Color(1, 1, 1, 0.55 * clamp(flash, 0.0, 1.0)))
	var pop := _fuse_time - GATHER_TIME - FLASH_TIME
	if pop > 0.0:
		var k: float = clamp(pop / POP_TIME, 0.0, 1.0)
		var scale: float = 1.35 * (1.0 - pow(1.0 - k, 3.0))
		if k >= 1.0:
			scale = 1.3 + 0.05 * sin(_time * 5.0)
		for ring in 3:
			var radius: float = size * scale * (0.75 + 0.3 * ring) * (1.0 + 0.04 * sin(_time * 3.0 + ring))
			draw_circle(center, radius, Color(GOLD.r, GOLD.g, GOLD.b, 0.08))
		_draw_crate(center, size * scale, LEGEND, LEGEND_DARK, GOLD, 1.0, 0.0)
		_draw_star(center, size * scale * 0.24, GOLD)


func _draw_crate(center: Vector2, size: float, body: Color, dark: Color, trim: Color, alpha: float, angle: float) -> void:
	draw_set_transform(center, angle, Vector2.ONE)
	var half := size / 2.0
	var rect := Rect2(Vector2(-half, -half), Vector2(size, size))
	draw_rect(rect, _alpha(dark, alpha))
	var inner := rect.grow(-size * 0.1)
	draw_rect(inner, _alpha(body, alpha))
	# Tablas en cruz y bordes, como las cajas del juego.
	var plank := size * 0.12
	draw_line(inner.position, inner.end, _alpha(trim, alpha), plank, true)
	draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), _alpha(trim, alpha), plank, true)
	draw_rect(rect, _alpha(dark.darkened(0.3), alpha), false, max(2.0, size * 0.05))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PoolVector2Array()
	for i in 10:
		var r: float = radius if i % 2 == 0 else radius * 0.45
		var a: float = PI * i / 5.0 - PI / 2.0
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, color, PoolVector2Array(), null, null, true)


static func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha)
