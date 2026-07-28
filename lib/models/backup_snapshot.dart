import 'packing_item.dart';
import 'trip_snapshot.dart';

/// Bumped whenever the shape of [BackupSnapshot.toJson] changes in a way
/// that isn't backward compatible, so [TripImportService] can reject a file
/// it doesn't know how to read instead of silently corrupting data.
const int backupSchemaVersion = 1;

/// A full, self-contained copy of everything the app knows: every trip
/// (each as a [TripSnapshot]) plus the app-wide packing list, which isn't
/// scoped to a single trip today. This is what a manual/automatic backup
/// stores and what "Restore from backup" reads back.
///
/// [aiConversations] is a forward-compatible placeholder: chat history in
/// this app is currently kept per-screen-instance only (see
/// `AIChatController`), not in a persisted, app-wide store, so there is
/// nothing real to serialize yet. The field exists so wiring up persistent
/// AI history later is additive, not a schema break, and so the "include AI
/// conversations" setting already has somewhere to write to.
class BackupSnapshot {
  final int schemaVersion;
  final DateTime capturedAt;
  final List<TripSnapshot> trips;
  final List<PackingItem> packingItems;
  final List<Map<String, dynamic>> aiConversations;
  final Map<String, dynamic> settings;

  const BackupSnapshot({
    this.schemaVersion = backupSchemaVersion,
    required this.capturedAt,
    required this.trips,
    required this.packingItems,
    this.aiConversations = const [],
    this.settings = const {},
  });

  int get tripCount => trips.length;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'capturedAt': capturedAt.toIso8601String(),
        'trips': [for (final t in trips) t.toJson()],
        'packingItems': [for (final p in packingItems) p.toJson()],
        'aiConversations': aiConversations,
        'settings': settings,
      };

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) {
    return BackupSnapshot(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      trips: [
        for (final t in (json['trips'] as List? ?? const []))
          TripSnapshot.fromJson(t as Map<String, dynamic>),
      ],
      packingItems: [
        for (final p in (json['packingItems'] as List? ?? const []))
          PackingItem.fromJson(p as Map<String, dynamic>),
      ],
      aiConversations: [
        for (final c in (json['aiConversations'] as List? ?? const [])) c as Map<String, dynamic>,
      ],
      settings: (json['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
