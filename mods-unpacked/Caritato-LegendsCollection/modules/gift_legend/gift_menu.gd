extends CanvasLayer

# Ventana de La Leyenda del Regalo, construida por código.
#
# En la tienda cooperativa el juego mueve el foco de cada mando con sus propios
# «FocusEmulator», que consumen la entrada. Mientras esta ventana está abierta
# se pausan y la ventana gestiona su propia navegación: arriba/izquierda y
# abajo/derecha recorren los botones, aceptar pulsa y atrás cierra. Funciona
# con cualquier mando, teclado o ratón.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")

const THEME_PATH := "res://resources/themes/base_theme.tres"
const FONT_TITLE_PATH := "res://resources/fonts/actual/base/font_40_outline.tres"
const FONT_SMALL_PATH := "res://resources/fonts/actual/base/font_smallest_text.tres"
const FOCUS_EMULATOR_SCRIPT_SUFFIX := "focus_emulator.gd"
const COLOR_MUTED := Color(0.72, 0.72, 0.72)
const COLOR_OK := Color(0.55, 0.85, 0.45)
const COLOR_ERROR := Color(1.0, 0.45, 0.4)
const ICON_SIZE := Vector2(52, 52)

var legend = null
var shop: Node = null
var giver := 0

var _list: VBoxContainer = null
var _info_label: Label = null
var _message_label: Label = null
var _close_button: Button = null
var _return_focus: Control = null
var _nav := []
var _nav_index := 0
var _paused_emulators := []
var _font_small: Font = null


func _init() -> void:
	layer = 111
	pause_mode = Node.PAUSE_MODE_PROCESS


func open(p_legend, p_shop: Node, p_giver: int, return_focus: Control = null) -> void:
	legend = p_legend
	shop = p_shop
	giver = p_giver
	_return_focus = return_focus
	_pause_focus_emulators()
	_build()
	_rebuild_rows()


func close() -> void:
	_resume_focus_emulators()
	if _return_focus != null and is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		if Compat.is_coop_run():
			Compat.focus_player_control(_return_focus, giver)
		else:
			_return_focus.call_deferred("grab_focus")
	queue_free()


func _exit_tree() -> void:
	_resume_focus_emulators()


# --- Entrada propia ----------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	if _is_action(event, "ui_cancel") or _is_action(event, "ui_pause"):
		get_tree().set_input_as_handled()
		if event.is_action_released("ui_cancel") or event.is_action_released("ui_pause"):
			close()
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
		_move_focus(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		_move_focus(1)
	elif event.is_action_pressed("ui_accept"):
		_press_focused()
	elif not (event.is_action("ui_up") or event.is_action("ui_down") or event.is_action("ui_left") or event.is_action("ui_right") or event.is_action("ui_accept")):
		return
	get_tree().set_input_as_handled()


static func _is_action(event: InputEvent, action: String) -> bool:
	return InputMap.has_action(action) and event.is_action(action)


func _move_focus(step: int) -> void:
	if _nav.empty():
		return
	_nav_index = int(clamp(_nav_index + step, 0, _nav.size() - 1))
	_focus_current()


func _focus_current() -> void:
	if _nav.empty():
		return
	var control: Control = _nav[_nav_index]
	if is_instance_valid(control):
		control.grab_focus()


func _press_focused() -> void:
	if _nav.empty():
		return
	var control = _nav[_nav_index]
	if is_instance_valid(control) and control is BaseButton and not control.disabled:
		control.emit_signal("pressed")


# --- Emuladores de foco del juego -------------------------------------------------

func _pause_focus_emulators() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var pending := [scene]
	while not pending.empty():
		var node: Node = pending.pop_back()
		var script = node.get_script()
		if script != null and str(script.resource_path).ends_with(FOCUS_EMULATOR_SCRIPT_SUFFIX):
			# Igual que hace el juego al pausar: se ocultan y dejan de leer la entrada.
			_paused_emulators.append({
				"node": node,
				"input": node.is_processing_input(),
				"visible": node.visible if "visible" in node else true,
			})
			node.set_process_input(false)
			if "visible" in node:
				node.visible = false
		for child in node.get_children():
			pending.append(child)


func _resume_focus_emulators() -> void:
	for entry in _paused_emulators:
		var node = entry.node
		if not is_instance_valid(node):
			continue
		node.set_process_input(entry.input)
		if "visible" in node:
			node.visible = entry.visible
	_paused_emulators.clear()


# --- Construcción -------------------------------------------------------------

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
	for side in ["margin_left", "margin_right"]:
		outer.add_constant_override(side, 240)
	for side in ["margin_top", "margin_bottom"]:
		outer.add_constant_override(side, 60)
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
	title.text = tr("CLC_GIFT_TITLE") % [giver + 1, tr(Compat.get_character_name_key(giver))]
	title.align = Label.ALIGN_CENTER
	var title_font = _load_resource(FONT_TITLE_PATH)
	if title_font is Font:
		title.add_font_override("font", title_font)
	layout.add_child(title)

	_info_label = _make_label("", COLOR_MUTED)
	_info_label.align = Label.ALIGN_CENTER
	layout.add_child(_info_label)

	_message_label = _make_label("", COLOR_OK)
	_message_label.align = Label.ALIGN_CENTER
	_message_label.visible = false
	layout.add_child(_message_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	scroll.follow_focus = true
	layout.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_constant_override("separation", 8)
	scroll.add_child(_list)

	_close_button = Button.new()
	_close_button.text = tr("CLC_GIFT_CLOSE")
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var _err = _close_button.connect("pressed", self, "close")
	layout.add_child(_close_button)


func _rebuild_rows() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_nav = []

	var left: int = legend.gifts_left(giver)
	_info_label.text = tr("CLC_GIFT_INFO") if left < 0 else tr("CLC_GIFT_INFO_LIMIT") % left

	var offers: Array = legend.get_offers(giver)
	var weapons := []
	var items := []
	for offer in offers:
		if offer.is_weapon:
			weapons.append(offer)
		else:
			items.append(offer)

	if offers.empty():
		_list.add_child(_make_label(tr("CLC_GIFT_EMPTY"), COLOR_MUTED))
	if not weapons.empty():
		_list.add_child(_make_header(tr("CLC_GIFT_WEAPONS")))
		for offer in weapons:
			_build_row(offer)
	if not items.empty():
		_list.add_child(_make_header(tr("CLC_GIFT_ITEMS")))
		for offer in items:
			_build_row(offer)

	_nav.append(_close_button)
	_nav_index = int(clamp(_nav_index, 0, _nav.size() - 1))
	call_deferred("_focus_current")


func _build_row(offer: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_constant_override("separation", 2)
	_list.add_child(box)

	var row := HBoxContainer.new()
	row.add_constant_override("separation", 12)
	box.add_child(row)

	var icon := TextureRect.new()
	icon.rect_min_size = ICON_SIZE
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if "icon" in offer.data and offer.data.icon is Texture:
		icon.texture = offer.data.icon
	row.add_child(icon)

	var name_label := Label.new()
	var text: String = offer.label
	for tag in offer.tags:
		text += "  [%s]" % tr(tag)
	name_label.text = text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_color_override("font_color", Compat.tier_color(offer.tier))
	row.add_child(name_label)

	var first_reason := ""
	for recipient in offer.recipients:
		var button := Button.new()
		button.text = tr("CLC_GIFT_TO") % [recipient.index + 1, tr(Compat.get_character_name_key(recipient.index))]
		if recipient.reason != "":
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE
			button.hint_tooltip = tr(recipient.reason)
			if first_reason == "":
				first_reason = recipient.reason
		else:
			var _err = button.connect("pressed", self, "_on_gift_pressed", [offer, recipient.index])
			_nav.append(button)
		row.add_child(button)

	if first_reason != "":
		var reason_label := _make_label(tr(first_reason), COLOR_MUTED)
		box.add_child(reason_label)


func _on_gift_pressed(offer: Dictionary, recipient: int) -> void:
	var error_key: String = legend.gift(shop, giver, recipient, offer.data, offer.is_weapon)
	_message_label.visible = true
	if error_key != "":
		_message_label.text = tr(error_key)
		_message_label.add_color_override("font_color", COLOR_ERROR)
	else:
		_message_label.text = tr("CLC_GIFT_DONE") % [offer.label, recipient + 1]
		_message_label.add_color_override("font_color", COLOR_OK)
	_rebuild_rows()


func _make_header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


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
