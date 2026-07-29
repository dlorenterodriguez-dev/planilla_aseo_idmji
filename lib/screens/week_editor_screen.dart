import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/assignment.dart';
import '../models/event_templates.dart';
import '../models/service_occurrence.dart';
import '../models/volunteer.dart';
import '../services/assignment_storage_service.dart';
import '../services/auto_assignment_service.dart';
import '../services/volunteer_storage_service.dart';
import '../services/week_service.dart';

enum ScheduleMode { week, month }

class WeekEditorScreen extends StatefulWidget {
  final ScheduleMode mode;

  const WeekEditorScreen({super.key, this.mode = ScheduleMode.week});

  @override
  State<WeekEditorScreen> createState() => _WeekEditorScreenState();
}

class _WeekEditorScreenState extends State<WeekEditorScreen> {
  final _previewKey = GlobalKey();
  List<Volunteer> _volunteers = [];
  List<Assignment> _allAssignments = [];
  late DateTime _period;
  var _loading = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = widget.mode == ScheduleMode.week
        ? DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - 1))
        : DateTime(now.year, now.month);
    _load();
  }

  List<ServiceOccurrence> get _occurrences => widget.mode == ScheduleMode.week
      ? EventTemplates.forWeek(_period)
      : EventTemplates.forMonth(_period);

  Map<String, Assignment> get _assignmentsById => {
    for (final assignment in _allAssignments) assignment.eventId: assignment,
  };

  Future<void> _load() async {
    final volunteers = await VolunteerStorageService.loadVolunteers();
    final assignments = await AssignmentStorageService.loadAssignments();
    if (!mounted) return;
    setState(() {
      _volunteers = volunteers;
      _allAssignments = assignments;
      _loading = false;
    });
  }

  Future<void> _changePeriod(int direction) async {
    setState(() {
      _period = widget.mode == ScheduleMode.week
          ? _period.add(Duration(days: 7 * direction))
          : DateTime(_period.year, _period.month + direction);
    });
    if (widget.mode == ScheduleMode.week) {
      await WeekService.saveWeekStart(_period);
    }
  }

  Assignment _assignmentFor(ServiceOccurrence occurrence) {
    return _assignmentsById[occurrence.eventId] ??
        Assignment(
          eventId: occurrence.eventId,
          eventType: occurrence.eventType,
          date: occurrence.date,
        );
  }

  Future<void> _setVolunteer(
    ServiceOccurrence occurrence,
    String? volunteerId,
  ) async {
    final assignment = _assignmentFor(occurrence);
    final existingIndex = _allAssignments.indexWhere(
      (current) => current.eventId == occurrence.eventId,
    );
    if (volunteerId != null && volunteerId.isNotEmpty) {
      final alreadyAssigned = _allAssignments.any(
        (current) =>
            current.eventId != occurrence.eventId &&
            current.eventType == occurrence.eventType &&
            DateUtils.isSameDay(current.date, occurrence.date) &&
            current.volunteerId == volunteerId,
      );
      if (alreadyAssigned) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cada puesto del culto debe tener una voluntaria diferente',
            ),
          ),
        );
        return;
      }
      final volunteer = _volunteers
          .where((candidate) => candidate.id == volunteerId)
          .firstOrNull;
      if (volunteer != null &&
          !volunteer.isAvailableFor(
            occurrence.eventType,
            occurrence.date,
            cleaningArea: occurrence.cleaningArea,
          )) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Voluntaria no disponible'),
            content: Text(
              '${volunteer.name} figura como no disponible para este culto. '
              '¿Quieres asignarla de todas formas?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Asignar'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    assignment.volunteerId = volunteerId == null || volunteerId.isEmpty
        ? null
        : volunteerId;
    if (existingIndex < 0) {
      _allAssignments.add(assignment);
    }
    await AssignmentStorageService.saveAssignments(_allAssignments);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _autoAssign() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AutoAssignmentService.autoAssign(
        occurrences: _occurrences,
        assignments: _allAssignments,
        volunteers: _volunteers,
      );
      await AssignmentStorageService.saveAssignments(_allAssignments);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Autoasignación terminada')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePlan() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _previewKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('No se pudo preparar la planilla');
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('No se pudo generar la imagen');
      final bytes = data.buffer.asUint8List();
      final suffix = widget.mode == ScheduleMode.week
          ? DateFormat('yyyy-MM-dd').format(_period)
          : DateFormat('yyyy-MM').format(_period);
      final name = 'planilla_aseo_$suffix.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              mimeType: 'image/png',
              name: name,
            ),
          ],
          fileNameOverrides: [name],
          subject: 'Planilla de Aseo',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo compartir la planilla')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _periodLabel {
    if (widget.mode == ScheduleMode.month) {
      return DateFormat('MMMM yyyy', 'es_ES').format(_period);
    }
    final end = _period.add(const Duration(days: 6));
    return '${DateFormat('d MMM', 'es_ES').format(_period)} – '
        '${DateFormat('d MMM yyyy', 'es_ES').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == ScheduleMode.week
              ? 'Planilla semanal'
              : 'Planilla mensual',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changePeriod(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        _periodLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changePeriod(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy || _volunteers.isEmpty ? null : _autoAssign,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Autoasignar'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _sharePlan,
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir como imagen'),
                ),
                if (_volunteers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Añade voluntarias antes de realizar asignaciones.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _previewKey,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'IDMJI · Voluntariado Aseo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF0E2A8B),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _periodLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          ..._occurrences.map(_buildOccurrence),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOccurrence(ServiceOccurrence occurrence) {
    final assignment = _assignmentFor(occurrence);
    final knownVolunteer = _volunteers.any(
      (volunteer) => volunteer.id == assignment.volunteerId,
    );
    final value = knownVolunteer ? assignment.volunteerId : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey('${occurrence.eventId}-${assignment.volunteerId}'),
        initialValue: value,
        decoration: InputDecoration(
          labelText:
              '${DateFormat('EEEE d', 'es_ES').format(occurrence.date)} · '
              '${occurrence.label} · ${occurrence.positionLabel}',
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('— Sin asignar —')),
          ..._volunteers.map(
            (volunteer) => DropdownMenuItem(
              value: volunteer.id,
              child: Text(
                volunteer.isAvailableFor(
                      occurrence.eventType,
                      occurrence.date,
                      cleaningArea: occurrence.cleaningArea,
                    )
                    ? volunteer.name
                    : '${volunteer.name} · no disponible',
              ),
            ),
          ),
        ],
        onChanged: (value) => _setVolunteer(occurrence, value),
      ),
    );
  }
}
