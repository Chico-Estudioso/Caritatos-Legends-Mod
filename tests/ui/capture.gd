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
	core.boot(MOD_PATH.trim_suffix("/"), "1.0.0")
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
	yield(_capture_haggle_and_harvest(), "completed")
	yield(_capture_preview(), "completed")

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
	confirm.setup(core.get_runtime("gift_legend"), null, 0, 1, offer)
	core.show_popup(confirm)
	yield(_frames(60), "completed")
	_save("regalo_1_confirmacion")
	confirm.celebrate()
	yield(_frames(12), "completed")
	_save("regalo_2_celebracion")
	confirm.close_popup("accepted")
	yield(_frames(2), "completed")

	# Elegir a quién regalar (cuatro jugadores, uno sin hueco de arma).
	var picker = load(MOD_PATH + "modules/gift_legend/gift_recipient_popup.gd").new()
	picker.player_index = 0
	picker.offer = {"data": data, "is_weapon": true, "label": "Pistola láser", "tier": 2, "tags": [], "recipients": [
		{"index": 1, "reason": ""},
		{"index": 2, "reason": "CLC_GIFT_REASON_NO_SLOT"},
		{"index": 3, "reason": ""},
	]}
	core.show_popup(picker)
	yield(_frames(6), "completed")
	_save("regalo_3_elegir")
	picker.close_popup("cancelled")
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


# Regateo del Mercader y cosecha dorada de la Cosecha Eterna.
func _capture_haggle_and_harvest() -> void:
	var haggle = load(MOD_PATH + "modules/merchant_legend/haggle_popup.gd").new()
	haggle.max_percent = 10
	core.show_popup(haggle)
	haggle._meter.position = 0.2
	yield(_frames(8), "completed")
	_save("mercader_1_regateo")
	haggle.stop_at("green")
	yield(_frames(10), "completed")
	_save("mercader_2_trato")
	haggle.close_popup("green")
	yield(_frames(2), "completed")

	var harvest = load(MOD_PATH + "modules/endless_harvest/harvest_popup.gd").new()
	harvest.harvesting = 150
	harvest.full_reward = 15
	harvest.near_reward = 7
	core.show_popup(harvest)
	harvest._field._time = 1.55
	yield(_frames(6), "completed")
	_save("cosecha_1_trigo")
	harvest.harvest_at("gold")
	yield(_frames(10), "completed")
	_save("cosecha_2_dorada")
	harvest.close_popup("gold")
	yield(_frames(2), "completed")


# Portada del Workshop (512×512): corazón, título y las leyendas. Solo piezas
# dibujadas por el mod, sin recursos del juego.
func _capture_preview() -> void:
	var Heart = load(MOD_PATH + "ui/widgets/heart.gd")
	var Sparkles = load(MOD_PATH + "ui/widgets/sparkles.gd")
	var layer := CanvasLayer.new()
	layer.layer = 200
	root.add_child(layer)
	var canvas := Panel.new()
	canvas.rect_position = Vector2.ZERO
	canvas.rect_size = Vector2(512, 512)
	var background := UiStyle.box(Color("1a1424"), 0, Vector2.ZERO)
	background.border_color = UiStyle.BRAND
	background.set_border_width_all(6)
	canvas.add_stylebox_override("panel", background)
	layer.add_child(canvas)
	var theme := UiStyle.game_theme()
	if theme != null:
		canvas.theme = theme

	var sparkles = Sparkles.new()
	sparkles.rect_size = Vector2(512, 330)
	sparkles.spread = Vector2(210, 120)
	canvas.add_child(sparkles)
	var heart = Heart.new()
	heart.color = UiStyle.BRAND
	heart.rect_position = Vector2(156, 34)
	heart.rect_size = Vector2(200, 200)
	canvas.add_child(heart)

	var title := Label.new()
	title.text = "Caritatopc"
	title.align = Label.ALIGN_CENTER
	title.rect_position = Vector2(0, 236)
	title.rect_size = Vector2(512, 80)
	title.add_color_override("font_color", UiStyle.BRAND)
	var title_font = UiStyle.font(76, 3)
	if title_font != null:
		title.add_font_override("font", title_font)
	canvas.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Brotato Legends Collection"
	subtitle.align = Label.ALIGN_CENTER
	subtitle.rect_position = Vector2(0, 322)
	subtitle.rect_size = Vector2(512, 40)
	subtitle.add_color_override("font_color", UiStyle.TEXT_SOFT)
	var subtitle_font = UiStyle.font(30)
	if subtitle_font != null:
		subtitle.add_font_override("font", subtitle_font)
	canvas.add_child(subtitle)

	var ids: Array = core.get_module_ids()
	var tile_size := 66.0
	var gap := 14.0
	var start := (512.0 - ids.size() * tile_size - (ids.size() - 1) * gap) / 2.0
	for i in ids.size():
		var definition: Dictionary = core.get_definition(ids[i])
		var tile := Panel.new()
		tile.rect_position = Vector2(start + i * (tile_size + gap), 404)
		tile.rect_size = Vector2(tile_size, tile_size)
		tile.add_stylebox_override("panel", UiStyle.box(Color(definition.accent), 18, Vector2.ZERO))
		canvas.add_child(tile)
		var letter := Label.new()
		letter.text = tr(definition.short_name_key).substr(0, 1).to_upper()
		letter.align = Label.ALIGN_CENTER
		letter.valign = Label.VALIGN_CENTER
		letter.rect_size = Vector2(tile_size, tile_size)
		letter.add_color_override("font_color", UiStyle.INK)
		var letter_font = UiStyle.font(40)
		if letter_font != null:
			letter.add_font_override("font", letter_font)
		tile.add_child(letter)

	yield(_frames(90), "completed")
	var image: Image = root.get_texture().get_data()
	image.flip_y()
	var preview := image.get_rect(Rect2(0, 0, 512, 512))
	var path := _out_dir.plus_file("preview.png")
	if preview.save_png(path) == OK:
		_saved += 1
		print("Portada: %s" % path)
	layer.queue_free()
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
