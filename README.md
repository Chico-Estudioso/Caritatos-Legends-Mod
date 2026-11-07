# Caritatos Legends

**Brotato Legends Collection**: un único mod de Brotato que reúne «leyendas» —mods clásicos de la comunidad recuperados, recreados y adaptados— y deja que cada jugador elija desde el propio juego cuáles activa y con qué valores.

## Qué incluye

| Leyenda | Qué hace | Estado |
|---|---|---|
| **La Leyenda del Anzuelo** *(Abyssal Terrors)* | El Anzuelo aparece garantizado en la tienda de la oleada que elijas (por defecto, la 4) y puedes fijar la probabilidad de maldición que da cada anzuelo | Incluida, pendiente de prueba en el juego |
| **La Leyenda de la Cosecha Eterna** | En el modo infinito eliges cuánta recolección se pierde tras la oleada 20 (por defecto 0 %, el juego quita un 20 %), si sigue creciendo como antes y si la Hucha sigue funcionando | Incluida, pendiente de prueba en el juego |
| **La Leyenda del Mercader** | Precio de los artículos y de los rerolls en porcentaje (0 % = rerolls gratis) y opción de que no suban con las oleadas. Por defecto, la tienda funciona como en el juego | Incluida, pendiente de prueba en el juego |
| **La Leyenda del Supermercado** *(muy fuerte, apagada por defecto)* | Botón **Supermercado** en la tienda: catálogo con los objetos y armas que podrías encontrar. Los encargos se ganan derrotando élites o jefes, cuestan un 50 % más (configurable) y llegan bloqueados a la siguiente tienda | Incluida, pendiente de prueba en el juego (solo un jugador) |
| **La Leyenda de las Cajas** | Al terminar la oleada, fusiona cajas por abrir en una caja legendaria: la primera pide 3, después 6 y 9 (configurable). Las cajas se juntan y sale la legendaria | Incluida, pendiente de prueba en el juego |
| **La Leyenda de la Fusión** *(muy fuerte, apagada por defecto)* | Al empezar la partida, fusiónate con otro personaje y suma sus efectos, a cambio de menos experiencia, precios más altos y más enemigos (recreación de GMO) | Incluida, pendiente de prueba en el juego |
| **El Taller de los Tatos** *(con BroEditor)* | «Tus tatos»: dibuja el aspecto de tu patata píxel a píxel (o importa un PNG), llévalo puesto en las partidas y úsalo como icono en BroEditor. Medidor de poder para ver si un personaje u objeto es demasiado fuerte. Para crear personajes y objetos se usa [BroEditor](https://steamcommunity.com/sharedfiles/filedetails/?id=3817655214) | Incluida, pendiente de prueba en el juego |
| **La Leyenda del Regalo** *(cooperativo)* | En la tienda, pulsa un arma u objeto propio → **Regalar** (junto a Reciclar): se lo das a otro jugador (también armas mecanizadas o malditas), que lo acepta con un choque de puños («¡Regalo de tu bro!»). El Tumor y los objetos ligados a mecánicas propias no se regalan | Incluida, pendiente de prueba en el juego |

## Instalación

### Steam Workshop
Cuando se publique: suscríbete en el Workshop de Brotato y abre el juego. No necesita ningún otro mod.

### Manual (pruebas locales)
La versión de Steam de Brotato **no lee la carpeta `mods`**: solo carga los ZIP que hay dentro de las carpetas de los mods del Workshop a los que estás suscrito. Para probar el ZIP sin publicarlo:

1. Genera el paquete (`python tools/build.py` → `dist/Caritato-LegendsCollection.zip`) o descárgalo de los artefactos de la CI.
2. Suscríbete a un mod pequeño de Brotato en el Workshop (o usa uno al que ya estés suscrito) y abre el juego una vez para que Steam lo descargue.
3. Copia el ZIP **sin descomprimir** dentro de la carpeta de ese mod: `<biblioteca de Steam>\steamapps\workshop\content\1942280\<número del mod>\`.
4. Abre Brotato: en «Mods» aparece **LegendsCollection** y en el menú principal, el botón **Caritatopc**.

En las versiones sin Steam (GOG, Epic) sí vale la carpeta `mods` de la instalación. Más detalle y diagnóstico en `docs/PRUEBAS.md`.

## Configuración en el juego

- Menú principal → botón **Caritatopc** (debajo de «Mods»).
- Durante una partida: pausa → **Caritatopc**.

La pantalla es una biblioteca: a la izquierda, una tarjeta por leyenda; a la derecha, su ficha con el interruptor, los ajustes y una línea que explica el ajuste seleccionado. Los valores se aplican al momento; «Guardar» los guarda en `%APPDATA%\Brotato\caritato_legends\settings.json`. Activar una leyenda que no estaba cargada requiere reiniciar Brotato, y la pantalla lo avisa.

## Compatibilidad

Desarrollado contra **Brotato 1.1.15.4** con **ModLoader 6.3.0** (el que trae el juego). Lo verificado y lo pendiente está en `docs/COMPATIBILIDAD.md`.

## Desarrollo

```bash
python tools/validate.py --gdparse      # manifiesto, leyendas, textos, rutas y sintaxis GDScript
python -m unittest discover -s tests/python -v
python tools/build.py                   # ZIP reproducible en dist/
```

La sintaxis GDScript se comprueba con `gdtoolkit` 3 (`pip install "gdtoolkit==3.6.0" "setuptools<81"`). Las pruebas del núcleo en GDScript se ejecutan en la CI con Godot 3.6 headless (`tools/run_gdscript_tests.py`).

Arquitectura y cómo añadir una leyenda: `docs/ARQUITECTURA.md`. Reglas de trabajo: `CLAUDE.md` y `AGENTS.md`. Página de Workshop y publicación: `docs/WORKSHOP.md`.

## Créditos y licencias

Cada leyenda declara su procedencia. Consulta `docs/LICENCIAS_Y_CREDITOS.md`. Brotato es propiedad de Blobfish Games; este repositorio no contiene archivos del juego.
