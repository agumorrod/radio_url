# Reglas de desarrollo

## Principios generales

- El código del commit de trabajo prevalece sobre estos documentos.
- Inspecciona los usos de una clase/provider/método antes de modificarlo.
- Haz cambios acotados y coherentes con las capas existentes.
- No añadas dependencias si la funcionalidad puede resolverse razonablemente con las existentes.
- No declares una tarea terminada sin verificar sus criterios de aceptación.

## Dart y Flutter

- Usa tipos explícitos y evita `dynamic` innecesario.
- Ejecuta `dart format` sobre los archivos modificados.
- Respeta los lints configurados.
- Mantén lógica de negocio y red fuera de los widgets.
- Gestiona correctamente `mounted`, controllers, subscriptions y recursos asíncronos.
- Proporciona estados de carga, error, vacío y éxito comprensibles.

## Riverpod

- Mantén una fuente de verdad para la colección de emisoras.
- Deriva favoritos desde `Station.isFavorite`.
- Usa IDs estables, no índices de lista.
- Ten presente que `_save` actualiza el estado antes de persistir; trata explícitamente errores de escritura.
- Define el ciclo de vida de providers que escuchan streams.
- Cancela subscriptions cuando corresponda.
- Evita efectos secundarios no controlados durante `build`.

## Red y comprobación de emisoras

- Distingue conectividad general, respuesta HTTP y reproducción de audio: son tres cosas diferentes.
- No marques todas las emisoras como caídas si no hay conexión.
- Mantén límites de timeout y concurrencia para evitar saturar red/dispositivo.
- No descargues el contenido completo del stream para una comprobación de disponibilidad.
- Trata respuestas atípicas (p. ej. ICY) con cuidado y evita falsos positivos negativos.
- Mantén los mensajes de error legibles y conserva suficiente detalle técnico para depuración.

## Importación y persistencia

- Valida URLs HTTP(S) sin romper URLs válidas que contengan `;`.
- Conserva el número de línea y motivo de cada entrada rechazada.
- No descartes errores de importación silenciosamente.
- Mantén exportación e importación compatibles.
- Compara duplicados según una política explícita.
- No cambies claves ni formatos de `SharedPreferences` sin migración/compatibilidad.

## Audio y Android

- Mantén sincronizados player, tipo de reproducción, foreground service, notificación y wakelock.
- Maneja errores de preparación y errores asíncronos de reproducción.
- No mantengas servicio o wakelock activo tras detener el audio.
- No añadas permisos Android innecesarios.
- Verifica en las versiones Android objetivo; compilar no demuestra por sí solo el comportamiento en segundo plano.

## Verificación antes de entregar

Ejecuta, cuando el entorno esté disponible:
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter build apk` si el cambio afecta Android.

Incluye en la entrega:
- archivos modificados;
- decisiones técnicas;
- pruebas y comandos ejecutados;
- resultados reales;
- riesgos y limitaciones conocidas.