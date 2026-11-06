extends Reference

# Reglas de La Leyenda del Anzuelo sin dependencias del juego, para poder
# probarlas con Godot en modo headless (tests/gdscript/test_hook_rules.gd).

const KIND_ITEM := "item"
const KIND_WEAPON := "weapon"


# ¿Hay que garantizar el Anzuelo en esta tienda?
#   wave: oleada recién terminada (RunData.current_wave en la tienda).
#   max_owned: máximo de anzuelos por jugador (-1 = sin límite).
static func should_guarantee(wave: int, target_wave: int, until_owned: bool, owned: int, max_owned: int, banned: bool) -> bool:
	if banned:
		return false
	if wave < target_wave:
		return false
	if wave > target_wave and (not until_owned or owned > 0):
		return false
	if max_owned != -1 and owned >= max_owned:
		return false
	return true


# Elige el hueco que se sustituye. kinds: tipo de cada artículo de la tienda
# (KIND_ITEM, KIND_WEAPON o "" si está vacío); los primeros locked_count son
# artículos bloqueados y nunca se tocan. Prefiere el último objeto; solo cambia
# un arma si no queda ningún objeto. Devuelve -1 si no hay hueco.
static func pick_slot(kinds: Array, locked_count: int) -> int:
	var fallback := -1
	for index in range(kinds.size() - 1, int(max(locked_count, 0)) - 1, -1):
		var kind = kinds[index]
		if kind == KIND_ITEM:
			return index
		if kind == KIND_WEAPON and fallback == -1:
			fallback = index
	return fallback
