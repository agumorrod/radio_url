import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radio_url/data/models/station.dart';
import 'package:radio_url/data/repositories/settings_repository.dart';
import 'package:radio_url/data/services/audio_player_service.dart';
import 'package:radio_url/domain/providers/app_providers.dart';

void main() {
  test(
    'removing the selected station clears its ID and stops playback',
    () async {
      final selected = _station('selected');
      final repository = _MemorySettingsRepository(
        stations: [selected, _station('other')],
        currentStationId: selected.id,
      );
      final audioService = _FakeAudioPlayerService();
      final container = _createContainer(repository, audioService);
      addTearDown(container.dispose);

      await container.read(stationsProvider.future);
      await container.read(currentStationIdProvider.future);
      await container.read(stationsProvider.notifier).remove(selected.id);

      expect(repository.currentStationId, isNull);
      expect(container.read(currentStationIdProvider).value, isNull);
      expect(container.read(stationsProvider).value!.map((s) => s.id), [
        'other',
      ]);
      expect(audioService.stopCount, 1);
    },
  );

  test(
    'removing a non-selected station keeps selection and playback',
    () async {
      final selected = _station('selected');
      final repository = _MemorySettingsRepository(
        stations: [selected, _station('other')],
        currentStationId: selected.id,
      );
      final audioService = _FakeAudioPlayerService();
      final container = _createContainer(repository, audioService);
      addTearDown(container.dispose);

      await container.read(stationsProvider.future);
      await container.read(currentStationIdProvider.future);
      await container.read(stationsProvider.notifier).remove('other');

      expect(repository.currentStationId, selected.id);
      expect(container.read(currentStationIdProvider).value, selected.id);
      expect(audioService.stopCount, 0);
    },
  );
}

ProviderContainer _createContainer(
  _MemorySettingsRepository repository,
  _FakeAudioPlayerService audioService,
) {
  return ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
      audioServiceProvider.overrideWithValue(audioService),
    ],
  );
}

Station _station(String id) =>
    Station(id: id, name: 'Radio $id', url: 'https://example.com/$id');

class _MemorySettingsRepository implements SettingsRepository {
  _MemorySettingsRepository({
    required this.stations,
    required this.currentStationId,
  });

  List<Station> stations;
  String? currentStationId;

  @override
  Future<bool> hasStations() async => true;

  @override
  Future<List<Station>> getStations() async => stations;

  @override
  Future<void> saveStations(List<Station> stations) async {
    this.stations = stations;
  }

  @override
  Future<String?> getCurrentStationId() async => currentStationId;

  @override
  Future<void> saveCurrentStationId(String stationId) async {
    currentStationId = stationId;
  }

  @override
  Future<void> clearCurrentStationId() async {
    currentStationId = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudioPlayerService implements AudioPlayerService {
  int stopCount = 0;

  @override
  PlaybackType get currentType => PlaybackType.radio;

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
