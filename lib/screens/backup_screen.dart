import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  static const int _maximumBackupSize = 10 * 1024 * 1024;

  var _isBusy = false;
  var _hasRecoveryBackup = false;

  @override
  void initState() {
    super.initState();
    _refreshRecoveryState();
  }

  Future<void> _refreshRecoveryState() async {
    final available = await BackupService.hasRecoveryBackup();
    if (!mounted) return;
    setState(() => _hasRecoveryBackup = available);
  }

  Future<void> _exportBackup() async {
    await _runBusy(() async {
      final backupJson = await BackupService.createBackupJson();
      final now = DateTime.now();
      final fileName =
          'idmji_biblias_${DateFormat('yyyy-MM-dd').format(now)}.json';
      final file = XFile.fromData(
        Uint8List.fromList(utf8.encode(backupJson)),
        mimeType: 'application/json',
        name: fileName,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          fileNameOverrides: [fileName],
          subject: 'Copia de seguridad de IDMJI Voluntariado Biblias',
        ),
      );
    });
  }

  Future<void> _importBackup() async {
    await _runBusy(() async {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null) return;

      final file = result.files.single;
      if (file.size > _maximumBackupSize) {
        throw const FormatException('La copia supera el límite de 10 MB');
      }
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException('No se pudo leer el archivo seleccionado');
      }

      final backupJson = utf8.decode(bytes);
      final summary = BackupService.inspectBackup(backupJson);
      if (!mounted) return;

      final confirmed = await _confirmRestore(
        title: 'Importar copia',
        summary: summary,
        message: 'Los datos locales actuales serán reemplazados.',
      );
      if (!confirmed) return;

      await BackupService.restoreBackup(backupJson);
      await _refreshRecoveryState();
      if (!mounted) return;
      _showMessage('Copia restaurada correctamente');
    });
  }

  Future<void> _restorePreviousData() async {
    await _runBusy(() async {
      final summary = await BackupService.inspectRecoveryBackup();
      if (summary == null || !mounted) return;

      final confirmed = await _confirmRestore(
        title: 'Recuperar datos anteriores',
        summary: summary,
        message: 'Se reemplazarán los datos actuales por la copia anterior.',
      );
      if (!confirmed) return;

      await BackupService.restoreRecoveryBackup();
      await _refreshRecoveryState();
      if (!mounted) return;
      _showMessage('Datos anteriores recuperados');
    });
  }

  Future<bool> _confirmRestore({
    required String title,
    required BackupSummary summary,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              'Copia del '
              '${DateFormat('dd/MM/yyyy HH:mm').format(summary.exportedAt.toLocal())}',
            ),
            Text('Voluntarios: ${summary.volunteerCount}'),
            Text('Asignaciones guardadas: ${summary.assignmentCount}'),
            Text('Registros históricos: ${summary.serviceEventCount}'),
            Text('Cultos procesados: ${summary.processedServiceCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    return 'No se pudo completar la operación';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copias de seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Guarda todos los voluntarios, asignaciones e históricos en un '
            'archivo que podrás importar en otro dispositivo.',
          ),
          const SizedBox(height: 20),
          _BackupActionCard(
            icon: Icons.upload_file,
            title: 'Exportar copia',
            description: 'Crea y comparte un archivo JSON con todos los datos.',
            buttonLabel: 'Exportar',
            onPressed: _isBusy ? null : _exportBackup,
          ),
          const SizedBox(height: 12),
          _BackupActionCard(
            icon: Icons.download,
            title: 'Importar copia',
            description:
                'Valida el archivo antes de reemplazar los datos locales.',
            buttonLabel: 'Seleccionar archivo',
            onPressed: _isBusy ? null : _importBackup,
          ),
          if (_hasRecoveryBackup) ...[
            const SizedBox(height: 12),
            _BackupActionCard(
              icon: Icons.restore,
              title: 'Recuperar datos anteriores',
              description:
                  'Restaura el estado guardado antes de la última importación.',
              buttonLabel: 'Recuperar',
              onPressed: _isBusy ? null : _restorePreviousData,
            ),
          ],
          if (_isBusy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _BackupActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
