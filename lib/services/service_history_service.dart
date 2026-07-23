import '../models/event_templates.dart';
import '../models/service_event.dart';
import 'assignment_storage_service.dart';
import 'processed_services_storage.dart';
import 'service_event_storage_service.dart';

class ServiceHistoryService {
  static Future<void> processCompletedServices({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final assignments = await AssignmentStorageService.loadAssignments();
    final processed = await ProcessedServicesStorage.loadProcessed();

    for (final assignment in assignments) {
      if (processed.contains(assignment.eventId)) continue;
      final occurrence = EventTemplates.forWeek(
        assignment.date.subtract(Duration(days: assignment.date.weekday - 1)),
      ).where((event) => event.eventId == assignment.eventId).firstOrNull;
      if (occurrence == null) continue;
      final completedAt = _at(occurrence.date, occurrence.endTime);
      if (currentTime.isBefore(completedAt)) continue;

      final volunteerId = assignment.volunteerId;
      if (volunteerId != null && volunteerId.isNotEmpty) {
        await ServiceEventStorageService.addEvent(
          ServiceEvent(
            volunteerId: volunteerId,
            eventType: assignment.eventType,
            eventId: assignment.eventId,
            date: assignment.date,
          ),
        );
      }
      await ProcessedServicesStorage.markAsProcessed(assignment.eventId);
      processed.add(assignment.eventId);
    }
  }

  static DateTime _at(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
