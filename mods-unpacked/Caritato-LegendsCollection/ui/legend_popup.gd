extends CanvasLayer

# Ventana breve e interactiva de una leyenda (minijuegos y sorpresas).
#
# Las subclases construyen su contenido en _build_content() y reaccionan a
# _on_accept(), _on_cancel() y _on_direction(). En cooperativo solo responde
# el mando del jugador indicado en player_index; con -1, cualquiera. El ratón
# vale si ese jugador juega con teclado y ratón. Mientras está abierta se
# pausan los FocusEmulator de la tienda. Se abren de una en una con
# LegendsCore.show_popup() y emiten «closed» con el resultado.

signal closed(result)

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")
const FocusGuard = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/focus_guard.gd")

var accent: Color = UiStyle.BRAND
var player_index := -1
var result := ""

var _fonts := {}
var _paused := []
var _closing := false
var _card: PanelContainer = null


func _init() -> void:
	layer = 113
	pause_mode = Node.PAUSE_MODE_PROCESS


func popup_open() -> void:
	_paused = FocusGuard.pause(get_tree())
	_build()
	_after_open()


func close_popup(p_result: String = "") -> void:
	if _closing and is_queued_for_deletion():
		return
	_closing = true
	result = p_result
	FocusGuard.resume(_paused)
	emit_signal("closed", result)
	queue_free()


# Cierra al cabo de unos segundos (para que se vea el resultado).
func close_later(seconds: float, p_result: String) -> void:
	_closing = true
	result = p_result
	if not is_inside_tree():
		close_popup(p_result)
		return
	var timer := get_tree().create_timer(seconds, true)
	var _err = timer.connect("timeout", self, "close_popup", [p_result])


func is_closing() -> bool:
	return _closing


func _exit_tree() -> void:
	FocusGuard.resume(_paused)


# --- Entrada -------------------------------------------------------------------

# En Godot 3, _input se llama en todos los niveles de herencia: las subclases
# no lo redefinen, sino _handle_input().
func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		return
	get_tree().set_input_as_handled()
	if _closing:
		return
	_handle_input(event)


func _handle_input(event: InputEvent) -> void:
	if _is_released(event, "ui_cancel") or _is_released(event, "ui_pause"):
		_on_cancel()
	elif _is_pressed(event, "ui_accept"):
		_on_accept()
	elif _is_pressed(event, "ui_left") or _is_pressed(event, "ui_up"):
		_on_direction(-1)
	elif _is_pressed(event, "ui_right") or _is_pressed(event, "ui_down"):
		_on_direction(1)


func _is_pressed(event: InputEvent, action: String, who: int = -2) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	return _is_action_of(event, action, player_index if who == -2 else who)


func _is_released(event: InputEvent, action: String, who: int = -2) -> bool:
	if event.is_pressed():
		return false
	return _is_action_of(event, action, player_index if who == -2 else who)


static func _is_action_of(event: InputEvent, action: String, who: int) -> bool:
	if who >= 0:
		return Compat.is_player_action(event, action, who)
	return InputMap.has_action(action) and event.is_action(action)


func mouse_allowed() -> bool:
	return player_index < 0 or not (Compat.has_player_actions(player_index) and Compat.player_uses_gamepad(player_index))


func _on_card_gui_input(event: InputEvent) -> void:
	if _closing or not mouse_allowed():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		_on_accept()


# --- Para las subclases ----------------------------------------------------------

func _build_content(_layout: VBoxContainer) -> void:
	pass


func _after_open() -> void:
	pass


func _on_accept() -> void:
	pass


func _on_cancel() -> void:
	close_popup("cancelled")


func _on_direction(_step: int) -> void:
	pass


# --- Construcción común ------------------------------------------------------------

func _build() -> void:
	_fonts = {
		"title": UiStyle.font(52, 2),
		"big": UiStyle.font(40, 1),
		"name": UiStyle.font(32, 1),
		"body": UiStyle.font(26),
		"small": UiStyle.font(21),
		"tiny": UiStyle.font(18),
	}
	var root := Control.new()
	root.name = "LegendPopupRoot"
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var theme := UiStyle.game_theme()
	if theme != null:
		root.theme = theme
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(accent.r * 0.08, accent.g * 0.05, accent.b * 0.08, 0.84)
	dim.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	_card = PanelContainer.new()
	_card.rect_min_size = Vector2(900, 0)
	var card_style := UiStyle.bordered(UiStyle.BG, 30, accent, 3, Vector2(46, 34))
	card_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.26)
	card_style.shadow_size = 38
	_card.add_stylebox_override("panel", card_style)
	var _err = _card.connect("gui_input", self, "_on_card_gui_input")
	center.add_child(_card)

	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 16)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(layout)
	_build_content(layout)


func _label(text: String, font_key: String, color: Color, wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.align = Label.ALIGN_CENTER
	label.autowrap = wrap
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_color_override("font_color", color)
	var label_font = _fonts.get(font_key)
	if label_font != null:
		label.add_font_override("font", label_font)
	return label


func _chip(text: String, color: Color, background: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_stylebox_override("panel", UiStyle.box(background, 10, Vector2(12, 4)))
	var label := _label(text, "tiny", color, false)
	chip.add_child(label)
	return chip


# Área de ancho completo y alto fijo para dibujos animados.
func _stage(height: float) -> Control:
	var stage := Control.new()
	stage.rect_min_size = Vector2(0, height)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return stage


func _fill(child: Control) -> Control:
	child.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return child


# Tarjeta de un objeto o arma: icono con el color del tier y su nombre.
func _item_card(data, label: String, tier: int) -> Control:
	var tier_color := Compat.tier_color(tier)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := PanelContainer.new()
	card.rect_min_size = Vector2(560, 0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE_2, 18, Vector2(18, 12)))
	holder.add_child(card)
	var row := HBoxContainer.new()
	row.add_constant_override("separation", 18)
	card.add_child(row)
	var tile := PanelContainer.new()
	tile.rect_min_size = Vector2(84, 84)
	tile.add_stylebox_override("panel", UiStyle.bordered(tier_color.darkened(0.55), 16, tier_color, 3, Vector2(8, 8)))
	row.add_child(tile)
	var icon := TextureRect.new()
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = Compat.item_icon(data)
	tile.add_child(icon)
	var name_label := _label(label, "name", tier_color, false)
	name_label.align = Label.ALIGN_LEFT
	name_label.valign = Label.VALIGN_CENTER
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	return holder
