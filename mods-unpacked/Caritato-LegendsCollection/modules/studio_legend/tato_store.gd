extends Reference

# Tus tatos guardados: cada uno es un PNG de 50 × 50 (el dibujo, que se lleva
# a 150 × 150 sobre la patata) y un JSON con su nombre. También guarda qué
# tato lleva puesto cada jugador y exporta iconos para BroEditor.

const DEFAULT_DIR := "user://caritato_legends/tatos/"
const BROEDITOR_ICON_DIR := "user://Mojimoon-BroEditor/icons/"
const WORN_FILE := "worn.json"
const CANVAS := 50
const OVERLAY := 150
const ICON := 96

var dir := DEFAULT_DIR


func _init(p_dir: String = DEFAULT_DIR) -> void:
	dir = p_dir if p_dir.ends_with("/") else p_dir + "/"


# Identificador seguro a partir del nombre: minúsculas, números y guiones bajos.
static func make_id(name: String) -> String:
	var clean := ""
	for character in name.to_lower().strip_edges():
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			clean += character
		elif character in [" ", "-", "_"]:
			clean += "_"
		elif character in ["á", "à", "ä"]:
			clean += "a"
		elif character in ["é", "è", "ë"]:
			clean += "e"
		elif character in ["í", "ì", "ï"]:
			clean += "i"
		elif character in ["ó", "ò", "ö"]:
			clean += "o"
		elif character in ["ú", "ù", "ü"]:
			clean += "u"
		elif character == "ñ":
			clean += "n"
	while clean.find("__") != -1:
		clean = clean.replace("__", "_")
	clean = clean.strip_edges().trim_prefix("_").trim_suffix("_")
	return clean if clean != "" else "tato"


func list() -> Array:
	var result := []
	var directory := Directory.new()
	if directory.open(dir) != OK:
		return result
	var _err = directory.list_dir_begin(true, true)
	var file_name := directory.get_next()
	while file_name != "":
		if file_name.ends_with(".png"):
			var id := file_name.get_basename()
			result.append({"id": id, "name": _read_name(id)})
		file_name = directory.get_next()
	directory.list_dir_end()
	result.sort_custom(self, "_by_name")
	return result


func _by_name(a: Dictionary, b: Dictionary) -> bool:
	return str(a.name).to_lower() < str(b.name).to_lower()


func save(id: String, name: String, image: Image) -> int:
	var _err = Directory.new().make_dir_recursive(dir)
	var copy := normalized(image)
	var result := copy.save_png(dir + id + ".png")
	if result != OK:
		return result
	var file := File.new()
	if file.open(dir + id + ".json", File.WRITE) == OK:
		file.store_string(to_json({"name": name}))
		file.close()
	return OK


func load_image(id: String) -> Image:
	var image := Image.new()
	if not File.new().file_exists(dir + id + ".png") or image.load(dir + id + ".png") != OK:
		return null
	return normalized(image)


func delete(id: String) -> void:
	var directory := Directory.new()
	for extension in [".png", ".json"]:
		if directory.file_exists(dir + id + extension):
			var _err = directory.remove(dir + id + extension)
	var worn := worn_map()
	for key in worn.keys():
		if worn[key] == id:
			var _erased = worn.erase(key)
	_write_worn(worn)


func _read_name(id: String) -> String:
	var file := File.new()
	if file.open(dir + id + ".json", File.READ) != OK:
		return id
	var data = parse_json(file.get_as_text())
	file.close()
	return str(data.get("name", id)) if data is Dictionary else id


# --- Puestos ---------------------------------------------------------------------

func worn_map() -> Dictionary:
	var file := File.new()
	if file.open(dir + WORN_FILE, File.READ) != OK:
		return {}
	var data = parse_json(file.get_as_text())
	file.close()
	return data if data is Dictionary else {}


func worn_by(player_index: int) -> String:
	return str(worn_map().get(str(player_index), ""))


func set_worn(player_index: int, id: String) -> void:
	var worn := worn_map()
	if id == "":
		var _erased = worn.erase(str(player_index))
	else:
		worn[str(player_index)] = id
	_write_worn(worn)


func _write_worn(worn: Dictionary) -> void:
	var _err = Directory.new().make_dir_recursive(dir)
	var file := File.new()
	if file.open(dir + WORN_FILE, File.WRITE) == OK:
		file.store_string(to_json(worn))
		file.close()


# --- Imágenes ----------------------------------------------------------------------

# Cualquier imagen se lleva a 50 × 50 RGBA, manteniendo la proporción y centrada.
static func normalized(image: Image) -> Image:
	var source := Image.new()
	source.copy_from(image)
	if source.is_compressed():
		var _err = source.decompress()
	source.convert(Image.FORMAT_RGBA8)
	if source.get_width() == CANVAS and source.get_height() == CANVAS:
		return source
	var scale: float = float(CANVAS) / float(max(source.get_width(), source.get_height()))
	var width: int = int(max(1, round(source.get_width() * scale)))
	var height: int = int(max(1, round(source.get_height() * scale)))
	source.resize(width, height, Image.INTERPOLATE_NEAREST)
	var result := Image.new()
	result.create(CANVAS, CANVAS, false, Image.FORMAT_RGBA8)
	result.blit_rect(source, Rect2(0, 0, width, height), Vector2(int((CANVAS - width) / 2), int((CANVAS - height) / 2)))
	return result


# El dibujo a tamaño de la patata (150 × 150), para llevarlo en la partida.
static func overlay_image(image: Image) -> Image:
	var result := normalized(image)
	result.resize(OVERLAY, OVERLAY, Image.INTERPOLATE_NEAREST)
	return result


# Icono de 96 × 96 (patata + dibujo) para BroEditor.
static func icon_image(image: Image, potato: Image) -> Image:
	var canvas := Image.new()
	canvas.create(OVERLAY, OVERLAY, false, Image.FORMAT_RGBA8)
	if potato != null:
		var base := Image.new()
		base.copy_from(potato)
		if base.is_compressed():
			var _err = base.decompress()
		base.convert(Image.FORMAT_RGBA8)
		base.resize(OVERLAY, OVERLAY, Image.INTERPOLATE_BILINEAR)
		canvas.blend_rect(base, Rect2(0, 0, OVERLAY, OVERLAY), Vector2.ZERO)
	var drawing := overlay_image(image)
	canvas.blend_rect(drawing, Rect2(0, 0, OVERLAY, OVERLAY), Vector2.ZERO)
	canvas.resize(ICON, ICON, Image.INTERPOLATE_BILINEAR)
	return canvas


# Guarda el icono en la carpeta de iconos de BroEditor. Devuelve el nombre del
# archivo o "" si no se pudo.
func export_icon(id: String, image: Image, potato: Image, icon_dir: String = BROEDITOR_ICON_DIR) -> String:
	var _err = Directory.new().make_dir_recursive(icon_dir)
	var file_name := "caritato_" + id + ".png"
	if icon_image(image, potato).save_png(icon_dir + file_name) != OK:
		return ""
	return file_name
