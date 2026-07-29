import '../models/trip_context_model.dart';
import '../providers/memories_provider.dart';
import '../providers/packing_provider.dart';
import '../providers/places_provider.dart';
import '../providers/reservations_provider.dart';
import '../providers/trip_provider.dart';

/// Gathers everything the AI Assistant needs to know about the current trip
/// into a single [TripContextModel] — the seam that keeps the assistant
/// automatically "trip-aware" without the user ever having to explain their
/// plans, bookings, or budget.
abstract class AIContextService {
  TripContextModel buildContext();
}

/// The real implementation: reads live data straight out of the app's own
/// providers, so the assistant always sees exactly what's on screen.
class ProviderAIContextService implements AIContextService {
  final TripProvider tripProvider;
  final PlacesProvider placesProvider;
  final ReservationsProvider reservationsProvider;
  final PackingProvider packingProvider;
  final MemoriesProvider memoriesProvider;

  const ProviderAIContextService({
    required this.tripProvider,
    required this.placesProvider,
    required this.reservationsProvider,
    required this.packingProvider,
    required this.memoriesProvider,
  });

  @override
  TripContextModel buildContext() {
    final dashboard = tripProvider.current;
    final tripId = dashboard.trip.id;

    final places = placesProvider.forTrip(tripId);
    final reservations = reservationsProvider.forTrip(tripId);

    final walletDocuments = [
      ...dashboard.documents,
      for (final reservation in reservations) ...reservation.attachments,
    ];

    final areas = <String>{
      for (final stop in dashboard.journeyStops) stop.location,
      for (final place in places)
        if (place.area.trim().isNotEmpty) place.area.trim(),
    }.toList();

    return TripContextModel(
      trip: dashboard.trip,
      journeyStops: dashboard.journeyStops,
      areas: areas,
      places: places,
      reservations: reservations,
      walletDocuments: walletDocuments,
      expenses: dashboard.expenses,
      packingItems: packingProvider.forTrip(tripId),
      memories: memoriesProvider.forTrip(tripId),
      anchorLocation: placesProvider.simulatedCurrentLocation(tripId),
    );
  }
}
