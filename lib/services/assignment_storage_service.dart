import 'package:shared_preferences/shared_preferences.dart';
import '../models/assignment.dart';

class AssignmentStorageService {
  static Future<void> saveAssignments({
    required List<Assignment> alabanza,
    required List<Assignment> estudio,
    required List<Assignment> ensenanza,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final alabanzaData =
    alabanza.map((a) => a.volunteerId ?? '').toList();

    final estudioData =
    estudio.map((a) => a.volunteerId ?? '').toList();

    final ensenanzaData =
    ensenanza.map((a) => a.volunteerId ?? '').toList();

    await prefs.setStringList(
      'alabanza_assignments_v2',
      alabanzaData,
    );

    await prefs.setStringList(
      'estudio_assignments_v2',
      estudioData,
    );

    await prefs.setStringList(
      'ensenanza_assignments_v2',
      ensenanzaData,
    );
  }
}