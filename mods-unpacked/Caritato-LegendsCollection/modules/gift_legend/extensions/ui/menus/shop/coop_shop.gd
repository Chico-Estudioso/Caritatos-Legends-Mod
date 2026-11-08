extends "res://ui/menus/shop/coop_shop.gd"

# La Leyenda del Regalo: contador de regalos por tienda y refresco de la
# interfaz tras un regalo. El botón «Regalar» está en el menú de cada arma u
# objeto (extensión de coop_item_popup.gd).

const _CLC_GIFT_API = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")
const _CLC_GIFT_SYNC = preload("res://mods-unpacked/Caritato-LegendsCollection/modules/gift_legend/gift_shop_sync.gd")
const _CLC_GIFT_ID := "gift_legend"


# En Godot 3, _ready() se ejecuta en todos los niveles de herencia de forma
# automática (primero el del juego), así que no se llama a ._ready().
func _ready() -> void:
	var legend = _CLC_GIFT_API.get_runtime(_CLC_GIFT_ID)
	if legend != null:
		_CLC_GIFT_API.trace("Tienda cooperativa: lista (Regalo)")
		legend.on_shop_opened()
		_clc_gift_check_popups()


# Si el menú del arma u objeto no tiene la extensión, «Regalar» no saldrá:
# se deja constancia en el log de ModLoader para poder diagnosticarlo.
func _clc_gift_check_popups() -> void:
	for player_index in RunData.get_player_count():
		var popup = _get_item_popup(player_index)
		if popup != null and not popup.has_method("_clc_gift_on_pressed"):
			ModLoaderLog.error("El menú del objeto de J%d no tiene el botón Regalar (%s)." % [player_index + 1, popup.get_script().resource_path if popup.get_script() != null else "?"], "Caritato-LegendsCollection:Gift")


func _exit_tree() -> void:
	_CLC_GIFT_API.clear_popups()


# Tras un regalo: inventarios, estadísticas, precios de la tienda y del reroll
# de los dos jugadores (los objetos pueden cambiar precios y rerolls).
# Antes de tocar los inventarios, el foco que estuviera sobre ellos pasa al
# reroll de cada jugador; después se quita una casilla a quien regala y se
# añade otra a quien recibe, como al reciclar o comprar (ver gift_shop_sync.gd).
func _clc_gift_refresh(giver: int, recipient: int, data, received, is_weapon: bool) -> void:
	var involved := [giver, recipient]
	var gears := []
	var manager = get("_popup_manager")
	for player_index in involved:
		gears.append(_get_gear_container(player_index))
		if manager != null and manager.has_method("reset_focus"):
			manager.reset_focus(player_index)
	var emulators := []
	var fallbacks := []
	for player_index in RunData.get_player_count():
		emulators.append(Utils.get_focus_emulator(player_index) if Utils.has_method("get_focus_emulator") else null)
		fallbacks.append(_get_reroll_button(player_index))
	var moved: int = _CLC_GIFT_SYNC.release_focus(emulators, gears, fallbacks)
	_CLC_GIFT_API.trace("Regalo: foco movido al reroll en %d jugadores" % moved)

	var key: String = "weapons_container" if is_weapon else "items_container"
	var from_inventory = _CLC_GIFT_SYNC.inventory_of(gears[0], key)
	var to_inventory = _CLC_GIFT_SYNC.inventory_of(gears[1], key)
	if not _CLC_GIFT_SYNC.move_element(from_inventory, to_inventory, data, received, is_weapon):
		_CLC_GIFT_API.trace("Regalo: se rehacen los inventarios")
		for index in involved.size():
			if is_weapon:
				gears[index].set_weapons_data(RunData.get_player_weapons(involved[index]))
			else:
				gears[index].set_items_data(RunData.get_player_items(involved[index]))

	for index in involved.size():
		var player_index: int = involved[index]
		# Un objeto puede cambiar los huecos de armas («Armas (2/6)»).
		if gears[index].has_method("_on_weapons_changed"):
			gears[index]._on_weapons_changed()
		_update_stats(player_index)
		_get_shop_items_container(player_index).reload_shop_items()
		var reroll: Array = ItemService.get_reroll_price(RunData.current_wave, _paid_reroll_count[player_index], player_index)
		_reroll_price[player_index] = reroll[0]
		_reroll_discount[player_index] = reroll[1]
		set_reroll_button_price(player_index)
