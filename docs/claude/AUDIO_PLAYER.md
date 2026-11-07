# Reproductor de audio

## Implementación

`AudioPlayerService` es un singleton que encapsula un único `just_audio.AudioPlayer`. Coordina además `WakelockPlus` y un MethodChannel Android.

El servicio escucha `playerStateStream` y `errorStream` en un único punto de sincronización: el wakelock sigue `playing`, y la notificación Android cambia entre Pausar/Reproducir y En directo/En pausa. La acción nativa `updatePlaybackState` solo actualiza la notificación; no devuelve un callback al player, evitando ciclos de pausa/reanudación.

`PlaybackType` contiene `none`, `radio` y `podcast`. El servicio implementa `playRadio` y `playPodcast`, aunque la existencia del segundo método no demuestra que haya una funcionalidad completa de podcasts en la UI.

## Reproducción de radio

`playRadio(url, title:)`:

1. Marca el tipo actual como `radio` y limpia el ID de podcast.
2. Solicita iniciar el servicio foreground Android; el listener del player sincroniza el wakelock según el estado real.
3. Detiene la fuente anterior.
4. Carga la nueva URL con `setUrl`.
5. Lanza `play()` sin esperarlo, porque un stream en directo no termina mientras está reproduciéndose.
6. Si la preparación/carga falla, cambia el tipo a `none`, detiene el foreground y relanza el error.

Cada carga de radio recibe un token. Las comprobaciones tras las operaciones asíncronas impiden que una petición superada inicie el siguiente paso. Si `setUrl` queda interrumpido por una petición posterior, su `catch` no cambia el tipo de reproducción, no detiene el foreground ni propaga el error. El provider usa su propio token para descartar resultados obsoletos antes de cambiar disponibilidad, registrar errores o mostrar un snackbar.

El provider resuelve previamente M3U/PLS mediante `StreamResolver`, antes de llamar al servicio.

## Pausa, reanudación y parada

- `pause()` actualiza el foreground/wakelock y pausa el player.
- `resume()` vuelve a cargar la URL de radio activa, igual que el botón de reproducción de la app; para otros tipos lanza `play()` sin esperarlo. El listener sincroniza foreground/wakelock.
- `stop()` limpia el tipo y el ID de podcast, detiene foreground/wakelock y para el player.
- `seek()` y `setVolume()` delegan en `just_audio`.
- El volumen inicial compartido por el servicio y el provider es 0.7. El servicio lo aplica al crear el player y espera esa operación antes de iniciar audio; los cambios posteriores se limitan al intervalo 0.0–1.0.

## Buffer

La configuración observada de `AndroidLoadControl` usa buffer mínimo de 50 segundos y máximo de 120 segundos, con prioridad de tiempo sobre tamaño.

## MethodChannel

Canal: `es.app.radio_url/foreground`

Flutter → Android:
- `startService`
- `pauseService`
- `resumeService`
- `updatePlaybackState` (actualiza la notificación sin callback a Flutter)
- `stopService`

Android → Flutter:
- `onPause`
- `onResume`
- `onStop`

Los callbacks nativos actúan sobre el player y el wakelock. Comprueba que cualquier cambio en nombres de métodos o payloads se refleje en ambos lados.

## Errores

`describePlaybackError` traduce algunos errores de ExoPlayer/just_audio, incluyendo códigos HTTP, host no resoluble, timeout, cleartext HTTP, conexión rechazada y formato de entrada no reconocido. Los mensajes deben seguir siendo informativos sin ocultar el error técnico en logs de depuración.

## Puntos de auditoría

- `play()` se lanza con `unawaited`; `errorStream` sincroniza los indicadores de reproducción cuando falla después de `setUrl`.
- `dispose()` invoca `_stopForeground()` y `_player.dispose()` sin esperar explícitamente las operaciones asíncronas. Verifica el contrato y el ciclo de vida antes de corregirlo.
- `RadioPlaybackNotifier` escucha `playerStateStream`; confirma la gestión de la suscripción y su cancelación al destruir el provider.
- Evita que estado `playing`, `currentType`, notificación y wakelock se desincronicen.

## Pruebas recomendadas

- Preparación y reproducción de URL válida.
- Fallo de `setUrl`, error posterior de `play`, desconexión y timeout.
- Cambio rápido de emisora.
- Pausa/reanudación desde UI y notificación.
- Parada y limpieza de foreground/wakelock.
- Liberación del singleton y cancelación de listeners.
