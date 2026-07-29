/// A trip's link to one [VaultDocument] — never a copy of the file itself.
/// [TripLinkService] is the only place these get created or removed, and
/// resolving one back to a live [VaultDocument] always looks the document up
/// by id, so an edit to the vault document is instantly visible everywhere
/// it's referenced.
class DocumentReference {
  final String tripId;
  final String vaultDocumentId;
  final DateTime linkedAt;

  const DocumentReference({
    required this.tripId,
    required this.vaultDocumentId,
    required this.linkedAt,
  });

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'vaultDocumentId': vaultDocumentId,
        'linkedAt': linkedAt.toIso8601String(),
      };

  factory DocumentReference.fromJson(Map<String, dynamic> json) {
    return DocumentReference(
      tripId: json['tripId'] as String,
      vaultDocumentId: json['vaultDocumentId'] as String,
      linkedAt: DateTime.parse(json['linkedAt'] as String),
    );
  }
}
