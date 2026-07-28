import 'place.dart';

/// Fields recognized for a not-yet-saved place, produced by any capture
/// method (Google Maps search, a pasted Google Maps URL, a scanned
/// screenshot, a pasted website, or a Google Maps import) and used to
/// pre-fill the Add Place form so the traveler only has to confirm/correct
/// fields instead of typing everything from scratch.
class PlaceDraft {
  final String? name;
  final double? latitude;
  final double? longitude;
  final PlaceCategory? category;
  final String? area;
  final String? notes;
  final String? googleMapsUrl;
  final PlaceSource source;

  const PlaceDraft({
    this.name,
    this.latitude,
    this.longitude,
    this.category,
    this.area,
    this.notes,
    this.googleMapsUrl,
    this.source = PlaceSource.manual,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}
