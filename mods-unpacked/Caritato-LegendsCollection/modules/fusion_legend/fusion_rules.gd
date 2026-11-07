extends Reference

# Reglas de La Leyenda de la Fusión, sin depender del juego.

# [efecto del juego, ajuste del módulo, signo]: la experiencia baja; precios,
# enemigos y velocidad de los enemigos suben.
const PENALTIES := [
	["xp_gain", "penalty_xp", -1],
	["items_price", "penalty_price", 1],
	["number_of_enemies", "penalty_enemies", 1],
	["enemy_speed", "penalty_speed", 1],
]


# [[efecto, valor], …] a partir de los ajustes {penalty_xp: 10, …}; sin ceros.
static func penalty_values(settings: Dictionary) -> Array:
	var result := []
	for penalty in PENALTIES:
		var amount: int = int(abs(int(settings.get(penalty[1], 0))))
		if amount != 0:
			result.append([penalty[0], amount * int(penalty[2])])
	return result


# Compañeros posibles: todos menos el personaje actual y, si se pide, solo los
# desbloqueados. entries: [{id, unlocked}], devuelve sus posiciones.
static func partner_indices(entries: Array, current_id: String, allow_locked: bool) -> Array:
	var result := []
	for index in entries.size():
		var entry: Dictionary = entries[index]
		if str(entry.get("id", "")) == current_id:
			continue
		if not allow_locked and not bool(entry.get("unlocked", true)):
			continue
		result.append(index)
	return result


# Movimiento por una cuadrícula de «columns» columnas sin salirse.
static func grid_move(index: int, total: int, columns: int, dx: int, dy: int) -> int:
	if total <= 0:
		return 0
	var cols: int = int(max(1, columns))
	var target: int = index + dx + dy * cols
	if dy != 0 and (target < 0 or target >= total):
		return index
	return int(clamp(target, 0, total - 1))
