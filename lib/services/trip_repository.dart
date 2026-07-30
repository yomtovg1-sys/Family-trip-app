import '../models/trip.dart';
import 'hive_json_store.dart';

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

/// Persists trips on-device via Hive. Seeds the family's three starter
/// trips only on a genuine first launch (an empty box); once real trips
/// exist, they're what gets loaded — the seed data never overwrites them.
class HiveTripRepository implements TripRepository {
  final HiveJsonStore<Trip> _store;
  final List<Trip> _trips;

  HiveTripRepository._(this._store, this._trips);

  static Future<HiveTripRepository> open() async {
    final store = await HiveJsonStore.open<Trip>(
      'trips',
      toJson: (t) => t.toJson(),
      fromJson: Trip.fromJson,
      idOf: (t) => t.id,
    );
    final trips = store.isEmpty ? InMemoryTripRepository._seedTrips() : store.getAll();
    if (store.isEmpty) store.putAll(trips);
    return HiveTripRepository._(store, trips);
  }

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
  void add(Trip trip) {
    _trips.add(trip);
    _store.put(trip);
  }

  @override
  void update(Trip trip) {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
    } else {
      _trips.add(trip);
    }
    _store.put(trip);
  }

  @override
  void remove(String id) {
    _trips.removeWhere((t) => t.id == id);
    _store.remove(id);
  }
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
