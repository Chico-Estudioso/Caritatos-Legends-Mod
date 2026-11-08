extends Reference

# Cómo se actualiza la tienda cooperativa tras un regalo sin dejar referencias
# a casillas del inventario destruidas.
#
# En cooperativo, cada jugador mueve el foco con su «FocusEmulator», que
# guarda el control enfocado y lo vuelve a dibujar cada vez que alguien cambia
# de foco. Si esa casilla se destruye con el foco encima, el juego se cierra
# de golpe al dibujarla (en la versión publicada no se comprueba si sigue
# existiendo). Por eso, tras un regalo:
#   1. el foco que estuviera sobre los inventarios implicados pasa al botón de
#      reroll de ese jugador, antes de tocar nada;
#   2. se quita una casilla a quien regala y se añade una a quien recibe, igual
#      que hace el juego al reciclar o comprar, en lugar de rehacer los
#      inventarios enteros.
#
# Todo funciona con nodos cualesquiera que tengan los mismos nombres que los
# del juego, para poder probarlo sin Brotato.


# Mueve al control de `fallbacks` (mismo índice) el foco de cada emulador que
# esté dentro de alguno de `containers`. Si no hay control al que moverlo, lo
# deja sin foco. Devuelve cuántos ha movido.
static func release_focus(emulators: Array, containers: Array, fallbacks: Array) -> int:
	var moved := 0
	for index in emulators.size():
		var emulator = emulators[index]
		if not is_instance_valid(emulator) or not "focused_control" in emulator:
			continue
		var control = emulator.focused_control
		if not is_instance_valid(control) or not is_inside_any(control, containers):
			continue
		var fallback = fallbacks[index] if index < fallbacks.size() else null
		emulator.focused_control = fallback if is_instance_valid(fallback) else null
		moved += 1
	return moved


static func is_inside_any(control: Node, containers: Array) -> bool:
	for container in containers:
		if is_instance_valid(container) and (container == control or container.is_a_parent_of(control)):
			return true
	return false


# Inventario (nodo «Inventory») de un contenedor de equipo del juego:
# key es "weapons_container" o "items_container".
static func inventory_of(gear, key: String):
	if not is_instance_valid(gear):
		return null
	var container = gear.get(key)
	if not is_instance_valid(container):
		return null
	var inventory = container.get("_elements")
	return inventory if is_instance_valid(inventory) else null


# Casilla de `inventory` que muestra `data`: la de ese mismo objeto o, si se
# permite, la primera del mismo id que no esté maldita (el juego agrupa los
# objetos repetidos en una casilla con un contador y deja aparte los
# malditos). No cuenta las casillas que ya se van a destruir.
static func find_element(inventory: Node, data, allow_same_id: bool) -> Node:
	if not is_instance_valid(inventory) or data == null:
		return null
	var same_id: Node = null
	var data_cursed := _flag(data, "is_cursed")
	for child in inventory.get_children():
		if child.is_queued_for_deletion() or not "item" in child or child.item == null:
			continue
		if child.item == data:
			return child
		if allow_same_id and same_id == null and not data_cursed and not _flag(child.item, "is_cursed") \
				and "my_id" in child.item and "my_id" in data and child.item.my_id == data.my_id:
			same_id = child
	return same_id


# Pasa la casilla de un inventario a otro: `data` es lo que mostraba la casilla
# de quien regala y `received`, lo que ahora tiene quien recibe. Devuelve
# false si no ha podido hacerlo (y entonces hay que rehacer los inventarios).
static func move_element(from_inventory: Node, to_inventory: Node, data, received, is_weapon: bool) -> bool:
	if not is_instance_valid(from_inventory) or not is_instance_valid(to_inventory) or received == null:
		return false
	if not from_inventory.has_method("remove_element") or not to_inventory.has_method("add_element"):
		return false
	var element := find_element(from_inventory, data, not is_weapon)
	if element == null:
		return false
	# Igual que el juego al reciclar: comparación exacta con lo que muestra la
	# casilla (si hay varios, solo baja el contador).
	from_inventory.remove_element(element.item, 1, true)
	# Igual que el juego al comprar: los objetos repetidos se suman a su casilla.
	if is_weapon:
		to_inventory.add_element(received)
	else:
		to_inventory.add_element(received, true)
	return true


static func _flag(item, flag: String) -> bool:
	return item != null and flag in item and bool(item.get(flag))
