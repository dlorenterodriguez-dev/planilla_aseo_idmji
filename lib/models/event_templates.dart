import 'service_occurrence.dart';

class EventTemplates {
  static List<ServiceOccurrence> forWeek(DateTime monday) {
    final start = DateTime(monday.year, monday.month, monday.day);
    final services = [
      (start.add(const Duration(days: 1)), 'alabanza', '18:00', '20:30'),
      (start.add(const Duration(days: 5)), 'estudio', '16:00', '18:30'),
      (start.add(const Duration(days: 6)), 'ensenanza', '16:00', '18:30'),
    ];
    return [
      for (final service in services)
        for (var position = 1; position <= 2; position++)
          _occurrence(service.$1, service.$2, service.$3, service.$4, position),
    ];
  }

  static List<ServiceOccurrence> forMonth(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1);
    final firstMonday = first.subtract(Duration(days: first.weekday - 1));
    final occurrences = <ServiceOccurrence>[];

    for (
      var monday = firstMonday;
      monday.isBefore(last);
      monday = monday.add(const Duration(days: 7))
    ) {
      occurrences.addAll(
        forWeek(monday).where(
          (occurrence) =>
              occurrence.date.year == month.year &&
              occurrence.date.month == month.month,
        ),
      );
    }
    occurrences.sort((a, b) => a.date.compareTo(b.date));
    return occurrences;
  }

  static ServiceOccurrence _occurrence(
    DateTime date,
    String type,
    String start,
    String end,
    int position,
  ) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return ServiceOccurrence(
      eventId: '${date.year}-$month-$day-$type-$position',
      eventType: type,
      date: date,
      startTime: start,
      endTime: end,
      position: position,
    );
  }
}
