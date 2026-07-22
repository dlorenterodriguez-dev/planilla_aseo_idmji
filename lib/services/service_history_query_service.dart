import '../models/service_event.dart';
import 'service_event_storage_service.dart';

class ServiceHistoryQueryService {
  static Future<int> countAssignments({
    required String volunteerId,
    required String serviceType,
    String? eventType,
    DateTime? since,
    DateTime? until,
  }) async {
    final counts = await countAssignmentsByVolunteer(
      serviceType: serviceType,
      eventType: eventType,
      since: since,
      until: until,
    );

    return counts[volunteerId] ?? 0;
  }

  static Future<Map<String, int>> countAssignmentsByVolunteer({
    required String serviceType,
    String? eventType,
    DateTime? since,
    DateTime? until,
  }) async {
    final events = await ServiceEventStorageService.loadEvents();
    final counts = <String, int>{};
    final countedAssignments = <String>{};

    for (final event in events) {
      if (!_isValid(event) || event.serviceType != serviceType) {
        continue;
      }
      if (eventType != null && event.eventType != eventType) {
        continue;
      }
      if (since != null && event.date.isBefore(since)) {
        continue;
      }
      if (until != null && event.date.isAfter(until)) {
        continue;
      }

      final assignmentKey = _assignmentKey(event);
      if (!countedAssignments.add(assignmentKey)) {
        continue;
      }

      counts.update(
        event.volunteerId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return counts;
  }

  static bool _isValid(ServiceEvent event) {
    return event.volunteerId.isNotEmpty &&
        event.serviceType.isNotEmpty &&
        event.eventId.isNotEmpty;
  }

  static String _assignmentKey(ServiceEvent event) {
    return [
      event.eventId,
      event.volunteerId,
      event.serviceType,
      event.role,
      event.startTime,
      event.endTime,
    ].join('|');
  }
}
