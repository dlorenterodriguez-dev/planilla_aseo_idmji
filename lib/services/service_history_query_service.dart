import '../models/service_event.dart';
import 'service_event_storage_service.dart';

class VolunteerServiceStats {
  final int total;
  final Map<String, int> byEventType;
  final DateTime? lastService;

  const VolunteerServiceStats({
    required this.total,
    required this.byEventType,
    required this.lastService,
  });
}

class ServiceHistoryQueryService {
  static Future<Map<String, VolunteerServiceStats>> statsByVolunteer() async {
    final events = await ServiceEventStorageService.loadEvents();
    final byVolunteer = <String, List<ServiceEvent>>{};
    for (final event in events) {
      if (event.volunteerId.isEmpty || event.eventId.isEmpty) continue;
      byVolunteer.putIfAbsent(event.volunteerId, () => []).add(event);
    }

    return byVolunteer.map((volunteerId, volunteerEvents) {
      final unique = <String, ServiceEvent>{
        for (final event in volunteerEvents) event.eventId: event,
      }.values.toList();
      final byType = <String, int>{};
      DateTime? lastService;
      for (final event in unique) {
        byType.update(event.eventType, (count) => count + 1, ifAbsent: () => 1);
        if (lastService == null || event.date.isAfter(lastService)) {
          lastService = event.date;
        }
      }
      return MapEntry(
        volunteerId,
        VolunteerServiceStats(
          total: unique.length,
          byEventType: byType,
          lastService: lastService,
        ),
      );
    });
  }
}
