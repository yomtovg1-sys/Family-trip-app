import 'place.dart';

/// The kind of Google Maps saved-places list a place can come from — mirrors
/// the lists Google Maps itself offers under "Saved".
enum GoogleMapsListType { favorites, wantToGo, starred, custom }

extension GoogleMapsListTypeX on GoogleMapsListType {
  String get emoji {
    switch (this) {
      case GoogleMapsListType.favorites:
        return '❤️';
      case GoogleMapsListType.wantToGo:
        return '🔖';
      case GoogleMapsListType.starred:
        return '⭐';
      case GoogleMapsListType.custom:
        return '📋';
    }
  }
}

/// One of the traveler's saved-places lists in their Google account, as
/// returned by [GoogleMapsImportService.fetchLists].
class GoogleMapsSavedList {
  final String id;
  final String name;
  final GoogleMapsListType type;
  final int placeCount;

  const GoogleMapsSavedList({
    required this.id,
    required this.name,
    required this.type,
    required this.placeCount,
  });
}

/// A single place read from the traveler's Google Maps account, before it's
/// been reconciled against places already saved in this trip.
class GoogleMapsImportCandidate {
  final String name;
  final double? latitude;
  final double? longitude;
  final String? address;
  final PlaceCategory? category;
  final String googleMapsUrl;
  final String? notes;
  final String listName;

  const GoogleMapsImportCandidate({
    required this.name,
    this.latitude,
    this.longitude,
    this.address,
    this.category,
    required this.googleMapsUrl,
    this.notes,
    required this.listName,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}

/// The outcome of running [PlacesProvider.importPlaces] over a batch of
/// [GoogleMapsImportCandidate]s: how many became new [SavedPlace]s, how many
/// were skipped as duplicates of places already saved, and how many
/// couldn't be imported at all (e.g. missing coordinates).
class GoogleMapsImportResult {
  final List<SavedPlace> imported;
  final int duplicatesSkipped;
  final int failed;

  const GoogleMapsImportResult({
    required this.imported,
    required this.duplicatesSkipped,
    required this.failed,
  });

  int get importedCount => imported.length;
}
