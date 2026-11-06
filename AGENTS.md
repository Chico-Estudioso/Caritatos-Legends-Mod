# AGENTS.md — Instrucciones para agentes

Estas reglas se aplican a Claude Code y a cualquier otro agente que trabaje en el repositorio.

1. Lee `CLAUDE.md` completo antes de modificar el proyecto. Sus reglas de trabajo prevalecen sobre las de `docs/prompts/`.
2. Consulta `ROADMAP.md` y los documentos de `docs/` relacionados con la tarea.
3. No inventes APIs ni compatibilidad: verifica contra Brotato 1.1.15.4 / ModLoader 6.3.0 o la versión vigente indicada en `docs/COMPATIBILIDAD.md`.
4. No copies código o recursos de terceros sin licencia compatible, permiso verificable o decisión expresa del propietario registrada en `docs/DECISIONES.md`.
5. Mantén cada leyenda dentro de su carpeta `modules/<id>/`. Lo compartido va en `core/`.
6. Todo entra en `main` mediante Pull Request pequeña; nada de pushes directos a `main`.
7. Las PR se pueden fusionar (squash) cuando la CI está en verde. Publicar en Steam Workshop requiere aprobación expresa del propietario.
8. Commits y PR a nombre del propietario, sin líneas de atribución a herramientas de IA.
9. Añade pruebas y distingue lo probado de lo pendiente de validación manual dentro de Brotato.
10. Actualiza `ROADMAP.md`, `CHANGELOG.md`, compatibilidad, catálogo y créditos cuando corresponda.
11. Responde y documenta en español; conserva los identificadores técnicos en inglés.

El propietario (Mauro, `Chico-Estudioso`) decide el alcance y las publicaciones, y ha delegado en los agentes la revisión y el merge de las Pull Requests.
