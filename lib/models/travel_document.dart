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

/// A document that belongs either to a whole trip (passport, insurance,
/// emergency contacts, ...) or to a single reservation (boarding pass,
/// hotel voucher, ticket, ...). [category] is only set for trip-level
/// documents — reservation documents don't need one since the reservation
/// itself already carries that context.
enum TripDocumentCategory {
  passport,
  insurance,
  drivingLicense,
  emergencyContacts,
  vaccination,
  visa,
  other,
}

extension TripDocumentCategoryX on TripDocumentCategory {
  String get label {
    switch (this) {
      case TripDocumentCategory.passport:
        return 'Passport';
      case TripDocumentCategory.insurance:
        return 'Travel Insurance';
      case TripDocumentCategory.drivingLicense:
        return 'Driving License';
      case TripDocumentCategory.emergencyContacts:
        return 'Emergency Contacts';
      case TripDocumentCategory.vaccination:
        return 'Vaccination';
      case TripDocumentCategory.visa:
        return 'Visa';
      case TripDocumentCategory.other:
        return 'Other Documents';
    }
  }

  IconData get icon {
    switch (this) {
      case TripDocumentCategory.passport:
        return Icons.badge_rounded;
      case TripDocumentCategory.insurance:
        return Icons.health_and_safety_rounded;
      case TripDocumentCategory.drivingLicense:
        return Icons.directions_car_filled_rounded;
      case TripDocumentCategory.emergencyContacts:
        return Icons.emergency_rounded;
      case TripDocumentCategory.vaccination:
        return Icons.vaccines_rounded;
      case TripDocumentCategory.visa:
        return Icons.travel_explore_rounded;
      case TripDocumentCategory.other:
        return Icons.folder_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TripDocumentCategory.passport:
        return const Color(0xFF3A6EA5);
      case TripDocumentCategory.insurance:
        return const Color(0xFF2F9E44);
      case TripDocumentCategory.drivingLicense:
        return const Color(0xFFE8590C);
      case TripDocumentCategory.emergencyContacts:
        return const Color(0xFFE53935);
      case TripDocumentCategory.vaccination:
        return const Color(0xFF7986CB);
      case TripDocumentCategory.visa:
        return const Color(0xFF2B8A8A);
      case TripDocumentCategory.other:
        return const Color(0xFF757575);
    }
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
  final TripDocumentCategory? category;

  const TravelDocument({
    required this.id,
    required this.fileName,
    required this.type,
    required this.bytes,
    required this.uploadedAt,
    this.category,
  });

  int get sizeBytes => bytes.length;

  String get sizeLabel {
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  TravelDocument copyWith({String? fileName, TripDocumentCategory? category}) {
    return TravelDocument(
      id: id,
      fileName: fileName ?? this.fileName,
      type: type,
      bytes: bytes,
      uploadedAt: uploadedAt,
      category: category ?? this.category,
    );
  }
}
