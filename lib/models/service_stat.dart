class ServiceStat {
  final int count;
  final DateTime? lastServed;

  const ServiceStat({
    this.count = 0,
    this.lastServed,
  });

  ServiceStat copyWith({
    int? count,
    DateTime? lastServed,
  }) {
    return ServiceStat(
      count: count ?? this.count,
      lastServed: lastServed ?? this.lastServed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'lastServed': lastServed?.toIso8601String(),
    };
  }

  factory ServiceStat.fromJson(Map<String, dynamic> json) {
    return ServiceStat(
      count: (json['count'] ?? 0) as int,
      lastServed: json['lastServed'] != null
          ? DateTime.parse(json['lastServed'] as String)
          : null,
    );
  }
}