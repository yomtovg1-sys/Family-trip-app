import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/place.dart';

/// The bottom sheet shown when a pin is tapped: name, category, area,
/// notes, and the Open in Google Maps / Edit / Favorite actions.
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: place.category.color.withValues(alpha: 0.16),
                  child: Text(place.category.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        place.category.label,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    place.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: place.isFavorite ? const Color(0xFFFFB300) : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggleFavorite,
                ),
              ],
            ),
            if (place.area.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(place.area, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            if (place.notes != null && place.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(place.notes!, style: theme.textTheme.bodyMedium),
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
    );
  }

  Future<void> _openInGoogleMaps(SavedPlace place) async {
    final uri = Uri.parse(place.googleMapsUrl ?? place.mapsSearchUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
