import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_photo.dart';
import '../providers/memories_provider.dart';
import '../providers/trip_provider.dart';
import '../services/memory_photo_picker.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_section.dart';
import '../widgets/memories/add_photos_sheet.dart';
import '../widgets/memories/edit_caption_sheet.dart';
import '../widgets/memories/reorderable_photo_grid.dart';
import 'album_preview_screen.dart';

/// Each trip's Memories page: upload photos, caption them, delete them,
/// drag to reorder — and turn them into a printable travel album.
class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = context.watch<TripProvider>().current.trip;
    final photos = context.watch<MemoriesProvider>().forTrip(trip.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      drawer: const AppDrawer(currentRoute: AppSection.photosRoute),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPhotos(context, trip.id),
        child: const Icon(Icons.add_a_photo_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: _CreateAlbumButton(
              enabled: photos.isNotEmpty,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AlbumPreviewScreen(tripId: trip.id)),
              ),
            ),
          ),
          Expanded(
            child: photos.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📷', style: TextStyle(fontSize: 44)),
                          const SizedBox(height: 16),
                          Text('No memories yet', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to upload your first photo from this trip.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReorderablePhotoGrid(
                    photos: photos,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    onReorder: (oldIndex, newIndex) =>
                        context.read<MemoriesProvider>().reorderPhotos(trip.id, oldIndex, newIndex),
                    onTapPhoto: (photo) => _editCaption(context, photo),
                    onDelete: (photo) => _confirmDelete(context, photo),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPhotos(BuildContext context, String tripId) async {
    await showAddPhotosSheet(
      context,
      onChooseFromLibrary: () async {
        final photos = await pickMemoryPhotosFromLibrary(tripId);
        if (photos.isNotEmpty && context.mounted) {
          context.read<MemoriesProvider>().addPhotos(photos);
        }
      },
      onTakePhoto: () async {
        final photo = await pickMemoryPhotoFromCamera(tripId);
        if (photo != null && context.mounted) {
          context.read<MemoriesProvider>().addPhotos([photo]);
        }
      },
    );
  }

  Future<void> _editCaption(BuildContext context, MemoryPhoto photo) async {
    final caption = await showEditCaptionSheet(context, initialCaption: photo.caption);
    if (caption != null && context.mounted) {
      context.read<MemoriesProvider>().updateCaption(photo.id, caption.isEmpty ? null : caption);
    }
  }

  Future<void> _confirmDelete(BuildContext context, MemoryPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This photo will be removed from your Memories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<MemoriesProvider>().deletePhoto(photo.id);
    }
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
              const Text('📖', style: TextStyle(fontSize: 24)),
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
                      enabled ? 'Turn your photos into a printable album' : 'Add photos to create an album',
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
