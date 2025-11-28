import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/emprendimiento_model.dart';

class EmprendimientosLocalDataSource {
  final SharedPreferences sharedPreferences;

  EmprendimientosLocalDataSource({required this.sharedPreferences});

  static const String _emprendimientosKey = 'cached_emprendimientos';
  static const String _lastUpdateKey = 'emprendimientos_last_update';
  static const String _favoritesKey = 'favorite_emprendimientos';
  static const String _searchHistoryKey = 'search_history';
  static const Duration _cacheValidDuration = Duration(hours: 2);

  // Cache emprendimientos
  Future<bool> cacheEmprendimientos(List<Emprendimiento> emprendimientos) async {
    try {
      final jsonList = emprendimientos.map((e) => e.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await sharedPreferences.setString(_emprendimientosKey, jsonString);
      await sharedPreferences.setInt(
        _lastUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get cached emprendimientos
  Future<List<Emprendimiento>?> getCachedEmprendimientos() async {
    try {
      if (!_isCacheValid()) return null;
      
      final jsonString = sharedPreferences.getString(_emprendimientosKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => Emprendimiento.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  // Check if cache is valid
  bool _isCacheValid() {
    final lastUpdate = sharedPreferences.getInt(_lastUpdateKey);
    if (lastUpdate == null) return false;

    final lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    final now = DateTime.now();
    
    return now.difference(lastUpdateTime) < _cacheValidDuration;
  }

  // Clear cache
  Future<bool> clearCache() async {
    try {
      await sharedPreferences.remove(_emprendimientosKey);
      await sharedPreferences.remove(_lastUpdateKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Favorites management
  Future<bool> addToFavorites(int emprendimientoId) async {
    try {
      final favorites = await getFavorites();
      if (!favorites.contains(emprendimientoId)) {
        favorites.add(emprendimientoId);
        final jsonString = json.encode(favorites);
        await sharedPreferences.setString(_favoritesKey, jsonString);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromFavorites(int emprendimientoId) async {
    try {
      final favorites = await getFavorites();
      favorites.remove(emprendimientoId);
      final jsonString = json.encode(favorites);
      await sharedPreferences.setString(_favoritesKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<int>> getFavorites() async {
    try {
      final jsonString = sharedPreferences.getString(_favoritesKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<int>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> isFavorite(int emprendimientoId) async {
    final favorites = await getFavorites();
    return favorites.contains(emprendimientoId);
  }

  // Search history management
  Future<bool> addToSearchHistory(String searchTerm) async {
    try {
      final history = await getSearchHistory();
      // Remove if already exists to avoid duplicates
      history.remove(searchTerm);
      // Add to beginning
      history.insert(0, searchTerm);
      // Keep only last 10 searches
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }
      
      final jsonString = json.encode(history);
      await sharedPreferences.setString(_searchHistoryKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getSearchHistory() async {
    try {
      final jsonString = sharedPreferences.getString(_searchHistoryKey);
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> clearSearchHistory() async {
    try {
      await sharedPreferences.remove(_searchHistoryKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // User preferences
  Future<bool> saveFilterPreferences({
    String? categoria,
    String? parroquia,
    String? ordenarPor,
  }) async {
    try {
      final preferences = {
        'categoria': categoria,
        'parroquia': parroquia,
        'ordenar_por': ordenarPor,
      };
      
      final jsonString = json.encode(preferences);
      await sharedPreferences.setString('filter_preferences', jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String?>> getFilterPreferences() async {
    try {
      final jsonString = sharedPreferences.getString('filter_preferences');
      if (jsonString == null) {
        return {
          'categoria': null,
          'parroquia': null,
          'ordenar_por': null,
        };
      }
      
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return {
        'categoria': jsonMap['categoria'] as String?,
        'parroquia': jsonMap['parroquia'] as String?,
        'ordenar_por': jsonMap['ordenar_por'] as String?,
      };
    } catch (e) {
      return {
        'categoria': null,
        'parroquia': null,
        'ordenar_por': null,
      };
    }
  }

  // Cache individual emprendimiento
  Future<bool> cacheEmprendimiento(Emprendimiento emprendimiento) async {
    try {
      final key = 'emprendimiento_${emprendimiento.id}';
      final jsonString = json.encode(emprendimiento.toJson());
      await sharedPreferences.setString(key, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Emprendimiento?> getCachedEmprendimiento(int id) async {
    try {
      final key = 'emprendimiento_$id';
      final jsonString = sharedPreferences.getString(key);
      if (jsonString == null) return null;

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return Emprendimiento.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }
}