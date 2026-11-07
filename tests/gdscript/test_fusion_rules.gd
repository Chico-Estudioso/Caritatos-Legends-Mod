extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda de la Fusión.

var FusionRules = load(MOD_PATH + "modules/fusion_legend/fusion_rules.gd")


func _init() -> void:
	run_case("penalizaciones a partir de los ajustes", "test_penalties")
	run_case("compañeros posibles", "test_partners")
	run_case("movimiento por la cuadrícula", "test_grid")
	finish()


func test_penalties() -> void:
	var values: Array = FusionRules.penalty_values({"penalty_xp": 10, "penalty_price": 20, "penalty_enemies": 0, "penalty_speed": 5})
	check(values == [["xp_gain", -10], ["items_price", 20], ["enemy_speed", 5]], "la experiencia baja y el resto sube; los ceros no cuentan")
	check(FusionRules.penalty_values({}).empty(), "sin ajustes no hay penalizaciones")


func test_partners() -> void:
	var entries := [
		{"id": "character_bull", "unlocked": true},
		{"id": "character_mage", "unlocked": false},
		{"id": "character_ghost", "unlocked": true},
	]
	check(FusionRules.partner_indices(entries, "character_bull", false) == [2], "ni el propio ni los bloqueados")
	check(FusionRules.partner_indices(entries, "character_bull", true) == [1, 2], "con bloqueados permitidos")


func test_grid() -> void:
	check(FusionRules.grid_move(0, 30, 12, -1, 0) == 0, "no se sale por la izquierda")
	check(FusionRules.grid_move(11, 30, 12, 1, 0) == 12, "a la derecha pasa a la fila siguiente")
	check(FusionRules.grid_move(5, 30, 12, 0, 1) == 17, "abajo baja una fila")
	check(FusionRules.grid_move(20, 30, 12, 0, 1) == 20, "abajo desde la última fila no se mueve")
	check(FusionRules.grid_move(3, 30, 12, 0, -1) == 3, "arriba desde la primera fila no se mueve")
	check(FusionRules.grid_move(0, 0, 12, 1, 0) == 0, "sin personajes")
