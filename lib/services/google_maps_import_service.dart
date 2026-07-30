import '../models/google_maps_import.dart';
import '../models/place.dart';

/// Architecture seam for reading a traveler's saved places out of their
/// Google account. A real implementation would authenticate with Google
/// (OAuth) and call the Google Maps "saved places" / Takeout data, or a
/// scraped export, to list the traveler's lists and the places in them.
///
/// No real Google authentication is implemented yet; [MockGoogleMapsImportService]
/// returns realistic canned data so the whole Import flow — list picking,
/// progress, dedup, summary — is fully usable today.
abstract class GoogleMapsImportService {
  Future<List<GoogleMapsSavedList>> fetchLists();

  /// Fetches the places belonging to [listIds]. A null or empty [listIds]
  /// means "all saved places, across every list".
  Future<List<GoogleMapsImportCandidate>> fetchPlaces({List<String>? listIds});
}

class MockGoogleMapsImportService implements GoogleMapsImportService {
  const MockGoogleMapsImportService();

  static const _lists = [
    GoogleMapsSavedList(
      id: 'favorites',
      name: 'Favorites',
      type: GoogleMapsListType.favorites,
      placeCount: 5,
    ),
    GoogleMapsSavedList(
      id: 'want-to-go',
      name: 'Want to go',
      type: GoogleMapsListType.wantToGo,
      placeCount: 4,
    ),
    GoogleMapsSavedList(
      id: 'starred',
      name: 'Starred places',
      type: GoogleMapsListType.starred,
      placeCount: 2,
    ),
    GoogleMapsSavedList(
      id: 'tahoe-food',
      name: 'Tahoe Food Crawl',
      type: GoogleMapsListType.custom,
      placeCount: 3,
    ),
  ];

  @override
  Future<List<GoogleMapsSavedList>> fetchLists() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return _lists;
  }

  @override
  Future<List<GoogleMapsImportCandidate>> fetchPlaces({List<String>? listIds}) async {
    await Future.delayed(const Duration(milliseconds: 1600));
    final all = _allCandidates;
    if (listIds == null || listIds.isEmpty) return all;
    final selectedNames = {
      for (final list in _lists.where((l) => listIds.contains(l.id))) list.name,
    };
    return all.where((c) => selectedNames.contains(c.listName)).toList();
  }

  // Three of these intentionally match places already seeded in
  // PlacesProvider (same name + coordinates) so the dedup path in
  // PlacesProvider.importPlaces has something real to skip, and two are
  // missing coordinates so the "failed" path has something to report.
  static const _allCandidates = [
    GoogleMapsImportCandidate(
      name: 'El Dorado Beach',
      latitude: 38.9445,
      longitude: -119.9770,
      address: 'South Lake Tahoe, CA',
      category: PlaceCategory.nature,
      googleMapsUrl: 'https://maps.google.com/?q=38.9445,-119.9770',
      listName: 'Favorites',
    ),
    GoogleMapsImportCandidate(
      name: "Kalani's Lakefront",
      latitude: 38.9310,
      longitude: -119.9850,
      address: 'South Lake Tahoe, CA',
      category: PlaceCategory.restaurants,
      googleMapsUrl: 'https://maps.google.com/?q=38.9310,-119.9850',
      listName: 'Want to go',
    ),
    GoogleMapsImportCandidate(
      name: 'Tahoe City Marina',
      latitude: 39.1701,
      longitude: -120.1420,
      address: 'Tahoe City, CA',
      category: PlaceCategory.attractions,
      googleMapsUrl: 'https://maps.google.com/?q=39.1701,-120.1420',
      listName: 'Starred places',
    ),
    GoogleMapsImportCandidate(
      name: 'Fire Sign Cafe',
      latitude: 39.1750,
      longitude: -120.1380,
      address: 'Tahoe City, CA',
      category: PlaceCategory.cafes,
      googleMapsUrl: 'https://maps.google.com/?q=39.1750,-120.1380',
      listName: 'Tahoe Food Crawl',
    ),
    GoogleMapsImportCandidate(
      name: 'Van Sickle Bi-State Park',
      latitude: 38.9578,
      longitude: -119.9410,
      address: 'Stateline, NV',
      category: PlaceCategory.nature,
      googleMapsUrl: 'https://maps.google.com/?q=38.9578,-119.9410',
      listName: 'Want to go',
    ),
    GoogleMapsImportCandidate(
      name: 'The Shops at Heavenly Village',
      latitude: 38.9360,
      longitude: -119.9395,
      address: 'South Lake Tahoe, CA',
      category: PlaceCategory.shopping,
      googleMapsUrl: 'https://maps.google.com/?q=38.9360,-119.9395',
      listName: 'Favorites',
    ),
    GoogleMapsImportCandidate(
      name: 'Camp Richardson Corral',
      latitude: 38.9522,
      longitude: -120.0630,
      address: 'South Lake Tahoe, CA',
      category: PlaceCategory.attractions,
      googleMapsUrl: 'https://maps.google.com/?q=38.9522,-120.0630',
      listName: 'Starred places',
    ),
    GoogleMapsImportCandidate(
      name: 'Zephyr Cove Resort Parking',
      latitude: 39.0033,
      longitude: -119.9528,
      address: 'Zephyr Cove, NV',
      category: PlaceCategory.parking,
      googleMapsUrl: 'https://maps.google.com/?q=39.0033,-119.9528',
      listName: 'Tahoe Food Crawl',
    ),
    GoogleMapsImportCandidate(
      name: 'Sand Harbor Beach',
      latitude: 39.1985,
      longitude: -119.9294,
      address: 'Incline Village, NV',
      category: PlaceCategory.nature,
      googleMapsUrl: 'https://maps.google.com/?q=39.1985,-119.9294',
      listName: 'Favorites',
    ),
    GoogleMapsImportCandidate(
      name: 'Tahoe Pines Cabin',
      latitude: 39.0968,
      longitude: -120.0324,
      address: 'South Lake Tahoe, CA',
      category: PlaceCategory.hotels,
      googleMapsUrl: 'https://maps.google.com/?q=39.0968,-120.0324',
      listName: 'Want to go',
    ),
    GoogleMapsImportCandidate(
      name: 'Mystery Trailhead',
      category: PlaceCategory.nature,
      googleMapsUrl: 'https://maps.google.com/?q=Mystery+Trailhead+Tahoe',
      listName: 'Want to go',
    ),
    GoogleMapsImportCandidate(
      name: 'Random Overlook',
      category: PlaceCategory.other,
      googleMapsUrl: 'https://maps.google.com/?q=Random+Overlook+Tahoe',
      listName: 'Favorites',
    ),
    GoogleMapsImportCandidate(
      name: 'Kiva Beach',
      latitude: 38.9490,
      longitude: -120.0470,
      address: 'South Lake Tahoe, CA',
      category: PlaceCategory.nature,
      googleMapsUrl: 'https://maps.google.com/?q=38.9490,-120.0470',
      listName: 'Favorites',
    ),
    GoogleMapsImportCandidate(
      name: 'Cold Water Brewery',
      latitude: 38.9295,
      longitude: -119.9840,
      address: 'South Lake Tahoe, CA',
      category: PlaceCategory.restaurants,
      googleMapsUrl: 'https://maps.google.com/?q=38.9295,-119.9840',
      listName: 'Tahoe Food Crawl',
    ),
  ];
}
