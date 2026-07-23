import 'package:shared_preferences/shared_preferences.dart';

class ProcessedServicesStorage {
  static const String storageKey = 'biblias_processed_services_v1';

  static Future<Set<String>> loadProcessed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(storageKey) ?? const []).toSet();
  }

  static Future<void> markAsProcessed(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final processed = (prefs.getStringList(storageKey) ?? const []).toSet()
      ..add(eventId);
    final saved = await prefs.setStringList(
      storageKey,
      processed.toList()..sort(),
    );
    if (!saved) throw StateError('No se pudo contabilizar el culto');
  }
}
