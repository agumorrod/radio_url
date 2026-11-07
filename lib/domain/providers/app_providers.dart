import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_utils.dart';
import '../../data/models/station.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/station_checker.dart';
import '../../data/services/stream_resolver.dart';

// ─── Repositorios ──────────────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final audioServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

// Convierte listas .m3u / .pls en la URL real del streaming antes de reproducir
final streamResolverProvider = Provider<StreamResolver>((ref) {
  return StreamResolver();
});

// Comprueba en segundo plano si las emisoras responden
final stationCheckerProvider = Provider<StationChecker>((ref) {
  return StationChecker(ref.read(streamResolverProvider));
});

// ─── Radio URL Provider ────────────────────────────────────────────────────────

class RadioUrlNotifier extends AsyncNotifier<String?> {
  // ✏️ Cambia esta URL por la de tu radio
  static const String _defaultUrl =
      'http://radiotrebujena.es:8000/radiotrebujena.mp3';

  @override
  Future<String?> build() async {
    final repo = ref.read(settingsRepositoryProvider);
    final savedUrl = await repo.getRadioUrl();
    return savedUrl ?? _defaultUrl;
  }

  Future<void> saveUrl(String url) async {
    final repo = ref.read(settingsRepositoryProvider);
    // Si la URL está vacía, usamos la URL por defecto
    final urlToSave = url.trim().isEmpty ? _defaultUrl : url.trim();
    await repo.saveRadioUrl(urlToSave);
    state = AsyncData(urlToSave);
  }
}

final radioUrlProvider = AsyncNotifierProvider<RadioUrlNotifier, String?>(
  RadioUrlNotifier.new,
);

// ─── Error Log Provider ────────────────────────────────────────────────────────

enum LogLevel { error, success }

class LogEntry {
  final int id;
  final DateTime time;
  final LogLevel level;
  final String message;

  const LogEntry({
    required this.id,
    required this.time,
    required this.level,
    required this.message,
  });
}

/// Registro de errores SOLO EN MEMORIA: no se guarda en disco, así que se
/// vacía solo cada vez que se cierra la app.
class ErrorLogNotifier extends Notifier<List<LogEntry>> {
  static const int _maxEntries = 300; // tope para que nunca crezca sin límite
  int _nextId = 0;

  @override
  List<LogEntry> build() => [];

  void addError(String message) => _add(LogLevel.error, message);

  // Solo se usa para informar de las emisoras añadidas en una carga
  void addSuccess(String message) => _add(LogLevel.success, message);

  void _add(LogLevel level, String message) {
    // Si el mismo mensaje ya está, lo subimos arriba en vez de duplicarlo
    // (evita llenar el registro si se pulsa play varias veces en una emisora caída)
    final rest = state
        .where((e) => !(e.level == level && e.message == message))
        .toList();
    final entry = LogEntry(
      id: _nextId++,
      time: DateTime.now(),
      level: level,
      message: message,
    );
    state = [
      entry,
      ...rest,
    ].take(_maxEntries).toList(); // la más reciente primero
  }

  void remove(int id) {
    state = state.where((e) => e.id != id).toList();
  }

  void clear() {
    state = [];
  }
}

final errorLogProvider = NotifierProvider<ErrorLogNotifier, List<LogEntry>>(
  ErrorLogNotifier.new,
);

// ─── Unavailable Stations Provider ─────────────────────────────────────────────

/// IDs de las emisoras que NO se han podido reproducir o que no respondieron
/// en la comprobación de arranque. Solo en memoria. La tarjeta las pinta
/// "deshabilitadas" (pero con sus botones activos).
class UnavailableStationsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markUnavailable(String stationId) {
    if (!state.contains(stationId)) state = {...state, stationId};
  }

  void markAvailable(String stationId) {
    if (state.contains(stationId)) state = {...state}..remove(stationId);
  }
}

final unavailableStationsProvider =
    NotifierProvider<UnavailableStationsNotifier, Set<String>>(
      UnavailableStationsNotifier.new,
    );

// ─── Stations Provider ─────────────────────────────────────────────────────────

class StationsNotifier extends AsyncNotifier<List<Station>> {
  @override
  Future<List<Station>> build() async {
    final repo = ref.read(settingsRepositoryProvider);

    // Primera vez que se abre la app: creamos la emisora por defecto
    if (!await repo.hasStations()) {
      final seed = [
        Station(
          id: 'default_radio_trebujena',
          name: 'Radio Trebujena',
          url: RadioUrlNotifier._defaultUrl,
          category: 'Local',
        ),
      ];
      await repo.saveStations(seed);
      return seed;
    }
    return await repo.getStations();
  }

  Future<void> add(Station station) async {
    await _save([...(state.value ?? []), station]);
  }

  /// Añade varias emisoras de golpe (importación) saltándose las que ya existen
  /// con la misma URL. Devuelve las que se han añadido de verdad.
  Future<List<Station>> addMany(List<Station> newStations) async {
    final current = state.value ?? [];
    final knownUrls = current.map((s) => s.url).toSet();
    final fresh = <Station>[];
    for (final s in newStations) {
      // add() devuelve false si la URL ya estaba
      if (knownUrls.add(s.url)) {
        fresh.add(s);
      }
    }
    if (fresh.isNotEmpty) {
      await _save([...current, ...fresh]);
    }
    return fresh;
  }

  // OJO: no se puede llamar 'update' porque AsyncNotifier ya tiene un método con ese nombre
  Future<void> updateStation(Station station) async {
    final current = state.value ?? [];
    await _save(current.map((s) => s.id == station.id ? station : s).toList());
  }

  Future<void> remove(String stationId) async {
    final current = state.value ?? [];
    await _save(current.where((s) => s.id != stationId).toList());
  }

  Future<void> toggleFavorite(String stationId) async {
    final current = state.value ?? [];
    await _save(
      current.map((s) {
        if (s.id == stationId) return s.copyWith(isFavorite: !s.isFavorite);
        return s;
      }).toList(),
    );
  }

  // Actualiza primero la UI y después persiste (así la pantalla responde al instante)
  Future<void> _save(List<Station> stations) async {
    state = AsyncData(stations);
    await ref.read(settingsRepositoryProvider).saveStations(stations);
  }
}

final stationsProvider = AsyncNotifierProvider<StationsNotifier, List<Station>>(
  StationsNotifier.new,
);

// ─── Station Health Provider ───────────────────────────────────────────────────

/// Comprueba en segundo plano, una vez por ejecución, qué emisoras responden.
/// El estado es true mientras la comprobación está en marcha.
class StationHealthNotifier extends Notifier<bool> {
  bool _started = false;

  @override
  bool build() => false;

  Future<void> startBackgroundCheck() async {
    // En web no es fiable (CORS) y solo se hace una vez por ejecución
    if (_started || kIsWeb) return;
    _started = true;

    // Unos segundos de cortesía para no competir con el arranque de la app
    await Future<void>.delayed(const Duration(seconds: 4));

    final stations = await ref.read(stationsProvider.future);
    if (stations.isEmpty) return;

    final checker = ref.read(stationCheckerProvider);
    final log = ref.read(errorLogProvider.notifier);
    final unavailable = ref.read(unavailableStationsProvider.notifier);

    // Sin internet todas fallarían: lo anotamos una sola vez y no marcamos nada
    if (!await checker.hasInternet()) {
      log.addError(
        'Sin conexión a internet: no se pudieron comprobar las emisoras al arrancar',
      );
      return;
    }

    state = true;
    await checker.checkAll(
      stations,
      onResult: (station, failure) {
        if (failure == null) {
          unavailable.markAvailable(station.id);
        } else {
          unavailable.markUnavailable(station.id);
          log.addError('Emisora no disponible: "${station.name}" ($failure)');
        }
      },
    );
    state = false;
  }
}

final stationHealthProvider = NotifierProvider<StationHealthNotifier, bool>(
  StationHealthNotifier.new,
);

// ─── Favorites Provider ───────────────────────────────────────────────────────

// Los favoritos ya no se guardan aparte: son las emisoras con isFavorite = true.
// Al derivarse de stationsProvider, Radios y Favoritos siempre están sincronizados.
final favoritesProvider = Provider<AsyncValue<List<Station>>>((ref) {
  return ref.watch(stationsProvider).whenData((stations) {
    final favorites = stations.where((s) => s.isFavorite).toList();
    favorites.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return favorites;
  });
});

// ─── Current Station Provider ─────────────────────────────────────────────────

// Guarda solo el ID de la emisora cargada en Inicio (y lo persiste)
class CurrentStationIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return await ref.read(settingsRepositoryProvider).getCurrentStationId();
  }

  Future<void> select(String stationId) async {
    await ref.read(settingsRepositoryProvider).saveCurrentStationId(stationId);
    state = AsyncData(stationId);
  }
}

final currentStationIdProvider =
    AsyncNotifierProvider<CurrentStationIdNotifier, String?>(
      CurrentStationIdNotifier.new,
    );

// La emisora completa se deriva del ID + la lista: si editas la emisora actual,
// Inicio se actualiza solo. Si no hay ninguna elegida (o se borró) devuelve null.
final currentStationProvider = Provider<Station?>((ref) {
  final id = ref.watch(currentStationIdProvider).value;
  final stations = ref.watch(stationsProvider).value ?? [];
  for (final station in stations) {
    if (station.id == id) return station;
  }
  return null;
});

// ─── Radio Playback Provider ───────────────────────────────────────────────────

class RadioPlaybackNotifier extends Notifier<bool> {
  int _playRequestId = 0;

  @override
  bool build() {
    final audioService = ref.read(audioServiceProvider);
    audioService.playerStateStream.listen((playerState) {
      final isActuallyPlaying =
          playerState.playing && audioService.currentType == PlaybackType.radio;
      if (state != isActuallyPlaying) state = isActuallyPlaying;
    });
    return false;
  }

  /// Play/pausa desde Inicio
  Future<void> toggle(
    String url, {
    String title = 'Radio Trebujena',
    String? stationId,
  }) async {
    final audioService = ref.read(audioServiceProvider);
    if (state) {
      await audioService.pause();
    } else {
      await _playTracked(url, title, stationId);
    }
  }

  /// Play/pausa desde la pestaña Emisoras o Favoritos.
  /// Si pulsas play en OTRA emisora, la carga en Inicio y cambia el audio.
  Future<void> toggleStation(Station station) async {
    final currentId = ref.read(currentStationIdProvider).value;
    if (state && currentId == station.id) {
      await ref.read(audioServiceProvider).pause();
    } else {
      await ref.read(currentStationIdProvider.notifier).select(station.id);
      await _playTracked(station.url, station.name, station.id);
    }
  }

  /// Reproduce y deja constancia del resultado:
  ///  - Si falla: la emisora pasa a "no disponible" y se anota en el registro.
  ///  - Si funciona: vuelve a estar disponible (aunque estuviera marcada como caída).
  /// El error se relanza para que la pantalla muestre el aviso inferior.
  Future<void> _playTracked(String url, String title, String? stationId) async {
    final requestId = ++_playRequestId;
    final unavailable = ref.read(unavailableStationsProvider.notifier);
    try {
      await _play(url, title, requestId);
      if (requestId != _playRequestId) return;
      if (stationId != null) {
        unavailable.markAvailable(stationId);
      }
    } catch (e) {
      // Si otra emisora ya sustituyó esta petición, su interrupción no es un
      // fallo de la emisora y no debe generar snackbar ni registro de error.
      if (requestId != _playRequestId) return;
      if (stationId != null) {
        unavailable.markUnavailable(stationId);
      }
      ref
          .read(errorLogProvider.notifier)
          .addError(
            'No se pudo reproducir "$title": ${describePlaybackError(e)}',
          );
      rethrow;
    }
  }

  Future<void> _play(String url, String title, int requestId) async {
    // Si la URL es un .m3u / .pls se sustituye por la URL real del streaming
    final streamUrl = await ref.read(streamResolverProvider).resolve(url);
    if (requestId != _playRequestId) return;

    await ref.read(audioServiceProvider).playRadio(streamUrl, title: title);
  }

  void setPlaying(bool playing) => state = playing;
}

final radioPlaybackProvider = NotifierProvider<RadioPlaybackNotifier, bool>(
  RadioPlaybackNotifier.new,
);

// ─── Volume Provider ──────────────────────────────────────────────────────────

class VolumeNotifier extends Notifier<double> {
  @override
  double build() => 0.7;

  Future<void> setVolume(double volume) async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.setVolume(volume);
    state = volume;
  }
}

final volumeProvider = NotifierProvider<VolumeNotifier, double>(
  VolumeNotifier.new,
);
