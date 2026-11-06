extends SceneTree

# Utilidades comunes de las pruebas GDScript. Cada archivo test_*.gd la
# extiende, define sus casos y llama a finish() al terminar.

const MOD_PATH := "res://mods-unpacked/Caritato-LegendsCollection/"

var _passed := 0
var _failed := 0
var _current := ""


func run_case(title: String, method: String) -> void:
	_current = title
	var failures_before := _failed
	call(method)
	if _failed == failures_before:
		_passed += 1
		print("OK   %s" % title)


func check(condition: bool, message: String) -> void:
	if not condition:
		_failed += 1
		print("FALLO %s: %s" % [_current, message])


func finish() -> void:
	print("RESULTADO: %d correctas, %d fallidas" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
