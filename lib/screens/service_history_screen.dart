import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/service_event.dart';
import '../models/service_types.dart';
import '../services/service_event_storage_service.dart';
import '../services/volunteer_storage_service.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  var _isLoading = true;
  Object? _loadError;
  List<_HistoryGroup> _groups = [];
  Map<String, String> _volunteerNames = {};

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
      final volunteersFuture = VolunteerStorageService.loadVolunteers();
      final events = await eventsFuture;
      final volunteers = await volunteersFuture;

      if (!mounted) return;
      setState(() {
        _groups = _groupEvents(events);
        _volunteerNames = {
          for (final volunteer in volunteers)
            volunteer.id: volunteer.name,
        };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de servicios')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text('No se pudo cargar el histórico'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
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
          return Card(
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              leading: const Icon(Icons.event_available),
              title: Text(
                '${_eventTypeLabel(group.eventType)} · '
                '${DateFormat('dd/MM/yyyy').format(group.date)}',
              ),
              subtitle: Text(
                '${group.events.length} '
                '${group.events.length == 1 ? 'puesto' : 'puestos'}',
              ),
              children: group.events.map(_buildEventTile).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventTile(ServiceEvent event) {
    final volunteerName = _volunteerNames[event.volunteerId];
    final schedule = event.startTime.isEmpty || event.endTime.isEmpty
        ? ''
        : ' · ${event.startTime}-${event.endTime}';

    return ListTile(
      leading: Icon(_serviceTypeIcon(event.serviceType)),
      title: Text(volunteerName ?? event.volunteerId),
      subtitle: Text('${event.role}$schedule'),
      trailing: volunteerName == null
          ? const Tooltip(
              message: 'Voluntario no disponible',
              child: Icon(Icons.person_off_outlined),
            )
          : null,
    );
  }

  static List<_HistoryGroup> _groupEvents(List<ServiceEvent> events) {
    final grouped = <String, List<ServiceEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.eventId, () => []).add(event);
    }

    final groups = grouped.entries.map((entry) {
      final groupEvents = entry.value
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      final first = groupEvents.first;
      return _HistoryGroup(
        eventId: entry.key,
        eventType: first.eventType,
        date: first.date,
        events: groupEvents,
      );
    }).toList()
      ..sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return a.eventId.compareTo(b.eventId);
      });

    return groups;
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
}

class _HistoryGroup {
  final String eventId;
  final String eventType;
  final DateTime date;
  final List<ServiceEvent> events;

  const _HistoryGroup({
    required this.eventId,
    required this.eventType,
    required this.date,
    required this.events,
  });
}
