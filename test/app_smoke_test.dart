import 'package:flutter_test/flutter_test.dart';
import 'package:planilla_biblias_idmji/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('muestra los accesos principales de Biblias', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BibliasApp());
    await tester.pumpAndSettle();

    expect(find.text('IDMJI Voluntariado Biblias'), findsOneWidget);
    expect(find.text('Gestionar voluntarias'), findsOneWidget);
    expect(find.text('Planilla semanal'), findsOneWidget);
    expect(find.text('Planilla mensual'), findsOneWidget);
    expect(find.text('Consultar histórico'), findsOneWidget);
    expect(find.text('Copias de seguridad'), findsOneWidget);
  });
}
