extends Reference

# Reglas de La Leyenda del Ratón, sin depender del juego (se prueban aparte).

# Dónde está el cursor respecto a los paneles de los jugadores.
const ZONE_FREE := 0   # fuera de los paneles de los jugadores
const ZONE_OWN := 1    # en el panel de quien usa el ratón
const ZONE_OTHER := 2  # solo en el panel de otro jugador


# Quién usa el ratón: el primer jugador que no juega con mando. Si todos usan
# mando, el J1.
static func mouse_player(uses_gamepad: Array) -> int:
	for index in uses_gamepad.size():
		if not uses_gamepad[index]:
			return index
	return 0


# zones: [{player, rect}] con los paneles visibles de cada jugador.
static func zone_at(point: Vector2, zones: Array, player: int) -> int:
	var own := false
	var other := false
	for zone in zones:
		if not zone.rect.has_point(point):
			continue
		if int(zone.player) == player:
			own = true
		else:
			other = true
	if own:
		return ZONE_OWN
	return ZONE_OTHER if other else ZONE_FREE


# ¿Llega el evento del ratón a la interfaz? Sobre el panel de otro jugador no
# se puede pulsar, usar la rueda ni resaltar nada. Al soltar el botón siempre
# llega, para que un botón pulsado dentro no se quede trabado.
static func lets_through(zone: int, is_release: bool) -> bool:
	return zone != ZONE_OTHER or is_release


# ¿Se ha usado el ratón hace poco? hide_after en segundos; 0 = no se oculta.
static func is_recent(now_ms: int, last_mouse_ms: int, hide_after: int) -> bool:
	if last_mouse_ms < 0:
		return false
	return hide_after <= 0 or now_ms - last_mouse_ms <= hide_after * 1000


# A quién se atribuye un control pulsado con el ratón. owners son los
# jugadores en cuyo panel está. Si está en el de quien usa el ratón, o fuera
# de todos, es suyo; si solo está en el de otros, no se atribuye (-1).
static func claim(owners: Array, player: int) -> int:
	if owners.empty() or owners.has(player):
		return player
	return -1
