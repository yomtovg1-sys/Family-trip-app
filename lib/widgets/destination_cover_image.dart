import 'package:flutter/material.dart';
import '../utils/destination_covers.dart';

/// Renders a [DestinationCover] as a simple vector landscape — a gradient
/// sky behind a silhouette matching the destination's signature scenery
/// (a mountain peak, a coastal cliff, etc). Fully offline and destination-
/// matched, with no photo licensing or network dependency.
class DestinationCoverImage extends StatelessWidget {
  final DestinationCover cover;

  const DestinationCoverImage({super.key, required this.cover});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LandscapePainter(cover),
      size: Size.infinite,
    );
  }
}

class _LandscapePainter extends CustomPainter {
  final DestinationCover cover;

  _LandscapePainter(this.cover);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: cover.sky,
        ).createShader(rect),
    );

    switch (cover.scene) {
      case LandscapeScene.mountain:
        _paintMountain(canvas, size);
      case LandscapeScene.coastalCliff:
        _paintCoastalCliff(canvas, size);
      case LandscapeScene.lakesForest:
        _paintLakesForest(canvas, size);
      case LandscapeScene.beach:
        _paintBeach(canvas, size);
      case LandscapeScene.desert:
        _paintDesert(canvas, size);
      case LandscapeScene.citySkyline:
        _paintCitySkyline(canvas, size);
      case LandscapeScene.countryside:
        _paintCountryside(canvas, size);
    }
  }

  void _paintMountain(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sunPaint = Paint()..color = cover.accent.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(w * 0.78, h * 0.28), w * 0.07, sunPaint);

    final back = Path()
      ..moveTo(0, h * 0.72)
      ..lineTo(w * 0.28, h * 0.42)
      ..lineTo(w * 0.5, h * 0.62)
      ..lineTo(w * 0.74, h * 0.36)
      ..lineTo(w, h * 0.68)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = cover.land.withValues(alpha: 0.55));

    final peak = Path()
      ..moveTo(w * 0.2, h * 0.98)
      ..lineTo(w * 0.5, h * 0.32)
      ..lineTo(w * 0.8, h * 0.98)
      ..close();
    canvas.drawPath(peak, Paint()..color = cover.land);

    final snowCap = Path()
      ..moveTo(w * 0.5, h * 0.32)
      ..lineTo(w * 0.58, h * 0.46)
      ..lineTo(w * 0.5, h * 0.44)
      ..lineTo(w * 0.42, h * 0.46)
      ..close();
    canvas.drawPath(snowCap, Paint()..color = cover.accent.withValues(alpha: 0.95));
  }

  void _paintCoastalCliff(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sea = Rect.fromLTWH(0, h * 0.62, w, h * 0.38);
    canvas.drawRect(sea, Paint()..color = cover.accent.withValues(alpha: 0.55));

    final cliff = Path()
      ..moveTo(0, h * 0.7)
      ..lineTo(w * 0.18, h * 0.4)
      ..lineTo(w * 0.32, h * 0.5)
      ..lineTo(w * 0.5, h * 0.24)
      ..lineTo(w * 0.68, h * 0.46)
      ..lineTo(w * 0.85, h * 0.34)
      ..lineTo(w, h * 0.58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(cliff, Paint()..color = cover.land);

    final dotPaint = Paint()..color = cover.accent.withValues(alpha: 0.9);
    for (final dx in [0.28, 0.36, 0.44, 0.56, 0.64]) {
      canvas.drawRect(Rect.fromCenter(center: Offset(w * dx, h * 0.5), width: w * 0.03, height: h * 0.05), dotPaint);
    }
  }

  void _paintLakesForest(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final lake = Rect.fromLTWH(0, h * 0.66, w, h * 0.34);
    canvas.drawRect(lake, Paint()..color = cover.accent.withValues(alpha: 0.6));

    for (final terrace in [0.7, 0.6, 0.5]) {
      canvas.drawRect(
        Rect.fromLTWH(0, h * terrace, w, h * 0.04),
        Paint()..color = cover.land.withValues(alpha: 0.5),
      );
    }

    final treeline = Path()
      ..moveTo(0, h * 0.66)
      ..lineTo(w * 0.15, h * 0.5)
      ..lineTo(w * 0.3, h * 0.6)
      ..lineTo(w * 0.5, h * 0.42)
      ..lineTo(w * 0.7, h * 0.58)
      ..lineTo(w * 0.85, h * 0.46)
      ..lineTo(w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(treeline, Paint()..color = cover.land);
  }

  void _paintBeach(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w * 0.82, h * 0.24), w * 0.06, Paint()..color = cover.accent.withValues(alpha: 0.95));

    final sea = Rect.fromLTWH(0, h * 0.58, w, h * 0.26);
    canvas.drawRect(sea, Paint()..color = cover.land.withValues(alpha: 0.75));

    final sand = Rect.fromLTWH(0, h * 0.84, w, h * 0.16);
    canvas.drawRect(sand, Paint()..color = cover.accent.withValues(alpha: 0.5));

    final trunkPaint = Paint()..color = cover.land;
    final leafPaint = Paint()..color = cover.land.withValues(alpha: 0.85);
    for (final dx in [0.18, 0.85]) {
      final baseX = w * dx;
      canvas.drawLine(Offset(baseX, h * 0.9), Offset(baseX + w * 0.02, h * 0.55), trunkPaint..strokeWidth = w * 0.012);
      final leaves = Path()
        ..moveTo(baseX, h * 0.55)
        ..quadraticBezierTo(baseX - w * 0.12, h * 0.42, baseX - w * 0.02, h * 0.5)
        ..quadraticBezierTo(baseX + w * 0.1, h * 0.4, baseX + w * 0.04, h * 0.55)
        ..close();
      canvas.drawPath(leaves, leafPaint);
    }
  }

  void _paintDesert(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.09, Paint()..color = cover.accent.withValues(alpha: 0.85));

    final dune1 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.3, h * 0.5, w * 0.6, h * 0.68)
      ..quadraticBezierTo(w * 0.8, h * 0.78, w, h * 0.64)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(dune1, Paint()..color = cover.land.withValues(alpha: 0.65));

    final triangle = Paint()..color = cover.accent.withValues(alpha: 0.8);
    for (final dx in [0.62, 0.72, 0.82]) {
      final path = Path()
        ..moveTo(w * dx, h * 0.9)
        ..lineTo(w * dx + w * 0.08, h * 0.9)
        ..lineTo(w * dx + w * 0.04, h * 0.62)
        ..close();
      canvas.drawPath(path, triangle);
    }

    final dune2 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.4, h * 0.7, w, h * 0.9)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(dune2, Paint()..color = cover.land);
  }

  void _paintCitySkyline(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final buildingPaint = Paint()..color = cover.land;
    final windowPaint = Paint()..color = cover.accent.withValues(alpha: 0.8);

    final heights = [0.5, 0.62, 0.42, 0.7, 0.48, 0.6, 0.38, 0.66];
    final count = heights.length;
    final buildingWidth = w / count;
    for (var i = 0; i < count; i++) {
      final left = i * buildingWidth;
      final top = h * heights[i];
      final rect = Rect.fromLTWH(left + 2, top, buildingWidth - 4, h - top);
      canvas.drawRect(rect, buildingPaint);
      for (var row = top + h * 0.05; row < h - h * 0.05; row += h * 0.08) {
        canvas.drawRect(Rect.fromLTWH(left + buildingWidth * 0.3, row, buildingWidth * 0.12, h * 0.03), windowPaint);
        canvas.drawRect(Rect.fromLTWH(left + buildingWidth * 0.58, row, buildingWidth * 0.12, h * 0.03), windowPaint);
      }
    }
  }

  void _paintCountryside(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final hillBack = Path()
      ..moveTo(0, h * 0.68)
      ..quadraticBezierTo(w * 0.3, h * 0.5, w * 0.6, h * 0.64)
      ..quadraticBezierTo(w * 0.82, h * 0.74, w, h * 0.6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillBack, Paint()..color = cover.land.withValues(alpha: 0.55));

    final hillFront = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.35, h * 0.7, w * 0.65, h * 0.84)
      ..quadraticBezierTo(w * 0.85, h * 0.92, w, h * 0.8)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(hillFront, Paint()..color = cover.land);

    final dotPaint = Paint()..color = cover.accent.withValues(alpha: 0.85);
    for (final p in [
      Offset(w * 0.2, h * 0.9),
      Offset(w * 0.3, h * 0.94),
      Offset(w * 0.75, h * 0.88),
      Offset(w * 0.85, h * 0.93),
    ]) {
      canvas.drawCircle(p, w * 0.012, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LandscapePainter oldDelegate) => oldDelegate.cover != cover;
}
