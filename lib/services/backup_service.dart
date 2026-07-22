import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_templates.dart';
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
  static const int schemaVersion = 1;
  static const String _recoveryKey = 'backup_before_restore_v1';

  static Future<String> createBackupJson() async {
    final volunteers = await VolunteerStorageService.loadVolunteers();
    final weekStart = await WeekService.loadWeekStart();
    final alabanza = await AssignmentStorageService.loadAssignmentIds(
      'alabanza_assignments_v2',
    );
    final estudio = await AssignmentStorageService.loadAssignmentIds(
      'estudio_assignments_v2',
    );
    final ensenanza = await AssignmentStorageService.loadAssignmentIds(
      'ensenanza_assignments_v2',
    );
    final serviceEvents = await ServiceEventStorageService.loadEvents();
    final processedServices = await ProcessedServicesStorage.loadProcessed();

    final backupJson = const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'volunteers': volunteers.map((volunteer) => volunteer.toJson()).toList(),
      'weekStart': weekStart.toIso8601String(),
      'assignments': {
        'alabanza': _normalizedAssignments(
          alabanza,
          EventTemplates.alabanza().length,
        ),
        'estudio': _normalizedAssignments(
          estudio,
          EventTemplates.estudio().length,
        ),
        'ensenanza': _normalizedAssignments(
          ensenanza,
          EventTemplates.ensenanza().length,
        ),
      },
      'serviceEvents': serviceEvents.map((event) => event.toJson()).toList(),
      'processedServices': processedServices.toList()..sort(),
    });
    _parseBackup(backupJson);
    return backupJson;
  }

  static BackupSummary inspectBackup(String backupJson) {
    final data = _parseBackup(backupJson);
    return BackupSummary(
      exportedAt: data.exportedAt,
      volunteerCount: data.volunteers.length,
      assignmentCount: [
        ...data.alabanza,
        ...data.estudio,
        ...data.ensenanza,
      ].where((id) => id.isNotEmpty).length,
      serviceEventCount: data.serviceEvents.length,
      processedServiceCount: data.processedServices.length,
    );
  }

  static Future<void> restoreBackup(String backupJson) async {
    final data = _parseBackup(backupJson);
    final currentBackup = await createBackupJson();
    final prefs = await SharedPreferences.getInstance();

    await _setString(prefs, _recoveryKey, currentBackup);

    try {
      await _writeBackup(prefs, data);
    } catch (_) {
      await _writeBackup(prefs, _parseBackup(currentBackup));
      rethrow;
    }
  }

  static Future<bool> hasRecoveryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recoveryKey) != null;
  }

  static Future<BackupSummary?> inspectRecoveryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final recovery = prefs.getString(_recoveryKey);
    if (recovery == null) return null;
    return inspectBackup(recovery);
  }

  static Future<void> restoreRecoveryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final recovery = prefs.getString(_recoveryKey);
    if (recovery == null) {
      throw StateError('No hay una copia anterior disponible');
    }
    await restoreBackup(recovery);
  }

  static _BackupData _parseBackup(String backupJson) {
    final decoded = jsonDecode(backupJson);
    final root = _map(decoded, 'El archivo no contiene un objeto JSON válido');

    if (root['schemaVersion'] != schemaVersion) {
      throw const FormatException('Versión de copia no compatible');
    }

    final exportedAt = DateTime.parse(_string(root['exportedAt'], 'exportedAt'));
    final weekStart = DateTime.parse(_string(root['weekStart'], 'weekStart'));
    if (weekStart.weekday != DateTime.monday) {
      throw const FormatException('La semana guardada no comienza en lunes');
    }

    final volunteers = _list(root['volunteers'], 'volunteers')
        .map((value) => Volunteer.fromJson(_map(value, 'volunteers')))
        .toList();
    final volunteerIds = <String>{};
    for (final volunteer in volunteers) {
      if (volunteer.id.isEmpty || volunteer.name.trim().isEmpty) {
        throw const FormatException('Hay un voluntario sin identificador o nombre');
      }
      if (!volunteerIds.add(volunteer.id)) {
        throw const FormatException('Hay identificadores de voluntario duplicados');
      }
    }

    final assignments = _map(root['assignments'], 'assignments');
    final alabanza = _stringList(assignments['alabanza'], 'assignments.alabanza');
    final estudio = _stringList(assignments['estudio'], 'assignments.estudio');
    final ensenanza = _stringList(assignments['ensenanza'], 'assignments.ensenanza');

    _validateAssignmentList(
      alabanza,
      EventTemplates.alabanza().length,
      volunteerIds,
      'Alabanza',
    );
    _validateAssignmentList(
      estudio,
      EventTemplates.estudio().length,
      volunteerIds,
      'Estudio',
    );
    _validateAssignmentList(
      ensenanza,
      EventTemplates.ensenanza().length,
      volunteerIds,
      'Enseñanza',
    );

    final serviceEvents = _list(root['serviceEvents'], 'serviceEvents')
        .map((value) => ServiceEvent.fromJson(_map(value, 'serviceEvents')))
        .toList();
    for (final event in serviceEvents) {
      if (event.volunteerId.isEmpty ||
          event.serviceType.isEmpty ||
          event.eventId.isEmpty) {
        throw const FormatException('Hay eventos históricos incompletos');
      }
    }

    final processedServices = _stringList(
      root['processedServices'],
      'processedServices',
    ).toSet();
    if (processedServices.any((eventId) => eventId.isEmpty)) {
      throw const FormatException('Hay cultos procesados sin identificador');
    }

    return _BackupData(
      exportedAt: exportedAt,
      volunteers: volunteers,
      weekStart: weekStart,
      alabanza: alabanza,
      estudio: estudio,
      ensenanza: ensenanza,
      serviceEvents: serviceEvents,
      processedServices: processedServices,
    );
  }

  static Future<void> _writeBackup(
    SharedPreferences prefs,
    _BackupData data,
  ) async {
    await _setStringList(
      prefs,
      'volunteers_v2',
      data.volunteers.map((volunteer) => jsonEncode(volunteer.toJson())).toList(),
    );
    await _setString(prefs, 'week_start_date', data.weekStart.toIso8601String());
    await _setStringList(prefs, 'alabanza_assignments_v2', data.alabanza);
    await _setStringList(prefs, 'estudio_assignments_v2', data.estudio);
    await _setStringList(prefs, 'ensenanza_assignments_v2', data.ensenanza);
    await _setStringList(
      prefs,
      'service_events_v1',
      data.serviceEvents.map((event) => jsonEncode(event.toJson())).toList(),
    );
    await _setStringList(
      prefs,
      'processed_services_v1',
      data.processedServices.toList()..sort(),
    );

    await prefs.remove('volunteers');
    await prefs.remove('alabanza_assignments');
    await prefs.remove('estudio_assignments');
    await prefs.remove('ensenanza_assignments');
  }

  static void _validateAssignmentList(
    List<String> assignments,
    int expectedLength,
    Set<String> volunteerIds,
    String label,
  ) {
    if (assignments.length != expectedLength) {
      throw FormatException('$label tiene un número de puestos incorrecto');
    }
    if (assignments.any(
      (id) => id.isNotEmpty && !volunteerIds.contains(id),
    )) {
      throw FormatException('$label contiene voluntarios inexistentes');
    }
  }

  static List<String> _normalizedAssignments(
    List<String> assignments,
    int expectedLength,
  ) {
    return List<String>.generate(
      expectedLength,
      (index) => index < assignments.length ? assignments[index] : '',
    );
  }

  static Map<String, dynamic> _map(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Campo no válido: $field');
    }
    return Map<String, dynamic>.from(value);
  }

  static List<dynamic> _list(Object? value, String field) {
    if (value is! List) {
      throw FormatException('Campo no válido: $field');
    }
    return value;
  }

  static String _string(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw FormatException('Campo no válido: $field');
    }
    return value;
  }

  static List<String> _stringList(Object? value, String field) {
    final values = _list(value, field);
    if (values.any((item) => item is! String)) {
      throw FormatException('Campo no válido: $field');
    }
    return values.cast<String>().toList();
  }

  static Future<void> _setString(
    SharedPreferences prefs,
    String key,
    String value,
  ) async {
    if (!await prefs.setString(key, value)) {
      throw StateError('No se pudo guardar $key');
    }
  }

  static Future<void> _setStringList(
    SharedPreferences prefs,
    String key,
    List<String> value,
  ) async {
    if (!await prefs.setStringList(key, value)) {
      throw StateError('No se pudo guardar $key');
    }
  }
}

class _BackupData {
  final DateTime exportedAt;
  final List<Volunteer> volunteers;
  final DateTime weekStart;
  final List<String> alabanza;
  final List<String> estudio;
  final List<String> ensenanza;
  final List<ServiceEvent> serviceEvents;
  final Set<String> processedServices;

  const _BackupData({
    required this.exportedAt,
    required this.volunteers,
    required this.weekStart,
    required this.alabanza,
    required this.estudio,
    required this.ensenanza,
    required this.serviceEvents,
    required this.processedServices,
  });
}
