import 'package:image_picker/image_picker.dart';
import '../models/memory_photo.dart';

String _newId() => 'photo-${DateTime.now().microsecondsSinceEpoch}';

/// Opens the photo library for multi-select upload — the "Photos" option
/// on a day's Memories page.
Future<List<MemoryPhoto>> pickMemoryPhotosFromLibrary(String tripId, int dayIndex) async {
  final picker = ImagePicker();
  final files = await picker.pickMultiImage();

  final photos = <MemoryPhoto>[];
  for (final file in files) {
    photos.add(
      MemoryPhoto(
        id: _newId(),
        tripId: tripId,
        dayIndex: dayIndex,
        bytes: await file.readAsBytes(),
        fileName: file.name,
        takenAt: DateTime.now(),
      ),
    );
  }
  return photos;
}

/// Opens the camera to take a new photo — the "Camera" option on a day's
/// Memories page.
Future<MemoryPhoto?> pickMemoryPhotoFromCamera(String tripId, int dayIndex) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.camera);
  if (file == null) return null;

  return MemoryPhoto(
    id: _newId(),
    tripId: tripId,
    dayIndex: dayIndex,
    bytes: await file.readAsBytes(),
    fileName: file.name,
    takenAt: DateTime.now(),
  );
}
