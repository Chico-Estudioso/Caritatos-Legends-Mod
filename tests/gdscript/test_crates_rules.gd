extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda de las Cajas y la fusión sobre listas de prueba.

const CRATE := 11
const LEGENDARY := 22
const FRUIT := 33

var CratesRules = load(MOD_PATH + "modules/crates_legend/crates_rules.gd")
var CratesLegend = load(MOD_PATH + "modules/crates_legend/crates_legend.gd")


class FakeData:
	var my_id_hash := 0
	func _init(p_hash: int) -> void:
		my_id_hash = p_hash


class FakeEntry:
	var consumable_data = null
	var player_index := 0


class FakeContainer:
	var elements := []
	func add_element(data) -> void:
		elements.append(data)
	func remove_element(data) -> void:
		elements.erase(data)


func _init() -> void:
	run_case("cajas que pide cada fusión", "test_cost")
	run_case("se fusiona solo con cajas suficientes", "test_can_fuse")
	run_case("se eligen las últimas cajas normales", "test_pick")
	run_case("la fusión cambia cajas por una legendaria", "test_fuse")
	finish()


func test_cost() -> void:
	check(CratesRules.fusion_cost(3, 3, 9, 0) == 3, "la primera pide 3")
	check(CratesRules.fusion_cost(3, 3, 9, 1) == 6, "la segunda pide 6")
	check(CratesRules.fusion_cost(3, 3, 9, 2) == 9, "la tercera pide 9")
	check(CratesRules.fusion_cost(3, 3, 9, 5) == 9, "no pasa del máximo")
	check(CratesRules.fusion_cost(4, 0, 9, 3) == 4, "sin aumento todas piden lo mismo")
	check(CratesRules.fusion_cost(5, 2, 3, 1) == 7, "un máximo menor que la primera se ignora")


func test_can_fuse() -> void:
	check(CratesRules.can_fuse(3, 3), "con justo las cajas necesarias")
	check(not CratesRules.can_fuse(2, 3), "sin cajas suficientes")
	check(not CratesRules.can_fuse(5, 0), "una fusión gratis no tiene sentido")


func test_pick() -> void:
	var hashes := [CRATE, FRUIT, CRATE, LEGENDARY, CRATE, CRATE]
	check(CratesRules.pick_crates(hashes, CRATE, 3) == [5, 4, 2], "se toman las tres últimas cajas normales")
	check(CratesRules.pick_crates(hashes, CRATE, 5).empty(), "sin bastantes cajas no se toma ninguna")


func test_fuse() -> void:
	var to_process := []
	var ui := FakeContainer.new()
	for hash_value in [CRATE, FRUIT, CRATE, CRATE, CRATE]:
		var entry := FakeEntry.new()
		entry.consumable_data = FakeData.new(hash_value)
		to_process.append(entry)
		ui.add_element(entry.consumable_data)
	check(CratesLegend.count_crates(to_process, CRATE) == 4, "hay cuatro cajas normales")
	var legendary := FakeData.new(LEGENDARY)
	check(CratesLegend.fuse_crates(to_process, ui, 1, 3, CRATE, legendary), "debería fusionar")
	check(CratesLegend.count_crates(to_process, CRATE) == 1, "queda una caja normal")
	check(to_process.size() == 3, "quedan la caja, la fruta y la legendaria")
	var last = to_process[to_process.size() - 1]
	check(last.consumable_data == legendary and last.player_index == 1, "la legendaria es del jugador")
	check(ui.elements.size() == 3 and ui.elements.has(legendary), "la interfaz cuenta lo mismo")
	check(not CratesLegend.fuse_crates(to_process, ui, 1, 3, CRATE, legendary), "sin cajas suficientes no cambia nada")
	check(to_process.size() == 3, "la lista sigue igual")
