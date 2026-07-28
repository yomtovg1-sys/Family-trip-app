import 'dart:typed_data';

/// Architecture seam for sending a generated album out to a real
/// print-on-demand vendor (a physical photo book printing company). No
/// vendor is integrated yet — today, "exporting" an album means the family
/// downloads or shares the PDF directly (see AlbumPreviewScreen).
///
/// This interface exists so that capability can be added later — call a
/// vendor's API with the generated PDF and get back an order to track —
/// without redesigning the Album Preview screen. It is intentionally not
/// wired into any button yet.
abstract class PrintingService {
  Future<PrintOrder> submitOrder({
    required Uint8List pdfBytes,
    required String albumTitle,
    required int copies,
  });
}

/// The result of a submitted print order, once a real [PrintingService] is
/// implemented.
class PrintOrder {
  final String orderId;
  final PrintOrderStatus status;

  const PrintOrder({required this.orderId, required this.status});
}

enum PrintOrderStatus { submitted, processing, shipped, delivered, failed }

/// No print vendor is connected yet. Calling this throws on purpose, so a
/// future real implementation is a deliberate, visible swap-in rather than
/// a silent no-op somewhere in the UI.
class UnavailablePrintingService implements PrintingService {
  const UnavailablePrintingService();

  @override
  Future<PrintOrder> submitOrder({
    required Uint8List pdfBytes,
    required String albumTitle,
    required int copies,
  }) {
    throw UnimplementedError('Printing service integration is not available yet.');
  }
}
