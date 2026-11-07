import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

enum PlaybackType { none, radio, podcast }

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _player = AudioPlayer(
      audioLoadConfiguration: AudioLoadConfiguration(
        androidLoadControl: AndroidLoadControl(
          minBufferDuration: const Duration(seconds: 50),
          maxBufferDuration: const Duration(seconds: 120),
          prioritizeTimeOverSizeThresholds: true,
        ),
      ),
    );

    _playerStateSubscription = _player.playerStateStream.listen((state) {
      _synchronizePlaybackState(state.playing);
    });
    _playerErrorSubscription = _player.errorStream.listen((_) {
      _synchronizePlaybackState(false);
    });

    // Escuchamos los callbacks de los botones de la notificación
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPause':
          await _player.pause();
          break;
        case 'onResume':
          await _resumeCurrentPlayback();
          break;
        case 'onStop':
          _radioRequestId++;
          _currentType = PlaybackType.none;
          _currentPodcastId = null;
          _currentRadioUrl = null;
          _foregroundStarted = false;
          _lastNotifiedPlaying = null;
          await _player.stop();
          break;
      }
    });
  }

  static const _channel = MethodChannel('es.app.radio_url/foreground');

  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<PlayerException> _playerErrorSubscription;
  PlaybackType _currentType = PlaybackType.none;
  String? _currentPodcastId;
  String? _currentRadioUrl;
  String _currentRadioTitle = 'Radio Trebujena';
  int _radioRequestId = 0;
  String _foregroundTitle = 'Radio URL';
  String _foregroundSubtitle = 'En directo';
  bool _foregroundStarted = false;
  bool? _lastSynchronizedPlaying;
  bool? _lastNotifiedPlaying;

  PlaybackType get currentType => _currentType;
  String? get currentPodcastId => _currentPodcastId;
  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> _startForeground({
    String title = 'Radio URL',
    String subtitle = 'En directo',
  }) async {
    try {
      await _channel.invokeMethod('startService', {
        'title': title,
        'subtitle': subtitle,
      });
      _foregroundTitle = title;
      _foregroundSubtitle = subtitle;
      _foregroundStarted = true;
      _lastNotifiedPlaying = null;
      _synchronizePlaybackState(_player.playing);
    } catch (_) {}
  }

  Future<void> _stopForeground() async {
    _foregroundStarted = false;
    _lastNotifiedPlaying = null;
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
  }

  void _synchronizePlaybackState(bool isPlaying) {
    if (_lastSynchronizedPlaying != isPlaying) {
      _lastSynchronizedPlaying = isPlaying;
      final updateWakeLock = isPlaying
          ? WakelockPlus.enable()
          : WakelockPlus.disable();
      unawaited(updateWakeLock.catchError((_) {}));
    }

    if (!_foregroundStarted || _lastNotifiedPlaying == isPlaying) return;
    _lastNotifiedPlaying = isPlaying;
    final subtitle = _currentType == PlaybackType.radio
        ? (isPlaying ? 'En directo' : 'En pausa')
        : _foregroundSubtitle;
    unawaited(
      _channel
          .invokeMethod<void>('updatePlaybackState', {
            'isPlaying': isPlaying,
            'title': _foregroundTitle,
            'subtitle': subtitle,
          })
          .catchError((_) {}),
    );
  }

  // ─── Radio ───────────────────────────────────────────────────────────────────

  Future<void> playRadio(String url, {String title = 'Radio Trebujena'}) async {
    final requestId = ++_radioRequestId;
    _currentType = PlaybackType.radio;
    _currentPodcastId = null;
    _currentRadioUrl = url;
    _currentRadioTitle = title;
    try {
      await _startForeground(title: title, subtitle: 'En directo');
      if (requestId != _radioRequestId) return;

      await _player.stop();
      if (requestId != _radioRequestId) return;

      await _player.setUrl(url);
      if (requestId != _radioRequestId) return;

      // Sin await: play() no termina mientras suena (es un directo). Así esta
      // función devuelve cuando el streaming YA está cargado, y si setUrl() falla
      // el error llega al catch de abajo.
      unawaited(_player.play().catchError((_) {}));
    } catch (e) {
      // setUrl puede fallar con PlayerInterruptedException si otra emisora
      // inició una carga más reciente. Esa petición nueva controla el player.
      if (requestId != _radioRequestId) return;

      // Si falla, quitamos la notificación en primer plano que se acababa de crear
      _currentType = PlaybackType.none;
      _currentRadioUrl = null;
      await _stopForeground();
      throw Exception('Error al reproducir radio: $e');
    }
  }

  // ─── Podcast ─────────────────────────────────────────────────────────────────

  Future<Duration?> playPodcast(
    String url,
    String podcastId, {
    String title = 'Podcast: ',
  }) async {
    _radioRequestId++;
    _currentType = PlaybackType.podcast;
    _currentPodcastId = podcastId;
    _currentRadioUrl = null;
    try {
      await _startForeground(title: title, subtitle: '');
      await _player.stop();
      final duration = await _player.setUrl(url);
      await _player.play();
      return duration;
    } catch (e) {
      throw Exception('Error al reproducir podcast: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _resumeCurrentPlayback();
  }

  Future<void> _resumeCurrentPlayback() async {
    if (_currentType == PlaybackType.radio) {
      final url = _currentRadioUrl;
      if (url == null) return;
      await playRadio(url, title: _currentRadioTitle);
      return;
    }

    unawaited(_player.play().catchError((_) {}));
  }

  Future<void> stop() async {
    _radioRequestId++;
    _currentType = PlaybackType.none;
    _currentPodcastId = null;
    _currentRadioUrl = null;
    await _stopForeground();
    await _player.stop();
  }

  Future<void> seek(Duration position) async => await _player.seek(position);

  Future<void> setVolume(double volume) async =>
      await _player.setVolume(volume.clamp(0.0, 1.0));

  double get volume => _player.volume;

  void dispose() {
    _synchronizePlaybackState(false);
    unawaited(_playerStateSubscription.cancel());
    unawaited(_playerErrorSubscription.cancel());
    _stopForeground();
    _player.dispose();
  }
}
