import 'expense_entry.dart';
import 'journey_stop.dart';
import 'memory_photo.dart';
import 'place.dart';
import 'reservation.dart';
import 'travel_document.dart';
import 'trip.dart';

/// Everything one trip owns, captured at a single point in time. This is the
/// unit both full app backups and single-trip export/import work with, and
/// [capturedAt] is what [ConflictResolver] compares when the same trip shows
/// up from two different sources (e.g. a local copy and an imported file).
class TripSnapshot {
  final Trip trip;
  final List<JourneyStop> journeyStops;
  final List<SavedPlace> places;
  final List<Reservation> reservations;
  final List<ExpenseEntry> expenses;
  final List<TravelDocument> documents;
  final List<MemoryPhoto> photos;
  final DateTime capturedAt;

  const TripSnapshot({
    required this.trip,
    required this.journeyStops,
    required this.places,
    required this.reservations,
    required this.expenses,
    required this.documents,
    required this.photos,
    required this.capturedAt,
  });

  int get itemCount =>
      journeyStops.length +
      places.length +
      reservations.length +
      expenses.length +
      documents.length +
      photos.length;

  Map<String, dynamic> toJson() => {
        'trip': trip.toJson(),
        'journeyStops': [for (final s in journeyStops) s.toJson()],
        'places': [for (final p in places) p.toJson()],
        'reservations': [for (final r in reservations) r.toJson()],
        'expenses': [for (final e in expenses) e.toJson()],
        'documents': [for (final d in documents) d.toJson()],
        'photos': [for (final p in photos) p.toJson()],
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory TripSnapshot.fromJson(Map<String, dynamic> json) {
    return TripSnapshot(
      trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
      journeyStops: [
        for (final s in (json['journeyStops'] as List? ?? const []))
          JourneyStop.fromJson(s as Map<String, dynamic>),
      ],
      places: [
        for (final p in (json['places'] as List? ?? const []))
          SavedPlace.fromJson(p as Map<String, dynamic>),
      ],
      reservations: [
        for (final r in (json['reservations'] as List? ?? const []))
          Reservation.fromJson(r as Map<String, dynamic>),
      ],
      expenses: [
        for (final e in (json['expenses'] as List? ?? const []))
          ExpenseEntry.fromJson(e as Map<String, dynamic>),
      ],
      documents: [
        for (final d in (json['documents'] as List? ?? const []))
          TravelDocument.fromJson(d as Map<String, dynamic>),
      ],
      photos: [
        for (final p in (json['photos'] as List? ?? const []))
          MemoryPhoto.fromJson(p as Map<String, dynamic>),
      ],
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );
  }
}
