import 'package:shared_preferences/shared_preferences.dart';

class AccidentLogStore {
  static const _key = 'accident_logs';
  static List<String> _cache = [];

  /// Call once at startup (see main.dart).
  static Future<void> init() async {
    if (_cache.isNotEmpty) return;          // already loaded
    final prefs = await SharedPreferences.getInstance();
    _cache = prefs.getStringList(_key) ?? [];
  }

  static List<String> get logs => List.unmodifiable(_cache);

  static Future<void> add(String entry) async {
    _cache.add(entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _cache);
  }

  static Future<void> clear() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
