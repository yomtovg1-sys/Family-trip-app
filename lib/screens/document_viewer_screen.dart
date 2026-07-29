import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/travel_document.dart';
import '../widgets/image_or_placeholder.dart';
import '../widgets/documents/rename_document_dialog.dart';

class DocumentViewerScreen extends StatefulWidget {
  final TravelDocument document;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;

  const DocumentViewerScreen({
    super.key,
    required this.document,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late TravelDocument _document;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_document.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.drive_file_rename_outline_rounded),
            onPressed: _rename,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              widget.onDelete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _document.type == AttachmentType.image && looksLikeRealImage(_document.bytes)
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.memory(_document.bytes),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_document.type.icon, color: Colors.white54, size: 72),
                        const SizedBox(height: 16),
                        Text(
                          _document.fileName,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_document.sizeLabel} · Preview not available',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Share file'),
                        ),
                      ],
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Uploaded ${dateFormat.format(_document.uploadedAt)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename() async {
    final newName = await showRenameDocumentDialog(context, _document.fileName);
    if (newName != null && newName != _document.fileName) {
      setState(() => _document = _document.copyWith(fileName: newName));
      widget.onRename(newName);
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles([
      XFile.fromData(_document.bytes, name: _document.fileName),
    ]);
  }
}
