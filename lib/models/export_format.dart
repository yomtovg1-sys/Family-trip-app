/// The file formats a trip can be exported as. [zip] is listed for the
/// future-ready "bundle everything, including photo files, into one
/// archive" export and isn't wired up yet — see [ExportFormatX.isAvailable].
enum ExportFormat { json, pdf, zip }

extension ExportFormatX on ExportFormat {
  String get label {
    switch (this) {
      case ExportFormat.json:
        return 'JSON (full backup)';
      case ExportFormat.pdf:
        return 'PDF (trip summary)';
      case ExportFormat.zip:
        return 'ZIP (coming soon)';
    }
  }

  String get description {
    switch (this) {
      case ExportFormat.json:
        return 'Every detail — places, reservations, expenses, documents, photos — as machine-readable data.';
      case ExportFormat.pdf:
        return 'A printable overview: itinerary, reservations, and spending.';
      case ExportFormat.zip:
        return 'A single archive with the JSON backup and original photo/document files.';
    }
  }

  bool get isAvailable => this != ExportFormat.zip;

  String fileName(String tripName) {
    final slug = tripName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    switch (this) {
      case ExportFormat.json:
        return '$slug-backup.json';
      case ExportFormat.pdf:
        return '$slug-summary.pdf';
      case ExportFormat.zip:
        return '$slug-export.zip';
    }
  }
}
