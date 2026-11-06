extends Node

# Punto de entrada que ModLoader instancia al arrancar Brotato.
#
# ModLoader solo permite instalar extensiones de scripts durante su fase de
# inicialización, así que aquí se lee la configuración del jugador y se cargan
# únicamente las leyendas activadas. Activar una leyenda que no estaba cargada
# requiere reiniciar el juego; la interfaz lo indica.

const MOD_ID := "Caritato-LegendsCollection"
const LOG_NAME := "Caritato-LegendsCollection:Main"
const VERSION := "0.1.0"

var mod_dir := ""
var core: Node = null


func _init() -> void:
	mod_dir = ModLoaderMod.get_unpacked_dir().plus_file(MOD_ID)
	ModLoaderLog.info("Iniciando Caritatos Legends v%s" % VERSION, LOG_NAME)

	var core_script = load(mod_dir.plus_file("core/legends_core.gd"))
	if core_script == null:
		ModLoaderLog.error("No se pudo cargar el núcleo; la colección queda desactivada.", LOG_NAME)
		return

	core = core_script.new()
	core.name = "LegendsCore"
	add_child(core)
	core.boot(mod_dir, VERSION)

	_install_core_extensions()


func _install_core_extensions() -> void:
	# Accesos a la pantalla de configuración (menú principal y menú de pausa).
	var extensions := [
		"extensions/ui/menus/pages/main_menu.gd",
		"extensions/ui/menus/ingame/ingame_main_menu.gd",
	]
	for extension in extensions:
		var path: String = mod_dir.plus_file(extension)
		if File.new().file_exists(path) or ResourceLoader.exists(path):
			ModLoaderMod.install_script_extension(path)
		else:
			ModLoaderLog.error("Falta la extensión del núcleo: %s" % path, LOG_NAME)


func _ready() -> void:
	ModLoaderLog.success("Caritatos Legends listo.", LOG_NAME)
