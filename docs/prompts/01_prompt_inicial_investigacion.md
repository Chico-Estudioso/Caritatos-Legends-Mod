# Prompt 01: revisión inicial, investigación y arquitectura

Pega este prompt en Claude Code desde la raíz del repositorio. Activa Plan Mode si lo utilizas.

---

Hola. Vamos a desarrollar **Brotato Legends Collection**, un mod comunitario para Brotato.

Quiero recuperar mods clásicos que han quedado obsoletos con las actualizaciones del juego, adaptarlos y reunirlos dentro de **un único mod instalable desde Steam Workshop**. El jugador podrá configurar qué módulos de contenido quiere activar.

El enfoque de contenido será híbrido:
- Reutilizaremos código y recursos de otros creadores únicamente cuando su licencia permita expresamente la modificación y redistribución o tengamos permiso verificable.
- Cuando no exista autorización, no copies su código ni sus recursos. Investiga la funcionalidad y valora una implementación independiente con código, nombres, textos y recursos propios, sin reproducir material protegido.
- Mantén los créditos y la procedencia de cada contenido.

Todo el proyecto, la documentación y tus respuestas deben estar en español. Mantén en inglés los identificadores, nombres de funciones, clases y términos técnicos que sea conveniente conservar.

## Antes de escribir código

1. Lee completos `CLAUDE.md`, `AGENTS.md`, `README.md`, `ROADMAP.md` y los documentos de `docs/`.
2. Revisa el estado del repositorio: rama actual, cambios sin guardar, últimos commits y remotos configurados. No sobrescribas ni descartes cambios existentes.
3. Comprueba `git config user.name`, `git config user.email` y el estado de autenticación de GitHub CLI (`gh auth status`, si está instalado). Informa de los resultados. No cambies la identidad ni la cuenta.
4. Comprueba qué versión de Brotato está instalada, qué versión de ModLoader utiliza el entorno disponible y cómo está organizada una instalación de mod válida. No des por supuesto que la documentación de versiones anteriores sigue vigente.
5. Investiga la documentación y los repositorios actuales de la comunidad, empezando por:
   - https://github.com/BrotatoMods
   - https://github.com/BrotatoMods/Brotato-ContentLoader
   - https://github.com/BrotatoMods/Brotato-ModLoader
   - https://steamcommunity.com/app/1942280/workshop/
   - https://brotato.wiki.spellsandguns.com/Modding_Notes
6. Investiga también los mods o frameworks de configuración disponibles para Brotato, incluido Mod Options si sigue siendo relevante. Comprueba su compatibilidad real, dependencias, licencia y posibilidades de integración.
7. Investiga ContentLoader y otras herramientas de contenido. Comprueba su versión, API, dependencias, compatibilidad y licencia. No copies ni incorpores código de terceros sin permiso suficiente.

## Decisiones que debes respetar

- El jugador instalará un único mod principal.
- Los contenidos estarán separados internamente por módulos.
- Los módulos desactivados no deben registrar sus contenidos.
- Si activar o desactivar contenido requiere reiniciar el juego, la interfaz debe indicarlo.
- No queremos depender de otro mod de Workshop de forma obligatoria si eso obliga al jugador a instalarlo por separado.
- Aun así, no reinventes herramientas existentes sin investigarlas: recomienda aprovechar una solución cuando sea compatible y su uso esté permitido.
- No diseñes una arquitectura compleja que no necesitemos.

## Investigación de mods clásicos

Prepara un catálogo inicial de posibles mods que merezca la pena recuperar. Para cada uno, registra cuando sea posible:
- Nombre y autor.
- Enlace de Workshop y/o GitHub.
- Qué contenido añade.
- Última actualización conocida.
- Si se puede acceder al código fuente.
- Licencia del código y de los recursos.
- Si hace falta pedir permiso.
- Dependencias.
- Compatibilidad conocida con la versión actual.
- Dificultad estimada de adaptación.

No descargues ni integres automáticamente contenido de terceros. Si una licencia no está clara, marca el contenido como `PENDIENTE DE PERMISO`.

## Documentos que debes preparar o actualizar

- `docs/ARQUITECTURA.md`: propuesta sencilla de la arquitectura.
- `docs/DECISIONES.md`: decisiones técnicas con fecha y motivo.
- `docs/COMPATIBILIDAD.md`: versión de Brotato, ModLoader y estado comprobado.
- `docs/CATALOGO_MODS.md`: lista de candidatos a recuperar.
- `docs/LICENCIAS_Y_CREDITOS.md`: licencias, permisos, autores y recursos.
- `docs/PRUEBAS.md`: cómo se comprobará el funcionamiento.
- `ROADMAP.md`: fases, tareas y criterios para avanzar.

No rellenes documentos con texto genérico. Incluye datos comprobados y marca lo que quede pendiente.

## Git y seguridad

- No trabajes sobre `main`.
- No hagas commits ni push durante esta fase de investigación.
- No cambies la identidad de Git.
- No instales software ni modifiques la instalación del juego sin consultarme.
- No descargues recursos protegidos ni copies archivos del juego al repositorio.
- No hagas `reset --hard`, `push --force` ni borres ramas.

## Entrega

Al terminar, presenta:
1. Qué versión de Brotato y ModLoader has podido verificar.
2. Cómo se instala y estructura un mod válido actualmente.
3. Qué opciones existen para configurar módulos dentro del juego.
4. Si ContentLoader u otras herramientas pueden aprovecharse y bajo qué condiciones.
5. La arquitectura que recomiendas para un único mod.
6. Los primeros mods que propones recuperar y el estado de sus permisos.
7. Riesgos técnicos y dudas que requieren mi decisión.
8. El contenido propuesto para cada fase del ROADMAP.

No empieces a implementar todavía. Primero quiero revisar la investigación y aprobar la arquitectura. Si encuentras contradicciones, explícitalas y espera mi aprobación antes de cambiar decisiones importantes.
---
