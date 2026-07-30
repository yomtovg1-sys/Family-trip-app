import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/travel_document.dart';

String _newId() => 'doc-${DateTime.now().microsecondsSinceEpoch}';

/// Opens the platform file browser for PDFs and documents — the "Files"
/// option in the native-style Add Document sheet.
Future<List<TravelDocument>> pickFromFiles({bool allowMultiple = true}) async {
  final result = await FilePicker.platform.pickFiles(
    withData: true,
    allowMultiple: allowMultiple,
    type: FileType.custom,
    allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'heic', 'webp'],
  );
  if (result == null) return [];

  final documents = <TravelDocument>[];
  for (final file in result.files) {
    final bytes = file.bytes;
    if (bytes == null) continue;
    documents.add(
      TravelDocument(
        id: _newId(),
        fileName: file.name,
        type: AttachmentTypeX.fromExtension(file.name),
        bytes: bytes,
        uploadedAt: DateTime.now(),
      ),
    );
  }
  return documents;
}

/// Opens the photo library — the "Photos" option in the Add Document sheet.
Future<List<TravelDocument>> pickFromPhotos({bool allowMultiple = true}) async {
  final picker = ImagePicker();
  List<XFile> files;
  if (allowMultiple) {
    files = await picker.pickMultiImage();
  } else {
    final single = await picker.pickImage(source: ImageSource.gallery);
    files = single == null ? [] : [single];
  }

  final documents = <TravelDocument>[];
  for (final file in files) {
    documents.add(
      TravelDocument(
        id: _newId(),
        fileName: file.name,
        type: AttachmentType.image,
        bytes: await file.readAsBytes(),
        uploadedAt: DateTime.now(),
      ),
    );
  }
  return documents;
}

/// Opens the camera to scan or photograph a document — the "Camera" option
/// in the Add Document sheet.
Future<TravelDocument?> pickFromCamera() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.camera);
  if (file == null) return null;

  return TravelDocument(
    id: _newId(),
    fileName: file.name,
    type: AttachmentType.image,
    bytes: await file.readAsBytes(),
    uploadedAt: DateTime.now(),
  );
}
