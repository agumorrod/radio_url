import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/station.dart';

/// Repositorio de configuración - similar a un @Repository en Spring Boot
/// Gestiona la persistencia local con SharedPreferences
class SettingsRepository {
  static const String _radioUrlKey = 'radio_stream_url';
  static const String _stationsKey = 'stations_list';
  static const String _currentStationKey = 'current_station_id';
  static const String _addButtonXKey = 'add_button_x';
  static const String _addButtonYKey = 'add_button_y';

  // ─── Radio URL ───────────────────────────────────────────────────────────────

  Future<String?> getRadioUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_radioUrlKey);
  }

  Future<void> saveRadioUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_radioUrlKey, url);
  }

  // ─── Emisoras ────────────────────────────────────────────────────────────────

  /// Distingue "nunca se ha guardado la lista" de "la lista está vacía"
  /// (así solo se crea la emisora por defecto la primera vez)
  Future<bool> hasStations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_stationsKey);
  }

  Future<List<Station>> getStations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_stationsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Station.fromJson(e)).toList();
  }

  /// Guarda TODA la lista en una sola clave JSON. Con 200 emisoras son ~40 KB.
  /// Los favoritos no se guardan aparte: son el campo isFavorite de cada emisora.
  Future<void> saveStations(List<Station> stations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(stations.map((s) => s.toJson()).toList());
    await prefs.setString(_stationsKey, jsonString);
  }

  // ─── Emisora actual (la que se carga en Inicio) ──────────────────────────────

  Future<String?> getCurrentStationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentStationKey);
  }

  Future<void> saveCurrentStationId(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentStationKey, stationId);
  }

  Future<void> clearCurrentStationId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentStationKey);
  }

  // ─── Posición del botón "+" ──────────────────────────────────────────────────

  /// Se guarda como fracción (0.0 a 1.0) del espacio disponible, no en píxeles,
  /// así sigue siendo válida si cambia el tamaño de la pantalla.
  /// Devuelve [x, y] o null si el usuario nunca lo ha movido.
  Future<List<double>?> getAddButtonPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_addButtonXKey);
    final y = prefs.getDouble(_addButtonYKey);
    if (x == null || y == null) return null;
    return [x, y];
  }

  Future<void> saveAddButtonPosition(double x, double y) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_addButtonXKey, x);
    await prefs.setDouble(_addButtonYKey, y);
  }
}
