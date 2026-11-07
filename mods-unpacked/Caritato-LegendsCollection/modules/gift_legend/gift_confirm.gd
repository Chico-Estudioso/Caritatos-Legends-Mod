extends CanvasLayer

# Ventana con la que quien recibe un regalo lo acepta o lo rechaza.
#
# Solo responde el mando o teclado de quien recibe: izquierda/derecha eligen,
# aceptar confirma y atrás rechaza. Quien regala puede retirarlo con atrás.
# El ratón solo vale si quien recibe juega con teclado y ratón. Al aceptar se
# hace el regalo y sale una lluvia de corazones.
#
# Emite «finished» con "accepted", "declined", "withdrawn" o la clave del
# motivo por el que no se pudo regalar.

signal finished(result)

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")
const Heart = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/heart.gd")
const Sparkles = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/sparkles.gd")

const CELEBRATION_TIME := 1.7
const ERROR_TIME := 2.2
const BUTTON_DECLINE := 0
const BUTTON_ACCEPT := 1

var legend = null
var shop: Node = null
var giver := 0
var recipient := 1
var offer := {}

var _buttons := []
var _focus_index := BUTTON_ACCEPT
var _heart: Control = null
var _sparkles: Control = null
var _title: Label = null
var _subtitle: Label = null
var _question: Label = null
var _buttons_box: Control = null
var _hints: Control = null
var _tween: Tween = null
var _closing := false
var _result := ""


func _init() -> void:
	layer = 112
	pause_mode = Node.PAUSE_MODE_PROCESS


func open(p_legend, p_shop: Node, p_giver: int, p_recipient: int, p_offer: Dictionary) -> void:
	legend = p_legend
	shop = p_shop
	giver = p_giver
	recipient = p_recipient
	offer = p_offer
	_build()
	_set_focus(BUTTON_ACCEPT)


# --- Entrada -------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	get_tree().set_input_as_handled()
	if _closing:
		return
	if _is_released(event, "ui_cancel", recipient) or _is_released(event, "ui_pause", recipient):
		_decline()
	elif giver != recipient and (_is_released(event, "ui_cancel", giver) or _is_released(event, "ui_pause", giver)):
		_withdraw()
	elif _is_pressed(event, "ui_left", recipient) or _is_pressed(event, "ui_up", recipient):
		_set_focus(BUTTON_DECLINE)
	elif _is_pressed(event, "ui_right", recipient) or _is_pressed(event, "ui_down", recipient):
		_set_focus(BUTTON_ACCEPT)
	elif _is_pressed(event, "ui_accept", recipient):
		_activate(_focus_index)


static func _is_pressed(event: InputEvent, action: String, player_index: int) -> bool:
	return Compat.is_player_action(event, action, player_index) and event.is_pressed() and not event.is_echo()


static func _is_released(event: InputEvent, action: String, player_index: int) -> bool:
	return Compat.is_player_action(event, action, player_index) and not event.is_pressed()


func _set_focus(index: int) -> void:
	_focus_index = index
	if index < _buttons.size() and is_instance_valid(_buttons[index]):
		_buttons[index].grab_focus()


func _activate(index: int) -> void:
	if index == BUTTON_ACCEPT:
		accept()
	else:
		_decline()


func _on_button_pressed(index: int) -> void:
	# Los clics de ratón solo cuentan si quien recibe juega con teclado y ratón.
	if Compat.has_player_actions(recipient) and Compat.player_uses_gamepad(recipient):
		return
	_activate(index)


# --- Resultado ---------------------------------------------------------------

func accept() -> void:
	if _closing:
		return
	var error_key := ""
	if legend != null:
		error_key = legend.gift(shop, giver, recipient, offer.data, offer.is_weapon)
	if error_key != "":
		_show_error(error_key)
	else:
		celebrate()


func _decline() -> void:
	if not _closing:
		_finish("declined")


func _withdraw() -> void:
	if not _closing:
		_finish("withdrawn")


func celebrate() -> void:
	_closing = true
	_result = "accepted"
	_title.text = tr("CLC_GIFT_RECEIVED_TITLE")
	_subtitle.text = tr("CLC_GIFT_RECEIVED_TEXT") % [recipient + 1, offer.label]
	_subtitle.add_color_override("font_color", UiStyle.TEXT)
	# Se ocultan sin cambiar el tamaño de la tarjeta, para que nada salte.
	for control in [_question, _buttons_box, _hints]:
		control.modulate.a = 0.0
	for button in _buttons:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
	_sparkles.burst(46)
	_heart.rect_pivot_offset = _heart.rect_size / 2.0
	_tween.interpolate_property(_heart, "rect_scale", Vector2.ONE, Vector2(1.25, 1.25), 0.2, Tween.TRANS_BACK, Tween.EASE_OUT)
	_tween.interpolate_property(_heart, "rect_scale", Vector2(1.25, 1.25), Vector2(1.08, 1.08), 0.35, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.2)
	var _started = _tween.start()
	_finish_later(CELEBRATION_TIME)


func _show_error(error_key: String) -> void:
	_closing = true
	_result = error_key
	_question.text = tr(error_key)
	_question.add_color_override("font_color", UiStyle.ERROR)
	for control in [_buttons_box, _hints]:
		control.modulate.a = 0.0
	for button in _buttons:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
	_finish_later(ERROR_TIME)


func _finish_later(seconds: float) -> void:
	if not is_inside_tree():
		_finish(_result)
		return
	var timer := get_tree().create_timer(seconds, true)
	var _err = timer.connect("timeout", self, "_finish", [_result])


func _finish(result: String) -> void:
	if is_queued_for_deletion():
		return
	_closing = true
	emit_signal("finished", result)
	queue_free()


# --- Construcción -------------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.name = "GiftConfirmRoot"
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var theme := UiStyle.game_theme()
	if theme != null:
		root.theme = theme
	add_child(root)

	_tween = Tween.new()
	_tween.pause_mode = Node.PAUSE_MODE_PROCESS
	root.add_child(_tween)

	var dim := ColorRect.new()
	dim.color = Color(0.09, 0.02, 0.08, 0.84)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var card := PanelContainer.new()
	card.rect_min_size = Vector2(900, 0)
	var card_style := UiStyle.bordered(UiStyle.BG, 30, UiStyle.BRAND, 3, Vector2(46, 34))
	card_style.shadow_color = Color(UiStyle.BRAND.r, UiStyle.BRAND.g, UiStyle.BRAND.b, 0.28)
	card_style.shadow_size = 38
	card.add_stylebox_override("panel", card_style)
	center.add_child(card)

	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 16)
	card.add_child(layout)

	# Corazón con brillo y corazones que suben.
	var heart_area := Control.new()
	heart_area.rect_min_size = Vector2(0, 190)
	heart_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(heart_area)
	_sparkles = Sparkles.new()
	_sparkles.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	heart_area.add_child(_sparkles)
	_heart = Heart.new()
	_heart.color = UiStyle.BRAND
	_heart.pulse = true
	_heart.rect_min_size = Vector2(170, 170)
	_heart.rect_size = Vector2(170, 170)
	_heart.anchor_left = 0.5
	_heart.anchor_right = 0.5
	_heart.margin_left = -85
	_heart.margin_right = 85
	_heart.margin_top = 10
	_heart.margin_bottom = 180
	heart_area.add_child(_heart)

	_title = _label(tr("CLC_GIFT_CONFIRM_TITLE"), UiStyle.font(54, 2), UiStyle.BRAND)
	layout.add_child(_title)

	var name_key := Compat.get_character_name_key(giver)
	var from_text: String = tr("CLC_GIFT_CONFIRM_FROM") % [giver + 1, tr(name_key)] if name_key != "" else tr("CLC_GIFT_CONFIRM_FROM_SHORT") % (giver + 1)
	_subtitle = _label(from_text, UiStyle.font(26), Compat.player_color(giver))
	layout.add_child(_subtitle)

	layout.add_child(_build_item_card())

	_question = _label(tr("CLC_GIFT_CONFIRM_QUESTION") % (recipient + 1), UiStyle.font(32), UiStyle.TEXT)
	layout.add_child(_question)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 24)
	layout.add_child(buttons)
	_buttons_box = buttons

	var decline := Button.new()
	decline.text = tr("CLC_GIFT_DECLINE")
	decline.rect_min_size = Vector2(240, 64)
	UiStyle.style_button(decline, "ghost", UiStyle.BRAND, 28)
	var _err = decline.connect("pressed", self, "_on_button_pressed", [BUTTON_DECLINE])
	buttons.add_child(decline)

	var accept_button := Button.new()
	accept_button.text = tr("CLC_GIFT_ACCEPT")
	accept_button.rect_min_size = Vector2(280, 64)
	UiStyle.style_button(accept_button, "primary", UiStyle.BRAND, 30)
	_err = accept_button.connect("pressed", self, "_on_button_pressed", [BUTTON_ACCEPT])
	buttons.add_child(accept_button)
	_buttons = [decline, accept_button]

	var hints := VBoxContainer.new()
	hints.add_constant_override("separation", 2)
	layout.add_child(hints)
	_hints = hints
	hints.add_child(_label(tr("CLC_GIFT_CONFIRM_WHO") % (recipient + 1), UiStyle.font(21), Compat.player_color(recipient)))
	hints.add_child(_label(tr("CLC_GIFT_CONFIRM_WITHDRAW") % (giver + 1), UiStyle.font(19), UiStyle.MUTED))


func _build_item_card() -> Control:
	var tier: int = int(offer.get("tier", 0))
	var tier_color := Compat.tier_color(tier)

	var holder := CenterContainer.new()
	var item_card := PanelContainer.new()
	item_card.rect_min_size = Vector2(620, 0)
	item_card.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE_2, 20, Vector2(22, 16)))
	holder.add_child(item_card)

	var row := HBoxContainer.new()
	row.add_constant_override("separation", 22)
	item_card.add_child(row)

	var tile := PanelContainer.new()
	tile.rect_min_size = Vector2(110, 110)
	tile.add_stylebox_override("panel", UiStyle.bordered(tier_color.darkened(0.55), 18, tier_color, 3, Vector2(10, 10)))
	row.add_child(tile)
	var icon := TextureRect.new()
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Compat.item_icon(offer.get("data"))
	tile.add_child(icon)

	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGN_CENTER
	texts.add_constant_override("separation", 8)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	var name_label := _label(str(offer.get("label", "")), UiStyle.font(36, 1), tier_color)
	name_label.align = Label.ALIGN_LEFT
	texts.add_child(name_label)

	var chips := HBoxContainer.new()
	chips.add_constant_override("separation", 8)
	texts.add_child(chips)
	var kind_key := "CLC_GIFT_KIND_WEAPON" if offer.get("is_weapon", false) else "CLC_GIFT_KIND_ITEM"
	chips.add_child(_chip(tr(kind_key), UiStyle.TEXT_SOFT, UiStyle.SURFACE_3))
	for tag in offer.get("tags", []):
		chips.add_child(_chip(tr(tag), UiStyle.INK, UiStyle.WARN))
	return holder


func _label(text: String, label_font: Font, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.align = Label.ALIGN_CENTER
	label.autowrap = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_color_override("font_color", color)
	if label_font != null:
		label.add_font_override("font", label_font)
	return label


func _chip(text: String, color: Color, background: Color) -> Control:
	var chip := PanelContainer.new()
	chip.add_stylebox_override("panel", UiStyle.box(background, 10, Vector2(12, 4)))
	var label := Label.new()
	label.text = text
	label.add_color_override("font_color", color)
	var chip_font := UiStyle.font(20)
	if chip_font != null:
		label.add_font_override("font", chip_font)
	chip.add_child(label)
	return chip
