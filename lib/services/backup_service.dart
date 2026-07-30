import '../models/backup_meta.dart';
import '../models/backup_snapshot.dart';
import 'backup_repository.dart';

/// The mid-level API for creating and restoring backups: coordinates
/// [BackupRepository] (where snapshots live) with a snapshot builder
/// supplied by the caller (in practice, [BackupManager] closing over the
/// live providers). Kept free of any Flutter/provider dependency so it's
/// easy to reason about and test on its own.
class BackupService {
  final BackupRepository repository;
  final Future<BackupSnapshot> Function() buildSnapshot;

  BackupService({required this.repository, required this.buildSnapshot});

  Future<BackupMeta> createManualBackup() async =>
      repository.saveBackup(await buildSnapshot(), trigger: BackupTrigger.manual);

  Future<BackupMeta> createAutomaticBackup() async =>
      repository.saveBackup(await buildSnapshot(), trigger: BackupTrigger.automatic);

  Future<List<BackupMeta>> listBackups() => repository.listBackups();

  Future<BackupMeta?> latestBackup() => repository.latestBackup();

  Future<int> storageUsedBytes() => repository.totalStorageUsedBytes();

  Future<void> deleteBackup(String backupId) => repository.deleteBackup(backupId);

  /// Loads the backup to restore, first safeguarding the current state with
  /// its own backup — so a restore is never a one-way door. Returns null if
  /// [backupId] no longer exists.
  Future<BackupSnapshot?> prepareRestore(String backupId) async {
    await repository.saveBackup(await buildSnapshot(), trigger: BackupTrigger.beforeRestore);
    return repository.loadBackup(backupId);
  }
}
