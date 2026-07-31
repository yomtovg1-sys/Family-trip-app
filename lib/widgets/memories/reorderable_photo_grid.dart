import 'package:flutter/material.dart';
import '../../models/memory_photo.dart';
import '../image_or_placeholder.dart';

/// A photo grid that supports drag-and-drop reordering (long-press a photo
/// and drag it onto another to swap positions), used by the day album
/// screen and the Album Preview screen. The first photo is always a day's
/// cover, so dragging a photo to the front sets it as the cover too.
class ReorderablePhotoGrid extends StatelessWidget {
  final List<MemoryPhoto> photos;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<MemoryPhoto>? onTapPhoto;
  final ValueChanged<MemoryPhoto>? onDelete;
  final EdgeInsets padding;
  final bool showCoverBadge;

  const ReorderablePhotoGrid({
    super.key,
    required this.photos,
    required this.onReorder,
    this.onTapPhoto,
    this.onDelete,
    this.padding = const EdgeInsets.all(16),
    this.showCoverBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) => onReorder(details.data, index),
          builder: (context, candidateData, rejectedData) {
            final isTarget = candidateData.isNotEmpty;
            return LongPressDraggable<int>(
              data: index,
              feedback: _DragFeedback(photo: photo),
              childWhenDragging: Opacity(opacity: 0.3, child: _PhotoTile(photo: photo)),
              child: AnimatedScale(
                scale: isTarget ? 1.05 : 1,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: _PhotoTile(
                  photo: photo,
                  highlighted: isTarget,
                  isCover: showCoverBadge && index == 0,
                  onTap: onTapPhoto == null ? null : () => onTapPhoto!(photo),
                  onDelete: onDelete == null ? null : () => onDelete!(photo),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final MemoryPhoto photo;
  final bool highlighted;
  final bool isCover;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _PhotoTile({
    required this.photo,
    this.highlighted = false,
    this.isCover = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: highlighted ? 4 : 0,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageOrPlaceholder(bytes: photo.bytes, icon: Icons.photo_rounded),
            if (isCover)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 3),
                      Text('Cover', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 6,
              left: 6,
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.85),
                shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
            if (onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  final MemoryPhoto photo;

  const _DragFeedback({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Transform.rotate(
        angle: 0.04,
        child: SizedBox(
          width: 150,
          height: 150 / 0.82,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ImageOrPlaceholder(bytes: photo.bytes, icon: Icons.photo_rounded),
          ),
        ),
      ),
    );
  }
}
