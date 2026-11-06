# Prompt 02: Fase 0, repositorio y primer mod instalable

Ejecuta la Fase 0 de `ROADMAP.md` en una rama `feat/fase-0-arranque`. Lee antes `CLAUDE.md`, `AGENTS.md` y los documentos de `docs/`. Utiliza la arquitectura aprobada tras la Fase inicial.

## Objetivo

Dejar un proyecto mínimo, ordenado y verificable que Brotato pueda detectar y cargar. Todavía no recuperes mods de terceros ni añadas contenido grande.

## Antes de empezar

1. Comprueba que el árbol de trabajo está limpio y que no hay cambios del usuario que puedan perderse.
2. Comprueba que estás en una rama distinta de `main`. Si no existe la rama indicada, créala desde la versión actualizada de `main`.
3. Comprueba `git config user.name` y `git config user.email`. No cambies estos valores.
4. Resume las tareas y los criterios de aceptación antes de modificar archivos.

## Tareas

1. Crea la estructura mínima del proyecto según la arquitectura aprobada. No crees carpetas o capas que todavía no tengan una función real.
2. Añade los metadatos y archivos de entrada exigidos por la versión actual de Brotato ModLoader. Verifica los nombres y formatos con documentación o ejemplos actuales.
3. Implementa un mod mínimo que se inicialice y deje un mensaje identificable en el registro de diagnóstico.
4. Prepara una estructura inicial para el código y los recursos propios del mod.
5. Añade un procedimiento reproducible para empaquetar el mod en el formato que utiliza ModLoader.
6. Añade validaciones automáticas sencillas para comprobar los archivos obligatorios, las rutas de recursos y el formato del paquete.
7. Documenta cómo instalar el mod localmente, cómo activar el ModLoader y dónde consultar los registros.
8. Añade una comprobación de CI en GitHub Actions solo para tareas que puedan ejecutarse de forma fiable en GitHub. No intentes lanzar Brotato en CI si no existe un entorno adecuado.

## Reglas

- No añadas dependencias si no son necesarias.
- No copies código de ContentLoader, Mod Options u otros mods.
- No introduzcas todavía el sistema completo de módulos ni la interfaz de configuración.
- No incluyas archivos del juego, ejecutables, DLL, recursos propietarios ni contenido de otros mods en GitHub.
- Si una comprobación requiere iniciar Brotato, márcala como prueba manual y no la declares superada sin ejecutarla.

## GitHub

- Haz commits pequeños con Conventional Commits en español, por ejemplo `chore: prepara estructura inicial del mod` o `feat: añade mod mínimo de prueba`.
- Actualiza `ROADMAP.md` y `CHANGELOG.md`.
- Comprueba lint/validaciones/tests/build disponibles.
- Sube únicamente la rama `feat/fase-0-arranque` y abre una Pull Request con la plantilla de `.github/`, si `gh` está disponible y autorizado.
- Nunca hagas push a `main`, nunca fuerces el push y no fusiones la PR.

## Criterios de aceptación

- Brotato ModLoader detecta el paquete.
- El mod se inicializa en el juego sin errores conocidos.
- El procedimiento de empaquetado funciona.
- Las validaciones automáticas pasan.
- La documentación permite instalarlo y comprobarlo manualmente.
- La PR contiene resumen, pruebas y pasos para probarlo.

Al terminar, dime qué se ha probado realmente, qué queda pendiente de probar dentro del juego y cómo puedo comprobarlo yo.
---
