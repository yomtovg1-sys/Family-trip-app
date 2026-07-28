import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/places_provider.dart';
import '../providers/trip_provider.dart';
import '../services/google_maps_url_parser.dart';
import '../services/place_extractors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/documents/add_document_sheet.dart';
import '../widgets/places/add_place_sheet.dart';
import '../widgets/places/nearby_places_panel.dart';
import '../widgets/places/place_detail_sheet.dart';
import '../widgets/places/place_filter_chips.dart';
import 'add_place_screen.dart';
import 'import_google_maps_screen.dart';
import 'paste_link_screen.dart';
import 'place_search_screen.dart';

/// The Map / Places screen — a visual planner for every place the family
/// has saved for this trip, not a turn-by-turn navigation screen.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  PlaceFilter _filter = PlaceFilter.all;

  void _fitToPlaces(List<SavedPlace> places) {
    if (places.isEmpty) return;
    if (places.length == 1) {
      _mapController.move(LatLng(places.first.latitude, places.first.longitude), 13);
      return;
    }
    final bounds = LatLngBounds.fromPoints([
      for (final p in places) LatLng(p.latitude, p.longitude),
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.fromLTRB(40, 110, 40, 170)),
    );
  }

  void _onFilterSelected(PlaceFilter filter, String tripId) {
    final newFiltered = context.read<PlacesProvider>().forTrip(tripId).where(filter.matches).toList();
    setState(() => _filter = filter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToPlaces(newFiltered));
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().current.trip;
    final placesProvider = context.watch<PlacesProvider>();
    final allPlaces = placesProvider.forTrip(trip.id);
    final filtered = allPlaces.where(_filter.matches).toList();

    final currentLocation = placesProvider.simulatedCurrentLocation(trip.id);
    final nearby = currentLocation == null
        ? <SavedPlace>[]
        : placesProvider.nearbyPlaces(trip.id, from: currentLocation);

    final fallbackCenter = currentLocation != null
        ? LatLng(currentLocation.latitude, currentLocation.longitude)
        : const LatLng(39.0968, -120.0324);

    return Scaffold(
      appBar: AppBar(title: const Text('Map & Places')),
      drawer: const AppDrawer(currentRoute: AppSection.mapRoute),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: fallbackCenter,
              initialZoom: 12,
              onMapReady: () => _fitToPlaces(filtered),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.familytrip.family_trip_app',
              ),
              MarkerLayer(
                markers: [
                  for (final place in filtered)
                    Marker(
                      point: LatLng(place.latitude, place.longitude),
                      width: 42,
                      height: 42,
                      child: GestureDetector(
                        onTap: () => _openPlaceDetail(place),
                        child: _PlacePin(place: place),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: PlaceFilterChips(
              selected: _filter,
              onSelected: (f) => _onFilterSelected(f, trip.id),
            ),
          ),
          if (nearby.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: NearbyPlacesPanel(
                places: nearby,
                distanceKmFor: (p) => placesProvider.distanceKmFrom(currentLocation!, p),
                onTapPlace: _openPlaceDetail,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlace(trip.id),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openPlaceDetail(SavedPlace place) {
    showPlaceDetailSheet(
      context,
      place: place,
      onEdit: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddPlaceScreen(editing: place)),
      ),
      onToggleFavorite: () => context.read<PlacesProvider>().toggleFavorite(place.id),
    );
  }

  void _showAddPlace(String tripId) {
    showAddPlaceSheet(
      context,
      onSearch: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlaceSearchScreen()),
      ),
      onPasteUrl: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PasteLinkScreen(
            title: 'Paste Google Maps URL',
            hint: 'https://www.google.com/maps/place/...',
            helperText: "Share a place from the Google Maps app and paste the link here — "
                "we'll pull out its coordinates.",
            notFoundMessage: "Couldn't find coordinates in that link. Try Manual entry instead.",
            onParse: (link) async => parseGoogleMapsUrl(link),
          ),
        ),
      ),
      onScanScreenshot: () => showAddDocumentSheet(
        context,
        onPicked: (documents) async {
          if (documents.isEmpty || !mounted) return;
          const extractor = MockPlaceScreenshotExtractor();
          final draft = await extractor.extract(documents.first.bytes);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddPlaceScreen(draft: draft)),
          );
        },
      ),
      onPasteWebsite: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PasteLinkScreen(
            title: 'Paste Website',
            hint: 'https://example-restaurant.com',
            helperText: "Paste a restaurant, hotel, or attraction's website and we'll pull out its name.",
            notFoundMessage: "Couldn't read that website.",
            onParse: (link) => const MockWebsitePlaceExtractor().extract(link),
          ),
        ),
      ),
      onManualEntry: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
      ),
      onImportFromGoogleMaps: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ImportGoogleMapsScreen(tripId: tripId)),
      ),
    );
  }
}

class _PlacePin extends StatelessWidget {
  final SavedPlace place;

  const _PlacePin({required this.place});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: place.category.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(place.category.emoji, style: const TextStyle(fontSize: 15)),
        ),
        if (place.isFavorite)
          const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFE53935)),
      ],
    );
  }
}
