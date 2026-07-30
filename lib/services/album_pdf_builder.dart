import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/album_layout.dart';
import '../models/memory_photo.dart';

/// Builds a printable travel album as PDF bytes: a cover page with the trip
/// name and album title, followed by the photos in order (with captions,
/// where set), laid out per [layout]. Pure client-side generation — no
/// network call, no printing vendor involved.
Future<Uint8List> buildAlbumPdf({
  required String tripName,
  required String albumTitle,
  required List<MemoryPhoto> photos,
  required AlbumLayout layout,
}) async {
  final doc = pw.Document();
  final images = {for (final photo in photos) photo.id: pw.MemoryImage(photo.bytes)};

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

  switch (layout) {
    case AlbumLayout.classic:
      for (final photo in photos) {
        doc.addPage(_classicPage(photo, images[photo.id]!));
      }
      break;
    case AlbumLayout.grid:
      for (var i = 0; i < photos.length; i += 4) {
        final chunk = photos.sublist(i, (i + 4).clamp(0, photos.length));
        doc.addPage(_gridPage(chunk, images));
      }
      break;
    case AlbumLayout.collage:
      for (var i = 0; i < photos.length; i += 3) {
        final chunk = photos.sublist(i, (i + 3).clamp(0, photos.length));
        doc.addPage(_collagePage(chunk, images));
      }
      break;
  }

  return doc.save();
}

pw.Page _classicPage(MemoryPhoto photo, pw.MemoryImage image) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    build: (context) => pw.Column(
      children: [
        pw.Expanded(child: pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain))),
        if (photo.caption != null && photo.caption!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text(
            photo.caption!,
            style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ],
    ),
  );
}

pw.Page _gridPage(List<MemoryPhoto> chunk, Map<String, pw.MemoryImage> images) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(20),
    build: (context) => pw.GridView(
      crossAxisCount: 2,
      childAspectRatio: 0.85,
      children: [for (final photo in chunk) _gridCell(photo, images[photo.id]!)],
    ),
  );
}

pw.Widget _gridCell(MemoryPhoto photo, pw.MemoryImage image) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Column(
      children: [
        pw.Expanded(child: pw.Image(image, fit: pw.BoxFit.cover)),
        if (photo.caption != null && photo.caption!.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              photo.caption!,
              style: const pw.TextStyle(fontSize: 9),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
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
