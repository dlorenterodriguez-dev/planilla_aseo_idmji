import '../models/assignment.dart';
import '../models/service_occurrence.dart';
import '../models/volunteer.dart';
import 'service_history_query_service.dart';

class AutoAssignmentService {
  static Future<void> autoAssign({
    required List<ServiceOccurrence> occurrences,
    required List<Assignment> assignments,
    required List<Volunteer> volunteers,
  }) async {
    final stats = await ServiceHistoryQueryService.statsByVolunteer();
    final assignmentsById = {
      for (final assignment in assignments) assignment.eventId: assignment,
    };
    final periodCounts = <String, int>{};
    final weeklyCounts = <String, Map<String, int>>{};

    for (final occurrence in occurrences) {
      final volunteerId = assignmentsById[occurrence.eventId]?.volunteerId;
      if (volunteerId == null || volunteerId.isEmpty) continue;
      periodCounts.update(volunteerId, (count) => count + 1, ifAbsent: () => 1);
      final weekKey = _weekKey(occurrence.date);
      weeklyCounts
          .putIfAbsent(weekKey, () => {})
          .update(volunteerId, (count) => count + 1, ifAbsent: () => 1);
    }

    final ordered = List<ServiceOccurrence>.of(occurrences)
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final occurrence in ordered) {
      final assignment = assignmentsById.putIfAbsent(occurrence.eventId, () {
        final created = Assignment(
          eventId: occurrence.eventId,
          eventType: occurrence.eventType,
          date: occurrence.date,
        );
        assignments.add(created);
        return created;
      });
      if (assignment.volunteerId?.isNotEmpty ?? false) continue;

      final candidates = volunteers
          .where(
            (volunteer) =>
                volunteer.isAvailableFor(
                  occurrence.eventType,
                  occurrence.date,
                ) &&
                !_isAlreadyAssignedToService(
                  volunteer.id,
                  occurrence,
                  assignments,
                ),
          )
          .toList();
      if (candidates.isEmpty) continue;

      final weekCounts = weeklyCounts.putIfAbsent(
        _weekKey(occurrence.date),
        () => {},
      );
      candidates.sort((a, b) {
        int compare(int left, int right) => left.compareTo(right);

        var result = compare(weekCounts[a.id] ?? 0, weekCounts[b.id] ?? 0);
        if (result != 0) return result;
        result = compare(periodCounts[a.id] ?? 0, periodCounts[b.id] ?? 0);
        if (result != 0) return result;

        final aStats = stats[a.id];
        final bStats = stats[b.id];
        result = compare(aStats?.total ?? 0, bStats?.total ?? 0);
        if (result != 0) return result;
        result = compare(
          aStats?.byEventType[occurrence.eventType] ?? 0,
          bStats?.byEventType[occurrence.eventType] ?? 0,
        );
        if (result != 0) return result;

        final aLast = aStats?.lastService;
        final bLast = bStats?.lastService;
        if (aLast == null && bLast != null) return -1;
        if (aLast != null && bLast == null) return 1;
        if (aLast != null && bLast != null) {
          result = aLast.compareTo(bLast);
          if (result != 0) return result;
        }
        result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return result != 0 ? result : a.id.compareTo(b.id);
      });

      final selected = candidates.first;
      assignment.volunteerId = selected.id;
      periodCounts.update(selected.id, (count) => count + 1, ifAbsent: () => 1);
      weekCounts.update(selected.id, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  static String _weekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-${monday.month}-${monday.day}';
  }

  static bool _isAlreadyAssignedToService(
    String volunteerId,
    ServiceOccurrence occurrence,
    List<Assignment> assignments,
  ) {
    return assignments.any(
      (assignment) =>
          assignment.eventId != occurrence.eventId &&
          assignment.eventType == occurrence.eventType &&
          _sameDay(assignment.date, occurrence.date) &&
          assignment.volunteerId == volunteerId,
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
