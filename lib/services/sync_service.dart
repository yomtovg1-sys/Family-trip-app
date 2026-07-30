import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cloud_account.dart';
import '../models/sync_status.dart';
import 'backup_manager.dart';
import 'cloud_repository.dart';
import 'settings_repository.dart';

/// The top-level "is everything backed up and in sync" state machine shown
/// on the Sync & Backup screen. Local persistence (via [BackupManager]) is
/// the part that actually works today; pushing to [CloudRepository] is the
/// forward-looking half that quietly reports [SyncStatus.offline] instead
/// of an error until a real provider is connected — see [CloudRepository]
/// for why. The pending-trip queue below is the real offline sync queue:
/// it fills up as trips change and drains the moment a cloud push succeeds,
/// so wiring in a provider later doesn't require touching this class.
class SyncService extends ChangeNotifier {
  final BackupManager backupManager;
  final CloudRepository cloudRepository;
  final SettingsRepository settingsRepository;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncedAt;
  CloudAccountInfo? _connectedAccount;
  final Set<String> _pendingTripIds = {};
  String? _lastErrorMessage;

  SyncService({
    required this.backupManager,
    required this.cloudRepository,
    required this.settingsRepository,
  }) {
    backupManager.addListener(_onBackupChanged);
    unawaited(_init());
  }

  SyncStatus get status => _status;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  CloudAccountInfo? get connectedAccount => _connectedAccount;
  int get pendingChangesCount => _pendingTripIds.length;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get isCloudConnected => cloudRepository.isConnected;

  Future<void> _init() async {
    _connectedAccount = await settingsRepository.getConnectedAccount();
    final latest = backupManager.latestBackup;
    if (latest != null) {
      _lastSyncedAt = latest.createdAt;
      _status = SyncStatus.synced;
    }
    notifyListeners();
  }

  void _onBackupChanged() {
    if (backupManager.isBackingUp) {
      _status = SyncStatus.syncing;
      notifyListeners();
      return;
    }
    final meta = backupManager.latestBackup;
    if (meta == null) return;
    _lastSyncedAt = meta.createdAt;
    for (final dashboard in backupManager.tripProvider.all) {
      _pendingTripIds.add(dashboard.trip.id);
    }
    unawaited(_pushPending());
  }

  Future<void> _pushPending() async {
    if (!cloudRepository.isConnected) {
      _status = _pendingTripIds.isEmpty ? SyncStatus.synced : SyncStatus.offline;
      notifyListeners();
      return;
    }

    _status = SyncStatus.syncing;
    notifyListeners();
    try {
      for (final tripId in _pendingTripIds.toList()) {
        final snapshot = backupManager.buildTripSnapshot(tripId);
        await cloudRepository.uploadTripSnapshot(tripId, snapshot.toJson());
        _pendingTripIds.remove(tripId);
      }
      _status = SyncStatus.synced;
      _lastErrorMessage = null;
    } catch (e) {
      _status = SyncStatus.error;
      _lastErrorMessage = e.toString();
    }
    notifyListeners();
  }

  /// "Sync now": takes a fresh local backup — which always succeeds — and
  /// then attempts to push the pending trips to the cloud.
  Future<void> syncNow() async {
    await backupManager.createManualBackup();
  }

  /// Retries whatever is still queued for the cloud. The seam automatic
  /// retry (on reconnect, on a timer, ...) would call into.
  Future<void> retry() => _pushPending();

  @override
  void dispose() {
    backupManager.removeListener(_onBackupChanged);
    super.dispose();
  }
}
