extends "res://mods-unpacked/Caritato-LegendsCollection/ui/legend_popup.gd"

# «¡Fusión de cajas!»: al terminar una oleada, las cajas que se pueden fusionar
# botan; con «¡Fusionar!» vuelan al centro, destellan y sale una caja
# legendaria entre estrellas. «Ahora no» (o atrás) las deja como estaban.
#
# Resultado («closed»): "fused" o "declined".

const CrateFusion = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/crate_fusion.gd")
const Sparkles = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/sparkles.gd")

const ACCENT := Color("d4a373")
const BUTTON_LATER := 0
const BUTTON_FUSE := 1
const FUSE_TIME := 1.9

var player_number := 1
var crates := 3
var cost := 3
var next_cost := 6

var _fusion: Control = null
var _sparkles: Control = null
var _title: Label = null
var _subtitle: Label = null
var _deal: Label = null
var _buttons := []
var _buttons_box: Control = null
var _focus := BUTTON_FUSE


func _init() -> void:
	accent = ACCENT


func _build_content(layout: VBoxContainer) -> void:
	var stage := _stage(230)
	layout.add_child(stage)
	_sparkles = _fill(Sparkles.new())
	_sparkles.ambient = false
	_sparkles.tints = [CrateFusion.GOLD, CrateFusion.LEGEND, UiStyle.BRAND_LIGHT, Color(1, 1, 1)]
	stage.add_child(_sparkles)
	_fusion = _fill(CrateFusion.new())
	_fusion.setup(crates, cost)
	stage.add_child(_fusion)

	_title = _label(tr("CLC_CRATES_TITLE"), "title", ACCENT)
	layout.add_child(_title)
	var have: String = tr("CLC_CRATES_HAVE_PLAYER") % [player_number, crates] if player_index >= 0 else tr("CLC_CRATES_HAVE") % crates
	_subtitle = _label(have, "body", UiStyle.TEXT_SOFT)
	layout.add_child(_subtitle)
	_deal = _label(tr("CLC_CRATES_DEAL") % cost, "name", UiStyle.TEXT)
	layout.add_child(_deal)

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGN_CENTER
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips.add_child(_chip(tr("CLC_CRATES_NEXT") % next_cost, UiStyle.TEXT_SOFT, UiStyle.SURFACE_3))
	layout.add_child(chips)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 24)
	layout.add_child(buttons)
	_buttons_box = buttons
	var later := Button.new()
	later.text = tr("CLC_CRATES_LATER")
	later.rect_min_size = Vector2(240, 64)
	UiStyle.style_button(later, "ghost", ACCENT, 28)
	var _err = later.connect("pressed", self, "_on_button_pressed", [BUTTON_LATER])
	buttons.add_child(later)
	var fuse_button := Button.new()
	fuse_button.text = tr("CLC_CRATES_FUSE")
	fuse_button.rect_min_size = Vector2(280, 64)
	UiStyle.style_button(fuse_button, "primary", ACCENT, 30)
	_err = fuse_button.connect("pressed", self, "_on_button_pressed", [BUTTON_FUSE])
	buttons.add_child(fuse_button)
	_buttons = [later, fuse_button]

	if player_index >= 0:
		layout.add_child(_label(tr("CLC_CRATES_WHO") % player_number, "small", Compat.player_color(player_index)))


func _after_open() -> void:
	_set_focus(BUTTON_FUSE)


func _on_direction(step: int) -> void:
	_set_focus(BUTTON_LATER if step < 0 else BUTTON_FUSE)


func _on_accept() -> void:
	_activate(_focus)


func _on_cancel() -> void:
	decline()


func _on_button_pressed(index: int) -> void:
	if mouse_allowed():
		_activate(index)


func _set_focus(index: int) -> void:
	_focus = index
	if index < _buttons.size() and is_instance_valid(_buttons[index]):
		_buttons[index].grab_focus()


func _activate(index: int) -> void:
	if index == BUTTON_FUSE:
		fuse()
	else:
		decline()


func fuse() -> void:
	if is_closing():
		return
	for button in _buttons:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
	_buttons_box.modulate.a = 0.0
	_fusion.fuse()
	_title.text = tr("CLC_CRATES_DONE")
	_subtitle.text = tr("CLC_CRATES_LEFT") % int(max(0, crates - cost))
	_deal.text = tr("CLC_CRATES_DONE_TEXT")
	if is_inside_tree():
		var timer := get_tree().create_timer(CrateFusion.GATHER_TIME + CrateFusion.FLASH_TIME, true)
		var _err = timer.connect("timeout", self, "_burst")
	close_later(FUSE_TIME, "fused")


func decline() -> void:
	if not is_closing():
		close_popup("declined")


func _burst() -> void:
	if is_instance_valid(_sparkles):
		_sparkles.burst(50)
