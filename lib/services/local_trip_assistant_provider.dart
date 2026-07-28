import 'package:intl/intl.dart';
import '../models/ai_chat_message.dart';
import '../models/expense_entry.dart';
import '../models/place.dart';
import '../models/reservation.dart';
import '../models/travel_document.dart';
import '../models/trip_context_model.dart';
import '../utils/currency.dart';
import '../utils/geo.dart';
import 'ai_provider.dart';

/// The default, always-available [AIProvider]: no network call, no API
/// key — every answer is computed directly from the live
/// [TripContextModel], which is exactly why it can honestly claim to
/// "never answer using only general knowledge when trip-specific
/// information is available." A real LLM provider can be swapped in later
/// (see [UnavailableRemoteAIProvider]) without touching anything upstream.
class LocalTripAssistantProvider implements AIProvider {
  const LocalTripAssistantProvider();

  @override
  String get id => 'local-trip-assistant';

  @override
  String get displayName => 'Trip Assistant (offline)';

  @override
  AIProviderCapabilities get capabilities => const AIProviderCapabilities(supportsStreaming: true);

  @override
  Future<AIProviderReply> generateReply(AIProviderRequest request) async {
    return _reply(request.userMessage, request.context);
  }

  @override
  Stream<String> streamReply(AIProviderRequest request) async* {
    final reply = _reply(request.userMessage, request.context);
    final words = reply.text.split(' ');
    for (var i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 22));
      yield i == 0 ? words[i] : ' ${words[i]}';
    }
  }

  // ---------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------

  AIProviderReply _reply(String message, TripContextModel ctx) {
    final text = message.toLowerCase().trim();
    final currency = ctx.trip.currency;

    bool has(List<String> keywords) => keywords.any(text.contains);

    if (has(['passport', 'insurance', 'boarding', 'visa', 'wallet', 'document', 'pdf'])) {
      return _findDocuments(text, ctx);
    }
    if (has(['next reservation', 'upcoming reservation', "what's next"])) {
      return _nextReservation(ctx, currency);
    }
    if (has(['flight'])) {
      return _reservationsByCategory(ctx, ReservationCategory.flight, currency);
    }
    if (has(['hotel']) && has(['information', 'details', 'reservation', 'booking', 'check-in', 'checkin'])) {
      return _reservationsByCategory(ctx, ReservationCategory.hotel, currency);
    }
    if (has(['reservation', 'booking'])) {
      return _allReservations(ctx, currency);
    }
    if (has(['largest expense', 'biggest expense', 'most expensive'])) {
      return _largestExpenses(ctx, currency);
    }
    if (has(['expense', 'spent', 'spending', 'budget', 'cost of the trip'])) {
      if (has(['categor'])) return _expensesByCategory(ctx, currency);
      return _totalExpenses(ctx, currency);
    }
    if (has(['how many days', 'days left', 'days remaining', 'days do i have'])) {
      return _daysRemaining(ctx);
    }
    if (has(['what should i do today', 'today'])) {
      return _today(ctx);
    }
    if (has(['restaurant', 'food', 'hungry', 'dining', 'dinner', 'lunch', 'breakfast'])) {
      return _restaurants(ctx);
    }
    if (has(['attraction']) && has(['near', 'hotel', 'close'])) {
      return _nearbyAttractions(ctx);
    }
    if (has(['organize', 'plan my trip', 'plan the trip', 'itinerary'])) {
      return _organizeByArea(ctx);
    }
    if (has(['optimize', 'route', 'travel between'])) {
      return _optimizeRoute(ctx);
    }
    if (has(['activities', 'suggest activities', 'what can we do'])) {
      return _activitiesForDays(ctx);
    }
    if (has(['caption'])) {
      return _albumCaptions(ctx);
    }
    if (has(['album title', 'name the album', 'title for'])) {
      return _albumTitle(ctx);
    }
    if (has(['album'])) {
      return _albumHelp(ctx);
    }
    if (has(['trip summary', 'summarize my trip', 'overview'])) {
      return _tripSummary(ctx, currency);
    }
    if (has(['packing', 'pack'])) {
      return _packing(ctx);
    }
    if (has(['hello', 'hi ', 'hey'])) {
      return AIProviderReply(text: _greeting(ctx));
    }

    return _fallback(ctx);
  }

  // ---------------------------------------------------------------------
  // Trip planning
  // ---------------------------------------------------------------------

  AIProviderReply _organizeByArea(TripContextModel ctx) {
    if (ctx.places.isEmpty) {
      return AIProviderReply(
        text: "You haven't saved any places for ${ctx.trip.name} yet — add some from the Places tab and "
            "I'll help you organize them by area.",
        suggestedAction: AIQuickLinkTarget.mapPlaces,
        suggestedActionLabel: 'Open Places',
      );
    }
    final byArea = ctx.placesByArea;
    final lines = byArea.entries.map((e) => '• ${e.key}: ${e.value.map((p) => p.name).join(', ')}');
    return AIProviderReply(
      text: 'Here\'s how your ${ctx.places.length} saved places break down by area for ${ctx.trip.name}:\n\n'
          '${lines.join('\n')}\n\n'
          'Grouping your days by area like this will save you the most travel time.',
      suggestedAction: AIQuickLinkTarget.mapPlaces,
      suggestedActionLabel: 'Open Places',
    );
  }

  AIProviderReply _optimizeRoute(TripContextModel ctx) {
    final anchor = ctx.anchorLocation;
    if (ctx.places.length < 2 || anchor == null) {
      return AIProviderReply(
        text: 'Save a few more places and I can suggest the most efficient order to visit them in.',
        suggestedAction: AIQuickLinkTarget.mapPlaces,
        suggestedActionLabel: 'Open Places',
      );
    }
    final ordered = _nearestNeighborOrder(anchor, ctx.places);
    final lines = [
      for (var i = 0; i < ordered.length; i++) '${i + 1}. ${ordered[i].name} (${ordered[i].area})',
    ];
    return AIProviderReply(
      text: 'Starting from where you\'re staying, here\'s a low-backtracking order to visit your saved places:\n\n'
          '${lines.join('\n')}',
      suggestedAction: AIQuickLinkTarget.mapPlaces,
      suggestedActionLabel: 'Open Map',
    );
  }

  AIProviderReply _activitiesForDays(TripContextModel ctx) {
    final days = ctx.daysRemainingInTrip > 0 ? ctx.daysRemainingInTrip : ctx.trip.durationInDays;
    final attractions = ctx.places.where((p) => p.category == PlaceCategory.attractions).toList();
    if (attractions.isEmpty) {
      return AIProviderReply(
        text: 'You have $days day${days == 1 ? '' : 's'} for ${ctx.trip.name} — save a few attractions to '
            "your Places list and I'll help spread them across your days.",
        suggestedAction: AIQuickLinkTarget.mapPlaces,
        suggestedActionLabel: 'Open Places',
      );
    }
    final perDay = (attractions.length / days).ceil().clamp(1, attractions.length);
    return AIProviderReply(
      text: 'With $days day${days == 1 ? '' : 's'} and ${attractions.length} saved attraction'
          '${attractions.length == 1 ? '' : 's'}, aim for about $perDay a day so you\'re not rushing:\n\n'
          '${attractions.map((p) => '• ${p.name} (${p.area})').join('\n')}',
      suggestedAction: AIQuickLinkTarget.mapPlaces,
      suggestedActionLabel: 'Open Places',
    );
  }

  // ---------------------------------------------------------------------
  // Travel questions
  // ---------------------------------------------------------------------

  AIProviderReply _today(TripContextModel ctx) {
    final now = DateTime.now();
    final todaysReservations = ctx.reservations.where((r) => _isSameDay(r.dateTime, now)).toList();
    final buffer = StringBuffer();
    if (todaysReservations.isNotEmpty) {
      buffer.writeln('Today for ${ctx.trip.name}:');
      for (final r in todaysReservations) {
        buffer.writeln('• ${r.category.emoji} ${r.title} at ${DateFormat('h:mm a').format(r.dateTime)}');
      }
    } else if (!ctx.trip.hasStarted) {
      buffer.writeln(
          '${ctx.trip.name} hasn\'t started yet — it begins in ${ctx.daysUntilStart} day${ctx.daysUntilStart == 1 ? '' : 's'}.');
    } else if (ctx.trip.hasEnded) {
      buffer.writeln('${ctx.trip.name} has already wrapped up — check Memories for the highlights!');
    } else {
      buffer.writeln('Nothing booked for today on ${ctx.trip.name}, so it\'s a great day to explore.');
    }
    final attractions = ctx.places.where((p) => p.category == PlaceCategory.attractions).take(3).toList();
    if (attractions.isNotEmpty) {
      buffer.writeln('\nSaved ideas nearby: ${attractions.map((p) => p.name).join(', ')}.');
    }
    return AIProviderReply(
      text: buffer.toString().trim(),
      suggestedAction: AIQuickLinkTarget.mapPlaces,
      suggestedActionLabel: 'Open Places',
    );
  }

  AIProviderReply _nearbyAttractions(TripContextModel ctx) {
    final nearest = _nearestPlaces(ctx, category: PlaceCategory.attractions);
    if (nearest.isEmpty) {
      return AIProviderReply(
        text: "You don't have any attractions saved yet for ${ctx.trip.name} — save some from the Places tab "
            'and I\'ll rank them by distance from your hotel.',
        suggestedAction: AIQuickLinkTarget.mapPlaces,
        suggestedActionLabel: 'Open Places',
      );
    }
    return AIProviderReply(
      text: 'Closest saved attractions to your hotel:\n\n${_describeWithDistance(ctx, nearest)}',
      suggestedAction: AIQuickLinkTarget.mapPlaces,
      suggestedActionLabel: 'Open Places',
    );
  }

  AIProviderReply _restaurants(TripContextModel ctx) {
    final food = ctx.places
        .where((p) => p.category == PlaceCategory.restaurants || p.category == PlaceCategory.cafes)
        .toList();
    if (food.isEmpty) {
      return AIProviderReply(
        text: "You haven't saved any restaurants or cafes for ${ctx.trip.name} yet. Save some from the Places "
            "tab (or Google Maps search) and I'll sort them by distance from your hotel.",
        suggestedAction: AIQuickLinkTarget.mapPlaces,
        suggestedActionLabel: 'Open Places',
      );
    }
    final nearest = _nearestPlaces(ctx, category: null, from: food);
    return AIProviderReply(
      text: 'Restaurants and cafes you\'ve saved, closest first:\n\n${_describeWithDistance(ctx, nearest)}',
      suggestedAction: AIQuickLinkTarget.mapPlaces,
      suggestedActionLabel: 'Open Places',
    );
  }

  AIProviderReply _daysRemaining(TripContextModel ctx) {
    final trip = ctx.trip;
    if (!trip.hasStarted) {
      return AIProviderReply(
        text: '${trip.name} starts in ${ctx.daysUntilStart} day${ctx.daysUntilStart == 1 ? '' : 's'} and runs '
            'for ${trip.durationInDays} days total.',
      );
    }
    if (trip.hasEnded) {
      return AIProviderReply(text: '${trip.name} has already ended — I hope it was a great trip!');
    }
    final days = ctx.daysRemainingInTrip;
    return AIProviderReply(text: 'You have $days day${days == 1 ? '' : 's'} left on ${trip.name}.');
  }

  // ---------------------------------------------------------------------
  // Expenses
  // ---------------------------------------------------------------------

  AIProviderReply _totalExpenses(TripContextModel ctx, String currency) {
    if (ctx.expenses.isEmpty) {
      return AIProviderReply(
        text: "No expenses logged yet for ${ctx.trip.name}. Tap + on the Expenses tab to add your first one.",
        suggestedAction: AIQuickLinkTarget.expenses,
        suggestedActionLabel: 'Open Expenses',
      );
    }
    return AIProviderReply(
      text: "You've spent ${formatMoney(ctx.totalExpenses, currency)} so far on ${ctx.trip.name}, across "
          '${ctx.expenses.length} expense${ctx.expenses.length == 1 ? '' : 's'}.',
      suggestedAction: AIQuickLinkTarget.expenses,
      suggestedActionLabel: 'Open Expenses',
    );
  }

  AIProviderReply _expensesByCategory(TripContextModel ctx, String currency) {
    if (ctx.expenses.isEmpty) {
      return AIProviderReply(
        text: 'No expenses logged yet for ${ctx.trip.name}.',
        suggestedAction: AIQuickLinkTarget.expenses,
        suggestedActionLabel: 'Open Expenses',
      );
    }
    final sorted = ctx.expensesByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final lines = sorted.map((e) => '• ${e.key.emoji} ${e.key.label}: ${formatMoney(e.value, currency)}');
    return AIProviderReply(
      text: 'Expenses by category for ${ctx.trip.name} '
          '(total ${formatMoney(ctx.totalExpenses, currency)}):\n\n${lines.join('\n')}',
      suggestedAction: AIQuickLinkTarget.expenses,
      suggestedActionLabel: 'Open Expenses',
    );
  }

  AIProviderReply _largestExpenses(TripContextModel ctx, String currency) {
    if (ctx.expenses.isEmpty) {
      return AIProviderReply(
        text: 'No expenses logged yet for ${ctx.trip.name}.',
        suggestedAction: AIQuickLinkTarget.expenses,
        suggestedActionLabel: 'Open Expenses',
      );
    }
    final top = ctx.expensesByAmountDesc.take(3);
    final lines = top.map((e) => '• ${e.title}: ${formatMoney(e.amount, currency)}');
    return AIProviderReply(
      text: 'Your biggest expenses on ${ctx.trip.name} so far:\n\n${lines.join('\n')}',
      suggestedAction: AIQuickLinkTarget.expenses,
      suggestedActionLabel: 'Open Expenses',
    );
  }

  // ---------------------------------------------------------------------
  // Reservations
  // ---------------------------------------------------------------------

  AIProviderReply _nextReservation(TripContextModel ctx, String currency) {
    final now = DateTime.now();
    final upcoming = ctx.reservations.where((r) => r.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (upcoming.isEmpty) {
      return AIProviderReply(
        text: 'No upcoming reservations found for ${ctx.trip.name}.',
        suggestedAction: AIQuickLinkTarget.reservations,
        suggestedActionLabel: 'Open Reservations',
      );
    }
    final next = upcoming.first;
    return AIProviderReply(
      text: 'Your next reservation is ${next.category.emoji} ${next.title} on '
          '${DateFormat('EEE, MMM d · h:mm a').format(next.dateTime)} at ${next.location} '
          '(confirmation ${next.confirmationNumber}).',
      suggestedAction: AIQuickLinkTarget.reservations,
      suggestedActionLabel: 'Open Reservations',
    );
  }

  AIProviderReply _reservationsByCategory(TripContextModel ctx, ReservationCategory category, String currency) {
    final matches = ctx.reservations.where((r) => r.category == category).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (matches.isEmpty) {
      return AIProviderReply(
        text: 'No ${category.label.toLowerCase()} found for ${ctx.trip.name}.',
        suggestedAction: AIQuickLinkTarget.reservations,
        suggestedActionLabel: 'Open Reservations',
      );
    }
    final lines = matches.map((r) =>
        '• ${r.title} — ${DateFormat('EEE, MMM d, h:mm a').format(r.dateTime)} at ${r.location} '
        '(${r.provider}, confirmation ${r.confirmationNumber})');
    return AIProviderReply(
      text: '${category.label} for ${ctx.trip.name}:\n\n${lines.join('\n')}',
      suggestedAction: AIQuickLinkTarget.reservations,
      suggestedActionLabel: 'Open Reservations',
    );
  }

  AIProviderReply _allReservations(TripContextModel ctx, String currency) {
    if (ctx.reservations.isEmpty) {
      return AIProviderReply(
        text: 'No reservations saved yet for ${ctx.trip.name}.',
        suggestedAction: AIQuickLinkTarget.reservations,
        suggestedActionLabel: 'Open Reservations',
      );
    }
    final sorted = [...ctx.reservations]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final lines = sorted.map((r) => '• ${r.category.emoji} ${r.title} — ${DateFormat('MMM d').format(r.dateTime)}');
    return AIProviderReply(
      text: 'All reservations for ${ctx.trip.name}:\n\n${lines.join('\n')}',
      suggestedAction: AIQuickLinkTarget.reservations,
      suggestedActionLabel: 'Open Reservations',
    );
  }

  // ---------------------------------------------------------------------
  // Travel wallet
  // ---------------------------------------------------------------------

  AIProviderReply _findDocuments(String text, TripContextModel ctx) {
    final docs = ctx.walletDocuments;
    if (docs.isEmpty) {
      return AIProviderReply(
        text: 'Your Travel Wallet is empty for ${ctx.trip.name} — add passports, insurance, or boarding passes '
            'from the Travel Wallet tab.',
        suggestedAction: AIQuickLinkTarget.travelWallet,
        suggestedActionLabel: 'Open Travel Wallet',
      );
    }

    Iterable<TravelDocument> filtered = docs;
    String what = 'documents';
    if (text.contains('passport')) {
      filtered = docs.where((d) => d.tag.label == 'Passport' || d.fileName.toLowerCase().contains('passport'));
      what = 'passports';
    } else if (text.contains('insurance')) {
      filtered = docs.where((d) => d.tag.label == 'Insurance');
      what = 'insurance documents';
    } else if (text.contains('boarding')) {
      filtered = docs.where((d) =>
          d.tag.label == 'Flight' ||
          d.fileName.toLowerCase().contains('boarding') ||
          d.looksLikeQrCode);
      what = 'boarding passes';
    } else if (text.contains('visa')) {
      filtered = docs.where((d) => d.fileName.toLowerCase().contains('visa'));
      what = 'visas';
    } else if (text.contains('pdf')) {
      filtered = docs.where((d) => d.fileName.toLowerCase().endsWith('.pdf'));
      what = 'PDF documents';
    }

    final results = filtered.toList();
    if (results.isEmpty) {
      return AIProviderReply(
        text: "I couldn't find any $what in your Travel Wallet for ${ctx.trip.name}.",
        suggestedAction: AIQuickLinkTarget.travelWallet,
        suggestedActionLabel: 'Open Travel Wallet',
      );
    }
    final lines = results.map((d) => '• ${d.fileName}');
    return AIProviderReply(
      text: 'Found ${results.length} $what in your Travel Wallet:\n\n${lines.join('\n')}',
      suggestedAction: AIQuickLinkTarget.travelWallet,
      suggestedActionLabel: 'Open Travel Wallet',
    );
  }

  // ---------------------------------------------------------------------
  // Album
  // ---------------------------------------------------------------------

  AIProviderReply _albumHelp(TripContextModel ctx) {
    if (ctx.memories.isEmpty) {
      return AIProviderReply(
        text: "You don't have any photos saved yet for ${ctx.trip.name} — add some on the Memories tab and "
            "I'll help you title it and write captions.",
        suggestedAction: AIQuickLinkTarget.memories,
        suggestedActionLabel: 'Open Memories',
      );
    }
    return AIProviderReply(
      text: 'You have ${ctx.memories.length} photo${ctx.memories.length == 1 ? '' : 's'} saved for '
          '${ctx.trip.name} — I can suggest an album title, write captions, or summarize the trip. '
          'Ready to build it?',
      suggestedAction: AIQuickLinkTarget.albumPreview,
      suggestedActionLabel: 'Create Travel Album',
    );
  }

  AIProviderReply _albumTitle(TripContextModel ctx) {
    final trip = ctx.trip;
    final year = trip.startDate.year;
    final suggestions = [
      '${trip.destination} $year',
      'Our ${trip.name}',
      '${trip.flagEmoji} ${trip.destination} Adventure',
    ];
    return AIProviderReply(
      text: 'A few album title ideas for ${trip.name}:\n\n${suggestions.map((s) => '• $s').join('\n')}',
      suggestedAction: AIQuickLinkTarget.albumPreview,
      suggestedActionLabel: 'Create Travel Album',
    );
  }

  AIProviderReply _albumCaptions(TripContextModel ctx) {
    if (ctx.memories.isEmpty) {
      return AIProviderReply(
        text: 'Add a few photos to Memories first and I\'ll suggest captions for each one.',
        suggestedAction: AIQuickLinkTarget.memories,
        suggestedActionLabel: 'Open Memories',
      );
    }
    final dateFormat = DateFormat('MMM d');
    final sample = ctx.memories.take(3);
    final lines = sample.map((photo) {
      if (photo.caption != null && photo.caption!.trim().isNotEmpty) {
        return '• Already captioned: "${photo.caption}"';
      }
      return '• Photo from ${dateFormat.format(photo.takenAt)}: try something like '
          '"Another perfect day in ${ctx.trip.destination} ✨"';
    });
    return AIProviderReply(
      text: 'Caption ideas for your recent memories:\n\n${lines.join('\n')}\n\n'
          "Once real image understanding is connected I'll read each photo directly instead of guessing.",
      suggestedAction: AIQuickLinkTarget.memories,
      suggestedActionLabel: 'Open Memories',
    );
  }

  AIProviderReply _tripSummary(TripContextModel ctx, String currency) {
    final trip = ctx.trip;
    final buffer = StringBuffer()
      ..writeln('${trip.flagEmoji} ${trip.name} — ${trip.destination}')
      ..writeln('${DateFormat('MMM d').format(trip.startDate)}–${DateFormat('MMM d, yyyy').format(trip.endDate)} '
          '(${trip.durationInDays} days)');
    if (ctx.places.isNotEmpty) {
      buffer.writeln('${ctx.places.length} places saved across ${ctx.placesByArea.length} areas');
    }
    if (ctx.expenses.isNotEmpty) {
      buffer.writeln('${formatMoney(ctx.totalExpenses, currency)} spent so far');
    }
    if (ctx.memories.isNotEmpty) {
      buffer.writeln('${ctx.memories.length} memories captured');
    }
    return AIProviderReply(text: buffer.toString().trim());
  }

  // ---------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------

  AIProviderReply _packing(TripContextModel ctx) {
    if (ctx.packingItems.isEmpty) {
      return AIProviderReply(text: 'Your packing list is empty — add items from the Packing tab.');
    }
    final remaining = ctx.packingItems.length - ctx.packedCount;
    return AIProviderReply(
      text: "You've packed ${ctx.packedCount} of ${ctx.packingItems.length} items"
          '${remaining > 0 ? ' — $remaining left to go' : ' — all packed! 🎉'} for ${ctx.trip.name}.',
      suggestedAction: AIQuickLinkTarget.packing,
      suggestedActionLabel: 'Open Packing List',
    );
  }

  String _greeting(TripContextModel ctx) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');
    return '$timeGreeting! Ready to talk about ${ctx.trip.name}? Ask me about your places, reservations, '
        'expenses, or documents any time.';
  }

  AIProviderReply _fallback(TripContextModel ctx) {
    return AIProviderReply(
      text: "I'm not sure about that one, but I know everything saved for ${ctx.trip.name} — try asking about "
          "today's plans, nearby restaurants, your expenses, reservations, or travel documents.",
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<SavedPlace> _nearestPlaces(
    TripContextModel ctx, {
    PlaceCategory? category,
    List<SavedPlace>? from,
    int limit = 5,
  }) {
    final candidates = from ?? (category == null ? ctx.places : ctx.places.where((p) => p.category == category));
    final list = candidates.toList();
    final anchor = ctx.anchorLocation;
    if (anchor != null) {
      list.sort((a, b) => haversineKm(anchor.latitude, anchor.longitude, a.latitude, a.longitude)
          .compareTo(haversineKm(anchor.latitude, anchor.longitude, b.latitude, b.longitude)));
    }
    return list.take(limit).toList();
  }

  List<SavedPlace> _nearestNeighborOrder(({double latitude, double longitude}) start, List<SavedPlace> places) {
    final remaining = [...places];
    final ordered = <SavedPlace>[];
    var currentLat = start.latitude;
    var currentLng = start.longitude;
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) => haversineKm(currentLat, currentLng, a.latitude, a.longitude)
          .compareTo(haversineKm(currentLat, currentLng, b.latitude, b.longitude)));
      final next = remaining.removeAt(0);
      ordered.add(next);
      currentLat = next.latitude;
      currentLng = next.longitude;
    }
    return ordered;
  }

  String _describeWithDistance(TripContextModel ctx, List<SavedPlace> places) {
    final anchor = ctx.anchorLocation;
    return places.map((p) {
      if (anchor == null) return '• ${p.name} (${p.area})';
      final km = haversineKm(anchor.latitude, anchor.longitude, p.latitude, p.longitude);
      final distance = km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
      return '• ${p.name} (${p.area}) — $distance away';
    }).join('\n');
  }
}
