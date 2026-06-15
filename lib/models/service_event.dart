class ServiceEvent {
  final String volunteerId;
  final String serviceType;

  /// Identificador único del culto, por ejemplo:
  /// "2026-06-14-ensenanza"
  final String eventId;

  /// Fecha y hora en la que se contabilizó el servicio.
  final DateTime date;

  const ServiceEvent({
    required this.volunteerId,
    required this.serviceType,
    required this.eventId,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'volunteerId': volunteerId,
      'serviceType': serviceType,
      'eventId': eventId,
      'date': date.toIso8601String(),
    };
  }

  factory ServiceEvent.fromJson(Map<String, dynamic> json) {
    return ServiceEvent(
      volunteerId: json['volunteerId'] as String,
      serviceType: json['serviceType'] as String,
      eventId: json['eventId'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}