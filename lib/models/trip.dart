class Trip {
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String heroEmoji;

  const Trip({
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.heroEmoji = '✈️',
  });

  Duration get timeUntilStart => startDate.difference(DateTime.now());

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  bool get hasStarted => DateTime.now().isAfter(startDate);

  bool get hasEnded => DateTime.now().isAfter(endDate);
}
