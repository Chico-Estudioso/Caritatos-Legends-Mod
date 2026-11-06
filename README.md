# Caritatos Legends

**Brotato Legends Collection**: un único mod de Brotato que reúne «leyendas» —mods clásicos de la comunidad recuperados, recreados y adaptados— y deja que cada jugador elija desde el propio juego cuáles activa y con qué valores.

## Qué incluye

| Leyenda | Qué hace | Estado |
|---|---|---|
| **La Leyenda del Anzuelo** *(Abyssal Terrors)* | El Anzuelo aparece garantizado en la tienda de la oleada que elijas (por defecto, la 4) y puedes fijar la probabilidad de maldición que da cada anzuelo | Incluida, pendiente de prueba en el juego |

## Instalación

### Steam Workshop
Cuando se publique: suscríbete en el Workshop de Brotato y abre el juego. No necesita ningún otro mod.

### Manual (pruebas locales)
1. Genera el paquete: `python tools/build.py` → `dist/Caritato-LegendsCollection.zip`.
2. Copia el ZIP **sin descomprimir** en la carpeta `mods` de la instalación de Brotato (crea la carpeta si no existe). En Steam: clic derecho en Brotato → Administrar → Ver archivos locales.
3. Abre Brotato. El ModLoader integrado detecta el mod.

Más detalle y diagnóstico en `docs/PRUEBAS.md`.

## Configuración en el juego

- Menú principal → botón **Leyendas** (debajo de «Mods»).
- Durante una partida: pausa → **Leyendas**.

Cada leyenda tiene un interruptor y sus ajustes. Los valores se aplican al momento; «Guardar y cerrar» los guarda en `%APPDATA%\Brotato\caritato_legends\settings.json`. Activar una leyenda que no estaba cargada requiere reiniciar Brotato, y la pantalla lo avisa.

## Compatibilidad

Desarrollado contra **Brotato 1.1.15.4** con **ModLoader 6.3.0** (el que trae el juego). Lo verificado y lo pendiente está en `docs/COMPATIBILIDAD.md`.

## Desarrollo

```bash
python tools/validate.py --gdparse      # manifiesto, leyendas, textos, rutas y sintaxis GDScript
python -m unittest discover -s tests/python -v
python tools/build.py                   # ZIP reproducible en dist/
```

La sintaxis GDScript se comprueba con `gdtoolkit` 3 (`pip install "gdtoolkit==3.6.0" "setuptools<81"`). Las pruebas del núcleo en GDScript se ejecutan en la CI con Godot 3.6 headless (`tools/run_gdscript_tests.py`).

Arquitectura y cómo añadir una leyenda: `docs/ARQUITECTURA.md`. Reglas de trabajo: `CLAUDE.md` y `AGENTS.md`.

## Créditos y licencias

Cada leyenda declara su procedencia. Consulta `docs/LICENCIAS_Y_CREDITOS.md`. Brotato es propiedad de Blobfish Games; este repositorio no contiene archivos del juego.
