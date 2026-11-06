extends CanvasLayer

# Pantalla de configuración de Caritatos Legends.
#
# Se construye por código para no depender de escenas ni recursos importados.
# Los valores se aplican al momento; «Cancelar» devuelve todo al estado que
# tenía al abrir la pantalla y «Guardar y cerrar» lo escribe en disco.

signal closed

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")

const THEME_PATH := "res://resources/themes/base_theme.tres"
const FONT_TITLE_PATH := "res://resources/fonts/actual/base/font_40_outline.tres"
const FONT_HEADER_PATH := "res://resources/fonts/actual/base/font_26_outline.tres"
const FONT_SMALL_PATH := "res://resources/fonts/actual/base/font_smallest_text.tres"

const COLOR_OK := Color(0.55, 0.85, 0.45)
const COLOR_WARN := Color(1.0, 0.75, 0.3)
const COLOR_ERROR := Color(1.0, 0.45, 0.4)
const COLOR_MUTED := Color(0.72, 0.72, 0.72)

const DLC_NAME_KEYS := {
	"abyssal_terrors": "CLC_DLC_ABYSSAL_TERRORS",
}

var core = null
var context := "title"

var _snapshot := {}
# id -> {toggle, status, controls: [{key, type, control, value_label, row}]}
var _rows := {}
var _restart_banner: Label = null
var _message_label: Label = null
var _first_focus: Control = null
var _previous_focus: Control = null
var _refreshing := false
var _cancel_actions := []
var _font_small: Font = null
var _font_header: Font = null


func _init() -> void:
	layer = 110
	pause_mode = Node.PAUSE_MODE_PROCESS


func open(p_core, p_context: String = "title", p_return_focus: Control = null) -> void:
	core = p_core
	context = p_context
	_previous_focus = p_return_focus
	_snapshot = core.snapshot()
	_collect_cancel_actions()
	_build()
	_refresh_all()
	if _first_focus != null:
		_first_focus.call_deferred("grab_focus")


func close() -> void:
	emit_signal("closed")
	if _previous_focus != null and is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.call_deferred("grab_focus")
	queue_free()


func _input(event: InputEvent) -> void:
	# Se consume «atrás/pausa» para que el menú de pausa no se cierre por debajo.
	for action in _cancel_actions:
		if event.is_action(action):
			get_tree().set_input_as_handled()
			if event.is_action_released(action):
				_on_cancel_pressed()
			return


# --- Construcción -----------------------------------------------------------

func _build() -> void:
	_font_small = _load_font(FONT_SMALL_PATH)
	_font_header = _load_font(FONT_HEADER_PATH)

	var root := Control.new()
	root.name = "LegendsMenuRoot"
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var theme_resource = _load_if_exists(THEME_PATH)
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
	outer.add_constant_override("margin_left", 180)
	outer.add_constant_override("margin_right", 180)
	outer.add_constant_override("margin_top", 60)
	outer.add_constant_override("margin_bottom", 60)
	root.add_child(outer)

	var panel := PanelContainer.new()
	outer.add_child(panel)

	var inner := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_constant_override(side, 28)
	panel.add_child(inner)

	var layout := VBoxContainer.new()
	layout.add_constant_override("separation", 14)
	inner.add_child(layout)

	var title := Label.new()
	title.text = tr("CLC_MENU_TITLE")
	title.align = Label.ALIGN_CENTER
	var title_font := _load_font(FONT_TITLE_PATH)
	if title_font != null:
		title.add_font_override("font", title_font)
	layout.add_child(title)

	var subtitle := _make_wrapped_label(tr("CLC_MENU_SUBTITLE"), COLOR_MUTED)
	subtitle.align = Label.ALIGN_CENTER
	layout.add_child(subtitle)

	if context == "ingame":
		var ingame_note := _make_wrapped_label(tr("CLC_MENU_INGAME_NOTE"), COLOR_WARN)
		ingame_note.align = Label.ALIGN_CENTER
		layout.add_child(ingame_note)

	_restart_banner = _make_wrapped_label(tr("CLC_MENU_RESTART_BANNER"), COLOR_WARN)
	_restart_banner.align = Label.ALIGN_CENTER
	layout.add_child(_restart_banner)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.scroll_horizontal_enabled = false
	scroll.follow_focus = true
	layout.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_constant_override("separation", 18)
	scroll.add_child(list)

	var ids: Array = core.get_module_ids()
	if ids.empty():
		list.add_child(_make_wrapped_label(tr("CLC_MENU_EMPTY"), COLOR_MUTED))

	for category in _categories_in_order(ids):
		var header := Label.new()
		header.text = tr("CLC_CATEGORY_%s" % category.to_upper())
		if _font_header != null:
			header.add_font_override("font", _font_header)
		list.add_child(header)
		for id in ids:
			if core.get_definition(id).category == category:
				_build_module(list, id)

	_message_label = _make_wrapped_label("", COLOR_ERROR)
	_message_label.visible = false
	layout.add_child(_message_label)

	var footer := HBoxContainer.new()
	footer.add_constant_override("separation", 20)
	layout.add_child(footer)

	var reset_button := _make_button(tr("CLC_BUTTON_RESET"), "_on_reset_pressed")
	footer.add_child(reset_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	footer.add_child(_make_button(tr("CLC_BUTTON_CANCEL"), "_on_cancel_pressed"))
	var save_button := _make_button(tr("CLC_BUTTON_SAVE"), "_on_save_pressed")
	footer.add_child(save_button)

	if _first_focus == null:
		_first_focus = save_button


func _build_module(list: VBoxContainer, id: String) -> void:
	var definition: Dictionary = core.get_definition(id)

	var box := VBoxContainer.new()
	box.add_constant_override("separation", 6)
	list.add_child(box)

	var toggle := CheckButton.new()
	toggle.text = tr(definition.name_key)
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var _err = toggle.connect("toggled", self, "_on_module_toggled", [id])
	box.add_child(toggle)
	if _first_focus == null:
		_first_focus = toggle

	box.add_child(_make_wrapped_label(tr(definition.description_key), COLOR_MUTED))

	var status := _make_wrapped_label("", COLOR_MUTED)
	box.add_child(status)

	var settings_margin := MarginContainer.new()
	settings_margin.add_constant_override("margin_left", 40)
	box.add_child(settings_margin)
	var settings_box := VBoxContainer.new()
	settings_box.add_constant_override("separation", 8)
	settings_margin.add_child(settings_box)

	var controls := []
	for setting in definition.settings:
		controls.append(_build_setting(settings_box, id, setting))

	box.add_child(HSeparator.new())
	_rows[id] = {"toggle": toggle, "status": status, "controls": controls}


func _build_setting(parent: VBoxContainer, id: String, setting: Dictionary) -> Dictionary:
	var entry := {"key": setting.key, "type": setting.type, "depends_on": setting.depends_on, "suffix": setting.suffix}
	var holder := VBoxContainer.new()
	holder.add_constant_override("separation", 2)
	parent.add_child(holder)
	entry["row"] = holder

	match setting.type:
		"bool":
			var check := CheckBox.new()
			check.text = tr(setting.label_key)
			var _err = check.connect("toggled", self, "_on_bool_changed", [id, setting.key])
			holder.add_child(check)
			entry["control"] = check
		"int", "float":
			var line := HBoxContainer.new()
			line.add_constant_override("separation", 16)
			holder.add_child(line)
			var label := Label.new()
			label.text = tr(setting.label_key)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(label)
			var slider := HSlider.new()
			slider.min_value = setting.min
			slider.max_value = setting.max
			slider.step = setting.step
			slider.rect_min_size = Vector2(360, 32)
			slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var _err = slider.connect("value_changed", self, "_on_number_changed", [id, setting.key])
			line.add_child(slider)
			var value_label := Label.new()
			value_label.rect_min_size = Vector2(110, 0)
			value_label.align = Label.ALIGN_RIGHT
			line.add_child(value_label)
			entry["control"] = slider
			entry["value_label"] = value_label
		"enum":
			var line := HBoxContainer.new()
			line.add_constant_override("separation", 16)
			holder.add_child(line)
			var label := Label.new()
			label.text = tr(setting.label_key)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(label)
			var option_button := OptionButton.new()
			for index in setting.options.size():
				var option: String = setting.options[index]
				option_button.add_item(tr("%s_%s" % [setting.label_key, option.to_upper()]), index)
			var _err = option_button.connect("item_selected", self, "_on_enum_selected", [id, setting.key, setting.options])
			line.add_child(option_button)
			entry["control"] = option_button
			entry["options"] = setting.options

	if setting.help_key != "":
		holder.add_child(_make_wrapped_label(tr(setting.help_key), COLOR_MUTED))

	return entry


# --- Estado ------------------------------------------------------------------

func _refresh_all() -> void:
	_refreshing = true
	for id in _rows.keys():
		_refresh_module(id)
	_restart_banner.visible = core.any_needs_restart()
	_refreshing = false


func _refresh_module(id: String) -> void:
	var row: Dictionary = _rows[id]
	var enabled: bool = core.is_module_enabled(id)
	row.toggle.pressed = enabled

	var status: Array = _status_for(id)
	row.status.text = status[0]
	row.status.add_color_override("font_color", status[1])

	var values := {}
	for entry in row.controls:
		values[entry.key] = core.get_setting(id, entry.key)

	for entry in row.controls:
		var value = values[entry.key]
		var control = entry.control
		match entry.type:
			"bool":
				control.pressed = bool(value)
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
		entry.row.modulate = Color(1, 1, 1, 1) if usable else Color(1, 1, 1, 0.45)


func _status_for(id: String) -> Array:
	var state: Dictionary = core.get_boot_state(id)
	var enabled: bool = core.is_module_enabled(id)

	if state.state == "error":
		return [tr("CLC_STATUS_ERROR") % state.detail, COLOR_ERROR]
	if enabled and state.state == "blocked":
		if state.reason == "conflict":
			return [tr("CLC_STATUS_BLOCKED_CONFLICT") % _module_name(state.detail), COLOR_WARN]
		if not core.is_module_enabled(state.detail):
			return [tr("CLC_STATUS_BLOCKED_DEPENDENCY") % _module_name(state.detail), COLOR_WARN]
	if core.needs_restart(id):
		return [tr("CLC_STATUS_RESTART"), COLOR_WARN]
	if not enabled:
		if core.is_module_loaded(id):
			return [tr("CLC_STATUS_DISABLED_LIVE"), COLOR_MUTED]
		return [tr("CLC_STATUS_DISABLED"), COLOR_MUTED]

	var definition: Dictionary = core.get_definition(id)
	for dlc_id in definition.requires_dlc:
		if not Compat.is_dlc_available(dlc_id):
			return [tr("CLC_STATUS_REQUIRES_DLC") % tr(DLC_NAME_KEYS.get(dlc_id, dlc_id)), COLOR_WARN]

	var game_version := Compat.game_version()
	var compatibility: Dictionary = definition.compatibility
	if compatibility.status == "tested" and compatibility.game_versions.has(game_version):
		return [tr("CLC_STATUS_ACTIVE") + " · " + tr("CLC_STATUS_TESTED") % game_version, COLOR_OK]
	return [tr("CLC_STATUS_ACTIVE") + " · " + tr("CLC_STATUS_UNTESTED") % game_version, COLOR_OK]


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


# --- Utilidades ----------------------------------------------------------------

func _make_wrapped_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_color_override("font_color", color)
	if _font_small != null:
		label.add_font_override("font", _font_small)
	return label


func _make_button(text: String, method: String) -> Button:
	var button := Button.new()
	button.text = text
	var _err = button.connect("pressed", self, method)
	return button


func _set_control_enabled(control: Control, usable: bool) -> void:
	if control is BaseButton:
		control.disabled = not usable
	elif control is Range:
		control.editable = usable
	control.focus_mode = Control.FOCUS_ALL if usable else Control.FOCUS_NONE


func _categories_in_order(ids: Array) -> Array:
	var categories := []
	for id in ids:
		var category: String = core.get_definition(id).category
		if not categories.has(category):
			categories.append(category)
	return categories


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


static func _load_if_exists(path: String):
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func _load_font(path: String) -> Font:
	var resource = _load_if_exists(path)
	return resource if resource is Font else null
