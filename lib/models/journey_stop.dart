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

  Map<String, dynamic> toJson() => {
        'location': location,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  factory JourneyStop.fromJson(Map<String, dynamic> json) {
    return JourneyStop(
      location: json['location'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }
}
