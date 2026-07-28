import 'service_occurrence.dart';

class EventTemplates {
  static List<ServiceOccurrence> forWeek(DateTime monday) {
    final start = DateTime(monday.year, monday.month, monday.day);
    return [
      _occurrence(
        start.add(const Duration(days: 1)),
        'alabanza',
        '20:30',
        '21:00',
        'sala',
        1,
      ),
      _occurrence(
        start.add(const Duration(days: 1)),
        'alabanza',
        '20:30',
        '21:00',
        'sala',
        2,
      ),
      _occurrence(
        start.add(const Duration(days: 5)),
        'estudio',
        '18:30',
        '19:00',
        'sala',
        1,
      ),
      _occurrence(
        start.add(const Duration(days: 5)),
        'estudio',
        '18:30',
        '19:00',
        'sala',
        2,
      ),
      _occurrence(
        start.add(const Duration(days: 5)),
        'estudio',
        '18:30',
        '19:00',
        'banos',
        1,
      ),
      _occurrence(
        start.add(const Duration(days: 6)),
        'ensenanza',
        '18:30',
        '19:00',
        'banos',
        1,
      ),
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
    String cleaningArea,
    int position,
  ) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return ServiceOccurrence(
      eventId: '${date.year}-$month-$day-$type-$cleaningArea-$position',
      eventType: type,
      date: date,
      startTime: start,
      endTime: end,
      cleaningArea: cleaningArea,
      position: position,
    );
  }
}
