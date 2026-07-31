import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../emoji_text.dart';

/// A horizontal strip of saved places close to the traveler's current
/// location, shown as a floating panel over the bottom of the map.
class NearbyPlacesPanel extends StatelessWidget {
  final List<SavedPlace> places;
  final double Function(SavedPlace place) distanceKmFor;
  final ValueChanged<SavedPlace> onTapPlace;

  const NearbyPlacesPanel({
    super.key,
    required this.places,
    required this.distanceKmFor,
    required this.onTapPlace,
  });

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me_rounded, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text('Nearby Saved Places', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final place = places[index];
                return _NearbyCard(
                  place: place,
                  distanceKm: distanceKmFor(place),
                  onTap: () => onTapPlace(place),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  final SavedPlace place;
  final double distanceKm;
  final VoidCallback onTap;

  const _NearbyCard({required this.place, required this.distanceKm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceLabel =
        distanceKm < 1 ? '${(distanceKm * 1000).round()} m' : '${distanceKm.toStringAsFixed(1)} km';

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EmojiText(place.category.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                distanceLabel,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
