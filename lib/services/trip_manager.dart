import 'package:flutter/foundation.dart';
import '../models/document_reference.dart';
import '../models/family_task.dart';
import '../models/packing_item.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../models/trip_context.dart';
import '../models/trip_template.dart';
import '../models/vault_document.dart';
import '../providers/packing_provider.dart';
import '../providers/places_provider.dart';
import '../providers/tasks_provider.dart';
import 'personal_vault.dart';
import 'template_repository.dart';
import 'trip_link_service.dart';
import 'trip_repository.dart';

/// The central data-management hub for the whole app: it owns which trips
/// exist, which one is currently active, and how trips relate to the
/// Personal Vault and to templates. Every screen that needs "the current
/// trip" ultimately traces back to this class — directly, or through
/// [TripProvider], which delegates trip identity and selection here so
/// existing screens didn't need to change to plug into it.
///
/// TripManager intentionally does not own places/reservations/expenses/
/// packing/memories data itself — those stay in their own providers, each
/// already keyed by trip id, which is what makes "trip data is independent
/// for every trip" true without this class having to enforce it by hand.
class TripManager extends ChangeNotifier {
  final TripRepository tripRepository;
  final PersonalVault personalVault;
  final TripLinkService linkService;
  final TemplateRepository templateRepository;

  late String _currentTripId;

  TripManager({
    required this.tripRepository,
    required this.personalVault,
    required this.linkService,
    required this.templateRepository,
  }) {
    _currentTripId = tripRepository.getAll().first.id;
  }

  List<Trip> get trips => tripRepository.getAll();

  Trip get currentTrip => tripRepository.byId(_currentTripId) ?? trips.first;

  TripContext get currentContext => TripContext(trip: currentTrip);

  void selectTrip(String tripId) {
    if (tripId == _currentTripId) return;
    if (tripRepository.byId(tripId) == null) return;
    _currentTripId = tripId;
    notifyListeners();
  }

  Trip createTrip({
    required String name,
    required String destination,
    required String flagEmoji,
    required DateTime startDate,
    required DateTime endDate,
    String? photoAsset,
    String currency = 'USD',
    List<String> vaultDocumentIds = const [],
  }) {
    final trip = Trip(
      id: 'trip-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      heroEmoji: flagEmoji,
      flagEmoji: flagEmoji,
      photoAsset: photoAsset,
      currency: currency,
    );
    tripRepository.add(trip);
    if (vaultDocumentIds.isNotEmpty) {
      linkService.replaceLinksForTrip(trip.id, vaultDocumentIds);
    }
    _currentTripId = trip.id;
    notifyListeners();
    return trip;
  }

  /// Registers a trip built elsewhere (a restore, an import) as the
  /// canonical record for its id — inserting it if new, replacing it if it
  /// already exists. Never mints a duplicate.
  void upsertTrip(Trip trip) {
    tripRepository.update(trip);
    notifyListeners();
  }

  // --- Personal Vault linking -------------------------------------------

  List<DocumentReference> vaultLinksFor(String tripId) => linkService.linksFor(tripId);

  List<VaultDocument> vaultDocumentsFor(String tripId) =>
      linkService.resolve(tripId, personalVault.documents);

  void attachVaultDocument(String tripId, String vaultDocumentId) {
    linkService.attach(tripId, vaultDocumentId);
    notifyListeners();
  }

  void detachVaultDocument(String tripId, String vaultDocumentId) {
    linkService.detach(tripId, vaultDocumentId);
    notifyListeners();
  }

  // --- Templates -----------------------------------------------------------

  List<TripTemplate> get templates => templateRepository.getAll();

  /// Seeds [tripId]'s packing list, favorite places, and travel checklist
  /// from [templateId] — a one-time copy, not a link. The Personal Vault is
  /// never involved, since templates only ever hold generic starter
  /// content.
  void applyTemplate({
    required String tripId,
    required String templateId,
    required PackingProvider packingProvider,
    required PlacesProvider placesProvider,
    required TasksProvider tasksProvider,
  }) {
    final template = templateRepository.byId(templateId);
    if (template == null) return;

    for (final item in template.packingItems) {
      packingProvider.addItem(
        PackingItem(
          id: 'pack-${DateTime.now().microsecondsSinceEpoch}-${item.name.hashCode}',
          tripId: tripId,
          name: item.name,
          category: item.category,
          assignedTo: item.assignedTo,
        ),
      );
    }

    for (final place in template.favoritePlaces) {
      if (!place.hasCoordinates) continue;
      placesProvider.addPlace(
        SavedPlace(
          id: 'place-${DateTime.now().microsecondsSinceEpoch}-${place.name.hashCode}',
          tripId: tripId,
          name: place.name,
          latitude: place.latitude!,
          longitude: place.longitude!,
          category: place.category,
          area: place.area,
          notes: place.notes,
          source: PlaceSource.manual,
        ),
      );
    }

    for (final title in template.checklist) {
      tasksProvider.addTask(
        FamilyTask(
          id: 'task-${DateTime.now().microsecondsSinceEpoch}-${title.hashCode}',
          title: title,
          assignedTo: 'Everyone',
        ),
      );
    }
  }
}
