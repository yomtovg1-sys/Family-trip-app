import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/backup_snapshot.dart';
import '../models/packing_item.dart';
import '../models/sync_conflict.dart';
import '../models/trip_snapshot.dart';
import 'conflict_resolver.dart';

/// What came out of trying to read an imported file. [errorMessage] is set
/// only when the file couldn't be understood at all (not valid JSON, wrong
/// shape, or a schema version this app doesn't know); trips whose ids don't
/// collide with anything on this device land in [readyTrips] and can be
/// applied immediately, while trips that do collide land in [conflicts] for
/// the family to resolve one at a time.
class ImportOutcome {
  final bool isValid;
  final String? errorMessage;
  final List<TripSnapshot> readyTrips;
  final List<SyncConflict> conflicts;
  final List<PackingItem>? packingItems;

  const ImportOutcome._({
    required this.isValid,
    this.errorMessage,
    this.readyTrips = const [],
    this.conflicts = const [],
    this.packingItems,
  });

  factory ImportOutcome.invalid(String message) => ImportOutcome._(isValid: false, errorMessage: message);

  factory ImportOutcome.valid({
    required List<TripSnapshot> readyTrips,
    required List<SyncConflict> conflicts,
    List<PackingItem>? packingItems,
  }) =>
      ImportOutcome._(
        isValid: true,
        readyTrips: readyTrips,
        conflicts: conflicts,
        packingItems: packingItems,
      );

  bool get hasConflicts => conflicts.isNotEmpty;
}

/// Reads a previously-exported backup or a single shared-trip file, checks
/// it's a shape this app understands, and sorts each trip it contains into
/// "safe to apply" or "needs conflict resolution" against what's already on
/// this device. Never writes to any provider itself — [BackupManager] does
/// the actual applying, once the family (or the caller, for the
/// no-conflict case) has decided what to do.
class TripImportService {
  final ConflictResolver conflictResolver;

  const TripImportService({this.conflictResolver = const ConflictResolver()});

  /// Opens the platform file picker for a `.json` export/backup file.
  Future<Uint8List?> pickImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result?.files.single.bytes;
  }

  ImportOutcome parseAndValidate(Uint8List bytes, {required List<TripSnapshot> existingTrips}) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      return ImportOutcome.invalid("This file isn't valid JSON.");
    }

    try {
      if (json.containsKey('trips')) {
        return _validateBackup(BackupSnapshot.fromJson(json), existingTrips);
      }
      if (json.containsKey('trip')) {
        return _validateSingleTrip(TripSnapshot.fromJson(json), existingTrips);
      }
    } catch (_) {
      return ImportOutcome.invalid("This file doesn't look like a trip backup or shared trip.");
    }

    return ImportOutcome.invalid("This file doesn't look like a trip backup or shared trip.");
  }

  ImportOutcome _validateBackup(BackupSnapshot backup, List<TripSnapshot> existingTrips) {
    if (backup.schemaVersion > backupSchemaVersion) {
      return ImportOutcome.invalid(
        'This backup was created by a newer version of the app and can\'t be read yet.',
      );
    }
    if (backup.trips.isEmpty) {
      return ImportOutcome.invalid('This backup is empty — nothing to import.');
    }

    final ready = <TripSnapshot>[];
    final conflicts = <SyncConflict>[];
    for (final incoming in backup.trips) {
      _sortIncoming(incoming, existingTrips, ready, conflicts);
    }

    return ImportOutcome.valid(readyTrips: ready, conflicts: conflicts, packingItems: backup.packingItems);
  }

  ImportOutcome _validateSingleTrip(TripSnapshot incoming, List<TripSnapshot> existingTrips) {
    if (incoming.trip.id.trim().isEmpty || incoming.trip.name.trim().isEmpty) {
      return ImportOutcome.invalid('This trip file is missing required fields.');
    }

    final ready = <TripSnapshot>[];
    final conflicts = <SyncConflict>[];
    _sortIncoming(incoming, existingTrips, ready, conflicts);

    return ImportOutcome.valid(readyTrips: ready, conflicts: conflicts);
  }

  void _sortIncoming(
    TripSnapshot incoming,
    List<TripSnapshot> existingTrips,
    List<TripSnapshot> ready,
    List<SyncConflict> conflicts,
  ) {
    TripSnapshot? existing;
    for (final e in existingTrips) {
      if (e.trip.id == incoming.trip.id) {
        existing = e;
        break;
      }
    }

    if (existing == null) {
      ready.add(incoming);
      return;
    }

    final conflict = conflictResolver.detect(local: existing, incoming: incoming);
    if (conflict == null) {
      // Same id, no meaningful difference — nothing new to apply.
      return;
    }
    conflicts.add(conflict);
  }
}
