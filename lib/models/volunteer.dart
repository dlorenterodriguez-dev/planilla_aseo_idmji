class Volunteer {
  final String id;
  final String name;
  final bool isActive;

  final bool canVigilance;
  final bool canMicrophone;
  final bool canAccommodation;
  final bool firstVigilanceOnly;
  final bool canCleaning;
  final bool canBookTable;
  final bool canAudiovisuals;

  const Volunteer({
    required this.id,
    required this.name,
    required this.isActive,
    this.canVigilance = false,
    this.canMicrophone = false,
    this.canAccommodation = false,
    this.firstVigilanceOnly = false,
    this.canCleaning = false,
    this.canBookTable = false,
    this.canAudiovisuals = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'canVigilance': canVigilance,
      'canMicrophone': canMicrophone,
      'canAccommodation': canAccommodation,
      'firstVigilanceOnly': firstVigilanceOnly,
      'canCleaning': canCleaning,
      'canBookTable': canBookTable,
      'canAudiovisuals': canAudiovisuals,

    };
  }

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? false,
      canVigilance: json['canVigilance'] as bool? ?? false,
      canMicrophone: json['canMicrophone'] as bool? ?? false,
      canAccommodation: json['canAccommodation'] as bool? ?? false,
      firstVigilanceOnly:
      json['firstVigilanceOnly'] as bool? ?? false,
      canCleaning: json['canCleaning'] as bool? ?? false,
      canBookTable: json['canBookTable'] as bool? ?? false,
      canAudiovisuals: json['canAudiovisuals'] as bool? ?? false,
    );
  }
}