class Volunteer {
  final String id;
  final String name;
  final bool isActive;

  final bool canMicrophone;
  final bool canAccommodation;
  final bool canFirstVigilance;
  final bool canMiddleVigilance;
  final bool canLastVigilance;
  final bool canCleaning;
  final bool canBookTable;
  final bool canAudiovisuals;

  const Volunteer({
    required this.id,
    required this.name,
    required this.isActive,
    this.canMicrophone = false,
    this.canAccommodation = false,
    this.canFirstVigilance = true,
    this.canMiddleVigilance = true,
    this.canLastVigilance = true,
    this.canCleaning = false,
    this.canBookTable = false,
    this.canAudiovisuals = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isActive': isActive,
      'canMicrophone': canMicrophone,
      'canAccommodation': canAccommodation,
      'canFirstVigilance': canFirstVigilance,
      'canMiddleVigilance': canMiddleVigilance,
      'canLastVigilance': canLastVigilance,
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
      canMicrophone: json['canMicrophone'] as bool? ?? false,
      canAccommodation: json['canAccommodation'] as bool? ?? false,
      canFirstVigilance: json['canFirstVigilance'] as bool? ?? true,
      canMiddleVigilance: json['canMiddleVigilance'] as bool? ?? true,
      canLastVigilance: json['canLastVigilance'] as bool? ?? true,
      canCleaning: json['canCleaning'] as bool? ?? false,
      canBookTable: json['canBookTable'] as bool? ?? false,
      canAudiovisuals: json['canAudiovisuals'] as bool? ?? false,
    );
  }
}
