import 'package:flutter/material.dart';
import 'screens/volunteers_screen.dart';
import 'screens/week_editor_screen.dart';
import 'screens/planilla_preview_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const PlanillaApp());
}

class PlanillaApp extends StatelessWidget {
  const PlanillaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Planilla IDMJI',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planilla IDMJI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VolunteersScreen(),
                    ),
                  );
                },
                child: const Text('Gestionar voluntarios'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeekEditorScreen(),
                    ),
                  );
                },
                child: const Text('Editar semana'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlanillaPreviewScreen(),
                    ),
                  );
                },
                child: const Text('Generar planilla'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}