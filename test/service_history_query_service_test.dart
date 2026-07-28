import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_aseo_idmji/models/service_event.dart';
import 'package:planilla_aseo_idmji/services/service_event_storage_service.dart';
import 'package:planilla_aseo_idmji/services/service_history_query_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('resume totales, cultos y último servicio por voluntaria', () async {
    SharedPreferences.setMockInitialValues({});
    await ServiceEventStorageService.saveEvents([
      ServiceEvent(
        volunteerId: 'ana',
        eventType: 'alabanza',
        eventId: '2026-08-04-alabanza-sala-1',
        date: DateTime(2026, 8, 4),
      ),
      ServiceEvent(
        volunteerId: 'ana',
        eventType: 'estudio',
        eventId: '2026-08-08-estudio-sala-1',
        date: DateTime(2026, 8, 8),
      ),
    ]);
    final stats = (await ServiceHistoryQueryService.statsByVolunteer())['ana']!;
    expect(stats.total, 2);
    expect(stats.byEventType['alabanza'], 1);
    expect(stats.lastService, DateTime(2026, 8, 8));
  });
}
