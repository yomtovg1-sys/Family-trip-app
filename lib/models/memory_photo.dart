import 'dart:convert';
import 'dart:typed_data';

/// A single photo saved to a trip's Memories page. Order within a trip is
/// whatever [MemoriesProvider] currently stores it in — chronological by
/// [takenAt] to start, then whatever the family drags it to.
class MemoryPhoto {
  final String id;
  final String tripId;
  final Uint8List bytes;
  final String fileName;
  final String? caption;
  final DateTime takenAt;

  const MemoryPhoto({
    required this.id,
    required this.tripId,
    required this.bytes,
    required this.fileName,
    this.caption,
    required this.takenAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'bytesBase64': base64Encode(bytes),
        'fileName': fileName,
        'caption': caption,
        'takenAt': takenAt.toIso8601String(),
      };

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) {
    return MemoryPhoto(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      bytes: base64Decode(json['bytesBase64'] as String),
      fileName: json['fileName'] as String,
      caption: json['caption'] as String?,
      takenAt: DateTime.parse(json['takenAt'] as String),
    );
  }
}
