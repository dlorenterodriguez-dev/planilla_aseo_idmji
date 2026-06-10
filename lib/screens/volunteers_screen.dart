import 'package:flutter/material.dart';
import '../models/volunteer.dart';
import '../services/volunteer_storage_service.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  List<Volunteer> volunteers = [];
  @override
  void initState() {
    super.initState();
    loadVolunteers();
  }

  Future<void> loadVolunteers() async {
    final savedVolunteers =
        await VolunteerStorageService.loadVolunteers();

    setState(() {
      volunteers = savedVolunteers;
    });
  }
  Future<void> confirmDeleteVolunteer(int index) async {
    final volunteer = volunteers[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar voluntario'),
        content: Text(
          '¿Seguro que deseas eliminar a ${volunteer.name}?\n\n'
              'Las asignaciones asociadas quedarán vacías.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${volunteer.name} pendiente de eliminar',
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir voluntario'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nombre',
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
                    ),
                  );
                });

                saveVolunteers();
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void editVolunteer(int index) {
    final controller = TextEditingController(
      text: volunteers[index].name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar voluntario'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nombre',
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
                  );
                });

                saveVolunteers();
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  void toggleVolunteerStatus(int index) {
    setState(() {
      final volunteer = volunteers[index];

      volunteers[index] = Volunteer(
        id: volunteer.id,
        name: volunteer.name,
        isActive: !volunteer.isActive,
      );
    });

    saveVolunteers();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voluntarios'),
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
            subtitle: volunteer.isActive
                ? null
                : const Text('Inactivo'),
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
