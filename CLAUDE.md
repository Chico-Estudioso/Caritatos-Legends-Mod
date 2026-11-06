# CLAUDE.md — Caritatos Legends (Brotato Legends Collection)

Lee también `AGENTS.md`. Los documentos de `docs/` contienen el alcance, las decisiones y los procedimientos del proyecto.

## Objetivo

Caritatos Legends es **un único mod de Brotato** distribuido desde Steam Workshop. Reúne «leyendas»: mods clásicos de la comunidad recuperados, recreados o adaptados, organizados en módulos internos que el jugador activa, desactiva y ajusta desde el propio juego (botón **Leyendas** del menú principal y del menú de pausa).

## Forma de trabajar acordada con Mauro (propietario)

Estas reglas prevalecen sobre las restricciones de los prompts de `docs/prompts/`, que se redactaron antes de acordarlas:

- Claude trabaja con autonomía: investiga, decide los detalles técnicos razonables, crea carpetas y archivos que falten, abre Pull Requests **y las fusiona** cuando las comprobaciones pasan. Solo pregunta cuando una decisión es realmente del propietario (alcance, publicación en Workshop, gasto, cuentas).
- Todo el trabajo se publica **a nombre de Mauro**: commits con su identidad de Git y Pull Requests desde su cuenta. **Nunca** se añaden líneas de atribución a Claude (`Co-Authored-By`, «Generated with Claude Code», enlaces de sesión ni similares) en commits, PR, issues ni comentarios.
- `main` no recibe pushes directos: todo entra por Pull Request (una tarea, una PR pequeña), con squash merge.
- Publicar o actualizar en Steam Workshop sigue requiriendo el visto bueno expreso de Mauro.
- Mauro irá proponiendo nuevas leyendas; Claude puede añadir por iniciativa propia mods de calidad que encajen, documentando su procedencia.

## Decisiones del proyecto

- Distribución: un único mod instalable, sin dependencias obligatorias de otros mods de Workshop.
- Alcance: recuperar, recrear y adaptar mods clásicos; se admiten mejoras configurables propias si Mauro las pide.
- Contenido de terceros: enfoque híbrido. Reutilizar código o recursos cuando la licencia lo permita o haya permiso; si no, recreación independiente con código propio. Mauro puede autorizar otras libertades caso a caso; documéntalo en `docs/DECISIONES.md`.
- Configuración: por leyenda (activar/desactivar) y por ajuste, persistente en `user://caritato_legends/settings.json`.
- Activar una leyenda que no estaba cargada requiere reiniciar Brotato; la interfaz lo indica. Los valores se aplican al momento.

## Idioma y código

- Conversaciones, documentación, mensajes de interfaz y commits en español.
- Identificadores de código, nombres de clases, funciones y propiedades en inglés.
- Textos visibles siempre mediante claves `CLC_*` en `mods-unpacked/Caritato-LegendsCollection/i18n/strings.json` (español e inglés).

## Fuente de verdad

- `ROADMAP.md`: fases y estado.
- `CHANGELOG.md`: cambios realizados.
- `docs/ARQUITECTURA.md`: arquitectura y cómo añadir una leyenda.
- `docs/DECISIONES.md`: decisiones y motivos.
- `docs/COMPATIBILIDAD.md`: versiones verificadas y API del juego usada.
- `docs/CATALOGO_MODS.md`: leyendas candidatas y estado.
- `docs/LICENCIAS_Y_CREDITOS.md`: procedencia, licencias y atribuciones.
- `docs/PRUEBAS.md`: instalación local, pruebas automáticas y manuales.

Si la documentación contradice el código, no elijas en silencio: corrige la que esté mal en la misma PR y explícalo.

## Reglas técnicas

- Brotato usa Godot 3 (GDScript 3) y ModLoader 6.3.0. No uses sintaxis de Godot 4.
- En Godot 3, `_init`, `_ready`, `_enter_tree`, `_exit_tree`, `_process`, `_input`… se ejecutan en todos los niveles de herencia automáticamente: **no llames a `._ready()`** en una extensión. Para métodos normales sí se usa `.metodo()` para llamar al original.
- Verifica nombres de funciones y rutas contra el código real del juego (ver `docs/COMPATIBILIDAD.md`). No inventes APIs.
- Las llamadas a la API del juego compartidas van en `core/compat.gd`.
- Una leyenda desactivada no instala extensiones ni crea su runtime. Si se desactiva en caliente, sus extensiones deben comportarse como el juego base.
- Las extensiones deben ser finas: comprueban si la leyenda está activa y delegan en su runtime. Sus constantes, variables y funciones auxiliares llevan prefijo `_clc_<leyenda>_` / `_CLC_<LEYENDA>_` (un miembro repetido en la cadena de herencia rompe el script).
- Cada leyenda declara procedencia (`origin`) y compatibilidad en su `module.json`.
- No se incluyen archivos del juego, código descompilado ni recursos propietarios en el repositorio. Las copias de referencia viven fuera (carpetas ignoradas en `.gitignore`).
- No afirmes que una prueba ha pasado si no la has ejecutado; distingue pruebas automáticas de pruebas dentro de Brotato.

## Git y GitHub

- Ramas de trabajo: la rama asignada a la sesión o `feat/*`, `fix/*`, `chore/*`, `docs/*`.
- Conventional Commits en español: `feat(anzuelo): añade la probabilidad configurable`.
- Antes del primer commit comprueba que `git config user.name` / `user.email` corresponden a Mauro (`Mauro Serrano Hevia` / `144903323+Chico-Estudioso@users.noreply.github.com`).
- Sin `push --force` a ramas compartidas ni a `main`. Se permite `--force-with-lease` sobre la propia rama de trabajo cuando todo su historial ya está fusionado.
- PR con la plantilla de `.github/PULL_REQUEST_TEMPLATE.md`. Fusionar con squash cuando la CI esté en verde.

## Antes de terminar una tarea

1. `python tools/validate.py --gdparse` y `python -m unittest discover -s tests/python`.
2. Añade o actualiza pruebas.
3. Actualiza `ROADMAP.md`, `CHANGELOG.md` y, si aplica, `docs/DECISIONES.md`, `docs/COMPATIBILIDAD.md`, `docs/CATALOGO_MODS.md` y `docs/LICENCIAS_Y_CREDITOS.md`.
4. Abre la PR con resumen, pruebas y pasos para probar; fusiónala cuando la CI pase.
5. Informa de lo que no se haya podido verificar dentro del juego.
