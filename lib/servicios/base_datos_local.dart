import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Servicio de almacenamiento local simple usando solo Flutter
/// En una implementación real, se usaría shared_preferences
class BaseDatosLocal {
  static BaseDatosLocal? _instance;
  static BaseDatosLocal get instance => _instance ??= BaseDatosLocal._();

  BaseDatosLocal._();

  // Simulación de almacenamiento en memoria para desarrollo
  final Map<String, String> _storage = {};

  /// Guardar un string
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
    debugPrint('=ñ Guardado: $key = $value');
  }

  /// Obtener un string
  Future<String?> getString(String key) async {
    final value = _storage[key];
    debugPrint('=ñ Leído: $key = $value');
    return value;
  }

  /// Guardar un int
  Future<void> setInt(String key, int value) async {
    _storage[key] = value.toString();
    debugPrint('=ñ Guardado: $key = $value');
  }

  /// Obtener un int
  Future<int?> getInt(String key) async {
    final value = _storage[key];
    if (value != null) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Guardar un double
  Future<void> setDouble(String key, double value) async {
    _storage[key] = value.toString();
    debugPrint('=ñ Guardado: $key = $value');
  }

  /// Obtener un double
  Future<double?> getDouble(String key) async {
    final value = _storage[key];
    if (value != null) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Guardar un bool
  Future<void> setBool(String key, bool value) async {
    _storage[key] = value.toString();
    debugPrint('=ñ Guardado: $key = $value');
  }

  /// Obtener un bool
  Future<bool?> getBool(String key) async {
    final value = _storage[key];
    if (value != null) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  /// Guardar una lista de strings
  Future<void> setStringList(String key, List<String> value) async {
    _storage[key] = json.encode(value);
    debugPrint('=ñ Guardado: $key = $value');
  }

  /// Obtener una lista de strings
  Future<List<String>?> getStringList(String key) async {
    final value = _storage[key];
    if (value != null) {
      try {
        final List<dynamic> decoded = json.decode(value);
        return decoded.cast<String>();
      } catch (e) {
        debugPrint('Error decodificando lista: $e');
        return null;
      }
    }
    return null;
  }

  /// Guardar un Map como JSON
  Future<void> setMap(String key, Map<String, dynamic> value) async {
    _storage[key] = json.encode(value);
    debugPrint('=ñ Guardado: $key = ${value.toString()}');
  }

  /// Obtener un Map desde JSON
  Future<Map<String, dynamic>?> getMap(String key) async {
    final value = _storage[key];
    if (value != null) {
      try {
        return json.decode(value);
      } catch (e) {
        debugPrint('Error decodificando map: $e');
        return null;
      }
    }
    return null;
  }

  /// Verificar si existe una clave
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  /// Eliminar una clave
  Future<void> remove(String key) async {
    _storage.remove(key);
    debugPrint('=ñ Eliminado: $key');
  }

  /// Limpiar todo el almacenamiento
  Future<void> clear() async {
    _storage.clear();
    debugPrint('=ñ Almacenamiento limpiado');
  }

  /// Obtener todas las claves
  Future<Set<String>> getKeys() async {
    return _storage.keys.toSet();
  }

  /// Obtener el tamaño del almacenamiento (número de claves)
  Future<int> getSize() async {
    return _storage.length;
  }

  /// Mostrar todo el contenido (para debug)
  void debugPrint() {
    debugPrint('=== ALMACENAMIENTO LOCAL ===');
    for (final entry in _storage.entries) {
      debugPrint('${entry.key}: ${entry.value}');
    }
    debugPrint('===========================');
  }

  /// Métodos de conveniencia para objetos complejos

  /// Guardar configuración de usuario
  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    await setMap('user_preferences', preferences);
  }

  /// Obtener configuración de usuario
  Future<Map<String, dynamic>?> getUserPreferences() async {
    return await getMap('user_preferences');
  }

  /// Guardar historial de búsquedas
  Future<void> addSearchHistory(String searchTerm) async {
    final history = await getStringList('search_history') ?? [];

    // Remover si ya existe para evitar duplicados
    history.remove(searchTerm);

    // Agregar al inicio
    history.insert(0, searchTerm);

    // Mantener solo los últimos 10
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }

    await setStringList('search_history', history);
  }

  /// Obtener historial de búsquedas
  Future<List<String>> getSearchHistory() async {
    return await getStringList('search_history') ?? [];
  }

  /// Limpiar historial de búsquedas
  Future<void> clearSearchHistory() async {
    await remove('search_history');
  }

  /// Guardar productos favoritos
  Future<void> addFavoriteProduct(String productId) async {
    final favorites = await getStringList('favorite_products') ?? [];
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await setStringList('favorite_products', favorites);
    }
  }

  /// Remover producto favorito
  Future<void> removeFavoriteProduct(String productId) async {
    final favorites = await getStringList('favorite_products') ?? [];
    favorites.remove(productId);
    await setStringList('favorite_products', favorites);
  }

  /// Obtener productos favoritos
  Future<List<String>> getFavoriteProducts() async {
    return await getStringList('favorite_products') ?? [];
  }

  /// Verificar si un producto es favorito
  Future<bool> isFavoriteProduct(String productId) async {
    final favorites = await getFavoriteProducts();
    return favorites.contains(productId);
  }

  /// Guardar configuración de tema
  Future<void> setThemeMode(String themeMode) async {
    await setString('theme_mode', themeMode);
  }

  /// Obtener configuración de tema
  Future<String> getThemeMode() async {
    return await getString('theme_mode') ?? 'system';
  }

  /// Guardar idioma preferido
  Future<void> setLanguage(String languageCode) async {
    await setString('language', languageCode);
  }

  /// Obtener idioma preferido
  Future<String> getLanguage() async {
    return await getString('language') ?? 'es';
  }

  /// Guardar configuración de notificaciones
  Future<void> setNotificationSettings(Map<String, bool> settings) async {
    await setMap('notification_settings', settings.map((k, v) => MapEntry(k, v)));
  }

  /// Obtener configuración de notificaciones
  Future<Map<String, bool>> getNotificationSettings() async {
    final settings = await getMap('notification_settings') ?? {};
    return settings.map((k, v) => MapEntry(k, v as bool));
  }

  /// Guardar carrito de compras
  Future<void> setShoppingCart(Map<String, dynamic> cart) async {
    await setMap('shopping_cart', cart);
  }

  /// Obtener carrito de compras
  Future<Map<String, dynamic>?> getShoppingCart() async {
    return await getMap('shopping_cart');
  }

  /// Limpiar carrito de compras
  Future<void> clearShoppingCart() async {
    await remove('shopping_cart');
  }

  /// Guardar filtros de búsqueda
  Future<void> setSearchFilters(Map<String, dynamic> filters) async {
    await setMap('search_filters', filters);
  }

  /// Obtener filtros de búsqueda
  Future<Map<String, dynamic>?> getSearchFilters() async {
    return await getMap('search_filters');
  }
}