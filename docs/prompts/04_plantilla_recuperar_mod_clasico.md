# Prompt 04: plantilla para recuperar un mod clásico

Copia este prompt para cada mod que quieras recuperar. Sustituye los campos entre corchetes. Trabaja **un mod por rama y Pull Request**.

---

Quiero investigar y, si es viable, recuperar este mod clásico para **Brotato Legends Collection**.

## Datos del mod

- Nombre: `[NOMBRE DEL MOD]`
- Autor original: `[AUTOR]`
- Workshop: `[URL O ID, SI EXISTE]`
- GitHub: `[URL, SI EXISTE]`
- Contenido: `[PERSONAJE / ARMA / OBJETO / MECÁNICA / ENEMIGO / JEFE / OTRO]`
- Nombre del módulo interno propuesto: `[ID_DEL_MODULO]`

## Antes de programar

1. Lee `CLAUDE.md`, `AGENTS.md`, `docs/ARQUITECTURA.md`, `docs/COMPATIBILIDAD.md`, `docs/CATALOGO_MODS.md` y `docs/LICENCIAS_Y_CREDITOS.md`.
2. Comprueba que estás en una rama independiente de `main` y que el árbol de trabajo está limpio. No sobrescribas cambios de otras tareas.
3. Investiga qué hacía realmente el mod: funcionalidades, contenido, estadísticas, dependencias, recursos, versión original y problemas conocidos.
4. Busca el código fuente original si está disponible. No confundas que esté disponible públicamente o gratis en Workshop con que su licencia permita redistribuirlo.
5. Revisa por separado la licencia del código y la de imágenes, audio, fuentes, traducciones y otros recursos.

## Puerta de licencias y permisos

Clasifica el resultado como una de estas opciones:
- `REUTILIZACIÓN PERMITIDA`: licencia comprobada y compatible con el uso previsto.
- `PERMISO OBTENIDO`: permiso del autor documentado y suficiente para modificar y redistribuir.
- `RECREACIÓN INDEPENDIENTE`: no se incorporará código ni recurso original; se estudiará una implementación propia que no copie material protegido.
- `BLOQUEADO`: no hay base suficiente para reutilizar ni una alternativa independiente clara.

Si la licencia no existe, no se entiende o no cubre la redistribución, no copies el contenido. Si hace falta permiso, detén esa parte y deja constancia de lo que debe autorizar el creador. No inventes permisos.

## Informe previo

Antes de escribir código, prepara un informe que explique:
- Qué hacía el mod.
- Qué partes queremos recuperar.
- Qué partes se pueden reutilizar legalmente.
- Qué partes requieren permiso o recreación.
- Qué API de Brotato utiliza.
- Qué cambios de la versión actual afectan al mod.
- Qué dependencias necesita.
- Qué conflictos puede tener con otros módulos.
- Qué pruebas hacen falta.

Si el estado de derechos impide continuar, no programes una copia. Actualiza el catálogo y explícame el bloqueo.

## Implementación

Cuando la vía de recuperación esté aprobada:

1. Implementa el contenido dentro de su módulo, siguiendo la arquitectura actual.
2. Usa IDs únicos y evita modificar otros módulos.
3. Respeta la configuración global: si el módulo está apagado, no debe registrar su contenido.
4. Mantén el comportamiento original en la medida permitida y técnicamente posible. Documenta cualquier cambio de estadísticas o mecánicas.
5. Aísla llamadas específicas de una versión del juego en la capa de compatibilidad cuando corresponda.
6. No añadas dependencias externas obligatorias sin mi aprobación.
7. Registra autores, enlaces, licencias y permisos en `docs/LICENCIAS_Y_CREDITOS.md`.

## Pruebas

Comprueba, según el tipo de contenido:
- Que el módulo carga y descarga según la configuración.
- Que los recursos existen y se cargan.
- Que no hay IDs duplicados.
- Que el contenido aparece donde debe.
- Que estadísticas, efectos y comportamiento funcionan.
- Que no hay errores conocidos en los registros.
- Que no rompe contenido vanilla ni módulos ya validados.

Distingue entre pruebas automáticas y pruebas manuales dentro de Brotato. No declares superado lo que no hayas ejecutado.

## Git y entrega

- Usa una rama `feat/recuperar-[nombre]`.
- Haz una PR pequeña para este mod, no mezcles otros mods en la misma PR.
- Actualiza `ROADMAP.md`, `CHANGELOG.md`, `docs/CATALOGO_MODS.md`, `docs/COMPATIBILIDAD.md` y `docs/LICENCIAS_Y_CREDITOS.md` según corresponda.
- Ejecuta las comprobaciones disponibles.
- Sube solo la rama de trabajo y abre una PR con la plantilla del repositorio, si GitHub CLI está configurado.
- No hagas push a `main`, no uses force-push y no fusiones la PR.

## Informe final

Indica qué se ha recuperado, qué se ha recreado, qué se ha omitido, el estado de los permisos, archivos modificados, pruebas ejecutadas, resultado dentro del juego y limitaciones pendientes.
---
