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
