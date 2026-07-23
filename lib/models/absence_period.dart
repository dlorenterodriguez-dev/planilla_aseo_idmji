class AbsencePeriod {
  final DateTime start;
  final DateTime end;

  const AbsencePeriod({required this.start, required this.end});

  bool includes(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final first = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    return !day.isBefore(first) && !day.isAfter(last);
  }

  Map<String, dynamic> toJson() => {
    'start': _dateKey(start),
    'end': _dateKey(end),
  };

  factory AbsencePeriod.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['start'] as String);
    final end = DateTime.parse(json['end'] as String);
    if (end.isBefore(start)) {
      throw const FormatException(
        'El final de una ausencia precede a su inicio',
      );
    }
    return AbsencePeriod(start: start, end: end);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
