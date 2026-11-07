# Changelog

Los cambios importantes de Caritatos Legends se documentan aquí. El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el versionado es semántico.

## [Sin publicar]

### Corregido
- **Compatibilidad con Brotato 1.2**: las extensiones de scripts de escenas (tienda, `main.gd`, menús) se instalan en `_ready` y no en `_init`. En 1.2.0.1, cargar la tienda durante `_init` rompía su compilación y el juego desactivaba todos los mods en el siguiente arranque.
- El Anzuelo ya no consulta la lista de objetos al arrancar (en 1.2 se quedaría en caché sin los objetos de los DLC).
- La comprobación de DLC en la partida usa los «conjuntos de objetos» de la 1.2 (`RunData.active_update_data_ids`).

### Cambiado
- `compatible_game_version`: 1.2.X.X y 1.1.15.4.
- Validación: las extensiones deben replicar la ruta del script que extienden.

## [0.2.0] - 2026-11-06

Versión candidata: completa en pruebas automáticas, pendiente de probar dentro de Brotato antes de publicarla.

### Añadido
- **La Leyenda del Anzuelo** (`hook_legend`, Abyssal Terrors): Anzuelo garantizado al entrar en la tienda de la oleada elegida (por defecto, la 4), opción de repetirlo hasta tener uno y probabilidad de maldición por anzuelo configurable (1-100 %). Respeta objetos bloqueados, prohibidos y el máximo de anzuelos.
- **La Leyenda de la Cosecha Eterna** (`endless_harvest`): pérdida de recolección por oleada del modo infinito configurable (0-100 %, por defecto 0 %; el juego quita un 20 %), opción de seguir creciendo como en las oleadas 1-20 (Granjero y Corona incluidos) y Hucha que sigue dando interés tras la oleada 20. El texto de la estadística de Recolección refleja la configuración.
- **La Leyenda del Mercader** (`merchant_legend`): precio de los artículos (10-300 %) y de los rerolls (0-300 %, 0 % = gratis), con opción de que no se encarezcan con las oleadas. Valores por defecto neutros.
- **La Leyenda del Supermercado** (`supermarket_legend`): botón en la tienda (un jugador) que abre un catálogo con los objetos y armas que el juego podría ofrecerte; el elegido se coloca en un hueco libre o en el último no bloqueado y se compra con las reglas del juego. Encargos por tienda (1 por defecto), coste del encargo, tier máximo y armas configurables.
- Ajustes que dependen de que otro esté apagado (`"depends_on": "!clave"`).
- Validación: los miembros propios de las extensiones llevan prefijo `_clc_` y no pueden repetirse entre extensiones del mismo script.
- Pruebas GDScript de arranque completo del núcleo con las leyendas reales y de la pantalla de configuración, con sustitutos de ModLoader.

## [0.1.0] - 2026-11-06

### Añadido
- Mod único `Caritato-LegendsCollection` para ModLoader 6.3.0 (Brotato 1.1.15.4).
- Núcleo modular: definiciones de leyendas en `modules/<id>/module.json`, validación de ids, ajustes, dependencias, conflictos y ciclos; una leyenda con errores se desactiva sin afectar a las demás.
- Configuración persistente en `user://caritato_legends/settings.json` con valores por defecto, saneado de tipos y rangos, y recuperación (con copia de seguridad) si el archivo está dañado.
- Pantalla **Leyendas** en el menú principal y en el menú de pausa: activar/desactivar, ajustes, restaurar valores por defecto, cancelar y guardar, avisos de reinicio, dependencias, DLC y compatibilidad.
- Capa de compatibilidad `core/compat.gd` y textos en español e inglés.
- Herramientas: `tools/validate.py`, `tools/build.py` (ZIP reproducible), `tools/run_gdscript_tests.py`; pruebas en Python y GDScript; CI en GitHub Actions.
- Documentación del proyecto, catálogo inicial de leyendas y registro de decisiones.
