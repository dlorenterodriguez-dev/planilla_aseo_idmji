import 'absence_period.dart';

class Volunteer {
  final String id;
  final String name;
  final bool isActive;
  final bool availableAlabanza;
  final bool availableEstudio;
  final bool availableEnsenanza;
  final List<AbsencePeriod> absences;

  const Volunteer({
    required this.id,
    required this.name,
    this.isActive = true,
    this.availableAlabanza = true,
    this.availableEstudio = true,
    this.availableEnsenanza = true,
    this.absences = const [],
  });

  bool isAvailableFor(String eventType, DateTime date) {
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
    List<AbsencePeriod>? absences,
  }) {
    return Volunteer(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      availableAlabanza: availableAlabanza ?? this.availableAlabanza,
      availableEstudio: availableEstudio ?? this.availableEstudio,
      availableEnsenanza: availableEnsenanza ?? this.availableEnsenanza,
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
      absences: (json['absences'] as List<dynamic>? ?? const [])
          .map(
            (value) =>
                AbsencePeriod.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(),
    );
  }
}
