import '../models/trip.dart';

/// Storage for [Trip] identity records — name, destination, dates, currency.
/// This is the single place a [Trip] is created or edited; every other
/// provider (places, reservations, packing, ...) only ever stores data
/// keyed by a trip id it looks up here, so a trip's core details exist in
/// exactly one place.
abstract class TripRepository {
  List<Trip> getAll();
  Trip? byId(String id);
  void add(Trip trip);
  void update(Trip trip);
  void remove(String id);
}

/// In-memory implementation, seeded with the family's three trips.
class InMemoryTripRepository implements TripRepository {
  final List<Trip> _trips = _seedTrips();

  @override
  List<Trip> getAll() => List.unmodifiable(_trips);

  @override
  Trip? byId(String id) {
    for (final trip in _trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  @override
  void add(Trip trip) => _trips.add(trip);

  @override
  void update(Trip trip) {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
    } else {
      _trips.add(trip);
    }
  }

  @override
  void remove(String id) => _trips.removeWhere((t) => t.id == id);

  static List<Trip> _seedTrips() {
    final now = DateTime.now();
    return [
      Trip(
        id: 'trip-tahoe',
        name: 'Griswold Family Summer Adventure',
        destination: 'Lake Tahoe, California',
        startDate: now.add(const Duration(days: 21)),
        endDate: now.add(const Duration(days: 28)),
        heroEmoji: '🏔️',
        flagEmoji: '🇺🇸',
        photoAsset: 'assets/images/family_hero.jpg',
        currency: 'USD',
      ),
      Trip(
        id: 'trip-japan',
        name: 'Japan Family Adventure',
        destination: 'Tokyo, Japan',
        startDate: now.add(const Duration(days: 410)),
        endDate: now.add(const Duration(days: 424)),
        heroEmoji: '🗼',
        flagEmoji: '🇯🇵',
        currency: 'JPY',
      ),
      Trip(
        id: 'trip-italy',
        name: 'Italy Family Trip',
        destination: 'Rome, Italy',
        startDate: now.subtract(const Duration(days: 201)),
        endDate: now.subtract(const Duration(days: 191)),
        heroEmoji: '🍝',
        flagEmoji: '🇮🇹',
        currency: 'EUR',
      ),
    ];
  }
}
