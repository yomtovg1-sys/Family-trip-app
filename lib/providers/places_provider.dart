import 'package:flutter/material.dart';
import '../models/google_maps_import.dart';
import '../models/place.dart';
import '../utils/geo.dart';

/// Places the family has saved for the trip — restaurants to try, viewpoints,
/// hotels, parking — grouped and filtered on the Map/Places screen. This is
/// a planning list, not a navigation layer.
class PlacesProvider extends ChangeNotifier {
  final List<SavedPlace> _places = _seedPlaces();

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
    notifyListeners();
  }

  void updatePlace(SavedPlace updated) {
    final index = _places.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _places[index] = updated;
      notifyListeners();
    }
  }

  void deletePlace(String id) {
    _places.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Replaces every saved place for [tripId] with [places] — used to apply a
  /// backup restore or import, which always carries a trip's full list
  /// rather than incremental changes.
  void replaceForTrip(String tripId, List<SavedPlace> places) {
    _places.removeWhere((p) => p.tripId == tripId);
    _places.addAll(places);
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
    if (imported.isNotEmpty) notifyListeners();

    return GoogleMapsImportResult(imported: imported, duplicatesSkipped: duplicates, failed: failed);
  }

  static List<SavedPlace> _seedPlaces() {
    return [
      // --- Lake Tahoe ---
      const SavedPlace(
        id: 'place-t1',
        tripId: 'trip-tahoe',
        name: 'Sand Harbor Beach',
        latitude: 39.1985,
        longitude: -119.9294,
        category: PlaceCategory.nature,
        area: 'Incline Village, NV',
        notes: 'Calm, clear water — great for the kids.',
        isFavorite: true,
      ),
      const SavedPlace(
        id: 'place-t2',
        tripId: 'trip-tahoe',
        name: 'Eagle Falls Trailhead',
        latitude: 38.9987,
        longitude: -120.1188,
        category: PlaceCategory.nature,
        area: 'Emerald Bay, CA',
        notes: 'Moderate hike, stunning overlook.',
      ),
      const SavedPlace(
        id: 'place-t3',
        tripId: 'trip-tahoe',
        name: 'Heavenly Village',
        latitude: 38.9357,
        longitude: -119.9400,
        category: PlaceCategory.shopping,
        area: 'South Lake Tahoe, CA',
      ),
      const SavedPlace(
        id: 'place-t4',
        tripId: 'trip-tahoe',
        name: 'Sunset Grill',
        latitude: 38.9330,
        longitude: -119.9820,
        category: PlaceCategory.restaurants,
        area: 'South Lake Tahoe, CA',
        notes: 'Lake view patio — book ahead for sunset.',
        isFavorite: true,
      ),
      const SavedPlace(
        id: 'place-t5',
        tripId: 'trip-tahoe',
        name: 'Tahoe Roasting Co.',
        latitude: 38.9345,
        longitude: -119.9765,
        category: PlaceCategory.cafes,
        area: 'South Lake Tahoe, CA',
      ),
      const SavedPlace(
        id: 'place-t6',
        tripId: 'trip-tahoe',
        name: 'Tahoe Pines Cabin',
        latitude: 39.0968,
        longitude: -120.0324,
        category: PlaceCategory.hotels,
        area: 'South Lake Tahoe, CA',
        notes: 'Our home base for the week.',
        isFavorite: true,
      ),
      const SavedPlace(
        id: 'place-t7',
        tripId: 'trip-tahoe',
        name: 'Emerald Bay State Park',
        latitude: 38.9587,
        longitude: -120.1073,
        category: PlaceCategory.nature,
        area: 'Emerald Bay, CA',
        notes: 'Best photo spot on the whole lake.',
        isFavorite: true,
      ),
      const SavedPlace(
        id: 'place-t8',
        tripId: 'trip-tahoe',
        name: 'Zephyr Cove Parking',
        latitude: 39.0033,
        longitude: -119.9528,
        category: PlaceCategory.parking,
        area: 'Zephyr Cove, NV',
      ),
      const SavedPlace(
        id: 'place-t9',
        tripId: 'trip-tahoe',
        name: 'Tahoe Adventure Co.',
        latitude: 39.1990,
        longitude: -119.9300,
        category: PlaceCategory.attractions,
        area: 'Incline Village, NV',
        notes: 'Kayak tours — booked for Thursday.',
      ),
      const SavedPlace(
        id: 'place-t10',
        tripId: 'trip-tahoe',
        name: 'Base Camp Pizza Co.',
        latitude: 38.9310,
        longitude: -119.9770,
        category: PlaceCategory.restaurants,
        area: 'South Lake Tahoe, CA',
        isFavorite: true,
      ),
      const SavedPlace(
        id: 'place-t11',
        tripId: 'trip-tahoe',
        name: 'Family Rest Stop',
        latitude: 39.0350,
        longitude: -119.8500,
        category: PlaceCategory.other,
        area: 'Along Hwy 50',
      ),

      // --- Japan ---
      const SavedPlace(
        id: 'place-j1',
        tripId: 'trip-japan',
        name: 'Shinjuku Gyoen',
        latitude: 35.6852,
        longitude: 139.7100,
        category: PlaceCategory.nature,
        area: 'Shinjuku, Tokyo',
        isFavorite: true,
      ),
      const SavedPlace(
        id: 'place-j2',
        tripId: 'trip-japan',
        name: 'teamLab Planets',
        latitude: 35.6455,
        longitude: 139.7930,
        category: PlaceCategory.attractions,
        area: 'Toyosu, Tokyo',
        notes: 'Wear shorts — some rooms involve wading through water.',
      ),
      const SavedPlace(
        id: 'place-j3',
        tripId: 'trip-japan',
        name: 'Ichiran Ramen Shinjuku',
        latitude: 35.6935,
        longitude: 139.7005,
        category: PlaceCategory.restaurants,
        area: 'Shinjuku, Tokyo',
      ),
      const SavedPlace(
        id: 'place-j4',
        tripId: 'trip-japan',
        name: 'Shinjuku Family Suites',
        latitude: 35.6938,
        longitude: 139.7034,
        category: PlaceCategory.hotels,
        area: 'Shinjuku, Tokyo',
        isFavorite: true,
      ),

      // --- Italy ---
      const SavedPlace(
        id: 'place-i1',
        tripId: 'trip-italy',
        name: 'Colosseum',
        latitude: 41.8902,
        longitude: 12.4922,
        category: PlaceCategory.attractions,
        area: 'Rome, Italy',
        isFavorite: true,
      ),
      const SavedPlace(
        id: 'place-i2',
        tripId: 'trip-italy',
        name: 'Hotel Artemide',
        latitude: 41.8992,
        longitude: 12.4853,
        category: PlaceCategory.hotels,
        area: 'Rome, Italy',
      ),
      const SavedPlace(
        id: 'place-i3',
        tripId: 'trip-italy',
        name: 'Trattoria da Enzo',
        latitude: 41.8896,
        longitude: 12.4694,
        category: PlaceCategory.restaurants,
        area: 'Trastevere, Rome',
      ),
    ];
  }
}
