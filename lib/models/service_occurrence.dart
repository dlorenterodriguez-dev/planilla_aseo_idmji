class ServiceOccurrence {
  final String eventId;
  final String eventType;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String cleaningArea;
  final int position;

  const ServiceOccurrence({
    required this.eventId,
    required this.eventType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.cleaningArea,
    required this.position,
  });

  String get label => switch (eventType) {
    'alabanza' => 'Alabanza',
    'estudio' => 'Estudio',
    'ensenanza' => 'Enseñanza',
    _ => eventType,
  };

  String get positionLabel => switch (cleaningArea) {
    'sala' => 'Aseo sala de culto $position',
    'banos' => 'Aseo baños',
    _ => 'Puesto $position',
  };
}
