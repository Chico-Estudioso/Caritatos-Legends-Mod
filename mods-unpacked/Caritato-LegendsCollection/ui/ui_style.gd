extends Reference

# Estilo visual común de las ventanas de Caritatopc: paleta, cajas con esquinas
# redondeadas, botones, deslizadores, fuentes e iconos generados por código.
# Las fuentes se derivan de la fuente del tema del juego (Anybody) para que
# encajen con Brotato; si no hay tema, se usa la fuente por defecto de Godot.

const THEME_PATH := "res://resources/themes/base_theme.tres"

# Morado: el color favorito de Mauro. Las superficies llevan un toque morado.
const BRAND := Color("a970ff")
const BRAND_LIGHT := Color("d7bcff")
const SPARK := Color("ffd166")
const BG := Color("15121d")
const SURFACE := Color("1e1a29")
const SURFACE_2 := Color("292338")
const SURFACE_3 := Color("372f4a")
const TEXT := Color("f6f1ff")
const TEXT_SOFT := Color("d2c8e6")
const MUTED := Color("9d93b5")
const OK := Color("7ddc8a")
const WARN := Color("ffb454")
const ERROR := Color("ff6b6b")
const OFF := Color("4d4560")
const INK := Color("1a1225")


static func game_theme() -> Theme:
	if ResourceLoader.exists(THEME_PATH):
		var theme = load(THEME_PATH)
		if theme is Theme:
			return theme
	return null


# Copia de la fuente del tema con otro tamaño. Devuelve null si el tema no
# usa una DynamicFont (entonces el control conserva la fuente por defecto).
static func font(size: int, outline: int = 0) -> Font:
	var theme := game_theme()
	if theme == null or not theme.default_font is DynamicFont:
		return null
	var copy: DynamicFont = theme.default_font.duplicate()
	copy.size = size
	copy.outline_size = outline
	copy.outline_color = Color(0, 0, 0, 0.8)
	copy.extra_spacing_top = 0
	return copy


static func box(color: Color, radius: int = 12, padding: Vector2 = Vector2(16, 10)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding.x
	style.content_margin_right = padding.x
	style.content_margin_top = padding.y
	style.content_margin_bottom = padding.y
	style.anti_aliasing = true
	return style


static func bordered(color: Color, radius: int, border: Color, width: int, padding: Vector2 = Vector2(16, 10)) -> StyleBoxFlat:
	var style := box(color, radius, padding)
	style.set_border_width_all(width)
	style.border_color = border
	return style


# Caja con una franja de color a la izquierda (tarjeta seleccionada).
static func stripe(color: Color, radius: int, accent: Color, width: int = 6) -> StyleBoxFlat:
	var style := box(color, radius)
	style.border_width_left = width
	style.border_color = accent
	return style


# Anillo de foco: se dibuja encima del control cuando tiene el foco.
static func ring(color: Color, radius: int, width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.set_border_width_all(width)
	style.border_color = color
	style.set_corner_radius_all(radius + width)
	style.set_expand_margin_all(width + 1)
	style.anti_aliasing = true
	return style


static func panel_box() -> StyleBoxFlat:
	var style := bordered(BG, 24, Color(BRAND.r, BRAND.g, BRAND.b, 0.35), 2, Vector2(34, 30))
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 24
	return style


# kind: "primary" (relleno de color) o "ghost" (discreto).
static func style_button(button: Button, kind: String, accent: Color, font_size: int = 28) -> void:
	var radius := 14
	var padding := Vector2(26, 12)
	if kind == "primary":
		button.add_stylebox_override("normal", box(accent, radius, padding))
		button.add_stylebox_override("hover", box(accent.lightened(0.12), radius, padding))
		button.add_stylebox_override("pressed", box(accent.darkened(0.15), radius, padding))
		button.add_stylebox_override("disabled", box(OFF, radius, padding))
		for color_name in ["font_color", "font_color_hover", "font_color_pressed", "font_color_focus"]:
			button.add_color_override(color_name, INK)
	else:
		button.add_stylebox_override("normal", box(SURFACE_2, radius, padding))
		button.add_stylebox_override("hover", box(SURFACE_3, radius, padding))
		button.add_stylebox_override("pressed", box(SURFACE, radius, padding))
		button.add_stylebox_override("disabled", box(SURFACE, radius, padding))
		for color_name in ["font_color", "font_color_hover", "font_color_pressed", "font_color_focus"]:
			button.add_color_override(color_name, TEXT)
	button.add_color_override("font_color_disabled", MUTED)
	button.add_stylebox_override("focus", ring(TEXT if kind == "primary" else accent, radius))
	var button_font := font(font_size)
	if button_font != null:
		button.add_font_override("font", button_font)


static func style_slider(slider: Slider, accent: Color) -> void:
	slider.add_stylebox_override("slider", box(SURFACE_3, 6, Vector2(0, 5)))
	slider.add_stylebox_override("grabber_area", box(accent, 6, Vector2(0, 5)))
	slider.add_stylebox_override("grabber_area_highlight", box(accent.lightened(0.15), 6, Vector2(0, 5)))
	slider.add_stylebox_override("focus", StyleBoxEmpty.new())
	slider.add_icon_override("grabber", circle_texture(30, TEXT, accent, 4.0))
	slider.add_icon_override("grabber_highlight", circle_texture(34, Color(1, 1, 1), accent.lightened(0.2), 4.0))
	slider.add_icon_override("grabber_disabled", circle_texture(30, MUTED, OFF, 4.0))
	slider.add_icon_override("tick", ImageTexture.new())


static func style_option_button(option: OptionButton, accent: Color, font_size: int = 26) -> void:
	style_button(option, "ghost", accent, font_size)


# Círculo con borde y bordes suavizados, para tiradores y puntos de estado.
static func circle_texture(diameter: int, fill: Color, border: Color, border_width: float = 0.0) -> ImageTexture:
	var image := Image.new()
	image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.lock()
	var radius := diameter / 2.0
	for y in diameter:
		for x in diameter:
			var distance := Vector2(x + 0.5 - radius, y + 0.5 - radius).length()
			var color := Color(0, 0, 0, 0)
			if distance <= radius + 0.5:
				color = border if distance > radius - border_width else fill
				color.a *= clamp(radius - distance + 0.5, 0.0, 1.0)
			image.set_pixel(x, y, color)
	image.unlock()
	var texture := ImageTexture.new()
	texture.create_from_image(image, Texture.FLAG_FILTER)
	return texture
