import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/backup_screen.dart';
import 'screens/service_history_screen.dart';
import 'screens/volunteers_screen.dart';
import 'screens/week_editor_screen.dart';
import 'services/service_history_service.dart';

void main() => runApp(const AseoApp());

class AseoApp extends StatefulWidget {
  const AseoApp({super.key});

  @override
  State<AseoApp> createState() => _AseoAppState();
}

class _AseoAppState extends State<AseoApp> with WidgetsBindingObserver {
  var _processingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _processHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _processHistory();
  }

  Future<void> _processHistory() async {
    if (_processingHistory) return;
    _processingHistory = true;
    try {
      await ServiceHistoryService.processCompletedServices();
    } catch (error, stackTrace) {
      debugPrint('No se pudo actualizar el histórico: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _processingHistory = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const corporateBlue = Color(0xFF0E2A8B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IDMJI Voluntariado Aseo',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      theme: ThemeData(
        fontFamily: 'Montserrat',
        colorScheme: ColorScheme.fromSeed(seedColor: corporateBlue),
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
      appBar: AppBar(title: const Text('IDMJI Voluntariado Aseo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HomeAction(
            icon: Icons.groups_2_outlined,
            label: 'Gestionar voluntarias',
            onPressed: () => _open(context, const VolunteersScreen()),
          ),
          _HomeAction(
            icon: Icons.view_week_outlined,
            label: 'Planilla semanal',
            onPressed: () =>
                _open(context, const WeekEditorScreen(mode: ScheduleMode.week)),
          ),
          _HomeAction(
            icon: Icons.calendar_month_outlined,
            label: 'Planilla mensual',
            onPressed: () => _open(
              context,
              const WeekEditorScreen(mode: ScheduleMode.month),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _HomeAction(
            icon: Icons.history,
            label: 'Consultar histórico',
            onPressed: () => _open(context, const ServiceHistoryScreen()),
          ),
          _HomeAction(
            icon: Icons.settings_backup_restore,
            label: 'Copias de seguridad',
            onPressed: () => _open(context, const BackupScreen()),
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _HomeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(label),
        ),
      ),
    );
  }
}
