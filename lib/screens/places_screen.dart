import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../models/place_draft.dart';
import '../providers/places_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/places/simple_add_place_sheet.dart';
import 'add_place_screen.dart';
import 'pick_location_screen.dart';
import 'place_search_screen.dart';

/// The Places screen: a simple, organized list of everywhere the family
/// wants to go on this trip — not a fixed itinerary, just a tidy wishlist
/// grouped by city/area, searchable, and quick to add to from the map, a
/// search, or by hand.
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = context.watch<TripProvider>().current.trip;
    final places = context.watch<PlacesProvider>().forTrip(trip.id);

    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? places
        : places
            .where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.area.toLowerCase().contains(query) ||
                p.category.label.toLowerCase().contains(query))
            .toList();

    final groups = _groupByArea(filtered);
    final groupKeys = groups.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Places')),
      drawer: const AppDrawer(currentRoute: AppSection.placesRoute),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search places…',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: places.isEmpty
                ? const _EmptyState()
                : filtered.isEmpty
                    ? const _NoResultsState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: groupKeys.length,
                        itemBuilder: (context, groupIndex) {
                          final area = groupKeys[groupIndex];
                          final areaPlaces = groups[area]!;
                          return _AreaSection(
                            area: area,
                            places: areaPlaces,
                            baseDelayMs: groupIndex * 60,
                            onTapPlace: (place) => _editPlace(place),
                            onToggleFavorite: (place) =>
                                context.read<PlacesProvider>().toggleFavorite(place.id),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(trip.id),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Map<String, List<SavedPlace>> _groupByArea(List<SavedPlace> places) {
    final groups = <String, List<SavedPlace>>{};
    for (final place in places) {
      final key = place.area.trim().isEmpty ? 'Other' : place.area.trim();
      groups.putIfAbsent(key, () => []).add(place);
    }
    for (final list in groups.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return groups;
  }

  void _editPlace(SavedPlace place) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddPlaceScreen(editing: place)),
    );
  }

  void _showAddSheet(String tripId) {
    showSimpleAddPlaceSheet(
      context,
      onAddManually: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
      ),
      onSearch: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlaceSearchScreen()),
      ),
      onPickFromMap: () => _pickFromMap(tripId),
    );
  }

  Future<void> _pickFromMap(String tripId) async {
    final sim = context.read<PlacesProvider>().simulatedCurrentLocation(tripId);
    final anchor = sim != null ? LatLng(sim.latitude, sim.longitude) : const LatLng(39.0968, -120.0324);

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

class _AreaSection extends StatelessWidget {
  final String area;
  final List<SavedPlace> places;
  final int baseDelayMs;
  final ValueChanged<SavedPlace> onTapPlace;
  final ValueChanged<SavedPlace> onToggleFavorite;

  const _AreaSection({
    required this.area,
    required this.places,
    required this.baseDelayMs,
    required this.onTapPlace,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              Icon(Icons.place_rounded, size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 5),
              Text(
                area,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              Text(
                '${places.length}',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        for (var i = 0; i < places.length; i++)
          _Reveal(
            delay: Duration(milliseconds: baseDelayMs + i * 40),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlaceCard(
                place: places[i],
                onTap: () => onTapPlace(places[i]),
                onToggleFavorite: () => onToggleFavorite(places[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final SavedPlace place;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _PlaceCard({required this.place, required this.onTap, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: place.category.color.withValues(alpha: 0.16),
                child: Text(place.category.emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.category.label,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _FavoriteButton(isFavorite: place.isFavorite, onTap: onToggleFavorite),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              key: ValueKey(isFavorite),
              color: isFavorite ? const Color(0xFFFFB300) : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🗺️', style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 16),
            Text('No places saved yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Tap + to add somewhere you want to visit on this trip.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No places match your search',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Fades and slides its child in shortly after being built.
class _Reveal extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _Reveal({required this.child, this.delay = Duration.zero});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        child: widget.child,
      ),
    );
  }
}
