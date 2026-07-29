import '../models/travel_document.dart';
import '../models/vault_document.dart';
import '../utils/placeholder_bytes.dart';

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
        category: VaultDocumentCategory.passport,
        fileName: 'Galit Passport.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 200)),
        expiryDate: now.add(const Duration(days: 900)),
      ),
      VaultDocument(
        id: 'vault-passport-amit',
        holderName: 'Amit',
        category: VaultDocumentCategory.passport,
        fileName: 'Amit Passport.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 200)),
        expiryDate: now.add(const Duration(days: 640)),
      ),
      VaultDocument(
        id: 'vault-license-family',
        holderName: 'Family',
        category: VaultDocumentCategory.driverLicense,
        fileName: 'Family Driver License.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 150)),
        expiryDate: now.add(const Duration(days: 1200)),
      ),
      VaultDocument(
        id: 'vault-idp-family',
        holderName: 'Family',
        category: VaultDocumentCategory.internationalDrivingPermit,
        fileName: 'International Driving Permit.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 40)),
        expiryDate: now.add(const Duration(days: 320)),
      ),
      VaultDocument(
        id: 'vault-insurance-family',
        holderName: 'Family',
        category: VaultDocumentCategory.healthInsurance,
        fileName: 'Health Insurance Card.pdf',
        type: AttachmentType.pdf,
        bytes: placeholderDocumentBytes,
        uploadedAt: now.subtract(const Duration(days: 90)),
      ),
      VaultDocument(
        id: 'vault-emergency-contacts',
        holderName: 'Family',
        category: VaultDocumentCategory.emergencyContact,
        fileName: 'Emergency Contacts.png',
        type: AttachmentType.image,
        bytes: placeholderImageBytes,
        uploadedAt: now.subtract(const Duration(days: 90)),
        notes: 'Grandma Rivka (+1 555-0142), Dr. Cohen (+1 555-0198)',
      ),
      VaultDocument(
        id: 'vault-frequent-flyer',
        holderName: 'Galit',
        category: VaultDocumentCategory.frequentFlyer,
        fileName: 'SkyMiles Card.png',
        type: AttachmentType.image,
        bytes: placeholderImageBytes,
        uploadedAt: now.subtract(const Duration(days: 60)),
      ),
    ];
  }
}
