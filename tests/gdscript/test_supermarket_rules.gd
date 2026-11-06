extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda del Supermercado.

var SupermarketRules = load(MOD_PATH + "modules/supermarket_legend/supermarket_rules.gd")


func _init() -> void:
	run_case("límite de encargos por tienda", "test_can_order")
	run_case("coste del encargo", "test_order_fee")
	run_case("hueco para el encargo", "test_target_slot")
	run_case("orden del catálogo", "test_sort")
	finish()


func test_can_order() -> void:
	check(SupermarketRules.can_order(0, 1), "el primer encargo se permite")
	check(not SupermarketRules.can_order(1, 1), "no se supera el límite")
	check(SupermarketRules.can_order(2, 3), "quedan encargos")


func test_order_fee() -> void:
	check(SupermarketRules.order_fee(40, 0) == 0, "0 % es gratis")
	check(SupermarketRules.order_fee(40, 25) == 10, "25 % de 40")
	check(SupermarketRules.order_fee(7, 10) == 1, "se redondea hacia arriba")
	check(SupermarketRules.order_fee(0, 50) == 0, "un artículo gratis no tiene coste")


func test_target_slot() -> void:
	check(SupermarketRules.target_slot([false, true], 4) == 2, "con huecos vacíos se añade al final")
	check(SupermarketRules.target_slot([false, false, true, false], 4) == 3, "sin huecos, el último no bloqueado")
	check(SupermarketRules.target_slot([false, true, true, true], 4) == 0, "salta los bloqueados")
	check(SupermarketRules.target_slot([true, true, true, true], 4) == -1, "todo bloqueado")
	check(SupermarketRules.target_slot([], 4) == 0, "tienda vacía")


func test_sort() -> void:
	var entries := [
		{"label": "Zapato", "tier": 1},
		{"label": "árbol", "tier": 0},
		{"label": "Ancla", "tier": 1},
		{"label": "Bota", "tier": 0},
	]
	var sorted: Array = SupermarketRules.sort_entries(entries)
	check(sorted[0].tier == 0 and sorted[2].tier == 1, "primero por tier")
	check(sorted[2].label == "Ancla" and sorted[3].label == "Zapato", "después por nombre")
	check(entries[0].label == "Zapato", "no modifica la lista original")
