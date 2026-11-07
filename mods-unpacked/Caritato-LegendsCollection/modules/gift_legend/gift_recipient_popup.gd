extends "res://mods-unpacked/Caritato-LegendsCollection/ui/legend_popup.gd"

# «¿A quién se lo regalas?»: sale cuando hay varios jugadores a los que
# regalar o cuando no se puede regalar a nadie (para explicar el motivo).
# Responde quien regala (player_index). Resultado: "to:<jugador>" o "cancelled".

# {data, is_weapon, label, tier, tags, recipients: [{index, reason}]}
var offer := {}

var _choices := []
var _focus := 0


func _init() -> void:
	accent = UiStyle.BRAND


func _build_content(layout: VBoxContainer) -> void:
	layout.add_child(_label(tr("CLC_GIFT_PICK_TITLE"), "big", UiStyle.BRAND))
	layout.add_child(_item_card(offer.get("data"), str(offer.get("label", "")), int(offer.get("tier", 0))))

	var buttons := VBoxContainer.new()
	buttons.add_constant_override("separation", 10)
	layout.add_child(buttons)
	for recipient in offer.get("recipients", []):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGN_CENTER
		row.add_constant_override("separation", 16)
		buttons.add_child(row)
		var button := Button.new()
		var name_key := Compat.get_character_name_key(recipient.index)
		button.text = tr("CLC_GIFT_TO") % (recipient.index + 1) if name_key == "" else "%s · %s" % [tr("CLC_GIFT_TO") % (recipient.index + 1), tr(name_key)]
		button.rect_min_size = Vector2(360, 58)
		UiStyle.style_button(button, "primary", Compat.player_color(recipient.index), 26)
		row.add_child(button)
		if recipient.reason != "":
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE
			var reason := _label(tr(recipient.reason), "small", UiStyle.MUTED)
			reason.align = Label.ALIGN_LEFT
			reason.rect_min_size = Vector2(380, 0)
			row.add_child(reason)
		else:
			var _err = button.connect("pressed", self, "_on_choice_pressed", [recipient.index])
			_choices.append({"button": button, "index": recipient.index})

	if _choices.empty():
		layout.add_child(_label(tr("CLC_GIFT_PICK_NONE"), "small", UiStyle.MUTED))
	var close := Button.new()
	close.text = tr("CLC_GIFT_CLOSE")
	close.rect_min_size = Vector2(220, 0)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiStyle.style_button(close, "ghost", UiStyle.BRAND, 24)
	var _err = close.connect("pressed", self, "_on_close_pressed")
	layout.add_child(close)
	_choices.append({"button": close, "index": -1})


func _after_open() -> void:
	_move(0)


func _on_direction(step: int) -> void:
	_move(step)


func _move(step: int) -> void:
	if _choices.empty():
		return
	_focus = int(clamp(_focus + step, 0, _choices.size() - 1))
	_choices[_focus].button.grab_focus()


func _on_accept() -> void:
	if _choices.empty():
		return
	choose(_choices[_focus].index)


func choose(index: int) -> void:
	if index < 0:
		close_popup("cancelled")
	else:
		close_popup("to:%d" % index)


func _on_choice_pressed(index: int) -> void:
	if mouse_allowed():
		choose(index)


func _on_close_pressed() -> void:
	if mouse_allowed():
		close_popup("cancelled")
