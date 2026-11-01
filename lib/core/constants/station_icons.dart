import 'package:flutter/material.dart';
import '../utils/text_utils.dart';

/// Un icono del catálogo: clave (lo que se guarda), nombre visible e icono
class StationIconOption {
  final String key;
  final String label;
  final IconData icon;

  const StationIconOption(this.key, this.label, this.icon);
}

/// Catálogo de iconos de emisora y reglas para elegir uno según la categoría
class StationIcons {
  StationIcons._();

  /// ✏️ AQUÍ SE AÑADEN ICONOS NUEVOS: una línea por icono.
  ///   StationIconOption('clave', 'Nombre visible', Icons.nombre_del_icono)
  /// - La CLAVE debe ser única, en minúsculas y sin espacios. Es lo que se guarda
  ///   en cada emisora, así que no la cambies una vez que la hayas usado.
  /// - El orden de esta lista es el orden en el desplegable.
  ///
  /// Cómo ver más iconos y añadir los tuyos

  // Los iconos son los Material Icons de Flutter. Para encontrar más:

  // En el navegador: entra en fonts.google.com/icons, busca por palabra (en inglés, por ejemplo “guitar” o “basketball”) y fíjate en el nombre del icono. En Flutter se escribe igual, en minúsculas y con guiones bajos: sports_basketball pasa a ser Icons.sports_basketball.
  // En VS Code: escribe Icons. y el autocompletado enseña una vista previa dibujada de cada icono. Es lo más rápido.

  // Para añadirlo, abre station_icons.dart y añade una línea a la lista options:

  // dart
  // StationIconOption('guitar', 'Guitarra', Icons.music_note),

  // Los tres valores son:

  // Clave ('guitar'): única, en minúsculas y sin espacios. Es lo que se guarda en cada emisora, así que no la cambies después de usarla.
  // Nombre visible ('Guitarra'): el que se muestra al lado del icono y al mantenerlo pulsado en la rejilla.
  // Icono (Icons.music_note): el de Material.

  // El orden de la lista es el orden en el desplegable. Después de editar el archivo, usa hot restart (R), porque es una constante y el hot reload normal no la recarga.

  // Si quieres que además se elija solo por categoría, añade una regla en _rules, por ejemplo ('guitar', ['guitarra', 'acustico']). La clave debe existir en options.

  // Si flutter analyze dice que Icons.algo no está definido, ese nombre no existe en tu versión de Flutter. Cámbialo por otro parecido, o dímelo y lo sustituyo.

  // Los iconos de Material son solo los que trae Flutter. Si más adelante quieres usar tus propias imágenes (PNG o SVG) como icono de emisora, es posible pero requiere otro mecanismo, y puedo prepararlo.
  static const List<StationIconOption> options = [
    // Radio y música
    StationIconOption('radio', 'Radio', Icons.radio),
    StationIconOption('music', 'Música', Icons.music_note),
    StationIconOption('playlist', 'Listas de música', Icons.queue_music),
    StationIconOption('library', 'Discos', Icons.library_music),
    StationIconOption('album', 'Álbum', Icons.album),
    StationIconOption('headphones', 'Auriculares', Icons.headphones),
    StationIconOption('wave', 'Ondas', Icons.graphic_eq),
    StationIconOption('equalizer', 'Ecualizador', Icons.equalizer),
    StationIconOption('speaker', 'Altavoz', Icons.speaker),
    // Voz y actualidad
    StationIconOption('talk', 'Charla', Icons.mic),
    StationIconOption('voice', 'Voz', Icons.record_voice_over),
    StationIconOption('podcast', 'Podcast', Icons.podcasts),
    StationIconOption('announce', 'Anuncio', Icons.campaign),
    StationIconOption('news', 'Noticias', Icons.newspaper),
    StationIconOption('politics', 'Política', Icons.account_balance),
    StationIconOption('people', 'Gente', Icons.groups),
    StationIconOption('solidarity', 'Solidaridad', Icons.volunteer_activism),
    // Deporte y motor
    StationIconOption('sports', 'Fútbol', Icons.sports_soccer),
    StationIconOption('basketball', 'Baloncesto', Icons.sports_basketball),
    StationIconOption('tennis', 'Tenis', Icons.sports_tennis),
    StationIconOption('motor', 'Motor', Icons.sports_motorsports),
    StationIconOption('car', 'Coche', Icons.directions_car),
    // Cultura y educación
    StationIconOption('religion', 'Religión', Icons.church),
    StationIconOption('education', 'Educación', Icons.school),
    StationIconOption('books', 'Libros', Icons.menu_book),
    StationIconOption('history', 'Historia', Icons.history_edu),
    StationIconOption('culture', 'Cultura', Icons.theater_comedy),
    StationIconOption('movie', 'Cine', Icons.movie),
    StationIconOption('tv', 'Televisión', Icons.tv),
    StationIconOption('language', 'Idiomas', Icons.translate),
    // Lugares
    StationIconOption('local', 'Local', Icons.location_city),
    StationIconOption('world', 'Mundo', Icons.public),
    // Ocio
    StationIconOption('kids', 'Infantil', Icons.child_care),
    StationIconOption('humor', 'Humor', Icons.emoji_emotions),
    StationIconOption('party', 'Fiesta', Icons.celebration),
    StationIconOption('night', 'Noche', Icons.nightlife),
    StationIconOption('food', 'Cocina', Icons.restaurant),
    StationIconOption('cafe', 'Café', Icons.local_cafe),
    // Otros
    StationIconOption('tech', 'Tecnología', Icons.computer),
    StationIconOption('health', 'Salud', Icons.health_and_safety),
    StationIconOption('weather', 'Tiempo', Icons.wb_sunny),
    StationIconOption('travel', 'Viajes', Icons.flight),
    StationIconOption('beach', 'Playa', Icons.beach_access),
    StationIconOption('nature', 'Naturaleza', Icons.park),
    StationIconOption('farm', 'Campo', Icons.agriculture),
    StationIconOption('pets', 'Mascotas', Icons.pets),
    StationIconOption('star', 'Estrella', Icons.star),
    StationIconOption('heart', 'Corazón', Icons.favorite),
  ];

  // Índice por clave para buscar rápido
  static final Map<String, StationIconOption> _byKey = {
    for (final option in options) option.key: option,
  };

  /// Reglas automáticas: si la categoría (sin tildes ni mayúsculas) CONTIENE
  /// alguna de las palabras, se usa ese icono. Gana la primera regla que coincida,
  /// así que "Noticias locales" da noticias y no ciudad.
  /// La clave de cada regla debe existir en 'options'.
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
    ('health', ['salud', 'medic', 'sanidad']),
    ('food', ['cocina', 'gastronom', 'receta']),
    ('farm', ['agricultur', 'campo', 'rural', 'naturaleza']),
    ('politics', ['politic', 'gobierno', 'ayuntamiento']),
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

  /// Nombre visible de un icono del catálogo (null si no existe)
  static String? labelFor(String? key) => _byKey[key]?.label;

  /// Icono final de una emisora: el elegido a mano (iconKey) o, si no hay,
  /// el automático según su categoría
  static IconData iconFor(String? iconKey, String category) {
    final key = (iconKey != null && _byKey.containsKey(iconKey))
        ? iconKey
        : autoKeyForCategory(category);
    return _byKey[key]?.icon ?? Icons.radio;
  }
}
