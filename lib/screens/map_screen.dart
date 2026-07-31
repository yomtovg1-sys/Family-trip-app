import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/map_pin.dart';
import '../models/place.dart';
import '../models/place_draft.dart';
import '../providers/places_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';
import '../services/google_maps_url_parser.dart';
import '../services/place_extractors.dart';
import '../utils/country_coordinates.dart';
import '../utils/world_countries.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/documents/add_document_sheet.dart';
import '../widgets/map/map_layer_chips.dart';
import '../widgets/map/pin_detail_sheet.dart';
import '../widgets/places/add_place_sheet.dart';
import '../widgets/places/nearby_places_panel.dart';
import 'add_place_screen.dart';
import 'add_reservation_screen.dart';
import 'import_google_maps_screen.dart';
import 'paste_link_screen.dart';
import 'pick_location_screen.dart';
import 'place_search_screen.dart';

/// The Map screen — a smart layer on top of OpenStreetMap (no paid map or
/// places service involved). Every trip item with coordinates — saved
/// places and reservations the family has pinned — is always drawn as a
/// pin, grouped into toggleable layers, and centered on the active trip's
/// country the moment the screen opens.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Set<MapLayer> _enabledLayers = MapLayer.values.toSet();
  bool _initialFitDone = false;

  void _fitToPins(List<MapPin> pins, {required LatLng fallbackCenter, required double fallbackZoom}) {
    if (pins.isEmpty) {
      _mapController.move(fallbackCenter, fallbackZoom);
      return;
    }
    if (pins.length == 1) {
      _mapController.move(LatLng(pins.first.latitude, pins.first.longitude), 13);
      return;
    }
    final bounds = LatLngBounds.fromPoints([
      for (final pin in pins) LatLng(pin.latitude, pin.longitude),
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.fromLTRB(40, 110, 40, 170)),
    );
  }

  void _toggleLayer(MapLayer layer, List<MapPin> allPins, LatLng fallbackCenter, double fallbackZoom) {
    setState(() {
      if (_enabledLayers.contains(layer)) {
        _enabledLayers = {..._enabledLayers}..remove(layer);
      } else {
        _enabledLayers = {..._enabledLayers, layer};
      }
    });
    final visible = allPins.where((p) => _enabledLayers.contains(p.layer)).toList();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fitToPins(visible, fallbackCenter: fallbackCenter, fallbackZoom: fallbackZoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().current.trip;
    final placesProvider = context.watch<PlacesProvider>();
    final reservationsProvider = context.watch<ReservationsProvider>();

    final places = placesProvider.forTrip(trip.id);
    final locatedReservations = reservationsProvider.forTrip(trip.id).where((r) => r.hasCoordinates);

    final allPins = [
      for (final place in places) MapPin.fromPlace(place),
      for (final reservation in locatedReservations) MapPin.fromReservation(reservation),
    ];
    final visiblePins = allPins.where((pin) => _enabledLayers.contains(pin.layer)).toList();

    // Centers on the active trip's country the moment the screen opens —
    // never a hardcoded place. If the trip has real pins, fitting to their
    // bounds (below) takes over as soon as the map is ready.
    final countryCenter = capitalCoordinatesFor(countryByName(trip.country)?.iso2 ?? '');
    final fallbackCenter = countryCenter ?? const LatLng(20, 0);
    final fallbackZoom = countryCenter != null ? 6.0 : 2.0;

    final currentLocation = placesProvider.simulatedCurrentLocation(trip.id);
    final nearby = currentLocation == null
        ? <SavedPlace>[]
        : placesProvider.nearbyPlaces(trip.id, from: currentLocation);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search trip items',
            onPressed: () => _openSearch(allPins),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppSection.mapRoute),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: fallbackCenter,
              initialZoom: fallbackZoom,
              onMapReady: () {
                if (_initialFitDone) return;
                _initialFitDone = true;
                _fitToPins(visiblePins, fallbackCenter: fallbackCenter, fallbackZoom: fallbackZoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.familytrip.family_trip_app',
              ),
              MarkerLayer(
                markers: [
                  for (final pin in visiblePins)
                    Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 42,
                      height: 42,
                      child: GestureDetector(
                        onTap: () => _openPinDetail(pin),
                        child: _MapPinMarker(pin: pin),
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
            child: MapLayerChips(
              enabled: _enabledLayers,
              onToggle: (layer) => _toggleLayer(layer, allPins, fallbackCenter, fallbackZoom),
            ),
          ),
          if (allPins.isEmpty)
            Positioned(
              left: 32,
              right: 32,
              top: 90,
              child: _MapEmptyState(onAddPlace: () => _showAddPlace(trip.id)),
            ),
          if (nearby.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: NearbyPlacesPanel(
                places: nearby,
                distanceKmFor: (p) => placesProvider.distanceKmFrom(currentLocation!, p),
                onTapPlace: (place) => _openPinDetail(MapPin.fromPlace(place)),
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

  void _openPinDetail(MapPin pin) {
    showPinDetailSheet(
      context,
      pin: pin,
      onEdit: () {
        final place = pin.place;
        final reservation = pin.reservation;
        if (place != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddPlaceScreen(editing: place)),
          );
        } else if (reservation != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddReservationScreen(editing: reservation)),
          );
        }
      },
      onToggleFavorite:
          pin.place != null ? () => context.read<PlacesProvider>().toggleFavorite(pin.place!.id) : null,
    );
  }

  Future<void> _openSearch(List<MapPin> allPins) async {
    final result = await showModalBottomSheet<MapPin>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TripItemSearchSheet(pins: allPins),
    );
    if (result == null || !mounted) return;
    _mapController.move(LatLng(result.latitude, result.longitude), 15);
    _openPinDetail(result);
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
      onPickFromMap: () => _pickFromMap(tripId),
      onImportFromGoogleMaps: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ImportGoogleMapsScreen(tripId: tripId)),
      ),
    );
  }

  Future<void> _pickFromMap(String tripId) async {
    final sim = context.read<PlacesProvider>().simulatedCurrentLocation(tripId);
    final trip = context.read<TripProvider>().current.trip;
    final anchor = sim != null
        ? LatLng(sim.latitude, sim.longitude)
        : capitalCoordinatesFor(countryByName(trip.country)?.iso2 ?? '') ?? const LatLng(20, 0);

    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => PickLocationScreen(initialCenter: anchor)),
    );
    if (picked == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPlaceScreen(
          draft: PlaceDraft(latitude: picked.latitude, longitude: picked.longitude),
        ),
      ),
    );
  }
}

/// A full-screen search restricted to this trip's own items — places and
/// pinned reservations — never a general geocoder. A free OSM/Nominatim
/// place search could be layered in later without changing this sheet's
/// shape, just what feeds its result list.
class _TripItemSearchSheet extends StatefulWidget {
  final List<MapPin> pins;

  const _TripItemSearchSheet({required this.pins});

  @override
  State<_TripItemSearchSheet> createState() => _TripItemSearchSheetState();
}

class _TripItemSearchSheetState extends State<_TripItemSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? widget.pins
        : widget.pins.where((p) => p.title.toLowerCase().contains(query) || p.subtitle.toLowerCase().contains(query)).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text('Search this trip', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Hotels, reservations, saved places…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          widget.pins.isEmpty ? 'Nothing on the map yet for this trip.' : 'No matches.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final pin = results[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: pin.color.withValues(alpha: 0.16),
                              child: Text(pin.emoji, style: const TextStyle(fontSize: 18)),
                            ),
                            title: Text(pin.title),
                            subtitle: Text(pin.subtitle.isEmpty ? pin.layer.label : pin.subtitle),
                            onTap: () => Navigator.of(context).pop(pin),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown over the map when the trip has no pinned items yet — the map
/// itself still renders (centered on the trip's country) so it doesn't
/// look broken, but this makes clear there's nothing to see yet.
class _MapEmptyState extends StatelessWidget {
  final VoidCallback onAddPlace;

  const _MapEmptyState({required this.onAddPlace});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onAddPlace,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗺️', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Text('No pinned items yet', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Tap here to add a place, or pin a reservation\'s location from its edit screen.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPinMarker extends StatelessWidget {
  final MapPin pin;

  const _MapPinMarker({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: pin.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(pin.emoji, style: const TextStyle(fontSize: 15)),
        ),
        if (pin.place?.isFavorite ?? false)
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
      ],
    );
  }
}
