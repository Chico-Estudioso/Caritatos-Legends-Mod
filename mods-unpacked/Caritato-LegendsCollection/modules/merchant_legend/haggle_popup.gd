extends "res://mods-unpacked/Caritato-LegendsCollection/ui/legend_popup.gd"

# La Leyenda del Mercader: «¡A regatear!». Una aguja va y viene por una barra;
# al pulsar Aceptar se para. En la zona verde, el máximo descuento en los
# artículos de esta tienda; en la amarilla, la mitad; en la roja, nada. Un
# intento por tienda.
#
# Resultado: "green", "yellow", "red" o "cancelled" (cancelar no gasta el intento).

const HaggleMeter = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/haggle_meter.gd")
const Sparkles = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/sparkles.gd")
const MerchantRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/merchant_legend/merchant_rules.gd")

const ACCENT := Color("ffc845")
const COINS := [Color("ffc845"), Color("ffe08a"), Color("e0a526"), Color("ffffff")]
const RESULT_TIME := 1.8

var max_percent := 10

var _meter: Control = null
var _coins: Control = null
var _title: Label = null
var _hint: Label = null
var _button: Button = null
var _done := false


func _init() -> void:
	accent = ACCENT


func _build_content(layout: VBoxContainer) -> void:
	var stage := _stage(150)
	layout.add_child(stage)
	_coins = _fill(Sparkles.new())
	_coins.ambient = false
	_coins.shape = "confetti"
	_coins.tints = COINS
	_coins.gravity = 900.0
	stage.add_child(_coins)
	_meter = _fill(HaggleMeter.new())
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_meter.green_center = rng.randf_range(0.25, 0.75)
	stage.add_child(_meter)

	_title = _label(tr("CLC_MERCHANT_HAGGLE_TITLE"), "title", ACCENT)
	layout.add_child(_title)
	_hint = _label(tr("CLC_MERCHANT_HAGGLE_HINT"), "body", UiStyle.TEXT_SOFT)
	layout.add_child(_hint)
	layout.add_child(_label(tr("CLC_MERCHANT_HAGGLE_PRIZE") % [max_percent, MerchantRules.haggle_percent(MerchantRules.ZONE_YELLOW, max_percent)], "small", UiStyle.MUTED))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	layout.add_child(buttons)
	_button = Button.new()
	_button.text = tr("CLC_MERCHANT_HAGGLE_STOP")
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
	var stopped_at: float = _meter.stop()
	stop_at(MerchantRules.haggle_zone(stopped_at, _meter.green_center, _meter.green_half, _meter.yellow_half))


func stop_at(zone: String) -> void:
	if _done:
		return
	_done = true
	_meter.stop()
	var percent: int = MerchantRules.haggle_percent(zone, max_percent)
	if zone == MerchantRules.ZONE_GREEN:
		_title.text = tr("CLC_MERCHANT_HAGGLE_GREEN")
		_title.add_color_override("font_color", UiStyle.OK)
		_coins.burst(60)
	elif zone == MerchantRules.ZONE_YELLOW:
		_title.text = tr("CLC_MERCHANT_HAGGLE_YELLOW")
		_coins.burst(25)
	else:
		_title.text = tr("CLC_MERCHANT_HAGGLE_RED")
		_title.add_color_override("font_color", UiStyle.MUTED)
	_hint.text = tr("CLC_MERCHANT_HAGGLE_RESULT") % percent if percent > 0 else tr("CLC_MERCHANT_HAGGLE_NOTHING")
	_button.disabled = true
	close_later(RESULT_TIME, zone)
