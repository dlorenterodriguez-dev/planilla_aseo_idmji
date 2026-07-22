import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_idmji/services/processed_services_storage.dart';
import 'package:planilla_idmji/services/service_event_storage_service.dart';
import 'package:planilla_idmji/services/service_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('archives a completed service once and preserves every filled slot',
      () async {
    SharedPreferences.setMockInitialValues({
      'week_start_date': DateTime(2026, 7, 20).toIso8601String(),
      'alabanza_assignments_v2': ['volunteer-1', 'volunteer-1', ''],
      'estudio_assignments_v2': ['volunteer-2', '', ''],
    });

    final beforeEnd = DateTime(2026, 7, 21, 20, 29);
    await ServiceHistoryService.processCompletedServices(now: beforeEnd);
    expect(await ServiceEventStorageService.loadEvents(), isEmpty);

    final afterEnd = DateTime(2026, 7, 21, 20, 30);
    await ServiceHistoryService.processCompletedServices(now: afterEnd);
    await ServiceHistoryService.processCompletedServices(now: afterEnd);

    final events = await ServiceEventStorageService.loadEvents();
    expect(events, hasLength(2));
    expect(events.map((event) => event.startTime), ['18:00', '19:00']);
    expect(events.every((event) => event.eventType == 'alabanza'), isTrue);

    final processed = await ProcessedServicesStorage.loadProcessed();
    expect(processed, contains('2026-07-21-alabanza'));
    expect(processed, isNot(contains('2026-07-25-estudio')));
  });
}
