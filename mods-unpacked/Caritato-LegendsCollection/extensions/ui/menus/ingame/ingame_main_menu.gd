extends "res://ui/menus/ingame/ingame_main_menu.gd"

# Añade el botón «Leyendas» al menú de pausa, debajo de «Opciones», para
# ajustar valores sin salir de la partida.

const LegendsAPI = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")

var _clc_legends_button: Button = null


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática (primero el del juego), así que no se llama a ._ready().
func _ready() -> void:
	_clc_add_legends_button()


func _clc_add_legends_button() -> void:
	if _clc_legends_button != null and is_instance_valid(_clc_legends_button):
		return
	var options_button = get_node_or_null("%OptionsButton")
	if options_button == null or options_button.get_parent() == null:
		return

	var button := Button.new()
	button.set_script(options_button.get_script())
	button.name = "CaritatoLegendsButton"
	button.text = tr("CLC_MENU_BUTTON")
	button.size_flags_horizontal = options_button.size_flags_horizontal
	button.size_flags_vertical = options_button.size_flags_vertical
	button.rect_min_size = options_button.rect_min_size

	var container: Node = options_button.get_parent()
	container.add_child_below_node(options_button, button)
	var _err = button.connect("pressed", self, "_clc_on_legends_button_pressed")
	_clc_legends_button = button

	if "_buttons_array" in self and _buttons_array is Array:
		_buttons_array.append(button)


func _clc_on_legends_button_pressed() -> void:
	var _menu = LegendsAPI.open_menu("ingame", _clc_legends_button)
