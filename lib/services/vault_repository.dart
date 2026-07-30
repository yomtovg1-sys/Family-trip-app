import '../models/document_category.dart';
import '../models/travel_document.dart';
import '../models/vault_document.dart';
import '../utils/placeholder_bytes.dart';
import 'hive_json_store.dart';

/// Storage for [VaultDocument]s. Kept separate from [PersonalVault] (the
/// ChangeNotifier the UI watches) so the storage backend — in-memory today,
/// on-device or cloud-backed later — can change without touching any
/// screen.
abstract class VaultRepository {
  List<VaultDocument> getAll();
  void add(VaultDocument document);
  void update(VaultDocument document);
  void remove(String id);
}

/// Persists the Personal Vault's documents on-device via Hive, seeding the
/// family's starter documents only on a genuine first launch.
class HiveVaultRepository implements VaultRepository {
  final HiveJsonStore<VaultDocument> _store;
  final List<VaultDocument> _documents;

  HiveVaultRepository._(this._store, this._documents);

  static Future<HiveVaultRepository> open() async {
    final store = await HiveJsonStore.open<VaultDocument>(
      'vault_documents',
      toJson: (d) => d.toJson(),
      fromJson: VaultDocument.fromJson,
      idOf: (d) => d.id,
    );
    final documents = store.isEmpty ? InMemoryVaultRepository._seedDocuments() : store.getAll();
    if (store.isEmpty) store.putAll(documents);
    return HiveVaultRepository._(store, documents);
  }

  @override
  List<VaultDocument> getAll() => List.unmodifiable(_documents);

  @override
  void add(VaultDocument document) {
    _documents.add(document);
    _store.put(document);
  }

  @override
  void update(VaultDocument document) {
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index != -1) _documents[index] = document;
    _store.put(document);
  }

  @override
  void remove(String id) {
    _documents.removeWhere((d) => d.id == id);
    _store.remove(id);
  }
}

/// The only implementation today: holds documents in memory for the
/// session, seeded with the family's real permanent documents so the vault
/// isn't empty on first launch.
class InMemoryVaultRepository implements VaultRepository {
  final List<VaultDocument> _documents = _seedDocuments();

  @override
  List<VaultDocument> getAll() => List.unmodifiable(_documents);

  @override
  void add(VaultDocument document) => _documents.add(document);

  @override
  void update(VaultDocument document) {
    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index != -1) _documents[index] = document;
  }

  @override
  void remove(String id) => _documents.removeWhere((d) => d.id == id);

  static List<VaultDocument> _seedDocuments() {
    final now = DateTime.now();
    return [
      VaultDocument(
        id: 'vault-passport-galit',
        holderName: 'Galit',
        category: DocumentCategory.passport,
        fileName: 'Galit Passport.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 200)),
        expiryDate: now.add(const Duration(days: 900)),
      ),
      VaultDocument(
        id: 'vault-passport-amit',
        holderName: 'Amit',
        category: DocumentCategory.passport,
        fileName: 'Amit Passport.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 200)),
        expiryDate: now.add(const Duration(days: 640)),
      ),
      VaultDocument(
        id: 'vault-license-family',
        holderName: 'Family',
        category: DocumentCategory.driverLicense,
        fileName: 'Family Driver License.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 150)),
        expiryDate: now.add(const Duration(days: 1200)),
      ),
      VaultDocument(
        id: 'vault-idp-family',
        holderName: 'Family',
        category: DocumentCategory.internationalDrivingPermit,
        fileName: 'International Driving Permit.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 40)),
        expiryDate: now.add(const Duration(days: 320)),
      ),
      VaultDocument(
        id: 'vault-insurance-family',
        holderName: 'Family',
        category: DocumentCategory.insurance,
        fileName: 'Health Insurance Card.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 90)),
      ),
      VaultDocument(
        id: 'vault-emergency-contacts',
        holderName: 'Family',
        category: DocumentCategory.emergencyContact,
        fileName: 'Emergency Contacts.png',
        type: AttachmentType.image,
        bytes: placeholderImageBytes,
        uploadedAt: now.subtract(const Duration(days: 90)),
        notes: 'Grandma Rivka (+1 555-0142), Dr. Cohen (+1 555-0198)',
      ),
      VaultDocument(
        id: 'vault-frequent-flyer',
        holderName: 'Galit',
        category: DocumentCategory.frequentFlyer,
        fileName: 'SkyMiles Card.png',
        type: AttachmentType.image,
        bytes: placeholderImageBytes,
        uploadedAt: now.subtract(const Duration(days: 60)),
      ),
    ];
  }
}
