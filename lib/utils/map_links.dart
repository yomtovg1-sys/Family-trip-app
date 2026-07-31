/// Deep links for handing a coordinate off to whichever map app the family
/// already has — every one of these is a plain URL, no API key and no paid
/// service involved. Each falls back gracefully to that provider's website
/// if the native app isn't installed.
String googleMapsUrl(double latitude, double longitude, {String? name}) {
  final query = name != null && name.trim().isNotEmpty ? Uri.encodeComponent('$name, $latitude,$longitude') : '$latitude,$longitude';
  return 'https://www.google.com/maps/search/?api=1&query=$query';
}

/// Apple's universal link format — works on iOS/macOS Safari (opens the
/// Maps app) and falls back to maps.apple.com everywhere else.
String appleMapsUrl(double latitude, double longitude, {String? name}) {
  final label = name != null && name.trim().isNotEmpty ? '&q=${Uri.encodeComponent(name)}' : '';
  return 'https://maps.apple.com/?ll=$latitude,$longitude$label';
}

/// Waze's universal link format. Opens the Waze app with turn-by-turn
/// navigation queued up if installed, otherwise opens waze.com.
String wazeUrl(double latitude, double longitude) {
  return 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes';
}
