extends CanvasLayer

# «Tus tatos»: dibuja el aspecto de tu patata. El dibujo (50 × 50 píxeles) se
# pinta encima de la patata del juego, se guarda en
# user://caritato_legends/tatos/, se puede llevar puesto en las partidas y,
# con BroEditor, se guarda también como icono para sus personajes y objetos.
#
# Ratón: pintar en el lienzo y pulsar botones. Teclado y mando: con el foco en
# el lienzo, las flechas mueven el cursor y Aceptar pinta; al llegar al borde,
# el foco pasa a los botones. Atrás (desde el menú Caritatopc) cierra.

signal closed

const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")
const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const PixelCanvas = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/pixel_canvas.gd")
const TatoStore = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/studio_legend/tato_store.gd")

const ACCENT := Color("b98cff")
const PALETTE := [
	Color("a970ff"), Color("d7bcff"), Color("5a32a8"), Color("1a1225"),
	Color("ffffff"), Color("9d93b5"), Color("ffd166"), Color("ff8c42"),
	Color("ff6b6b"), Color("ff8fd8"), Color("7ddc8a"), Color("2e9d5b"),
	Color("4fc3f7"), Color("2b5fb8"), Color("c98b4f"), Color("6b3e22"),
]
const TOOLS := [
	["pencil", "CLC_TATOS_TOOL_PENCIL"],
	["eraser", "CLC_TATOS_TOOL_ERASER"],
	["fill", "CLC_TATOS_TOOL_FILL"],
	["picker", "CLC_TATOS_TOOL_PICKER"],
]

var legend = null
var store = null
var player_count := 4

var _fonts := {}
var _root: Control = null
var _canvas: Control = null
var _name_edit: LineEdit = null
var _list_box: VBoxContainer = null
var _icon_preview: TextureRect = null
var _body_preview: TextureRect = null
var _status: Label = null
var _tool_buttons := {}
var _swatches := []
var _worn_buttons := []
var _color_picker: ColorPickerButton = null
var _current_id := ""
var _potato_image: Image = null
var _preview_dirty := true


func _init() -> void:
	layer = 120
	pause_mode = Node.PAUSE_MODE_PROCESS


func open(p_legend, p_store) -> void:
	legend = p_legend
	store = p_store
	_potato_image = _load_potato_image()
	_build()
	_refresh_list()
	new_tato()
	_canvas.call_deferred("grab_focus")


func close_screen() -> void:
	emit_signal("closed")
	queue_free()


func current_id() -> String:
	return _current_id


func canvas() -> Control:
	return _canvas


func set_status(text: String, color: Color = UiStyle.TEXT_SOFT) -> void:
	_status.text = text
	_status.add_color_override("font_color", color)


# --- Acciones ------------------------------------------------------------------------

func new_tato() -> void:
	_current_id = ""
	_canvas.set_image(_blank())
	_name_edit.text = tr("CLC_TATOS_DEFAULT_NAME")
	_refresh_worn()
	set_status(tr("CLC_TATOS_HINT"))


func load_tato(id: String) -> void:
	var image: Image = store.load_image(id)
	if image == null:
		set_status(tr("CLC_TATOS_LOAD_ERROR"), UiStyle.ERROR)
		return
	_current_id = id
	_canvas.set_image(image)
	for entry in store.list():
		if entry.id == id:
			_name_edit.text = str(entry.name)
	_refresh_worn()
	set_status(tr("CLC_TATOS_LOADED") % _name_edit.text)


func save_tato() -> String:
	var tato_name := _name_edit.text.strip_edges()
	if tato_name == "":
		tato_name = tr("CLC_TATOS_DEFAULT_NAME")
		_name_edit.text = tato_name
	var id := _current_id
	if id == "":
		id = _unique_id(TatoStore.make_id(tato_name))
	var image: Image = _canvas.get_image()
	if store.save(id, tato_name, image) != OK:
		set_status(tr("CLC_TATOS_SAVE_ERROR"), UiStyle.ERROR)
		return ""
	_current_id = id
	var message: String = tr("CLC_TATOS_SAVED") % tato_name
	if legend != null and legend.exports_to_broeditor():
		var icon_name: String = store.export_icon(id, image, _potato_image)
		if icon_name != "":
			message = tr("CLC_TATOS_SAVED_BROEDITOR") % [tato_name, icon_name]
	set_status(message, UiStyle.OK)
	_refresh_list()
	return id


func delete_tato() -> void:
	if _current_id == "":
		new_tato()
		return
	store.delete(_current_id)
	_refresh_list()
	new_tato()
	set_status(tr("CLC_TATOS_DELETED"))


func toggle_worn(player_index: int) -> void:
	var id := _current_id
	if id == "":
		id = save_tato()
		if id == "":
			return
	if store.worn_by(player_index) == id:
		store.set_worn(player_index, "")
		set_status(tr("CLC_TATOS_UNWORN") % (player_index + 1))
	else:
		store.set_worn(player_index, id)
		set_status(tr("CLC_TATOS_WORN") % [player_index + 1, _name_edit.text], UiStyle.OK)
	_refresh_worn()


func import_png(path: String) -> bool:
	var image := Image.new()
	if image.load(path) != OK:
		set_status(tr("CLC_TATOS_IMPORT_ERROR"), UiStyle.ERROR)
		return false
	_canvas.set_image(TatoStore.normalized(image))
	if _name_edit.text == tr("CLC_TATOS_DEFAULT_NAME"):
		_name_edit.text = path.get_file().get_basename()
	set_status(tr("CLC_TATOS_IMPORTED"), UiStyle.OK)
	return true


func select_tool(tool_name: String) -> void:
	_canvas.tool = tool_name
	for key in _tool_buttons.keys():
		var button: Button = _tool_buttons[key]
		UiStyle.style_button(button, "primary" if key == tool_name else "ghost", ACCENT, 22)


func select_color(color: Color) -> void:
	_canvas.color = color
	if _canvas.tool == PixelCanvas.TOOL_ERASER or _canvas.tool == PixelCanvas.TOOL_PICKER:
		select_tool(PixelCanvas.TOOL_PENCIL)
	_color_picker.color = color
	for index in _swatches.size():
		var chosen: bool = PALETTE[index].is_equal_approx(color)
		_swatches[index].add_stylebox_override("normal", _swatch_style(PALETTE[index], chosen))


# --- Construcción --------------------------------------------------------------------

func _build() -> void:
	_fonts = {
		"title": UiStyle.font(48, 2),
		"name": UiStyle.font(30, 1),
		"body": UiStyle.font(24),
		"small": UiStyle.font(20),
		"tiny": UiStyle.font(17),
	}
	_root = Control.new()
	_root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var theme := UiStyle.game_theme()
	if theme != null:
		_root.theme = theme
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.05, 0.9)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	_root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	for side in ["left", "right"]:
		margin.add_constant_override("margin_" + side, 70)
	for side in ["top", "bottom"]:
		margin.add_constant_override("margin_" + side, 46)
	_root.add_child(margin)

	var panel := PanelContainer.new()
	panel.add_stylebox_override("panel", UiStyle.bordered(UiStyle.BG, 24, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.5), 2, Vector2(34, 26)))
	margin.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 18)
	panel.add_child(layout)

	layout.add_child(_build_header())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_constant_override("separation", 30)
	layout.add_child(body)
	body.add_child(_build_gallery())
	body.add_child(_build_canvas_column())
	body.add_child(_build_side())
	layout.add_child(_build_footer())


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_constant_override("separation", 18)
	var titles := VBoxContainer.new()
	titles.add_constant_override("separation", 0)
	titles.add_child(_label(tr("CLC_TATOS_TITLE"), "title", ACCENT))
	titles.add_child(_label(tr("CLC_TATOS_SUBTITLE"), "small", UiStyle.MUTED))
	header.add_child(titles)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var connected: bool = legend != null and legend.broeditor_loaded()
	var chip := _chip(tr("CLC_TATOS_BROEDITOR_ON") if connected else tr("CLC_TATOS_BROEDITOR_OFF"), UiStyle.INK, UiStyle.OK if connected else UiStyle.WARN)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(chip)
	return header


func _build_gallery() -> Control:
	var column := VBoxContainer.new()
	column.rect_min_size = Vector2(300, 0)
	column.add_constant_override("separation", 12)
	column.add_child(_label(tr("CLC_TATOS_LIST").to_upper(), "tiny", UiStyle.MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	column.add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_constant_override("separation", 8)
	scroll.add_child(_list_box)
	column.add_child(_button(tr("CLC_TATOS_NEW"), "new_tato", [], "ghost"))
	return column


func _build_canvas_column() -> Control:
	var column := VBoxContainer.new()
	column.add_constant_override("separation", 14)
	_canvas = PixelCanvas.new()
	_canvas.rect_min_size = Vector2(560, 560)
	_canvas.guide = _texture_from(_potato_image)
	var _err = _canvas.connect("changed", self, "_on_canvas_changed")
	_err = _canvas.connect("color_picked", self, "_on_color_picked")
	column.add_child(_canvas)
	var tools := HBoxContainer.new()
	tools.add_constant_override("separation", 8)
	column.add_child(tools)
	for entry in TOOLS:
		var button := _button(tr(entry[1]), "select_tool", [entry[0]], "ghost", 22)
		_tool_buttons[entry[0]] = button
		tools.add_child(button)
	var actions := HBoxContainer.new()
	actions.add_constant_override("separation", 8)
	column.add_child(actions)
	actions.add_child(_button(tr("CLC_TATOS_UNDO"), "_on_undo", [], "ghost", 22))
	actions.add_child(_button(tr("CLC_TATOS_CLEAR"), "_on_clear", [], "ghost", 22))
	actions.add_child(_button(tr("CLC_TATOS_GRID"), "_on_grid", [], "ghost", 22))
	select_tool(PixelCanvas.TOOL_PENCIL)
	return column


func _build_side() -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_constant_override("separation", 12)

	column.add_child(_label(tr("CLC_TATOS_COLOR").to_upper(), "tiny", UiStyle.MUTED))
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_constant_override("hseparation", 8)
	grid.add_constant_override("vseparation", 8)
	column.add_child(grid)
	for color in PALETTE:
		var swatch := Button.new()
		swatch.rect_min_size = Vector2(46, 46)
		swatch.focus_mode = Control.FOCUS_ALL
		for state in ["normal", "hover", "pressed"]:
			swatch.add_stylebox_override(state, _swatch_style(color, false))
		swatch.add_stylebox_override("focus", UiStyle.ring(UiStyle.TEXT, 10))
		var _err = swatch.connect("pressed", self, "select_color", [color])
		grid.add_child(swatch)
		_swatches.append(swatch)
	var other := HBoxContainer.new()
	other.add_constant_override("separation", 14)
	column.add_child(other)
	var other_label := _label(tr("CLC_TATOS_OTHER_COLOR"), "body", UiStyle.TEXT_SOFT)
	other_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	other.add_child(other_label)
	_color_picker = ColorPickerButton.new()
	_color_picker.edit_alpha = false
	_color_picker.rect_min_size = Vector2(150, 46)
	_color_picker.color = PALETTE[0]
	_color_picker.add_stylebox_override("normal", UiStyle.box(UiStyle.SURFACE_2, 10, Vector2(6, 6)))
	_color_picker.add_stylebox_override("hover", UiStyle.box(UiStyle.SURFACE_3, 10, Vector2(6, 6)))
	_color_picker.add_stylebox_override("focus", UiStyle.ring(ACCENT, 10))
	var _picker_err = _color_picker.connect("color_changed", self, "select_color")
	other.add_child(_color_picker)

	column.add_child(_label(tr("CLC_TATOS_PREVIEW").to_upper(), "tiny", UiStyle.MUTED))
	var previews := HBoxContainer.new()
	previews.add_constant_override("separation", 22)
	column.add_child(previews)
	_body_preview = _preview_rect(150)
	previews.add_child(_body_preview)
	_icon_preview = _preview_rect(96)
	_icon_preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	previews.add_child(_icon_preview)

	column.add_child(_label(tr("CLC_TATOS_NAME").to_upper(), "tiny", UiStyle.MUTED))
	_name_edit = LineEdit.new()
	_name_edit.max_length = 32
	_name_edit.rect_min_size = Vector2(0, 50)
	var name_font = _fonts.get("body")
	if name_font != null:
		_name_edit.add_font_override("font", name_font)
	_name_edit.add_stylebox_override("normal", UiStyle.box(UiStyle.SURFACE_2, 12, Vector2(16, 8)))
	_name_edit.add_stylebox_override("focus", UiStyle.ring(ACCENT, 12))
	column.add_child(_name_edit)

	var buttons := HBoxContainer.new()
	buttons.add_constant_override("separation", 10)
	column.add_child(buttons)
	buttons.add_child(_button(tr("CLC_TATOS_SAVE"), "save_tato", [], "primary"))
	buttons.add_child(_button(tr("CLC_TATOS_IMPORT"), "_on_import", [], "ghost"))
	buttons.add_child(_button(tr("CLC_TATOS_DELETE"), "delete_tato", [], "ghost"))

	column.add_child(_label(tr("CLC_TATOS_WEAR").to_upper(), "tiny", UiStyle.MUTED))
	var worn := HBoxContainer.new()
	worn.add_constant_override("separation", 10)
	column.add_child(worn)
	for player_index in player_count:
		var button := _button(tr("CLC_TATOS_PLAYER") % (player_index + 1), "toggle_worn", [player_index], "ghost", 22)
		worn.add_child(button)
		_worn_buttons.append(button)

	if legend == null or not legend.broeditor_loaded():
		var notice := PanelContainer.new()
		notice.add_stylebox_override("panel", UiStyle.bordered(Color(UiStyle.WARN.r, UiStyle.WARN.g, UiStyle.WARN.b, 0.12), 12, Color(UiStyle.WARN.r, UiStyle.WARN.g, UiStyle.WARN.b, 0.5), 2, Vector2(14, 10)))
		var notice_box := VBoxContainer.new()
		notice_box.add_child(_label(tr("CLC_TATOS_NEEDS_BROEDITOR"), "tiny", UiStyle.WARN, true))
		notice_box.add_child(_button(tr("CLC_STUDIO_DOWNLOAD"), "_on_download", [], "ghost", 20))
		notice.add_child(notice_box)
		column.add_child(notice)
	return column


func _build_footer() -> Control:
	var footer := HBoxContainer.new()
	footer.add_constant_override("separation", 16)
	_status = _label("", "small", UiStyle.TEXT_SOFT, true)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_status)
	footer.add_child(_button(tr("CLC_TATOS_CLOSE"), "close_screen", [], "ghost"))
	return footer


# --- Estado ------------------------------------------------------------------------

func _refresh_list() -> void:
	for child in _list_box.get_children():
		child.queue_free()
	var entries: Array = store.list()
	if entries.empty():
		_list_box.add_child(_label(tr("CLC_TATOS_EMPTY"), "small", UiStyle.MUTED, true))
		return
	for entry in entries:
		var row := Button.new()
		row.text = "  " + str(entry.name)
		row.align = Button.ALIGN_LEFT
		row.rect_min_size = Vector2(0, 64)
		row.clip_text = true
		var image: Image = store.load_image(entry.id)
		if image != null:
			row.icon = _texture_from(TatoStore.icon_image(image, _potato_image), 0)
		UiStyle.style_button(row, "ghost", ACCENT, 22)
		var _err = row.connect("pressed", self, "load_tato", [entry.id])
		_list_box.add_child(row)


func _refresh_worn() -> void:
	for player_index in _worn_buttons.size():
		var wearing: bool = _current_id != "" and store.worn_by(player_index) == _current_id
		UiStyle.style_button(_worn_buttons[player_index], "primary" if wearing else "ghost", ACCENT, 22)


func _process(_delta: float) -> void:
	if not _preview_dirty or _canvas == null:
		return
	_preview_dirty = false
	var image: Image = _canvas.get_image()
	_icon_preview.texture = _texture_from(TatoStore.icon_image(image, _potato_image), 0)
	var body := Image.new()
	body.create(TatoStore.OVERLAY, TatoStore.OVERLAY, false, Image.FORMAT_RGBA8)
	if _potato_image != null:
		body.blend_rect(_potato_image, Rect2(0, 0, TatoStore.OVERLAY, TatoStore.OVERLAY), Vector2.ZERO)
	body.blend_rect(TatoStore.overlay_image(image), Rect2(0, 0, TatoStore.OVERLAY, TatoStore.OVERLAY), Vector2.ZERO)
	_body_preview.texture = _texture_from(body, 0)


func _on_canvas_changed() -> void:
	_preview_dirty = true


func _on_color_picked(color: Color) -> void:
	select_color(color)


func _on_undo() -> void:
	_canvas.undo()


func _on_clear() -> void:
	_canvas.clear()


func _on_grid() -> void:
	_canvas.show_grid = not _canvas.show_grid
	_canvas.update()


func _on_download() -> void:
	if legend != null:
		legend.open_broeditor_page()


func _on_import() -> void:
	var dialog := FileDialog.new()
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PoolStringArray(["*.png ; PNG"])
	dialog.window_title = tr("CLC_TATOS_IMPORT")
	dialog.rect_min_size = Vector2(1000, 640)
	dialog.pause_mode = Node.PAUSE_MODE_PROCESS
	var _err = dialog.connect("file_selected", self, "import_png")
	_err = dialog.connect("popup_hide", dialog, "queue_free")
	_root.add_child(dialog)
	dialog.popup_centered()


# --- Utilidades -----------------------------------------------------------------------

func _unique_id(base: String) -> String:
	var taken := {}
	for entry in store.list():
		taken[entry.id] = true
	var id := base
	var suffix := 2
	while taken.has(id):
		id = "%s_%d" % [base, suffix]
		suffix += 1
	return id


func _blank() -> Image:
	var image := Image.new()
	image.create(TatoStore.CANVAS, TatoStore.CANVAS, false, Image.FORMAT_RGBA8)
	return image


# La patata del juego como guía y fondo de los iconos; sin juego (pruebas),
# una patata dibujada.
func _load_potato_image() -> Image:
	var texture := Compat.potato_texture()
	if texture != null:
		var data = texture.get_data()
		if data is Image:
			var image := Image.new()
			image.copy_from(data)
			if image.is_compressed():
				var _err = image.decompress()
			image.convert(Image.FORMAT_RGBA8)
			image.resize(TatoStore.OVERLAY, TatoStore.OVERLAY, Image.INTERPOLATE_BILINEAR)
			return image
	return fallback_potato()


static func fallback_potato() -> Image:
	var image := Image.new()
	image.create(TatoStore.OVERLAY, TatoStore.OVERLAY, false, Image.FORMAT_RGBA8)
	image.lock()
	var center := Vector2(75, 80)
	for y in TatoStore.OVERLAY:
		for x in TatoStore.OVERLAY:
			var d := Vector2((x - center.x) / 52.0, (y - center.y) / 62.0)
			var distance: float = d.length()
			if distance <= 1.0:
				image.set_pixel(x, y, Color("c98b4f") if distance < 0.93 else Color("6b3e22"))
	image.unlock()
	return image


func _texture_from(image: Image, flags: int = Texture.FLAG_FILTER) -> ImageTexture:
	if image == null:
		return null
	var texture := ImageTexture.new()
	texture.create_from_image(image, flags)
	return texture


func _preview_rect(size: int) -> TextureRect:
	var rect := TextureRect.new()
	rect.rect_min_size = Vector2(size, size)
	rect.expand = true
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _swatch_style(color: Color, chosen: bool) -> StyleBoxFlat:
	if chosen:
		return UiStyle.bordered(color, 10, UiStyle.TEXT, 3, Vector2.ZERO)
	return UiStyle.box(color, 10, Vector2.ZERO)


func _button(text: String, method: String, args: Array, kind: String, font_size: int = 24) -> Button:
	var button := Button.new()
	button.text = text
	button.rect_min_size = Vector2(0, 52)
	UiStyle.style_button(button, kind, ACCENT, font_size)
	var _err = button.connect("pressed", self, method, args)
	return button


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
	chip.add_stylebox_override("panel", UiStyle.box(background, 12, Vector2(14, 6)))
	chip.add_child(_label(text, "small", color))
	return chip
