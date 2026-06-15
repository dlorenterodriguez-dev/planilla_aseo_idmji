class ServiceTypes {
  static const String vigilance = 'vigilance';
  static const String microphone = 'microphone';
  static const String accommodation = 'accommodation';
  static const String cleaning = 'cleaning';
  static const String bookTable = 'bookTable';
  static const String audiovisuals = 'audiovisuals';

  static String fromRole(String role) {
    switch (role) {
      case 'Vigilancia':
        return vigilance;

      case 'Micrófono':
        return microphone;

      case 'Acomodación pasillo 1':
      case 'Acomodación pasillo 2':
        return accommodation;

      case 'Aseo':
        return cleaning;

      case 'Mesa de Biblias':
        return bookTable;

      case 'Audiovisuales':
        return audiovisuals;

      default:
        throw UnsupportedError('Rol desconocido: $role');
    }
  }
}