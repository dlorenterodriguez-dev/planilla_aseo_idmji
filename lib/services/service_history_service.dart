import '../models/assignment.dart';
import '../models/event_templates.dart';
import '../models/service_event.dart';
import '../models/service_types.dart';
import 'assignment_storage_service.dart';
import 'processed_services_storage.dart';
import 'service_event_storage_service.dart';
import 'week_service.dart';

class ServiceHistoryService {
  static Future<void> processCompletedServices({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final weekStart = await WeekService.loadWeekStart();

    final services = [
      _ServiceDefinition(
        eventType: 'alabanza',
        dayOffset: 1,
        assignmentKey: 'alabanza_assignments_v2',
        assignments: EventTemplates.alabanza(),
      ),
      _ServiceDefinition(
        eventType: 'estudio',
        dayOffset: 5,
        assignmentKey: 'estudio_assignments_v2',
        assignments: EventTemplates.estudio(),
      ),
      _ServiceDefinition(
        eventType: 'ensenanza',
        dayOffset: 6,
        assignmentKey: 'ensenanza_assignments_v2',
        assignments: EventTemplates.ensenanza(),
      ),
    ];

    final processed = await ProcessedServicesStorage.loadProcessed();

    for (final service in services) {
      final eventDate = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + service.dayOffset,
      );
      final eventId = '${_dateKey(eventDate)}-${service.eventType}';

      if (processed.contains(eventId)) {
        continue;
      }

      final lastEndTime = service.assignments
          .map((assignment) => assignment.endTime)
          .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
      final completedAt = _dateTimeAt(eventDate, lastEndTime);

      if (currentTime.isBefore(completedAt)) {
        continue;
      }

      final volunteerIds = await AssignmentStorageService.loadAssignmentIds(
        service.assignmentKey,
      );
      final events = <ServiceEvent>[];

      for (var index = 0; index < service.assignments.length; index++) {
        if (index >= volunteerIds.length || volunteerIds[index].isEmpty) {
          continue;
        }

        final assignment = service.assignments[index];
        events.add(
          ServiceEvent(
            volunteerId: volunteerIds[index],
            serviceType: ServiceTypes.fromRole(assignment.role),
            eventType: service.eventType,
            role: assignment.role,
            startTime: assignment.startTime,
            endTime: assignment.endTime,
            eventId: eventId,
            date: eventDate,
          ),
        );
      }

      await ServiceEventStorageService.addEvents(events);
      await ProcessedServicesStorage.markAsProcessed(eventId);
      processed.add(eventId);
    }
  }

  static DateTime _dateTimeAt(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ServiceDefinition {
  final String eventType;
  final int dayOffset;
  final String assignmentKey;
  final List<Assignment> assignments;

  const _ServiceDefinition({
    required this.eventType,
    required this.dayOffset,
    required this.assignmentKey,
    required this.assignments,
  });
}
