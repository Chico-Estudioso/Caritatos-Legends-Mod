# Kit de arranque — Brotato Legends Collection

Este kit prepara el repositorio y los prompts para desarrollar **Brotato Legends Collection** con Claude Code y GitHub.

## Decisiones ya tomadas

- **Distribución:** un único mod en Steam Workshop.
- **Alcance:** recuperar y adaptar mods clásicos de Brotato.
- **Contenido original:** enfoque híbrido. Reutilizar código o recursos solo cuando la licencia lo permita o exista permiso del autor; en los demás casos, valorar una recreación independiente.
- **Configuración:** el jugador podrá activar y desactivar módulos desde el juego. Si el registro de contenido requiere reiniciar, se indicará claramente.
- **Idioma del proyecto:** documentación, prompts, mensajes y textos de interfaz en español. Identificadores y código en inglés cuando sea la convención técnica habitual.
- **Repositorio:** GitHub. `main` protegida; trabajo mediante ramas y Pull Requests.

## Orden de uso

1. Crea un repositorio vacío en GitHub. Es recomendable que sea **privado al principio**, mientras se investiga el contenido y se revisan los permisos.
2. Clónalo en tu PC.
3. Copia el contenido de `repo_files/` a la raíz del repositorio, incluidos `.claude/` y `.github/`.
4. En GitHub, configura la protección de `main`: exigir Pull Request para integrar cambios y bloquear force-push. Cuando exista CI, añade sus comprobaciones como requisitos de la PR.
5. Comprueba tu identidad de Git con `git config user.name` y `git config user.email`. No la cambies desde Claude sin decidirlo tú.
6. Abre Claude Code en la raíz del repositorio y ejecuta los prompts de `prompts/` en orden. No avances de fase hasta revisar y aprobar la PR anterior y actualizar el ROADMAP.

## Prompts incluidos

- `01`: revisión inicial e investigación. No debe implementar todavía.
- `02`: arranque técnico y primer mod mínimo instalable.
- `03`: núcleo modular y configuración dentro del juego.
- `04`: plantilla para recuperar un mod clásico, uno por tarea.
- `05`: adaptación cuando Brotato reciba una actualización.
- `06`: preparación de una versión para Steam Workshop.
- `99`: plantilla para tareas pequeñas fuera del roadmap.

## Herramientas

Necesitarás Git, una cuenta de GitHub y Claude Code. GitHub CLI (`gh`) es útil para crear Pull Requests desde terminal. Brotato debe estar instalado para las pruebas reales.

No instales herramientas, descargues dependencias externas, cambies ajustes de Windows ni modifiques cuentas sin que Claude te explique qué va a hacer y tú lo autorices.

## Regla de Git

Nunca se trabaja directamente en `main`:

- `feat/<nombre>` para funcionalidades.
- `fix/<nombre>` para correcciones.
- `chore/<nombre>` para mantenimiento.
- `docs/<nombre>` para documentación.

Una tarea = una rama = una Pull Request pequeña. Claude puede subir la rama y abrir la PR si `gh` está configurado y la tarea lo pide, pero **no puede fusionarla**. Tú revisas y decides cuándo se integra.

No se permite `git push` a `main`, `git push --force`, `git reset --hard` ni borrar ramas con trabajo sin autorización expresa.
