class PhotoEntry {
  final String id;
  final String caption;
  final String takenBy;
  final DateTime date;
  final String emoji;

  const PhotoEntry({
    required this.id,
    required this.caption,
    required this.takenBy,
    required this.date,
    this.emoji = '📷',
  });
}
