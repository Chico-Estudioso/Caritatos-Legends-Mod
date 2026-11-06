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
