extends SceneTree

# Saca capturas de las ventanas del mod para revisar el diseño sin Brotato.
# Lo lanza tools/capture_ui.py con Godot 3 en una pantalla virtual; las
# imágenes se guardan en la carpeta de la variable CLC_CAPTURE_DIR.
#
# Sin Brotato no hay partida ni objetos del juego: las ventanas se ven con los
# datos que el mod puede construir por sí mismo. La fuente imita la del juego
# si tools/capture_ui.py recibe una.

const MOD_PATH := "res://mods-unpacked/Caritato-LegendsCollection/"
const CONFIG_PATH := "user://caritato_legends/settings.json"

var core = null
var _out_dir := ""
var _saved := 0


func _initialize() -> void:
	_out_dir = OS.get_environment("CLC_CAPTURE_DIR")
	if _out_dir == "":
		_out_dir = "user://capturas"
	var _err = Directory.new().make_dir_recursive(_out_dir)
	VisualServer.set_default_clear_color(Color("3b3a3f"))
	TranslationServer.set_locale("es")

	var dir := Directory.new()
	if dir.file_exists(CONFIG_PATH):
		_err = dir.remove(CONFIG_PATH)
	core = load(MOD_PATH + "core/legends_core.gd").new()
	core.name = "LegendsCore"
	root.add_child(core)
	core.boot(MOD_PATH.trim_suffix("/"), "0.3.0")
	_run()


func _run() -> void:
	yield(_frames(3), "completed")

	var menu = core.open_menu("title")
	yield(_frames(8), "completed")
	_save("menu_1_anzuelo")

	for id in ["supermarket_legend", "gift_legend", "endless_harvest"]:
		menu._select(id)
		yield(_frames(6), "completed")
		_save("menu_%d_%s" % [_saved + 1, id])

	# Con el foco en un ajuste, su explicación aparece abajo.
	menu._select("merchant_legend")
	var controls: Array = menu._detail.controls
	if not controls.empty():
		controls[0].control.grab_focus()
	yield(_frames(6), "completed")
	_save("menu_%d_foco_en_ajuste" % (_saved + 1))

	menu._on_cancel_pressed()
	yield(_frames(3), "completed")
	_extra_captures()


# Las PR que añaden ventanas nuevas amplían esta función.
func _extra_captures() -> void:
	print("Capturas guardadas: %d en %s" % [_saved, _out_dir])
	quit(0 if _saved > 0 else 1)


func _frames(count: int) -> void:
	for _i in count:
		yield(self, "idle_frame")


func _save(name: String) -> void:
	var image: Image = root.get_texture().get_data()
	image.flip_y()
	var path := _out_dir.plus_file(name + ".png")
	var err := image.save_png(path)
	if err == OK:
		_saved += 1
		print("Captura: %s" % path)
	else:
		print("No se pudo guardar %s (error %d)" % [path, err])
