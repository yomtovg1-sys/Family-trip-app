import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Real photos are at minimum a few KB; anything this small is
/// placeholder/seed data standing in for a file that was never uploaded.
bool looksLikeRealImage(Uint8List bytes) => bytes.length > 1024;

/// Renders [bytes] as an image, or a soft icon placeholder when the bytes
/// are too small to be a real photo (seed/demo data uses tiny stand-in
/// bytes so the app never has to touch a filesystem). Keeps every photo
/// grid from showing a broken-looking solid black square.
class ImageOrPlaceholder extends StatelessWidget {
  final Uint8List bytes;
  final BoxFit fit;
  final IconData icon;
  final double iconSize;

  const ImageOrPlaceholder({
    super.key,
    required this.bytes,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_rounded,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (!looksLikeRealImage(bytes)) {
      final theme = Theme.of(context);
      return Container(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: theme.colorScheme.primary),
      );
    }
    return Image.memory(bytes, fit: fit);
  }
}
