import 'package:flutter/material.dart';
import '../../models/travel_document.dart';
import '../../services/document_picker.dart';

/// The native-style "Add Document" action sheet: Files, Photos, or Camera —
/// matching the familiar iOS attachment picker instead of jumping straight
/// into a single file browser.
Future<void> showAddDocumentSheet(
  BuildContext context, {
  required void Function(List<TravelDocument> documents) onPicked,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AddDocumentSheet(onPicked: onPicked),
  );
}

class _AddDocumentSheet extends StatelessWidget {
  final void Function(List<TravelDocument> documents) onPicked;

  const _AddDocumentSheet({required this.onPicked});

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
            Text('Add Document', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Choose where to add a file from',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.folder_rounded,
              title: 'Files',
              subtitle: 'Choose a document or PDF from Files',
              onTap: () async {
                Navigator.of(context).pop();
                final docs = await pickFromFiles();
                if (docs.isNotEmpty) onPicked(docs);
              },
            ),
            _OptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Photos',
              subtitle: 'Choose an existing photo or screenshot',
              onTap: () async {
                Navigator.of(context).pop();
                final docs = await pickFromPhotos();
                if (docs.isNotEmpty) onPicked(docs);
              },
            ),
            _OptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Camera',
              subtitle: 'Scan or photograph a document now',
              onTap: () async {
                Navigator.of(context).pop();
                final doc = await pickFromCamera();
                if (doc != null) onPicked([doc]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
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
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
