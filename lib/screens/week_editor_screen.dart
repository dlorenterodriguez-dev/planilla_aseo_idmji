import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/conflict_service.dart';
import '../models/assignment.dart';
import '../models/volunteer.dart';
import '../models/event_templates.dart';
import '../services/volunteer_storage_service.dart';
import '../services/assignment_storage_service.dart';
import '../services/auto_assignment_service.dart';
import '../services/week_service.dart';
import '../models/service_types.dart';

class WeekEditorScreen extends StatefulWidget {

  const WeekEditorScreen({super.key});

  @override
  State<WeekEditorScreen> createState() => _WeekEditorScreenState();
}

class _WeekEditorScreenState extends State<WeekEditorScreen> {

  Future<void> autoAssign() async {
    await AutoAssignmentService.autoAssign(
      assignments: alabanza,
      volunteers: volunteers,
      isAlabanza: true,
    );
    await AutoAssignmentService.autoAssign(
      assignments: estudio,
      volunteers: volunteers,
      isAlabanza: false,
    );
    await AutoAssignmentService.autoAssign(
      assignments: ensenanza,
      volunteers: volunteers,
      isAlabanza: false,
    );

    await AssignmentStorageService.saveAssignments(
      alabanza: alabanza,
      estudio: estudio,
      ensenanza: ensenanza,
    );

    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Autoasignación completada')),
    );
  }

  DateTime? weekStart;
  DateTime get martes => weekStart!.add(const Duration(days: 1));
  DateTime get sabado => weekStart!.add(const Duration(days: 5));
  DateTime get domingo => weekStart!.add(const Duration(days: 6));

  List<Volunteer> volunteers = [];
  List<Volunteer> availableVolunteersFor(
      Assignment assignment,
      ) {
    // Localizar dinámicamente el primer turno de vigilancia del mismo culto.
    final List<Assignment> currentService;
    if (alabanza.contains(assignment)) {
      currentService = alabanza;
    } else if (estudio.contains(assignment)) {
      currentService = estudio;
    } else {
      currentService = ensenanza;
    }

    final serviceType = ServiceTypes.fromRole(assignment.role);
    final vigilanceAssignments = currentService
        .where(
          (currentAssignment) =>
              ServiceTypes.fromRole(currentAssignment.role) ==
              ServiceTypes.vigilance,
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final vigilanceTurnIndex = vigilanceAssignments.indexWhere(
      (currentAssignment) => identical(currentAssignment, assignment),
    );
    final isAlabanza = identical(currentService, alabanza);
    final isLastVigilance =
        vigilanceTurnIndex == vigilanceAssignments.length - 1;

    return volunteers.where((volunteer) {
      // Mantener visible el voluntario ya asignado para no romper
      // la edición manual.
      if (volunteer.id == assignment.volunteerId) {
        return true;
      }

      if (!volunteer.isActive) {
        return false;
      }

      bool allowed = false;

      if (serviceType == ServiceTypes.vigilance) {
        allowed = true;
      } else if (serviceType == ServiceTypes.microphone) {
        allowed = volunteer.canMicrophone;
      } else if (serviceType == ServiceTypes.accommodation) {
        allowed = volunteer.canAccommodation;
      } else if (serviceType == ServiceTypes.cleaning) {
        allowed = volunteer.canCleaning;
      } else if (serviceType == ServiceTypes.bookTable) {
        allowed = volunteer.canBookTable;
      } else if (serviceType == ServiceTypes.audiovisuals) {
        allowed = volunteer.canAudiovisuals;
      }

      if (!allowed) {
        return false;
      }

      if (serviceType != ServiceTypes.vigilance) {
        return true;
      }

      // En Alabanza, los voluntarios de imposición no pueden hacer
      // la última vigilancia.
      if (isAlabanza &&
          isLastVigilance &&
          volunteer.canImposition) {
        return false;
      }

      if (vigilanceTurnIndex == 0) {
        return volunteer.canFirstVigilance;
      }

      if (isLastVigilance) {
        return volunteer.canLastVigilance;
      }

      return volunteer.canMiddleVigilance;
    }).toList();
  }

  final List<Assignment> alabanza =
  EventTemplates.alabanza();

  final List<Assignment> ensenanza =
  EventTemplates.ensenanza();

  final List<Assignment> estudio =
  EventTemplates.estudio();

  @override
  void initState() {
    super.initState();

    loadWeek();

    loadVolunteers().then((_) {
      loadAssignments();
    });
  }

  Future<void> loadWeek() async {
    final date = await WeekService.loadWeekStart();

    setState(() {
      weekStart = date;
    });
  }

  Future<void> loadVolunteers() async {
    final savedVolunteers =
    await VolunteerStorageService.loadVolunteers();

    savedVolunteers.sort(
          (a, b) => a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      ),
    );

    setState(() {
      volunteers = savedVolunteers;
    });
  }

  Future<void> loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();

    final alabanzaData =
    prefs.getStringList('alabanza_assignments_v2');

    final estudioData =
    prefs.getStringList('estudio_assignments_v2');

    final ensenanzaData =
    prefs.getStringList('ensenanza_assignments_v2');

    debugPrint(
      'loadAssignments alabanza_assignments_v2 exists: ${alabanzaData != null}, count: ${alabanzaData?.length ?? 0}',
    );
    debugPrint(
      'loadAssignments estudio_assignments_v2 exists: ${estudioData != null}, count: ${estudioData?.length ?? 0}',
    );
    debugPrint(
      'loadAssignments ensenanza_assignments_v2 exists: ${ensenanzaData != null}, count: ${ensenanzaData?.length ?? 0}',
    );

    var migratedLegacyAssignments = false;

    if (alabanzaData != null) {
      loadAssignmentIds(alabanza, alabanzaData);
    } else {
      debugPrint(
        'loadAssignments migrating alabanza from legacy key',
      );
      loadLegacyAssignmentNames(
        alabanza,
        prefs.getStringList('alabanza_assignments'),
      );
      migratedLegacyAssignments = true;
    }

    if (estudioData != null) {
      loadAssignmentIds(estudio, estudioData);
    } else {
      debugPrint(
        'loadAssignments migrating estudio from legacy key',
      );
      loadLegacyAssignmentNames(
        estudio,
        prefs.getStringList('estudio_assignments'),
      );
      migratedLegacyAssignments = true;
    }

    if (ensenanzaData != null) {
      loadAssignmentIds(ensenanza, ensenanzaData);
    } else {
      debugPrint(
        'loadAssignments migrating ensenanza from legacy key',
      );
      loadLegacyAssignmentNames(
        ensenanza,
        prefs.getStringList('ensenanza_assignments'),
      );
      migratedLegacyAssignments = true;
    }

    if (migratedLegacyAssignments) {
      debugPrint(
        'loadAssignments saving migrated legacy assignments',
      );
      await AssignmentStorageService.saveAssignments(
        alabanza: alabanza,
        estudio: estudio,
        ensenanza: ensenanza,
      );
    }

    setState(() {});
  }

  void loadAssignmentIds(
    List<Assignment> assignments,
    List<String>? assignmentData,
  ) {
    if (assignmentData == null) {
      return;
    }

    for (int i = 0;
        i < assignments.length &&
            i < assignmentData.length;
        i++) {
      if (assignmentData[i].isNotEmpty) {
        assignments[i].volunteerId =
            resolveVolunteerId(assignmentData[i]);
      }
    }
  }

  void loadLegacyAssignmentNames(
    List<Assignment> assignments,
    List<String>? assignmentData,
  ) {
    if (assignmentData == null) {
      return;
    }

    for (int i = 0;
        i < assignments.length &&
            i < assignmentData.length;
        i++) {
      if (assignmentData[i].isNotEmpty) {
        assignments[i].volunteerId =
            resolveVolunteerIdByName(assignmentData[i]);
      }
    }
  }

  String? resolveVolunteerId(String volunteerId) {
    final exists = volunteers.any(
      (volunteer) => volunteer.id == volunteerId,
    );

    return exists ? volunteerId : null;
  }

  String? resolveVolunteerIdByName(String volunteerName) {
    for (final volunteer in volunteers) {
      if (volunteer.name == volunteerName) {
        return volunteer.id;
      }
    }

    return null;
  }

  Future<void> clearAssignments() async {
    setState(() {
      for (final a in alabanza) {
        a.volunteerId = null;
      }

      for (final a in estudio) {
        a.volunteerId = null;
      }

      for (final a in ensenanza) {
        a.volunteerId = null;
      }
    });

    await AssignmentStorageService.saveAssignments(
      alabanza: alabanza,
      estudio: estudio,
      ensenanza: ensenanza,
    );
  }

  String? dropdownValueFor(Assignment assignment) {
    return assignment.volunteerId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar semana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Autoasignar',
            onPressed: autoAssign,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm =
              await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'Limpiar semana',
                  ),
                  content: const Text(
                    '¿Borrar todas las asignaciones?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                            context,
                            false,
                          ),
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(
                            context,
                            true,
                          ),
                      child: const Text(
                        'Borrar',
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await clearAssignments();
              }
            },
          ),
        ],
      ),
      body: ListView(

        padding: const EdgeInsets.all(16),
        children: [

          if (weekStart != null) ...[
            Text(
              'Semana: '
                  '${weekStart!.day.toString().padLeft(2, '0')}/'
                  '${weekStart!.month.toString().padLeft(2, '0')}/'
                  '${weekStart!.year}'
                  ' - '
                  '${weekStart!.add(const Duration(days: 6)).day.toString().padLeft(2, '0')}/'
                  '${weekStart!.add(const Duration(days: 6)).month.toString().padLeft(2, '0')}/'
                  '${weekStart!.add(const Duration(days: 6)).year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: weekStart ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (selected != null) {
                  final monday = selected.subtract(
                    Duration(days: selected.weekday - 1),
                  );

                  await WeekService.saveWeekStart(monday);

                  setState(() {
                    weekStart = monday;
                  });
                }
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Cambiar semana'),
            ),

          ],

          Text(
            'Martes ${martes.day} - Alabanza',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...alabanza.map(
                (assignment) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: DropdownButtonFormField<String>(
                initialValue: dropdownValueFor(assignment),
                decoration: InputDecoration(
                  labelText:
                  '${assignment.role} (${assignment.startTime}-${assignment.endTime})',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('— Sin asignar —'),
                  ),
                  ...availableVolunteersFor(assignment).map((volunteer) {
                    return DropdownMenuItem<String>(
                      value: volunteer.id,
                      child: Text(volunteer.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  if (value.isEmpty) {
                    setState(() {
                      assignment.volunteerId = null;
                    });

                    AssignmentStorageService.saveAssignments(
                      alabanza: alabanza,
                      estudio: estudio,
                      ensenanza: ensenanza,
                    );

                    return;
                  }

                  final hasConflict =
                  ConflictService.hasConflict(
                    alabanza,
                    assignment,
                    value,
                  );

                  if (hasConflict) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Conflicto horario detectado',
                        ),
                      ),
                    );

                    return;
                  }

                  setState(() {
                    assignment.volunteerId = value;
                  });
                  AssignmentStorageService.saveAssignments(
                    alabanza: alabanza,
                    estudio: estudio,
                    ensenanza: ensenanza,
                  );
                },
              ),
            ),
          ),


          const SizedBox(height: 32),
          const SizedBox(height: 32),
          Text(
            'Sábado ${sabado.day} - Estudio',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...estudio.map(
                (assignment) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: DropdownButtonFormField<String>(
                initialValue: dropdownValueFor(assignment),
                decoration: InputDecoration(
                  labelText:
                  '${assignment.role} (${assignment.startTime}-${assignment.endTime})',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('— Sin asignar —'),
                  ),
                  ...availableVolunteersFor(assignment).map((volunteer) {
                    return DropdownMenuItem<String>(
                      value: volunteer.id,
                      child: Text(volunteer.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  if (value.isEmpty) {
                    setState(() {
                      assignment.volunteerId = null;
                    });

                    AssignmentStorageService.saveAssignments(
                      alabanza: alabanza,
                      estudio: estudio,
                      ensenanza: ensenanza,
                    );

                    return;
                  }

                  final hasConflict =
                  ConflictService.hasConflict(
                    estudio,
                    assignment,
                    value,
                  );

                  if (hasConflict) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Conflicto horario detectado',
                        ),
                      ),
                    );

                    return;
                  }

                  setState(() {
                    assignment.volunteerId = value;
                  });

                  AssignmentStorageService.saveAssignments(
                    alabanza: alabanza,
                    estudio: estudio,
                    ensenanza: ensenanza,
                  );
                },
              ),
            ),
          ),
          Text(
            'Domingo ${domingo.day} - Enseñanza',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...ensenanza.map(
                (assignment) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: DropdownButtonFormField<String>(
                initialValue: dropdownValueFor(assignment),
                decoration: InputDecoration(
                  labelText:
                  '${assignment.role} (${assignment.startTime}-${assignment.endTime})',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('— Sin asignar —'),
                  ),
                  ...availableVolunteersFor(assignment).map((volunteer) {
                    return DropdownMenuItem<String>(
                      value: volunteer.id,
                      child: Text(volunteer.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  if (value.isEmpty) {
                    setState(() {
                      assignment.volunteerId = null;
                    });

                    AssignmentStorageService.saveAssignments(
                      alabanza: alabanza,
                      estudio: estudio,
                      ensenanza: ensenanza,
                    );

                    return;
                  }

                  final hasConflict =
                  ConflictService.hasConflict(
                    ensenanza,
                    assignment,
                    value,
                  );

                  if (hasConflict) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Conflicto horario detectado',
                        ),
                      ),
                    );

                    return;
                  }

                  setState(() {
                    assignment.volunteerId = value;
                  });
                  AssignmentStorageService.saveAssignments(
                    alabanza: alabanza,
                    estudio: estudio,
                    ensenanza: ensenanza,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
