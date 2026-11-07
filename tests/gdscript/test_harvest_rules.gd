extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda de la Cosecha Eterna.

var HarvestRules = load(MOD_PATH + "modules/endless_harvest/harvest_rules.gd")


func _init() -> void:
	run_case("modo según oleada y configuración", "test_mode")
	run_case("pérdida de recolección redondeada hacia arriba", "test_decay_amount")
	run_case("interés de la Hucha", "test_piggy_bank")
	run_case("objetos permitidos de nuevo en el modo infinito", "test_filter_bans")
	run_case("cosecha dorada: zona y premio", "test_golden")
	finish()


func test_mode() -> void:
	check(HarvestRules.endless_mode(false, true, true, 0, 20) == "vanilla", "inactiva: el juego decide")
	check(HarvestRules.endless_mode(true, false, true, 0, 20) == "vanilla", "antes de la oleada 21: el juego decide")
	check(HarvestRules.endless_mode(true, true, true, 0, 20) == "grow", "crecer tiene prioridad")
	check(HarvestRules.endless_mode(true, true, false, 0, 20) == "decay", "0 % sustituye al juego")
	check(HarvestRules.endless_mode(true, true, false, 20, 20) == "vanilla", "el mismo porcentaje del juego no se reemplaza")
	check(HarvestRules.endless_mode(true, true, false, 35, 20) == "decay", "más severo que el juego")


func test_decay_amount() -> void:
	check(HarvestRules.decay_amount(100.0, 20) == 20, "20 % de 100")
	check(HarvestRules.decay_amount(7.0, 10) == 1, "se redondea hacia arriba")
	check(HarvestRules.decay_amount(50.0, 0) == 0, "0 % no quita nada")
	check(HarvestRules.decay_amount(-5.0, 20) == 0, "recolección negativa no cambia")
	check(HarvestRules.decay_amount(3.0, 100) == 3, "100 % lo quita todo")


func test_piggy_bank() -> void:
	check(HarvestRules.piggy_bank_amount(250, 20.0) == 50, "20 % de 250")
	check(HarvestRules.piggy_bank_amount(9, 25.0) == 2, "se trunca como el juego")
	check(HarvestRules.piggy_bank_amount(0, 20.0) == 0, "sin materiales no hay interés")
	check(HarvestRules.piggy_bank_amount(100, -10.0) == 0, "un porcentaje negativo no lo gestiona la leyenda")


func test_filter_bans() -> void:
	var bans := ["item_piggy_bank", "item_crown", 1234]
	check(HarvestRules.filter_bans(bans, ["item_piggy_bank"], []) == ["item_crown", 1234], "quita la Hucha por id")
	check(HarvestRules.filter_bans(bans, [], [1234]) == ["item_piggy_bank", "item_crown"], "quita por hash")
	check(HarvestRules.filter_bans(bans, [], []).size() == 3, "sin permisos, la lista no cambia")
	check(bans.size() == 3, "no modifica la lista original")


func test_golden() -> void:
	check(HarvestRules.golden_zone(0.95) == "gold", "trigo dorado")
	check(HarvestRules.golden_zone(0.7) == "near", "casi dorado")
	check(HarvestRules.golden_zone(0.3) == "none", "trigo verde")
	check(HarvestRules.golden_reward(150, "gold", 10) == 15, "10 % de la recolección")
	check(HarvestRules.golden_reward(150, "near", 10) == 7, "la mitad, redondeada hacia abajo")
	check(HarvestRules.golden_reward(150, "none", 10) == 0, "sin premio")
	check(HarvestRules.golden_reward(0, "gold", 10) == 0, "sin recolección no hay premio")
