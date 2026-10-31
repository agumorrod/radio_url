import 'package:flutter/material.dart';
import '../utils/text_utils.dart';

/// Catálogo de iconos de emisora y reglas para elegir uno según la categoría
class StationIcons {
  StationIcons._();

  /// Iconos que se pueden elegir a mano (clave → icono).
  /// Lo que se guarda en la emisora es la CLAVE, no el icono en sí.
  static const Map<String, IconData> catalog = {
    'radio': Icons.radio,
    'music': Icons.music_note,
    'playlist': Icons.queue_music,
    'headphones': Icons.headphones,
    'wave': Icons.graphic_eq,
    'talk': Icons.mic,
    'news': Icons.newspaper,
    'sports': Icons.sports_soccer,
    'religion': Icons.church,
    'education': Icons.school,
    'culture': Icons.theater_comedy,
    'local': Icons.location_city,
    'world': Icons.public,
    'kids': Icons.child_care,
    'humor': Icons.emoji_emotions,
    'tech': Icons.computer,
    'weather': Icons.wb_sunny,
    'travel': Icons.flight,
  };

  // Si quieres otros iconos o más reglas, _rules en station_icons.dart es una
  //lista de una línea por regla. Por ejemplo, para que “Flamenco” tenga su
  //propio icono, bastaría añadir la clave al catálogo y una regla.

  /// Reglas automáticas: si la categoría (sin tildes ni mayúsculas) CONTIENE
  /// alguna de las palabras, se usa ese icono. Gana la primera regla que coincida,
  /// así que "Noticias locales" da noticias y no ciudad.
  /// Para añadir una regla nueva basta con añadir una línea.
  static const List<(String, List<String>)> _rules = [
    ('news', ['noticia', 'news', 'informaci', 'actualidad', 'prensa']),
    ('sports', ['deport', 'sport', 'futbol', 'baloncesto', 'motor']),
    (
      'religion',
      ['religi', 'cristian', 'catoli', 'gospel', 'iglesia', 'evangel'],
    ),
    ('education', ['educa', 'univers', 'escuela', 'ciencia']),
    ('culture', ['cultur', 'teatro', 'cine', 'literatur']),
    ('kids', ['infantil', 'nino', 'kids', 'juvenil']),
    ('humor', ['humor', 'comedia']),
    ('tech', ['tecnolog', 'tech', 'gaming', 'videojuego', 'informatica']),
    ('travel', ['viaje', 'turismo', 'travel']),
    ('weather', ['tiempo', 'meteo', 'clima']),
    (
      'talk',
      [
        'tertulia',
        'charla',
        'hablad',
        'talk',
        'entrevista',
        'debate',
        'podcast',
      ],
    ),
    (
      'music',
      [
        'musica',
        'music',
        'pop',
        'rock',
        'jazz',
        'clasic',
        'latin',
        'dance',
        'hits',
        'flamenco',
        'reggae',
        'hip hop',
        'electronic',
        'indie',
        'oldies',
        'blues',
        'country',
        'folk',
        'cancion',
      ],
    ),
    ('world', ['internacional', 'mundo', 'world', 'global']),
    (
      'local',
      [
        'local',
        'municipal',
        'ciudad',
        'pueblo',
        'regional',
        'comarcal',
        'provincial',
      ],
    ),
  ];

  /// Clave del icono que correspondería a una categoría ('radio' si no hay regla)
  static String autoKeyForCategory(String category) {
    final text = normalizeText(category);
    for (final (key, words) in _rules) {
      for (final word in words) {
        if (text.contains(word)) return key;
      }
    }
    return 'radio';
  }

  /// Icono final de una emisora: el elegido a mano (iconKey) o, si no hay,
  /// el automático según su categoría
  static IconData iconFor(String? iconKey, String category) {
    final key = (iconKey != null && catalog.containsKey(iconKey))
        ? iconKey
        : autoKeyForCategory(category);
    return catalog[key] ?? Icons.radio;
  }
}
