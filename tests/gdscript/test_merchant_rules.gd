extends "res://tests/gdscript/base_test.gd"

# Reglas de La Leyenda del Mercader.

var MerchantRules = load(MOD_PATH + "modules/merchant_legend/merchant_rules.gd")


func _init() -> void:
	run_case("oleada usada para calcular precios", "test_price_wave")
	run_case("precio de los artículos", "test_item_price")
	run_case("precio de los rerolls", "test_reroll_price")
	run_case("regateo: zona y descuento", "test_haggle")
	finish()


func test_price_wave() -> void:
	check(MerchantRules.price_wave(12, false) == 12, "sin precios fijos se usa la oleada real")
	check(MerchantRules.price_wave(12, true) == 1, "con precios fijos se usa la oleada 1")
	check(MerchantRules.price_wave(0, true) == 0, "no sube oleadas menores que 1")


func test_item_price() -> void:
	check(MerchantRules.scale_item_price(40, 100) == 40, "100 % no cambia nada")
	check(MerchantRules.scale_item_price(40, 50) == 20, "50 % es la mitad")
	check(MerchantRules.scale_item_price(3, 10) == 1, "nunca baja de 1")
	check(MerchantRules.scale_item_price(33, 150) == 50, "se redondea")


func test_reroll_price() -> void:
	check(MerchantRules.scale_reroll_price(7, 100) == 7, "100 % no cambia nada")
	check(MerchantRules.scale_reroll_price(7, 0) == 0, "0 % es gratis")
	check(MerchantRules.scale_reroll_price(7, 50) == 4, "se redondea hacia arriba")
	check(MerchantRules.scale_reroll_price(1, 5) == 1, "un porcentaje bajo no lo hace gratis")
	check(MerchantRules.scale_reroll_price(0, 50) == 0, "un reroll gratis sigue gratis")


func test_haggle() -> void:
	check(MerchantRules.haggle_zone(0.5, 0.5, 0.06, 0.16) == "green", "en el centro de la zona verde")
	check(MerchantRules.haggle_zone(0.6, 0.5, 0.06, 0.16) == "yellow", "fuera del verde, dentro del amarillo")
	check(MerchantRules.haggle_zone(0.9, 0.5, 0.06, 0.16) == "red", "lejos de la zona verde")
	check(MerchantRules.haggle_percent("green", 10) == 10, "verde: el máximo")
	check(MerchantRules.haggle_percent("yellow", 10) == 5, "amarillo: la mitad")
	check(MerchantRules.haggle_percent("red", 10) == 0, "rojo: nada")
	check(MerchantRules.apply_discount(40, 10) == 36, "−10 % de 40")
	check(MerchantRules.apply_discount(1, 30) == 1, "un artículo de 1 no baja")
	check(MerchantRules.apply_discount(40, 0) == 40, "sin descuento no cambia")
