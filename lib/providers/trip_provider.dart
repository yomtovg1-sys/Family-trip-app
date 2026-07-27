import 'package:flutter/material.dart';
import '../models/expense_entry.dart';
import '../models/journey_stop.dart';
import '../models/travel_alert.dart';
import '../models/trip.dart';
import '../models/weather_snapshot.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Everything the Home dashboard needs for one trip: the trip itself, its
/// route/journey, a weather snapshot, running expenses, and an optional
/// passport-expiry date used to derive alerts.
class TripDashboard {
  final Trip trip;
  final List<JourneyStop> journeyStops;
  final WeatherSnapshot? weather;
  final List<ExpenseEntry> expenses;
  final DateTime? passportExpiryDate;

  TripDashboard({
    required this.trip,
    required this.journeyStops,
    required this.weather,
    required this.expenses,
    this.passportExpiryDate,
  });

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

class TripProvider extends ChangeNotifier {
  final List<TripDashboard> _dashboards = _seedDashboards();
  int _selectedIndex = 0;

  List<TripDashboard> get all => List.unmodifiable(_dashboards);

  TripDashboard get current => _dashboards[_selectedIndex];

  Trip get trip => current.trip;

  void selectTrip(String tripId) {
    final index = _dashboards.indexWhere((d) => d.trip.id == tripId);
    if (index != -1 && index != _selectedIndex) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void addTrip({
    required String name,
    required String destination,
    required String flagEmoji,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final trip = Trip(
      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      heroEmoji: flagEmoji,
      flagEmoji: flagEmoji,
    );
    _dashboards.add(
      TripDashboard(
        trip: trip,
        journeyStops: [
          JourneyStop(location: destination, start: startDate, end: endDate),
        ],
        weather: null,
        expenses: const [],
      ),
    );
    _selectedIndex = _dashboards.length - 1;
    notifyListeners();
  }

  static List<TripDashboard> _seedDashboards() {
    final now = DateTime.now();

    final tahoe = Trip(
      id: 'trip-tahoe',
      name: 'Griswold Family Summer Adventure',
      destination: 'Lake Tahoe, California',
      startDate: now.add(const Duration(days: 21)),
      endDate: now.add(const Duration(days: 28)),
      heroEmoji: '🏔️',
      flagEmoji: '🇺🇸',
      photoAsset: 'assets/images/family_hero.jpg',
    );

    final japan = Trip(
      id: 'trip-japan',
      name: 'Japan Family Adventure',
      destination: 'Tokyo, Japan',
      startDate: now.add(const Duration(days: 410)),
      endDate: now.add(const Duration(days: 424)),
      heroEmoji: '🗼',
      flagEmoji: '🇯🇵',
    );

    final italy = Trip(
      id: 'trip-italy',
      name: 'Italy Family Trip',
      destination: 'Rome, Italy',
      startDate: now.subtract(const Duration(days: 201)),
      endDate: now.subtract(const Duration(days: 191)),
      heroEmoji: '🍝',
      flagEmoji: '🇮🇹',
    );

    return [
      TripDashboard(
        trip: tahoe,
        journeyStops: [
          JourneyStop(
            location: 'South Lake Tahoe',
            start: tahoe.startDate,
            end: tahoe.startDate.add(const Duration(days: 4)),
          ),
          JourneyStop(
            location: 'Truckee',
            start: tahoe.startDate.add(const Duration(days: 4)),
            end: tahoe.endDate,
          ),
        ],
        weather: const WeatherSnapshot(
          tempCelsius: 24,
          condition: WeatherCondition.sunny,
          rainChancePercent: 10,
          aiTip: 'Great day for outdoor activities. ☀️',
        ),
        expenses: [
          ExpenseEntry(
            id: 'e1',
            description: 'Round-trip flights',
            amount: 1450,
            category: ExpenseCategory.transportation,
            date: now.subtract(const Duration(days: 10)),
          ),
          ExpenseEntry(
            id: 'e2',
            description: 'Cabin rental (7 nights)',
            amount: 1200,
            category: ExpenseCategory.hotels,
            date: now.subtract(const Duration(days: 8)),
          ),
          ExpenseEntry(
            id: 'e3',
            description: 'Rental car',
            amount: 380,
            category: ExpenseCategory.transportation,
            date: now.subtract(const Duration(days: 5)),
          ),
          ExpenseEntry(
            id: 'e4',
            description: 'Grocery run',
            amount: 140,
            category: ExpenseCategory.food,
            date: now.subtract(const Duration(days: 3)),
          ),
          ExpenseEntry(
            id: 'e5',
            description: 'Kayak rental',
            amount: 90,
            category: ExpenseCategory.attractions,
            date: now.subtract(const Duration(days: 2)),
          ),
          ExpenseEntry(
            id: 'e6',
            description: 'Hiking permits',
            amount: 25,
            category: ExpenseCategory.attractions,
            date: now,
          ),
          ExpenseEntry(
            id: 'e7',
            description: 'Family day packs',
            amount: 60,
            category: ExpenseCategory.shopping,
            date: now,
          ),
        ],
      ),
      TripDashboard(
        trip: japan,
        journeyStops: [
          JourneyStop(
            location: 'Tokyo',
            start: japan.startDate,
            end: japan.startDate.add(const Duration(days: 3)),
          ),
          JourneyStop(
            location: 'Hakone',
            start: japan.startDate.add(const Duration(days: 3)),
            end: japan.startDate.add(const Duration(days: 5)),
          ),
          JourneyStop(
            location: 'Kyoto',
            start: japan.startDate.add(const Duration(days: 5)),
            end: japan.startDate.add(const Duration(days: 9)),
          ),
          JourneyStop(
            location: 'Osaka',
            start: japan.startDate.add(const Duration(days: 9)),
            end: japan.endDate,
          ),
        ],
        weather: const WeatherSnapshot(
          tempCelsius: 26,
          condition: WeatherCondition.partlyCloudy,
          rainChancePercent: 40,
          aiTip: 'Pack a light rain jacket just in case. 🌦️',
        ),
        expenses: [
          ExpenseEntry(
            id: 'j1',
            description: 'International flights (deposit)',
            amount: 600,
            category: ExpenseCategory.transportation,
            date: now.subtract(const Duration(days: 60)),
          ),
          ExpenseEntry(
            id: 'j2',
            description: 'Ryokan booking',
            amount: 450,
            category: ExpenseCategory.hotels,
            date: now.subtract(const Duration(days: 45)),
          ),
          ExpenseEntry(
            id: 'j3',
            description: 'JR Rail Pass',
            amount: 380,
            category: ExpenseCategory.transportation,
            date: now.subtract(const Duration(days: 10)),
          ),
          ExpenseEntry(
            id: 'j4',
            description: 'Travel guidebook & gear',
            amount: 70,
            category: ExpenseCategory.shopping,
            date: now.subtract(const Duration(days: 5)),
          ),
          ExpenseEntry(
            id: 'j5',
            description: 'Universal Studios tickets',
            amount: 210,
            category: ExpenseCategory.attractions,
            date: now,
          ),
        ],
        passportExpiryDate: now.add(const Duration(days: 90)),
      ),
      TripDashboard(
        trip: italy,
        journeyStops: [
          JourneyStop(
            location: 'Rome',
            start: italy.startDate,
            end: italy.startDate.add(const Duration(days: 3)),
          ),
          JourneyStop(
            location: 'Florence',
            start: italy.startDate.add(const Duration(days: 3)),
            end: italy.startDate.add(const Duration(days: 6)),
          ),
          JourneyStop(
            location: 'Venice',
            start: italy.startDate.add(const Duration(days: 6)),
            end: italy.endDate,
          ),
        ],
        weather: null,
        expenses: [
          ExpenseEntry(
            id: 'i1',
            description: 'Round-trip flights',
            amount: 1100,
            category: ExpenseCategory.transportation,
            date: italy.startDate,
          ),
          ExpenseEntry(
            id: 'i2',
            description: 'Hotels (3 cities)',
            amount: 1400,
            category: ExpenseCategory.hotels,
            date: italy.startDate.add(const Duration(days: 1)),
          ),
          ExpenseEntry(
            id: 'i3',
            description: 'Meals & trattorias',
            amount: 680,
            category: ExpenseCategory.food,
            date: italy.startDate.add(const Duration(days: 2)),
          ),
          ExpenseEntry(
            id: 'i4',
            description: 'Colosseum & Uffizi tickets',
            amount: 150,
            category: ExpenseCategory.attractions,
            date: italy.startDate.add(const Duration(days: 3)),
          ),
          ExpenseEntry(
            id: 'i5',
            description: 'Souvenirs',
            amount: 220,
            category: ExpenseCategory.shopping,
            date: italy.startDate.add(const Duration(days: 7)),
          ),
          ExpenseEntry(
            id: 'i6',
            description: 'Gondola ride',
            amount: 90,
            category: ExpenseCategory.attractions,
            date: italy.startDate.add(const Duration(days: 8)),
          ),
        ],
      ),
    ];
  }
}
