import '../models/reservation_attachment.dart';
import '../models/reservation_draft.dart';

/// Architecture seam for AI-assisted reservation entry. A future
/// implementation would send [attachment] (a boarding pass, hotel voucher,
/// PDF confirmation, or screenshot) to an OCR/LLM pipeline and recognize
/// dates, times, flight numbers, hotel names, confirmation numbers, and
/// addresses — returning them as a [ReservationDraft] that pre-fills the
/// "Add Reservation" form.
///
/// No real extraction is implemented yet; [MockReservationExtractor] is the
/// current no-op implementation so the rest of the app (the upload-first
/// flow in the add-reservation sheet) can already be wired against this
/// interface.
abstract class ReservationExtractor {
  Future<ReservationDraft> extract(ReservationAttachment attachment);
}

class MockReservationExtractor implements ReservationExtractor {
  const MockReservationExtractor();

  @override
  Future<ReservationDraft> extract(ReservationAttachment attachment) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const ReservationDraft();
  }
}
