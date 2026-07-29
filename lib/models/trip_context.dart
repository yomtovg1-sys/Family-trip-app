import 'trip.dart';

/// The identity of whichever trip is currently active — the one thing
/// nearly every screen needs and the reason [TripManager] exists. Screens
/// depend on this instead of reaching into trip-selection state directly,
/// so switching trips is a single, traceable event every screen reacts to
/// the same way.
class TripContext {
  final Trip trip;

  const TripContext({required this.trip});

  String get tripId => trip.id;
}
