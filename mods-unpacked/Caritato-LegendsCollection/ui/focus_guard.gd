extends Reference

# En la tienda cooperativa el juego mueve el foco de cada mando con sus propios
# «FocusEmulator», que consumen la entrada. Mientras una ventana del mod está
# abierta se pausan igual que hace el juego al pausar: se ocultan y dejan de
# leer la entrada. resume() los deja como estaban.

const FOCUS_EMULATOR_SCRIPT_SUFFIX := "focus_emulator.gd"


static func pause(tree: SceneTree) -> Array:
	var paused := []
	if tree == null or tree.current_scene == null:
		return paused
	var pending := [tree.current_scene]
	while not pending.empty():
		var node: Node = pending.pop_back()
		var script = node.get_script()
		if script != null and str(script.resource_path).ends_with(FOCUS_EMULATOR_SCRIPT_SUFFIX):
			paused.append({
				"node": node,
				"input": node.is_processing_input(),
				"visible": node.visible if "visible" in node else true,
			})
			node.set_process_input(false)
			if "visible" in node:
				node.visible = false
		for child in node.get_children():
			pending.append(child)
	return paused


static func resume(paused: Array) -> void:
	for entry in paused:
		var node = entry.node
		if not is_instance_valid(node):
			continue
		node.set_process_input(entry.input)
		if "visible" in node:
			node.visible = entry.visible
	paused.clear()
