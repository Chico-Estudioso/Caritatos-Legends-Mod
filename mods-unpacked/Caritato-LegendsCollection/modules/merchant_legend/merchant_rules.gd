extends Reference

# Reglas de La Leyenda del Mercader sin dependencias del juego, para poder
# probarlas con Godot en modo headless (tests/gdscript/test_merchant_rules.gd).


# Oleada con la que se calcula un precio: la 1 si los precios no deben subir
# con las oleadas, o la real en caso contrario.
static func price_wave(wave: int, fixed_prices: bool) -> int:
	if fixed_prices and wave > 1:
		return 1
	return wave


# Precio de un artículo con el porcentaje configurado (nunca menos de 1).
static func scale_item_price(value: int, percent: int) -> int:
	if percent == 100:
		return value
	return int(max(1, round(value * percent / 100.0)))


# Precio de un reroll con el porcentaje configurado (0 % = gratis).
static func scale_reroll_price(price: int, percent: int) -> int:
	if percent == 100:
		return price
	if percent <= 0 or price <= 0:
		return 0
	return int(max(1, ceil(price * percent / 100.0)))


# --- Regateo -------------------------------------------------------------------

const ZONE_GREEN := "green"
const ZONE_YELLOW := "yellow"
const ZONE_RED := "red"


# Zona en la que se ha parado la aguja (posiciones de 0 a 1).
static func haggle_zone(position: float, green_center: float, green_half: float, yellow_half: float) -> String:
	var distance: float = abs(position - green_center)
	if distance <= green_half:
		return ZONE_GREEN
	if distance <= yellow_half:
		return ZONE_YELLOW
	return ZONE_RED


# Descuento conseguido: el máximo en verde, la mitad en amarillo.
static func haggle_percent(zone: String, max_percent: int) -> int:
	if zone == ZONE_GREEN:
		return int(max(0, max_percent))
	if zone == ZONE_YELLOW:
		return int(max(0, max_percent / 2))
	return 0


static func apply_discount(value: int, percent: int) -> int:
	if percent <= 0 or value <= 1:
		return value
	return int(max(1, round(value * (100 - percent) / 100.0)))
