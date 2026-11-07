extends Node

# Punto de entrada que ModLoader instancia al arrancar Brotato.
#
# Dos momentos de instalación:
# - _init(): se lee la configuración, se deciden las leyendas que se cargan y
#   se instalan las extensiones de autoloads (res://singletons/...), que deben
#   estar antes de que el juego cree esos nodos.
# - _ready(): se instalan las extensiones de scripts de escenas (tienda,
#   main.gd, menús). En Brotato 1.2.0.1 cargar base_shop.gd durante _init
#   rompe su compilación y el CrashReporter desactiva todos los mods.
#
# Activar una leyenda que no estaba cargada requiere reiniciar el juego; la
# interfaz lo indica.

const MOD_ID := "Caritato-LegendsCollection"
const LOG_NAME := "Caritato-LegendsCollection:Main"
const VERSION := "0.2.0"

# Accesos a la pantalla de configuración (menú principal y menú de pausa).
const CORE_EXTENSIONS := [
	"extensions/ui/menus/pages/main_menu.gd",
	"extensions/ui/menus/ingame/ingame_main_menu.gd",
]

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


func _ready() -> void:
	_install_core_extensions()
	if core != null:
		core.install_late_extensions()
	ModLoaderLog.success("Caritatos Legends listo.", LOG_NAME)


func _install_core_extensions() -> void:
	for extension in CORE_EXTENSIONS:
		var path: String = mod_dir.plus_file(extension)
		if File.new().file_exists(path) or ResourceLoader.exists(path):
			ModLoaderMod.install_script_extension(path)
		else:
			ModLoaderLog.error("Falta la extensión del núcleo: %s" % path, LOG_NAME)
