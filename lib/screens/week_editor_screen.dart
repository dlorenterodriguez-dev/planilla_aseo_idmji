import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/conflict_service.dart';
import '../models/assignment.dart';
import '../models/volunteer.dart';
import '../models/event_templates.dart';
import '../services/volunteer_storage_service.dart';
import '../services/assignment_storage_service.dart';

class WeekEditorScreen extends StatefulWidget {
  const WeekEditorScreen({super.key});

  @override
  State<WeekEditorScreen> createState() => _WeekEditorScreenState();
}

class _WeekEditorScreenState extends State<WeekEditorScreen> {
  List<Volunteer> volunteers = [];
  List<Volunteer> availableVolunteersFor(
      Assignment assignment,
      ) {
    return volunteers.where((volunteer) {
      return volunteer.isActive ||
          volunteer.id == assignment.volunteerId;
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

    loadVolunteers().then((_) {
      loadAssignments();
    });
  }
  Future<void> loadVolunteers() async {
    final savedVolunteers =
        await VolunteerStorageService.loadVolunteers();

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
    final volunteerId = assignment.volunteerId;

    if (volunteerId == null) {
      return null;
    }

    final exists = volunteers.any(
      (volunteer) => volunteer.id == volunteerId,
    );

    return exists ? volunteerId : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar semana'),
        actions: [
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
          const Text(
            'Martes - Alabanza',
            style: TextStyle(
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
                value: dropdownValueFor(assignment),
                decoration: InputDecoration(
                  labelText:
                  '${assignment.role} (${assignment.startTime}-${assignment.endTime})',
                  border: const OutlineInputBorder(),
                ),
                  items: availableVolunteersFor(assignment,).map((volunteer)  {
                  return DropdownMenuItem(
                    value: volunteer.id,
                    child: Text(volunteer.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

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

          const Text(
            'Sábado - Estudio',
            style: TextStyle(
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
                value: dropdownValueFor(assignment),
                decoration: InputDecoration(
                  labelText:
                  '${assignment.role} (${assignment.startTime}-${assignment.endTime})',
                  border: const OutlineInputBorder(),
                ),
                items: availableVolunteersFor(
                  assignment,
                ).map((volunteer) {
                  return DropdownMenuItem(
                    value: volunteer.id,
                    child: Text(volunteer.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

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
          const Text(
            'Domingo - Enseñanza',
            style: TextStyle(
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
                value: dropdownValueFor(assignment),
                decoration: InputDecoration(
                  labelText:
                  '${assignment.role} (${assignment.startTime}-${assignment.endTime})',
                  border: const OutlineInputBorder(),
                ),
                items: availableVolunteersFor(
                  assignment,
                ).map((volunteer) {
                  return DropdownMenuItem(
                    value: volunteer.id,
                    child: Text(volunteer.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

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
