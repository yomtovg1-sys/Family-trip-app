import 'dart:typed_data';
import 'package:flutter/material.dart';

enum AttachmentType { pdf, image, other }

extension AttachmentTypeX on AttachmentType {
  IconData get icon {
    switch (this) {
      case AttachmentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case AttachmentType.image:
        return Icons.image_rounded;
      case AttachmentType.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  static AttachmentType fromExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return AttachmentType.pdf;
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.webp')) {
      return AttachmentType.image;
    }
    return AttachmentType.other;
  }
}

/// A file attached to a reservation (boarding pass, voucher, QR code,
/// screenshot, PDF confirmation, etc). Bytes are kept in memory for this
/// session — there's no backend storage layer yet.
class ReservationAttachment {
  final String id;
  final String fileName;
  final AttachmentType type;
  final Uint8List bytes;
  final DateTime uploadedAt;

  const ReservationAttachment({
    required this.id,
    required this.fileName,
    required this.type,
    required this.bytes,
    required this.uploadedAt,
  });

  int get sizeBytes => bytes.length;

  String get sizeLabel {
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
