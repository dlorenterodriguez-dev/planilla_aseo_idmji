import '../models/assignment.dart';
import '../models/service_types.dart';
import '../models/volunteer.dart';

class AutoAssignmentService {
  static Future<void> autoAssign({
    required List<Assignment> assignments,
    required List<Volunteer> volunteers,
    required bool isAlabanza,
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

      final occupiedVolunteerIds = <String>{};
      for (final existing in assignments) {
        final id = existing.volunteerId;
        if (id != null && id.isNotEmpty) {
          occupiedVolunteerIds.add(id);
        }
      }

      Volunteer? selected;
      for (final candidate in candidates) {
        if (!occupiedVolunteerIds.contains(candidate.id)) {
          selected = candidate;
          break;
        }
      }

      selected ??= candidates.first;
      assignment.volunteerId = selected.id;
    }
  }

  static bool _isUnassigned(Assignment assignment) {
    final id = assignment.volunteerId;
    return id == null || id.isEmpty;
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
