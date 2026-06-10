class Assignment {
  final String role;
  final String startTime;
  final String endTime;
  String? volunteerId;

  Assignment({
    required this.role,
    required this.startTime,
    required this.endTime,
    this.volunteerId,
  });
}
