# Arquitectura

Un único paquete para ModLoader con un núcleo pequeño y una carpeta por leyenda.

## Estructura del paquete

```text
mods-unpacked/Caritato-LegendsCollection/
├── manifest.json            # metadatos para ModLoader 6.3.0
├── mod_main.gd              # punto de entrada: arranca el núcleo e instala extensiones del núcleo
├── core/
│   ├── legends_core.gd      # orquestador (nodo LegendsCore): carga, configuración, API, menú
│   ├── module_registry.gd   # lógica pura: valida definiciones y decide qué se carga
│   ├── config_store.gd      # lógica pura: persistencia y saneado de preferencias
│   ├── legends_api.gd       # acceso estático para las extensiones
│   ├── compat.gd            # capa de compatibilidad con la API interna de Brotato
│   └── i18n.gd              # registra los textos en el TranslationServer
├── i18n/strings.json        # textos CLC_* en español e inglés
├── ui/legends_menu.gd       # pantalla «Leyendas» construida por código
├── extensions/              # extensiones del núcleo (botones de menú)
└── modules/
    ├── modules.json         # índice de leyendas en orden
    └── <id>/
        ├── module.json      # definición de la leyenda
        ├── <id>.gd          # runtime (lógica de la leyenda)
        └── extensions/...   # extensiones de scripts del juego
```

En el ZIP final esta carpeta va bajo `mods-unpacked/` (lo genera `tools/build.py`).

## Arranque

1. ModLoader instancia `mod_main.gd` durante su inicialización (es el único momento en que se pueden instalar extensiones de scripts).
2. `LegendsCore.boot()` registra los textos, lee `modules/modules.json` y cada `module.json`, valida referencias y lee la configuración del jugador.
3. `module_registry.resolve_load_set()` decide el estado de cada leyenda:
   - `loaded`: activada, sin errores, con dependencias cargadas y sin conflictos.
   - `disabled`: desactivada por el jugador → no instala nada.
   - `blocked`: falta una dependencia o hay conflicto con otra leyenda cargada.
   - `error`: definición inválida o archivos ausentes → se registra en el log con su id.
4. Para cada leyenda `loaded` se comprueba que existen todos sus archivos, se instalan sus extensiones con `ModLoaderMod.install_script_extension()` y se crea su runtime como hijo de `LegendsCore`.
5. Se guarda la configuración completada con los valores por defecto.

## Activación, desactivación y reinicio

- **Valores**: se leen en el momento de usarlos, así que cambian al instante (también desde el menú de pausa).
- **Desactivar** una leyenda cargada: deja de aplicarse al momento; sus extensiones siguen instaladas pero se comportan como el juego base. Al reiniciar ya no se instalan.
- **Activar** una leyenda que no se cargó al arrancar: requiere reiniciar Brotato. La pantalla lo indica por leyenda y con un aviso general.

No se intenta desinstalar extensiones en caliente: ModLoader 6.3.0 no lo garantiza de forma segura.

## Extensiones y runtime

Las extensiones son finas: comprueban si su leyenda está activa y delegan en el runtime.

```gdscript
extends "res://ui/menus/shop/base_shop.gd"
const LegendsAPI = preload("res://mods-unpacked/Caritato-LegendsCollection/core/legends_api.gd")

func fill_shop_items(locked: Array, player_index: int, just_entered_shop: bool = false) -> void:
	.fill_shop_items(locked, player_index, just_entered_shop)
	var legend = LegendsAPI.get_runtime("mi_leyenda")   # null si no está activa
	if legend != null:
		legend.on_shop_filled(_shop_items[player_index], player_index)
```

El runtime recibe `setup(core, module_id)` al crearse y `on_config_changed()` cada vez que cambia su configuración. Lee sus ajustes con `core.get_setting(id, clave)`.

Reglas de Godot 3 que hay que respetar:
- `_ready`, `_enter_tree`, `_process`, `_input`… se ejecutan en todos los niveles de herencia automáticamente: no se llama a `._ready()`.
- Para métodos normales, `.metodo(args)` llama a la implementación original y mantiene la cadena con otros mods.
- Varias leyendas pueden extender el mismo script; ModLoader encadena las extensiones.

## Definición de una leyenda (`module.json`)

```json
{
  "id": "mi_leyenda",
  "version": "1.0.0",
  "category": "mechanics",
  "name_key": "CLC_MOD_MI_LEYENDA_NAME",
  "description_key": "CLC_MOD_MI_LEYENDA_DESC",
  "enabled_by_default": true,
  "requires_dlc": [],
  "dependencies": [],
  "conflicts": [],
  "runtime": "mi_leyenda.gd",
  "extensions": ["extensions/ui/menus/shop/base_shop.gd"],
  "compatibility": {"status": "untested", "game_versions": ["1.1.15.4"]},
  "origin": {"type": "independent_recreation", "inspired_by": [], "notes": ""},
  "settings": [
    {"key": "activo", "type": "bool", "default": true, "label_key": "CLC_..."},
    {"key": "oleada", "type": "int", "default": 4, "min": 1, "max": 20, "step": 1,
     "label_key": "CLC_...", "help_key": "CLC_...", "suffix": "", "depends_on": "activo"}
  ]
}
```

- `category`: `mechanics`, `shop`, `economy`, `balance`, `content` o `quality_of_life`.
- Tipos de ajuste: `bool`, `int`, `float` y `enum` (`options` + textos `<label_key>_<OPCION>`).
- `depends_on`: el control se atenúa si el ajuste booleano indicado está apagado.
- `compatibility.status`: `tested` solo cuando se ha probado dentro de Brotato en esas versiones.
- `origin.type`: `independent_recreation`, `reused_with_license`, `reused_with_permission` u `original`.

## Cómo añadir una leyenda

1. Crea `modules/<id>/` con `module.json`, el runtime y las extensiones.
2. Añade el id a `modules/modules.json`.
3. Añade sus textos `CLC_*` en `i18n/strings.json` (español e inglés).
4. Si necesitas una API del juego que pueda cambiar o que compartan varias leyendas, añádela a `core/compat.gd`.
5. Ejecuta `python tools/validate.py --gdparse` y las pruebas.
6. Documenta procedencia en `docs/LICENCIAS_Y_CREDITOS.md` y estado en `docs/CATALOGO_MODS.md`.

## Frameworks existentes evaluados

- **Mod Options** (`dami-ModOptions`, MIT): añade una pestaña de configuración. Obligaría a instalar otro mod de Workshop, así que no se usa como dependencia. La pantalla propia es independiente y no copia su código.
- **ModLoaderConfig** (configs con `config_schema`): no se usa porque la configuración por leyenda con validación propia es más sencilla de mantener y de probar sin el juego.
- **ContentLoader** (`Darkly77-ContentLoader`): útil para registrar personajes, armas y objetos nuevos. Sin licencia publicada en su repositorio; se evaluará cuando llegue la primera leyenda de contenido (ver `docs/DECISIONES.md`).
