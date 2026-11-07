# Licencias, permisos y créditos

Registro de la procedencia de todo código, texto o recurso de la colección.

**Importante:** que un mod sea gratuito en Steam Workshop no implica que su contenido pueda copiarse y redistribuirse. Por defecto, las leyendas son **recreaciones independientes**: reproducen la idea o la mecánica con código, textos y nombres propios, sin copiar material del mod original.

## Código y recursos del proyecto

| Elemento | Autor | Licencia | Notas |
|---|---|---|---|
| Núcleo, interfaz, herramientas y leyendas | Mauro Serrano Hevia (Chico-Estudioso) | Pendiente de elegir por el propietario | Código original del proyecto |

## Contenido externo incluido

| Elemento | Autor | Enlace | Tipo | Licencia | Permiso documentado | Uso | Archivos |
|---|---|---|---|---|---|---|---|
| *(ninguno por ahora)* | | | | | | | |

## Mods que han inspirado leyendas (sin código copiado)

Se documentan al incorporar cada leyenda, con enlace al original y la confirmación de que no se ha copiado su material.

| Leyenda | Mods que la inspiran | Autor | Enlace | Qué se toma | Código copiado |
|---|---|---|---|---|---|
| La Leyenda del Anzuelo | Mod de anzuelo garantizado en la oleada 4 | Por identificar | Steam Workshop | La idea de garantizar el Anzuelo en una tienda concreta | No |
| La Leyenda del Anzuelo | Mod de probabilidad de anzuelo configurable | Por identificar | Steam Workshop | La idea de ajustar la probabilidad de cada anzuelo | No |
| La Leyenda del Anzuelo | Guaranteed Curse | Xterionix | https://github.com/Xterionix/BrotatoMod-GuaranteedCurse | Referencia de la mecánica (cubierta con la probabilidad al 100 %) | No (repositorio sin licencia) |
| La Leyenda del Anzuelo | ImperfectHook | mojimoon | https://github.com/mojimoon/BrotatoMods | Referencia de la mecánica | No (repositorio sin licencia) |
| La Leyenda de la Cosecha Eterna | No Harvesting Decay | Windows98 | Steam Workshop 3120330525 | La idea de anular la pérdida de recolección | No |
| La Leyenda de la Cosecha Eterna | Infinite Bank and Harvesting | Hypermarine_AuT | Steam Workshop | La idea de mantener la Hucha y la recolección en infinito | No |
| La Leyenda de la Cosecha Eterna | Piggy Bank And Harvest Work After 20 Waves | dreadhead | Steam Workshop 3638873783 | Referencia de la mecánica | No |
| La Leyenda de la Cosecha Eterna | Endless-less | dami | Steam Workshop 2938652633 | Referencia de la mecánica | No |
| La Leyenda del Mercader | FreeRerolls | Por identificar | Steam Workshop | La idea de rerolls gratis | No |
| La Leyenda del Mercader | SIFD's Mod | SIFD | Steam Workshop | La idea de precios y rerolls sin inflación por oleada | No |
| La Leyenda del Supermercado | Supermarket (超市) | duyang97 | Steam Workshop 2993532272 (retirado) | La idea de un botón en la tienda para elegir artículos | No |
| La Leyenda del Regalo | Idea de Mauro (leyenda original) | — | — | QuickEquip (Oudstand) sirvió para confirmar la API de añadir y quitar objetos y armas en Brotato 1.2 | No |
| La Leyenda de las Cajas | Idea de Mauro (leyenda original) | — | — | BroEditor (mojimoon) y NewContentLoader (Yoko) sirvieron para confirmar la API de las cajas por abrir en la 1.2 | No (BroEditor sin licencia; NewContentLoader con licencia restringida: solo se leyó) |
| La Leyenda de la Fusión | Genetically Modified Overkill (GMO) | Flabort | https://github.com/Flabort/Genetically-Engineered-Overkill | La idea de jugar con dos personajes con penalizaciones y sus valores por defecto | No (repositorio sin licencia) |
| El Taller de los Tatos | BroEditor | Mojimoon | https://steamcommunity.com/sharedfiles/filedetails/?id=3817655214 | Se usa junto a Caritatopc (no se incluye): el Taller guarda iconos en su carpeta y enlaza su página | No (repositorio sin licencia) |
| La Leyenda de la Cosecha Eterna | Stronger Harvesting | CommanderAstern | https://github.com/CommanderAstern/brotato-stronger-harvesting | Referencia de la opción de crecer en infinito | No (repositorio sin licencia) |

## Herramientas y dependencias del juego

- **Brotato** © Blobfish Games. El repositorio no contiene archivos del juego. Las extensiones solo referencian rutas `res://` del juego en tiempo de ejecución.
- **Godot Mod Loader 6.3.0** (CC0 1.0), integrado en Brotato. El mod usa su API pública; no se redistribuye.
- **gdtoolkit** (MIT): solo para comprobar sintaxis en desarrollo y CI; no forma parte del paquete.

## Material de referencia

Para verificar la API real se ha consultado localmente el código descompilado de Brotato (1.1.15.4 y 1.1.14.5 con Abyssal Terrors) publicado por terceros en GitHub. Ese material **no** se ha copiado al repositorio: solo se registran nombres de funciones, rutas y comportamiento en `docs/COMPATIBILIDAD.md` y `tools/game_scripts.txt` (lista de rutas).

## Reglas

- Revisar por separado código y recursos.
- Respetar atribuciones, avisos y obligaciones de cada licencia (por ejemplo, Apache-2.0 exige conservar el aviso de licencia y señalar los cambios).
- Guardar referencia al permiso del autor cuando sea necesario.
- Si no hay licencia clara ni permiso, no redistribuir; marcar como recreación o pendiente.
- No incluir archivos propietarios del juego.
