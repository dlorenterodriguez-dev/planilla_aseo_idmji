import 'package:shared_preferences/shared_preferences.dart';

class ProcessedServicesStorage {
  static const _key = 'processed_services_v1';

  static Future<Set<String>> loadProcessed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  static Future<void> markAsProcessed(String eventId) async {
    final prefs = await SharedPreferences.getInstance();

    final processed = (prefs.getStringList(_key) ?? []).toSet();
    processed.add(eventId);

    await prefs.setStringList(_key, processed.toList());
  }

  static Future<bool> isProcessed(String eventId) async {
    final processed = await loadProcessed();
    return processed.contains(eventId);
  }
}