import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_history.dart';

class ServiceHistoryStorageService {
  static const String _key = 'service_histories_v1';

  static Future<ServiceHistory> getOrCreateHistory(
      String volunteerId,
      ) async {
    final histories = await loadHistories();

    for (final history in histories) {
      if (history.volunteerId == volunteerId) {
        return history;
      }
    }

    return ServiceHistory(volunteerId: volunteerId);
  }

  static Future<List<ServiceHistory>> loadHistories() async {
    final prefs = await SharedPreferences.getInstance();

    final savedHistories = prefs.getStringList(_key);

    if (savedHistories == null) {
      return [];
    }

    return savedHistories
        .map(
          (history) => ServiceHistory.fromJson(
        jsonDecode(history) as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  static Future<void> saveHistories(
      List<ServiceHistory> histories,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      histories
          .map((history) => jsonEncode(history.toJson()))
          .toList(),
    );
  }
}