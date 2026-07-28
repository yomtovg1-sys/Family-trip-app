import 'trip_snapshot.dart';

/// How the family resolves a [SyncConflict] — surfaced as three buttons in
/// the conflict sheet, e.g. "This trip was modified on another device."
enum ConflictChoice { keepNewest, keepLocal, merge }

extension ConflictChoiceX on ConflictChoice {
  String get label {
    switch (this) {
      case ConflictChoice.keepNewest:
        return 'Keep newest version';
      case ConflictChoice.keepLocal:
        return 'Keep local version';
      case ConflictChoice.merge:
        return 'Merge automatically';
    }
  }

  String get description {
    switch (this) {
      case ConflictChoice.keepNewest:
        return 'Use whichever copy was saved most recently.';
      case ConflictChoice.keepLocal:
        return "Keep what's on this device and discard the other copy.";
      case ConflictChoice.merge:
        return 'Combine both copies field by field where possible.';
    }
  }
}

/// The same trip exists in two places — on this device and in an incoming
/// snapshot (a restore, an import, or a future cloud pull) — with
/// conflicting data. Built by [SyncService]/[TripImportService] and resolved
/// by [ConflictResolver].
class SyncConflict {
  final String tripId;
  final String tripName;
  final TripSnapshot local;
  final TripSnapshot incoming;

  const SyncConflict({
    required this.tripId,
    required this.tripName,
    required this.local,
    required this.incoming,
  });

  DateTime get localModifiedAt => local.capturedAt;
  DateTime get incomingModifiedAt => incoming.capturedAt;

  /// Whether the two copies actually differ, or this is a false alarm (same
  /// trip id but identical content) that can be resolved without asking.
  bool get isMeaningful => local.trip.toJson().toString() != incoming.trip.toJson().toString() ||
      local.itemCount != incoming.itemCount;
}
