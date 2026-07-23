import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/service_event.dart';

class ServiceEventStorageService {
  static const String storageKey = 'biblias_service_events_v1';

  static Future<List<ServiceEvent>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final events = <ServiceEvent>[];
    for (final encoded in prefs.getStringList(storageKey) ?? const []) {
      try {
        events.add(
          ServiceEvent.fromJson(
            Map<String, dynamic>.from(jsonDecode(encoded) as Map),
          ),
        );
      } catch (_) {
        // Un registro corrupto no impide consultar los restantes.
      }
    }
    return events;
  }

  static Future<void> addEvent(ServiceEvent event) async {
    final events = await loadEvents()
      ..removeWhere((existing) => existing.eventId == event.eventId)
      ..add(event);
    await saveEvents(events);
  }

  static Future<void> saveEvents(List<ServiceEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = <String, ServiceEvent>{
      for (final event in events) event.eventId: event,
    }.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final saved = await prefs.setStringList(
      storageKey,
      normalized.map((event) => jsonEncode(event.toJson())).toList(),
    );
    if (!saved) throw StateError('No se pudo guardar el histórico');
  }
}
