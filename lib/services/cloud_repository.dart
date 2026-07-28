import '../models/cloud_account.dart';

/// Architecture seam for a real remote backend — Google Drive, iCloud, or
/// Dropbox — that would let backups sync across a family's devices. No
/// vendor is connected yet: today, "sync" means [BackupRepository] persists
/// to this device only. [SyncService] checks [isConnected] and quietly
/// falls back to local-only backups when it's false, so wiring up a real
/// provider later only means implementing this interface and does not
/// require touching the UI or [SyncService]'s orchestration logic.
abstract class CloudRepository {
  CloudProviderKind get providerKind;

  bool get isConnected;

  Future<CloudAccountInfo?> currentAccount();

  /// Pushes one trip's full snapshot (as JSON) to the cloud, keyed by trip
  /// id, so it can be pulled down on another signed-in device.
  Future<void> uploadTripSnapshot(String tripId, Map<String, dynamic> snapshotJson);

  /// Pulls the latest snapshot the cloud has for [tripId], or null if the
  /// cloud has nothing for it yet.
  Future<Map<String, dynamic>?> downloadTripSnapshot(String tripId);

  /// All trip ids the signed-in account has backed up to the cloud — how a
  /// newly signed-in device would discover "all trips should automatically
  /// appear".
  Future<List<String>> listRemoteTripIds();
}

/// No cloud vendor is wired up yet. Every call throws on purpose — a
/// deliberate, visible signal when this gets swapped in for real, rather
/// than a silent no-op somewhere in [SyncService]. Mirrors
/// `UnavailablePrintingService`.
class UnavailableCloudRepository implements CloudRepository {
  const UnavailableCloudRepository(this.providerKind);

  @override
  final CloudProviderKind providerKind;

  @override
  bool get isConnected => false;

  @override
  Future<CloudAccountInfo?> currentAccount() async => null;

  @override
  Future<void> uploadTripSnapshot(String tripId, Map<String, dynamic> snapshotJson) {
    throw UnimplementedError('${providerKind.label} is not connected yet.');
  }

  @override
  Future<Map<String, dynamic>?> downloadTripSnapshot(String tripId) {
    throw UnimplementedError('${providerKind.label} is not connected yet.');
  }

  @override
  Future<List<String>> listRemoteTripIds() {
    throw UnimplementedError('${providerKind.label} is not connected yet.');
  }
}
