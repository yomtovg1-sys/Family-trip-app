import 'package:file_picker/file_picker.dart';
import '../models/reservation_attachment.dart';

/// Opens the platform file picker and returns the picked files as
/// [ReservationAttachment]s. Supports PDFs and common image formats —
/// boarding passes, booking confirmations, vouchers, QR codes, and
/// screenshots.
Future<List<ReservationAttachment>> pickAttachments({bool allowMultiple = true}) async {
  final result = await FilePicker.platform.pickFiles(
    withData: true,
    allowMultiple: allowMultiple,
    type: FileType.custom,
    allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'heic', 'webp'],
  );

  if (result == null) return [];

  final attachments = <ReservationAttachment>[];
  for (final file in result.files) {
    final bytes = file.bytes;
    if (bytes == null) continue;
    attachments.add(
      ReservationAttachment(
        id: 'att-${DateTime.now().microsecondsSinceEpoch}-${attachments.length}',
        fileName: file.name,
        type: AttachmentTypeX.fromExtension(file.name),
        bytes: bytes,
        uploadedAt: DateTime.now(),
      ),
    );
  }
  return attachments;
}
