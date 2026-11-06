# Pruebas

## Pruebas automáticas

| Comprobación | Comando | Dónde se ejecuta |
|---|---|---|
| Manifiesto, archivos, leyendas, textos, rutas, versiones | `python tools/validate.py` | Local y CI |
| Sintaxis GDScript (gdtoolkit 3) | `python tools/validate.py --gdparse` | Local y CI |
| Herramientas de validación y empaquetado | `python -m unittest discover -s tests/python -v` | Local y CI |
| Núcleo en GDScript (registro y configuración) | `python tools/run_gdscript_tests.py --godot <Godot 3 headless>` | CI (Godot 3.6 headless) |
| ZIP reproducible y con estructura correcta | `python tools/build.py` | Local y CI |

Instalar las herramientas de sintaxis:

```bash
pip install "gdtoolkit==3.6.0" "setuptools<81"
```

La CI (`.github/workflows/validacion.yml`) ejecuta todo lo anterior en cada push y PR, y adjunta el ZIP como artefacto.

## Instalación local para probar en Brotato

1. `python tools/build.py` → `dist/Caritato-LegendsCollection.zip`.
2. Abre la carpeta de instalación (Steam → Brotato → Administrar → Ver archivos locales).
3. Crea la carpeta `mods` si no existe y copia dentro el ZIP sin descomprimir.
4. Si también estás suscrito a la versión de Workshop, desuscríbete mientras pruebas para no cargar dos copias.
5. Abre Brotato y revisa `%APPDATA%\Brotato\logs\modloader.log`. Debe aparecer:
   - `Iniciando Caritatos Legends v<versión>`
   - una línea por leyenda: `[id] cargada`, `[id] desactivada por el jugador`, etc.
   - `Caritatos Legends listo.`

La configuración se guarda en `%APPDATA%\Brotato\caritato_legends\settings.json`. Si se borra, el mod vuelve a los valores por defecto. Si está dañada, se guarda una copia `settings.json.invalido.bak` y se arranca con los valores por defecto.

## Prueba rápida recomendada (15 minutos)

1. Instala el ZIP como se indica arriba y abre Brotato.
2. Menú principal → **Leyendas**: deben aparecer 4 leyendas activas. Cierra con «Guardar y cerrar».
3. Partida nueva con Abyssal Terrors: al terminar la oleada 4, el Anzuelo debe estar en la tienda.
4. En esa tienda, botón **Supermercado** → encarga un objeto → aparece en la tienda y se puede comprar.
5. Pausa → **Leyendas** → Mercader: rerolls al 0 % → al volver a la tienda, el reroll cuesta 0.
6. Si tienes una partida infinita guardada pasada la oleada 20: la recolección ya no baja.
7. Envía `%APPDATA%\Brotato\logs\modloader.log` si algo falla.

## Pruebas manuales dentro de Brotato

Núcleo (cada versión):
- [ ] El mod aparece en el menú «Mods» del juego y el log muestra «Caritatos Legends listo».
- [ ] El menú principal muestra el botón **Leyendas** debajo de «Mods»; abre la pantalla.
- [ ] Ratón, teclado y mando: se puede navegar, cambiar valores y cerrar con «atrás».
- [ ] «Cancelar» descarta los cambios; «Guardar y cerrar» los conserva tras reiniciar el juego.
- [ ] «Restaurar valores por defecto» deja todas las leyendas en su estado inicial.
- [ ] Activar una leyenda desactivada muestra el aviso de reinicio; tras reiniciar aparece como activa.
- [ ] Durante una partida: pausa → **Leyendas**; al cerrar con «atrás» se vuelve al menú de pausa sin reanudar la partida.
- [ ] Un `settings.json` con texto basura no impide arrancar y genera la copia `.invalido.bak`.

Cada leyenda tiene su propia lista en `docs/CATALOGO_MODS.md`.

## Cómo informar de resultados

En cada PR se separan:
- Pruebas automáticas ejecutadas y resultado.
- Pruebas manuales dentro de Brotato (con versión exacta del juego y del ModLoader).
- Pruebas pendientes.

No se marca como probado lo que solo se ha revisado leyendo código.
