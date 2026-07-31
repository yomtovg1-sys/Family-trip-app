import 'dart:convert';
import 'dart:typed_data';

/// A single photo saved to one day of a trip's Memories page. Order within
/// a day is whatever [MemoriesProvider] currently stores it in —
/// upload order to start, then whatever the family drags it to. The first
/// photo in that order is always the day's cover.
class MemoryPhoto {
  final String id;
  final String tripId;
  final int dayIndex;
  final Uint8List bytes;
  final String fileName;
  final DateTime takenAt;

  const MemoryPhoto({
    required this.id,
    required this.tripId,
    required this.dayIndex,
    required this.bytes,
    required this.fileName,
    required this.takenAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'dayIndex': dayIndex,
        'bytesBase64': base64Encode(bytes),
        'fileName': fileName,
        'takenAt': takenAt.toIso8601String(),
      };

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) {
    return MemoryPhoto(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      dayIndex: json['dayIndex'] as int? ?? 0,
      bytes: base64Decode(json['bytesBase64'] as String),
      fileName: json['fileName'] as String,
      takenAt: DateTime.parse(json['takenAt'] as String),
    );
  }
}
