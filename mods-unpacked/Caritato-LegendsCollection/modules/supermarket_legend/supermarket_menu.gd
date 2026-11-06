extends CanvasLayer

# Catálogo de La Leyenda del Supermercado, construido por código.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")

const THEME_PATH := "res://resources/themes/base_theme.tres"
const FONT_TITLE_PATH := "res://resources/fonts/actual/base/font_40_outline.tres"
const FONT_SMALL_PATH := "res://resources/fonts/actual/base/font_smallest_text.tres"
const COLOR_MUTED := Color(0.72, 0.72, 0.72)
const COLOR_ERROR := Color(1.0, 0.45, 0.4)
const ICON_SIZE := Vector2(56, 56)

var legend = null
var shop: Node = null
var player_index := 0

var _info_label: Label = null
var _message_label: Label = null
var _return_focus: Control = null
var _first_focus: Control = null
var _cancel_actions := []
var _font_small: Font = null


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
	_refresh_info()
	if _first_focus != null:
		_first_focus.call_deferred("grab_focus")


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


func _build() -> void:
	_font_small = _load_resource(FONT_SMALL_PATH) as Font

	var root := Control.new()
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var theme_resource = _load_resource(THEME_PATH)
	if theme_resource is Theme:
		root.theme = theme_resource
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var outer := MarginContainer.new()
	outer.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	outer.add_constant_override("margin_left", 220)
	outer.add_constant_override("margin_right", 220)
	outer.add_constant_override("margin_top", 60)
	outer.add_constant_override("margin_bottom", 60)
	root.add_child(outer)

	var panel := PanelContainer.new()
	outer.add_child(panel)
	var inner := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_constant_override(side, 24)
	panel.add_child(inner)

	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 12)
	inner.add_child(layout)

	var title := Label.new()
	title.text = tr("CLC_SUPER_TITLE")
	title.align = Label.ALIGN_CENTER
	var title_font = _load_resource(FONT_TITLE_PATH)
	if title_font is Font:
		title.add_font_override("font", title_font)
	layout.add_child(title)

	_info_label = _make_label("", COLOR_MUTED)
	_info_label.align = Label.ALIGN_CENTER
	layout.add_child(_info_label)

	_message_label = _make_label("", COLOR_ERROR)
	_message_label.align = Label.ALIGN_CENTER
	_message_label.visible = false
	layout.add_child(_message_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	scroll.follow_focus = true
	layout.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_constant_override("separation", 6)
	scroll.add_child(list)

	var catalog: Array = legend.get_catalog(player_index)
	if catalog.empty():
		list.add_child(_make_label(tr("CLC_SUPER_EMPTY"), COLOR_MUTED))
	for entry in catalog:
		_build_row(list, entry)

	var close_button := Button.new()
	close_button.text = tr("CLC_SUPER_CLOSE")
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var _err = close_button.connect("pressed", self, "close")
	layout.add_child(close_button)
	if _first_focus == null:
		_first_focus = close_button


func _build_row(list: VBoxContainer, entry: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_constant_override("separation", 14)
	list.add_child(row)

	var icon := TextureRect.new()
	icon.rect_min_size = ICON_SIZE
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if "icon" in entry.item and entry.item.icon is Texture:
		icon.texture = entry.item.icon
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = "%s  ·  %s" % [entry.label, tr("CLC_SUPER_TIER") % (entry.tier + 1)]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_color_override("font_color", Compat.tier_color(entry.tier))
	row.add_child(name_label)

	var price: int = legend.price_of(entry.item, player_index)
	var fee: int = legend.fee_of(entry.item, player_index)
	var price_label := Label.new()
	price_label.text = (tr("CLC_SUPER_PRICE_WITH_FEE") % [price, fee]) if fee > 0 else (tr("CLC_SUPER_PRICE") % price)
	price_label.add_color_override("font_color", COLOR_MUTED)
	if _font_small != null:
		price_label.add_font_override("font", _font_small)
	row.add_child(price_label)

	var order_button := Button.new()
	order_button.text = tr("CLC_SUPER_ORDER")
	var _err = order_button.connect("pressed", self, "_on_order_pressed", [entry])
	row.add_child(order_button)
	if _first_focus == null:
		_first_focus = order_button


func _on_order_pressed(entry: Dictionary) -> void:
	var error_key: String = legend.order(shop, entry.item, player_index)
	if error_key != "":
		_message_label.text = tr(error_key)
		_message_label.visible = true
		return
	if legend.orders_left(player_index) <= 0:
		close()
		return
	_message_label.visible = false
	_refresh_info()


func _refresh_info() -> void:
	_info_label.text = tr("CLC_SUPER_INFO") % legend.orders_left(player_index)


func _make_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_color_override("font_color", color)
	if _font_small != null:
		label.add_font_override("font", _font_small)
	return label


static func _load_resource(path: String):
	if ResourceLoader.exists(path):
		return load(path)
	return null
