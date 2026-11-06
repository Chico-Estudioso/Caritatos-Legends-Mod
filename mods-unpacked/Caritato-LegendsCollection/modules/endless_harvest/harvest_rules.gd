extends Reference

# Reglas de La Leyenda de la Cosecha Eterna sin dependencias del juego, para
# poder probarlas con Godot en modo headless (tests/gdscript/test_harvest_rules.gd).

const MODE_VANILLA := "vanilla"
const MODE_GROW := "grow"
const MODE_DECAY := "decay"


# Qué hacer con la recolección al final de una oleada:
#   vanilla: lo que haga el juego (también si el porcentaje coincide con el suyo).
#   grow: crecer como en las oleadas normales.
#   decay: perder decay_percent en lugar del porcentaje del juego.
static func endless_mode(active: bool, after_last_normal_wave: bool, grow: bool, decay_percent: int, vanilla_decay: int) -> String:
	if not active or not after_last_normal_wave:
		return MODE_VANILLA
	if grow:
		return MODE_GROW
	if decay_percent == vanilla_decay:
		return MODE_VANILLA
	return MODE_DECAY


# Recolección que se pierde, redondeada hacia arriba como en el juego.
static func decay_amount(stat: float, percent: int) -> int:
	if stat <= 0.0 or percent <= 0:
		return 0
	return int(ceil(stat * percent / 100.0))


# Interés de la Hucha al empezar una oleada (el juego trunca a entero).
static func piggy_bank_amount(gold: int, percent: float) -> int:
	if gold <= 0 or percent <= 0.0:
		return 0
	return int(gold * percent / 100.0)


# Quita de la lista de objetos vetados en el modo infinito los que se permiten.
# La lista del juego puede contener ids de texto o hashes.
static func filter_bans(bans: Array, allowed_ids: Array, allowed_hashes: Array) -> Array:
	var result := []
	for entry in bans:
		if allowed_ids.has(entry) or allowed_hashes.has(entry):
			continue
		result.append(entry)
	return result
