import 'absence_period.dart';

class Volunteer {
  final String id;
  final String name;
  final bool isActive;
  final bool availableAlabanza;
  final bool availableEstudio;
  final bool availableEnsenanza;
  final String? partnerId;
  final List<AbsencePeriod> absences;

  const Volunteer({
    required this.id,
    required this.name,
    this.isActive = true,
    this.availableAlabanza = true,
    this.availableEstudio = true,
    this.availableEnsenanza = true,
    this.partnerId,
    this.absences = const [],
  });

  bool isAvailableFor(String eventType, DateTime date, {String? cleaningArea}) {
    final availableForCulto = switch (eventType) {
      'alabanza' => availableAlabanza,
      'estudio' => availableEstudio,
      'ensenanza' => availableEnsenanza,
      _ => false,
    };
    return isActive &&
        availableForCulto &&
        !absences.any((absence) => absence.includes(date));
  }

  Volunteer copyWith({
    String? name,
    bool? isActive,
    bool? availableAlabanza,
    bool? availableEstudio,
    bool? availableEnsenanza,
    String? partnerId,
    bool clearPartner = false,
    List<AbsencePeriod>? absences,
  }) {
    return Volunteer(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      availableAlabanza: availableAlabanza ?? this.availableAlabanza,
      availableEstudio: availableEstudio ?? this.availableEstudio,
      availableEnsenanza: availableEnsenanza ?? this.availableEnsenanza,
      partnerId: clearPartner ? null : partnerId ?? this.partnerId,
      absences: absences ?? this.absences,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isActive': isActive,
    'availableAlabanza': availableAlabanza,
    'availableEstudio': availableEstudio,
    'availableEnsenanza': availableEnsenanza,
    'partnerId': partnerId,
    'absences': absences.map((absence) => absence.toJson()).toList(),
  };

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? true,
      availableAlabanza: json['availableAlabanza'] as bool? ?? true,
      availableEstudio: json['availableEstudio'] as bool? ?? true,
      availableEnsenanza: json['availableEnsenanza'] as bool? ?? true,
      partnerId: json['partnerId'] as String?,
      absences: (json['absences'] as List<dynamic>? ?? const [])
          .map(
            (value) =>
                AbsencePeriod.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(),
    );
  }
}
