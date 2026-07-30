import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/document_reference.dart';
import '../models/vault_document.dart';

/// Links trips to Personal Vault documents — and only links. This service
/// never touches a document's bytes; it stores id pairs and, when asked to
/// resolve them, looks the current document up fresh every time. That's
/// what makes "if a document is updated in the Personal Vault, all trips
/// using it automatically use the latest version" true by construction
/// rather than something that has to be kept in sync.
///
/// Persisted via Hive so a trip's vault attachments (e.g. "use our family
/// passports for this trip") survive a reload rather than resetting.
class TripLinkService {
  final Box<String> _box;
  final List<DocumentReference> _links;

  TripLinkService._(this._box, this._links);

  static Future<TripLinkService> open() async {
    final box = await Hive.openBox<String>('vault_links');
    final links = [
      for (final raw in box.values) DocumentReference.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    ];
    return TripLinkService._(box, links);
  }

  static String _key(String tripId, String vaultDocumentId) => '$tripId::$vaultDocumentId';

  List<DocumentReference> linksFor(String tripId) =>
      _links.where((l) => l.tripId == tripId).toList();

  bool isLinked(String tripId, String vaultDocumentId) =>
      _links.any((l) => l.tripId == tripId && l.vaultDocumentId == vaultDocumentId);

  void attach(String tripId, String vaultDocumentId) {
    if (isLinked(tripId, vaultDocumentId)) return;
    final link = DocumentReference(tripId: tripId, vaultDocumentId: vaultDocumentId, linkedAt: DateTime.now());
    _links.add(link);
    _box.put(_key(tripId, vaultDocumentId), jsonEncode(link.toJson()));
  }

  void detach(String tripId, String vaultDocumentId) {
    _links.removeWhere((l) => l.tripId == tripId && l.vaultDocumentId == vaultDocumentId);
    _box.delete(_key(tripId, vaultDocumentId));
  }

  /// Replaces every link for [tripId] in one go — used when creating a trip
  /// with a preselected set of vault items, or applying an import/restore.
  void replaceLinksForTrip(String tripId, Iterable<String> vaultDocumentIds) {
    for (final l in linksFor(tripId)) {
      _box.delete(_key(tripId, l.vaultDocumentId));
    }
    _links.removeWhere((l) => l.tripId == tripId);
    final now = DateTime.now();
    for (final id in vaultDocumentIds) {
      final link = DocumentReference(tripId: tripId, vaultDocumentId: id, linkedAt: now);
      _links.add(link);
      _box.put(_key(tripId, id), jsonEncode(link.toJson()));
    }
  }

  /// Resolves [tripId]'s links against the vault's live document list —
  /// never a cached copy, so an edited or removed document is reflected
  /// immediately.
  List<VaultDocument> resolve(String tripId, List<VaultDocument> allVaultDocuments) {
    final linkedIds = linksFor(tripId).map((l) => l.vaultDocumentId).toSet();
    return allVaultDocuments.where((d) => linkedIds.contains(d.id)).toList();
  }
}
