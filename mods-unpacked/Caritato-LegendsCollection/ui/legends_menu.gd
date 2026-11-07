extends CanvasLayer

# Pantalla de configuración de Caritatopc, con forma de biblioteca.
#
# A la izquierda, una tarjeta por leyenda con su estado. A la derecha, la ficha
# de la leyenda elegida: interruptor, descripción breve, ajustes y una línea de
# ayuda que explica el ajuste que tiene el foco (así no hay texto de más).
# Se construye por código para no depender de escenas. Los valores se aplican
# al momento; «Cancelar» deshace los cambios y «Guardar» los escribe en disco.

signal closed

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")
const Switch = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/switch.gd")
const Heart = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/heart.gd")
const FocusGuard = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/focus_guard.gd")

const NAV_ACTIONS := ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept"]
# Marca de las acciones que esta pantalla reenvía a la interfaz.
const FORWARDED_DEVICE := -77

const DLC_NAME_KEYS := {
	"abyssal_terrors": "CLC_DLC_ABYSSAL_TERRORS",
}

var core = null
var context := "title"

var _snapshot := {}
var _selected := ""
# id -> {button, dot, label}
var _cards := {}
# Ficha abierta: {id, toggle, status, controls: [{key, type, control, value_label, row, ...}]}
var _detail := {}
var _detail_box: VBoxContainer = null
var _hint_label: Label = null
var _restart_banner: Control = null
var _message_label: Label = null
var _previous_focus: Control = null
var _refreshing := false
var _cancel_actions := []
# «ui_up_3» -> «ui_up»: acciones de cada mando o teclado en cooperativo.
var _nav_variants := {}
var _paused_emulators := []
var _fonts := {}
var _dots := {}


func _init() -> void:
	layer = 110
	pause_mode = Node.PAUSE_MODE_PROCESS


func open(p_core, p_context: String = "title", p_return_focus: Control = null) -> void:
	core = p_core
	context = p_context
	_previous_focus = p_return_focus
	_snapshot = core.snapshot()
	_collect_cancel_actions()
	_collect_nav_actions()
	# En cooperativo, los FocusEmulator del menú de pausa se comen la entrada.
	_paused_emulators = FocusGuard.pause(get_tree())
	_build()
	var ids: Array = core.get_module_ids()
	if not ids.empty():
		_select(ids[0])
		_cards[ids[0]].button.call_deferred("grab_focus")
	_refresh_all()


func close() -> void:
	FocusGuard.resume(_paused_emulators)
	emit_signal("closed")
	if _previous_focus != null and is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.call_deferred("grab_focus")
	queue_free()


func _exit_tree() -> void:
	FocusGuard.resume(_paused_emulators)


func _input(event: InputEvent) -> void:
	if event.device == FORWARDED_DEVICE:
		return
	# Se consume «atrás/pausa» para que el menú de pausa no se cierre por debajo.
	for action in _cancel_actions:
		if event.is_action(action):
			get_tree().set_input_as_handled()
			if event.is_action_released(action):
				_on_cancel_pressed()
			return
	# En cooperativo, cada mando o teclado manda acciones propias («ui_up_3»)
	# que la interfaz no entiende: se reenvían como la acción normal.
	var base := forwardable_action(event)
	if base != "":
		get_tree().set_input_as_handled()
		var forwarded := InputEventAction.new()
		forwarded.action = base
		forwarded.pressed = event.is_pressed()
		forwarded.device = FORWARDED_DEVICE
		Input.parse_input_event(forwarded)


# Acción de navegación de un mando o teclado concreto que la interfaz normal
# no reconoce ("" si no lo es o si ya es la acción normal). El stick analógico
# se ignora: el juego ya lo convierte en acciones a un ritmo cómodo.
func forwardable_action(event: InputEvent) -> String:
	if event is InputEventMouse or event is InputEventJoypadMotion:
		return ""
	for base in NAV_ACTIONS:
		if InputMap.has_action(base) and event.is_action(base):
			return ""
	for variant in _nav_variants.keys():
		if event.is_action(variant):
			return _nav_variants[variant]
	return ""


# --- Construcción -----------------------------------------------------------

func _build() -> void:
	_fonts = {
		"title": UiStyle.font(54, 2),
		"name": UiStyle.font(40, 1),
		"card": UiStyle.font(30),
		"body": UiStyle.font(25),
		"small": UiStyle.font(22),
		"tiny": UiStyle.font(18),
		"tile": UiStyle.font(34),
		"tile_big": UiStyle.font(46),
	}
	_dots = {
		"ok": UiStyle.circle_texture(14, UiStyle.OK, UiStyle.OK),
		"warn": UiStyle.circle_texture(14, UiStyle.WARN, UiStyle.WARN),
		"error": UiStyle.circle_texture(14, UiStyle.ERROR, UiStyle.ERROR),
		"off": UiStyle.circle_texture(14, UiStyle.OFF, UiStyle.OFF),
	}

	var root := Control.new()
	root.name = "CaritatopcMenu"
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
	outer.add_constant_override("margin_left", 110)
	outer.add_constant_override("margin_right", 110)
	outer.add_constant_override("margin_top", 56)
	outer.add_constant_override("margin_bottom", 56)
	root.add_child(outer)

	var panel := PanelContainer.new()
	panel.add_stylebox_override("panel", UiStyle.panel_box())
	outer.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 22)
	panel.add_child(layout)

	layout.add_child(_build_header())

	_restart_banner = _build_notice(tr("CLC_MENU_RESTART_BANNER"), UiStyle.WARN)
	layout.add_child(_restart_banner)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_constant_override("separation", 26)
	layout.add_child(body)
	body.add_child(_build_library())
	body.add_child(_build_detail_panel())

	_message_label = _label("", "small", UiStyle.ERROR, true)
	_message_label.visible = false
	layout.add_child(_message_label)

	layout.add_child(_build_footer())


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_constant_override("separation", 18)

	var heart := Heart.new()
	heart.color = UiStyle.BRAND
	heart.pulse = true
	heart.rect_min_size = Vector2(58, 58)
	heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(heart)

	var titles := VBoxContainer.new()
	titles.add_constant_override("separation", 0)
	titles.alignment = BoxContainer.ALIGN_CENTER
	titles.add_child(_label(tr("CLC_MENU_TITLE"), "title", UiStyle.TEXT))
	titles.add_child(_label(tr("CLC_MENU_SUBTITLE"), "small", UiStyle.MUTED))
	header.add_child(titles)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var version_chip := _chip("v%s" % core.version, UiStyle.MUTED, UiStyle.SURFACE_2)
	version_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(version_chip)
	return header


func _build_library() -> Control:
	var column := VBoxContainer.new()
	column.rect_min_size = Vector2(500, 0)
	column.add_constant_override("separation", 14)
	column.add_child(_label(tr("CLC_MENU_LIBRARY").to_upper(), "tiny", UiStyle.MUTED))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	scroll.follow_focus = true
	column.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_constant_override("separation", 12)
	scroll.add_child(list)

	var ids: Array = core.get_module_ids()
	if ids.empty():
		list.add_child(_label(tr("CLC_MENU_EMPTY"), "body", UiStyle.MUTED, true))
	for id in ids:
		list.add_child(_build_card(id))
	return column


func _build_card(id: String) -> Control:
	var definition: Dictionary = core.get_definition(id)
	var accent := _accent(id)

	var card := Button.new()
	card.name = "Card_%s" % id
	card.rect_min_size = Vector2(0, 96)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.add_stylebox_override("hover", UiStyle.box(UiStyle.SURFACE_2, 16))
	card.add_stylebox_override("pressed", UiStyle.box(UiStyle.SURFACE_2, 16))
	card.add_stylebox_override("focus", UiStyle.ring(accent, 16, 3))
	var _err = card.connect("focus_entered", self, "_select", [id, false])
	_err = card.connect("pressed", self, "_select", [id, true])

	var row := HBoxContainer.new()
	row.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	row.margin_left = 18
	row.margin_right = -20
	row.add_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var tile := _icon_tile(id, 62, "tile")
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tile)

	var texts := VBoxContainer.new()
	texts.alignment = BoxContainer.ALIGN_CENTER
	texts.add_constant_override("separation", 2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(_label(tr(definition.short_name_key), "card", UiStyle.TEXT))
	texts.add_child(_label(tr("CLC_CATEGORY_%s" % definition.category.to_upper()), "tiny", UiStyle.MUTED))
	row.add_child(texts)

	var status := HBoxContainer.new()
	status.add_constant_override("separation", 8)
	status.alignment = BoxContainer.ALIGN_END
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := TextureRect.new()
	dot.texture = _dots.off
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_child(dot)
	var status_label := _label("", "tiny", UiStyle.MUTED)
	status.add_child(status_label)
	row.add_child(status)

	_cards[id] = {"button": card, "dot": dot, "label": status_label, "accent": accent}
	_update_card_style(id)
	return card


func _build_detail_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE, 20, Vector2(30, 26)))
	_detail_box = VBoxContainer.new()
	_detail_box.add_constant_override("separation", 18)
	panel.add_child(_detail_box)
	return panel


func _build_detail(id: String) -> void:
	var definition: Dictionary = core.get_definition(id)
	var accent := _accent(id)

	var head := HBoxContainer.new()
	head.add_constant_override("separation", 22)
	_detail_box.add_child(head)
	var tile := _icon_tile(id, 88, "tile_big")
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tile)

	var titles := VBoxContainer.new()
	titles.alignment = BoxContainer.ALIGN_CENTER
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_constant_override("separation", 4)
	titles.add_child(_label(tr(definition.name_key), "name", UiStyle.TEXT, true))
	var status := _label("", "small", UiStyle.MUTED, true)
	titles.add_child(status)
	head.add_child(titles)

	var toggle := Switch.new()
	toggle.accent = accent
	toggle.rect_min_size = Vector2(104, 54)
	var _err = toggle.connect("toggled", self, "_on_module_toggled", [id])
	_connect_hint(toggle, tr("CLC_MENU_TOGGLE_HINT"))
	head.add_child(toggle)

	_detail_box.add_child(_label(tr(definition.description_key), "body", UiStyle.TEXT_SOFT, true))

	if definition.warning_key != "":
		_detail_box.add_child(_build_notice(tr(definition.warning_key), UiStyle.WARN))

	var controls := []
	if definition.settings.empty():
		var empty := _label(tr("CLC_MENU_NO_SETTINGS"), "small", UiStyle.MUTED, true)
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_detail_box.add_child(empty)
	else:
		_detail_box.add_child(_label(tr("CLC_MENU_SETTINGS").to_upper(), "tiny", UiStyle.MUTED))
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.scroll_horizontal_enabled = false
		scroll.follow_focus = true
		_detail_box.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_constant_override("separation", 10)
		scroll.add_child(list)
		for setting in definition.settings:
			controls.append(_build_setting(list, id, setting, accent))

	var hint_box := PanelContainer.new()
	hint_box.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE_2, 12, Vector2(18, 12)))
	hint_box.rect_min_size = Vector2(0, 76)
	_hint_label = _label(tr("CLC_MENU_HINT_IDLE"), "small", UiStyle.TEXT_SOFT, true)
	_hint_label.valign = Label.VALIGN_CENTER
	hint_box.add_child(_hint_label)
	_detail_box.add_child(hint_box)

	_detail = {"id": id, "toggle": toggle, "status": status, "controls": controls}


func _build_setting(parent: VBoxContainer, id: String, setting: Dictionary, accent: Color) -> Dictionary:
	var entry := {"key": setting.key, "type": setting.type, "depends_on": setting.depends_on, "suffix": setting.suffix}
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE_2, 14, Vector2(22, 10)))
	parent.add_child(row)
	entry["row"] = row

	var line := HBoxContainer.new()
	line.add_constant_override("separation", 18)
	row.add_child(line)
	var label := _label(tr(setting.label_key), "body", UiStyle.TEXT, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.valign = Label.VALIGN_CENTER
	line.add_child(label)

	var hint := tr(setting.help_key) if setting.help_key != "" else ""
	match setting.type:
		"bool":
			var toggle := Switch.new()
			toggle.accent = accent
			var _err = toggle.connect("toggled", self, "_on_bool_changed", [id, setting.key])
			line.add_child(toggle)
			entry["control"] = toggle
		"int", "float":
			var slider := HSlider.new()
			slider.min_value = setting.min
			slider.max_value = setting.max
			slider.step = setting.step
			slider.rect_min_size = Vector2(300, 40)
			slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			UiStyle.style_slider(slider, accent)
			var _err = slider.connect("value_changed", self, "_on_number_changed", [id, setting.key])
			line.add_child(slider)
			var value_chip := _chip("", UiStyle.TEXT, UiStyle.SURFACE_3)
			value_chip.rect_min_size = Vector2(104, 0)
			value_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line.add_child(value_chip)
			entry["control"] = slider
			entry["value_label"] = value_chip.get_child(0)
			# El foco del deslizador se marca en su fila (el tirador ya resalta).
			_err = slider.connect("focus_entered", self, "_on_row_focus", [row, accent, true])
			_err = slider.connect("focus_exited", self, "_on_row_focus", [row, accent, false])
		"enum":
			var option_button := OptionButton.new()
			for index in setting.options.size():
				var option: String = setting.options[index]
				option_button.add_item(tr("%s_%s" % [setting.label_key, option.to_upper()]), index)
			UiStyle.style_option_button(option_button, accent, 24)
			var _err = option_button.connect("item_selected", self, "_on_enum_selected", [id, setting.key, setting.options])
			line.add_child(option_button)
			entry["control"] = option_button
			entry["options"] = setting.options

	_connect_hint(entry.control, hint if hint != "" else tr(setting.label_key))
	return entry


func _build_footer() -> Control:
	var footer := HBoxContainer.new()
	footer.add_constant_override("separation", 16)
	footer.add_child(_make_button(tr("CLC_BUTTON_RESET"), "_on_reset_pressed", "ghost"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	footer.add_child(_make_button(tr("CLC_BUTTON_CANCEL"), "_on_cancel_pressed", "ghost"))
	footer.add_child(_make_button(tr("CLC_BUTTON_SAVE"), "_on_save_pressed", "primary"))
	return footer


func _build_notice(text: String, color: Color) -> Control:
	var notice := PanelContainer.new()
	var background := Color(color.r, color.g, color.b, 0.14)
	notice.add_stylebox_override("panel", UiStyle.bordered(background, 12, Color(color.r, color.g, color.b, 0.55), 2, Vector2(18, 10)))
	notice.add_child(_label(text, "small", color, true))
	return notice


# --- Selección -----------------------------------------------------------------

func _select(id: String, focus_detail: bool = false) -> void:
	if id != _selected or _detail.empty():
		_selected = id
		for child in _detail_box.get_children():
			_detail_box.remove_child(child)
			child.queue_free()
		_build_detail(id)
		for card_id in _cards.keys():
			_update_card_style(card_id)
		_link_focus()
		_refresh_all()
	if focus_detail:
		_detail.toggle.call_deferred("grab_focus")


func _update_card_style(id: String) -> void:
	var card: Dictionary = _cards[id]
	var style: StyleBox = UiStyle.stripe(UiStyle.SURFACE_2, 16, card.accent) if id == _selected else UiStyle.box(UiStyle.SURFACE, 16)
	card.button.add_stylebox_override("normal", style)
	if id == _selected:
		card.button.add_stylebox_override("hover", style)
	else:
		card.button.add_stylebox_override("hover", UiStyle.box(UiStyle.SURFACE_2, 16))


# Con mando o teclado: derecha entra en la ficha e izquierda vuelve a la tarjeta.
func _link_focus() -> void:
	if _detail.empty() or not _cards.has(_selected):
		return
	var card: Button = _cards[_selected].button
	var toggle: Control = _detail.toggle
	for card_id in _cards.keys():
		var other: Button = _cards[card_id].button
		other.focus_neighbour_right = other.get_path_to(toggle)
	toggle.focus_neighbour_left = toggle.get_path_to(card)
	for entry in _detail.controls:
		if not entry.control is Slider:
			entry.control.focus_neighbour_left = entry.control.get_path_to(card)


# --- Estado ------------------------------------------------------------------

func _refresh_all() -> void:
	_refreshing = true
	for id in _cards.keys():
		_refresh_card(id)
	if not _detail.empty():
		_refresh_detail()
	if _restart_banner != null:
		_restart_banner.visible = core.any_needs_restart()
	_refreshing = false


func _refresh_card(id: String) -> void:
	var card: Dictionary = _cards[id]
	var short_status: Array = _short_status_for(id)
	card.label.text = short_status[0]
	card.label.add_color_override("font_color", short_status[1])
	card.dot.texture = _dots[short_status[2]]


func _refresh_detail() -> void:
	var id: String = _detail.id
	var enabled: bool = core.is_module_enabled(id)
	_detail.toggle.set_on(enabled)

	var status: Array = _status_for(id)
	_detail.status.text = status[0]
	_detail.status.add_color_override("font_color", status[1])

	var values := {}
	for entry in _detail.controls:
		values[entry.key] = core.get_setting(id, entry.key)

	for entry in _detail.controls:
		var value = values[entry.key]
		var control = entry.control
		match entry.type:
			"bool":
				control.set_on(bool(value))
			"int", "float":
				control.value = float(value)
				entry.value_label.text = _format_number(value, entry.type) + entry.suffix
			"enum":
				var index: int = entry.options.find(value)
				control.select(int(max(0, index)))

		var usable := enabled
		if entry.depends_on != "":
			# «clave» = usable si el ajuste está encendido; «!clave» = si está apagado.
			var inverted: bool = entry.depends_on.begins_with("!")
			var parent_key: String = entry.depends_on.trim_prefix("!")
			if values.has(parent_key):
				usable = usable and (bool(values[parent_key]) != inverted)
		_set_control_enabled(control, usable)
		entry.row.modulate = Color(1, 1, 1, 1) if usable else Color(1, 1, 1, 0.4)


# [texto, color, punto] para la tarjeta.
func _short_status_for(id: String) -> Array:
	var state: Dictionary = core.get_boot_state(id)
	var enabled: bool = core.is_module_enabled(id)
	if state.state == "error":
		return [tr("CLC_CARD_ERROR"), UiStyle.ERROR, "error"]
	if not enabled:
		return [tr("CLC_CARD_OFF"), UiStyle.MUTED, "off"]
	if state.state == "blocked" or core.needs_restart(id):
		return [tr("CLC_CARD_RESTART") if core.needs_restart(id) else tr("CLC_CARD_BLOCKED"), UiStyle.WARN, "warn"]
	for dlc_id in core.get_definition(id).requires_dlc:
		if not Compat.is_dlc_available(dlc_id):
			return [tr("CLC_CARD_NO_DLC"), UiStyle.WARN, "warn"]
	return [tr("CLC_CARD_ON"), UiStyle.OK, "ok"]


# [texto, color] para la ficha.
func _status_for(id: String) -> Array:
	var state: Dictionary = core.get_boot_state(id)
	var enabled: bool = core.is_module_enabled(id)

	if state.state == "error":
		return [tr("CLC_STATUS_ERROR") % state.detail, UiStyle.ERROR]
	if enabled and state.state == "blocked":
		if state.reason == "conflict":
			return [tr("CLC_STATUS_BLOCKED_CONFLICT") % _module_name(state.detail), UiStyle.WARN]
		if not core.is_module_enabled(state.detail):
			return [tr("CLC_STATUS_BLOCKED_DEPENDENCY") % _module_name(state.detail), UiStyle.WARN]
	if core.needs_restart(id):
		return [tr("CLC_STATUS_RESTART"), UiStyle.WARN]
	if not enabled:
		if core.is_module_loaded(id):
			return [tr("CLC_STATUS_DISABLED_LIVE"), UiStyle.MUTED]
		return [tr("CLC_STATUS_DISABLED"), UiStyle.MUTED]

	var definition: Dictionary = core.get_definition(id)
	for dlc_id in definition.requires_dlc:
		if not Compat.is_dlc_available(dlc_id):
			return [tr("CLC_STATUS_REQUIRES_DLC") % tr(DLC_NAME_KEYS.get(dlc_id, dlc_id)), UiStyle.WARN]

	var game_version := Compat.game_version()
	if game_version == "":
		return [tr("CLC_STATUS_ACTIVE"), UiStyle.OK]
	var compatibility: Dictionary = definition.compatibility
	if compatibility.status == "tested" and compatibility.game_versions.has(game_version):
		return [tr("CLC_STATUS_ACTIVE") + " · " + tr("CLC_STATUS_TESTED") % game_version, UiStyle.OK]
	return [tr("CLC_STATUS_ACTIVE") + " · " + tr("CLC_STATUS_UNTESTED") % game_version, UiStyle.OK]


func _module_name(id: String) -> String:
	var definition: Dictionary = core.get_definition(id)
	return tr(definition.name_key) if not definition.empty() else id


# --- Eventos -----------------------------------------------------------------

func _on_module_toggled(pressed: bool, id: String) -> void:
	if _refreshing:
		return
	core.set_module_enabled(id, pressed)
	_refresh_all()


func _on_bool_changed(pressed: bool, id: String, key: String) -> void:
	if _refreshing:
		return
	var _stored = core.set_setting(id, key, pressed)
	_refresh_all()


func _on_number_changed(value: float, id: String, key: String) -> void:
	if _refreshing:
		return
	var _stored = core.set_setting(id, key, value)
	_refresh_all()


func _on_enum_selected(index: int, id: String, key: String, options: Array) -> void:
	if _refreshing or index < 0 or index >= options.size():
		return
	var _stored = core.set_setting(id, key, options[index])
	_refresh_all()


func _on_reset_pressed() -> void:
	core.reset_defaults()
	_refresh_all()


func _on_cancel_pressed() -> void:
	core.restore(_snapshot)
	close()


func _on_save_pressed() -> void:
	if core.save_config():
		close()
		return
	_message_label.text = tr("CLC_SAVE_FAILED") % core.config_save_error
	_message_label.visible = true


func _on_hint(text: String) -> void:
	if _hint_label != null and is_instance_valid(_hint_label):
		_hint_label.text = text


func _on_row_focus(row: PanelContainer, accent: Color, focused: bool) -> void:
	if not is_instance_valid(row):
		return
	var style: StyleBox = UiStyle.bordered(UiStyle.SURFACE_2, 14, accent, 3, Vector2(22, 10)) if focused else UiStyle.box(UiStyle.SURFACE_2, 14, Vector2(22, 10))
	row.add_stylebox_override("panel", style)


# --- Utilidades ----------------------------------------------------------------

func _connect_hint(control: Control, text: String) -> void:
	var _err = control.connect("focus_entered", self, "_on_hint", [text])
	_err = control.connect("mouse_entered", self, "_on_hint", [text])


func _label(text: String, font_key: String, color: Color, wrap: bool = false) -> Label:
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


func _chip(text: String, color: Color, background: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_stylebox_override("panel", UiStyle.box(background, 12, Vector2(14, 6)))
	var label := _label(text, "small", color)
	label.align = Label.ALIGN_CENTER
	chip.add_child(label)
	return chip


# Recuadro del color de la leyenda con la inicial de su nombre corto.
func _icon_tile(id: String, size: int, font_key: String) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.rect_min_size = Vector2(size, size)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_stylebox_override("panel", UiStyle.box(_accent(id), int(size * 0.26), Vector2.ZERO))
	var short_name: String = tr(core.get_definition(id).short_name_key)
	var letter := _label(short_name.substr(0, 1).to_upper(), font_key, UiStyle.INK)
	letter.align = Label.ALIGN_CENTER
	letter.valign = Label.VALIGN_CENTER
	tile.add_child(letter)
	return tile


func _make_button(text: String, method: String, kind: String) -> Button:
	var button := Button.new()
	button.text = text
	button.rect_min_size = Vector2(170, 0)
	UiStyle.style_button(button, kind, UiStyle.BRAND, 26)
	var _err = button.connect("pressed", self, method)
	return button


func _accent(id: String) -> Color:
	var accent: String = core.get_definition(id).get("accent", "")
	return Color(accent) if accent != "" else UiStyle.BRAND


func _set_control_enabled(control: Control, usable: bool) -> void:
	if control is BaseButton:
		control.disabled = not usable
	elif control is Range:
		control.editable = usable
	control.focus_mode = Control.FOCUS_ALL if usable else Control.FOCUS_NONE


func _collect_nav_actions() -> void:
	_nav_variants = {}
	for action in InputMap.get_actions():
		var action_name := str(action)
		for base in NAV_ACTIONS:
			if action_name.begins_with(base + "_") and action_name.substr(base.length() + 1).is_valid_integer():
				_nav_variants[action_name] = base


func _collect_cancel_actions() -> void:
	_cancel_actions = []
	for action in InputMap.get_actions():
		var action_name := str(action)
		if action_name.begins_with("ui_cancel") or action_name.begins_with("ui_pause"):
			_cancel_actions.append(action_name)


static func _format_number(value, type: String) -> String:
	if type == "int":
		return str(int(value))
	return "%.2f" % float(value)
