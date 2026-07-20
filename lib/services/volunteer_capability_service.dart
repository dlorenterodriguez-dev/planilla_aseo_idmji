import '../models/service_types.dart';
import '../models/volunteer.dart';

class VolunteerCapabilityService {
  static bool canServe({
    required Volunteer volunteer,
    required String serviceType,
  }) {
    if (!volunteer.isActive) {
      return false;
    }

    switch (serviceType) {
      case ServiceTypes.vigilance:
        return volunteer.canFirstVigilance ||
            volunteer.canMiddleVigilance ||
            volunteer.canLastVigilance;

      case ServiceTypes.microphone:
        return volunteer.canMicrophone;

      case ServiceTypes.accommodation:
        return volunteer.canAccommodation;

      case ServiceTypes.cleaning:
        return volunteer.canCleaning;

      case ServiceTypes.bookTable:
        return volunteer.canBookTable;

      case ServiceTypes.audiovisuals:
        return volunteer.canAudiovisuals;

      default:
        return false;
    }
  }
}