extends "res://mods-unpacked/Caritato-LegendsCollection/ui/legend_popup.gd"

# La Leyenda de la Cosecha Eterna: «Cosecha dorada». El trigo madura y se pasa
# sin parar; al pulsar Aceptar se cosecha. Si estaba dorado, se gana un 10 %
# de la recolección en materiales; si casi, la mitad; si verde, nada. Un
# intento por tienda del modo infinito.
#
# Resultado: "gold", "near", "none" o "cancelled".

const WheatField = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/wheat_field.gd")
const Sparkles = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/sparkles.gd")
const HarvestRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/endless_harvest/harvest_rules.gd")

const ACCENT := Color("8bd450")
const GRAINS := [Color("ffc845"), Color("ffe08a"), Color("e0a526"), Color("8bd450")]
const RESULT_TIME := 1.8

var harvesting := 0
var full_reward := 0
var near_reward := 0

var _field: Control = null
var _grains: Control = null
var _title: Label = null
var _hint: Label = null
var _button: Button = null
var _done := false


func _init() -> void:
	accent = ACCENT


func _build_content(layout: VBoxContainer) -> void:
	var stage := _stage(230)
	layout.add_child(stage)
	_field = _fill(WheatField.new())
	stage.add_child(_field)
	_grains = _fill(Sparkles.new())
	_grains.ambient = false
	_grains.shape = "confetti"
	_grains.tints = GRAINS
	_grains.gravity = 700.0
	stage.add_child(_grains)

	_title = _label(tr("CLC_HARVEST_GOLDEN_TITLE"), "title", ACCENT)
	layout.add_child(_title)
	_hint = _label(tr("CLC_HARVEST_GOLDEN_HINT"), "body", UiStyle.TEXT_SOFT)
	layout.add_child(_hint)
	layout.add_child(_label(tr("CLC_HARVEST_GOLDEN_PRIZE") % [full_reward, near_reward, harvesting], "small", UiStyle.MUTED))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	layout.add_child(buttons)
	_button = Button.new()
	_button.text = tr("CLC_HARVEST_GOLDEN_BUTTON")
	_button.rect_min_size = Vector2(280, 64)
	UiStyle.style_button(_button, "primary", ACCENT, 28)
	var _err = _button.connect("pressed", self, "_on_button_pressed")
	buttons.add_child(_button)


func _after_open() -> void:
	_button.call_deferred("grab_focus")


func _on_button_pressed() -> void:
	if mouse_allowed():
		_on_accept()


func _on_accept() -> void:
	if _done:
		return
	harvest_at(HarvestRules.golden_zone(_field.harvest()))


func harvest_at(zone: String) -> void:
	if _done:
		return
	_done = true
	if not _field.is_harvested():
		_field.harvest()
	if zone == HarvestRules.ZONE_GOLD:
		_title.text = tr("CLC_HARVEST_GOLDEN_GOLD")
		_title.add_color_override("font_color", UiStyle.WARN)
		_hint.text = tr("CLC_HARVEST_GOLDEN_GAIN") % full_reward
		_grains.burst(70)
	elif zone == HarvestRules.ZONE_NEAR:
		_title.text = tr("CLC_HARVEST_GOLDEN_NEAR")
		_hint.text = tr("CLC_HARVEST_GOLDEN_GAIN") % near_reward
		_grains.burst(30)
	else:
		_title.text = tr("CLC_HARVEST_GOLDEN_NONE")
		_title.add_color_override("font_color", UiStyle.MUTED)
		_hint.text = tr("CLC_HARVEST_GOLDEN_NONE_TEXT")
	_button.disabled = true
	close_later(RESULT_TIME, zone)
