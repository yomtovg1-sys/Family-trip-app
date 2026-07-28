import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reservation_attachment.dart';

class AttachmentViewerScreen extends StatelessWidget {
  final ReservationAttachment attachment;
  final VoidCallback onDelete;

  const AttachmentViewerScreen({
    super.key,
    required this.attachment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(attachment.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _share(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              onDelete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Center(
        child: attachment.type == AttachmentType.image
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(attachment.bytes),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(attachment.type.icon, color: Colors.white54, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    attachment.fileName,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${attachment.sizeLabel} · Preview not available',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share file'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    await Share.shareXFiles([
      XFile.fromData(attachment.bytes, name: attachment.fileName),
    ]);
  }
}
