extends "res://ui/menus/pages/main_menu.gd"

# Añade el botón «Leyendas» al menú principal, debajo del botón «Mods».

const _CLC_CORE_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")

var _clc_core_legends_button: Button = null


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática (primero el del juego), así que no se llama a ._ready().
func _ready() -> void:
	_clc_core_add_legends_button()


func _clc_core_add_legends_button() -> void:
	if _clc_core_legends_button != null and is_instance_valid(_clc_core_legends_button):
		return
	if mods_button == null or mods_button.get_parent() == null:
		return

	# Botón nuevo con el mismo script (sonidos y foco del juego) y sin copiar
	# las conexiones del botón original.
	var button := Button.new()
	button.set_script(mods_button.get_script())
	button.name = "CaritatoLegendsButton"
	button.text = tr("CLC_MENU_BUTTON")
	button.size_flags_horizontal = mods_button.size_flags_horizontal
	button.size_flags_vertical = mods_button.size_flags_vertical
	button.rect_min_size = mods_button.rect_min_size
	button.focus_neighbour_left = mods_button.focus_neighbour_left
	button.focus_neighbour_right = mods_button.focus_neighbour_right

	var container: Node = mods_button.get_parent()
	container.add_child_below_node(mods_button, button)
	var _err = button.connect("pressed", self, "_clc_core_on_legends_button_pressed")
	_clc_core_legends_button = button


func _clc_core_on_legends_button_pressed() -> void:
	var _menu = _CLC_CORE_API.open_menu("title", _clc_core_legends_button)
