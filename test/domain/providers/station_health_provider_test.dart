import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_url/data/models/station.dart';
import 'package:radio_url/data/repositories/settings_repository.dart';
import 'package:radio_url/data/services/station_checker.dart';
import 'package:radio_url/data/services/stream_resolver.dart';
import 'package:radio_url/domain/providers/app_providers.dart';

void main() {
  test('resets checking state and retries after a checker failure', () async {
    final checker = _FailOnceStationChecker();
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          _MemorySettingsRepository(),
        ),
        stationCheckerProvider.overrideWithValue(checker),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(stationHealthProvider.notifier);

    await notifier.startBackgroundCheck();

    expect(container.read(stationHealthProvider), isFalse);
    expect(checker.checkAllCalls, 1);
    expect(container.read(errorLogProvider), hasLength(1));

    await notifier.startBackgroundCheck();

    expect(container.read(stationHealthProvider), isFalse);
    expect(checker.checkAllCalls, 2);
  });
}

class _FailOnceStationChecker extends StationChecker {
  _FailOnceStationChecker() : super(StreamResolver());

  int checkAllCalls = 0;

  @override
  Future<bool> hasInternet() async => true;

  @override
  Future<void> checkAll(
    List<Station> stations, {
    required void Function(Station station, String? failure) onResult,
    int concurrency = 4,
  }) async {
    checkAllCalls++;
    if (checkAllCalls == 1) throw StateError('fallo simulado');
  }
}

class _MemorySettingsRepository implements SettingsRepository {
  @override
  Future<bool> hasStations() async => true;

  @override
  Future<List<Station>> getStations() async => [
    Station(
      id: 'station-1',
      name: 'Radio',
      url: 'https://radio.example/stream',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
