extends Reference

# Reglas de La Leyenda de las Cajas, sin depender del juego para poder
# probarlas: cuántas cajas pide cada fusión y cuáles se fusionan.


# Cajas que pide la siguiente fusión: la primera pide «first» y cada fusión
# hecha suma «step», sin pasar de «max_cost» (si es mayor o igual que first).
static func fusion_cost(first: int, step: int, max_cost: int, fusions_done: int) -> int:
	var cost: int = first + step * int(max(0, fusions_done))
	if max_cost >= first:
		cost = int(min(cost, max_cost))
	return int(max(1, cost))


static func can_fuse(crates: int, cost: int) -> bool:
	return cost > 0 and crates >= cost


# Posiciones (de la última a la primera) de las cajas normales que se fusionan.
# Se toman las últimas para no mover las que ya estaban en la lista. Si no hay
# bastantes, devuelve una lista vacía.
static func pick_crates(hashes: Array, crate_hash: int, cost: int) -> Array:
	var picked := []
	var index: int = hashes.size() - 1
	while index >= 0 and picked.size() < cost:
		if int(hashes[index]) == crate_hash:
			picked.append(index)
		index -= 1
	if picked.size() < cost:
		return []
	return picked
