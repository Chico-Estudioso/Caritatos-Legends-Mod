extends "res://mods-unpacked/Caritato-LegendsCollection/ui/legend_popup.gd"

# «¡Regalo de tu bro!»: quien recibe acepta o rechaza el regalo.
#
# Solo responde el mando o teclado de quien recibe (player_index):
# izquierda/derecha eligen, aceptar confirma y atrás rechaza. Quien regala
# puede retirarlo con atrás. El ratón solo vale si quien recibe juega con
# teclado y ratón. Arriba, dos puños (uno con el color de cada jugador) chocan
# sin parar; al aceptar se hace el regalo y chocan fuerte entre estrellas.
#
# Resultado («closed»): "accepted", "declined", "withdrawn" o la clave del
# motivo por el que no se pudo regalar.

const FistBump = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/fist_bump.gd")
const Sparkles = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/sparkles.gd")

const CELEBRATION_TIME := 1.7
const ANSWER_TIME := 1.2
const ERROR_TIME := 2.2
const BUTTON_DECLINE := 0
const BUTTON_ACCEPT := 1

var legend = null
var shop: Node = null
var giver := 0
var offer := {}

var _buttons := []
var _focus_index := BUTTON_ACCEPT
var _bros: Control = null
var _sparkles: Control = null
var _title: Label = null
var _subtitle: Label = null
var _question: Label = null
var _buttons_box: Control = null
var _hints: Control = null
var _tween: Tween = null


func _init() -> void:
	accent = UiStyle.BRAND


func setup(p_legend, p_shop: Node, p_giver: int, p_recipient: int, p_offer: Dictionary) -> void:
	legend = p_legend
	shop = p_shop
	giver = p_giver
	player_index = p_recipient
	offer = p_offer


func recipient() -> int:
	return player_index


func _after_open() -> void:
	_set_focus(BUTTON_ACCEPT)


# --- Entrada ---------------------------------------------------------------------

func _handle_input(event: InputEvent) -> void:
	if _is_released(event, "ui_cancel") or _is_released(event, "ui_pause"):
		decline()
	elif giver != player_index and (_is_released(event, "ui_cancel", giver) or _is_released(event, "ui_pause", giver)):
		withdraw()
	elif _is_pressed(event, "ui_left") or _is_pressed(event, "ui_up"):
		_set_focus(BUTTON_DECLINE)
	elif _is_pressed(event, "ui_right") or _is_pressed(event, "ui_down"):
		_set_focus(BUTTON_ACCEPT)
	elif _is_pressed(event, "ui_accept"):
		_activate(_focus_index)


func _set_focus(index: int) -> void:
	_focus_index = index
	if index < _buttons.size() and is_instance_valid(_buttons[index]):
		_buttons[index].grab_focus()


func _activate(index: int) -> void:
	if index == BUTTON_ACCEPT:
		accept()
	else:
		decline()


func _on_button_pressed(index: int) -> void:
	if mouse_allowed():
		_activate(index)


# --- Resultado -------------------------------------------------------------------

func accept() -> void:
	if is_closing():
		return
	var error_key := ""
	if legend != null:
		error_key = legend.gift(shop, giver, player_index, offer.data, offer.is_weapon)
	if error_key != "":
		_answer(tr(error_key), UiStyle.ERROR, error_key, ERROR_TIME)
	else:
		celebrate()


func decline() -> void:
	if not is_closing():
		_answer(tr("CLC_GIFT_DECLINED") % (player_index + 1), UiStyle.WARN, "declined", ANSWER_TIME)


func withdraw() -> void:
	if not is_closing():
		_answer(tr("CLC_GIFT_WITHDRAWN") % (giver + 1), UiStyle.MUTED, "withdrawn", ANSWER_TIME)


func celebrate() -> void:
	_hide_controls([_question, _buttons_box, _hints])
	_title.text = tr("CLC_GIFT_RECEIVED_TITLE")
	_subtitle.text = tr("CLC_GIFT_RECEIVED_TEXT") % [player_index + 1, offer.label]
	_subtitle.add_color_override("font_color", UiStyle.TEXT)
	_sparkles.burst(46)
	_bros.bump()
	_bros.rect_pivot_offset = _bros.rect_size / 2.0
	_tween.interpolate_property(_bros, "rect_scale", Vector2.ONE, Vector2(1.18, 1.18), 0.2, Tween.TRANS_BACK, Tween.EASE_OUT)
	_tween.interpolate_property(_bros, "rect_scale", Vector2(1.18, 1.18), Vector2(1.06, 1.06), 0.35, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.2)
	var _started = _tween.start()
	close_later(CELEBRATION_TIME, "accepted")


# Muestra la respuesta un momento (sin mover la tarjeta) y cierra.
func _answer(text: String, color: Color, p_result: String, seconds: float) -> void:
	_hide_controls([_buttons_box, _hints])
	_question.text = text
	_question.add_color_override("font_color", color)
	close_later(seconds, p_result)


func _hide_controls(controls: Array) -> void:
	for control in controls:
		control.modulate.a = 0.0
	for button in _buttons:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE


# --- Construcción ------------------------------------------------------------------

func _build_content(layout: VBoxContainer) -> void:
	_tween = Tween.new()
	_tween.pause_mode = Node.PAUSE_MODE_PROCESS
	add_child(_tween)

	# Choque de puños (quien regala a la izquierda, quien recibe a la derecha)
	# con estrellas que suben.
	var bros_area := _stage(190)
	layout.add_child(bros_area)
	_sparkles = _fill(Sparkles.new())
	_sparkles.tints = [Compat.player_color(giver), Compat.player_color(player_index), UiStyle.SPARK, UiStyle.BRAND_LIGHT]
	bros_area.add_child(_sparkles)
	_bros = FistBump.new()
	_bros.color = Compat.player_color(giver)
	_bros.color_right = Compat.player_color(player_index)
	_bros.spark_color = UiStyle.SPARK
	_bros.animate = true
	_bros.rect_min_size = Vector2(340, 176)
	_bros.rect_size = Vector2(340, 176)
	_bros.anchor_left = 0.5
	_bros.anchor_right = 0.5
	_bros.margin_left = -170
	_bros.margin_right = 170
	_bros.margin_top = 7
	_bros.margin_bottom = 183
	bros_area.add_child(_bros)

	_title = _label(tr("CLC_GIFT_CONFIRM_TITLE"), "title", UiStyle.BRAND)
	layout.add_child(_title)

	var name_key := Compat.get_character_name_key(giver)
	var from_text: String = tr("CLC_GIFT_CONFIRM_FROM") % [giver + 1, tr(name_key)] if name_key != "" else tr("CLC_GIFT_CONFIRM_FROM_SHORT") % (giver + 1)
	_subtitle = _label(from_text, "body", Compat.player_color(giver))
	layout.add_child(_subtitle)

	layout.add_child(_offer_card())

	_question = _label(tr("CLC_GIFT_CONFIRM_QUESTION") % (player_index + 1), "name", UiStyle.TEXT)
	layout.add_child(_question)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 24)
	layout.add_child(buttons)
	_buttons_box = buttons

	var decline_button := Button.new()
	decline_button.text = tr("CLC_GIFT_DECLINE")
	decline_button.rect_min_size = Vector2(240, 64)
	UiStyle.style_button(decline_button, "ghost", UiStyle.BRAND, 28)
	var _err = decline_button.connect("pressed", self, "_on_button_pressed", [BUTTON_DECLINE])
	buttons.add_child(decline_button)

	var accept_button := Button.new()
	accept_button.text = tr("CLC_GIFT_ACCEPT")
	accept_button.rect_min_size = Vector2(280, 64)
	UiStyle.style_button(accept_button, "primary", UiStyle.BRAND, 30)
	_err = accept_button.connect("pressed", self, "_on_button_pressed", [BUTTON_ACCEPT])
	buttons.add_child(accept_button)
	_buttons = [decline_button, accept_button]

	var hints := VBoxContainer.new()
	hints.add_constant_override("separation", 2)
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(hints)
	_hints = hints
	hints.add_child(_label(tr("CLC_GIFT_CONFIRM_WHO") % (player_index + 1), "small", Compat.player_color(player_index)))
	hints.add_child(_label(tr("CLC_GIFT_CONFIRM_WITHDRAW") % (giver + 1), "tiny", UiStyle.MUTED))


func _offer_card() -> Control:
	var holder := _item_card(offer.get("data"), str(offer.get("label", "")), int(offer.get("tier", 0)))
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGN_CENTER
	chips.add_constant_override("separation", 8)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kind_key := "CLC_GIFT_KIND_WEAPON" if offer.get("is_weapon", false) else "CLC_GIFT_KIND_ITEM"
	chips.add_child(_chip(tr(kind_key), UiStyle.TEXT_SOFT, UiStyle.SURFACE_3))
	for tag in offer.get("tags", []):
		chips.add_child(_chip(tr(tag), UiStyle.INK, UiStyle.WARN))
	var box := VBoxContainer.new()
	box.add_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(holder)
	box.add_child(chips)
	return box
