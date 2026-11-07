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

### Dónde busca mods el juego

| Versión de Brotato | Dónde carga los ZIP | Carpeta `mods` |
|---|---|---|
| Steam | Solo en `<biblioteca de Steam>\steamapps\workshop\content\1942280\<id>\`, y solo si `<id>` es un objeto del Workshop al que estás suscrito | **Se ignora** (también `--mods-path`) |
| GOG, Epic y otras | `<instalación de Brotato>\mods\` (o la ruta de `--mods-path=<ruta>`) | Sí |

Evidencia en `docs/COMPATIBILIDAD.md` («Cómo se carga un mod»).

### En Steam (antes de publicar)

1. Consigue el ZIP: `python tools/build.py` → `dist/Caritato-LegendsCollection.zip`, o el artefacto `Caritato-LegendsCollection` de la última ejecución de la CI (el artefacto descargado es un ZIP que contiene nuestro ZIP: sácalo, pero **no** lo descomprimas).
2. Suscríbete en el Workshop a un mod pequeño de Brotato que no toque la tienda, la recolección ni los menús (o usa uno al que ya estés suscrito). Abre Brotato una vez para que Steam lo descargue y ciérralo.
3. Abre `<biblioteca de Steam>\steamapps\workshop\content\1942280\`. Hay una carpeta numérica por cada objeto del Workshop; la del mod elegido lleva el número que aparece en su página (`steamcommunity.com/sharedfiles/filedetails/?id=<número>`). Las carpetas de mods a los que ya no estás suscrito no se cargan.
4. Copia `Caritato-LegendsCollection.zip` sin descomprimir dentro de esa carpeta, junto al ZIP del otro mod. Si no quieres que ese mod se cargue, puedes borrar su ZIP (Steam puede volver a ponerlo cuando se actualice).
5. Abre Brotato. En «Mods» debe aparecer **LegendsCollection** y en el menú principal, el botón **Caritatopc**.
6. En cada versión nueva, sobrescribe el ZIP. Si Steam actualiza el mod de esa carpeta puede borrar el nuestro: vuelve a copiarlo.
7. Cuando el mod esté publicado en el Workshop (aunque sea oculto), basta con suscribirse; quita entonces la copia manual para no cargar dos.

La carpeta `Brotato\mods` de la instalación de Steam no hace falta y se puede borrar.

### En GOG, Epic y otras versiones

1. Crea la carpeta `mods` en la instalación de Brotato si no existe.
2. Copia dentro el ZIP sin descomprimir.

### Comprobar que ha cargado

Abre Brotato y revisa `%APPDATA%\Brotato\logs\modloader.log`. Debe aparecer:
- `Checking workshop item path: "...\1942280\<número>"` (solo en Steam) y, después, el ZIP cargado.
- `Iniciando Caritatos Legends v<versión>`
- una línea por leyenda: `[id] cargada`, `[id] desactivada por el jugador`, etc.
- `Caritatos Legends listo.`

Si el menú «Mods» sale vacío, el ZIP no está en una carpeta que el juego lea: revisa la tabla de arriba y el log.

La configuración se guarda en `%APPDATA%\Brotato\caritato_legends\settings.json`. Si se borra, el mod vuelve a los valores por defecto. Si está dañada, se guarda una copia `settings.json.invalido.bak` y se arranca con los valores por defecto.

## Prueba rápida recomendada (15 minutos)

1. Instala el ZIP como se indica arriba y abre Brotato.
2. Menú principal → **Caritatopc**: deben aparecer 5 tarjetas con el punto verde «Activa». Cierra con «Guardar».
3. Partida nueva con Abyssal Terrors: al terminar la oleada 4, el Anzuelo debe estar en la tienda.
4. En esa tienda, botón **Supermercado** → encarga un objeto → aparece en la tienda y se puede comprar.
5. Pausa → **Caritatopc** → Mercader: rerolls al 0 % → al volver a la tienda, el reroll cuesta 0.
6. Si tienes una partida infinita guardada pasada la oleada 20: la recolección ya no baja.
7. Envía `%APPDATA%\Brotato\logs\modloader.log` si algo falla.

## Pruebas manuales dentro de Brotato

Núcleo (cada versión):
- [ ] El mod aparece en el menú «Mods» del juego y el log muestra «Caritatos Legends listo».
- [ ] El menú principal muestra el botón **Caritatopc** debajo de «Mods»; abre la pantalla.
- [ ] Ratón, teclado y mando: se puede navegar, cambiar valores y cerrar con «atrás».
- [ ] «Cancelar» descarta los cambios; «Guardar» los conserva tras reiniciar el juego.
- [ ] «Restaurar» deja todas las leyendas en su estado inicial.
- [ ] Biblioteca: al moverse por las tarjetas (ratón, teclado o mando) la ficha de la derecha cambia; «derecha» o «aceptar» entra en la ficha e «izquierda» vuelve a la tarjeta.
- [ ] Al pasar por un ajuste, su explicación aparece en el recuadro de abajo.
- [ ] Activar una leyenda desactivada muestra el aviso de reinicio; tras reiniciar aparece como activa.
- [ ] Durante una partida: pausa → **Caritatopc**; al cerrar con «atrás» se vuelve al menú de pausa sin reanudar la partida.
- [ ] En cooperativo (teclado + mando): en la pausa → **Caritatopc** se navega con el teclado y con el mando (cruceta y stick), y «atrás» la cierra.
- [ ] Un `settings.json` con texto basura no impide arrancar y genera la copia `.invalido.bak`.

Cada leyenda tiene su propia lista en `docs/CATALOGO_MODS.md`.

## Cómo informar de resultados

En cada PR se separan:
- Pruebas automáticas ejecutadas y resultado.
- Pruebas manuales dentro de Brotato (con versión exacta del juego y del ModLoader).
- Pruebas pendientes.

No se marca como probado lo que solo se ha revisado leyendo código.
