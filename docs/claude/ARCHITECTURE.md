# Arquitectura

## Organización

La aplicación separa responsabilidades en `lib/`:

- `core/`: utilidades compartidas; incluye utilidades de traducción de errores.
- `data/`: modelos, repositorios y servicios de datos/red.
- `domain/providers/`: estado y coordinación mediante Riverpod.
- `presentation/`: pantallas y widgets.

`main.dart` configura el árbol Flutter y los providers globales. La navegación principal mantiene las secciones de Inicio, Emisoras y Favoritos.

## Providers relevantes

En `lib/domain/providers/app_providers.dart` se observan:

- `settingsRepositoryProvider`
- `audioServiceProvider`
- `streamResolverProvider`
- `stationCheckerProvider`
- `radioUrlProvider`
- `errorLogProvider`
- `unavailableStationsProvider`
- `stationsProvider`
- `stationHealthProvider`
- `favoritesProvider`
- `currentStationIdProvider`
- `currentStationProvider`
- `radioPlaybackProvider`
- `volumeProvider`

### Responsabilidades

- `settingsRepositoryProvider`: persistencia local con `SharedPreferences`.
- `audioServiceProvider`: acceso al servicio singleton de audio.
- `streamResolverProvider`: resolución de playlists M3U/PLS.
- `stationCheckerProvider`: comprobación HTTP de emisoras.
- `errorLogProvider`: log de errores/éxitos en memoria.
- `unavailableStationsProvider`: conjunto de IDs temporalmente no disponibles.
- `stationsProvider`: fuente de verdad para la lista y sus mutaciones.
- `stationHealthProvider`: inicia la comprobación de disponibilidad una vez por ejecución.
- `favoritesProvider`: deriva y ordena alfabéticamente las emisoras favoritas.
- `currentStationIdProvider`: carga y persiste el ID de la emisora seleccionada.
- `currentStationProvider`: deriva el objeto `Station` a partir del ID y la lista.
- `radioPlaybackProvider`: coordina reproducción y estado del player.

## Flujo de estado

1. La UI observa providers Riverpod.
2. `stationsProvider` carga la lista desde `SettingsRepository`; si nunca se ha guardado una lista, crea la emisora inicial por defecto.
3. Las operaciones de alta, edición, borrado y favoritos actualizan la lista y la persisten.
4. `favoritesProvider` deriva los favoritos desde `isFavorite`.
5. `currentStationProvider` resuelve el ID persistido contra la lista actual; si la emisora ya no existe, devuelve `null`.
6. `stationHealthProvider` realiza una comprobación de red al inicio de la ejecución y actualiza los providers de disponibilidad y registro.
7. `radioPlaybackProvider` resuelve la URL y coordina `AudioPlayerService`.

## Estado optimista y consistencia

`StationsNotifier._save` publica `AsyncData(stations)` antes de completar la escritura en preferencias, para que la UI responda inmediatamente. Tenlo presente al introducir persistencia adicional: define qué ocurre si la escritura falla y evita que UI y disco queden divergentes.

`addMany` evita duplicados comparando la URL exacta con las URLs existentes. Si se cambia la normalización, define primero cómo tratar mayúsculas, barras finales, parámetros y URLs equivalentes.

## Reglas de arquitectura

- Mantén una única fuente de verdad para las emisoras.
- No dupliques favoritos en otra colección persistida.
- Conserva la selección por ID, no por índice.
- Mantén operaciones de red y parsing fuera de los widgets.
- Define explícitamente los estados de carga, error y éxito.
- Al crear providers que escuchen streams, revisa cancelación y ciclo de vida.