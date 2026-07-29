import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'travel_document.dart';

/// A category of permanent, personal document — never tied to a single
/// trip. Every category here is something a family member only needs to
/// upload once and then reuse across every future trip.
enum VaultDocumentCategory {
  passport,
  driverLicense,
  internationalDrivingPermit,
  healthInsurance,
  frequentFlyer,
  loungeMembership,
  emergencyContact,
  visa,
  other,
}

extension VaultDocumentCategoryX on VaultDocumentCategory {
  String get label {
    switch (this) {
      case VaultDocumentCategory.passport:
        return 'Passport';
      case VaultDocumentCategory.driverLicense:
        return 'Driver License';
      case VaultDocumentCategory.internationalDrivingPermit:
        return 'International Driving Permit';
      case VaultDocumentCategory.healthInsurance:
        return 'Health Insurance Card';
      case VaultDocumentCategory.frequentFlyer:
        return 'Frequent Flyer Card';
      case VaultDocumentCategory.loungeMembership:
        return 'Lounge Membership';
      case VaultDocumentCategory.emergencyContact:
        return 'Emergency Contact';
      case VaultDocumentCategory.visa:
        return 'Visa';
      case VaultDocumentCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case VaultDocumentCategory.passport:
        return Icons.badge_rounded;
      case VaultDocumentCategory.driverLicense:
        return Icons.directions_car_filled_rounded;
      case VaultDocumentCategory.internationalDrivingPermit:
        return Icons.card_travel_rounded;
      case VaultDocumentCategory.healthInsurance:
        return Icons.health_and_safety_rounded;
      case VaultDocumentCategory.frequentFlyer:
        return Icons.flight_rounded;
      case VaultDocumentCategory.loungeMembership:
        return Icons.airline_seat_flat_rounded;
      case VaultDocumentCategory.emergencyContact:
        return Icons.emergency_rounded;
      case VaultDocumentCategory.visa:
        return Icons.travel_explore_rounded;
      case VaultDocumentCategory.other:
        return Icons.folder_rounded;
    }
  }

  Color get color {
    switch (this) {
      case VaultDocumentCategory.passport:
        return const Color(0xFF3A6EA5);
      case VaultDocumentCategory.driverLicense:
        return const Color(0xFFE8590C);
      case VaultDocumentCategory.internationalDrivingPermit:
        return const Color(0xFFB5651D);
      case VaultDocumentCategory.healthInsurance:
        return const Color(0xFF2F9E44);
      case VaultDocumentCategory.frequentFlyer:
        return const Color(0xFF6741D9);
      case VaultDocumentCategory.loungeMembership:
        return const Color(0xFF00838F);
      case VaultDocumentCategory.emergencyContact:
        return const Color(0xFFE53935);
      case VaultDocumentCategory.visa:
        return const Color(0xFF2B8A8A);
      case VaultDocumentCategory.other:
        return const Color(0xFF757575);
    }
  }
}

/// A permanent, personal document kept in the [PersonalVault] — a passport,
/// license, insurance card, and so on. It exists independently of any trip;
/// trips only ever hold a [DocumentReference] pointing at one of these, so
/// the file itself is uploaded and stored exactly once no matter how many
/// trips use it.
class VaultDocument {
  final String id;
  final String holderName;
  final VaultDocumentCategory category;
  final String fileName;
  final AttachmentType type;
  final Uint8List bytes;
  final DateTime uploadedAt;
  final DateTime? expiryDate;
  final String? notes;

  const VaultDocument({
    required this.id,
    required this.holderName,
    required this.category,
    required this.fileName,
    required this.type,
    required this.bytes,
    required this.uploadedAt,
    this.expiryDate,
    this.notes,
  });

  /// A one-line label for chips/lists, e.g. "Galit Passport".
  String get displayName => '$holderName ${category.label}';

  VaultDocument copyWith({
    String? holderName,
    VaultDocumentCategory? category,
    String? fileName,
    DateTime? expiryDate,
    String? notes,
  }) {
    return VaultDocument(
      id: id,
      holderName: holderName ?? this.holderName,
      category: category ?? this.category,
      fileName: fileName ?? this.fileName,
      type: type,
      bytes: bytes,
      uploadedAt: uploadedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
    );
  }

  /// Adapts this vault document to a [TravelDocument] purely for reuse of
  /// existing document UI (`DocumentCard`, `DocumentViewerScreen`) — no
  /// separate copy is stored anywhere, this is a view built on demand.
  TravelDocument get asTravelDocument => TravelDocument(
        id: id,
        fileName: fileName,
        type: type,
        bytes: bytes,
        uploadedAt: uploadedAt,
        tag: DocumentTag.other,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'holderName': holderName,
        'category': category.name,
        'fileName': fileName,
        'type': type.name,
        'bytesBase64': base64Encode(bytes),
        'uploadedAt': uploadedAt.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'notes': notes,
      };

  factory VaultDocument.fromJson(Map<String, dynamic> json) {
    return VaultDocument(
      id: json['id'] as String,
      holderName: json['holderName'] as String,
      category: VaultDocumentCategory.values.byName(json['category'] as String),
      fileName: json['fileName'] as String,
      type: AttachmentType.values.byName(json['type'] as String),
      bytes: base64Decode(json['bytesBase64'] as String),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      notes: json['notes'] as String?,
    );
  }
}
