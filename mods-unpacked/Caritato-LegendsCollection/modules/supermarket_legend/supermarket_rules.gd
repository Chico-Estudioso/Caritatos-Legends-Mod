extends Reference

# Reglas de La Leyenda del Supermercado sin dependencias del juego, para
# poder probarlas con Godot en modo headless (tests/gdscript/test_supermarket_rules.gd).


static func can_order(orders_done: int, orders_per_shop: int) -> bool:
	return orders_done < orders_per_shop


# Coste del encargo: porcentaje del precio del artículo, redondeado hacia arriba.
static func order_fee(price: int, percent: int) -> int:
	if price <= 0 or percent <= 0:
		return 0
	return int(ceil(price * percent / 100.0))


# Hueco donde colocar el encargo: un hueco vacío si la tienda tiene menos de
# max_slots artículos (se añade al final) o el último artículo no bloqueado.
# locked: un booleano por artículo actual. Devuelve -1 si todo está bloqueado.
static func target_slot(locked: Array, max_slots: int) -> int:
	if locked.size() < max_slots:
		return locked.size()
	for index in range(locked.size() - 1, -1, -1):
		if not locked[index]:
			return index
	return -1


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
