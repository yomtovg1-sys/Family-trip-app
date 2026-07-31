import 'package:flutter/material.dart';
import '../emoji_text.dart';

/// The "upload photos" chooser for the Memories page: library or camera.
Future<void> showAddPhotosSheet(
  BuildContext context, {
  required VoidCallback onChooseFromLibrary,
  required VoidCallback onTakePhoto,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AddPhotosSheet(
      onChooseFromLibrary: onChooseFromLibrary,
      onTakePhoto: onTakePhoto,
    ),
  );
}

class _AddPhotosSheet extends StatelessWidget {
  final VoidCallback onChooseFromLibrary;
  final VoidCallback onTakePhoto;

  const _AddPhotosSheet({required this.onChooseFromLibrary, required this.onTakePhoto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Add Photos', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _OptionTile(
              emoji: '🖼️',
              title: 'Choose from Photos',
              subtitle: 'Pick one or more photos',
              onTap: () {
                Navigator.of(context).pop();
                onChooseFromLibrary();
              },
            ),
            _OptionTile(
              emoji: '📷',
              title: 'Take a Photo',
              subtitle: 'Use the camera',
              onTap: () {
                Navigator.of(context).pop();
                onTakePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: EmojiText(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(
                      subtitle,
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
