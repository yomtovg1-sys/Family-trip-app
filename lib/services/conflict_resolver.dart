import '../models/journey_stop.dart';
import '../models/sync_conflict.dart';
import '../models/trip.dart';
import '../models/trip_snapshot.dart';

/// Resolves a [SyncConflict] the family has been shown (e.g. "This trip was
/// modified on another device") into a single [TripSnapshot], according to
/// their chosen [ConflictChoice]. Pure, synchronous, and side-effect free —
/// callers decide what to do with the result (save it, restore it, ...).
class ConflictResolver {
  const ConflictResolver();

  /// Compares a trip already on this device with one arriving from a
  /// restore, import, or (in future) a cloud pull. Returns a [SyncConflict]
  /// only when the two copies genuinely differ — an incoming copy that's
  /// identical, or a trip id local doesn't have at all, isn't a conflict.
  SyncConflict? detect({required TripSnapshot local, required TripSnapshot incoming}) {
    if (local.trip.id != incoming.trip.id) return null;
    final conflict = SyncConflict(
      tripId: local.trip.id,
      tripName: local.trip.name,
      local: local,
      incoming: incoming,
    );
    return conflict.isMeaningful ? conflict : null;
  }

  TripSnapshot resolve(SyncConflict conflict, ConflictChoice choice) {
    switch (choice) {
      case ConflictChoice.keepLocal:
        return conflict.local;
      case ConflictChoice.keepNewest:
        return _newerOf(conflict.local, conflict.incoming);
      case ConflictChoice.merge:
        return _merge(conflict.local, conflict.incoming);
    }
  }

  TripSnapshot _newerOf(TripSnapshot a, TripSnapshot b) =>
      a.capturedAt.isAfter(b.capturedAt) ? a : b;

  /// Combines both copies: trip metadata comes from whichever side is newer,
  /// and every list (places, reservations, expenses, documents, photos) is a
  /// union deduplicated by id — where both sides have the same id, the
  /// newer side's version wins. Journey stops have no id, so they're
  /// deduplicated by (location, start, end) instead.
  TripSnapshot _merge(TripSnapshot local, TripSnapshot incoming) {
    final newer = _newerOf(local, incoming);
    final older = identical(newer, local) ? incoming : local;

    final mergedTrip = Trip(
      id: newer.trip.id,
      name: newer.trip.name,
      destination: newer.trip.destination,
      startDate: newer.trip.startDate,
      endDate: newer.trip.endDate,
      heroEmoji: newer.trip.heroEmoji,
      flagEmoji: newer.trip.flagEmoji,
      country: newer.trip.country ?? older.trip.country,
      photoBytes: newer.trip.photoBytes ?? older.trip.photoBytes,
      currency: newer.trip.currency,
    );

    return TripSnapshot(
      trip: mergedTrip,
      journeyStops: _mergeJourneyStops(newer.journeyStops, older.journeyStops),
      places: _mergeById(newer.places, older.places, (p) => p.id),
      reservations: _mergeById(newer.reservations, older.reservations, (r) => r.id),
      expenses: _mergeById(newer.expenses, older.expenses, (e) => e.id),
      documents: _mergeById(newer.documents, older.documents, (d) => d.id),
      photos: _mergeById(newer.photos, older.photos, (p) => p.id),
      capturedAt: DateTime.now(),
    );
  }

  List<T> _mergeById<T>(List<T> newer, List<T> older, String Function(T) idOf) {
    final byId = <String, T>{for (final item in older) idOf(item): item};
    for (final item in newer) {
      byId[idOf(item)] = item;
    }
    return byId.values.toList();
  }

  List<JourneyStop> _mergeJourneyStops(List<JourneyStop> newer, List<JourneyStop> older) {
    String key(JourneyStop s) => '${s.location}|${s.start.toIso8601String()}|${s.end.toIso8601String()}';
    final byKey = <String, JourneyStop>{for (final s in older) key(s): s};
    for (final s in newer) {
      byKey[key(s)] = s;
    }
    return byKey.values.toList();
  }
}
