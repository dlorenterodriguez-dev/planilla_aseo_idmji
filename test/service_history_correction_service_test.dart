import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_idmji/models/event_templates.dart';
import 'package:planilla_idmji/models/service_event.dart';
import 'package:planilla_idmji/models/service_types.dart';
import 'package:planilla_idmji/services/service_event_storage_service.dart';
import 'package:planilla_idmji/services/service_history_correction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('changes and removes the volunteer assigned to a historical slot',
      () async {
    final assignment = EventTemplates.alabanza().first;
    await ServiceEventStorageService.saveEvents([
      _eventFor(assignment.startTime, assignment.endTime, 'volunteer-1'),
    ]);

    await ServiceHistoryCorrectionService.correctAssignment(
      eventId: '2026-07-21-alabanza',
      eventType: 'alabanza',
      serviceType: ServiceTypes.vigilance,
      date: DateTime(2026, 7, 21),
      assignment: assignment,
      volunteerId: 'volunteer-2',
    );

    var events = await ServiceEventStorageService.loadEvents();
    expect(events, hasLength(1));
    expect(events.single.volunteerId, 'volunteer-2');

    await ServiceHistoryCorrectionService.correctAssignment(
      eventId: '2026-07-21-alabanza',
      eventType: 'alabanza',
      serviceType: ServiceTypes.vigilance,
      date: DateTime(2026, 7, 21),
      assignment: assignment,
    );

    events = await ServiceEventStorageService.loadEvents();
    expect(events, isEmpty);
  });

  test('adds a missing historical slot and can undo the correction', () async {
    final assignment = EventTemplates.alabanza()[1];

    await ServiceHistoryCorrectionService.correctAssignment(
      eventId: '2026-07-21-alabanza',
      eventType: 'alabanza',
      serviceType: ServiceTypes.vigilance,
      date: DateTime(2026, 7, 21),
      assignment: assignment,
      volunteerId: 'volunteer-1',
    );

    expect(await ServiceEventStorageService.loadEvents(), hasLength(1));
    expect(await ServiceHistoryCorrectionService.canUndo(), isTrue);

    await ServiceHistoryCorrectionService.undoLastCorrection();

    expect(await ServiceEventStorageService.loadEvents(), isEmpty);
    expect(await ServiceHistoryCorrectionService.canUndo(), isFalse);
  });
}

ServiceEvent _eventFor(
  String startTime,
  String endTime,
  String volunteerId,
) {
  return ServiceEvent(
    volunteerId: volunteerId,
    serviceType: ServiceTypes.vigilance,
    eventType: 'alabanza',
    role: 'Vigilancia',
    startTime: startTime,
    endTime: endTime,
    eventId: '2026-07-21-alabanza',
    date: DateTime(2026, 7, 21),
  );
}
