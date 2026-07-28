import 'reservation.dart';

/// Partial reservation fields recognized from an uploaded document. Produced
/// by a [ReservationExtractor] and used to pre-fill the manual reservation
/// form so the traveler only has to confirm/correct fields instead of typing
/// everything from scratch.
class ReservationDraft {
  final String? title;
  final ReservationCategory? category;
  final DateTime? dateTime;
  final String? location;
  final String? confirmationNumber;
  final String? provider;

  const ReservationDraft({
    this.title,
    this.category,
    this.dateTime,
    this.location,
    this.confirmationNumber,
    this.provider,
  });

  bool get isEmpty =>
      title == null &&
      category == null &&
      dateTime == null &&
      location == null &&
      confirmationNumber == null &&
      provider == null;
}
