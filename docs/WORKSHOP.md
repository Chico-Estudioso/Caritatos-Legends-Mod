# Steam Workshop

Cómo se publica Caritatopc en el Workshop de Brotato. **No se publica nada sin la aprobación de Mauro**, y antes hay que completar las pruebas manuales de `docs/PRUEBAS.md` y `docs/CATALOGO_MODS.md`.

## Antes de publicar

- [ ] Pruebas manuales del núcleo y de cada leyenda superadas en la versión actual de Brotato.
- [ ] `docs/COMPATIBILIDAD.md` actualizado con la versión probada (y `compatibility.status: "tested"` en cada `module.json` probado).
- [ ] Créditos revisados en `docs/LICENCIAS_Y_CREDITOS.md`.
- [ ] La cuenta de Steam que publica ha gastado al menos 5 $ en Steam (requisito de Valve para publicar en el Workshop).

## Qué se sube

La CI prepara el artefacto **`Caritatopc-Workshop`** (también con `python tools/build.py --workshop dist/workshop`):

| Archivo | Para qué |
|---|---|
| `Caritatopc - Brotato Legends Collection.zip` | El mod. El Workshop Uploader usa **el nombre del archivo como título**, por eso el ZIP se llama así. Dentro, la carpeta sigue siendo `mods-unpacked/Caritato-LegendsCollection/`. |
| `preview.png` | Portada de 512×512, dibujada por la CI con piezas del propio mod (`tests/ui/capture.gd`), sin recursos del juego. Se guarda en `workshop/preview.png`. |
| `description_es.txt` / `description_en.txt` | Descripción en BBCode para pegar en la página del Workshop. Se editan en `workshop/`. |

## Primera publicación (la hace Mauro con su cuenta)

1. En Steam: clic derecho en **Brotato → Propiedades → Betas** y elige la rama **modding**. Deja que se actualice.
2. Abre Brotato **desde Steam**: ahora ofrece abrir el **Workshop Uploader** (GodotWorkshopUtility). No abras el `.exe` directamente: solo funciona lanzado desde Steam.
3. En el uploader:
   - **Mod zip**: `Caritatopc - Brotato Legends Collection.zip`.
   - **Image**: `preview.png`.
   - **Workshop ID**: déjalo **vacío** (la primera subida crea el objeto).
4. Cuando termine, abre la página nueva del Workshop:
   - Pega `description_es.txt` en la descripción (y, si quieres, el resumen en inglés de `description_en.txt` al final).
   - El objeto empieza **oculto**: déjalo así para probarlo antes.
5. Vuelve a la rama **Ninguna** en Betas para jugar con el juego normal.
6. **Suscríbete a tu propio objeto** y comprueba que funciona. Borra la copia de prueba que pusiste en la carpeta de otro mod (`steamapps/workshop/content/1942280/<otro mod>/Caritato-LegendsCollection.zip`) para no cargar dos.
7. Si todo va bien, cambia la visibilidad a **Pública**.
8. Apunta el número del objeto (el `id=` de la URL) aquí y en `README.md`.

## Actualizaciones

1. Descarga el artefacto `Caritatopc-Workshop` de la última ejecución de la CI en `main`.
2. Rama **modding** → Workshop Uploader → mismo ZIP y portada, y en **Workshop ID** el número del objeto.
3. Añade una nota de cambios en la página (resumen de `CHANGELOG.md`) y vuelve a la rama **Ninguna**.
4. Etiqueta la versión en GitHub (`v<versión>`).

## Procedencia de este procedimiento

Pasos del Workshop Uploader de Brotato tal como los documenta otro mod publicado (`MattieTK/brotato-extended-coop-8`, `workshop/UPLOAD_INSTRUCTIONS.md`), que remite a la guía oficial de modding de Brotato en Steam. La herramienta es la Godot Workshop Utility de Blobfish (`Blobfish-Games/godot-workshop-utility`). Si el uploader cambia, se actualiza esta página la primera vez que se publique.
