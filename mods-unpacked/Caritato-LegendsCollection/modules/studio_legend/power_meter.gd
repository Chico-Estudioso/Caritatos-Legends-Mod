extends CanvasLayer

# Medidor de poder: lista los personajes u objetos (los del juego, los de los
# DLC y los que crea BroEditor) de más a menos fuerte, con una barra y una
# etiqueta: Equilibrado, Fuerte, Muy fuerte o Roto. Sirve para ver si una
# creación se ha pasado de fuerte respecto a lo que ya hay en el juego.

signal closed

const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")
const PowerRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/studio_legend/power_rules.gd")

const ACCENT := Color("b98cff")
const KIND_CHARACTERS := "characters"
const KIND_ITEMS := "items"
const RATING_KEYS := ["CLC_POWER_BALANCED", "CLC_POWER_STRONG", "CLC_POWER_VERY_STRONG", "CLC_POWER_BROKEN"]
const RATING_COLORS := [Color("7ddc8a"), Color("ffd166"), Color("ff8c42"), Color("ff6b6b")]

var legend = null
var kind := KIND_CHARACTERS
# Para las pruebas y capturas: {kind: [entradas]} en lugar de pedirlas al juego.
var entries_override := {}

var _fonts := {}
var _list: VBoxContainer = null
var _tabs := {}
var _summary: Label = null


func _init() -> void:
	layer = 120
	pause_mode = Node.PAUSE_MODE_PROCESS


func open(p_legend) -> void:
	legend = p_legend
	_build()
	show_kind(KIND_CHARACTERS)


func close_screen() -> void:
	emit_signal("closed")
	queue_free()


func entries_for(p_kind: String) -> Array:
	if entries_override.has(p_kind):
		return entries_override[p_kind]
	if legend == null:
		return []
	return legend.power_entries(p_kind)


func show_kind(p_kind: String) -> void:
	kind = p_kind
	for key in _tabs.keys():
		UiStyle.style_button(_tabs[key], "primary" if key == kind else "ghost", ACCENT, 24)
	for child in _list.get_children():
		child.queue_free()
	var entries := entries_for(kind)
	if entries.empty():
		_list.add_child(_label(tr("CLC_POWER_EMPTY"), "body", UiStyle.MUTED, true))
		_summary.text = ""
		return
	var highest := 0.0
	var counts := [0, 0, 0, 0]
	for entry in entries:
		highest = max(highest, float(entry.score))
		counts[int(entry.rating)] += 1
	for entry in entries:
		_list.add_child(_row(entry, highest))
	_summary.text = tr("CLC_POWER_SUMMARY") % [entries.size(), counts[2] + counts[3]]


# --- Construcción --------------------------------------------------------------------

func _build() -> void:
	_fonts = {
		"title": UiStyle.font(48, 2),
		"name": UiStyle.font(26, 1),
		"body": UiStyle.font(24),
		"small": UiStyle.font(20),
	}
	var root := Control.new()
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var theme := UiStyle.game_theme()
	if theme != null:
		root.theme = theme
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.9)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	for side in ["left", "right"]:
		margin.add_constant_override("margin_" + side, 160)
	for side in ["top", "bottom"]:
		margin.add_constant_override("margin_" + side, 50)
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_stylebox_override("panel", UiStyle.bordered(UiStyle.BG, 24, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.5), 2, Vector2(34, 26)))
	margin.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 16)
	panel.add_child(layout)

	layout.add_child(_label(tr("CLC_POWER_TITLE"), "title", ACCENT))
	layout.add_child(_label(tr("CLC_POWER_INTRO"), "small", UiStyle.TEXT_SOFT, true))

	var tabs := HBoxContainer.new()
	tabs.add_constant_override("separation", 10)
	layout.add_child(tabs)
	for entry in [[KIND_CHARACTERS, "CLC_POWER_CHARACTERS"], [KIND_ITEMS, "CLC_POWER_ITEMS"]]:
		var button := Button.new()
		button.text = tr(entry[1])
		button.rect_min_size = Vector2(220, 52)
		var _err = button.connect("pressed", self, "show_kind", [entry[0]])
		tabs.add_child(button)
		_tabs[entry[0]] = button
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)
	for index in RATING_KEYS.size():
		var chip := _chip(tr(RATING_KEYS[index]), UiStyle.INK, RATING_COLORS[index])
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tabs.add_child(chip)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	scroll.follow_focus = true
	layout.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_constant_override("separation", 6)
	scroll.add_child(_list)

	var footer := HBoxContainer.new()
	layout.add_child(footer)
	_summary = _label("", "small", UiStyle.TEXT_SOFT, true)
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_summary)
	var close := Button.new()
	close.text = tr("CLC_TATOS_CLOSE")
	close.rect_min_size = Vector2(200, 52)
	UiStyle.style_button(close, "ghost", ACCENT, 24)
	var _close_err = close.connect("pressed", self, "close_screen")
	footer.add_child(close)
	close.call_deferred("grab_focus")


func _row(entry: Dictionary, highest: float) -> Control:
	var row := PanelContainer.new()
	row.focus_mode = Control.FOCUS_ALL
	row.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE, 12, Vector2(14, 6)))
	var box := HBoxContainer.new()
	box.add_constant_override("separation", 16)
	row.add_child(box)
	var icon := TextureRect.new()
	icon.texture = entry.get("icon")
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.rect_min_size = Vector2(52, 52)
	box.add_child(icon)
	var name_label := _label(str(entry.get("name", "")), "name", UiStyle.TEXT)
	name_label.rect_min_size = Vector2(360, 0)
	name_label.clip_text = true
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(name_label)

	var rating: int = int(entry.get("rating", 0))
	var color: Color = RATING_COLORS[int(clamp(rating, 0, 3))]
	var bar_back := PanelContainer.new()
	bar_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_back.rect_min_size = Vector2(0, 18)
	bar_back.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE_3, 9, Vector2.ZERO))
	var bar_fill := ColorRect.new()
	bar_fill.color = color
	bar_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bar := HBoxContainer.new()
	bar.add_constant_override("separation", 0)
	var fraction: float = PowerRules.bar_fraction(float(entry.get("score", 0.0)), highest)
	bar_fill.size_flags_stretch_ratio = max(0.001, fraction)
	var rest := Control.new()
	rest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest.size_flags_stretch_ratio = max(0.001, 1.0 - fraction)
	bar.add_child(bar_fill)
	bar.add_child(rest)
	bar_back.add_child(bar)
	box.add_child(bar_back)

	var score_label := _label("%d" % int(round(float(entry.get("score", 0.0)))), "small", UiStyle.TEXT_SOFT)
	score_label.rect_min_size = Vector2(60, 0)
	score_label.align = Label.ALIGN_RIGHT
	score_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(score_label)
	var chip := _chip(tr(RATING_KEYS[int(clamp(rating, 0, 3))]), UiStyle.INK, color)
	chip.rect_min_size = Vector2(170, 0)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(chip)
	return row


func _label(text: String, font_key: String, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap = wrap
	label.add_color_override("font_color", color)
	var font = _fonts.get(font_key)
	if font != null:
		label.add_font_override("font", font)
	return label


func _chip(text: String, color: Color, background: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_stylebox_override("panel", UiStyle.box(background, 12, Vector2(14, 5)))
	var label := _label(text, "small", color)
	label.align = Label.ALIGN_CENTER
	chip.add_child(label)
	return chip
