import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/service_event.dart';
import '../models/volunteer.dart';
import '../services/processed_services_storage.dart';
import '../services/service_event_storage_service.dart';
import '../services/service_history_correction_service.dart';
import '../services/volunteer_storage_service.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<ServiceEvent> _events = [];
  List<Volunteer> _volunteers = [];
  Set<String> _processed = {};
  var _loading = true;
  var _canUndo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await ServiceEventStorageService.loadEvents();
    final volunteers = await VolunteerStorageService.loadVolunteers();
    final processed = await ProcessedServicesStorage.loadProcessed();
    final canUndo = await ServiceHistoryCorrectionService.canUndo();
    events.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    setState(() {
      _events = events;
      _volunteers = volunteers;
      _processed = processed;
      _canUndo = canUndo;
      _loading = false;
    });
  }

  Future<void> _correct(_HistoryRow row) async {
    var selected = row.event?.volunteerId ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Corregir servicio'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: 'Voluntaria que sirvió',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('— No realizado —'),
              ),
              if (selected.isNotEmpty &&
                  !_volunteers.any((volunteer) => volunteer.id == selected))
                DropdownMenuItem(
                  value: selected,
                  child: const Text('Voluntaria eliminada'),
                ),
              ..._volunteers.map(
                (volunteer) => DropdownMenuItem(
                  value: volunteer.id,
                  child: Text(
                    volunteer.isActive
                        ? volunteer.name
                        : '${volunteer.name} · inactiva',
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              selected = value ?? '';
              setDialogState(() {});
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result == row.event?.volunteerId) return;
    await ServiceHistoryCorrectionService.correctAssignment(
      eventId: row.eventId,
      eventType: row.eventType,
      date: row.date,
      volunteerId: result,
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Histórico actualizado'),
        action: SnackBarAction(label: 'Deshacer', onPressed: _undo),
      ),
    );
  }

  Future<void> _undo() async {
    await ServiceHistoryCorrectionService.undoLastCorrection();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Corrección deshecha')));
  }

  List<_HistoryRow> get _rows {
    final eventById = {for (final event in _events) event.eventId: event};
    final ids = {..._processed, ...eventById.keys};
    final rows = ids.map((eventId) {
      final event = eventById[eventId];
      return _HistoryRow(
        eventId: eventId,
        eventType: event?.eventType ?? _eventTypeFromId(eventId),
        date: event?.date ?? DateTime.parse(eventId.substring(0, 10)),
        event: event,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Aseo'),
        actions: [
          if (_canUndo)
            IconButton(
              onPressed: _undo,
              tooltip: 'Deshacer última corrección',
              icon: const Icon(Icons.undo),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? const Center(child: Text('Todavía no hay cultos contabilizados'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final volunteer = _volunteers
                      .where(
                        (candidate) => candidate.id == row.event?.volunteerId,
                      )
                      .firstOrNull;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(
                        volunteer?.name ??
                            (row.event == null
                                ? 'No realizado'
                                : 'Voluntaria desconocida'),
                      ),
                      subtitle: Text(
                        '${_eventTypeLabel(row.eventType)}'
                        '${_positionLabel(row.eventId)} · '
                        '${DateFormat('dd/MM/yyyy').format(row.date)}',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _correct(row),
                    ),
                  );
                },
              ),
            ),
    );
  }

  static String _eventTypeFromId(String eventId) {
    if (eventId.length <= 11) return '';
    return eventId
        .substring(11)
        .replaceFirst(RegExp(r'-(sala|banos)-\d+$'), '');
  }

  static String _positionLabel(String eventId) {
    final match = RegExp(r'-(sala|banos)-(\d+)$').firstMatch(eventId);
    if (match == null) return ' · ';
    return match.group(1) == 'sala'
        ? ' · Sala ${match.group(2)} · '
        : ' · Baños · ';
  }

  static String _eventTypeLabel(String eventType) => switch (eventType) {
    'alabanza' => 'Alabanza',
    'estudio' => 'Estudio',
    'ensenanza' => 'Enseñanza',
    _ => eventType,
  };
}

class _HistoryRow {
  final String eventId;
  final String eventType;
  final DateTime date;
  final ServiceEvent? event;

  const _HistoryRow({
    required this.eventId,
    required this.eventType,
    required this.date,
    required this.event,
  });
}
