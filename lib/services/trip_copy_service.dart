import '../models/expense_entry.dart';
import '../models/memory_photo.dart';
import '../models/place.dart';
import '../models/reservation.dart';
import '../models/packing_item.dart';
import '../providers/memories_provider.dart';
import '../providers/packing_provider.dart';
import '../providers/places_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';

/// The kinds of trip data that can be copied or moved from one trip to
/// another. [aiConversations] is listed because the feature is meant to be
/// future-ready for it, but there's no persisted, app-wide chat history to
/// copy yet (see `AIChatController`) — so it's marked unavailable rather
/// than faking a copy of nothing.
enum TripDataCategory { reservations, places, packingItems, expenses, memories, aiConversations }

extension TripDataCategoryX on TripDataCategory {
  String get label {
    switch (this) {
      case TripDataCategory.reservations:
        return 'Reservations';
      case TripDataCategory.places:
        return 'Explore Places';
      case TripDataCategory.packingItems:
        return 'Packing List';
      case TripDataCategory.expenses:
        return 'Expenses';
      case TripDataCategory.memories:
        return 'Memories';
      case TripDataCategory.aiConversations:
        return 'AI Chat';
    }
  }

  bool get isAvailable => this != TripDataCategory.aiConversations;
}

/// How many items of each category actually got copied — the destination
/// trip may already have had some, or a category may have had nothing to
/// copy, so this is reported back rather than assumed.
class TripCopyResult {
  final Map<TripDataCategory, int> copiedCounts;

  const TripCopyResult(this.copiedCounts);

  int get totalCopied => copiedCounts.values.fold(0, (sum, n) => sum + n);
}

/// Duplicates or moves trip data — reservations, places, packing items,
/// expenses, memories — from one trip to another. Every copied item gets a
/// brand-new id; nothing is shared by reference between trips here (that's
/// what the Personal Vault link is for — see [TripLinkService]). A move is
/// simply a copy followed by deleting the originals from the source trip.
class TripCopyService {
  final ReservationsProvider reservationsProvider;
  final PlacesProvider placesProvider;
  final PackingProvider packingProvider;
  final TripProvider tripProvider;
  final MemoriesProvider memoriesProvider;

  TripCopyService({
    required this.reservationsProvider,
    required this.placesProvider,
    required this.packingProvider,
    required this.tripProvider,
    required this.memoriesProvider,
  });

  TripCopyResult copy({
    required String fromTripId,
    required String toTripId,
    required Set<TripDataCategory> categories,
    bool move = false,
  }) {
    final counts = <TripDataCategory, int>{};

    if (categories.contains(TripDataCategory.reservations)) {
      counts[TripDataCategory.reservations] = _copyReservations(fromTripId, toTripId, move);
    }
    if (categories.contains(TripDataCategory.places)) {
      counts[TripDataCategory.places] = _copyPlaces(fromTripId, toTripId, move);
    }
    if (categories.contains(TripDataCategory.packingItems)) {
      counts[TripDataCategory.packingItems] = _copyPacking(fromTripId, toTripId, move);
    }
    if (categories.contains(TripDataCategory.expenses)) {
      counts[TripDataCategory.expenses] = _copyExpenses(fromTripId, toTripId, move);
    }
    if (categories.contains(TripDataCategory.memories)) {
      counts[TripDataCategory.memories] = _copyMemories(fromTripId, toTripId, move);
    }

    return TripCopyResult(counts);
  }

  String _newId(String prefix, int salt) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-$salt';

  int _copyReservations(String fromTripId, String toTripId, bool move) {
    final source = reservationsProvider.forTrip(fromTripId);
    var i = 0;
    for (final r in source) {
      reservationsProvider.addReservation(
        Reservation(
          id: _newId('rsv', i++),
          tripId: toTripId,
          category: r.category,
          subtype: r.subtype,
          title: r.title,
          dateTime: r.dateTime,
          endDateTime: r.endDateTime,
          location: r.location,
          confirmationNumber: r.confirmationNumber,
          provider: r.provider,
          phone: r.phone,
          website: r.website,
          notes: r.notes,
          status: r.status,
          attachments: r.attachments,
        ),
      );
      if (move) reservationsProvider.deleteReservation(r.id);
    }
    return source.length;
  }

  int _copyPlaces(String fromTripId, String toTripId, bool move) {
    final source = placesProvider.forTrip(fromTripId);
    var i = 0;
    for (final p in source) {
      placesProvider.addPlace(
        SavedPlace(
          id: _newId('place', i++),
          tripId: toTripId,
          name: p.name,
          latitude: p.latitude,
          longitude: p.longitude,
          category: p.category,
          area: p.area,
          notes: p.notes,
          isFavorite: p.isFavorite,
          googleMapsUrl: p.googleMapsUrl,
          source: p.source,
        ),
      );
      if (move) placesProvider.deletePlace(p.id);
    }
    return source.length;
  }

  int _copyPacking(String fromTripId, String toTripId, bool move) {
    final source = packingProvider.forTrip(fromTripId);
    var i = 0;
    for (final item in source) {
      packingProvider.addItem(
        PackingItem(
          id: _newId('pack', i++),
          tripId: toTripId,
          name: item.name,
          category: item.category,
          assignedTo: item.assignedTo,
        ),
      );
      if (move) packingProvider.removeItem(item.id);
    }
    return source.length;
  }

  int _copyExpenses(String fromTripId, String toTripId, bool move) {
    final source = tripProvider.expensesForTrip(fromTripId);
    var i = 0;
    for (final e in source) {
      tripProvider.addExpense(
        toTripId,
        ExpenseEntry(
          id: _newId('exp', i++),
          amount: e.amount,
          currency: e.currency,
          category: e.category,
          date: e.date,
          merchant: e.merchant,
          notes: e.notes,
          vatAmount: e.vatAmount,
          paymentMethod: e.paymentMethod,
          receipt: e.receipt,
        ),
      );
      if (move) tripProvider.removeExpense(fromTripId, e.id);
    }
    return source.length;
  }

  int _copyMemories(String fromTripId, String toTripId, bool move) {
    final source = memoriesProvider.forTrip(fromTripId);
    var i = 0;
    final copies = [
      for (final photo in source)
        MemoryPhoto(
          id: _newId('photo', i++),
          tripId: toTripId,
          bytes: photo.bytes,
          fileName: photo.fileName,
          caption: photo.caption,
          takenAt: photo.takenAt,
        ),
    ];
    if (copies.isNotEmpty) memoriesProvider.addPhotos(copies);
    if (move) {
      for (final photo in source) {
        memoriesProvider.deletePhoto(photo.id);
      }
    }
    return source.length;
  }
}
