/// Traduce el error técnico de ExoPlayer / just_audio a un motivo legible
/// para el registro de errores
String describePlaybackError(Object error) {
  final text = error.toString().toLowerCase();

  // "Response code: 404" → el servidor existe pero la URL no es válida
  final code = RegExp(r'response code:?\s*(\d{3})').firstMatch(text)?.group(1);
  if (code != null) return 'el servidor respondió con el error $code';

  if (text.contains('unable to resolve host') ||
      text.contains('unknownhost') ||
      text.contains('no address associated')) {
    return 'no se encuentra el servidor (dirección incorrecta o sin internet)';
  }
  if (text.contains('timeout') || text.contains('timed out')) {
    return 'tiempo de espera agotado';
  }
  if (text.contains('cleartext')) {
    return 'conexión HTTP no permitida en este dispositivo';
  }
  if (text.contains('connection refused') ||
      text.contains('failed to connect') ||
      text.contains('network is unreachable')) {
    return 'no se pudo conectar con el servidor';
  }
  if (text.contains('unrecognizedinputformat') ||
      text.contains('could not parse') ||
      text.contains('source error')) {
    return 'formato de audio no reconocido o el servidor no emite un streaming';
  }
  return 'error desconocido';
}
