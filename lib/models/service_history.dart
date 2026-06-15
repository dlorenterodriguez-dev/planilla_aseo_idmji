import 'service_stat.dart';

class ServiceHistory {
  final String volunteerId;
  final Map<String, ServiceStat> serviceStats;

  const ServiceHistory({
    required this.volunteerId,
    this.serviceStats = const {},
  });

  ServiceHistory copyWith({
    String? volunteerId,
    Map<String, ServiceStat>? serviceStats,
  }) {
    return ServiceHistory(
      volunteerId: volunteerId ?? this.volunteerId,
      serviceStats: serviceStats ?? this.serviceStats,
    );
  }

  /// Devuelve las estadísticas de un servicio concreto.
  ServiceStat getStat(String serviceType) {
    return serviceStats[serviceType] ?? const ServiceStat();
  }

  /// Devuelve una copia incrementando el contador y actualizando la fecha.
  ServiceHistory increment(
      String serviceType, {
        DateTime? servedAt,
      }) {
    final updatedStats =
    Map<String, ServiceStat>.from(serviceStats);

    final current = getStat(serviceType);

    updatedStats[serviceType] = current.copyWith(
      count: current.count + 1,
      lastServed: servedAt ?? DateTime.now(),
    );

    return copyWith(serviceStats: updatedStats);
  }

  Map<String, dynamic> toJson() {
    return {
      'volunteerId': volunteerId,
      'serviceStats': serviceStats.map(
            (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  factory ServiceHistory.fromJson(Map<String, dynamic> json) {
    final rawStats =
        (json['serviceStats'] as Map?)?.cast<String, dynamic>() ?? {};

    return ServiceHistory(
      volunteerId: json['volunteerId'] as String,
      serviceStats: rawStats.map(
            (key, value) => MapEntry(
          key,
          ServiceStat.fromJson(
            (value as Map).cast<String, dynamic>(),
          ),
        ),
      ),
    );
  }
}