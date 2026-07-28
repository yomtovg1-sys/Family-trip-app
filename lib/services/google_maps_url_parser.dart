import '../models/place.dart';
import '../models/place_draft.dart';

final RegExp _atCoordsPattern = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
final RegExp _placeNamePattern = RegExp(r'/place/([^/]+)/');
final RegExp _plainCoordsPattern = RegExp(r'^(-?\d+\.\d+),\s*(-?\d+\.\d+)$');

/// Parses coordinates (and a best-effort name) out of a pasted Google Maps
/// URL. Unlike the other capture methods, this is plain string parsing —
/// no network call, no API key needed — so it works for real today instead
/// of being an architecture stub.
///
/// Returns null if the text isn't a Google Maps link, or doesn't carry a
/// coordinate we can extract (e.g. a shortened maps.app.goo.gl link only
/// resolves via a network request, which this function deliberately
/// doesn't make).
PlaceDraft? parseGoogleMapsUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;

  Uri? uri;
  try {
    uri = Uri.parse(trimmed);
  } catch (_) {
    return null;
  }
  final host = uri.host.toLowerCase();
  if (!host.contains('google') && !host.contains('goo.gl')) return null;

  double? lat;
  double? lng;
  String? name;

  final atMatch = _atCoordsPattern.firstMatch(trimmed);
  if (atMatch != null) {
    lat = double.tryParse(atMatch.group(1)!);
    lng = double.tryParse(atMatch.group(2)!);
  }

  final qParam = uri.queryParameters['q'];
  if (qParam != null) {
    final qMatch = _plainCoordsPattern.firstMatch(qParam.trim());
    if (qMatch != null) {
      lat ??= double.tryParse(qMatch.group(1)!);
      lng ??= double.tryParse(qMatch.group(2)!);
    } else {
      name ??= qParam;
    }
  }

  final placeMatch = _placeNamePattern.firstMatch(trimmed);
  if (placeMatch != null) {
    name = Uri.decodeComponent(placeMatch.group(1)!.replaceAll('+', ' '));
  }

  if (lat == null || lng == null) return null;

  return PlaceDraft(
    name: name,
    latitude: lat,
    longitude: lng,
    googleMapsUrl: trimmed,
    source: PlaceSource.googleMapsUrl,
  );
}
