import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_biblias_idmji/models/assignment.dart';
import 'package:planilla_biblias_idmji/services/assignment_storage_service.dart';
import 'package:planilla_biblias_idmji/services/processed_services_storage.dart';
import 'package:planilla_biblias_idmji/services/service_event_storage_service.dart';
import 'package:planilla_biblias_idmji/services/service_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'contabiliza una asignación una sola vez al terminar el culto',
    () async {
      await AssignmentStorageService.saveAssignments([
        Assignment(
          eventId: '2026-08-04-alabanza',
          eventType: 'alabanza',
          date: DateTime(2026, 8, 4),
          volunteerId: 'ana',
        ),
      ]);

      await ServiceHistoryService.processCompletedServices(
        now: DateTime(2026, 8, 4, 21),
      );
      await ServiceHistoryService.processCompletedServices(
        now: DateTime(2026, 8, 5),
      );

      expect(await ServiceEventStorageService.loadEvents(), hasLength(1));
      expect(
        await ProcessedServicesStorage.loadProcessed(),
        contains('2026-08-04-alabanza'),
      );
    },
  );

  test('no contabiliza antes de finalizar', () async {
    await AssignmentStorageService.saveAssignments([
      Assignment(
        eventId: '2026-08-04-alabanza',
        eventType: 'alabanza',
        date: DateTime(2026, 8, 4),
        volunteerId: 'ana',
      ),
    ]);
    await ServiceHistoryService.processCompletedServices(
      now: DateTime(2026, 8, 4, 20),
    );
    expect(await ServiceEventStorageService.loadEvents(), isEmpty);
  });
}
