extends "res://mods-unpacked/Caritato-LegendsCollection/ui/legend_popup.gd"

# La Leyenda del Anzuelo: «¡Pica!». Cuando aparece el Anzuelo garantizado, el
# jugador pesca: el corcho flota un rato al azar y de pronto se hunde. Si se
# pulsa Aceptar mientras está hundido, se pesca y la tienda da un reroll
# gratis. Antes de tiempo, el pez se asusta; tarde, se escapa. Un intento.
#
# Resultado: "caught", "early", "missed" o "cancelled".

const FishingScene = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/widgets/fishing_scene.gd")
const HookRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/hook_legend/hook_rules.gd")

const ACCENT := Color("4fc3f7")
const BITE_WINDOW := 0.75
const RESULT_TIME := 1.8

var _scene: Control = null
var _title: Label = null
var _hint: Label = null
var _elapsed := 0.0
var _bite_at := 2.0
var _done := false


func _init() -> void:
	accent = ACCENT


func _build_content(layout: VBoxContainer) -> void:
	var stage := _stage(240)
	layout.add_child(stage)
	_scene = _fill(FishingScene.new())
	stage.add_child(_scene)
	_title = _label(tr("CLC_HOOK_FISH_TITLE"), "title", ACCENT)
	layout.add_child(_title)
	_hint = _label(tr("CLC_HOOK_FISH_HINT"), "body", UiStyle.TEXT_SOFT)
	layout.add_child(_hint)
	layout.add_child(_label(tr("CLC_HOOK_FISH_PRIZE"), "small", UiStyle.MUTED))


func _after_open() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_bite_at = rng.randf_range(1.4, 3.2)
	set_process(true)


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	if _scene.state == "waiting" and _elapsed >= _bite_at:
		start_bite()
	elif _scene.state == "bite" and _elapsed > _bite_at + BITE_WINDOW:
		finish_fishing("missed")


func start_bite() -> void:
	_scene.set_state("bite")
	_title.text = tr("CLC_HOOK_FISH_BITE")
	_title.add_color_override("font_color", UiStyle.WARN)


func _on_accept() -> void:
	if _done:
		return
	finish_fishing(HookRules.fishing_result(_elapsed, _bite_at, BITE_WINDOW))


func finish_fishing(outcome: String) -> void:
	if _done:
		return
	_done = true
	match outcome:
		"caught":
			_scene.set_state("caught")
			_title.text = tr("CLC_HOOK_FISH_CAUGHT")
			_title.add_color_override("font_color", UiStyle.OK)
			_hint.text = tr("CLC_HOOK_FISH_CAUGHT_TEXT")
		"early":
			_scene.set_state("missed")
			_title.text = tr("CLC_HOOK_FISH_EARLY")
			_title.add_color_override("font_color", UiStyle.MUTED)
			_hint.text = tr("CLC_HOOK_FISH_EARLY_TEXT")
		_:
			_scene.set_state("missed")
			_title.text = tr("CLC_HOOK_FISH_MISSED")
			_title.add_color_override("font_color", UiStyle.MUTED)
			_hint.text = tr("CLC_HOOK_FISH_MISSED_TEXT")
	close_later(RESULT_TIME, outcome)
