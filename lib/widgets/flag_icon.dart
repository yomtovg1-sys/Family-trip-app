import 'package:flutter/material.dart';
import '../utils/flag_specs.dart';
import '../utils/world_countries.dart';

/// A country's flag, drawn as plain shapes rather than a Unicode flag
/// emoji. Flag emoji rely on a color-emoji font — proven, on real devices,
/// to not render at all in some browsers' CanvasKit build — so this draws
/// the flag itself instead, which has no font dependency and renders
/// identically everywhere.
class FlagIcon extends StatelessWidget {
  final Country? country;
  final double width;

  const FlagIcon(this.country, {super.key, this.width = 28});

  @override
  Widget build(BuildContext context) {
    final spec = country != null ? flagSpecFor(country!.iso2) : null;
    return Container(
      width: width,
      height: width * 0.72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 0.6),
      ),
      child: spec == null
          ? Container(color: const Color(0xFF9AA5B1))
          : CustomPaint(painter: _FlagPainter(spec), size: Size.infinite),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final FlagSpec spec;

  _FlagPainter(this.spec);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    switch (spec.layout) {
      case FlagLayout.solid:
        canvas.drawRect(rect, Paint()..color = spec.colors.first);

      case FlagLayout.horizontalStripes:
        final n = spec.colors.length;
        final h = size.height / n;
        for (var i = 0; i < n; i++) {
          canvas.drawRect(Rect.fromLTWH(0, h * i, size.width, h + 0.5), Paint()..color = spec.colors[i]);
        }

      case FlagLayout.verticalStripes:
        final n = spec.colors.length;
        final w = size.width / n;
        for (var i = 0; i < n; i++) {
          canvas.drawRect(Rect.fromLTWH(w * i, 0, w + 0.5, size.height), Paint()..color = spec.colors[i]);
        }

      case FlagLayout.nordicCross:
        canvas.drawRect(rect, Paint()..color = spec.colors[0]);
        final crossPaint = Paint()..color = spec.colors[1];
        canvas.drawRect(Rect.fromLTWH(size.width * 0.32, 0, size.width * 0.16, size.height), crossPaint);
        canvas.drawRect(Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.16), crossPaint);

      case FlagLayout.centeredCross:
        canvas.drawRect(rect, Paint()..color = spec.colors[0]);
        final crossPaint = Paint()..color = spec.colors[1];
        canvas.drawRect(Rect.fromLTWH(size.width * 0.42, 0, size.width * 0.16, size.height), crossPaint);
        canvas.drawRect(Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.16), crossPaint);

      case FlagLayout.disc:
        canvas.drawRect(rect, Paint()..color = spec.colors[0]);
        canvas.drawCircle(rect.center, size.height * 0.32, Paint()..color = spec.colors[1]);

      case FlagLayout.canton:
        final bgColors = spec.colors.sublist(0, spec.colors.length - 1);
        final cantonColor = spec.colors.last;
        if (bgColors.length == 1) {
          canvas.drawRect(rect, Paint()..color = bgColors.first);
        } else {
          final n = bgColors.length;
          final h = size.height / n;
          for (var i = 0; i < n; i++) {
            canvas.drawRect(Rect.fromLTWH(0, h * i, size.width, h + 0.5), Paint()..color = bgColors[i]);
          }
        }
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.5, size.height * 0.5), Paint()..color = cantonColor);
    }
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) => true;
}
