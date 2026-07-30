/// The state shown by the small sync indicator on the Sync & Backup screen.
/// The feature is meant to work silently — most of these values render as a
/// quiet checkmark or nothing at all; only [error] and [conflict] are meant
/// to actively call for attention.
enum SyncStatus { idle, syncing, synced, offline, error, conflict }

extension SyncStatusX on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.idle:
        return 'Up to date';
      case SyncStatus.syncing:
        return 'Syncing…';
      case SyncStatus.synced:
        return 'Synced successfully';
      case SyncStatus.offline:
        return 'Offline — will sync later';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.conflict:
        return 'Needs your attention';
    }
  }

  bool get needsAttention => this == SyncStatus.error || this == SyncStatus.conflict;
}
