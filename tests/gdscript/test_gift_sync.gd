extends "res://tests/gdscript/base_test.gd"

# La tienda tras un regalo (gift_shop_sync.gd) y la búsqueda de lo que se
# regala en RunData (Compat.owned_index), con nodos de mentira que imitan los
# del juego.

var Sync = load(MOD_PATH + "modules/gift_legend/gift_shop_sync.gd")
var Compat = load(MOD_PATH + "core/compat.gd")


func _init() -> void:
	run_case("el foco sobre los inventarios pasa al reroll", "test_release_focus")
	run_case("la casilla de lo que se regala", "test_find_element")
	run_case("se quita una casilla y se añade otra", "test_move_element")
	run_case("lo que se regala se encuentra aunque sea una copia", "test_owned_index")
	finish()


func _script(source: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = source
	var _err = script.reload()
	return script


func _item(id: String, cursed: bool = false):
	var item = _script("extends Resource\nvar my_id := \"\"\nvar is_cursed := false\n").new()
	item.my_id = id
	item.is_cursed = cursed
	return item


func _element(item) -> Node:
	var element: Node = _script("extends Control\nvar item = null\n").new()
	element.item = item
	return element


func _inventory() -> Node:
	return _script("""extends Control
var calls := []
func remove_element(element, nb_to_remove = 1, deep_comparison = false):
	calls.append(["remove", element, nb_to_remove, deep_comparison])
func add_element(element, check_for_duplicates = false):
	calls.append(["add", element, check_for_duplicates])
""").new()


func _emulator(control) -> Node:
	var emulator: Node = _script("extends Node2D\nvar focused_control = null\n").new()
	emulator.focused_control = control
	return emulator


func test_release_focus() -> void:
	var gear_giver := Control.new()
	var gear_recipient := Control.new()
	var other_gear := Control.new()
	var giver_element := _element(_item("item_a"))
	gear_giver.add_child(giver_element)
	var recipient_element := _element(_item("item_b"))
	gear_recipient.add_child(recipient_element)
	var outside := _element(_item("item_c"))
	other_gear.add_child(outside)
	var rerolls := [Button.new(), Button.new(), Button.new(), Button.new()]

	var emulators := [_emulator(giver_element), _emulator(recipient_element), _emulator(outside), _emulator(null)]
	var moved: int = Sync.release_focus(emulators, [gear_giver, gear_recipient], rerolls)
	check(moved == 2, "deberían moverse dos focos (%d)" % moved)
	check(emulators[0].focused_control == rerolls[0], "quien regala debería pasar a su reroll")
	check(emulators[1].focused_control == rerolls[1], "quien recibe también, aunque no haya pulsado nada")
	check(emulators[2].focused_control == outside, "el foco de otro jugador no se toca")
	check(emulators[3].focused_control == null, "sin foco sigue sin foco")

	# Sin reroll al que ir, el foco se queda vacío en lugar de en una casilla.
	var lonely := _emulator(giver_element)
	moved = Sync.release_focus([lonely], [gear_giver], [])
	check(moved == 1 and lonely.focused_control == null, "sin reroll el foco debería quedar vacío")

	# Un emulador que ya no existe o un foco ya destruido no rompen nada.
	var gone := _element(_item("item_d"))
	gear_giver.add_child(gone)
	var stale := _emulator(gone)
	gone.free()
	var dead := _emulator(null)
	dead.free()
	moved = Sync.release_focus([stale, dead, null], [gear_giver], rerolls)
	check(moved == 0, "nada que mover si el control ya no existe (%d)" % moved)

	for node in [gear_giver, gear_recipient, other_gear, lonely, stale] + emulators + rerolls:
		node.free()


func test_find_element() -> void:
	var inventory := _inventory()
	var cursed_a = _item("item_a", true)
	var plain_a = _item("item_a")
	var other_copy = _item("item_a")
	var cursed_element := _element(cursed_a)
	var plain_element := _element(plain_a)
	inventory.add_child(cursed_element)
	inventory.add_child(plain_element)
	inventory.add_child(_element(null))

	check(Sync.find_element(inventory, plain_a, true) == plain_element, "debería encontrar la casilla del mismo objeto")
	check(Sync.find_element(inventory, cursed_a, true) == cursed_element, "la maldita es la suya")
	check(Sync.find_element(inventory, other_copy, true) == plain_element, "una copia va a la casilla sin maldición del mismo id")
	check(Sync.find_element(inventory, other_copy, false) == null, "las armas solo valen si es el mismo objeto")
	check(Sync.find_element(inventory, _item("item_a", true), true) == null, "una maldita distinta no comparte casilla")
	check(Sync.find_element(inventory, _item("item_z"), true) == null, "otro id no está")

	plain_element.queue_free()
	check(Sync.find_element(inventory, plain_a, true) == null, "no cuenta una casilla que se va a destruir")
	inventory.free()


func test_move_element() -> void:
	var from := _inventory()
	var to := _inventory()
	var shown = _item("item_a")
	from.add_child(_element(shown))
	var received = _item("item_a")

	check(Sync.move_element(from, to, shown, received, false), "debería pasar el objeto")
	check(from.calls == [["remove", shown, 1, true]], "a quien regala se le quita una (%s)" % str(from.calls))
	check(to.calls == [["add", received, true]], "a quien recibe se le suma a su casilla (%s)" % str(to.calls))

	from.calls.clear()
	to.calls.clear()
	var weapon = _item("weapon_knife_1")
	from.add_child(_element(weapon))
	var received_weapon = _item("weapon_knife_1")
	check(Sync.move_element(from, to, weapon, received_weapon, true), "debería pasar el arma")
	check(to.calls == [["add", received_weapon, false]], "las armas no se agrupan (%s)" % str(to.calls))

	from.calls.clear()
	check(not Sync.move_element(from, to, _item("weapon_other"), received_weapon, true), "sin casilla hay que rehacer")
	check(from.calls.empty(), "si falla no debería tocar nada")
	check(not Sync.move_element(from, to, weapon, null, true), "sin lo recibido hay que rehacer")
	check(not Sync.move_element(null, to, weapon, received_weapon, true), "sin inventario hay que rehacer")
	from.free()
	to.free()


func test_owned_index() -> void:
	var a = _item("item_a")
	var cursed_a = _item("item_a", true)
	var b = _item("item_b")
	var list := [b, cursed_a, a]
	check(Compat.owned_index(list, a) == 2, "el mismo objeto")
	check(Compat.owned_index(list, _item("item_a")) == 2, "una copia: mismo id sin maldición")
	check(Compat.owned_index(list, _item("item_a", true)) == 1, "una copia maldita va con la maldita")
	check(Compat.owned_index(list, _item("item_c")) == -1, "otro id no está")
	check(Compat.owned_index(list, null) == -1, "nada no está")
	check(Compat.owned_index(list, _item("item_a"), funcref(self, "_never_same")) == -1, "si el juego dice que no son iguales, no está")
	check(Compat.owned_index(list, _item("item_a"), funcref(self, "_always_same")) == 2, "si el juego dice que son iguales, sí")


func _never_same(_a, _b) -> bool:
	return false


func _always_same(_a, _b) -> bool:
	return true
