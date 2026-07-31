import 'package:flutter/material.dart';
import '../models/memory_photo.dart';
import '../services/hive_json_store.dart';

/// Photos saved to each trip's Memories page. Order is stored per-trip:
/// seeded chronologically, then whatever the family reorders it to by drag
/// and drop — this provider doesn't re-sort behind their back.
class MemoriesProvider extends ChangeNotifier {
  final HiveJsonStore<MemoryPhoto> _store;
  final List<MemoryPhoto> _photos;

  MemoriesProvider._(this._store, this._photos);

  static Future<MemoriesProvider> open() async {
    final store = await HiveJsonStore.open<MemoryPhoto>(
      'memories',
      toJson: (p) => p.toJson(),
      fromJson: MemoryPhoto.fromJson,
      idOf: (p) => p.id,
    );
    return MemoriesProvider._(store, store.getAll());
  }

  List<MemoryPhoto> forTrip(String tripId) => _photos.where((p) => p.tripId == tripId).toList();

  List<MemoryPhoto> forDay(String tripId, int dayIndex) =>
      _photos.where((p) => p.tripId == tripId && p.dayIndex == dayIndex).toList();

  /// Photo count per day index, for the Memories day list — days with no
  /// photos simply have no entry.
  Map<int, int> countsByDay(String tripId) {
    final counts = <int, int>{};
    for (final p in _photos) {
      if (p.tripId != tripId) continue;
      counts[p.dayIndex] = (counts[p.dayIndex] ?? 0) + 1;
    }
    return counts;
  }

  void addPhotos(List<MemoryPhoto> photos) {
    _photos.addAll(photos);
    _store.putAll(photos);
    notifyListeners();
  }

  void deletePhoto(String id) {
    _photos.removeWhere((p) => p.id == id);
    _store.remove(id);
    notifyListeners();
  }

  /// Replaces every photo for [tripId] with [photos] — used to apply a
  /// backup restore or import.
  void replaceForTrip(String tripId, List<MemoryPhoto> photos) {
    _photos.removeWhere((p) => p.tripId == tripId);
    _photos.addAll(photos);
    _store.replaceAll(_photos);
    notifyListeners();
  }

  /// Moves the photo at [oldIndex] (within this day's photo list) to
  /// [newIndex], persisting the family's manual drag-and-drop order. The
  /// photo that ends up first is that day's cover.
  void reorderWithinDay(String tripId, int dayIndex, int oldIndex, int newIndex) {
    final dayPhotos = forDay(tripId, dayIndex);
    if (oldIndex < 0 || oldIndex >= dayPhotos.length) return;
    final moved = dayPhotos.removeAt(oldIndex);
    dayPhotos.insert(newIndex.clamp(0, dayPhotos.length), moved);

    _photos.removeWhere((p) => p.tripId == tripId && p.dayIndex == dayIndex);
    _photos.addAll(dayPhotos);
    _store.replaceAll(_photos);
    notifyListeners();
  }

  /// Promotes [photoId] to the front of its day, making it that day's
  /// cover. A no-op if it's already the cover.
  void setCoverPhoto(String tripId, int dayIndex, String photoId) {
    final dayPhotos = forDay(tripId, dayIndex);
    final index = dayPhotos.indexWhere((p) => p.id == photoId);
    if (index <= 0) return;
    reorderWithinDay(tripId, dayIndex, index, 0);
  }
}
