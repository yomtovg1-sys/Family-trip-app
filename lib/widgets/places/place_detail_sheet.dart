import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/place.dart';
import 'star_rating.dart';

/// The bottom sheet shown when a pin is tapped: photo, name, category,
/// area, notes, and the Open in Google Maps / Edit / Favorite actions.
Future<void> showPlaceDetailSheet(
  BuildContext context, {
  required SavedPlace place,
  required VoidCallback onEdit,
  required VoidCallback onToggleFavorite,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _PlaceDetailSheet(
      place: place,
      onEdit: onEdit,
      onToggleFavorite: onToggleFavorite,
    ),
  );
}

class _PlaceDetailSheet extends StatelessWidget {
  final SavedPlace place;
  final VoidCallback onEdit;
  final VoidCallback onToggleFavorite;

  const _PlaceDetailSheet({
    required this.place,
    required this.onEdit,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Photo(place: place),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(place.name, style: theme.textTheme.titleLarge),
                        ),
                        IconButton(
                          icon: Icon(
                            place.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: place.isFavorite ? const Color(0xFFE53935) : theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: onToggleFavorite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CategoryPill(category: place.category),
                        if (place.area.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place_outlined, size: 15, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(place.area, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        StarRating(value: place.priority, size: 15),
                      ],
                    ),
                    if (place.notes != null && place.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(place.notes!, style: theme.textTheme.bodyMedium),
                    ],
                    if (place.estimatedDuration != null || place.estimatedCost != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (place.estimatedDuration != null) ...[
                            Icon(Icons.schedule_rounded, size: 15, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(_formatDuration(place.estimatedDuration!), style: theme.textTheme.bodySmall),
                            const SizedBox(width: 16),
                          ],
                          if (place.estimatedCost != null) ...[
                            Icon(Icons.payments_outlined, size: 15, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('~\$${place.estimatedCost!.toStringAsFixed(0)}', style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _openInGoogleMaps(place),
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: const Text('Open in Google Maps'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onEdit();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps(SavedPlace place) async {
    final uri = Uri.parse(place.googleMapsUrl ?? place.mapsSearchUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final minutes = d.inMinutes % 60;
      return minutes == 0 ? '${d.inHours}h' : '${d.inHours}h ${minutes}m';
    }
    return '${d.inMinutes}m';
  }
}

class _Photo extends StatelessWidget {
  final SavedPlace place;

  const _Photo({required this.place});

  @override
  Widget build(BuildContext context) {
    final photoUrl = place.photoUrl;

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: photoUrl != null
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _PhotoPlaceholder(place: place),
            )
          : _PhotoPlaceholder(place: place),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final SavedPlace place;

  const _PhotoPlaceholder({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [place.category.color.withValues(alpha: 0.55), place.category.color.withValues(alpha: 0.25)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(place.category.emoji, style: const TextStyle(fontSize: 48)),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final PlaceCategory category;

  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: theme.textTheme.labelSmall?.copyWith(color: category.color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
