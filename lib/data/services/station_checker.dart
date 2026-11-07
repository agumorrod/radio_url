import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/station.dart';
import 'stream_resolver.dart';

/// Comprueba si una emisora RESPONDE, sin reproducirla.
///
/// Es barato a propósito: solo se espera a las cabeceras HTTP y se cierra la
/// conexión sin leer audio, así que casi no gasta datos ni batería.
/// No decodifica el audio: una URL que responda pero no sea un streaming real
/// se dará por buena hasta que se intente reproducir.
class StationChecker {
  final StreamResolver _resolver;

  StationChecker(this._resolver);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      followRedirects: true,
      maxRedirects: 4,
      // Los 4xx y 5xx cuentan como emisora caída
      validateStatus: (status) => status != null && status < 400,
      headers: {'User-Agent': 'Mozilla/5.0 (Linux; Android 14) RadioApp'},
    ),
  );

  /// Sin internet TODAS las emisoras fallarían: se comprueba antes para no
  /// marcarlas como caídas por error
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Devuelve null si la emisora responde, o el motivo en texto si no
  Future<String?> check(String url) async {
    final cancelToken = CancelToken();
    try {
      // Si es un .m3u / .pls, se comprueba la URL real que contiene
      final streamUrl = await _resolver.resolve(url);

      final response = await _dio
          .get<ResponseBody>(
            streamUrl,
            options: Options(responseType: ResponseType.stream),
            cancelToken: cancelToken,
          )
          .timeout(const Duration(seconds: 10));

      // Ya tenemos las cabeceras: responde. Cancelar la suscripción cierra la
      // conexión sin descargar nada de audio
      await response.data?.stream.listen((_) {}).cancel();
      return null;
    } on TimeoutException {
      cancelToken.cancel('tiempo agotado');
      return 'tiempo de espera agotado';
    } on DioException catch (e) {
      return _describe(e);
    } catch (_) {
      // Algo inesperado: ante la duda NO se marca la emisora como caída
      return null;
    }
  }

  String? _describe(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'tiempo de espera agotado';
      case DioExceptionType.badResponse:
        return 'el servidor respondió con el error ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return 'no se pudo conectar con el servidor';
      case DioExceptionType.badCertificate:
        return 'certificado HTTPS no válido';
      case DioExceptionType.cancel:
        return null; // la hemos cancelado nosotros
      case DioExceptionType.unknown:
        final inner = e.error;
        if (inner is SocketException) {
          return 'no se pudo conectar con el servidor';
        }
        if (inner is HandshakeException) {
          return 'error de seguridad HTTPS';
        }
        // Respuestas raras, como el "ICY 200 OK" de algunos Shoutcast: Dart no
        // sabe leerlas pero ExoPlayer sí. Si el servidor contesta, lo damos por bueno.
        return null;
    }
  }

  /// Comprueba muchas emisoras con pocas conexiones simultáneas (por defecto 4),
  /// para que 200 emisoras no saturen la red ni el móvil.
  /// 'onResult' se llama por cada emisora según va terminando.
  Future<void> checkAll(
    List<Station> stations, {
    required void Function(Station station, String? failure) onResult,
    int concurrency = 4,
  }) async {
    final queue = Queue<Station>.of(stations);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final station = queue.removeFirst();
        onResult(station, await check(station.url));
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
  }
}
