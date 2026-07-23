import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/assignment.dart';
import '../models/service_event.dart';
import 'service_event_storage_service.dart';

class ServiceHistoryCorrectionService {
  static const String _undoKey = 'service_events_before_correction_v1';

  static Future<void> correctAssignment({
    required String eventId,
    required String eventType,
    required String serviceType,
    required DateTime date,
    required Assignment assignment,
    String? volunteerId,
  }) async {
    final events = await ServiceEventStorageService.loadEvents();
    final snapshot = events.map((event) => jsonEncode(event.toJson())).toList();
    final prefs = await SharedPreferences.getInstance();

    if (!await prefs.setStringList(_undoKey, snapshot)) {
      throw StateError('No se pudo crear el punto de recuperación');
    }

    final correctedEvents = events
        .where(
          (event) => !_isSameAssignment(
            event,
            eventId: eventId,
            assignment: assignment,
          ),
        )
        .toList();

    if (volunteerId != null && volunteerId.isNotEmpty) {
      correctedEvents.add(
        ServiceEvent(
          volunteerId: volunteerId,
          serviceType: serviceType,
          eventType: eventType,
          role: assignment.role,
          startTime: assignment.startTime,
          endTime: assignment.endTime,
          eventId: eventId,
          date: DateTime(date.year, date.month, date.day),
        ),
      );
    }

    try {
      await ServiceEventStorageService.saveEvents(correctedEvents);
    } catch (_) {
      await ServiceEventStorageService.saveEvents(events);
      rethrow;
    }
  }

  static Future<bool> canUndo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_undoKey) != null;
  }

  static Future<void> undoLastCorrection() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = prefs.getStringList(_undoKey);
    if (snapshot == null) {
      throw StateError('No hay ninguna corrección para deshacer');
    }

    final previousEvents = snapshot
        .map(
          (encoded) => ServiceEvent.fromJson(
            jsonDecode(encoded) as Map<String, dynamic>,
          ),
        )
        .toList();
    await ServiceEventStorageService.saveEvents(previousEvents);
    await prefs.remove(_undoKey);
  }

  static bool _isSameAssignment(
    ServiceEvent event, {
    required String eventId,
    required Assignment assignment,
  }) {
    return event.eventId == eventId &&
        event.role == assignment.role &&
        event.startTime == assignment.startTime &&
        event.endTime == assignment.endTime;
  }
}
