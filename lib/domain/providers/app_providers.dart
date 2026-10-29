import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radio_app/data/models/podcast.dart';
import 'package:radio_app/data/repositories/podcast_repository.dart';
import 'package:radio_app/data/repositories/settings_repository.dart';
import 'package:radio_app/data/services/audio_player_service.dart';

// ─── Repositorios ──────────────────────────────────────────────────────────────

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final podcastRepositoryProvider = Provider<PodcastRepository>((ref) {
  return PodcastRepository();
});

final audioServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
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
    await repo.saveRadioUrl(url);
    state = AsyncData(url);
  }
}

final radioUrlProvider = AsyncNotifierProvider<RadioUrlNotifier, String?>(
  RadioUrlNotifier.new,
);

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

  Future<void> toggle(String url) async {
    final audioService = ref.read(audioServiceProvider);
    if (state) {
      await audioService.pause();
    } else {
      await ref.read(podcastPlaybackProvider.notifier).stop();
      await audioService.playRadio(url);
    }
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

// ─── Podcasts Provider ────────────────────────────────────────────────────────

class PodcastsNotifier extends AsyncNotifier<List<Podcast>> {
  @override
  Future<List<Podcast>> build() async {
    final favorites = await ref.read(settingsRepositoryProvider).getFavorites();
    final favoriteIds = favorites.map((f) => f.id).toSet();
    final podcasts = await ref
        .read(podcastRepositoryProvider)
        .fetchPodcasts('https://feeds.ivoox.com/feed_fg_f197737_filtro_1.xml');
    return podcasts
        .map((p) => p.copyWith(isFavorite: favoriteIds.contains(p.id)))
        .toList();
  }

  Future<void> toggleFavorite(String podcastId) async {
    final repo = ref.read(settingsRepositoryProvider);
    final currentPodcasts = state.value ?? [];

    final updatedPodcasts = currentPodcasts.map((p) {
      if (p.id == podcastId) return p.copyWith(isFavorite: !p.isFavorite);
      return p;
    }).toList();

    state = AsyncData(updatedPodcasts);

    final podcast = updatedPodcasts.firstWhere((p) => p.id == podcastId);
    if (podcast.isFavorite) {
      await repo.addFavorite(podcast);
    } else {
      await repo.removeFavorite(podcastId);
    }

    ref.invalidate(favoritesProvider);
  }
}

final podcastsProvider = AsyncNotifierProvider<PodcastsNotifier, List<Podcast>>(
  PodcastsNotifier.new,
);

// ─── Favorites Provider ───────────────────────────────────────────────────────

class FavoritesNotifier extends AsyncNotifier<List<Podcast>> {
  @override
  Future<List<Podcast>> build() async {
    return await ref.read(settingsRepositoryProvider).getFavorites();
  }

  Future<void> removeFavorite(String podcastId) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.removeFavorite(podcastId);

    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != podcastId).toList());

    ref.read(podcastsProvider.notifier).toggleFavorite(podcastId);
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<Podcast>>(
      FavoritesNotifier.new,
    );

// ─── Podcast Playback State ───────────────────────────────────────────────────

class PodcastPlaybackState {
  final String? currentPodcastId;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;

  const PodcastPlaybackState({
    this.currentPodcastId,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
  });

  PodcastPlaybackState copyWith({
    String? currentPodcastId,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return PodcastPlaybackState(
      currentPodcastId: currentPodcastId ?? this.currentPodcastId,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

// ─── Podcast Playback Provider ────────────────────────────────────────────────

class PodcastPlaybackNotifier extends Notifier<PodcastPlaybackState> {
  @override
  PodcastPlaybackState build() {
    final audioService = ref.read(audioServiceProvider);

    // ✅ FIX: Sincronizamos isPlaying con el estado REAL del player.
    // Así cuando se reanuda la reproducción, el botón se actualiza
    // automáticamente a pausa sin necesidad de gestión manual.
    audioService.playerStateStream.listen((playerState) {
      if (state.currentPodcastId == null) return;
      // Solo actuamos si el audio activo es un podcast (no la radio)
      if (audioService.currentType != PlaybackType.podcast) return;

      final isActuallyPlaying = playerState.playing;
      if (state.isPlaying != isActuallyPlaying) {
        state = state.copyWith(isPlaying: isActuallyPlaying);
      }
    });

    // Actualizamos posición en tiempo real para la barra de progreso
    audioService.positionStream.listen((position) {
      if (state.currentPodcastId != null) {
        state = state.copyWith(position: position);
      }
    });

    // Red de seguridad: si setUrl no devuelve duración, la pillamos aquí
    audioService.durationStream.listen((duration) {
      if (duration != null &&
          state.currentPodcastId != null &&
          state.duration == null) {
        state = state.copyWith(duration: duration);
      }
    });

    return const PodcastPlaybackState();
  }

  Future<void> togglePodcast(Podcast podcast) async {
    final audioService = ref.read(audioServiceProvider);

    if (state.currentPodcastId == podcast.id && state.isPlaying) {
      // Pausar — el playerStateStream actualizará isPlaying a false
      await audioService.pause();
    } else if (state.currentPodcastId == podcast.id && !state.isPlaying) {
      // Reanudar — el playerStateStream actualizará isPlaying a true
      await audioService.resume();
    } else {
      // Nuevo podcast: mostramos la barra inmediatamente
      state = PodcastPlaybackState(
        currentPodcastId: podcast.id,
        isPlaying: true,
      );

      ref.read(radioPlaybackProvider.notifier).setPlaying(false);

      String prefix = 'Podcast: ';

      final duration = await audioService.playPodcast(
        podcast.streamUrl,
        podcast.id,
        title: prefix + podcast.title,
      );

      state = state.copyWith(duration: duration);
    }
  }

  Future<void> seek(Duration position) async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.seek(position);
    state = state.copyWith(position: position);
  }

  Future<void> stop() async {
    final audioService = ref.read(audioServiceProvider);
    if (audioService.currentType == PlaybackType.podcast) {
      await audioService.stop();
      state = const PodcastPlaybackState();
    }
  }
}

final podcastPlaybackProvider =
    NotifierProvider<PodcastPlaybackNotifier, PodcastPlaybackState>(
      PodcastPlaybackNotifier.new,
    );
