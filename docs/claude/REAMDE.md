# Radio URL — documentación de contexto para Claude

Esta carpeta reúne el contexto técnico y las reglas de trabajo para colaborar en **Radio URL**, aplicación Flutter para gestionar y reproducir emisoras de radio por URL.

## Orden recomendado de lectura

1. [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) — propósito, alcance, stack y funcionalidades.
2. [ARCHITECTURE.md](ARCHITECTURE.md) — capas, providers y flujos de datos.
3. [AUDIO_PLAYER.md](AUDIO_PLAYER.md) — reproducción, resolución y ciclo de vida del audio.
4. [STATION_HEALTH.md](STATION_HEALTH.md) — comprobación de emisoras, registro de errores e importación.
5. [ANDROID.md](ANDROID.md) — integración Android y compatibilidad.
6. [CODING_RULES.md](CODING_RULES.md) — convenciones y criterios para modificar el proyecto.
7. [CURRENT_STATUS.md](CURRENT_STATUS.md) — estado conocido y límites de la revisión.
8. [ROADMAP.md](ROADMAP.md) — prioridades propuestas.
9. [TASK_TEMPLATE.md](TASK_TEMPLATE.md) — plantilla para nuevas tareas.

## Fuente de verdad y revisión

- Repositorio: https://github.com/agumorrod/radio_url
- Rama revisada: `develop`
- Commit revisado: `874f27108a60e861cdf8bef480543c5f0cf97ad8`
- La revisión de esta versión se realizó leyendo los archivos del repositorio y comparando el commit con su padre.
- El commit anterior usado para identificar los cambios fue `e00d6088e1c4c38a604ba120c60558da24d59fdf`.

El código actual siempre prevalece sobre esta documentación. Antes de implementar, comprueba que sigues trabajando sobre el commit/estado esperado.

## Instrucciones para Claude

- No inventes funcionalidades ni afirmes que una característica está terminada sin comprobar su implementación.
- Inspecciona los usos de cualquier provider, método o modelo antes de cambiarlo.
- Conserva la compatibilidad con los datos locales existentes.
- Distingue errores de red de emisoras que realmente no responden.
- No conviertas una comprobación HTTP de disponibilidad en una garantía de que el audio se puede decodificar.
- No afirmes que tests, builds o pruebas en dispositivos han pasado si no se han ejecutado.
- Actualiza estos documentos cuando cambien arquitectura, persistencia, audio o comportamiento funcional.