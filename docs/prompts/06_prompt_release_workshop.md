# Prompt 06: preparación de una versión para Steam Workshop

Prepara una versión candidata de Brotato Legends Collection. No publiques nada en Steam Workshop sin mi aprobación expresa.

## Antes de preparar la versión

1. Lee `CLAUDE.md`, `AGENTS.md`, `ROADMAP.md`, `CHANGELOG.md`, `docs/COMPATIBILIDAD.md`, `docs/LICENCIAS_Y_CREDITOS.md` y `docs/PRUEBAS.md`.
2. Comprueba la rama, el estado del repositorio y las PR pendientes.
3. Comprueba que el árbol de trabajo está limpio y que la versión candidata parte de una rama actualizada.
4. Revisa que todos los módulos incluidos tengan un estado de permisos conocido.

## Revisión de contenido

- Ningún módulo bloqueado por permisos puede entrar en el paquete.
- Los créditos y licencias deben estar completos.
- No incluir archivos del juego ni recursos de terceros sin autorización.
- No incluir herramientas de desarrollo que no necesite el jugador.
- La configuración por defecto debe ser segura y coherente.
- Los módulos experimentales deben aparecer claramente identificados o quedar desactivados por defecto.

## Revisión técnica

- Validar metadatos y estructura del paquete.
- Comprobar rutas y referencias a recursos.
- Buscar IDs duplicados.
- Ejecutar lint, tests, validaciones y build disponibles.
- Instalar el ZIP en un entorno de prueba limpio y comprobar que ModLoader lo detecta.
- Abrir Brotato y comprobar inicio, configuración, módulos activados y módulos desactivados.
- Revisar los registros de errores.

No declares superada una prueba manual que no hayas realizado.

## Documentación de versión

Actualiza:
- `CHANGELOG.md`.
- `README.md` con instrucciones de instalación y configuración.
- `docs/COMPATIBILIDAD.md`.
- `ROADMAP.md`.
- Notas de créditos y licencias si hay cambios.

Prepara una descripción para Workshop en español con:
- Qué incluye el mod.
- Cómo activar y desactivar módulos.
- Si es necesario reiniciar el juego.
- Versión de Brotato y ModLoader probada.
- Créditos y enlaces a creadores originales.
- Problemas conocidos.

## Git y publicación

- Prepara una rama `release/[version]` o utiliza el proceso de release acordado en el repositorio.
- No hagas push a `main`.
- No uses force-push.
- No fusiones PRs.
- No publiques ni actualices Steam Workshop sin mi aprobación.
- Deja el ZIP candidato y las notas de publicación listos para revisión.

## Informe final

Indica la versión candidata, contenido incluido, módulos excluidos y motivos, pruebas realizadas, pruebas pendientes, ZIP generado y pasos manuales que debo realizar para publicar.
---
