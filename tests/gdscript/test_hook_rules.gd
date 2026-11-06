extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda del Anzuelo.

var HookRules = load(MOD_PATH + "modules/hook_legend/hook_rules.gd")


func _init() -> void:
	run_case("anzuelo garantizado solo en la oleada elegida", "test_target_wave_only")
	run_case("modo repetir hasta tener uno", "test_until_owned")
	run_case("respeta prohibidos y máximo de anzuelos", "test_limits")
	run_case("elige un objeto no bloqueado como hueco", "test_pick_slot")
	finish()


func test_target_wave_only() -> void:
	check(not HookRules.should_guarantee(3, 4, false, 0, 3, false), "antes de la oleada no")
	check(HookRules.should_guarantee(4, 4, false, 0, 3, false), "en la oleada elegida sí")
	check(HookRules.should_guarantee(4, 4, false, 1, 3, false), "en la oleada elegida también si ya tiene uno")
	check(not HookRules.should_guarantee(5, 4, false, 0, 3, false), "después no, si no se repite")


func test_until_owned() -> void:
	check(HookRules.should_guarantee(7, 4, true, 0, 3, false), "se repite mientras no tenga ninguno")
	check(not HookRules.should_guarantee(7, 4, true, 1, 3, false), "deja de repetirse al tener uno")


func test_limits() -> void:
	check(not HookRules.should_guarantee(4, 4, false, 0, 3, true), "un anzuelo prohibido no aparece")
	check(not HookRules.should_guarantee(4, 4, false, 3, 3, false), "no supera el máximo")
	check(HookRules.should_guarantee(4, 4, false, 5, -1, false), "-1 significa sin límite")


func test_pick_slot() -> void:
	var item: String = HookRules.KIND_ITEM
	var weapon: String = HookRules.KIND_WEAPON
	check(HookRules.pick_slot([weapon, item, weapon, item], 0) == 3, "elige el último objeto")
	check(HookRules.pick_slot([item, weapon, weapon, weapon], 0) == 0, "busca objetos antes que armas")
	check(HookRules.pick_slot([item, item, weapon, weapon], 2) == 3, "sin objetos libres usa la última arma")
	check(HookRules.pick_slot([item, item, item, item], 4) == -1, "todo bloqueado: no hay hueco")
	check(HookRules.pick_slot([item, "", weapon], 1) == 2, "ignora huecos vacíos")
	check(HookRules.pick_slot([], 0) == -1, "tienda vacía")
