import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense_entry.dart';
import '../models/place.dart';
import '../models/reservation.dart';
import '../models/trip_snapshot.dart';
import '../utils/currency.dart';

/// Turns one trip's [TripSnapshot] into a downloadable file. JSON is a
/// full, lossless backup of that trip (the same shape a restore reads);
/// PDF is a human-readable summary for printing or sharing with family who
/// don't use the app. Pure client-side generation, no network involved —
/// same approach as [buildAlbumPdf].
class TripExportService {
  const TripExportService();

  Uint8List exportAsJson(TripSnapshot snapshot) {
    const encoder = JsonEncoder.withIndent('  ');
    return Uint8List.fromList(utf8.encode(encoder.convert(snapshot.toJson())));
  }

  Future<Uint8List> exportAsPdf(TripSnapshot snapshot) async {
    final trip = snapshot.trip;
    final dateFormat = DateFormat('MMM d, y');
    final doc = pw.Document();

    final totalExpenses = snapshot.expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final byCategory = <String, double>{};
    for (final e in snapshot.expenses) {
      byCategory[e.category.label] = (byCategory[e.category.label] ?? 0) + e.amount;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(trip.name, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${trip.destination} · ${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
            style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 24),
          if (snapshot.journeyStops.isNotEmpty) ...[
            _sectionTitle('Itinerary'),
            for (final stop in snapshot.journeyStops)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '${stop.location}: ${dateFormat.format(stop.start)} - ${dateFormat.format(stop.end)}',
                ),
              ),
            pw.SizedBox(height: 16),
          ],
          if (snapshot.reservations.isNotEmpty) ...[
            _sectionTitle('Reservations'),
            for (final r in snapshot.reservations)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(r.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '${r.category.singularLabel} · ${dateFormat.format(r.dateTime)} · ${r.provider} · Conf# ${r.confirmationNumber}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(height: 16),
          ],
          if (snapshot.places.isNotEmpty) ...[
            _sectionTitle('Saved Places (${snapshot.places.length})'),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in snapshot.places)
                  pw.Text('${p.category.emoji} ${p.name}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 16),
          ],
          if (snapshot.expenses.isNotEmpty) ...[
            _sectionTitle('Expenses — Total ${formatMoney(totalExpenses, trip.currency)}'),
            for (final entry in byCategory.entries)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key),
                    pw.Text(formatMoney(entry.value, trip.currency)),
                  ],
                ),
              ),
            pw.SizedBox(height: 16),
          ],
          _sectionTitle('Trip Wallet'),
          pw.Text('${snapshot.documents.length} documents · ${snapshot.photos.length} memories saved'),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
      );
}
