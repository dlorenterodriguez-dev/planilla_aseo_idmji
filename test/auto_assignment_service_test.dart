import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_idmji/models/event_templates.dart';
import 'package:planilla_idmji/models/service_event.dart';
import 'package:planilla_idmji/models/service_types.dart';
import 'package:planilla_idmji/models/volunteer.dart';
import 'package:planilla_idmji/services/auto_assignment_service.dart';
import 'package:planilla_idmji/services/service_event_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const volunteers = [
    Volunteer(id: 'volunteer-1', name: 'Ana', isActive: true),
    Volunteer(id: 'volunteer-2', name: 'Bea', isActive: true),
    Volunteer(id: 'volunteer-3', name: 'Celia', isActive: true),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ServiceEventStorageService.saveEvents([
      _vigilanceEvent('volunteer-1', DateTime(2026, 7, 7)),
      _vigilanceEvent('volunteer-1', DateTime(2026, 7, 14)),
      _vigilanceEvent('volunteer-2', DateTime(2026, 7, 14)),
    ]);
  });

  test('prefers volunteers with fewer historical assignments', () async {
    final assignments = EventTemplates.alabanza();

    await AutoAssignmentService.autoAssign(
      assignments: assignments,
      volunteers: volunteers,
      isAlabanza: true,
    );

    expect(
      assignments.map((assignment) => assignment.volunteerId),
      ['volunteer-3', 'volunteer-2', 'volunteer-1'],
    );
  });

  test('preserves manual assignments while applying historical fairness',
      () async {
    final assignments = EventTemplates.alabanza();
    assignments.first.volunteerId = 'volunteer-1';

    await AutoAssignmentService.autoAssign(
      assignments: assignments,
      volunteers: volunteers,
      isAlabanza: true,
    );

    expect(
      assignments.map((assignment) => assignment.volunteerId),
      ['volunteer-1', 'volunteer-3', 'volunteer-2'],
    );
  });
}

ServiceEvent _vigilanceEvent(String volunteerId, DateTime date) {
  final dateKey = date.toIso8601String().substring(0, 10);
  return ServiceEvent(
    volunteerId: volunteerId,
    serviceType: ServiceTypes.vigilance,
    eventType: 'alabanza',
    role: 'Vigilancia',
    startTime: '18:00',
    endTime: '19:00',
    eventId: '$dateKey-alabanza',
    date: date,
  );
}
