import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_idmji/models/service_event.dart';
import 'package:planilla_idmji/models/service_types.dart';
import 'package:planilla_idmji/models/volunteer.dart';
import 'package:planilla_idmji/screens/service_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows historical services grouped by event', (tester) async {
    const volunteer = Volunteer(
      id: 'volunteer-1',
      name: 'Ana',
      isActive: true,
    );
    final event = ServiceEvent(
      volunteerId: volunteer.id,
      serviceType: ServiceTypes.vigilance,
      eventType: 'alabanza',
      role: 'Vigilancia',
      startTime: '18:00',
      endTime: '19:00',
      eventId: '2026-07-21-alabanza',
      date: DateTime(2026, 7, 21),
    );

    SharedPreferences.setMockInitialValues({
      'volunteers_v2': [jsonEncode(volunteer.toJson())],
      'service_events_v1': [jsonEncode(event.toJson())],
    });

    await tester.pumpWidget(
      const MaterialApp(home: ServiceHistoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alabanza · 21/07/2026'), findsOneWidget);
    expect(find.text('1 puesto'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Vigilancia · 18:00-19:00'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no events', (tester) async {
    SharedPreferences.setMockInitialValues({
      'volunteers_v2': <String>[],
      'service_events_v1': <String>[],
    });

    await tester.pumpWidget(
      const MaterialApp(home: ServiceHistoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no hay servicios contabilizados'),
      findsOneWidget,
    );
  });
}
