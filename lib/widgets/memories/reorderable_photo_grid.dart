import 'package:flutter/material.dart';
import '../../models/memory_photo.dart';

/// A photo grid that supports drag-and-drop reordering (long-press a photo
/// and drag it onto another to swap positions), used by both the Memories
/// page and the Album Preview screen.
class ReorderablePhotoGrid extends StatelessWidget {
  final List<MemoryPhoto> photos;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<MemoryPhoto>? onTapPhoto;
  final ValueChanged<MemoryPhoto>? onDelete;
  final EdgeInsets padding;

  const ReorderablePhotoGrid({
    super.key,
    required this.photos,
    required this.onReorder,
    this.onTapPhoto,
    this.onDelete,
    this.padding = const EdgeInsets.all(16),
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
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _PhotoTile({required this.photo, this.highlighted = false, this.onTap, this.onDelete});

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
            Image.memory(photo.bytes, fit: BoxFit.cover),
            if (photo.caption != null && photo.caption!.trim().isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.65)],
                    ),
                  ),
                  child: Text(
                    photo.caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
            child: Image.memory(photo.bytes, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
