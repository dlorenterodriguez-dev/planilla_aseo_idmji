import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_biblias_idmji/models/assignment.dart';
import 'package:planilla_biblias_idmji/models/volunteer.dart';
import 'package:planilla_biblias_idmji/services/assignment_storage_service.dart';
import 'package:planilla_biblias_idmji/services/backup_service.dart';
import 'package:planilla_biblias_idmji/services/volunteer_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('exporta y restaura todos los datos de Biblias', () async {
    const volunteer = Volunteer(id: 'ana', name: 'Ana');
    await VolunteerStorageService.saveVolunteers([volunteer]);
    await AssignmentStorageService.saveAssignments([
      Assignment(
        eventId: '2026-08-04-alabanza',
        eventType: 'alabanza',
        date: DateTime(2026, 8, 4),
        volunteerId: volunteer.id,
      ),
    ]);
    final backup = await BackupService.createBackupJson();
    final summary = BackupService.inspectBackup(backup);
    expect(summary.volunteerCount, 1);
    expect(summary.assignmentCount, 1);

    await VolunteerStorageService.saveVolunteers([]);
    await AssignmentStorageService.saveAssignments([]);
    await BackupService.restoreBackup(backup);
    expect(await VolunteerStorageService.loadVolunteers(), hasLength(1));
  });

  test('rechaza copias de otra aplicación', () {
    final foreign = jsonEncode({
      'applicationId': 'idmji-voluntariado-vigilancia',
      'schemaVersion': 1,
    });
    expect(
      () => BackupService.inspectBackup(foreign),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'mensaje',
          contains('no pertenece'),
        ),
      ),
    );
  });
}
