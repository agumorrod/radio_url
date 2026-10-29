import 'package:dio/dio.dart';
import '../models/podcast.dart';

class PodcastRepository {
  final Dio _dio;

  PodcastRepository()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  Future<List<Podcast>> fetchPodcasts(String ivooxFeedUrl) async {
    try {
      final response = await _dio.get(
        ivooxFeedUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/rss+xml, application/xml, text/xml'},
        ),
      );
      return _parseRssFeed(response.data as String);
    } on DioException catch (e) {
      throw Exception('Error al cargar podcasts: ${e.message}');
    }
  }

  List<Podcast> _parseRssFeed(String xmlContent) {
    final List<Podcast> podcasts = [];
    final itemPattern = RegExp(r'<item>([\s\S]*?)</item>', multiLine: true);
    final items = itemPattern.allMatches(xmlContent);

    int index = 0;
    for (final item in items) {
      final itemContent = item.group(1) ?? '';

      final title = _extractTag(itemContent, 'title') ?? 'Sin título';
      final imageUrl =
          _extractAttribute(itemContent, 'itunes:image', 'href') ?? '';
      final duration = _extractTag(itemContent, 'itunes:duration') ?? '0:00';
      final rawDate = _extractTag(itemContent, 'pubDate') ?? '';
      final streamUrl =
          _extractAttribute(itemContent, 'enclosure', 'url') ?? '';
      final guid = _extractTag(itemContent, 'guid') ?? 'podcast_$index';

      if (streamUrl.isNotEmpty) {
        podcasts.add(
          Podcast(
            id: guid,
            title: title,
            imageUrl: imageUrl,
            duration: _formatDuration(duration),
            date: _formatDateDisplay(rawDate), // String para mostrar en UI
            pubDate: _parseDateToDateTime(rawDate), // DateTime para ordenar
            streamUrl: streamUrl,
          ),
        );
      }
      index++;
    }

    return podcasts;
  }

  String? _extractTag(String content, String tag) {
    final pattern = RegExp(
      '<$tag[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]></$tag>|<$tag[^>]*>([^<]*)</$tag>',
    );
    final match = pattern.firstMatch(content);
    return match?.group(1)?.trim() ?? match?.group(2)?.trim();
  }

  String? _extractAttribute(String content, String tag, String attribute) {
    final pattern = RegExp('<$tag[^>]*$attribute="([^"]*)"[^>]*/?>');
    return pattern.firstMatch(content)?.group(1);
  }

  // Convierte "Tue, 14 Apr 2026 14:12:25 +0200" a DateTime
  DateTime _parseDateToDateTime(String pubDate) {
    try {
      const months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };
      final parts = pubDate.trim().split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        final day = int.parse(parts[1]);
        final month = months[parts[2]] ?? 1;
        final year = int.parse(parts[3]);
        final time = parts[4].split(':');
        final hour = int.parse(time[0]);
        final min = int.parse(time[1]);
        final sec = time.length > 2 ? int.parse(time[2]) : 0;
        return DateTime(year, month, day, hour, min, sec);
      }
    } catch (_) {}
    return DateTime(2000);
  }

  // Convierte "Tue, 14 Apr 2026 14:12:25 +0200" a "14 abr 2026"
  String _formatDateDisplay(String pubDate) {
    try {
      const monthsEs = {
        'Jan': 'ene',
        'Feb': 'feb',
        'Mar': 'mar',
        'Apr': 'abr',
        'May': 'may',
        'Jun': 'jun',
        'Jul': 'jul',
        'Aug': 'ago',
        'Sep': 'sep',
        'Oct': 'oct',
        'Nov': 'nov',
        'Dec': 'dic',
      };
      final parts = pubDate.trim().split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        final day = parts[1];
        final month = monthsEs[parts[2]] ?? parts[2].toLowerCase();
        final year = parts[3];
        return '$day $month $year';
      }
    } catch (_) {}
    return pubDate;
  }

  String _formatDuration(String duration) {
    if (duration.contains(':')) return duration;
    final seconds = int.tryParse(duration) ?? 0;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

List<Podcast> getMockPodcasts() {
  return [
    Podcast(
      id: '1',
      title: 'El futuro de la música digital',
      imageUrl: 'https://picsum.photos/seed/pod1/200/200',
      duration: '45:30',
      date: '20 feb 2026',
      pubDate: DateTime(2026, 2, 20),
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    ),
    Podcast(
      id: '2',
      title: 'Entrevista: Artistas emergentes',
      imageUrl: 'https://picsum.photos/seed/pod2/200/200',
      duration: '38:15',
      date: '19 feb 2026',
      pubDate: DateTime(2026, 2, 19),
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    ),
    Podcast(
      id: '3',
      title: 'Historia del rock alternativo',
      imageUrl: 'https://picsum.photos/seed/pod3/200/200',
      duration: '52:45',
      date: '18 feb 2026',
      pubDate: DateTime(2026, 2, 18),
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    ),
    Podcast(
      id: '4',
      title: 'Análisis: Tendencias musicales 2026',
      imageUrl: 'https://picsum.photos/seed/pod4/200/200',
      duration: '41:20',
      date: '17 feb 2026',
      pubDate: DateTime(2026, 2, 17),
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    ),
    Podcast(
      id: '5',
      title: 'Los mejores festivales del año',
      imageUrl: 'https://picsum.photos/seed/pod5/200/200',
      duration: '33:10',
      date: '16 feb 2026',
      pubDate: DateTime(2026, 2, 16),
      streamUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    ),
  ];
}
