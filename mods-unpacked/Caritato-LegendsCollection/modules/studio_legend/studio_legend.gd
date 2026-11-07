extends Node

# El Taller de los Tatos: lo que Caritatopc añade a BroEditor (de Mojimoon).
#
# - «Tus tatos»: un editor de píxeles para dibujar el aspecto de tu patata.
#   Se puede llevar puesto en las partidas y, con BroEditor, se guarda también
#   como icono para sus personajes y objetos.
# - Medidor de poder: compara personajes y objetos (también los de BroEditor)
#   con los del juego y avisa si algo es demasiado fuerte.
#
# Crear personajes y objetos se hace con BroEditor: el Taller lo indica y da el
# enlace de descarga si no está instalado.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const PowerRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/studio_legend/power_rules.gd")
const TatoStore = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/studio_legend/tato_store.gd")
const EDITOR_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/studio_legend/tato_editor.gd"
const METER_PATH := "res://mods-unpacked/Caritato-LegendsCollection/modules/studio_legend/power_meter.gd"
const BROEDITOR_ID := "Mojimoon-BroEditor"
const BROEDITOR_URL := "https://steamcommunity.com/sharedfiles/filedetails/?id=3817655214"
const LOG_NAME := "Caritato-LegendsCollection:Studio"

var core = null
var module_id := ""
var store = TatoStore.new()
var _textures := {}


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


func broeditor_loaded() -> bool:
	return Compat.is_mod_loaded(BROEDITOR_ID)


func exports_to_broeditor() -> bool:
	return broeditor_loaded() and bool(get_setting("export_broeditor", true))


# --- Acciones del menú Caritatopc -------------------------------------------------------

func open_tatos(host = null) -> Node:
	return _open_screen(EDITOR_PATH, host, [self, store])


func open_power_meter(host = null) -> Node:
	return _open_screen(METER_PATH, host, [self])


func open_broeditor_page(_host = null) -> void:
	var _err = OS.shell_open(BROEDITOR_URL)


func _open_screen(path: String, host, args: Array) -> Node:
	var script = load(path)
	var tree = get_tree()
	if script == null or tree == null:
		return null
	var screen = script.new()
	tree.root.add_child(screen)
	screen.callv("open", args)
	if host != null and is_instance_valid(host) and "overlay" in host:
		host.overlay = screen
	return screen


# --- Medidor de poder ------------------------------------------------------------------

# [{name, icon, score, rating, tier}] de mayor a menor puntuación. Los
# personajes se comparan con todos los personajes; los objetos, con los de su
# misma rareza.
func power_entries(kind: String) -> Array:
	var source: Array = Compat.get_characters() if kind == "characters" else Compat.get_items()
	var entries := []
	var by_tier := {}
	for data in source:
		if data == null:
			continue
		var tier: int = int(data.tier) if "tier" in data else 0
		var score: float = PowerRules.total(Compat.effect_summaries(data))
		entries.append({
			"name": tr(str(data.name)) if "name" in data else "?",
			"icon": Compat.item_icon(data),
			"score": score,
			"tier": tier,
		})
		var group: int = 0 if kind == "characters" else tier
		if not by_tier.has(group):
			by_tier[group] = []
		by_tier[group].append(score)
	for entry in entries:
		var group: int = 0 if kind == "characters" else int(entry.tier)
		entry["rating"] = PowerRules.rating(float(entry.score), by_tier.get(group, []))
	entries.sort_custom(self, "_by_score")
	return entries


func _by_score(a: Dictionary, b: Dictionary) -> bool:
	return float(a.score) > float(b.score)


# --- Tus tatos en la partida -----------------------------------------------------------

# Textura de 150 × 150 del tato que lleva puesto un jugador (o null).
func worn_texture(player_index: int) -> Texture:
	if not is_active() or not bool(get_setting("wear_in_runs", true)):
		return null
	var id: String = store.worn_by(player_index)
	if id == "":
		return null
	if _textures.has(id):
		return _textures[id]
	var image: Image = store.load_image(id)
	if image == null:
		return null
	var texture := ImageTexture.new()
	texture.create_from_image(TatoStore.overlay_image(image), 0)
	_textures[id] = texture
	return texture


func forget_textures() -> void:
	_textures.clear()
