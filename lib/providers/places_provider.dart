import 'package:flutter/material.dart';
import '../models/google_maps_import.dart';
import '../models/place.dart';
import '../services/hive_json_store.dart';
import '../utils/geo.dart';

/// Places the family has saved for the trip — restaurants to try, viewpoints,
/// hotels, parking — grouped and filtered on the Map/Places screen. This is
/// a planning list, not a navigation layer.
class PlacesProvider extends ChangeNotifier {
  final HiveJsonStore<SavedPlace> _store;
  final List<SavedPlace> _places;

  PlacesProvider._(this._store, this._places);

  static Future<PlacesProvider> open() async {
    final store = await HiveJsonStore.open<SavedPlace>(
      'places',
      toJson: (p) => p.toJson(),
      fromJson: SavedPlace.fromJson,
      idOf: (p) => p.id,
    );
    return PlacesProvider._(store, store.getAll());
  }

  List<SavedPlace> get all => List.unmodifiable(_places);

  List<SavedPlace> forTrip(String tripId) => _places.where((p) => p.tripId == tripId).toList();

  SavedPlace? byId(String id) {
    for (final p in _places) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addPlace(SavedPlace place) {
    _places.add(place);
    _store.put(place);
    notifyListeners();
  }

  void updatePlace(SavedPlace updated) {
    final index = _places.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _places[index] = updated;
      _store.put(updated);
      notifyListeners();
    }
  }

  void deletePlace(String id) {
    _places.removeWhere((p) => p.id == id);
    _store.remove(id);
    notifyListeners();
  }

  /// Replaces every saved place for [tripId] with [places] — used to apply a
  /// backup restore or import, which always carries a trip's full list
  /// rather than incremental changes.
  void replaceForTrip(String tripId, List<SavedPlace> places) {
    _places.removeWhere((p) => p.tripId == tripId);
    _places.addAll(places);
    _store.replaceAll(_places);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final place = byId(id);
    if (place != null) updatePlace(place.copyWith(isFavorite: !place.isFavorite));
  }

  /// A stand-in for the traveler's live device location during the trip —
  /// there's no real geolocation wired up yet, so "nearby" is simulated
  /// from the trip's lodging, which is realistically where the family
  /// spends most of their time. Swapping in a real GPS position later only
  /// means changing what's passed as `from` to [nearbyPlaces].
  ({double latitude, double longitude})? simulatedCurrentLocation(String tripId) {
    final places = forTrip(tripId);
    if (places.isEmpty) return null;
    for (final place in places) {
      if (place.category == PlaceCategory.hotels) {
        return (latitude: place.latitude, longitude: place.longitude);
      }
    }
    return (latitude: places.first.latitude, longitude: places.first.longitude);
  }

  /// Saved places within [radiusKm] of `from`, nearest first.
  List<SavedPlace> nearbyPlaces(
    String tripId, {
    required ({double latitude, double longitude}) from,
    double radiusKm = 15,
    int limit = 8,
  }) {
    final withDistance = forTrip(tripId)
        .map((p) => (place: p, distanceKm: haversineKm(from.latitude, from.longitude, p.latitude, p.longitude)))
        .where((e) => e.distanceKm <= radiusKm)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return withDistance.take(limit).map((e) => e.place).toList();
  }

  double distanceKmFrom(({double latitude, double longitude}) from, SavedPlace place) =>
      haversineKm(from.latitude, from.longitude, place.latitude, place.longitude);

  /// Imports a batch of Google Maps candidates into [tripId], skipping ones
  /// that look like places already saved (same name, or within ~50m of an
  /// existing place) and ones missing coordinates.
  GoogleMapsImportResult importPlaces(String tripId, List<GoogleMapsImportCandidate> candidates) {
    final existing = forTrip(tripId);
    final imported = <SavedPlace>[];
    var duplicates = 0;
    var failed = 0;

    for (final candidate in candidates) {
      if (!candidate.hasCoordinates) {
        failed++;
        continue;
      }
      final isDuplicate = existing.any((p) {
        final sameName = p.name.trim().toLowerCase() == candidate.name.trim().toLowerCase();
        final closeBy = haversineKm(p.latitude, p.longitude, candidate.latitude!, candidate.longitude!) < 0.05;
        return sameName || closeBy;
      });
      if (isDuplicate) {
        duplicates++;
        continue;
      }

      final place = SavedPlace(
        id: 'place-${DateTime.now().microsecondsSinceEpoch}-${imported.length}',
        tripId: tripId,
        name: candidate.name,
        latitude: candidate.latitude!,
        longitude: candidate.longitude!,
        category: candidate.category ?? PlaceCategory.other,
        area: candidate.address ?? '',
        notes: candidate.notes,
        googleMapsUrl: candidate.googleMapsUrl,
        source: PlaceSource.googleImport,
      );
      imported.add(place);
      existing.add(place);
    }

    _places.addAll(imported);
    if (imported.isNotEmpty) {
      _store.putAll(imported);
      notifyListeners();
    }

    return GoogleMapsImportResult(imported: imported, duplicatesSkipped: duplicates, failed: failed);
  }
}
