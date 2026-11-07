extends CanvasLayer

# Ventana de La Leyenda del Regalo, construida por código.
#
# En la tienda cooperativa el juego mueve el foco de cada mando con sus propios
# «FocusEmulator», que consumen la entrada. Mientras esta ventana está abierta
# se pausan y la ventana gestiona su propia navegación: arriba/izquierda y
# abajo/derecha recorren los botones, aceptar pulsa y atrás cierra. Funciona
# con cualquier mando, teclado o ratón.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")
const Heart = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/heart.gd")
const FocusGuard = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/focus_guard.gd")
const CONFIRM_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/gift_legend/gift_confirm.gd"
const ICON_SIZE := Vector2(68, 68)

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
var _confirm: Node = null
var _fonts := {}


func _init() -> void:
	layer = 111
	pause_mode = Node.PAUSE_MODE_PROCESS


func open(p_legend, p_shop: Node, p_giver: int, return_focus: Control = null) -> void:
	legend = p_legend
	shop = p_shop
	giver = p_giver
	_return_focus = return_focus
	_paused_emulators = FocusGuard.pause(get_tree())
	_build()
	_rebuild_rows()


func close() -> void:
	FocusGuard.resume(_paused_emulators)
	if _return_focus != null and is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		if Compat.is_coop_run():
			Compat.focus_player_control(_return_focus, giver)
		else:
			_return_focus.call_deferred("grab_focus")
	queue_free()


func _exit_tree() -> void:
	FocusGuard.resume(_paused_emulators)
	if _confirm != null and is_instance_valid(_confirm):
		_confirm.queue_free()


# --- Entrada propia ----------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouse or (_confirm != null and is_instance_valid(_confirm)):
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


# --- Construcción -------------------------------------------------------------

func _build() -> void:
	_fonts = {
		"title": UiStyle.font(46, 2),
		"name": UiStyle.font(28),
		"body": UiStyle.font(24),
		"small": UiStyle.font(21),
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
	dim.color = Color(0.03, 0.02, 0.06, 0.84)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var outer := MarginContainer.new()
	outer.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	for side in ["margin_left", "margin_right"]:
		outer.add_constant_override(side, 250)
	for side in ["margin_top", "margin_bottom"]:
		outer.add_constant_override(side, 60)
	root.add_child(outer)

	var panel := PanelContainer.new()
	panel.add_stylebox_override("panel", UiStyle.panel_box())
	outer.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 14)
	panel.add_child(layout)

	var header := HBoxContainer.new()
	header.add_constant_override("separation", 16)
	layout.add_child(header)
	var heart := Heart.new()
	heart.color = UiStyle.BRAND
	heart.rect_min_size = Vector2(50, 50)
	heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(heart)
	var title := _make_label(tr("CLC_GIFT_TITLE"), UiStyle.TEXT, "title", false)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title)
	var name_key := Compat.get_character_name_key(giver)
	var player_text: String = "J%d" % (giver + 1) if name_key == "" else "J%d · %s" % [giver + 1, tr(name_key)]
	var player_chip := _make_chip(player_text, UiStyle.INK, Compat.player_color(giver))
	player_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(player_chip)

	_info_label = _make_label("", UiStyle.MUTED, "small")
	layout.add_child(_info_label)

	_message_label = _make_label("", UiStyle.OK, "body")
	_message_label.visible = false
	layout.add_child(_message_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	scroll.follow_focus = true
	layout.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_constant_override("separation", 10)
	scroll.add_child(_list)

	_close_button = Button.new()
	_close_button.text = tr("CLC_GIFT_CLOSE")
	_close_button.rect_min_size = Vector2(200, 0)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	UiStyle.style_button(_close_button, "ghost", UiStyle.BRAND, 26)
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
		_list.add_child(_make_label(tr("CLC_GIFT_EMPTY"), UiStyle.MUTED, "body"))
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
	var tier_color := Compat.tier_color(offer.tier)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE, 16, Vector2(16, 12)))
	_list.add_child(card)

	var row := HBoxContainer.new()
	row.add_constant_override("separation", 16)
	card.add_child(row)

	var tile := PanelContainer.new()
	tile.rect_min_size = ICON_SIZE
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.add_stylebox_override("panel", UiStyle.bordered(tier_color.darkened(0.6), 14, tier_color, 2, Vector2(6, 6)))
	row.add_child(tile)
	var icon := TextureRect.new()
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Compat.item_icon(offer.data)
	tile.add_child(icon)

	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGN_CENTER
	texts.add_constant_override("separation", 4)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	var name_line := HBoxContainer.new()
	name_line.add_constant_override("separation", 8)
	texts.add_child(name_line)
	name_line.add_child(_make_label(offer.label, tier_color, "name", false))
	for tag in offer.tags:
		var chip := _make_chip(tr(tag), UiStyle.INK, UiStyle.WARN)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_line.add_child(chip)

	var first_reason := ""
	var buttons := HBoxContainer.new()
	buttons.add_constant_override("separation", 10)
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(buttons)
	for recipient in offer.recipients:
		var button := Button.new()
		var name_key := Compat.get_character_name_key(recipient.index)
		button.text = tr("CLC_GIFT_TO") % (recipient.index + 1)
		button.hint_tooltip = tr(name_key) if name_key != "" else ""
		UiStyle.style_button(button, "primary", Compat.player_color(recipient.index), 22)
		if recipient.reason != "":
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE
			button.hint_tooltip = tr(recipient.reason)
			if first_reason == "":
				first_reason = recipient.reason
		else:
			var _err = button.connect("pressed", self, "_on_gift_pressed", [offer, recipient.index])
			_nav.append(button)
		buttons.add_child(button)

	if first_reason != "":
		texts.add_child(_make_label(tr(first_reason), UiStyle.MUTED, "tiny"))


func _on_gift_pressed(offer: Dictionary, recipient: int) -> void:
	var reason: String = legend.block_reason(giver, recipient, offer.data, offer.is_weapon)
	if reason != "":
		_show_message(tr(reason), UiStyle.ERROR)
		_rebuild_rows()
		return
	var confirm_script = load(CONFIRM_PATH)
	if confirm_script == null:
		return
	_confirm = confirm_script.new()
	get_tree().root.add_child(_confirm)
	var _err = _confirm.connect("finished", self, "_on_confirm_finished", [offer, recipient])
	_confirm.open(legend, shop, giver, recipient, offer)


func _on_confirm_finished(result: String, offer: Dictionary, recipient: int) -> void:
	_confirm = null
	match result:
		"accepted":
			_show_message(tr("CLC_GIFT_DONE") % [offer.label, recipient + 1], UiStyle.OK)
		"declined":
			_show_message(tr("CLC_GIFT_DECLINED") % (recipient + 1), UiStyle.WARN)
		"withdrawn":
			_show_message(tr("CLC_GIFT_WITHDRAWN"), UiStyle.MUTED)
		_:
			_show_message(tr(result), UiStyle.ERROR)
	if is_inside_tree():
		_rebuild_rows()


func _show_message(text: String, color: Color) -> void:
	_message_label.text = text
	_message_label.add_color_override("font_color", color)
	_message_label.visible = true


func _make_header(text: String) -> Label:
	return _make_label(text.to_upper(), UiStyle.MUTED, "tiny", false)


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


func _make_chip(text: String, color: Color, background: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.add_stylebox_override("panel", UiStyle.box(background, 10, Vector2(12, 4)))
	chip.add_child(_make_label(text, color, "tiny", false))
	return chip
