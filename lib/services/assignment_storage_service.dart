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
  static Future<int> countVolunteerAssignments(
      String volunteerId,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final alabanza =
        prefs.getStringList('alabanza_assignments_v2') ?? [];

    final estudio =
        prefs.getStringList('estudio_assignments_v2') ?? [];

    final ensenanza =
        prefs.getStringList('ensenanza_assignments_v2') ?? [];

    int count = 0;

    count += alabanza.where((id) => id == volunteerId).length;
    count += estudio.where((id) => id == volunteerId).length;
    count += ensenanza.where((id) => id == volunteerId).length;

    return count;
  }
  static Future<void> removeVolunteerFromAssignments(
      String volunteerId,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final alabanza =
        prefs.getStringList('alabanza_assignments_v2') ?? [];

    final estudio =
        prefs.getStringList('estudio_assignments_v2') ?? [];

    final ensenanza =
        prefs.getStringList('ensenanza_assignments_v2') ?? [];

    for (int i = 0; i < alabanza.length; i++) {
      if (alabanza[i] == volunteerId) {
        alabanza[i] = '';
      }
    }

    for (int i = 0; i < estudio.length; i++) {
      if (estudio[i] == volunteerId) {
        estudio[i] = '';
      }
    }

    for (int i = 0; i < ensenanza.length; i++) {
      if (ensenanza[i] == volunteerId) {
        ensenanza[i] = '';
      }
    }

    await prefs.setStringList(
      'alabanza_assignments_v2',
      alabanza,
    );

    await prefs.setStringList(
      'estudio_assignments_v2',
      estudio,
    );

    await prefs.setStringList(
      'ensenanza_assignments_v2',
      ensenanza,
    );
  }
}