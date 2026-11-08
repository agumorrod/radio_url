import 'package:flutter_test/flutter_test.dart';
import 'package:radio_url/data/models/station.dart';
import 'package:radio_url/data/services/station_importer.dart';

void main() {
  test('round-trips a Shoutcast URL ending in semicolon and its category', () {
    final original = Station(
      id: 'station-1',
      name: 'Radio',
      url: 'http://host:8000/;',
      category: 'Música',
    );

    final exported = StationImporter.toText([original]);
    final imported = StationImporter.parse(exported);

    expect(exported, 'Radio;http://host:8000/;;Música');
    expect(imported.issues, isEmpty);
    expect(imported.stations, hasLength(1));
    expect(imported.stations.single.url, original.url);
    expect(imported.stations.single.category, original.category);
  });

  test('still parses a legacy row without category', () {
    final result = StationImporter.parse('Radio;https://host/stream');

    expect(result.issues, isEmpty);
    expect(result.stations.single.name, 'Radio');
    expect(result.stations.single.url, 'https://host/stream');
    expect(result.stations.single.category, 'Sin categoría');
  });

  test('parses M3U attributes containing commas', () {
    final result = StationImporter.parse(
      '#EXTM3U\n'
      '#EXTINF:-1 group-title="Pop, Rock",Nombre de la emisora\n'
      'https://host/stream',
    );

    expect(result.issues, isEmpty);
    expect(result.stations, hasLength(1));
    expect(result.stations.single.name, 'Nombre de la emisora');
    expect(result.stations.single.category, 'Pop, Rock');
  });

  test('parses a delimited row whose name starts with http', () {
    final result = StationImporter.parse('httpradio;http://host/stream;Pop');

    expect(result.issues, isEmpty);
    expect(result.stations, hasLength(1));
    expect(result.stations.single.name, 'httpradio');
    expect(result.stations.single.url, 'http://host/stream');
    expect(result.stations.single.category, 'Pop');
  });
}
