import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/assignment.dart';

class AssignmentStorageService {
  static const String storageKey = 'aseo_assignments_v1';

  static Future<List<Assignment>> loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(storageKey) ?? const [])
        .map(
          (value) => Assignment.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          ),
        )
        .toList();
  }

  static Future<void> saveAssignments(List<Assignment> assignments) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = <String, Assignment>{
      for (final assignment in assignments) assignment.eventId: assignment,
    }.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final saved = await prefs.setStringList(
      storageKey,
      normalized.map((assignment) => jsonEncode(assignment.toJson())).toList(),
    );
    if (!saved) throw StateError('No se pudieron guardar las asignaciones');
  }

  static Future<int> countVolunteerAssignments(String volunteerId) async {
    final assignments = await loadAssignments();
    return assignments
        .where((assignment) => assignment.volunteerId == volunteerId)
        .length;
  }

  static Future<void> removeVolunteerFromAssignments(String volunteerId) async {
    final assignments = await loadAssignments();
    for (final assignment in assignments) {
      if (assignment.volunteerId == volunteerId) {
        assignment.volunteerId = null;
      }
    }
    await saveAssignments(assignments);
  }

  static Future<void> removeObsoleteFutureAssignments({DateTime? now}) async {
    final assignments = await loadAssignments();
    final todayValue = now ?? DateTime.now();
    final today = DateTime(todayValue.year, todayValue.month, todayValue.day);
    final originalLength = assignments.length;
    assignments.removeWhere(
      (assignment) =>
          !assignment.date.isBefore(today) &&
          (assignment.eventId.endsWith('-alabanza-sala-2') ||
              assignment.eventId.contains('-banos-')),
    );
    if (assignments.length != originalLength) {
      await saveAssignments(assignments);
    }
  }
}
