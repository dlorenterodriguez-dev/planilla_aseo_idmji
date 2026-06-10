import 'assignment.dart';

class EventTemplates {
  static List<Assignment> alabanza() {
    return [
      Assignment(
        role: 'Vigilancia',
        startTime: '18:00',
        endTime: '19:00',
      ),
      Assignment(
        role: 'Vigilancia',
        startTime: '19:00',
        endTime: '19:45',
      ),
      Assignment(
        role: 'Vigilancia',
        startTime: '19:45',
        endTime: '20:30',
      ),
    ];
  }

  static List<Assignment> estudio() {
    return [
      Assignment(
        role: 'Vigilancia',
        startTime: '16:00',
        endTime: '17:00',
      ),
      Assignment(
        role: 'Vigilancia',
        startTime: '17:00',
        endTime: '17:45',
      ),
      Assignment(
        role: 'Vigilancia',
        startTime: '17:45',
        endTime: '18:30',
      ),
    ];
  }

  static List<Assignment> ensenanza() {
    return [
      Assignment(
        role: 'Vigilancia',
        startTime: '16:00',
        endTime: '17:00',
      ),
      Assignment(
        role: 'Vigilancia',
        startTime: '17:00',
        endTime: '17:45',
      ),
      Assignment(
        role: 'Vigilancia',
        startTime: '17:45',
        endTime: '18:30',
      ),
      Assignment(
        role: 'Micrófono',
        startTime: '17:50',
        endTime: '18:30',
      ),
      Assignment(
        role: 'Acomodación pasillo 1',
        startTime: '17:00',
        endTime: '17:30',
      ),
      Assignment(
        role: 'Acomodación pasillo 2',
        startTime: '17:00',
        endTime: '17:30',
      ),
    ];
  }
}