extends Node

# La Leyenda del Ratón.
#
# En cooperativo, el juego esconde el ratón con cualquier pulsación de
# cualquier jugador (InputService._input). Además, lo que se pulsa con el
# ratón no pasa por los FocusEmulator, así que la interfaz no sabe de qué
# jugador es. Esta leyenda:
# - deja el cursor visible mientras se usa el ratón; se oculta tras unos
#   segundos sin moverlo;
# - en cooperativo, solo deja pulsar, usar la rueda y resaltar en el panel de
#   quien juega con teclado y ratón (el J1 si todos usan mando). El cursor
#   pasa por encima de los demás paneles sin hacer nada en ellos;
# - atribuye a ese jugador lo que se pulsa con el ratón (extensión de
#   FocusEmulatorSignal);
# - en solitario con un mando conectado, hace que el cursor vuelva al mover
#   el ratón, aunque el mando mande eventos sin parar. Durante la oleada no se
#   toca: ahí el juego gestiona el cursor (puntería manual).
#
# Los paneles de cada jugador son las zonas de foco («bases») de los
# FocusEmulator de la pantalla: en la tienda, el contenedor de cada jugador.

const Compat = preload("res://mods-unpacked/Caritato-LegendsCollection/core/compat.gd")
const MouseRules = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/mouse_legend/mouse_rules.gd")

const FOCUS_EMULATOR_SCRIPT_SUFFIX := "focus_emulator.gd"
const MAIN_SCENE := "res://main.tscn"
# Si una pantalla no tenía FocusEmulator, cada cuánto se vuelve a buscar.
const RESCAN_MS := 2000

var core = null
var module_id := ""

var _last_mouse_ms := -1
# Hay un evento del ratón sin atribuir en este fotograma. Las señales y las
# llamadas diferidas que provoca llegan antes de _process, que lo limpia.
var _mouse_event_pending := false
var _shown := false
# FocusEmulator de la escena actual.
var _emulators := []
var _scanned_scene_id := 0
var _scanned_ms := -100000
# Para las pruebas: FocusEmulator que usar en lugar de buscarlos en la escena.
var emulators_override = null


func _init() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS


func setup(p_core, p_module_id: String) -> void:
	core = p_core
	module_id = p_module_id


func is_active() -> bool:
	return core != null and core.is_module_active(module_id)


func get_setting(key: String, fallback):
	if core == null:
		return fallback
	return core.get_setting(module_id, key, fallback)


# Este nodo cuelga de ModLoader, que va antes que InputService en el árbol:
# recibe cada evento justo después de que InputService haya escondido el
# cursor, y lo vuelve a mostrar si toca.
func _input(event: InputEvent) -> void:
	if not is_active():
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_on_mouse_event(event)
	_update_cursor()


func _process(_delta: float) -> void:
	_mouse_event_pending = false
	if is_active():
		_update_cursor()
	else:
		_shown = false


# --- Cooperativo -------------------------------------------------------------

func is_coop() -> bool:
	return Compat.is_coop_run() and Compat.get_player_count() > 1


func coop_mouse_enabled() -> bool:
	return is_coop() and bool(get_setting("coop_mouse", true))


func mouse_player() -> int:
	var uses_gamepad := []
	for player_index in Compat.get_player_count():
		uses_gamepad.append(Compat.player_uses_gamepad(player_index))
	return MouseRules.mouse_player(uses_gamepad)


# Paneles visibles de cada jugador: [{player, rect, node}]. Si los
# FocusEmulator están ocultos (pausa, ventanas de Caritatopc), no hay paneles
# y el ratón vale en toda la pantalla.
func visible_zones() -> Array:
	var zones := []
	for emulator in _focus_emulators():
		if emulator is CanvasItem and not emulator.is_visible_in_tree():
			continue
		var player = emulator.get("player_index")
		var bases = emulator.get("_focus_base_nodes")
		if player == null or int(player) < 0 or not bases is Array:
			continue
		for base in bases:
			if is_instance_valid(base) and base is Control and base.is_visible_in_tree():
				zones.append({"player": int(player), "rect": base.get_global_rect(), "node": base})
	return zones


# Jugador al que se atribuye un control que acaba de pulsar o resaltar el
# ratón (lo llama la extensión de FocusEmulatorSignal cuando el juego no sabe
# de quién es). Devuelve fallback si no es cosa del ratón.
func claim_player(control: Control, fallback: int) -> int:
	if not is_active() or not _mouse_event_pending or not coop_mouse_enabled() or not is_instance_valid(control):
		return fallback
	var owners := []
	for zone in visible_zones():
		var node: Control = zone.node
		if (node == control or node.is_a_parent_of(control)) and not owners.has(zone.player):
			owners.append(zone.player)
	var claimed: int = MouseRules.claim(owners, mouse_player())
	return claimed if claimed >= 0 else fallback


func _on_mouse_event(event: InputEvent) -> void:
	# Solo cuenta mover el ratón de verdad o pulsar: algunos sistemas mandan
	# movimientos sin desplazamiento al mostrar u ocultar el cursor.
	var moved: bool = event is InputEventMouseMotion and event.relative != Vector2.ZERO
	var pressed: bool = event is InputEventMouseButton and event.pressed
	if moved or pressed:
		_last_mouse_ms = OS.get_ticks_msec()
	if not coop_mouse_enabled():
		return
	var zone: int = MouseRules.zone_at(event.position, visible_zones(), mouse_player())
	var is_release: bool = event is InputEventMouseButton and not event.pressed
	if MouseRules.lets_through(zone, is_release):
		_mouse_event_pending = true
	else:
		get_tree().set_input_as_handled()


# --- Cursor ------------------------------------------------------------------

func should_show() -> bool:
	if not MouseRules.is_recent(OS.get_ticks_msec(), _last_mouse_ms, int(get_setting("hide_after", 5))):
		return false
	if is_coop():
		return bool(get_setting("coop_mouse", true))
	return bool(get_setting("solo_gamepad", true)) and not Input.get_connected_joypads().empty() and not _in_solo_wave()


func _update_cursor() -> void:
	if should_show():
		if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_shown = true
	elif _shown:
		_shown = false
		# En cooperativo el juego lo escondería con la siguiente pulsación;
		# se esconde ya. En solitario se deja como lo tenga el juego.
		if is_coop():
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _in_solo_wave() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	var scene = tree.current_scene
	return scene != null and scene.filename == MAIN_SCENE and not tree.paused


# FocusEmulator de la escena actual. Se buscan una vez por escena (la de la
# oleada tiene muchos nodos) y otra vez si alguno desaparece.
func _focus_emulators() -> Array:
	if emulators_override != null:
		return emulators_override
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return []
	var scene: Node = tree.current_scene
	var now := OS.get_ticks_msec()
	var stale := scene.get_instance_id() != _scanned_scene_id
	for emulator in _emulators:
		if not is_instance_valid(emulator):
			stale = true
	if _emulators.empty() and now - _scanned_ms > RESCAN_MS:
		stale = true
	if stale:
		_emulators = find_focus_emulators(scene)
		_scanned_scene_id = scene.get_instance_id()
		_scanned_ms = now
	return _emulators


static func find_focus_emulators(root: Node) -> Array:
	var found := []
	var pending := [root]
	while not pending.empty():
		var node: Node = pending.pop_back()
		var script = node.get_script()
		if script != null and str(script.resource_path).ends_with(FOCUS_EMULATOR_SCRIPT_SUFFIX):
			found.append(node)
		for child in node.get_children():
			pending.append(child)
	return found
