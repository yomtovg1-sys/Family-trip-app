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

/// A general-purpose tag applied to any document — trip-level or
/// reservation-level — so the whole Travel Wallet can be searched and
/// filtered the same way regardless of where a document lives.
enum DocumentTag { flight, hotel, insurance, passport, carRental, tickets, other }

extension DocumentTagX on DocumentTag {
  String get label {
    switch (this) {
      case DocumentTag.flight:
        return 'Flight';
      case DocumentTag.hotel:
        return 'Hotel';
      case DocumentTag.insurance:
        return 'Insurance';
      case DocumentTag.passport:
        return 'Passport';
      case DocumentTag.carRental:
        return 'Car Rental';
      case DocumentTag.tickets:
        return 'Tickets';
      case DocumentTag.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentTag.flight:
        return Icons.flight_rounded;
      case DocumentTag.hotel:
        return Icons.hotel_rounded;
      case DocumentTag.insurance:
        return Icons.health_and_safety_rounded;
      case DocumentTag.passport:
        return Icons.badge_rounded;
      case DocumentTag.carRental:
        return Icons.directions_car_rounded;
      case DocumentTag.tickets:
        return Icons.confirmation_number_rounded;
      case DocumentTag.other:
        return Icons.sell_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DocumentTag.flight:
        return const Color(0xFF3A6EA5);
      case DocumentTag.hotel:
        return const Color(0xFF7986CB);
      case DocumentTag.insurance:
        return const Color(0xFF2F9E44);
      case DocumentTag.passport:
        return const Color(0xFF00838F);
      case DocumentTag.carRental:
        return const Color(0xFFE8590C);
      case DocumentTag.tickets:
        return const Color(0xFFD6336C);
      case DocumentTag.other:
        return const Color(0xFF757575);
    }
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

  /// The sensible default [DocumentTag] for a document uploaded under this
  /// trip-document category, so every document gets a useful tag without
  /// making the family pick one twice.
  DocumentTag get defaultDocumentTag {
    switch (this) {
      case TripDocumentCategory.passport:
        return DocumentTag.passport;
      case TripDocumentCategory.insurance:
        return DocumentTag.insurance;
      case TripDocumentCategory.drivingLicense:
        return DocumentTag.carRental;
      case TripDocumentCategory.emergencyContacts:
      case TripDocumentCategory.vaccination:
      case TripDocumentCategory.visa:
      case TripDocumentCategory.other:
        return DocumentTag.other;
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
  final DocumentTag tag;

  const TravelDocument({
    required this.id,
    required this.fileName,
    required this.type,
    required this.bytes,
    required this.uploadedAt,
    this.category,
    this.tag = DocumentTag.other,
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

  TravelDocument copyWith({String? fileName, TripDocumentCategory? category, DocumentTag? tag}) {
    return TravelDocument(
      id: id,
      fileName: fileName ?? this.fileName,
      type: type,
      bytes: bytes,
      uploadedAt: uploadedAt,
      category: category ?? this.category,
      tag: tag ?? this.tag,
    );
  }
}
