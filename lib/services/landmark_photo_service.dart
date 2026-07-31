import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Looks up a real photo of a country's signature landmark from Wikipedia's
/// public REST API — free, keyless, and CORS-enabled for direct browser use.
/// Used to progressively enhance [DestinationCoverImage]'s illustrated
/// fallback with an actual "most familiar view" photo when the network is
/// available; every failure mode (offline, no matching article, no lead
/// image, slow response) resolves to `null` so the caller can keep showing
/// the illustration instead.
class LandmarkPhotoService {
  LandmarkPhotoService._();

  static final Map<String, String?> _cache = {};
  static final Map<String, Future<String?>> _inFlight = {};

  /// Resolves [landmarkQuery] (e.g. "Mount Fuji", "Machu Picchu") to a
  /// photo URL at roughly [width] pixels wide, or `null` if none was found.
  static Future<String?> fetchPhotoUrl(String landmarkQuery, {int width = 1200}) {
    final cached = _cache[landmarkQuery];
    if (_cache.containsKey(landmarkQuery)) return Future.value(cached);

    final pending = _inFlight[landmarkQuery];
    if (pending != null) return pending;

    final future = _fetch(landmarkQuery, width).then((url) {
      _cache[landmarkQuery] = url;
      _inFlight.remove(landmarkQuery);
      return url;
    });
    _inFlight[landmarkQuery] = future;
    return future;
  }

  static Future<String?> _fetch(String landmarkQuery, int width) async {
    try {
      final uri = Uri.https(
        'en.wikipedia.org',
        '/api/rest_v1/page/summary/${Uri.encodeComponent(landmarkQuery.replaceAll(' ', '_'))}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['type'] == 'disambiguation') return null;

      final original = body['originalimage'] as Map<String, dynamic>?;
      final thumbnail = body['thumbnail'] as Map<String, dynamic>?;
      final source = (original ?? thumbnail)?['source'] as String?;
      if (source == null) return null;

      return _atWidth(source, width);
    } catch (_) {
      return null;
    }
  }

  /// Wikimedia thumbnail URLs embed the requested width as a `/NNNpx-`
  /// path segment that its thumb handler will happily rescale to any
  /// width — rewriting it gets a better-fitting image than whatever size
  /// the summary endpoint defaulted to, without a second round trip.
  static String _atWidth(String source, int width) {
    final match = RegExp(r'/\d+px-').firstMatch(source);
    if (match == null) return source;
    return source.replaceRange(match.start, match.end, '/${width}px-');
  }
}
