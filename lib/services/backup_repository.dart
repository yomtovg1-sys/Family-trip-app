import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/backup_meta.dart';
import '../models/backup_snapshot.dart';

/// On-device storage for backup snapshots — the part of Sync & Backup that
/// works today with no cloud vendor required. [CloudRepository] is the seam
/// for pushing these same snapshots to Drive/iCloud/Dropbox later; this
/// repository is what makes "Create a manual backup" and "Restore from
/// backup" actually work in the meantime.
abstract class BackupRepository {
  Future<BackupMeta> saveBackup(BackupSnapshot snapshot, {required BackupTrigger trigger});
  Future<List<BackupMeta>> listBackups();
  Future<BackupSnapshot?> loadBackup(String backupId);
  Future<void> deleteBackup(String backupId);
  Future<BackupMeta?> latestBackup();
  Future<int> totalStorageUsedBytes();
}

/// Persists snapshots as JSON strings via `shared_preferences` — real
/// on-device storage, not an in-memory fake, so a backup taken now is still
/// there after a page reload. Keeps only the most recent [maxHistory]
/// backups so storage doesn't grow without bound; older ones are evicted
/// automatically, oldest first.
class LocalBackupRepository implements BackupRepository {
  static const _indexKey = 'sync_backup.index';
  static String _snapshotKey(String id) => 'sync_backup.snapshot.$id';

  final int maxHistory;

  LocalBackupRepository({this.maxHistory = 10});

  Future<List<BackupMeta>> _readIndex(SharedPreferences prefs) async {
    final raw = prefs.getString(_indexKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return [for (final e in list) BackupMeta.fromJson(e as Map<String, dynamic>)];
  }

  Future<void> _writeIndex(SharedPreferences prefs, List<BackupMeta> index) async {
    await prefs.setString(_indexKey, jsonEncode([for (final m in index) m.toJson()]));
  }

  @override
  Future<BackupMeta> saveBackup(BackupSnapshot snapshot, {required BackupTrigger trigger}) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(snapshot.toJson());
    final id = 'backup-${DateTime.now().microsecondsSinceEpoch}';

    await prefs.setString(_snapshotKey(id), payload);

    final meta = BackupMeta(
      id: id,
      createdAt: snapshot.capturedAt,
      trigger: trigger,
      sizeBytes: payload.length,
      tripCount: snapshot.tripCount,
    );

    final index = await _readIndex(prefs)
      ..add(meta);
    index.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    while (index.length > maxHistory) {
      final evicted = index.removeLast();
      await prefs.remove(_snapshotKey(evicted.id));
    }

    await _writeIndex(prefs, index);
    return meta;
  }

  @override
  Future<List<BackupMeta>> listBackups() async {
    final prefs = await SharedPreferences.getInstance();
    final index = await _readIndex(prefs);
    index.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return index;
  }

  @override
  Future<BackupSnapshot?> loadBackup(String backupId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey(backupId));
    if (raw == null) return null;
    return BackupSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBackup(String backupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotKey(backupId));
    final index = await _readIndex(prefs)..removeWhere((m) => m.id == backupId);
    await _writeIndex(prefs, index);
  }

  @override
  Future<BackupMeta?> latestBackup() async {
    final backups = await listBackups();
    return backups.isEmpty ? null : backups.first;
  }

  @override
  Future<int> totalStorageUsedBytes() async {
    final backups = await listBackups();
    return backups.fold<int>(0, (sum, m) => sum + m.sizeBytes);
  }
}
