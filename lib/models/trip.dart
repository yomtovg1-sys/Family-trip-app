import 'dart:convert';
import 'dart:typed_data';

class Trip {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String heroEmoji;
  final String flagEmoji;
  final String? country;
  final Uint8List? photoBytes;
  final String currency;
  final String timezone;

  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.heroEmoji = '✈️',
    this.flagEmoji = '🌍',
    this.country,
    this.photoBytes,
    this.currency = 'USD',
    this.timezone = 'UTC',
  });

  /// Returns a copy with the given fields replaced. [photoBytes] is
  /// distinguished from "unset" via [clearPhotoBytes], since null already
  /// means "use the auto cover" — passing null here alone would leave the
  /// existing photo untouched instead of clearing it.
  Trip copyWith({
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? heroEmoji,
    String? flagEmoji,
    String? country,
    Uint8List? photoBytes,
    bool clearPhotoBytes = false,
    String? currency,
    String? timezone,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      heroEmoji: heroEmoji ?? this.heroEmoji,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      country: country ?? this.country,
      photoBytes: clearPhotoBytes ? null : (photoBytes ?? this.photoBytes),
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
    );
  }

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
        'country': country,
        'photoBytesBase64': photoBytes == null ? null : base64Encode(photoBytes!),
        'currency': currency,
        'timezone': timezone,
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
      country: json['country'] as String?,
      photoBytes: json['photoBytesBase64'] == null ? null : base64Decode(json['photoBytesBase64'] as String),
      currency: json['currency'] as String? ?? 'USD',
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }
}
