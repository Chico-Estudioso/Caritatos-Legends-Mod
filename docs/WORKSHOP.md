# Steam Workshop

Borrador de la página de Workshop y pasos de publicación. **No se publica nada sin la aprobación de Mauro**, y antes hay que completar las pruebas manuales de `docs/PRUEBAS.md` y `docs/CATALOGO_MODS.md`.

## Antes de publicar

- [ ] Pruebas manuales del núcleo y de cada leyenda superadas en la versión actual de Brotato.
- [ ] `docs/COMPATIBILIDAD.md` actualizado con la versión probada (y `compatibility.status: "tested"` en cada `module.json` probado).
- [ ] ZIP generado por la CI o con `python tools/build.py` (estructura `mods-unpacked/Caritato-LegendsCollection/`).
- [ ] Imagen de portada propia (sin recursos del juego ni de otros mods).
- [ ] Créditos revisados en `docs/LICENCIAS_Y_CREDITOS.md`.

## Descripción (BBCode de Steam)

```text
[h1]Caritatos Legends — Brotato Legends Collection[/h1]
Un único mod que recupera mods clásicos de Brotato («leyendas») y te deja elegir desde el propio juego cuáles activas y con qué valores. No necesita ningún otro mod.

[h2]Leyendas incluidas[/h2]
[list]
[*][b]La Leyenda del Anzuelo[/b] (Abyssal Terrors): el Anzuelo aparece garantizado en la tienda de la oleada que elijas (por defecto, la 4) y puedes fijar la probabilidad de maldición de cada anzuelo.
[*][b]La Leyenda de la Cosecha Eterna[/b]: en el modo infinito eliges cuánta recolección se pierde tras la oleada 20 (por defecto, nada), si sigue creciendo como antes y si la Hucha sigue funcionando.
[*][b]La Leyenda del Mercader[/b]: precio de artículos y rerolls en porcentaje (0 % = rerolls gratis) y opción de que no suban con las oleadas.
[*][b]La Leyenda del Supermercado[/b]: botón en la tienda con un catálogo de los objetos y armas que podrías encontrar; el que elijas aparece en tu tienda.
[/list]

[h2]Configuración[/h2]
Menú principal → [b]Leyendas[/b] (también desde la pausa durante una partida). Los valores se aplican al momento. Activar una leyenda que estaba apagada al abrir el juego requiere reiniciar Brotato; la pantalla lo avisa.

[h2]Compatibilidad[/h2]
Brotato 1.1.15.4 con el ModLoader 6.3.0 del juego. Puede chocar con mods que cambien las mismas mecánicas (tienda, recolección del modo infinito, precios).

[h2]Créditos[/h2]
Recreaciones independientes inspiradas en: Supermarket (duyang97), FreeRerolls, SIFD's Mod (SIFD), No Harvesting Decay (Windows98), Infinite Bank and Harvesting (Hypermarine_AuT), Piggy Bank And Harvest Work After 20 Waves (dreadhead), Endless-less (dami), Guaranteed Curse (Xterionix) y los mods del Anzuelo de la comunidad. Gracias a todos sus autores.

Código: https://github.com/Chico-Estudioso/Caritatos-Legends-Mod
```

## English summary

```text
[h1]Caritatos Legends — Brotato Legends Collection[/h1]
One mod that brings back classic Brotato mods ("legends"), each one toggleable and configurable from the in-game Legends menu. No other mods required.
[list]
[*][b]Legend of the Fish Hook[/b] (Abyssal Terrors): guaranteed Fish Hook in the shop of your chosen wave (default 4) and custom curse chance per hook.
[*][b]Legend of the Eternal Harvest[/b]: choose how much harvesting is lost per endless wave (default none), keep it growing, keep the Piggy Bank working.
[*][b]Legend of the Merchant[/b]: item and reroll price percentages (0% = free rerolls) and no per-wave inflation.
[*][b]Legend of the Supermarket[/b]: shop button with a catalog of items and weapons; your pick appears in your shop.
[/list]
```

## Publicación

1. Mauro aprueba la versión candidata.
2. Se sube el ZIP con la herramienta de subida al Workshop que use Brotato en ese momento (procedimiento a documentar la primera vez que se publique).
3. Se etiqueta la versión en GitHub (`v<versión>`) y se mueve la sección `[Sin publicar]` del `CHANGELOG.md`.
