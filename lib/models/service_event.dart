class ServiceEvent {
  final String volunteerId;
  final String eventType;
  final String eventId;
  final DateTime date;

  const ServiceEvent({
    required this.volunteerId,
    required this.eventType,
    required this.eventId,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'volunteerId': volunteerId,
    'eventType': eventType,
    'eventId': eventId,
    'date': date.toIso8601String(),
  };

  factory ServiceEvent.fromJson(Map<String, dynamic> json) {
    return ServiceEvent(
      volunteerId: json['volunteerId'] as String,
      eventType: json['eventType'] as String,
      eventId: json['eventId'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
