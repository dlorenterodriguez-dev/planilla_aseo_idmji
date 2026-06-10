import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/conflict_service.dart';
import '../models/assignment.dart';
import '../models/volunteer.dart';
import '../models/event_templates.dart';
import '../services/volunteer_storage_service.dart';

class WeekEditorScreen extends StatefulWidget {
  const WeekEditorScreen({super.key});

  @override
  State<WeekEditorScreen> createState() => _WeekEditorScreenState();
}

class _WeekEditorScreenState extends State<WeekEditorScreen> {
  List<Volunteer> volunteers = [];

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
  Future<void> saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();

    final alabanzaData =
    alabanza.map((a) => a.volunteer ?? '').toList();
    final estudioData =
    estudio.map((a) => a.volunteer ?? '').toList();
    final ensenanzaData =
    ensenanza.map((a) => a.volunteer ?? '').toList();

    await prefs.setStringList(
      'alabanza_assignments',
      alabanzaData,
    );

    await prefs.setStringList(
      'ensenanza_assignments',
      ensenanzaData,
    );

    await prefs.setStringList(
      'estudio_assignments',
      estudioData,
    );
  }

  Future<void> loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();

    final alabanzaData =
    prefs.getStringList('alabanza_assignments');

    final estudioData =
    prefs.getStringList('estudio_assignments');

    final ensenanzaData =
    prefs.getStringList('ensenanza_assignments');

    if (alabanzaData != null) {
      for (int i = 0;
      i < alabanza.length &&
          i < alabanzaData.length;
      i++) {
        if (alabanzaData[i].isNotEmpty) {
          alabanza[i].volunteer =
          alabanzaData[i];
        }
      }
    }
    if (estudioData != null) {
      for (int i = 0;
      i < estudio.length &&
          i < estudioData.length;
      i++) {
        if (estudioData[i].isNotEmpty) {
          estudio[i].volunteer =
          estudioData[i];
        }
      }
    }
    if (ensenanzaData != null) {
      for (int i = 0;
      i < ensenanza.length &&
          i < ensenanzaData.length;
      i++) {
        if (ensenanzaData[i].isNotEmpty) {
          ensenanza[i].volunteer =
          ensenanzaData[i];
        }
      }
    }

    setState(() {});
  }
  Future<void> clearAssignments() async {
    for (final a in alabanza) {
      a.volunteer = null;
    }

    for (final a in estudio) {
      a.volunteer = null;
    }

    for (final a in ensenanza) {
      a.volunteer = null;
    }

    await saveAssignments();

    setState(() {});
  }

  String? dropdownValueFor(Assignment assignment) {
    final volunteer = assignment.volunteer;

    if (volunteer == null) {
      return null;
    }

    final exists = volunteers.any(
      (currentVolunteer) => currentVolunteer.name == volunteer,
    );

    return exists ? volunteer : null;
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
                items: volunteers.map((volunteer) {
                  return DropdownMenuItem(
                    value: volunteer.name,
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
                    assignment.volunteer = value;
                  });
                  saveAssignments();
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
                items: volunteers.map((volunteer) {
                  return DropdownMenuItem(
                    value: volunteer.name,
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
                    assignment.volunteer = value;
                  });

                  saveAssignments();
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
                items: volunteers.map((volunteer) {
                  return DropdownMenuItem(
                    value: volunteer.name,
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
                    assignment.volunteer = value;
                  });
                  saveAssignments();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
