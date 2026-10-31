import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radio_url/data/models/station.dart';
import 'package:radio_url/data/repositories/settings_repository.dart';
import 'package:radio_url/data/services/audio_player_service.dart';
import 'package:radio_url/data/services/stream_resolver.dart';

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
  /// con la misma URL. Devuelve cuántas se han añadido de verdad.
  Future<int> addMany(List<Station> newStations) async {
    final current = state.value ?? [];
    final knownUrls = current.map((s) => s.url).toSet();
    final fresh = <Station>[];
    for (final s in newStations) {
      if (knownUrls.add(s.url)) {
        fresh.add(s);
      }
    }
    if (fresh.isNotEmpty) {
      await _save([...current, ...fresh]);
    }
    return fresh.length;
  }

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
  Future<void> toggle(String url, {String title = 'Radio Trebujena'}) async {
    final audioService = ref.read(audioServiceProvider);
    if (state) {
      await audioService.pause();
    } else {
      await _play(url, title);
    }
  }

  /// Play/pausa desde la pestaña Radios o Favoritos.
  /// Si pulsas play en OTRA emisora, la carga en Inicio y cambia el audio.
  Future<void> toggleStation(Station station) async {
    final currentId = ref.read(currentStationIdProvider).value;
    if (state && currentId == station.id) {
      await ref.read(audioServiceProvider).pause();
    } else {
      await ref.read(currentStationIdProvider.notifier).select(station.id);
      await _play(station.url, station.name);
    }
  }

  Future<void> _play(String url, String title) async {
    // Si la URL es un .m3u / .pls se sustituye por la URL real del streaming
    final streamUrl = await ref.read(streamResolverProvider).resolve(url);
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
