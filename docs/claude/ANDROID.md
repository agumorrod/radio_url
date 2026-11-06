# Android: integración nativa y compatibilidad

## Integración observada

El reproductor Flutter usa `just_audio`; el lado Android coordina el servicio foreground y la notificación mediante Kotlin y un MethodChannel.

Canal observado: `es.app.radio_url/foreground`.

Métodos Flutter → Android:
- `startService`
- `pauseService`
- `resumeService`
- `stopService`

Callbacks Android → Flutter:
- `onPause`
- `onResume`
- `onStop`

El servicio observado utiliza un canal de notificación `radio_url_channel`, ID `1`, tipo foreground `mediaPlayback` y `START_STICKY`.

## Permisos

La inspección anterior identificó permisos de Internet, foreground service, foreground service de media playback, wakelock y notificaciones. Verifica el `AndroidManifest.xml` del commit actual antes de cambiar permisos o documentar su estado como definitivo.

La solicitud runtime de `POST_NOTIFICATIONS` había aparecido comentada en una revisión previa; comprueba el flujo actual y el comportamiento en Android 13+.

## Toolchain y SDK

La configuración Android debe leerse de los archivos Gradle actuales. En la revisión anterior se habían observado AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14 y JVM 17; no se debe asumir que siguen siendo las versiones vigentes sin volver a comprobarlas.

`compileSdk`, `minSdk` y `targetSdk` pueden derivarse de las variables de Flutter. No infieras un target API concreto sin comprobar el valor efectivo de la instalación Flutter usada.

## Android 17 / API 37

La compatibilidad con Android 17/API 37 no se ha certificado mediante build ni pruebas en dispositivo. Antes de afirmar compatibilidad:

1. Confirma el `targetSdk` efectivo.
2. Revisa los cambios de comportamiento aplicables a la versión de Android y al target.
3. Verifica los requisitos de foreground services de tipo `mediaPlayback`.
4. Comprueba permisos declarados y runtime.
5. Prueba reproducción con pantalla apagada, cambio de app, pausa, reanudación y parada.
6. Comprueba notificación, acciones y recreación del proceso/servicio.
7. Revisa plugins y dependencias Android transitivas.
8. Ejecuta build y pruebas en emulador/dispositivo.

Referencias oficiales:
- https://developer.android.com/about/versions/17/behavior-changes-17
- https://developer.android.com/about/versions/17/behavior-changes-all
- https://developer.android.com/about/versions/17/changes/bg-audio
- https://developer.android.com/about/versions/17/summary

No añadas permisos ni alarmas como workaround sin una necesidad demostrada y una justificación técnica. No introduzcas `USAGE_ALARM` para mantener la reproducción.

## Validación

La revisión de código no equivale a una prueba en dispositivo. Registra siempre versiones de Flutter, Dart, JDK y SDK, comandos ejecutados, dispositivo/API y resultados.