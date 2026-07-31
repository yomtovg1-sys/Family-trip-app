import 'memory_photo.dart';

/// One day's worth of [MemoryPhoto]s, grouped for display on the Memories
/// day list and for the day-by-day travel album — the single shape both
/// screens build from so the album always mirrors the day structure shown
/// on the Memories page.
class DayPhotos {
  final int dayIndex;
  final DateTime date;
  final List<MemoryPhoto> photos;

  const DayPhotos({required this.dayIndex, required this.date, required this.photos});

  MemoryPhoto? get cover => photos.isEmpty ? null : photos.first;
}
