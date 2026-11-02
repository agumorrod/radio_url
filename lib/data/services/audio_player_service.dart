import 'package:just_audio/just_audio.dart';

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
  }

  late final AudioPlayer _player;

  PlaybackType _currentType = PlaybackType.none;
  String? _currentPodcastId;

  PlaybackType get currentType => _currentType;
  String? get currentPodcastId => _currentPodcastId;
  bool get isPlaying => _player.playing;
  Duration? get duration => _player.duration;
  double get volume => _player.volume;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> playRadio(String url, {String title = 'Radio Trebujena'}) async {
    _currentType = PlaybackType.radio;
    _currentPodcastId = null;

    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      _currentType = PlaybackType.none;
      throw Exception('Error al reproducir radio: $e');
    }
  }

  Future<Duration?> playPodcast(
    String url,
    String podcastId, {
    String title = 'Podcast',
  }) async {
    _currentType = PlaybackType.podcast;
    _currentPodcastId = podcastId;

    try {
      await _player.stop();
      final duration = await _player.setUrl(url);
      await _player.play();
      return duration;
    } catch (e) {
      _currentType = PlaybackType.none;
      _currentPodcastId = null;
      throw Exception('Error al reproducir podcast: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    _currentType = PlaybackType.none;
    _currentPodcastId = null;
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
