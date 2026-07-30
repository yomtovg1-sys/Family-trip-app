import 'package:flutter/material.dart';
import '../models/memory_photo.dart';
import '../services/hive_json_store.dart';
import '../utils/placeholder_bytes.dart';

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
    final photos = store.isEmpty ? _seedPhotos() : store.getAll();
    if (store.isEmpty) store.putAll(photos);
    return MemoriesProvider._(store, photos);
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

  static List<MemoryPhoto> _seedPhotos() {
    final now = DateTime.now();

    // Seeded already in chronological (takenAt ascending) order per trip.
    return [
      MemoryPhoto(
        id: 'ph1',
        tripId: 'trip-tahoe',
        bytes: placeholderImageBytes,
        fileName: 'planning-the-route.png',
        caption: 'Planning the route!',
        takenAt: now.subtract(const Duration(days: 5)),
      ),
      MemoryPhoto(
        id: 'ph2',
        tripId: 'trip-tahoe',
        bytes: placeholderImageBytes,
        fileName: 'new-hiking-boots.png',
        caption: 'New hiking boots arrived',
        takenAt: now.subtract(const Duration(days: 3)),
      ),
      MemoryPhoto(
        id: 'ph3',
        tripId: 'trip-tahoe',
        bytes: placeholderImageBytes,
        fileName: 'family-hike.png',
        caption: 'Family hike through the pines',
        takenAt: now.subtract(const Duration(days: 1)),
      ),
      MemoryPhoto(
        id: 'ph4',
        tripId: 'trip-tahoe',
        bytes: placeholderImageBytes,
        fileName: 'snack-break.png',
        caption: 'Snack break on the trail',
        takenAt: now,
      ),
      MemoryPhoto(
        id: 'ph6',
        tripId: 'trip-japan',
        bytes: placeholderImageBytes,
        fileName: 'booked-the-ryokan.png',
        caption: 'Booked the ryokan!',
        takenAt: now.subtract(const Duration(days: 45)),
      ),
      MemoryPhoto(
        id: 'ph5',
        tripId: 'trip-japan',
        bytes: placeholderImageBytes,
        fileName: 'japanese-phrases.png',
        caption: 'Learning basic Japanese phrases',
        takenAt: now.subtract(const Duration(days: 20)),
      ),
      MemoryPhoto(
        id: 'ph7',
        tripId: 'trip-italy',
        bytes: placeholderImageBytes,
        fileName: 'colosseum-sunset.png',
        caption: 'Colosseum at sunset',
        takenAt: now.subtract(const Duration(days: 200)),
      ),
      MemoryPhoto(
        id: 'ph8',
        tripId: 'trip-italy',
        bytes: placeholderImageBytes,
        fileName: 'best-gelato.png',
        caption: 'Best gelato in Florence',
        takenAt: now.subtract(const Duration(days: 197)),
      ),
      MemoryPhoto(
        id: 'ph9',
        tripId: 'trip-italy',
        bytes: placeholderImageBytes,
        fileName: 'venice-canals.png',
        caption: 'Venice canals by gondola',
        takenAt: now.subtract(const Duration(days: 193)),
      ),
    ];
  }
}
