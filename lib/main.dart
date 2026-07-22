import 'package:flutter/material.dart';
import 'screens/volunteers_screen.dart';
import 'screens/week_editor_screen.dart';
import 'screens/planilla_preview_screen.dart';
import 'screens/service_history_screen.dart';
import 'screens/backup_screen.dart';
import 'services/service_history_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const PlanillaApp());
}

class PlanillaApp extends StatefulWidget {
  const PlanillaApp({super.key});

  @override
  State<PlanillaApp> createState() => _PlanillaAppState();
}

class _PlanillaAppState extends State<PlanillaApp>
    with WidgetsBindingObserver {
  var _isProcessingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _processCompletedServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processCompletedServices();
    }
  }

  Future<void> _processCompletedServices() async {
    if (_isProcessingHistory) {
      return;
    }

    _isProcessingHistory = true;
    try {
      await ServiceHistoryService.processCompletedServices();
    } catch (error, stackTrace) {
      debugPrint('No se pudo actualizar el histórico: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isProcessingHistory = false;
    }
  }

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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServiceHistoryScreen(),
                    ),
                  );
                },
                label: const Text('Consultar histórico'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings_backup_restore),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BackupScreen(),
                    ),
                  );
                },
                label: const Text('Copias de seguridad'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
