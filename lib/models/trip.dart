class Trip {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String heroEmoji;
  final String flagEmoji;
  final String? photoAsset;
  final String currency;

  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.heroEmoji = '✈️',
    this.flagEmoji = '🌍',
    this.photoAsset,
    this.currency = 'USD',
  });

  Duration get timeUntilStart => startDate.difference(DateTime.now());

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  bool get hasStarted => DateTime.now().isAfter(startDate);

  bool get hasEnded => DateTime.now().isAfter(endDate);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'destination': destination,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'heroEmoji': heroEmoji,
        'flagEmoji': flagEmoji,
        'photoAsset': photoAsset,
        'currency': currency,
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      heroEmoji: json['heroEmoji'] as String? ?? '✈️',
      flagEmoji: json['flagEmoji'] as String? ?? '🌍',
      photoAsset: json['photoAsset'] as String?,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}
