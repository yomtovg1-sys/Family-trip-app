import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'document_category.dart';

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

/// A file the family has uploaded — a boarding pass, hotel voucher, PDF
/// confirmation, passport scan, screenshot, and so on. Bytes are kept in
/// memory for this session; there's no backend storage layer yet.
class TravelDocument {
  final String id;
  final String fileName;
  final AttachmentType type;
  final Uint8List bytes;
  final DateTime uploadedAt;
  final DocumentCategory category;

  const TravelDocument({
    required this.id,
    required this.fileName,
    required this.type,
    required this.bytes,
    required this.uploadedAt,
    this.category = DocumentCategory.other,
  });

  /// Whether this file looks like a QR code based on its name — used to
  /// pick a more appropriate icon than the generic image/PDF one.
  bool get looksLikeQrCode => fileName.toLowerCase().contains('qr');

  int get sizeBytes => bytes.length;

  String get sizeLabel {
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  TravelDocument copyWith({String? fileName, DocumentCategory? category}) {
    return TravelDocument(
      id: id,
      fileName: fileName ?? this.fileName,
      type: type,
      bytes: bytes,
      uploadedAt: uploadedAt,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'type': type.name,
        'bytesBase64': base64Encode(bytes),
        'uploadedAt': uploadedAt.toIso8601String(),
        'category': category.name,
      };

  factory TravelDocument.fromJson(Map<String, dynamic> json) {
    return TravelDocument(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      type: AttachmentType.values.byName(json['type'] as String),
      bytes: base64Decode(json['bytesBase64'] as String),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      category: json['category'] != null
          ? DocumentCategory.values.byName(json['category'] as String)
          : DocumentCategory.other,
    );
  }
}
