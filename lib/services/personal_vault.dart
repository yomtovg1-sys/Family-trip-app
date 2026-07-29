import 'package:flutter/material.dart';
import '../models/vault_document.dart';
import 'vault_repository.dart';

/// The Personal Vault: permanent documents that belong to the family, not
/// to any one trip — passports, driver licenses, insurance cards, and so
/// on. Every document here is uploaded exactly once and every trip that
/// needs it only ever holds a reference (see [DocumentReference],
/// [TripLinkService]), so editing or replacing a document here is instantly
/// reflected everywhere it's linked.
class PersonalVault extends ChangeNotifier {
  final VaultRepository repository;

  PersonalVault({required this.repository});

  List<VaultDocument> get documents => repository.getAll();

  List<VaultDocument> byCategory(VaultDocumentCategory category) =>
      documents.where((d) => d.category == category).toList();

  VaultDocument? byId(String id) {
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  void addDocument(VaultDocument document) {
    repository.add(document);
    notifyListeners();
  }

  /// Replaces a document in place — the update every trip referencing it by
  /// id sees immediately, with nothing else needing to change.
  void updateDocument(VaultDocument document) {
    repository.update(document);
    notifyListeners();
  }

  void renameDocument(String id, String newFileName) {
    final document = byId(id);
    if (document != null) updateDocument(document.copyWith(fileName: newFileName));
  }

  void removeDocument(String id) {
    repository.remove(id);
    notifyListeners();
  }
}
