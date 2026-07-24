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
}
