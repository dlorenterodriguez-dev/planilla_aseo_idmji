import '../models/assignment.dart';

class ConflictService {
  static bool hasConflict(
      List<Assignment> assignments,
      Assignment currentAssignment,
      String volunteer,
      ) {
    for (final assignment in assignments) {
      if (assignment == currentAssignment) continue;

      if (assignment.volunteer != volunteer) continue;

      if (_overlaps(
        currentAssignment.startTime,
        currentAssignment.endTime,
        assignment.startTime,
        assignment.endTime,
      )) {
        return true;
      }
    }

    return false;
  }

  static bool _overlaps(
      String start1,
      String end1,
      String start2,
      String end2,
      ) {
    final s1 = _toMinutes(start1);
    final e1 = _toMinutes(end1);

    final s2 = _toMinutes(start2);
    final e2 = _toMinutes(end2);

    return s1 < e2 && s2 < e1;
  }

  static int _toMinutes(String time) {
    final parts = time.split(':');

    return int.parse(parts[0]) * 60 +
        int.parse(parts[1]);
  }
}