# Registro de decisiones

| Fecha | Decisión | Motivo | Estado |
|---|---|---|---|
| 2026-11-06 | Distribución en un único mod de Workshop | Facilitar la instalación al jugador | Aprobada |
| 2026-11-06 | Alcance: recuperar, recrear y adaptar mods clásicos | Objetivo del proyecto definido por Mauro | Aprobada |
| 2026-11-06 | Reutilización híbrida con control de licencias; Mauro puede autorizar libertades caso a caso | Aprovechar contenido legalmente y recrear lo demás | Aprobada |
| 2026-11-06 | Configuración de leyendas dentro del juego | Cada jugador elige su contenido | Aprobada |
| 2026-11-06 | Claude trabaja con autonomía y fusiona las PR con la CI en verde; todo a nombre de Mauro y sin atribuciones de IA | Confianza ya verificada en otros proyectos; indicación expresa de Mauro | Aprobada |
| 2026-11-06 | Versión objetivo: Brotato 1.1.15.4 con ModLoader 6.3.0 (integrado en el juego) | Es la versión más reciente con código verificable; el juego trae ModLoader 6.3.0 | Aprobada |
| 2026-11-06 | ID del mod `Caritato-LegendsCollection` (namespace `Caritato`, nombre `LegendsCollection`) | ModLoader solo admite letras, números y `_` en nombre y namespace | Aprobada |
| 2026-11-06 | Pantalla de configuración propia, sin depender de Mod Options | Evitar una dependencia obligatoria de Workshop; Mod Options añade una pestaña genérica sin avisos de reinicio | Aprobada |
| 2026-11-06 | Preferencias propias en `user://caritato_legends/settings.json` en lugar de ModLoaderConfig | Validación por leyenda, recuperación ante errores y pruebas sin el juego | Aprobada |
| 2026-11-06 | Definiciones de leyendas en JSON (`module.json`) | Las validan tanto el juego (GDScript) como la CI (Python) con las mismas reglas | Aprobada |
| 2026-11-06 | Las extensiones se instalan solo al arrancar; activar una leyenda nueva requiere reiniciar | ModLoader solo instala extensiones con seguridad durante su inicialización | Aprobada |
| 2026-11-06 | Interfaz y textos construidos por código (sin escenas ni `.translation` importados) | El ZIP no pasa por el importador del editor de Godot | Aprobada |
| 2026-11-06 | Sin módulos de demostración: las primeras leyendas reales sirven de prueba del núcleo | Mauro ha pedido leyendas concretas desde el principio | Aprobada |
| 2026-11-06 | Código del juego descompilado solo como referencia local, nunca en el repositorio | Verificar la API real sin redistribuir material propietario | Aprobada |
| 2026-11-07 | Versión objetivo principal: Brotato 1.2.x (con Primal Dread), manteniendo 1.1.15.4 | La 1.2 es la versión actual; no hay código público de la 1.2, así que se usa la guía de migración de mojimoon y mods actualizados como referencia | Aprobada |
| 2026-11-07 | Extensiones de autoloads en `_init`; extensiones de escenas en `_ready` (`base_shop.gd` primero) | En 1.2.0.1 cargar `base_shop.gd` en `_init` rompe el juego y desactiva todos los mods; las de autoloads tienen que instalarse antes de que existan | Aprobada |
| 2026-11-07 | Las extensiones replican la ruta del script que extienden | El núcleo y la validación deciden por la ruta cuándo instalar cada una | Aprobada |
| Pendiente | Uso de ContentLoader para leyendas de contenido (personajes, armas, objetos) | Su repositorio no publica licencia; decidir integración o recreación al llegar la primera leyenda de contenido | Por decidir |
