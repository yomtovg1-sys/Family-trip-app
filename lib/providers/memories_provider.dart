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

  void updateCaption(String id, String? caption) {
    final index = _photos.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final old = _photos[index];
    final updated = MemoryPhoto(
      id: old.id,
      tripId: old.tripId,
      bytes: old.bytes,
      fileName: old.fileName,
      caption: caption,
      takenAt: old.takenAt,
    );
    _photos[index] = updated;
    _store.put(updated);
    notifyListeners();
  }

  /// Moves the photo at [oldIndex] (within this trip's photo list) to
  /// [newIndex], persisting the family's manual drag-and-drop order.
  void reorderPhotos(String tripId, int oldIndex, int newIndex) {
    final tripPhotos = forTrip(tripId);
    if (oldIndex < 0 || oldIndex >= tripPhotos.length) return;
    final moved = tripPhotos.removeAt(oldIndex);
    tripPhotos.insert(newIndex.clamp(0, tripPhotos.length), moved);

    _photos.removeWhere((p) => p.tripId == tripId);
    _photos.addAll(tripPhotos);
    _store.replaceAll(_photos);
    notifyListeners();
  }
}
