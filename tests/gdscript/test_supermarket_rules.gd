extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda del Supermercado.

var SupermarketRules = load(MOD_PATH + "modules/supermarket_legend/supermarket_rules.gd")


func _init() -> void:
	run_case("encargos ganados menos gastados", "test_credits")
	run_case("encargos en cada tienda", "test_every_shop_left")
	run_case("misma partida o partida nueva", "test_is_same_run")
	run_case("un encargo por oleada con élite o jefe", "test_next_run_state")
	run_case("encargos apartados al rerolear", "test_last_occurrences")
	run_case("recargo del encargo", "test_order_fee")
	run_case("hueco en la siguiente tienda", "test_fits_next_shop")
	run_case("bloqueados de más al entrar", "test_overflow_to_drop")
	run_case("encargos fuera del reroll", "test_keep_without")
	run_case("orden del catálogo", "test_sort")
	finish()


func test_credits() -> void:
	check(SupermarketRules.credits(0, 0) == 0, "sin ganados no hay encargos")
	check(SupermarketRules.credits(2, 1) == 1, "los no gastados se guardan")
	check(SupermarketRules.credits(1, 5) == 0, "nunca negativo")


func test_every_shop_left() -> void:
	check(SupermarketRules.every_shop_left(1, 0) == 1, "uno por tienda")
	check(SupermarketRules.every_shop_left(1, 1) == 0, "gastado en esta tienda")
	check(SupermarketRules.every_shop_left(2, 3) == 0, "nunca negativo")


func test_is_same_run() -> void:
	var stored := {"run": "abc", "kills": 2, "wave": 12, "earned": 1, "spent": {"0": 1}}
	check(SupermarketRules.is_same_run(stored, "abc", 2, 12), "la misma tienda otra vez")
	check(SupermarketRules.is_same_run(stored, "abc", 3, 13), "la tienda siguiente")
	check(not SupermarketRules.is_same_run(stored, "xyz", 3, 13), "otros personajes o dificultad")
	check(not SupermarketRules.is_same_run(stored, "abc", 0, 5), "menos bajas: otra partida")
	check(not SupermarketRules.is_same_run(stored, "abc", 2, 1), "vuelta a la oleada 1: otra partida")
	check(not SupermarketRules.is_same_run(null, "abc", 0, 1), "sin estado guardado")


func test_next_run_state() -> void:
	var stored := {"run": "abc", "kills": 2, "wave": 12, "earned": 1, "spent": {"0": 1}}
	var same: Dictionary = SupermarketRules.next_run_state(stored, "abc", 2, 13, 1)
	check(same.earned == 1 and same.spent.get("0") == 1, "sin bajas nuevas no se gana nada y se conserva lo gastado")
	var one: Dictionary = SupermarketRules.next_run_state(stored, "abc", 3, 13, 1)
	check(one.earned == 2 and one.kills == 3 and one.wave == 13, "un élite derrotado: un encargo más")
	var two: Dictionary = SupermarketRules.next_run_state(stored, "abc", 4, 13, 1)
	check(two.earned == 2, "dos jefes en la misma oleada: un solo encargo")
	var more: Dictionary = SupermarketRules.next_run_state(stored, "abc", 3, 13, 2)
	check(more.earned == 3, "con 2 encargos por oleada, dos más")
	var other: Dictionary = SupermarketRules.next_run_state(stored, "abc", 0, 1, 1)
	check(other.earned == 0 and other.spent.empty(), "otra partida empieza de cero")
	var broken: Dictionary = SupermarketRules.next_run_state({"run": "abc", "kills": 0, "wave": 2, "spent": "roto"}, "abc", 0, 3, 1)
	check(broken.spent.empty() and broken.earned == 0, "un estado roto no rompe nada")


func test_last_occurrences() -> void:
	check(SupermarketRules.last_occurrences(["a", "b", "a"], ["a"]) == [2], "la última aparición")
	check(SupermarketRules.last_occurrences(["a", "b", "a", "c"], ["a", "c"]) == [2, 3], "una por encargo")
	check(SupermarketRules.last_occurrences(["a", "a"], ["a", "a"]) == [0, 1], "dos encargos iguales")
	check(SupermarketRules.last_occurrences(["a"], ["z"]).empty(), "lo que no está no se aparta")


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
