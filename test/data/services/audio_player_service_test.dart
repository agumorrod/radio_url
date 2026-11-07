import 'package:flutter_test/flutter_test.dart';
import 'package:radio_url/data/services/audio_player_service.dart';

void main() {
  test('player starts at the shared default volume', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final audioService = AudioPlayerService();

    expect(audioService.volume, AudioPlayerService.defaultVolume);
  });
}
