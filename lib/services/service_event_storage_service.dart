import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_event.dart';

class ServiceEventStorageService {
  static const String _key = 'service_events_v1';

  static Future<List<ServiceEvent>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getStringList(_key);

    if (stored == null) {
      return [];
    }

    return stored
        .map(
          (e) => ServiceEvent.fromJson(
        jsonDecode(e) as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  static Future<void> saveEvents(
      List<ServiceEvent> events,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      events.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}