extends Reference

# Registra los textos del mod en el TranslationServer a partir de un JSON
# {"es": {CLAVE: texto}, "en": {...}}. Se construyen en tiempo de ejecución
# para no depender de archivos .translation importados por el editor.


static func register_file(path: String) -> Array:
	var errors := []
	var file := File.new()
	if not file.file_exists(path):
		errors.append("no existe el archivo de textos %s" % path)
		return errors

	var open_error := file.open(path, File.READ)
	if open_error != OK:
		errors.append("no se pudo abrir %s (error %d)" % [path, open_error])
		return errors

	var parsed := JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or not parsed.result is Dictionary:
		errors.append("JSON de textos inválido en %s" % path)
		return errors

	var locales: Dictionary = parsed.result
	for locale in locales.keys():
		var messages = locales[locale]
		if not messages is Dictionary:
			errors.append("la sección '%s' de los textos no es un objeto" % str(locale))
			continue
		var translation := Translation.new()
		translation.locale = str(locale)
		for key in messages.keys():
			translation.add_message(str(key), str(messages[key]))
		TranslationServer.add_translation(translation)

	return errors
