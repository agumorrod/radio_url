/// Modelo de una Emisora - equivalente a un DTO en Spring Boot
class Station {
  final String id;
  final String name;
  final String url; // URL del streaming (mp3, aac, m3u8, m3u, pls...)
  final String category; // ej: "Local", "Música", "Noticias"
  final String?
  iconKey; // icono elegido a mano; null = automático según la categoría
  bool isFavorite;

  Station({
    required this.id,
    required this.name,
    required this.url,
    this.category = 'Sin categoría',
    this.iconKey,
    this.isFavorite = false,
  });

  /// Genera un id único. El parámetro 'salt' evita colisiones cuando se crean
  /// muchas emisoras en el mismo instante (por ejemplo al importar un listado)
  static String newId([int salt = 0]) =>
      '${DateTime.now().microsecondsSinceEpoch}_$salt';

  /// Crea una copia con campos modificados (inmutabilidad controlada)
  Station copyWith({
    String? id,
    String? name,
    String? url,
    String? category,
    String? iconKey,
    bool? isFavorite,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      category: category ?? this.category,
      iconKey: iconKey ?? this.iconKey,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Serialización a Map para guardar en SharedPreferences
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'category': category,
    'iconKey': iconKey,
    'isFavorite': isFavorite,
  };

  /// Deserialización desde Map. Las emisoras guardadas antes de existir los
  /// iconos no tienen 'iconKey': se leen como null (icono automático).
  factory Station.fromJson(Map<String, dynamic> json) => Station(
    id: json['id'],
    name: json['name'],
    url: json['url'],
    category: json['category'] ?? 'Sin categoría',
    iconKey: json['iconKey'],
    isFavorite: json['isFavorite'] ?? false,
  );
}
