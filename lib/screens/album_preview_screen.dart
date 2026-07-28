import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/album_layout.dart';
import '../models/memory_photo.dart';
import '../providers/memories_provider.dart';
import '../providers/trip_provider.dart';
import '../services/album_pdf_builder.dart';
import '../widgets/memories/reorderable_photo_grid.dart';

/// The Album Preview screen: rename the album, rearrange or remove photos,
/// pick a layout, then generate a printable PDF. Removing a photo here only
/// takes it out of the album, not the Memories page.
class AlbumPreviewScreen extends StatefulWidget {
  final String tripId;

  const AlbumPreviewScreen({super.key, required this.tripId});

  @override
  State<AlbumPreviewScreen> createState() => _AlbumPreviewScreenState();
}

class _AlbumPreviewScreenState extends State<AlbumPreviewScreen> {
  late final TextEditingController _titleController;
  late List<MemoryPhoto> _photos;
  AlbumLayout _layout = AlbumLayout.classic;
  bool _generating = false;
  Uint8List? _generatedPdf;

  @override
  void initState() {
    super.initState();
    final trip = context.read<TripProvider>().current.trip;
    _titleController = TextEditingController(text: trip.name);
    _photos = List.of(context.read<MemoriesProvider>().forTrip(widget.tripId));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final moved = _photos.removeAt(oldIndex);
      _photos.insert(newIndex.clamp(0, _photos.length), moved);
      _generatedPdf = null;
    });
  }

  void _removePhoto(MemoryPhoto photo) {
    setState(() {
      _photos.removeWhere((p) => p.id == photo.id);
      _generatedPdf = null;
    });
  }

  Future<void> _generate() async {
    if (_photos.isEmpty) return;
    setState(() => _generating = true);
    final trip = context.read<TripProvider>().current.trip;
    final bytes = await buildAlbumPdf(
      tripName: trip.name,
      albumTitle: _titleController.text.trim().isEmpty ? trip.name : _titleController.text.trim(),
      photos: _photos,
      layout: _layout,
    );
    if (!mounted) return;
    setState(() {
      _generating = false;
      _generatedPdf = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Album Preview')),
      body: _generatedPdf != null
          ? _AlbumReadyView(
              albumTitle: _titleController.text.trim(),
              pdfBytes: _generatedPdf!,
              onEdit: () => setState(() => _generatedPdf = null),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TextField(
                  controller: _titleController,
                  style: theme.textTheme.titleLarge,
                  decoration: const InputDecoration(labelText: 'Album Title'),
                ),
                const SizedBox(height: 20),
                Text('Layout', style: theme.textTheme.titleSmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final layout in AlbumLayout.values) ...[
                      Expanded(
                        child: _LayoutOption(
                          layout: layout,
                          selected: _layout == layout,
                          onTap: () => setState(() => _layout = layout),
                        ),
                      ),
                      if (layout != AlbumLayout.values.last) const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Photos', style: theme.textTheme.titleSmall),
                    const SizedBox(width: 6),
                    Text(
                      '${_photos.length}',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Text(
                      'Drag to rearrange',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_photos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No photos left in this album.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  SizedBox(
                    height: (_photos.length / 2).ceil() * 190.0,
                    child: ReorderablePhotoGrid(
                      photos: _photos,
                      padding: EdgeInsets.zero,
                      onReorder: _reorder,
                      onDelete: _removePhoto,
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: (_photos.isEmpty || _generating) ? null : _generate,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_stories_rounded),
                  label: Text(_generating ? 'Generating…' : 'Generate Album'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  final AlbumLayout layout;
  final bool selected;
  final VoidCallback onTap;

  const _LayoutOption({required this.layout, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(layout.icon, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(
                layout.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                layout.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumReadyView extends StatelessWidget {
  final String albumTitle;
  final Uint8List pdfBytes;
  final VoidCallback onEdit;

  const _AlbumReadyView({required this.albumTitle, required this.pdfBytes, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Your album is ready', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            albumTitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _viewOrSavePdf(context),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('View / Save PDF'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Album'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewOrSavePdf(BuildContext context) async {
    try {
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: '$albumTitle.pdf');
    } catch (error, stackTrace) {
      debugPrint('View/Save PDF failed: $error\n$stackTrace');
      if (context.mounted) _showExportError(context, "Couldn't open the PDF preview.");
    }
  }

  Future<void> _share(BuildContext context) async {
    try {
      await Printing.sharePdf(bytes: pdfBytes, filename: '$albumTitle.pdf');
    } catch (error, stackTrace) {
      debugPrint('Share failed: $error\n$stackTrace');
      if (context.mounted) _showExportError(context, "Couldn't open the share sheet.");
    }
  }

  void _showExportError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
