/// Modelo de un Podcast - equivalente a un DTO en Spring Boot
class Podcast {
  final String id;
  final String title;
  final String imageUrl;
  final String duration; // ej: "45:30" — para mostrar en UI
  final String date; // ej: "20 feb 2026" — para mostrar en UI
  final DateTime pubDate; // fecha real para ordenar correctamente
  final String streamUrl;
  bool isFavorite;

  Podcast({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.duration,
    required this.date,
    required this.pubDate,
    required this.streamUrl,
    this.isFavorite = false,
  });

  Podcast copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? duration,
    String? date,
    DateTime? pubDate,
    String? streamUrl,
    bool? isFavorite,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      pubDate: pubDate ?? this.pubDate,
      streamUrl: streamUrl ?? this.streamUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'duration': duration,
    'date': date,
    'pubDate': pubDate.toIso8601String(),
    'streamUrl': streamUrl,
    'isFavorite': isFavorite,
  };

  factory Podcast.fromJson(Map<String, dynamic> json) => Podcast(
    id: json['id'],
    title: json['title'],
    imageUrl: json['imageUrl'],
    duration: json['duration'],
    date: json['date'],
    pubDate: json['pubDate'] != null
        ? DateTime.tryParse(json['pubDate']) ?? DateTime(2000)
        : DateTime(2000),
    streamUrl: json['streamUrl'],
    isFavorite: json['isFavorite'] ?? false,
  );
}
