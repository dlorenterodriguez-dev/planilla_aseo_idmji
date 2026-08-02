import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_aseo_idmji/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('muestra los accesos principales de Aseo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AseoApp());
    await tester.pumpAndSettle();

    expect(find.text('IDMJI Voluntariado Aseo'), findsOneWidget);
    expect(find.text('Gestionar voluntarias'), findsOneWidget);
    expect(find.text('Planilla semanal'), findsOneWidget);
    expect(find.text('Planilla mensual'), findsOneWidget);
    expect(find.text('Consultar histórico'), findsOneWidget);
    expect(find.text('Copias de seguridad'), findsOneWidget);
  });

  testWidgets('la planilla mensual separa la imagen de los editores', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AseoApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Planilla mensual'));
    await tester.pumpAndSettle();

    expect(find.text('Voluntariado de Aseo'), findsOneWidget);
    expect(find.text('Autoasignar'), findsOneWidget);
    expect(find.text('Compartir como imagen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Editar asignaciones'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Editar asignaciones'), findsOneWidget);
  });
}
