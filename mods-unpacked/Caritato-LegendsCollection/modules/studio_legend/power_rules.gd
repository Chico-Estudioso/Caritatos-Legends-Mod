extends Reference

# Medidor de poder: una estimación sencilla de lo fuerte que es un personaje u
# objeto, para avisar de creaciones demasiado fuertes. No sustituye a jugar,
# pero ordena bien: suma los efectos con un peso por estadística y compara el
# resultado con los del juego.

# Signos de Brotato (effects/enums/sign.gd).
const SIGN_POSITIVE := 0
const SIGN_NEGATIVE := 1
const SIGN_NEUTRAL := 2

# Puntos por unidad. Para lo demás se usa DEFAULT_WEIGHT con un tope.
const WEIGHTS := {
	"stat_max_hp": 1.0,
	"stat_hp_regeneration": 1.5,
	"stat_lifesteal": 2.0,
	"stat_percent_damage": 0.8,
	"stat_melee_damage": 1.4,
	"stat_ranged_damage": 1.4,
	"stat_elemental_damage": 1.4,
	"stat_engineering": 1.4,
	"stat_attack_speed": 1.0,
	"stat_crit_chance": 0.9,
	"stat_range": 0.06,
	"stat_armor": 2.5,
	"stat_dodge": 1.2,
	"stat_speed": 0.9,
	"stat_luck": 0.8,
	"stat_harvesting": 0.7,
	"xp_gain": 0.25,
	"items_price": 0.4,
	"number_of_enemies": 0.15,
	"enemy_speed": 0.3,
	"weapon_slot": 6.0,
}
const DEFAULT_WEIGHT := 0.3
const UNKNOWN_CAP := 25

const RATING_BALANCED := 0
const RATING_STRONG := 1
const RATING_VERY_STRONG := 2
const RATING_BROKEN := 3


# +1 si el efecto ayuda, -1 si perjudica, 0 si es neutro (como el color que
# le da el juego en la descripción).
static func goodness(sign_value: int, value: int) -> int:
	if sign_value == SIGN_POSITIVE:
		return 1
	if sign_value == SIGN_NEGATIVE:
		return -1
	if sign_value == SIGN_NEUTRAL:
		return 0
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


static func effect_score(key: String, value: int, sign_value: int) -> float:
	var good := goodness(sign_value, value)
	if good == 0:
		return 0.0
	var magnitude: float = abs(value)
	var weight: float = DEFAULT_WEIGHT
	if WEIGHTS.has(key):
		weight = WEIGHTS[key]
	else:
		magnitude = min(magnitude, UNKNOWN_CAP)
	return good * magnitude * weight


# effects: [[clave, valor, signo]]
static func total(effects: Array) -> float:
	var score := 0.0
	for effect in effects:
		score += effect_score(str(effect[0]), int(effect[1]), int(effect[2]))
	return score


# Dónde cae una puntuación respecto a las de referencia (las del juego):
# hasta el percentil 75, equilibrado; hasta la más alta, fuerte; hasta un 50 %
# más, muy fuerte; por encima, roto.
static func rating(score: float, baseline: Array) -> int:
	if baseline.empty():
		return RATING_BALANCED
	var sorted := baseline.duplicate()
	sorted.sort()
	var p75: float = float(sorted[int(floor((sorted.size() - 1) * 0.75))])
	var top: float = float(sorted[sorted.size() - 1])
	if score <= p75:
		return RATING_BALANCED
	if score <= top:
		return RATING_STRONG
	if top > 0.0 and score <= top * 1.5:
		return RATING_VERY_STRONG
	return RATING_BROKEN


# Ancho relativo de la barra (0..1) respecto a la mayor puntuación.
static func bar_fraction(score: float, highest: float) -> float:
	if highest <= 0.0:
		return 0.0
	return clamp(score / highest, 0.0, 1.0)
