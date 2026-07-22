import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_idmji/models/service_event.dart';
import 'package:planilla_idmji/models/service_types.dart';
import 'package:planilla_idmji/services/service_history_query_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('counts unique assignments and applies historical filters', () async {
    final firstTurn = ServiceEvent(
      volunteerId: 'volunteer-1',
      serviceType: ServiceTypes.vigilance,
      eventType: 'alabanza',
      role: 'Vigilancia',
      startTime: '18:00',
      endTime: '19:00',
      eventId: '2026-07-21-alabanza',
      date: DateTime(2026, 7, 21),
    );
    final secondTurn = ServiceEvent(
      volunteerId: 'volunteer-1',
      serviceType: ServiceTypes.vigilance,
      eventType: 'alabanza',
      role: 'Vigilancia',
      startTime: '19:00',
      endTime: '19:45',
      eventId: '2026-07-21-alabanza',
      date: DateTime(2026, 7, 21),
    );
    final laterTurn = ServiceEvent(
      volunteerId: 'volunteer-2',
      serviceType: ServiceTypes.vigilance,
      eventType: 'estudio',
      role: 'Vigilancia',
      startTime: '16:00',
      endTime: '17:00',
      eventId: '2026-07-25-estudio',
      date: DateTime(2026, 7, 25),
    );

    SharedPreferences.setMockInitialValues({
      'service_events_v1': [
        jsonEncode(firstTurn.toJson()),
        jsonEncode(firstTurn.toJson()),
        jsonEncode(secondTurn.toJson()),
        jsonEncode(laterTurn.toJson()),
        'registro corrupto',
      ],
    });

    final allVigilance =
        await ServiceHistoryQueryService.countAssignmentsByVolunteer(
      serviceType: ServiceTypes.vigilance,
    );
    expect(allVigilance, {'volunteer-1': 2, 'volunteer-2': 1});

    final alabanzaCount = await ServiceHistoryQueryService.countAssignments(
      volunteerId: 'volunteer-1',
      serviceType: ServiceTypes.vigilance,
      eventType: 'alabanza',
    );
    expect(alabanzaCount, 2);

    final recentVigilance =
        await ServiceHistoryQueryService.countAssignmentsByVolunteer(
      serviceType: ServiceTypes.vigilance,
      since: DateTime(2026, 7, 22),
      until: DateTime(2026, 7, 25),
    );
    expect(recentVigilance, {'volunteer-2': 1});
  });
}
