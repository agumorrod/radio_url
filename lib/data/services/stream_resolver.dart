import 'package:dio/dio.dart';

/// Resuelve listas de reproducción (.m3u / .pls) a la URL real del streaming.
///
/// ExoPlayer (just_audio en Android) reproduce MP3, AAC y HLS (.m3u8), pero NO
/// entiende los .m3u / .pls: son archivos de texto que contienen la URL de verdad.
class StreamResolver {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  Future<String> resolve(String url) async {
    // Ignoramos la query (?token=...) para mirar solo la extensión
    final path = url.toLowerCase().split('?').first;

    // OJO: '.m3u8' NO termina en '.m3u', así que el HLS pasa sin tocarse
    final isM3u = path.endsWith('.m3u');
    final isPls = path.endsWith('.pls');
    if (!isM3u && !isPls) return url;

    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.plain),
      );

      for (final raw in (response.data as String).split(RegExp(r'\r?\n'))) {
        var line = raw.trim();
        // .pls → "File1=http://..."
        if (isPls && line.toLowerCase().startsWith('file1=')) {
          line = line.substring(6).trim();
        }
        // .m3u → primera línea que no sea comentario (#...) y sea una URL
        if (line.startsWith('http://') || line.startsWith('https://')) {
          return line;
        }
      }
    } catch (_) {
      // Si falla la descarga devolvemos la URL original y que ExoPlayer decida
    }
    return url;
  }
}
