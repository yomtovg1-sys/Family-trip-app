import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/map_pin.dart';
import '../../models/place.dart';
import '../../models/reservation.dart';
import '../../utils/map_links.dart';

/// The bottom sheet shown when any pin on the Map screen is tapped — a
/// place or a reservation alike, since both flow through [MapPin]. Shows
/// name, address, category, notes, and (for a reservation-backed pin) its
/// confirmation details, plus deep links to whichever map app the family
/// already has installed.
Future<void> showPinDetailSheet(
  BuildContext context, {
  required MapPin pin,
  required VoidCallback onEdit,
  VoidCallback? onToggleFavorite,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _PinDetailSheet(pin: pin, onEdit: onEdit, onToggleFavorite: onToggleFavorite),
  );
}

class _PinDetailSheet extends StatelessWidget {
  final MapPin pin;
  final VoidCallback onEdit;
  final VoidCallback? onToggleFavorite;

  const _PinDetailSheet({required this.pin, required this.onEdit, this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = pin.place;
    final reservation = pin.reservation;
    final categoryLabel = place?.category.label ?? reservation?.category.label ?? pin.layer.label;
    final notes = place?.notes ?? reservation?.notes;

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
                  backgroundColor: pin.color.withValues(alpha: 0.16),
                  child: Text(pin.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pin.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        categoryLabel,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (place != null && onToggleFavorite != null)
                  IconButton(
                    icon: Icon(
                      place.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: place.isFavorite ? const Color(0xFFFFB300) : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onToggleFavorite,
                  ),
              ],
            ),
            if (pin.subtitle.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Expanded(child: Text(pin.subtitle, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ],
            if (reservation != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    DateFormat('EEE, MMM d, yyyy · h:mm a').format(reservation.dateTime),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text('${reservation.provider} · ${reservation.confirmationNumber}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            if (notes != null && notes.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(notes, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(googleMapsUrl(pin.latitude, pin.longitude, name: pin.title)),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('Google'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(appleMapsUrl(pin.latitude, pin.longitude, name: pin.title)),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Apple'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(wazeUrl(pin.latitude, pin.longitude)),
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: const Text('Waze'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onEdit();
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
