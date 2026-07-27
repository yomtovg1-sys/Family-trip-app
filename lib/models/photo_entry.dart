class PhotoEntry {
  final String id;
  final String tripId;
  final String caption;
  final String takenBy;
  final DateTime date;
  final String emoji;
  final bool isFavorite;

  const PhotoEntry({
    required this.id,
    required this.tripId,
    required this.caption,
    required this.takenBy,
    required this.date,
    this.emoji = '📷',
    this.isFavorite = false,
  });
}
