import '../models/assignment.dart';
import '../models/volunteer.dart';

class AutoAssignmentService {
  static Future<void> autoAssign({
    required List<Assignment> assignments,
    required List<Volunteer> volunteers,
  }) async {
    // 1. Obtener únicamente los puestos sin asignar.
    final pendingAssignments =
    assignments.where(_isUnassigned).toList();

    if (pendingAssignments.isEmpty) {
      return;
    }

    // 2. Orden temporal y determinista.
    // En el siguiente paso lo sustituiremos por la
    // ordenación basada en el número de candidatos.
    pendingAssignments.sort(
          (a, b) => a.role.compareTo(b.role),
    );

    // 3. Recorrer los puestos pendientes.
    for (final assignment in pendingAssignments) {
      // La lógica de autoasignación irá aquí.
    }
  }

  static bool _isUnassigned(Assignment assignment) {
    return (assignment.volunteerId ?? '').isEmpty;
  }
}