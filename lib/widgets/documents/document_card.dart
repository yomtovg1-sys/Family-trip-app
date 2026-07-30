import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/document_category.dart';
import '../../models/travel_document.dart';
import '../image_or_placeholder.dart';
import 'rename_document_dialog.dart';

class DocumentCard extends StatelessWidget {
  final TravelDocument document;
  final VoidCallback onPreview;
  final ValueChanged<String> onRename;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onPreview,
    required this.onRename,
    required this.onShare,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPreview,
        child: Container(
          width: 134,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: document.type == AttachmentType.image
                        ? ImageOrPlaceholder(bytes: document.bytes, icon: document.type.icon)
                        : Container(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                            alignment: Alignment.center,
                            child: Icon(
                              document.type.icon,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _showActions(context),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.more_horiz_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                  if (document.looksLikeQrCode || document.category != DocumentCategory.other)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: document.looksLikeQrCode ? Colors.black87 : document.category.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          document.looksLikeQrCode ? Icons.qr_code_rounded : document.category.icon,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${document.sizeLabel} · ${DateFormat('MMM d').format(document.uploadedAt)}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DocumentActionsSheet(
        document: document,
        onPreview: onPreview,
        onRename: onRename,
        onShare: onShare,
        onDownload: onDownload,
        onDelete: onDelete,
      ),
    );
  }
}

class _DocumentActionsSheet extends StatelessWidget {
  final TravelDocument document;
  final VoidCallback onPreview;
  final ValueChanged<String> onRename;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _DocumentActionsSheet({
    required this.document,
    required this.onPreview,
    required this.onRename,
    required this.onShare,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
            const SizedBox(height: 14),
            Text(
              document.fileName,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Preview'),
              onTap: () {
                Navigator.of(context).pop();
                onPreview();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.of(context).pop();
                final newName = await showRenameDocumentDialog(context, document.fileName);
                if (newName != null && newName != document.fileName) onRename(newName);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                onShare();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download_rounded),
              title: const Text('Download'),
              onTap: () {
                Navigator.of(context).pop();
                onDownload();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
              title: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddDocumentTile extends StatelessWidget {
  final VoidCallback onTap;

  const AddDocumentTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 134,
          height: 138,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: theme.colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                'Add Document',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
