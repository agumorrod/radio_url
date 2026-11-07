import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radio_url/data/services/audio_player_service.dart';
import 'package:radio_url/domain/providers/app_providers.dart';

void main() {
  test('ignores an interrupted load after a newer station request', () async {
    final audioService = _ControlledAudioService();
    final container = ProviderContainer(
      overrides: [audioServiceProvider.overrideWithValue(audioService)],
    );
    addTearDown(container.dispose);

    final playback = container.read(radioPlaybackProvider.notifier);
    final firstRequest = playback.toggle(
      'https://radio.example/one',
      title: 'Radio uno',
      stationId: 'one',
    );
    await Future<void>.delayed(Duration.zero);

    final secondRequest = playback.toggle(
      'https://radio.example/two',
      title: 'Radio dos',
      stationId: 'two',
    );
    await Future<void>.delayed(Duration.zero);

    audioService.firstLoad.completeError(
      PlayerInterruptedException('Loading interrupted'),
    );
    audioService.secondLoad.complete();
    await Future.wait([firstRequest, secondRequest]);

    expect(container.read(errorLogProvider), isEmpty);
    expect(container.read(unavailableStationsProvider), isEmpty);
  });
}

class _ControlledAudioService implements AudioPlayerService {
  final firstLoad = Completer<void>();
  final secondLoad = Completer<void>();
  int _loadCount = 0;

  @override
  PlaybackType get currentType => PlaybackType.none;

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Future<void> playRadio(String url, {String title = 'Radio Trebujena'}) {
    _loadCount++;
    return _loadCount == 1 ? firstLoad.future : secondLoad.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
