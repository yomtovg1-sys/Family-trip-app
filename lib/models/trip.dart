class Trip {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String heroEmoji;
  final String flagEmoji;
  final String? photoAsset;

  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.heroEmoji = '✈️',
    this.flagEmoji = '🌍',
    this.photoAsset,
  });

  Duration get timeUntilStart => startDate.difference(DateTime.now());

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  bool get hasStarted => DateTime.now().isAfter(startDate);

  bool get hasEnded => DateTime.now().isAfter(endDate);
}
