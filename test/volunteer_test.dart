import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_aseo_idmji/models/absence_period.dart';
import 'package:planilla_aseo_idmji/models/volunteer.dart';

void main() {
  test(
    'la ausencia es inclusiva y se combina con la disponibilidad habitual',
    () {
      final volunteer = Volunteer(
        id: 'ana',
        name: 'Ana',
        availableEstudio: false,
        absences: [
          AbsencePeriod(
            start: DateTime(2026, 8, 4),
            end: DateTime(2026, 8, 10),
          ),
        ],
      );
      expect(
        volunteer.isAvailableFor('alabanza', DateTime(2026, 8, 4)),
        isFalse,
      );
      expect(
        volunteer.isAvailableFor('estudio', DateTime(2026, 8, 15)),
        isFalse,
      );
      expect(
        volunteer.isAvailableFor('ensenanza', DateTime(2026, 8, 16)),
        isTrue,
      );
    },
  );

  test('conserva la pareja al serializar y admite datos antiguos', () {
    const volunteer = Volunteer(id: 'ana', name: 'Ana', partnerId: 'luis');
    expect(Volunteer.fromJson(volunteer.toJson()).partnerId, 'luis');
    expect(
      Volunteer.fromJson({'id': 'old', 'name': 'Antigua'}).partnerId,
      isNull,
    );
  });
}
