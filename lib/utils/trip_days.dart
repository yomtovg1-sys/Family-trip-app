import '../models/trip.dart';

/// The calendar date of day [dayIndex] (0-based) of [trip] — day 0 is
/// [Trip.startDate], day 1 is the next calendar day, and so on. Normalized
/// to midnight so it can be compared/formatted without time-of-day noise.
DateTime tripDayDate(Trip trip, int dayIndex) {
  final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
  return start.add(Duration(days: dayIndex));
}

/// "Day 1", "Day 2", ... — 1-based for display, built from the 0-based
/// [dayIndex] every other trip-days helper and [MemoryPhoto.dayIndex] use.
String tripDayLabel(int dayIndex) => 'Day ${dayIndex + 1}';

/// The 0-based index of today within [trip]'s date range, or `null` if
/// today falls before the trip starts or after it ends — used to highlight
/// "today's day" on the Memories page so the family can jump straight to
/// uploading without hunting for the right day.
int? currentTripDayIndex(Trip trip) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final startDate = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
  final diff = todayDate.difference(startDate).inDays;
  if (diff < 0 || diff >= trip.durationInDays) return null;
  return diff;
}
