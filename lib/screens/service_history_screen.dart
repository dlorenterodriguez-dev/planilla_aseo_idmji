import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/assignment.dart';
import '../models/event_templates.dart';
import '../models/service_event.dart';
import '../models/service_types.dart';
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
  var _isLoading = true;
  var _canUndo = false;
  Object? _loadError;
  List<_HistoryGroup> _groups = [];
  List<Volunteer> _volunteers = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final eventsFuture = ServiceEventStorageService.loadEvents();
      final processedFuture = ProcessedServicesStorage.loadProcessed();
      final volunteersFuture = VolunteerStorageService.loadVolunteers();
      final undoFuture = ServiceHistoryCorrectionService.canUndo();

      final events = await eventsFuture;
      final processed = await processedFuture;
      final volunteers = await volunteersFuture;
      final canUndo = await undoFuture;

      volunteers.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      if (!mounted) return;
      setState(() {
        _groups = _buildGroups(events, processed);
        _volunteers = volunteers;
        _canUndo = canUndo;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _editSlot(_HistoryGroup group, _HistorySlot slot) async {
    final currentVolunteerId = slot.event?.volunteerId ?? '';
    var selectedVolunteerId = currentVolunteerId;
    final knownIds = _volunteers.map((volunteer) => volunteer.id).toSet();

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Corregir puesto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.assignment.role),
              Text(
                '${slot.assignment.startTime}-${slot.assignment.endTime}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedVolunteerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Voluntario que sirvió',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('— No realizado —'),
                  ),
                  if (currentVolunteerId.isNotEmpty &&
                      !knownIds.contains(currentVolunteerId))
                    DropdownMenuItem(
                      value: currentVolunteerId,
                      child: Text(currentVolunteerId),
                    ),
                  ..._volunteers.map(
                    (volunteer) => DropdownMenuItem(
                      value: volunteer.id,
                      child: Text(
                        volunteer.isActive
                            ? volunteer.name
                            : '${volunteer.name} (inactivo)',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedVolunteerId = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedVolunteerId),
              child: const Text('Guardar corrección'),
            ),
          ],
        ),
      ),
    );

    if (selected == null || selected == currentVolunteerId || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar corrección'),
        content: Text(
          selected.isEmpty
              ? 'El puesto quedará marcado como no realizado.'
              : 'Se actualizará el voluntario que realizó este puesto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ServiceHistoryCorrectionService.correctAssignment(
        eventId: group.eventId,
        eventType: group.eventType,
        serviceType: slot.serviceType,
        date: group.date,
        assignment: slot.assignment,
        volunteerId: selected,
      );
      await _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Histórico actualizado'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: _undoLastCorrection,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo corregir el histórico')),
      );
    }
  }

  Future<void> _undoLastCorrection() async {
    try {
      await ServiceHistoryCorrectionService.undoLastCorrection();
      await _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrección deshecha')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo deshacer la corrección')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de servicios'),
        actions: [
          if (_canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Deshacer última corrección',
              onPressed: _undoLastCorrection,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _loadHistory,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }

    if (_groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Todavía no hay servicios contabilizados',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          final completedSlots =
              group.slots.where((slot) => slot.event != null).length;
          return Card(
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              leading: const Icon(Icons.event_available),
              title: Text(
                '${_eventTypeLabel(group.eventType)} · '
                '${DateFormat('dd/MM/yyyy').format(group.date)}',
              ),
              subtitle: Text(
                '$completedSlots de ${group.slots.length} puestos registrados',
              ),
              children: group.slots
                  .map((slot) => _buildSlotTile(group, slot))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotTile(_HistoryGroup group, _HistorySlot slot) {
    final event = slot.event;
    final volunteer = event == null
        ? null
        : _firstOrNull(
            _volunteers.where(
              (candidate) => candidate.id == event.volunteerId,
            ),
          );
    final volunteerLabel = event == null
        ? 'Sin registrar'
        : volunteer?.name ?? event.volunteerId;

    return ListTile(
      leading: Icon(_serviceTypeIcon(slot.serviceType)),
      title: Text(volunteerLabel),
      subtitle: Text(
        '${slot.assignment.role} · '
        '${slot.assignment.startTime}-${slot.assignment.endTime}',
      ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _editSlot(group, slot),
    );
  }

  static List<_HistoryGroup> _buildGroups(
    List<ServiceEvent> events,
    Set<String> processedEventIds,
  ) {
    final allEventIds = {
      ...processedEventIds,
      ...events.map((event) => event.eventId),
    };
    final eventsById = <String, List<ServiceEvent>>{};
    for (final event in events) {
      eventsById.putIfAbsent(event.eventId, () => []).add(event);
    }

    final groups = <_HistoryGroup>[];
    for (final eventId in allEventIds) {
      final groupEvents = eventsById[eventId] ?? [];
      final eventType = groupEvents.isNotEmpty
          ? groupEvents.first.eventType
          : _eventTypeFromId(eventId);
      final date = groupEvents.isNotEmpty
          ? groupEvents.first.date
          : _dateFromId(eventId);
      if (eventType == null || date == null) continue;

      final template = _templateFor(eventType);
      final slots = template.map((assignment) {
        final matchingEvents = groupEvents.where(
          (event) =>
              event.role == assignment.role &&
              event.startTime == assignment.startTime &&
              event.endTime == assignment.endTime,
        );
        return _HistorySlot(
          assignment: assignment,
          serviceType: ServiceTypes.fromRole(assignment.role),
          event: _firstOrNull(matchingEvents),
        );
      }).toList();

      for (final event in groupEvents) {
        final represented = slots.any(
          (slot) =>
              slot.assignment.role == event.role &&
              slot.assignment.startTime == event.startTime &&
              slot.assignment.endTime == event.endTime,
        );
        if (!represented) {
          slots.add(
            _HistorySlot(
              assignment: Assignment(
                role: event.role,
                startTime: event.startTime,
                endTime: event.endTime,
              ),
              serviceType: event.serviceType,
              event: event,
            ),
          );
        }
      }

      slots.sort(
        (a, b) => a.assignment.startTime.compareTo(b.assignment.startTime),
      );
      groups.add(
        _HistoryGroup(
          eventId: eventId,
          eventType: eventType,
          date: date,
          slots: slots,
        ),
      );
    }

    groups.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      return a.eventId.compareTo(b.eventId);
    });
    return groups;
  }

  static List<Assignment> _templateFor(String eventType) {
    switch (eventType) {
      case 'alabanza':
        return EventTemplates.alabanza();
      case 'estudio':
        return EventTemplates.estudio();
      case 'ensenanza':
        return EventTemplates.ensenanza();
      default:
        return [];
    }
  }

  static DateTime? _dateFromId(String eventId) {
    if (eventId.length < 10) return null;
    return DateTime.tryParse(eventId.substring(0, 10));
  }

  static String? _eventTypeFromId(String eventId) {
    if (eventId.length < 12) return null;
    return eventId.substring(11);
  }

  static String _eventTypeLabel(String eventType) {
    switch (eventType) {
      case 'alabanza':
        return 'Alabanza';
      case 'estudio':
        return 'Estudio';
      case 'ensenanza':
        return 'Enseñanza';
      default:
        return eventType;
    }
  }

  static IconData _serviceTypeIcon(String serviceType) {
    switch (serviceType) {
      case ServiceTypes.vigilance:
        return Icons.visibility;
      case ServiceTypes.microphone:
        return Icons.mic;
      case ServiceTypes.accommodation:
        return Icons.chair_alt;
      case ServiceTypes.cleaning:
        return Icons.cleaning_services;
      case ServiceTypes.bookTable:
        return Icons.menu_book;
      case ServiceTypes.audiovisuals:
        return Icons.cast_connected;
      default:
        return Icons.assignment_ind_outlined;
    }
  }

  static T? _firstOrNull<T>(Iterable<T> values) {
    for (final value in values) {
      return value;
    }
    return null;
  }
}

class _HistoryGroup {
  final String eventId;
  final String eventType;
  final DateTime date;
  final List<_HistorySlot> slots;

  const _HistoryGroup({
    required this.eventId,
    required this.eventType,
    required this.date,
    required this.slots,
  });
}

class _HistorySlot {
  final Assignment assignment;
  final String serviceType;
  final ServiceEvent? event;

  const _HistorySlot({
    required this.assignment,
    required this.serviceType,
    required this.event,
  });
}
