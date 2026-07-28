import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/backup_meta.dart';
import '../models/backup_snapshot.dart';
import '../models/trip_snapshot.dart';
import '../providers/memories_provider.dart';
import '../providers/packing_provider.dart';
import '../providers/places_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';
import 'backup_repository.dart';
import 'backup_service.dart';
import 'settings_repository.dart';

/// The feature's silent background worker. Listens to every provider that
/// holds trip data and, when automatic backups are enabled, quietly takes a
/// debounced backup a few seconds after things settle down — no matter
/// which screen the family is on. Also owns the manual "create backup" and
/// "restore from backup" actions, since both need the same snapshot
/// build/apply logic this class already has for the automatic path.
///
/// This is deliberately the one place in the app that touches every data
/// provider at once — everywhere else keeps to its own feature.
class BackupManager extends ChangeNotifier {
  final TripProvider tripProvider;
  final PlacesProvider placesProvider;
  final ReservationsProvider reservationsProvider;
  final PackingProvider packingProvider;
  final MemoriesProvider memoriesProvider;
  final BackupRepository backupRepository;
  final SettingsRepository settingsRepository;

  late final BackupService backupService;

  BackupMeta? _latestBackup;
  bool _autoBackupEnabled = true;
  bool _isBackingUp = false;
  bool _initialized = false;
  Timer? _debounce;

  static const _debounceDelay = Duration(seconds: 4);

  BackupManager({
    required this.tripProvider,
    required this.placesProvider,
    required this.reservationsProvider,
    required this.packingProvider,
    required this.memoriesProvider,
    required this.backupRepository,
    required this.settingsRepository,
  }) {
    backupService = BackupService(repository: backupRepository, buildSnapshot: buildSnapshot);
    tripProvider.addListener(_onDataChanged);
    placesProvider.addListener(_onDataChanged);
    reservationsProvider.addListener(_onDataChanged);
    packingProvider.addListener(_onDataChanged);
    memoriesProvider.addListener(_onDataChanged);
    unawaited(_loadInitialState());
  }

  BackupMeta? get latestBackup => _latestBackup;
  bool get autoBackupEnabled => _autoBackupEnabled;
  bool get isBackingUp => _isBackingUp;
  bool get initialized => _initialized;

  Future<void> _loadInitialState() async {
    _autoBackupEnabled = await settingsRepository.getAutoBackupEnabled();
    _latestBackup = await backupService.latestBackup();
    _initialized = true;
    notifyListeners();
  }

  void _onDataChanged() {
    if (!_autoBackupEnabled) return;
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      unawaited(_runAutomaticBackup());
    });
  }

  Future<void> _runAutomaticBackup() async {
    _isBackingUp = true;
    notifyListeners();
    try {
      _latestBackup = await backupService.createAutomaticBackup();
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  Future<BackupMeta> createManualBackup() async {
    _debounce?.cancel();
    _isBackingUp = true;
    notifyListeners();
    try {
      _latestBackup = await backupService.createManualBackup();
      return _latestBackup!;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    _autoBackupEnabled = enabled;
    notifyListeners();
    await settingsRepository.setAutoBackupEnabled(enabled);
  }

  Future<List<BackupMeta>> listBackups() => backupService.listBackups();

  Future<int> storageUsedBytes() => backupService.storageUsedBytes();

  Future<void> deleteBackup(String backupId) async {
    await backupService.deleteBackup(backupId);
    _latestBackup = await backupService.latestBackup();
    notifyListeners();
  }

  /// Restores from [backupId]: safeguards current state first, then applies
  /// every trip and the packing list from that backup back into the live
  /// providers.
  Future<bool> restoreFromBackup(String backupId) async {
    final snapshot = await backupService.prepareRestore(backupId);
    if (snapshot == null) return false;
    applySnapshot(snapshot);
    _latestBackup = await backupService.latestBackup();
    notifyListeners();
    return true;
  }

  /// Applies a full [BackupSnapshot] — every trip plus the packing list —
  /// into the live providers. Used for restore and for importing a
  /// full-backup JSON file.
  void applySnapshot(BackupSnapshot snapshot) {
    for (final tripSnapshot in snapshot.trips) {
      applyTripSnapshot(tripSnapshot);
    }
    packingProvider.replaceAll(snapshot.packingItems);
  }

  /// Applies a single [TripSnapshot] into the live providers — used for a
  /// single-trip import.
  void applyTripSnapshot(TripSnapshot tripSnapshot) {
    tripProvider.restoreTripSnapshot(tripSnapshot);
    placesProvider.replaceForTrip(tripSnapshot.trip.id, tripSnapshot.places);
    reservationsProvider.replaceForTrip(tripSnapshot.trip.id, tripSnapshot.reservations);
    memoriesProvider.replaceForTrip(tripSnapshot.trip.id, tripSnapshot.photos);
  }

  /// Captures everything the app currently holds. This is what an automatic
  /// or manual backup stores, and what a full JSON export contains.
  Future<BackupSnapshot> buildSnapshot() async {
    return BackupSnapshot(
      capturedAt: DateTime.now(),
      trips: [for (final dashboard in tripProvider.all) buildTripSnapshot(dashboard.trip.id)],
      packingItems: packingProvider.items,
      settings: {
        'autoBackupEnabled': await settingsRepository.getAutoBackupEnabled(),
        'includeAiConversations': await settingsRepository.getIncludeAiConversations(),
      },
    );
  }

  /// Captures one trip's data as it stands right now.
  TripSnapshot buildTripSnapshot(String tripId) {
    final dashboard = tripProvider.all.firstWhere((d) => d.trip.id == tripId);
    return TripSnapshot(
      trip: dashboard.trip,
      journeyStops: dashboard.journeyStops,
      places: placesProvider.forTrip(tripId),
      reservations: reservationsProvider.forTrip(tripId),
      expenses: dashboard.expenses,
      documents: dashboard.documents,
      photos: memoriesProvider.forTrip(tripId),
      capturedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    tripProvider.removeListener(_onDataChanged);
    placesProvider.removeListener(_onDataChanged);
    reservationsProvider.removeListener(_onDataChanged);
    packingProvider.removeListener(_onDataChanged);
    memoriesProvider.removeListener(_onDataChanged);
    super.dispose();
  }
}
