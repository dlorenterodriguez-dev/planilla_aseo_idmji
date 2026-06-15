import 'package:flutter/material.dart';
import '../models/volunteer.dart';
import '../services/volunteer_storage_service.dart';
import '../services/assignment_storage_service.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  bool ascendingOrder = true;
  List<Volunteer> volunteers = [];

  @override
  void initState() {
    super.initState();
    loadVolunteers();
  }

  void sortVolunteers() {
    volunteers.sort((a, b) {
      final comparison =
      a.name.toLowerCase().compareTo(
        b.name.toLowerCase(),
      );

      return ascendingOrder
          ? comparison
          : -comparison;
    });
  }


  Future<void> loadVolunteers() async {
    final savedVolunteers =
        await VolunteerStorageService.loadVolunteers();

    setState(() {
      volunteers = savedVolunteers;
      sortVolunteers();
    });
  }
  Future<void> confirmDeleteVolunteer(int index) async {
    final volunteer = volunteers[index];
    final assignmentCount =
    await AssignmentStorageService.countVolunteerAssignments(
      volunteer.id,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar voluntario'),
        content: Text(
          '¿Seguro que deseas eliminar a ${volunteer.name}?\n\n'
              'Tiene $assignmentCount asignaciones.\n'
              'Las asignaciones quedarán vacías.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AssignmentStorageService
          .removeVolunteerFromAssignments(
        volunteer.id,
      );
      setState(() {
        volunteers.removeAt(index);
      });

      await saveVolunteers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${volunteer.name} - Persona eliminada',
          ),
        ),
      );
    }
  }
  Future<void> saveVolunteers() async {
    await VolunteerStorageService.saveVolunteers(volunteers);
  }
  void addVolunteer() {
    final controller = TextEditingController();
    bool canVigilance = false;
    bool canMicrophone = false;
    bool canAccommodation = false;
    bool firstVigilanceOnly = false;
    bool canCleaning = false;
    bool canBookTable = false;
    bool canAudiovisuals = false;

    showDialog(
      context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
        title: const Text('Añadir voluntario'),
            content: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Nombre',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('Vigilancia'),
                    ],
                  ),
                  value: canVigilance,
                  onChanged: (value) {
                    setDialogState(() {
                      canVigilance = value!;
                    });
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.mic, size: 20),
                      SizedBox(width: 8),
                      Text('Micrófono'),
                    ],
                  ),
                  value: canMicrophone,
                  onChanged: (value) {
                    setDialogState(() {
                      canMicrophone = value!;
                    });
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.chair_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Acomodación'),
                    ],
                  ),
                  value: canAccommodation,
                  onChanged: (value) {
                    setDialogState(() {
                      canAccommodation = value!;
                    });
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.cleaning_services, size: 20),
                      SizedBox(width: 8),
                      Text('Aseo'),
                    ],
                  ),
                  value: canCleaning,
                  onChanged: (value) {
                    setDialogState(() {
                      canCleaning = value!;
                    });
                  },
                ),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.menu_book, size: 20),
                      SizedBox(width: 8),
                      Text('Biblias'),
                    ],
                  ),
                  value: canBookTable,
                  onChanged: (value) {
                    setDialogState(() {
                      canBookTable = value!;
                    });
                  },
                ),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.cast_connected, size: 20),
                      SizedBox(width: 8),
                      Text('Audiovisuales'),
                    ],
                  ),
                  value: canAudiovisuals,
                  onChanged: (value) {
                    setDialogState(() {
                      canAudiovisuals = value!;
                    });
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.workspace_premium, size: 20),
                      SizedBox(width: 8),
                      Text('Pastor'),
                    ],
                  ),                  value: firstVigilanceOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      firstVigilanceOnly = value!;
                    });
                  },
                ),
              ],
              ),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  volunteers.add(
                      Volunteer(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        name: controller.text.trim(),
                        isActive: true,
                        canVigilance: canVigilance,
                        canMicrophone: canMicrophone,
                        canAccommodation: canAccommodation,
                        firstVigilanceOnly: firstVigilanceOnly,
                        canCleaning: canCleaning,
                        canBookTable: canBookTable,
                        canAudiovisuals: canAudiovisuals,
                      )
                  );
                  sortVolunteers();
                });

                saveVolunteers();
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
      ),
    );
  }

  void editVolunteer(int index) {
    final controller = TextEditingController(
      text: volunteers[index].name,
    );
    bool canVigilance = volunteers[index].canVigilance;
    bool canMicrophone = volunteers[index].canMicrophone;
    bool canAccommodation = volunteers[index].canAccommodation;
    bool firstVigilanceOnly = volunteers[index].firstVigilanceOnly;
    bool canCleaning = volunteers[index].canCleaning;
    bool canBookTable = volunteers[index].canBookTable;
    bool canAudiovisuals = volunteers[index].canAudiovisuals;

    showDialog(
      context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
        title: const Text('Editar voluntario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Nombre',
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text('Vigilancia'),
                      ],
                    ),
                    value: canVigilance,
                    onChanged: (value) {
                      setDialogState(() {
                        canVigilance = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Row(
                      children: [
                        Icon(Icons.mic, size: 20),
                        SizedBox(width: 8),
                        Text('Micrófono'),
                      ],
                    ),
                    value: canMicrophone,
                    onChanged: (value) {
                      setDialogState(() {
                        canMicrophone = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Row(
                      children: [
                        Icon(Icons.chair_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Acomodación'),
                      ],
                    ),
                    value: canAccommodation,
                    onChanged: (value) {
                      setDialogState(() {
                        canAccommodation = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Row(
                      children: [
                        Icon(Icons.cleaning_services, size: 20),
                        SizedBox(width: 8),
                        Text('Aseo'),
                      ],
                    ),
                    value: canCleaning,
                    onChanged: (value) {
                      setDialogState(() {
                        canCleaning = value!;
                      });
                    },
                  ),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Row(
                      children: [
                        Icon(Icons.menu_book, size: 20),
                        SizedBox(width: 8),
                        Text('Biblias'),
                      ],
                    ),
                    value: canBookTable,
                    onChanged: (value) {
                      setDialogState(() {
                        canBookTable = value!;
                      });
                    },
                  ),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Row(
                      children: [
                        Icon(Icons.cast_connected, size: 20),
                        SizedBox(width: 8),
                        Text('Audiovisuales'),
                      ],
                    ),
                    value: canAudiovisuals,
                    onChanged: (value) {
                      setDialogState(() {
                        canAudiovisuals = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Row(
                      children: [
                        Icon(Icons.workspace_premium, size: 20),
                        SizedBox(width: 8),
                        Text('Pastor'),
                      ],
                    ),
                    value: firstVigilanceOnly,
                    onChanged: (value) {
                      setDialogState(() {
                        firstVigilanceOnly = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final volunteer = volunteers[index];

                  volunteers[index] = Volunteer(
                    id: volunteer.id,
                    name: controller.text.trim(),
                    isActive: volunteer.isActive,
                    canVigilance: canVigilance,
                    canMicrophone: canMicrophone,
                    canAccommodation: canAccommodation,
                    firstVigilanceOnly: firstVigilanceOnly,
                    canCleaning: canCleaning,
                    canBookTable: canBookTable,
                    canAudiovisuals: canAudiovisuals,
                  );
                  sortVolunteers();
                });

                saveVolunteers();
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
        ),
    );
    sortVolunteers();
  }
  Future<void> toggleVolunteerStatus(int index) async {
    final volunteer = volunteers[index];

    if (volunteer.isActive) {
      final assignmentCount =
      await AssignmentStorageService.countVolunteerAssignments(
        volunteer.id,
      );

      if (assignmentCount > 0) {
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(volunteer.name),
            content: Text(
              'Tiene $assignmentCount asignaciones.\n\n'
                  '¿Qué deseas hacer?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, 'cancel'),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, 'keep'),
                child: const Text('Conservar asignaciones'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, 'remove'),
                child: const Text('Eliminar asignaciones'),
              ),
            ],
          ),
        );

        if (action == 'cancel' || action == null) {
          return;
        }

        if (action == 'remove') {
          await AssignmentStorageService
              .removeVolunteerFromAssignments(
            volunteer.id,
          );
        }
      }
    }

    setState(() {
      volunteers[index] = Volunteer(
        id: volunteer.id,
        name: volunteer.name,
        isActive: !volunteer.isActive,
      );
    });
    sortVolunteers();
    saveVolunteers();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voluntarios'),
        actions: [
          IconButton(
            icon: Icon(
              ascendingOrder
                  ? Icons.sort_by_alpha
                  : Icons.sort,
            ),
            tooltip: ascendingOrder
                ? 'Orden A → Z'
                : 'Orden Z → A',
            onPressed: () {
              setState(() {
                ascendingOrder = !ascendingOrder;

                sortVolunteers();
                });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: volunteers.length,
        itemBuilder: (context, index) {
          final volunteer = volunteers[index];

          return ListTile(
            leading: Icon(
              volunteer.isActive
                  ? Icons.person
                  : Icons.person_off,
            ),
            title: Text(
              volunteer.name,
              style: TextStyle(
                color: volunteer.isActive
                    ? null
                    : Colors.grey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!volunteer.isActive)
                  const Text(
                    'Inactivo',
                    style: TextStyle(color: Colors.grey),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (volunteer.canVigilance ||
                        volunteer.firstVigilanceOnly)
                      const Tooltip(
                        message: 'Puede hacer vigilancia',
                        child: Icon(
                          Icons.visibility,
                          size: 18,
                        ),
                      ),
                    if (volunteer.canMicrophone)
                      const Tooltip(
                        message: 'Puede hacer micrófono',
                        child: Icon(
                          Icons.mic,
                          size: 18,
                        ),
                      ),
                    if (volunteer.canAccommodation)
                      const Tooltip(
                        message: 'Puede hacer acomodación',
                        child: Icon(
                          Icons.event_seat,
                          size: 18,
                        ),
                      ),
                    if (volunteer.firstVigilanceOnly)
                      const Tooltip(
                        message: 'Solo primer turno de vigilancia',
                        child: Icon(
                          Icons.filter_1,
                          size: 18,
                        ),
                      ),
                    if (volunteer.canCleaning)
                      const Tooltip(
                        message: 'Puede hacer aseo',
                        child: Icon(
                          Icons.cleaning_services,
                          size: 18,
                        ),
                      ),
                    if (volunteer.canBookTable)
                      const Tooltip(
                        message: 'Puede atender la mesa de Biblias',
                        child: Icon(
                          Icons.menu_book,
                          size: 18,
                        ),
                      ),
                    if (volunteer.canAudiovisuals)
                      const Tooltip(
                        message: 'Puede hacer audiovisuales',
                        child: Icon(
                          Icons.cast_connected,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            onTap: () => editVolunteer(index),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    volunteer.isActive
                        ? Icons.pause_circle
                        : Icons.play_circle,
                  ),
                  tooltip: volunteer.isActive
                      ? 'Desactivar'
                      : 'Activar',
                  onPressed: () => toggleVolunteerStatus(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Eliminar',
                  onPressed: () => confirmDeleteVolunteer(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addVolunteer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
