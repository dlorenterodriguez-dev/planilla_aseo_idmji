class ServiceEvent {
  final String volunteerId;
  final String serviceType;

  /// Culto o equipo al que pertenece la asignación.
  final String eventType;

  /// Nombre visible y horario del puesto archivado.
  final String role;
  final String startTime;
  final String endTime;

  /// Identificador único del culto, por ejemplo:
  /// "2026-06-14-ensenanza"
  final String eventId;

  /// Fecha del culto contabilizado.
  final DateTime date;

  const ServiceEvent({
    required this.volunteerId,
    required this.serviceType,
    required this.eventType,
    required this.role,
    required this.startTime,
    required this.endTime,
    required this.eventId,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'volunteerId': volunteerId,
      'serviceType': serviceType,
      'eventType': eventType,
      'role': role,
      'startTime': startTime,
      'endTime': endTime,
      'eventId': eventId,
      'date': date.toIso8601String(),
    };
  }

  factory ServiceEvent.fromJson(Map<String, dynamic> json) {
    final eventId = json['eventId'] as String;

    return ServiceEvent(
      volunteerId: json['volunteerId'] as String,
      serviceType: json['serviceType'] as String,
      eventType: json['eventType'] as String? ?? eventId.split('-').last,
      role: json['role'] as String? ?? json['serviceType'] as String,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      eventId: eventId,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
