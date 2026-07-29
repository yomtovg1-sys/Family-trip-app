import 'package:flutter/material.dart';
import '../models/document_category.dart';
import '../models/expense_entry.dart';
import '../models/journey_stop.dart';
import '../models/travel_alert.dart';
import '../models/travel_document.dart';
import '../models/trip.dart';
import '../models/trip_snapshot.dart';
import '../models/weather_snapshot.dart';
import '../services/trip_manager.dart';
import '../utils/placeholder_bytes.dart';

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
}

/// The Home dashboard's view of trip data. [TripManager] is the source of
/// truth for which trips exist and which is active — this class only adds
/// the dashboard-specific extras (journey stops, weather, expenses,
/// trip-level documents) on top, keyed by the same trip ids, and mirrors
/// [TripManager]'s notifications so every screen watching [TripProvider]
/// (unchanged from before) keeps working exactly as it did.
class TripProvider extends ChangeNotifier {
  final TripManager tripManager;
  final Map<String, _DashboardExtras> _extras = _seedExtras();

  TripProvider({required this.tripManager}) {
    tripManager.addListener(_onTripManagerChanged);
  }

  void _onTripManagerChanged() => notifyListeners();

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
    return _extras.putIfAbsent(tripId, () => _DashboardExtras.startingPoint(_tripById(tripId)));
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
    notifyListeners();
  }

  void renameTripDocument(String tripId, String documentId, String newName) {
    final documents = _extrasFor(tripId).documents;
    final index = documents.indexWhere((d) => d.id == documentId);
    if (index != -1) {
      documents[index] = documents[index].copyWith(fileName: newName);
      notifyListeners();
    }
  }

  void removeTripDocument(String tripId, String documentId) {
    _extrasFor(tripId).documents.removeWhere((d) => d.id == documentId);
    notifyListeners();
  }

  void addExpense(String tripId, ExpenseEntry expense) {
    _extrasFor(tripId).expenses.add(expense);
    notifyListeners();
  }

  List<ExpenseEntry> expensesForTrip(String tripId) => List.unmodifiable(_extrasFor(tripId).expenses);

  void removeExpense(String tripId, String expenseId) {
    _extrasFor(tripId).expenses.removeWhere((e) => e.id == expenseId);
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
    notifyListeners();
  }

  @override
  void dispose() {
    tripManager.removeListener(_onTripManagerChanged);
    super.dispose();
  }

  static Map<String, _DashboardExtras> _seedExtras() {
    final now = DateTime.now();

    final tahoeStart = now.add(const Duration(days: 21));
    final tahoeEnd = now.add(const Duration(days: 28));
    final japanStart = now.add(const Duration(days: 410));
    final japanEnd = now.add(const Duration(days: 424));
    final italyStart = now.subtract(const Duration(days: 201));
    final italyEnd = now.subtract(const Duration(days: 191));

    return {
      'trip-tahoe': _DashboardExtras(
        journeyStops: [
          JourneyStop(
            location: 'South Lake Tahoe',
            start: tahoeStart,
            end: tahoeStart.add(const Duration(days: 4)),
          ),
          JourneyStop(
            location: 'Truckee',
            start: tahoeStart.add(const Duration(days: 4)),
            end: tahoeEnd,
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
            merchant: 'Delta Airlines',
            amount: 1450,
            currency: 'USD',
            category: ExpenseCategory.flights,
            date: now.subtract(const Duration(days: 10)),
          ),
          ExpenseEntry(
            id: 'e2',
            merchant: 'Cabin rental (7 nights)',
            amount: 1200,
            currency: 'USD',
            category: ExpenseCategory.hotel,
            date: now.subtract(const Duration(days: 8)),
          ),
          ExpenseEntry(
            id: 'e3',
            merchant: 'Enterprise Rent-A-Car',
            amount: 380,
            currency: 'USD',
            category: ExpenseCategory.transportation,
            date: now.subtract(const Duration(days: 5)),
          ),
          ExpenseEntry(
            id: 'e4',
            merchant: 'Grocery run',
            amount: 140,
            currency: 'USD',
            category: ExpenseCategory.grocery,
            date: now.subtract(const Duration(days: 3)),
          ),
          ExpenseEntry(
            id: 'e5',
            merchant: 'Kayak rental',
            amount: 90,
            currency: 'USD',
            category: ExpenseCategory.attractions,
            date: now.subtract(const Duration(days: 2)),
          ),
          ExpenseEntry(
            id: 'e6',
            merchant: 'Hiking permits',
            amount: 25,
            currency: 'USD',
            category: ExpenseCategory.attractions,
            date: now,
          ),
          ExpenseEntry(
            id: 'e7',
            merchant: 'Family day packs',
            amount: 60,
            currency: 'USD',
            category: ExpenseCategory.shopping,
            date: now,
          ),
        ],
        documents: [
          TravelDocument(
            id: 'doc1',
            fileName: 'Family Passports.pdf',
            type: AttachmentType.pdf,
            bytes: placeholderDocumentBytes,
            uploadedAt: now.subtract(const Duration(days: 12)),
            category: DocumentCategory.passport,
          ),
          TravelDocument(
            id: 'doc2',
            fileName: 'Travel Insurance Policy.pdf',
            type: AttachmentType.pdf,
            bytes: placeholderDocumentBytes,
            uploadedAt: now.subtract(const Duration(days: 9)),
            category: DocumentCategory.insurance,
          ),
          TravelDocument(
            id: 'doc3',
            fileName: 'Emergency Contacts.png',
            type: AttachmentType.image,
            bytes: placeholderImageBytes,
            uploadedAt: now.subtract(const Duration(days: 6)),
            category: DocumentCategory.emergencyContact,
          ),
        ],
      ),
      'trip-japan': _DashboardExtras(
        journeyStops: [
          JourneyStop(
            location: 'Tokyo',
            start: japanStart,
            end: japanStart.add(const Duration(days: 3)),
          ),
          JourneyStop(
            location: 'Hakone',
            start: japanStart.add(const Duration(days: 3)),
            end: japanStart.add(const Duration(days: 5)),
          ),
          JourneyStop(
            location: 'Kyoto',
            start: japanStart.add(const Duration(days: 5)),
            end: japanStart.add(const Duration(days: 9)),
          ),
          JourneyStop(
            location: 'Osaka',
            start: japanStart.add(const Duration(days: 9)),
            end: japanEnd,
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
            merchant: 'International flights (deposit)',
            amount: 600,
            currency: 'USD',
            category: ExpenseCategory.flights,
            date: now.subtract(const Duration(days: 60)),
          ),
          ExpenseEntry(
            id: 'j2',
            merchant: 'Ryokan booking',
            amount: 450,
            currency: 'USD',
            category: ExpenseCategory.hotel,
            date: now.subtract(const Duration(days: 45)),
          ),
          ExpenseEntry(
            id: 'j3',
            merchant: 'JR Rail Pass',
            amount: 380,
            currency: 'USD',
            category: ExpenseCategory.transportation,
            date: now.subtract(const Duration(days: 10)),
          ),
          ExpenseEntry(
            id: 'j4',
            merchant: 'Travel guidebook & gear',
            amount: 70,
            currency: 'USD',
            category: ExpenseCategory.shopping,
            date: now.subtract(const Duration(days: 5)),
          ),
          ExpenseEntry(
            id: 'j5',
            merchant: 'Universal Studios tickets',
            amount: 210,
            currency: 'USD',
            category: ExpenseCategory.attractions,
            date: now,
          ),
        ],
        passportExpiryDate: now.add(const Duration(days: 90)),
      ),
      'trip-italy': _DashboardExtras(
        journeyStops: [
          JourneyStop(
            location: 'Rome',
            start: italyStart,
            end: italyStart.add(const Duration(days: 3)),
          ),
          JourneyStop(
            location: 'Florence',
            start: italyStart.add(const Duration(days: 3)),
            end: italyStart.add(const Duration(days: 6)),
          ),
          JourneyStop(
            location: 'Venice',
            start: italyStart.add(const Duration(days: 6)),
            end: italyEnd,
          ),
        ],
        weather: null,
        expenses: [
          ExpenseEntry(
            id: 'i1',
            merchant: 'Round-trip flights',
            amount: 1100,
            currency: 'EUR',
            category: ExpenseCategory.flights,
            date: italyStart,
          ),
          ExpenseEntry(
            id: 'i2',
            merchant: 'Hotels (3 cities)',
            amount: 1400,
            currency: 'EUR',
            category: ExpenseCategory.hotel,
            date: italyStart.add(const Duration(days: 1)),
          ),
          ExpenseEntry(
            id: 'i3',
            merchant: 'Meals & trattorias',
            amount: 680,
            currency: 'EUR',
            category: ExpenseCategory.food,
            date: italyStart.add(const Duration(days: 2)),
          ),
          ExpenseEntry(
            id: 'i4',
            merchant: 'Colosseum & Uffizi tickets',
            amount: 150,
            currency: 'EUR',
            category: ExpenseCategory.attractions,
            date: italyStart.add(const Duration(days: 3)),
          ),
          ExpenseEntry(
            id: 'i5',
            merchant: 'Souvenirs',
            amount: 220,
            currency: 'EUR',
            category: ExpenseCategory.shopping,
            date: italyStart.add(const Duration(days: 7)),
          ),
          ExpenseEntry(
            id: 'i6',
            merchant: 'Gondola ride',
            amount: 90,
            currency: 'EUR',
            category: ExpenseCategory.attractions,
            date: italyStart.add(const Duration(days: 8)),
          ),
        ],
      ),
    };
  }
}
