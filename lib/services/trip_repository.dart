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

/// Persists trips on-device via Hive. A genuine first launch loads an empty
/// list — a new installation starts with no trips, so the family creates
/// their first one themselves.
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
    return HiveTripRepository._(store, store.getAll());
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
