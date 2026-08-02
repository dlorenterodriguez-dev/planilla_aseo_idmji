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
    final volunteersById = {
      for (final volunteer in volunteers) volunteer.id: volunteer,
    };
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

      final sameService = ordered
          .where(
            (other) =>
                other.eventType == occurrence.eventType &&
                _sameDay(other.date, occurrence.date),
          )
          .toList();
      final assignedPartner = sameService
          .map((other) => assignmentsById[other.eventId]?.volunteerId)
          .whereType<String>()
          .map((id) => volunteersById[id])
          .whereType<Volunteer>()
          .where((volunteer) => volunteer.partnerId != null)
          .where((volunteer) => volunteer.partnerId != volunteer.id)
          .where((volunteer) => volunteer.partnerId != null)
          .where(
            (volunteer) =>
                volunteersById[volunteer.partnerId!]?.partnerId == volunteer.id,
          )
          .firstOrNull;
      if (sameService.length == 2 &&
          assignedPartner != null &&
          assignedPartner.partnerId != null) {
        final partner = volunteersById[assignedPartner.partnerId!];
        if (partner != null &&
            partner.isAvailableFor(
              occurrence.eventType,
              occurrence.date,
              cleaningArea: occurrence.cleaningArea,
            )) {
          assignment.volunteerId = partner.id;
          _incrementCounts(
            partner.id,
            occurrence.date,
            periodCounts,
            weeklyCounts,
          );
          continue;
        }
      }

      final emptySlots = sameService
          .where(
            (other) =>
                !(assignmentsById[other.eventId]?.volunteerId?.isNotEmpty ??
                    false),
          )
          .length;

      final candidates = volunteers
          .where(
            (volunteer) =>
                volunteer.isAvailableFor(
                  occurrence.eventType,
                  occurrence.date,
                  cleaningArea: occurrence.cleaningArea,
                ) &&
                !_isAlreadyAssignedToService(
                  volunteer.id,
                  occurrence,
                  assignments,
                ) &&
                _canEnterAsUnit(
                  volunteer,
                  occurrence,
                  emptySlots,
                  volunteersById,
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
      _incrementCounts(
        selected.id,
        occurrence.date,
        periodCounts,
        weeklyCounts,
      );

      final partnerId = selected.partnerId;
      if (partnerId != null && emptySlots >= 2) {
        final partnerOccurrence = sameService.firstWhere(
          (other) => other.eventId != occurrence.eventId,
        );
        final partnerAssignment = assignmentsById.putIfAbsent(
          partnerOccurrence.eventId,
          () {
            final created = Assignment(
              eventId: partnerOccurrence.eventId,
              eventType: partnerOccurrence.eventType,
              date: partnerOccurrence.date,
            );
            assignments.add(created);
            return created;
          },
        );
        partnerAssignment.volunteerId = partnerId;
        _incrementCounts(
          partnerId,
          partnerOccurrence.date,
          periodCounts,
          weeklyCounts,
        );
      }
    }
  }

  static bool _canEnterAsUnit(
    Volunteer volunteer,
    ServiceOccurrence occurrence,
    int emptySlots,
    Map<String, Volunteer> volunteersById,
  ) {
    final partnerId = volunteer.partnerId;
    if (partnerId == null) return true;
    if (occurrence.eventType != 'estudio' || emptySlots < 2) return false;
    final partner = volunteersById[partnerId];
    return partner != null &&
        partner.partnerId == volunteer.id &&
        volunteer.id.compareTo(partner.id) < 0 &&
        partner.isAvailableFor(
          occurrence.eventType,
          occurrence.date,
          cleaningArea: occurrence.cleaningArea,
        );
  }

  static void _incrementCounts(
    String volunteerId,
    DateTime date,
    Map<String, int> periodCounts,
    Map<String, Map<String, int>> weeklyCounts,
  ) {
    periodCounts.update(volunteerId, (count) => count + 1, ifAbsent: () => 1);
    weeklyCounts
        .putIfAbsent(_weekKey(date), () => {})
        .update(volunteerId, (count) => count + 1, ifAbsent: () => 1);
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
