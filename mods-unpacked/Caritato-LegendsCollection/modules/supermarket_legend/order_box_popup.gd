extends "res://mods-unpacked/Caritato-LegendsCollection/ui/legend_popup.gd"

# La Leyenda del Supermercado: «¡Tu encargo ha llegado!». Una caja de cartón
# que se abre a toques (aceptar o clic); cada toque la hace temblar más y al
# tercero sale volando la tapa con confeti y se ve lo que había dentro. Es
# solo un detalle visual: el encargo ya está bloqueado en la tienda.

const OrderBox = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/order_box.gd")
const Sparkles = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/sparkles.gd")

const ACCENT := Color("ff8c42")
const TAPS_TO_OPEN := 3
const CONFETTI := [Color("ff8c42"), Color("ffc845"), Color("ffffff"), Color("4fc3f7"), Color("a970ff")]

# [{data, label, tier}]
var items := []

var _box: Control = null
var _confetti: Control = null
var _title: Label = null
var _hint: Label = null
var _contents: VBoxContainer = null
var _button: Button = null
var _taps := 0


func _init() -> void:
	accent = ACCENT


func taps() -> int:
	return _taps


func is_open() -> bool:
	return _box != null and _box.is_open()


func _build_content(layout: VBoxContainer) -> void:
	var stage := _stage(250)
	layout.add_child(stage)
	_confetti = _fill(Sparkles.new())
	_confetti.ambient = false
	_confetti.shape = "confetti"
	_confetti.tints = CONFETTI
	_confetti.gravity = 900.0
	stage.add_child(_confetti)
	_box = _fill(OrderBox.new())
	stage.add_child(_box)

	_title = _label(tr("CLC_SUPER_BOX_TITLE"), "title", ACCENT)
	layout.add_child(_title)
	_hint = _label(tr("CLC_SUPER_BOX_HINT") % TAPS_TO_OPEN, "body", UiStyle.TEXT_SOFT)
	layout.add_child(_hint)

	_contents = VBoxContainer.new()
	_contents.add_constant_override("separation", 10)
	_contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contents.modulate.a = 0.0
	layout.add_child(_contents)
	for item in items:
		_contents.add_child(_item_card(item.get("data"), str(item.get("label", "")), int(item.get("tier", 0))))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	layout.add_child(buttons)
	_button = Button.new()
	_button.text = tr("CLC_SUPER_BOX_OPEN")
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
	if is_open():
		close_popup("opened")
		return
	_taps += 1
	_box.shake(_taps)
	if _taps >= TAPS_TO_OPEN:
		_open()
	else:
		_hint.text = tr("CLC_SUPER_BOX_HINT") % (TAPS_TO_OPEN - _taps)


func _open() -> void:
	_box.open()
	_confetti.burst(70)
	_title.text = tr("CLC_SUPER_BOX_OPENED")
	_hint.text = tr("CLC_SUPER_BOX_LOCKED")
	_contents.modulate.a = 1.0
	_button.text = tr("CLC_SUPER_BOX_CLOSE")
