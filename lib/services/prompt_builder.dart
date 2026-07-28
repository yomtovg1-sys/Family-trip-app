import 'package:intl/intl.dart';
import '../models/expense_entry.dart';
import '../models/place.dart';
import '../models/reservation.dart';
import '../models/travel_document.dart';
import '../models/trip_context_model.dart';
import '../utils/currency.dart';

/// Builds the structured prompt a real LLM provider would receive as
/// grounding context, automatically, from the current [TripContextModel] —
/// the user never types any of this themselves.
///
/// A local, rule-based `AIProvider` doesn't strictly need a flattened
/// string (it reads [TripContextModel] directly), but this is exactly the
/// system-prompt shape a remote provider like OpenAI would be given, so
/// building it here — rather than only inside the local provider — is what
/// keeps swapping providers a drop-in change.
class PromptBuilder {
  const PromptBuilder();

  String buildSystemPrompt(TripContextModel context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final trip = context.trip;
    final buffer = StringBuffer();

    buffer.writeln('You are a warm, concise personal travel assistant for one family.');
    buffer.writeln('Always answer using the TRIP DATA below before relying on general knowledge.');
    buffer.writeln('Never invent details the data does not contain — say what is actually known.');
    buffer.writeln();
    buffer.writeln('=== TRIP DATA ===');
    buffer.writeln('Trip: ${trip.name}');
    buffer.writeln('Destination: ${trip.destination} ${trip.flagEmoji}');
    buffer.writeln('Dates: ${dateFormat.format(trip.startDate)} – ${dateFormat.format(trip.endDate)} '
        '(${trip.durationInDays} days)');
    buffer.writeln('Currency: ${trip.currency}');
    buffer.writeln('Status: ${trip.hasEnded ? 'completed' : trip.hasStarted ? 'in progress' : 'upcoming'}');

    if (context.areas.isNotEmpty) {
      buffer.writeln('Areas/cities: ${context.areas.join(', ')}');
    }

    buffer.writeln();
    buffer.writeln('Saved places (${context.places.length}):');
    context.placesByArea.forEach((area, places) {
      buffer.writeln('- $area: ${places.map((p) => '${p.name} (${p.category.label})').join(', ')}');
    });

    buffer.writeln();
    buffer.writeln('Reservations (${context.reservations.length}):');
    for (final r in context.reservations) {
      buffer.writeln('- ${r.category.label}: ${r.title} on ${dateFormat.format(r.dateTime)} at ${r.location}');
    }

    buffer.writeln();
    buffer.writeln('Travel wallet documents (${context.walletDocuments.length}):');
    for (final d in context.walletDocuments) {
      buffer.writeln('- ${d.fileName} [${d.tag.label}]');
    }

    buffer.writeln();
    buffer.writeln('Expenses: total ${formatMoney(context.totalExpenses, trip.currency)} '
        'across ${context.expenses.length} entries');
    context.expensesByCategory.forEach((category, amount) {
      buffer.writeln('- ${category.label}: ${formatMoney(amount, trip.currency)}');
    });

    buffer.writeln();
    buffer.writeln('Packing list: ${context.packedCount}/${context.packingItems.length} packed');
    buffer.writeln('Memories: ${context.memories.length} photos saved');

    return buffer.toString();
  }
}
