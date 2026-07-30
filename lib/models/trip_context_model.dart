import '../models/expense_entry.dart';
import '../models/journey_stop.dart';
import '../models/memory_photo.dart';
import '../models/packing_item.dart';
import '../models/place.dart';
import '../models/reservation.dart';
import '../models/travel_document.dart';
import '../models/trip.dart';

/// A read-only snapshot of everything the AI Assistant knows about the
/// current trip: the trip itself, its cities/areas, saved places,
/// reservations, travel wallet documents, expenses, packing list, and
/// memories. Built fresh by `AIContextService` before every reply, so the
/// user never has to explain any of this themselves.
class TripContextModel {
  final Trip trip;
  final List<JourneyStop> journeyStops;
  final List<String> areas;
  final List<SavedPlace> places;
  final List<Reservation> reservations;
  final List<TravelDocument> walletDocuments;
  final List<ExpenseEntry> expenses;
  final List<PackingItem> packingItems;
  final List<MemoryPhoto> memories;

  /// A stand-in "you are here" coordinate — the trip's saved hotel, or the
  /// first saved place, used for proximity questions ("near me", "near my
  /// hotel"). Mirrors PlacesProvider.simulatedCurrentLocation.
  final ({double latitude, double longitude})? anchorLocation;

  const TripContextModel({
    required this.trip,
    required this.journeyStops,
    required this.areas,
    required this.places,
    required this.reservations,
    required this.walletDocuments,
    required this.expenses,
    required this.packingItems,
    required this.memories,
    this.anchorLocation,
  });

  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + e.amount);

  Map<ExpenseCategory, double> get expensesByCategory {
    final map = <ExpenseCategory, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  List<ExpenseEntry> get expensesByAmountDesc =>
      [...expenses]..sort((a, b) => b.amount.compareTo(a.amount));

  Map<String, List<SavedPlace>> get placesByArea {
    final map = <String, List<SavedPlace>>{};
    for (final place in places) {
      final key = place.area.trim().isEmpty ? 'Unsorted' : place.area.trim();
      map.putIfAbsent(key, () => []).add(place);
    }
    return map;
  }

  /// Days until the trip starts (0 if it has already started).
  int get daysUntilStart => trip.hasStarted ? 0 : trip.timeUntilStart.inDays + 1;

  /// Days left in the trip while it's ongoing (0 before it starts or after
  /// it ends).
  int get daysRemainingInTrip {
    if (!trip.hasStarted || trip.hasEnded) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return trip.endDate.difference(today).inDays + 1;
  }

  int get packedCount => packingItems.where((i) => i.isPacked).length;

  bool get hasAnyData =>
      places.isNotEmpty ||
      reservations.isNotEmpty ||
      walletDocuments.isNotEmpty ||
      expenses.isNotEmpty ||
      memories.isNotEmpty;
}
