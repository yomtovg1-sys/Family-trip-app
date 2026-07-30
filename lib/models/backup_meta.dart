/// What caused a backup to be created — shown in the backup history and used
/// to tell an automatic "quiet" backup apart from one the user asked for.
enum BackupTrigger { manual, automatic, beforeRestore }

extension BackupTriggerX on BackupTrigger {
  String get label {
    switch (this) {
      case BackupTrigger.manual:
        return 'Manual backup';
      case BackupTrigger.automatic:
        return 'Automatic backup';
      case BackupTrigger.beforeRestore:
        return 'Safety backup before restore';
    }
  }
}

/// Metadata about one stored backup snapshot — everything the Sync & Backup
/// screen needs to list and describe a backup without loading its full,
/// potentially large, JSON payload.
class BackupMeta {
  final String id;
  final DateTime createdAt;
  final BackupTrigger trigger;
  final int sizeBytes;
  final int tripCount;

  const BackupMeta({
    required this.id,
    required this.createdAt,
    required this.trigger,
    required this.sizeBytes,
    required this.tripCount,
  });

  String get sizeLabel {
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'trigger': trigger.name,
        'sizeBytes': sizeBytes,
        'tripCount': tripCount,
      };

  factory BackupMeta.fromJson(Map<String, dynamic> json) {
    return BackupMeta(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      trigger: BackupTrigger.values.byName(json['trigger'] as String),
      sizeBytes: json['sizeBytes'] as int,
      tripCount: json['tripCount'] as int,
    );
  }
}
