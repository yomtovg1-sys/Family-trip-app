import 'dart:convert';
import 'dart:typed_data';

/// This app has no real files on disk, so seed data uses these placeholder
/// byte arrays: a tiny valid 1x1 PNG for "image" documents (so they can be
/// decoded and rendered as thumbnails), and arbitrary bytes for "pdf"/"other"
/// documents (which are never decoded as an image, just shown behind a file
/// icon).
final Uint8List placeholderImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

final Uint8List placeholderDocumentBytes = Uint8List.fromList(
  utf8.encode('placeholder document contents'),
);
