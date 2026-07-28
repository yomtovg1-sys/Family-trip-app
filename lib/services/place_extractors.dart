import 'dart:typed_data';
import '../models/place.dart';
import '../models/place_draft.dart';

/// Architecture seam for turning a free-text query into place candidates —
/// stands in for a real Google Places Autocomplete/Text Search call.
abstract class PlaceSearchService {
  Future<List<PlaceDraft>> search(String query);
}

class MockPlaceSearchService implements PlaceSearchService {
  const MockPlaceSearchService();

  @override
  Future<List<PlaceDraft>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    return [
      PlaceDraft(
        name: trimmed,
        latitude: 39.0968,
        longitude: -120.0324,
        category: PlaceCategory.attractions,
        area: 'South Lake Tahoe',
        googleMapsUrl:
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}',
        source: PlaceSource.googleSearch,
      ),
    ];
  }
}

/// Architecture seam for reading a screenshot of a Google Maps place card
/// (name, category, address) — stands in for a real OCR/vision pipeline.
abstract class PlaceScreenshotExtractor {
  Future<PlaceDraft> extract(Uint8List imageBytes);
}

class MockPlaceScreenshotExtractor implements PlaceScreenshotExtractor {
  const MockPlaceScreenshotExtractor();

  @override
  Future<PlaceDraft> extract(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return const PlaceDraft(
      name: 'Heavenly Village',
      category: PlaceCategory.shopping,
      area: 'South Lake Tahoe',
      latitude: 38.9357,
      longitude: -119.9400,
      source: PlaceSource.screenshot,
    );
  }
}

/// Architecture seam for reading a business/restaurant website and pulling
/// out its name and category — stands in for a real webpage-scraping +
/// LLM-extraction pipeline.
abstract class WebsitePlaceExtractor {
  Future<PlaceDraft> extract(String url);
}

class MockWebsitePlaceExtractor implements WebsitePlaceExtractor {
  const MockWebsitePlaceExtractor();

  @override
  Future<PlaceDraft> extract(String url) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final uri = Uri.tryParse(url);
    final host = uri?.host.replaceFirst('www.', '') ?? '';
    final guess = host.contains('.') ? host.substring(0, host.indexOf('.')) : host;
    final name = guess.isEmpty ? 'New Place' : _titleCase(guess);
    return PlaceDraft(name: name, category: PlaceCategory.restaurants, source: PlaceSource.website);
  }

  String _titleCase(String s) => s[0].toUpperCase() + s.substring(1);
}
