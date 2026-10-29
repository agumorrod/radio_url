import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/podcast.dart';

/// Repositorio de configuración - similar a un @Repository en Spring Boot
/// Gestiona la persistencia local con SharedPreferences
class SettingsRepository {
  static const String _radioUrlKey = 'radio_stream_url';
  static const String _favoritesKey = 'favorite_podcasts';

  // ─── Radio URL ───────────────────────────────────────────────────────────────

  Future<String?> getRadioUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_radioUrlKey);
  }

  Future<void> saveRadioUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_radioUrlKey, url);
  }

  // ─── Favoritos ───────────────────────────────────────────────────────────────

  Future<List<Podcast>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_favoritesKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Podcast.fromJson(e)).toList();
  }

  Future<void> saveFavorites(List<Podcast> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(favorites.map((p) => p.toJson()).toList());
    await prefs.setString(_favoritesKey, jsonString);
  }

  Future<void> addFavorite(Podcast podcast) async {
    final favorites = await getFavorites();
    final exists = favorites.any((p) => p.id == podcast.id);
    if (!exists) {
      favorites.add(podcast.copyWith(isFavorite: true));
      await saveFavorites(favorites);
    }
  }

  Future<void> removeFavorite(String podcastId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((p) => p.id == podcastId);
    await saveFavorites(favorites);
  }
}
