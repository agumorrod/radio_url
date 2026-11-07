# Roadmap propuesto

Este roadmap es una propuesta derivada de la lectura del código, no un compromiso de producto.

## 1. Consolidar las mejoras recientes

- [ ] Añadir tests unitarios de `StationChecker`.
- [ ] Probar conectividad ausente y evitar falsos positivos de emisoras caídas.
- [ ] Probar respuestas HTTP, redirecciones, timeout y servidores ICY/Shoutcast.
- [ ] Verificar el límite de concurrencia de `checkAll`.
- [ ] Añadir tests de `ImportResult`, incidencias por línea y exportación.
- [ ] Probar URLs que terminan en `;` y preservar compatibilidad del formato.
- [ ] Probar deduplicación y comportamiento del registro de errores.
- [ ] Verificar persistencia/restauración de la posición del botón flotante.

## 2. Fiabilidad del reproductor

- [ ] Auditar ciclo de vida del singleton y `AudioPlayer`.
- [ ] Gestionar explícitamente subscriptions de streams.
- [ ] Revisar errores que ocurren después de `setUrl` durante `play()`.
- [ ] Asegurar limpieza de foreground service y wakelock en todos los caminos de error.
- [ ] Probar cambios rápidos de emisora, pause/resume y desconexiones.

## 3. Persistencia y consistencia

- [ ] Manejar fallos de escritura de `SharedPreferences`.
- [ ] Definir política de recuperación ante JSON corrupto.
- [ ] Añadir tests de migración si evoluciona `Station`.
- [ ] Verificar que el ID actual se limpia o resuelve correctamente al borrar la emisora seleccionada.

## 4. Android

- [ ] Confirmar target SDK efectivo.
- [ ] Validar permisos de notificación y foreground media playback.
- [ ] Probar controles de notificación y reproducción con pantalla apagada.
- [ ] Validar en versiones Android objetivo, incluida API 37 si se desea soportar.

## 5. Experiencia de usuario

- [ ] Revisar accesibilidad de tarjetas y estados no disponibles.
- [ ] Mejorar feedback de importaciones parciales y exportaciones.
- [ ] Probar listas grandes y operaciones de edición/borrado.
- [ ] Decidir explícitamente el alcance de podcasts antes de anunciarlo como función disponible.

## Criterio de finalización

Cada tarea debe incluir criterios de aceptación verificables, pruebas relevantes, resultados reales y actualización de la documentación afectada.