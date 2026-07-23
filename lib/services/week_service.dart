import 'package:shared_preferences/shared_preferences.dart';

class WeekService {
  static const String storageKey = 'biblias_week_start_v1';

  static Future<DateTime> loadWeekStart() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(storageKey);
    if (saved != null) return DateTime.parse(saved);
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
  }

  static Future<void> saveWeekStart(DateTime monday) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, monday.toIso8601String());
  }
}
