import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/expense_entry.dart';
import '../models/journey_stop.dart';
import '../models/travel_alert.dart';
import '../models/travel_document.dart';
import '../models/trip.dart';
import '../models/trip_snapshot.dart';
import '../models/weather_snapshot.dart';
import '../services/trip_manager.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Everything the Home dashboard needs for one trip: the trip itself, its
/// route/journey, a weather snapshot, running expenses, trip-level travel
/// wallet documents, and an optional passport-expiry date used to derive
/// alerts.
class TripDashboard {
  final Trip trip;
  final List<JourneyStop> journeyStops;
  final WeatherSnapshot? weather;
  final List<ExpenseEntry> expenses;
  final List<TravelDocument> documents;
  final DateTime? passportExpiryDate;

  TripDashboard({
    required this.trip,
    required this.journeyStops,
    required this.weather,
    required this.expenses,
    List<TravelDocument>? documents,
    this.passportExpiryDate,
  }) : documents = documents ?? [];

  /// The journey stop that should currently be highlighted: the first stop
  /// if the trip hasn't started yet, the last stop if it's over, or the
  /// active leg of the trip right now.
  JourneyStop get displayStop {
    if (journeyStops.isEmpty) {
      throw StateError('TripDashboard requires at least one journey stop');
    }
    if (!trip.hasStarted) return journeyStops.first;
    if (trip.hasEnded) return journeyStops.last;
    final now = DateTime.now();
    for (final stop in journeyStops.reversed) {
      if (!now.isBefore(stop.start)) return stop;
    }
    return journeyStops.first;
  }

  JourneyStop? get nextStop {
    final index = journeyStops.indexOf(displayStop);
    if (index >= 0 && index + 1 < journeyStops.length) {
      return journeyStops[index + 1];
    }
    return null;
  }

  String get locationSectionLabel {
    if (trip.hasEnded) return 'Where you explored';
    if (trip.hasStarted) return 'Current location';
    return 'First stop';
  }

  double get totalExpenses => expenses.fold(0, (sum, e) => sum + e.amount);

  double get todayExpenses {
    final now = DateTime.now();
    return expenses
        .where((e) => _isSameDay(e.date, now))
        .fold(0, (sum, e) => sum + e.amount);
  }

  Map<ExpenseCategory, double> get expensesByCategory {
    final map = <ExpenseCategory, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  List<TravelAlert> get alerts {
    final alerts = <TravelAlert>[];
    final now = DateTime.now();

    if (!trip.hasStarted) {
      final hoursUntil = trip.timeUntilStart.inHours;
      if (_in24hWindow(hoursUntil)) {
        alerts.add(TravelAlert(
          id: 'checkin-${trip.id}',
          icon: Icons.flight_takeoff_rounded,
          message: 'Flight check-in opens tomorrow',
          severity: AlertSeverity.warning,
        ));
      }
    }

    if (trip.hasStarted && !trip.hasEnded) {
      final stop = displayStop;
      if (_isSameDay(stop.start, now)) {
        alerts.add(TravelAlert(
          id: 'checkin-hotel-${trip.id}',
          icon: Icons.hotel_rounded,
          message: 'Hotel check-in today at ${stop.location}',
          severity: AlertSeverity.info,
        ));
      }
    }

    final passportExpiry = passportExpiryDate;
    if (passportExpiry != null && !trip.hasEnded) {
      final daysUntilExpiry = passportExpiry.difference(now).inDays;
      if (daysUntilExpiry <= 180) {
        alerts.add(TravelAlert(
          id: 'passport-${trip.id}',
          icon: Icons.badge_rounded,
          message: 'Passport expires in $daysUntilExpiry days — renew before travel',
          severity: AlertSeverity.urgent,
        ));
      }
    }

    return alerts;
  }

  bool _in24hWindow(int hoursUntil) => hoursUntil > 0 && hoursUntil <= 24;
}

/// Dashboard-only data for one trip — everything [TripDashboard] needs
/// besides the [Trip] identity itself, which lives in [TripManager]/
/// [TripRepository] and is never duplicated here.
class _DashboardExtras {
  final List<JourneyStop> journeyStops;
  final WeatherSnapshot? weather;
  final List<ExpenseEntry> expenses;
  final List<TravelDocument> documents;
  final DateTime? passportExpiryDate;

  _DashboardExtras({
    required this.journeyStops,
    this.weather,
    required this.expenses,
    List<TravelDocument>? documents,
    this.passportExpiryDate,
  }) : documents = documents ?? [];

  /// A safe, always-valid default for a trip with no dashboard extras yet
  /// (e.g. one just created): a single journey stop spanning the whole
  /// trip, no expenses, no documents.
  factory _DashboardExtras.startingPoint(Trip trip) => _DashboardExtras(
        journeyStops: [JourneyStop(location: trip.destination, start: trip.startDate, end: trip.endDate)],
        expenses: [],
      );

  Map<String, dynamic> toJson() => {
        'journeyStops': [for (final s in journeyStops) s.toJson()],
        'weather': weather?.toJson(),
        'expenses': [for (final e in expenses) e.toJson()],
        'documents': [for (final d in documents) d.toJson()],
        'passportExpiryDate': passportExpiryDate?.toIso8601String(),
      };

  factory _DashboardExtras.fromJson(Map<String, dynamic> json) {
    return _DashboardExtras(
      journeyStops: [
        for (final s in json['journeyStops'] as List) JourneyStop.fromJson(s as Map<String, dynamic>),
      ],
      weather: json['weather'] == null ? null : WeatherSnapshot.fromJson(json['weather'] as Map<String, dynamic>),
      expenses: [for (final e in json['expenses'] as List) ExpenseEntry.fromJson(e as Map<String, dynamic>)],
      documents: [for (final d in json['documents'] as List) TravelDocument.fromJson(d as Map<String, dynamic>)],
      passportExpiryDate:
          json['passportExpiryDate'] == null ? null : DateTime.parse(json['passportExpiryDate'] as String),
    );
  }
}

/// The Home dashboard's view of trip data. [TripManager] is the source of
/// truth for which trips exist and which is active — this class only adds
/// the dashboard-specific extras (journey stops, weather, expenses,
/// trip-level documents) on top, keyed by the same trip ids, and mirrors
/// [TripManager]'s notifications so every screen watching [TripProvider]
/// (unchanged from before) keeps working exactly as it did.
class TripProvider extends ChangeNotifier {
  final TripManager tripManager;
  final Box<String> _extrasBox;
  final Map<String, _DashboardExtras> _extras;

  TripProvider._(this.tripManager, this._extrasBox, this._extras) {
    tripManager.addListener(_onTripManagerChanged);
  }

  /// Loads dashboard extras (journey stops, weather, expenses, trip-level
  /// documents, passport expiry) from Hive, keyed by trip id.
  static Future<TripProvider> open({required TripManager tripManager}) async {
    final box = await Hive.openBox<String>('dashboard_extras');
    final extras = {
      for (final key in box.keys)
        key as String: _DashboardExtras.fromJson(jsonDecode(box.get(key)!) as Map<String, dynamic>),
    };
    return TripProvider._(tripManager, box, extras);
  }

  void _onTripManagerChanged() => notifyListeners();

  void _persist(String tripId) {
    final extras = _extras[tripId];
    if (extras == null) return;
    _extrasBox.put(tripId, jsonEncode(extras.toJson()));
  }

  List<TripDashboard> get all => [for (final trip in tripManager.trips) _dashboardFor(trip)];

  TripDashboard get current => _dashboardFor(tripManager.currentTrip);

  Trip get trip => tripManager.currentTrip;

  TripDashboard _dashboardFor(Trip trip) {
    final extras = _extras[trip.id] ?? _DashboardExtras.startingPoint(trip);
    return TripDashboard(
      trip: trip,
      journeyStops: extras.journeyStops,
      weather: extras.weather,
      expenses: extras.expenses,
      documents: extras.documents,
      passportExpiryDate: extras.passportExpiryDate,
    );
  }

  _DashboardExtras _extrasFor(String tripId) {
    final existing = _extras[tripId];
    if (existing != null) return existing;
    final created = _DashboardExtras.startingPoint(_tripById(tripId));
    _extras[tripId] = created;
    _persist(tripId);
    return created;
  }

  Trip _tripById(String tripId) {
    for (final trip in tripManager.trips) {
      if (trip.id == tripId) return trip;
    }
    return tripManager.currentTrip;
  }

  void selectTrip(String tripId) => tripManager.selectTrip(tripId);

  void addTripDocument(String tripId, TravelDocument document) {
    _extrasFor(tripId).documents.add(document);
    _persist(tripId);
    notifyListeners();
  }

  void renameTripDocument(String tripId, String documentId, String newName) {
    final documents = _extrasFor(tripId).documents;
    final index = documents.indexWhere((d) => d.id == documentId);
    if (index != -1) {
      documents[index] = documents[index].copyWith(fileName: newName);
      _persist(tripId);
      notifyListeners();
    }
  }

  void removeTripDocument(String tripId, String documentId) {
    _extrasFor(tripId).documents.removeWhere((d) => d.id == documentId);
    _persist(tripId);
    notifyListeners();
  }

  void addExpense(String tripId, ExpenseEntry expense) {
    _extrasFor(tripId).expenses.add(expense);
    _persist(tripId);
    notifyListeners();
  }

  List<ExpenseEntry> expensesForTrip(String tripId) => List.unmodifiable(_extrasFor(tripId).expenses);

  void removeExpense(String tripId, String expenseId) {
    _extrasFor(tripId).expenses.removeWhere((e) => e.id == expenseId);
    _persist(tripId);
    notifyListeners();
  }

  /// Applies a [TripSnapshot] from a backup restore or import: registers
  /// the trip identity with [TripManager] (never a duplicate — an existing
  /// id is replaced in place), then replaces the matching dashboard extras
  /// (journey stops, expenses, trip-level documents). Weather and
  /// passport-expiry aren't part of the backup payload, so they carry over
  /// from the existing dashboard when there is one.
  void restoreTripSnapshot(TripSnapshot snapshot) {
    tripManager.upsertTrip(snapshot.trip);
    final previous = _extras[snapshot.trip.id];
    _extras[snapshot.trip.id] = _DashboardExtras(
      journeyStops: snapshot.journeyStops.isNotEmpty
          ? snapshot.journeyStops
          : [
              JourneyStop(
                location: snapshot.trip.destination,
                start: snapshot.trip.startDate,
                end: snapshot.trip.endDate,
              ),
            ],
      weather: previous?.weather,
      expenses: List.of(snapshot.expenses),
      documents: List.of(snapshot.documents),
      passportExpiryDate: previous?.passportExpiryDate,
    );
    _persist(snapshot.trip.id);
    notifyListeners();
  }

  @override
  void dispose() {
    tripManager.removeListener(_onTripManagerChanged);
    super.dispose();
  }
}
