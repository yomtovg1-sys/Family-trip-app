import 'dart:convert';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
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

/// Persists snapshots via Hive (IndexedDB on web) — real on-device storage,
/// not an in-memory fake, so a backup taken now is still there after a page
/// reload. Backup snapshots can carry base64 photo/document bytes and grow
/// well past what `shared_preferences`/localStorage can reliably hold on
/// web (~5-10MB total, previously this repository's actual backend); Hive
/// has no such ceiling. Keeps only the most recent [maxHistory] backups so
/// storage doesn't grow without bound; older ones are evicted automatically,
/// oldest first.
class HiveBackupRepository implements BackupRepository {
  static const _indexKey = 'index';
  static String _snapshotKey(String id) => 'snapshot.$id';

  final Box<String> _box;
  final int maxHistory;

  HiveBackupRepository._(this._box, {this.maxHistory = 10});

  static Future<HiveBackupRepository> open({int maxHistory = 10}) async {
    final box = await Hive.openBox<String>('backups');
    return HiveBackupRepository._(box, maxHistory: maxHistory);
  }

  List<BackupMeta> _readIndex() {
    final raw = _box.get(_indexKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return [for (final e in list) BackupMeta.fromJson(e as Map<String, dynamic>)];
  }

  void _writeIndex(List<BackupMeta> index) {
    _box.put(_indexKey, jsonEncode([for (final m in index) m.toJson()]));
  }

  @override
  Future<BackupMeta> saveBackup(BackupSnapshot snapshot, {required BackupTrigger trigger}) async {
    final payload = jsonEncode(snapshot.toJson());
    final id = 'backup-${DateTime.now().microsecondsSinceEpoch}';

    _box.put(_snapshotKey(id), payload);

    final meta = BackupMeta(
      id: id,
      createdAt: snapshot.capturedAt,
      trigger: trigger,
      sizeBytes: payload.length,
      tripCount: snapshot.tripCount,
    );

    final index = _readIndex()..add(meta);
    index.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    while (index.length > maxHistory) {
      final evicted = index.removeLast();
      _box.delete(_snapshotKey(evicted.id));
    }

    _writeIndex(index);
    return meta;
  }

  @override
  Future<List<BackupMeta>> listBackups() async {
    final index = _readIndex();
    index.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return index;
  }

  @override
  Future<BackupSnapshot?> loadBackup(String backupId) async {
    final raw = _box.get(_snapshotKey(backupId));
    if (raw == null) return null;
    return BackupSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBackup(String backupId) async {
    _box.delete(_snapshotKey(backupId));
    final index = _readIndex()..removeWhere((m) => m.id == backupId);
    _writeIndex(index);
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
