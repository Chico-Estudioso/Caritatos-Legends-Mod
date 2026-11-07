extends CanvasLayer

# Catálogo de La Leyenda del Supermercado, construido por código.
#
# Muestra los encargos disponibles, el recargo y una tarjeta por artículo. Lo
# encargado no aparece en esta tienda: llega bloqueado a la siguiente.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")

const ACCENT := Color("ff8c42")
const ICON_SIZE := Vector2(64, 64)

var legend = null
var shop: Node = null
var player_index := 0

var _status_chip: PanelContainer = null
var _status_label: Label = null
var _lock_notice: Control = null
var _message_label: Label = null
var _close_button: Button = null
var _order_buttons := []
var _return_focus: Control = null
var _cancel_actions := []
var _fonts := {}


func _init() -> void:
	layer = 111
	pause_mode = Node.PAUSE_MODE_PROCESS


func open(p_legend, p_shop: Node, p_player_index: int, return_focus: Control = null) -> void:
	legend = p_legend
	shop = p_shop
	player_index = p_player_index
	_return_focus = return_focus
	for action in InputMap.get_actions():
		var action_name := str(action)
		if action_name.begins_with("ui_cancel") or action_name.begins_with("ui_pause"):
			_cancel_actions.append(action_name)
	_build()
	_refresh()


func close() -> void:
	if _return_focus != null and is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.call_deferred("grab_focus")
	queue_free()


func _input(event: InputEvent) -> void:
	for action in _cancel_actions:
		if event.is_action(action):
			get_tree().set_input_as_handled()
			if event.is_action_released(action):
				close()
			return


# --- Construcción -------------------------------------------------------------

func _build() -> void:
	_fonts = {
		"title": UiStyle.font(46, 2),
		"name": UiStyle.font(26),
		"body": UiStyle.font(23),
		"small": UiStyle.font(20),
		"tiny": UiStyle.font(18),
	}

	var root := Control.new()
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var theme := UiStyle.game_theme()
	if theme != null:
		root.theme = theme
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.86)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var outer := MarginContainer.new()
	outer.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	for side in ["margin_left", "margin_right"]:
		outer.add_constant_override(side, 150)
	for side in ["margin_top", "margin_bottom"]:
		outer.add_constant_override(side, 56)
	root.add_child(outer)

	var panel := PanelContainer.new()
	var panel_style := UiStyle.bordered(UiStyle.BG, 24, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.6), 2, Vector2(32, 28))
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 24
	panel.add_stylebox_override("panel", panel_style)
	outer.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 14)
	panel.add_child(layout)

	# Cabecera
	var header := HBoxContainer.new()
	header.add_constant_override("separation", 16)
	layout.add_child(header)
	var tile := PanelContainer.new()
	tile.rect_min_size = Vector2(58, 58)
	tile.add_stylebox_override("panel", UiStyle.box(ACCENT, 16, Vector2.ZERO))
	var letter := _make_label("S", UiStyle.INK, "title", false)
	letter.align = Label.ALIGN_CENTER
	letter.valign = Label.VALIGN_CENTER
	tile.add_child(letter)
	header.add_child(tile)
	var titles := VBoxContainer.new()
	titles.add_constant_override("separation", 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(_make_label(tr("CLC_SUPER_TITLE"), UiStyle.TEXT, "title", false))
	titles.add_child(_make_label(tr("CLC_SUPER_INFO") % int(legend.get_setting("order_markup_percent", 50)), UiStyle.MUTED, "small"))
	header.add_child(titles)
	_status_chip = PanelContainer.new()
	_status_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_label = _make_label("", UiStyle.INK, "body", false)
	_status_chip.add_child(_status_label)
	header.add_child(_status_chip)

	_lock_notice = _make_notice(tr("CLC_SUPER_LOCKED_NOTICE"), UiStyle.WARN)
	layout.add_child(_lock_notice)

	_message_label = _make_label("", UiStyle.OK, "body")
	_message_label.visible = false
	layout.add_child(_message_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	scroll.follow_focus = true
	layout.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_constant_override("hseparation", 12)
	grid.add_constant_override("vseparation", 12)
	scroll.add_child(grid)

	var catalog: Array = legend.get_catalog(player_index)
	if catalog.empty():
		layout.add_child(_make_label(tr("CLC_SUPER_EMPTY"), UiStyle.MUTED, "body"))
	for entry in catalog:
		grid.add_child(_build_card(entry))

	_close_button = Button.new()
	_close_button.text = tr("CLC_SUPER_CLOSE")
	_close_button.rect_min_size = Vector2(200, 0)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	UiStyle.style_button(_close_button, "ghost", ACCENT, 26)
	var _err = _close_button.connect("pressed", self, "close")
	layout.add_child(_close_button)


func _build_card(entry: Dictionary) -> Control:
	var tier_color := Compat.tier_color(entry.tier)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE, 16, Vector2(14, 12)))

	var row := HBoxContainer.new()
	row.add_constant_override("separation", 14)
	card.add_child(row)

	var tile := PanelContainer.new()
	tile.rect_min_size = ICON_SIZE
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.add_stylebox_override("panel", UiStyle.bordered(tier_color.darkened(0.6), 14, tier_color, 2, Vector2(6, 6)))
	var icon := TextureRect.new()
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Compat.item_icon(entry.item)
	tile.add_child(icon)
	row.add_child(tile)

	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGN_CENTER
	texts.add_constant_override("separation", 4)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	texts.add_child(_make_label(entry.label, tier_color, "name"))
	var price: int = legend.price_of(entry.item, player_index)
	var fee: int = legend.fee_of(entry.item, player_index)
	var price_text: String = tr("CLC_SUPER_PRICE_WITH_FEE") % [fee, price] if fee > 0 else tr("CLC_SUPER_PRICE") % price
	texts.add_child(_make_label(price_text, UiStyle.TEXT_SOFT, "small"))
	var kind := tr("CLC_GIFT_KIND_WEAPON") if entry.is_weapon else tr("CLC_GIFT_KIND_ITEM")
	texts.add_child(_make_label("%s · %s" % [tr("CLC_SUPER_TIER") % (entry.tier + 1), kind], UiStyle.MUTED, "tiny"))

	var order_button := Button.new()
	order_button.text = tr("CLC_SUPER_ORDER")
	order_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(order_button, "primary", ACCENT, 22)
	var _err = order_button.connect("pressed", self, "_on_order_pressed", [entry])
	row.add_child(order_button)
	_order_buttons.append(order_button)
	return card


# --- Estado ----------------------------------------------------------------------

func _refresh() -> void:
	var left: int = legend.orders_left(player_index)
	var unlocked: bool = legend.is_unlocked()
	var can_order := unlocked and left > 0
	_status_label.text = tr("CLC_SUPER_ORDERS_LEFT") % left if unlocked else tr("CLC_SUPER_LOCKED")
	_status_chip.add_stylebox_override("panel", UiStyle.box(ACCENT if can_order else UiStyle.OFF, 12, Vector2(16, 6)))
	_status_label.add_color_override("font_color", UiStyle.INK if can_order else UiStyle.TEXT_SOFT)
	_lock_notice.visible = not unlocked
	for button in _order_buttons:
		button.disabled = not can_order
		button.focus_mode = Control.FOCUS_ALL if can_order else Control.FOCUS_NONE
	var first: Control = _order_buttons[0] if can_order and not _order_buttons.empty() else _close_button
	first.call_deferred("grab_focus")


func _on_order_pressed(entry: Dictionary) -> void:
	var error_key: String = legend.order(shop, entry.item, player_index)
	_message_label.visible = true
	if error_key != "":
		_message_label.text = tr(error_key)
		_message_label.add_color_override("font_color", UiStyle.ERROR)
		return
	_message_label.text = tr("CLC_SUPER_ORDERED") % entry.label
	_message_label.add_color_override("font_color", UiStyle.OK)
	_refresh()


# --- Utilidades ------------------------------------------------------------------

func _make_label(text: String, color: Color, font_key: String = "small", wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap = wrap
	if wrap:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_color_override("font_color", color)
	var label_font = _fonts.get(font_key)
	if label_font != null:
		label.add_font_override("font", label_font)
	return label


func _make_notice(text: String, color: Color) -> Control:
	var notice := PanelContainer.new()
	var background := Color(color.r, color.g, color.b, 0.14)
	notice.add_stylebox_override("panel", UiStyle.bordered(background, 12, Color(color.r, color.g, color.b, 0.55), 2, Vector2(18, 10)))
	notice.add_child(_make_label(text, color, "body"))
	return notice
