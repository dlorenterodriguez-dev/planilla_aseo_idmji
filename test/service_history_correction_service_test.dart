import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_aseo_idmji/models/service_event.dart';
import 'package:planilla_aseo_idmji/services/service_event_storage_service.dart';
import 'package:planilla_aseo_idmji/services/service_history_correction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('corrige y deshace un servicio', () async {
    SharedPreferences.setMockInitialValues({});
    final date = DateTime(2026, 8, 4);
    await ServiceEventStorageService.saveEvents([
      ServiceEvent(
        volunteerId: 'ana',
        eventType: 'alabanza',
        eventId: '2026-08-04-alabanza-1',
        date: date,
      ),
    ]);
    await ServiceHistoryCorrectionService.correctAssignment(
      eventId: '2026-08-04-alabanza-1',
      eventType: 'alabanza',
      date: date,
      volunteerId: 'bea',
    );
    expect(
      (await ServiceEventStorageService.loadEvents()).single.volunteerId,
      'bea',
    );
    await ServiceHistoryCorrectionService.undoLastCorrection();
    expect(
      (await ServiceEventStorageService.loadEvents()).single.volunteerId,
      'ana',
    );
  });
}
