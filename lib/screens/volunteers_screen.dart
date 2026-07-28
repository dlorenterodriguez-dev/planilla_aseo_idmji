import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/absence_period.dart';
import '../models/volunteer.dart';
import '../services/assignment_storage_service.dart';
import '../services/service_history_query_service.dart';
import '../services/volunteer_storage_service.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  List<Volunteer> _volunteers = [];
  Map<String, VolunteerServiceStats> _stats = {};
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final volunteers = await VolunteerStorageService.loadVolunteers();
    final stats = await ServiceHistoryQueryService.statsByVolunteer();
    volunteers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    if (!mounted) return;
    setState(() {
      _volunteers = volunteers;
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _editVolunteer([Volunteer? volunteer]) async {
    final result = await showDialog<Volunteer>(
      context: context,
      builder: (_) => _VolunteerDialog(volunteer: volunteer),
    );
    if (result == null) return;
    final index = _volunteers.indexWhere((current) => current.id == result.id);
    if (index < 0) {
      _volunteers.add(result);
    } else {
      _volunteers[index] = result;
    }
    await VolunteerStorageService.saveVolunteers(_volunteers);
    await _load();
  }

  Future<void> _deleteVolunteer(Volunteer volunteer) async {
    final futureAssignments =
        await AssignmentStorageService.countVolunteerAssignments(volunteer.id);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar voluntaria'),
        content: Text(
          '¿Eliminar a ${volunteer.name}? Sus $futureAssignments asignaciones '
          'guardadas quedarán vacías. El histórico realizado se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AssignmentStorageService.removeVolunteerFromAssignments(volunteer.id);
    _volunteers.removeWhere((current) => current.id == volunteer.id);
    await VolunteerStorageService.saveVolunteers(_volunteers);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voluntarias de Aseo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editVolunteer(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Añadir'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _volunteers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no hay voluntarias.\nPulsa “Añadir” para comenzar.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: _volunteers.length,
              itemBuilder: (context, index) {
                final volunteer = _volunteers[index];
                final stats = _stats[volunteer.id];
                final last = stats?.lastService;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        volunteer.name.trim().isEmpty
                            ? '?'
                            : volunteer.name.trim()[0].toUpperCase(),
                      ),
                    ),
                    title: Text(
                      volunteer.isActive
                          ? volunteer.name
                          : '${volunteer.name} · inactiva',
                    ),
                    subtitle: Text(
                      '${stats?.total ?? 0} servicios · '
                      'Último: ${last == null ? 'nunca' : DateFormat('dd/MM/yyyy').format(last)}\n'
                      '${_availabilityLabel(volunteer)}',
                    ),
                    isThreeLine: true,
                    onTap: () => _editVolunteer(volunteer),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editVolunteer(volunteer);
                        if (value == 'delete') _deleteVolunteer(volunteer);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _availabilityLabel(Volunteer volunteer) {
    final cultos = <String>[
      if (volunteer.availableAlabanza) 'Alabanza',
      if (volunteer.availableEstudio) 'Estudio',
      if (volunteer.availableEnsenanza) 'Enseñanza',
    ];
    final base = cultos.isEmpty ? 'Sin cultos disponibles' : cultos.join(', ');
    final areas = <String>[
      if (volunteer.canCleanWorshipHall) 'sala',
      if (volunteer.canCleanBathrooms) 'baños',
    ];
    final areaLabel = areas.isEmpty ? 'sin puestos' : areas.join(' y ');
    final absences = volunteer.absences.length;
    return absences == 0
        ? '$base · $areaLabel'
        : '$base · $areaLabel · '
              '$absences ${absences == 1 ? 'ausencia' : 'ausencias'}';
  }
}

class _VolunteerDialog extends StatefulWidget {
  final Volunteer? volunteer;

  const _VolunteerDialog({this.volunteer});

  @override
  State<_VolunteerDialog> createState() => _VolunteerDialogState();
}

class _VolunteerDialogState extends State<_VolunteerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool _isActive;
  late bool _alabanza;
  late bool _estudio;
  late bool _ensenanza;
  late bool _canCleanWorshipHall;
  late bool _canCleanBathrooms;
  late List<AbsencePeriod> _absences;

  @override
  void initState() {
    super.initState();
    final volunteer = widget.volunteer;
    _nameController = TextEditingController(text: volunteer?.name ?? '');
    _isActive = volunteer?.isActive ?? true;
    _alabanza = volunteer?.availableAlabanza ?? true;
    _estudio = volunteer?.availableEstudio ?? true;
    _ensenanza = volunteer?.availableEnsenanza ?? true;
    _canCleanWorshipHall = volunteer?.canCleanWorshipHall ?? true;
    _canCleanBathrooms = volunteer?.canCleanBathrooms ?? true;
    _absences = List.of(volunteer?.absences ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addAbsence() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDateRange: DateTimeRange(start: now, end: now),
      helpText: 'Seleccionar ausencia',
      saveText: 'Guardar',
    );
    if (range == null) return;
    setState(() {
      _absences.add(AbsencePeriod(start: range.start, end: range.end));
      _absences.sort((a, b) => a.start.compareTo(b.start));
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.volunteer;
    final id =
        existing?.id ??
        '${DateTime.now().microsecondsSinceEpoch}-${_nameController.text.hashCode.abs()}';
    Navigator.pop(
      context,
      Volunteer(
        id: id,
        name: _nameController.text.trim(),
        isActive: _isActive,
        availableAlabanza: _alabanza,
        availableEstudio: _estudio,
        availableEnsenanza: _ensenanza,
        canCleanWorshipHall: _canCleanWorshipHall,
        canCleanBathrooms: _canCleanBathrooms,
        absences: _absences,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.volunteer == null ? 'Nueva voluntaria' : 'Editar voluntaria',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe un nombre'
                      : null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Voluntaria activa'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const Divider(),
                Text(
                  'Disponibilidad habitual',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alabanza'),
                  value: _alabanza,
                  onChanged: (value) =>
                      setState(() => _alabanza = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Estudio'),
                  value: _estudio,
                  onChanged: (value) =>
                      setState(() => _estudio = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enseñanza'),
                  value: _ensenanza,
                  onChanged: (value) =>
                      setState(() => _ensenanza = value ?? false),
                ),
                const Divider(),
                Text(
                  'Puestos que puede realizar',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aseo de sala de culto'),
                  value: _canCleanWorshipHall,
                  onChanged: (value) =>
                      setState(() => _canCleanWorshipHall = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aseo de baños'),
                  value: _canCleanBathrooms,
                  onChanged: (value) =>
                      setState(() => _canCleanBathrooms = value ?? false),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ausencias',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addAbsence,
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir'),
                    ),
                  ],
                ),
                if (_absences.isEmpty)
                  const Text('Sin ausencias registradas')
                else
                  ..._absences.asMap().entries.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        '${DateFormat('dd/MM/yyyy').format(entry.value.start)} – '
                        '${DateFormat('dd/MM/yyyy').format(entry.value.end)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Eliminar ausencia',
                        onPressed: () =>
                            setState(() => _absences.removeAt(entry.key)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
