import 'package:shared_preferences/shared_preferences.dart';

class WeekService {
  static const String _key = 'week_start_date';

  static Future<DateTime> loadWeekStart() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString(_key);

    if (savedDate != null) {
      return DateTime.parse(savedDate);
    }

    final now = DateTime.now();

    final monday = now.subtract(
      Duration(days: now.weekday - 1),
    );

    await saveWeekStart(monday);

    return monday;
  }

  static Future<void> saveWeekStart(
      DateTime monday,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      monday.toIso8601String(),
    );
  }
}