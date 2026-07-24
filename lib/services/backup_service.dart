import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/assignment.dart';
import '../models/service_event.dart';
import '../models/volunteer.dart';
import 'assignment_storage_service.dart';
import 'processed_services_storage.dart';
import 'service_event_storage_service.dart';
import 'volunteer_storage_service.dart';
import 'week_service.dart';

class BackupSummary {
  final DateTime exportedAt;
  final int volunteerCount;
  final int assignmentCount;
  final int serviceEventCount;
  final int processedServiceCount;

  const BackupSummary({
    required this.exportedAt,
    required this.volunteerCount,
    required this.assignmentCount,
    required this.serviceEventCount,
    required this.processedServiceCount,
  });
}

class BackupService {
  static const String applicationId = 'idmji-voluntariado-aseo';
  static const int schemaVersion = 1;
  static const String _recoveryKey = 'aseo_backup_before_restore_v1';

  static Future<String> createBackupJson() async {
    final data = {
      'applicationId': applicationId,
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'volunteers': (await VolunteerStorageService.loadVolunteers())
          .map((volunteer) => volunteer.toJson())
          .toList(),
      'assignments': (await AssignmentStorageService.loadAssignments())
          .map((assignment) => assignment.toJson())
          .toList(),
      'serviceEvents': (await ServiceEventStorageService.loadEvents())
          .map((event) => event.toJson())
          .toList(),
      'processedServices':
          (await ProcessedServicesStorage.loadProcessed()).toList()..sort(),
      'weekStart': (await WeekService.loadWeekStart()).toIso8601String(),
    };
    final result = const JsonEncoder.withIndent('  ').convert(data);
    _parseBackup(result);
    return result;
  }

  static BackupSummary inspectBackup(String backupJson) {
    final data = _parseBackup(backupJson);
    return BackupSummary(
      exportedAt: data.exportedAt,
      volunteerCount: data.volunteers.length,
      assignmentCount: data.assignments
          .where((assignment) => assignment.volunteerId?.isNotEmpty ?? false)
          .length,
      serviceEventCount: data.serviceEvents.length,
      processedServiceCount: data.processedServices.length,
    );
  }

  static Future<void> restoreBackup(String backupJson) async {
    final incoming = _parseBackup(backupJson);
    final current = await createBackupJson();
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_recoveryKey, current)) {
      throw StateError('No se pudo crear la copia preventiva');
    }
    try {
      await _writeBackup(prefs, incoming);
    } catch (_) {
      await _writeBackup(prefs, _parseBackup(current));
      rethrow;
    }
  }

  static Future<bool> hasRecoveryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recoveryKey) != null;
  }

  static Future<BackupSummary?> inspectRecoveryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_recoveryKey);
    return value == null ? null : inspectBackup(value);
  }

  static Future<void> restoreRecoveryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_recoveryKey);
    if (value == null) throw StateError('No hay una copia anterior disponible');
    await _writeBackup(prefs, _parseBackup(value));
    await prefs.remove(_recoveryKey);
  }

  static _BackupData _parseBackup(String backupJson) {
    final decoded = jsonDecode(backupJson);
    if (decoded is! Map) {
      throw const FormatException(
        'El archivo no contiene un objeto JSON válido',
      );
    }
    final root = Map<String, dynamic>.from(decoded);
    if (root['applicationId'] != applicationId) {
      throw const FormatException(
        'Esta copia no pertenece a IDMJI Voluntariado Aseo',
      );
    }
    if (root['schemaVersion'] != schemaVersion) {
      throw const FormatException('Versión de copia no compatible');
    }

    final exportedAt = DateTime.parse(_requiredString(root, 'exportedAt'));
    final weekStart = DateTime.parse(_requiredString(root, 'weekStart'));
    final volunteers = _mapList(
      root,
      'volunteers',
    ).map(Volunteer.fromJson).toList();
    final assignments = _mapList(
      root,
      'assignments',
    ).map(Assignment.fromJson).toList();
    final events = _mapList(
      root,
      'serviceEvents',
    ).map(ServiceEvent.fromJson).toList();
    final processed = _stringList(root, 'processedServices').toSet();

    final volunteerIds = <String>{};
    for (final volunteer in volunteers) {
      if (volunteer.id.isEmpty || volunteer.name.trim().isEmpty) {
        throw const FormatException('Hay una voluntaria incompleta');
      }
      if (!volunteerIds.add(volunteer.id)) {
        throw const FormatException('Hay voluntarias duplicadas');
      }
    }
    final eventIds = <String>{};
    for (final assignment in assignments) {
      if (assignment.eventId.isEmpty || !eventIds.add(assignment.eventId)) {
        throw const FormatException(
          'Hay asignaciones duplicadas o incompletas',
        );
      }
      final volunteerId = assignment.volunteerId;
      if (volunteerId != null &&
          volunteerId.isNotEmpty &&
          !volunteerIds.contains(volunteerId)) {
        throw const FormatException(
          'Una asignación usa una voluntaria inexistente',
        );
      }
    }
    for (final event in events) {
      if (event.eventId.isEmpty || event.volunteerId.isEmpty) {
        throw const FormatException('Hay registros históricos incompletos');
      }
    }

    return _BackupData(
      exportedAt: exportedAt,
      weekStart: weekStart,
      volunteers: volunteers,
      assignments: assignments,
      serviceEvents: events,
      processedServices: processed,
    );
  }

  static Future<void> _writeBackup(
    SharedPreferences prefs,
    _BackupData data,
  ) async {
    await _setStringList(
      prefs,
      VolunteerStorageService.storageKey,
      data.volunteers.map((value) => jsonEncode(value.toJson())).toList(),
    );
    await _setStringList(
      prefs,
      AssignmentStorageService.storageKey,
      data.assignments.map((value) => jsonEncode(value.toJson())).toList(),
    );
    await _setStringList(
      prefs,
      ServiceEventStorageService.storageKey,
      data.serviceEvents.map((value) => jsonEncode(value.toJson())).toList(),
    );
    await _setStringList(
      prefs,
      ProcessedServicesStorage.storageKey,
      data.processedServices.toList()..sort(),
    );
    if (!await prefs.setString(
      WeekService.storageKey,
      data.weekStart.toIso8601String(),
    )) {
      throw StateError('No se pudo restaurar la semana seleccionada');
    }
  }

  static List<Map<String, dynamic>> _mapList(
    Map<String, dynamic> root,
    String key,
  ) {
    final value = root[key];
    if (value is! List) throw FormatException('Campo no válido: $key');
    return value.map((item) {
      if (item is! Map) throw FormatException('Campo no válido: $key');
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static List<String> _stringList(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Campo no válido: $key');
    }
    return value.cast<String>();
  }

  static String _requiredString(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Campo no válido: $key');
    }
    return value;
  }

  static Future<void> _setStringList(
    SharedPreferences prefs,
    String key,
    List<String> value,
  ) async {
    if (!await prefs.setStringList(key, value)) {
      throw StateError('No se pudo restaurar $key');
    }
  }
}

class _BackupData {
  final DateTime exportedAt;
  final DateTime weekStart;
  final List<Volunteer> volunteers;
  final List<Assignment> assignments;
  final List<ServiceEvent> serviceEvents;
  final Set<String> processedServices;

  const _BackupData({
    required this.exportedAt,
    required this.weekStart,
    required this.volunteers,
    required this.assignments,
    required this.serviceEvents,
    required this.processedServices,
  });
}
