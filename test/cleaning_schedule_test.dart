import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_aseo_idmji/models/event_templates.dart';

void main() {
  test('crea los puestos semanales de sala y baños', () {
    final occurrences = EventTemplates.forWeek(DateTime(2026, 8, 3));

    expect(
      occurrences
          .where((value) => value.eventType == 'alabanza')
          .map((value) => value.positionLabel),
      ['Aseo sala de culto 1', 'Aseo sala de culto 2'],
    );
    expect(
      occurrences
          .where((value) => value.eventType == 'estudio')
          .map((value) => value.positionLabel),
      ['Aseo sala de culto 1', 'Aseo sala de culto 2', 'Aseo baños'],
    );
    expect(
      occurrences
          .where((value) => value.eventType == 'ensenanza')
          .map((value) => value.positionLabel),
      ['Aseo baños'],
    );
  });
}
