import 'package:flutter/material.dart';

import '../models/volunteer.dart';
import '../services/assignment_storage_service.dart';
import '../services/volunteer_storage_service.dart';

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
      final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return ascendingOrder ? comparison : -comparison;
    });
  }

  Future<void> loadVolunteers() async {
    final savedVolunteers = await VolunteerStorageService.loadVolunteers();

    if (!mounted) return;
    setState(() {
      volunteers = savedVolunteers;
      sortVolunteers();
    });
  }

  Future<void> saveVolunteers() async {
    await VolunteerStorageService.saveVolunteers(volunteers);
  }

  Future<void> confirmDeleteVolunteer(int index) async {
    final volunteer = volunteers[index];
    final assignmentCount = await AssignmentStorageService.countVolunteerAssignments(
      volunteer.id,
    );
    if (!mounted) return;

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

    if (confirmed != true) return;

    await AssignmentStorageService.removeVolunteerFromAssignments(volunteer.id);
    if (!mounted) return;

    setState(() {
      volunteers.removeAt(index);
    });
    await saveVolunteers();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${volunteer.name} - Persona eliminada')),
    );
  }

  void addVolunteer() {
    final controller = TextEditingController();
    var canMicrophone = false;
    var canAccommodation = false;
    var canFirstVigilance = true;
    var canMiddleVigilance = true;
    var canLastVigilance = true;
    var canCleaning = false;
    var canBookTable = false;
    var canAudiovisuals = false;
    var canImposition = false;

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
                  decoration: const InputDecoration(hintText: 'Nombre'),
                ),
                _permissionCheckbox(
                  title: 'Micrófono',
                  icon: Icons.mic,
                  value: canMicrophone,
                  onChanged: (value) => setDialogState(() => canMicrophone = value),
                ),
                _permissionCheckbox(
                  title: 'Acomodación',
                  icon: Icons.chair_alt,
                  value: canAccommodation,
                  onChanged: (value) =>
                      setDialogState(() => canAccommodation = value),
                ),
                _permissionCheckbox(
                  title: 'Aseo',
                  icon: Icons.cleaning_services,
                  value: canCleaning,
                  onChanged: (value) => setDialogState(() => canCleaning = value),
                ),
                _permissionCheckbox(
                  title: 'Biblias',
                  icon: Icons.menu_book,
                  value: canBookTable,
                  onChanged: (value) => setDialogState(() => canBookTable = value),
                ),
                _permissionCheckbox(
                  title: 'Audiovisuales',
                  icon: Icons.cast_connected,
                  value: canAudiovisuals,
                  onChanged: (value) =>
                      setDialogState(() => canAudiovisuals = value),
                ),
                _permissionCheckbox(
                  title: 'Imposición',
                  icon: Icons.pan_tool,
                  value: canImposition,
                  onChanged: (value) =>
                      setDialogState(() => canImposition = value),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('1ª vigilancia'),
                    ],
                  ),
                  value: canFirstVigilance,
                  onChanged: (value) =>
                      setDialogState(() => canFirstVigilance = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('2ª vigilancia'),
                    ],
                  ),
                  value: canMiddleVigilance,
                  onChanged: (value) =>
                      setDialogState(() => canMiddleVigilance = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('3ª vigilancia'),
                    ],
                  ),
                  value: canLastVigilance,
                  onChanged: (value) =>
                      setDialogState(() => canLastVigilance = value ?? false),
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
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    volunteers.add(
                        Volunteer(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          isActive: true,
                          canMicrophone: canMicrophone,
                          canAccommodation: canAccommodation,
                          canFirstVigilance: canFirstVigilance,
                          canMiddleVigilance: canMiddleVigilance,
                          canLastVigilance: canLastVigilance,
                          canCleaning: canCleaning,
                          canBookTable: canBookTable,
                          canAudiovisuals: canAudiovisuals,
                          canImposition: canImposition,
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
    final volunteer = volunteers[index];
    final controller = TextEditingController(text: volunteer.name);
    var canMicrophone = volunteer.canMicrophone;
    var canAccommodation = volunteer.canAccommodation;
    var canFirstVigilance = volunteer.canFirstVigilance;
    var canMiddleVigilance = volunteer.canMiddleVigilance;
    var canLastVigilance = volunteer.canLastVigilance;
    var canCleaning = volunteer.canCleaning;
    var canBookTable = volunteer.canBookTable;
    var canAudiovisuals = volunteer.canAudiovisuals;
    var canImposition = volunteer.canImposition;

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
                  decoration: const InputDecoration(hintText: 'Nombre'),
                ),
                _permissionCheckbox(
                  title: 'Micrófono',
                  icon: Icons.mic,
                  value: canMicrophone,
                  onChanged: (value) => setDialogState(() => canMicrophone = value),
                ),
                _permissionCheckbox(
                  title: 'Acomodación',
                  icon: Icons.chair_alt,
                  value: canAccommodation,
                  onChanged: (value) =>
                      setDialogState(() => canAccommodation = value),
                ),
                _permissionCheckbox(
                  title: 'Aseo',
                  icon: Icons.cleaning_services,
                  value: canCleaning,
                  onChanged: (value) => setDialogState(() => canCleaning = value),
                ),
                _permissionCheckbox(
                  title: 'Biblias',
                  icon: Icons.menu_book,
                  value: canBookTable,
                  onChanged: (value) => setDialogState(() => canBookTable = value),
                ),
                _permissionCheckbox(
                  title: 'Sonido',
                  icon: Icons.cast_connected,
                  value: canAudiovisuals,
                  onChanged: (value) =>
                      setDialogState(() => canAudiovisuals = value),
                ),
                _permissionCheckbox(
                  title: 'Imposición',
                  icon: Icons.pan_tool,
                  value: canImposition,
                  onChanged: (value) =>
                      setDialogState(() => canImposition = value),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('1ª vigilancia'),
                    ],
                  ),
                  value: canFirstVigilance,
                  onChanged: (value) =>
                      setDialogState(() => canFirstVigilance = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('2ª vigilancia'),
                    ],
                  ),
                  value: canMiddleVigilance,
                  onChanged: (value) =>
                      setDialogState(() => canMiddleVigilance = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 8),
                      Text('3ª vigilancia'),
                    ],
                  ),
                  value: canLastVigilance,
                  onChanged: (value) =>
                      setDialogState(() => canLastVigilance = value ?? false),
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
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    volunteers[index] = Volunteer(
                      id: volunteer.id,
                      name: name,
                      isActive: volunteer.isActive,
                      canMicrophone: canMicrophone,
                      canAccommodation: canAccommodation,
                      canFirstVigilance: canFirstVigilance,
                      canMiddleVigilance: canMiddleVigilance,
                      canLastVigilance: canLastVigilance,
                      canCleaning: canCleaning,
                      canBookTable: canBookTable,
                      canAudiovisuals: canAudiovisuals,
                      canImposition: canImposition,
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

  Future<void> toggleVolunteerStatus(int index) async {
    final volunteer = volunteers[index];

    if (volunteer.isActive) {
      final assignmentCount = await AssignmentStorageService.countVolunteerAssignments(
        volunteer.id,
      );
      if (!mounted) return;

      if (assignmentCount > 0) {
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(volunteer.name),
            content: Text(
              'Tiene $assignmentCount asignaciones.\n\n¿Qué deseas hacer?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'keep'),
                child: const Text('Conservar asignaciones'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'remove'),
                child: const Text('Eliminar asignaciones'),
              ),
            ],
          ),
        );

        if (action == null || action == 'cancel') return;

        if (action == 'remove') {
          await AssignmentStorageService.removeVolunteerFromAssignments(
            volunteer.id,
          );
          if (!mounted) return;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      volunteers[index] = Volunteer(
        id: volunteer.id,
        name: volunteer.name,
        isActive: !volunteer.isActive,
        canMicrophone: volunteer.canMicrophone,
        canAccommodation: volunteer.canAccommodation,
        canFirstVigilance: volunteer.canFirstVigilance,
        canMiddleVigilance: volunteer.canMiddleVigilance,
        canLastVigilance: volunteer.canLastVigilance,
        canCleaning: volunteer.canCleaning,
        canBookTable: volunteer.canBookTable,
        canAudiovisuals: volunteer.canAudiovisuals,
        canImposition: volunteer.canImposition,
      );
      sortVolunteers();
    });
    await saveVolunteers();
  }

  Widget _permissionCheckbox({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      value: value,
      onChanged: (value) => onChanged(value ?? false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voluntarios'),
        actions: [
          IconButton(
            icon: Icon(ascendingOrder ? Icons.sort_by_alpha : Icons.sort),
            tooltip: ascendingOrder ? 'Orden A → Z' : 'Orden Z → A',
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
              volunteer.isActive ? Icons.person : Icons.person_off,
            ),
            title: Text(
              volunteer.name,
              style: TextStyle(
                color: volunteer.isActive ? null : Colors.grey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!volunteer.isActive)
                  const Text('Inactivo', style: TextStyle(color: Colors.grey)),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (volunteer.canFirstVigilance ||
                        volunteer.canMiddleVigilance ||
                        volunteer.canLastVigilance)
                      const Tooltip(
                        message: 'Puede hacer vigilancia',
                        child: Icon(Icons.visibility, size: 18),
                      ),
                    if (volunteer.canMicrophone)
                      const Tooltip(
                        message: 'Puede hacer micrófono',
                        child: Icon(Icons.mic, size: 18),
                      ),
                    if (volunteer.canAccommodation)
                      const Tooltip(
                        message: 'Puede hacer acomodación',
                        child: Icon(Icons.chair_alt, size: 18),
                      ),
                    if (volunteer.canCleaning)
                      const Tooltip(
                        message: 'Puede hacer aseo',
                        child: Icon(Icons.cleaning_services, size: 18),
                      ),
                    if (volunteer.canBookTable)
                      const Tooltip(
                        message: 'Puede atender la mesa de Biblias',
                        child: Icon(Icons.menu_book, size: 18),
                      ),
                    if (volunteer.canAudiovisuals)
                      const Tooltip(
                        message: 'Puede hacer audiovisuales',
                        child: Icon(Icons.cast_connected, size: 18),
                      ),
                    if (volunteer.canImposition)
                      const Tooltip(
                        message: 'Puede hacer imposición',
                        child: Icon(Icons.pan_tool, size: 18),
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
                  tooltip: volunteer.isActive ? 'Desactivar' : 'Activar',
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
