import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/default_volunteers.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});

  @override
  State<VolunteersScreen> createState() => _VolunteersScreenState();
}

class _VolunteersScreenState extends State<VolunteersScreen> {
  List<String> volunteers = [];
  @override
  void initState() {
    super.initState();
    loadVolunteers();
  }

  Future<void> loadVolunteers() async {
    final prefs = await SharedPreferences.getInstance();

    final savedVolunteers = prefs.getStringList('volunteers');

    setState(() {
      volunteers = savedVolunteers ??
          defaultVolunteers;
    });
  }

  Future<void> saveVolunteers() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'volunteers',
      volunteers,
    );
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
                  volunteers.add(controller.text.trim());
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
      text: volunteers[index],
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
                  volunteers[index] = controller.text.trim();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voluntarios'),
      ),
      body: ListView.builder(
        itemCount: volunteers.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(volunteers[index]),
            onTap: () => editVolunteer(index),
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
