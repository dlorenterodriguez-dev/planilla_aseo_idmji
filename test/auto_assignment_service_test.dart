import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_aseo_idmji/models/absence_period.dart';
import 'package:planilla_aseo_idmji/models/assignment.dart';
import 'package:planilla_aseo_idmji/models/event_templates.dart';
import 'package:planilla_aseo_idmji/models/service_event.dart';
import 'package:planilla_aseo_idmji/models/volunteer.dart';
import 'package:planilla_aseo_idmji/services/auto_assignment_service.dart';
import 'package:planilla_aseo_idmji/services/service_event_storage_service.dart';
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
    for (final date in occurrences.map((value) => value.date).toSet()) {
      final assignedOnDate = assignments
          .where((assignment) => assignment.date == date)
          .map((assignment) => assignment.volunteerId)
          .toList();
      expect(assignedOnDate.toSet(), hasLength(assignedOnDate.length));
    }
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
          .first
          .volunteerId,
      'solo-estudio',
    );
    expect(
      assignments.any((assignment) => assignment.volunteerId == 'ausente'),
      isFalse,
    );
  });

  test('asigna voluntarias distintas a los puestos simultáneos', () async {
    final occurrences = EventTemplates.forWeek(DateTime(2026, 8, 3));
    final assignments = <Assignment>[];

    await AutoAssignmentService.autoAssign(
      occurrences: occurrences,
      assignments: assignments,
      volunteers: const [
        Volunteer(id: 'a', name: 'Ana'),
        Volunteer(id: 'b', name: 'Beatriz'),
        Volunteer(id: 'c', name: 'Carmen'),
      ],
    );

    expect(assignments, hasLength(6));
    for (final date in occurrences.map((value) => value.date).toSet()) {
      final ids = assignments
          .where((assignment) => assignment.date == date)
          .map((assignment) => assignment.volunteerId)
          .toList();
      expect(ids, everyElement(isNotNull));
      expect(ids.toSet(), hasLength(ids.length));
    }
  });

  test('respeta las capacidades de sala y baños', () async {
    final occurrences = EventTemplates.forWeek(DateTime(2026, 8, 3));
    final assignments = <Assignment>[];

    await AutoAssignmentService.autoAssign(
      occurrences: occurrences,
      assignments: assignments,
      volunteers: const [
        Volunteer(id: 'sala', name: 'Sala', canCleanBathrooms: false),
        Volunteer(id: 'banos', name: 'Baños', canCleanWorshipHall: false),
        Volunteer(id: 'ambos', name: 'Ambos'),
      ],
    );

    final byId = {for (final value in occurrences) value.eventId: value};
    for (final assignment in assignments) {
      final area = byId[assignment.eventId]!.cleaningArea;
      if (area == 'sala') {
        expect(assignment.volunteerId, isNot('banos'));
      } else {
        expect(assignment.volunteerId, isNot('sala'));
      }
    }
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
