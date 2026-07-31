import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/memory_photo.dart';
import '../providers/memories_provider.dart';
import '../providers/trip_provider.dart';
import '../utils/trip_days.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/image_or_placeholder.dart';
import 'album_preview_screen.dart';
import 'day_album_screen.dart';

/// Each trip's Memories page: one card per day of the trip, so the family
/// can simply open today's day and upload today's pictures — no manual
/// organizing needed. "Create Travel Album" turns every day's photos into
/// a single printable album that keeps the day-by-day structure.
class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().current.trip;
    final counts = context.watch<MemoriesProvider>().countsByDay(trip.id);
    final todayIndex = currentTripDayIndex(trip);
    final hasAnyPhotos = counts.values.any((c) => c > 0);
    final dateFormat = DateFormat('EEE, MMM d');

    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      drawer: const AppDrawer(currentRoute: AppSection.photosRoute),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: _CreateAlbumButton(
              enabled: hasAnyPhotos,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AlbumPreviewScreen(tripId: trip.id)),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: trip.durationInDays,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, dayIndex) {
                final dayPhotos = context.watch<MemoriesProvider>().forDay(trip.id, dayIndex);
                return _DayCard(
                  dayIndex: dayIndex,
                  dateLabel: dateFormat.format(tripDayDate(trip, dayIndex)),
                  photoCount: counts[dayIndex] ?? 0,
                  cover: dayPhotos.isEmpty ? null : dayPhotos.first,
                  isToday: dayIndex == todayIndex,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DayAlbumScreen(tripId: trip.id, dayIndex: dayIndex)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int dayIndex;
  final String dateLabel;
  final int photoCount;
  final MemoryPhoto? cover;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCard({
    required this.dayIndex,
    required this.dateLabel,
    required this.photoCount,
    required this.cover,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = this.cover;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isToday ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isToday ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: cover != null
                      ? ImageOrPlaceholder(bytes: cover.bytes, icon: Icons.photo_rounded)
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          alignment: Alignment.center,
                          child: Icon(Icons.photo_camera_outlined, color: theme.colorScheme.onSurfaceVariant),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tripDayLabel(dayIndex),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Today',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      photoCount == 0 ? 'No photos yet' : '$photoCount photo${photoCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateAlbumButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _CreateAlbumButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: enabled
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Travel Album',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: enabled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      enabled ? 'Turn your daily photos into a printable album' : 'Add photos to create an album',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: (enabled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant)
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
