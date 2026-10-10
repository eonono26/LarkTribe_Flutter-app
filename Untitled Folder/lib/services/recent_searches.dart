import 'package:shared_preferences/shared_preferences.dart';

/// Search history kept on the device (no backend endpoint for this).
class RecentSearches {
  static const _key = 'recent_searches';
  static const _max = 6;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  static Future<List<String>> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return load();
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(_key) ?? <String>[])
      ..removeWhere((e) => e.toLowerCase() == q.toLowerCase())
      ..insert(0, q);
    final trimmed = list.take(_max).toList();
    await prefs.setStringList(_key, trimmed);
    return trimmed;
  }

  static Future<List<String>> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(_key) ?? <String>[])..remove(query);
    await prefs.setStringList(_key, list);
    return list;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
