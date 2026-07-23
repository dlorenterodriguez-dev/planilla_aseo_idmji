import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/service_event.dart';
import 'service_event_storage_service.dart';

class ServiceHistoryCorrectionService {
  static const String undoKey = 'biblias_history_undo_v1';

  static Future<void> correctAssignment({
    required String eventId,
    required String eventType,
    required DateTime date,
    required String volunteerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final events = await ServiceEventStorageService.loadEvents();
    await prefs.setStringList(
      undoKey,
      events.map((event) => jsonEncode(event.toJson())).toList(),
    );
    events.removeWhere((event) => event.eventId == eventId);
    if (volunteerId.isNotEmpty) {
      events.add(
        ServiceEvent(
          volunteerId: volunteerId,
          eventType: eventType,
          eventId: eventId,
          date: date,
        ),
      );
    }
    await ServiceEventStorageService.saveEvents(events);
  }

  static Future<bool> canUndo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(undoKey) != null;
  }

  static Future<void> undoLastCorrection() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = prefs.getStringList(undoKey);
    if (snapshot == null) {
      throw StateError('No hay una corrección que deshacer');
    }
    final events = snapshot
        .map(
          (value) => ServiceEvent.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          ),
        )
        .toList();
    await ServiceEventStorageService.saveEvents(events);
    await prefs.remove(undoKey);
  }
}
