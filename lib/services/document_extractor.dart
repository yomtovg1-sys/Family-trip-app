import '../models/reservation_draft.dart';
import '../models/travel_document.dart';

/// Architecture seam for AI-assisted document reading. A future
/// implementation would send [document] (a PDF, boarding pass, QR code,
/// hotel voucher, or screenshot) through an OCR/QR/LLM pipeline and
/// recognize:
///  - flight numbers
///  - dates and times
///  - hotel names
///  - reservation / confirmation numbers
///  - addresses
///
/// ...returning them as a [ReservationDraft] that pre-fills the "Add
/// Reservation" form, or in the future, auto-tags a Trip Document's
/// category (e.g. recognizing a passport scan).
///
/// No real extraction is implemented yet; [MockDocumentExtractor] is the
/// current no-op implementation so the rest of the app (the upload-first
/// flow in the add-reservation sheet, and document uploads in the Travel
/// Wallet) can already be wired against this interface.
abstract class DocumentExtractor {
  Future<ReservationDraft> extract(TravelDocument document);
}

class MockDocumentExtractor implements DocumentExtractor {
  const MockDocumentExtractor();

  @override
  Future<ReservationDraft> extract(TravelDocument document) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const ReservationDraft();
  }
}
