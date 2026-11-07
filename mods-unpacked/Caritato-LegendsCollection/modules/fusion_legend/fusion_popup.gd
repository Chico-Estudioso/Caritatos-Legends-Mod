extends "res://mods-unpacked/Caritato-LegendsCollection/ui/legend_popup.gd"

# «¡Fusión de bros!»: al empezar la partida, el jugador elige con qué personaje
# fusionarse en una cuadrícula (mando, teclado o ratón). Se ven sus efectos y
# las penalizaciones; al confirmar, los dos personajes chocan los puños.
#
# Resultado («closed»): "partner:<posición en partners>" o "none".

const FistBump = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/fist_bump.gd")
const Sparkles = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/sparkles.gd")
const FusionRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/fusion_legend/fusion_rules.gd")

const ACCENT := Color("ff8fd8")
const COLUMNS := 12
const CELL := 62
const PENALTY_KEYS := {
	"xp_gain": "CLC_FUSION_PEN_XP",
	"items_price": "CLC_FUSION_PEN_PRICE",
	"number_of_enemies": "CLC_FUSION_PEN_ENEMIES",
	"enemy_speed": "CLC_FUSION_PEN_SPEED",
}

var player_number := 1
var own_icon: Texture = null
# [{id, name, icon, text, data}]
var partners := []
# [[efecto, valor]]
var penalties := []

var _selected := 0
var _cells := []
var _bros: Control = null
var _sparkles: Control = null
var _partner_icon: TextureRect = null
var _title: Label = null
var _subtitle: Label = null
var _name: Label = null
var _effects: RichTextLabel = null
var _controls := []


func _init() -> void:
	accent = ACCENT


func selected() -> int:
	return _selected


func _build_content(layout: VBoxContainer) -> void:
	_card_width(1060)
	var stage := _stage(130)
	layout.add_child(stage)
	_sparkles = _fill(Sparkles.new())
	_sparkles.ambient = false
	_sparkles.tints = [ACCENT, UiStyle.BRAND, UiStyle.SPARK, Color(1, 1, 1)]
	stage.add_child(_sparkles)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_fill(center))
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGN_CENTER
	header.add_constant_override("separation", 18)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(header)
	header.add_child(_portrait(own_icon))
	_bros = FistBump.new()
	_bros.color = Compat.player_color(int(max(0, player_index)))
	_bros.color_right = ACCENT
	_bros.spark_color = UiStyle.SPARK
	_bros.animate = true
	_bros.rect_min_size = Vector2(210, 108)
	header.add_child(_bros)
	_partner_icon = _portrait(null)
	header.add_child(_partner_icon)

	_title = _label(tr("CLC_FUSION_TITLE"), "title", ACCENT)
	layout.add_child(_title)
	var question: String = tr("CLC_FUSION_QUESTION_PLAYER") % player_number if player_index >= 0 else tr("CLC_FUSION_QUESTION")
	_subtitle = _label(question, "body", UiStyle.TEXT_SOFT)
	layout.add_child(_subtitle)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_constant_override("hseparation", 8)
	grid.add_constant_override("vseparation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(grid)
	for index in partners.size():
		var cell := _cell(partners[index], index)
		grid.add_child(cell)
		_cells.append(cell)

	var info := VBoxContainer.new()
	info.add_constant_override("separation", 4)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(info)
	_name = _label("", "name", UiStyle.TEXT)
	info.add_child(_name)
	_effects = RichTextLabel.new()
	_effects.bbcode_enabled = true
	_effects.fit_content_height = true
	_effects.scroll_active = false
	_effects.rect_min_size = Vector2(900, 60)
	_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var effects_font = _fonts.get("small")
	if effects_font != null:
		_effects.add_font_override("normal_font", effects_font)
	info.add_child(_effects)

	if not penalties.empty():
		var chips := HBoxContainer.new()
		chips.alignment = BoxContainer.ALIGN_CENTER
		chips.add_constant_override("separation", 8)
		chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chips.add_child(_chip(tr("CLC_FUSION_COST"), UiStyle.TEXT_SOFT, UiStyle.SURFACE_3))
		for penalty in penalties:
			var key: String = PENALTY_KEYS.get(penalty[0], "")
			if key != "":
				chips.add_child(_chip(tr(key) % int(abs(int(penalty[1]))), UiStyle.INK, UiStyle.WARN))
		layout.add_child(chips)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 24)
	layout.add_child(buttons)
	var none := Button.new()
	none.text = tr("CLC_FUSION_NONE")
	none.rect_min_size = Vector2(240, 60)
	UiStyle.style_button(none, "ghost", ACCENT, 26)
	var _err = none.connect("pressed", self, "_on_none_pressed")
	buttons.add_child(none)
	var fuse_button := Button.new()
	fuse_button.text = tr("CLC_FUSION_FUSE")
	fuse_button.rect_min_size = Vector2(280, 60)
	UiStyle.style_button(fuse_button, "primary", ACCENT, 28)
	_err = fuse_button.connect("pressed", self, "_on_fuse_pressed")
	buttons.add_child(fuse_button)
	_controls = [none, fuse_button]
	if player_index >= 0:
		layout.add_child(_label(tr("CLC_FUSION_WHO") % player_number, "small", Compat.player_color(player_index)))


func _after_open() -> void:
	select(0)


# Entrada: flechas o stick por la cuadrícula, aceptar fusiona, atrás no.
func _handle_input(event: InputEvent) -> void:
	if _is_released(event, "ui_cancel") or _is_released(event, "ui_pause"):
		choose_none()
	elif _is_pressed(event, "ui_accept"):
		fuse()
	elif _is_pressed(event, "ui_left"):
		_move(-1, 0)
	elif _is_pressed(event, "ui_right"):
		_move(1, 0)
	elif _is_pressed(event, "ui_up"):
		_move(0, -1)
	elif _is_pressed(event, "ui_down"):
		_move(0, 1)


func _move(dx: int, dy: int) -> void:
	select(FusionRules.grid_move(_selected, partners.size(), COLUMNS, dx, dy))


func select(index: int) -> void:
	if partners.empty():
		return
	_selected = int(clamp(index, 0, partners.size() - 1))
	for i in _cells.size():
		_style_cell(_cells[i], i == _selected)
	var partner: Dictionary = partners[_selected]
	_partner_icon.texture = partner.get("icon")
	_name.text = str(partner.get("name", ""))
	_effects.bbcode_text = "[center]%s[/center]" % str(partner.get("text", ""))


func fuse() -> void:
	if is_closing() or partners.empty():
		return
	for control in _controls:
		control.disabled = true
		control.focus_mode = Control.FOCUS_NONE
	_bros.bump()
	_sparkles.burst(44)
	_title.text = tr("CLC_FUSION_DONE")
	_subtitle.text = tr("CLC_FUSION_DONE_TEXT") % str(partners[_selected].get("name", ""))
	close_later(1.6, "partner:%d" % _selected)


func choose_none() -> void:
	if not is_closing():
		close_popup("none")


func _on_fuse_pressed() -> void:
	if mouse_allowed():
		fuse()


func _on_none_pressed() -> void:
	if mouse_allowed():
		choose_none()


func _on_cell_input(event: InputEvent, index: int) -> void:
	if is_closing() or not mouse_allowed():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if index == _selected and event.doubleclick:
			fuse()
		else:
			select(index)


# --- Construcción ------------------------------------------------------------------

func _card_width(width: float) -> void:
	if _card != null:
		_card.rect_min_size.x = width


func _portrait(texture: Texture) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand = true
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.rect_min_size = Vector2(96, 96)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _cell(partner: Dictionary, index: int) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.rect_min_size = Vector2(CELL, CELL)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon := TextureRect.new()
	icon.texture = partner.get("icon")
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.rect_min_size = Vector2(CELL - 12, CELL - 12)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon)
	_style_cell(cell, false)
	var _err = cell.connect("gui_input", self, "_on_cell_input", [index])
	return cell


func _style_cell(cell: PanelContainer, chosen: bool) -> void:
	if chosen:
		cell.add_stylebox_override("panel", UiStyle.bordered(UiStyle.SURFACE_3, 12, ACCENT, 3, Vector2(4, 4)))
	else:
		cell.add_stylebox_override("panel", UiStyle.box(UiStyle.SURFACE_2, 12, Vector2(6, 6)))
