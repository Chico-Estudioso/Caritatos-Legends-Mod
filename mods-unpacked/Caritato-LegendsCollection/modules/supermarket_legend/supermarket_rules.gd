extends Reference

# Reglas de La Leyenda del Supermercado sin dependencias del juego, para
# poder probarlas con Godot en modo headless (tests/gdscript/test_supermarket_rules.gd).

const MODE_BOSS := "boss"
const MODE_EVERY_SHOP := "every_shop"


# Encargos que quedan en el modo «al derrotar un élite o un jefe»: cada élite
# o jefe derrotado en la partida da per_kill encargos, que se guardan hasta
# gastarlos.
static func boss_credits(kills: int, per_kill: int, spent: int) -> int:
	return int(max(0, kills * int(max(0, per_kill)) - spent))


# Encargos que quedan en el modo «en cada tienda»: no se acumulan.
static func every_shop_left(per_shop: int, done: int) -> int:
	return int(max(0, per_shop - done))


# Estado guardado de la partida: {run, kills, spent: {jugador: gastados}}. Si
# es otra partida (otra huella, o menos bajas que las guardadas, que en una
# misma partida solo suben), los gastados empiezan de cero.
static func next_run_state(stored, fingerprint: String, kills: int) -> Dictionary:
	var same_run: bool = stored is Dictionary and str(stored.get("run", "")) == fingerprint and kills >= int(stored.get("kills", 0))
	var spent = stored.get("spent", {}) if same_run else {}
	if not spent is Dictionary:
		spent = {}
	return {"run": fingerprint, "kills": kills, "spent": spent}


# Recargo del encargo: porcentaje del precio del artículo, redondeado hacia arriba.
static func order_fee(price: int, percent: int) -> int:
	if price <= 0 or percent <= 0:
		return 0
	return int(ceil(price * percent / 100.0))


# Cada encargo viaja como artículo bloqueado: solo cabe si queda un hueco.
static func fits_next_shop(locked_count: int, max_slots: int) -> bool:
	return locked_count < max_slots


# Si al entrar en la tienda hay más bloqueados que huecos, se descartan
# primero los últimos que no son encargos (los encargos ya están pagados).
# is_order: un booleano por bloqueado. Devuelve los índices que se descartan.
static func overflow_to_drop(is_order: Array, max_slots: int) -> Array:
	var drop := []
	var excess := is_order.size() - max_slots
	for pass_orders in [false, true]:
		var index := is_order.size() - 1
		while excess > 0 and index >= 0:
			if bool(is_order[index]) == pass_orders and not drop.has(index):
				drop.append(index)
				excess -= 1
			index -= 1
	return drop


# Índices de las últimas apariciones de cada id de «wanted» (una por cada vez
# que aparece en «wanted»). Los encargos se añaden al final de la lista de
# bloqueados, así que son las últimas apariciones de su id.
static func last_occurrences(ids: Array, wanted: Array) -> Array:
	var remaining := wanted.duplicate()
	var found := []
	var index := ids.size() - 1
	while index >= 0 and not remaining.empty():
		if remaining.has(ids[index]):
			remaining.erase(ids[index])
			found.append(index)
		index -= 1
	found.sort()
	return found


# Quita de una lista de ids una aparición de cada id de «remove» (los
# encargos pendientes no deben aparecer al rerolear la tienda en la que se
# hicieron). Devuelve los índices que se conservan.
static func keep_without(ids: Array, remove: Array) -> Array:
	var remaining := remove.duplicate()
	var kept := []
	for index in ids.size():
		if remaining.has(ids[index]):
			remaining.erase(ids[index])
		else:
			kept.append(index)
	return kept


# Orden del catálogo: por tier y después por nombre visible.
static func sort_entries(entries: Array) -> Array:
	var sorted := entries.duplicate()
	sorted.sort_custom(EntrySorter, "before")
	return sorted


class EntrySorter:
	static func before(a: Dictionary, b: Dictionary) -> bool:
		if a.tier != b.tier:
			return a.tier < b.tier
		return a.label.nocasecmp_to(b.label) < 0
