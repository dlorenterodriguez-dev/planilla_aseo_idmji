class Assignment {
  final String eventId;
  final String eventType;
  final DateTime date;
  String? volunteerId;

  Assignment({
    required this.eventId,
    required this.eventType,
    required this.date,
    this.volunteerId,
  });

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'eventType': eventType,
    'date': date.toIso8601String(),
    'volunteerId': volunteerId,
  };

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      eventId: json['eventId'] as String,
      eventType: json['eventType'] as String,
      date: DateTime.parse(json['date'] as String),
      volunteerId: json['volunteerId'] as String?,
    );
  }
}
