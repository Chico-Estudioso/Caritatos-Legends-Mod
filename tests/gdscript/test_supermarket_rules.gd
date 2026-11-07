extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda del Supermercado.

var SupermarketRules = load(MOD_PATH + "modules/supermarket_legend/supermarket_rules.gd")


func _init() -> void:
	run_case("encargos por tienda según el modo", "test_orders_for_shop")
	run_case("élite o jefe derrotado", "test_unlocked_by_kills")
	run_case("límite de encargos", "test_can_order")
	run_case("recargo del encargo", "test_order_fee")
	run_case("hueco en la siguiente tienda", "test_fits_next_shop")
	run_case("bloqueados de más al entrar", "test_overflow_to_drop")
	run_case("encargos fuera del reroll", "test_keep_without")
	run_case("orden del catálogo", "test_sort")
	finish()


func test_orders_for_shop() -> void:
	check(SupermarketRules.orders_for_shop("boss", 1, false) == 0, "sin élite ni jefe no hay encargos")
	check(SupermarketRules.orders_for_shop("boss", 2, true) == 2, "tras un élite o jefe, los encargos configurados")
	check(SupermarketRules.orders_for_shop("every_shop", 1, false) == 1, "en cada tienda no hace falta derrotar a nadie")


func test_unlocked_by_kills() -> void:
	check(SupermarketRules.unlocked_by_kills(12, 1, 12, 2, false), "una baja más que al salir de la tienda anterior")
	check(not SupermarketRules.unlocked_by_kills(12, 2, 12, 2, true), "con foto, una oleada de élite sin baja no cuenta")
	check(SupermarketRules.unlocked_by_kills(-1, -1, 12, 0, true), "sin foto, basta con que fuera oleada de élite")
	check(not SupermarketRules.unlocked_by_kills(11, 0, 12, 5, false), "una foto de otra oleada no sirve")


func test_can_order() -> void:
	check(SupermarketRules.can_order(0, 1), "el primer encargo se permite")
	check(not SupermarketRules.can_order(1, 1), "no se supera el límite")
	check(not SupermarketRules.can_order(0, 0), "sin encargos disponibles")


func test_order_fee() -> void:
	check(SupermarketRules.order_fee(40, 0) == 0, "0 % no tiene recargo")
	check(SupermarketRules.order_fee(40, 50) == 20, "50 % de 40")
	check(SupermarketRules.order_fee(7, 10) == 1, "se redondea hacia arriba")
	check(SupermarketRules.order_fee(0, 50) == 0, "un artículo gratis no tiene recargo")


func test_fits_next_shop() -> void:
	check(SupermarketRules.fits_next_shop(0, 4), "sin bloqueados cabe")
	check(SupermarketRules.fits_next_shop(3, 4), "con 3 bloqueados cabe")
	check(not SupermarketRules.fits_next_shop(4, 4), "con 4 bloqueados no cabe")


func test_overflow_to_drop() -> void:
	check(SupermarketRules.overflow_to_drop([false, true, false], 4).empty(), "si cabe, no se descarta nada")
	var drop: Array = SupermarketRules.overflow_to_drop([false, true, false, false, false], 4)
	check(drop == [4], "se descarta el último que no es encargo")
	drop = SupermarketRules.overflow_to_drop([false, false, false, false, true, true], 4)
	check(drop.size() == 2 and drop.has(3) and drop.has(2), "los encargos se conservan")
	drop = SupermarketRules.overflow_to_drop([true, true, true, true, true], 4)
	check(drop == [4], "si todo son encargos, el último")


func test_keep_without() -> void:
	var kept: Array = SupermarketRules.keep_without(["a", "b", "a", "c"], ["a"])
	check(kept == [1, 2, 3], "quita una sola aparición")
	kept = SupermarketRules.keep_without(["a", "b"], [])
	check(kept == [0, 1], "sin encargos no cambia nada")


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
