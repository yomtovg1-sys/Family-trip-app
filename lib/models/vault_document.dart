import 'dart:convert';
import 'dart:typed_data';
import 'document_category.dart';
import 'travel_document.dart';

/// A permanent, personal document kept in the [PersonalVault] — a passport,
/// license, insurance card, and so on. It exists independently of any trip;
/// trips only ever hold a [DocumentReference] pointing at one of these, so
/// the file itself is uploaded and stored exactly once no matter how many
/// trips use it.
class VaultDocument {
  final String id;
  final String holderName;
  final DocumentCategory category;
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
    DocumentCategory? category,
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
        category: category,
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
      category: DocumentCategory.values.byName(json['category'] as String),
      fileName: json['fileName'] as String,
      type: AttachmentType.values.byName(json['type'] as String),
      bytes: base64Decode(json['bytesBase64'] as String),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      notes: json['notes'] as String?,
    );
  }
}
