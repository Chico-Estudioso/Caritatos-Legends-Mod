# ROADMAP — Caritatos Legends

Estados: `[ ]` pendiente, `[~]` en curso, `[x]` terminado, `[!]` bloqueado. Se actualiza al cerrar cada PR.

## Fase 0 — Investigación y decisiones
- [x] Verificar versión de Brotato y ModLoader (1.1.15.4 / 6.3.0, verificado en código).
- [x] Confirmar estructura, manifiesto e instalación de un mod actual.
- [x] Investigar ContentLoader y Mod Options.
- [x] Decidir herramientas sin dependencias obligatorias (pantalla propia, sin Mod Options).
- [x] Catálogo inicial de mods clásicos (`docs/CATALOGO_MODS.md`).
- [x] Revisar licencias de los primeros candidatos.
- [x] Arquitectura documentada (`docs/ARQUITECTURA.md`).

## Fase 1 — Repositorio y mod mínimo
- [x] Estructura del proyecto y del paquete.
- [x] Manifiesto y punto de entrada para ModLoader 6.3.0.
- [x] Empaquetado reproducible (`tools/build.py`).
- [x] Validaciones automáticas y CI.
- [x] Documentación de instalación y diagnóstico (`docs/PRUEBAS.md`).
- [~] Comprobar dentro de Brotato que se detecta e inicializa (prueba manual; primer intento en Steam 1.2.0.1 sin cargar porque se usó la carpeta `mods`, ver `docs/PRUEBAS.md`).

## Fase 2 — Núcleo modular y configuración
- [x] Registro de leyendas con ids únicos y validación de definiciones.
- [x] Dependencias, conflictos y ciclos.
- [x] Activación/desactivación persistente y recuperación de configuración inválida.
- [x] Pantalla de configuración en el menú principal y en el de pausa (botón **Caritatopc**, formato biblioteca).
- [x] Aviso de reinicio y estado por leyenda.
- [x] Pruebas del núcleo (GDScript en CI) y de herramientas (Python).
- [ ] Prueba manual de la pantalla con ratón, teclado y mando.

## Fase 3 — Leyendas pedidas por Mauro
- [x] La Leyenda del Anzuelo: anzuelo garantizado desde la oleada elegida y probabilidad de maldición configurable.
- [ ] Prueba manual de La Leyenda del Anzuelo (lista en `docs/CATALOGO_MODS.md`).
- [x] La Leyenda de la Cosecha Eterna: pérdida de recolección configurable tras la oleada 20 y hucha en modo infinito.
- [ ] Prueba manual de La Leyenda de la Cosecha Eterna (lista en `docs/CATALOGO_MODS.md`).

## Fase 4 — Más leyendas clásicas
- [x] Priorizar candidatos del catálogo por interés, estado técnico y licencia.
- [x] La Leyenda del Mercader (FreeRerolls + SIFD's Mod).
- [x] La Leyenda del Supermercado (Supermarket), versión de un jugador.
- [ ] Supermercado en cooperativo.
- [x] La Leyenda del Regalo (cooperativo): regalar objetos y armas.
- [ ] Prueba manual de La Leyenda del Regalo en cooperativo.
- [ ] Mejora de cajas a legendaria (idea de Mauro: a las 3 cajas, luego cada 6 y cada 9) — pendiente de valorar.
- [ ] Siguientes candidatas: Rainbow Crate (Apache-2.0), Second Chance (MIT), contador de rerolls, medidor de daño.
- [ ] Una leyenda por PR, con procedencia y pruebas.

## Fase 5 — Integración y pruebas
- [ ] Probar leyendas individualmente y en combinación dentro de Brotato.
- [ ] Revisar conflictos con mods populares de Workshop.
- [ ] Revisar rendimiento y registros.

## Fase 6 — Publicación
- [x] Versión candidata 0.2.0 y borrador de la página de Workshop (`docs/WORKSHOP.md`).
- [ ] Revisar créditos y licencias de todo lo incluido.
- [ ] Prueba de instalación limpia.
- [ ] Descripción, imágenes e instrucciones de Workshop.
- [ ] Publicar con aprobación de Mauro.

## Mantenimiento
- [x] Adaptación a Brotato 1.2 con la información pública (orden de instalación de extensiones, caché de objetos, conjuntos de objetos).
- [ ] Prueba en Brotato 1.2 de todas las leyendas.
- [ ] Revisar cada actualización de Brotato (prompt `docs/prompts/05_...`).
- [ ] Regenerar `tools/game_scripts.txt` y la matriz de compatibilidad.

## Riesgos abiertos
- Cambios internos de Brotato que rompan las extensiones (mitigado con `core/compat.gd` y la validación de rutas).
- Mods del Workshop que reemplazan las mismas funciones sin llamar al original.
- Nada se ha probado todavía dentro del juego desde este entorno: cada versión necesita una prueba manual antes de publicarse.
