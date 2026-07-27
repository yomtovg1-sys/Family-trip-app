class JourneyStop {
  final String location;
  final DateTime start;
  final DateTime end;

  const JourneyStop({
    required this.location,
    required this.start,
    required this.end,
  });

  bool isCurrentOn(DateTime now) => !now.isBefore(start) && !now.isAfter(end);
}
