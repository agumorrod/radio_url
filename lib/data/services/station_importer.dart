import '../models/station.dart';

/// Convierte texto en emisoras (importar) y emisoras en texto (exportar).
/// Evita tener que teclear 200 emisoras una a una.
class StationImporter {
  /// Formatos admitidos (una emisora por línea):
  ///  1) Nombre;URL;Categoría        (la categoría es opcional)
  ///  2) M3U extendido:  #EXTINF:-1 group-title="Música",Nombre
  ///                     http://servidor/stream
  ///  3) Solo la URL (el nombre será el dominio)
  static List<Station> parse(String text) {
    final stations = <Station>[];
    String? pendingName;
    String? pendingCategory;
    var salt = 0;

    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#EXTM3U')) continue;

      // Cabecera M3U: guardamos nombre y categoría para la URL de la línea siguiente
      if (line.startsWith('#EXTINF')) {
        final comma = line.indexOf(',');
        pendingName = comma >= 0 ? line.substring(comma + 1).trim() : null;
        pendingCategory = RegExp(
          r'group-title="([^"]*)"',
        ).firstMatch(line)?.group(1);
        continue;
      }
      if (line.startsWith('#')) continue; // otros comentarios

      String name;
      String url;
      String category;

      // Una URL puede acabar en ';' (típico de Shoutcast: http://host:8000/;)
      // por eso solo separamos por ';' si la línea NO empieza por http
      if (!line.startsWith('http') && line.contains(';')) {
        final parts = line.split(';').map((p) => p.trim()).toList();
        name = parts[0];
        url = parts.length > 1 ? parts[1] : '';
        category = parts.length > 2 ? parts[2] : '';
      } else {
        url = line;
        name = pendingName ?? '';
        category = pendingCategory ?? '';
      }
      pendingName = null;
      pendingCategory = null;

      if (!url.startsWith('http://') && !url.startsWith('https://')) continue;
      if (name.isEmpty) name = Uri.tryParse(url)?.host ?? url;

      stations.add(
        Station(
          id: Station.newId(salt++),
          name: name,
          url: url,
          category: category.isEmpty ? 'Sin categoría' : category,
        ),
      );
    }
    return stations;
  }

  /// Genera el formato 1 (Nombre;URL;Categoría), compatible con parse()
  static String toText(List<Station> stations) {
    return stations
        .map((s) => '${_clean(s.name)};${s.url};${_clean(s.category)}')
        .join('\n');
  }

  // El ';' es el separador, así que lo sustituimos si aparece en un nombre
  static String _clean(String value) => value.replaceAll(';', ',');
}
