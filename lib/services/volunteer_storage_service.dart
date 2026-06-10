import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/default_volunteers.dart';
import '../models/volunteer.dart';

class VolunteerStorageService {
  static const String _legacyKey = 'volunteers';
  static const String _key = 'volunteers_v2';

  static Future<List<Volunteer>> loadVolunteers() async {
    final prefs = await SharedPreferences.getInstance();

    final savedVolunteers = prefs.getStringList(_key);

    if (savedVolunteers != null) {
      return savedVolunteers
          .map((volunteer) => Volunteer.fromJson(
                jsonDecode(volunteer) as Map<String, dynamic>,
              ))
          .toList();
    }

    final legacyVolunteers =
        prefs.getStringList(_legacyKey) ?? defaultVolunteers;
    final volunteers = _fromNames(legacyVolunteers);

    await saveVolunteers(volunteers);

    return volunteers;
  }

  static Future<void> saveVolunteers(List<Volunteer> volunteers) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      volunteers
          .map((volunteer) => jsonEncode(volunteer.toJson()))
          .toList(),
    );
  }

  static List<Volunteer> _fromNames(List<String> names) {
    final usedIds = <String>{};

    return names.map((name) {
      final id = _uniqueIdForName(name, usedIds);
      usedIds.add(id);

      return Volunteer(
        id: id,
        name: name,
        isActive: true,
      );
    }).toList();
  }

  static String _uniqueIdForName(String name, Set<String> usedIds) {
    final baseId = _idForName(name);
    var id = baseId;
    var suffix = 2;

    while (usedIds.contains(id)) {
      id = '$baseId-$suffix';
      suffix++;
    }

    return id;
  }

  static String _idForName(String name) {
    final id = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (id.isEmpty) {
      return 'volunteer';
    }

    return id;
  }
}
