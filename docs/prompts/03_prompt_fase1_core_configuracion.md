# Prompt 03: Fase 1, núcleo modular y configuración dentro del juego

Ejecuta la Fase 1 de `ROADMAP.md` en una rama `feat/core-configuracion`. Antes, lee `CLAUDE.md`, `AGENTS.md`, `docs/ARQUITECTURA.md`, `docs/DECISIONES.md`, `docs/COMPATIBILIDAD.md` y `docs/PRUEBAS.md`.

## Objetivo

Construir la base que permitirá incluir muchos contenidos dentro de un único mod y que el jugador pueda decidir qué módulos quiere activar.

## Tareas

### 1. Registro de módulos

Implementa un registro central y sencillo. Cada módulo debe declarar como mínimo:
- ID único.
- Nombre visible.
- Descripción.
- Categoría.
- Versión interna.
- Estado activado/desactivado.
- Dependencias internas, si existen.
- Estado de compatibilidad.

Comprueba IDs duplicados, dependencias inexistentes y conflictos declarados. No permitas que un módulo desactivado registre su contenido.

### 2. Configuración persistente

Implementa el guardado de preferencias usando el mecanismo adecuado para Brotato/ModLoader, una vez verificado.

Debe permitir:
- Guardar los módulos que el jugador ha activado.
- Cargar la configuración al iniciar el juego.
- Crear valores por defecto si todavía no hay configuración.
- Recuperarse de una configuración inválida sin bloquear el inicio.
- Mantener la configuración entre actualizaciones del mod.

No guardes preferencias en la carpeta de instalación si existe una ubicación de usuario adecuada.

### 3. Interfaz de configuración

Implementa una pantalla o apartado de configuración dentro del juego que permita:
- Ver las categorías disponibles.
- Activar/desactivar cada módulo.
- Consultar una descripción breve.
- Ver avisos de módulos incompatibles o con dependencias pendientes.
- Restaurar los valores por defecto.
- Guardar los cambios.

Si el juego necesita reiniciarse para registrar o retirar contenido, muestra un aviso claro. No simules que el contenido se descarga de una partida en curso si técnicamente no es seguro.

### 4. Uso de frameworks existentes

Antes de crear una interfaz propia completa, revisa el resultado de la investigación sobre Mod Options y otras soluciones.

Puedes reutilizar una herramienta si:
- Funciona con la versión objetivo.
- Su licencia permite el uso previsto o tenemos permiso.
- No obliga al jugador a instalar otro mod de Workshop por separado, salvo que yo lo apruebe expresamente.
- No introduce una dependencia que comprometa la colección.

Si no cumple estas condiciones, implementa la configuración necesaria dentro de nuestro mod, sin copiar código de terceros.

### 5. Módulos de demostración

Crea dos o tres módulos de prueba con contenido original y sencillo. Sirven para demostrar el registro y la configuración; no deben contener material de otros creadores.

Comprueba que:
- Se registran cuando están activados.
- No se registran cuando están desactivados.
- La configuración persiste al reiniciar.
- Un error controlado en un módulo se identifica correctamente.

## Pruebas

Añade pruebas automáticas donde sea posible para el registro, IDs, dependencias y lectura/escritura de configuración.

Haz pruebas dentro del juego para la interfaz y el registro real. No marques como validado nada que no hayas ejecutado.

## GitHub

- Una tarea concreta por PR; si hace falta, divide la fase en varias PR pequeñas.
- Rama `feat/core-configuracion` o ramas más específicas creadas desde `main` actualizada.
- No trabajes sobre `main`.
- Actualiza `ROADMAP.md`, `CHANGELOG.md` y `docs/DECISIONES.md` si has tomado decisiones nuevas.
- Ejecuta las pruebas disponibles.
- Sube la rama y abre PR con la plantilla del repositorio cuando esté lista.
- No fusiones la PR ni hagas push a `main`.

## Criterios de aceptación

- El registro identifica los módulos disponibles.
- La interfaz permite activar y desactivar módulos.
- La configuración se guarda y se recupera.
- Los módulos desactivados no registran contenido.
- Los errores se muestran en los registros sin impedir innecesariamente el funcionamiento de los demás módulos.
- La instalación sigue siendo un único mod.

Al terminar, explica cómo probar cada punto dentro de Brotato y qué limitaciones quedan.
---
