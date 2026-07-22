import '../models/assignment.dart';
import '../models/service_types.dart';
import '../models/volunteer.dart';
import 'service_history_query_service.dart';

class AutoAssignmentService {
  static Future<void> autoAssign({
    required List<Assignment> assignments,
    required List<Volunteer> volunteers,
    required bool isAlabanza,
    required Map<String, int> weeklyAssignmentCounts,
  }) async {
    final pendingAssignments = assignments.where(_isUnassigned).toList();

    if (pendingAssignments.isEmpty) {
      return;
    }

    final vigilanceAssignments = assignments
        .where(
          (assignment) =>
              ServiceTypes.fromRole(assignment.role) ==
              ServiceTypes.vigilance,
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final candidateCounts = <int>[];
    final candidateLists = <List<Volunteer>>[];
    final historicalCountsByServiceType = <String, Map<String, int>>{};

    for (final assignment in pendingAssignments) {
      final serviceType = ServiceTypes.fromRole(assignment.role);
      historicalCountsByServiceType[serviceType] ??=
          await ServiceHistoryQueryService.countAssignmentsByVolunteer(
        serviceType: serviceType,
      );
    }

    for (final assignment in pendingAssignments) {
      final candidates = _eligibleCandidates(
        assignment: assignment,
        volunteers: volunteers,
        vigilanceAssignments: vigilanceAssignments,
        isAlabanza: isAlabanza,
      );
      candidateLists.add(candidates);
      candidateCounts.add(candidates.length);
    }

    final indices = List<int>.generate(
      pendingAssignments.length,
      (index) => index,
    );

    indices.sort((a, b) {
      final difficulty = candidateCounts[a].compareTo(candidateCounts[b]);
      if (difficulty != 0) {
        return difficulty;
      }

      final roleCompare =
          pendingAssignments[a].role.compareTo(pendingAssignments[b].role);
      if (roleCompare != 0) {
        return roleCompare;
      }

      final startCompare = pendingAssignments[a].startTime.compareTo(
        pendingAssignments[b].startTime,
      );
      if (startCompare != 0) {
        return startCompare;
      }

      return pendingAssignments[a].endTime.compareTo(
        pendingAssignments[b].endTime,
      );
    });

    for (final index in indices) {
      final assignment = pendingAssignments[index];
      final candidates = candidateLists[index];

      if (candidates.isEmpty) {
        continue;
      }

      final serviceType = ServiceTypes.fromRole(assignment.role);

      final occupiedVolunteerIds = <String>{};
      for (final existing in assignments) {
        final id = existing.volunteerId;
        if (id != null && id.isNotEmpty) {
          occupiedVolunteerIds.add(id);
        }
      }

      final availableCandidates = candidates
          .where((candidate) => !occupiedVolunteerIds.contains(candidate.id))
          .toList();
      final selectionPool = availableCandidates.isEmpty
          ? List<Volunteer>.of(candidates)
          : availableCandidates;
      selectionPool.sort(
        (a, b) => _compareCandidates(
          a,
          b,
          weeklyAssignmentCounts,
          historicalCountsByServiceType[serviceType]!,
        ),
      );

      final selected = selectionPool.first;
      assignment.volunteerId = selected.id;
      weeklyAssignmentCounts.update(
        selected.id,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  static bool _isUnassigned(Assignment assignment) {
    final id = assignment.volunteerId;
    return id == null || id.isEmpty;
  }

  static int _compareCandidates(
    Volunteer a,
    Volunteer b,
    Map<String, int> weeklyAssignmentCounts,
    Map<String, int> historicalCounts,
  ) {
    final weeklyLoadCompare = (weeklyAssignmentCounts[a.id] ?? 0).compareTo(
      weeklyAssignmentCounts[b.id] ?? 0,
    );
    if (weeklyLoadCompare != 0) {
      return weeklyLoadCompare;
    }

    final loadCompare = (historicalCounts[a.id] ?? 0).compareTo(
      historicalCounts[b.id] ?? 0,
    );
    if (loadCompare != 0) {
      return loadCompare;
    }

    final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (nameCompare != 0) {
      return nameCompare;
    }

    return a.id.compareTo(b.id);
  }

  static List<Volunteer> _eligibleCandidates({
    required Assignment assignment,
    required List<Volunteer> volunteers,
    required List<Assignment> vigilanceAssignments,
    required bool isAlabanza,
  }) {
    final serviceType = ServiceTypes.fromRole(assignment.role);
    final vigilanceTurnIndex = vigilanceAssignments.indexWhere(
      (currentAssignment) => identical(currentAssignment, assignment),
    );
    final candidates = <Volunteer>[];

    for (final volunteer in volunteers) {
      if (!volunteer.isActive) {
        continue;
      }

      final permitted = _hasPermission(volunteer, serviceType);
      if (!permitted) {
        continue;
      }

      if (serviceType != ServiceTypes.vigilance ||
          _canServeVigilanceTurn(
            volunteer: volunteer,
            vigilanceTurnIndex: vigilanceTurnIndex,
            vigilanceTurnCount: vigilanceAssignments.length,
            isAlabanza: isAlabanza,
          )) {
        candidates.add(volunteer);
      }
    }

    return candidates;
  }

  static bool _hasPermission(Volunteer volunteer, String serviceType) {
    if (serviceType == ServiceTypes.vigilance) {
      return true;
    }
    if (serviceType == ServiceTypes.microphone) {
      return volunteer.canMicrophone;
    }
    if (serviceType == ServiceTypes.accommodation) {
      return volunteer.canAccommodation;
    }
    if (serviceType == ServiceTypes.cleaning) {
      return volunteer.canCleaning;
    }
    if (serviceType == ServiceTypes.bookTable) {
      return volunteer.canBookTable;
    }
    if (serviceType == ServiceTypes.audiovisuals) {
      return volunteer.canAudiovisuals;
    }
    return false;
  }

  static bool _canServeVigilanceTurn({
    required Volunteer volunteer,
    required int vigilanceTurnIndex,
    required int vigilanceTurnCount,
    required bool isAlabanza,
  }) {
    // En Alabanza, los voluntarios de Imposición no pueden
    // realizar la última vigilancia.
    if (isAlabanza &&
        vigilanceTurnIndex == vigilanceTurnCount - 1 &&
        volunteer.canImposition) {
      return false;
    }

    if (vigilanceTurnIndex == 0) {
      return volunteer.canFirstVigilance;
    }

    if (vigilanceTurnIndex == vigilanceTurnCount - 1) {
      return volunteer.canLastVigilance;
    }

    return volunteer.canMiddleVigilance;
  }
}
