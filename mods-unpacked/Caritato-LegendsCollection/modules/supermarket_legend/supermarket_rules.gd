extends Reference

# Reglas de La Leyenda del Supermercado sin dependencias del juego, para
# poder probarlas con Godot en modo headless (tests/gdscript/test_supermarket_rules.gd).

const MODE_BOSS := "boss"
const MODE_EVERY_SHOP := "every_shop"


# Encargos que se pueden hacer en una tienda. En el modo «boss» solo hay
# encargos en la tienda que sigue a una oleada en la que se derrotó a un élite
# o a un jefe; en «every_shop», en todas.
static func orders_for_shop(mode: String, per_unlock: int, unlocked: bool) -> int:
	if mode == MODE_EVERY_SHOP or unlocked:
		return int(max(0, per_unlock))
	return 0


# ¿Se derrotó a un élite o a un jefe en la oleada que acaba de terminar?
# Con la foto de bajas tomada al salir de la tienda anterior basta comparar.
# Sin foto (por ejemplo, al continuar una partida guardada) se acepta si la
# oleada era de élite o de jefe.
static func unlocked_by_kills(snapshot_wave: int, snapshot_kills: int, wave: int, kills_now: int, special_wave: bool) -> bool:
	if snapshot_wave == wave and snapshot_kills >= 0:
		return kills_now > snapshot_kills
	return special_wave


static func can_order(orders_done: int, orders_allowed: int) -> bool:
	return orders_done < orders_allowed


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
