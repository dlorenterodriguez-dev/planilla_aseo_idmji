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

    final events = <ServiceEvent>[];

    for (final encodedEvent in stored) {
      try {
        final json = jsonDecode(encodedEvent) as Map<String, dynamic>;
        events.add(ServiceEvent.fromJson(json));
      } catch (_) {
        // Un registro corrupto no debe impedir consultar el resto del histórico.
      }
    }

    return events;
  }

  static Future<void> addEvent(ServiceEvent event) async {
    await addEvents([event]);
  }

  static Future<void> addEvents(List<ServiceEvent> newEvents) async {
    final events = await loadEvents();

    for (final event in newEvents) {
      final alreadyExists = events.any(
        (existing) =>
            existing.eventId == event.eventId &&
            existing.volunteerId == event.volunteerId &&
            existing.serviceType == event.serviceType &&
            existing.role == event.role &&
            existing.startTime == event.startTime &&
            existing.endTime == event.endTime,
      );

      if (!alreadyExists) {
        events.add(event);
      }
    }

    await saveEvents(events);
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
