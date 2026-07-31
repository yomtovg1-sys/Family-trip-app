import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/album_layout.dart';
import '../models/day_photos.dart';
import '../models/memory_photo.dart';
import '../utils/trip_days.dart';

/// Builds a printable travel album as PDF bytes: a cover page with the trip
/// name and album title, then each day in chronological order — a day
/// divider page followed by that day's photos laid out per [layout] — so
/// the album always preserves the same day-by-day structure as the
/// Memories page. Pure client-side generation — no network call, no
/// printing vendor involved.
Future<Uint8List> buildAlbumPdf({
  required String tripName,
  required String albumTitle,
  required List<DayPhotos> days,
  required AlbumLayout layout,
}) async {
  final doc = pw.Document();
  final images = {
    for (final day in days)
      for (final photo in day.photos) photo.id: pw.MemoryImage(photo.bytes),
  };

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              albumTitle,
              style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              tripName,
              style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 28),
            pw.Container(width: 64, height: 2, color: PdfColors.grey400),
          ],
        ),
      ),
    ),
  );

  final dateFormat = DateFormat('EEEE, MMM d');
  for (final day in days) {
    doc.addPage(_dayDividerPage(tripDayLabel(day.dayIndex), dateFormat.format(day.date)));

    switch (layout) {
      case AlbumLayout.classic:
        for (final photo in day.photos) {
          doc.addPage(_classicPage(images[photo.id]!));
        }
      case AlbumLayout.grid:
        for (var i = 0; i < day.photos.length; i += 4) {
          final chunk = day.photos.sublist(i, (i + 4).clamp(0, day.photos.length));
          doc.addPage(_gridPage(chunk, images));
        }
      case AlbumLayout.collage:
        for (var i = 0; i < day.photos.length; i += 3) {
          final chunk = day.photos.sublist(i, (i + 3).clamp(0, day.photos.length));
          doc.addPage(_collagePage(chunk, images));
        }
    }
  }

  return doc.save();
}

pw.Page _dayDividerPage(String label, String dateLabel) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    build: (context) => pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(dateLabel, style: const pw.TextStyle(fontSize: 15, color: PdfColors.grey700)),
        ],
      ),
    ),
  );
}

pw.Page _classicPage(pw.MemoryImage image) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    build: (context) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
  );
}

pw.Page _gridPage(List<MemoryPhoto> chunk, Map<String, pw.MemoryImage> images) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(20),
    build: (context) => pw.GridView(
      crossAxisCount: 2,
      childAspectRatio: 0.85,
      children: [
        for (final photo in chunk)
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Image(images[photo.id]!, fit: pw.BoxFit.cover),
          ),
      ],
    ),
  );
}

pw.Page _collagePage(List<MemoryPhoto> chunk, Map<String, pw.MemoryImage> images) {
  final big = chunk.first;
  final rest = chunk.skip(1).toList();
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(20),
    build: (context) => pw.Column(
      children: [
        pw.Expanded(flex: 2, child: pw.Image(images[big.id]!, fit: pw.BoxFit.cover)),
        if (rest.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Expanded(
            flex: 1,
            child: pw.Row(
              children: [
                for (var i = 0; i < rest.length; i++) ...[
                  if (i > 0) pw.SizedBox(width: 10),
                  pw.Expanded(child: pw.Image(images[rest[i].id]!, fit: pw.BoxFit.cover)),
                ],
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
