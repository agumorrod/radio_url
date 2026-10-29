import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

    // Escuchamos los callbacks de los botones de la notificación
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPause':
          await _player.pause();
          await WakelockPlus.disable();
          break;
        case 'onResume':
          await _player.play();
          await WakelockPlus.enable();
          break;
        case 'onStop':
          _currentType = PlaybackType.none;
          _currentPodcastId = null;
          await _player.stop();
          await WakelockPlus.disable();
          break;
      }
    });
  }

  static const _channel = MethodChannel('es.app.radio_app/foreground');

  late final AudioPlayer _player;
  PlaybackType _currentType = PlaybackType.none;
  String? _currentPodcastId;

  PlaybackType get currentType => _currentType;
  String? get currentPodcastId => _currentPodcastId;
  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> _startForeground({
    String title = 'Radio Trebujena',
    String subtitle = 'En directo',
  }) async {
    try {
      await _channel.invokeMethod('startService', {
        'title': title,
        'subtitle': subtitle,
      });
    } catch (_) {}
    await WakelockPlus.enable();
  }

  Future<void> _pauseForeground() async {
    try {
      await _channel.invokeMethod('pauseService');
    } catch (_) {}
    await WakelockPlus.disable();
  }

  Future<void> _resumeForeground() async {
    try {
      await _channel.invokeMethod('resumeService');
    } catch (_) {}
    await WakelockPlus.enable();
  }

  Future<void> _stopForeground() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
    await WakelockPlus.disable();
  }

  // ─── Radio ───────────────────────────────────────────────────────────────────

  Future<void> playRadio(String url) async {
    _currentType = PlaybackType.radio;
    _currentPodcastId = null;
    try {
      // await _startForeground(title: 'Radio Trebujena', subtitle: 'En directo');
      await _startForeground(title: 'En directo', subtitle: '');
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      throw Exception('Error al reproducir radio: $e');
    }
  }

  // ─── Podcast ─────────────────────────────────────────────────────────────────

  Future<Duration?> playPodcast(
    String url,
    String podcastId, {
    String title = 'Podcast: ',
  }) async {
    _currentType = PlaybackType.podcast;
    _currentPodcastId = podcastId;
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
    await _pauseForeground();
    await _player.pause();
  }

  Future<void> resume() async {
    await _resumeForeground();
    await _player.play();
  }

  Future<void> stop() async {
    _currentType = PlaybackType.none;
    _currentPodcastId = null;
    await _stopForeground();
    await _player.stop();
  }

  Future<void> seek(Duration position) async => await _player.seek(position);

  Future<void> setVolume(double volume) async =>
      await _player.setVolume(volume.clamp(0.0, 1.0));

  double get volume => _player.volume;

  void dispose() {
    _stopForeground();
    _player.dispose();
  }
}
