import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/volunteer.dart';

class VolunteerStorageService {
  static const String storageKey = 'aseo_volunteers_v1';

  static Future<List<Volunteer>> loadVolunteers() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(storageKey) ?? const [])
        .map(
          (value) => Volunteer.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          ),
        )
        .toList();
  }

  static Future<void> saveVolunteers(List<Volunteer> volunteers) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
      storageKey,
      volunteers.map((volunteer) => jsonEncode(volunteer.toJson())).toList(),
    );
    if (!saved) throw StateError('No se pudieron guardar las voluntarias');
  }
}
