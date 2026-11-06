# Prompt 05: adaptación a una nueva actualización de Brotato

Ejecuta esta tarea cuando Brotato, ModLoader o una dependencia relevante reciba una actualización.

Versión anterior comprobada: `[VERSION ANTERIOR]`
Nueva versión objetivo: `[NUEVA VERSION]`
Notas oficiales del parche: `[ENLACE, SI EXISTE]`

## Objetivo

Comprobar qué partes de Brotato Legends Collection se han visto afectadas y adaptar únicamente lo necesario. No hagas una reescritura general ni cambies el equilibrio de contenido por una incompatibilidad técnica.

## Antes de modificar

1. Lee `CLAUDE.md`, `AGENTS.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/COMPATIBILIDAD.md`, `docs/ARQUITECTURA.md` y `docs/PRUEBAS.md`.
2. Comprueba la versión real del juego y del ModLoader disponible.
3. Lee las notas oficiales y contrástalas con los cambios reales que puedas verificar.
4. Revisa los registros de errores y los módulos que dependen de las APIs modificadas.
5. Crea un informe de impacto antes de tocar código.

## Informe de impacto

Para cada módulo, indica uno de estos estados:
- `COMPATIBLE Y PROBADO`.
- `NO PROBADO EN ESTA VERSIÓN`.
- `NECESITA ADAPTACIÓN`.
- `INCOMPATIBLE`.
- `BLOQUEADO POR DEPENDENCIA`.

Explica el motivo y señala las funciones, recursos o dependencias afectadas. No marques una versión como compatible por intuición.

## Adaptación

1. Prioriza corregir la capa de compatibilidad compartida cuando el cambio afecte a varios módulos.
2. Modifica un módulo concreto cuando el problema sea propio de ese módulo.
3. Conserva el comportamiento y equilibrio existentes salvo que el cambio del juego lo haga imposible. Documenta cualquier diferencia.
4. Si un módulo no puede cargarse con seguridad, desactívalo de forma controlada y explica el motivo.
5. No elimines contenido ni cambies sus permisos o créditos.
6. Añade pruebas de regresión para cada corrección.

## Pruebas

Ejecuta las pruebas automáticas disponibles y prueba en Brotato:
- Inicio del mod.
- Apertura de la configuración.
- Carga de módulos.
- Activación y desactivación.
- Contenido afectado por el parche.
- Combinaciones de módulos que puedan verse afectadas.

Separa claramente lo probado de lo pendiente de prueba manual.

## GitHub

- Trabaja en `fix/compatibilidad-[version]`.
- No trabajes sobre `main`.
- Una PR por conjunto coherente de correcciones; separa cambios independientes.
- Actualiza `COMPATIBILIDAD.md`, `CHANGELOG.md` y `ROADMAP.md`.
- Abre una PR con la plantilla del repositorio cuando esté lista.
- No hagas push a `main`, no uses force-push y no fusiones la PR.

## Entrega

Incluye el resumen del parche, módulos afectados, cambios realizados, pruebas ejecutadas, módulos que siguen desactivados o sin probar y recomendación sobre publicar o no una nueva versión.
---
