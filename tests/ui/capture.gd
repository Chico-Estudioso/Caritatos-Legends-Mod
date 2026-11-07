extends SceneTree

# Saca capturas de las ventanas del mod para revisar el diseño sin Brotato.
# Lo lanza tools/capture_ui.py con Godot 3 en una pantalla virtual; las
# imágenes se guardan en la carpeta de la variable CLC_CAPTURE_DIR.
#
# Sin Brotato no hay partida ni objetos del juego: las ventanas se ven con los
# datos que el mod puede construir por sí mismo. La fuente imita la del juego
# si tools/capture_ui.py recibe una.

const MOD_PATH := "res://mods-unpacked/Caritato-LegendsCollection/"
const UiStyle = preload("res://mods-unpacked/Caritato-LegendsCollection/ui/ui_style.gd")
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

	yield(_capture_gift(), "completed")
	yield(_capture_supermarket(), "completed")
	yield(_capture_fishing(), "completed")

	print("Capturas guardadas: %d en %s" % [_saved, _out_dir])
	quit(0 if _saved > 0 else 1)


# Confirmación de un regalo (con un arma inventada) y la celebración al aceptar.
func _capture_gift() -> void:
	var fake := GDScript.new()
	fake.source_code = "extends Resource\nvar my_id := \"weapon_capture\"\nvar name := \"WEAPON_CAPTURE\"\nvar tier := 2\nvar icon = null\n"
	var _reloaded = fake.reload()
	var data = fake.new()
	data.icon = UiStyle.circle_texture(96, Color("ffd166"), Color("ff8c42"), 8.0)
	var offer := {"data": data, "is_weapon": true, "label": "Pistola láser", "tier": 2, "tags": ["CLC_GIFT_TAG_MECA"], "recipients": []}

	var confirm = load(MOD_PATH + "modules/gift_legend/gift_confirm.gd").new()
	root.add_child(confirm)
	confirm.open(core.get_runtime("gift_legend"), null, 0, 1, offer)
	yield(_frames(60), "completed")
	_save("regalo_1_confirmacion")
	confirm.celebrate()
	yield(_frames(12), "completed")
	_save("regalo_2_celebracion")
	confirm._finish("accepted")
	yield(_frames(2), "completed")


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


# Catálogo del Supermercado con artículos inventados (sin Brotato no hay objetos).
func _capture_supermarket() -> void:
	var fake := GDScript.new()
	fake.source_code = "extends Resource\nvar my_id := \"\"\nvar name := \"\"\nvar value := 0\nvar icon = null\n"
	var _reloaded = fake.reload()
	var legend := FakeSupermarket.new()
	var samples := [["Ojo de gato", 0, 18, false], ["Pala", 0, 22, true], ["Hucha", 1, 35, false], ["Lanzallamas", 1, 48, true], ["Corona", 2, 70, false], ["Láser médico", 3, 120, true]]
	for sample in samples:
		var item = fake.new()
		item.my_id = sample[0]
		item.name = sample[0]
		item.value = sample[2]
		item.icon = UiStyle.circle_texture(64, Color("ffd166").darkened(0.15 * sample[1]), Color("ff8c42"), 6.0)
		legend.entries.append({"item": item, "label": sample[0], "tier": sample[1], "is_weapon": sample[3]})

	var menu = load(MOD_PATH + "modules/supermarket_legend/supermarket_menu.gd").new()
	root.add_child(menu)
	menu.open(legend, null, 0, null)
	yield(_frames(8), "completed")
	_save("super_1_catalogo")
	menu._on_order_pressed(legend.entries[2])
	yield(_frames(4), "completed")
	_save("super_2_encargado")
	menu.close()
	legend.unlocked = false
	legend.left = 0
	menu = load(MOD_PATH + "modules/supermarket_legend/supermarket_menu.gd").new()
	root.add_child(menu)
	menu.open(legend, null, 0, null)
	yield(_frames(8), "completed")
	_save("super_3_sin_encargos")
	menu.close()
	yield(_frames(2), "completed")

	# La caja del encargo: cerrada (tras un toque) y abierta con confeti.
	var box = load(MOD_PATH + "modules/supermarket_legend/order_box_popup.gd").new()
	box.items = [{"data": legend.entries[4].item, "label": "Corona", "tier": 2}]
	core.show_popup(box)
	yield(_frames(10), "completed")
	box._on_accept()
	yield(_frames(4), "completed")
	_save("super_4_caja_cerrada")
	box._on_accept()
	box._on_accept()
	yield(_frames(14), "completed")
	_save("super_5_caja_abierta")
	box.close_popup("opened")
	yield(_frames(2), "completed")


# «¡Pica!» del Anzuelo: el corcho hundido y el pez pescado.
func _capture_fishing() -> void:
	var popup = load(MOD_PATH + "modules/hook_legend/fishing_popup.gd").new()
	core.show_popup(popup)
	popup.set_process(false)
	popup.start_bite()
	yield(_frames(12), "completed")
	_save("anzuelo_1_pica")
	popup.finish_fishing("caught")
	yield(_frames(24), "completed")
	_save("anzuelo_2_pescado")
	popup.close_popup("caught")
	yield(_frames(2), "completed")


class FakeSupermarket:
	extends Reference

	var entries := []
	var unlocked := true
	var left := 1

	func get_setting(key: String, fallback):
		return 50 if key == "order_markup_percent" else fallback

	func get_catalog(_player_index: int) -> Array:
		return entries

	func price_of(item, _player_index: int) -> int:
		return item.value

	func fee_of(item, _player_index: int) -> int:
		return int(ceil(item.value * 0.5))

	func orders_left(_player_index: int) -> int:
		return left

	func is_unlocked() -> bool:
		return unlocked

	func order(_shop, _item, _player_index: int) -> String:
		left -= 1
		return ""
