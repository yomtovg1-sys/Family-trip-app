import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/memory_photo.dart';
import '../providers/memories_provider.dart';
import '../providers/trip_provider.dart';
import '../services/memory_photo_picker.dart';
import '../utils/trip_days.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/image_or_placeholder.dart';
import '../widgets/memories/add_photos_sheet.dart';
import '../widgets/memories/reorderable_photo_grid.dart';

/// One day of a trip's Memories: upload, delete, and reorder that day's
/// photos, and pick which one is the cover (or leave it as the first photo
/// uploaded). No captions, tags, or favorites — just the photos in order.
class DayAlbumScreen extends StatelessWidget {
  final String tripId;
  final int dayIndex;

  const DayAlbumScreen({super.key, required this.tripId, required this.dayIndex});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().current.trip;
    final photos = context.watch<MemoriesProvider>().forDay(tripId, dayIndex);
    final dateLabel = DateFormat('EEEE, MMM d').format(tripDayDate(trip, dayIndex));

    return Scaffold(
      appBar: AppBar(
        title: Text(tripDayLabel(dayIndex)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPhotos(context),
        child: const Icon(Icons.add_a_photo_rounded),
      ),
      body: photos.isEmpty
          ? EmptyState(
              visual: Icon(Icons.photo_camera_rounded, size: 44, color: Theme.of(context).colorScheme.primary),
              title: 'No photos yet',
              subtitle: 'Tap + to upload today\'s pictures.',
            )
          : ReorderablePhotoGrid(
              photos: photos,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              showCoverBadge: true,
              onReorder: (oldIndex, newIndex) =>
                  context.read<MemoriesProvider>().reorderWithinDay(tripId, dayIndex, oldIndex, newIndex),
              onTapPhoto: (photo) => _openViewer(context, photo),
              onDelete: (photo) => _confirmDelete(context, photo),
            ),
    );
  }

  Future<void> _addPhotos(BuildContext context) async {
    await showAddPhotosSheet(
      context,
      onChooseFromLibrary: () async {
        final photos = await pickMemoryPhotosFromLibrary(tripId, dayIndex);
        if (photos.isNotEmpty && context.mounted) {
          context.read<MemoriesProvider>().addPhotos(photos);
        }
      },
      onTakePhoto: () async {
        final photo = await pickMemoryPhotoFromCamera(tripId, dayIndex);
        if (photo != null && context.mounted) {
          context.read<MemoriesProvider>().addPhotos([photo]);
        }
      },
    );
  }

  Future<void> _openViewer(BuildContext context, MemoryPhoto photo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewerScreen(tripId: tripId, dayIndex: dayIndex, photo: photo),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MemoryPhoto photo) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete photo?',
      message: 'This photo will be removed from your Memories.',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<MemoriesProvider>().deletePhoto(photo.id);
    }
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  final String tripId;
  final int dayIndex;
  final MemoryPhoto photo;

  const _PhotoViewerScreen({required this.tripId, required this.dayIndex, required this.photo});

  @override
  Widget build(BuildContext context) {
    final photos = context.watch<MemoriesProvider>().forDay(tripId, dayIndex);
    final isCover = photos.isNotEmpty && photos.first.id == photo.id;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: ImageOrPlaceholder(bytes: photo.bytes, fit: BoxFit.contain, iconSize: 64),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isCover
                          ? null
                          : () {
                              context.read<MemoriesProvider>().setCoverPhoto(tripId, dayIndex, photo.id);
                              Navigator.of(context).pop();
                            },
                      icon: Icon(isCover ? Icons.star_rounded : Icons.star_outline_rounded),
                      label: Text(isCover ? 'Cover Photo' : 'Set as Cover'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete photo?',
                          message: 'This photo will be removed from your Memories.',
                          isDestructive: true,
                        );
                        if (confirmed && context.mounted) {
                          context.read<MemoriesProvider>().deletePhoto(photo.id);
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8A80),
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
