# Contexto del proyecto

## Resumen

**Radio URL** es una aplicación Flutter/Dart centrada en gestionar una colección de emisoras de radio, seleccionar una emisora principal y reproducir streams en directo. La aplicación permite importar/exportar emisoras, organizar favoritos y detectar emisoras que no responden.

Repositorio: https://github.com/agumorrod/radio_url  
Rama revisada: `develop`  
Commit revisado: `874f27108a60e861cdf8bef480543c5f0cf97ad8`

## Stack observado

- Flutter y Dart; `pubspec.yaml` declara el constraint de Dart `^3.11.0`.
- Estado: `flutter_riverpod`.
- Navegación: `go_router`.
- Reproducción: `just_audio`.
- HTTP: `dio`.
- Preferencias locales: `shared_preferences`.
- Wakelock: `wakelock_plus`.
- Imágenes: `cached_network_image`.
- Kotlin para integración Android nativa.

Las versiones concretas de dependencias deben leerse siempre del `pubspec.yaml` del commit de trabajo, no copiarse de esta documentación si el proyecto ha avanzado.

## Funcionalidades observadas en el código

- Navegación principal con Inicio, Emisoras y Favoritos.
- Selección de una emisora actual persistida por ID.
- Gestión de una colección de emisoras con nombre, URL, categoría, icono y favorito.
- Alta, edición y eliminación de emisoras desde la interfaz de gestión.
- Favoritos almacenados como propiedad `isFavorite` de cada emisora y derivados de la lista principal.
- Importación de texto con formatos:
  - `Nombre;URL;Categoría` (categoría opcional).
  - M3U extendido con `#EXTINF` y `group-title`.
  - Una URL HTTP(S) por línea.
- Exportación de emisoras al formato delimitado por punto y coma.
- Detección de URLs duplicadas durante la importación masiva.
- Comprobación en segundo plano de emisoras que responden, con concurrencia limitada.
- Registro de errores y avisos de éxito en memoria, limitado a 300 entradas.
- Marcado visual de emisoras no disponibles sin desactivar los controles de la tarjeta.
- Mensajes de error de reproducción traducidos a motivos legibles.
- Posición del botón flotante de añadir guardada como fracciones del área disponible.

## Modelo de emisora

El modelo `Station` observado incluye `id`, `name`, `url`, `category`, `iconKey` e `isFavorite`. Revisa `lib/data/models/station.dart` antes de ampliar el modelo o asumir valores por defecto y reglas de serialización.

## Persistencia

`SettingsRepository` usa `SharedPreferences`. Claves observadas:

- `radio_stream_url`
- `stations_list`
- `current_station_id`
- `add_button_x`
- `add_button_y`

La lista de emisoras se serializa como JSON en una única clave. Los favoritos no se guardan en una lista paralela: se guardan en `isFavorite`. La posición del botón flotante se guarda como valores relativos (fracciones), no como píxeles.

No cambies claves ni estructura de serialización sin contemplar los datos que ya puedan tener los usuarios.

## Alcance no confirmado

El servicio de audio contiene `PlaybackType.podcast` y `playPodcast`, pero eso por sí solo no acredita una experiencia completa de podcasts. El README y las dependencias deben contrastarse con pantallas, providers y navegación antes de describir podcasts como funcionalidad disponible.