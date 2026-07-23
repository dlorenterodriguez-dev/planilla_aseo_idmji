import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_biblias_idmji/models/absence_period.dart';
import 'package:planilla_biblias_idmji/models/assignment.dart';
import 'package:planilla_biblias_idmji/models/event_templates.dart';
import 'package:planilla_biblias_idmji/models/service_event.dart';
import 'package:planilla_biblias_idmji/models/volunteer.dart';
import 'package:planilla_biblias_idmji/services/auto_assignment_service.dart';
import 'package:planilla_biblias_idmji/services/service_event_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reparte un mes con una diferencia máxima de un servicio', () async {
    final volunteers = [
      const Volunteer(id: 'a', name: 'Ana'),
      const Volunteer(id: 'b', name: 'Beatriz'),
      const Volunteer(id: 'c', name: 'Carmen'),
    ];
    final assignments = <Assignment>[];
    final occurrences = EventTemplates.forMonth(DateTime(2026, 8));

    await AutoAssignmentService.autoAssign(
      occurrences: occurrences,
      assignments: assignments,
      volunteers: volunteers,
    );

    final counts = {
      for (final volunteer in volunteers)
        volunteer.id: assignments
            .where((assignment) => assignment.volunteerId == volunteer.id)
            .length,
    };
    expect(assignments, hasLength(occurrences.length));
    expect(
      counts.values.reduce((a, b) => a > b ? a : b) -
          counts.values.reduce((a, b) => a < b ? a : b),
      lessThanOrEqualTo(1),
    );
  });

  test('conserva manuales y respeta disponibilidad y ausencias', () async {
    final monday = DateTime(2026, 8, 3);
    final occurrences = EventTemplates.forWeek(monday);
    final assignments = [
      Assignment(
        eventId: occurrences.first.eventId,
        eventType: occurrences.first.eventType,
        date: occurrences.first.date,
        volunteerId: 'manual',
      ),
    ];
    final volunteers = [
      const Volunteer(id: 'manual', name: 'Manual'),
      Volunteer(
        id: 'ausente',
        name: 'Ausente',
        absences: [
          AbsencePeriod(
            start: monday,
            end: monday.add(const Duration(days: 7)),
          ),
        ],
      ),
      const Volunteer(
        id: 'solo-estudio',
        name: 'Solo estudio',
        availableAlabanza: false,
        availableEnsenanza: false,
      ),
    ];

    await AutoAssignmentService.autoAssign(
      occurrences: occurrences,
      assignments: assignments,
      volunteers: volunteers,
    );

    expect(assignments.first.volunteerId, 'manual');
    expect(
      assignments
          .where((assignment) => assignment.eventType == 'estudio')
          .single
          .volunteerId,
      'solo-estudio',
    );
    expect(
      assignments.any((assignment) => assignment.volunteerId == 'ausente'),
      isFalse,
    );
  });

  test('favorece a quien menos ha servido históricamente', () async {
    await ServiceEventStorageService.saveEvents([
      ServiceEvent(
        volunteerId: 'a',
        eventType: 'alabanza',
        eventId: '2026-07-01-alabanza',
        date: DateTime(2026, 7, 1),
      ),
    ]);
    final occurrence = EventTemplates.forWeek(DateTime(2026, 8, 3)).first;
    final assignments = <Assignment>[];

    await AutoAssignmentService.autoAssign(
      occurrences: [occurrence],
      assignments: assignments,
      volunteers: const [
        Volunteer(id: 'a', name: 'Ana'),
        Volunteer(id: 'b', name: 'Beatriz'),
      ],
    );

    expect(assignments.single.volunteerId, 'b');
  });
}
