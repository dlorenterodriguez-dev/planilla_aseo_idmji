import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_aseo_idmji/models/event_templates.dart';

void main() {
  test('crea un puesto el martes y dos puestos el sábado', () {
    final occurrences = EventTemplates.forWeek(DateTime(2026, 8, 3));

    expect(
      occurrences
          .where((value) => value.eventType == 'alabanza')
          .map((value) => value.positionLabel),
      ['Aseo sala de culto 1'],
    );
    expect(
      occurrences
          .where((value) => value.eventType == 'estudio')
          .map((value) => value.positionLabel),
      ['Aseo sala de culto 1', 'Aseo sala de culto 2'],
    );
    expect(occurrences, hasLength(3));
    expect(occurrences.any((value) => value.cleaningArea == 'banos'), isFalse);
    expect(occurrences.any((value) => value.eventType == 'ensenanza'), isFalse);
  });
}
