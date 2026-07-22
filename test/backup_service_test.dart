import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_idmji/models/service_event.dart';
import 'package:planilla_idmji/models/service_types.dart';
import 'package:planilla_idmji/models/volunteer.dart';
import 'package:planilla_idmji/services/assignment_storage_service.dart';
import 'package:planilla_idmji/services/backup_service.dart';
import 'package:planilla_idmji/services/processed_services_storage.dart';
import 'package:planilla_idmji/services/service_event_storage_service.dart';
import 'package:planilla_idmji/services/volunteer_storage_service.dart';
import 'package:planilla_idmji/services/week_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports and restores every canonical data set', () async {
    const volunteer = Volunteer(
      id: 'volunteer-1',
      name: 'Ana',
      isActive: true,
      canMicrophone: true,
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
      'week_start_date': DateTime(2026, 7, 20).toIso8601String(),
      'alabanza_assignments_v2': [volunteer.id, '', ''],
      'estudio_assignments_v2': ['', '', ''],
      'ensenanza_assignments_v2': ['', '', '', '', '', ''],
      'service_events_v1': [jsonEncode(event.toJson())],
      'processed_services_v1': [event.eventId],
    });

    final backup = await BackupService.createBackupJson();
    final summary = BackupService.inspectBackup(backup);
    expect(summary.volunteerCount, 1);
    expect(summary.assignmentCount, 1);
    expect(summary.serviceEventCount, 1);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await BackupService.restoreBackup(backup);

    expect((await VolunteerStorageService.loadVolunteers()).single.name, 'Ana');
    expect(await WeekService.loadWeekStart(), DateTime(2026, 7, 20));
    expect(
      await AssignmentStorageService.loadAssignmentIds(
        'alabanza_assignments_v2',
      ),
      [volunteer.id, '', ''],
    );
    expect(await ServiceEventStorageService.loadEvents(), hasLength(1));
    expect(
      await ProcessedServicesStorage.loadProcessed(),
      contains(event.eventId),
    );
  });

  test('rejects invalid backups without changing local data', () async {
    SharedPreferences.setMockInitialValues({
      'week_start_date': DateTime(2026, 7, 20).toIso8601String(),
      'volunteers_v2': <String>[],
    });
    final prefs = await SharedPreferences.getInstance();

    expect(
      () => BackupService.inspectBackup('{"schemaVersion":999}'),
      throwsFormatException,
    );
    expect(
      prefs.getString('week_start_date'),
      DateTime(2026, 7, 20).toIso8601String(),
    );
  });
}
